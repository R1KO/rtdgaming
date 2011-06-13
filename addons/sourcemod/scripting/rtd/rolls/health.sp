#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>

public setMaxHealth(client)
{
	//This should only be called on spawn or loadout change
	//when the player is expected to have full health
	
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	if(class == TFClass_Unknown)
		return;
	
	new decapitations = GetEntProp(client, Prop_Send, "m_iDecapitations");
	if(decapitations > 4)
		decapitations = 4;
	
	if(hasLoadoutChanged(client))
	{
		//PrintToChat(client, "Loadout change detected!");
		saveLoadout(client);
		
		clientMaxHealth[client] = GetClientHealth(client) - 15*decapitations;
		
		return;
	}
	
	//PrintToChat(client, "Diff: %i", GetTime() - clientSpawnTime[client]);
	if(GetTime() > clientSpawnTime[client])
		return;
	
	clientMaxHealth[client] = GetClientHealth(client) - 15*decapitations;
}

public bool:hasLoadoutChanged(client)
{
	//checks to see if player's loadout as changed
	
	//for weapons that are removed, only one is the shield so far
	//if(m_iItemDefinitionIndex == 131 && GetEntProp(client, Prop_Send, "m_bShieldEquipped"))
	//	return true;
	
	new iWeapon ;
	
	for (new islot = 0; islot < 5; islot++) 
	{
		iWeapon = GetPlayerWeaponSlot(client, islot);
		if (IsValidEntity(iWeapon))
		{
			//compare current loadout with previous loadout
			if(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex") != clientItems[client][islot])
				return true;
		}else{
			if(clientItems[client][islot] != -1)
				return true;
		}
	}
	
	if(GetEntProp(client, Prop_Send, "m_bShieldEquipped") != clientItems[client][6])
	{
		//PrintToChat(client, "Client shield status changed to: %i", GetEntProp(client, Prop_Send, "m_bShieldEquipped") );
		return true;
	}
	
	//check wearables. i.e. shields
	
	//save found wearables into an array
	new totWearables;
	new Handle: tempWearablesArray;
	tempWearablesArray = CreateArray(1, 8);
	
	new ent = -1;
	while( (ent = FindEntityByClassname(ent, "tf_wearable")) != -1 )
	{
		if (IsValidEntity(ent))
		{		
			if (GetEntDataEnt2(ent, m_hOwnerEntity) == client && totWearables < 6)
			{
				totWearables ++;
				SetArrayCell(tempWearablesArray, totWearables, GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex"));
				//tempIDIndex[totWearables] = GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");
			}
		}
	}
	
	
	//check to see if wearable m_iItemDefinitionIndex is still valid
	new bool:wearableFound = false;
	
	for (new i = 7; i < 11; i++)
	{
		if(clientItems[client][i] == 0)
			continue;
		
		wearableFound = false;
		for(new j = 1; j <= totWearables; j++)
		{
			if(GetArrayCell(tempWearablesArray, j, 0) == clientItems[client][i])
			{
				wearableFound = true;
			}
		}
		
		if(!wearableFound)
		{
			//PrintToChat(client, "Client no longer has: %i", clientItems[client][i]);
			CloseHandle(tempWearablesArray);
			return true;
		}
	}
	
	CloseHandle(tempWearablesArray);
	
	return false;
}

public saveLoadout(client)
{
	new iWeapon ;
	
	for (new islot = 0; islot < 6; islot++) 
	{
		iWeapon = GetPlayerWeaponSlot(client, islot);
		if (IsValidEntity(iWeapon))
		{
			clientItems[client][islot] = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
		}else{
			clientItems[client][islot] = -1;
		}
	}
	
	if(GetEntProp(client, Prop_Send, "m_bShieldEquipped"))
	{
		clientItems[client][6] = 1;
	}else{
		clientItems[client][6] = 0;
	}
	
	new curSlot = 7;
	new ent = -1;
	while( (ent = FindEntityByClassname(ent, "tf_wearable")) != -1 )
	{
		if ( IsValidEntity(ent) )
		{		
			if (GetEntDataEnt2(ent, FindSendPropOffs("CTFWearable", "m_hOwnerEntity")) == client)
			{
				if(curSlot < 10)
				{
					clientItems[client][curSlot] = GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");
					curSlot ++;
				}
			}
		}
	}
}

public Action:waitHealthAdjust(Handle:timer, any:client)
{
	if(client < 1)
		return Plugin_Stop;
	
	if(!IsClientInGame(client))
		return Plugin_Stop;
	
	setMaxHealth(client);
	
	//player was Hulk before but now he changed class
	if(client_rolls[client][AWARD_G_HULK][0])
	{
		//Fists of Steel + Hulk is a no no
		if(isPlayerHolding_UniqueWeapon(client, 331))
		{
			PrintToChat(client, "\x04[RTD]\x01You lost \x03%s\x01 for switching to the Fists of Steel", roll_Text[AWARD_G_HULK]);
			PrintCenterText(client, "You lost: %s for switching to the Fists of Steel", roll_Text[AWARD_G_HULK]);
			
			client_rolls[client][AWARD_G_HULK][0] = 0;
			client_rolls[client][AWARD_G_SPEED][0] = 0;
			ROFMult[client] = 1.0;
			
			Colorize(client, NORMAL);
			SetEntityGravity(client, 1.0);
			ResetClientSpeed(client);
		}
	}
	
	//Give the medic his ubercharge back
	if(!client_rolls[client][AWARD_B_WEAPONS][1])
		return Plugin_Stop;
	
	client_rolls[client][AWARD_B_WEAPONS][1] = 0;
	
	//used mainly for medic to restore ubercharge
	new weapon = GetPlayerWeaponSlot(client, 1);
	if (IsValidEntity(weapon))
	{
		new String:classname[64];
		GetEdictClassname(weapon, classname, 64);
		
		//is the player holding the medigun?
		if(StrEqual(classname, "tf_weapon_medigun"))
		{
			SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", float(client_rolls[client][AWARD_B_WEAPONS][2])/100.0);
		}
	}
	
	return Plugin_Stop;
}

public finalHealthAdjustments(client)
{
	new decapitations = GetEntProp(client, Prop_Send, "m_iDecapitations");
	if(decapitations > 4)
	{
		decapitations = 4;
	}
	
	return (clientMaxHealth[client] + 15*decapitations);
}

public Action:addHealth(client, amountOfHealth)
{
	//Adds health to a client but will not allow it to go over maxhealth
	if(IsClientConnected(client) || IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{	
			if ((GetClientHealth(client)+ amountOfHealth) > finalHealthAdjustments(client))
			{
				if(GetClientHealth(client) < finalHealthAdjustments(client))
					SetEntityHealth(client, finalHealthAdjustments(client));
				
				if((GetClientHealth(client)+ amountOfHealth -1) == finalHealthAdjustments(client))
					SetEntityHealth(client, finalHealthAdjustments(client));
			}else{
				SetEntityHealth(client,GetClientHealth(client) + amountOfHealth);
			}
		}
	}
}

public Action:addHealthPercentage(client, Float:percentOfMaxHealth, bool:allowOverHeal)
{
	//Adds health to a client but will not allow it to go over maxhealth
	if(IsClientConnected(client) || IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			new maxHealth = finalHealthAdjustments(client);
			new amountOfHealth = RoundToCeil(float(finalHealthAdjustments(client)) * percentOfMaxHealth);
			new clientHealth = GetClientHealth(client);
			
			if ((clientHealth + amountOfHealth) > maxHealth)
			{
				if(allowOverHeal)
				{
					SetEntityHealth(client, clientHealth + amountOfHealth);
				}else{
					
					if(clientHealth < maxHealth)
						SetEntityHealth(client, maxHealth);
					
					if((clientHealth + amountOfHealth -1) == maxHealth)
						SetEntityHealth(client, maxHealth);
				}
			}else{
				SetEntityHealth(client, clientHealth + amountOfHealth);
			}
		}
	}
}

public Action:RegenerateHealth(Handle:timer, any:client)
{
	if(client_rolls[client][AWARD_G_REGEN][0] && IsClientInGame(client))
	{
		addHealth(client, 3);
	}else{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}