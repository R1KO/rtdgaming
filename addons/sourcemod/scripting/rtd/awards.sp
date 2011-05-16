#include <rtd_rollinfo>

new awardsCount = 0;
new awardsID[255]; //id
new awardsInformation[255][5]; //id, value
new String:strAwardsInformation[255][2][255]; //id, value, buffer

//Trigers loading the Awards
stock LoadAwards()
{
	new String:sqlQuery[255];
	Format(sqlQuery, sizeof(sqlQuery), "SELECT * FROM `awards`");
	SQL_TQuery(db, LoadAwardsQuery, sqlQuery, _);
}

//Query Handler for Load Awards
public LoadAwardsQuery(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logPath,"[AWARDS] Query failed! %s", error);
	}
	else 
	{
		while(SQL_FetchRow(hndl))
		{
			new String:awardName[255];
			new String:awardCode[255];
			SQL_FetchString(hndl, 1, awardName, sizeof(awardName));
			SQL_FetchString(hndl, 5, awardCode, sizeof(awardCode));
			
			strAwardsInformation[awardsCount][0] = awardName;
			strAwardsInformation[awardsCount][1] = awardCode;
			
			awardsInformation[awardsCount][0] = SQL_FetchInt(hndl, 0); //Award ID
			awardsInformation[awardsCount][1] = SQL_FetchInt(hndl, 2); //Begin Timestamp
			awardsInformation[awardsCount][2] = SQL_FetchInt(hndl, 3); //End Timestamp
			awardsInformation[awardsCount][3] = SQL_FetchInt(hndl, 4); //Static
			awardsInformation[awardsCount][4] = SQL_FetchInt(hndl, 6); //Times Awarded
			
			awardsID[SQL_FetchInt(hndl, 0)] = awardsCount;
			//PrintToChatAll("RTD DEBUG Award %d - Name %s - Code %s - Bstamp %d - EStamp %d - Static %d - TimesAwarded %d", SQL_FetchInt(hndl, 0), awardName, awardCode, SQL_FetchInt(hndl, 2), SQL_FetchInt(hndl, 3), SQL_FetchInt(hndl, 4), SQL_FetchInt(hndl, 6));
			awardsCount++;
		}
	}
}

//This function queries to see if there is a code in the database
stock AwardCheck(client, String:code[128])
{
	new String:sqlQuery[255];
	new String:steamId[MAX_LINE_WIDTH];
	
	GetClientAuthString(client, steamId, sizeof(steamId));
	SQL_EscapeString(db, code, code, sizeof(code));
	
	new Handle:dataPack = CreateDataPack();
	WritePackCell(dataPack, client);
	WritePackString(dataPack, code);

	//Checks for a difference between static and non static codes
	if(StrContains(code, "-0-", false) != -1)
	{
		WritePackCell(dataPack, 0);
		new bool:foundAward;
		for(new i = 0; i < awardsCount; i++)
		{
			if(StrEqual(code, strAwardsInformation[i][1], false))
			{
				if(awardsInformation[i][1] != 0 && awardsInformation[i][1] > GetTime())
				{
					PrintToChat(client, "%c[RTD][AWARDS]%c This code is not yet valid.", cGreen, cDefault);
					CloseHandle(dataPack);
				}
				else if(awardsInformation[i][2] != 0 && awardsInformation[i][2] < GetTime())
				{
					PrintToChat(client, "%c[RTD][AWARDS]%c This code has expired.", cGreen, cDefault);
					CloseHandle(dataPack);
				}
				else
				{
					WritePackCell(dataPack, awardsInformation[i][0]);
					Format(sqlQuery, sizeof(sqlQuery), "SELECT * FROM `awards_received` WHERE `steamid` = '%s' AND `code` = '%s' LIMIT 1", steamId, code);
					SQL_TQuery(db, AwardCheckQuery, sqlQuery, dataPack);
				}
				foundAward = true;
				break;
			}
		}
		if(!foundAward)
		{
			PrintToChat(client, "%c[RTD][AWARDS]%c Unable to find code in database.", cGreen, cDefault);
			CloseHandle(dataPack);
		}
	}
	else if(StrContains(code, "-1-", false) != -1)
	{
		WritePackCell(dataPack, 1);
		Format(sqlQuery, sizeof(sqlQuery), "SELECT * FROM `awards_received` WHERE `steamid` = '%s' AND `code` = '%s' LIMIT 1", steamId, code);
		SQL_TQuery(db, AwardCheckQuery, sqlQuery, dataPack);
	}
	else
	{
		PrintToChat(client, "%c[RTD][AWARDS]%c Invalid Code.", cGreen, cDefault);
		CloseHandle(dataPack);
	}
}

