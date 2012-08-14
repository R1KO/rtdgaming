#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2>
#include <rtd_rollinfo>

public Action:Spawn_Dummy(client, health, maxhealth, originalOwner)
{
	new iTeam = GetClientTeam(client);
	
	new Float:pos[3];
	new Float:ang[3];
	GetClientEyePosition(client, pos);
	GetClientAbsAngles(client, ang); 
	
	new Float:Direction[3];
	Direction[0] = pos[0];
	Direction[1] = pos[1];
	Direction[2] = pos[2]-1024;
	
	g_FilteredEntity = client;
	
	new Handle:Trace = TR_TraceRayFilterEx(pos, Direction, MASK_SOLID, RayType_EndPoint, TraceFilter);
	new Float:AmmoPos[3];
	TR_GetEndPosition(AmmoPos, Trace);
	CloseHandle(Trace);
	
	ang[1] -= 90.0;
	
	///////////////////////////////////////////////////////////////////
	// Create the animated entity
	// This is the dynamic prop that will be animated, punching
	///////////////////////////////////////////////////////////////////
	new dummy = CreateEntityByName("prop_dynamic_override");
	if ( dummy == -1 )
	{
		ReplyToCommand(client, "Could not deploy a dummy." );
		return Plugin_Handled;
	}
	
	SetEntityModel(dummy, MODEL_DUMMY);
	
	SetEntProp(dummy, Prop_Data, "m_takedamage", 2);  //default = 2
	
	DispatchSpawn(dummy);
	
	new ownerOfDummy = GetClientOfUserId(originalOwner);
	SetEntPropEnt(dummy, Prop_Data, "m_hOwnerEntity", client);
	if(ownerOfDummy > 0)
	{
		if(iTeam == GetClientTeam(ownerOfDummy))
		{
			SetEntPropEnt(dummy, Prop_Data, "m_hOwnerEntity", ownerOfDummy);
		}
	}
	
	decl String:dummyName_dyn[32];
	Format(dummyName_dyn, 32, "dyn_%i", dummy);
	DispatchKeyValue(dummy, "targetname", dummyName_dyn);
	
	TeleportEntity(dummy, AmmoPos, ang, NULL_VECTOR);
	
	SetEntProp(dummy, Prop_Data, "m_takedamage", 2);  //default = 2
	
	SetVariantInt(iTeam);
	AcceptEntityInput(dummy, "TeamNum", -1, -1, 0);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(dummy, "SetTeam", -1, -1, 0); 
	
	if(iTeam == BLUE_TEAM)
	{
		DispatchKeyValue(dummy, "skin","1"); 
	}else{
		DispatchKeyValue(dummy, "skin","0"); 
	}
	
	SetEntProp(dummy, Prop_Data, "m_nSolidType", 6 );
	SetEntProp(dummy, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(dummy, Prop_Data, "m_CollisionGroup", 2);
	SetEntProp(dummy, Prop_Send, "m_CollisionGroup", 2);
	
	AcceptEntityInput( dummy, "DisableCollision" );
	AcceptEntityInput( dummy, "EnableCollision" );
	
	SetEntProp(dummy, Prop_Data, "m_iMaxHealth", maxhealth);
	SetEntProp(dummy, Prop_Data, "m_iHealth", health);
	
	SetVariantString("idle");
	AcceptEntityInput(dummy, "SetAnimation", -1, -1, 0); 
	
	if(iTeam== RED_TEAM)
	{
		SetVariantString(bluDamageFilter);
	}else{
		SetVariantString(redDamageFilter);
	}
	AcceptEntityInput(dummy, "SetDamageFilter", -1, -1, 0);
	
	
	HookSingleEntityOutput(dummy, "OnAnimationDone", OnAnimationDone_Dummy, false);
	HookSingleEntityOutput(dummy, "OnHealthChanged", Dummy_Hurt, false);
	
	/////////////////////////////////////////////
	//Initiate the timer.                      //
	//Important variables to keep track of     //
	/////////////////////////////////////////////
	new Handle:dataPack;
	CreateDataTimer(0.2, Dummy_Timer, dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPack, dummy);
	WritePackCell(dataPack, GetTime()+180);//PackPosition(8)  time to kill
	WritePackCell(dataPack, GetClientUserId(client));//16
	WritePackFloat(dataPack, GetTickedTime());//24
	WritePackCell(dataPack, GetTime() + 2); //32 when it can be picked up
	
	return Plugin_Handled;
}

public Dummy_Hurt (const String:output[], caller, activator, Float:delay)
{
	if(IsValidEntity(caller))
	{
		if(GetEntProp(caller, Prop_Data, "m_iHealth") <= 200)
		{
			SendObjectDestroyedEvent(activator, caller, "killeddummy");
			
			AttachRTDParticle(caller, "target_break_child_puff", true, false, -45.0);
			
			SetVariantString("die");
			AcceptEntityInput(caller, "SetAnimation", -1, -1, 0); 
			
			AcceptEntityInput( caller, "DisableCollision" );
			
			UnhookSingleEntityOutput(caller, "OnHealthChanged", Dummy_Hurt);
			
			killEntityIn(caller, 20.0);
			
			//killEntityIn(caller, 0.1);
			//Let's reward the player for killing this entity
			new rndNum = GetRandomInt(0,20);
			if(rndNum > 10)
			{
				TF_SpawnMedipack(caller, "item_healthkit_medium", true);
			}else{
				TF_SpawnMedipack(caller, "item_ammopack_medium", true);
			}	
		}
	}
}

public OnAnimationDone_Dummy (const String:output[], caller, activator, Float:delay)
{
	if(IsValidEntity(caller))
	{
		new sequence = GetEntProp(caller, Prop_Data, "m_nSequence");
		//PrintToChatAll("%i", sequence);
		
		if(sequence == 1)
		{
			SetVariantString("idle");
			AcceptEntityInput(caller, "SetAnimation", -1, -1, 0); 
			return;
		}
		
		//coming from prep
		if(sequence == 2)
		{
			SetVariantString("idlefight");
			AcceptEntityInput(caller, "SetAnimation", -1, -1, 0);
			return;
		}
	}
}

public stopDummyTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new dummy = ReadPackCell(dataPackHandle);
	new timeToKill = ReadPackCell(dataPackHandle);
	
	if(!IsValidEntity(dummy))
	{	
		return true;
	}
	
	if(GetTime() > timeToKill)
	{
		AcceptEntityInput(dummy,"kill");
		return true;
	}
	
	if(GetEntProp(dummy, Prop_Data, "m_iHealth") <= 200)
		return true;
	
	return false;
}

