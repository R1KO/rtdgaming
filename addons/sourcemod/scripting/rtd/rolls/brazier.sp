#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>

public Action:Spawn_Brazier(client, nextTime)
{
	//---duke tf2nades
	// get position and angles
	new Float:gnSpeed = 1.0;
	
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
		ReplyToCommand( client, "Failed to create Brazier!" );
		return Plugin_Handled;
	}
	
	SetEntityModel(ent, MODEL_BRAZIER);
	
	//make sure to do this before we actually spawn the P.O.S.
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	DispatchSpawn(ent);
	
	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
	
	decl String:brazierName[32];
	Format(brazierName, 32, "brazier_%i", ent);
	DispatchKeyValue(ent, "targetname", brazierName);
	
	new iTeam = GetEntProp(client, Prop_Data, "m_iTeamNum");
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	

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
	
	if(GetClientTeam(client) == RED_TEAM)
	{
		SetVariantString(bluDamageFilter);
	}else{
		SetVariantString(redDamageFilter);
	}
	
	AcceptEntityInput(ent, "SetDamageFilter", -1, -1, 0); 
	
	EmitSoundToAll(SOUND_IGNITE, ent);
	
	AttachTempParticle(ent, "superrare_burning1", 1.0, true, brazierName, 30.0, false);
	
	/////////////////////////////////////////////
	//Initiate the timer.                      //
	//Important variables to keep track of     //
	/////////////////////////////////////////////
	new Handle:dataPack;
	CreateDataTimer(0.4,Brazier_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPack, ent);
	WritePackCell(dataPack, GetTime()); //PackPosition(8) time to re-emit brazier idle sound
	WritePackCell(dataPack, RoundFloat(startpt[0])); //16
	WritePackCell(dataPack, RoundFloat(startpt[1])); //24
	WritePackCell(dataPack, RoundFloat(startpt[2])); //32
	WritePackCell(dataPack, 0); //40 still time
	WritePackCell(dataPack, nextTime); //48, next time it can allow fire damage
	WritePackCell(dataPack, GetTime() + 2);// 56 time it can be picked up
	
	WritePackCell(dataPack, GetTime() + 120);// 64 time it should be removed
	
	//Throw or spawn the brazier
	TeleportEntity(ent, startpt, NULL_VECTOR, speed);
	SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
	
	HookSingleEntityOutput(ent, "OnHealthChanged", brazier_Hurt, false);
	
	Create_phys_keepupright(ent, brazierName, 7.0, 1270);
	
	return Plugin_Handled;
}

public brazier_Hurt (const String:output[], caller, activator, Float:delay)
{
	if(IsValidEntity(caller))
	{	
		if(GetEntProp(caller, Prop_Data, "m_iHealth") <= 0)
		{	
			//Let's reward the player for killing this entity
			new rndNum = GetRandomInt(0,20);
			if(rndNum > 10)
			{
				TF_SpawnMedipack(caller, "item_healthkit_medium", true);
			}else{
				TF_SpawnMedipack(caller, "item_ammopack_medium", true);
			}
			
			StopSound(caller, SNDCHAN_AUTO, SOUND_BRAZIER);
		}
	}
}

public stopBrazierTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new brazier = ReadPackCell(dataPackHandle);
	
	SetPackPosition(dataPackHandle, 64);
	new killTime = ReadPackCell(dataPackHandle);
	
	if(!IsValidEntity(brazier))
	{	
		return true;
	}
	
	new currIndex = GetEntProp(brazier, Prop_Data, "m_nModelIndex");
	
	if(currIndex != brazierModelIndex)
	{
		StopSound(brazier, SNDCHAN_AUTO, SOUND_BRAZIER);
		return true;
	}
	
	if(roundEnded || GetTime() > killTime)
	{
		StopSound(brazier, SNDCHAN_AUTO, SOUND_BRAZIER);
		AcceptEntityInput(brazier, "kill");
		return true;
	}
	
	return false;
}

