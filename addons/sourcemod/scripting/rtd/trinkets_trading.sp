#include <sourcemod>
#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>
#include <rtd_rollinfo>
#pragma semicolon 1

askAmountToTrade(client, selectedSlot)
{
	trading[client][0] = 1;
	trading[client][1] = selectedSlot;
	trading[client][2] = 0;
	
	new Handle:dataPackHandle;
	CreateDataTimer(0.5, Timer_AskForInput, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPackHandle, GetClientUserId(client));
	WritePackCell(dataPackHandle, GetTime() + 60);
}

public Action:Timer_AskForInput(Handle:timer, Handle:dataPackHandle)
{
	ResetPack(dataPackHandle);
	new client = GetClientOfUserId(ReadPackCell(dataPackHandle));
	new endTime = ReadPackCell(dataPackHandle);
	
	if(client < 1)
		return Plugin_Stop;
	
	if(!IsClientAuthorized(client))
	{
		cancelTrading(client, 0);
		return Plugin_Stop;
	}
	
	if(GetTime() > endTime)
	{
		PrintCenterText(client, "Trading timed out!");
		cancelTrading(client, 0);
		return Plugin_Stop;
	}
	
	if(trading[client][2] == 0)
	{
		PrintCenterText(client, "Enter trading amount in chat (%isecs left)",endTime - GetTime());
	}else if(trading[client][2] < 0){
		PrintCenterText(client, "Trading amount must be more than 0 credits! (%isecs left)",endTime - GetTime());
	}else{
		PrintCenterText(client, "Confirm trade amount of %i credits",trading[client][2]);
		confirmAmount(client);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action:confirmAmount(client)
{
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_ConfirmAmountMenuHandler);
	new String:menuTitle[64];
	
	trading[client][0] = 2; 
	new selectedSlot = trading[client][1];
	
	Format(menuTitle, 64, "Sell %s %s for %i credits?", trinket_TierID[RTD_TrinketIndex[client][selectedSlot]][RTD_TrinketTier[client][selectedSlot]], trinket_Title[RTD_TrinketIndex[client][selectedSlot]],trading[client][2]);
	
	SetMenuTitle(hCMenu, menuTitle);
	
	AddMenuItem(hCMenu, "0", "No", ITEMDRAW_DEFAULT);
	AddMenuItem(hCMenu, "1", "Yes", ITEMDRAW_DEFAULT);
	
	//SetMenuExitBackButton(hCMenu, true);
	DisplayMenuAtItem(hCMenu, client, 0, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public fn_ConfirmAmountMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{	
	switch (action) 
	{
		case MenuAction_Select: 
		{
			switch(param2)
			{
				//no
				case 0:
				{
					cancelTrading(param1, 1);
				}
				
				//approve trade
				case 1:
				{
					selectPlayerToTrade(param1);
				}
			}
		}
		
		case MenuAction_Cancel: {
			cancelTrading(param1, 1);
		}
		
		case MenuAction_End: 
		{
			cancelTrading(param1, 0);
			
			CloseHandle(menu);
		}
	}
}

stock selectPlayerToTrade(client)
{
	if(!IsClientInGame(client))
		return;
	
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_PlayerTradeMenuHandler);
	SetMenuTitle(hCMenu,"Select player to trade to");
		
	new String:name[32];
	new String:userid[32];
	new String:textInfo[64];
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(i == client)
			continue;
		
		if(!(IsClientInGame(i) && IsClientAuthorized(i)))
			continue;
		
		Format(userid, sizeof(userid), "%i", GetClientUserId(i));
		GetClientName(i, name, sizeof(name));
		
		Format(textInfo, sizeof(textInfo), "%s", name);
		AddMenuItem(hCMenu,userid, textInfo, trading[i][0]?ITEMDRAW_DISABLED:amountOfTrinketsHeld(i)>20?ITEMDRAW_DISABLED:RTDCredits[i]<trading[client][2]?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	}
	
	//SetMenuExitBackButton(hCMenu, true);
	DisplayMenu(hCMenu,client,MENU_TIME_FOREVER);
}

stock cancelTrading(client, goToMenu)
{
	if(client < 0 || client > MaxClients)
		return;
	
	trading[client][0] = 0;
	trading[client][1] = 0;
	trading[client][2] = 0;
	trading[client][3] = 0;
	trading[client][4] = 0;
	trading[client][5] = 0;
	
	if(goToMenu == 1)
		TrinketsLoadoutMenu(client, 0);
}

public fn_PlayerTradeMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{	
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
			
			if(receiver < 1)
			{
				PrintToChat(param1, "That player is no longer in game!");
				PrintCenterText(param1, "That player is no longer in game!");
				cancelTrading(param1, 1);
			}else if(!IsClientAuthorized(receiver))
			{
				PrintToChat(param1, "That player is no longer in game!");
				PrintCenterText(param1, "That player is no longer in game!");
				cancelTrading(param1, 1);
			}else if(trading[receiver][0] > 0)
			{
				PrintToChat(param1, "That player is already trading!");
				PrintCenterText(param1, "That player is already trading!");
				cancelTrading(param1, 1);
			}else if(amountOfTrinketsHeld(receiver)>20)
			{
				PrintToChat(param1, "That player's trinket inventory is full!");
				PrintCenterText(param1, "That player's trinket inventory is full!");
				cancelTrading(param1, 1);
			}else if(RTDCredits[receiver]<trading[param1][2])
			{
				PrintToChat(param1, "That player's does not have enough credits!");
				PrintCenterText(param1, "That player's does not have enough credits!");
				cancelTrading(param1, 1);
			}else{
				//Finally, ask buyer if offer is acceptable
				showOffer(param1, receiver);
			}
		}
		
		case MenuAction_Cancel: {
			cancelTrading(param1, 1);
		}
		
		case MenuAction_End: {
			cancelTrading(param1, 0);
			CloseHandle(menu);
		}
	}
}

