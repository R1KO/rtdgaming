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
	
	//not full game admin get outta here
	if(!CheckAdminFlagsByString(client, "z"))
		return Plugin_Handled;
	
	decl String:strMessage[128];
	GetCmdArg(1, strMessage, sizeof(strMessage));
	new String:adminName[128];
	GetClientName(client, adminName, sizeof(adminName));
	
	
	if(StrEqual("spawndice", strMessage, false))
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
	else if(StrEqual("donate", strMessage, false))
	{
		if(args < 7)
		{
			PrintToChat(client, "usage: /rtdadmin donate <SteamID> <amount>");
			return Plugin_Handled;
		}
		
		new String:steamID[128];
		new String:steamIDPart1[128];
		new String:steamIDPart2[128];
		new String:steamIDPart3[128];
		new String:amountStr[128];
		
		GetCmdArg(2, steamIDPart1, sizeof(steamIDPart1));
		GetCmdArg(4, steamIDPart2, sizeof(steamIDPart2));
		GetCmdArg(6, steamIDPart3, sizeof(steamIDPart3));
		
		GetCmdArg(7, amountStr, sizeof(amountStr));
		
		Format(steamID,sizeof(steamID),"%s:%s:%s",steamIDPart1,steamIDPart2,steamIDPart3);
		
		//rtdadmin donate STEAM_0:0:15175229 
		//STEAM_0:0:15175229 
		new amount = StringToInt(amountStr);
		
		ReplaceString(steamID, sizeof(steamID), "\\", "", true);
		SQL_EscapeString(db, steamID, steamID, sizeof(steamID));
		
		//1 =  donation
		confirmDonationMenu(steamID, amount, client, 1);
		
		return Plugin_Handled;
	}
	else if(StrEqual("awardcreds", strMessage, false))
	{
		if(args < 7)
		{
			PrintToChat(client, "usage: /rtdadmin awardcreds <SteamID> <amount>");
			return Plugin_Handled;
		}
		
		new String:steamID[128];
		new String:steamIDPart1[128];
		new String:steamIDPart2[128];
		new String:steamIDPart3[128];
		new String:amountStr[128];
		
		GetCmdArg(2, steamIDPart1, sizeof(steamIDPart1));
		GetCmdArg(4, steamIDPart2, sizeof(steamIDPart2));
		GetCmdArg(6, steamIDPart3, sizeof(steamIDPart3));
		
		GetCmdArg(7, amountStr, sizeof(amountStr));
		
		Format(steamID,sizeof(steamID),"%s:%s:%s",steamIDPart1,steamIDPart2,steamIDPart3);
		
		//rtdadmin donate STEAM_0:0:15175229 
		//STEAM_0:0:15175229 
		new amount = StringToInt(amountStr);
		
		ReplaceString(steamID, sizeof(steamID), "\\", "", true);
		SQL_EscapeString(db, steamID, steamID, sizeof(steamID));
		
		//0 = not a donation but an award
		confirmDonationMenu(steamID, amount, client, 0);
		
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
	else if(StrEqual("loadawards", strMessage, false))
	{
		LoadAwards();
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
	else if(StrEqual("dicedebug", strMessage, false))
	{
		diceDebug[client] = !diceDebug[client];
		PrintToChat(client, "[RTD][ADMIN] Dice mine debugging turned %s.", diceDebug[client] ? "ON" : "OFF");
		return Plugin_Handled;
	}
	else if(StrEqual("savestats", strMessage, false))
	{
		if(areStatsLoaded[client] && g_BCONNECTED)
			saveStats(client);
		
		return Plugin_Handled;
	}else if(StrEqual("serverhour", strMessage, false))
	{
		decl String:szTime[30];
		FormatTime(szTime, sizeof(szTime), "%H", GetTime());
		
		new serverHour = StringToInt(szTime);
		PrintToChat(client, "%i", serverHour);
	}
	else
	{
		SetupAdminMenu(client);
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action:Command_rtd(client, args)
{
	// Check to see if client is valid
	if(client <= 0 || !IsClientConnected(client)) return Plugin_Continue;
	
	if(!IsClientInGame(client)) return Plugin_Continue;
	
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
	
	if(trading[client][0] == 1)
	{
		trading[client][2] = StringToInt(strArgs[0]);
		return Plugin_Handled;
	}
	
	if(StrEqual("!rtd", strArgs[0], false)) cond = true;
	
	if(StrEqual("/rtd", strArgs[0], false)) cond = true;
	
	//Buy commands
	
	if(StrEqual(strArgs[0], "buy", false))
	{
		if(rtd_classic)
		{
			PrintToChat(client, "Buying is DISABLED in Classic RTD");
		}else{
			decl String:arg2[128];
			if (StrEqual(strArgs[1], "", false) && GetCmdArg(2, arg2, sizeof(arg2)) != 0)
				SetupCreditsMenu(client, arg2);
			else
				SetupCreditsMenu(client, strArgs[1]);
		}
		
		return Plugin_Handled;
	}
	
	if(StrEqual(strArgs[0], "/buy", false))
	{
		if(rtd_classic)
		{
			PrintToChat(client, "Buying is DISABLED in Classic RTD");
		}else{
			decl String:arg2[128];
			if (StrEqual(strArgs[1], "", false) && GetCmdArg(2, arg2, sizeof(arg2)) != 0)
				SetupCreditsMenu(client, arg2);
			else
				SetupCreditsMenu(client, strArgs[1]);
		}
		
		return Plugin_Handled;
	}
	
	if(StrEqual(strArgs[0], "!buy", false))
	{
		if(rtd_classic)
		{
			PrintToChat(client, "Buying is DISABLED in Classic RTD");
		}else{
			decl String:arg2[128];
			if (StrEqual(strArgs[1], "", false) && GetCmdArg(2, arg2, sizeof(arg2)) != 0)
				SetupCreditsMenu(client, arg2);
			else
				SetupCreditsMenu(client, strArgs[1]);
		}
		
		return Plugin_Handled;
	}
	
	//
	
	if((StrEqual(strArgs[0], "givecreds", false) || StrEqual(strArgs[0], "givecredits", false) || StrEqual(strArgs[0], "givecredit", false) || StrEqual(strArgs[0], "givecred", false)))
	{
		if(rtd_classic)
		{
			PrintToChat(client, "That is DISABLED in Classic RTD");
		}else{
			SetupGiveCreditsMenu(client, StringToInt(strArgs[1]));	
		}
		
		return Plugin_Handled;
	}
	
	if(StrEqual(strArgs[0], "gift", false))
	{
		if(rtd_classic)
		{
			PrintToChat(client, "Gifting is DISABLED in Classic RTD");
		}else{
			SetupGiftMenu(client);
		}
		
		return Plugin_Handled;
	}
	
	if(StrEqual(strArgs[0], "rollinfo", false) || StrEqual(strArgs[0], "wiki", false))
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
		if(StrEqual(chatCreditTriggers[i], strArgs[0], false) && GetConVarInt(c_Enabled) && !rtd_classic)
		{
			SetupCreditsMenu(client, "");
			return Plugin_Handled;
		}
	}
	
	
	if((StrEqual("perk", strArgs[0], false) || StrEqual("perks", strArgs[0], false) || StrEqual("!perk", strArgs[0], false) || StrEqual("diceperk", strArgs[0], false) || StrEqual("diceperks", strArgs[0], false)) && StrEqual("", strArgs[1], false))
	{
		if(!rtd_classic)
			SetupPerksMenu(client, 0);
		
		return Plugin_Handled;
	}
	
	if((StrEqual("trinket", strArgs[0], false) || StrEqual("trinkets", strArgs[0], false) || StrEqual("!trinket", strArgs[0], false) || StrEqual("/trinkets", strArgs[0], false) || StrEqual("!trinkets", strArgs[0], false) || StrEqual("/trinket", strArgs[0], false) || StrEqual("trinks", strArgs[0], false) || StrEqual("trinkts", strArgs[0], false) || StrEqual("trinkt", strArgs[0], false)) && StrEqual("", strArgs[1], false))
	{
		if(!rtd_classic)
		{
			if(rtd_trinket_enabled == 1)
			{
				SetupTrinketsMenu(client, 0);
			}else{
				PrintCenterText(client, "Trinkets are DISABLED!");
			}
		}
		
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
	
	if (StrEqual("!respec", strArgs[0], false) && !rtd_classic)
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
		if(StrEqual("", strArgs[1], false))
		{
			if(!rtd_classic)
				ShowDiceStatus(client);
			
			return Plugin_Handled;
		}
	}
	
	if(StrEqual("rtdrank", strArgs[0], false) || StrEqual("rtdstats", strArgs[0], false) || StrEqual("rtdplace", strArgs[0], false) || StrEqual("rtdstat", strArgs[0], false))
	{
		if(StrEqual("", strArgs[1], false))
			showStatsPage(client);
		
		return Plugin_Continue;
	}
	
	if(StrEqual("topcreds", strArgs[0], false) || StrEqual("topcredits", strArgs[0], false) || StrEqual("topcredit", strArgs[0], false) || StrEqual("creditrank", strArgs[0], false) || StrEqual("rankcredit", strArgs[0], false))
	{
		if(!rtd_classic)
			top10pnl(client);
		
		return Plugin_Handled;
	}
	
	if(StrEqual("topdice", strArgs[0], false) || StrEqual("toprtddice", strArgs[0], false) || StrEqual("dicerank", strArgs[0], false)  || StrEqual("rankdice", strArgs[0], false))
	{
		if(!rtd_classic)
			top10Dice(client);
		
		return Plugin_Handled;
	}
	
	if(StrEqual("status", strArgs[0], false) || StrEqual("rolls", strArgs[0], false) || (StrEqual("active", strArgs[0], false) && StrEqual("rolls", strArgs[0], false)))
	{
		showActiveRolls(client);
		return Plugin_Handled;
	}
	
	if(StrEqual("activetrinket", strArgs[0], false))
	{
		new trinketIndex;
		
		for(new i = 0; i < 21; i++)
		{
			if(!StrEqual(RTD_TrinketUnique[client][i], "", false))
			{
				if(RTD_TrinketEquipped[client][i] == 1)
				{
					trinketIndex = RTD_TrinketIndex[client][i];
					
					PrintToChat(client, "Current equipped trinket: %s %s", trinket_TierID[trinketIndex][RTD_TrinketTier[client][i]], trinket_Title[trinketIndex]);
					PrintToChat(client, "isActive: %i | Bonus: %i | Misc: %i", RTD_TrinketActive[client][trinketIndex], RTD_TrinketBonus[client][trinketIndex], RTD_TrinketMisc[client][trinketIndex]);
					
					break;
				}
			}
		}
		
		
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
	
	if (StrEqual("checktalentpoints", strArgs[0], false) && !rtd_classic)
	{
		checkTalentPoints(client);
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
	
	if(StrEqual("award", strArgs[0], false) && !rtd_classic)
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
	if (!IsClientAuthorized(iClient)) return false;
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