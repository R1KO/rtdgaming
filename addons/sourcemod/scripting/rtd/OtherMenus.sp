#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1

public Action:SetupGenericMenu(menuType, client)
{
	new String:strMenuType[6];
	IntToString(menuType, strMenuType, sizeof(strMenuType));
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_GenericMenuHandler);
	switch(menuType)
	{
		case 1:
			SetMenuTitle(hCMenu,"Donate Credits Menu");
		case 2:
			SetMenuTitle(hCMenu,"Reimburse Credits Menu");
		case 3:
			SetMenuTitle(hCMenu,"Reimburse Dice Menu");
		case 4:
			SetMenuTitle(hCMenu,"Player Information List Menu");
		case 5:
			SetMenuTitle(hCMenu,"Teleport Player To Reticle");
	}

	new String:clientName[128];
	
	for (new i = 1; i <= MaxClients; i++) 
	{	
		if(IsClientInGame(i)) 
		{
			GetClientName(i, clientName, sizeof(clientName));
			switch(menuType)
			{
				case 1:
					Format(clientName, sizeof(clientName), "%s has %i Credits" , clientName ,RTDCredits[i]);
				case 2:
					Format(clientName, sizeof(clientName), "%s has %i Credits" , clientName, RTDCredits[i]);
				case 3:
					Format(clientName, sizeof(clientName), "%s has %i Dice" , clientName, RTDdice[i]);
				case 4:
					Format(clientName, sizeof(clientName), "%s" , clientName);
				case 5:
					Format(clientName, sizeof(clientName), "%s" , clientName);
			}
			AddMenuItem(hCMenu, strMenuType, clientName);
		}else{
			AddMenuItem(hCMenu, "", "--EMPTY--", ITEMDRAW_DISABLED);
		}
	}
	SetMenuExitBackButton(hCMenu, true);
	DisplayMenu(hCMenu, client, MENU_TIME_FOREVER);
}

