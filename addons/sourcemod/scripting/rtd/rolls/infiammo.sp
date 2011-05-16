#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>

public Action:GivePlayerInfiAmmo(client)
{
	new iWeapon ;		
	new String:classname[256];
	
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	new islot = GetActiveWeaponSlot(client);
	iWeapon = GetPlayerWeaponSlot(client, islot);

	if(IsValidEntity(iWeapon))
	{
		//sandwich
		if (GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex") == 42)
			return;
		
		GetEntityNetClass(iWeapon, classname, sizeof(classname));
		new iCurAmmo;
		if(class == TFClass_Pyro || class == TFClass_Heavy || class == TFClass_Sniper && islot == 0)
			iCurAmmo = GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 4);
		else
			iCurAmmo = GetEntData(iWeapon, FindSendPropInfo(classname, "m_iClip1"));
		
		if(class == TFClass_Scout && (islot == 2))
			TF2_AddSpecialAmmo(client, 1, 2);
		else if(class == TFClass_Sniper && islot == 1)
			TF2_AddSpecialAmmo(client, 1, 2);
		else if(class == TFClass_Pyro || class == TFClass_Heavy || class == TFClass_Sniper && islot == 0 && iCurAmmo < TFClass_MaxAmmo[class][islot] * 1.25)
			SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 4, iCurAmmo + RoundToCeil(TFClass_MaxAmmo[class][islot] * 0.05));
		else if(iCurAmmo < TFClass_MaxAmmo[class][islot] * 1.25)
			SetEntData(iWeapon, FindSendPropInfo(classname, "m_iClip1"), iCurAmmo + RoundToCeil(TFClass_MaxAmmo[class][islot] * 0.05));
	}
	
	if(TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		new ent = -1;
		while ((ent = FindEntityByClassname(ent, "obj_sentrygun")) != -1)
		{
			if(IsValidEntity(ent))
			{
				if(GetEntDataEnt2(ent, FindSendPropOffs("CObjectSentrygun","m_hBuilder")) == client)
				{
					new String:modelname[128];
					GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 128);

					if (!StrEqual(modelname, "models/buildables/sentry1_blueprint.mdl"))
					{
						new iCurRock = GetEntProp(ent, Prop_Send, "m_iAmmoRockets");
						new iCurShell = GetEntProp(ent, Prop_Send, "m_iAmmoShells");
						
						if(iCurRock < 20 && client_rolls[client][AWARD_G_INFIAMMO][2] == 2)
						{
							client_rolls[client][AWARD_G_INFIAMMO][2] = 0;
							SetEntProp(ent, Prop_Send, "m_iAmmoRockets", iCurRock+1);
						}
						else
							client_rolls[client][AWARD_G_INFIAMMO][2] += 1;
						if(iCurShell < 200)
							SetEntProp(ent, Prop_Send, "m_iAmmoShells", iCurShell+10);
					}
					
				}
			}
		}
	}
}

//Creds to "noodleboy347" for orig
//New version is made to work as 1 function for Sandman, Jarate, and Milk
stock TF2_AddSpecialAmmo(iClient, iAmmo, iAmmoMax)
{
	new TFClassType:class = TF2_GetPlayerClass(iClient);
	if (class != TFClass_Scout && class != TFClass_Sniper) return; 
	
	new islot = GetActiveWeaponSlot(iClient);
	new iWeapon, weaponid;
	new bool:valid_weapon;
	
	iWeapon = GetPlayerWeaponSlot(iClient, islot);
	if(IsValidEntity(iWeapon))
		weaponid = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
	
	if(class == TFClass_Scout && (weaponid == 44 || weaponid == 222))
			valid_weapon = true;
	else if(weaponid == 58)
		valid_weapon = true;
	else
		valid_weapon = false;
	if (valid_weapon)
	{
		new iOffset = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		new iCurAmmo = GetEntData(iClient, iAmmoTable+iOffset);
		if(iCurAmmo < iAmmoMax)
			SetEntData(iClient, iAmmoTable+iOffset, iCurAmmo+iAmmo, 4, true);
	}
}

