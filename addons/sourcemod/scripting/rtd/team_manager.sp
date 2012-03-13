GetClientScrambleScore(client)
{
	return TF2_GetPlayerResourceData(client, TFResource_TotalScore);
}

stock ScramblePlayers()
{
	PrintToChatAll("\x01\x04[Scramble]\x01 Teams are being Scrambled!");
	EmitSoundToAll(SCRAMBLE_SOUND, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL); // TEAMS ARE BEING SCRAMBLED!
	
	new iCount, iSwaps, client;
	new iValidPlayers[GetClientCount()];
	
	SetRandomSeed(GetTime());
	new bool:bTeam = GetRandomInt(0,1) == 0;
	
	for(new i=1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsValidTeam(i))
		{
			iValidPlayers[iCount++] = i;
		}
	}
	
	new scoreArray[iCount][2];
	for(new i=0; i < iCount; i++)
	{
		client = iValidPlayers[i];
		SetRandomSeed(GetTime());
		new diceValue = (RTDdice[client] < 500) ? 10 : (RTDdice[client] < 1000) ? 8 : (RTDdice[client] < 1500) ? 6 : 4;
		
		scoreArray[i][0] = client;
		scoreArray[i][1] = (RTDdice[client] / diceValue) + (GetClientScrambleScore(client) * 3) + (GetRandomInt(-100, 100) * ScrambleMultiplier);
		
	}
	
	SortCustom2D(_:scoreArray, iCount, SortScoreDesc);
	/*
	for(new i=0; i < iCount; i++)
	{
		PrintToChatAll("CLIENT %N ||  Value %d", scoreArray[i][0], scoreArray[i][1]);
	}
	*/
	for(new i=0; i < iCount; i++)
	{
		client = scoreArray[i][0];
		if(IsClientInGame(client) && IsValidTeam(client))
		{
			g_bBlockDeath = true;
			ChangeClientTeam(client, bTeam ? RED_TEAM:BLUE_TEAM);
			bTeam = !bTeam;
			g_bBlockDeath = false;
			iSwaps++;
		}
	}

	BlockAllTeamChange();
	
	ScrambleMultiplier++;
}