public fn_GenericMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	//This loads the Info data from the menu
	//Previously unused we just had "Option i++"
	//The param2 is pulled from the options elected, not the "info"
	new String:menuInfo[2];
	GetMenuItem(menu, param2, menuInfo, sizeof(menuInfo));
	new menuType = StringToInt(menuInfo);
	switch (action) 
	{
		case MenuAction_Select: 
		{
			new String:name[32];
			GetClientName(param1, name, sizeof(name));
			if(IsClientInGame(param2+1))
			{
				switch(menuType)
				{
					case 1:
					{
						SetupDonateAmountMenu(param1,param2+1);
					}
					case 2:
					{
						SetupReimburseAmountMenu(param1,param2+1);
					}
					case 3:
					{
						SetupReimburseDiceAmountMenu(param1,param2+1);
					}
					case 4:
					{
						SetupPlayerInfoMenu(param1,param2+1);
					}
					case 5:
					{
						TeleportPlayerToReticle(param1, param2+1);
					}
				}
			}
		}
		
		case MenuAction_Cancel: {
			new String:menuTitle[64];
			GetMenuTitle(menu, menuTitle, sizeof(menuTitle));
			if(StrEqual("Donate Credits Menu", menuTitle, false))
				SetupCreditsMenu(param1, "");
			else
				showAdminMenu(param1);
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public Action:SetupDonateAmountMenu(donator,receiver)
{
	
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_DonateAmountMenuHandler);
	
	new String:optionNum[128];
	new String:receiverName[128];
	
	GetClientName(receiver, receiverName, sizeof(receiverName));

	SetMenuTitle(hCMenu,"Donate Credits to %s",receiverName);
	
	for (new i = 1; i <= RTDCredits[donator]; i++) 
	{	
		Format(optionNum, sizeof(optionNum), "Option %i", i);
		
		Format(receiverName, sizeof(receiverName), "%i Credits" , i );
		
		AddMenuItem(hCMenu,optionNum, receiverName);
	}
	
	idOfReceiver[donator] = receiver;
	SetMenuExitBackButton(hCMenu, true);
	DisplayMenu(hCMenu,donator,MENU_TIME_FOREVER);
}

public fn_DonateAmountMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action) 
	{
		case MenuAction_Select: 
		{
			new String:donatorName[32];
			if(IsClientInGame(idOfReceiver[param1])){
				GetClientName(param1, donatorName, sizeof(donatorName));
				
				new String:receiverName[32];
				GetClientName(idOfReceiver[param1], receiverName, sizeof(receiverName));
				
				//param2 = client index
				PrintToChatAll("\x01\x04[CREDITS] \x03%s\x04 gave \x03%s \x01 %i CREDITS \x04", donatorName,receiverName, param2+1);
				RTDCredits[idOfReceiver[param1]] = RTDCredits[idOfReceiver[param1]] + param2 + 1;
				RTDCredits[param1] = RTDCredits[param1] - (param2 + 1 );
				
				EmitSoundToClient(idOfReceiver[param1], SOUND_BOUGHTSOMETHING);
				PrintCenterText(idOfReceiver[param1], "%s gave you %i CREDITS!",donatorName,param2+1);
			}
		}
		
		case MenuAction_Cancel: {
			SetupGenericMenu(1, param1);
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public Action:SetupReimburseAmountMenu(donator,receiver){
	
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_ReimburseAmountMenuHandler);
	
	new String:optionNum[128];
	new String:receiverName[128];
	
	GetClientName(receiver, receiverName, sizeof(receiverName));

	SetMenuTitle(hCMenu,"Reimburse Credits to %s",receiverName);
	
	new j;
	for (new i = 1; i <= 40; i++) 
	{	
		j = j + 5;
		Format(optionNum, sizeof(optionNum), "Option %i", j);
		
		Format(receiverName, sizeof(receiverName), "%i Credits" , j);
		
		AddMenuItem(hCMenu,optionNum, receiverName);
	}
	
	idOfReceiver[donator] = receiver;
	SetMenuExitBackButton(hCMenu, true);
	DisplayMenu(hCMenu,donator,MENU_TIME_FOREVER);
}

public fn_ReimburseAmountMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action) 
	{
		case MenuAction_Select: 
		{
			new String:donatorName[32];
			if(IsClientInGame(idOfReceiver[param1])){
				GetClientName(param1, donatorName, sizeof(donatorName));
				
				new String:receiverName[32];
				GetClientName(idOfReceiver[param1], receiverName, sizeof(receiverName));
				
				//param2 = client index
				if(idOfReceiver[param1] != param1)
				{
					PrintToChatAll("\x01\x04[RTD][ADMIN] \x03%s\x04 reimbursed \x03%s\x01 %i Credits \x04", donatorName,receiverName, (param2 + 1) * 5);
					LogToFile(logPath,"[RTD][ADMIN]  %s reimbursed %s %i Credits", donatorName,receiverName, (param2 + 1) * 5);
					RTDCredits[idOfReceiver[param1]] = RTDCredits[idOfReceiver[param1]] + (param2 + 1) * 5;
				}
			}
		}
		
		case MenuAction_Cancel: {
			SetupGenericMenu(2, param1);
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public Action:SetupReimburseDiceAmountMenu(donator,receiver)
{
	
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_ReimDiceAmountMenuHandler);
	
	new String:optionNum[128];
	new String:receiverName[128];
	
	GetClientName(receiver, receiverName, sizeof(receiverName));

	SetMenuTitle(hCMenu,"Reimburse Dice to %s",receiverName);
	
	new j;
	for (new i = 1; i <= 40; i++) 
	{	
		j = j + 5;
		Format(optionNum, sizeof(optionNum), "Option %i", j);
		
		Format(receiverName, sizeof(receiverName), "%i Dice" , j);
		
		AddMenuItem(hCMenu,optionNum, receiverName);
	}
	
	idOfReceiver[donator] = receiver;
	SetMenuExitBackButton(hCMenu, true);
	DisplayMenu(hCMenu,donator,MENU_TIME_FOREVER);
}

public fn_ReimDiceAmountMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action) 
	{
		case MenuAction_Select: 
		{
			new String:donatorName[32];
			if(IsClientInGame(idOfReceiver[param1])){
				GetClientName(param1, donatorName, sizeof(donatorName));
				
				new String:receiverName[32];
				GetClientName(idOfReceiver[param1], receiverName, sizeof(receiverName));
				
				//param2 = client index
				if(idOfReceiver[param1] != param1)
				{
					PrintToChatAll("\x01\x04[RTD][ADMIN] \x03%s\x04 reimbursed \x03%s\x01 %i Dice\x04", donatorName,receiverName, (param2 + 1) * 5);
					LogToFile(logPath,"[RTD][ADMIN] %s reimbursed %s %i Dice", donatorName,receiverName, (param2 + 1) * 5);
					RTDdice[idOfReceiver[param1]] = RTDdice[idOfReceiver[param1]] + (param2 + 1) * 5;
				}
			}
		}
		
		case MenuAction_Cancel: {
			SetupGenericMenu(3, param1);
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public Action:SelectClientToAward(client)
{
	if(!IsClientInGame(client))
		return;
	
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_SelectClientToAward);
	SetMenuTitle(hCMenu,"Select player");
	
	new String:name[32];
	new String:userid[32];
	new String:textInfo[64];
	
	Format(userid, sizeof(userid), "%i", GetClientUserId(client));
	Format(textInfo, sizeof(textInfo), "(Self) %s ", name);
	GetClientName(client, name, sizeof(name));
	AddMenuItem(hCMenu,userid, textInfo, ITEMDRAW_DEFAULT);
	
	AddMenuItem(hCMenu,"-100", "Everyone", ITEMDRAW_DEFAULT);
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(i == client)
			continue;
		
		if(!(IsClientInGame(i) && IsClientAuthorized(i)))
			continue;
		
		
		Format(userid, sizeof(userid), "%i", GetClientUserId(i));
		GetClientName(i, name, sizeof(name));
		
		//PrintToChatAll("String UserId: %s (%i)", userid, GetClientUserId(i));
		
		Format(textInfo, sizeof(textInfo), "%s", name);
		AddMenuItem(hCMenu,userid, textInfo, ITEMDRAW_DEFAULT);
	}
	
	SetMenuExitBackButton(hCMenu, true);
	DisplayMenu(hCMenu,client,MENU_TIME_FOREVER);
}

