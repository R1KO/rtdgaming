//Last modified: 1/8/2010
#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <rtd_rollinfo>

///SPECIAL THANKS//////////////////////////////////////////////////////////////////
//FuncommandsX                                                                   //
//=============                                                                  //
//                                                                               //
//All of the Invisibility code is by: FuncommandsX - By Spazman0 and Arg!        //
//Without their code this would not be possible :D                               //
///////////////////////////////////////////////////////////////////////////////////


public Action:Timer_InvisLowHealth(Handle:Timer, any:dataPackHandle)
{
	ResetPack(dataPackHandle);
	new client = ReadPackCell(dataPackHandle);
	
	if(!IsClientConnected(client) || !IsClientInGame(client))
		return Plugin_Stop;
	
	if(roundEnded)
		return Plugin_Continue;
	
	if(!IsPlayerAlive(client))
		return Plugin_Stop;
	
	if(!client_rolls[client][AWARD_G_INVISLOWHEALTH][0])
		return Plugin_Stop;
	
	if(client_rolls[client][AWARD_G_INVIS][0]) return Plugin_Continue;
	
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	new timeOfLastFakeDeath = ReadPackCell(dataPackHandle);
	new allowFakeDeath = ReadPackCell(dataPackHandle);
	
	new cflags = GetEntData(client, FindSendPropOffs("CBasePlayer", "m_fFlags"));
	
	if (GetClientHealth(client)  < RoundFloat(finalHealthAdjustments(client) * 0.5))
	{
		new alpha = GetEntData(client, m_clrRender + 3, 1);
		if(alpha == 255 && (GetTime() - timeOfLastFakeDeath) > 5 && allowFakeDeath)
		{
			SpawnFakeBody(client);
			SetPackPosition(dataPackHandle, 8);
			WritePackCell(dataPackHandle, GetTime());//PackPosition(8) - This is the last time a fake body was spawned
			WritePackCell(dataPackHandle, 0);//PackPosition(16) - Disable fake death
		}
		
		client_rolls[client][AWARD_G_INVISLOWHEALTH][4] = 1;
		
		InvisibleHideFixes(client, class, 0);
		SetHudTextParams(0.425, 0.82, 0.5, 250, 250, 210, 255);
		ShowHudText(client, HudMsg3, "You are invisible");
		
		DeleteParticle(client, "all");
		Colorize(client, INVIS);
		addHealth(client, 4, false);
	} else {
		SetPackPosition(dataPackHandle, 16);
		WritePackCell(dataPackHandle, 1);//PackPosition(16) - allow fake death
		
		if(!client_rolls[client][AWARD_G_INVIS][0])
		{
			new alpha = GetEntData(client, m_clrRender + 3, 1);
			if(alpha != 255)
			{
				if(!client_rolls[client][AWARD_G_CROUCHINVIS][0])
				{
					Colorize(client, NORMAL);
					InvisibleHideFixes(client, class, 1);
					client_rolls[client][AWARD_G_INVISLOWHEALTH][4] = 0;
				}else{
					if(!(cflags & FL_DUCKING &&  cflags && FL_ONGROUND))
					{
						Colorize(client, NORMAL);
						InvisibleHideFixes(client, class, 1);
						client_rolls[client][AWARD_G_INVISLOWHEALTH][4] = 0;
					}
				}
			}
			
		}
	}
	
	return Plugin_Continue;
}

