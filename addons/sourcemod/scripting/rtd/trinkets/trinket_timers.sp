#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>

#pragma semicolon 1
#include <rtd_rollinfo>



public Action:TrinketsTimer(Handle:timer)
{	
	for (new i = 1; i <= MaxClients; i++)
	{
		//ok let's make sure that the player really is in the game
		if(IsClientInGame(i))
		{
			if(!IsPlayerAlive(i))
				continue;
			
			//Debugging comment out before release
			//RTD_TrinketActive[i][TRINKET_ELEMENTALRES] = 1;
			//RTD_TrinketBonus[i][TRINKET_ELEMENTALRES] = 20;
			
			//////////////////////////////////
			// Elemental Resistance Trinket //
			//////////////////////////////////
			if(RTD_TrinketActive[i][TRINKET_ELEMENTALRES])
			{
				if(RTD_TrinketMisc[i][TRINKET_ELEMENTALRES] < GetTime() && 
					!client_rolls[i][AWARD_B_LOSER][0] && 
					!roundEnded &&
					!yoshi_eaten[i][0] &&
					!client_rolls[i][AWARD_G_YOSHI][0] &&
					GetTime() > client_rolls[i][AWARD_G_YOSHI][4])
				{
					new bool:foundCondition = false;
					
					//find out what what effect the user has
					
					//1
					if(TF2_IsPlayerInCondition(i, TFCond_OnFire) && !foundCondition)
					{
						RTD_TrinketMisc_03[i][TRINKET_ELEMENTALRES] = 1;
						
						TF2_RemoveCondition(i, TFCond_OnFire);
						
						foundCondition = true;
					}
					
					//2
					if(TF2_IsPlayerInCondition(i, TFCond_Jarated) && !foundCondition)
					{
						RTD_TrinketMisc_03[i][TRINKET_ELEMENTALRES] = 2;
						
						TF2_RemoveCondition(i, TFCond_Jarated);
						
						foundCondition = true;
					}
					
					//3
					if(TF2_IsPlayerInCondition(i, TFCond_Bleeding) && !foundCondition)
					{
						RTD_TrinketMisc_03[i][TRINKET_ELEMENTALRES] = 3;
						
						TF2_RemoveCondition(i, TFCond_Bleeding);
						
						foundCondition = true;
					}
					
					//4
					if(TF2_IsPlayerInCondition(i, TFCond_Milked) && !foundCondition)
					{
						RTD_TrinketMisc_03[i][TRINKET_ELEMENTALRES] = 4;
						
						TF2_RemoveCondition(i, TFCond_Milked);
						
						foundCondition = true;
					}
					
					//5
					if(TF2_IsPlayerInCondition(i, TFCond_Dazed) && !foundCondition)
					{
						RTD_TrinketMisc_03[i][TRINKET_ELEMENTALRES] = 5;
						
						TF2_RemoveCondition(i, TFCond_Dazed);
						
						foundCondition = true;
					}
					
					if(foundCondition)
					{
						//apply cooldown
						RTD_TrinketMisc[i][TRINKET_ELEMENTALRES] = GetTime() + RTD_TrinketBonus[i][TRINKET_ELEMENTALRES];
						
						//immunity
						RTD_TrinketMisc_02[i][TRINKET_ELEMENTALRES] = GetTime() + 3;
						
						new Float:addedHPBuff;
						
						switch(RTD_TrinketLevel[i][TRINKET_ELEMENTALRES])
						{
							case 0:
								addedHPBuff = 0.02;
							
							case 1:
								addedHPBuff = 0.04;
							
							case 2:
								addedHPBuff = 0.06;
							
							case 3:
								addedHPBuff = 0.08;
						}
						
						if(clientOverlay[i] == false)
							ShowOverlay(i, "effects/com_shield002a.vmt ", 0.6);
						
						addHealthPercentage(i, addedHPBuff, false);
						
						new rnd = GetRandomInt(1,3);
						switch(rnd)
						{
							case 1:
								EmitSoundToAll(SOUND_ELEMENTAL_IMPACT_01,i);
							
							case 2:
								EmitSoundToAll(SOUND_ELEMENTAL_IMPACT_02,i);
								
							case 3:
								EmitSoundToAll(SOUND_ELEMENTAL_IMPACT_03,i);
						}
						
						CreateTimer(0.5,  Timer_ShowElementalWait, GetClientUserId(i), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}
					
				}else{
					//allow immunity
					if(GetTime() < RTD_TrinketMisc_02[i][TRINKET_ELEMENTALRES])
					{
						new bool:foundCondition = false;
						
						switch(RTD_TrinketMisc_03[i][TRINKET_ELEMENTALRES])
						{
							case 1:
							{
								if(TF2_IsPlayerInCondition(i, TFCond_OnFire))
								{
									TF2_RemoveCondition(i, TFCond_OnFire);
									foundCondition = true;
								}
							}
							
							case 2:
							{
								if(TF2_IsPlayerInCondition(i, TFCond_Jarated))
								{
									TF2_RemoveCondition(i, TFCond_Jarated);
									foundCondition = true;
								}
							}
								
							case 3:
							{
								if(TF2_IsPlayerInCondition(i, TFCond_Bleeding))
								{
									TF2_RemoveCondition(i, TFCond_Bleeding);
									foundCondition = true;
								}
							}
								
							case 4:
							{
								if(TF2_IsPlayerInCondition(i, TFCond_Milked))
								{
									TF2_RemoveCondition(i, TFCond_Milked);
									foundCondition = true;
								}
							}
							
							case 5:
							{
								if(TF2_IsPlayerInCondition(i, TFCond_Dazed))
								{
									TF2_RemoveCondition(i, TFCond_Dazed);
									foundCondition = true;
								}
							}
						}
						
						if(foundCondition)
						{
							new rnd = GetRandomInt(1,3);
							switch(rnd)
							{
								case 1:
									EmitSoundToAll(SOUND_ELEMENTAL_IMPACT_01,i);
								
								case 2:
									EmitSoundToAll(SOUND_ELEMENTAL_IMPACT_02,i);
									
								case 3:
									EmitSoundToAll(SOUND_ELEMENTAL_IMPACT_03,i);
							}
							
							if(clientOverlay[i] == false)
								ShowOverlay(i, "effects/com_shield002a.vmt ", 0.6);
						}
						
					}else{
						if(GetTime() == RTD_TrinketMisc_02[i][TRINKET_ELEMENTALRES])
						{
							RTD_TrinketMisc_02[i][TRINKET_ELEMENTALRES] = 0;
							EmitSoundToAll(SOUND_ELEMENTAL_BREAK,i);
						}
					}
				}
			}
			
			/////////////////////////
			// Scary Taunt Trinket //
			/////////////////////////
			if(RTD_TrinketActive[i][TRINKET_SCARYTAUNT])
			{
				if(TF2_IsPlayerInCondition(i, TFCond_Taunting) && !isActiveWeapon(i, 163) && !isActiveWeapon(i, 46))
				{	
					if(RTD_TrinketMisc[i][TRINKET_SCARYTAUNT] < GetTime())
					{
						//can't scary taunt with the Phlogistinator 
						if(isPlayerHolding_UniqueWeapon(i, 594))
						{
							PrintCenterText(i, "Can't Scary Taunt with: Phlogistinator");
						}else{
							
							SetEntData(i, m_iMovementStunAmount, 0 );
							
							timeExpireScare[i] = GetTime() + RTD_TrinketBonus[i][TRINKET_SCARYTAUNT];
							addHealthPercentage(i, 0.5, true); //add 20% health
							
							AttachTempParticle(i,"superrare_ghosts",5.0, false,"",20.0, false);
							
							RTD_TrinketMisc[i][TRINKET_SCARYTAUNT] = GetTime() + 30;
							
							new playerTeam;
							playerTeam = GetClientTeam(i);
							
							new Float:playerPos[3];
							new Float:enemyPos[3];
							new Float:distance;
							new String:playsound[64];
							new rndNum;
							new stunFlag;
							
							GetClientAbsOrigin(i, playerPos);
							new String:name[32];
							GetClientName(i, name, 32);
							
							for (new j = 1; j <= MaxClients ; j++)
							{
								if(!IsClientInGame(j) || !IsPlayerAlive(j))
									continue;
								
								if(TF2_IsPlayerInCondition(j, TFCond_Ubercharged))
									continue;
								
								
								if(playerTeam != GetClientTeam(j))
								{
									GetClientAbsOrigin(j,enemyPos);
									distance = GetVectorDistance( playerPos, enemyPos);
									
									if(distance < 400.0)
									{
										stunFlag = GetEntData(j, m_iStunFlags);
										
										//scare the player
										if(stunFlag != TF_STUNFLAGS_LOSERSTATE)
										{
											if(isVisibileCheck(i, j))
											{
												timeExpireScare[j] = GetTime() + RTD_TrinketBonus[i][TRINKET_SCARYTAUNT];
												
												rndNum = GetRandomInt(1,8);
												
												Format(playsound, sizeof(playsound), "vo/halloween_scream%i.wav", rndNum);
												EmitSoundToAll(playsound,j);
												
												rndNum = GetRandomInt(1,6);
												Format(playsound, sizeof(playsound), "vo/halloween_boo%i.wav", rndNum);
												EmitSoundToAll(playsound,i);
												
												TF2_StunPlayer(j,float(RTD_TrinketBonus[i][TRINKET_SCARYTAUNT]), 0.0, TF_STUNFLAGS_LOSERSTATE, 0);
												ResetClientSpeed(j);
												SetEntData(j, m_iMovementStunAmount, 0 );
												
												PrintCenterText(j, "%s scared you for %i seconds!", name, RTD_TrinketBonus[i][TRINKET_SCARYTAUNT]);
											}
										}
									}
								}
							}
						}
					}else{
						PrintCenterText(i, "Scary Taunt recharging. Wait: %i", RTD_TrinketMisc[i][TRINKET_SCARYTAUNT]- GetTime());
					}
				}
			}
			
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_ShowElementalWait(Handle:timer, any:clientUserID)
{
	new client = GetClientOfUserId(clientUserID);
	
	if(client < 1)
		return Plugin_Stop;
	
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	if(!RTD_TrinketActive[client][TRINKET_ELEMENTALRES])
		return Plugin_Stop;
	
	if(RTD_TrinketMisc[client][TRINKET_ELEMENTALRES] <= GetTime())
	{
		if(!(GetClientButtons(client) & IN_SCORE))
		{
			decl String:message[100];
			Format(message, 100, "Elemental Resistance Ready!");
			
			centerHudText(client, message, 0.0, 2.0, HudMsg3, 0.09);
		}
		return Plugin_Stop;
	}
	
	/////////////////////////////
	// Show message            //
	/////////////////////////////
	if(!(GetClientButtons(client) & IN_SCORE) && !isUsingHud4(client))
	{
		decl String:message[100];
		Format(message, 100, "Elemental Resistance Cooldown: %is", (RTD_TrinketMisc[client][TRINKET_ELEMENTALRES] - GetTime()));
		
		centerHudText(client, message, 0.0, 1.5, HudMsg3, 0.09);
	}
	
	return Plugin_Continue;
}


public Action:doSuperJump(Handle:timer, any:clientUserID)
{
	new client = GetClientOfUserId(clientUserID);
	
	if(client < 1)
		return Plugin_Stop;
	
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	if(GetEntityFlags(client) & FL_ONGROUND)
		return Plugin_Stop;
	
	new alpha = GetEntData(client, m_clrRender + 3, 1);
	
	if(TF2_GetPlayerClass(client) == TFClass_Spy)
		if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			alpha = 0;
		
	
	if(RTD_TrinketMisc_02[client][TRINKET_SUPERJUMP] <= GetTime() || RTD_TrinketMisc_02[client][TRINKET_SUPERJUMP] == 0)
	{
		if(alpha  > 0)
		{
			switch(GetRandomInt(1,2))
			{
				case 1:
					EmitSoundToAll(SOUND_JUMP01, client);
					
				case 2:
					EmitSoundToAll(SOUND_JUMP03, client);
			}
		}
		
		new Float:speed[3];
		speed[0] = superJumpVelocity[client][0];
		speed[1] = superJumpVelocity[client][1];
		speed[2] = superJumpVelocity[client][2];
		ScaleVector(speed, 1+(float(RTD_TrinketBonus[client][TRINKET_SUPERJUMP])/10.0));
		
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, speed);
		
		if(alpha  > 0)
		{
			//AttachFastParticle(client, "rockettrail", 1.0);
			AttachFastParticle4(client, "rocketjump_smoke", 1.0, 5.0);
			
		}
		
		RTD_TrinketMisc_02[client][TRINKET_SUPERJUMP] = GetTime() + 10;
		
		CreateTimer(1.0,  Timer_ShowSuperJumpWait, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
	}else{
		
		EmitSoundToClient(client, SOUND_DENY);
	}
	
	RTD_TrinketMisc[client][TRINKET_SUPERJUMP] = 0;
	
	return Plugin_Stop;
}

public Action:Timer_ShowSuperJumpWait(Handle:timer, any:clientUserID)
{
	new client = GetClientOfUserId(clientUserID);
	
	if(client < 1)
		return Plugin_Stop;
	
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	if(!RTD_TrinketActive[client][TRINKET_SUPERJUMP])
		return Plugin_Stop;
	
	if(RTD_TrinketMisc_02[client][TRINKET_SUPERJUMP] <= GetTime())
	{
		if(!(GetClientButtons(client) & IN_SCORE))
		{
			decl String:message[100];
			Format(message, 100, "Super Jump Ready!");
			
			centerHudText(client, message, 0.0, 2.0, HudMsg3, 0.09);
		}
		return Plugin_Stop;
	}
	
	/////////////////////////////
	// Show message            //
	/////////////////////////////
	if(!(GetClientButtons(client) & IN_SCORE))
	{
		decl String:message[100];
		Format(message, 100, "Super Jump Cooldown: %is", (RTD_TrinketMisc_02[client][TRINKET_SUPERJUMP] - GetTime()));
		
		centerHudText(client, message, 0.0, 1.5, HudMsg3, 0.09);
	}
	
	return Plugin_Continue;
}

public Action:doAirDash(Handle:timer, any:clientUserID)
{
	new client = GetClientOfUserId(clientUserID);
	
	if(client < 1)
		return Plugin_Stop;
	
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	if(GetEntityFlags(client) & FL_ONGROUND)
		return Plugin_Stop;
	
	new Float:speed[3];
	new Float:oldZ;
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", speed);
	oldZ = speed[2];
	ScaleVector(speed, 0.8);
	speed[2] = oldZ;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, speed);
	
	new Float:finalvec[3];
	finalvec[2] = float(RTD_TrinketBonus[client][TRINKET_AIRDASH]);
	SetEntDataVector(client,BaseVelocityOffset,finalvec,true);
	
	new alpha = GetEntData(client, m_clrRender + 3, 1);
	
	if(TF2_GetPlayerClass(client) == TFClass_Spy)
		if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			alpha = 0;
		
	if(alpha > 0)
		AttachFastParticle4(client, "doublejump_puff", 1.5, 5.0);
	
	//AttachFastParticle(client, "rocketjump_smoke", 1.0);
	
	RTD_TrinketMisc[client][TRINKET_AIRDASH] = 0;
	
	return Plugin_Stop;
}

public Action:recordVelocity(Handle:timer, any:clientUserID)
{
	new client = GetClientOfUserId(clientUserID);
	
	if(client < 1)
		return Plugin_Stop;
	
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	new Float:speed[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", speed);
	superJumpVelocity[client][0] = speed[0];
	superJumpVelocity[client][1] = speed[1];
	superJumpVelocity[client][2] = speed[2];
	
	return Plugin_Stop;
}