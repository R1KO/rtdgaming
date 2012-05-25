#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>
#include <vphysics>

#define DICEDEPOSIT_DELAY 2 //Delay(seconds) between hits to attempt

new dicedepositSpawnPoints[50][6];
new dicedepositSpawnPointCount;
new dicedepositSpawnLimit;

stock SpawnDiceDeposit(i)
{
	new Float:vicorigvec[3];
	vicorigvec[0] = float(dicedepositSpawnPoints[i][3]);
	vicorigvec[1] = float(dicedepositSpawnPoints[i][4]);
	vicorigvec[2] = float(dicedepositSpawnPoints[i][5]);
	
	new dicedeposit;
	
	//if(GetRandomInt(0, 10) > 5)
	//{
		//make it physics and move it up
	dicedeposit = CreateEntityByName("prop_physics_override");
	vicorigvec[2] += 100.0;
	//}else{
	//	dicedeposit = CreateEntityByName("prop_dynamic_override");
	//}
	
	SetEntityModel(dicedeposit,MODEL_DICEDEPOSIT);
	DispatchSpawn(dicedeposit);
	TeleportEntity(dicedeposit, vicorigvec, NULL_VECTOR, NULL_VECTOR);
	
	SetVariantString("idle");
	AcceptEntityInput(dicedeposit, "SetAnimation", -1, -1, 0);
	
	SetVariantInt(dicedepositSpawnPoints[i][1]);
	AcceptEntityInput(dicedeposit, "TeamNum", -1, -1, 0);
	SetVariantInt(dicedepositSpawnPoints[i][1]);
	AcceptEntityInput(dicedeposit, "SetTeam", -1, -1, 0); 
	
	SetEntProp(dicedeposit, Prop_Data, "m_nSolidType", 6 );
	SetEntProp(dicedeposit, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(dicedeposit, Prop_Data, "m_CollisionGroup", 2);
	SetEntProp(dicedeposit, Prop_Send, "m_CollisionGroup", 2);
	
	//Do not show particles if in Dice Debuggin mode
	if(GetConVarInt(c_Dice_Debug) == 0)
	{
		//parent the particle to the dicedeposit
		new String:tName[128];
		new particle = CreateEntityByName("info_particle_system");
		if (IsValidEdict(particle))
		{
			TeleportEntity(particle, vicorigvec, NULL_VECTOR, NULL_VECTOR);
			
			Format(tName, sizeof(tName), "dicedeposit%i", dicedeposit);
			DispatchKeyValue(dicedeposit, "targetname", tName);
			
			DispatchKeyValue(particle, "parentname", tName);
			
			if(dicedepositSpawnPoints[i][1] == BLUE_TEAM)
				DispatchKeyValue(particle, "effect_name", "critical_rocket_blue");
			else
				DispatchKeyValue(particle, "effect_name", "critical_rocket_red");
			
			DispatchSpawn(particle);
			
			SetVariantString(tName);
			AcceptEntityInput(particle, "SetParent", particle, particle, 0);
			
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");
		}
		HookSingleEntityOutput(dicedeposit, "OnTakeDamage", dicedepositDamage, false);
	}
	new Float:spawnDuration = float(dicedepositSpawnPoints[i][2]);
	killEntityIn(dicedeposit, spawnDuration);
	
	Phys_SetMass(dicedeposit, GetRandomFloat(0.0, 180.0));
	
	if(GetRandomInt(0,10) > 7)
		Phys_EnableDrag(dicedeposit, false);
	
	if(GetRandomInt(0,10) > 7)
	{
		Phys_EnableGravity(dicedeposit, false);
		
		//create timer to simulate gravity every 5s
		new Handle:dataPackHandle;
		CreateDataTimer(0.5, DiceDeposit_GTimer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
		WritePackCell(dataPackHandle, EntIndexToEntRef(dicedeposit));
		WritePackCell(dataPackHandle, GetTime() + 3);
	}
	
	SDKHook(dicedeposit, SDKHook_OnTakeDamage, 	MeleeOnlyDamage_Hook);
	
}

public Action:DiceDeposit_GTimer(Handle:timer, Handle:dataPackHandle)
{
	ResetPack(dataPackHandle);
	new diceDeposit = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new nextTime = ReadPackCell(dataPackHandle);
	
	if(!IsValidEntity(diceDeposit))
		return Plugin_Stop;
	
	if(GetTime() > nextTime)
	{
		if(Phys_IsGravityEnabled(diceDeposit))
		{
			//disable gravity for 5s
			Phys_EnableGravity(diceDeposit, false);
			SetPackPosition(dataPackHandle, 8);
			WritePackCell(dataPackHandle, GetTime() + 3);
		}else{
			//enable gravity for 2s
			Phys_EnableGravity(diceDeposit, true);
			SetPackPosition(dataPackHandle, 8);
			WritePackCell(dataPackHandle, GetTime() + 1);
		}
	}
	
	return Plugin_Continue;
}

stock SetupDiceDepositRoundSpawn(spawnForce=false, spawnAll=false)
{
	if(dicedepositSpawnPointCount <= 0)
		return;
	
	///////////////////////////////////////////////////
	// Delete any Dice Mines
	//////////////////////////////////
	new ent = -1;
	new currIndex;
	
	while ((ent = FindEntityByClassname(ent, "prop_dynamic")) != -1)
	{	
		currIndex = GetEntProp(ent, Prop_Data, "m_nModelIndex");
		
		if(currIndex == diceDepositModelIndex)
		{
			killEntityIn(ent, 1.0);
		}
	}
	
	
	new playersFound;
	for (new j = 1; j <= MaxClients ; j++)
	{
		if(IsClientInGame(j))
			playersFound ++;
	}
	if(playersFound < GetConVarInt(c_Dice_MinPlayers) && !spawnForce)
		return;
	
	PrintToChatAll("\x01\x04[RTD] Spawning Dice Deposits.");
	
	
	//LogToFile(logPath, "CurrentRound: %i | SpawnAll:%i | dicedepositSpawnPointCount:%i", currentRound, spawnAll, dicedepositSpawnPointCount);
	
	new roundSpawnedCount = 0;
	for(new i = 0; i < dicedepositSpawnPointCount;i++)
	{
		//if(roundSpawnedCount == 2)
		//	break;
		
		if(dicedepositSpawnPoints[i][0] == currentRound)
		{
			roundSpawnedCount++;
			SpawnDiceDeposit(i);
		}
		else if(spawnAll == 1)
		{
			roundSpawnedCount++;
			SpawnDiceDeposit(i);
		}
	}
}

public dicedepositDamage(const String:output[], caller, activator, Float:delay)
{
	decl String:message[200];
	if(IsValidEntity(caller))
	{
		new String:modelname[128];
		GetEntPropString(caller, Prop_Data, "m_ModelName", modelname, 128);
		if (StrEqual(modelname, MODEL_DICEDEPOSIT))
		{
			if(activator <= MaxClients && activator >= 1)
			{
				new iTeam = GetEntProp(caller, Prop_Data, "m_iTeamNum");
				if(GetClientTeam(activator) == iTeam)
				{
					//Gets Current Weapon
					decl String:activator_weapon[64];
					GetClientWeapon(activator, activator_weapon, sizeof(activator_weapon));
					
					//Gets The weapon and name of the weapon in melee slot
					decl String:activator_melee[64];
					new activator_melee_slot = GetPlayerWeaponSlot(activator, 2);
					if (activator_melee_slot != -1)
					{
						GetEdictClassname(activator_melee_slot, activator_melee, sizeof(activator_melee));
					}
					
					//Check to confirm the weapon used is the melee weapon
					if (StrEqual(activator_weapon, activator_melee))
					{
						GiveAmmoToActiveWeapon(activator, 0.1);
						client_rolls[activator][AWARD_G_JUMPPAD][2] = 1;
						
						if(TF2_GetPlayerClass(activator) == TFClass_Medic)
							TF_AddUberLevel(activator, 0.1);
						
						new Float:pos[3];
						GetClientEyePosition(activator, pos);
						new Float:finalvec[3];
						finalvec[0]=GetRandomFloat(100.0, 170.0)*GetRandomInt(-2,2);
						finalvec[1]=GetRandomFloat(100.0, 170.0)*GetRandomInt(-2,2);
						finalvec[2]=GetConVarFloat(g_Cvar_DiscoHeight)*60.0;
						SetEntDataVector(activator,BaseVelocityOffset,finalvec,true);
						
						if(dicedeposit_timestamp[activator] < GetTime())
						{
							dicedeposit_timestamp[activator] = GetTime()+DICEDEPOSIT_DELAY;
							new dicedeposit_roll = GetRandomInt(0, 100);
							
							//PrintToChat(activator, "Need More than:%i  | You Have:%i",dicedeposit_roll, (100-RTD_Perks[activator][16]));
							
							
							new diceMined;
							new diceChances;
							
							if(Phys_IsGravityEnabled(caller))
							{
								diceChances += 3;
							}else{
								diceChances += 6;
							}
							
							if(Phys_IsDragEnabled(caller))
							{
								diceChances += 1;
							}else{
								diceChances += 3;
							}
							
							new Float:diceMass = Phys_GetMass(caller);
							new String:massString[64];
							new String:gravString[64];
							new String:dragString[64];
							
							//dice mass
							if(diceMass < 20)
							{
								diceChances += 4;
								Format(massString, 64, "Low");
							}
							
							if(diceMass >= 20 && diceMass < 50)
							{
								diceChances += 2;
								Format(massString, 64, "Medium");
							}
							
							if(diceMass >= 50)
							{
								diceChances += 1;
								Format(massString, 64, "Heavy");
							}
							
							if(Phys_IsGravityEnabled(caller))
							{
								Format(gravString, 64, "Yes");
							}else{
								Format(gravString, 64, "No");
							}
							
							if(Phys_IsDragEnabled(caller))
							{
								Format(dragString, 64, "Yes");
							}else{
								Format(dragString, 64, "No");
							}
							
							if(RTD_TrinketActive[activator][TRINKET_DICEMINER])
							{
								diceChances += RTD_TrinketBonus[activator][TRINKET_DICEMINER];
							}
							
							Format(message, sizeof(message), "Mining Chance: %i\%", (RTD_Perks[activator][16]-5) + diceChances) ;
							PrintHintText(activator, message);
							
							if(dicedeposit_roll > (100-(RTD_Perks[activator][16]-5) - diceChances))
							{
								diceMined = GetRandomInt(1, mineMaxAmount);
								addDice(activator, 5, diceMined);
								
								if(RTD_TrinketActive[activator][TRINKET_DICEMINER])
								{
									if(GetClientHealth(activator) < (clientMaxHealth[activator] * 2))
									{
										new Float:addedHPBuff;
										
										switch(RTD_TrinketLevel[activator][TRINKET_DICEMINER])
										{
											case 0:
												addedHPBuff = 0.2;
											
											case 1:
												addedHPBuff = 0.3;
											
											case 2:
												addedHPBuff = 0.4;
											
											case 3:
												addedHPBuff = 0.6;
										}
										
										addHealthPercentage(activator, addedHPBuff, true);
									}
								}
							}
							
							new String:activator_name[64], String:buf[128];
							GetClientName(activator, activator_name, sizeof(activator_name));
							Format(buf, sizeof(buf), "Dice Mined: %d (N: %d | G: %d) by %s", diceMined, 100-RTD_Perks[activator][16] + 1, dicedeposit_roll, activator_name);
							for (new i = 0; i < MaxClients; i++)
									if (diceDebug[i] && IsValidClient(i))
										PrintToChat(i, buf);
						}
					}
					else
					{
						
						Format(message, sizeof(message), "[RTD] You must use a melee weapon to mine the dice deposit.");
						PrintCenterText(activator, message);
					}
				}
				else
				{
					Format(message, sizeof(message), "[RTD] You can only mine from a dice deposit for your team.");
					PrintCenterText(activator, message);
				}
			}
		}
	}
}

DiceDeposit_ParseList()
{
	//LogToFile(logPath,"# START PARSING DICEDEPOSIT SPAWN POINTS#");
	decl String:currentMap[32];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	new Handle:kvItemList = CreateKeyValues("RTD_DiceDeposit_SpawnPoints");
	new String:strLocation[256];
	new String:strLine[256];
	new String:strMapName[32];
	dicedepositSpawnPointCount = 0;
	
	new String:strLine2[256];
	Format(strLine2, sizeof(strLine2), "configs/rtd/dice_deposits_spawnpoints/%s.cfg",currentMap); 
	
	// Load the key files.
	BuildPath(Path_SM, strLocation, 256, strLine2);
	FileToKeyValues(kvItemList, strLocation);
	
	// Check if the parsed values are correct
	if (!KvGotoFirstSubKey(kvItemList)) 
	{ 
		LogToFile(logPath,"File not found: %s", strLocation);
		return; 
	}
	
	do
	{
		// Retrieve section name, which would be the map name
		KvGetSectionName(kvItemList, strMapName,  256);
		//LogToFile(logPath,"Name of Map in CFG: %s",strMapName);
		
		//The sectionName corresponds to the map that the server is currently playing
		if(StrEqual(currentMap, strMapName,false))
		{
			//LogToFile(logPath,"Loading Spawn Points for: %s",strMapName);
			do
			{
				KvGotoFirstSubKey(kvItemList);
				
				if(dicedepositSpawnPointCount < 50)
				{
					KvGetString(kvItemList, "round",   strLine, sizeof(strLine)); dicedepositSpawnPoints[dicedepositSpawnPointCount][0]   = StringToInt(strLine);
					KvGetString(kvItemList, "team",   strLine, sizeof(strLine)); dicedepositSpawnPoints[dicedepositSpawnPointCount][1]   = StringToInt(strLine);
					KvGetString(kvItemList, "duration",   strLine, sizeof(strLine)); dicedepositSpawnPoints[dicedepositSpawnPointCount][2]   = StringToInt(strLine);
					KvGetString(kvItemList, "x",   strLine, sizeof(strLine)); dicedepositSpawnPoints[dicedepositSpawnPointCount][3]   = StringToInt(strLine);
					KvGetString(kvItemList, "y",   strLine, sizeof(strLine)); dicedepositSpawnPoints[dicedepositSpawnPointCount][4]   = StringToInt(strLine);
					KvGetString(kvItemList, "z",   strLine, sizeof(strLine)); dicedepositSpawnPoints[dicedepositSpawnPointCount][5]   = StringToInt(strLine);
				}
				//LogToFile(logPath,"SpawnPoint Found: %i, %i, %i, %i, %i, %i",dicedepositSpawnPoints[dicedepositSpawnPointCount][0],dicedepositSpawnPoints[dicedepositSpawnPointCount][1],dicedepositSpawnPoints[dicedepositSpawnPointCount][2],dicedepositSpawnPoints[dicedepositSpawnPointCount][3],dicedepositSpawnPoints[dicedepositSpawnPointCount][4],dicedepositSpawnPoints[dicedepositSpawnPointCount][5]);
				dicedepositSpawnPointCount ++;
			}
			 while (KvGotoNextKey(kvItemList));
		}
	}
	while (KvGotoNextKey(kvItemList));
	
	if(dicedepositSpawnPointCount >= 50)
		dicedepositSpawnPointCount = 49;
	
	if(dicedepositSpawnLimit == -1 || GetConVarInt(c_Dice_Debug))
		dicedepositSpawnLimit = dicedepositSpawnPointCount;
	
	//LogToFile(logPath,"DiceDeposits Found: %i",dicedepositSpawnPointCount);
	CloseHandle(kvItemList);    
	//LogToFile(logPath,"# FINISHED PARSING DICEDEPOSIT SPAWN POINTS#");
}

public Action:DiceDepositRoundSpawn_Timer(Handle:timer)
{
	SetupDiceDepositRoundSpawn();
}

public RemoveDepositsNearEntity(cpIndex)
{	
	//Used when removing DiceDeposits near capture points so players
	//don't linger behind
	new Float:entityPos[3];
	new Float:depositPos[3];
	new Float:distance;
	new cpEntity = -1;
	
	//find the control point entity
	new controlPoint = -1;
	while ((controlPoint = FindEntityByClassname(controlPoint, "team_control_point")) != -1)
	{	
		if(cpIndex == GetEntProp(controlPoint, Prop_Data, "m_iPointIndex"))
		{
			cpEntity = controlPoint;
			break;
		}
		
	}
	
	//Hmmm invalid
	if(cpEntity == -1)
		return;
	
	GetEntPropVector(cpEntity, Prop_Data, "m_vecOrigin", entityPos);
	
	new ent = -1;
	new currIndex;
	
	while ((ent = FindEntityByClassname(ent, "prop_dynamic")) != -1)
	{	
		currIndex = GetEntProp(ent, Prop_Data, "m_nModelIndex");
		
		if(currIndex == diceDepositModelIndex)
		{
			GetEntPropVector(ent, Prop_Data, "m_vecOrigin", depositPos);
			distance = GetVectorDistance(entityPos, depositPos);
			//PrintToChatAll("%f", distance);
			//A deposit was found near the cap point
			//Remove found deposit so players can go elsewhere
			if(distance < 300.0)
				killEntityIn(ent, 2.0);
		}
	}
}
