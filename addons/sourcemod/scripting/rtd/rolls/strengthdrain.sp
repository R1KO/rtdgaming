#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>

public Action:Spawn_StrengthDrain(client)
{
	if (!GetConVarInt(c_Enabled))
		return Plugin_Handled;
	
	new Float:range;
	new Float:vicorigvec[3];
	GetClientAbsOrigin(client, Float:vicorigvec);
	
	new ent = CreateEntityByName("prop_dynamic_override");
	
	if(RTD_PerksLevel[client][58] > 0)
	{
		range = 240.0;
		SetEntityModel(ent,MODEL_STRENGTHDRAIN_02);
	}else{
		range = 180.0;
		SetEntityModel(ent,MODEL_STRENGTHDRAIN);
	}
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 0);  //default = 2
	
	DispatchSpawn(ent);
	
	//Set the Object's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	new iTeam = GetClientTeam(client);
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	
	if(iTeam == RED_TEAM)
	{
		DispatchKeyValue(ent, "skin","0"); 
	}else{
		DispatchKeyValue(ent, "skin","1"); 
	}
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 0);  //default = 2
	//SetEntProp(ent, Prop_Send, "m_takedamage", 2);  //default = 2
	
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	
	SetEntProp( ent, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 6 );
	
	//Set the entity's health
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", 3000);
	SetEntProp(ent, Prop_Data, "m_iHealth", 3000);
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 1);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
	
	vicorigvec[2] -= 40.0;
	
	TeleportEntity(ent, vicorigvec, NULL_VECTOR, NULL_VECTOR);
	
	HookSingleEntityOutput(ent, "OnBreak", AngelicBreak, false);
	EmitSoundToAll(SND_DROP, client);
	
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, StrengthDrain_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(ent)); //Slowcube entity reference
	WritePackCell(dataPackHandle, 600); //8, health
	WritePackCell(dataPackHandle, GetTime()); //16, sound emission
	WritePackCell(dataPackHandle, GetTime()); //24, time to show annotations
	WritePackFloat(dataPackHandle, range); //24, time to show annotations
	
	return Plugin_Continue;
}

public stopStrengthDrainTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new strengthDrain = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	if(strengthDrain < 1)
		return true;
	
	if(!IsValidEntity(strengthDrain))
		return true;
	
	return false;
}

public Action:StrengthDrain_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopStrengthDrainTimer(dataPackHandle))
	{	
		for (new i = 1; i <= MaxClients ; i++)
		{
			if(!IsClientInGame(i) || !IsPlayerAlive(i))
				continue;
			
			if(client_rolls[i][AWARD_G_STRENGTHDRAIN][3])
			{
				EmitSoundToClient(i,SlowCube_Exit);
				
				client_rolls[i][AWARD_G_STRENGTHDRAIN][3] = 0;
				
			}
		}
		
		return Plugin_Stop;
	}
	
	//////////////////////////////////////////
	//Retrieve the values from the datapack //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new strengthDrain = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	SetPackPosition(dataPackHandle, 16);
	new nextSoundEmission =  ReadPackCell(dataPackHandle);
	new timeToShowAnnotations =  ReadPackCell(dataPackHandle);
	new Float:range =  ReadPackFloat(dataPackHandle);
	
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
		StopSound(strengthDrain, SNDCHAN_AUTO, SlowCube_Idle);
		
		EmitSoundToAll(SlowCube_Idle, strengthDrain);
	}
	
	new Float: playerPos[3];
	new Float: strengthDrainPos[3];
	new playerTeam;
	new strengthDrainTeam =  GetEntProp(strengthDrain, Prop_Data, "m_iTeamNum");
	new String:message[64];
	
	GetEntPropVector(strengthDrain, Prop_Data, "m_vecOrigin", strengthDrainPos);
	
	SetVariantInt(1);
	AcceptEntityInput(strengthDrain, "RemoveHealth");
	
	new objHealth = GetEntProp(strengthDrain, Prop_Data, "m_iHealth");
	new objMaxHeath = GetEntProp(strengthDrain, Prop_Data, "m_iMaxHealth");
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		playerTeam = GetClientTeam(i);
		
		GetClientAbsOrigin(i,playerPos);
		
		
		//Show the annotations to nearbvy players
		if(GetVectorDistance(playerPos,strengthDrainPos) < 500.0)
		{
			if(showAnnotations)
			{
				Format(message, sizeof(message), "Strength Drain (%i/%i hp)", objHealth,objMaxHeath);
				
				SpawnAnnotationEx(i, strengthDrain, message, strengthDrainPos, 3.0);
			}
		}else{
			continue;
		}
		
		if(playerTeam == strengthDrainTeam)
			continue;
		
		//The user is no longer in this SlowCube
		if(GetVectorDistance(playerPos,strengthDrainPos) > range)
		{
			//If the TickedTime is off by 0.5 then that means the client
			//is no longer in any SlowCube as the TickTime gets updated every 0.1
			if(client_rolls[i][AWARD_G_STRENGTHDRAIN][4] < RoundFloat(GetTickedTime() * 10.0) && client_rolls[i][AWARD_G_STRENGTHDRAIN][4] != 0)
			{
				//The user is nowhere near another slowcube
				EmitSoundToClient(i,SlowCube_Exit);
				
				client_rolls[i][AWARD_G_STRENGTHDRAIN][4] = 0;
				client_rolls[i][AWARD_G_STRENGTHDRAIN][3] = 0;
				
			}
			
			continue;
		}
		
		//PrintCenterText(i, "Strength being drained");
		centerHudText(i, "Strength being drained", 0.0, 1.0, HudMsg3, 0.82); 
		
		//tick away from auras health
		SetVariantInt(1);
		AcceptEntityInput(strengthDrain, "RemoveHealth");
		
		//play sound when entering strength drain
		if(client_rolls[i][AWARD_G_STRENGTHDRAIN][3] == 0)
		{
			EmitSoundToClient(i,SlowCube_Enter);
		}
		
		//Mark the player that he is in the slowcube
		client_rolls[i][AWARD_G_STRENGTHDRAIN][3] = 1; 
		
		//Save the time that the player entered the slowcube
		client_rolls[i][AWARD_G_STRENGTHDRAIN][4] = RoundFloat(GetTickedTime() * 10.0) + 2;
		
		//if(clientOverlay[i] == false)
		//	ShowOverlay(i, "models/props_combine/portalball001_sheet ", 2.0);
		
	}
	
	return Plugin_Continue;
}

public StrengthDrainBreak (const String:output[], caller, activator, Float:delay)
{
	if(IsValidEntity(caller))
	{
		// play sound 
		EmitSoundToAll(SOUND_SENTRY_EXPLODE, caller);
		StopSound(caller, SNDCHAN_AUTO, SlowCube_Idle);
		
		TF_SpawnMedipack(caller, "item_healthkit_medium", true);
		
		UnhookSingleEntityOutput(caller,"OnBreak", AmplifierBreak);
		
		for (new i = 1; i <= MaxClients ; i++)
		{
			if(!IsClientInGame(i) || !IsPlayerAlive(i))
				continue;
			
			if(client_rolls[i][AWARD_G_STRENGTHDRAIN][3])
			{
				EmitSoundToClient(i,SlowCube_Exit);
				
				client_rolls[i][AWARD_G_STRENGTHDRAIN][3] = 0;
				
			}
		}
	}
}