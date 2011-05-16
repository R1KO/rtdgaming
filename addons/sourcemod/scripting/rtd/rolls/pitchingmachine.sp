#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2>
#include <rtd_rollinfo>

public Action:Spawn_PitchingMachine(client)
{
	client_rolls[client][AWARD_G_PITCHMACHINE][0] = 0;
	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Pitching machine" );
		return Plugin_Handled;
	}
	
	new iTeam = GetEntProp(client, Prop_Data, "m_iTeamNum");
	
	if(iTeam == BLUE_TEAM)
	{
		SetEntityModel(ent, MODEL_PITCHMACHINE_BLU);
	}else{
		SetEntityModel(ent, MODEL_PITCHMACHINE);
	}
	
	//make sure to do this before we actually spawn the P.O.S.
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	DispatchSpawn(ent);
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	SetEntProp( ent, Prop_Data, "m_nSolidType", 7 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 7 );
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 3);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 3);
	
	AcceptEntityInput( ent, "DisableCollision" );
	AcceptEntityInput( ent, "EnableCollision" );
	
	
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	//new iTeam = GetClientTeam(client);
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", 1000);
	SetEntProp(ent, Prop_Data, "m_iHealth", 1000);
	
	if(iTeam == RED_TEAM)
	{
		SetVariantString(bluDamageFilter);
	}else{
		SetVariantString(redDamageFilter);
	}
	AcceptEntityInput(ent, "SetDamageFilter", -1, -1, 0); 
	
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	new Float:pos[3];
	new Float:ang[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
	GetEntPropVector(client, Prop_Data, "m_angRotation", ang);
	ang[1] += 180.0;
	//GetClientAbsOrigin(client,pos);
	
	TeleportEntity(ent, pos, ang, NULL_VECTOR);
	/////////////////////////////////////////////
	//Initiate the timer.                      //
	//Important variables to keep track of     //
	/////////////////////////////////////////////
	new Handle:dataPack;
	CreateDataTimer(1.0,PitchMachine_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPack, ent);
	WritePackCell(dataPack, GetTime());//PackPosition(8) 
	WritePackCell(dataPack, 120); //PackPosition(16) amount of time it will live in seconds
	WritePackCell(dataPack, 0); //PackPosition(24) Start Time of last trap activation
	WritePackCell(dataPack, 1); //PackPosition(32) Shooting frequency
	WritePackCell(dataPack, 0); //PackPosition(40) Incr to remit sound
	
	killEntityIn(ent, 121.0);
	
	EmitSoundToAll(SOUND_PITCHMACHINE_HUM, ent);
	/*
	if(annotation)
	{
		CreateAnnotation(ent, "", 0, iTeam, 1);
	}*/
	
	return Plugin_Handled;
}

public Action:PitchMachine_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopPitchingMachineTimer(dataPackHandle))
		return Plugin_Stop;
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new pitchMachine = ReadPackCell(dataPackHandle);
	SetPackPosition(dataPackHandle, 24);
	new incrTime = ReadPackCell(dataPackHandle);
	new shootTime = ReadPackCell(dataPackHandle);
	new incrSoundReEmit = ReadPackCell(dataPackHandle);
	
	incrTime++;
	incrSoundReEmit ++;
	
	if(incrSoundReEmit > 1000)
	{
		StopSound(pitchMachine, SNDCHAN_AUTO, SOUND_PITCHMACHINE_HUM);
		EmitSoundToAll(SOUND_PITCHMACHINE_HUM, pitchMachine);
		incrSoundReEmit = 0;
		
	}
	SetPackPosition(dataPackHandle, 40);
	WritePackCell(dataPackHandle, 0); //PackPosition(40) Incr to remit sound
	
	
	if(incrTime >= shootTime)
	{	
		SpawnBaseBall(pitchMachine);
		SetVariantString("shoot");
		AcceptEntityInput(pitchMachine, "SetAnimation", -1, -1, 0);
		incrTime = 0;
		
		//play idle animation in 0.3seconds
		new String:addoutput[64];
		Format(addoutput, sizeof(addoutput), "OnUser1 !self:SetAnimation:idle:0.3:1");
		SetVariantString(addoutput);
		AcceptEntityInput(pitchMachine, "AddOutput");
		AcceptEntityInput(pitchMachine, "FireUser1");
		
	}
	
	SetPackPosition(dataPackHandle, 24);
	WritePackCell(dataPackHandle, incrTime); //PackPosition(24) Start Time of last trap activation
	
	return Plugin_Continue;
}

public stopPitchingMachineTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new pitchingMachine = ReadPackCell(dataPackHandle);
	new spawnTime = ReadPackCell(dataPackHandle);
	new liveTime = ReadPackCell(dataPackHandle);
	
	if(!IsValidEntity(pitchingMachine))
	{	
		return true;
	}
	
	new currIndex = GetEntProp(pitchingMachine, Prop_Data, "m_nModelIndex");
	
	if(pitchMachineModelIndex[0] != currIndex && pitchMachineModelIndex[1] != currIndex)
	{
		return true;
	}
	
	if(spawnTime + liveTime < GetTime())
	{
		StopSound(pitchingMachine, SNDCHAN_AUTO, SOUND_PITCHMACHINE_HUM);
		killEntityIn(pitchingMachine, 0.1);
		return true;
	}
	
	return false;
}

