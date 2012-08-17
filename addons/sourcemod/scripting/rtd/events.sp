#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <clientprefs>
#include <regex>
#include <rtd_rollinfo>
#include <tf2>
 
// if the plugin was loaded late we have a bunch of initialization that needs to be done
public APLRes:AskPluginLoad2(Handle:hPlugin, bool:isAfterMapLoaded, String:error[], err_max)
{
	lateLoaded = isAfterMapLoaded;
	
	//return APLRes_Success;
}

 public OnClientPostAdminCheck(client)
{
	if (!IsClientInGame(client)) return;
	
	CleanPlayer(client);
	resetPerkAttributes(client);
	showStartupMsg[client] = true;
	
	credsUsed[client][0] = 0;
	credsUsed[client][1] = GetTime();
	
	creds_Gifted[client] = 0;
	
	creds_ReceivedFromGifts[client] = 0;
	
	//clear trinkets
	for(new k = 0; k < 21; k++)
	{
		Format(RTD_TrinketUnique[client][k], 32, "");
		Format(RTD_TrinketTitle[client][k], 32, "");
		
		RTD_TrinketEquipped[client][k] = 0;
		
		RTD_TrinketTier[client][k] = 0;
		RTD_TrinketIndex[client][k] = 0;
	}
	
	for(new k = 0; k <= MAX_TRINKETS; k++)
	{
		RTD_TrinketActive[client][k] = 0;
		RTD_TrinketBonus[client][k] = 0;
	}
	
	CreateTimer(600.0, resetCredsUsed, GetClientUserId(client), TIMER_REPEAT |TIMER_FLAG_NO_MAPCHANGE);
	
	if(g_BCONNECTED && !rtd_classic)
	{
		SetHudTextParams(0.42, 0.22, 10.0, 250, 250, 210, 255, 2);
		ShowHudText(client, HudMsg3, "Connecting to Database...");
		areStatsLoaded[client] = false;
		updateplayername(client);
		InitializeClientonDB(client);
	}
	
	g_BeginScore[client] = 0;
	
	SDKHook(client,	SDKHook_OnTakeDamage, 	TakeDamageHook);
	//SDKHook(client,	SDKHook_TraceAttack, 	TakeDamageHook);
	
	seedingLimit[client] = 0;
}

public OnClientDisconnect(client)
{	
	//connects to database to save client's active credits
	//Only connect if the client is connected and the DB is a valid handle
	if(areStatsLoaded[client] && g_BCONNECTED && !rtd_classic)
		saveStats(client);
	
	if(inTimerBasedRoll[client])
		PrintToChatAll("%c[RTD]%c %T", cGreen, cDefault, "Player_Disconnect", LANG_SERVER);
	
	CleanPlayer(client);
}

public Action:Event_PlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client)
		return;

	new TFClassType:class = TFClassType:GetEventInt(event, "class");
	new TFClassType:oldclass = TF2_GetPlayerClass(client);
	
	//player is the same class  :P
	if (class == oldclass)
		return;
	
	if(showStartupMsg[client] && class != TFClass_Unknown && g_BCONNECTED)
	{
		if(isNewUser[client])
		{
			//show_newUser_TalentPoints_msg(client);
			showWelcomeBackPanel(client);
		}else{
			showWelcomeBackPanel(client);
		}
	}
	
	//player was Hulk before but now he changed class
	if(client_rolls[client][AWARD_G_HULK][0])
	{
		if(class != TFClass_Heavy)
		{
			PrintToChat(client, "\x04[RTD]\x01You lost \x03%s\x01 for switching classes", roll_Text[AWARD_G_HULK]);
			PrintCenterText(client, "You lost: %s for switching classes", roll_Text[AWARD_G_HULK]);
			
			client_rolls[client][AWARD_G_HULK][0] = 0;
			client_rolls[client][AWARD_G_SPEED][0] = 0;
			ROFMult[client] = 1.0;
			
			Colorize(client, NORMAL);
			SetEntityGravity(client, 1.0);
			ResetClientSpeed(client);
		}
	}
	
	if(client_rolls[client][AWARD_G_MEDIRAY][0])
	{
		if(class != TFClass_Medic)
		{
			PrintToChat(client, "\x04[RTD]\x01You lost \x03%s\x01 for switching classes", roll_Text[AWARD_G_MEDIRAY]);
			PrintCenterText(client, "You lost: %s for switching classes", roll_Text[AWARD_G_MEDIRAY]);
			client_rolls[client][AWARD_G_MEDIRAY][0] = 0;
		}
	}
	
	if (client_rolls[client][AWARD_G_YOSHI][0])
	{
		client_rolls[client][AWARD_G_YOSHI][0] = 0;
		PrintToChat(client, "\x04[RTD]\x01You lost your \x03Yoshi\x01 roll for switching classes.");
	}
	
	if (client_rolls[client][AWARD_G_WINGS][0])
	{
		Drop_Wings(client);
		PrintToChat(client, "\x04[RTD]\x01You lost your \x03Redbull\x01 roll for switching classes.");
	}
	
	//Remove any rolls that have class restrictions
	for(new i=0; i<MAX_GOOD_AWARDS + MAX_BAD_AWARDS; i ++)
	{
		//aright we found a restriction
		if(class != roll_ClassRestriction[i] && roll_ClassRestriction[i] != TFClass_Unknown && client_rolls[client][i][0] || class == roll_ExcludeClass[i] && roll_ExcludeClass[i] != TFClass_Unknown && client_rolls[client][i][0])
		{
			PrintToChat(client, "\x04[RTD]\x01You lost \x03%s\x01 for switching classes", roll_Text[i]);
			PrintCenterText(client, "You lost: %s for switching classes", roll_Text[i]);
			
			client_rolls[client][i][0] = 0;
		}
	}
	
	//Let's check to see if the player has an active menu displayed
	if(GetClientMenu(client) != MenuSource_None ){
		CancelClientMenu(client,true);
	}
	
}

