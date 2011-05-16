#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Action:Spawn_Accelerator(client)
{
	new Float:vicorigvec[3];
	GetClientAbsOrigin(client, Float:vicorigvec);
	
	new Float:angles[3];
	GetClientAbsAngles(client, angles);
	
	new ent = CreateEntityByName("prop_dynamic_override");
	
	SetEntityModel(ent,MODEL_ACCELERATOR);
	SetEntProp(ent, Prop_Data, "m_takedamage", 0);  //default = 2
	
	DispatchSpawn(ent);
	
	//Set the Slowcube's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	new iTeam = GetClientTeam(client);
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 0);  //default = 2
	//SetEntProp(ent, Prop_Send, "m_takedamage", 2);  //default = 2
	
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	
	SetEntProp( ent, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 3);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 3);
	
	
	TeleportEntity(ent, vicorigvec, angles, NULL_VECTOR);
	
	// send "kill" event to the event queue
	killEntityIn(ent, cvLife);
	
	EmitSoundToAll(SND_DROP, client);
	
	CreateTimer(1.0, AcceleratorEffects_Timer, ent, TIMER_REPEAT |TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1, Accelerator_Timer, ent, TIMER_REPEAT |TIMER_FLAG_NO_MAPCHANGE);
	//CreateTimer(cvLife, DestroyJumpPad_Timer, ent, TIMER_REPEAT |TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action:DoAccelerate(any:client, accelerator)
{
	// Calculate and apply a new velocity to the player.
	new Float:speed[3];
	new Float:acceleratorAngle[3];
	
	GetEntPropVector(accelerator, Prop_Data, "m_angRotation", acceleratorAngle);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", speed);
	new Float:accSpeed = 5.0;
	
	new TFClassType:class = TF2_GetPlayerClass(client);
	if(GetClientButtons(client) & IN_ATTACK2 && class == TFClass_Heavy)
		accSpeed = 7.0;
	
	speed[0] *= accSpeed;//2.5
	speed[1] *= accSpeed;//2.5
	speed[2] = 260.0;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, speed);
	
	// play sound 
	EmitSoundToAll(SOUND_WHOOSH, client);
	
	
	AttachFastParticle(client, "rockettrail", 1.0);
}

public Action:Accelerator_Timer(Handle:timer, any:other)
{
	if(!IsValidEntity(other))
	{
		KillTimer(timer);
		return Plugin_Handled;
	}
	
	new String:modelname[128];
	GetEntPropString(other, Prop_Data, "m_ModelName", modelname, 128);
	
	if (!StrEqual(modelname, MODEL_ACCELERATOR))
	{
		KillTimer(timer);
		return Plugin_Handled;
	}
	
	new Float: playerPos[3];
	new Float: jumpPos[3];
	new Float: distance;
	new playerTeam;
	new jumpTeam =  GetEntProp(other, Prop_Data, "m_iTeamNum");
	
	GetEntPropVector(other, Prop_Data, "m_vecOrigin", jumpPos);
	new ownerEntity = GetEntPropEnt(other, Prop_Data, "m_hOwnerEntity");
		
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		playerTeam = GetClientTeam(i);
		
		//Invalid attacker, possible reasons player left
		//attacker must be a client!
		if(ownerEntity == -1 || ownerEntity > MaxClients)
		{
			ownerEntity = i;
		}
		
		//Check to see if player is close to a Accelrator
		if(playerTeam == jumpTeam)
		{
			GetClientAbsOrigin(i,playerPos);
			distance = GetVectorDistance( playerPos, jumpPos);
			
			if(distance < 40.0)
			{
				DoAccelerate(i, other);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:AcceleratorEffects_Timer(Handle:timer, any:other)
{
	if(!IsValidEntity(other))
	{
		KillTimer(timer);
		return Plugin_Handled;
	}
	
	new String:modelname[128];
	GetEntPropString(other, Prop_Data, "m_ModelName", modelname, 128);
	
	if (!StrEqual(modelname, MODEL_ACCELERATOR))
	{
		KillTimer(timer);
		return Plugin_Handled;
	}
	
	new iTeam =  GetEntProp(other, Prop_Data, "m_iTeamNum");
	if(iTeam == BLUE_TEAM)
	{
		AttachFastParticle(other, "teleporter_blue_exit_level1", 1.0);
	}else{
		AttachFastParticle(other, "teleporter_red_exit_level1", 1.0);
	}
	
	return Plugin_Continue;
}