public Action:CrouchInvisTimer(Handle:Timer)
{
	for (new i = 1; i <= MaxClients; i++) 
	{
		if(!IsClientConnected(i) || !IsClientInGame(i))
			continue;
		
		if(!IsPlayerAlive(i))
			continue;
		
		if(client_rolls[i][AWARD_G_INVIS][0]) return Plugin_Continue;
		
		new TFClassType:class = TF2_GetPlayerClass(i);
		
		if(client_rolls[i][AWARD_G_CROUCHINVIS][0])
		{
			
			new cflags = GetEntData(i, FindSendPropOffs("CTFPlayer", "m_fFlags"));
			
			if(cflags & FL_DUCKING &&  cflags & FL_ONGROUND) 
			{
				// player is ducking
				//PrintCenterText(i, "You are invisible!");
				SetHudTextParams(0.425, 0.82, 0.5, 250, 250, 210, 255);
				ShowHudText(i, HudMsg3, "You are invisible");
				InvisibleHideFixes(i, class, 0);
				DeleteParticle(i, "all");
				Colorize(i, INVIS);
				
				client_rolls[i][AWARD_G_CROUCHINVIS][4] = 1;
			} else {
				//player is NOT ducking
				isUserDucking[i] = 0;
				
				crouchInvisAlpha[i] = 255;
				new alpha = GetEntData(i, m_clrRender + 3, 1);
				
				//prevent conflictions with InvisLowHealth
				if ((client_rolls[i][AWARD_G_INVISLOWHEALTH][0] && GetClientHealth(i)  >= RoundFloat(finalHealthAdjustments(i) * 0.5)) || !client_rolls[i][AWARD_G_INVISLOWHEALTH][0])
				{
					if(alpha != 255)
					{
						Colorize(i, NORMAL);
						InvisibleHideFixes(i, class, 1);
						
						client_rolls[i][AWARD_G_CROUCHINVIS][4] = 0;
					}
				}
				
			}
		}
	}
	return Plugin_Continue;
}

stock Colorize(client, c[4], self=true)
{	
	//c is NOT passed by value, we don't want to modify it.
	new color[4];
	color[0] = c[0];
	color[1] = c[1];
	color[2] = c[2];
	color[3] = c[3];
	//Colorize the weapons
	
	new type;
	
	if(client_rolls[client][AWARD_G_HULK][0] && color[3] >= 255)
	{
		color[0] = 0;
		color[1] = 255;
		color[2] = 0;
	}
	
	new weapon;
	for (new slot = 0; slot <= 6; slot++)
	{
		weapon = GetPlayerWeaponSlot(client, slot);
		
		if(weapon > -1 )
		{
			SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(weapon, color[0], color[1], color[2], color[3]);
		}
	}
	
	//Colorize the wearables, such as hats
	SetWearablesRGBA_Impl( client, "tf_wearable", "CTFWearable",color );
	SetWearablesRGBA_Impl( client, "tf_wearable_demoshield", "CTFWearableDemoShield", color);
	
	//Colorize any backpacks
	if(client_rolls[client][AWARD_G_BACKPACK][0])
	{
		if(IsValidEntity(client_rolls[client][AWARD_G_BACKPACK][1]))
		{
			new currIndex = GetEntProp(client_rolls[client][AWARD_G_BACKPACK][1], Prop_Data, "m_nModelIndex");
			
			if(currIndex == backpackModelIndex[0] || currIndex == backpackModelIndex[1] || currIndex == backpackModelIndex[2] || currIndex == backpackModelIndex[3])
			{
				SetEntityRenderMode(client_rolls[client][AWARD_G_BACKPACK][1], RENDER_TRANSCOLOR);	
				SetEntityRenderColor(client_rolls[client][AWARD_G_BACKPACK][1], color[0], color[1], color[2], color[3]);
			}
		}
	}
	
	//Colorize any backpack blizzards
	if(client_rolls[client][AWARD_G_BACKPACK][0])
	{
		if(IsValidEntity(client_rolls[client][AWARD_G_BLIZZARD][1]))
		{
			new currIndex = GetEntProp(client_rolls[client][AWARD_G_BLIZZARD][1], Prop_Data, "m_nModelIndex");
			
			if(currIndex == blizzardModelIndex[0] || currIndex == blizzardModelIndex[1])
			{
				SetEntityRenderMode(client_rolls[client][AWARD_G_BLIZZARD][1], RENDER_TRANSCOLOR);	
				SetEntityRenderColor(client_rolls[client][AWARD_G_BLIZZARD][1], color[0], color[1], color[2], color[3]);
			}
		}
	}
	
	//Colorize the player
	if (self) {
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
	}
	
	if(color[3] > 0)
		type = 1;
	
	new TFClassType:class = TF2_GetPlayerClass(client);
	InvisibleHideFixes(client, class, type);
	return;
}

