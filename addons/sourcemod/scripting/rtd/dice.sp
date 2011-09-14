#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <rtd_rollinfo>

#define maxDice 450
new diceSpawnPoints[maxDice][3];
new spawnPointCount;
new spawnPointUsed[maxDice];
new spawnPointEnt[maxDice];
new diceSpawnLimit;


// ------------------------------------------------------------------------
// Item_ParseList()
// ------------------------------------------------------------------------
// Parse the items list and precache all the needed models through the
// dependencies file.
// ------------------------------------------------------------------------
Item_ParseList()
{
	decl String:currentMap[32];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	//LogToFile(logPath,"Current Map:%s",currentMap);
	
	// Parse the objects list key values text to acquire all the possible
	// wearable items.
	new Handle:kvItemList = CreateKeyValues("RTD_Dice_SpawnPoints");
	new String:strLocation[256];
	new String:strLine[256];
	new String:strMapName[32];
	spawnPointCount = 0;
	
	// Load the key files.
	new String:strLine2[256];
	Format(strLine2, sizeof(strLine2), "configs/rtd/dice_spawnpoints/%s.cfg",currentMap); 
	
	BuildPath(Path_SM, strLocation, 256, strLine2);
	FileToKeyValues(kvItemList, strLocation);
	
	// Check if the parsed values are correct
	if (!KvGotoFirstSubKey(kvItemList)) 
	{ 
		LogToFile(logPath,"Error, can't read file containing the spawn points : %s", strLocation);
		return; 
	}
	
	//Reset all previous values
	for(new i = 1; i <maxDice;i++)
	{
		spawnPointUsed[i] = -1;
		spawnPointEnt[i]  = -1;
	}
	
	// Iterate through all keys.
	do
	{
		// Retrieve section name, which would be the map name
		KvGetSectionName(kvItemList,       strMapName,  256);
		//LogToFile(logPath,"Name of Map in CFG: %s",strMapName);
		
		//The sectionName corresponds to the map that the server is currently playing
		if(StrEqual(currentMap,strMapName,false))
		{
			//LogToFile(logPath,"Loading Spawn Points for: %s",strMapName);
			//Ok we found our map now let's iterate through the spawnpoints
			
			//Now get the max number of dice allowed on the map
			KvGetString(kvItemList, "Amount of Dice to Spawn",   strLine, sizeof(strLine)); 
			
			diceSpawnLimit  = StringToInt(strLine);
			
			if(StrEqual(strLine,"all",false))
				diceSpawnLimit = -1;
			
			do
			{
				KvGotoFirstSubKey(kvItemList);
				
				if(spawnPointCount < maxDice)
				{
					KvGetString(kvItemList, "x",   strLine, sizeof(strLine)); diceSpawnPoints[spawnPointCount][0]   = StringToInt(strLine);
					KvGetString(kvItemList, "y",   strLine, sizeof(strLine)); diceSpawnPoints[spawnPointCount][1]   = StringToInt(strLine);
					KvGetString(kvItemList, "z",   strLine, sizeof(strLine)); diceSpawnPoints[spawnPointCount][2]   = StringToInt(strLine);
				}
				//LogToFile(logPath,"SpawnPoint Found: %i, %i, %i",diceSpawnPoints[spawnPointCount][0],diceSpawnPoints[spawnPointCount][1],diceSpawnPoints[spawnPointCount][2]);
				spawnPointCount ++;
			}
			 while (KvGotoNextKey(kvItemList));
		}
	}
	while (KvGotoNextKey(kvItemList));
	
	if(spawnPointCount >= maxDice)
		spawnPointCount = maxDice - 1;
	
	//PrintToChatAll("diceSpawnLimit:%i | dice_multiplier:%i",diceSpawnLimit,dice_multiplier);
	if((dice_multiplier * diceSpawnLimit) <= spawnPointCount && diceSpawnLimit > 0 && dice_multiplier != 0)
	{
		//LogToFile(logPath,"[RTD] Setting Dice spawn limit from %i to %i: DiceMultipler = %i",diceSpawnLimit, (diceSpawnLimit * dice_multiplier), dice_multiplier);
		diceSpawnLimit *= dice_multiplier;
	}else{
		//LogToFile(logPath,"[RTD] FAILED to set dice multiplier: %i | Total Spawnpoints: %i | Original Spawn limit: %i",dice_multiplier, spawnPointCount, diceSpawnLimit);
	}
	//PrintToChatAll("diceSpawnLimit:%i",diceSpawnLimit);
	
	if(diceSpawnLimit == -1 || GetConVarInt(c_Dice_Debug))
		diceSpawnLimit = spawnPointCount;
	
	PrintToServer("SpawnPoints Found: %i",spawnPointCount);
	//LogToFile(logPath,"SpawnPoints Found: %i",spawnPointCount);
	CloseHandle(kvItemList);    
	//LogToFile(logPath,"# FINISHED PARSING DICE SPAWN POINTS#");
}

