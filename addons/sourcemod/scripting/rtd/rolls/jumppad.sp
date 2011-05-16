#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <rtd_rollinfo>

public Action:Spawn_JumpPad(client)
{
	new Float:vicorigvec[3];
	GetClientAbsOrigin(client, Float:vicorigvec);
	
	new ent = CreateEntityByName("prop_dynamic_override");
	
	SetEntityModel(ent,MDL_JUMP);
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	DispatchSpawn(ent);
	
	//Set the Slowcube's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	new iTeam = GetClientTeam(client);
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	//SetEntProp(ent, Prop_Send, "m_takedamage", 2);  //default = 2
	
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	
	SetEntProp( ent, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 3);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 3);
	
	//Set the shield's health
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", 500);
	SetEntProp(ent, Prop_Data, "m_iHealth", 500);
	
	
	//argggh F.U. valve
	AcceptEntityInput( ent, "DisableCollision" );
	AcceptEntityInput( ent, "EnableCollision" );
	
	if(GetClientTeam(client) == RED_TEAM){
		SetVariantString(bluDamageFilter);
	}else{
		SetVariantString(redDamageFilter);
	}
	AcceptEntityInput(ent, "SetDamageFilter", -1, -1, 0); 
	
	TeleportEntity(ent, vicorigvec, NULL_VECTOR, NULL_VECTOR);
	
	// send "kill" event to the event queue
	killEntityIn(ent, cvLife);
	
	// play sound 
	if(iTeam == BLUE_TEAM)
	{
		AttachRTDParticle(ent, "teleporter_blue_exit_level3",true,false,-15.0);
	}else{
		AttachRTDParticle(ent, "teleporter_red_exit_level3",true,false,-15.0);
	}
	
	HookSingleEntityOutput(ent, "OnBreak", JumpPadBreak, false);
	
	EmitSoundToAll(SND_DROP, client);
	
	CreateTimer(1.0, JumppadEffects_Timer, ent, TIMER_REPEAT |TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1, Jumppad_Timer, ent, TIMER_REPEAT |TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(cvLife, DestroyJumpPad_Timer, ent, TIMER_REPEAT |TIMER_FLAG_NO_MAPCHANGE);
	/*
	if(annotation)
	{
		CreateAnnotation(ent, "", 0, iTeam, 1);
	}*/
	
	return Plugin_Continue;
}

public Action:DoJump(any:client)
{
	client_rolls[client][AWARD_G_JUMPPAD][2] = 1;
	
	// Calculate and apply a new velocity to the player.
	new Float:speed[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", speed);
	speed[0] *= cvHSpeed;
	speed[1] *= cvHSpeed;
	
	speed[2] = cvVSpeed;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, speed);
	
	// play sound 
	EmitSoundToAll(SND_JUMP, client);
	
	
	AttachFastParticle(client, "rockettrail", 1.0);
}

public Action:DestroyJumpPad_Timer(Handle:timer, any:other)
{
	if(!IsValidEntity(other))
	{
		KillTimer(timer);
		return Plugin_Handled;
	}
	
	new String:modelname[128];
	GetEntPropString(other, Prop_Data, "m_ModelName", modelname, 128);
	
	if (!StrEqual(modelname, MDL_JUMP))
	{
		KillTimer(timer);
		return Plugin_Handled;
	}
	
	EmitSoundToAll(SND_JUMPEXPLODE, other);
	
	return Plugin_Continue;
}

public Action:JumppadEffects_Timer(Handle:timer, any:other)
{
	if(!IsValidEntity(other))
	{
		KillTimer(timer);
		return Plugin_Handled;
	}
	
	new String:modelname[128];
	GetEntPropString(other, Prop_Data, "m_ModelName", modelname, 128);
	
	if (!StrEqual(modelname, MDL_JUMP))
	{
		KillTimer(timer);
		return Plugin_Handled;
	}
	
	new iTeam =  GetEntProp(other, Prop_Data, "m_iTeamNum");
	if(iTeam == BLUE_TEAM)
	{
		AttachFastParticle(other, "teleporter_blue_exit_level3", 1.0);
	}else{
		AttachFastParticle(other, "teleporter_red_exit_level3", 1.0);
	}
	
	return Plugin_Continue;
}

public Action:Jumppad_Timer(Handle:timer, any:other)
{
	if(!IsValidEntity(other))
	{
		KillTimer(timer);
		return Plugin_Handled;
	}
	
	new String:modelname[128];
	GetEntPropString(other, Prop_Data, "m_ModelName", modelname, 128);
	
	if (!StrEqual(modelname, MDL_JUMP))
	{
		KillTimer(timer);
		return Plugin_Handled;
	}
	
	new Float: playerPos[3];
	new Float: jumpPos[3];
	new playerTeam;
	new jumpTeam =  GetEntProp(other, Prop_Data, "m_iTeamNum");
	
	GetEntPropVector(other, Prop_Data, "m_vecOrigin", jumpPos);
	new ownerEntity = GetEntPropEnt(other, Prop_Data, "m_hOwnerEntity");
	new cflags;
		
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
		
		//Check to see if player is close to a Crap Pile
		if(playerTeam == jumpTeam)
		{
			cflags = GetEntData(i, FindSendPropOffs("CBasePlayer", "m_fFlags"));
			if(cflags & FL_ONGROUND)
				client_rolls[i][AWARD_G_JUMPPAD][2] = 0;
			
			GetClientAbsOrigin(i,playerPos);
			
			if(FloatAbs(playerPos[0] - jumpPos[0]) < 40.0 && FloatAbs(playerPos[1] - jumpPos[1]) < 40.0 && FloatAbs(playerPos[2] - jumpPos[2]) < 100.0)
			{
				DoJump(i);
			}
		}
	}

	return Plugin_Continue;
}

public JumpPadBreak (const String:output[], caller, activator, Float:delay)
{
	if(IsValidEntity(caller))
	{
		new String:modelname[128];
		GetEntPropString(caller, Prop_Data, "m_ModelName", modelname, 128);
		if (StrEqual(modelname, MDL_JUMP))
		{
			// play sound 
			EmitSoundToAll(SND_JUMPEXPLODE, caller);
			
			UnhookSingleEntityOutput(caller,"OnBreak", JumpPadBreak);
		}
	}
}