public Action:Event_RoundActive(Handle:event, const String:name[], bool:dontBroadcast)
{
	//When the round is active and players can move
	roundEnded = false;
	//Start the timer
	roundStartTime = GetTime();
	
	if (g_TimerExtendDatapack != INVALID_HANDLE)
		CloseHandle(g_TimerExtendDatapack);
	g_TimerExtendDatapack = CreateDataPack();
	WritePackCell(g_TimerExtendDatapack, 0);
	
	/*
	if(GetConVarInt(c_Enabled))
	{
		PrintToChatAll("%c[RTD]%c %T", cGreen, cDefault, "Announcement_Message", LANG_SERVER, cGreen, cDefault);
	}*/
	if(g_bScramblePending)
	{
		ScramblePlayers();
		g_bScramblePending = false;
	}
	
	roll_enabled[AWARD_G_NOCLIP] = 0;
	
	//Disable capping during Setup
	//If no setup time is found then game continues as usual
	
	//PrintToChatAll("Event_RoundActive: %i", GameRules_GetProp("m_bInSetup", 4, 0));
	//disable control points during setup
	/*
	if(GameRules_GetProp("m_bInSetup", 4, 0))
		disableControlPoints(true);
	*/
	
	removeAllDice();
	
	//When the round is active and players can move
	for (new j = 1; j <= MaxClients; j++)
		g_BeginScore[j] = TF2_GetPlayerResourceData(j, TFResource_TotalScore) ;
	
	//Spawn the dice deposit
	if(GetConVarInt(c_Dice_Deposits) && !rtd_classic)
		CreateTimer(1.0, DiceDepositRoundSpawn_Timer);
}



public Action:Event_Setup(Handle:event,  const String:name[], bool:dontBroadcast) 
{ 
	roundEnded = false;
	
    //Ok setup time is over let's re-enable noclip 
    //Update the disabled commands with what is saved in the cfg 
	roll_enabled[AWARD_G_NOCLIP] = 1;
	
	//re-enable the cap points
	//PrintToChatAll("Event_Setup: %i", GameRules_GetProp("m_bInSetup", 4, 0));
	
	//wait until next frame to check if in setup
	/*
	CreateTimer(0.1, delayCheck);
	*/
	
	//respawn the dice
	if(diceNeeded > 0 && !rtd_classic)
	{
		if(diceNeeded > diceSpawnLimit)
			diceNeeded = diceSpawnLimit;
		
		RespawnDisabledDice(diceNeeded);
	}
	
	//Start the timer
	roundStartTime = GetTime();
} 


public Action:delayCheck(Handle:Timer)
{
	if(GameRules_GetProp("m_bInSetup", 4, 0) == 0)
		disableControlPoints(false);
	
	return Plugin_Stop;
}

public Action:disableControlPoints(bool:capState)
{
	new i = -1;
	new CP = 0;

	for (new n = 0; n <= 16; n++)
	{
		CP = FindEntityByClassname(i, "trigger_capture_area");
		if (IsValidEntity(CP))
		{
			if(capState)
			{
				AcceptEntityInput(CP, "Disable");
			}else{
				AcceptEntityInput(CP, "Enable");
			}
			i = CP;
		}
		else
			break;
	}
}


	
public Action:Event_Teamplay_Win_Panel(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(rtd_classic)
		return Plugin_Continue;
	
	new playersFound;
	
	//Award MVPs with dice
	//Depending on the amount of users on
	// amountofPlayers must be > 5 to be awarded a dice
	
	new MVP1 = GetEventInt(event, "player_1");
	new MVP2 = GetEventInt(event, "player_2");
	new MVP3 = GetEventInt(event, "player_3");
	new winningTeam = GetEventInt(event, "winning_team");
	
	new winreason = GetEventInt(event, "winreason");
	
	if(winreason == -9)
	{
		PrintToChatAll("det!");
		return Plugin_Handled;
	}
	
	//prevent player earning dice twice
	if(MVP1 == MVP2)
		MVP2 = 0;
	
	if(MVP1 == MVP3)
		MVP3 = 0;
	
	for (new j = 1; j <= MaxClients ; j++)
	{
		if(IsClientInGame(j))
			playersFound ++;
	}
	
	//Figure out how much extra dice to give based on round length
	new roundLength = RoundFloat(float(GetTime() - roundStartTime)/60.0);
	new extraDice = roundLength / 6;
	
	//This would get called if plugin was reloaded midgame
	if(roundStartTime == 0)
		extraDice = 0;
	
	if(playersFound <= 5 )
		return Plugin_Continue;
	
	if(roundLength > 1)
	{
		addDice(MVP1, 1, 2+extraDice);
		addDice(MVP2, 1, 1+extraDice);
		addDice(MVP3, 1, extraDice);
		GiveDiceToTopLoser(winningTeam, MVP1, MVP2, 1+extraDice);
	}else{
		addDice(MVP1, 1, 1);
	}
	
	PrintToChatAll("\x04[MVP]\x01 %i\x03 Extra Dice awarded | Round Length: \x01%i\x03 mins",extraDice, roundLength);
	
	return Plugin_Continue;
}

