#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <attachments>
#include <rtd_rollinfo>

public Action:SpawnAndAttachClientDynamite(client, originalEntity)
{	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Dynamite!" );
		return Plugin_Handled;
	}
	
	if(!RTD_TrinketActive[client][TRINKET_EXPLOSIVEDEATH])
		return Plugin_Stop;
	
	switch(RTD_TrinketLevel[client][TRINKET_EXPLOSIVEDEATH])
	{
		case 0:
			SetEntityModel(ent, MODEL_DYNAMITE);
			
		case 1:
			SetEntityModel(ent, MODEL_DYNAMITE02);
		
		case 2:
			SetEntityModel(ent, MODEL_DYNAMITE03);
		
		case 3:
			SetEntityModel(ent, MODEL_DYNAMITE04);
	}
	
	//Set the Dynamite's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	SDKHook(ent, SDKHook_SetTransmit, Hook_ClientBlizzard);  //Hook_EveryoneBlizzard - Hook_ClientBlizzard
	
	DispatchSpawn(ent);
	CAttach(ent, client, "flag");
	
	new Float:pos[3];
	
	if(TF2_GetPlayerClass(client) == TFClass_Pyro)
		pos[2] = 7.0;
	
	if(TF2_GetPlayerClass(client) == TFClass_Medic)
		pos[2] = 5.0;
	
	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	
	
	decl String:dynamiteName[32];
	Format(dynamiteName, 32, "dynamiteclient_%i", ent);
	DispatchKeyValue(ent, "targetname", dynamiteName);
	
	AcceptEntityInput( ent, "DisableShadow" );
	
	AcceptEntityInput( ent, "DisableCollision" );
	
	
	//The Datapack stores all the Backpack's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.3, Client_Dynamite_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(ent));   //PackPosition(0);  Backpack Index
	WritePackCell(dataPackHandle, GetClientUserId(client));     //PackPosition(8) ;  Amount of ammopacks
	WritePackCell(dataPackHandle, 0);     //PackPosition(8) ; unused was a particle
	WritePackCell(dataPackHandle, 1);     //PackPosition(24) ;  client only
	WritePackCell(dataPackHandle, EntIndexToEntRef(originalEntity));     //PackPosition(24) ;  client only
	
	return Plugin_Handled;
}

public Action:SpawnAndAttachDynamite(client)
{
	if(!IsClientInGame(client))
		return Plugin_Handled;
	
	if(!IsPlayerAlive(client))
		return Plugin_Handled;
	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Dynamite!" );
		return Plugin_Handled;
	}
	
	if(!RTD_TrinketActive[client][TRINKET_EXPLOSIVEDEATH])
		return Plugin_Stop;
	
	switch(RTD_TrinketLevel[client][TRINKET_EXPLOSIVEDEATH])
	{
		case 0:
			SetEntityModel(ent, MODEL_DYNAMITE);
			
		case 1:
			SetEntityModel(ent, MODEL_DYNAMITE02);
		
		case 2:
			SetEntityModel(ent, MODEL_DYNAMITE03);
		
		case 3:
			SetEntityModel(ent, MODEL_DYNAMITE04);
	}
	
	decl String:dynamiteName[32];
	Format(dynamiteName, 32, "dynamite_%i", ent);
	DispatchKeyValue(ent, "targetname", dynamiteName);
	
	//Set the Dynamite's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	SDKHook(ent, SDKHook_SetTransmit, Hook_EveryoneBlizzard ); //Hook_ClientBlizzard - Hook_EveryoneBlizzard
	
	DispatchSpawn(ent);
	CAttach(ent, client, "flag");
	
	new Float:pos[3];
	
	if(TF2_GetPlayerClass(client) == TFClass_Pyro)
		pos[2] = 7.0;
	
	if(TF2_GetPlayerClass(client) == TFClass_Medic)
		pos[2] = 5.0;
	
	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	
	
	AcceptEntityInput( ent, "DisableShadow" );
	
	//new particle = AttachFastParticle3(ent, client, 0, "candle_light1", 0.0, "CENTER");
	
	
	
	AcceptEntityInput( ent, "DisableCollision" );
	
	RTD_TrinketMisc[client][TRINKET_EXPLOSIVEDEATH] = EntIndexToEntRef(ent);
	
	//The Datapack stores all the Backpack's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.3, Dynamite_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(ent));   //PackPosition(0);  Backpack Index
	WritePackCell(dataPackHandle, GetClientUserId(client));     //PackPosition(8) ;  Amount of ammopacks
	WritePackCell(dataPackHandle, 0);     //PackPosition(16) ; unsused was a particle
	WritePackCell(dataPackHandle, 0);     //PackPosition(24) ;  client only
	WritePackCell(dataPackHandle, 0);     //PackPosition(32) ;  original entity
	
	SpawnAndAttachClientDynamite(client, ent);
	
	return Plugin_Handled;
}