public Action:Brazier_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopBrazierTimer(dataPackHandle))
		return Plugin_Stop;
	
	ResetPack(dataPackHandle);
	new brazier = ReadPackCell(dataPackHandle);
	new soundTime = ReadPackCell(dataPackHandle);
	
	SetPackPosition(dataPackHandle, 48);
	new nextFireTime = ReadPackCell(dataPackHandle);
	
	new Float: brazierPos[3];
	GetEntPropVector(brazier, Prop_Data, "m_vecOrigin", brazierPos);
	
	///////////////////////////////////////
	// Stop brazier from being able to move //
	///////////////////////////////////////
	if(GetEntityMoveType(brazier) == MOVETYPE_VPHYSICS)
	{
		new savedPos[3];
		
		SetPackPosition(dataPackHandle,16);
		
		savedPos[0] = ReadPackCell(dataPackHandle);
		savedPos[1] = ReadPackCell(dataPackHandle);
		savedPos[2] = ReadPackCell(dataPackHandle);
		
		new stillTime = ReadPackCell(dataPackHandle);
		
		
		if(RoundFloat(brazierPos[0]) == savedPos[0] && RoundFloat(brazierPos[1]) == savedPos[1] && RoundFloat(brazierPos[2]) == savedPos[2])
			stillTime ++;
		
		SetPackPosition(dataPackHandle, 16);
		WritePackCell(dataPackHandle, RoundFloat(brazierPos[0])); //40
		WritePackCell(dataPackHandle, RoundFloat(brazierPos[1])); //48
		WritePackCell(dataPackHandle, RoundFloat(brazierPos[2])); //56
		
		WritePackCell(dataPackHandle, stillTime); //64
		if(stillTime > 3)
		{
			SetEntityMoveType(brazier, MOVETYPE_NONE);
			//PrintToChatAll("Debug msg: brazier frozen!");
		}
		
	}
	
	///////////////////////////////
	//Set if it can be picked up //
	///////////////////////////////
	if(GetEntProp(brazier, Prop_Data, "m_PerformanceMode") != 1)
	{
		SetPackPosition(dataPackHandle,56);
		new timeToPickup = ReadPackCell(dataPackHandle);
		if(GetTime() > timeToPickup)
			SetEntProp(brazier, Prop_Data, "m_PerformanceMode", 1);
	}
	
	//////////////////////
	// Re-Emit Sounds   //
	//////////////////////
	if(soundTime < GetTime())
	{
		decl String:brazierName[32];
		Format(brazierName, 32, "brazier_%i", brazier);
		
		AttachTempParticle(brazier, "superrare_burning1", 16.0, true, brazierName, 30.0, false);
		//AttachRTDParticle(brazier, "rtd_brazier_smoke", true, true, 0.0);
		
		StopSound(brazier, SNDCHAN_AUTO, SOUND_BRAZIER);
		EmitSoundToAll(SOUND_BRAZIER, brazier);
		
		SetPackPosition(dataPackHandle, 8);
		WritePackCell(dataPackHandle, GetTime() + 15);
	}
	
	///////////////////////
	//allow Fire Damage? //
	///////////////////////
	if(GetTime() < nextFireTime)
		return Plugin_Continue;
	
	decl String:brazierName[32];
	Format(brazierName, 32, "brazier_%i", brazier);
	
	EmitSoundToAll(SOUND_IGNITE_2, brazier);
	
	AttachTempParticle(brazier, "burning_torch", 3.0, true, brazierName, 30.0, false);
	AttachTempParticle(brazier, "ExplosionCore_MidAir", 3.0, true, brazierName, 30.0, false);
	
	
	//set it so that it allows fire damage in 10 seconds
	SetPackPosition(dataPackHandle, 48);
	WritePackCell(dataPackHandle, GetTime() + 5);
	
	new Float: playerPos[3];
	new Float: distance;
	new playerTeam;
	new brazierTeam =  GetEntProp(brazier, Prop_Data, "m_iTeamNum");
	
	new owner = GetEntPropEnt(brazier, Prop_Data, "m_hOwnerEntity");
	
	//find nearby allies and give them fire damage
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		playerTeam = GetClientTeam(i);
		
		//Check to see if player is close to a brazier Pile
		GetClientAbsOrigin(i,playerPos);
		distance = GetVectorDistance( playerPos, brazierPos);
		
		if(distance < 200.0)
		{
			if(playerTeam == brazierTeam)
			{
				client_rolls[i][AWARD_G_BRAZIER][5] = GetTime() + 7;
				
				//light any huntsman arrows
				new iWeapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(iWeapon))
				{
					if(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex") == 56)
					{
						SetEntProp(iWeapon, Prop_Send, "m_bArrowAlight", 1);
					}
				}
			}else{
				//light nearby enemies
				if(owner < 0 || owner > MaxClients)
				{
					TF2_IgnitePlayer(i, i);
				}else{
					TF2_IgnitePlayer(i, owner);
				}
			}
		}
	}
	
	return Plugin_Continue;
}