public GiveDiceToTopLoser(winningTeam, any:MVP1, any:MVP2, diceToGive)
{
	new Scores[MaxClients][2];
	new client;
	
	// For sorting purpose, start fill Scores[][] array from zero index
	//
	for (new i = 0; i < MaxClients; i++)
	{
		client = i + 1;
		Scores[i][0] = client;
		if (IsClientInGame(client) && GetClientTeam(client) != winningTeam && client != MVP1 && client != MVP2 && (GetClientTeam(client) == RED_TEAM || GetClientTeam(client) == BLUE_TEAM))
			Scores[i][1] = TF2_GetPlayerResourceData(client, TFResource_TotalScore) - g_BeginScore[client];
		else
			Scores[i][1] = -1;
	}
	
	SortCustom2D(Scores, MaxClients, SortScoreDesc);
	
	if(Scores[0][1] > 0 && Scores[0][0] != MVP1)
	{
		TF2_StunPlayer(Scores[0][0],0.5, 0.0, TF_STUNFLAGS_LOSERSTATE, 0);
		addDice(Scores[0][0], 4, diceToGive);
	}
}

public SortScoreDesc(x[], y[], array[][], Handle:data)
{
	if (x[1] > y[1])
		return -1;
	else if (x[1] < y[1])
		return 1;
	return 0;
}

public Action:Event_PointCaptured(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(rtd_classic)
		return Plugin_Continue;
	
	//For Dice Deposit
	//new String:cap[32];
	//GetEventString(event, "cpname", cap, sizeof(cap));
	RemoveDepositsNearEntity(GetEventInt(event, "cp"));
	
	return Plugin_Continue;
}

public Action:Event_RoundSelected(Handle:event, const String:name[], bool:dontBroadcast)
{
	//For Dice Deposit
	new String:round[32];
	GetEventString(event, "round", round, sizeof(round));
	currentRound = -1;
	
	if(SimpleRegexMatch(round, "^round_?(1|a)$", PCRE_CASELESS))
		currentRound = 1;
	else if(SimpleRegexMatch(round, "^round_?(2|b)$", PCRE_CASELESS))
		currentRound = 2;
	else if(SimpleRegexMatch(round, "^round_?(3|c)$", PCRE_CASELESS))
		currentRound = 3;
	else if(SimpleRegexMatch(round, "^round_?(4|d)$", PCRE_CASELESS))
		currentRound = 4;
	else if(SimpleRegexMatch(round, "^round_?(5|e)$", PCRE_CASELESS))
		currentRound = 5;
	else
	{
		currentRound = -1;
		LogToFile(logPath,"Error Current Round Match not found Round is '%s'", round);
	}
}