public SpawnBaseBall(entity)
{
	new ent_projectile;
	new Float:ori[3];
	new Float:ang[3];
	new Float:vec[3];
	
	new team =  GetEntProp(entity, Prop_Data, "m_iTeamNum");
	new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", ori);
	GetEntPropVector(entity, Prop_Data, "m_angRotation", ang);
	
	ang[0] += GetRandomFloat(180.0, 240.0);
	
	ang[1] += GetRandomFloat(-15.0, 15.0);
	
	ori[2] += 50.0;
	
	ent_projectile = CreateEntityByName("prop_physics_override");
	
	SetEntityModel(ent_projectile, PROJECTILE_BALL);
	
	
	SetVariantInt(team);
	AcceptEntityInput(ent_projectile, "TeamNum", -1, -1, 0);

	SetVariantInt(team);
	AcceptEntityInput(ent_projectile, "SetTeam", -1, -1, 0); 
	
	SetEntPropEnt(ent_projectile, Prop_Data, "m_hOwnerEntity", owner);
	
	//SetEntityGravity(ent_projectile, 0.0);
	
	DispatchSpawn(ent_projectile);
	
	SetEntProp( ent_projectile, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( ent_projectile, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(ent_projectile, Prop_Data, "m_CollisionGroup", 3);
	SetEntProp(ent_projectile, Prop_Send, "m_CollisionGroup", 3);
	
	
	GetAngleVectors(ang, vec, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vec, GetRandomFloat(500.0, 1500.0));
	TeleportEntity(ent_projectile, ori, NULL_VECTOR, vec);
	
	killEntityIn(ent_projectile, 2.0);
	CreateTimer(0.0,ball_Timer,ent_projectile, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	EmitSoundToAll(SOUND_PITCHMACHINE_HIT01, ent_projectile);
}

public Action:ball_Timer(Handle:timer, any:entity)
{
	if(!IsValidEntity(entity))
		return Plugin_Stop;
	
	new Float:ori[3];
	new Float:clientPos[3];
	new Float:clientEyepos[3];
	new Float:distance[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", ori);
	new cond;
	new playerTeam;
	new ballTeam =  GetEntProp(entity, Prop_Data, "m_iTeamNum");
	new Float:traceEndPos[3];
	new Float:foundRange;
	
	//Cycle through the players and find out who is close
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		cond = GetEntData(i, m_nPlayerCond);
		if(cond == 32 || cond == 327712)
			continue;
		
		playerTeam = GetClientTeam(i);
		
		//Check to see if player is close to cloud
		if(playerTeam == ballTeam)
			continue;
		
		GetClientAbsOrigin(i,clientPos);
		GetClientEyePosition(i,clientEyepos);
		distance[0] = GetVectorDistance( clientPos, ori);
		distance[1] = GetVectorDistance( clientEyepos, ori);
		
		if(distance[0] < 45.0 || distance[1] < 45.0)
		{
			//begin our trace from our the Amplifier to the client
			new Handle:Trace = TR_TraceRayFilterEx(ori, clientEyepos, MASK_NPCWORLDSTATIC, RayType_EndPoint, TraceFilterAll, entity);
			TR_GetEndPosition(traceEndPos, Trace);
			CloseHandle(Trace);
			
			foundRange = GetVectorDistance(clientEyepos,traceEndPos);
			
			//Was the trace close to the player? If not the let's shoot from the player
			//back to the Amplifier. This makes sure that none of the entites saw each other
			if(foundRange > 35.0)
			{
				Trace = TR_TraceRayFilterEx(clientEyepos, ori, MASK_NPCWORLDSTATIC, RayType_EndPoint, TraceFilterAll, i);
				TR_GetEndPosition(traceEndPos, Trace);
				CloseHandle(Trace);
				
				//did the player see a building?
				foundRange = GetVectorDistance(ori, traceEndPos);
			}
			
			if(foundRange < 35.0)
			{
				
				new stunFlag = GetEntData(i, m_iStunFlags);
				
				//scare the player
				if(stunFlag != TF_STUNFLAGS_LOSERSTATE)
				{	
					EmitSoundToAll(SOUND_PITCHMACHINE_STUN, i);
					
					killEntityIn(entity, 0.0);
					TF2_StunPlayer(i,3.0, 0.0, TF_STUNFLAGS_LOSERSTATE, 0);
					ResetClientSpeed(i);
					SetEntData(i, m_iMovementStunAmount, 0 );
					
					return Plugin_Stop;
				}
			}
		}
	}
	
	return Plugin_Continue;
}