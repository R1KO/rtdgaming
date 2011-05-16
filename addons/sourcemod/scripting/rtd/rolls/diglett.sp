#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2>
#include <rtd_rollinfo>

public Action:Spawn_Diglett(client)
{
	client_rolls[client][AWARD_G_DIGLETT][0] = 0;
	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Diglett!" );
		return Plugin_Handled;
	}
	
	SetEntityModel(ent, MODEL_DIGLETT);
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 0);  //default = 2
	
	DispatchSpawn(ent);
	
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	
	new iTeam = GetClientTeam(client);
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	//SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	

	SetEntProp( ent, Prop_Data, "m_nSolidType", 7 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 7 );
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 3);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 3);
	
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", 1000);
	SetEntProp(ent, Prop_Data, "m_iHealth", 1000);
	
	if(iTeam == RED_TEAM){
		SetVariantString("filter_blue_team");
	}else{
		SetVariantString("filter_red_team");
	}
	AcceptEntityInput(ent, "SetDamageFilter", -1, -1, 0); 
	
	
	new Float:pos[3];
	new Float:angle[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
	GetEntPropVector(client, Prop_Data, "m_angRotation", angle);
	pos[2] += 80.0; //push it up cause we arent using eye pos anymore
	
	new Float:Direction[3];
	Direction[0] = pos[0];
	Direction[1] = pos[1];
	Direction[2] = pos[2]-1024;
	
	new Float:AmmoPos[3];
	
	new Handle:Trace = TR_TraceRayFilterEx(pos, Direction, MASK_SOLID, RayType_EndPoint, TraceFilterAll, client);
	TR_GetEndPosition(AmmoPos, Trace);
	CloseHandle(Trace);
	
	TeleportEntity(ent, AmmoPos, angle, NULL_VECTOR);
	
	
	SetVariantString("Up");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0);
	
	if(iTeam == RED_TEAM)
	{
		DispatchKeyValue(ent, "skin","0"); 
	}else{
		DispatchKeyValue(ent, "skin","1"); 
	}
	
	//----------------------------------------------------------------------------------------------
	
	//----------------------------------------------------------------------------------------------
	new Handle:dataPack;
	CreateDataTimer(0.1,Diglett_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPack, ent); //PackPosition(0) 
	WritePackCell(dataPack, GetTime()+60);		//PackPosition(8), time to evolve into Dugtrio
	WritePackCell(dataPack, 0);		//PackPosition(16), time in current state
	WritePackCell(dataPack, 1);		//PackPosition(24), current State
	WritePackCell(dataPack, 0);		//PackPosition(32), step for sounds
	WritePackCell(dataPack, 0);		//PackPosition(40), isDugTrio
	WritePackCell(dataPack, GetTime()+120);		//PackPosition(48), timeto kill timer
	
	HookSingleEntityOutput(ent, "OnHealthChanged", diglett_Hurt, false);
	/*
	if(annotation)
	{
		CreateAnnotation(ent, "Friendly ", 1, iTeam, 1, 1);
		CreateAnnotation(ent, "Enemy ", 2, iTeam, 1, 1);
	}*/
	
	return Plugin_Handled;
}