//Query Handler for Award checking
public AwardCheckQuery(Handle:owner, Handle:hndl, const String:error[], any:dataPack)
{
	new String:sqlQuery[255];
	new String:steamId[MAX_LINE_WIDTH];
	
	ResetPack(dataPack);
	new client = ReadPackCell(dataPack);
	new String:code[255];
	ReadPackString(dataPack, code, sizeof(code));
	new type = ReadPackCell(dataPack);
	
	GetClientAuthString(client, steamId, sizeof(steamId));
	
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logPath,"[AWARDS] Query failed! %s", error);
	}
	else 
	{
		if(!SQL_GetRowCount(hndl))
		{
			if(type == 0)
			{
				new award = ReadPackCell(dataPack);
				//Clears the datapack data from above to use the same handle
				ResetPack(dataPack, true);
				WritePackCell(dataPack, client);
				WritePackCell(dataPack, award);
				WritePackString(dataPack, code);
				WritePackCell(dataPack, 0);
			
				Format(sqlQuery, sizeof(sqlQuery), "INSERT INTO `awards_received` (`steamid`, `code`, `award`, `awarded`) VALUES ('%s', '%s', %d, 1)", steamId, code, award);
				SQL_TQuery(db, GenericAwardQuery, sqlQuery, dataPack);
			}
			else if(type == 1)
			{
				PrintToChat(client, "%c[RTD][AWARDS]%c Unable to find code in database.", cGreen, cDefault);
				CloseHandle(dataPack);
			}
		}
		else
		{
			
			if(type == 0)
			{
				PrintToChat(client, "%c[RTD][AWARDS]%c You have already been Awarded for this code.", cGreen, cDefault);
				CloseHandle(dataPack);
			}
			else if(type == 1)
			{
				SQL_FetchRow(hndl);
				new awardIndex = awardsID[SQL_FetchInt(hndl, 3)];
				if(awardsInformation[awardIndex][1] != 0 && awardsInformation[awardIndex][1] > GetTime())
					PrintToChat(client, "%c[RTD][AWARDS]%c This code is not yet valid.", cGreen, cDefault);
				else if(awardsInformation[awardIndex][2] != 0 &&awardsInformation[awardIndex][2] < GetTime())
				{
					PrintToChat(client, "%c[RTD][AWARDS]%c This code has expired.", cGreen, cDefault);
					Format(sqlQuery, sizeof(sqlQuery), "DELETE FROM `awards_received` WHERE `steamid` = '%s' AND `code` = '%s' LIMIT 1", steamId, code);
					SQL_TQuery(db, GenericQuery, sqlQuery, _);
				}
				else if(awardsInformation[awardIndex][4] > SQL_FetchInt(hndl, 4))
				{
					//Clears the datapack data from above to use the same handle
					ResetPack(dataPack, true);
					WritePackCell(dataPack, client);
					WritePackCell(dataPack, SQL_FetchInt(hndl, 3));
					WritePackString(dataPack, code);
					WritePackCell(dataPack, SQL_FetchInt(hndl, 4));
					
					Format(sqlQuery, sizeof(sqlQuery), "UPDATE `awards_received` SET `awarded` = %d WHERE `steamid` = '%s' AND `code` = '%s' LIMIT 1", (SQL_FetchInt(hndl, 4)+1), steamId, code);
					SQL_TQuery(db, GenericAwardQuery, sqlQuery, dataPack); 
				}
				else
				{
					PrintToChat(client, "%c[RTD][AWARDS]%c You have already been Awarded for this code.", cGreen, cDefault);
					CloseHandle(dataPack);
				}
			}
		}
	}
}