public Action:Dummy_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopDummyTimer(dataPackHandle))
		return Plugin_Stop;
	
	ResetPack(dataPackHandle);
	new dummy = ReadPackCell(dataPackHandle);
	SetPackPosition(dataPackHandle, 16);
	new clientUserID = ReadPackCell(dataPackHandle);
	new Float:nextHit = ReadPackFloat(dataPackHandle);
	new pickUpTime = ReadPackCell(dataPackHandle);
	
	new dummyTeam =  GetEntProp(dummy, Prop_Data, "m_iTeamNum");
	
	/////////////////////////////////////////
	// Delay dummy from attacking on spawn //
	/////////////////////////////////////////
	if(pickUpTime > GetTime())
		return Plugin_Continue;
	
	///////////////////////////////
	//Set if it can be picked up //
	///////////////////////////////
	if(GetEntProp(dummy, Prop_Data, "m_PerformanceMode") != 1)
	{
		if(GetTime() > pickUpTime)
			SetEntProp(dummy, Prop_Data, "m_PerformanceMode", 1);
	}
	
	////////////////////////////////////////////////////
	//Invalid attacker, possible reasons player left  //
	//This is so client get's credit for kills        //
	////////////////////////////////////////////////////
	new client = GetClientOfUserId(clientUserID);
	if(client < 1)
	{
		client = dummy;
	}else if(!IsClientInGame(client))
	{
		client = dummy;
	}
	
	/////////////////////////
	// Find nearby enemies //
	/////////////////////////
	new isFinished = GetEntProp(dummy, Prop_Data, "m_bSequenceFinished");
	
	new Float:dummyPos[3];
	new Float:dummyAngle[3];
	new Float:victim_fwd[3];
	new Float:angle_vec[3];
	new Float:diffAng;
	
	new Float: playerPos[3];
	new Float: distance;
	new playerTeam;
	new enemy = -1;
	
	GetEntPropVector(dummy, Prop_Data, "m_vecAbsOrigin", dummyPos);
	GetEntPropVector(dummy, Prop_Data, "m_angRotation", dummyAngle);
	
	new alpha;
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		playerTeam = GetClientTeam(i);
		
		//Check to see if player is close to a Crap Pile
		if(playerTeam != dummyTeam)
		{
			alpha = GetEntData(i, m_clrRender + 3, 1);
			
			if(alpha < 255)
				continue;
			
			if(TF2_IsPlayerInCondition(i, TFCond_Cloaked))
				continue;
			
			if(TF2_GetPlayerClass(i) == TFClass_Spy)
			{
				if(GetEntData(i, m_nDisguiseTeam) == dummyTeam)
					continue;
			}
			
			GetClientAbsOrigin(i,playerPos);
			distance = GetVectorDistance( playerPos, dummyPos);
			
			
			if(distance < 430.0)
			{
				playerPos[2] = dummyPos[2];
				dummyAngle[1] -= 90.0;
				
				//make sure player is in front of dummy
				GetAngleVectors(dummyAngle, victim_fwd, NULL_VECTOR, NULL_VECTOR);
				MakeVectorFromPoints(playerPos, dummyPos, angle_vec);
				NormalizeVector(angle_vec, angle_vec);
				diffAng = GetVectorDotProduct(victim_fwd, angle_vec);
				//PrintToChatAll("%f",diffAng);
				
				//make sure both the dummy and player can see each other
				if(!isVisibileCheck(i, dummy))
					continue;
				
				if (diffAng < 0.5)
					continue;
				
				enemy = i;
				
				if(GetEntProp(dummy, Prop_Data, "m_nSequence") == 0)
				{
					//PrintToChatAll("Starting Sequence: Prep (%i)", sequence);
					SetVariantString("prep");
					AcceptEntityInput(dummy, "SetAnimation", -1, -1, 0); 
				}
				
				//coming from idlefight sequence
				if(GetEntProp(dummy, Prop_Data, "m_nSequence") == 3 && distance < 140.0)
				{
					SetVariantString("fight");
					AcceptEntityInput(dummy, "SetAnimation", -1, -1, 0); 
				}
				
				if(distance > 140.0)
					continue;
				
				if(GetEntProp(dummy, Prop_Data, "m_nSequence") != 4)
				{
					SetVariantString("fight");
					AcceptEntityInput(dummy, "SetAnimation", -1, -1, 0); 
				}
				
				if(nextHit < GetTickedTime())
				{
					nextHit = GetTickedTime() + 0.4;
					SetPackPosition(dataPackHandle, 24);
					WritePackFloat(dataPackHandle, nextHit);
					
					victim_fwd[0] *= -1.0;
					victim_fwd[1] *= -1.0;
					new Float:rndScale = GetRandomFloat(350.0, 700.0);
					ScaleVector(victim_fwd, rndScale);
					victim_fwd[2] = rndScale/4.0;
					SetEntDataVector(enemy,BaseVelocityOffset,victim_fwd,true);
					
					if(rndScale < 450.0)
					{
						DealDamage(enemy, 35, client, 4226, "dummy");
					}else{
						DealDamage(enemy, 45, client, 4226, "dummy");
					}
					
					if(client < cMaxClients)
					{
						if(RTD_Perks[client][28] && GetRandomInt(0, 99) < 50 && client_rolls[i][AWARD_G_DUMMY][2] < GetTime())
						{
							TF2_StunPlayer(enemy, 1.5, 0.0, TF_STUNFLAGS_NORMALBONK, 0);
							
							//Next time the player can get stunned
							client_rolls[i][AWARD_G_DUMMY][2] = GetTime() + 7;
						}
					}
					
					switch(GetRandomInt(1,4))
					{
						case 1:
							EmitSoundToAll(SOUND_BOXINGHIT01, dummy);
							
						case 2:
							EmitSoundToAll(SOUND_BOXINGHIT02, dummy);
							
						case 3:
							EmitSoundToAll(SOUND_BOXINGHIT01, dummy);
							
						case 4:
							EmitSoundToAll(SOUND_BOXINGHIT01, dummy);
					}
					
					//aright we hurt someone this pass let the dumm wait until next time
					break;
				}
			}
		}
	}
	
	if(GetEntProp(dummy, Prop_Data, "m_nSequence") != 1 && GetEntProp(dummy, Prop_Data, "m_nSequence") != 0 && (nextHit + 1.8) < GetTickedTime() && enemy == -1)
	{
		SetVariantString("sleep");
		AcceptEntityInput(dummy, "SetAnimation", -1, -1, 0); 
	}
	
	if(GetEntProp(dummy, Prop_Data, "m_nSequence") == 4 && isFinished)
	{
		//PrintToChatAll("switching to idle! %i", GetTime());
		SetVariantString("idlefight");
		AcceptEntityInput(dummy, "SetAnimation", -1, -1, 0); 
	}
	
	return Plugin_Continue;
}