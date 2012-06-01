#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public confirmDonationMenu(String:steamID[], amount, admin, isDonation)
{
	new String:title[64];
	new String:displayIdent[64];
	
	if(isDonation)
	{
		Format(title, sizeof(title), "Donate %i Credits to %s?", amount, steamID);
	}else{
		Format(title, sizeof(title), "Award %i Credits to %s?", amount, steamID);
	}
	
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_DonateMenuHandler);
	SetMenuTitle(hCMenu, title);
	
	Format(displayIdent, 64, "0:%i:%i:%s:%i", admin, amount, steamID, isDonation); 
	AddMenuItem(hCMenu, displayIdent, "No", ITEMDRAW_DEFAULT);
	
	Format(displayIdent, 64, "1:%i:%i:%s:%i", admin, amount, steamID, isDonation);
	AddMenuItem(hCMenu, displayIdent, "Yes", ITEMDRAW_DEFAULT);
	
	DisplayMenu(hCMenu, admin, MENU_TIME_FOREVER);
}

public fn_DonateMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			decl String:MenuInfo[64];
			decl String:steamID[64];
			new String:menuTriggers[10][32];
			new option;
			new admin;
			new amount;
			new style;
			new isDonation;
			
			GetMenuItem(menu, param2, MenuInfo, sizeof(MenuInfo),style);
			ExplodeString(MenuInfo, ":", menuTriggers, 8, 32);
			//STEAM_0:0:16952541
			option = StringToInt(menuTriggers[0]);
			admin = StringToInt(menuTriggers[1]);
			amount = StringToInt(menuTriggers[2]);
			isDonation = StringToInt(menuTriggers[6]);
			
			Format(steamID, 64, "%s:%s:%s", menuTriggers[3], menuTriggers[4], menuTriggers[5]);
			
			if(option == 1)
			{
				donate(steamID, amount, admin, isDonation);
			}
			
		}
		
		case MenuAction_Cancel: {
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public isPlayerBySteamIDOnline(String:steamID[])
{
	new String:compareSteamID[MAX_LINE_WIDTH];
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		GetClientAuthString(i, compareSteamID, sizeof(compareSteamID));
		
		if (StrEqual(compareSteamID, steamID, false))
		{
			return GetClientUserId(i);
		}
	}
	
	return -1;
}

public donate(String:steamID[], amount, admin, isDonation)
{
	new clientUserID;
	new client;
	
	clientUserID = isPlayerBySteamIDOnline(steamID);
	client = GetClientOfUserId(clientUserID);
	
	new String:msg01[64];
	new String:msg02[64];
	
	if(isDonation)
	{
		Format(msg01, 64, "your donation");
		Format(msg02, 64, "a donation");
	}else{
		Format(msg01, 64, "an award");
		Format(msg02, 64, "an award");
	}
	
	if(clientUserID > 0)
	{
		//Player is online
		new String:name[32];
		GetClientName(client, name, sizeof(name));
		
		PrintCenterText(client, "You have received: %i credits from %s", amount, msg01);
		PrintToChat(client, "You have received: \x01%i\x04 credits from \x03%s", amount, msg01);
		
		PrintToChatAll("\x03%s\x04 has received \x01%i\x04 credits from \x03%s", name, amount, msg02);
		
		RTDCredits[client] += amount;
		
	}else{
		//Player is offline
		new String:query[1024];
		
		PrintToChat(admin, "Attempting to add %i credits to %s",  amount, steamID);
		
		donate_Amount[admin] = amount;
		Format(donate_SteamID[admin], 64, "%s", steamID);
		
		//select player
		Format(query, sizeof(query), "SELECT * FROM Player WHERE STEAMID = '%s'", steamID);
		SQL_TQuery(db, attemptDonation, query, admin);
		
	}
}

public attemptDonation(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logPath,"Query failed! %s", error);
	} else 
	{
		if (!SQL_GetRowCount(hndl)) 
		{
			PrintToChat(data, "SteamID: %s not found in database!", donate_SteamID[data]);
			PrintCenterText(data, "SteamID: %s not found in database!", donate_SteamID[data]);
		}else{
			new String:query[1024];
			Format(query, sizeof(query), "UPDATE `Player` SET `CREDITS` = `CREDITS` + '%i' WHERE `STEAMID` = '%s'", donate_Amount[data], donate_SteamID[data]);
			SQL_TQuery(db, SaveDonationData, query, data);
		}
	}
	
	return;
}

public SaveDonationData(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		PrintToChat(data, "Error: %s", error);
		PrintCenterText(data, "Error: %s", error);
	}else{
		PrintToChat(data, "Player (%s) is offline, action was successful!", donate_SteamID[data]);
		PrintCenterText(data, "Player (%s) is offline, action was successful!", donate_SteamID[data]);
	}
	
	return;
}