//Generic Query Handler awards areonly given if there was no error
public GenericAwardQuery(Handle:owner, Handle:hndl, const String:error[], any:dataPack)
{
	ResetPack(dataPack);
	new client = ReadPackCell(dataPack);
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logPath,"[AWARDS] Query failed! %s", error);
		PrintToChat(client, "%c[RTD][AWARDS]%c An error has occured while processing the award. Please try again later.", cGreen, cDefault);
		CloseHandle(dataPack);
	}
	else
	{
		new award = ReadPackCell(dataPack);
		
		GiveAward(client, award, dataPack);
	}
}

//Generic Query Handler
public GenericQuery(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logPath,"[AWARDS] Query failed! %s", error);
	}
}

//Incase the player has the roll already, it is denied and the sql must be reset
stock DenyAward(Handle:dataPack)
{
	new String:sqlQuery[255];
	new String:steamId[MAX_LINE_WIDTH];
	
	ResetPack(dataPack);
	new client = ReadPackCell(dataPack);
	ReadPackCell(dataPack);
	new String:code[255];
	ReadPackString(dataPack, code, sizeof(code));
	new awarded = ReadPackCell(dataPack);

	GetClientAuthString(client, steamId, sizeof(steamId));
	
	if(StrContains(code, "-0-", false) != -1)
	{
		Format(sqlQuery, sizeof(sqlQuery), "DELETE FROM `awards_received` WHERE `steamid` = '%s' AND `code` = '%s' LIMIT 1", steamId, code);
		SQL_TQuery(db, DenyAwardQuery, sqlQuery, dataPack); 
	}
	else if(StrContains(code, "-1-", false) != -1)
	{
		if((awarded-1) < 0)
			awarded = 0;
		else
			awarded -= 1;
		Format(sqlQuery, sizeof(sqlQuery), "UPDATE `awards_received` SET `awarded` = %d WHERE `steamid` = '%s' AND `code` = '%s' LIMIT 1", awarded, steamId, code);
		SQL_TQuery(db, DenyAwardQuery, sqlQuery, dataPack); 
	}
}

//Generic Query Handler awards areonly given if there was no error
public DenyAwardQuery(Handle:owner, Handle:hndl, const String:error[], any:dataPack)
{
	if (hndl == INVALID_HANDLE)
	{
		new String:steamId[MAX_LINE_WIDTH];
		
		ResetPack(dataPack);
		new client = ReadPackCell(dataPack);
		new award = ReadPackCell(dataPack);
		new String:code[255];
		ReadPackString(dataPack, code, sizeof(code));
		
		LogToFile(logPath,"[AWARDS] Query failed! %s", error);
		PrintToChat(client, "%c[RTD][AWARDS]%c An error has occured while trying to reset the award. An Admin please contact an admin on the forum.", cGreen, cDefault);
		LogToFile(logPath,"[AWARDS] DenyAward failed, Award %d - Code %s - SteamId %s", award, code, steamId);
	}
	CloseHandle(dataPack);
}

