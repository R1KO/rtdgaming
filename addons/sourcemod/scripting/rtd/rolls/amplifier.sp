#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2>
#include <rtd_rollinfo>

public Action:Spawn_Amplifier(client, health, maxHealth)
{
	client_rolls[client][AWARD_G_AMPLIFIER][4] = GetTime() + 5;
	
	new Float:pos[3];
	GetClientEyePosition(client, pos);
	
	new Float:Direction[3];
	Direction[0] = pos[0];
	Direction[1] = pos[1];
	Direction[2] = pos[2]-1024;
	
	new Float:floorPos[3];
	
	new Handle:Trace = TR_TraceRayFilterEx(pos, Direction, MASK_SOLID, RayType_EndPoint, TraceFilterAll, client);
	TR_GetEndPosition(floorPos, Trace);
	CloseHandle(Trace);
	
	floorPos[2] += 5.0;
	
	new amplifier = CreateEntityByName("prop_dynamic_override");
	
	SetEntityModel(amplifier,MODEL_AMPLIFIER);
	SetEntProp(amplifier, Prop_Data, "m_takedamage", 2);  //default = 2
	
	DispatchSpawn(amplifier);
	
	new iTeam = GetClientTeam(client);
	SetVariantInt(iTeam);
	AcceptEntityInput(amplifier, "TeamNum", -1, -1, 0);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(amplifier, "SetTeam", -1, -1, 0); 
	
	SetEntProp(amplifier, Prop_Data, "m_takedamage", 2);  //default = 2
	
	SetEntPropEnt(amplifier, Prop_Data, "m_hLastAttacker", client);
	
	//this is the owner
	SetEntProp(amplifier, Prop_Data, "m_PerformanceMode", client);
	
	SetEntProp( amplifier, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( amplifier, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(amplifier, Prop_Data, "m_CollisionGroup", 3);
	SetEntProp(amplifier, Prop_Send, "m_CollisionGroup", 3);
	
	//Set the shield's health
	SetEntProp(amplifier, Prop_Data, "m_iMaxHealth", maxHealth);
	SetEntProp(amplifier, Prop_Data, "m_iHealth", health);
	
	
	//argggh F.U. valve
	AcceptEntityInput( amplifier, "DisableCollision" );
	AcceptEntityInput( amplifier, "EnableCollision" );
	
	if(GetClientTeam(client) == RED_TEAM)
	{
		SetVariantString(bluDamageFilter);
		DispatchKeyValue(amplifier, "skin","1"); 
	}else{
		SetVariantString(redDamageFilter);
		DispatchKeyValue(amplifier, "skin","0"); 
	}
	//AcceptEntityInput(amplifier, "SetDamageFilter", -1, -1, 0); 
	
	TeleportEntity(amplifier,floorPos, NULL_VECTOR, NULL_VECTOR);
	
	// play sound
	EmitSoundToAll(SOUND_AMPLIFIER_HUM, amplifier);
	EmitSoundToAll(SOUND_AMPLIFIER_HUM_02, amplifier);
	
	HookSingleEntityOutput(amplifier, "OnBreak", AmplifierBreak, false);
	
	EmitSoundToAll(SND_DROP, client);
	
	SetVariantString("idle");
	AcceptEntityInput(amplifier, "SetAnimation", -1, -1, 0); 
	
	
	/////////////////////////////////////////////
	//Initiate the timer.                      //
	//Important variables to keep track of     //
	/////////////////////////////////////////////
	new Handle:dataPack;
	CreateDataTimer(0.2,Amplifier_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPack, amplifier);
	WritePackCell(dataPack, GetTime());//PackPosition(8) 
	WritePackCell(dataPack, 120); //PackPosition(16) amount of time it will live
	WritePackCell(dataPack, 0); //PackPosition(24) keeps track of health change, when this reaches 5 then -1 health is removed
	WritePackCell(dataPack, GetTime()); //PackPosition(32) used to re-emit it's sound
	WritePackCell(dataPack, GetTime());//PackPosition(40)  Last injection time
	
	////////////////////////////////
	//Setup the pretty stuff      //
	////////////////////////////////
	AttachRTDParticle(amplifier, "ghost_appearation", true, false, 10.0);
	
	if(GetClientTeam(client) == RED_TEAM)
	{
		AttachAmplifierParticle(amplifier, "critgun_weaponmodel_red", 155.0);
	}else{
		AttachAmplifierParticle(amplifier, "critgun_weaponmodel_blu", 155.0);
	}
	attachPoint_Tesla(amplifier, 155.0);
	
	SDKHook(amplifier,	SDKHook_OnTakeDamage, 	AmpHook);
	
	return Plugin_Continue;
}

public Action:AmpHook(amplifier, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(GetEntProp(amplifier, Prop_Data, "m_iTeamNum") == GetEntProp(attacker, Prop_Data, "m_iTeamNum"))
	{
		//PrintToChatAll("%i",damagetype);
		
		if(	damagetype&DMG_CLUB)
		{
			SetVariantInt(15);
			AcceptEntityInput(amplifier, "AddHealth");
			
			if(GetEntProp(amplifier, Prop_Data, "m_iHealth") > GetEntProp(amplifier, Prop_Data, "m_iMaxHealth"))
			{
				SetEntProp(amplifier, Prop_Data, "m_iHealth", GetEntProp(amplifier, Prop_Data, "m_iMaxHealth"));
				
				DealDamage(attacker, 2, attacker, 128, "");
			}else{
				DealDamage(attacker, 5, attacker, 128, "");
			}
		}
		
		damage = 0.0;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action:Amplifier_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopAmplifierTimer(dataPackHandle))
		return Plugin_Stop;
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new amplifier = ReadPackCell(dataPackHandle);
	SetPackPosition(dataPackHandle, 24);
	new incr = ReadPackCell(dataPackHandle);
	new lastSoundTime = ReadPackCell(dataPackHandle);
	new lastInjection = ReadPackCell(dataPackHandle);
	
	new bool:giveAmmo = false;
	
	/////////////////////////////////////////////
	//Trickle health away                      //
	//Currently every 0.5s it takes away 2hp   //
	/////////////////////////////////////////////
	incr ++;
	
	if(incr > 1)
	{
		SetVariantInt(1);
		AcceptEntityInput(amplifier, "RemoveHealth");
		incr = 0;
	}
	
	SetPackPosition(dataPackHandle, 24);
	WritePackCell(dataPackHandle, incr);
	
	if(GetEntProp(amplifier, Prop_Data, "m_iHealth") <= 0)
		return Plugin_Stop;
	
	/////////////////////////////////////////////
	//Reemit sounds every 30s even though this //
	//sound is already "loopable" this is done //
	//to make sure everyone hears it...        //
	/////////////////////////////////////////////
	if(lastSoundTime >= GetTime() + 30)
	{
		StopSound(amplifier, SNDCHAN_AUTO, SOUND_AMPLIFIER_HUM);
		StopSound(amplifier, SNDCHAN_AUTO, SOUND_AMPLIFIER_HUM_02);
		WritePackCell(dataPackHandle, GetTime());
		EmitSoundToAll(SOUND_AMPLIFIER_HUM, amplifier);
		EmitSoundToAll(SOUND_AMPLIFIER_HUM_02, amplifier);
		
	}
	
	if(GetTime() - lastInjection > 6)
	{
		giveAmmo = true;
		SetPackPosition(dataPackHandle, 40);
		WritePackCell(dataPackHandle, GetTime());
	}
	
	/////////////////////////////////////////////
	//Give minicrits to nearby players         //
	/////////////////////////////////////////////
	new Float:amplifierPos[3];
	GetEntPropVector(amplifier, Prop_Data, "m_vecOrigin", amplifierPos);
	amplifierPos[2] += 30.0;
	
	new Float:clientEyeOrigin[3];
	new iTeam = GetEntProp(amplifier, Prop_Data, "m_iTeamNum");
	new Float:distance;
	new Float:foundRange;
	new Float:traceEndPos[3];
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if(GetClientTeam(i) != iTeam)
			continue;
		
		GetClientEyePosition(i, clientEyeOrigin);
		
		distance = GetVectorDistance(amplifierPos, clientEyeOrigin);	
		
		if(distance > 350.0)
			continue;
		
		//begin our trace from our the Amplifier to the client
		new Handle:Trace = TR_TraceRayFilterEx(amplifierPos, clientEyeOrigin, MASK_NPCWORLDSTATIC, RayType_EndPoint, TraceFilterAll, amplifier);
		TR_GetEndPosition(traceEndPos, Trace);
		CloseHandle(Trace);
		
		foundRange = GetVectorDistance(clientEyeOrigin,traceEndPos);
		
		//Was the trace close to the player? If not the let's shoot from the player
		//back to the Amplifier. This makes sure that none of the entites saw each other
		if(foundRange > 35.0)
		{
			Trace = TR_TraceRayFilterEx(clientEyeOrigin, amplifierPos, MASK_NPCWORLDSTATIC, RayType_EndPoint, TraceFilterAll, i);
			TR_GetEndPosition(traceEndPos, Trace);
			CloseHandle(Trace);
			
			//did the player see a building?
			foundRange = GetVectorDistance(amplifierPos, traceEndPos);
		}
		
		distance = GetVectorDistance(clientEyeOrigin,amplifierPos);
		
		if(foundRange < 35.0 && distance < 350.0)
		{
			if(giveAmmo)
				GiveAmmoToActiveWeapon(i, 0.2);
			
			//19
			if(RTD_Perks[i][13] == 0)
			{
				TF2_AddCondition(i,TFCond_CritCola,0.3);
			}else{
				TF2_AddCondition(i,TFCond_Buffed,0.3);
			}
			
			
			//very low chance for crits
			if(GetRandomInt(0,100) == 100)
				TF2_AddCondition(i,TFCond_Kritzkrieged,2.0);
			
		}
	}
	
	return Plugin_Continue;
}

public stopAmplifierTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new amplifier = ReadPackCell(dataPackHandle);
	
	if(!IsValidEntity(amplifier))
	{	
		return true;
	}
	
	new currIndex = GetEntProp(amplifier, Prop_Data, "m_nModelIndex");
	
	if(currIndex != amplifierModelIndex)
	{
		StopSound(amplifier, SNDCHAN_AUTO, SOUND_AMPLIFIER_HUM);
		StopSound(amplifier, SNDCHAN_AUTO, SOUND_AMPLIFIER_HUM_02);
		
		//LogToFile(logPath,"Killing stopAmplifierTimer handle! Reason: Invalid Model");
		return true;
	}
	
	return false;
}

