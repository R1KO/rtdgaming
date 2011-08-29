#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>
#include <rtd_rollinfo>
#pragma semicolon 1

stock SetupGiftMenu(client)
{
	if(!IsClientInGame(client))
		return;
	new clientTeam = GetClientTeam(client);
	
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_GiftMenuHandler);
	SetMenuTitle(hCMenu,"Gifting Menu | %i/100 Gift Credit limit used.",creds_Gifted[client]);
		
	new String:name[32];
	new String:userid[32];
	new String:textInfo[64];
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(i == client)
			continue;
		
		if(!(IsClientInGame(i) && IsClientAuthorized(i)))
			continue;
		
		if(clientTeam != GetClientTeam(i))
			continue;
		
		Format(userid, sizeof(userid), "%i", GetClientUserId(i));
		GetClientName(i, name, sizeof(name));
		
		//PrintToChatAll("String UserId: %s (%i)", userid, GetClientUserId(i));
		
		Format(textInfo, sizeof(textInfo), "%s [%i/100]", name, creds_ReceivedFromGifts[i]);
		AddMenuItem(hCMenu,userid, textInfo, creds_ReceivedFromGifts[i]>=100?ITEMDRAW_DISABLED:inTimerBasedRoll[i]?ITEMDRAW_DISABLED:inWaitingToGift[client]?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	}
	
	SetMenuExitBackButton(hCMenu, true);
	DisplayMenu(hCMenu,client,MENU_TIME_FOREVER);
}

