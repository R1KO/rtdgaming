#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>

public SpawnBomb(client, bombType)
{
	//---duke tf2nades
	// get position and angles
	new Float:gnSpeed = 700.0;
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
	
	angle[0] = GetRandomFloat(-180.0, 180.0);
	angle[1] = GetRandomFloat(-180.0, 180.0);
	angle[2] = GetRandomFloat(-180.0, 180.0);
	
	
	new String:sModel[64];
	
	sModel = MODEL_BOMB;
	new ent = CreateEntityByName("prop_physics_override");
	
	SetEntityModel(ent,sModel);
	
	DispatchSpawn(ent);
	
	TeleportEntity(ent, startpt, NULL_VECTOR, NULL_VECTOR);
	
	new iTeam = GetClientTeam(client);
	//Set the bombs owner
	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
	
	//Give the bomb a unique ID, cause no entity should have a maxhealth
	//of 510371 <-- and if one does then  i'm screwed :D
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", GetTime() + 10);//this is the time when it will blow up
	SetEntProp(ent, Prop_Data, "m_iHealth", 510371);
	
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
	CreateDataTimer(0.1, Bomb_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, ent);   //PackPosition(0); Bomb Index
	WritePackCell(dataPackHandle, GetTime());     //PackPosition(8); Bomb Start Time
	WritePackCell(dataPackHandle, 10);     //PackPosition(16); Time in seconds before it blows up
	WritePackCell(dataPackHandle, 0);     //PackPosition(24); Started Ringing?
	WritePackCell(dataPackHandle, bombType); 
	
	EmitSoundToAll(Bomb_Tick, ent);
	
	AttachRTDParticle(ent, "candle_light1", false, false, 21.0);
	
	if(iTeam == BLUE_TEAM)
	{
		AttachRTDParticle(ent, "critical_pipe_blue", false, false, 21.0);
	}else{
		AttachRTDParticle(ent, "critical_pipe_red", false, false, 21.0);
	}
	
	TeleportEntity(ent, startpt, angle, speed);
	
	new String:text[24];
	
	//Setup bomb specifics
	switch(bombType)
	{
		case 1:
		{
			returnOrdinal(client_rolls[client][AWARD_G_BOMB][1], text, sizeof(text));
			DispatchKeyValue(ent, "skin","0"); 
			Phys_SetMass(ent, 70.0);
		}
			
		case 2:
		{
			returnOrdinal(client_rolls[client][AWARD_G_FIREBOMB][1], text, sizeof(text));
			DispatchKeyValue(ent, "skin","1"); 
			Phys_SetMass(ent, 110.0);
		}
			
		case 3:
		{
			returnOrdinal(client_rolls[client][AWARD_G_ICEBOMB][1], text, sizeof(text));
			DispatchKeyValue(ent, "skin","2"); 
			Phys_SetMass(ent, 50.0);
		}
	}
	
	
	
	SetHudTextParams(0.42, 0.82, 5.0, 250, 250, 210, 255);
	ShowHudText(client, HudMsg3, "%s Bomb Dropped", text);
	
	EmitSoundToAll(SOUND_B, ent, _, _, _, 0.75);
	
	//allow bomb to be picked up
	SetEntProp(ent, Prop_Data, "m_PerformanceMode", 1);
}