public GiveAmmo(client, amount)
{
	new clientAmmo[4];
	
	clientAmmo[0] = GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 4);
	clientAmmo[1] = GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 8);
	clientAmmo[2] = GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 12);
	
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	if (TFClass_MaxAmmo[class][0] > clientAmmo[0] )
	{
		if ((clientAmmo[0] + amount) > TFClass_MaxAmmo[class][0])
		{
			SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 4, (TFClass_MaxAmmo[class][0]) );
		}else{
			SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 4, (clientAmmo[0] + amount) );
		}
	}
	
	if (TFClass_MaxAmmo[class][1] > clientAmmo[1] )
	{
		if ((clientAmmo[1] + amount) > TFClass_MaxAmmo[class][1])
		{
			SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 8, (TFClass_MaxAmmo[class][1]) );
		}else{
			SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 8, (clientAmmo[1] + amount) );
		}
	}
	
	if (TFClass_MaxAmmo[class][2] > clientAmmo[2] )
	{
		if ((clientAmmo[2] + amount) > TFClass_MaxAmmo[class][2])
		{
			SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 12, (TFClass_MaxAmmo[class][2]) );
		}else{
			SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 12, (clientAmmo[2] + amount) );
		}
	}
}

public HasFullAmmo(client)
{
	new clientAmmo[4];
	
	clientAmmo[0] = GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 4);
	clientAmmo[1] = GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 8);
	clientAmmo[2] = GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 12);
	
	new TFClassType:class = TF2_GetPlayerClass(client);
	if
		(
			clientAmmo[0] >= TFClass_MaxAmmo[class][0] &&
			clientAmmo[1] >= TFClass_MaxAmmo[class][1] &&
			clientAmmo[2] >= TFClass_MaxAmmo[class][2]
		)
		return true;
	return false;
}

stock GetWeaponAmmo(client, slot)
{
    return GetEntData(client,FindDataMapOffs(client, "m_iAmmo")+((slot+1)*4));
}

stock SetWeaponAmmo(client, slot, amount)
{
    SetEntData(client,FindDataMapOffs(client, "m_iAmmo")+((slot+1)*4),amount);
}

stock GetActiveWeaponSlot(client)
{
	new weapon = GetEntDataEnt2(client, FindSendPropInfo("CTFPlayer", "m_hActiveWeapon"));
	new lookupWeapon;
	
	if(IsValidEntity(weapon))
	{
		for (new islot = 0; islot < 3; islot++) 
		{
			lookupWeapon = GetPlayerWeaponSlot(client, islot);
			if (weapon == lookupWeapon)
			{
				return islot;
			}
		}
	}
	return -1;
}

public GiveAmmoToActiveWeapon(client, Float:percentage)
{
	//The function name might be a little misleading
	///what this does is it gives ammo to the active weapon
	//but is based on the percentage of the weapons max ammo
	//
	//For example to simulate a Small Ammopack on a client 
	//GiveAmmoToActiveWeapon(client, 0.205)
	//I use 0.205 because that is the amount of ammo a small ammopack gives
	
	new islot = GetActiveWeaponSlot(client);
	
	if(islot != -1)
	{
		new amount;
		
		new weaponAmmo = GetWeaponAmmo(client, islot);
		
		new TFClassType:class = TF2_GetPlayerClass(client);
		
		amount = RoundFloat(float(TFClass_MaxAmmo[class][islot]) * percentage);
		
		if(amount == 0)
			amount = 1;
		
		//PrintToChat(client, "MaxAmmo: %i | CurAmmo: %i | Give: %i", TFClass_MaxAmmo[class][islot], weaponAmmo, amount);
		if (TFClass_MaxAmmo[class][islot] > weaponAmmo )
		{
			if ((weaponAmmo + amount) > TFClass_MaxAmmo[class][islot])
			{
				SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + ((islot+1)*4), (TFClass_MaxAmmo[class][islot]) );
			}else{
				SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + ((islot+1)*4), (weaponAmmo + amount) );
			}
		}
	}
}

stock AmmoInActiveWeapon(client)
{
	new islot = GetActiveWeaponSlot(client);
	
	if(islot != -1)
	{
		new weaponAmmo = GetWeaponAmmo(client, islot);
		
		return weaponAmmo;
	}
	
	return 0;
}

stock SetActiveWeaponAmmo(client, amount)
{
	new islot = GetActiveWeaponSlot(client);
	
	if(islot != -1)
	{
		SetEntData(client,FindDataMapOffs(client, "m_iAmmo")+((islot+1)*4),amount);
	}
}