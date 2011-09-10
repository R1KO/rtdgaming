#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2>
#include <attachments>

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
	WritePackCell(dataPack, RTD_PerksLevel[client][54]); //PackPosition(32) bleeding perk
	WritePackCell(dataPack, RTD_PerksLevel[client][57]); //PackPosition(40) latch onto enemies -RTD_PerksLevel[client][57]
	WritePackCell(dataPack, 0); //PackPosition(48) end of latch time
	WritePackCell(dataPack, 0); //PackPosition(56) latched enemy ID
	WritePackCell(dataPack, 0); //PackPosition(64) latched to enemy
	
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
	new bloodyTrap = ReadPackCell(dataPackHandle);
	new latchTrap = ReadPackCell(dataPackHandle);
	new latchTrapTime = ReadPackCell(dataPackHandle);
	new latchEnemyID = ReadPackCell(dataPackHandle);
	new latchedToEnemy = ReadPackCell(dataPackHandle);
	
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
	
	//the trap is latched onto an enemy
	if(latchedToEnemy)
	{
		
		
		new client = GetClientOfUserId(latchEnemyID);
		new dropTrap;
		
		//need valid client
		if(client < 1)
			dropTrap = 1;
		
		//client must be alive
		if(!IsPlayerAlive(client))
			dropTrap = 1;
		
		if(dropTrap != 1)
		{
			new Float:bearAngle[3];
			new Float:zeroPos[3];
			bearAngle[2] = -75.0;
			
			TeleportEntity(bearTrap, zeroPos, bearAngle, NULL_VECTOR);
			CAttach(bearTrap, client, "head");
		}
		
		if(dropTrap == 1 || (latchTrapTime < GetTime() && latchTrapTime != 0))
		{	
			if(dropTrap == 0)
				TF2_StunPlayer(client,3.0, 0.0, TF_STUNFLAGS_SMALLBONK, 0);
			
			CDetach(bearTrap);
			
			GetEntPropVector(bearTrap, Prop_Data, "m_vecOrigin", bearTrapPos);
			
			new Float:Direction[3];
			Direction[0] = bearTrapPos[0];
			Direction[1] = bearTrapPos[1];
			Direction[2] = bearTrapPos[2]-1024;
			
			new Float:floorPos[3];
			new Float:zeroAngle[3];
			
			new Handle:Trace = TR_TraceRayFilterEx(bearTrapPos, Direction, MASK_SOLID, RayType_EndPoint, TraceFilterAll, bearTrap);
			TR_GetEndPosition(floorPos, Trace);
			CloseHandle(Trace);
			
			floorPos[2] += 4;
			TeleportEntity(bearTrap, floorPos, zeroAngle, NULL_VECTOR);
			
			SetPackPosition(dataPackHandle, 48);
			WritePackCell(dataPackHandle, 0); //time when it will unlatch itself
			WritePackCell(dataPackHandle, 0); //enemy id
			WritePackCell(dataPackHandle, 0); //latched to enemy
			
		}
		
		
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
					
					if(latchTrap)
					{
						
						new Float:zeroPos[3];
						new Float:bearAngle[3];
						bearAngle[2] = -75.0;
						
						TeleportEntity(bearTrap, zeroPos, bearAngle, NULL_VECTOR);
						CAttach(bearTrap, i, "head");
						
						//ehh weird behavior have to do it twice
						TeleportEntity(bearTrap, zeroPos, bearAngle, NULL_VECTOR);
						CAttach(bearTrap, i, "head");
						
						SetPackPosition(dataPackHandle, 24);
						WritePackCell(dataPackHandle, GetTime() + 10); //time when it will open
						
						SetPackPosition(dataPackHandle, 48);
						WritePackCell(dataPackHandle, GetTime() + 5); //time when it will unlatch itself
						WritePackCell(dataPackHandle, GetClientUserId(i)); //enemy userid
						WritePackCell(dataPackHandle, 1); //latched to enemy
						
						
					}else{
						SetPackPosition(dataPackHandle, 24);
						WritePackCell(dataPackHandle, GetTime() + 5); //time when it will open
						
						
						client_rolls[i][AWARD_G_BEARTRAP][3] = 1; //this is used to disable the stun sound
						TF2_StunPlayer(i,3.0, 0.0, TF_STUNFLAGS_NORMALBONK, 0);
						
						SetEntityMoveType(i, MOVETYPE_NONE);
						SetEntityMoveType(i, MOVETYPE_WALK);
					}
					
					DealDamage(i, 30, bearTrap, 4226, "beartrap");
					
					client_rolls[i][AWARD_G_BEARTRAP][3] = 0;
					EmitSoundToAll(SOUND_BEARTRAP_CLOSE, bearTrap);
						
					if(bloodyTrap)
					{
						//delay the bleed effect in 3.5 seconds
						CreateTimer(3.5,  	Timer_BleedDelay, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
					}
					
					break;
				}
				//DealDamage(i, 4, m_hOwnerEntity, 4226, "tf_weaponbase_melee");
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_BleedDelay(Handle:Timer, any:clientUserID)
{
	new client = GetClientOfUserId(clientUserID);
	
	//need valid client
	if(client < 1)
		return Plugin_Stop;
	
	//client must be alive
	if(!IsPlayerAlive(client))
		return Plugin_Stop;
	
	TF2_MakeBleed(client, client, 4.0);
	
	return Plugin_Stop;
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