public AmplifierBreak (const String:output[], caller, activator, Float:delay)
{
	if(IsValidEntity(caller))
	{
		// play sound 
		EmitSoundToAll(SOUND_SENTRY_EXPLODE, caller);
		StopSound(caller, SNDCHAN_AUTO, SOUND_AMPLIFIER_HUM);
		StopSound(caller, SNDCHAN_AUTO, SOUND_AMPLIFIER_HUM_02);
		
		if(activator <= MaxClients && activator > 0)
		{
			ServerCommand("gameme_player_action %i killedobject_amplifier",activator);
		}
		
		UnhookSingleEntityOutput(caller,"OnBreak", AmplifierBreak);
	}
}

public attachPoint_Tesla(ent, Float:zOffset)
{
	//use these on the antenna
	//critgun_weaponmodel_red
	//critgun_weaponmodel_blu
	
	
	//Use these to "heal" from 
	//notes: has 2 control points
	//dispenser_beam_red_trail
	//dispenser_beam_blue_trail
	new particle = CreateEntityByName("point_tesla");

	new String:tName[128];
	if (IsValidEdict(particle))
	{
		new Float:pos[3]; 
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += zOffset;
		
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);
		
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "texture", SPRITE_PHYSBEAM);
		DispatchKeyValue(particle, "m_flRadius", "300.0");
		
		if(GetEntProp(ent, Prop_Data, "m_iTeamNum") == BLUE_TEAM)
		{
			DispatchKeyValue(particle, "m_Color", "0 0 255");
		}else{
			DispatchKeyValue(particle, "m_Color", "255 0 0");
		}
		
		DispatchKeyValue(particle, "thick_min", "0.1");
		DispatchKeyValue(particle, "thick_max", "15.0");
		
		DispatchKeyValue(particle, "interval_min", "1.0");
		DispatchKeyValue(particle, "interval_max", "6.0");
		
		DispatchKeyValue(particle, "lifetime_min", "0.2");
		DispatchKeyValue(particle, "lifetime_max", "0.4");
		
		DispatchKeyValue(particle, "beamcount_min", "5");
		DispatchKeyValue(particle, "beamcount_max", "10");
		
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		
		ActivateEntity(particle);
		AcceptEntityInput(particle, "TurnOn");
		
	}
}

AttachAmplifierParticle(ent, String:particleType[], Float:zOffset)
{	
	new particle = CreateEntityByName("info_particle_system");

	new String:tName[128];
	if (IsValidEdict(particle))
	{
		new Float:pos[3]; 
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += zOffset;
		
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);

		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
	}
}