stock SetupDiceSpawns(forceSpawn = false, count = -1)
{
	if (count == 0) return;
	
	removeAllDice();
	
	new randomSpawn;
	new playersFound;
	new Handle: spawnPointIndex;
	spawnPointIndex = CreateArray(1,349);
	
	for (new j = 1; j <= MaxClients ; j++)
	{
		if(IsClientInGame(j))
			playersFound ++;
	}
	
	for (new j = 0; j <= spawnPointCount ; j++)
		SetArrayCell(spawnPointIndex,j,j,0);
		
	
	if(forceSpawn || playersFound >= GetConVarInt(c_Dice_MinPlayers))
	{
		new diceToSpawn;
		
		//make sure the cfg file has more than 10 locations
		if(spawnPointCount > 10)
		{
			diceToSpawn = count < 0 ? diceSpawnLimit : count < spawnPointCount ? count : spawnPointCount;
			for(new i= 0; i <diceToSpawn;i++)
			{
				randomSpawn = GetRandomInt(1, spawnPointCount-i);
				
				new luckynumber = GetRandomInt(1, 100);
				if(luckynumber >= dice_RareSpawn)
					luckynumber = 0;
				SpawnDice(GetArrayCell(spawnPointIndex,randomSpawn,0), luckynumber);
				
				RemoveFromArray(spawnPointIndex,randomSpawn);
			}
		}
		
		if(diceToSpawn > 0)
		{
			diceNeeded = diceToSpawn;
			decl String:tense[32];
			
			if(diceToSpawn == 1)
			{
				Format(tense, sizeof(tense), "has");
			}else{
				Format(tense, sizeof(tense), "have");
			}
			
			PrintToChatAll("%i Dice %s spawned! Next respawn in %i minutes",diceToSpawn, tense, (dice_RespawnTime/60));
			
			decl String:message[200];
			Format(message, sizeof(message), "%i Dice %s spawned!",diceToSpawn, tense);
			
			diceOnMap = diceToSpawn;
			tf2_game_text(message, 8.0, diceOnMap);
		}
	}
	else
	{
		PrintToChatAll("Dice spawning disabled! Need at least %i players", GetConVarInt(c_Dice_MinPlayers));
	}
	
	CloseHandle(spawnPointIndex);
}

stock RespawnDisabledDice(any:amount)
{
	removeAllDice();
	
	new randomSpawn;
	new playersFound;
	new Handle: spawnPointIndex;
	spawnPointIndex = CreateArray(1,349);
	
	for (new j = 1; j <= MaxClients ; j++)
	{
		if(IsClientInGame(j))
			playersFound ++;
	}
	
	for (new j = 0; j <= spawnPointCount ; j++)
		SetArrayCell(spawnPointIndex,j,j,0);
		
	
	if(playersFound > 5)
	{
		//make sure the cfg file has more than 10 locations
		if(spawnPointCount > 10)
		{
			for(new i= 0; i <amount;i++)
			{
				randomSpawn = GetRandomInt(1, spawnPointCount-i);
				new luckynumber = GetRandomInt(1, 100);
				if(luckynumber >= dice_RareSpawn)
					luckynumber = 0;
				SpawnDice(GetArrayCell(spawnPointIndex,randomSpawn,0), luckynumber);
				
				RemoveFromArray(spawnPointIndex,randomSpawn);
			}
			
			decl String:message[200];
			if(amount > 1)
			{
				Format(message, sizeof(message), "%i Dice have been respawned!",amount);
				PrintToChatAll("%i Dice have been respawned!",amount);
			}else{
				Format(message, sizeof(message), "%i Dice has been respawned!",amount);
				PrintToChatAll("%i Dice has been respawned!",amount);
			}
			
			diceOnMap = amount;
			tf2_game_text(message, 8.0, amount);
			
		}
	}
	else
	{
		PrintToChatAll("Dice spawning disabled! Need at least 6 players");
	}
	
	CloseHandle(spawnPointIndex);
}