//Handles the actual giving out of awards
stock GiveAward(client, any:award, Handle:dataPack)
{
	new bool:denyAward;
	switch(award)
	{
		case 1:
		{
			if(client_rolls[client][AWARD_G_BEARTRAP][0])
			{
				PrintCenterText(client, "Please try again after you lose your current Bear Trap.");
				EmitSoundToAll(SOUND_DENY, client);
				denyAward = true;
			}
			else
			{
				client_rolls[client][AWARD_G_BEARTRAP][0] = 1;
				client_rolls[client][AWARD_G_BEARTRAP][1] = 0;
				addDice(client, 3, 5);
				PrintCenterText(client, "You have been awarded a: Bear Trap +5 dice!");
				
				AwardFireworks(client, 20);
			}
		}
		case 2:
		{
			if(client_rolls[client][AWARD_G_BACKPACK][0])
			{
				PrintCenterText(client, "Please try again after you lose your current Backpack.");
				EmitSoundToAll(SOUND_DENY, client);
				denyAward = true;
			}
			else
			{
				PrintCenterText(client, "You have been awarded a: Backpack +5 dice!");
				addDice(client, 3, 5);
				
				client_rolls[client][AWARD_G_BACKPACK][2] = 5;
				client_rolls[client][AWARD_G_BACKPACK][3] = 5;
				SpawnAndAttachBackpack(client);
				
				AwardFireworks(client, 20);
			}
		}
		case 3:
		{
			if(client_rolls[client][AWARD_G_AMPLIFIER][0])
			{
				PrintCenterText(client, "Please try again after you use your current Amplifier.");
				EmitSoundToAll(SOUND_DENY, client);
				denyAward = true;
			}
			else
			{
				PrintCenterText(client, "You have been awarded a: Amplifier +5 dice!");
				addDice(client, 3, 5);
				
				client_rolls[client][AWARD_G_AMPLIFIER][0] = 1;
				
				AwardFireworks(client, 20);
			}
		}
		case 4:
		{
			if(client_rolls[client][AWARD_G_MEDIRAY][0])
			{
				PrintCenterText(client, "Please try again after you use your current Human Dispenser.");
				EmitSoundToAll(SOUND_DENY, client);
				denyAward = true;
			}
			else
			{
				PrintCenterText(client, "You have been awarded a: Human Dispenser +5 dice!");
				addDice(client, 3, 5);
				
				client_rolls[client][AWARD_G_MEDIRAY][0] = 1;
				client_rolls[client][AWARD_G_MEDIRAY][1] = 1;
				equipMediray(client);
				
				AwardFireworks(client, 20);
			}
		}
		case 5:
		{
			PrintCenterText(client, "You have been awarded 5 dice and 20 credits!");
			addDice(client, 3, 5);
			RTDCredits[client] += 20;
			
			AwardFireworks(client, 20);
		}
		case 6:
		{
			new AwardDice = GetRandomInt(30, 45);
			new AwardCredits = GetRandomInt(150, 250);
			PrintCenterText(client, "You have been awarded %d dice, %d credits, and 3 Random Good Rolls!", AwardDice, AwardCredits);
			addDice(client, 3, AwardDice);
			RTDCredits[client] += AwardCredits;
			
			for(new i=0; i < 3;i++)
			{
				amountOfBadRolls[client] = 2.0;
				RollTheDice(client);
			}
			
			AwardFireworks(client, 20);
		}
		case 7:
		{
			new AwardDice = GetRandomInt(10, 20);
			new AwardCredits = GetRandomInt(75, 125);
			PrintCenterText(client, "You have been awarded %d dice, %d credits, and 5 Free Rolls on spawn!", AwardDice, AwardCredits);
			addDice(client, 3, AwardDice);
			RTDCredits[client] += AwardCredits;
			
			//awardTimerReset[client] = 6;
			
			AwardFireworks(client, 20);
		}
		case 8:
		{
			new AwardDice = GetRandomInt(5, 15);
			new AwardCredits = GetRandomInt(25, 100);
			PrintCenterText(client, "You have been awarded %d dice, %d credits, and a Backpack with 50 packs!", AwardDice, AwardCredits);
			addDice(client, 3, AwardDice);
			RTDCredits[client] += AwardCredits;
			
			if(client_rolls[client][AWARD_G_BACKPACK][0])
			{
				client_rolls[client][AWARD_G_BACKPACK][2] += 50;
				client_rolls[client][AWARD_G_BACKPACK][3] += 50;
				
			}
			else
			{
				client_rolls[client][AWARD_G_BACKPACK][2] = 50;
				client_rolls[client][AWARD_G_BACKPACK][3] = 50;
				SpawnAndAttachBackpack(client);
			}
			
			AwardFireworks(client, 20);
		}
		case 9:
		{
			new AwardDice = GetRandomInt(1, 30);
			new AwardCredits = GetRandomInt(100, 300);
			PrintCenterText(client, "You have been awarded %d dice, %d credits, and 10 Proximity Mines!", AwardDice, AwardCredits);
			addDice(client, 3, AwardDice);
			RTDCredits[client] += AwardCredits;
			
			client_rolls[client][AWARD_G_PROXMINES][0] = 1;
			client_rolls[client][AWARD_G_PROXMINES][1] = 10;
			
			AwardFireworks(client, 20);
		}
		case 10:
		{
			new AwardDice = GetRandomInt(1, 10);
			new AwardCredits = GetRandomInt(1, 100);
			PrintCenterText(client, "You have been awarded %d dice, %d credits, and 9 Bombs!", AwardDice, AwardCredits);
			addDice(client, 3, AwardDice);
			RTDCredits[client] += AwardCredits;
			
			client_rolls[client][AWARD_G_BOMB][0] = 1;
			client_rolls[client][AWARD_G_BOMB][1] = 6;
			
			AwardFireworks(client, 20);
		}
		case 12:
		{
			new AwardDice = GetRandomInt(5, 30);
			new AwardCredits = GetRandomInt(50, 200);
			PrintCenterText(client, "You have been awarded %d dice, %d credits, and to much stuff to mention!!!", AwardDice, AwardCredits);
			addDice(client, 3, AwardDice);
			RTDCredits[client] += AwardCredits;

			//awardTimerReset[client] = 12;
			client_rolls[client][AWARD_G_BOMB][0] = 1;
			client_rolls[client][AWARD_G_BOMB][1] = 6;
			
			client_rolls[client][AWARD_G_SENTRYBUILDER][0] = 1;
			client_rolls[client][AWARD_G_SENTRYBUILDER][1] = 1;
			
			
			for(new i=0; i < 5;i++)
			{
				amountOfBadRolls[client] = 2.0;
				RollTheDice(client);
			}
			
			AwardFireworks(client, 60);
		}
		case 13:
		{
			if(RTDdice[client] < 50)
			{
				decl String:message[200];
				new String:name[32];
				GetClientName(client, name, sizeof(name));
				
				Format(message, sizeof(message), "\x01\x04[AWARDS] \x03%s\x04 was awarded \x01200\x04 CREDITS!", name);
				PrintToChatSome(message, client);
				PrintCenterText(client, "You have been awarded 200 credits!!!");
				
				RTDCredits[client] += 200;
				
				AwardFireworks(client, 20);
			}else{
				PrintCenterText(client, "Aww too bad you have too many Dice");
			}
		}
		case 15:
		{
			if(!UnAcceptable(client, AWARD_G_BLIZZARD))
			{
				decl String:message[200];
				new String:name[32];
				GetClientName(client, name, sizeof(name));
				
				Format(message, sizeof(message), "\x01\x04[AWARDS] \x03%s\x04 was awarded \x01BACKPACK BLIZZARD\x04!", name);
				PrintToChatSome(message, client);
				PrintCenterText(client, "You have been awarded Backpack Blizzard!!!");
				
				GivePlayerEffect(client, AWARD_G_BLIZZARD, 0);
				
				AwardFireworks(client, 10);
			}else{
				PrintCenterText(client, "Hmmm try again or once you die...");
			}
		}
		case 16:
		{
			//xmas1
			new AwardDice = GetRandomInt(10, 30);
			new AwardCredits = GetRandomInt(75, 300);
			PrintCenterText(client, "You have been awarded %d dice, %d credits", AwardDice, AwardCredits);
			addDice(client, 3, AwardDice);
			RTDCredits[client] += AwardCredits;
			
			new String:name[32];
			GetClientName(client, name, sizeof(name));
			
			PrintToChatAll("%s was awarded %d dice and %d credits", name, AwardDice, AwardCredits);
			
			AwardFireworks(client, 20);
		}
		case 17:
		{
			//xmas2
			new AwardDice = GetRandomInt(10, 30);
			new AwardCredits = GetRandomInt(75, 500);
			PrintCenterText(client, "You have been awarded %d dice, %d credits", AwardDice, AwardCredits);
			addDice(client, 3, AwardDice);
			RTDCredits[client] += AwardCredits;
			
			new String:name[32];
			GetClientName(client, name, sizeof(name));
			
			PrintToChatAll("%s was awarded %d dice and %d credits", name, AwardDice, AwardCredits);
			
			AwardFireworks(client, 20);
		}
		case 18:
		{
			//xmas3
			new AwardDice = GetRandomInt(10, 20);
			new AwardCredits = GetRandomInt(75, 200);
			PrintCenterText(client, "You have been awarded %d dice, %d credits", AwardDice, AwardCredits);
			addDice(client, 3, AwardDice);
			RTDCredits[client] += AwardCredits;
			
			new String:name[32];
			GetClientName(client, name, sizeof(name));
			
			PrintToChatAll("%s was awarded %d dice and %d credits", name, AwardDice, AwardCredits);
			
			AwardFireworks(client, 20);
		}
		default:
		{
			new String:steamId[MAX_LINE_WIDTH];
			
			ResetPack(dataPack);
			client = ReadPackCell(dataPack);
			ReadPackCell(dataPack);
			new String:code[255];
			ReadPackString(dataPack, code, sizeof(code));
			GetClientAuthString(client, steamId, sizeof(steamId));
			
			PrintToChat(client, "%c[RTD][AWARDS]%c Award code found, but no information regarding this code. An error has been logged.", cGreen, cDefault);
			LogToFile(logPath,"[AWARDS] Award was Tiggered but not found: %d - Code %s - SteamId %s", award, code, steamId);
		}
	}
	if(denyAward)
	{
		DenyAward(dataPack);
	}
	else
	{
		CloseHandle(dataPack);
	}
	
}
stock AwardFireworks(client, duration, playsound=true)
{
	new Handle:dataPackHandle;
	CreateDataTimer(0.7, Timer_AwardFireworks, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPackHandle, client);
	WritePackCell(dataPackHandle, GetTime());
	WritePackCell(dataPackHandle, duration);
	WritePackCell(dataPackHandle, playsound);
	if (playsound)
		EmitSoundToAll(SOUND_GROOVITRON, client, SNDCHAN_AUTO);
}

