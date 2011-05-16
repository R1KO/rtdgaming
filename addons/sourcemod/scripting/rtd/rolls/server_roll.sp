#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

ServerRolls_LoadConfig()
{
	decl String:currentMap[32];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	new Handle:kvItemList = CreateKeyValues("RTD - Server Rolls");
	new String:strLocation[256];
	new String:strLine[256];
	new String:strMapName[32];
	
	serverRolls_Amount = 5;
	serverRolls_NextRoll = 0;
	
	
	/////////////////////////////////////////////
	//Normal Rolls that don't need any configs //
	/////////////////////////////////////////////
	serverRolls_Type[0] = 1; serverRolls_Round[0] = -1; //Hell's Fiery 
	serverRolls_Type[1] = 2; serverRolls_Round[1] = -1; //Saw Time
	serverRolls_Type[2] = 3; serverRolls_Round[2] = -1; //No Medicine for you!
	serverRolls_Type[3] = 4; serverRolls_Round[3] = -1; //Super Buff
	serverRolls_Type[4] = 5; serverRolls_Round[4] = -1; //Body Swap
	serverRolls_Type[5] = 6; serverRolls_Round[5] = -1; //Melee Time
	
	////////////////////////////////////////////////////////////
	//Load specialized rolls that require predfined locations //
	////////////////////////////////////////////////////////////
	new String:strLine2[256];
	Format(strLine2, sizeof(strLine2), "configs/rtd/server_rolls/%s.cfg",currentMap); 
	
	// Load the key files.
	BuildPath(Path_SM, strLocation, 256, strLine2);
	FileToKeyValues(kvItemList, strLocation);
	
	// Check if the parsed values are correct
	if (!KvGotoFirstSubKey(kvItemList)) 
	{ 
		LogToFile(logPath,"No Server Rolls Config found for: %s", currentMap);
		return; 
	}
	
	do
	{
		// Retrieve section name, which would be the map name
		KvGetSectionName(kvItemList, strMapName,  256);
		
		//The sectionName corresponds to the map that the server is currently playing
		if(StrEqual(currentMap, strMapName,false))
		{
			do
			{
				KvGotoFirstSubKey(kvItemList);
				
				if(serverRolls_Amount < 20)
				{
					KvGetString(kvItemList, "type",   strLine, sizeof(strLine));	serverRolls_Type[serverRolls_Amount]		= StringToInt(strLine);
					KvGetString(kvItemList, "round",   strLine, sizeof(strLine));	serverRolls_Round[serverRolls_Amount]		= StringToInt(strLine);
					KvGetString(kvItemList, "x",   strLine, sizeof(strLine));		serverRolls_Origin[serverRolls_Amount][0]   = StringToInt(strLine);
					KvGetString(kvItemList, "y",   strLine, sizeof(strLine));		serverRolls_Origin[serverRolls_Amount][1]   = StringToInt(strLine);
					KvGetString(kvItemList, "z",   strLine, sizeof(strLine));		serverRolls_Origin[serverRolls_Amount][2]	= StringToInt(strLine);
					KvGetString(kvItemList, "angle",   strLine, sizeof(strLine));	serverRolls_Angle[serverRolls_Amount]		= StringToInt(strLine);
				}
				
				serverRolls_Amount ++;
			}
			 while (KvGotoNextKey(kvItemList));
		}
	}
	while (KvGotoNextKey(kvItemList));
	
	CloseHandle(kvItemList);
	
	PrintToServer("Amount of Server Rolls: %i", serverRolls_Amount);
}

