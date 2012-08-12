#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

public Action:Spawn_Cage(client)
{
	if (!GetConVarInt(c_Enabled))
		return Plugin_Handled;
	
	new Float:pos[3];
	new Float:angle[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
	GetEntPropVector(client, Prop_Data, "m_angRotation", angle);
	
	new ent = CreateEntityByName("prop_physics_override");
	
	SetEntityModel(ent,MODEL_CAGE);
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	DispatchSpawn(ent);
	
	new iTeam = GetEntProp(client, Prop_Data, "m_iTeamNum");
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	SetEntProp( ent, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 1);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
	
	//Set the cage's health
	if(RTD_PerksLevel[client][63])
	{
		SetEntProp(ent, Prop_Data, "m_iMaxHealth", 2500);
		SetEntProp(ent, Prop_Data, "m_iHealth", 2500);
	}else{
		SetEntProp(ent, Prop_Data, "m_iMaxHealth", 2000);
		SetEntProp(ent, Prop_Data, "m_iHealth", 2000);
	}
	
	if(iTeam == RED_TEAM)
	{
		DispatchKeyValue(ent, "skin","0"); 
		SetVariantString(bluDamageFilter);
	}else{
		DispatchKeyValue(ent, "skin","1"); 
		SetVariantString(redDamageFilter);
	}
	
	TeleportEntity(ent, pos, angle, NULL_VECTOR);
	
	//The Datapack stores all the Entity's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, Cage_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, ent); //entity
	WritePackCell(dataPackHandle, iTeam); //entity
	WritePackCell(dataPackHandle, 0); //entity
	
	if(RTD_PerksLevel[client][63])
	{
		WritePackCell(dataPackHandle, 1); //perk
	}else{
		WritePackCell(dataPackHandle, 0); //perk
	}
	
	SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	
	if(RTD_PerksLevel[client][63])
	{
		SetEntityRenderColor(ent, 255, 255, 255, 25);
	}else{
		SetEntityRenderColor(ent, 255, 255, 255, 100);
	}
	
	
	killEntityIn(ent, 120.0);
	/*
	if(annotation)
	{
		CreateAnnotation(ent, "", 0, iTeam, 1);
	}*/
	
	return Plugin_Continue;
}

public stopCageTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new cage = ReadPackCell(dataPackHandle);
	
	if(!IsValidEntity(cage))
		return true;
	
	new currIndex = GetEntProp(cage, Prop_Data, "m_nModelIndex");
	
	if(currIndex != cageModelIndex)
		return true;
	
	return false;
}

public Action:Cage_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopCageTimer(dataPackHandle))
		return Plugin_Stop;
	
	ResetPack(dataPackHandle);
	new cage = ReadPackCell(dataPackHandle);
	new cageTeam = ReadPackCell(dataPackHandle);
	new playersWasInCage = ReadPackCell(dataPackHandle);
	new hasPerk = ReadPackCell(dataPackHandle);
	
	new Float: playerPos[3];
	new Float: playerPosTwo[3];
	new Float: cagePos[3];
	new Float: distance;
	new Float: distanceTwo;
	new playerTeam;
	new playerTeamTwo;
	new bool:playersInCage;
	
	GetEntPropVector(cage, Prop_Data, "m_vecOrigin", cagePos);
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		playerTeam = GetClientTeam(i);
		
		//Check to see if player is close to a Cage
		if(playerTeam != cageTeam)
		{
			GetClientAbsOrigin(i,playerPos);
			distance = GetVectorDistance( playerPos, cagePos);
			
			if(distance < 85.0)
			{
				playersInCage++;
			}
		}
	}
	if(playersInCage && playersWasInCage)
	{
		return Plugin_Continue;
	}
	else if(GetEntProp(cage, Prop_Data, "m_CollisionGroup") == 0)
	{
		//PrintToChatAll("CAGE UNLOCKED");
		//If no player is within range unlock the cage
		SetEntProp(cage, Prop_Data, "m_CollisionGroup", 1);
		SetEntProp(cage, Prop_Send, "m_CollisionGroup", 1);
		SetPackPosition(dataPackHandle, 16);
		WritePackCell(dataPackHandle, 0); //entity
		SetEntityRenderMode(cage, RENDER_TRANSCOLOR);
		
		if(hasPerk)
		{
			SetEntityRenderColor(cage, 255, 255, 255, 25);
		}else{
			SetEntityRenderColor(cage, 255, 255, 255, 100);
		}
	}
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		playerTeam = GetClientTeam(i);
		
		//Check to see if player is close to a Cage
		if(playerTeam != cageTeam)
		{
			GetClientAbsOrigin(i,playerPos);
			distance = GetVectorDistance(playerPos, cagePos);
			
			if(distance < 85.0)
			{
				SetPackPosition(dataPackHandle, 16);
				WritePackCell(dataPackHandle, 1); //entity
				//teleport the player to the ground
				
				TeleportEntity(i, cagePos, NULL_VECTOR, NULL_VECTOR);
				
				//teleport any players close to the cage to this players
				//location. This prevents those players from getting stuck.
				for (new j = 1; j <= MaxClients ; j++)
				{
					if(!IsClientInGame(j) || !IsPlayerAlive(j) || j == i)
						continue;
					
					playerTeamTwo = GetClientTeam(j);
					
					if(playerTeam == playerTeamTwo)
					{
						GetClientAbsOrigin(j,playerPosTwo);
						distanceTwo = GetVectorDistance( playerPosTwo, cagePos);
						
						if(distanceTwo < 200.0)
						{
							TeleportEntity(j, cagePos, NULL_VECTOR, NULL_VECTOR);
						}
					}
				}
				
				//lock the cage and stop this timer
				//PrintToChat(i, "Your in the cage! %f",distance);
				SetEntProp(cage, Prop_Data, "m_CollisionGroup", 0);
				SetEntProp(cage, Prop_Send, "m_CollisionGroup", 0);
				EmitSoundToAll(SOUND_CAGECLOSE,i);
				//return Plugin_Stop;
				SetEntityRenderMode(cage, RENDER_TRANSCOLOR);
				SetEntityRenderColor(cage, 255, 255, 255, 255);
			}
		}
	}
	
	return Plugin_Continue;
}