public Action:Timer_AwardFireworks(Handle:Timer, any:dataPackHandle)
{
	ResetPack(dataPackHandle);
	new client = ReadPackCell(dataPackHandle);
	new spawnTime = ReadPackCell(dataPackHandle);
	new maxLiveTime = ReadPackCell(dataPackHandle);
	new playsounds = ReadPackCell(dataPackHandle);
	
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		StopSound(client, SNDCHAN_AUTO, SOUND_GROOVITRON);
		return Plugin_Stop;
	}
	
	if(GetTime() >= spawnTime + maxLiveTime)
	{
		StopSound(client, SNDCHAN_AUTO, SOUND_GROOVITRON);
		return Plugin_Stop;
	}
	
	AttachTempParticle(client, EFFECT_FIREWORK_FLARE, 0.1, false, "", 0.0, false);
	AttachTempParticle(client, EFFECT_FIREWORK_FLASH, 0.1, false, "", 0.0, false);
	AttachTempParticle(client, EFFECT_FIREWORK, 0.1, false, "", 0.0, true);
	AttachTempParticle(client, EFFECT_FIREWORK, 0.1, false, "", 10.0, true);
	AttachTempParticle(client, EFFECT_FIREWORK, 0.1, false, "", 15.0, true);
	AttachTempParticle(client, EFFECT_FIREWORK, 0.1, false, "", 20.0, true);
	AttachTempParticle(client, EFFECT_FIREWORK, 0.1, false, "", -10.0, true);
	AttachTempParticle(client, EFFECT_FIREWORK, 0.1, false, "", -15.0, true);
	AttachTempParticle(client, EFFECT_FIREWORK, 0.1, false, "", -20.0, true);
	if (playsounds) {
		if(GetRandomInt(0, 2))
			EmitSoundToAll(SOUND_FIREWORK_EXPLODE2, client, _, _, SND_CHANGEPITCH, 1.0, 100);
		if(GetRandomInt(0, 1))
			EmitSoundToAll(SOUND_FIREWORK_EXPLODE1, client, _, _, SND_CHANGEPITCH, 1.0, 80);
		else
			EmitSoundToAll(SOUND_FIREWORK_EXPLODE3, client, _, _, SND_CHANGEPITCH, 1.0, 150);
	}
	
	return Plugin_Continue;
}