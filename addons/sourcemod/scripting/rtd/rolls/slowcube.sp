//Last modified: 1/8/2010
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>

public Action:Spawn_SlowCube(client)
{
	if (!GetConVarInt(c_Enabled))
		return Plugin_Handled;
	
	
	new Float:vicorigvec[3];
	GetClientAbsOrigin(client, Float:vicorigvec);
	
	new ent = CreateEntityByName("prop_dynamic_override");
	
	SetEntityModel(ent,MODEL_SLOWCUBE);
	SetEntProp(ent, Prop_Data, "m_takedamage", 0);  //default = 2
	
	DispatchSpawn(ent);
	
	//Set the Slowcube's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	new iTeam = GetClientTeam(client);
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 0);  //default = 2
	//SetEntProp(ent, Prop_Send, "m_takedamage", 2);  //default = 2
	
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	
	SetEntProp( ent, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 1);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
	
	TeleportEntity(ent, vicorigvec, NULL_VECTOR, NULL_VECTOR);
	
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, SlowCube_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, ent); //Slowcube entity
	WritePackCell(dataPackHandle, GetTime() + 60); //8, liveTime
	WritePackCell(dataPackHandle, GetTime()); //16, sound emission
	WritePackCell(dataPackHandle, GetTime()); //24, time to show annotations
	
	return Plugin_Continue;
}

public stopSlowCubeTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new slowcube = ReadPackCell(dataPackHandle);
	new dieTime =  ReadPackCell(dataPackHandle);
	
	if(!IsValidEntity(slowcube))
		return true;
	
	new currIndex = GetEntProp(slowcube, Prop_Data, "m_nModelIndex");
	
	if(currIndex != slowcubeModelIndex)
	{
		StopSound(slowcube, SNDCHAN_AUTO, SlowCube_Idle);
		return true;
	}
	
	if(GetTime() > dieTime)
	{
		AcceptEntityInput(slowcube,"kill");
		StopSound(slowcube, SNDCHAN_AUTO, SlowCube_Idle);
		
		return true;
	}
	
	return false;
}