public fn_SelectClientToAward(Handle:menu, MenuAction:action, param1, param2)
{	
	new receiver;
	
	switch (action) 
	{
		case MenuAction_Select: 
		{
			new String:menuInfo[16];
			GetMenuItem(menu, param2, menuInfo, sizeof(menuInfo));
			
			new receiverUserId = StringToInt(menuInfo);
			//PrintToChatAll("menuInfo:%s", menuInfo);
			
			if(receiverUserId == -100)
			{
				SetupAwardMenu(-100, param1);
			}else{
				receiver = GetClientOfUserId(receiverUserId);
				
				SetupAwardMenu(receiver, param1);
			}
			
		}
		
		case MenuAction_Cancel: {
			//SetupCreditsMenu(param1, "");
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public Action:SetupAwardMenu(client, admin){
	
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_AwardMenuHandler);
	
	new String:optionNum[128], String:optionMsg[128];
	
	new String:name[32];
	
	if(client == -100)
	{
		Format(name, sizeof(name), "Everyone");
	}else{
		GetClientName(client, name, sizeof(name));
	}
	
	SetMenuTitle(hCMenu,"Award Menu for %s", name);

	for (new i = 0; i < MAX_GOOD_AWARDS + MAX_BAD_AWARDS; i++) 
	{
		Format(optionNum, sizeof(optionNum), "%i:Option %i", client, i);
		Format(optionMsg, sizeof(optionMsg), "%s" , roll_Text[i]);
		
		AddMenuItem(hCMenu,optionNum, optionMsg);
	}
	
	SetMenuExitBackButton(hCMenu, true);
	DisplayMenu(hCMenu,admin,MENU_TIME_FOREVER);
}

public fn_AwardMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action) 
	{
		case MenuAction_Select: 
		{
			decl String:MenuInfo[64];
			new String:menuTriggers[2][20];
			new style;
			
			GetMenuItem(menu, param2, MenuInfo, sizeof(MenuInfo),style);
			ExplodeString(MenuInfo, ":", menuTriggers, 2, 20);
			
			new client = StringToInt(menuTriggers[0]);
			
			new String:adminName[32];
			if(client == -100)
			{
				for (new i = 1; i <= MaxClients ; i++)
				{
					if(!IsClientInGame(i) || i == client || !IsPlayerAlive(i))
						continue;
					
					GetClientName(i, adminName, sizeof(adminName));
					
					if(!UnAcceptable(i, param2) && !inTimerBasedRoll[i] && IsPlayerAlive(i))
					{
						GivePlayerEffect(i, param2, -2);
						LogToFile(logPath,"[RTD][ADMIN] %s was awarded %s", adminName, roll_Text[param2]);
					}
				}
				
			}else{	
				if(IsClientInGame(client))
				{
					GetClientName(client, adminName, sizeof(adminName));
					
					if(!UnAcceptable(client, param2) && !inTimerBasedRoll[client] && IsPlayerAlive(client))
					{
						GivePlayerEffect(client, param2, -2);
						LogToFile(logPath,"[RTD][ADMIN] %s was awarded %s", adminName, roll_Text[param2]);
					}
				}
			}
		}
		
		case MenuAction_Cancel: {
			
		showAdminMenu(param1);
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public Action:SetupAdminMenu(client){
	
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_AdminMenuHandler);
	
	SetMenuTitle(hCMenu,"RTD Admin Menu");

	AddMenuItem(hCMenu, "Option 1", "Reimburse Credits");
	AddMenuItem(hCMenu, "Option 2", "Reimburse Dice");
	AddMenuItem(hCMenu, "Option 3", "Give Award");
	AddMenuItem(hCMenu, "Option 4", "Spawn Dice");
	AddMenuItem(hCMenu, "Option 5", "Player Information");
	AddMenuItem(hCMenu, "Option 6", "Scramble Teams");
	AddMenuItem(hCMenu, "Option 7", "Toggle Rolls");
	AddMenuItem(hCMenu, "Option 8", "Teleport Player");
	
	DisplayMenu(hCMenu,client,MENU_TIME_FOREVER);
}

public Action:SetupBasicAdminMenu(client){
	
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_BasicAdminMenuHandler);
	
	SetMenuTitle(hCMenu,"RTD Admin Menu");

	AddMenuItem(hCMenu, "Option 1", "Scramble Teams");
	AddMenuItem(hCMenu, "Option 2", "Player Information");
	AddMenuItem(hCMenu, "Option 3", "Toggle Rolls");
	AddMenuItem(hCMenu, "Option 4", "Teleport Player");
	
	new alpha;
	alpha = GetEntData(client, m_clrRender + 3, 1);
	if(alpha == 255)
	{
		AddMenuItem(hCMenu, "Option 5", "Turn ON Invisibility on Self");
	}else{
		AddMenuItem(hCMenu, "Option 5", "Turn OFF Invisibility on Self");
	}
	
	if(isMicSpamEnabled())
	{
		AddMenuItem(hCMenu, "Option 6", "Voice from File: Enabled");
	}else{
		AddMenuItem(hCMenu, "Option 6", "Voice from File: Disabled");
	}
	DisplayMenu(hCMenu,client,MENU_TIME_FOREVER);
}

public fn_BasicAdminMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action) 
	{
		case MenuAction_Select: 
		{
			new String:adminName[32];
			if(IsClientInGame(param1)){
				GetClientName(param1, adminName, sizeof(adminName));
				
				switch(param2)
				{
					case 0:
					{
						PrintToChatAll("\x01\x04[Scramble]\x01 Teams will be scrambled next round.");
						g_bScramblePending = true;
						g_iScrambleDelay = GetTime() + 300;
					}
					
					case 1:
					{
						//Player information
						SetupGenericMenu(4, param1);
					}
					
					case 2:
					{
						SetupToggleRollsMenu(param1, 0);
					}
					
					case 3:
					{
						//teleport player
						SetupGenericMenu(5, param1);
					}
					
					case 4:
					{
						new alpha;
						alpha = GetEntData(param1, m_clrRender + 3, 1);
						
						if(alpha == 255)
						{
							Colorize(param1, INVIS);
							InvisibleHideFixes(param1, TF2_GetPlayerClass(param1), 0);
						}else{
							Colorize(param1, NORMAL);
							InvisibleHideFixes(param1, TF2_GetPlayerClass(param1), 1);
						}
					}
					
					case 5:
					{
						if(isMicSpamEnabled())
						{
							new Handle:convar = FindConVar("sv_allow_voice_from_file");
							SetConVarBool(convar, false, false, false);
							CloseHandle(convar);
							PrintCenterText(param1, "Voice from File: Disabled");
						}else{
							new Handle:convar = FindConVar("sv_allow_voice_from_file");
							SetConVarBool(convar, true, false, false);
							CloseHandle(convar);
							PrintCenterText(param1, "Voice from File: Enabled");
						}
					}
				}
			}
		}
		
		case MenuAction_Cancel: {
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public fn_AdminMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action) 
	{
		case MenuAction_Select: 
		{
			new String:adminName[32];
			if(IsClientInGame(param1)){
				GetClientName(param1, adminName, sizeof(adminName));
				
				switch(param2)
				{
					case 0:
						SetupGenericMenu(2, param1);
					case 1:
						SetupGenericMenu(3, param1);
					case 2:
						SelectClientToAward(param1);
					case 3:
					{
						Item_ParseList();
						CreateTimer(1.0, SpawnDice_Timer);
						LogToFile(logPath,"[RTD][ADMIN] %s Respawned Dice", adminName);
					}
					case 4:
						SetupGenericMenu(4, param1);
					case 5:
					{
						PrintToChatAll("\x01\x04[Scramble]\x01 Teams will be scrambled next round.");
						g_bScramblePending = true;
						g_iScrambleDelay = GetTime() + 300;
					}
					
					case 6:
						SetupToggleRollsMenu(param1, 0);
						
					case 7:
						SetupGenericMenu(5, param1);
				}
			}
		}
		
		case MenuAction_Cancel: {
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public Action:SetupPlayerInfoMenu(client,player){
	
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_PlayerInfoMenuHandler);
	
	new String:playerName[128];
	new String:playerDice[64];
	new String:playerCredits[64];
	new String:playerSteamid[64];
	new String:playerIP[64];
	
	GetClientName(player, playerName, sizeof(playerName));
	GetClientAuthString(player, playerSteamid, sizeof(playerSteamid));
	GetClientIP(player, playerIP, sizeof(playerIP));

	SetMenuTitle(hCMenu,"Player Information for %s", playerName);
	
	Format(playerDice, sizeof(playerDice), 		"Dice    : %d", RTDdice[player]);
	Format(playerCredits, sizeof(playerCredits), 	"Credits : %d", RTDCredits[player]);
	Format(playerSteamid, sizeof(playerSteamid), 	"SteamId : %s", playerSteamid);
	Format(playerIP, sizeof(playerIP),			 	"Ip      : %s", playerIP);
	AddMenuItem(hCMenu, "Option 1", playerDice, ITEMDRAW_DISABLED);
	AddMenuItem(hCMenu, "Option 2", playerCredits, ITEMDRAW_DISABLED);
	AddMenuItem(hCMenu, "Option 3", playerSteamid, ITEMDRAW_DISABLED);
	AddMenuItem(hCMenu, "Option 4", playerIP, ITEMDRAW_DISABLED);
	
	SetMenuExitBackButton(hCMenu, true);
	DisplayMenu(hCMenu, client, MENU_TIME_FOREVER);
	PrintToConsole(client, "\n");
	PrintToConsole(client, "Player Information for %s", playerName);
	PrintToConsole(client, "%s", playerDice);
	PrintToConsole(client, "%s", playerCredits);
	PrintToConsole(client, "%s", playerSteamid);
	PrintToConsole(client, "%s", playerIP);
	PrintToConsole(client, "\n");
}

public Action:showActiveRolls(client)
{
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_showActiveRolls);
	
	new String:playerName[128];
	new String:rollTextInfo[128];
	new activeRolls;
	
	GetClientName(client, playerName, sizeof(playerName));
	
	//show info about last roll
	if(lastRoll[client] != 0)
	{
		Format(rollTextInfo, sizeof(rollTextInfo),	"Last Roll: %s", roll_Text[lastRoll[client]]);
		AddMenuItem(hCMenu, "Option 1",rollTextInfo, ITEMDRAW_DEFAULT);
	}
	
	//show current rolls
	for(new i=0; i< MAX_GOOD_AWARDS + MAX_BAD_AWARDS; i++)
	{
		if(client_rolls[client][i][0] == 1)
		{
			activeRolls ++;
			
			if(roll_isDeployable[i])
			{
				Format(rollTextInfo, sizeof(rollTextInfo),	"%s (%i/%i)", roll_Text[i], client_rolls[client][i][1], roll_amountDeployable[i]);
				
				AddMenuItem(hCMenu, "Option 1",rollTextInfo, ITEMDRAW_DEFAULT);
				PrintToConsole(client, "%s", roll_Text[i]);
			}else{
				AddMenuItem(hCMenu, "Option 1", roll_Text[i], ITEMDRAW_DEFAULT);
				PrintToConsole(client, "%s", roll_Text[i]);
			}
			
		}
	}
	
	PrintToConsole(client, "%i active rolls for: %s", activeRolls, playerName);
	SetMenuTitle(hCMenu,"%i active rolls for: %s", activeRolls, playerName);
	
	if(activeRolls == 0)
		AddMenuItem(hCMenu, "Option 1", "No active rolls!", ITEMDRAW_DEFAULT);
	
	DisplayMenu(hCMenu, client, MENU_TIME_FOREVER);
}

public fn_showActiveRolls(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action) 
	{
		case MenuAction_Select: {
			showActiveRolls(param1);
		}
		
		case MenuAction_Cancel: {
		}
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}


public fn_PlayerInfoMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action) 
	{
		case MenuAction_Select: {
		}
		
		case MenuAction_Cancel: {
		SetupGenericMenu(4, param1);
		}
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public Action:SetupToggleRollsMenu(client, startAtPage){
	
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_ToggleMenuHandler);
	
	new String:optionNum[128], String:optionMsg[128];
	
	SetMenuTitle(hCMenu,"Toggle Rolls");

	for (new i = 0; i < MAX_GOOD_AWARDS + MAX_BAD_AWARDS; i++) 
	{	
		Format(optionNum, sizeof(optionNum), "Option %i", i);
		
		if(roll_enabled[i])
		{
			Format(optionMsg, sizeof(optionMsg), "[ENABLED] %s" , roll_Text[i]);
		}else{
			Format(optionMsg, sizeof(optionMsg), "[DISABLED] %s" , roll_Text[i]);
		}
		
		AddMenuItem(hCMenu,optionNum, optionMsg);
	}
	
	SetMenuExitBackButton(hCMenu, true);
	DisplayMenuAtItem(hCMenu,client,startAtPage, MENU_TIME_FOREVER);
}