public Action:Event_Pre_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bBlockDeath)
	{
		if (!dontBroadcast)
		{
			new Handle:hEvent = CreateEvent("player_team"), String:clientName[MAX_NAME_LENGTH + 1], 
				userId = GetEventInt(event, "userid"), client = GetClientOfUserId(userId);
			if (hEvent != INVALID_HANDLE)
			{
				GetClientName(client, clientName, sizeof(clientName));
				SetEventInt(hEvent, "userid", userId);
				SetEventInt(hEvent, "team", GetEventInt(event, "team"));
				SetEventInt(hEvent, "oldteam", GetEventInt(event, "oldteam"));
				SetEventBool(hEvent, "disconnect", GetEventBool(event, "disconnect"));
				SetEventBool(hEvent, "autoteam", GetEventBool(event, "autoteam"));
				SetEventBool(hEvent, "silent", GetEventBool(event, "silent"));
				SetEventString(hEvent, "name", clientName);
				FireEvent(hEvent, true);
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Event_Pre_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if (g_bBlockDeath)
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action:Event_TeamBalanced(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "player");
	new iTeam = GetEventInt(event, "team");
	if(IsBlocked(client) && IsClientConnected(client))
	{
		if(IsClientInGame(client))
		{
			g_BlockTime[client] = GetTime() + 300;
			g_BlockTeam[client] = iTeam;
		}
	}
	return Plugin_Continue;
}


bool:IsValidTeam(client)
{
	new team = GetClientTeam(client);
	if (team == RED_TEAM || team == BLUE_TEAM)
		return true;
	return false;
}

public SortIntsDesc(x[], y[], array[][], Handle:data)		// this sorts everything in the info array descending
{
	if (x[1] > y[1]) 
		return -1;
	else if (x[1] < y[1]) 
		return 1;
	return 0;
}

stock BlockAllTeamChange()
{
	for (new i=1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsValidTeam(i) || IsFakeClient(i))
			continue;
		else
			SetupTeamSwapBlock(i);
	}
}

SetupTeamSwapBlock(client)  /* blocks proper clients from team swapping*/
{
	g_BlockTime[client] = GetTime() + 300;
	g_BlockTeam[client] = GetClientTeam(client);
}

bool:IsBlocked(client)
{

	if (g_BlockTime[client] > GetTime())
		return true;
	return false;
}

public Action:JoinTeam_Listener(client, const String:command[], argc)
{
	if(IsFakeClient(client))
		return Plugin_Continue;

	if (IsValidTeam(client) && IsBlocked(client) && CheckImbalance())
	{
		/**
		allow clients to change teams during imbalances
		*/
		g_BlockTime[client] = -1;
		g_BlockTeam[client] = -1;
		return Plugin_Continue;
	}
	return Plugin_Continue;
}


stock CheckImbalance()
{
	new redSize = GetTeamClientCount(RED_TEAM),
		bluSize = GetTeamClientCount(BLUE_TEAM),
		difference;
	difference = GetAbsValue(redSize, bluSize);
	if (difference >= 2)
	{
		return true;
	}
	return false;
}

stock GetAbsValue(value1, value2)
{
	return RoundFloat(FloatAbs(FloatSub(float(value1), float(value2))));
}

DisplayScrambleVoteMenu()
{
	if(IsVoteInProgress())
		return;
	
	new Handle:voteMenu = CreateMenu(Handler_ScrambleVoteCallback, MenuAction:MENU_ACTIONS_ALL);
	
	SetMenuTitle(voteMenu, "Scramble Teams?");
	
	AddMenuItem(voteMenu, VOTE_YES, "Yes");
	AddMenuItem(voteMenu, VOTE_NO, "No");
	SetMenuExitButton(voteMenu, false);
	VoteMenuToAll(voteMenu, 20);
}

public Handler_ScrambleVoteCallback(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		//
	}
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("\x01\x04[Scramble]\x01  No Votes Cast");
	}	
	else if (action == MenuAction_VoteEnd)
	{
		decl String:item[64], String:display[64];
		new Float:percent, Float:limit, votes, totalVotes;

		GetMenuVoteInfo(param2, votes, totalVotes);
		GetMenuItem(menu, param1, item, sizeof(item), _, display, sizeof(display));
		
		if (strcmp(item, VOTE_NO) == 0 && param1 == 1)
		{
			votes = totalVotes - votes; // Reverse the votes to be in relation to the Yes option.
		}
		
		percent = FloatDiv(float(votes),float(totalVotes));

		// A multi-argument vote is "always successful", but have to check if its a Yes/No vote.
		if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent,limit) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
		{
			PrintToChatAll("\x01\x04[Scramble]\x01 Vote failed. %d%% vote required. (Received %d%% of %d votes)", RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
		}
		else
		{
			PrintToChatAll("\x01\x04[Scramble]\x01 Vote successful. Teams will be scrambled next round. (Received %d%% of %d votes)", RoundToNearest(100.0*percent), totalVotes);
			g_bScramblePending = true;
			g_iScrambleDelay = GetTime() + 300;
		}
	}
	
	return 0;
}


