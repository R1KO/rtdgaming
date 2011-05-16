#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2>
#include <rtd_rollinfo>

#define TRACE_START 28.8
#define TRACE_END 76.8

public isCloseToWall(client, msg)
{
	decl Float:start[3], Float:angle[3], Float:end[3];
	GetClientEyePosition( client, start );
	GetClientEyeAngles( client, angle );
	GetAngleVectors(angle, end, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(end, end);
	
	start[0]=start[0]+end[0]*TRACE_START;
	start[1]=start[1]+end[1]*TRACE_START;
	start[2]=start[2]+end[2]*TRACE_START;
	
	end[0]=start[0]+end[0]*TRACE_END;
	end[1]=start[1]+end[1]*TRACE_END;
	end[2]=start[2]+end[2]*TRACE_END;
	
	TR_TraceRayFilter(start, end, CONTENTS_SOLID, RayType_EndPoint, TraceFilterAll, 0);
	
	if (TR_DidHit(INVALID_HANDLE))
	{
		if(msg == 2)
			PrintCenterText(client,"Too close to  wall!");
		
		return true;
	}
	
	if(msg == 1)
		PrintCenterText(client,"Too far away from wall!");
	
	return false;
}

public Action:Spawn_Mine(client)
{

	if (isCloseToWall(client, 1))
	{
		decl Float:end[3], Float:normal[3];
		
		// find angles for tripmine
		TR_GetEndPosition(end, INVALID_HANDLE);
		TR_GetPlaneNormal(INVALID_HANDLE, normal);
		GetVectorAngles(normal, normal);
		
		new mine = CreateEntityByName("prop_dynamic_override");
		SetEntityModel(mine,MODEL_MINE);
		
		SetEntProp(mine, Prop_Data, "m_takedamage", 2);  //default = 2
		
		DispatchSpawn(mine);
		SetEntProp(mine, Prop_Data, "m_takedamage", 2);  //default = 2
		SetEntProp( mine, Prop_Data, "m_nSolidType", 6 );
		SetEntProp( mine, Prop_Send, "m_nSolidType", 6 );
		
		SetEntProp(mine, Prop_Data, "m_CollisionGroup", 3);
		SetEntProp(mine, Prop_Send, "m_CollisionGroup", 3);
		
		SetEntPropEnt(mine, Prop_Data, "m_hLastAttacker", client);
		
		SetEntProp(mine, Prop_Data, "m_iMaxHealth", 1000);
		SetEntProp(mine, Prop_Data, "m_iHealth", 1000);
		
		AcceptEntityInput( mine, "DisableCollision" );
		AcceptEntityInput( mine, "EnableCollision" );
		
		new iTeam = GetClientTeam(client);
		SetEntPropEnt(mine, Prop_Data, "m_hOwnerEntity", client);
		
		SetVariantInt(iTeam);
		AcceptEntityInput(mine, "TeamNum", -1, -1, 0);
		
		SetVariantInt(iTeam);
		AcceptEntityInput(mine, "SetTeam", -1, -1, 0); 
		
		if(GetClientTeam(client) == RED_TEAM)
		{
			SetVariantString(bluDamageFilter);
			DispatchKeyValue(mine, "skin","0"); 
		}else{
			SetVariantString(redDamageFilter);
			DispatchKeyValue(mine, "skin","1"); 
		}
		AcceptEntityInput(mine, "SetDamageFilter", -1, -1, 0); 
		
		TeleportEntity(mine, end, normal, NULL_VECTOR);
		
		HookSingleEntityOutput(mine, "OnBreak", MineBreak, false);
		
		EmitSoundToAll(SOUND_MINEATTACH, mine);
		
		
		//The Datapack stores all the Mine's important values
		new Handle:dataPackHandle;
		CreateDataTimer(0.1, Mine_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
		
		//Setup the datapack with appropriate information
		WritePackCell(dataPackHandle, mine);   //PackPosition(0); Bomb Index
		WritePackCell(dataPackHandle, GetTime());   //PackPosition(8); Bomb Index
		WritePackCell(dataPackHandle, 0);   //PackPosition(16); Bomb Index
		WritePackCell(dataPackHandle, 0);   //PackPosition(24); Time it last played CLOSE sound
		
		SetEntityRenderMode(mine, RENDER_TRANSCOLOR);
		SetEntityRenderColor(mine, 255, 255, 255, 150);
	}
	
	return Plugin_Continue;
}

public Action:Mine_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopMineTimer(dataPackHandle))
		return Plugin_Stop;
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new mine = ReadPackCell(dataPackHandle);
	new spawnTime = ReadPackCell(dataPackHandle);
	new playedSound = ReadPackCell(dataPackHandle);
	new closeTimeSound = ReadPackCell(dataPackHandle);
	
	//////////////////////////////////////////
	//Enable the mine after amoutn of time  //
	//////////////////////////////////////////
	new iTeam = GetEntProp(mine, Prop_Data, "m_iTeamNum");
	
	if(playedSound == 0)
	{
		if(GetTime() - spawnTime > 2)
		{
			SetPackPosition(dataPackHandle, 16);
			WritePackCell(dataPackHandle, 1);
			EmitSoundToAll(SOUND_MINEREADY, mine);
			
			SetEntProp(mine, Prop_Data, "m_iMaxHealth", 10);
			SetEntProp(mine, Prop_Data, "m_iHealth", 10);
			
			SetEntityRenderMode(mine, RENDER_TRANSCOLOR);
			SetEntityRenderColor(mine, 255, 255, 255, 255);
			
		}else{
			SetEntityRenderMode(mine, RENDER_TRANSCOLOR);
			SetEntityRenderColor(mine, 255, 255, 255, GetRandomInt(100,200));
			return Plugin_Continue;
		}
	}
	
	/////////////////////////////////////////////
	//Explode when an enemy gets close         //
	/////////////////////////////////////////////
	new Float:minePos[3];
	GetEntPropVector(mine, Prop_Data, "m_vecOrigin", minePos);
	
	new Float:clientEyeOrigin[3];
	new Float:distance;
	
	new Float:objectDistances[MaxClients][2];
	
	//store the distances of the players
	for (new i = 1; i <= MaxClients ; i++)
	{
		objectDistances[i-1][0] = float(i);
		objectDistances[i-1][1] = 1001.0;
		
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if(GetClientTeam(i) == iTeam)
			continue;
		
		GetClientEyePosition(i, clientEyeOrigin);
		
		distance = GetVectorDistance(minePos, clientEyeOrigin);	
		objectDistances[i-1][1] = distance;
	}
	
	//find the closest player
	SortCustom2D(_:objectDistances, MaxClients, SortDistanceAscend);
	new Float:closestEnemyDistance = objectDistances[0][1];
	
	if(closestEnemyDistance > 500.0)
		return Plugin_Continue;
	
	//play a sound depending on the distance of the closest player
	if(closeTimeSound <= GetTime())
	{
		StopSound(mine, SNDCHAN_AUTO, SOUND_MINE_RANGE_FAR);
		StopSound(mine, SNDCHAN_AUTO, SOUND_MINE_RANGE_MEDIUM);
		StopSound(mine, SNDCHAN_AUTO, SOUND_MINE_RANGE_CLOSE);
		StopSound(mine, SNDCHAN_AUTO, SOUND_MINE_RANGE_VERYCLOSE);
		
		if(iTeam == BLUE_TEAM)
		{
			AttachTempParticle(mine,"pipebomb_timer_blue", 1.0, false,"",0.0, false);
		}else{
			AttachTempParticle(mine,"pipebomb_timer_red", 1.0, false,"",0.0, false);
		}
		
		if(closestEnemyDistance > 400.0)
		{
			EmitSoundToAll(SOUND_MINE_RANGE_FAR, mine);
		}else if(closestEnemyDistance > 300)
		{
			EmitSoundToAll(SOUND_MINE_RANGE_MEDIUM, mine);
		}else if(closestEnemyDistance > 200)
		{
			EmitSoundToAll(SOUND_MINE_RANGE_CLOSE, mine);
		}else{
			EmitSoundToAll(SOUND_MINE_RANGE_VERYCLOSE, mine);
		}
		
		SetPackPosition(dataPackHandle, 24);
		WritePackCell(dataPackHandle, GetTime() + 1); //16  owner
	}
	
	if(closestEnemyDistance > 200.0)
		return Plugin_Continue;
	
	//enemy is close, blow up
	AcceptEntityInput(mine, "Break"); 
	
	return Plugin_Continue;
}

public stopMineTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new mine = ReadPackCell(dataPackHandle);
	
	if(!IsValidEntity(mine))
	{	
		return true;
	}
	
	new currIndex = GetEntProp(mine, Prop_Data, "m_nModelIndex");
	
	if(currIndex != mineModelIndex)
	{
		StopSound(mine, SNDCHAN_AUTO, SOUND_MINEBEEP);
		//LogToFile(logPath,"Killing stopmineTimer handle! Reason: Invalid Model");
		return true;
	}
	
	return false;
}

public MineBreak (const String:output[], caller, activator, Float:delay)
{
	if(IsValidEntity(caller))
	{
		new objectTeam = GetEntProp(caller, Prop_Data, "m_iTeamNum");
		new attacker = GetEntPropEnt(caller, Prop_Data, "m_hOwnerEntity");
		new Float:damageAmount;
		new Float:pos[3];
		new Float:distance;
		new cond;
		
		new Float:bombPos[3];
		GetEntPropVector(caller, Prop_Data, "m_vecOrigin", bombPos); 
		
		//createExplosion(caller);
		new Float:finalvec[3];
		finalvec[2]=200.0;
		finalvec[0]=GetRandomFloat(50.0, 75.0)*GetRandomInt(-1,1);
		finalvec[1]=GetRandomFloat(50.0, 75.0)*GetRandomInt(-1,1);
		
		for (new i = 1; i <= MaxClients ; i++)
		{
			if(!IsClientInGame(i) || !IsPlayerAlive(i))
				continue;
			
			if(objectTeam == GetClientTeam(i))
				continue;
			
			
			GetClientEyePosition(i, pos);
			
			distance = GetVectorDistance(bombPos, pos);
			
			cond = GetEntData(i, m_nPlayerCond);
			
			if(client_rolls[i][AWARD_G_GODMODE][0])
				continue;
			
			if(cond == 32 || cond == 327712)
				continue;
			
			if(distance > 300.0)
				continue;
			
			//Invalid attacker, possible reasons player left
			//attacker must be a client!
			if(attacker == -1 || attacker > MaxClients)
				attacker = i;
			
			
			
			damageAmount = 500.0 - distance;
			
			if(damageAmount > 50.0)
				damageAmount = 50.0;
			
			SetEntDataVector(i,BaseVelocityOffset,finalvec,true);
			
			DealDamage(i, RoundFloat(damageAmount), attacker, 128, "proxmine");
			
			SetHudTextParams(0.405, 0.82, 4.0, 255, 50, 50, 255);
			ShowHudText(i, HudMsg3, "You were hurt by: Proximity Mines");
		}
		
		StopSound(caller, SNDCHAN_AUTO, SOUND_MINEBEEP);
		// play sound 
		EmitSoundToAll(Bomb_Explode, caller);
		
		UnhookSingleEntityOutput(caller,"OnBreak", MineBreak);
		
		
		//show some nice effects on explode
		AttachTempParticle(caller,"ExplosionCore_MidAir", 1.0, false,"",0.0, false);
	}
}