#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>

public Action:throw_Diarhia(client)
{
	//---duke tf2nades
	// get position and angles
	new Float:gnSpeed = 850.0;
	
	new Float:startpt[3];
	GetClientEyePosition(client, startpt);
	new Float:angle[3];
	new Float:speed[3];
	new Float:playerspeed[3];
	GetClientEyeAngles(client, angle);
	GetAngleVectors(angle, speed, NULL_VECTOR, NULL_VECTOR);
	speed[2] += 0.2;
	speed[0]*=gnSpeed; speed[1]*=gnSpeed; speed[2]*=gnSpeed;
	
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
	AddVectors(speed, playerspeed, speed);
	
	new ent = CreateEntityByName("tf_projectile_jar");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create Crap!" );
		return Plugin_Handled;
	}
	
	SetEntityModel(ent, MODEL_DIARHIA_JAR);
	
	//make sure to do this before we actually spawn the P.O.S.
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	DispatchSpawn(ent);
	
	SetEntityModel(ent, MODEL_DIARHIA_JAR);
	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
	
	decl String:crapName[32];
	Format(crapName, 32, "crap_%i", ent);
	DispatchKeyValue(ent, "targetname", crapName);
	
	new iTeam = GetEntProp(client, Prop_Data, "m_iTeamNum");
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	

	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	

	SetEntProp(ent, Prop_Data, "m_takedamage", 2);
	
	//Set the shield's health
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", 1);
	SetEntProp(ent, Prop_Data, "m_iHealth", 1);
	
	AcceptEntityInput( ent, "DisableCollision" );
	AcceptEntityInput( ent, "EnableCollision" );
	
	//Throw or spawn the crap
	TeleportEntity(ent, startpt, NULL_VECTOR, speed);
	
	
	new Handle:dataPack;
	CreateDataTimer(0.0,Diarhia_Jar_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPack, EntIndexToEntRef(ent));
	WritePackCell(dataPack, iTeam);
	WritePackCell(dataPack, EntIndexToEntRef(client));
	WritePackFloat(dataPack, startpt[0]);
	WritePackFloat(dataPack, startpt[1]);
	WritePackFloat(dataPack, startpt[2]);
	
	return Plugin_Handled;
}

public Action:Diarhia_Jar_Timer(Handle:timer, Handle:dataPackHandle)
{
	new Float:jarPos[3];
	
	ResetPack(dataPackHandle);
	new jar = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new iTeam = ReadPackCell(dataPackHandle);
	new ownerEntity = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	jarPos[0] = ReadPackFloat(dataPackHandle);
	jarPos[1] = ReadPackFloat(dataPackHandle);
	jarPos[2] = ReadPackFloat(dataPackHandle);
	
	if(jar < 1 || !IsValidEntity(jar))
	{
		DiarhiaJarBreak (iTeam, ownerEntity, jarPos);
		
		return Plugin_Stop;
	}
	
	new Float:newJarPos[3];
	GetEntPropVector(jar, Prop_Data, "m_vecOrigin", newJarPos); 
	
	SetPackPosition(dataPackHandle, 24);
	WritePackFloat(dataPackHandle, newJarPos[0]);
	WritePackFloat(dataPackHandle, newJarPos[1]);
	WritePackFloat(dataPackHandle, newJarPos[2]);
	
	return Plugin_Continue;
}

public DiarhiaJarBreak (objectTeam, attacker, Float:jarPos[3])
{
	new Float:pos[3];
	new Float:distance;
	
	
	new Float:finalvec[3];
	finalvec[2]=200.0;
	finalvec[0]=GetRandomFloat(50.0, 75.0)*GetRandomInt(-1,1);
	finalvec[1]=GetRandomFloat(50.0, 75.0)*GetRandomInt(-1,1);
	
	new Float:jarRange = 350.0;
	
	if(RTD_Perks[attacker][59])
		jarRange = 490.0;
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if(objectTeam == GetClientTeam(i))
			continue;
		
		if(client_rolls[i][AWARD_G_DIARHIA][4])
			continue;
		
		GetClientEyePosition(i, pos);
		
		distance = GetVectorDistance(jarPos, pos);
		
		if(client_rolls[i][AWARD_G_GODMODE][0])
			continue;
		
		if(TF2_IsPlayerInCondition(i, TFCond_Ubercharged))
			continue;
		
		if(distance > jarRange)
			continue;
		
		//Invalid attacker, possible reasons player left
		//attacker must be a client!
		if(attacker == -1 || attacker > MaxClients)
			attacker = i;
		
		SetHudTextParams(0.405, 0.82, 4.0, 255, 50, 50, 255);
		ShowHudText(i, HudMsg3, "You're covered in Diarhia!");
		
		//add 2 intense bowel movements
		client_rolls[i][AWARD_G_DIARHIA][3] = 2;
		
		//mark player as being diarhied on
		client_rolls[i][AWARD_G_DIARHIA][4] = 1;
		
		//end time for bowel movements
		client_rolls[i][AWARD_G_DIARHIA][5] = GetTime() + 20;
		
		//next bowel movent
		client_rolls[i][AWARD_G_DIARHIA][6] = GetTime() + GetRandomInt(1, 12);
		
		new Handle:dataPack;
		CreateDataTimer(0.1, Diarhia_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
		WritePackCell(dataPack, GetClientUserId(i));
		
		TF2_AddCondition(i, TFCond_Jarated,5.0);
	}
}