stock SpawnDice(i, spawnRare)
{
	new Float:vicorigvec[3];
	vicorigvec[0] = float(diceSpawnPoints[i][0]);
	vicorigvec[1] = float(diceSpawnPoints[i][1]);
	vicorigvec[2] = float(diceSpawnPoints[i][2]);
	
	new String:sModel[64];
	sModel = MODEL_DICE;
	new dice = CreateEntityByName("prop_dynamic_override");
	
	SetEntityModel(dice,sModel);
	DispatchSpawn(dice);
	TeleportEntity(dice, vicorigvec, NULL_VECTOR, NULL_VECTOR);
	
	SetVariantString("idle");
	AcceptEntityInput(dice, "SetAnimation", -1, -1, 0); 
	
	//Do not show particles if in Dice Debuggin mode
	if(GetConVarInt(c_Dice_Debug) == 0)
	{
		//parent the particle to the dice
		new String:tName[128];
		new particle = CreateEntityByName("info_particle_system");
		if (particle != -1)
		{
			TeleportEntity(particle, vicorigvec, NULL_VECTOR, NULL_VECTOR);
			
			Format(tName, sizeof(tName), "dice%i", dice);
			DispatchKeyValue(dice, "targetname", tName);
			
			DispatchKeyValue(particle, "targetname", "tf2particle");
			DispatchKeyValue(particle, "parentname", tName);
			if(spawnRare == 0)
				DispatchKeyValue(particle, "effect_name", "critical_rocket_blue");
			else
				DispatchKeyValue(particle, "effect_name", "critical_rocket_red");
			
			DispatchSpawn(particle);
			
			SetVariantString(tName);
			AcceptEntityInput(particle, "SetParent", particle, particle, 0);
			
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");
		}
		
		//Prevent pickup when diceSpawnlimit is set to "all"
		//this is easier for dice seeding without accidently picking them up
		if(diceSpawnLimit != spawnPointCount)
		{
			//Set up the dice Touch timer
			new Handle:dataPackHandle;
			CreateDataTimer(0.1, diceTouch_Timer, dataPackHandle, TIMER_REPEAT |TIMER_FLAG_NO_MAPCHANGE);
			
			//Setup the datapack with appropriate information
			WritePackCell(dataPackHandle, dice);   //PackPosition(0); Dice Entity
			WritePackCell(dataPackHandle, GetTime());     //PackPosition(8);  Current Time
			WritePackCell(dataPackHandle, spawnRare);
		}
	}
	
	killEntityIn(dice, 599.0);
}