public Action:Bomb_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopBombTimer(dataPackHandle))
		return Plugin_Stop;
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new bomb = ReadPackCell(dataPackHandle);
	new startTime = ReadPackCell(dataPackHandle);
	new detonateTime = ReadPackCell(dataPackHandle);
	new startedRinging = ReadPackCell(dataPackHandle);
	
	new explosionTime = detonateTime + startTime;
	new secondsBeforeExplosion = explosionTime - GetTime();
	new bombType = ReadPackCell(dataPackHandle);
	
	/////////////////////////////////////////////
	//Show nearby players that there is a bomb //
	/////////////////////////////////////////////
	new Float:bombPos[3];
	
	new iTeam = GetEntProp(bomb, Prop_Data, "m_iTeamNum");
	
	new Float:pos[3];
	new Float:tempDistance;
	new Float:distance;
	new dynamic_ent = -1;
	new tempExplosionTime = 999999999999;
	new foundTime = -1;
	new tempSecBeforeExplosion;
	new tempBombTeam;
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if(GetClientTeam(i) == iTeam)
			continue;
		
		GetClientEyePosition(i, pos);
		
		//Check to see if the player is close to other bombs
		dynamic_ent = -1;
		tempExplosionTime = 9999999999; //this is the max valeu it can have
		
		while ((dynamic_ent = FindEntityByClassname(dynamic_ent, "prop_physics")) != -1)
		{
			if(bombModelIndex == GetEntProp(dynamic_ent, Prop_Data, "m_nModelIndex"))
			{
				GetEntPropVector(dynamic_ent, Prop_Data, "m_vecOrigin", bombPos);  
				tempBombTeam = GetEntProp(dynamic_ent, Prop_Data, "m_iTeamNum");
				tempDistance = GetVectorDistance(bombPos, pos);
				
				if(tempDistance < 800.0 && GetClientTeam(i) != tempBombTeam)
				{
					foundTime = GetEntProp(dynamic_ent, Prop_Data, "m_iMaxHealth");
					//PrintToChat(i, "FoundTime: %i",foundTime);
					
					//is this the closest bomb to go off?
					if(tempExplosionTime > foundTime)
					{
						tempExplosionTime = foundTime;
						distance= tempDistance;
					}
				}
				
			}
		}
		
		if(tempExplosionTime == 9999999999)
			continue;
		
		if(distance > 800.0 && inBombBlastZone[i])
		{
			PrintCenterText(i, "You escaped the Bomb's blast area");
			
			inBombBlastZone[i]= 0;
			continue;
		}
		
		inBombBlastZone[i]= 1;
		
		tempSecBeforeExplosion = tempExplosionTime - GetTime();
		
		//PrintToChat(i, "CurrentTime: %i | ExplosionTime:%i", GetTime(), tempExplosionTime);
		if(tempSecBeforeExplosion <= 0)
		{
			PrintCenterText(i, "");
			continue;
		}
		
		if(tempSecBeforeExplosion < 3)
		{
			PrintCenterText(i, "Immediate DANGER! Explosion in: %i",tempSecBeforeExplosion);
		}else{
			PrintCenterText(i, "Caution: Bomb will explode in: %is",tempSecBeforeExplosion);
		}
	}
	
	if(secondsBeforeExplosion <= 2 && startedRinging == 0)
	{
		StopSound(bomb, SNDCHAN_AUTO, Bomb_Tick);
		EmitSoundToAll(Bomb_Ready, bomb);
		
		ResetPack(dataPackHandle);
		SetPackPosition(dataPackHandle, 24);
		WritePackCell(dataPackHandle, 1);	//PackPosition(24); Started Ringing?
	}
	
	//Detonate the bomb once it reaches it detonation time
	if(GetTime() - startTime >= detonateTime)
	{
		StopSound(bomb, SNDCHAN_AUTO, Bomb_Ready);
		ExplodeBomb(bomb, bombType);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public stopBombTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new bomb = ReadPackCell(dataPackHandle);
	//new startTime = ReadPackCell(dataPackHandle);
	//new detonateTime = ReadPackCell(dataPackHandle);
	
	if(!IsValidEntity(bomb))
	{	
		return true;
	}
	
	new currIndex = GetEntProp(bomb, Prop_Data, "m_nModelIndex");
	
	if(currIndex != bombModelIndex)
	{
		//LogToFile(logPath,"Killing stopBackPackTimer handle! Reason: Invalid Model");
		return true;
	}
	
	return false;
}


