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
	
	// play sound 
	if(iTeam == BLUE_TEAM)
	{
		AttachRTDParticle(ent, "teleporter_blue_exit_level3",true,false,-15.0);
	}else{
		AttachRTDParticle(ent, "teleporter_red_exit_level3",true,false,-15.0);
	}
	
	HookSingleEntityOutput(ent, "OnBreak", JumpPadBreak, false);
	
	EmitSoundToAll(SND_DROP, client);
	
	/////////////////////////////////////////////
	//Initiate the timer.                      //
	//Important variables to keep track of     //
	/////////////////////////////////////////////
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, Jumppad_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(ent)); //entity reference
	WritePackCell(dataPackHandle, GetTime()); //PackPosition(8) time to re-emit particle
	WritePackCell(dataPackHandle, 10); //PackPosition(16) time to activate, reset to 0 when jumppad is used
	WritePackCell(dataPackHandle,GetTime() + (RoundFloat(cvLife) - 1)); //PackPosition(24) time to kill jumppad
	
	return Plugin_Continue;
}

public Action:DoJump(any:client, Float:hforce, Float:vForce)
{
	if(client < MaxClients)
		client_rolls[client][AWARD_G_JUMPPAD][2] = 1;
	
	// Calculate and apply a new velocity to the player.
	new Float:speed[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", speed);
	speed[0] *= (cvHSpeed * hforce);
	speed[1] *= (cvHSpeed * hforce);
	
	speed[2] = (cvVSpeed * vForce);
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, speed);
	
	// play sound 
	EmitSoundToAll(SND_JUMP, client);
	
	
	AttachFastParticle(client, "rockettrail", 1.0);
}

public stopJumpPadTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new jumpPad = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	if(jumpPad < 1)
		return true;
	
	if(!IsValidEntity(jumpPad))
		return true;
	
	return false;
}

public Action:Jumppad_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopJumpPadTimer(dataPackHandle))
		return Plugin_Stop;
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new jumpPad = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new jumpEffectTime = ReadPackCell(dataPackHandle);
	new jumpPadTimeOut = ReadPackCell(dataPackHandle);
	new timeToKill = ReadPackCell(dataPackHandle);
	
	/////////////////////
	// Destroy jumppad //
	/////////////////////
	if(GetTime() >= timeToKill)
	{
		EmitSoundToAll(SND_JUMPEXPLODE, jumpPad);
		
		killEntityIn(jumpPad, 0.1);
		return Plugin_Stop;
	}
	
	new jumpTeam =  GetEntProp(jumpPad, Prop_Data, "m_iTeamNum");
	
	///////////////////////
	//Do jumppad effects //
	///////////////////////
	if(GetTime() >= jumpEffectTime)
	{
		SetPackPosition(dataPackHandle, 8);
		WritePackCell(dataPackHandle, GetTime() + 1); //PackPosition(8) time to re-emit particle
		
		if(jumpTeam == BLUE_TEAM)
		{
			AttachFastParticle(jumpPad, "teleporter_blue_exit_level3", 1.0);
		}else{
			AttachFastParticle(jumpPad, "teleporter_red_exit_level3", 1.0);
		}
	}
	
	///////////////////////////////
	//Allow JumpPad to function  //
	///////////////////////////////
	if(jumpPadTimeOut > 7)
	{
		new Float: playerPos[3];
		new Float: jumpPos[3];
		new playerTeam;
		
		GetEntPropVector(jumpPad, Prop_Data, "m_vecOrigin", jumpPos);
		new cflags;
		
		for (new i = 1; i <= MaxClients ; i++)
		{
			if(!IsClientInGame(i) || !IsPlayerAlive(i))
				continue;
			
			playerTeam = GetClientTeam(i);
			
			//Check to see if player is close to a JumpPAd
			if(playerTeam == jumpTeam)
			{
				cflags = GetEntData(i, FindSendPropOffs("CBasePlayer", "m_fFlags"));
				if(cflags & FL_ONGROUND)
					client_rolls[i][AWARD_G_JUMPPAD][2] = 0;
				
				GetClientAbsOrigin(i,playerPos);
				
				if(FloatAbs(playerPos[0] - jumpPos[0]) < 40.0 && FloatAbs(playerPos[1] - jumpPos[1]) < 40.0 && FloatAbs(playerPos[2] - jumpPos[2]) < 100.0)
				{
					DoJump(i, 1.0, 1.0);
					
					jumpPadTimeOut = -1;
				}
			}
		}
	}
	
	//increment timeout
	jumpPadTimeOut ++;
	
	if(jumpPadTimeOut > 10)
		jumpPadTimeOut = 10;
	
	SetPackPosition(dataPackHandle, 16);
	WritePackCell(dataPackHandle, jumpPadTimeOut); //PackPosition(16) time to re-emit particle
	
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