public fn_ToggleMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action) 
	{
		case MenuAction_Select: 
		{
			if(IsClientInGame(param1))
			{
				
				if(roll_enabled[param2])
				{
					roll_enabled[param2] = 0;
				}else{
					roll_enabled[param2] = 1;
				}
				
				SetupToggleRollsMenu(param1,GetMenuSelectionPosition());
				
			}
		}
		
		case MenuAction_Cancel: 
			showAdminMenu(param1);
		
		case MenuAction_End:
			CloseHandle(menu);
	}
}

public showAdminMenu(client)
{
	if(!CheckAdminFlagsByString(client, "z") && !allowRTDAdminMenu)
	{
		//Limited admin menu
		SetupBasicAdminMenu(client);
	}else{
		SetupAdminMenu(client);
	}
}

public Action:SetupGiveCreditsMenu(client, amountToDonate)
{
	if(amountToDonate <= 0)
	{
		SetupGenericMenu(1, client);
		return Plugin_Handled;
	}
	
	if(RTDCredits[client] < amountToDonate)
	{
		PrintCenterText(client, "You don't have enough credits!");
		return Plugin_Handled;
	}
	
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_GiveCredsMenuHandler);
	
	SetMenuTitle(hCMenu,"Donate %i Credits To Who?", amountToDonate);

	new String:clientName[128];
	new String:menuInfo[64];
	
	for (new i = 1; i <= MaxClients; i++) 
	{	
		if(IsClientInGame(i)) 
		{
			if(!IsFakeClient(i))
			{
				GetClientName(i, clientName, sizeof(clientName));
				
				Format(clientName, sizeof(clientName), "%s has %i Credits" , clientName ,RTDCredits[i]);
				Format(menuInfo, sizeof(menuInfo), "%i" , GetClientUserId(i));
				
				AddMenuItem(hCMenu, menuInfo, clientName);
			}
		}
	}
	
	amountToGive[client] = amountToDonate;
	
	DisplayMenu(hCMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Continue;
}