SetWearablesRGBA_Impl( client,  const String:entClass[], const String:serverClass[], color[4])
{
	new ent = -1;
	while( (ent = FindEntityByClassname(ent, entClass)) != -1 )
	{
		if ( IsValidEntity(ent) )
		{		
			if (GetEntDataEnt2(ent, FindSendPropOffs(serverClass, "m_hOwnerEntity")) == client)
			{
				SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
				SetEntityRenderColor(ent, color[0], color[1], color[2], color[3]);
			}
		}
	}
}

InvisibleHideFixes(client, TFClassType:class, type)
{
	if(class == TFClass_DemoMan)
	{
		new decapitations = GetEntProp(client, Prop_Send, "m_iDecapitations");
		if(decapitations >= 1)
		{
			if(!type)
			{
				//Removes Glowing Eye
				TF2_RemoveCond(client, 18);
			}
			else
			{
				//Add Glowing Eye
				TF2_AddCond(client, 18);
			}
		}
	}
	else if(class == TFClass_Spy)
	{
		new disguiseWeapon = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
		if(IsValidEntity(disguiseWeapon))
		{
			//make sure that the entity has a rendermode
			new offsetSearch = -1;
			offsetSearch = FindDataMapOffs(disguiseWeapon,"m_nRenderMode");
			
			if(offsetSearch != -1)
			{
				if(!type)
				{
					SetEntityRenderMode(disguiseWeapon , RENDER_TRANSCOLOR);
					new color[4] = INVIS;
					SetEntityRenderColor(disguiseWeapon , color[0], color[1], color[2], color[3]);
				}
				else
				{
					SetEntityRenderMode(disguiseWeapon , RENDER_TRANSCOLOR);
					new color[4] = NORMAL;
					SetEntityRenderColor(disguiseWeapon , color[0], color[1], color[2], color[3]);
				}
			}
		}
	}
}

public SpawnFakeBody(client)
{
	new Float:PlayerPosition[3];
	
	new FakeBody = CreateEntityByName("tf_ragdoll");
	
	//Show Dissolve effect
	if(lastAttackerOnPlayer[client] > 0 && lastAttackerOnPlayer[client] <= MaxClients && IsValidEdict(FakeBody))
	{
		if(RTDOptions[lastAttackerOnPlayer[client]][4])
		{
			//CreateTimer(0.0, Dissolve, client); 
			new String:dname[32], String:dtype[32];
			Format(dname, sizeof(dname), "dis_%d", client);
			Format(dtype, sizeof(dtype), "%d", 0);
			
			new ent = CreateEntityByName("env_entity_dissolver");
			if (ent>0)
			{
				DispatchKeyValue(FakeBody, "targetname", dname);
				DispatchKeyValue(ent, "dissolvetype", dtype);
				DispatchKeyValue(ent, "target", dname);
				AcceptEntityInput(ent, "Dissolve");
				AcceptEntityInput(ent, "kill");
			}
		}
	}
	
	if (DispatchSpawn(FakeBody))
	{
		GetClientAbsOrigin(client, PlayerPosition);
		new offset = FindSendPropOffs("CTFRagdoll", "m_vecRagdollOrigin");
		SetEntDataVector(FakeBody, offset, PlayerPosition);
		
		offset = FindSendPropOffs("CTFRagdoll", "m_iClass");
		new TFClassType:class = TF2_GetPlayerClass(client);
		SetEntData(FakeBody, offset, class);
		
		offset = FindSendPropOffs("CTFRagdoll", "m_iPlayerIndex");
		SetEntData(FakeBody, offset, client);
		
		new team = GetClientTeam(client);
		offset = FindSendPropOffs("CTFRagdoll", "m_iTeam");
		SetEntData(FakeBody, offset, team);
		
	}
}

public bool:hasInvisRolls(client)
{
	if(client_rolls[client][AWARD_G_INVIS][0])
		return true;
	
	if(client_rolls[client][AWARD_G_INVISLOWHEALTH][4])
		return true;
	
	if(client_rolls[client][AWARD_G_CROUCHINVIS][4])
		return true;
	
	return false;
}