public Action:SlowCube_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopSlowCubeTimer(dataPackHandle))
	{	
		for (new i = 1; i <= MaxClients ; i++)
		{
			if(!IsClientInGame(i) || !IsPlayerAlive(i))
				continue;
			
			if(client_rolls[i][AWARD_G_SLOWCUBE][3])
			{
				EmitSoundToClient(i,SlowCube_Exit);
				
				client_rolls[i][AWARD_G_SLOWCUBE][3] = 0;
				
				SetEntityGravity(i, 1.0);
				ResetClientSpeed(i);
			}
		}
		
		return Plugin_Stop;
	}
	
	//////////////////////////////////////////
	//Retrieve the values from the datapack //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new slowcube = ReadPackCell(dataPackHandle);
	SetPackPosition(dataPackHandle, 16);
	new nextSoundEmission =  ReadPackCell(dataPackHandle);
	new timeToShowAnnotations =  ReadPackCell(dataPackHandle);
	new bool:showAnnotations = false;
	
	if(timeToShowAnnotations <= GetTime())
	{
		SetPackPosition(dataPackHandle, 24);
		WritePackCell(dataPackHandle, GetTime() + 3); //24, time to show annotations
		showAnnotations = true;
	}
	
	//////////////////////////////////
	//Should reemit SlowCube sound? //
	//////////////////////////////////
	if(GetTime() > nextSoundEmission)
	{
		//emit every 10seconds
		SetPackPosition(dataPackHandle, 16);
		WritePackCell(dataPackHandle, GetTime() + 10); //16, sound emission
		StopSound(slowcube, SNDCHAN_AUTO, SlowCube_Idle);
		
		EmitSoundToAll(SlowCube_Idle, slowcube);
	}
	
	new Float: playerPos[3];
	new Float: slowCubePos[3];
	new playerTeam;
	new slowCubeTeam =  GetEntProp(slowcube, Prop_Data, "m_iTeamNum");
	
	GetEntPropVector(slowcube, Prop_Data, "m_vecOrigin", slowCubePos);
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		playerTeam = GetClientTeam(i);
		
		GetClientAbsOrigin(i,playerPos);
		
		//Show the annotations to nearbvy players
		if(GetVectorDistance(playerPos,slowCubePos) < 600.0)
		{
			if(showAnnotations)
			{
				if(playerTeam == slowCubeTeam)
				{
					SpawnAnnotationEx(i, slowcube, "Friendly SlowCube", slowCubePos, 4.0);
				}else{
					SpawnAnnotationEx(i, slowcube, "Enemy SlowCube", slowCubePos, 4.0);
				}
			}
		}else{
			continue;
		}
		
		if(playerTeam == slowCubeTeam)
			continue;
		
		//The user is no longer in this SlowCube
		if(GetVectorDistance(playerPos,slowCubePos) > 140.0)
		{
			//If the TickedTime is off by 0.5 then that means the client
			//is no longer in any SlowCube as the TickTime gets updated every 0.1
			if(client_rolls[i][AWARD_G_SLOWCUBE][4] < RoundFloat(GetTickedTime() * 10.0) && client_rolls[i][AWARD_G_SLOWCUBE][4] != 0)
			{
				//The user is nowhere near another slowcube
				EmitSoundToClient(i,SlowCube_Exit);
				
				client_rolls[i][AWARD_G_SLOWCUBE][4] = 0;
				client_rolls[i][AWARD_G_SLOWCUBE][3] = 0;
				
				ResetClientSpeed(i);
				SetEntityGravity(i, 1.0);
			}
			
			continue;
		}
		
		
		if(client_rolls[i][AWARD_G_SLOWCUBE][3] == 0)
		{
			EmitSoundToClient(i,SlowCube_Enter);
		}else{
			if((GetRandomInt(0,100) > (100 - RTD_Perks[i][10])) || client_rolls[i][AWARD_G_SLOWCUBE][6] > GetTime())
			{
				client_rolls[i][AWARD_G_SLOWCUBE][6] = GetTime() + 1;
				centerHudText(i, "Bypassing SlowCube for 1 second!", 0.0, 0.3, HudMsg3, 0.7); 
				SetEntityGravity(i, 1.0);
				ResetClientSpeed(i);
			}else{
				new Float:speed[3];
				// Calculate and apply a new velocity to the player.
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", speed);	
				
				speed[0] /= 3;
				speed[1] /= 3;
				speed[2] /= 2;
				
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, speed);
				
				SetEntDataFloat(i, m_flMaxspeed, 90.0);
				SetEntityGravity(i, 0.2);
			}
		}
		
		//Mark the player that he is in the slowcube
		client_rolls[i][AWARD_G_SLOWCUBE][3] = 1; //formerly inSlowCube[i]
		
		//Save the time that the player entered the slowcube
		client_rolls[i][AWARD_G_SLOWCUBE][4] = RoundFloat(GetTickedTime() * 10.0) + 2;
		
		//PrintToChat(i, "%i | %f", client_rolls[i][AWARD_G_SLOWCUBE][4], GetTickedTime());
	}
	
	return Plugin_Continue;
}

public Action:sound_hook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{	
	if(entity > MaxClients || entity < 1)
		return Plugin_Continue;
	
	if(StrEqual(sample,"buttons/button14.wav"))
		return Plugin_Continue;
	
	//PrintToChat(entity, "%i %i %s", entity, AWARD_G_JUMPPAD, sample);
	
	
	if(client_rolls[entity][AWARD_G_JUMPPAD][2])
	{
		pitch = RoundToNearest(pitch * 1.2);
		return Plugin_Changed;
	}
	
	//PrintToChatAll("fsdfds| %s",sample);
	
	if(StrEqual(sample,"player/pl_impact_stun.wav") && client_rolls[entity][AWARD_G_BEARTRAP][3])
		return Plugin_Continue;
	
	if(beingSlowCubed[entity])
	{		
		if(!StrEqual(sample,"rtdgaming/slowcube_exit.mp3") && !StrEqual(sample,"rtdgaming/slowcube_enter.mp3"))
		{
			pitch = RoundToNearest(pitch * 0.8);
			
			return Plugin_Changed;
		}		
	}
	
	if(client_rolls[entity][AWARD_G_SPEED][0])
	{
		pitch = RoundToNearest(pitch * 1.2);
		return Plugin_Changed;
	}
	
	if(VoiceOptions[entity] == 1)
	{
		pitch = RoundToNearest(pitch * 0.8);
		return Plugin_Changed;
	}
	
	if(VoiceOptions[entity] == 2)
	{
		if(StrContains(sample, "vo/", false) != -1)
		{
			//PrintToChatAll("fsdfds| %s",sample);
			pitch = RoundToNearest(pitch * 1.2);
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}