public Action:Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundEnded = true;
	
	//disable RTD at this time
	SetConVarInt(c_Enabled, 0);
	
	new winningTeam = GetEventInt(event, "team");
	tf2_WinningTeam = winningTeam;
	
	//Players with more than 200 Dice have round end immunity
	
	//Remove SlowCubes, Telespheres, Ice Patches from the battlefield
	deleteRTDEntities();
	
	//Reset client speeed and gravity
	for (new i = 1; i <= MaxClients; i++) 
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
		{
			continue;
		}
		
		//Reset client speed due to Ice Effects
		inIce[i] = false;
		SetEntityGravity(i, 1.0);
		ResetClientSpeed(i);
		
		//Remove SlowCube effects
		if(beingSlowCubed[i])
		{
			inSlowCube[i] = 0;
			beingSlowCubed[i] = 0;
			SetEntityGravity(i, 1.0);
		}
	}
	
	diceNeeded = 0;
	new dynamic_ent = -1;
	while ((dynamic_ent = FindEntityByClassname(dynamic_ent, "prop_dynamic")) != -1)
	{
		if(diceModelIndex == GetEntProp(dynamic_ent, Prop_Data, "m_nModelIndex"))
			diceNeeded ++;
	}
	
	//PrintToChatAll("DEBUG: DiceNeeded = %i",diceNeeded);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	//re-enable RTD at this time
	SetConVarInt(c_Enabled, 1);
	
	//REMOVE round end immunity
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) 
		{
			if (RTD_Perks[i][6] != 0)
				SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
		}
	}
	
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	clientSpawnTime[client] = GetTime();
	
	//GivePlayerEffect(client, AWARD_G_AIRINTAKE, 0);
	
	Colorize(client, NORMAL);
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	if (yoshi_eaten[client][0])
		Yoshi_BreakEgg(client);
	
	//wait until next frame
	CreateTimer(0.0,waitHealthAdjust, client);
	
	new String:clientname[32];
	GetClientName(client, clientname, sizeof(clientname));
	
	NoClipThisLife[client] = 0;
	
	//player was Hulk before but now he changed class
	if(client_rolls[client][AWARD_G_HULK][0])
	{
		if(TF2_GetPlayerClass(client) == TFClass_Heavy)
		{
			client_rolls[client][AWARD_G_SPEED][0] = 1;
			ROFMult[client] = 2.0;
			
			SetEntityGravity(client, 0.6);
			Colorize(client, GREEN);
		}else{
			client_rolls[client][AWARD_G_HULK][0] = 0;
			Colorize(client, NORMAL);
			SetEntityGravity(client, 1.0);
		}
	}
	
	//Team manager
	if (IsBlocked(client))
	{
		if(IsClientInGame(client) && IsValidTeam(client) && g_BlockTeam[client] != GetClientTeam(client))
		{
			PrintToChat(client, "\x01\x04[Scramble]\x01 You are currently being blocked from swapping teams");
			ChangeClientTeam(client, g_BlockTeam[client]);
			TF2_RespawnPlayer(client);
		}
	}
	
	autoBalanced[client] = false;
	
	
	if(GetConVarInt(c_Enabled))
	{	
		if(client_rolls[client][AWARD_G_SPEED][0])
		{
			RemoveLifetimeRolls(client);
			RTD_Timer[client] = GetTime();
			
			decl String:message[200];
			Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Effect_Off", LANG_SERVER, cLightGreen, client, cDefault);
			
			SayText2(client, message);
		}
	}
	
	if(beingSlowCubed[client])
	{
		inSlowCube[client] = 0;
		beingSlowCubed[client] = 0;
		SetEntityGravity(client, 1.0);
	}
	
	if(client_rolls[client][AWARD_G_BACKPACK][0])
	{
		if(IsValidEntity(client_rolls[client][AWARD_G_BACKPACK][1]))
		{
			new currIndex = GetEntProp(client_rolls[client][AWARD_G_BACKPACK][1], Prop_Data, "m_nModelIndex");
			
			if(currIndex == backpackModelIndex[0] || currIndex == backpackModelIndex[1] || currIndex == backpackModelIndex[2] || currIndex == backpackModelIndex[3])
			{
				new String:playerName[128];
				Format(playerName, sizeof(playerName), "target%i", client);
				DispatchKeyValue(client, "targetname", playerName);
				
				CAttach(client_rolls[client][AWARD_G_BACKPACK][1], client, "flag");
			}else{
				//PrintToChatAll("Shield Changed Entities damn it!");
				SpawnAndAttachBackpack(client);
			}
		}else{
			SpawnAndAttachBackpack(client);
		}
	}
	
	if(client_rolls[client][AWARD_G_JETPACK][0])
	{
		new jetpack = EntRefToEntIndex(client_rolls[client][AWARD_G_JETPACK][1]);
		new clientJetpack = EntRefToEntIndex(client_rolls[client][AWARD_G_JETPACK][3]);
		
		if(jetpack > 1 && clientJetpack > 1)
		{
			if(IsValidEntity(jetpack) && IsValidEntity(clientJetpack))
			{
				CAttach(jetpack, client, "flag");
				CAttach(clientJetpack, client, "flag");
				
			}else{
				SpawnAndAttachJetpack(client, client_rolls[client][AWARD_G_JETPACK][6], client_rolls[client][AWARD_G_JETPACK][7]);
			}
		}else{
			SpawnAndAttachJetpack(client, client_rolls[client][AWARD_G_JETPACK][6], client_rolls[client][AWARD_G_JETPACK][7]);
		}
	}
	
	//trinket handling
	if(rtd_trinket_enabled)
	{
		if(RTD_TrinketActive[client][TRINKET_EXPLOSIVEDEATH])
		{	
			RTD_TrinketMisc[client][TRINKET_EXPLOSIVEDEATH] = 0;
			SpawnAndAttachDynamite(client);
		}
	}
	
	if(client_rolls[client][AWARD_G_WINGS][0])
	{
		if(IsValidEntity(client_rolls[client][AWARD_G_WINGS][1]))
		{
			new currIndex = GetEntProp(client_rolls[client][AWARD_G_WINGS][1], Prop_Data, "m_nModelIndex");
			
			if(currIndex == wingsModelIndex)
			{
				new String:playerName[128];
				Format(playerName, sizeof(playerName), "target%i", client);
				DispatchKeyValue(client, "targetname", playerName);
				
				CAttach(client_rolls[client][AWARD_G_WINGS][1], client, "flag");
			}else{
				//PrintToChatAll("Shield Changed Entities damn it!");
				SpawnAndAttachWings(client);
			}
		}else{
			SpawnAndAttachWings(client);
		}
	}
	
	if(client_rolls[client][AWARD_G_BLIZZARD][0])
	{
		if(IsValidEntity(client_rolls[client][AWARD_G_BLIZZARD][1]))
		{
			new currIndex = GetEntProp(client_rolls[client][AWARD_G_BLIZZARD][1], Prop_Data, "m_nModelIndex");
			
			if(currIndex == blizzardModelIndex[0] || currIndex == blizzardModelIndex[1])
			{
				new String:playerName[128];
				Format(playerName, sizeof(playerName), "target%i", client);
				DispatchKeyValue(client, "targetname", playerName);
				
				CAttach(client_rolls[client][AWARD_G_BLIZZARD][1], client, "flag");
				
			}else{
				//PrintToChatAll("Shield Changed Entities damn it!");
				SpawnAndAttachBlizzard(client);
			}
		}else{
			SpawnAndAttachBlizzard(client);
		}
	}
	
	if(client_rolls[client][AWARD_G_TREASURE][0])
	{
		new chest = EntRefToEntIndex(client_rolls[client][AWARD_G_TREASURE][1]);
		
		new client_chest = EntRefToEntIndex(client_rolls[client][AWARD_G_TREASURE][2]);
		
		if(client_chest > 0 && IsValidEntity(client_chest))
		{
			new currIndex = GetEntProp(client_chest, Prop_Data, "m_nModelIndex");
			
			if(currIndex == modelIndex[53] || currIndex == modelIndex[54])
			{
				new String:playerName[128];
				Format(playerName, sizeof(playerName), "target%i", client);
				DispatchKeyValue(client, "targetname", playerName);
				
				CDetach(client_chest);
				CAttach(client_chest, client, "flag");
				
			}else{
				//PrintToChatAll("Shield Changed Entities damn it!");
				//CreateTimer(1.0, waitAndAttachTreasure, GetClientUserId(client));
			}
		}else{
			//CreateTimer(1.0, waitAndAttachTreasure, GetClientUserId(client));
		}
		
		if(chest > 0 && IsValidEntity(chest))
		{
			new currIndex = GetEntProp(chest, Prop_Data, "m_nModelIndex");
			
			if(currIndex == modelIndex[53] || currIndex == modelIndex[54])
			{
				new String:playerName[128];
				Format(playerName, sizeof(playerName), "target%i", client);
				DispatchKeyValue(client, "targetname", playerName);
				
				CDetach(chest);
				CAttach(chest, client, "flag");
				
			}else{
				//PrintToChatAll("Shield Changed Entities damn it!");
				CreateTimer(1.0, waitAndAttachTreasure, GetClientUserId(client));
			}
		}else{
			CreateTimer(1.0, waitAndAttachTreasure, GetClientUserId(client));
		}
	}
	
	if(client_rolls[client][AWARD_G_SPIDER][1] != 0)
	{
		new spiderEntity = EntRefToEntIndex(client_rolls[client][AWARD_G_SPIDER][1]);
		
		if(IsValidEntity(spiderEntity))
		{
			new currIndex = GetEntProp(spiderEntity, Prop_Data, "m_nModelIndex");
			
			if(currIndex == spiderBackIndex)
			{
				new String:playerName[128];
				Format(playerName, sizeof(playerName), "target%i", client);
				DispatchKeyValue(client, "targetname", playerName);
				
				CDetach(spiderEntity);
				CAttach(spiderEntity, client, "flag");
			}else{
				AttachSpiderToBack(client, 500 + RTD_Perks[client][15], 500 + RTD_Perks[client][15]);
			}
		}else{
			AttachSpiderToBack(client, 500 + RTD_Perks[client][15], 500 + RTD_Perks[client][15]);
		}
	}
	
	if(client_rolls[client][AWARD_G_COW][1] != 0)
	{
		ResetClientSpeed(client);
		new cowEntity = EntRefToEntIndex(client_rolls[client][AWARD_G_COW][1]);
		
		if(IsValidEntity(cowEntity))
		{
			new currIndex = GetEntProp(cowEntity, Prop_Data, "m_nModelIndex");
			
			if(currIndex == cowOnBackModelIndex)
			{
				new String:playerName[128];
				Format(playerName, sizeof(playerName), "target%i", client);
				DispatchKeyValue(client, "targetname", playerName);
				
				CDetach(cowEntity);
				CAttach(cowEntity, client, "flag");
			}else{
				if(RTD_Perks[client][17])
				{
					AttachCowToBack(client, 1000, 1000);
				}else{
					AttachCowToBack(client, 800, 800);
				}
			}
		}else{
			if(RTD_Perks[client][17])
			{
				AttachCowToBack(client, 1000, 1000);
			}else{
				AttachCowToBack(client, 800, 800);
			}
		}
	}
	
	if(client_rolls[client][AWARD_G_MEDIRAY][0])
	{
		if(TF2_GetPlayerClass(client) != TFClass_Medic)
			client_rolls[client][AWARD_G_MEDIRAY][0] = 0;
		
		if(isClientOwnerOf(client, MODEL_MEDIRAY) == -1)
			equipMediray(client);
	}
	
	if(client_rolls[client][AWARD_G_STONEWALL][0])
	{
		if(IsValidEntity(client_rolls[client][AWARD_G_STONEWALL][1]))
		{
			new currIndex = GetEntProp(client_rolls[client][AWARD_G_STONEWALL][1], Prop_Data, "m_nModelIndex");
			
			if(currIndex == stonewallModelIndex[0] || currIndex == stonewallModelIndex[1])
			{
				new String:playerName[128];
				Format(playerName, sizeof(playerName), "target%i", client);
				DispatchKeyValue(client, "targetname", playerName);
				
				CAttach(client_rolls[client][AWARD_G_STONEWALL][1], client, "flag");
			}else{
				//PrintToChatAll("Shield Changed Entities damn it!");
				CreateTimer(1.0, waitAndAttachStoneWall, GetClientUserId(client));
			}
		}else{
			CreateTimer(1.0, waitAndAttachStoneWall, GetClientUserId(client));
		}
	}
	
	UpdateWaist(client);
	
	RTD_TrinketEquipTime[client] = 0;
	
	CreateTimer(0.1,  	Timer_DelayTrinketEquip, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action:Event_PlayerSappedObject(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "ownerid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client || !attacker)
		return Plugin_Continue;
	
	if (client_rolls[client][AWARD_G_CLASSIMMUNITY][0])
	{
		if(attacker <= (MaxClients + 1) && attacker > 0){
			if(client_rolls[client][AWARD_G_CLASSIMMUNITY][1] == GetEntProp(attacker, Prop_Send, "m_iClass"))
			{
				new String:inflictorname[32];
				GetClientName(client, inflictorname, sizeof(inflictorname));
				
				SetHudTextParams(0.32, 0.82, 1.0, 250, 250, 210, 255);
				ShowHudText(attacker, HudMsg3, "%s is immune to your attacks", inflictorname);

				new sapper_ent = -1;
				new sentry_owner, sentry_sapper, tele_owner, tele_sapper, dispenser_owner, dispenser_sapper, sapper_built_on;
				while ((sapper_ent = FindEntityByClassname(sapper_ent, "obj_attachment_sapper")) != -1)
				{
					sapper_built_on = GetEntDataEnt2(sapper_ent, FindSendPropOffs("CObjectSapper","m_hBuiltOnEntity"));
					if(sapper_built_on == -1)
						break;
					
					sentry_owner = GetEntDataEnt2(sapper_built_on, FindSendPropOffs("CObjectSentrygun","m_hBuilder"));
					sentry_sapper = GetEntData(sapper_built_on, FindSendPropOffs("CObjectSentrygun","m_bHasSapper"));
					if(sentry_owner == client && sentry_sapper)
					{
						break;
					}
					tele_owner = GetEntDataEnt2(sapper_built_on, FindSendPropOffs("CObjectTeleporter","m_hBuilder"));
					tele_sapper = GetEntData(sapper_built_on, FindSendPropOffs("CObjectTeleporter","m_bHasSapper"));
					if(tele_owner == client && tele_sapper)
					{
						break;
					}
					dispenser_owner = GetEntDataEnt2(sapper_built_on, FindSendPropOffs("CObjectDispenser","m_hBuilder"));
					dispenser_sapper = GetEntData(sapper_built_on, FindSendPropOffs("CObjectDispenser","m_bHasSapper"));
					if(dispenser_owner == client && dispenser_sapper)
					{
						break;
					}
				}
				if(IsValidEntity(sapper_ent))
					AcceptEntityInput(sapper_ent,"kill");
			}
		}
		
	}
	return Plugin_Continue;
}

/*
public Action:Event_PlayerDeath_Pre(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetEventInt(event, "inflictor_entindex");
	
	//new customkill = GetEventInt(event, "customkill");
	//SetEventInt(event, "customkill", 0);
	new iWeapon = GetEntDataEnt2(attacker, FindSendPropInfo("CTFPlayer", "m_hActiveWeapon"));
	if(IsValidEntity(iWeapon))
	{
		if(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex") == 169)
		{
			SetEventString(event, "weapon_logclassname", "wrench_golden");
			SetEventString(event, "weapon", "wrench_golden");
		}
	}
}
*/

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new death_ringer = GetEventInt(event, "death_flags");
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	
	lastAttackerOnPlayer[client] = attacker;
	
	//trinket handling
	if(rtd_trinket_enabled && !IsEntLimitReached())
	{
		if(client > 0 && client <= MaxClients && attacker > 0 && attacker <= MaxClients && client != attacker)
		{
			if(IsClientInGame(client) && IsClientInGame(attacker))
			{
				new playerHigherTrinket;
				
				if(RTD_TrinketActive[attacker][TRINKET_PARTYTIME] && RTD_TrinketActive[assister][TRINKET_PARTYTIME])
				{
					if(RTD_TrinketLevel[attacker][TRINKET_PARTYTIME] >= RTD_TrinketLevel[assister][TRINKET_PARTYTIME])
					{
						playerHigherTrinket = attacker;
					}else{
						playerHigherTrinket = assister;
					}
				}else{
					if(!RTD_TrinketActive[attacker][TRINKET_PARTYTIME] && RTD_TrinketActive[assister][TRINKET_PARTYTIME])
						playerHigherTrinket = assister;
					
					if(!RTD_TrinketActive[attacker][TRINKET_PARTYTIME] && !RTD_TrinketActive[assister][TRINKET_PARTYTIME])
						playerHigherTrinket = attacker;
				}
				
				if(playerHigherTrinket == 0)
					playerHigherTrinket = attacker;
				
				if(RTD_TrinketActive[playerHigherTrinket][TRINKET_PARTYTIME])
				{
					for(new i = 0; i <= RTD_TrinketLevel[playerHigherTrinket][TRINKET_PARTYTIME]; i++)
					{
						switch(GetRandomInt(1,3))
						{
							case 1:
								AttachFastParticle(client, "finishline_confetti", 2.0);
							
							case 2:
								AttachFastParticle(client, "bday_confetti", 2.0);
								
							case 3:
								AttachFastParticle(client, "bday_balloon02", 2.0);
						}
					}
				}
				
				if(RTD_TrinketActive[attacker][TRINKET_BLOODTHIRSTER] && !(death_ringer & 32))
				{
					addHealthPercentage(attacker, float(RTD_TrinketBonus[attacker][TRINKET_BLOODTHIRSTER])/100.0, true);
				}
				//AttachTempParticle(client,"finishline_confetti",2.0, false,"",0.0, false);
			}
		}
	}
	
	//PrintToChatAll("DEBUG: Client :%i | ATTACKER :%i | death_ringer:%i", client, attacker, death_ringer);
	
	if(death_ringer & 32)
		return Plugin_Continue;
	
	if (yoshi_eaten[client][0])
		Yoshi_BreakEgg(client);
	
	if(RTDOptions[attacker][4] && !isPlayerHolding_UniqueWeapon(attacker, 225))
		CreateTimer(0.0, Dissolve, client); 
	
	//new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	
	new customkill = GetEventInt(event, "customkill");
	new weaponid = GetEventInt(event, "weaponid");
	new death_flags = GetEventInt(event, "death_flags");
	new damagebits  = GetEventInt(event, "damagebits");
	
	//customkill 6 = suicide
	//PrintToChatAll("Event_PlayerDeath:%i | attacker:%i | weaponid:%i | customkill:%i | death_flags:%i | damagebits:%i", client,attacker,weaponid,customkill,death_flags, damagebits);
	
	SetHudTextParams(HUDxPos[client][0], HUDyPos[client][0], 0.1, 0, 255, 0, 255);
	ShowHudText(client, HudMsg1, "");
	
	SetHudTextParams(HUDxPos[client][1], HUDyPos[client][1], 3.0, 250, 250, 210, 255);
	ShowHudText(client, HudMsg2, "");
	
	//PrintToChatAll("%i",assister);
	new String:clientname[32];
	GetClientName(client, clientname, sizeof(clientname));

	if(g_bSaveRollsOnDeath)
	{
		PrintToChat(client, "Your RTD effects have been carried over through your untimely demise.");
		return Plugin_Continue;
	}
	
	//If player was autobalanced then let's not remove any RTD effects attached to them
	//the 1st part is called when changing teams 
	//g_bBlockDeath is used to prevent roll loss on scramble
	if(client == attacker && weaponid == 0 && customkill == 6 && death_flags == 0 && roundEnded || g_bBlockDeath)
	{
		PrintToChat(client, "You were balanced but your RTD effects have been carried over");
		autoBalanced[client] = true;
		return Plugin_Continue;
	}
	
	if(roundEnded)
	{
		PrintCenterText(client, "You died but your RTD effects will be carried over!");
		autoBalanced[client] = true;
		
		return Plugin_Continue;
	}
	
	autoBalanced[client] = false;
	//LogToFile(logPath,"Entering Event_PlayerDeath| Name: %s | Client:%i | Attacker: %i | Assister: %i | DeathFlags: %i",clientname, client, attacker, assister,death_ringer);
	
	//Keeps track of whether an item was spawned on death
	//Only one item can be spawned
	new bool:spawnedItem = false;
	
	if(client > 0 && client <= MaxClients && attacker > 0 && attacker <= MaxClients && client != attacker)
	{
		if(IsClientInGame(client) && IsClientInGame(attacker))
		{
			//trinket handling
			if(rtd_trinket_enabled)
			{
				if(RTD_TrinketActive[client][TRINKET_EXPLOSIVEDEATH])
				{
					SpawnExplodingDynamite(client);
				}
			}
			
			//presents and coin spawns
			if(!IsEntLimitReached())
			{
				//determine spawn for coin if attacker has treasure chest
				if(!spawnedItem && client_rolls[attacker][AWARD_G_TREASURE][0])
					spawnedItem = determineCoinSpawn(client, attacker, 0);
				
				//determine spawn for coin if assister has treasure chest
				if(assister != 0)
				{
					if(!spawnedItem && client_rolls[assister][AWARD_G_TREASURE][0])
						spawnedItem = determineCoinSpawn(client, assister, 1);
				}
				
				if(!spawnedItem)
					spawnedItem = DetermineQuestionBlockSpawn(client, attacker);
				
				//Chance for Small health on kill perk
				if(!spawnedItem)
				{
					if(RTD_Perks[client][3] != 0 && attacker != client && GetRandomInt(0, 100) > (100-(RTD_Perks[client][3])))
					{
						TF_SpawnMedipack(client, "item_healthkit_small", true);
						spawnedItem = true;
					}
				}
			}
			
			//sentry Wrench
			if(client_rolls[attacker][AWARD_G_SENTRYWRENCH][0] && GetTime() > client_rolls[attacker][AWARD_G_SENTRYWRENCH][6])
			{
				new iWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
				
				if(damagebits&DMG_CLUB)
				{	
					if(IsValidEntity(iWeapon))
					{
						//new itemDefinition = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
						
						client_rolls[attacker][AWARD_G_SENTRYWRENCH][6] = GetTime() + 20;
						
						switch(RTD_PerksLevel[attacker][51])
						{
							case 1:
							{
								BuildSentry(attacker, 0, 1, 60);
							}
							
							case 2:
							{
								BuildSentry(attacker, 0, 2, 40);
							}
							
							case 3:
							{
								BuildSentry(attacker, 0, 3, 30);
							}
							
							default:
							{
								BuildSentry(attacker, 1, 1, 60);
							}
						}
					}
				}
			}
			
			if(rtd_Event_MLK)
			{
				if(TF2_GetPlayerClass(attacker) == TFClass_DemoMan)
				{
					Spawn_FriedChicken(client);
				}
			}
		}
	}
	
	RemoveLifetimeRolls(client);
	
	Colorize(client, NORMAL);
	SetEntityGravity(client, 1.0);
	DeleteParticle(client, "all");
	
	//Reset RTD Timer on death perk
	if(RTD_PerksLevel[client][53] >= 0 && attacker != client)
	{
		//1/10 chance
		if(GetRandomInt(1, 10) == 5)
			RTD_Timer[client]= 0;
	}
	
	RTD_TrinketEquipTime[client] = 0;
	
	return Plugin_Continue;
}