public Action:ServerRolls_Timer(Handle:Timer)
{
	//PrintToChatAll("Entering ServerRolls_Timer!");
	///////////////////////
	//Did the round end? //
	///////////////////////
	if(roundEnded || inSetup)
	{
		//serverRolls_NextRoll = 0;
		return Plugin_Continue;
	}
	
	/////////////////////////////////////////////////////
	//Determine when our the next server roll will be  //
	/////////////////////////////////////////////////////
	if(serverRolls_NextRoll == 0)
	{
		serverRolls_NextRoll = GetTime() + GetRandomInt(serverRolls_MinTime * 60, serverRolls_MaxTime * 60);
		//PrintToChatAll("Next Roll at :%i",serverRolls_NextRoll);
	}
	
	/////////////////////////////////////////////////////
	//Has enough time passed so the server can roll?   //
	/////////////////////////////////////////////////////
	//PrintToChatAll("Next Server Roll in :%is",serverRolls_NextRoll - GetTime());
	
	if(GetTime() > serverRolls_NextRoll - 10)
	{
		decl timeleft;
		timeleft = serverRolls_NextRoll - GetTime();
		decl String:message[200];
		Format(message, sizeof(message), "Server will roll in %i seconds!",timeleft);
		
		tf2_game_text(message);
	}
	
	if(GetTime() >= serverRolls_NextRoll)
	{
		serverRolls_NextRoll = 0;
		serverRolls_EndTime = GetTime() + serverRolls_Duration;
		
		/////////////////////////////////////////////////////
		//Find amount of rolls that pertain to this round  //
		/////////////////////////////////////////////////////
		new amountofRollsFound = 0;
		new Handle: serverRolls_Array;
		serverRolls_Array = CreateArray(1,20);
		
		for (new i = 0; i <= serverRolls_Amount ; i++)
		{
			if(serverRolls_Round[i] == currentRound || serverRolls_Round[i] == -1)
			{
				SetArrayCell(serverRolls_Array,amountofRollsFound,i,0);
				amountofRollsFound ++;
			}
		}
		
		//////////////////////////////
		//Pick a random roll        //
		//////////////////////////////
		if(amountofRollsFound > 0)
		{
			new wantedRoll = GetArrayCell(serverRolls_Array, GetRandomInt(0, amountofRollsFound-1), 0);
			
			//serverRolls_Type[wantedRoll] = 6;
			
			switch(serverRolls_Type[wantedRoll])
			{
				case 1:
				{
					///////////////////////////
					//Hell's Fiery Setup     //
					///////////////////////////	
					PrintCenterTextAll("The Server has rolled: Hell's Wrath");
					
					new Handle:dataPack;
					CreateDataTimer(1.0, HellsFiery_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
					WritePackCell(dataPack, serverRolls_EndTime);//PackPosition(0) - Time to kill this timer
					WritePackCell(dataPack, 0);//PackPosition(8) - last time a firebomb went off
					WritePackCell(dataPack, 5);//PackPosition(16) - interval between bombings
				}
				
				case 2:
				{
					///////////////////////////
					//Saw Time Setup         //
					///////////////////////////	
					PrintCenterTextAll("The Server has rolled: Saw Time");
					
					new Handle:dataPack;
					CreateDataTimer(1.0, SawSpawner_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
					WritePackCell(dataPack, serverRolls_EndTime);//PackPosition(0) - Time to kill this timer
					WritePackCell(dataPack, GetTime());//PackPosition(8) - LastEmission
				}
				
				case 3:
				{
					///////////////////////////
					//No Medicine for you    //
					///////////////////////////	
					PrintCenterTextAll("The Server has rolled: No Medicine for You!");
					UpdateHealthContainers(false);
					
					new Handle:dataPack;
					CreateDataTimer(1.0, UpdateCabinets_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
					WritePackCell(dataPack, serverRolls_EndTime);//PackPosition(0) - Time to kill this timer
				}
				/*
				case 4:
				{
					///////////////////////////
					//Super Buff           //
					///////////////////////////	
					PrintCenterTextAll("The Server has blessed you with: Super Buff");
					
					new Handle:dataPack;
					CreateDataTimer(1.0, GiveStuff_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
					WritePackCell(dataPack, serverRolls_EndTime);//PackPosition(0) - Time to kill this timer
				}
				*/
				case 4:
				{
					///////////////////////////
					//Body Swap              //
					///////////////////////////	
					PrintCenterTextAll("The Server has rolled: Body Swap");
					
					new Handle:dataPack;
					CreateDataTimer(1.0, BodySwap_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
					WritePackCell(dataPack, serverRolls_EndTime);//PackPosition(0) - Time to kill this timer
					WritePackCell(dataPack, 0);//PackPosition(8) - last time a firebomb went off
					WritePackCell(dataPack, 20);//PackPosition(16) - interval between body swaps
				}
				
				case 5:
				{
					///////////////////////////
					//Body Swap              //
					///////////////////////////	
					PrintCenterTextAll("The Server has rolled: Body Swap");
					
					new Handle:dataPack;
					CreateDataTimer(1.0, BodySwap_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
					WritePackCell(dataPack, serverRolls_EndTime);//PackPosition(0) - Time to kill this timer
					WritePackCell(dataPack, 0);//PackPosition(8) - last time a firebomb went off
					WritePackCell(dataPack, 20);//PackPosition(16) - interval between body swaps
				}
				
				case 6:
				{
					///////////////////////////
					//Melee Mode             //
					///////////////////////////	
					PrintCenterTextAll("The Server has rolled: Melee Mode");
					
					new seconds = GetRandomInt(30, 60);
					serverRolls_EndTime = GetTime() + seconds;
					new String:message[128];
					Format(message, sizeof(message), "Melee Mode for %i seconds", seconds);
					
					for(new i=1; i <= MaxClients; i++)
					{
						// Check to make sure the player is on the same team
						if(IsClientInGame(i))
						{
							if(IsPlayerAlive(i))
							{
							centerHudText(i, message, 0.0, 5.0, HudMsg3, 0.42); 
							}
						}
					}
					
					new Handle:dataPack;
					CreateDataTimer(1.0, MeleeMode_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
					WritePackCell(dataPack, serverRolls_EndTime);//PackPosition(0) - Time to kill this timer
					WritePackCell(dataPack, GetTime());//PackPosition(8) - Time to kill this timer
					
					Disabled_Good_Commands[AWARD_G_SENTRYBUILDER] = 1;
					
					//disable sentries
					new String:classname[128];
					for(new i=1; i <= GetMaxEntities(); i++)
					{
						if(IsValidEdict(i))
						{
							if(IsValidEntity(i))
							{
								GetEdictClassname(i, classname, sizeof(classname));
								if(strcmp(classname, "obj_sentrygun") == 0)
								{
									SetEntProp(i, Prop_Send, "m_bDisabled", 1);
								}
							}
						}
					}
				}
			}
		}
		
		
		CloseHandle(serverRolls_Array);
	}
	
	return Plugin_Continue;
}

public Load_Saws(amountToSpawn)
{
	new totPlayers;
	new Handle: players_Array;
	players_Array = CreateArray(1,MaxClients);
	
	for(new i=1; i <= MaxClients; i++)
	{
		// Check to make sure the player is on the same team
		if(IsClientInGame(i))
		{
			if(IsPlayerAlive(i))
			{
				SetArrayCell(players_Array,totPlayers,i,0);
				totPlayers++;
			}
		}
	}
	
	if(amountToSpawn > totPlayers)
		amountToSpawn = totPlayers;
	
	/////////////////
	//Pick players //
	/////////////////
	new rndNum;
	for(new i=1; i <= amountToSpawn; i++)
	{
		rndNum = GetRandomInt(0, amountToSpawn-i);
		Spawn_Saw(GetArrayCell(players_Array, rndNum, 0));
		
		RemoveFromArray(players_Array,rndNum);
	}
	
	CloseHandle(players_Array);
}

public Action:BodySwap_Timer(Handle:timer, Handle:dataPackHandle)
{
	/////////////////////////////////
	//Round ended let's stop this! //
	/////////////////////////////////
	if(roundEnded)
		return Plugin_Stop;
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new endTime = ReadPackCell(dataPackHandle);
	new nextSwapTime = ReadPackCell(dataPackHandle);
	new interval = ReadPackCell(dataPackHandle);
	
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(GetTime() > endTime)
		return Plugin_Stop;
	
	//////////////////////////////////
	//Do we need to set off a bomb? //
	//////////////////////////////////
	if(GetTime() >= nextSwapTime)
	{
		SetPackPosition(dataPackHandle, 8);
		WritePackCell(dataPackHandle, GetTime() + interval);
	}else{
		return Plugin_Continue;
	}
	
	/////////////////////
	//Start swapping   //
	/////////////////////
	//Shake2(i, 0.5, 15.0);
	
	new totPlayers;
	new Handle: players_Array;
	new Handle: players_Array_Dupe;
	players_Array = CreateArray(1,MaxClients);
	players_Array_Dupe = CreateArray(1,MaxClients);
	
	for(new i=1; i <= MaxClients; i++)
	{
		// Check to make sure the player is on the same team
		if(IsClientInGame(i))
		{
			if(IsPlayerAlive(i))
			{
				SetArrayCell(players_Array,totPlayers,i,0);
				SetArrayCell(players_Array_Dupe,totPlayers,i,0);
				totPlayers++;
			}
		}
	}
	
	if(totPlayers < 2)
		return Plugin_Continue;
	
	/////////////////
	//Pick players //
	/////////////////
	new rndNum;
	new Float:pos[3];
	new pickedPlayer;
	new client;
	new totals = totPlayers-1;
	
	for(new i=0; i < totPlayers; i++)
	{
		client = GetArrayCell(players_Array, i, 0);
		rndNum = GetRandomInt(0, totals);
		
		pickedPlayer = GetArrayCell(players_Array_Dupe, rndNum, 0);
		
		totals --;
		RemoveFromArray(players_Array_Dupe,rndNum);
		
		if(client != pickedPlayer)
		{
			Shake2(client, 0.5, 15.0);
			EmitSoundToAll(SOUND_TELEPRE, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
			
			new Handle:message = StartMessageOne("Fade", client, 1);
			BfWriteShort(message, 285);
			BfWriteShort(message, 285);
			BfWriteShort(message, (0x0002));
			
			BfWriteByte(message, 255);
			BfWriteByte(message, 255);
			BfWriteByte(message, 255);
			
			BfWriteByte(message, 255);
			EndMessage();
			
			GetEntPropVector(pickedPlayer, Prop_Data, "m_vecOrigin", pos);
			
			
			new Handle:dataPack;
			CreateDataTimer(1.0, SwapClient,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
			WritePackCell(dataPack, client);
			WritePackFloat(dataPack, pos[0]);//PackPosition(0) - Time to kill this timer
			WritePackFloat(dataPack, pos[1]);//PackPosition(8) - last time a firebomb went off
			WritePackFloat(dataPack, pos[2]);//PackPosition(16) - interval between body swaps
		}
		
		
		//PrintToChatAll("Swapping %i with %i", client, pickedPlayer);
	}
	
	CloseHandle(players_Array);
	CloseHandle(players_Array_Dupe);
	
	return Plugin_Continue;
}

public Action:SwapClient(Handle:timer, Handle:dataPackHandle)
{
	ResetPack(dataPackHandle);
	new Float:pos[3];
	new client = ReadPackCell(dataPackHandle);
	pos[0] = ReadPackFloat(dataPackHandle);
	pos[1] = ReadPackFloat(dataPackHandle);
	pos[2] = ReadPackFloat(dataPackHandle);
	
	if(IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			//AttachTempParticle(client,"aurora_shockwave", 5.0, false,"",0.0, false);
			
			Shake2(client, 0.5, 15.0);
			EmitSoundToAll(SOUND_TELEPOST, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
			TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
		}
	}
	
	return Plugin_Stop;
	
}

public Action:HellsFiery_Timer(Handle:timer, Handle:dataPackHandle)
{
	/////////////////////////////////
	//Round ended let's stop this! //
	/////////////////////////////////
	if(roundEnded)
		return Plugin_Stop;
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new endTime = ReadPackCell(dataPackHandle);
	new nextBombTime = ReadPackCell(dataPackHandle);
	new interval = ReadPackCell(dataPackHandle);
	
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(GetTime() > endTime)
		return Plugin_Stop;
	
	//////////////////////////////////
	//Do we need to set off a bomb? //
	//////////////////////////////////
	if(GetTime() >= nextBombTime)
	{
		SetPackPosition(dataPackHandle, 8);
		WritePackCell(dataPackHandle, GetTime() + interval);
	}else{
		return Plugin_Continue;
	}
	
	////////////////////////////
	//Pick our lucky player   //
	////////////////////////////
	new Handle:players_Array;
	players_Array = CreateArray(1,MaxClients);
	new totPlayers;
	
	for(new i=1; i <= MaxClients; i++)
	{
		// Check to make sure the player is on the same team
		if(IsClientInGame(i))
		{
			if(IsPlayerAlive(i))
			{
				SetArrayCell(players_Array,totPlayers,i,0);
				totPlayers++;
			}
		}
	}
	
	new rndNum = GetRandomInt(0, totPlayers-1);
	new client = GetArrayCell(players_Array, rndNum, 0);
	CloseHandle(players_Array);
	
	Spawn_Fireball_HurtAll(client);
	
	return Plugin_Continue;
}

public Action:UpdateCabinets_Timer(Handle:timer, Handle:dataPackHandle)
{
	/////////////////////////////////
	//Round ended let's stop this! //
	/////////////////////////////////
	if(roundEnded)
	{
		UpdateHealthContainers(true);
		return Plugin_Stop;
	}
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new endTime = ReadPackCell(dataPackHandle);
	
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(GetTime() > endTime)
	{
		UpdateHealthContainers(true);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action:MeleeMode_Timer(Handle:timer, Handle:dataPackHandle)
{
	/////////////////////////////////
	//Round ended let's stop this! //
	/////////////////////////////////
	if(roundEnded)
	{
		GiveWeaponsBack();
		return Plugin_Stop;
	}
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new endTime = ReadPackCell(dataPackHandle);
	new nextSound = ReadPackCell(dataPackHandle);
	
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(GetTime() + 30 > endTime)
		PrintCenterTextAll("Melee mode will end in: %is", endTime + 1 - GetTime());
	
	if(GetTime() > endTime)
	{
		GiveWeaponsBack();
		return Plugin_Stop;
	}
	
	if(GetTime() > nextSound)
	{
		SetPackPosition(dataPackHandle, 8);
		WritePackCell(dataPackHandle, GetTime() + 15);
		
		for(new i=1; i <= MaxClients; i++)
		{
			// Check to make sure the player is on the same team
			if(IsClientInGame(i))
			{
				if(IsPlayerAlive(i))
				{
					EmitSoundToClient(i, SOUND_MELEE_MUSIC, i);
				}
			}
		}
	}
	
	//strip everyone to melee
	for(new i=1; i <= MaxClients; i++)
	{
		// Check to make sure the player is on the same team
		if(IsClientInGame(i))
		{
			if(IsPlayerAlive(i))
			{
				StripToMelee(i);
			}
		}
	}
	
	return Plugin_Continue;
}

stock GiveWeaponsBack()
{
	Disabled_Good_Commands[AWARD_G_SENTRYBUILDER] = 0;
	
	for(new i=1; i <= MaxClients; i++)
	{
		// Check to make sure the player is on the same team
		if(IsClientInGame(i))
		{
			if(IsPlayerAlive(i))
			{
				TF2_RegeneratePlayer(i);
				StopSound(i, SNDCHAN_AUTO, SOUND_MELEE_MUSIC);
				
			}
		}
	}
	
	new String:classname[128];
	for(new i=1; i <= GetMaxEntities(); i++)
	{
		if(IsValidEdict(i))
		{
			if(IsValidEntity(i))
			{
				GetEdictClassname(i, classname, sizeof(classname));
				if(strcmp(classname, "obj_sentrygun") == 0)
				{
					SetEntProp(i, Prop_Send, "m_bDisabled", 0);
				}
			}
		}
	}
}

stock UpdateHealthContainers(bool:enabled)
{
	new String:message[128];
	new String:sendState[32];
	new color;
	
	if(enabled)
	{
		Format(message, sizeof(message), "Health|Resupply Cabinets ENABLED!");
		Format(sendState, sizeof(sendState), "Enable");
		color = 255;
	}else{
		Format(message, sizeof(message), "Health|Resupply Cabinets DISABLED!");
		Format(sendState, sizeof(sendState), "Disable");
		color = 0;
	}
	
	//////////////////////////////
	//Disable resupply cabinets //
	//////////////////////////////
	new ent = -1;
	
	while ((ent = FindEntityByClassname(ent, "func_regenerate")) != -1)
	{
		AcceptEntityInput(ent,sendState);
	}
	
	//////////////////////
	//colorize lockers  //
	//////////////////////
	ent = -1;
	new String:modelname[128];
	
	while ((ent = FindEntityByClassname(ent, "prop_dynamic")) != -1)
	{
		GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 128);
		if (StrEqual(modelname, "models/props_gameplay/resupply_locker.mdl"))
		{
			SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
			SetEntityRenderColor(ent, color, color, color, 255);
		}
	}
	
	for(new i=1; i <= MaxClients; i++)
	{
		// Check to make sure the player is on the same team
		if(IsClientInGame(i))
		{
			if(IsPlayerAlive(i))
			{
				centerHudText(i, message, 0.0, 5.0, HudMsg3, 0.42); 
			}
		}
	}
}

public Action:GiveStuff_Timer(Handle:timer, Handle:dataPackHandle)
{
	/////////////////////////////////
	//Round ended let's stop this! //
	/////////////////////////////////
	if(roundEnded)
	{
		return Plugin_Stop;
	}
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new endTime = ReadPackCell(dataPackHandle);
	
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(GetTime() + 15 > endTime)
		PrintCenterTextAll("Super Buff will end in: %is", endTime + 1 - GetTime());
	
	//reset everyones stuff back to 0
	if(GetTime() > endTime)
	{
		for(new i=1; i <= MaxClients; i++)
		{
			// Check to make sure the player is on the same team
			if(IsClientInGame(i))
			{
				if(IsPlayerAlive(i))
				{
					SetEntityGravity(i, 1.0);
					UsingSpeed[i] = 0;
					ROFMult[i] = 1.0;
					UsingBerserker[i] = 0;
				}
			}
		}
		
		return Plugin_Stop;
	}
	
	for(new i=1; i <= MaxClients; i++)
	{
		// Check to make sure the player is on the same team
		if(IsClientInGame(i))
		{
			if(IsPlayerAlive(i))
			{
				SetEntityGravity(i, 0.6);
				UsingSpeed[i] = 1;
				ROFMult[i] = 1.5;
				UsingBerserker[i] = 1;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:SawSpawner_Timer(Handle:timer, Handle:dataPackHandle)
{
	/////////////////////////////////
	//Round ended let's stop this! //
	/////////////////////////////////
	if(roundEnded)
	{
		return Plugin_Stop;
	}
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new endTime = ReadPackCell(dataPackHandle);
	new nextSpawn = ReadPackCell(dataPackHandle);
	
	//reset everyones stuff back to 0
	if(GetTime() > endTime)
		return Plugin_Stop;
	
	if(nextSpawn < GetTime())
	{
		SetPackPosition(dataPackHandle, 8);
		WritePackCell(dataPackHandle,GetTime() + 28);
		Load_Saws(6);
	}
	
	return Plugin_Continue;
}

/*
public Action:ClassFavorites_Timer(Handle:timer, Handle:dataPackHandle)
{
	/////////////////////////////////
	//Round ended let's stop this! //
	/////////////////////////////////
	if(roundEnded)
	{
		return Plugin_Stop;
	}
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new endTime = ReadPackCell(dataPackHandle);
	
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(GetTime() + 15 > endTime)
		PrintCenterTextAll("Class Favorites will end in: %is", endTime + 1 - GetTime());
	
	//strip everyone to melee
	for(new i=1; i <= MaxClients; i++)
	{
		// Check to make sure the player is on the same team
		if(IsClientInGame(i))
		{
			if(IsPlayerAlive(i))
			{
				if(GetClientTeam(i) == BLUE_TEAM)
				{
					serverRolls_ClassWar[1]
					TF2_SetPlayerClass(i, TFClassType:class, bool:weapons=true, bool:persistant=true)
				}else{
					serverRolls_ClassWar[2]
				}
			}
		}
	}
	
	
	return Plugin_Continue;
}*/