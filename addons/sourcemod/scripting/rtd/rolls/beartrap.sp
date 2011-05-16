#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2>

public Action:Spawn_BearTrap(client)
{
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a BearTrap" );
		return Plugin_Handled;
	}
	
	SetEntityModel(ent, MODEL_BEARTRAP);
	
	//make sure to do this before we actually spawn the P.O.S.
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	DispatchSpawn(ent);
	
	//new iTeam = GetClientTeam(client);
	new iTeam = GetEntProp(client, Prop_Data, "m_iTeamNum");
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	

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
	
	if(iTeam == RED_TEAM)
	{
		SetVariantString("255+150+150");
		AcceptEntityInput(ent, "color", -1, -1, 0);
	}
	else
	{
		SetVariantString("150+150+255");
		AcceptEntityInput(ent, "color", -1, -1, 0);
	}
	
	new Float:pos[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
	//GetClientAbsOrigin(client,pos);
	
	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	/////////////////////////////////////////////
	//Initiate the timer.                      //
	//Important variables to keep track of     //
	/////////////////////////////////////////////
	new Handle:dataPack;
	CreateDataTimer(0.2,BearTrap_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPack, ent);
	WritePackCell(dataPack, GetTime());//PackPosition(8) 
	WritePackCell(dataPack, 120); //PackPosition(16) amount of time it will live in seconds
	WritePackCell(dataPack, 0); //PackPosition(24) Start Time of last trap activation
	/*
	if(annotation)
	{
		CreateAnnotation(ent, "Friendly ", 1, iTeam, 1);
		CreateAnnotation(ent, "Enemy ", 2, iTeam, 1);
		
	}*/
	
	return Plugin_Handled;
}

public Action:BearTrap_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopBearTrapTimer(dataPackHandle))
		return Plugin_Stop;
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new bearTrap = ReadPackCell(dataPackHandle);
	SetPackPosition(dataPackHandle, 24);
	new lastTrapTime = ReadPackCell(dataPackHandle);
	
	new Float: playerPos[3];
	new Float: bearTrapPos[3];
	new Float: distance;
	new playerTeam;
	new bearTrapTeam =  GetEntProp(bearTrap, Prop_Data, "m_iTeamNum");
	new isFinished = GetEntProp(bearTrap, Prop_Data, "m_bSequenceFinished");
	new cond;
	
	GetEntPropVector(bearTrap, Prop_Data, "m_vecOrigin", bearTrapPos);
	new currentSequence = GetEntProp(bearTrap, Prop_Data, "m_nSequence");
	
	//Sequence: OPEN - 2
	//Sequence: CLOSE - 1
	//Sequence: IDLE - 0

	//The trap is animating
	if(currentSequence != 0 && isFinished == 0)
	{
		return Plugin_Continue;
	}
	
	//Play opening anim once its been closed long enough
	if(GetTime() >= lastTrapTime  && currentSequence == 1)
	{
		SetVariantString("open");
		AcceptEntityInput(bearTrap, "SetAnimation", -1, -1, 0);
	}
	
	//Cycle through the players and find out who is close
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		cond = GetEntData(i, m_nPlayerCond);
		if(cond == 32 || cond == 327712)
			continue;
		
		playerTeam = GetClientTeam(i);
		
		//Check to see if player is close to a Bear Trap
		if(playerTeam != bearTrapTeam)
		{
			GetClientAbsOrigin(i,playerPos);
			distance = GetVectorDistance( playerPos, bearTrapPos);
			
			if(distance < 80.0)
			{
				//OK we found an enemy
				//is the Trap in the open position?
				if(currentSequence == 0 || currentSequence == 2)
				{
					SetVariantString("close");
					AcceptEntityInput(bearTrap, "SetAnimation", -1, -1, 0);
					
					SetPackPosition(dataPackHandle, 24);
					WritePackCell(dataPackHandle, GetTime() + 5); //time when it will open
					
					
					client_rolls[i][AWARD_G_BEARTRAP][3] = 1; //this is used to disable the stun sound
					TF2_StunPlayer(i,3.0, 0.0, TF_STUNFLAGS_NORMALBONK, 0);
					DealDamage(i, 30, bearTrap, 4226, "beartrap");
					SetEntityMoveType(i, MOVETYPE_NONE);
					SetEntityMoveType(i, MOVETYPE_WALK);
					client_rolls[i][AWARD_G_BEARTRAP][3] = 0;
					
					EmitSoundToAll(SOUND_BEARTRAP_CLOSE, bearTrap);
					
					break;
				}
				//DealDamage(i, 4, m_hOwnerEntity, 4226, "tf_weaponbase_melee");
			}
		}
	}
	
	return Plugin_Continue;
}

public stopBearTrapTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new bearTrap = ReadPackCell(dataPackHandle);
	new spawnTime = ReadPackCell(dataPackHandle);
	new liveTime = ReadPackCell(dataPackHandle);
	
	if(!IsValidEntity(bearTrap))
	{	
		return true;
	}
	
	new currIndex = GetEntProp(bearTrap, Prop_Data, "m_nModelIndex");
	
	if(currIndex != bearTrapModelIndex)
	{
		return true;
	}
	
	if(spawnTime + liveTime < GetTime())
	{
		killEntityIn(bearTrap, 0.1);
		return true;
	}
	
	return false;
}