public Action:showOffer(seller, receiver)
{
	new Handle:dataPackHandle;
	CreateDataTimer(0.5, WaitOnReceiver_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPackHandle, GetClientUserId(seller));
	WritePackCell(dataPackHandle, GetClientUserId(receiver));
	WritePackCell(dataPackHandle, GetTime() + 60);
	
	
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_confirmPurchase);
	new String:menuTitle[64];
	new String:menuDesc1[64];
	
	new String:sellername[32];
	GetClientName(seller, sellername, sizeof(sellername));
	
	new selectedSlot = trading[seller][1];
	
	Format(menuTitle, 64, "Accept %s's Trinket trade?", sellername);
	SetMenuTitle(hCMenu, menuTitle);
	
	
	Format(menuDesc1, 64, "%s %s for %i credits?", trinket_TierID[RTD_TrinketIndex[seller][selectedSlot]][RTD_TrinketTier[seller][selectedSlot]], trinket_Title[RTD_TrinketIndex[seller][selectedSlot]],trading[seller][2]);
	
	AddMenuItem(hCMenu, "0", menuDesc1, ITEMDRAW_DISABLED);
	AddMenuItem(hCMenu, "1", "No", ITEMDRAW_DEFAULT);
	AddMenuItem(hCMenu, "2", "Yes", ITEMDRAW_DEFAULT);
	
	trading[receiver][3] = GetClientUserId(seller);
	trading[receiver][5] = 0;
	trading[seller][4] = GetClientUserId(receiver);
	
	//SetMenuExitBackButton(hCMenu, true);
	DisplayMenuAtItem(hCMenu, receiver, 0, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public fn_confirmPurchase(Handle:menu, MenuAction:action, param1, param2)
{	
	switch (action) 
	{
		case MenuAction_Select: 
		{
			switch(param2)
			{
				//get outta here
				case 1:
				{
					cancelTrading(param1, 1);
					trading[param1][5] = -1;
				}
				
				//destroy trinket
				case 2:
				{
					new seller = GetClientOfUserId(trading[param1][3]);
					if(seller < 1)
					{
						PrintCenterText(param1, "Seller is no longer in game!");
						PrintToChat(param1, "Seller is no longer in game!");
						
						return;
					}
					
					if(!IsClientAuthorized(seller))
					{
						PrintCenterText(param1, "Seller is no longer in game!");
						PrintToChat(param1, "Seller is no longer in game!");
						
						return;
					}
					
					if(trading[seller][0] == 0)
					{
						PrintCenterText(param1, "Seller is no longer trading!");
						PrintToChat(param1, "Seller is no longer trading!");
						
						return;
					}
					
					if(GetClientOfUserId(trading[seller][4]) != param1)
					{
						PrintCenterText(param1, "Seller is busy with another trade!");
						PrintToChat(param1, "Seller is busy with another trade!");
						
						return;
					}
					
					finalAccept(seller, param1);
				}
			}
		}
		
		case MenuAction_Cancel: {
			cancelTrading(param1, 1);
			trading[param1][5] = -1;
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public Action:finalAccept(seller, receiver)
{		
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_OfferMenuHandler);
	new String:menuTitle[64];
	new String:menuDesc1[64];
	
	new String:sellername[32];
	GetClientName(seller, sellername, sizeof(sellername));
	
	new selectedSlot = trading[seller][1];
	
	Format(menuTitle, 64, "Confirm %s's Trinket trade?", sellername);
	SetMenuTitle(hCMenu, menuTitle);
	
	
	Format(menuDesc1, 64, "%s %s for %i credits?", trinket_TierID[RTD_TrinketIndex[seller][selectedSlot]][RTD_TrinketTier[seller][selectedSlot]], trinket_Title[RTD_TrinketIndex[seller][selectedSlot]],trading[seller][2]);
	
	AddMenuItem(hCMenu, "0", menuDesc1, ITEMDRAW_DISABLED);
	
	AddMenuItem(hCMenu, "1", "Last Confirmation!", ITEMDRAW_DISABLED);
	
	AddMenuItem(hCMenu, "2", "No", ITEMDRAW_DEFAULT);
	
	AddMenuItem(hCMenu, "3", "-", ITEMDRAW_DISABLED);
	AddMenuItem(hCMenu, "4", "Yes", ITEMDRAW_DEFAULT);
	
	trading[receiver][3] = GetClientUserId(seller);
	trading[receiver][5] = 0;
	trading[seller][4] = GetClientUserId(receiver);
	
	//SetMenuExitBackButton(hCMenu, true);
	DisplayMenuAtItem(hCMenu, receiver, 0, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Action:WaitOnReceiver_Timer(Handle:timer, Handle:dataPackHandle)
{
	ResetPack(dataPackHandle);
	new client = GetClientOfUserId(ReadPackCell(dataPackHandle));
	new receiver = GetClientOfUserId(ReadPackCell(dataPackHandle));
	new endTime = ReadPackCell(dataPackHandle);
	
	if(client < 1)
		return Plugin_Stop;
	
	if(!IsClientAuthorized(client))
	{
		cancelTrading(client, 0);
		return Plugin_Stop;
	}
	
	
	if(receiver < 1)
	{
		PrintToChat(client, "Buyer left the game!");
		PrintCenterText(client, "Buyer left the game!");
		cancelTrading(client, 0);
		return Plugin_Stop;
	}
	
	if(!IsClientAuthorized(receiver))
	{
		PrintToChat(client, "Buyer left the game!");
		PrintCenterText(client, "Buyer left the game!");
		cancelTrading(client, 0);
		return Plugin_Stop;
	}
	
	if(GetTime() > endTime)
	{
		PrintToChat(client, "Buyer did not respond!");
		PrintCenterText(client, "Buyer did not respond!");
		cancelTrading(client, 0);
		return Plugin_Stop;
	}
	
	if(trading[client][0] == 0)
	{
		PrintToChat(client, "You cancelled the trade!");
		PrintCenterText(client, "You cancelled the trade!");
		cancelTrading(client, 0);
		return Plugin_Stop;
	}
	
	//success
	if(trading[receiver][5] == 1)
	{
		cancelTrading(client, 0);
		cancelTrading(receiver, 0);
		return Plugin_Stop;
	}
	
	if(trading[receiver][5] == -1)
	{
		PrintToChat(client, "Trade was cancelled by buyer!");
		PrintCenterText(client, "Trade was cancelled by buyer!");
		cancelTrading(client, 0);
		return Plugin_Stop;
	}
	
	PrintCenterText(client, "Waiting (%isecs left)",endTime - GetTime());
	
	return Plugin_Continue;
}


public fn_OfferMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{	
	switch (action) 
	{
		case MenuAction_Select: 
		{
			switch(param2)
			{
				//no
				case 2:
				{
					cancelTrading(param1, 1);
					trading[param1][5] = -1;
				}
				
				//approve trade
				case 4:
				{
					new seller = GetClientOfUserId(trading[param1][3]);
					if(seller < 1)
					{
						PrintCenterText(param1, "Seller is no longer in game!");
						PrintToChat(param1, "Seller is no longer in game!");
						
						return;
					}
					
					if(!IsClientAuthorized(seller))
					{
						PrintCenterText(param1, "Seller is no longer in game!");
						PrintToChat(param1, "Seller is no longer in game!");
						
						return;
					}
					
					if(trading[seller][0] == 0)
					{
						PrintCenterText(param1, "Seller is no longer trading!");
						PrintToChat(param1, "Seller is no longer trading!");
						
						return;
					}
					
					if(GetClientOfUserId(trading[seller][4]) != param1)
					{
						PrintCenterText(param1, "Seller is busy with another trade!");
						PrintToChat(param1, "Seller is busy with another trade!");
						
						return;
					}
					
					if(RTDCredits[param1]<trading[seller][2])
					{
						PrintCenterText(param1, "Insufficient credits to continue trade!");
						PrintToChat(param1, "Insufficient credits to continue trade!");
						
						return;
					}
					
					if(amountOfTrinketsHeld(param1)>20)
					{
						PrintCenterText(param1, "You cannot hold more trinkets!");
						PrintToChat(param1, "You cannot hold more trinkets!");
						
						return;
					}
					
					//mark that the reciver accepted the offer
					trading[param1][5] = 1;
					
					//begin transfer
					RTDCredits[param1] -= trading[seller][2];
					RTDCredits[seller] += trading[seller][2];
					
					PrintCenterText(seller, "Your trinket was sold for: %i credits", trading[seller][2]);
					PrintToChat(seller, "Your trinket was sold for: %i credits", trading[seller][2]);
					
					new selectedSlot = trading[seller][1];
					
					//transfer values to buyer
					new availableSlot = nextAvailableSlot(param1);
					
					Format(RTD_TrinketUnique[param1][availableSlot], 32, "%s", RTD_TrinketUnique[seller][selectedSlot]);
					RTD_TrinketTier[param1][availableSlot] = RTD_TrinketTier[seller][selectedSlot];
					RTD_TrinketIndex[param1][availableSlot] = RTD_TrinketIndex[seller][selectedSlot];
					RTD_TrinketExpire[param1][availableSlot] = RTD_TrinketExpire[seller][selectedSlot];
					RTD_TrinketEquipped[param1][availableSlot] = 0;
					RTD_Trinket_DB_ID[param1][availableSlot] = 0;
					
					//clear values from seller
					eraseTrinket(seller, selectedSlot);
					
					//save trinket for buyer
					
					///finally we're done!!!!
					EmitSoundToClient(param1, SOUND_OPEN_TRINKET);
					EmitSoundToClient(seller, SOUND_BOUGHTSOMETHING);
					
					new String:name[32];
					GetClientName(param1, name, sizeof(name));
					
					decl String:chatMessage[200];
					Format(chatMessage, 128, "\x03%s\x04 received \x03%s %s\x04 from a trade", name, trinket_TierID[RTD_TrinketIndex[param1][availableSlot]][RTD_TrinketTier[param1][availableSlot]], trinket_Title[RTD_TrinketIndex[param1][availableSlot]]);
					PrintToChatAll(chatMessage);
				}
			}
		}
		
		case MenuAction_Cancel: {
			if(param1 > 0 && param1 < MaxClients)
				trading[param1][5] = -1;
		}
		
		case MenuAction_End: 
		{
			if(param1 > 0 && param1 < MaxClients)
				trading[param1][5] = -1;
			
			CloseHandle(menu);
		}
	}
	
	trading[param1][3] = 0;
}