public Action:Client_Dynamite_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopDynamiteTimer(dataPackHandle))
		return Plugin_Stop;
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new dynamite = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new client = GetClientOfUserId(ReadPackCell(dataPackHandle));
	
	
	/////////////////
	//Update Alpha //
	/////////////////
	new alpha = GetEntData(client, m_clrRender + 3, 1);
	
	if(!(TF2_IsPlayerInCondition(client, TFCond_Taunting) || TF2_IsPlayerInCondition(client, TFCond_Bonked) || GetEntData(client, m_iStunFlags) & TF_STUNFLAG_THIRDPERSON))
	{
		alpha = 0;
	}
	
	
	if(TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
		{
			SetEntityRenderMode(dynamite, RENDER_TRANSCOLOR);	
			SetEntityRenderColor(dynamite, 255, 255,255, 0);
			
		}else{
			SetEntityRenderMode(dynamite, RENDER_TRANSCOLOR);	
			SetEntityRenderColor(dynamite, 255, 255,255, alpha);
		}
	}else{
		SetEntityRenderMode(dynamite, RENDER_TRANSCOLOR);	
		SetEntityRenderColor(dynamite, 255, 255,255, alpha);
	}
	
	////////////////////
	// Determine skin //
	////////////////////
	new skin = GetEntProp(dynamite, Prop_Data, "m_nSkin");
	
	if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
	{	
		if(skin == 0 || skin == 2)
		{
			if(GetClientTeam(client) == RED_TEAM)
			{
				DispatchKeyValue(dynamite, "skin","1"); 
			}else{
				DispatchKeyValue(dynamite, "skin","3"); 
			}
		}
	}else{
		if(GetClientTeam(client) == RED_TEAM)
		{
			if(skin != 0)
				DispatchKeyValue(dynamite, "skin","0"); 
		}else{
			if(skin != 2)
				DispatchKeyValue(dynamite, "skin","2");
		}
	}
	
	return Plugin_Continue;
}

public Action:Dynamite_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopDynamiteTimer(dataPackHandle))
		return Plugin_Stop;
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new dynamite = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new client = GetClientOfUserId(ReadPackCell(dataPackHandle));
	
	
	/////////////////
	//Update Alpha //
	/////////////////
	new alpha = GetEntData(client, m_clrRender + 3, 1);
	
	if(TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
		{
			SetEntityRenderMode(dynamite, RENDER_TRANSCOLOR);	
			SetEntityRenderColor(dynamite, 255, 255,255, 0);
		}else{
			SetEntityRenderMode(dynamite, RENDER_TRANSCOLOR);	
			SetEntityRenderColor(dynamite, 255, 255,255, alpha);
		}
	}else{
		SetEntityRenderMode(dynamite, RENDER_TRANSCOLOR);	
		SetEntityRenderColor(dynamite, 255, 255,255, alpha);
	}
	
	////////////////////
	// Determine skin //
	////////////////////
	new skin = GetEntProp(dynamite, Prop_Data, "m_nSkin");
	
	if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
	{	
		if(skin == 0 || skin == 2)
		{
			if(GetClientTeam(client) == RED_TEAM)
			{
				DispatchKeyValue(dynamite, "skin","1"); 
			}else{
				DispatchKeyValue(dynamite, "skin","3"); 
			}
		}
	}else{
		if(GetClientTeam(client) == RED_TEAM)
		{
			if(skin != 0)
				DispatchKeyValue(dynamite, "skin","0"); 
		}else{
			if(skin != 2)
				DispatchKeyValue(dynamite, "skin","2");
		}
	}
	
	return Plugin_Continue;
}

public stopDynamiteTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new dynamite = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new client = GetClientOfUserId(ReadPackCell(dataPackHandle));
	
	SetPackPosition(dataPackHandle, 24);
	new clientOnly = ReadPackCell(dataPackHandle);
	new originalEntity = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	if(!IsValidEntity(dynamite))
		return true;
	
	if(client == 0)
	{
		CDetach(dynamite);
		killEntityIn(dynamite, 0.1);
		return true;
	}
	
	if(RTD_TrinketActive[client][TRINKET_EXPLOSIVEDEATH] == 0)
	{
		CDetach(dynamite);
		killEntityIn(dynamite, 0.1);
		return true;
	}
	
	if(!IsPlayerAlive(client))
	{
		CDetach(dynamite);
		killEntityIn(dynamite, 0.1);
		return true;
	}
	
	if(RTD_TrinketMisc[client][TRINKET_EXPLOSIVEDEATH] == 0)
	{
		CDetach(dynamite);
		killEntityIn(dynamite, 0.1);
		return true;
	}
	
	new savedEntity;
	
	if(clientOnly)
	{
		savedEntity = originalEntity;
	}else{
		savedEntity = EntRefToEntIndex(RTD_TrinketMisc[client][TRINKET_EXPLOSIVEDEATH]);
	}
	
	if(!IsValidEntity(savedEntity))
	{
		CDetach(dynamite);
		killEntityIn(dynamite, 0.1);
		return true;
	}
	
	if(clientOnly == 0 && savedEntity != dynamite)
	{
		CDetach(dynamite);
		killEntityIn(dynamite, 0.1);
		return true;
	}
	
	return false;
}