public onFlagPickup (const String:output[], caller, activator, Float:delay)
{
	new client = GetEntPropEnt(caller, Prop_Data, "m_pParent");
	
	//PrintToChatAll("%i %i %i",activator, caller, client);
	if(GetEntityMoveType(client) == MOVETYPE_NOCLIP)
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		client_rolls[client][AWARD_G_NOCLIP][0] = 0;
		
		new Float:pos[3];
		GetClientEyePosition(client, pos);
		
		pos[2] += 30.0;
		
		new Float:Direction[3];
		Direction[0] = pos[0];
		Direction[1] = pos[1];
		Direction[2] = pos[2]-1024;
		
		new Float:floorPos[3];
		
		new Handle:Trace = TR_TraceRayFilterEx(pos, Direction, MASK_SOLID, RayType_EndPoint, TraceFilterAll, client);
		TR_GetEndPosition(floorPos, Trace);
		CloseHandle(Trace);
		
		floorPos[2] += 30.0;
		
		TeleportEntity(client, floorPos, NULL_VECTOR, NULL_VECTOR);
		
		centerHudText(client, "NoClip lost due to intel pickup!", 0.0, 7.0, HudMsg3, 0.5); 
	}
}

public Event_Change_Loadout(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client)
		return;
	
	//wait until next frame
	CreateTimer(0.0,waitHealthAdjust, client);
}

public SendObjectDestroyedEvent(attacker, object, String:weapon[])
{
	new Handle:event = CreateEvent("object_destroyed");
	if (event == INVALID_HANDLE)
		return;
	
	if(attacker < 1 || attacker > MaxClients)
		return;
	
	SetEventInt(event, "index", object);
	
	SetEventInt(event, "userid", GetClientUserId(attacker));
	SetEventInt(event, "attacker", GetClientUserId(attacker));
	SetEventString(event, "weapon", weapon);
	SetEventInt(event, "objecttype", -1);
	
	FireEvent(event);
	
	return;
}

public Action:EventHighFiveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	//new initiator	=	GetClientOfUserId(GetEventInt(event, "initiator_entindex"));
	//new partner		=	GetClientOfUserId(GetEventInt(event, "partner_entindex"));
	
	new initiator	=	GetEventInt(event, "initiator_entindex");
	new partner		=	GetEventInt(event, "partner_entindex");
	
	//add 25% health
	addHealthPercentage(initiator, 0.25, true);
	addHealthPercentage(partner, 0.25, true);
}
