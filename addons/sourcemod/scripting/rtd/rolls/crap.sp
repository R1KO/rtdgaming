#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>

public Action:Spawn_Crap(client)
{
	//---duke tf2nades
	// get position and angles
	new Float:gnSpeed = 10.0;
	
	if(RTD_Perks[client][19])
		gnSpeed = 400.0;
	
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
		ReplyToCommand( client, "Failed to create Crap!" );
		return Plugin_Handled;
	}
	
	SetEntityModel(ent, MODEL_CRAP);
	
	//make sure to do this before we actually spawn the P.O.S.
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	DispatchSpawn(ent);
	
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
	
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	

	SetEntProp(ent, Prop_Data, "m_takedamage", 2);
	
	 //Use the balls VPhysics for collisions
	SetEntProp( ent, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 6 );

	//Only detect bullet/damage collisions
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 2); 
	
	//Set the shield's health
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", 800);
	SetEntProp(ent, Prop_Data, "m_iHealth", 800);
	
	AcceptEntityInput( ent, "DisableCollision" );
	AcceptEntityInput( ent, "EnableCollision" );
	
	if(GetClientTeam(client) == RED_TEAM)
	{
		SetVariantString(bluDamageFilter);
	}else{
		SetVariantString(redDamageFilter);
	}
	AcceptEntityInput(ent, "SetDamageFilter", -1, -1, 0); 
	
	EmitSoundToAll(SOUND_CRAPSTRAIN, client);
	
	
	/////////////////////////////////////////////
	//Initiate the timer.                      //
	//Important variables to keep track of     //
	/////////////////////////////////////////////
	new Handle:dataPack;
	CreateDataTimer(0.4,Crap_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPack, ent);
	WritePackCell(dataPack, GetTime()+120);//PackPosition(8)  time to kill crap
	WritePackCell(dataPack, RTD_Perks[client][14]); //PackPosition(16) keeps track of health change, when this reaches 5 then -1 health is removed
	WritePackCell(dataPack, GetClientUserId(client)); //PackPosition(24) keeps track of health change, when this reaches 5 then -1 health is removed
	WritePackCell(dataPack, GetTime()); //PackPosition(32) time to re-emit crap idle sound
	WritePackCell(dataPack, RoundFloat(startpt[0])); //40
	WritePackCell(dataPack, RoundFloat(startpt[1])); //48
	WritePackCell(dataPack, RoundFloat(startpt[2])); //56
	WritePackCell(dataPack, 0); //64
	WritePackCell(dataPack, GetTime() + 2);// 72 time it can be picked up
	
	//Throw or spawn the crap
	TeleportEntity(ent, startpt, NULL_VECTOR, speed);
	SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
	
	HookSingleEntityOutput(ent, "OnHealthChanged", Crap_Hurt, false);
	
	Create_phys_keepupright(ent, crapName, 7.0, 1270);
	
	return Plugin_Handled;
}

public Create_phys_keepupright(entity, const String:parentname[], Float:killIn, angularlimit)
{	
	new ent = CreateEntityByName("phys_keepupright");
	if ( ent == -1 )
	{
		//ReplyToCommand( client, "Failed to create phys_keepupright" );
		return -1;
	}
	
	//Now lets parent the physics box to the animated spider
	new String:phys_keepupright_Name[128];
	Format(phys_keepupright_Name, sizeof(phys_keepupright_Name), "target%i", ent);
	DispatchKeyValue(ent, "targetname", phys_keepupright_Name);
	
	//attach it to the entity
	SetVariantString(parentname);
	AcceptEntityInput(ent, "attach1");
	DispatchKeyValue(ent, "attach1", parentname);
	
	SetVariantInt(angularlimit);
	AcceptEntityInput(ent, "SetAngularLimit");
	
	DispatchSpawn(ent);
	
	SetVariantString(parentname);
	AcceptEntityInput(ent, "SetParent", -1, -1, 0);
	
	ActivateEntity(ent);
	AcceptEntityInput(ent, "TurnOn");
	
	if(killIn > 0.0)
		killEntityIn(ent, killIn);
	
	return ent;
}

public Crap_Hurt (const String:output[], caller, activator, Float:delay)
{
	if(IsValidEntity(caller))
	{
		AttachTempParticle(caller,"env_sawblood_chunk", 1.0, false,"",0.0, false);
		
		if(GetEntProp(caller, Prop_Data, "m_iHealth") <= 0)
		{
			//show some chunky blood on death
			AttachTempParticle(caller,"blood_impact_red_01_chunk", 1.0, false,"",0.0, false);
			
			//Let's reward the player for killing this entity
			new rndNum = GetRandomInt(0,20);
			if(rndNum > 10)
			{
				TF_SpawnMedipack(caller, "item_healthkit_medium", true);
			}else{
				TF_SpawnMedipack(caller, "item_ammopack_medium", true);
			}
			
			StopSound(caller, SNDCHAN_AUTO, SOUND_CRAPIDLE);
		}
	}
}

public stopCrapTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new crap = ReadPackCell(dataPackHandle);
	new killcrap = ReadPackCell(dataPackHandle);
	
	if(!IsValidEntity(crap))
	{	
		return true;
	}
	
	new currIndex = GetEntProp(crap, Prop_Data, "m_nModelIndex");
	
	if(currIndex != crapModelIndex)
	{
		StopSound(crap, SNDCHAN_AUTO, SOUND_CRAPIDLE);
		return true;
	}
	
	if(GetTime() > killcrap)
	{
		StopSound(crap, SNDCHAN_AUTO, SOUND_CRAPIDLE);
		AcceptEntityInput(crap,"kill");
	}
	
	return false;
}

public Action:Crap_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopCrapTimer(dataPackHandle))
		return Plugin_Stop;
	
	ResetPack(dataPackHandle);
	new crap = ReadPackCell(dataPackHandle);
	SetPackPosition(dataPackHandle,16);
	new bloodyCrap = ReadPackCell(dataPackHandle);
	new clientUserID = ReadPackCell(dataPackHandle);
	new soundTime = ReadPackCell(dataPackHandle);
	
	
	new Float: crapPos[3];
	GetEntPropVector(crap, Prop_Data, "m_vecOrigin", crapPos);
	
	///////////////////////////////////////
	// Stop crap from being able to move //
	///////////////////////////////////////
	if(GetEntityMoveType(crap) == MOVETYPE_VPHYSICS)
	{
		new savedPos[3];
		savedPos[0] = ReadPackCell(dataPackHandle);
		savedPos[1] = ReadPackCell(dataPackHandle);
		savedPos[2] = ReadPackCell(dataPackHandle);
		new stillTime = ReadPackCell(dataPackHandle);
		
		
		if(RoundFloat(crapPos[0]) == savedPos[0] && RoundFloat(crapPos[1]) == savedPos[1] && RoundFloat(crapPos[2]) == savedPos[2])
			stillTime ++;
		
		SetPackPosition(dataPackHandle, 40);
		WritePackCell(dataPackHandle, RoundFloat(crapPos[0])); //40
		WritePackCell(dataPackHandle, RoundFloat(crapPos[1])); //48
		WritePackCell(dataPackHandle, RoundFloat(crapPos[2])); //56
		
		WritePackCell(dataPackHandle, stillTime); //64
		if(stillTime > 3)
		{
			SetEntityMoveType(crap, MOVETYPE_NONE);
			//PrintToChatAll("Debug msg: crap frozen!");
		}
		
	}
	
	///////////////////////////////
	//Set if it can be picked up //
	///////////////////////////////
	if(GetEntProp(crap, Prop_Data, "m_PerformanceMode") != 1)
	{
		SetPackPosition(dataPackHandle,72);
		new timeToPickup = ReadPackCell(dataPackHandle);
		if(GetTime() > timeToPickup)
			SetEntProp(crap, Prop_Data, "m_PerformanceMode", 1);
	}
	
	//////////////////////
	// Re-Emit Sounds   //
	//////////////////////
	if(soundTime < GetTime())
	{
		decl String:crapName[32];
		Format(crapName, 32, "crap_%i", crap);
		//eyeboss_doorway_vortex
		//eyeboss_death_vortex
		//eb_doorway_vortex04
		//superrare_purpleenergy
		//eb_aura_calm01 -blu
		//eb_aura_angry01 -red
		//AttachTempParticle(crap, "eb_aura_angry01", 14.0, true, crapName, 30.0, false);
		//AttachTempParticle(crap, "eyeboss_doorway_vortex", 14.0, true, crapName, 30.0, false);
		AttachTempParticle(crap, "superrare_flies", 14.0, true, crapName, 30.0, false);
		//AttachRTDParticle(crap, "rtd_crap_smoke", true, true, 0.0);
		
		StopSound(crap, SNDCHAN_AUTO, SOUND_CRAPIDLE);
		EmitSoundToAll(SOUND_CRAPIDLE, crap);
		
		SetPackPosition(dataPackHandle,32);
		WritePackCell(dataPackHandle, GetTime() + 15);
	}
	
	new Float: playerPos[3];
	new Float: distance;
	new playerTeam;
	new crapTeam =  GetEntProp(crap, Prop_Data, "m_iTeamNum");
	
	
	new rndNum = GetRandomInt(1,4);
	new String:addoutput[64];
	Format(addoutput, sizeof(addoutput), "ambient/voices/cough%i.wav",rndNum);
	
	//Invalid attacker, possible reasons player left
	//attacker must be a client!
	new client = GetClientOfUserId(clientUserID);
	if(client < 1)
	{
		client = crap;
	}else if(!IsClientInGame(client))
	{
		client = crap;
	}
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		playerTeam = GetClientTeam(i);
		
		//Check to see if player is close to a Crap Pile
		if(playerTeam != crapTeam)
		{
			GetClientAbsOrigin(i,playerPos);
			distance = GetVectorDistance( playerPos, crapPos);
			
			if(distance < 140.0)
			{
				if((GetTime() - lastCoughed[i]) >= 2)
				{
					lastCoughed[i] = GetTime();
					EmitSoundToAll(addoutput,i);
				}
				
				DealDamage(i, 3, client, 4226, "crap");
				
				if(bloodyCrap)
					TF2_MakeBleed(i, i, 2.0);
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