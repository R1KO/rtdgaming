#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2>
#include <rtd_rollinfo>

stock bool:ForceRTD(client)
{
	// Check to see if client is valid
	if(client <= 0 || !IsClientConnected(client)) return false;	
	
	// Check to see if the person is already rtd'ing
	if(inTimerBasedRoll[client])	return false;
	
	if(!IsPlayerAlive(client)) return false;
	
	new bool:success = RollTheDice(client);
	
	if(!success)
		return false;
	
	return true;
}

public Action:Command_rtdadmin(client, args)
{
	//check to see if client is a "Full GameAdmin"
	if(!CheckAdminFlagsByString(client, "z"))
	{
		//is the admin menu disabled?
		if(!allowRTDAdminMenu)
		{
			//Limited admin menu
			SetupBasicAdminMenu(client);
			
			//PrintToChat(client, "RTD Admin menu is DISABLED! If on local add 'sm_rtd_admin_menu 1' to your server.cfg");
			//PrintCenterText(client, "RTD Admin Menu is DISABLED!");
			//PrintHintText(client, "RTD Admin Menu is DISABLED!");
			return Plugin_Handled;
		}
	}
	
	decl String:strMessage[128];
	GetCmdArg(1, strMessage, sizeof(strMessage));
	new String:adminName[128];
	GetClientName(client, adminName, sizeof(adminName));
	
	if(StrEqual("givedice", strMessage, false))
	{
		SetupGenericMenu(3, client);
		return Plugin_Handled;
	}
	else if(StrEqual("givecredits", strMessage, false))
	{
		SetupGenericMenu(2, client);
		return Plugin_Handled;
	}
	else if(StrEqual("teleportplayer", strMessage, false))
	{
		SetupGenericMenu(5, client);
		return Plugin_Handled;
	}
	else if(StrEqual("eggme", strMessage, false))
	{
		Yoshi_Eat(client, client);
		return Plugin_Handled;
	}
	else if(StrEqual("time", strMessage, false))
	{
		decl String:typeArg[64];
		GetCmdArg(2, typeArg, sizeof(typeArg));
		
		decl String:timeArg[64];
		GetCmdArg(3, timeArg, sizeof(timeArg));
		if (StrEqual("", timeArg, false)) {
			PrintToChat(client, "You must specify a time value as the third parameter.");
			return Plugin_Handled;
		}
		new timeVal = StringToInt(timeArg);
		
		//Alright, now the actual logic made by bl4nk to change the time
		if (StrEqual("add", typeArg, false)) {
			Round_AddTime(timeVal);
		} else if (StrEqual("sub", typeArg, false)) {
			Round_AddTime(-timeVal);
		} else if (StrEqual("set", typeArg, false)) {
			Round_SetTime(timeVal);
		} else {
			PrintToChat(client, "You must specify (add|rem|set) as the second parameter.");
		}
		return Plugin_Handled;		
	}
	else if (StrEqual("invis", strMessage, false))
	{
		decl String:actionArg[64];
		GetCmdArg(2, actionArg, sizeof(actionArg));
		if (StrEqual("true", actionArg, false)) {
			Colorize(client, INVIS);
			InvisibleHideFixes(client, TF2_GetPlayerClass(client), 0);
		} else if (StrEqual("false", actionArg, false)) {
			Colorize(client, NORMAL);
			InvisibleHideFixes(client, TF2_GetPlayerClass(client), 1);
		} else {
			PrintToChat(client, "You must supply an argument of \"true\" or \"false\" for that command");
		}
		return Plugin_Handled;
	}
	else if(StrEqual("award", strMessage, false))
	{
		decl String:roll_arg[64];
		GetCmdArg(2, roll_arg, sizeof(roll_arg));
		if (StrEqual("", roll_arg, false)) {
			SetupAwardMenu(client);
			return Plugin_Handled;
		}
		new roll = StringToInt(roll_arg);
		
		// Check if the admin wants to apply it to another player(s)
		decl String:playersArg[64];
		GetCmdArg(3, playersArg, sizeof(playersArg));
		
		decl String:forceArg[64];
		GetCmdArg(4, forceArg, sizeof(forceArg));
		new bool:forceRoll = StrEqual(forceArg, "true", false);
		
		//If they want to apply it to all players
		if (StrEqual("*", playersArg, false))
		{
			for(new i=1;i<=MaxClients;i++)
				if(IsValidClient(i) && IsPlayerAlive(i) && (forceRoll || !UnAcceptable(i, roll) && !inTimerBasedRoll[i]))
					GivePlayerEffect(i, roll, 0);
			LogToFile(logPath,"[RTD][ADMIN] %s awarded everyone %s", adminName, roll_Text[roll]);
			PrintToChatAll("[RTD][ADMIN] %s gave everyone %s", adminName, roll_Text[roll]);
		}
		else if (!StrEqual("", playersArg, false)) //They want to apply to some players
		{
			decl String:target_name[MAX_TARGET_LENGTH];
			decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
			if ((target_count = ProcessTargetString(
					playersArg,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
			{
				PrintToChat(client, "Couldn't match any players for the roll awardment.");
				return Plugin_Handled;
			}
			
			for (new i = 0; i < target_count; i++)
				if (IsValidClient(target_list[i]) && IsPlayerAlive(target_list[i]) && (forceRoll || !UnAcceptable(target_list[i], roll) && !inTimerBasedRoll[target_list[i]])) {
					GivePlayerEffect(target_list[i], roll, 0);
					LogToFile(logPath,"[RTD][ADMIN] %s awarded %s to %s", adminName, roll_Text[roll], target_name[i]);
					PrintToChat(target_list[i], "[RTD][ADMIN] %s gave you %s", adminName, roll_Text[roll]);
				}
		}
		else if (IsValidClient(client) && IsPlayerAlive(client) && (forceRoll || !UnAcceptable(client, roll) && !inTimerBasedRoll[client]))//Apply to themselves
		{
			LogToFile(logPath,"[RTD][ADMIN] %s was awarded %s", adminName, roll_Text[roll]);
			GivePlayerEffect(client, roll, 0);
		}
		
		return Plugin_Handled;
	}
	else if(StrEqual("resetcolor", strMessage, false))
	{
		// Check if the admin wants to apply it to another player(s)
		decl String:playersArg[64];
		GetCmdArg(2, playersArg, sizeof(playersArg));
		
		//If they want to apply it to all players
		if (StrEqual("*", playersArg, false))
		{
			for(new i=1;i<=MaxClients;i++)
				if(IsValidClient(i) && IsPlayerAlive(i))
					Colorize(i, NORMAL);
		}
		else if (!StrEqual("", playersArg, false)) //They want to apply to some players
		{
			decl String:target_name[MAX_TARGET_LENGTH];
			decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
			if ((target_count = ProcessTargetString(
					playersArg,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
			{
				PrintToChat(client, "Couldn't match any players for the roll awardment.");
				return Plugin_Handled;
			}
			
			for (new i = 0; i < target_count; i++)
				if (IsValidClient(target_list[i]) && IsPlayerAlive(target_list[i]))
					Colorize(target_list[i], NORMAL);
		}
		else if (IsValidClient(client) && IsPlayerAlive(client))//Apply to themselves
			Colorize(client, NORMAL);
		
		return Plugin_Handled;
	}
	else if(StrEqual("spawndice", strMessage, false))
	{
		decl String:arg[128];
		GetCmdArg(2, arg, sizeof(arg));
		new bool:force = StrEqual("true", arg, false);
		
		GetCmdArg(3, arg, sizeof(arg));		
		new amount = StrEqual("", arg, false) ? -1 : StringToInt(arg);
		if (amount == 0) {
			PrintToChat(client, "No dice were spawned since %s was interpreted as 0.", arg);
			return Plugin_Handled;
		}
		
		Item_ParseList();
		SetupDiceSpawns(force, amount);
		timeOfLastDiceSpawn = GetTime();
		//CreateTimer(1.0, SpawnDice_Timer);
		if (amount == -1)
			LogToFile(logPath,"[RTD][ADMIN] %s Respawned Dice", adminName);
		else
			LogToFile(logPath,"[RTD][ADMIN] %s Respawned %d Dice", adminName, amount);
		return Plugin_Handled;
	}
	else if(StrEqual("info", strMessage, false))
	{
		SetupGenericMenu(4, client);
		return Plugin_Handled;
	}
	else if(StrEqual("setdice", strMessage, false))
	{
		new String:diceAdd[12];
		GetCmdArg(2, diceAdd, sizeof(diceAdd));
		new diceAddAmount = StringToInt(diceAdd);
		RTDdice[client] = diceAddAmount;
		LogToFile(logPath,"[RTD][ADMIN] %s's Dice was Set to %d", adminName, diceAddAmount);
		return Plugin_Handled;
	}
	else if(StrEqual("equip", strMessage, false))
	{
		new String:equipArgs[128];
		GetCmdArg(2, equipArgs, sizeof(equipArgs));
		
		PrintToChat(client, "\x01\x04[RTD][ADMIN] Equip \x03%s\x04 with \x03%s", adminName, equipArgs);
		LogToFile(logPath,"[RTD][ADMIN]  Equip %s with %s", adminName, equipArgs);
		ServerCommand("equip_weapon \"%s\" %s", adminName, equipArgs);
		return Plugin_Handled;
	}
	else if(StrEqual("addcond", strMessage, false) || StrEqual("remcond", strMessage, false))
	{
		//Are we adding or removing it?
		new bool:adding = StrEqual("addcond", strMessage, false);
	
		decl String:condStrValue[128];
		GetCmdArg(2, condStrValue, sizeof(condStrValue));
		new condValue = StringToInt(condStrValue);
	
		// Check if the admin wants to apply it to another player(s)
		decl String:playersArg[64];
		GetCmdArg(3, playersArg, sizeof(playersArg));
		
		//If they want to apply it to all players
		if (StrEqual("*", playersArg, false))
		{
			for(new i=1;i<=MaxClients;i++)
				if(IsValidClient(i) && IsPlayerAlive(i))
					TF2_DoCond(i, condValue, adding);
			LogToFile(logPath,"[RTD][ADMIN] %s %s everyone condition %d", adminName, adding ? "added to" : "removed from", condValue);
			PrintToChatAll("\x01\x04[RTD][ADMIN] %s did something to everyone!", adminName);
		}
		else if (!StrEqual("", playersArg, false)) //They want to apply to some players
		{
			decl String:target_name[MAX_TARGET_LENGTH];
			decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
			if ((target_count = ProcessTargetString(
					playersArg,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
			{
				PrintToChat(client, "Couldn't match any players for the condition awardment.");
				return Plugin_Handled;
			}
			
			for (new i = 0; i < target_count; i++)
				if (IsValidClient(target_list[i]) && IsPlayerAlive(target_list[i])) {
					TF2_DoCond(target_list[i], condValue, adding);
					LogToFile(logPath,"[RTD][ADMIN] %s %s %s condition %d", adminName, adding ? "added to" : "removed from", target_name[i], condValue);
					PrintToChat(target_list[i], "\x01\x04[RTD][ADMIN] %s did something to you!", adminName);
				}
		}
		else if (IsValidClient(client) && IsPlayerAlive(client))//Apply to themselves
		{
			TF2_DoCond(client, condValue, adding);
			PrintToChat(client, "\x01\x04[RTD][ADMIN] %s Condition \x03%d\x04 on \x03%s", adding ? "Adding" : "Removing", condValue, adminName);
			LogToFile(logPath,"[RTD][ADMIN] %s Condition %d on %s", adding ? "Adding" : "Removing", adminName, condValue);
		}
		return Plugin_Handled;
	}	
	else if(StrEqual("spawnzombie1", strMessage, false))
	{
		Spawn_Zombie(client, 1);
		return Plugin_Handled;
	}	
	else if(StrEqual("spawnzombie2", strMessage, false))
	{
		Spawn_Zombie(client, 2);
		return Plugin_Handled;
	}	
	else if(StrEqual("spawnsaw", strMessage, false))
	{
		Spawn_Saw(client);
		return Plugin_Handled;
	}	
	else if(StrEqual("spawnzombie3", strMessage, false))
	{
		Spawn_Zombie(client, 3);
		return Plugin_Handled;
	}	
	else if(StrEqual("spawnroller", strMessage, false))
	{
		AddSphere(client);
		return Plugin_Handled;
	}
	else if(StrEqual("yoshime", strMessage, false))
	{
		client_rolls[client][AWARD_G_YOSHI][0] = 1;
		Make_Yoshi(client);
		CreateTimer(20.0, Remove_Yoshi_Timer, client, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Handled;
	}
	else if(StrEqual("findEnt", strMessage, false))
	{
		//This is used for finding certain values of the given class name
		//returns all entites found!
		
		new ent = -1;
		new String:entityClass[128];
		GetCmdArg(2, entityClass, sizeof(entityClass));
		new totFound;
		
		while ((ent = FindEntityByClassname(ent, entityClass)) != -1)
		{
			totFound ++;
			if(ent == -1)
			{
				PrintToChat(client, "\x01\x04[RTD][ADMIN] No entity found by classname \x03%s", adminName, entityClass);
			}else{
				PrintToChat(client, "\x01\x04[RTD][ADMIN] Entity found \x03%i", ent);
				//new String:modelname[128];
				//GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 128);
				PrintToChat(client, "\x01\x04[RTD][ADMIN] Model:%i", GetEntProp(ent, Prop_Data, "m_nModelIndex"));
				
				PrintToChat(client, "SolidType:%i | CollisionGroup:%i | SolidFlags:%i", GetEntProp(ent, Prop_Send, "m_nSolidType"), GetEntProp(ent, Prop_Send, "m_CollisionGroup"), GetEntProp(ent, Prop_Send, "m_usSolidFlags"));
			}
		}
		PrintToChat(client, "\x01\x04[RTD][ADMIN] Entity \x03%i", ent);
		PrintToChat(client, "\x01\x04[RTD][ADMIN] Total Found:\x03%i", totFound);
		LogToFile(logPath,"[RTD][ADMIN] %s Classname Lookup %s", adminName, entityClass);
		return Plugin_Handled;
	}
	else if(StrEqual("setdice#", strMessage, false))
	{
		if(args < 7)
		{
			PrintToChat(client, "usage: /rtdadmin setdice# <SteamID> <amount>");
			return Plugin_Handled;
		}
		
		new String:amountStr[128];
		new String:steamID[128];
		new String:steamIDPart1[128];
		new String:steamIDPart2[128];
		new String:steamIDPart3[128];
		
		GetCmdArg(2, steamIDPart1, sizeof(steamIDPart1));
		GetCmdArg(4, steamIDPart2, sizeof(steamIDPart2));
		GetCmdArg(6, steamIDPart3, sizeof(steamIDPart3));
		
		GetCmdArg(7, amountStr, sizeof(amountStr));
		
		Format(steamID,sizeof(steamID),"%s:%s:%s",steamIDPart1,steamIDPart2,steamIDPart3);
		
		//rtdadmin setcreds# STEAM_0:0:15175229 
		//STEAM_0:0:15175229 
		new amount = StringToInt(amountStr);
		new wantedClient = findClientbySteamID(steamID);
		if(wantedClient == -1)
		{
			PrintToChat(client, "Client %s not found!",steamID);
			return Plugin_Handled;
		}
		
		new String:name[32];
		GetClientName(wantedClient, name, sizeof(name));
		
		if(client > 0)
			PrintToChat(client, "\x01\x04[RTD][ADMIN] Setting Dice for %s:from %d to %d", name, RTDdice[wantedClient], amount);
		LogToFile(logPath,"[RTD][ADMIN] Setting Dice for %s: from %d to %d", name,RTDdice[wantedClient],  amount);
		
		RTDdice[wantedClient] = amount;
		
		return Plugin_Handled;
	}
	else if(StrEqual("setcreds#", strMessage, false))
	{
		if(args < 7)
		{
			PrintToChat(client, "usage: /rtdadmin setcreds# <SteamID> <amount>");
			return Plugin_Handled;
		}
		
		new String:amountStr[128];
		new String:steamID[128];
		new String:steamIDPart1[128];
		new String:steamIDPart2[128];
		new String:steamIDPart3[128];
		
		GetCmdArg(2, steamIDPart1, sizeof(steamIDPart1));
		GetCmdArg(4, steamIDPart2, sizeof(steamIDPart2));
		GetCmdArg(6, steamIDPart3, sizeof(steamIDPart3));
		
		GetCmdArg(7, amountStr, sizeof(amountStr));
		
		Format(steamID,sizeof(steamID),"%s:%s:%s",steamIDPart1,steamIDPart2,steamIDPart3);
		
		//rtdadmin setcreds# STEAM_0:0:15175229 
		//STEAM_0:0:15175229 
		new amount = StringToInt(amountStr);
		new wantedClient = findClientbySteamID(steamID);
		if(wantedClient == -1)
		{
			PrintToChat(client, "Client %s not found!",steamID);
			return Plugin_Handled;
		}
		
		new String:name[32];
		GetClientName(wantedClient, name, sizeof(name));
			
		PrintToChat(client, "\x01\x04[RTD][ADMIN] Setting Credits for %s:from %d to %d", name, RTDCredits[wantedClient], amount);
		LogToFile(logPath,"[RTD][ADMIN] Setting Credits for %s: from %d to %d", name,RTDCredits[wantedClient],  amount);
		
		RTDCredits[wantedClient] = amount;
		
		return Plugin_Handled;
	}
	else if(StrEqual("findrag", strMessage, false))
	{
		new ent = -1;
		new totFound;
		while ((ent = FindEntityByClassname(ent, "tf_ragdoll")) != -1)
		{
			totFound ++;
		}
		PrintToChat(client, "TotalRagdolls: %i",totFound);
		return Plugin_Handled;
	}
	else if(StrEqual("backpack", strMessage, false))
	{
		LogToFile(logPath,"[RTD][ADMIN] Attaching Backpack on %s", adminName);
		SpawnAndAttachBackpack(client);
		return Plugin_Handled;
	}
	else if(StrEqual("spawndeposits", strMessage, false))
	{
		new String:argsStr[128];
		
		GetCmdArg(2, argsStr, sizeof(argsStr));
		new bool:spawnForce = StrEqual("true", argsStr, false);
		
		GetCmdArg(3, argsStr, sizeof(argsStr));
		new bool:spawnAll = StrEqual("true", argsStr, false);
		
		LogToFile(logPath,"[RTD][ADMIN] %s is spawning Dice Deposits Setting %d - %d", adminName, spawnForce, spawnAll);
		DiceDeposit_ParseList();
		SetupDiceDepositRoundSpawn(spawnForce, spawnAll);
		return Plugin_Handled;
	}
	else if(StrEqual("dicedepositcfg", strMessage, false))
	{
		DiceDeposit_ParseList();
		return Plugin_Handled;
	}
	else if(StrEqual("forceserverroll", strMessage, false))
	{
		//serverRolls_NextRoll = GetTime();
		return Plugin_Handled;
	}
	else if(StrEqual("copyloc", strMessage, false))
	{
		new String:argsStr[128];
		
		GetCmdArg(2, argsStr, sizeof(argsStr));
		new locType = StringToInt(argsStr);
		
		GetCmdArg(3, argsStr, sizeof(argsStr));
		new locTeam = StringToInt(argsStr);
		
		GetCmdArg(4, argsStr, sizeof(argsStr));
		new locDuration = StringToInt(argsStr);
		
		new Float: userpos[3];
		GetClientAbsOrigin(client,userpos);
		PrintToChat(client, "		\"SpawnPoint\"");
		PrintToChat(client, "		{");
		if(locType == 1)
		{
			PrintToChat(client, "			\"round\"	\"%i\"",currentRound);
			PrintToChat(client, "			\"team\"	\"%i\"",locTeam);
			PrintToChat(client, "			\"duration\"	\"%i\"",locDuration);
		}
		PrintToChat(client, "			\"x\"	\"%i\"",RoundFloat(userpos[0]));
		PrintToChat(client, "			\"y\"	\"%i\"",RoundFloat(userpos[1]));
		PrintToChat(client, "			\"z\"	\"%i\"",RoundFloat(userpos[2]));
		PrintToChat(client, "		}");
		return Plugin_Handled;
	}
	else if(StrEqual("testmsg", strMessage, false))
	{
		return Plugin_Handled;
	}
	else if(StrEqual("loadawards", strMessage, false))
	{
		LoadAwards();
		return Plugin_Handled;
	}
	else if(StrEqual("awarddenydebug", strMessage, false))
	{
		new String:argsStr[128];
		
		GetCmdArg(2, argsStr, sizeof(argsStr));
		new award = StringToInt(argsStr);
		
		new String:code[128];
		GetCmdArg(3, code, sizeof(code));
		
		GetCmdArg(4, argsStr, sizeof(argsStr));
		new awarded = StringToInt(argsStr);
		
		new Handle:dataPack = CreateDataPack();
		WritePackCell(dataPack, client);
		WritePackCell(dataPack, award);
		WritePackString(dataPack, code);
		WritePackCell(dataPack, awarded);
		WritePackCell(dataPack, 0);
		DenyAward(dataPack);
		return Plugin_Handled;
	}
	else if(StrEqual("giveaward", strMessage, false))
	{
		new Handle:dataPack = CreateDataPack();
		new String:argsStr[128];
		
		GetCmdArg(2, argsStr, sizeof(argsStr));
		new award = StringToInt(argsStr);
		
		GiveAward(client, award, dataPack);
		return Plugin_Handled;
	}
	else if(StrEqual("scramble", strMessage, false))
	{
		PrintToChatAll("\x01\x04[Scramble]\x01 Teams will be scrambled next round.");
		g_bScramblePending = true;
		g_iScrambleDelay = GetTime() + 300;
		return Plugin_Handled;
	}
	else if(StrEqual("scramble2", strMessage, false))
	{
		DisplayScrambleVoteMenu();
		return Plugin_Handled;
	}
	else if(StrEqual("dmgDebug", strMessage, false))
	{
		if(dmgDebug[client] == false)
		{
			PrintCenterText(client, "DMG Debug ON");
			dmgDebug[client] = true;
		}else{
			PrintCenterText(client, "DMG Debug OFF");
			dmgDebug[client] = false;
		}
		return Plugin_Handled;
	}
	else if(StrEqual("kill", strMessage, false))
	{
		new String:player[64], String:saverolls[8];
		GetCmdArg(2, saverolls, sizeof(saverolls));
		GetCmdArg(3, player, sizeof(player));
		g_bSaveRollsOnDeath = StrEqual("true", saverolls, false);
		if (StrEqual("*", player, false))
		{
			for(new i=1;i<=MaxClients;i++)
				if(IsValidClient(i))
					SlapPlayer(i, 9001);
		}
		else if (!StrEqual("", player, false)) //They want to apply to some players
		{
			decl String:target_name[MAX_TARGET_LENGTH];
			decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
			if ((target_count = ProcessTargetString(
					player,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
			{
				PrintToChat(client, "Couldn't match any players for the kill.");
				g_bSaveRollsOnDeath = false;
				return Plugin_Handled;
			}
			for (new i = 0; i < target_count; i++)
				if (IsValidClient(target_list[i]) && IsPlayerAlive(target_list[i]))
					SlapPlayer(target_list[i], 9001);
		}
		else if (IsValidClient(client) && IsPlayerAlive(client))//Apply to themselves
		{
			SlapPlayer(client, 9001);
		}
		
		g_bSaveRollsOnDeath = false;
		return Plugin_Handled;
	}
	else if(StrEqual("dicedebug", strMessage, false))
	{
		diceDebug[client] = !diceDebug[client];
		PrintToChat(client, "[RTD][ADMIN] Dice mine debugging turned %s.", diceDebug[client] ? "ON" : "OFF");
		return Plugin_Handled;
	}
	else if(StrEqual("entcount", strMessage, false))
	{
		new maxents = GetMaxEntities();
		new i, c = 0;
		
		for(i = MaxClients; i <= maxents; i++)
		{
			if(IsValidEntity(i) || IsValidEdict(i))
				c += 1;	
		}
		
		PrintToChat(client, "%Ent Count: %i", c);
		return Plugin_Handled;
	}
	else
	{
		SetupAdminMenu(client);
		return Plugin_Handled;
	}

}

public Action:Command_rtd(client, args)
{
	// Check to see if client is valid
	if(client <= 0 || !IsClientConnected(client)) return Plugin_Continue;
	
	decl String:strMessage[128];
	GetCmdArg(1, strMessage, sizeof(strMessage));
	
	new String:strArgs[24][128];
	ExplodeString(strMessage, " ", strArgs, 24, 128);
	
	// Check for chat triggers
	new bool:cond = false;
	for(new i=0; i<g_iTriggers; i++)
	{
		if(StrEqual(chatTriggers[i], strArgs[0], false))
		{
			BoughtSomething[client] = 0;
			cond = true;
			continue;
		}
	}
	
	if(StrEqual("!rtd", strArgs[0], false)) cond = true;
	
	if(StrEqual(strArgs[0], "buy", false))
	{
		decl String:arg2[128];
		if (StrEqual(strArgs[1], "", false) && GetCmdArg(2, arg2, sizeof(arg2)) != 0)
			SetupCreditsMenu(client, arg2);
		else
			SetupCreditsMenu(client, strArgs[1]);
		return Plugin_Handled;
	}
	
	if((StrEqual(strArgs[0], "givecreds", false) || StrEqual(strArgs[0], "givecredits", false) || StrEqual(strArgs[0], "givecredit", false) || StrEqual(strArgs[0], "givecred", false)) && !StrEqual(strArgs[1], "", false))
	{
		SetupGiveCreditsMenu(client, StringToInt(strArgs[1]));
		return Plugin_Handled;
	}
	
	if(StrEqual(strArgs[0], "gift", false))
	{
		SetupGiftMenu(client);
		return Plugin_Handled;
	}
	
	if(StrEqual(strArgs[0], "rollinfo", false))
	{
		ShowWhatIsMOTD(client, strArgs[1]);
		//return Plugin_Handled;
	}
	
	if(StrEqual(strArgs[0], "call", false) || StrEqual(strArgs[0], "summon", false))
	{
		SummonObject(client);
		return Plugin_Handled;
	}
	
	if (StrEqual(strArgs[0], "+use", false))
	{
		if (RTDOptions[client][0] == 0) {
			PrintToChat(client, "%cTo activate rolls with +use instead of right clicking...", cGreen);
			PrintToChat(client, "%c1)%c  Type \"options\", press 1, and then 0.", cDarkGreen, cDefault); //" Notepad++ Formatting Fix
			PrintToChat(client, "%c2)%c  Type \"+use\" into chat again.", cDarkGreen, cDefault); //" Notepad++ Formatting Fix
		} else {
			PrintToChat(client, "%cTo get %s to work, you need to...", cGreen, strArgs[0]);
			PrintToChat(client, "%c1)%c  Enable the developer console (Esc -> Options -> [TAB]Keyboard -> Advanced...) if you have not already.", cDarkGreen, cDefault);
			PrintToChat(client, "%c2)%c  Press '~' in-game.", cDarkGreen, cDefault);
			PrintToChat(client, "%c3)%c  Execute the command (where <KEY> is the key you want to use): bind <KEY> +use", cDarkGreen, cDefault);
			PrintToChat(client, "%c4)%c  Congrats!  Press <KEY> in-game to use your rolls!", cDarkGreen, cDefault);
			PrintToChat(client, "%cCommand Example: bind p +use", cLightGreen);
		}
		return Plugin_Handled;
	}
	
	//check for credits
	for(new i=0; i<g_iCreditTriggers; i++)
	{
		if(StrEqual(chatCreditTriggers[i], strArgs[0], false) && GetConVarInt(c_Enabled))
		{
			SetupCreditsMenu(client, "");
			return Plugin_Handled;
		}
	}
	
	
	if((StrEqual("perk", strArgs[0], false) || StrEqual("perks", strArgs[0], false) || StrEqual("!perk", strArgs[0], false) || StrEqual("diceperk", strArgs[0], false) || StrEqual("diceperks", strArgs[0], false)) && StrEqual("", strArgs[1], false))
	{
		SetupPerksMenu(client, 0);
		return Plugin_Handled;
	}
	
	if(StrEqual("movehud", strArgs[0], false))
	{
		SetEntityMoveType(client,MOVETYPE_NONE);
		movingHUD[client] = true;
		moveHUDStage[client] = 0;
		ShowOverlay(client, "rtdgaming/movehud", 0.2);
		return Plugin_Handled;
	}
	
	if(StrEqual("options", strArgs[0], false) || StrEqual("option", strArgs[0], false))
	{
		//PrintToChat(client, "This command is currently disabled!");
		ShowRTDOptions(client, 0);
		return Plugin_Handled;
	}
	
	if (StrEqual("!respec", strArgs[0], false))
	{
		//PrintToChatAll("R: %d | P: %d | T: %d", client_rolls[client][AWARD_G_CLASSIMMUNITY][2], RTD_Perks[client][25], GetTime());
		if (RTD_PerksLevel[client][25] != 0)
			if (client_rolls[client][AWARD_G_CLASSIMMUNITY][0])
				if (client_rolls[client][AWARD_G_CLASSIMMUNITY][2] + RTD_Perks[client][25] < GetTime())
					GiveClassImmunity(client);
				else PrintCenterText(client, "You must wait %d more seconds before you can respec.", client_rolls[client][AWARD_G_CLASSIMMUNITY][2] + RTD_Perks[client][25] - GetTime());
			else PrintCenterText(client, "You do not have class immunity right now.");
		else PrintCenterText(client, "You do not have the class immunity respec perk.  Type buy.");
		return Plugin_Handled;
	}
		
	if(StrEqual("dice", strArgs[0], false) || StrEqual("!dice", strArgs[0], false))
	{
		ShowDiceStatus(client);
		return Plugin_Handled;
	}
	
	if(StrEqual("rtdrank", strArgs[0], false) || StrEqual("rtdstats", strArgs[0], false) || StrEqual("rtdplace", strArgs[0], false))
	{
		rankpanel(client);
		return Plugin_Handled;
	}
	
	if(StrEqual("topcreds", strArgs[0], false) || StrEqual("topcredits", strArgs[0], false) || StrEqual("topcredit", strArgs[0], false) || StrEqual("creditrank", strArgs[0], false) || StrEqual("rankcredit", strArgs[0], false))
	{
		top10pnl(client);
		return Plugin_Handled;
	}
	
	if(StrEqual("topdice", strArgs[0], false) || StrEqual("toprtddice", strArgs[0], false) || StrEqual("dicerank", strArgs[0], false)  || StrEqual("rankdice", strArgs[0], false))
	{
		top10Dice(client);
		return Plugin_Handled;
	}
	
	if(StrEqual("status", strArgs[0], false) || StrEqual("rolls", strArgs[0], false) )
	{
		showActiveRolls(client);
		return Plugin_Handled;
	}
	
	if(StrEqual("copyloc", strArgs[0], false))
	{
		//PrintToChat(client, "This command is currently disabled!");
		new Float: userpos[3];
		GetClientAbsOrigin(client,userpos);
		PrintToChat(client, "        \"SpawnPoint\"");
		PrintToChat(client, "        {");
		PrintToChat(client, "            \"x\"    \"%i\"",RoundFloat(userpos[0]));
		PrintToChat(client, "            \"y\"    \"%i\"",RoundFloat(userpos[1]));
		PrintToChat(client, "            \"z\"    \"%i\"",RoundFloat(userpos[2]));
		PrintToChat(client, "        }");
		return Plugin_Handled;
	}
	
	///////////////////////////////////////////
	//MAKE SURE TO REMOVE BEFORE SUBMITTING  //
	///////////////////////////////////////////
	if(StrEqual("testfunc", strArgs[0], false))
	{
		//this is a dummy message so this variable gets used :P
		PrintToChatAll("RTD Debug Status: %i",rtd_debug);
		//attachHatToSpider(client, -1);
	}
	
	if(StrEqual("award", strArgs[0], false))
	{
		if(StrEqual("", strArgs[1], false))
		{
			PrintToChat(client, "%c[RTD]%c You must enter a code.", cGreen, cDefault);
		}
		else
		{
			AwardCheck(client, strArgs[1]);
		}
		
		return Plugin_Handled;
	}
	
	if(StrEqual("version", strArgs[0], false))
	{
		PrintToChat(client, "Version: %s", PLUGIN_VERSION);
		return Plugin_Handled;
	}
	
	if(StrEqual("killme", strArgs[0], false))
	{
		if(StrEqual("1", strArgs[1], false))
		{
			DealDamage(client, 999, client, 128, "beartrap");
			PrintCenterText(client, "(Testing) Killed by: beartrap");
			return Plugin_Handled;
		}
		if(StrEqual("2", strArgs[1], false))
		{
			DealDamage(client, 999, client, 128, "fireball");
			PrintCenterText(client, "(Testing) Killed by: fireball");
			return Plugin_Handled;
		}
		if(StrEqual("3", strArgs[1], false))
		{
			DealDamage(client, 999, client, 128, "rollermine");
			PrintCenterText(client, "(Testing) Killed by: rollermine");
			return Plugin_Handled;
		}
		if(StrEqual("4", strArgs[1], false))
		{
			DealDamage(client, 999, client, 128, "collateral");
			PrintCenterText(client, "(Testing) Killed by: collateral");
			return Plugin_Handled;
		}
		if(StrEqual("5", strArgs[1], false))
		{
			DealDamage(client, 999, client, 128, "crap");
			PrintCenterText(client, "(Testing) Killed by: crap");
			return Plugin_Handled;
		}
		if(StrEqual("6", strArgs[1], false))
		{
			DealDamage(client, 999, client, 128, "bomb");
			PrintCenterText(client, "(Testing) Killed by: bomb");
			return Plugin_Handled;
		}
		if(StrEqual("7", strArgs[1], false))
		{
			DealDamage(client, 999, client, 128, "instakill");
			PrintCenterText(client, "(Testing) Killed by: instakill");
			return Plugin_Handled;
		}
		if(StrEqual("8", strArgs[1], false))
		{
			DealDamage(client, 999, client, 128, "proxmine");
			PrintCenterText(client, "(Testing) Killed by: proxmine");
			return Plugin_Handled;
		}
		if(StrEqual("9", strArgs[1], false))
		{
			DealDamage(client, 999, client, 128, "zombie");
			PrintCenterText(client, "(Testing) Killed by: zombie");
			return Plugin_Handled;
		}
		if(StrEqual("10", strArgs[1], false))
		{
			DealDamage(client, 999, client, 128, "spider");
			PrintCenterText(client, "(Testing) Killed by: spider");
			return Plugin_Handled;
		}
		if(StrEqual("11", strArgs[1], false))
		{
			DealDamage(client, 999, client, 128, "present");
			PrintCenterText(client, "(Testing) Killed by: present");
			return Plugin_Handled;
		}
		if(StrEqual("12", strArgs[1], false))
		{
			DealDamage(client, 999, client, 128, "wallflame");
			PrintCenterText(client, "(Testing) Killed by: wallflame");
			return Plugin_Handled;
		}
		if(StrEqual("13", strArgs[1], false))
		{
			SendObjectDestroyedEvent(client, client, "killedspider");
			//DealDamage(client, 999, client, 128, "wallflame");
			PrintCenterText(client, "(Testing) You Killed a: Spider");
			return Plugin_Handled;
		}
		if(StrEqual("14", strArgs[1], false))
		{
			SendObjectDestroyedEvent(client, client, "killedzombie");
			//DealDamage(client, 999, client, 128, "wallflame");
			PrintCenterText(client, "(Testing) You Killed a: Zombie");
			return Plugin_Handled;
		}
		if(StrEqual("15", strArgs[1], false))
		{
			DealDamage(client, 999, client, 128, "toxic");
			PrintCenterText(client, "(Testing) Killed by: Toxic");
			return Plugin_Handled;
		}
		
		DealDamage(client, 999, client, 128, "toxic");
		PrintCenterText(client, "(Testing) Boom! Your Dead");
		//return Plugin_Handled;
	}
	
	if(StrEqual("scramble", strArgs[0], false))
	{
		if(g_iScrambleDelay > GetTime())
		{
			new time_remaining = g_iScrambleDelay-GetTime();
			PrintToChat(client, "\x01\x04[Scramble]\x01 VoteScramble is Unavailable for the next %d seconds.",  time_remaining);
			return Plugin_Handled;
		}
		if (g_ScrambleVoted[client])
		{
			PrintToChat(client, "\x01\x04[Scramble]\x01 You have already attempted to start a VoteScramble. (%d votes, %d required)",  g_iScrambleVotes, 3);
			return Plugin_Handled;
		}

		new String:name[64];
		GetClientName(client, name, sizeof(name));

		g_iScrambleVotes++;
		g_ScrambleVoted[client] = true;

		PrintToChatAll("\x01\x04[Scramble]\x01 %s wants to start a VoteScramble. (%d votes, %d required)", name, g_iScrambleVotes, 3);
		if (g_iScrambleVotes >= 3)
		{
			DisplayScrambleVoteMenu();
			g_iScrambleVotes = 0;
			for(new i=1;i<=MaxClients;i++)
			{
				g_ScrambleVoted[i] = false;
			}
		}
	}
	
	if(StrEqual("testlevelup", strArgs[0], false))
	{
		ShowOverlay(client, "rtdgaming/levelup", 10.0);
	}
	
	if(!GetConVarInt(c_Enabled)) return Plugin_Continue;
	
	if(!cond) return Plugin_Continue;
	
	//Do not let players roll if they are in a yoshi egg
	if (yoshi_eaten[client][0])
	{
		PrintToChat(client, "%c[RTD]%c You may not rtd while in a yoshi egg.", cGreen, cDefault);
		return Plugin_Handled;
	}
	
	// Check to see if the person is already rtd'ing
	if(inTimerBasedRoll[client])
	{
		PrintToChat(client, "%c[RTD]%c %T", cGreen, cDefault, "Player_Already", LANG_SERVER);
		return Plugin_Handled;
	}
	
	// Check to see if the person has waited long enough
	new timeleft;
	
	if( RTD_Timer[client] <= GetTime())
	{
		timeleft = GetConVarInt(c_Timelimit) - ( GetTime() - RTD_Timer[client]) ;
	}else{
		timeleft = RTD_Timer[client] +  GetConVarInt(c_Timelimit) - GetTime();
	}
	
	if(timeleft > 0 )
	{
		PrintToChat(client, "%c[RTD]%c %T", cGreen, cDefault, "Player_Wait", LANG_SERVER, cGreen,timeleft, cDefault);
		EmitSoundToClient(client, SOUND_DENY, client);
		
		return Plugin_Handled;
	}
	
	// Check to see if the player is still alive
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "%c[RTD]%c %T", cGreen, cDefault, "Player_Alive", LANG_SERVER);
		return Plugin_Handled;
	}
	
	switch(GetConVarInt(c_Mode))
	{
		// Only one player can rtd at a time
		case 1:
			for(new i=1; i<MaxClients+1; i++)
			{
				if(inTimerBasedRoll[i])
				{
					decl String:message[200];
					Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Player_Occupied_Mode1", LANG_SERVER, cLightGreen, i, cDefault);
					
					// Another player is rtd'ing
					SayText2One(client, i, message);
					return Plugin_Handled;
				}
			}
		
		// Verify that only X ammount of players on a team can rtd
		case 2:
		{
			new counter;
			for(new i=1; i<MaxClients+1; i++)
			{
				if(inTimerBasedRoll[i])
				{
					if(GetClientTeam(i)==GetClientTeam(client))
						counter++;
				}
			}
			
			if(counter >= GetConVarInt(c_Teamlimit))
			{
				PrintToChat(client, "%c[RTD]%c %T", cGreen, cDefault, "Player_Occupied_Mode2", LANG_SERVER);
				return Plugin_Handled;
			}
		}
	}
	
	// Player has passed all the checks
	new bool:success = RollTheDice(client);
	
	if(!success)
		PrintToChat(client, "%c[RTD]%c %T", cGreen, cDefault, "Disable_Overload", LANG_SERVER);
	return Plugin_Handled;
}

stock bool:IsValidClient(iClient)
{
	if (iClient < 0) return false;
	if (iClient > MaxClients) return false;
	if (!IsClientConnected(iClient)) return false;
	return IsClientInGame(iClient);
}

stock findClientbySteamID(String:steamid[])
{
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		new String:ClientSteamID[MAX_LINE_WIDTH];
		GetClientAuthString(i, ClientSteamID, sizeof(ClientSteamID));
		
		if(StrEqual(steamid,ClientSteamID))
			return i;
	}
	
	return -1;
}