public SpawnDynamite(client)
{	
	new ent = CreateEntityByName("prop_dynamic_override");
	new Float:clientOrigin[3];
	
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientOrigin);
	clientOrigin[2] += 35.0;
	
	switch(RTD_TrinketLevel[client][TRINKET_EXPLOSIVEDEATH])
	{
		case 0:
			SetEntityModel(ent, MODEL_DYNAMITE);
			
		case 1:
			SetEntityModel(ent, MODEL_DYNAMITE02);
		
		case 2:
			SetEntityModel(ent, MODEL_DYNAMITE03);
		
		case 3:
			SetEntityModel(ent, MODEL_DYNAMITE04);
	}
	
	DispatchSpawn(ent);
	
	new Float:angles[3];
	angles[2] = 270.0;
	
	new iTeam = GetClientTeam(client);
	//Set the bombs owner
	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
	
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", 1000);
	SetEntProp(ent, Prop_Data, "m_iHealth", 1000);
	
	SetEntProp( ent, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 2);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	
	//The Datapack stores all the Backpack's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.5, dynamite_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(ent));   //PackPosition(0); dynamite entity
	WritePackCell(dataPackHandle, GetTime() + 1);     //PackPosition(8); time to go off
	WritePackCell(dataPackHandle, GetClientUserId(client));     //PackPosition(16); owner
	WritePackCell(dataPackHandle, RTD_TrinketBonus[client][TRINKET_EXPLOSIVEDEATH]);     //PackPosition(24); Damage amount
	
	AttachRTDParticle(ent, "candle_light1", false, false, 21.0);
	
	if(iTeam == BLUE_TEAM)
	{
		AttachRTDParticle(ent, "critical_pipe_blue", false, false, 21.0);
	}else{
		AttachRTDParticle(ent, "critical_pipe_red", false, false, 21.0);
	}
	
	TeleportEntity(ent, clientOrigin, angles, NULL_VECTOR);
	EmitSoundToAll(Bomb_Tick, ent);
}

public Action:dynamite_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stop_ExplodingDynamiteTimer(dataPackHandle))
		return Plugin_Stop;
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new dynamite = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new detonateTime = ReadPackCell(dataPackHandle);
	new owner = GetClientOfUserId(ReadPackCell(dataPackHandle));
	new damage = ReadPackCell(dataPackHandle);
	
	if(detonateTime > GetTime())
		return Plugin_Continue;
	
	StopSound(dynamite, SNDCHAN_AUTO, Bomb_Tick);
	
	AttachTempParticle(dynamite,"ExplosionCore_MidAir", 1.0, false,"",0.0, false);
	
	new Float:distance;
	new Float:dynamiteOrigin[3];
	new Float:enemyPos[3];
	new dynamiteTeam = GetEntProp(dynamite, Prop_Data, "m_iTeamNum");
	
	GetEntPropVector(dynamite, Prop_Send, "m_vecOrigin", dynamiteOrigin);
	
	new Float:finalvec[3];
	finalvec[2]=200.0;
	finalvec[0]=GetRandomFloat(150.0, 375.0)*GetRandomInt(-1,1);
	finalvec[1]=GetRandomFloat(150.0, 375.0)*GetRandomInt(-1,1);
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if(dynamiteTeam == GetClientTeam(i))
			continue;
		
		GetClientAbsOrigin(i, enemyPos);
		
		distance = GetVectorDistance(enemyPos, dynamiteOrigin);
		
		if(TF2_IsPlayerInCondition(i, TFCond_Ubercharged))
			continue;
		
		if(distance > 300.0)
			continue;
		
		SetEntDataVector(i,BaseVelocityOffset,finalvec,true);
		
		
		DelayDamage(0.1, i, damage, owner, 128, "proxmine");
		
		SetHudTextParams(0.405, 0.82, 4.0, 255, 50, 50, 255);
		ShowHudText(i, HudMsg3, "You were hurt by an Explosive Death");
		
	}
	
	killEntityIn(dynamite, 0.0);
	EmitSoundToAll(Bomb_Explode, dynamite);
	
	return Plugin_Stop;
}

public stop_ExplodingDynamiteTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new dynamite = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	if(!IsValidEntity(dynamite) || dynamite < 1)
		return true;
	
	
	return false;
}