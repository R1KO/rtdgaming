#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2>
#include <rtd_rollinfo>

public Action:Spawn_UrineCloud(client)
{
	client_rolls[client][AWARD_G_URINECLOUD][0] = 0;
	new radius = 150;
	new isUpgrade;
	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Urine Cloud!" );
		return Plugin_Handled;
	}
	
	if(RTD_PerksLevel[client][52] == 0)
	{
		SetEntityModel(ent, MODEL_CLOUD);
	}else{
		SetEntityModel(ent, MODEL_CLOUD_ANGRY);
		radius = 188; //
		isUpgrade = 1;
	}
	
	//make sure to do this before we actually spawn the P.O.S.
	//SetEntProp(ent, Prop_Data, "m_takedamage", 0);  //default = 2
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	DispatchSpawn(ent);
	
	//Set the Sandwich's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	
	new iTeam = GetClientTeam(client);
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	

	//SetEntProp(ent, Prop_Data, "m_takedamage", 0);  //default = 2
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	

	SetEntProp( ent, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 3);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 3);
	
	AcceptEntityInput( ent, "DisableCollision" );
	AcceptEntityInput( ent, "EnableCollision" );
	
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", 800);
	SetEntProp(ent, Prop_Data, "m_iHealth", 800);
	
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
	new Float:angle[3];
	GetClientAbsAngles(client, angle);
	GetClientAbsOrigin(client,pos);
	
	pos[2] += 90.0;
	
	TeleportEntity(ent, pos, angle, NULL_VECTOR);
	
	AttachRTDParticle(ent, "jaratee_rain", false, false, 0.0);
	
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0);
	
	if(iTeam == RED_TEAM)
	{
		DispatchKeyValue(ent, "skin","0"); 
	}else{
		DispatchKeyValue(ent, "skin","1"); 
	}
	
	new Handle:dataPack;
	CreateDataTimer(0.5,Cloud_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPack, EntIndexToEntRef(ent)); //PackPosition(0) 
	WritePackCell(dataPack, 0);		//PackPosition(8), used to restart sounds
	WritePackCell(dataPack, GetTime()+120);		//PackPosition(16), time to kill the cloud
	WritePackCell(dataPack, radius);
	WritePackCell(dataPack, isUpgrade);
	
	//rain sound will go here
	EmitSoundToAll(SOUND_RAIN, ent);
	
	HookSingleEntityOutput(ent, "OnHealthChanged", Urine_Hurt, false);
	
	if(RTD_PerksLevel[client][52] == 0)
		return Plugin_Continue;
	
	///////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////
	new particle = CreateEntityByName("info_particle_system");

	new String:tName[128];
	Format(tName, sizeof(tName), "cloud%i", ent);
	DispatchKeyValue(ent, "targetname", tName);
	
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", "jaratee_rain");
		
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", client);
		
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		
		SetVariantString("leftcloud");
		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
	}
	
	//////////////////////////////////-------------------------------------------------------------//
	
	particle = CreateEntityByName("info_particle_system");
	
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", "jaratee_rain");
		
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", client);
		
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		
		SetVariantString("rightcloud");
		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
	}
	/////////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////
	
	attachPoint_Tesla_2(ent, tName);
	
	if(GetClientTeam(client) == BLUE_TEAM)
	{
		DispatchKeyValue(ent, "skin","2"); 
	}else{
		DispatchKeyValue(ent, "skin","1"); 
	}
	
	return Plugin_Handled;
}