public fn_GiftMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(param1 > 0)
	{
		if(IsClientInGame(param1))
		{
			if(!IsPlayerAlive(param1))
			{
				PrintCenterText(param1, "You must be alive and in game!");
				PrintToChat(param1, "You must be alive and in game!");
				action = MenuAction_Cancel;
			}
		}
	}
	
	new receiver;
	
	switch (action) 
	{
		case MenuAction_Select: 
		{
			new String:menuInfo[16];
			GetMenuItem(menu, param2, menuInfo, sizeof(menuInfo));
			//PrintToChatAll("menuInfo: %s", menuInfo);
				
			new receiverUserId = StringToInt(menuInfo);
			
			//PrintToChatAll("UserID (receiverUserId): %i", receiverUserId);
			
			receiver = GetClientOfUserId(receiverUserId);
			
			if(!canClientHaveRollsGifted(receiver, param1))
			{
				SetupGiftMenu(param1);
			}else{
				//Finally, show the user which rolls this client can receive
				SetupGiftMenu_Rolls(param1, GetClientUserId(receiver));
			}
		}
		
		case MenuAction_Cancel: {
			SetupCreditsMenu(param1, "");
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public canClientHaveRollsGifted(receiver, client)
{
	//for some reason our orignal client is not here?
	if(!IsClientInGame(client))
		return false;
	
	//make sure receiver is still in game
	if(receiver == 0)
	{
		PrintCenterText(client, "This client is no longer in game!");
		PrintToChat(client, "This client is no longer in game!");
		
		EmitSoundToClient(client, SOUND_DENY);
		return false;
	}
	
	if(!IsClientInGame(receiver))
	{
		PrintCenterText(receiver, "This client is no longer in game!");
		PrintToChat(receiver, "This client is no longer in game!");
		
		EmitSoundToClient(client, SOUND_DENY);
		return false;
	}
	
	if(!IsPlayerAlive(receiver))
	{
		PrintCenterText(client, "This player is not alive!");
		PrintToChat(client, "This player is not alive!");
		
		EmitSoundToClient(client, SOUND_DENY);
		return false;
	}
	
	if(GetClientTeam(client) != GetClientTeam(receiver))
	{
		PrintCenterText(client, "This player is no longer on your team!");
		PrintToChat(client, "This player is no longer on your team!");
		
		EmitSoundToClient(client, SOUND_DENY);
		return false;
	}
	
	if(creds_ReceivedFromGifts[receiver] > 100)
	{
		PrintCenterText(client, "This player has reached the gifting limit. Please wait: %i", (GetTime() - credsUsed[receiver][1]));
		PrintToChat(client, "This player is no longer on your team!");
		
		EmitSoundToClient(client, SOUND_DENY);
		return false;
	}
	
	if(beingGifted[receiver] == 1)
	{
		PrintCenterText(client, "This player is already receiving a gift, please wait!");
		PrintToChat(client, "This player is already receiving a gift, please wait!");
		
		EmitSoundToClient(client, SOUND_DENY);
		return false;
	}
	
	if(inWaitingToGift[client])
	{
		PrintCenterText(client, "You already have a Gift in process, please wait!");
		PrintToChat(client, "You already have a Gift in process, please wait!");
		
		EmitSoundToClient(client, SOUND_DENY);
		return false;
	}
	
	return true;
}

public SetupGiftMenu_Rolls(client, receiverUserId)
{
	if(!IsClientInGame(client))
		return;
	
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_GiftMenu_Rolls_Handler);
	SetMenuTitle(hCMenu,"Gifting Menu | %i/100 Gift Credit limit used.",creds_Gifted[client]);
	
	new receiver = GetClientOfUserId(receiverUserId);
	
	addRollsToShop(hCMenu, receiver, client);
	giftingTo[client] = receiverUserId;
	
	SetMenuExitBackButton(hCMenu, true);
	DisplayMenu(hCMenu,client,MENU_TIME_FOREVER);
}

public fn_GiftMenu_Rolls_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	if(param1 > 0)
	{
		if(IsClientInGame(param1))
		{
			if(!IsPlayerAlive(param1))
			{
				PrintCenterText(param1, "You must be alive and in game!");
				PrintToChat(param1, "You must be alive and in game!");
				action = MenuAction_Cancel;
			}
		}
	}else{
		action = MenuAction_Cancel;
		return;
	}
	
	//PrintToChatAll("param1: %i",param1);
	//PrintToChatAll("giftingTo[param1]: %i",giftingTo[param1]);
	
	new receiver = GetClientOfUserId(giftingTo[param1]);
	
	//Selected player can no longer receive gift
	if(!canClientHaveRollsGifted(receiver, param1))
	{
		SetupGiftMenu(param1);
		return;
	}
	
	switch (action) 
	{
		case MenuAction_Select: 
		{
			new String:name[32];
			GetClientName(param1, name, sizeof(name));
			//qeury rtdcredits
			
			//format time left for CredsUsed
			new timeleft;
			new credsLeft;
			new cost;
			
			if(credsUsed[param1][1] == 0)
				credsUsed[param1][1] = GetTime();
			
			credsLeft = 100 - creds_Gifted[param1];
			timeleft  = 600 - (GetTime() - credsUsed[param1][1]);
			
			//PrintToChatAll("%i",credsUsed[param1][1]);
			
			if(credsLeft < 0)
				credsLeft = 0;
			
			decl String:MenuInfo[64];
			new String:menuTriggers[4][128];
			new bool:allowPurchase = false;
			decl award;
			
			new style;
			GetMenuItem(menu, param2, MenuInfo, sizeof(MenuInfo),style);
			ExplodeString(MenuInfo, ":", menuTriggers, 3, 15);
			
			cost = StringToInt(menuTriggers[0]);
			award = StringToInt(menuTriggers[2]);
			if(gift_discount != 0)
			{
				//PrintToChatAll("Cost %d | Shop Discount %f | Cost After %d", cost, shop_discount, RoundToFloor(cost * shop_discount));
				cost = RoundToFloor(cost * gift_discount);
			}
			//Determine if the player is allowed to purchase the selected item
			if(RTDCredits[param1] >= cost)
			{
				if(credsLeft < cost)
				{
					PrintCenterText(param1, "%i/100 Gift Credit limit used. Please wait: %i seconds",creds_Gifted[param1], timeleft);
					PrintToChat(param1, "%i/100 Gift Credit limit used. Please wait: %i seconds",creds_Gifted[param1], timeleft);
					EmitSoundToClient(param1, SOUND_DENY);
				}else{
					if(style != ITEMDRAW_DISABLED)
					{
						allowPurchase = true;
						
					}else{
						PrintCenterText(param1, "Requested item is DISABLED!");
						PrintToChat(param1, "Requested item is DISABLED!");
						
						EmitSoundToClient(param1, SOUND_DENY);
					}
				}
			}else{
				PrintCenterText(param1, "You do not have enough CREDITS");
				PrintToChat(param1, "You do have enough CREDITS!");
			}
			
			//Massive If...then statement
			if(allowPurchase)
			{
				askReceiverToAcceptGift(param1, award, cost);
			}
		}
		
		case MenuAction_Cancel: {
			SetupGiftMenu(param1);
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public askReceiverToAcceptGift(client, award, cost)
{
	new receiver = GetClientOfUserId(giftingTo[client]);
	
	beingGifted[receiver] = 1;
	acceptedGift[receiver] = 0;
	inWaitingToGift[client] = 1;
	
	new String:name[32];
	new String:clientName[32];
	GetClientName(receiver, name, sizeof(name));
	GetClientName(client, clientName, sizeof(clientName));
	
	//Show waiting message for client
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, waitingForReceiver_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPackHandle, client);
	WritePackCell(dataPackHandle, giftingTo[client]); //8
	WritePackCell(dataPackHandle, GetTime() + 10); //16 expiration
	WritePackCell(dataPackHandle, cost);
	WritePackCell(dataPackHandle, award);
	WritePackString(dataPackHandle, name);
	WritePackString(dataPackHandle, clientName);
	
	//Show menu to receiver
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_GiftMenu_Accept_Handler);
	
	new String:displayInfo[64];
	Format(displayInfo, sizeof(displayInfo), "ACCEPT %s from %s?", roll_Text[award], clientName);
	
	PrintCenterText(client,"%s", displayInfo);
	
	SetMenuTitle(hCMenu, displayInfo);
	
	AddMenuItem(hCMenu,"1", displayInfo);
	AddMenuItem(hCMenu,"0", "DECLINE Gift");
	
	DisplayMenu(hCMenu, receiver, 10);
	
	WritePackString(dataPackHandle, displayInfo);
}

public fn_GiftMenu_Accept_Handler(Handle:menu, MenuAction:action, param1, param2)
{	
	switch (action) 
	{
		case MenuAction_Select: 
		{	
			switch (param2) 
			{
				case 0: {
					acceptedGift[param1]  = 1;
				}
				case 1: {
					acceptedGift[param1]  = -1;
				}
			}
		}
	
		case MenuAction_Cancel: {
			acceptedGift[param1]  = -1;
		}

		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public Action:waitingForReceiver_Timer(Handle:timer, Handle:dataPackHandle)
{
	ResetPack(dataPackHandle);
	new client = ReadPackCell(dataPackHandle);
	new receiverId = ReadPackCell(dataPackHandle);
	new timeExpire = ReadPackCell(dataPackHandle);
	new cost = ReadPackCell(dataPackHandle);
	new award = ReadPackCell(dataPackHandle);
	
	new String:name[32];
	new String:clientName[32];
	new String:displayInfo[64];
	ReadPackString(dataPackHandle, name, sizeof(name));
	ReadPackString(dataPackHandle, clientName, sizeof(clientName));
	ReadPackString(dataPackHandle, displayInfo, sizeof(displayInfo));
	
	new receiver = GetClientOfUserId(receiverId);
	
	if(!IsClientInGame(client))
	{
		if(receiver != 0)
		{
			if(IsClientInGame(receiver))
			{
				PrintCenterText(receiver, "Your Gifter left the game!");
				PrintToChat(receiver, "Your Gifter left the game!");
				
				beingGifted[receiver] = 0;
				
				if(GetClientMenu(receiver) != MenuSource_None )
					CancelClientMenu(receiver,true);
			}
		}
		
		inWaitingToGift[client] = 0;
		
		return Plugin_Stop;
	}
	
	//make sure receiver is still in game
	if(receiver == 0)
	{
		PrintCenterText(client, "%s is no longer in game!", name);
		PrintToChat(client, "%s is no longer in game!", name);
		
		inWaitingToGift[client] = 0;
		
		EmitSoundToClient(client, SOUND_DENY);
		return Plugin_Stop;
	}
	
	if(!IsClientInGame(receiver))
	{
		PrintCenterText(client, "%s is no longer in game!", name);
		PrintToChat(client, "%s is no longer in game!", name);
		
		inWaitingToGift[client] = 0;
		
		EmitSoundToClient(client, SOUND_DENY);
		return Plugin_Stop;
	}
	
	if(!IsPlayerAlive(receiver))
	{
		PrintCenterText(client, "%s died before accepting gift", name);
		PrintToChat(client, "%s died before accepting gift", name);
		
		inWaitingToGift[client] = 0;
		beingGifted[receiver] = 0;
		
		if(GetClientMenu(receiver) != MenuSource_None )
			CancelClientMenu(receiver,true);
		
		EmitSoundToClient(client, SOUND_DENY);
		return Plugin_Stop;
	}
	
	if(GetClientTeam(client) != GetClientTeam(receiver))
	{
		PrintCenterText(client, "%s is no longer on your team!", name);
		PrintToChat(client, "%s is no longer on your team!", name);
		
		inWaitingToGift[client] = 0;
		beingGifted[receiver] = 0;
		
		if(GetClientMenu(receiver) != MenuSource_None )
			CancelClientMenu(receiver,true);
		
		EmitSoundToClient(client, SOUND_DENY);
		return Plugin_Stop;
	}
	
	if(GetTime() >= timeExpire)
	{
		PrintCenterText(client, "%s did not respond to your offer", name);
		PrintToChat(client, "%s did not respond to your offer", name);
		
		inWaitingToGift[client] = 0;
		beingGifted[receiver] = 0;
		
		if(GetClientMenu(receiver) != MenuSource_None )
			CancelClientMenu(receiver,true);
		
		EmitSoundToClient(client, SOUND_DENY);
		return Plugin_Stop;
	}
	
	if(UnAcceptable(receiver, award))
	{
		PrintCenterText(client, "%s can not be gifted at this time!", name);
		PrintToChat(client, "%s can not be gifted at this time!", name);
		
		inWaitingToGift[client] = 0;
		beingGifted[receiver] = 0;
		
		if(GetClientMenu(receiver) != MenuSource_None )
			CancelClientMenu(receiver,true);
		
		EmitSoundToClient(client, SOUND_DENY);
		return Plugin_Stop;
	}
	
	if(cost > RTDCredits[client])
	{
		PrintCenterText(client, "%s is sad because you are poor!", name);
		PrintToChat(client, "%s is sad because you are poor!", name);
		
		PrintCenterText(receiver, "%s no longer has enough credits", clientName);
		PrintToChat(receiver, "%s no longer has enough credits", clientName);
		
		inWaitingToGift[client] = 0;
		beingGifted[receiver] = 0;
		
		if(GetClientMenu(receiver) != MenuSource_None )
			CancelClientMenu(receiver,true);
		
		EmitSoundToClient(client, SOUND_DENY);
		return Plugin_Stop;
	}
	
	if(acceptedGift[receiver] == 1)
	{
		PrintCenterText(client, "%s accepted your gift", name);
		PrintToChat(client, "%s accepted your gift!", name);
		
		PrintCenterText(receiver, "Make sure to thank %s", clientName);
		PrintToChat(receiver, "make sure to thank %s", clientName);
		
		inWaitingToGift[client] = 0;
		beingGifted[receiver] = 0;
		acceptedGift[receiver] = 0;
		
		RTDCredits[client] -= cost;
		creds_Gifted[client] += cost;
		
		creds_ReceivedFromGifts[receiver] += cost;
		
		GivePlayerEffect(receiver, award, -1);
		
		if(GetClientMenu(receiver) != MenuSource_None )
			CancelClientMenu(receiver,true);
		
		EmitSoundToClient(client, SOUND_BOUGHTSOMETHING);
		return Plugin_Stop;
	}
	
	if(acceptedGift[receiver]  == -1)
	{
		PrintCenterText(client, "%s denied your gift!", name);
		PrintToChat(client, "%s denied your gift!", name);
		
		inWaitingToGift[client] = 0;
		beingGifted[receiver] = 0;
		
		EmitSoundToClient(client, SOUND_DENY);
		return Plugin_Stop;
	}
	
	new timeLeft = timeExpire - GetTime();
	PrintCenterText(client, "Waiting for response: %is left", timeLeft);
	PrintCenterText(receiver, "%s (%is left)", displayInfo, timeLeft);
	
	return Plugin_Continue;
}

public Action:SetupCreditsMenu(client, String:itemToBuy[])
{
	//somehow a client was able to call this function and disconnect
	//and so I need the following check
	if(!IsClientInGame(client))
		return Plugin_Handled;
	
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_CreditsMenuHandler);
	
	SetMenuTitle(hCMenu,"Credits Shopping Menu | %i/100 Credit limit used.",credsUsed[client][0]);
	
	addAllRolls(hCMenu, client);
	addLastRoll(hCMenu, client);
	
	if(StrEqual(itemToBuy, "", false))
	{
		DisplayMenu(hCMenu,client,MENU_TIME_FOREVER);
	}else{
		QuickBuy(hCMenu, client, itemToBuy);
	}
	
	return Plugin_Handled;
}

public fn_CreditsMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(param1 > 0)
	{
		if(IsClientInGame(param1))
		{
			if(!IsPlayerAlive(param1))
			{
				PrintCenterText(param1, "You must be alive and in game!");
				PrintToChat(param1, "You must be alive and in game!");
				action = MenuAction_Cancel;
			}
		}
	}
	
	if(param1 > 0 && param1 < cMaxClients)
	{
		if(inTimerBasedRoll[param1])
		{
			if(IsClientInGame(param1))
			{
				PrintCenterText(param1, "You can't purchase while in an active RTD");
				PrintToChat(param1, "You can't purchase while in an active RTD!");
				action = MenuAction_Cancel;
			}
		}
	}
	
	switch (action) 
	{
		case MenuAction_Select: 
		{
			new String:name[32];
			GetClientName(param1, name, sizeof(name));
			//qeury rtdcredits
			
			//format time left for CredsUsed
			new timeleft;
			new credsLeft;
			new cost;
			
			if(credsUsed[param1][1] == 0)
				credsUsed[param1][1] = GetTime();
			
			credsLeft = 100 - credsUsed[param1][0];
			timeleft  = 600 - (GetTime() - credsUsed[param1][1]);
			
			if(credsLeft < 0)
				credsLeft = 0;
			
			decl String:MenuInfo[64];
			new String:menuTriggers[4][128];
			new bool:allowPurchase = false;
			decl award;
			
			new style;
			GetMenuItem(menu, param2, MenuInfo, sizeof(MenuInfo),style);
			ExplodeString(MenuInfo, ":", menuTriggers, 3, 15);
			
			cost = StringToInt(menuTriggers[0]);
			award = StringToInt(menuTriggers[2]);
			
			/////////////////////////////////////////////////////////////////
			// REIMBURSE or DISCOUNT credits to original creator of idea   //
			/////////////////////////////////////////////////////////////////
			new String:clsteamId[MAX_LINE_WIDTH];
			new bool:reimburseCreds = false;
			new bool:giveDiscount = false;
			
			//make sure it is not blank
			//PrintToChatAll("sadasdasd: %s", roll_OwnerSteamID[award]);
			if(!StrEqual("", roll_OwnerSteamID[award], true))
			{
				GetClientAuthString(param1, clsteamId, sizeof(clsteamId));
				
				if(StrEqual(clsteamId, roll_OwnerSteamID[award], true))
				{
					//The original creator is purchasing the item
					//Give discount
					
					reimburseCreds = false;
					giveDiscount = true;
				}else{
					
					//Another client is purchasing the roll
					//Reimburse credits
					
					reimburseCreds = true;
					giveDiscount = false;
				}
			}
				
			/////////////////////////////////////////////////////////////////
			
			if(shop_discount != 0)
			{
				//PrintToChatAll("Cost %d | Shop Discount %f | Cost After %d", cost, shop_discount, RoundToFloor(cost * shop_discount));
				cost = RoundToFloor(cost * shop_discount);
			}
			
			//Determine if the player is allowed to purchase the selected item
			if(RTDCredits[param1] >= cost)
			{
				if(credsLeft < cost)
				{
					PrintCenterText(param1, "%i/100 Credit limit used. Please wait: %i seconds",credsUsed[param1][0], timeleft);
					PrintToChat(param1, "%i/100 Credit limit used. Please wait: %i seconds",credsUsed[param1][0], timeleft);
					EmitSoundToClient(param1, SOUND_DENY);
				}else{
					if(!inTimerBasedRoll[param1] && style != ITEMDRAW_DISABLED)
					{
						RTDCredits[param1] -= cost;
						credsUsed[param1][0] += cost;
						allowPurchase = true;
						
						if(reimburseCreds)
						{
							new amountToReimburse;
							amountToReimburse = RoundToCeil(float(cost) * 0.1);
							addCredits(amountToReimburse, award);
						}
						
						if(giveDiscount)
						{
							cost = RoundToFloor(cost * 0.9);
							PrintToChat(param1, "You received a discount from being the Idea Creator for this roll");
						}
						
						if(param2 != 0)
						{
							//GetMenuItem(menu, param2, MenuInfo, sizeof(MenuInfo),style);
							Format(lastBoughtRoll[param1], 64, "%s", MenuInfo);
						}
						
					}else{
						if(style == ITEMDRAW_DISABLED)
						{
							PrintCenterText(param1, "Requested item is DISABLED!");
							PrintToChat(param1, "Requested item is DISABLED!");
						}else{
							PrintCenterText(param1, "You cannot buy this while under RTD effect");
							PrintToChat(param1, "You cannot buy this while under RTD effect");
						}
						EmitSoundToClient(param1, SOUND_DENY);
					}
				}
			}else{
				PrintCenterText(param1, "You do not have enough CREDITS");
				PrintToChat(param1, "You do have enough CREDITS!");
			}
			
			//Massive If...then statement
			if(allowPurchase)
			{
				EmitSoundToClient(param1, SOUND_BOUGHTSOMETHING);
				
				
				if(StrContains(menuTriggers[1], "AWARD_G", false) != -1)
				{
					BoughtSomething[param1] = 1;
					GivePlayerEffect(param1, award, cost);
				}
				
				if(StrContains(menuTriggers[1], "Force", false) != -1)
				{
					BoughtSomething[param1] = 0;
					new value = StringToInt(menuTriggers[2]);
					new Float:adChance = float(value) * 0.01;
					amountOfBadRolls[param1] = adChance;
					ForceRTD(param1);
				}
				
				if(StrContains(menuTriggers[1], "Decrease", false) != -1)
				{
					RTD_Timer[param1] -= StringToInt(menuTriggers[2]);
				}
				
				if(StrEqual(menuTriggers[1], "BuyDice"))
				{
					BuyDice(param1);
				}else if(StrEqual(menuTriggers[1], "GiveCreds"))
				{
					SetupGenericMenu(1, param1);
				}else if(StrEqual(menuTriggers[1], "MediumAmmo"))
				{
					TF_SpawnMedipack(param1, "item_ammopack_medium", true);
				}else if(StrEqual(menuTriggers[1], "BuyDicePerks"))
				{
					SetupPerksMenu(param1, 0);
				}else if(StrEqual(menuTriggers[1], "GiveGift"))
				{
					SetupGiftMenu(param1);
				}else if(StrEqual(menuTriggers[1], "AddMinute"))
				{
					PrintToChatAll("[RTD] Player %s has purchased another minute!", name);
					Round_AddTime(60);
					Time_addClient(param1);
				}
				
				//Set the amount of credits used
				//if(credsLeft >= cost)
				//	PrintToChat(param1, "%i/100 Credit limit used.",credsUsed[param1][0]);
				
			}
		}
		
		case MenuAction_Cancel: {
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public QuickBuy(Handle:menu,client, String:itemToBuy[])
{
	//////////////////////////////////////////////////////////////
	//Look through the menu Handle and select the item          //
	//the user wants to buy                                     //
	//                                                          //
	//Note:the menu is not SHOWN to the client because there    //
	//is no need for it to be shown.                            //
	//////////////////////////////////////////////////////////////
	
	if(menu == INVALID_HANDLE)
		return;
	
	decl String:MenuInfo[64];
	new String:menuTriggers[16][64];
	new numTriggers = 0;
	decl curPos;
	
	for(new i=0; i < GetMenuItemCount(menu); i++)
	{
		GetMenuItem(menu, i, MenuInfo, sizeof(MenuInfo));
		ExplodeString(MenuInfo, ":", menuTriggers, 15, 25);
		
		curPos = 4;
		numTriggers = StringToInt(menuTriggers[3]);
		//PrintToChatAll("Menu:%s | NumTriggers:%i",MenuInfo,numTriggers);
		
		for(new j=1; j <= numTriggers; j ++)
		{
			//PrintToChatAll("Menu:%s | Trigger %i:%s",MenuInfo,j,menuTriggers[curPos]);
			if (StrEqual(itemToBuy, menuTriggers[curPos], false))
			{
				fn_CreditsMenuHandler(menu, MenuAction_Select, client, i);
				
				//PrintToChat(client, "\x03Trigger \x04%s\x03 found!",itemToBuy);
				return;
			}
			curPos ++;
		}
	}
	
	PrintToChat(client, "\x03Trigger \x04%s\x03 NOT found! Please check your spelling.",itemToBuy);
	EmitSoundToClient(client, SOUND_DENY);
	CloseHandle(menu);
}

public addLastRoll(Handle:hCMenu, client)
{
	decl String:MenuInfo[64];
	decl String:MenuDescription[64];
	new bool:found = false;
	new style;
	
	for (new i = 1; i <= GetMenuItemCount(hCMenu) ; i++)
	{
		GetMenuItem(hCMenu, i, MenuInfo, sizeof(MenuInfo),style, MenuDescription, sizeof(MenuDescription));
		
		
		if(StrEqual(MenuInfo, lastBoughtRoll[client]))
		{
			InsertMenuItem(hCMenu, 0, MenuInfo,	MenuDescription, style);
			
			found = true;
			break;
		}
	}
	
	if(!found)
		InsertMenuItem(hCMenu, 0, "placeholder",						"[Last Bought Roll]", ITEMDRAW_DISABLED);
}

public addRollsToShop(Handle:hCMenu, client, giftee)
{
	new costRoll[MAX_GOOD_AWARDS][2];
	new total;
	
	if(giftee == 0)
		giftee = client;
	
	//Load all those rolls that were loaded from the config
	for(new i = 0; i < MAX_GOOD_AWARDS; i ++)
	{
		if(roll_purchasable[i] && roll_isGood[i] && roll_cost[i] > 0)
		{
			costRoll[total][0] = i;
			costRoll[total][1] = roll_cost[i];
			total ++;
			
		}
	}
	
	//Sort the array by the cost, hopefully
	SortCustom2D(_:costRoll, total, SortDistanceAscend);
	
	new String:info[64];
	new String:display[64];
	new currentRoll;
	
	for(new i = 0; i < total; i ++)
	{
		currentRoll = costRoll[i][0];
		
		
		Format(info, sizeof(info), "%i:AWARD_G:%i:%i:%s", roll_cost[currentRoll], currentRoll, roll_amountTriggers[currentRoll], roll_QuickBuy[currentRoll]);
		Format(display, sizeof(display), "[%i Credits ] %s", roll_cost[currentRoll], roll_Text[currentRoll]);
		
		//Add the roll in the menu
		BoughtSomething[client] = 1;
		AddMenuItem(hCMenu, info, display, RTDCredits[giftee]<roll_cost[currentRoll]?ITEMDRAW_DISABLED:NoClipThisLife[client]?ITEMDRAW_DISABLED:UnAcceptable(client, currentRoll)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		BoughtSomething[client] = 0;
	}
}

public SortCostAscend(x[], y[], array[][], Handle:data)
{
    if (x[1] < y[1])
        return -1;
	else if (x[1] > y[1])
		return 1;
    return 0;
}

public addAllRolls(Handle:hCMenu, client)
{
	//////////////////////////////////////////////////////////////////////
	//To Increase readability each section should                       //
	//have at most 10 options followed by an empty line                 //
	//                                                                  //
	//About the Item's name:                                            //
	//AddMenuItem(hCMenu,"Cost:Function:Num Chat Triggers:Chat Triggers //
	//////////////////////////////////////////////////////////////////////
	
	AddMenuItem(hCMenu,"0:BuyDicePerks::4:perk:perks:diceperk:diceperks", "[0 Credits ] Buy Dice Perks", ITEMDRAW_DEFAULT);
	
	AddMenuItem(hCMenu,"0:BuyDice::1:dice",						"[0 Credits ] Buy Dice", RTDCredits[client]<1?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	AddMenuItem(hCMenu,"0:GiveGift::1:gift",					"[0 Credits ] Gift a roll to someone", RTDCredits[client]<1?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	AddMenuItem(hCMenu,"0:GiveCreds::2:givecreds:givecredits",	"[1 Credits ] Give credits to someone", RTDCredits[client]<1?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	
	AddMenuItem(hCMenu,"3:Decrease:30:1:decrease30",			"[3 Credits ] Decrease your Wait Time by 30 Seconds", RTDCredits[client]<3?ITEMDRAW_DISABLED:NoClipThisLife[client]?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	AddMenuItem(hCMenu,"5:MediumAmmo::2:mediumammo:medammo", 	"[5 Credits ] Buy Medium Ammo Pack", RTDCredits[client]<5?ITEMDRAW_DISABLED:NoClipThisLife[client]?ITEMDRAW_DISABLED:IsEntLimitReached()?ITEMDRAW_DISABLED:inTimerBasedRoll[client]?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	
	addRollsToShop(hCMenu, client, 0);
	
	

	AddMenuItem(hCMenu,"10:Force:0:1:50",						"[10 Credits] Buy a 50% chance of a good roll", RTDCredits[client]<10?ITEMDRAW_DISABLED:NoClipThisLife[client]?ITEMDRAW_DISABLED:inTimerBasedRoll[client]?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	
	AddMenuItem(hCMenu,"15:Force:10:1:60",						"[15 Credits] Buy a 60% chance of a good roll", RTDCredits[client]<15?ITEMDRAW_DISABLED:NoClipThisLife[client]?ITEMDRAW_DISABLED:inTimerBasedRoll[client]?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		
	AddMenuItem(hCMenu,"20:Force:50:1:100",						"[20 Credits] Buy a 100% chance of a good roll", RTDCredits[client]<20?ITEMDRAW_DISABLED:NoClipThisLife[client]?ITEMDRAW_DISABLED:inTimerBasedRoll[client]?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	
	AddMenuItem(hCMenu,"100:AddMinute::", "[100 Credits ] Add a minute to the round timer.", inSetup||RTDCredits[client]<50||Time_clientAlreadyBoughtTime(client)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
}

public Time_addClient(client)
{
	if (g_TimerExtendDatapack == INVALID_HANDLE) {
		g_TimerExtendDatapack = CreateDataPack();
		WritePackCell(g_TimerExtendDatapack, 0);
	}
	new String:steamID[64];
	ResetPack(g_TimerExtendDatapack);
	new records = ReadPackCell(g_TimerExtendDatapack);
	ResetPack(g_TimerExtendDatapack);
	WritePackCell(g_TimerExtendDatapack, records + 1);
	//Couldn't figure out a way to jump to the end
	for (new i = 0; i < records; i++)
		ReadPackString(g_TimerExtendDatapack, steamID, sizeof(steamID));
	GetClientAuthString(client, steamID, sizeof(steamID));
	WritePackString(g_TimerExtendDatapack, steamID);
}

public Time_clientAlreadyBoughtTime(client)
{
	if (g_TimerExtendDatapack == INVALID_HANDLE) {
		g_TimerExtendDatapack = CreateDataPack();
		WritePackCell(g_TimerExtendDatapack, 0);
	}
	new String:steamID[64], String:tempSteamID[64];
	GetClientAuthString(client, steamID, sizeof(steamID));
	ResetPack(g_TimerExtendDatapack);
	new records = ReadPackCell(g_TimerExtendDatapack);
	for (new i = 0; i < records; i++) {
		ReadPackString(g_TimerExtendDatapack, tempSteamID, sizeof(tempSteamID));
		if (StrEqual(steamID, tempSteamID, false))
			return true;
	}
	return false;
}