public Action:Diglett_Timer(Handle:timer, Handle:dataPack)
{	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPack);
	new diglett 		= ReadPackCell(dataPack);
	new timeToEvolve	= ReadPackCell(dataPack);
	new timeIn			= ReadPackCell(dataPack);
	new currentState	= ReadPackCell(dataPack);
	new soundStep		= ReadPackCell(dataPack);
	new isTrio			= ReadPackCell(dataPack);
	new timeToKill		= ReadPackCell(dataPack);
	
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(!IsValidEntity(diglett))
		return Plugin_Stop;
	
	new currIndex = GetEntProp(diglett, Prop_Data, "m_nModelIndex");
	
	if(currIndex != diglettModelIndex && currIndex != dugTrioModelIndex)
	{
		return Plugin_Stop;
	}
	
	if(GetTime() >= timeToKill)
	{
		
		SetVariantString("down");
		AcceptEntityInput(diglett, "SetAnimation", -1, -1, 0);
		
		EmitSoundToAll(SOUND_DIGLETT_DOWN, diglett);
		
		killEntityIn(diglett, 1.0);
		return Plugin_Stop;
	}
	
	if(isTrio == 0)
	{
		if(GetTime() >= timeToEvolve)
		{
			EmitSoundToAll(SOUND_EVOLVE, diglett);
			
			isTrio = 1;
			SetPackPosition(dataPack, 40);
			WritePackCell(dataPack, isTrio);	//PackPosition(40), isDugTrio
			
			SetVariantString("down");
			AcceptEntityInput(diglett, "SetAnimation", -1, -1, 0);
			
			
			playRumbleSound(diglett);
			EmitSoundToAll(SOUND_DIGLETT_DOWN, diglett);
			
			currentState = 2;
			timeIn = 0;
		}
	}
	
	new diglettTeam =  GetEntProp(diglett, Prop_Data, "m_iTeamNum");
	
	//Determine animations
	timeIn ++;
	
	if(currentState == 1 && timeIn >= 10 && timeIn <= 12)
	{
		SetVariantString("idle");
		AcceptEntityInput(diglett, "SetAnimation", -1, -1, 0);
		
		SetEntityRenderMode(diglett, RENDER_TRANSCOLOR);
		SetEntityRenderColor(diglett, 255, 255, 255, 255);
		SetEntProp(diglett, Prop_Data, "m_takedamage", 2);  //default = 2
	}
	
	new isFinished = GetEntProp(diglett, Prop_Data, "m_bSequenceFinished");
	
	if(GetEntProp(diglett, Prop_Data, "m_nSequence") == 1)
	{
		if(isFinished)
		{
			SetEntityRenderMode(diglett, RENDER_TRANSCOLOR);
			SetEntityRenderColor(diglett, 255, 255, 255, 0);
			SetEntProp(diglett, Prop_Data, "m_takedamage", 0);  //default = 2
		}
	}
	
	if(GetEntProp(diglett, Prop_Data, "m_nSequence") == 2 && isTrio)
	{
		if(timeIn == 1 || timeIn == 5 || timeIn == 10)
			EmitSoundToAll(SOUND_DIGLETT_UP, diglett);
	}
	
	if(GetEntProp(diglett, Prop_Data, "m_nSequence") == 1 && isTrio)
	{
		if(timeIn == 1 || timeIn == 5 || timeIn == 10)
			EmitSoundToAll(SOUND_DIGLETT_DOWN, diglett);
	}
	
	if(currentState == 1 && timeIn >= 100)
	{
		SetVariantString("down");
		AcceptEntityInput(diglett, "SetAnimation", -1, -1, 0);
		
		playRumbleSound(diglett);
		if(!isTrio)
			EmitSoundToAll(SOUND_DIGLETT_DOWN, diglett);
		
		currentState = 2;
		timeIn = 0;
	}else if(currentState == 2 && timeIn >= 40)
	{
		if(isTrio && currIndex == diglettModelIndex)
		{
			
			SetEntityModel(diglett, MODEL_DUGTRIO);
		}
		
		SetEntityRenderMode(diglett, RENDER_TRANSCOLOR);
		SetEntityRenderColor(diglett, 255, 255, 255, 255);
		
		SetEntProp(diglett, Prop_Data, "m_takedamage", 2);  //default = 2
		
		SetVariantString("up");
		AcceptEntityInput(diglett, "SetAnimation", -1, -1, 0);
		
		playRumbleSound(diglett);
		if(!isTrio)
			EmitSoundToAll(SOUND_DIGLETT_UP, diglett);
		
		EmitSoundToAll(SOUND_DIGLETT, diglett);
		
		currentState = 1;
		timeIn = 0;
		
		new lastAttacker = GetEntPropEnt(diglett, Prop_Data, "m_hLastAttacker");
		if(lastAttacker > 0 && GetRandomInt(0,4) >= 3)
		{
			if(IsClientInGame(lastAttacker) && IsPlayerAlive(lastAttacker))
			{
				if(GetClientTeam(lastAttacker) != diglettTeam)
				{
					new Float:pos[3];
					GetEntPropVector(lastAttacker, Prop_Data, "m_vecOrigin", pos);
					pos[2] += 80.0; //push it up cause we arent using eye pos anymore
					
					new Float:Direction[3];
					Direction[0] = pos[0];
					Direction[1] = pos[1];
					Direction[2] = pos[2]-1024;
					
					new Float:AmmoPos[3];
					
					new Handle:Trace = TR_TraceRayFilterEx(pos, Direction, MASK_SOLID, RayType_EndPoint, TraceFilterAll, lastAttacker);
					TR_GetEndPosition(AmmoPos, Trace);
					CloseHandle(Trace);
					
					TeleportEntity(diglett, AmmoPos, NULL_VECTOR, NULL_VECTOR);
				}
			}
		}
	}
	
	
	SetPackPosition(dataPack, 16);
	WritePackCell(dataPack, timeIn);		//PackPosition(16), time in current state
	WritePackCell(dataPack, currentState);	//PackPosition(24), current State
	
	
	soundStep++;
	if(soundStep >= 14)
	{
		if(currentState == 1 && timeIn > 6)
		{
			if(isTrio == 0)
			{
				new rndNum = GetRandomInt(1,3);
				
				switch(rndNum)
				{
					case 1:
					{
						EmitSoundToAll(SOUND_DIGLETTDIG01, diglett);
					}
					case 2:
					{
						EmitSoundToAll(SOUND_DIGLETTDIG02, diglett);
					}
					case 3:
					{
						EmitSoundToAll(SOUND_DIGLETTDIG03, diglett);
					}
				}
			}else{
				EmitSoundToAll(SOUND_DUGTRIO, diglett);
			}
		}
		soundStep = 0;
	}
	WritePackCell(dataPack, soundStep);	//PackPosition(24), current State
	
	new Float: playerPos[3];
	new Float: diglettPos[3];
	new Float: distance;
	new playerTeam;
	new cond;
	new Float:wantedDistance = 300.0;
	
	if(isTrio == 1)
		wantedDistance = 400.0;
	
	GetEntPropVector(diglett, Prop_Data, "m_vecOrigin", diglettPos);
	
	if(currentState == 2 )
		return Plugin_Continue;
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		playerTeam = GetClientTeam(i);
		
		if(playerTeam != diglettTeam)
		{
			GetClientAbsOrigin(i,playerPos);
			distance = GetVectorDistance( playerPos, diglettPos);
			
			if(distance < wantedDistance)
			{
				cond = GetEntData(i, m_nPlayerCond);
				
				if(!(cond&32))
				{
					//Shake(i);
					Shake2(i, 0.5, 15.0);
					//sendshakemsg(i, 0, 16.0, 255.0, 0.5);
				}
				
			}
		}
	}
	
	return Plugin_Continue;
}