public attachPoint_Tesla_2(ent, String:parentName[])
{
	//use these on the antenna
	//critgun_weaponmodel_red
	//critgun_weaponmodel_blu
	
	
	//Use these to "heal" from 
	//notes: has 2 control points
	//dispenser_beam_red_trail
	//dispenser_beam_blue_trail
	new particle = CreateEntityByName("point_tesla");

	if (IsValidEdict(particle))
	{
		new Float:pos[3]; 
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 50.0;
		
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", parentName);
		DispatchKeyValue(particle, "texture", SPRITE_PHYSBEAM);
		DispatchKeyValue(particle, "m_flRadius", "200.0");
		
		if(GetEntProp(ent, Prop_Data, "m_iTeamNum") == BLUE_TEAM)
		{
			DispatchKeyValue(particle, "m_Color", "50 50 255");
		}else{
			DispatchKeyValue(particle, "m_Color", "255 50 50");
		}
		
		DispatchKeyValue(particle, "thick_min", "0.1");
		DispatchKeyValue(particle, "thick_max", "5.0");
		
		DispatchKeyValue(particle, "interval_min", "1.0");
		DispatchKeyValue(particle, "interval_max", "6.0");
		
		DispatchKeyValue(particle, "lifetime_min", "0.2");
		DispatchKeyValue(particle, "lifetime_max", "0.4");
		
		DispatchKeyValue(particle, "beamcount_min", "5");
		DispatchKeyValue(particle, "beamcount_max", "10");
		
		DispatchSpawn(particle);
		SetVariantString(parentName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		
		//SetVariantString(attachment);
		//AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		
		
		//DispatchKeyValue(particle, "m_SoundName", SOUND_SPARK);
		
		ActivateEntity(particle);
		AcceptEntityInput(particle, "TurnOn");
		/*
		new Float:minbounds[3] = {-70.0, -70.0, -70.0}; 
		new Float:maxbounds[3] = {70.0, 70.0, 70.0}; 
		SetEntPropVector(particle, Prop_Send, "m_vecMins", minbounds); 
		SetEntPropVector(particle, Prop_Send, "m_vecMaxs", maxbounds); */
	}
}

public Urine_Hurt (const String:output[], caller, activator, Float:delay)
{
	if(IsValidEntity(caller))
	{
		AttachTempParticle(caller,"env_rain_guttersplash", 1.0, false,"",0.0, false);
		
		if(GetEntProp(caller, Prop_Data, "m_iHealth") <= 0)
		{
			//show some chunky blood on death
			AttachTempParticle(caller,"env_rain_guttersplash", 1.0, false,"",0.0, false);
			
			//Let's reward the player for killing this entity
			new rndNum = GetRandomInt(0,20);
			if(rndNum > 10)
			{
				TF_SpawnMedipack(caller, "item_healthkit_medium", true);
			}else{
				TF_SpawnMedipack(caller, "item_ammopack_medium", true);
			}
			
			StopSound(caller, SNDCHAN_AUTO, SOUND_RAIN);
		}
	}
	
}

public Action:Cloud_Timer(Handle:timer, Handle:dataPack)
{	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPack);
	new cloud 			= EntRefToEntIndex(ReadPackCell(dataPack));
	new soundInterval	= ReadPackCell(dataPack);
	new timeToKill		= ReadPackCell(dataPack);
	new Float:radius	= float(ReadPackCell(dataPack));
	new isUpgrade		= ReadPackCell(dataPack);
	
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(!IsValidEntity(cloud))
		return Plugin_Stop;
	
	if(GetTime() >= timeToKill)
	{
		//Stop the raining sound
		StopSound(cloud, SNDCHAN_AUTO, SOUND_RAIN);
		killEntityIn(cloud, 1.0);
		return Plugin_Stop;
	}
	
	soundInterval ++;
	if(soundInterval > 20)
	{
		StopSound(cloud, SNDCHAN_AUTO, SOUND_RAIN);
		soundInterval = 0;
		EmitSoundToAll(SOUND_RAIN, cloud);
	}
	SetPackPosition(dataPack, 8);
	WritePackCell(dataPack, soundInterval);		//PackPosition(8), used to restart sounds
	
	
	new Float: playerPos[3];
	new Float: cloudPos[3];
	new Float: distance;
	new playerTeam;
	new cloudTeam =  GetEntProp(cloud, Prop_Data, "m_iTeamNum");
	
	GetEntPropVector(cloud, Prop_Data, "m_vecOrigin", cloudPos);
	cloudPos[2] -= 50.0;
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		playerTeam = GetClientTeam(i);
		
		//Check to see if player is close to cloud
		GetClientAbsOrigin(i,playerPos);
		distance = GetVectorDistance( playerPos, cloudPos);
		
		if(distance < radius)
		{
			if(playerTeam != cloudTeam)
			{
				TF2_AddCondition(i,TFCond_Jarated,5.0);
			}else{
				TF2_RemoveCondition(i, TFCond_OnFire);
				
				if(isUpgrade)
				{
					TF2_RemoveCondition(i, TFCond_Milked);
					TF2_RemoveCondition(i, TFCond_Jarated);
				}
			}
		}
	}
	
	return Plugin_Continue;
}