public Action:diceTouch_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopDiceTouchTimer(dataPackHandle))
		return Plugin_Stop;
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new dice = ReadPackCell(dataPackHandle);
	ReadPackCell(dataPackHandle);//Simple way to Skip ahead to next field
	new rareSpawn = ReadPackCell(dataPackHandle);
	
	new Float: clientEyePos[3];
	new Float: clientFeetPos[3];
	new Float: dicePos[3];
	new Float: distanceFromEye;
	new Float: distanceFromFeet;
	
	GetEntPropVector(dice, Prop_Send, "m_vecOrigin", dicePos);
	
	for(new client=1; client <= MaxClients; client++)
	{
		//player is not here let's skip
		if (!IsClientInGame(client) || !IsPlayerAlive(client))
			continue;
		
		//Get the player's postion
		GetClientEyePosition(client, clientEyePos); 
		GetClientAbsOrigin(client, clientFeetPos);
		
		distanceFromEye = GetVectorDistance(clientEyePos, dicePos);
		distanceFromFeet = GetVectorDistance(clientFeetPos, dicePos);
		
		if(distanceFromEye < 70.0 || distanceFromFeet < 50.0)
		{
			//used if player found a dice on round end
			diceNeeded --;
			if(rareSpawn == 0) {
				addDice(client, 0, 1);
			} else {
				addDice(client, 0, 5);
			}
			
			AcceptEntityInput(dice,"kill");
			
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

public stopDiceTouchTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new dice = ReadPackCell(dataPackHandle);
	new spawnedTime = ReadPackCell(dataPackHandle);
	
	if(!IsValidEntity(dice))
		return true;
	
	//Has the 10 minutes passed?
	if((GetTime() - spawnedTime) > 599)
	{
		AcceptEntityInput(dice,"kill");
		return true;
	}
	
	new currIndex = GetEntProp(dice, Prop_Data, "m_nModelIndex");
	
	if(currIndex != diceModelIndex)
		return true;
	
	return false;
}

public Action:ShowDiceStatus(client)
{
	new String:nextSkill[128];
	new nextDiceSpawnTimeMin;
	new String:nextDiceSpawnTimeSec[3];
	new nextDiceSpawn;
	new nextLevel;
	
	nextLevel = RoundToCeil(float(RTDdice[client]+1)/200.0) * 200;
	
	if(nextLevel == 0)
		nextLevel = 200;
	
	//Load attributes
	new i = 0;
	for(i = 0; i <= totalDicePerks; i++)
	{
		//find 1st perk that is more than dice
		if(RTDdice[client] < dicePerk_need[i])
		{
			Format(nextSkill, 128, "[%i]| %s:%s",dicePerk_need[i], dicePerk_title[i],dicePerk_info[i]);
			break;
		}
	}
	
	nextDiceSpawn = (timeOfLastDiceSpawn + dice_RespawnTime) - GetTime();
	
	nextDiceSpawnTimeMin = nextDiceSpawn / 60; //Minutes Left
	
	IntToString((nextDiceSpawn - (nextDiceSpawnTimeMin * 60)), nextDiceSpawnTimeSec, sizeof(nextDiceSpawnTimeSec)); //Seconds Left
	if(strlen(nextDiceSpawnTimeSec) == 1)
	{
		Format(nextDiceSpawnTimeSec, sizeof(nextDiceSpawnTimeSec), "0%s", nextDiceSpawnTimeSec);
	}
	
	new String:message01[64];
	new String:message02[64];
	new String:message03[64];
	new String:message05[64];
	new String:message07[64];
	new String:message08[64];
	new String:message09[64];
	new String:message10[64];
	new String:message11[64];
	
	new diceLevel = RoundToFloor(RTDdice[client]/200.0);
	
	Format(message01, sizeof(message01), "    Active Dice: %i/%i", diceOnMap,diceSpawnLimit);
	Format(message02, sizeof(message02), "    Next Dice Spawn: %d:%s", nextDiceSpawnTimeMin, nextDiceSpawnTimeSec);
	Format(message03, sizeof(message03), "    Dice Found: %i", RTDdice[client]);
	Format(message10, sizeof(message10), "    Dice Level: %i", diceLevel);
	Format(message11, sizeof(message11), "    Mining Bonus: +%i%", RTD_Perks[client][16] + RTD_TrinketBonus[client][TRINKET_DICEMINER] - 5);
	
	
	
	Format(message07, sizeof(message07), "    Chance for Good Roll: %i\%%",RoundFloat(GetConVarFloat(c_Chance)*100.0) + RTD_Perks[client][1] + RTD_Perks[client][21] + RTD_TrinketBonus[client][TRINKET_LADYLUCK]);
	Format(message08, sizeof(message08), "    Time reduction/point: %is",RTD_Perks[client][0]);
	
	Format(message05, sizeof(message05), "    Next level at: %i Dice", nextLevel);
	Format(message09, sizeof(message09), "    Talent Points: %i", talentPoints[client]);
	
	new Handle:hMenu = CreatePanel();
	
	DrawPanelItem(hMenu, "Dice Information");
	DrawPanelText(hMenu, message01);
	DrawPanelText(hMenu, message02);
	
	DrawPanelItem(hMenu, "notext",ITEMDRAW_SPACER);
	DrawPanelItem(hMenu, "Dice Experience");
	DrawPanelText(hMenu, message10); //dice level
	DrawPanelText(hMenu, message03); //dice found
	DrawPanelText(hMenu, message05); //next level up
	DrawPanelText(hMenu, message09); //talent points - dice points
	
	
	DrawPanelItem(hMenu, "notext",ITEMDRAW_SPACER);
	DrawPanelItem(hMenu, "RTD Stats:");
	DrawPanelText(hMenu, message07);
	DrawPanelText(hMenu, message08);
	DrawPanelText(hMenu, message11); //chance to mine dice
	
	SendPanelToClient(hMenu, client, dice_MenuHandler, 20);
	CloseHandle(hMenu);
	
	new String: playerName[32];
	GetClientName(client, playerName, sizeof(playerName));
	
	PrintToChatAll("%s has \x03%i\x04 dice.", playerName, RTDdice[client]);
}

stock removeAllDice()
{
	new dice = -1;
	while ((dice = FindEntityByClassname(dice, "prop_dynamic")) != -1)
	{
		if(GetEntProp(dice, Prop_Data, "m_nModelIndex") == diceModelIndex)
		{
			AcceptEntityInput(dice,"kill");
		}
	}
	
	diceOnMap = 0;
}

public Action:SpawnDice_Timer(Handle:Timer)
{
	///////////////////////////////////////////
	//Has enough time passed to spawn dice?  //
	///////////////////////////////////////////
	if(!((GetTime() - timeOfLastDiceSpawn) > dice_RespawnTime))
		return Plugin_Continue;
	
	//skip dice functions if in classic
	if(rtd_classic)
		return Plugin_Continue;
	
	///////////////////////////////////////////
	//Dice have just been respawned, so save //
	//the time they got spawned              //
	///////////////////////////////////////////
	timeOfLastDiceSpawn = GetTime();
	
	
	removeAllDice();
	
	if(roundEnded || GameRules_GetProp("m_bInSetup", 4, 0))
	{
		diceNeeded = diceSpawnLimit;
		return Plugin_Continue;
	}
	
	new playersFound;
	
	for (new j = 1; j <= MaxClients ; j++)
	{
		if(IsClientInGame(j))
			playersFound ++;
	}
	
	if(playersFound < dice_MinPlayers)
	{
		PrintToChatAll("Not enough players to spawn dice! Require: %i players", dice_MinPlayers);
		return Plugin_Continue;
	}
	
	//----------------Load CFG for DICE spawn points-----------------------
	if(spawnPointCount < 1)
	{
		Item_ParseList();
	}
	else
	{
		//Reset all previous values
		for(new i = 1; i <maxDice;i++)
		{
			spawnPointUsed[i] = -1;
			spawnPointEnt[i]  = -1;
		}
	}
	SetupDiceSpawns();
	
	
	return Plugin_Continue;
}

public dice_MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action) 
	{
		case MenuAction_Select: 
		{
		}
	
		case MenuAction_Cancel: {
		}

		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public Action:removeOneDice(Handle:timer, any:i)
{
	if(IsValidEdict(spawnPointEnt[i]))
	{
		RemoveEdict(spawnPointEnt[i]);
		spawnPointUsed[i] = 0;
		spawnPointEnt[i]  = -1;
	}
}

public Action:startDiceAchievement(Handle:timer, Handle:dataPackHandle)
{
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new client = ReadPackCell(dataPackHandle);
	new spawnTime = ReadPackCell(dataPackHandle);
	new maxLiveTime = ReadPackCell(dataPackHandle);
	new lastParticlesTime = ReadPackCell(dataPackHandle);
	new incr = ReadPackCell(dataPackHandle);
	
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	if(GetTime() >= spawnTime + maxLiveTime)
		return Plugin_Stop;
	
	incr ++;
	
	if(incr > 3)
	{	
		incr = 0;
		
		AttachTempParticle(client,"bday_confetti",2.0, false,"",0.0, false);
		AttachTempParticle(client,"bday_balloon02",2.0, false,"",0.0, false);
		AttachTempParticle(client,"bday_balloon02",2.0, false,"",0.0, false);
	}
	SetPackPosition(dataPackHandle, 32);
	WritePackCell(dataPackHandle, incr);
	
	if(GetTime() >= lastParticlesTime + 5)
	{
		SetPackPosition(dataPackHandle, 24);
		WritePackCell(dataPackHandle, GetTime());
		
		EmitSoundToAll(DiceFound, client);
	}
	
	
	return Plugin_Continue;
}

public Action:addDice(any:client, any:typeOfFind, any:amountOfDice)
{
	//typeOfFind = 0 | Player found a dice
	//typeOfFind = 1 | Player earned a dice through MVP
	//typeOfFind = 2 | Player bought a dice
	//typeOfFind = 3 | Player reddemed a dice through a special event
	//typeOfFind = 4 | Player earned a dice through MVP LOSING TEAM
	//typeOfFind = 5 | Player earned a dice through Dice Deposit
	//typeOfFind = 6 | Player earned dice through the marked murderer roll
	//amountOfDice = amount of dice to award player
	
	//special case when round wins and no player was found
	if(client < 1)
		return;
	
	if(amountOfDice < 1)
		return;
	
	new currentLevel = RoundToFloor(RTDdice[client]/200.0);
	new newLevel =  RoundToFloor(float(RTDdice[client]+amountOfDice)/200.0);
	new amountOfGainedLevels = newLevel - currentLevel;
	
	RTDdice[client] += amountOfDice;
	
	//Lets try to save dice each time to prevent losses
	//save all stats to the MySql server
	if(IsClientInGame(client) && areStatsLoaded[client] && g_BCONNECTED)
	{
		new String:clsteamId[MAX_LINE_WIDTH];
		if(IsFakeClient(client))
		{
			GetClientName(client, clsteamId, sizeof(clsteamId));
		}else{
			GetClientAuthString(client, clsteamId, sizeof(clsteamId));
		}
		
		saveStats(client);
	}
	
	updatePerksOnClient(client);
	
	SetHudTextParams(0.38, 0.49, 10.0, 255, 250, 255, 255);
	ShowHudText(client, HudMsg6, "You now have %i DICE", RTDdice[client]);
	
	new String:zname[32];
	GetClientName(client, zname, sizeof(zname));
	
	new String:nextSkill[64];
	new String:lvlAttained[64];
	
	nextSkill = "none";
	
	
	if(amountOfGainedLevels > 0)
	{
		talentPoints[client] += (amountOfGainedLevels * 2);
		
		ShowOverlay(client, "rtdgaming/levelup", 10.0);
		
		PrintToChatAll("\x01%s\x04 has reached Level \x03%i\x04 | Total Talent Points:\x03%i", zname,newLevel,talentPoints[client]);
		
		
		//The Datapack stores all the Mine's important values
		new Handle:dataPackHandle;
		CreateDataTimer(0.1, startDiceAchievement, dataPackHandle, TIMER_REPEAT |TIMER_FLAG_NO_MAPCHANGE);
		
		//Setup the datapack with appropriate information
		WritePackCell(dataPackHandle, client);   //PackPosition(0); Bomb Index
		WritePackCell(dataPackHandle, GetTime());   //PackPosition(8); Bomb Index
		WritePackCell(dataPackHandle, 30);   //PackPosition(16); Max live time in seconds
		WritePackCell(dataPackHandle, GetTime());   //PackPosition(24); This is to repeat sounds and stuff every 5 seconds
		WritePackCell(dataPackHandle, 0);   //PackPosition(32); This is to repeat sounds and stuff every 5 seconds
		EmitSoundToAll(DiceFound, client);
	}
	
	
	if(!StrEqual(nextSkill,"none"))
	{
		PrintToChatAll("\x01%s\x04 has achieved \x03%s\x04. Skill:\x03%s", zname,lvlAttained,nextSkill);
		
		
		//The Datapack stores all the Mine's important values
		new Handle:dataPackHandle;
		CreateDataTimer(0.1, startDiceAchievement, dataPackHandle, TIMER_REPEAT |TIMER_FLAG_NO_MAPCHANGE);
		
		//Setup the datapack with appropriate information
		WritePackCell(dataPackHandle, client);   //PackPosition(0); Bomb Index
		WritePackCell(dataPackHandle, GetTime());   //PackPosition(8); Bomb Index
		WritePackCell(dataPackHandle, 30);   //PackPosition(16); Max live time in seconds
		WritePackCell(dataPackHandle, GetTime());   //PackPosition(24); This is to repeat sounds and stuff every 5 seconds
		WritePackCell(dataPackHandle, 0);   //PackPosition(32); This is to repeat sounds and stuff every 5 seconds
		EmitSoundToAll(DiceFound, client);
	}else{
		EmitSoundToAll(DiceFound, client);
	}
	
	if(typeOfFind == 0)
	{
		PrintToChatAll("\x01%s\x04 now has \x01%i\x04 DICE! ", zname,RTDdice[client]); 
		
		decl String:message[200];
		
		diceOnMap --;
		
		if(diceOnMap > 0)
		{
			Format(message, sizeof(message), "%i Dice left!",diceOnMap);
		}else{
			Format(message, sizeof(message), "Last Dice found!");
		}
		
		tf2_game_text(message, 6.0, diceOnMap);
	}
	else if(typeOfFind == 1)
	{
		SetHudTextParams(0.38, 0.49, 10.0, 255, 250, 255, 255);
		ShowHudText(client, HudMsg6, "[MVP] You earned %i DICE!", amountOfDice);
		
		PrintToChatAll("\x01%s\x04 has EARNED \x01%i\x04 DICE!", zname,amountOfDice); 
	}
	else if(typeOfFind == 2)
	{
		PrintToChatAll("\x01%s\x04 has BOUGHT \x01%i\x04 DICE!", zname,amountOfDice); 
	}
	else if(typeOfFind == 3)
	{
		PrintToChatAll("\x01%s\x04 has REDEEMED \x01%i\x04 DICE through a special event!!", zname,amountOfDice); 
	}
	else if(typeOfFind == 4)
	{
		PrintToChatAll("\x04MVP on losing team: \x01%s\x04 has EARNED \x01%i\x04 DICE!", zname,amountOfDice); 
	}
	else if(typeOfFind == 5)
	{
		PrintToChat(client, "\x01%s\x04 has MINED \x01%i\x04 DICE!", zname,amountOfDice); 
	}
	else if(typeOfFind == 6)
	{
		PrintToChatAll("\x01%s\x04 earned \x01%i\x04 DICE through the Marked Murderer roll!", zname,amountOfDice); 
	}
	
	if(typeOfFind != 2)
	{
		//reward the player for finding a Dice
		new Handle:dataPack;
		CreateDataTimer(1.0,giveCrits_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
		WritePackCell(dataPack, client);
		WritePackCell(dataPack, 0); //starting time
		WritePackCell(dataPack, 10); //max time
		TF_SpawnTempMedipack(client, "item_healthkit_full");
		TF_SpawnTempMedipack(client, "item_ammopack_full");
	}
}

public Action:BuyDice(client)
{
	new Handle:hMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_DiceMenuHandler);
	
	SetMenuTitle(hMenu,"Purchase DICE");
	
	AddMenuItem(hMenu,"Option 1","1 Dice for 50 Creds");
	AddMenuItem(hMenu,"Option 1","2 Dice for 100 Creds");
	AddMenuItem(hMenu,"Option 1","3 Dice for 150 Creds");
	AddMenuItem(hMenu,"Option 1","4 Dice for 200 Creds");
	AddMenuItem(hMenu,"Option 1","5 Dice for 250 Creds");
	AddMenuItem(hMenu,"Option 1","6 Dice for 300 Creds");
	
	DisplayMenu(hMenu,client,MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public fn_DiceMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action) 
	{
		case MenuAction_Select: 
		{
			new String:name[32];
			GetClientName(param1, name, sizeof(name));
			
			new cost = 50 * (param2 + 1) ;
			if(RTDCredits[param1] >= cost)
			{
				if(shop_discount != 0)
				{
					//PrintToChatAll("Cost %d | Shop Discount %f | Cost After %d", cost, shop_discount, RoundToFloor(cost * shop_discount));
					cost = RoundToFloor(cost * shop_discount);
				}
				RTDCredits[param1] -= cost;
				addDice(param1, 2, param2 + 1);
			}else{
				PrintCenterText(param1, "You do not have enough CREDITS");
				PrintToChat(param1, "You do have enough CREDITS!");
			}
		}
	
		case MenuAction_Cancel: {
		}

		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

show_newUser_TalentPoints_msg(client)
{
	showStartupMsg[client] = false;
	
	///////////////////////////////////////////////////
	//Finally! The player has chosen a class         //
	//so we can now load the default Dice Perks and  //
	//inform the user of the new stuff!              //
	///////////////////////////////////////////////////
	updatePerksOnClient(client);
	
	new String:message01[64];
	new String:message02[64];
	new String:message03[64];
	new String:message04[64];
	
	new nextLevel;
	
	nextLevel = RoundToCeil(float(RTDdice[client]+1)/200.0) * 200;
	
	if(nextLevel == 0)
		nextLevel = 200;
	
	new Handle:hMenu = CreatePanel();
	
	
	new diceLevel = RoundToFloor(RTDdice[client]/200.0);
	
	talentPoints[client] = diceLevel * 2;
	
	Format(message01, sizeof(message01), "    Dice Found: %i", RTDdice[client]);
	Format(message02, sizeof(message02), "    Dice Level: %i", diceLevel);
	Format(message03, sizeof(message03), "    Next Level Up: %i Dice", nextLevel);
	Format(message04, sizeof(message04), "    Talent Points: %i", talentPoints[client]);
	
	DrawPanelItem(hMenu, "New Feature: Dice Perks");
	DrawPanelText(hMenu, "    Dice Perks allow you to choose the perks that you want.");
	DrawPanelText(hMenu, "    PERKS are purchased with TALENT POINTS");
	DrawPanelText(hMenu, "    2 TALENT POINTS are earned on every Level Up");
	DrawPanelItem(hMenu, "notext",ITEMDRAW_SPACER);
	DrawPanelText(hMenu, "    Purchase Dice Perks through the shop"); 
	
	DrawPanelItem(hMenu, "notext",ITEMDRAW_SPACER);
	DrawPanelItem(hMenu, "Dice Experience:");
	DrawPanelText(hMenu, message01);
	DrawPanelText(hMenu, message02);
	DrawPanelText(hMenu, message03);
	DrawPanelText(hMenu, message04);
	
	SendPanelToClient(hMenu, client, emptyPanelHandler, 50);
	CloseHandle(hMenu);
	
	ShowOverlay(client, "rtdgaming/welcomediceperks", 10.0);
	
}

showWelcomeBackPanel(client)
{
	showStartupMsg[client] = false;
	
	updatePerksOnClient(client);
	
	///////////////////////////////////////////////////
	//Finally! The player has chosen a class         //
	//so we can now show the Beta Panel              //
	///////////////////////////////////////////////////
	new String:message01[64];
	new String:message02[64];
	new String:message03[64];
	new String:message04[64];
	new String:message05[64];
	
	new nextLevel;
	nextLevel = RoundToCeil(float(RTDdice[client]+1)/200.0) * 200;
	
	if(nextLevel == 0)
		nextLevel = 200;
	
	new diceLevel = RoundToFloor(RTDdice[client]/200.0);
	
	new Handle:hMenu = CreatePanel();
	SetPanelTitle(hMenu, "Welcome Back");
	
	Format(message01, sizeof(message01), "    Dice Found: %i", RTDdice[client]);
	Format(message02, sizeof(message02), "    Dice Level: %i", diceLevel);
	Format(message03, sizeof(message03), "    Next Level Up: %i Dice", nextLevel);
	Format(message04, sizeof(message04), "    Talent Points: %i", talentPoints[client]);
	
	if(talentPoints[client] > 0)
	{
		Format(message05, sizeof(message05), "You have %i unused Talent Points!", talentPoints[client]);
		
		DrawPanelItem(hMenu, "Hey!");
		DrawPanelText(hMenu, "    You have unused Talent Points!");
		DrawPanelText(hMenu, "    Talent Points are used to purchase Perks!");
		DrawPanelText(hMenu, "    Purchase Dice Perks through the shop"); 
		DrawPanelItem(hMenu, "notext",ITEMDRAW_SPACER);
		
		centerHudText(client, message05, 0.0, 4.0, HudMsg3, 0.65); 
	}
	
	DrawPanelItem(hMenu, "Dice Experience:");
	DrawPanelText(hMenu, message01);
	DrawPanelText(hMenu, message02);
	DrawPanelText(hMenu, message03);
	DrawPanelText(hMenu, message04);
	
	SendPanelToClient(hMenu, client, emptyPanelHandler, 40);
	CloseHandle(hMenu);
	
}

public emptyPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}