/**
||~~~~~~~~~~||
	Unused
||~~~~~~~~~~||

bool:AutoScrambleCheck(winningTeam)
{
	if (g_bFullRoundOnly && !g_bWasFullRound)
		return false;
	if (g_bKothMode)
	{
		if (!g_bRedCapped || !g_bBluCapped)
		{
			decl String:team[3];
			g_bRedCapped ? (team = "BLU") : (team = "RED");
			PrintToChatAll("\x01\x04[SM]\x01 %t", "NoCapMessage", team);
			LogAction(0, -1, "%s did not cap a point on KOTH", team);
			return true;
		}
	}
	new totalFrags = g_aTeams[iRedFrags] + g_aTeams[iBluFrags],
		losingTeam = winningTeam == TEAM_RED ? TEAM_BLUE : TEAM_RED,
		dominationDiffVar = GetConVarInt(cvar_DominationDiff);
	if (dominationDiffVar && totalFrags > 20)
	{
		new winningDoms = TF2_GetTeamDominations(winningTeam),
			losingDoms = TF2_GetTeamDominations(losingTeam);
		if (winningDoms > losingDoms)
		{
			new teamDominationDiff = RoundFloat(FloatAbs(float(winningDoms) - float(losingDoms)));
			if (teamDominationDiff >= dominationDiffVar)
			{
				LogAction(0, -1, "domination difference detected");
				PrintToChatAll("\x01\x04[SM]\x01 %t", "DominationMessage");
				return true;
			}	
		}
	}
	new Float:iDiffVar = GetConVarFloat(cvar_AvgDiff);
	if (totalFrags > 20 && iDiffVar > 0.0 && GetAvgScoreDifference(winningTeam) >= iDiffVar)
	{
		LogAction(0, -1, "Average score diff detected");
		PrintToChatAll("\x01\x04[SM]\x01 %t", "RatioMessage");
		return true;
	}
	new winningFrags = winningTeam == TEAM_RED ? g_aTeams[iRedFrags] : g_aTeams[iBluFrags],
		losingFrags	= winningTeam == TEAM_RED ? g_aTeams[iBluFrags] : g_aTeams[iRedFrags],
		Float:ratio = float(winningFrags) / float(losingFrags),
		iSteamRollVar = GetConVarInt(cvar_Steamroll),
		roundTime = GetTime() - g_iRoundStartTime;
	if (iSteamRollVar && winningFrags > losingFrags && iSteamRollVar >= roundTime && ratio >= GetConVarFloat(cvar_SteamrollRatio))
	{
		new minutes = iSteamRollVar / 60;
		new seconds = iSteamRollVar % 60;
		PrintToChatAll("\x01\x04[SM]\x01 %t", "WinTime", minutes, seconds);
		LogAction(0, -1, "steam roll detected");
		return true;		
	}
	new Float:iFragRatioVar = GetConVarFloat(cvar_FragRatio);
	if (totalFrags > 20 && winningFrags > losingFrags && iFragRatioVar > 0.0)	
	{		
		if (ratio >= iFragRatioVar)
		{
			PrintToChatAll("\x01\x04[SM]\x01 %t", "FragDetection");
			LogAction(0, -1, "Frag ratio detected");
			return true;			
		}
	}
	return false;
}

//Prioritize people based on active buildings, ubercharge, living/dead, or connection time
stock GetPlayerPriority(client)
{
	if (IsFakeClient(client))
		return 0;
	if (g_bUseBuddySystem)
	{
		if (g_aPlayers[client][iBuddy])
		{
			if (GetClientTeam(client) == GetClientTeam(g_aPlayers[client][iBuddy]))
				return -10;
			else if (IsValidTeam(g_aPlayers[client][iBuddy]))
				return 10;
		}
		if (IsClientBuddy(client))
			return -2;
	}
	new iPriority;
	if (IsClientInGame(client) && IsValidTeam(client))
	{
		if (g_aPlayers[client][iBalanceTime] > GetTime())
			return -5;
				
		if (g_aPlayers[client][iTeamworkTime] >= GetTime())
			iPriority -= 3;
			
		if (g_RoundState != bonusRound)
		{
			if (TF2_HasBuilding(client)||TF2_IsClientUberCharged(client)||TF2_IsClientUbered(client)||
				!IsNotTopPlayer(client, GetClientTeam(client))||TF2_IsClientOnlyMedic(client))
				return -10;
			if (!IsPlayerAlive(client))
				iPriority += 5;
			else
			{
				if (g_aPlayers[client][bHasFlag])
				{
					iPriority -= 20;
				}
				iPriority -= 1;
			}
		}		
		//make new clients more likely to get swapped
		if (GetClientTime(client) < 180)		
			iPriority += 5;	
	}
	return iPriority;
}

stock bool:TF2_IsClientUberCharged(client)
{
	if (!IsPlayerAlive(client))
		return false;
	new TFClassType:class = TF2_GetPlayerClass(client);
	if (class == TFClass_Medic)
	{			
		new iIdx = GetPlayerWeaponSlot(client, 1);
		if (iIdx > 0)
		{
			decl String:sClass[33];
			GetEntityNetClass(iIdx, sClass, sizeof(sClass));
			if (StrEqual(sClass, "CWeaponMedigun", true))
			{
				new Float:chargeLevel = GetEntPropFloat(iIdx, Prop_Send, "m_flChargeLevel");
				if (chargeLevel >= 0.55)	
				{
					return true;
				}
			}
		}
	}
	return false;
}

stock bool:TF2_IsClientUbered(client)
{
	if (GetEntProp(client, Prop_Send, "m_nPlayerCond") & 32)
		return true;
	return false;
}

stock bool:TF2_ClientBuilding(client, const String:building[])
{
	new iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, building)) != -1)
	{
		if (GetEntDataEnt2(iEnt, FindSendPropInfo("CBaseObject", "m_hBuilder")) == client)
			return true;
	}
	return false;
}

stock TF2_GetPlayerDominations(client)
{
	new offset = FindSendPropInfo("CTFPlayerResource", "m_iActiveDominations"),
		ent = FindEntityByClassname(-1, "tf_player_manager");
	if (ent != -1)
		return GetEntData(ent, (offset + client*4), 4);
	return 0;
}

stock TF2_GetTeamDominations(team)
{
	new dominations;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team)
			dominations += TF2_GetPlayerDominations(i);
	}
	return dominations;
}
*/