public fn_GiveCredsMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action) 
	{
		case MenuAction_Select: 
		{
			if(IsClientInGame(param1))
			{
				new String:menuInfo[16];
				GetMenuItem(menu, param2, menuInfo, sizeof(menuInfo));
				
				new receiverUserId = StringToInt(menuInfo);
				
				new receiver = GetClientOfUserId(receiverUserId);
				
				if(receiver != 0)
				{
					if(IsClientInGame(receiver))
					{
						if(RTDCredits[param1] >= amountToGive[param1])
						{
							new String:donatorName[32];
							new String:receiverName[32];
							
							GetClientName(param1, donatorName, sizeof(donatorName));
							GetClientName(receiver, receiverName, sizeof(receiverName));
							
							PrintToChatAll("\x01\x04[CREDITS] \x03%s\x04 gave \x03%s \x01 %i CREDITS \x04", donatorName,receiverName, amountToGive[param1]);
							RTDCredits[receiver] += amountToGive[param1];
							RTDCredits[param1] -= amountToGive[param1];
							
							EmitSoundToClient(param1, SOUND_BOUGHTSOMETHING);
							EmitSoundToClient(receiver, SOUND_BOUGHTSOMETHING);
							
							PrintCenterText(receiver, "%s gave you %i CREDITS!",donatorName,amountToGive[param1]);
						}else{
							PrintCenterText(param1, "You don't have enough credits!");
						}
					}else{
						PrintCenterText(param1, "Selected client is no longer in game!");
					}
				}else{
					PrintCenterText(param1, "Selected client is no longer in game!");
				}
			}
		}
		
		case MenuAction_Cancel: {
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public bool:isMicSpamEnabled()
{
	new Handle:convar = FindConVar("sv_allow_voice_from_file");
	new bool:isEnabled = GetConVarBool(convar);
	
	CloseHandle(convar);
	
	if(isEnabled)
		return true;
	
	return false;
}