public ExplodeBomb(any:other, any:bombType)
{
	if(IsValidEntity(other))
	{	
		StopSound(other, SNDCHAN_AUTO, Bomb_Ready);
		EmitSoundToAll(Bomb_Explode, other);
		
		new Float:pos[3];
		GetEntPropVector(other, Prop_Data, "m_vecOrigin", pos);
			
		//-----Smoke Effects
		new smokeEnt = CreateEntityByName("info_particle_system");
		DispatchKeyValue(smokeEnt, "effect_name", "cinefx_goldrush");
		TeleportEntity(smokeEnt, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchSpawn(smokeEnt);
		
		ActivateEntity(smokeEnt);
		AcceptEntityInput(smokeEnt, "start");
		//------------------------------
		
		new Handle:dataPackHandle;
		CreateDataTimer(0.1, damageNearbyPlayers_Timer, dataPackHandle, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
		
		//Setup the datapack with appropriate information
		WritePackCell(dataPackHandle, EntIndexToEntRef(other));   //PackPosition(0); 
		WritePackCell(dataPackHandle, bombType);   //PackPosition(8); 
		
		killEntityIn(smokeEnt, 1.0);
	}
}

public Action:damageNearbyPlayers_Timer(Handle:Timer, Handle:dataPackHandle)
{
	ResetPack(dataPackHandle);
	new bomb = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new bombType = ReadPackCell(dataPackHandle);
	
	//Bomb Type 1 = normal
	//Bomb Type 2 = fire
	//Bomb Type 3 = ice
	//PrintToChatAll("Bomb Type: %i", bombType);
	
	if (IsValidEntity(bomb))
	{
		//Get the bomb's postion
		new Float:bombPos[3];
		GetEntPropVector(bomb, Prop_Data, "m_vecOrigin", bombPos);  
		
		new iTeam = GetEntProp(bomb, Prop_Data, "m_iTeamNum");
		new attacker = GetEntPropEnt(bomb, Prop_Data, "m_hOwnerEntity");
		
		new Float:pos[3];
		new Float:distance;
		new Float:damageAmount;
		
		for (new i = 1; i <= MaxClients ; i++)
		{
			if(!IsClientInGame(i) || !IsPlayerAlive(i))
				continue;
			
			if(GetClientTeam(i) == iTeam)
				continue;
			
			GetClientEyePosition(i, pos);
			
			distance = GetVectorDistance(bombPos, pos);
			
			if(client_rolls[i][AWARD_G_GODMODE][0])
				continue;
			
			if(TF2_IsPlayerInCondition(i, TFCond_Ubercharged))
				continue;
			
			if(distance > 500.0)
				continue;
			
			//Invalid attacker, possible reasons player (bomb owner) left
			//attacker must be a client!
			if(attacker == -1 || attacker > MaxClients)
				attacker = i;
			
			
			switch(bombType)
			{
				case 1:
				{
					damageAmount = (-1 * distance) + 500.0;
					
					DealDamage(i, RoundFloat(damageAmount), attacker, 128, "bomb");
				}
				
				case 2:
				{
					damageAmount = (((-1 * distance) + 500.0) / 10.0) + 1.0;
					
					DealDamage(i, RoundFloat(damageAmount), attacker, 16779264, "bomb");
					DealDamage(i, 1, attacker, 2056,"tf_weapon_flamethrower");
					
					createFlame(bomb, 3.0);
				}
				
				case 3:
				{
					//can we freeze client
					if(GetTime() > client_rolls[i][AWARD_G_BLIZZARD][3])
					{
						damageAmount = 10.0;
						
						DealDamage(i, RoundFloat(damageAmount), attacker, 128, "bomb");
						
						//mark the next time the client can get frozen
						client_rolls[client][AWARD_G_BLIZZARD][3] = GetTime() + 3;
						
						//mark the client as frozen
						client_rolls[client][AWARD_G_BLIZZARD][7] = 1;
						
						FreezeClient(i, attacker, 3.0);
					}
				}
			}
		}
		
		//OK we're done with this entity lets get it outta here
		AcceptEntityInput(bomb,"kill");
	}
	
	return Plugin_Stop;
}