public Action:Diarhia_Timer(Handle:timer, Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new client = GetClientOfUserId(ReadPackCell(dataPackHandle));
	
	////////////////////////////
	//Determine stop timer    //
	////////////////////////////
	if(client < 1 || client > MaxClients)
		return Plugin_Stop;
	
	if(!IsPlayerAlive(client))
	{
		client_rolls[client][AWARD_G_DIARHIA][4] = 0;
		client_rolls[client][AWARD_G_DIARHIA][3] = 0;
		return Plugin_Stop;
	}
	
	if(client_rolls[client][AWARD_G_DIARHIA][3] <= 0 || client_rolls[client][AWARD_G_DIARHIA][4] == 0 || GetTime() > client_rolls[client][AWARD_G_DIARHIA][5])
	{
		client_rolls[client][AWARD_G_DIARHIA][4] = 0;
		client_rolls[client][AWARD_G_DIARHIA][3] = 0;
		return Plugin_Stop;
	}
	
	//////////////////////////////
	// Determine bowel movement //
	//////////////////////////////
	if(GetTime() > client_rolls[client][AWARD_G_DIARHIA][6])
	{
		if(!IsEntLimitReached())
			Spawn_Pattycake(client);
		
		//next bowel movent
		client_rolls[client][AWARD_G_DIARHIA][6] = GetTime() + GetRandomInt(1, 12);
		
		//take 1 bowel movement away
		client_rolls[client][AWARD_G_DIARHIA][3] --;
		
		new Float:finalvec[3];
		finalvec[2]=GetRandomFloat(200.0, 400.0);
		SetEntDataVector(client,BaseVelocityOffset,finalvec,true);
		
		SetHudTextParams(0.405, 0.82, 4.0, 255, 50, 50, 255);
		ShowHudText(client, HudMsg3, "...Diarhia!");
		
		TF2_AddCondition(client,TFCond_Jarated,5.0);
		TF2_MakeBleed(client, client, 5.0);
	}
	
	return Plugin_Continue;
}

public Action:Spawn_Pattycake(client)
{
	//---duke tf2nades
	// get position and angles
	new Float:gnSpeed = 10.0;
	
	new Float:startpt[3];
	GetClientEyePosition(client, startpt);
	new Float:angle[3];
	new Float:speed[3];
	new Float:playerspeed[3];
	GetClientEyeAngles(client, angle);
	GetAngleVectors(angle, speed, NULL_VECTOR, NULL_VECTOR);
	speed[2] += 0.2;
	speed[0]*=gnSpeed; speed[1]*=gnSpeed; speed[2]*=gnSpeed;
	
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
	AddVectors(speed, playerspeed, speed);
	
	new ent = CreateEntityByName("prop_physics_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create Pattycake!" );
		return Plugin_Handled;
	}
	
	SetEntityModel(ent, MODEL_DIARHIA);
	
	//make sure to do this before we actually spawn the P.O.S.
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	DispatchSpawn(ent);
	
	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
	
	decl String:crapName[32];
	Format(crapName, 32, "crap_%i", ent);
	DispatchKeyValue(ent, "targetname", crapName);

	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	

	SetEntProp(ent, Prop_Data, "m_takedamage", 2);
	
	 //Use the balls VPhysics for collisions
	SetEntProp( ent, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 6 );

	//Only detect bullet/damage collisions
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 2); 
	
	//Set the shield's health
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", 600);
	SetEntProp(ent, Prop_Data, "m_iHealth", 600);
	
	AcceptEntityInput( ent, "DisableCollision" );
	AcceptEntityInput( ent, "EnableCollision" );
	
	//patty cake is damaged by its own team
	if(GetClientTeam(client) == RED_TEAM)
	{
		SetVariantInt(BLUE_TEAM);
		AcceptEntityInput(ent, "TeamNum", -1, -1, 0);
		
		SetVariantInt(BLUE_TEAM);
		AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
		
		SetVariantString(redDamageFilter);
	}else{
		SetVariantInt(RED_TEAM);
		AcceptEntityInput(ent, "TeamNum", -1, -1, 0);
		
		SetVariantInt(RED_TEAM);
		AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
		
		SetVariantString(bluDamageFilter);
		
	}
	AcceptEntityInput(ent, "SetDamageFilter", -1, -1, 0); 
	
	EmitSoundToAll(SOUND_CRAPSTRAIN, client);
	
	
	/////////////////////////////////////////////
	//Initiate the timer.                      //
	//Important variables to keep track of     //
	/////////////////////////////////////////////
	new Handle:dataPack;
	CreateDataTimer(0.4,Pattycake_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPack, EntIndexToEntRef(ent));
	WritePackCell(dataPack, GetTime()+60);//PackPosition(8)  time to kill crap
	WritePackCell(dataPack, GetTime()); //PackPosition(16) time to re-emit crap idle sound
	WritePackCell(dataPack, RoundFloat(startpt[0])); //24
	WritePackCell(dataPack, RoundFloat(startpt[1])); //32
	WritePackCell(dataPack, RoundFloat(startpt[2])); //40
	WritePackCell(dataPack, 0); //48 still time
	
	//Throw or spawn the crap
	TeleportEntity(ent, startpt, NULL_VECTOR, speed);
	SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
	
	HookSingleEntityOutput(ent, "OnHealthChanged", Crap_Hurt, false);
	
	Create_phys_keepupright(ent, crapName, 7.0, 1270);
	
	return Plugin_Handled;
}

public stopPattycakeTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new pattycake = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new killPattycake = ReadPackCell(dataPackHandle);
	
	if(pattycake < 1)
		return true;
	
	if(!IsValidEntity(pattycake))
	{	
		return true;
	}
	
	if(GetTime() > killPattycake)
	{
		StopSound(pattycake, SNDCHAN_AUTO, SOUND_CRAPIDLE);
		AcceptEntityInput(pattycake,"kill");
	}
	
	return false;
}

public Action:Pattycake_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopPattycakeTimer(dataPackHandle))
		return Plugin_Stop;
	
	ResetPack(dataPackHandle);
	new pattycake = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	SetPackPosition(dataPackHandle,16);
	new soundTime = ReadPackCell(dataPackHandle);
	
	
	new Float: pattycakePos[3];
	GetEntPropVector(pattycake, Prop_Data, "m_vecOrigin", pattycakePos);
	
	/////////////////////////////////////////////
	// Stop pattycake from being able to move //
	////////////////////////////////////////////
	if(GetEntityMoveType(pattycake) == MOVETYPE_VPHYSICS)
	{
		new savedPos[3];
		savedPos[0] = ReadPackCell(dataPackHandle);
		savedPos[1] = ReadPackCell(dataPackHandle);
		savedPos[2] = ReadPackCell(dataPackHandle);
		new stillTime = ReadPackCell(dataPackHandle);
		
		
		if(RoundFloat(pattycakePos[0]) == savedPos[0] && RoundFloat(pattycakePos[1]) == savedPos[1] && RoundFloat(pattycakePos[2]) == savedPos[2])
			stillTime ++;
		
		SetPackPosition(dataPackHandle, 24);
		WritePackCell(dataPackHandle, RoundFloat(pattycakePos[0])); //24
		WritePackCell(dataPackHandle, RoundFloat(pattycakePos[1])); //32
		WritePackCell(dataPackHandle, RoundFloat(pattycakePos[2])); //40
		
		WritePackCell(dataPackHandle, stillTime); //64
		if(stillTime > 3)
		{
			SetEntityMoveType(pattycake, MOVETYPE_NONE);
			//PrintToChatAll("Debug msg: pattycake frozen!");
		}
		
	}
	
	//////////////////////
	// Re-Emit Sounds   //
	//////////////////////
	if(soundTime < GetTime())
	{
		decl String:crapName[32];
		Format(crapName, 32, "crap_%i", pattycake);
		AttachTempParticle(pattycake, "superrare_flies", 14.0, true, crapName, 30.0, false);
		
		StopSound(pattycake, SNDCHAN_AUTO, SOUND_CRAPIDLE);
		EmitSoundToAll(SOUND_CRAPIDLE, pattycake);
		
		SetPackPosition(dataPackHandle,16);
		WritePackCell(dataPackHandle, GetTime() + 15);
	}
	
	new Float: playerPos[3];
	new Float: distance;
	new playerTeam;
	new pattycakeTeam =  GetEntProp(pattycake, Prop_Data, "m_iTeamNum");
	
	
	new rndNum = GetRandomInt(1,4);
	new String:addoutput[64];
	Format(addoutput, sizeof(addoutput), "ambient/voices/cough%i.wav",rndNum);
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		playerTeam = GetClientTeam(i);
		
		//Check to see if player is close to a Pattycake
		if(playerTeam != pattycakeTeam)
		{
			GetClientAbsOrigin(i,playerPos);
			distance = GetVectorDistance( playerPos, pattycakePos);
			
			if(distance < 160.0)
			{
				if((GetTime() - lastCoughed[i]) >= 2)
				{
					lastCoughed[i] = GetTime();
					EmitSoundToAll(addoutput,i);
				}
				
				//DealDamage(i, 10, i, 4226, "crap");
				
				TF2_AddCondition(i,TFCond_Jarated, 10.0);
				TF2_MakeBleed(i, i, 10.0);
			}else{
				if(lastCoughed[i] != 0 && (GetTime() - lastCoughed[i]) == 1)
				{
					EmitSoundToAll(addoutput,i);
					lastCoughed[i] --;
				}
			}
		}
	}
	
	return Plugin_Continue;
}