public diglett_Hurt (const String:output[], caller, activator, Float:delay)
{
	//LogToFile(logPath,"spider_Hurt -- Entering");
	
	if(IsValidEntity(caller))
	{
		AttachTempParticle(caller,"env_sawblood", 1.0, false,"",0.0, false);
		
		if(GetEntProp(caller, Prop_Data, "m_iHealth") <= 0)
		{
			//show some chunky blood on death
			AttachTempParticle(caller,"blood_trail_red_01_goop", 1.0, false,"",0.0, false);
			
			//Let's reward the player for killing a spider
			new rndNum = GetRandomInt(0,20);
			if(rndNum > 10)
			{
				TF_SpawnMedipack(caller, "item_healthkit_medium", true);
			}else{
				TF_SpawnMedipack(caller, "item_ammopack_medium", true);
			}
		}else{
			//play hurt sounds
		}
	}
	
	//LogToFile(logPath,"spider_Hurt -- Leaving");
}

public playRumbleSound(diglett)
{
	AttachRTDParticle(diglett, "target_break_child_puff", true, false, -45.0);
	
	new rndNum = GetRandomInt(1,4);
	
	switch(rndNum)
	{
		case 1:
		{
			EmitSoundToAll(SOUND_RUMBLE01, diglett);
		}
		case 2:
		{
			EmitSoundToAll(SOUND_RUMBLE02, diglett);
		}
		case 3:
		{
			EmitSoundToAll(SOUND_RUMBLE03, diglett);
		}
		case 4:
		{
			EmitSoundToAll(SOUND_RUMBLE04, diglett);
		}
	}
}

stock Shake2(Client, Float:Length, Float:Severity)
{
	
	//Connected:	
	if(IsClientInGame(Client))
	{
		
		//Declare:
		decl Handle:ViewMessage;
		
		//Clients:
		new SendClient[2];
		SendClient[0] = Client;
		
		//Write:
		ViewMessage = StartMessageEx(ShakeID, SendClient, 1);
		BfWriteByte(ViewMessage, 0);
		BfWriteFloat(ViewMessage, Severity);
		BfWriteFloat(ViewMessage, 10.0);
		BfWriteFloat(ViewMessage, Length);
		
		//Send:
		EndMessage();
	}
}