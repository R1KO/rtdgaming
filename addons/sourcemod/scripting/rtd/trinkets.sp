#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <rtd_trinkets>

///////////////////////////////////////////////////////////
//              LOAD TRINKETS FROM TRINKETS.CFG          //
///////////////////////////////////////////////////////////
Load_Trinkets()
{	
	SetupTrinket_IDs(); //rtd_trinkets.cfg
	
	// Parse the objects list key values text to acquire all the possible
	// wearable items.
	new Handle:kvItemList = CreateKeyValues("RTD_Trinkets");
	new String:strLocation[256];
	new String:strLine[256];
	new String:splits[5][32];
	
	totalTrinkets = 0;
	
	//Setup our arrays that will store the loaded config data
	//afterwards it will be saved to a global array in proper order
	//that matches the order that is 'hard coded'
	new Handle: cfg_trinket_Unique 		= CreateArray(32, MAX_TRINKETS);
	new Handle: cfg_trinket_Title 		= CreateArray(32, MAX_TRINKETS);
	new Handle: cfg_trinket_Identifier 	= CreateArray(64, MAX_TRINKETS);
	new Handle: cfg_trinket_Description = CreateArray(128, MAX_TRINKETS);
	new Handle: cfg_trinket_TierID		= CreateArray(128, MAX_TRINKETS);
	new Handle: cfg_trinket_BonusAmount = CreateArray(32, MAX_TRINKETS);
	new Handle: cfg_trinket_TierChance 	= CreateArray(32, MAX_TRINKETS);
	
	new Handle: cfg_trinket_Enabled 	= CreateArray(1, MAX_TRINKETS);
	new Handle: cfg_trinket_Rarity 		= CreateArray(1, MAX_TRINKETS);
	new Handle: cfg_trinket_Tiers 		= CreateArray(1, MAX_TRINKETS);
	new Handle: cfg_trinket_Index	 	= CreateArray(1, MAX_TRINKETS);

	
	// Load the key files.
	BuildPath(Path_SM, strLocation, 256, "configs/rtd/trinkets.cfg");
	FileToKeyValues(kvItemList, strLocation);
	
	// Check if the parsed values are correct
	if (!KvGotoFirstSubKey(kvItemList)) 
	{ 
		LogToFile(logPath,"Error, can't read file containing RTD_Trinkets: %s", strLocation);
		return; 
	}
	
	
	// Iterate through all keys.
	do
	{
		//Read as Strings
		KvGetString(kvItemList, "unique", strLine, sizeof(strLine), "");
		SetArrayString(cfg_trinket_Unique, totalTrinkets, strLine);
		
		KvGetString(kvItemList, "title", strLine, sizeof(strLine), "");
		SetArrayString(cfg_trinket_Title, totalTrinkets, strLine);
		
		KvGetString(kvItemList, "identifier", strLine, sizeof(strLine), "");
		SetArrayString(cfg_trinket_Identifier, totalTrinkets, strLine);
		
		
		KvGetString(kvItemList, "description", strLine, sizeof(strLine), "");
		SetArrayString(cfg_trinket_Description, totalTrinkets, strLine);
		
		KvGetString(kvItemList, "tierID", strLine, sizeof(strLine), "");
		SetArrayString(cfg_trinket_TierID, totalTrinkets, strLine);
		
		KvGetString(kvItemList, "bonusAmount", strLine, sizeof(strLine), "");
		SetArrayString(cfg_trinket_BonusAmount, totalTrinkets, strLine);
		
		KvGetString(kvItemList, "tierChance", strLine, sizeof(strLine), "");
		SetArrayString(cfg_trinket_TierChance, totalTrinkets, strLine);
		
		
		//Read as Ints
		KvGetString(kvItemList, "enabled", strLine, sizeof(strLine), "");
		SetArrayCell(cfg_trinket_Enabled, totalTrinkets, StringToInt(strLine), 0);
		
		KvGetString(kvItemList, "rarity", strLine, sizeof(strLine), "");
		SetArrayCell(cfg_trinket_Rarity, totalTrinkets, StringToInt(strLine), 0);
		
		KvGetString(kvItemList, "tiers", strLine, sizeof(strLine), "");
		SetArrayCell(cfg_trinket_Tiers, totalTrinkets, StringToInt(strLine), 0);
		
		SetArrayCell(cfg_trinket_Index, totalTrinkets, totalTrinkets, 0);
		
		totalTrinkets ++;
	}
	while (KvGotoNextKey(kvItemList));
	
	CloseHandle(kvItemList);

	//////////////////////////////////////////////////////
	//Match up the loaded configs with 'hard coded' ids //
	//////////////////////////////////////////////////////
	//lastFound = 0;
	
	//start comparing the 'hard codes' ids
	for(new i = 0; i < MAX_TRINKETS; i++)
	{
		//compare 'hard coded' id with loaded id from config 
		for(new step = 0; step < GetArraySize(cfg_trinket_Identifier); step++)
		{
			//Found a match
			GetArrayString(cfg_trinket_Identifier, step, strLine, 32);
			
			//Debug message
			//PrintToChatAll("Found: %s | Attempting to match: %s", strLine, trinket_id[i]);
			
			if(StrEqual(trinket_id[i], strLine, false) && !StrEqual(trinket_id[i], "", false) && !StrEqual(strLine, "", false))
			{
				trinket_Index[i] = GetArrayCell(cfg_trinket_Index, step, 0);
				
				///////////////////////////////////////////
				//move the temp data into our main array //
				///////////////////////////////////////////
				GetArrayString(cfg_trinket_Identifier, step, trinket_Identifier[i], 32);
				GetArrayString(cfg_trinket_Title, step, trinket_Title[i], 32);
				GetArrayString(cfg_trinket_Unique, step, trinket_Unique[i], 32);
				GetArrayString(cfg_trinket_Description, step, trinket_Description[i], 32);
				
				/////////////////////////
				//split up the TierIDs //
				/////////////////////////
				GetArrayString(cfg_trinket_TierID, step, strLine, 128);
				ExplodeString(strLine, ",", trinket_TierID[i], 4, 15);
				
				///////////////////////////////
				//split up the Bonus amounts //
				///////////////////////////////
				GetArrayString(cfg_trinket_BonusAmount, step, strLine, 32);
				ExplodeString(strLine, ",", splits, 4, 32);
				
				trinket_BonusAmount[i][0] = StringToInt(splits[0]);
				trinket_BonusAmount[i][1] = StringToInt(splits[1]);
				trinket_BonusAmount[i][2] = StringToInt(splits[2]);
				trinket_BonusAmount[i][3] = StringToInt(splits[3]);
				
				////////////////////////////
				//split up the tierChance //
				////////////////////////////
				GetArrayString(cfg_trinket_TierChance, step, strLine, 32);
				ExplodeString(strLine, ",", splits, 4, 32);
				
				trinket_TierChance[i][0] = StringToInt(splits[0]);
				trinket_TierChance[i][1] = StringToInt(splits[1]);
				trinket_TierChance[i][2] = StringToInt(splits[2]);
				trinket_TierChance[i][3] = StringToInt(splits[3]);
				trinket_TotalChance[i] = trinket_TierChance[i][0] + trinket_TierChance[i][1] + trinket_TierChance[i][2] + trinket_TierChance[i][3];
				
				trinketChanceBounds[i][0] = trinket_TierChance[i][0];
				trinketChanceBounds[i][1] = trinket_TierChance[i][0] + trinket_TierChance[i][1];
				trinketChanceBounds[i][2] = trinketChanceBounds[i][1] + trinket_TierChance[i][2];
				trinketChanceBounds[i][3] = trinketChanceBounds[i][2] + trinket_TierChance[i][3];
				
				///////////////////////////////////////////
				//Phew, load up the other 1 digit values //
				///////////////////////////////////////////
				trinket_Enabled[i]	= GetArrayCell(cfg_trinket_Enabled, step, 0);
				trinket_Rarity[i]	= GetArrayCell(cfg_trinket_Rarity, step, 0);
				trinket_Tiers[i]	= GetArrayCell(cfg_trinket_Tiers, step, 0);
				
				
				//////////////////////////////
				//Remove this set of arrays //
				//////////////////////////////
				RemoveFromArray(cfg_trinket_Unique, step);
				RemoveFromArray(cfg_trinket_Title, step);
				RemoveFromArray(cfg_trinket_Identifier, step);
				RemoveFromArray(cfg_trinket_Description, step);
				RemoveFromArray(cfg_trinket_TierID, step);
				RemoveFromArray(cfg_trinket_BonusAmount, step);
				RemoveFromArray(cfg_trinket_TierChance, step);
				RemoveFromArray(cfg_trinket_Enabled, step);
				RemoveFromArray(cfg_trinket_Rarity, step);
				RemoveFromArray(cfg_trinket_Tiers, step);
				RemoveFromArray(cfg_trinket_Index, step);
				
				//debug message
				//PrintToChatAll("Trinket %s [%i]: | TierID: %s | Unique: %s", trinket_Title[i], trinket_Index[i], trinket_Identifier[i], trinket_Unique[i]);
				//PrintToChatAll("Tier chance %i|%i|%i|%i", trinket_TierChance[i][0], trinket_TierChance[i][1], trinket_TierChance[i][2], trinket_TierChance[i][3]);
				
				break;
			}
		}
	}
	
	CloseHandle(cfg_trinket_Unique);
	CloseHandle(cfg_trinket_Title);
	CloseHandle(cfg_trinket_Identifier);
	CloseHandle(cfg_trinket_Description);
	CloseHandle(cfg_trinket_TierID);
	CloseHandle(cfg_trinket_BonusAmount);
	CloseHandle(cfg_trinket_TierChance);
	CloseHandle(cfg_trinket_Enabled);
	CloseHandle(cfg_trinket_Rarity);
	CloseHandle(cfg_trinket_Tiers);
	CloseHandle(cfg_trinket_Index);
}

////////////////////////////////
// $ Trinkets Shopping Menu $ //
////////////////////////////////
public Action:SetupTrinketsMenu(client, startAtPage)
{
	trading[client][0] = 0;
	trading[client][1] = 0;
	trading[client][2] = 0;
	trading[client][3] = 0;
	trading[client][4] = 0;
	trading[client][5] = 0;
	
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_TrinketsMenuHandler);
	
	new String:menuTitle[64];
	Format(menuTitle, 64, "Trinkets Menu (%i/20)", amountOfTrinketsHeld(client));
	SetMenuTitle(hCMenu, menuTitle);
	
	new String:displayInfo[64];
	
	if(amountOfTrinketsHeld(client) < 1)
	{
		AddMenuItem(hCMenu, "0", "Trinket Loadout", ITEMDRAW_DISABLED);
	}else{
		AddMenuItem(hCMenu, "0", "Trinket Loadout", ITEMDRAW_DEFAULT);
	}
	
	Format(displayInfo, sizeof(displayInfo), "[%i Credits] Purchase Random Trinket", rtd_trinketPrice);
	AddMenuItem(hCMenu, "1", displayInfo, ITEMDRAW_DEFAULT);
	
	
	DisplayMenuAtItem(hCMenu, client, 0, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public fn_TrinketsMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{	
	switch (action) 
	{
		case MenuAction_Select: 
		{
			switch(param2)
			{
				case 0:
				{
					TrinketsLoadoutMenu(param1, 0);
				}
				
				case 1:
				{
					if(RTDCredits[param1] >= rtd_trinketPrice)
					{
						if(nextAvailableSlot(param1) >= 0)
						{
							GiveRandomTrinket(param1, 0);
							//SetupTrinketsMenu(param1, 0);
						}else{
							PrintCenterText(param1, "Trinket limit reached!");
							PrintToChat(param1, "Trinket limit reached!");
						}
					}else{
						PrintCenterText(param1, "Insufficent Credits!");
						PrintToChat(param1, "Insufficent Credits!");
						
						EmitSoundToClient(param1, SOUND_DENY);
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

public listTrinkets(client)
{
	/*
	//new Handle: temp_Trinkets 	= CreateArray(2, MAX_TRINKETS);
	new temp_Trinkets[50][4];
	new foundTrinkets;
	decl String:chatMessage[200];
	
	//Trinkets
	for(new i = 0; i < 50; i++)
	{
		if(!StrEqual(RTD_TrinketUnique[client][i], "", false))
		{
			temp_Trinkets[foundTrinkets][0] = RTD_TrinketIndex[client][i];
			temp_Trinkets[foundTrinkets][1] = RTD_TrinketTier[client][i];
			temp_Trinkets[foundTrinkets][2] = RTD_TrinketExpire[client][i];
			temp_Trinkets[foundTrinkets][3] = RTD_TrinketEquipped[client][i];
			
			RTD_TrinketUnique[client][i];Format(RTD_TrinketUnique[client][availableSlot], 32, "%s", trinket_Unique[awardedTrinket]);
			foundTrinkets ++;
		}
	}
	
	SortCustom2D(_:temp_Trinkets, foundTrinkets, SortAscend);
	

	for(new i = 0; i < foundTrinkets; i++)
	{
		RTD_TrinketIndex[client][i] = temp_Trinkets[foundTrinkets][0];
		RTD_TrinketTier[client][i] = temp_Trinkets[foundTrinkets][1];
		RTD_TrinketExpire[client][i] = temp_Trinkets[foundTrinkets][2];
		RTD_TrinketEquipped[client][i] = temp_Trinkets[foundTrinkets][3];
		
		Format(chatMessage, sizeof(chatMessage), "\x03%s \x01%s \x04Trinket", trinket_TierID[temp_Trinkets[i][0]][temp_Trinkets[i][1]], trinket_Title[temp_Trinkets[i][0]]);
		PrintToChat(client, chatMessage); 
	}*/
	
}

///////////////////////////////////
//       Organize Trinkets       //
//                               //
// Equippd items are in 1st slot //
// Rest are ordered by Variant   //
//                               //
///////////////////////////////////
public organizeTrinkets(client)
{
	//new Handle: temp_Trinkets 	= CreateArray(2, MAX_TRINKETS);
	new temp_Trinkets[50][2];
	new placeholder_Trinkets[50][5];
	new foundTrinkets;
	
	//Sort by saving the index and the tier
	for(new i = 0; i < 21; i++)
	{
		if(!StrEqual(RTD_TrinketUnique[client][i], "", false))
		{
			temp_Trinkets[foundTrinkets][0] = i;
			
			if(RTD_TrinketEquipped[client][i])
			{
				temp_Trinkets[foundTrinkets][1] = 999; //bump equipped to the top
			}else{
				if(trinketExpired(client, i))
				{
					temp_Trinkets[foundTrinkets][1] = RTD_TrinketTier[client][i] - 100;
				}else{
					temp_Trinkets[foundTrinkets][1] = RTD_TrinketTier[client][i];
				}
			}
			
			placeholder_Trinkets[i][0] = RTD_TrinketIndex[client][i];
			placeholder_Trinkets[i][1] = RTD_TrinketTier[client][i];
			placeholder_Trinkets[i][2] = RTD_TrinketExpire[client][i];
			placeholder_Trinkets[i][3] = RTD_TrinketEquipped[client][i];
			placeholder_Trinkets[i][4] = RTD_Trinket_DB_ID[client][i];
			
			//clear out the unique
			Format(RTD_TrinketUnique[client][i], 32, "");
			
			foundTrinkets ++;
			
		}
	}
	
	SortCustom2D(_:temp_Trinkets, foundTrinkets, SortAscend);
	
	new savedSlot;
	
	for(new i = 0; i < foundTrinkets; i++)
	{
		savedSlot = temp_Trinkets[i][0];
		
		
		RTD_TrinketIndex[client][i] = placeholder_Trinkets[savedSlot][0];
		RTD_TrinketTier[client][i] = placeholder_Trinkets[savedSlot][1];
		RTD_TrinketExpire[client][i] = placeholder_Trinkets[savedSlot][2];
		RTD_TrinketEquipped[client][i] = placeholder_Trinkets[savedSlot][3];
		RTD_Trinket_DB_ID[client][i] = placeholder_Trinkets[savedSlot][4];
		
		Format(RTD_TrinketUnique[client][i], 32, "%s", trinket_Unique[RTD_TrinketIndex[client][i]]);
	}
	
	
	//find the equipped
}


public Action:TrinketsLoadoutMenu(client, startAtPage)
{
	trading[client][0] = 0;
	trading[client][1] = 0;
	trading[client][2] = 0;
	trading[client][3] = 0;
	trading[client][4] = 0;
	trading[client][5] = 0;
	
	smelting[client][0] = -1;
	smelting[client][1] = -1;
	
	if(amountOfTrinketsHeld(client) < 1)
	{
		SetupTrinketsMenu(client, 1);
		PrintCenterText(client, "You have no trinkets!");
	}
	
	organizeTrinkets(client);
	
	
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_TrinketsLoadOutHandler);
	
	new String:menuTitle[64];
	Format(menuTitle, 64, "Trinkets Loadout Menu (%i/20)", amountOfTrinketsHeld(client));
	
	SetMenuTitle(hCMenu, menuTitle);
	
	new String:displayInfo[64];
	new String:displayIdent[64];
	new String:expireTime[64];
	
	new hrsLeft;
	new minsLeft;
	new totalTimeLeft;
	new daysLeft;
	
	//Trinkets
	for(new i = 0; i < 20; i++)
	{
		if(!StrEqual(RTD_TrinketUnique[client][i], "", false))
		{
			
			hrsLeft= 0; 
			minsLeft = 0;
			daysLeft = 0;
			
			totalTimeLeft = RTD_TrinketExpire[client][i] - GetTime();
			
			//PrintToChat(client, "Total Timeleft: %i (%i - %i)", totalTimeLeft, RTD_TrinketExpire[client][i], GetTime());
			
			
			if(totalTimeLeft > 0)
			{
				daysLeft = RoundToFloor(float(totalTimeLeft)/ 86400.0);
				hrsLeft = RoundToFloor(float(totalTimeLeft)/ 3600.0) - (daysLeft * 24);
				minsLeft = RoundToFloor(float((totalTimeLeft - daysLeft * 86400 - hrsLeft * 3600))/60.0);
			}
			
			Format(expireTime, 64, "%id:%ih:%im", daysLeft, hrsLeft, minsLeft);
			
			if(RTD_TrinketEquipped[client][i] == 1)
			{
				Format(displayInfo, 64, "[Equipped] (%s) %s (Expires: %s)", trinket_TierID[RTD_TrinketIndex[client][i]][RTD_TrinketTier[client][i]], trinket_Title[RTD_TrinketIndex[client][i]], expireTime);
				
				Format(displayIdent, 64, "%i:1", i); //1 = equipped
				
			}else{
				if(RTD_TrinketExpire[client][i] < GetTime())
				{
					Format(displayInfo, 64, "[Expired] (%s) %s", trinket_TierID[RTD_TrinketIndex[client][i]][RTD_TrinketTier[client][i]], trinket_Title[RTD_TrinketIndex[client][i]]);
					
					Format(displayIdent, 64, "%i:0", i); //0 = expired
				}else{
					Format(displayInfo, 64, "(%s) %s (Expires in %s)", trinket_TierID[RTD_TrinketIndex[client][i]][RTD_TrinketTier[client][i]], trinket_Title[RTD_TrinketIndex[client][i]], expireTime);
					
					Format(displayIdent, 64, "%i:2", i); //2 = unequipped
				}
			}
			
			AddMenuItem(hCMenu, displayIdent, displayInfo, ITEMDRAW_DEFAULT);
		}
	}
	
	SetMenuExitBackButton(hCMenu, true);
	DisplayMenuAtItem(hCMenu, client, startAtPage, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public fn_TrinketsLoadOutHandler(Handle:menu, MenuAction:action, param1, param2)
{	
	switch (action) 
	{
		case MenuAction_Select: 
		{
			//param2 item
			//param1 client
			decl String:MenuInfo[64];
			new String:menuTriggers[4][16];
			new style;
			new selectedSlot;
			new slotStatus;
			
			GetMenuItem(menu, param2, MenuInfo, sizeof(MenuInfo),style);
			ExplodeString(MenuInfo, ":", menuTriggers, 2, 3);
			
			selectedSlot = StringToInt(menuTriggers[0]);
			slotStatus = StringToInt(menuTriggers[1]);
			
			showTrinketSelectionMenu(param1, selectedSlot, slotStatus);
		}
		
		case MenuAction_Cancel: {
			SetupTrinketsMenu(param1, 1);
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public Action:showTrinketSelectionMenu(client, selectedSlot, slotStatus)
{
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_TrinSelMenuHandler);
	new String:menuTitle[64];
	
	Format(menuTitle, 64, "Select action for trinket: %s %s", trinket_TierID[RTD_TrinketIndex[client][selectedSlot]][RTD_TrinketTier[client][selectedSlot]], trinket_Title[RTD_TrinketIndex[client][selectedSlot]]);
	
	SetMenuTitle(hCMenu, menuTitle);
	
	new String:extendTrinket[64];
	new String:displayIdent[64];
	new String:reRollText[64];
	
	//slotStatus
	//1 = equipped
	//0 = expired
	//2 = unequipped
	
	Format(extendTrinket, 64, "[%i Credits] 30 Day Trinket Extension", rtd_trinketExtPrice);
	Format(reRollText, 64, "[%i Credits] Reroll Variant", rtd_trinket_rerollPrice);
	
	if(slotStatus == 1)
	{
		Format(displayIdent, 64, "%i:2", selectedSlot);
		AddMenuItem(hCMenu, displayIdent, "Unequip Trinket", ITEMDRAW_DEFAULT);
	}else if(slotStatus == 2)
	{
		Format(displayIdent, 64, "%i:1", selectedSlot);
		AddMenuItem(hCMenu, displayIdent, "Equip Trinket", ITEMDRAW_DEFAULT);
	}
	
	Format(displayIdent, 64, "%i:0", selectedSlot);
	AddMenuItem(hCMenu, displayIdent, extendTrinket, ITEMDRAW_DEFAULT);
	
	Format(displayIdent, 64, "%i:4", selectedSlot);
	//AddMenuItem(hCMenu, displayIdent, reRollText, ITEMDRAW_DEFAULT);
	AddMenuItem(hCMenu, displayIdent, reRollText, RTD_TrinketTier[client][selectedSlot]>=(trinket_Tiers[RTD_TrinketIndex[client][selectedSlot]]-1)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	
	Format(displayIdent, 64, "%i:5", selectedSlot);
	AddMenuItem(hCMenu, displayIdent, "Trade Trinket!", ITEMDRAW_DEFAULT);
	
	Format(displayIdent, 64, "%i:6", selectedSlot);
	AddMenuItem(hCMenu, displayIdent, "Smelt Trinket!", ITEMDRAW_DEFAULT);
	
	Format(displayIdent, 64, "%i:3", selectedSlot);
	AddMenuItem(hCMenu, displayIdent, "Destroy Trinket!", ITEMDRAW_DEFAULT);
	
	SetMenuExitBackButton(hCMenu, true);
	DisplayMenuAtItem(hCMenu, client, 0, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public fn_TrinSelMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{	
	switch (action) 
	{
		case MenuAction_Select: 
		{
			//param2 item
			//param1 client
			decl String:MenuInfo[64];
			new String:menuTriggers[4][16];
			decl String:chatMessage[200];
			
			new style;
			new selectedSlot;
			new slotStatus;
			
			GetMenuItem(menu, param2, MenuInfo, sizeof(MenuInfo),style);
			ExplodeString(MenuInfo, ":", menuTriggers, 2, 3);
			
			selectedSlot = StringToInt(menuTriggers[0]);
			slotStatus = StringToInt(menuTriggers[1]);
			
			switch(slotStatus)
			{
				//extend trinket
				case 0:
				{
					if(RTDCredits[param1] >= rtd_trinketExtPrice)
					{
						EmitSoundToClient(param1, SOUND_BOUGHTSOMETHING);
						
						RTDCredits[param1] -= rtd_trinketExtPrice;
						
						if(RTD_TrinketExpire[param1][selectedSlot] < GetTime())
						{
							RTD_TrinketExpire[param1][selectedSlot] = GetTime() + 2592000;
						}else{
							RTD_TrinketExpire[param1][selectedSlot] += 2592000;
						}
						
						Format(chatMessage, sizeof(chatMessage), "\x03Extended\x04 (\x03%s\x04) \x01%s \x04Trinket", trinket_TierID[RTD_TrinketIndex[param1][selectedSlot]][RTD_TrinketTier[param1][selectedSlot]], trinket_Title[RTD_TrinketIndex[param1][selectedSlot]]);
						PrintToChat(param1, chatMessage); 
						
						Format(chatMessage, sizeof(chatMessage), "Extended (%s) %s Trinket", trinket_TierID[RTD_TrinketIndex[param1][selectedSlot]][RTD_TrinketTier[param1][selectedSlot]], trinket_Title[RTD_TrinketIndex[param1][selectedSlot]]);
						PrintCenterText(param1, chatMessage);
						
						TrinketsLoadoutMenu(param1, 0);
						
					}else{
						PrintCenterText(param1, "Insufficent Credits!");
						PrintToChat(param1, "Insufficent Credits!");
						
						EmitSoundToClient(param1, SOUND_DENY);
					}
				}
				
				//equip trinket
				case 1:
				{
					//trinket cool down
					if(RTD_TrinketEquipTime[param1] > GetTime())
					{
						
						Format(chatMessage, sizeof(chatMessage), "\x03Trinket cool down: \x01%is", RTD_TrinketEquipTime[param1] - GetTime());
						PrintToChat(param1, chatMessage); 
						
						Format(chatMessage, sizeof(chatMessage), "Must wait %is before changing trinkets", RTD_TrinketEquipTime[param1] - GetTime());
						PrintCenterText(param1, chatMessage);
						
						EmitSoundToClient(param1, SOUND_DENY);
						
						TrinketsLoadoutMenu(param1, 0);
					}else{
						RTD_TrinketEquipTime[param1] = GetTime() + 30;
						
						unequipTrinkets(param1);
						
						RTD_TrinketEquipped[param1][selectedSlot] = 1;
						equipActiveTrinket(param1);
						
						Format(chatMessage, sizeof(chatMessage), "\x03Equipped\x04 (\x03%s\x04) \x01%s \x04Trinket", trinket_TierID[RTD_TrinketIndex[param1][selectedSlot]][RTD_TrinketTier[param1][selectedSlot]], trinket_Title[RTD_TrinketIndex[param1][selectedSlot]]);
						PrintToChat(param1, chatMessage); 
						
						Format(chatMessage, sizeof(chatMessage), "Equipped (%s) %s Trinket", trinket_TierID[RTD_TrinketIndex[param1][selectedSlot]][RTD_TrinketTier[param1][selectedSlot]], trinket_Title[RTD_TrinketIndex[param1][selectedSlot]]);
						PrintCenterText(param1, chatMessage);
						
						//TrinketsLoadoutMenu(param1, 0);
					}
					
				}
				
				//unequip trinket
				case 2:
				{
					unequipTrinkets(param1);
					
					Format(chatMessage, sizeof(chatMessage), "\x03Unequipped\x04 (\x03%s\x04)\x01%s \x04Trinket", trinket_TierID[RTD_TrinketIndex[param1][selectedSlot]][RTD_TrinketTier[param1][selectedSlot]], trinket_Title[RTD_TrinketIndex[param1][selectedSlot]]);
					PrintToChat(param1, chatMessage); 
					
					Format(chatMessage, sizeof(chatMessage), "Unequipped (%s) %s Trinket", trinket_TierID[RTD_TrinketIndex[param1][selectedSlot]][RTD_TrinketTier[param1][selectedSlot]], trinket_Title[RTD_TrinketIndex[param1][selectedSlot]]);
					PrintCenterText(param1, chatMessage);
					
					TrinketsLoadoutMenu(param1, 0);
				}
				
				//destroy trinket
				case 3:
				{
					confirmDestroyTrinket(param1, selectedSlot, slotStatus);
				}
				
				//reroll Variant
				case 4:
				{
					confirmReRollTrinket(param1, selectedSlot, slotStatus);
				}
				
				//trade trinket
				case 5:
				{
					askAmountToTrade(param1, selectedSlot);
				}
				
				//smelt trinket
				case 6:
				{
					selectSecondTrinket(param1, selectedSlot);
				}
			}
		}
		
		case MenuAction_Cancel: {
			TrinketsLoadoutMenu(param1, 0);
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

////////////////////////////////////////
// Reroll Trinket                     //
// User can change variant on trinket //
////////////////////////////////////////
public Action:confirmReRollTrinket(client, selectedSlot, slotStatus)
{
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_ReRollTrinkMenuHandler);
	
	new String:menuTitle[64];
	new String:displayIdent[64];
	
	Format(menuTitle, 64, "[%i Credits] Change variant on: %s %s ?", rtd_trinket_rerollPrice, trinket_TierID[RTD_TrinketIndex[client][selectedSlot]][RTD_TrinketTier[client][selectedSlot]], trinket_Title[RTD_TrinketIndex[client][selectedSlot]]);
	SetMenuTitle(hCMenu, menuTitle);
	
	Format(displayIdent, 64, "%i", selectedSlot);
	AddMenuItem(hCMenu, displayIdent, "No", ITEMDRAW_DEFAULT);
	
	Format(displayIdent, 64, "%i", selectedSlot);
	AddMenuItem(hCMenu, displayIdent, "Yes", ITEMDRAW_DEFAULT);
	
	SetMenuExitBackButton(hCMenu, true);
	DisplayMenuAtItem(hCMenu, client, 0, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public fn_ReRollTrinkMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{	
	switch (action) 
	{
		case MenuAction_Select: 
		{
			decl String:MenuInfo[64];
			decl String:chatMessage[200];
			
			new style;
			new selectedSlot;
			
			GetMenuItem(menu, param2, MenuInfo, sizeof(MenuInfo),style);
			
			selectedSlot = StringToInt(MenuInfo[0]);
			
			switch(param2)
			{
				//get outta here
				case 0:
				{
				}
				
				//change variant on trinket
				case 1:
				{
					if(RTDCredits[param1] >= rtd_trinket_rerollPrice)
					{
						EmitSoundToClient(param1, SOUND_BOUGHTSOMETHING);
						
						RTDCredits[param1] -= rtd_trinket_rerollPrice;
							
						new variant;
						new oldVariant = RTD_TrinketTier[param1][selectedSlot];
						new rndNum;
						
						rndNum = GetRandomInt(1, trinket_TotalChance[RTD_TrinketIndex[param1][selectedSlot]]);
						
						//PrintToChat(param1, "%i", rndNum);
						
						//find out which tier our rndNum falls under
						for(new i = 0; i < trinket_Tiers[RTD_TrinketIndex[param1][selectedSlot]]; i++)
						{
							if(rndNum <= trinketChanceBounds[RTD_TrinketIndex[param1][selectedSlot]][i])
							{
								variant = i;
								break;
							}
						}
						
						RTD_TrinketTier[param1][selectedSlot] = variant;
						
						equipActiveTrinket(param1);
						
						EmitSoundToClient(param1, SOUND_OPEN_TRINKET);
						
						new String:name[32];
						GetClientName(param1, name, sizeof(name));
						
						Format(chatMessage, 128, "\x03%s\x04 rerolled \x03%s\x04 from: \x01%s\x04 to \x01%s", name, trinket_Title[RTD_TrinketIndex[param1][selectedSlot]], trinket_TierID[RTD_TrinketIndex[param1][selectedSlot]][oldVariant], trinket_TierID[RTD_TrinketIndex[param1][selectedSlot]][variant]);
						PrintToChatAll(chatMessage);
						
						Format(chatMessage, sizeof(chatMessage), "Obtained: (%s) %s Trinket", trinket_TierID[RTD_TrinketIndex[param1][selectedSlot]][variant], trinket_Title[RTD_TrinketIndex[param1][selectedSlot]]);
						PrintCenterText(param1, chatMessage);
					}else{
						PrintCenterText(param1, "Insufficent Credits!");
						PrintToChat(param1, "Insufficent Credits!");
						
						EmitSoundToClient(param1, SOUND_DENY);
					}
				}
			}
			
			new slotStatus = 2; //unequipped
			if(RTD_TrinketEquipped[param1][selectedSlot])
				slotStatus = 1;
			
			showTrinketSelectionMenu(param1, selectedSlot, slotStatus);
			//TrinketsLoadoutMenu(param1, 0);
		}
		
		case MenuAction_Cancel: {
			TrinketsLoadoutMenu(param1, 0);
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}


////////////////////////////////////////
// Destroy Trinket                    //
// User can destroy a trinket         //
////////////////////////////////////////
public Action:confirmDestroyTrinket(client, selectedSlot, slotStatus)
{
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_DestroyTrinkMenuHandler);
	
	new String:menuTitle[64];
	new String:displayIdent[64];
	
	Format(menuTitle, 64, "Destroy Trinket: %s %s ?", trinket_TierID[RTD_TrinketIndex[client][selectedSlot]][RTD_TrinketTier[client][selectedSlot]], trinket_Title[RTD_TrinketIndex[client][selectedSlot]]);
	SetMenuTitle(hCMenu, menuTitle);
	
	Format(displayIdent, 64, "%i", selectedSlot);
	AddMenuItem(hCMenu, displayIdent, "No! Wait! How'd I get here?!", ITEMDRAW_DEFAULT);
	
	Format(displayIdent, 64, "%i", selectedSlot);
	AddMenuItem(hCMenu, displayIdent, "Yes", ITEMDRAW_DEFAULT);
	
	SetMenuExitBackButton(hCMenu, true);
	DisplayMenuAtItem(hCMenu, client, 0, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public fn_DestroyTrinkMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{	
	switch (action) 
	{
		case MenuAction_Select: 
		{
			decl String:MenuInfo[64];
			decl String:chatMessage[200];
			
			new style;
			new selectedSlot;
			
			GetMenuItem(menu, param2, MenuInfo, sizeof(MenuInfo),style);
			
			selectedSlot = StringToInt(MenuInfo[0]);
			
			switch(param2)
			{
				//get outta here
				case 0:
				{
					Format(chatMessage, 64, "Phew! Close call (I'm an idiot sometimes)");
					PrintToChat(param1, chatMessage);
					PrintCenterText(param1, chatMessage);
				}
				
				//destroy trinket
				case 1:
				{
					Format(chatMessage, 64, "Destroyed Trinket: %s %s", trinket_TierID[RTD_TrinketIndex[param1][selectedSlot]][RTD_TrinketTier[param1][selectedSlot]], trinket_Title[RTD_TrinketIndex[param1][selectedSlot]]);
					PrintToChat(param1, chatMessage);
					PrintCenterText(param1, chatMessage);
					
					eraseTrinket(param1, selectedSlot);
					
					Format(RTD_TrinketUnique[param1][selectedSlot], 32, "");
				}
			}
			
			TrinketsLoadoutMenu(param1, 0);
		}
		
		case MenuAction_Cancel: {
			TrinketsLoadoutMenu(param1, 0);
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

////////////////////////////////////////
// Smelt Trinket                      //
// User can combine trinkets          //
////////////////////////////////////////
public Action:selectSecondTrinket(client, selectedSlot)
{
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_SelectSecondMenuHandler);
	
	new String:menuTitle[64];
	new String:displayInfo[128];
	new String:displayIdent[64];
	
	Format(menuTitle, 64, "Smelt %s %s with ?", trinket_TierID[RTD_TrinketIndex[client][selectedSlot]][RTD_TrinketTier[client][selectedSlot]], trinket_Title[RTD_TrinketIndex[client][selectedSlot]]);
	SetMenuTitle(hCMenu, menuTitle);
	
	//Trinkets
	for(new i = 0; i < 20; i++)
	{
		if(!StrEqual(RTD_TrinketUnique[client][i], "", false) && selectedSlot != i)
		{
			if(RTD_TrinketEquipped[client][i] == 1)
			{
				Format(displayInfo, 64, "[Equipped] (%s) %s", trinket_TierID[RTD_TrinketIndex[client][i]][RTD_TrinketTier[client][i]], trinket_Title[RTD_TrinketIndex[client][i]]);
				
				Format(displayIdent, 64, "%i:1", i); //1 = equipped
				
			}else{
				if(RTD_TrinketExpire[client][i] < GetTime())
				{
					Format(displayInfo, 64, "[Expired] (%s) %s", trinket_TierID[RTD_TrinketIndex[client][i]][RTD_TrinketTier[client][i]], trinket_Title[RTD_TrinketIndex[client][i]]);
					
					Format(displayIdent, 64, "%i:0", i); //0 = expired
				}else{
					Format(displayInfo, 64, "(%s) %s", trinket_TierID[RTD_TrinketIndex[client][i]][RTD_TrinketTier[client][i]], trinket_Title[RTD_TrinketIndex[client][i]]);
					
					Format(displayIdent, 64, "%i:2", i); //2 = unequipped
				}
			}
			
			AddMenuItem(hCMenu, displayIdent, displayInfo, ITEMDRAW_DEFAULT);
		}
	}
	
	smelting[client][0] = selectedSlot;
	smelting[client][1] = -1;
	
	SetMenuExitBackButton(hCMenu, true);
	DisplayMenuAtItem(hCMenu, client, 0, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public fn_SelectSecondMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{	
	switch (action) 
	{
		case MenuAction_Select: 
		{
			//param2 item
			//param1 client
			decl String:MenuInfo[64];
			new String:menuTriggers[4][16];
			
			new style;
			
			GetMenuItem(menu, param2, MenuInfo, sizeof(MenuInfo),style);
			ExplodeString(MenuInfo, ":", menuTriggers, 2, 3);
			
			smelting[param1][1] = StringToInt(menuTriggers[0]);
			
			confirmSmelt(param1);
		}
		
		case MenuAction_Cancel: {
			smelting[param1][0] = -1;
			smelting[param1][1] = -1;
			
			TrinketsLoadoutMenu(param1, 0);
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public bool:isValidToSmelt(client)
{
	//emergency scenario
	if(smelting[client][0] == -1 || smelting[client][1] == -1)
	{
		PrintCenterText(client, "Invalid trinkets selected!");
		TrinketsLoadoutMenu(client, 0);
		return false;
	}
	
	//make sure the trinkets are valid (should never be false)
	if(StrEqual(RTD_TrinketUnique[client][smelting[client][0]], "", false) || StrEqual(RTD_TrinketUnique[client][smelting[client][1]], "", false))
	{
		PrintCenterText(client, "Invalid trinkets selected!");
		TrinketsLoadoutMenu(client, 0);
		return false;
	}
	
	return true;
}

public confirmSmelt(client)
{
	if(!isValidToSmelt(client))
		return;
	
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_ConfirmSmeltMenuHandler);
	
	new String:menuTitle[64];
	
	new tempSlot1 = smelting[client][0];
	new tempSlot2 = smelting[client][1];
	
	Format(menuTitle, 64, "Smelt %s %s with %s %s", trinket_TierID[RTD_TrinketIndex[client][tempSlot1]][RTD_TrinketTier[client][tempSlot1]], trinket_Title[RTD_TrinketIndex[client][tempSlot1]], trinket_TierID[RTD_TrinketIndex[client][tempSlot2]][RTD_TrinketTier[client][tempSlot2]], trinket_Title[RTD_TrinketIndex[client][tempSlot2]]);
	SetMenuTitle(hCMenu, menuTitle);

	AddMenuItem(hCMenu, "0", "No", ITEMDRAW_DEFAULT);
	AddMenuItem(hCMenu, "1", "Yes", ITEMDRAW_DEFAULT);
	
	DisplayMenuAtItem(hCMenu, client, 0, MENU_TIME_FOREVER);
}
	
public fn_ConfirmSmeltMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{	
	switch (action) 
	{
		case MenuAction_Select: 
		{	
			switch(param2)
			{
				//get outta here
				case 0:
				{
				}
				
				//finally smelt the trinkets!!
				case 1:
				{
					smeltTrinkets(param1);
				}
			}
			
			TrinketsLoadoutMenu(param1, 0);
		}
		
		case MenuAction_Cancel: {
			TrinketsLoadoutMenu(param1, 0);
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}
public smeltTrinkets(client)
{
	if(!isValidToSmelt(client))
		return;
	
	new tempSlot1 = smelting[client][0];
	new tempSlot2 = smelting[client][1];
	decl String:chatMessage[200];
	
	new String:name[32];
	GetClientName(client, name, sizeof(name));
	
	//check to make there are trinkets loaded
	if(totalTrinkets < 1)
	{
		PrintCenterText(client, "Ooops, no trinkets found in the database! Smelt not possible!");
		PrintToChat(client, "Ooops, no trinkets found in the database! Smelt not possible!");
		
		smelting[client][0] = -1;
		smelting[client][1] = -1;
		return;
	}
	
	//player cannot roll the first smelted trinket
	new excludedTrinket = RTD_TrinketIndex[client][smelting[client][0]];
	
	//Let's pick a rarity
	new rarity = GetRandomInt(1, 100);
	new baseRarity;
	
	if(rarity <= 50)
	{
		baseRarity = 1;
	}
	
	if(rarity > 50 && rarity <= 80)
	{
		baseRarity = 2;
	}
	
	if(rarity > 80 && rarity <= 95)
	{
		baseRarity = 3;
	}
	
	if(rarity > 95)
	{
		baseRarity = 4;
	}
	
	if(countRarity(baseRarity) < 1)
	{
		PrintCenterText(client, "Ooops, no trinkets found in the shop matching rarity: %i! Smelting not possible!!", baseRarity);
		PrintToChat(client, "Ooops, no trinkets found in the shop matching rarity: %i! Smelting not possible!!", baseRarity);
		
		smelting[client][0] = -1;
		smelting[client][1] = -1;
		return;
	}
	
	Format(chatMessage, sizeof(chatMessage), "\x03%s\x04 smelted: (\x03%s\x04) \x01%s \x04with (\x03%s\x04) \x01%s", name, trinket_TierID[RTD_TrinketIndex[client][tempSlot1]][RTD_TrinketTier[client][tempSlot1]], trinket_Title[RTD_TrinketIndex[client][tempSlot1]], trinket_TierID[RTD_TrinketIndex[client][tempSlot2]][RTD_TrinketTier[client][tempSlot2]], trinket_Title[RTD_TrinketIndex[client][tempSlot2]]);
	PrintToChatSome(chatMessage, client);
	
	eraseTrinket(client, tempSlot1);
	eraseTrinket(client, tempSlot2);
	
	//Build an array for trinkets that match this rarity
	new Handle: rarityArray 	= CreateArray(1, countRarity);
	new totFound;
	new awardedTrinket;
	new rndPickFromArray;
	new variant;
	new rndNum;
	
	//put all the trinkets with the rarity into an array
	for(new i = 0; i < totalTrinkets; i++)
	{
		if(trinket_Rarity[i] == baseRarity)
		{
			if(excludedTrinket != i)
			{
				SetArrayCell(rarityArray, totFound, i, 0);
				totFound ++;
			}
		}
	}
	
	//pick a trinket
	rndPickFromArray = GetRandomInt(0, totFound-1);
	awardedTrinket = GetArrayCell(rarityArray, rndPickFromArray, 0);
	CloseHandle(rarityArray);
	
	//aright now let's pick the variant
	rndNum = GetRandomInt(1, trinket_TotalChance[awardedTrinket]);
	//PrintToChat(client, "Rolled: %i ", rndNum);
	
	//find out which tier our rndNum falls under
	for(new i = 0; i < trinket_Tiers[awardedTrinket]; i++)
	{
		if(rndNum <= trinketChanceBounds[awardedTrinket][i])
		{
			variant = i;
			break;
		}
	}
	
	new availableSlot = nextAvailableSlot(client);
	
	Format(RTD_TrinketUnique[client][availableSlot], 32, "%s", trinket_Unique[awardedTrinket]);
	RTD_TrinketTier[client][availableSlot] = variant;
	RTD_TrinketIndex[client][availableSlot] = trinket_Index[awardedTrinket];
	RTD_TrinketExpire[client][availableSlot] = GetTime() + 604800; // expire in 7 days
	RTD_TrinketEquipped[client][availableSlot] = 0;
	RTD_Trinket_DB_ID[client][availableSlot] = 0;
	
	Format(RTD_TrinketTitle[client][availableSlot], 32, "%s", trinket_Title[awardedTrinket]);
	
	Format(chatMessage, sizeof(chatMessage), "\x03%s\x04 obtained: (\x03%s\x04) \x01%s \x04Trinket", name, trinket_TierID[awardedTrinket][variant], trinket_Title[awardedTrinket]);
	
	
	PrintToChatSome(chatMessage, client);
	
	Format(chatMessage, sizeof(chatMessage), "Obtained: (%s) %s Trinket", trinket_TierID[awardedTrinket][variant], trinket_Title[awardedTrinket]);
	PrintCenterText(client, chatMessage);
	
	
	smelting[client][0] = -1;
	smelting[client][1] = -1;
	
	EmitSoundToClient(client, SOUND_OPEN_TRINKET);
}

public bool:isTrinketEquipped(client, trinketLookup)
{
	//Check to see if player has any trinkets
	for(new i = 0; i < totalTrinkets; i++)
	{
		if(!StrEqual(RTD_TrinketUnique[client][i], "", false))
		{
			if(RTD_TrinketIndex[client][i] == trinketLookup && RTD_TrinketEquipped[client][i] && RTD_TrinketExpire[client][i] < GetTime())
			{
				return true;
			}
		}
	}
	
	return false;
}

public equipActiveTrinket(client)
{	
	//Check to see if player has any trinkets
	for(new i = 0; i < 21; i++)
	{
		if(!StrEqual(RTD_TrinketUnique[client][i], "", false))
		{
			if(RTD_TrinketEquipped[client][i] == 1)
			{
				new trinketIndex = RTD_TrinketIndex[client][i];
				
				RTD_TrinketActive[client][trinketIndex] = 1;
				RTD_TrinketBonus[client][trinketIndex] = trinket_BonusAmount[trinketIndex][RTD_TrinketTier[client][i]];
				RTD_TrinketMisc[client][trinketIndex] = 0;
				RTD_TrinketLevel[client][trinketIndex] = RTD_TrinketTier[client][i];
				
				PrintHintText(client, "(%s) \%s Trinket currently equipped", trinket_TierID[trinketIndex][RTD_TrinketTier[client][i]], trinket_Title[trinketIndex]);
				//PrintToChat(client, "Trinket Bonus: %i", RTD_TrinketBonus[client][RTD_TrinketIndex[client][i]]);
			}
		}
	}
	
	if(RTD_TrinketActive[client][TRINKET_QUICKDRAW])
		ROFMult[client] = 1.0 + (float(RTD_TrinketBonus[client][TRINKET_QUICKDRAW])/100.0);
	
	if(RTD_TrinketActive[client][TRINKET_EXPLOSIVEDEATH])
	{
		RTD_TrinketMisc[client][TRINKET_EXPLOSIVEDEATH] = 0;
		
		if(IsPlayerAlive(client))
			SpawnAndAttachDynamite(client);
	}
}

public unequipTrinkets(client)
{
	if(RTD_TrinketActive[client][TRINKET_QUICKDRAW])
		ROFMult[client] = 0.0;
	
	//get ready to equip by unequipping all trinkets
	for(new k = 0; k < 21; k++)
	{
		RTD_TrinketEquipped[client][k] = 0;
	}
	
	for(new k = 0; k <= MAX_TRINKETS; k++)
	{
		RTD_TrinketActive[client][k] = 0;
		RTD_TrinketBonus[client][k] = 0;
		RTD_TrinketLevel[client][k] = 0;
		RTD_TrinketMisc[client][k] = 0;
	}
}

public checkTrinketsExpiration(client)
{
	if(!(IsClientInGame(client) && IsClientAuthorized(client)))
		return;
	
	new expiredTrinkets;
	
	//Check to see if player has any trinkets
	for(new i = 0; i < 21; i++)
	{
		if(!StrEqual(RTD_TrinketUnique[client][i], "", false))
		{
			if(RTD_TrinketExpire[client][i] < GetTime())
			{
				expiredTrinkets = 1;
				RTD_TrinketEquipped[client][i] = 0;
				RTD_TrinketExpire[client][i] = 0;
				
				RTD_TrinketActive[client][RTD_TrinketIndex[client][i]] = 0;
				RTD_TrinketBonus[client][RTD_TrinketIndex[client][i]] = 0;
				RTD_TrinketLevel[client][RTD_TrinketIndex[client][i]] = 0;
				RTD_TrinketMisc[client][RTD_TrinketIndex[client][i]] = 0;
			}
		}
	}
	
	if(expiredTrinkets == 1 && lastExpireNotification[client] < GetTime())
	{
		PrintToChat(client, "You have expired trinkets! Extend them through the Trinkets menu.");
		lastExpireNotification[client] = GetTime() + 600;
	}
	
}

public amountOfTrinketsHeld(client)
{
	new totTrinkets;
	
	//Check to see if player has any trinkets
	for(new i = 0; i < 50; i++)
	{
		if(!StrEqual(RTD_TrinketUnique[client][i], "", false))
			totTrinkets ++;
	}
	
	return totTrinkets;
}

public bool:trinketExpired(client, slot)
{
	if(RTD_TrinketExpire[client][slot] == 0)
		return true;
	
	if(RTD_TrinketExpire[client][slot] < GetTime())
		return true;
	
	return false;
}

public countRarity(match)
{
	new totFound;
	
	for(new i = 0; i < totalTrinkets; i++)
	{
		if(trinket_Rarity[i] == match)
			totFound ++;
	}
	
	return totFound;
}

public nextAvailableSlot(client)
{
	//Trinkets
	for(new i = 0; i < 20; i++)
	{	
		if(StrEqual(RTD_TrinketUnique[client][i], "", false))
			return i;
	}
	
	return -1;
}

GiveRandomTrinket(client, test)
{
	decl String:chatMessage[200];
	
	//check to make there are trinkets loaded
	if(totalTrinkets < 1)
	{
		PrintCenterText(client, "Ooops, no trinkets found in the shop! You have not been charged!!");
		PrintToChat(client, "Ooops, no trinkets found in the shop! You have not been charged!!");
		return;
	}
	
	if(amountOfTrinketsHeld(client) > 20)
	{
		PrintCenterText(client, "You cannot hold more than 20 trinkets!");
		PrintToChat(client, "You cannot hold more than 20 trinkets!");
		return;
	}
	
	//Let's pick a rarity
	new rarity = GetRandomInt(1, 100);
	new baseRarity;
	
	if(rarity <= 50)
	{
		baseRarity = 1;
	}
	
	if(rarity > 50 && rarity <= 80)
	{
		baseRarity = 2;
	}
	
	if(rarity > 80 && rarity <= 95)
	{
		baseRarity = 3;
	}
	
	if(rarity > 95)
	{
		baseRarity = 4;
	}
	
	if(countRarity(baseRarity) < 1)
	{
		PrintCenterText(client, "Ooops, no trinkets found in the shop matching rarity: %i! You have not been charged!!", baseRarity);
		PrintToChat(client, "Ooops, no trinkets found in the shop matching rarity: %i! You have not been charged!!", baseRarity);
		return;
	}
	
	//Build an array for trinkets that match this rarity
	new Handle: rarityArray 	= CreateArray(1, countRarity);
	new totFound;
	new awardedTrinket;
	new rndPickFromArray;
	new variant;
	new rndNum;
	
	//put all the trinkets with the rarity into an array
	for(new i = 0; i < totalTrinkets; i++)
	{
		if(trinket_Rarity[i] == baseRarity)
		{
			SetArrayCell(rarityArray, totFound, i, 0);
			totFound ++;
		}
	}
	
	//pick a trinket
	rndPickFromArray = GetRandomInt(0, totFound-1);
	awardedTrinket = GetArrayCell(rarityArray, rndPickFromArray, 0);
	CloseHandle(rarityArray);
	
	//aright now let's pick the variant
	rndNum = GetRandomInt(1, trinket_TotalChance[awardedTrinket]);
	//PrintToChat(client, "Rolled: %i ", rndNum);
	
	//find out which tier our rndNum falls under
	for(new i = 0; i < trinket_Tiers[awardedTrinket]; i++)
	{
		if(rndNum <= trinketChanceBounds[awardedTrinket][i])
		{
			variant = i;
			break;
		}
	}
	
	new String:name[32];
	GetClientName(client, name, sizeof(name));
	
	if(test == 0)
	{
		new availableSlot = nextAvailableSlot(client);
		
		Format(RTD_TrinketUnique[client][availableSlot], 32, "%s", trinket_Unique[awardedTrinket]);
		RTD_TrinketTier[client][availableSlot] = variant;
		RTD_TrinketIndex[client][availableSlot] = trinket_Index[awardedTrinket];
		RTD_TrinketExpire[client][availableSlot] = GetTime() + 604800; // expire in 7 days
		RTD_TrinketEquipped[client][availableSlot] = 0;
		RTD_Trinket_DB_ID[client][availableSlot] = 0;
		
		Format(RTD_TrinketTitle[client][availableSlot], 32, "%s", trinket_Title[awardedTrinket]);
		
		Format(chatMessage, sizeof(chatMessage), "\x03%s\x04 obtained: (\x03%s\x04) \x01%s \x04Trinket", name, trinket_TierID[awardedTrinket][variant], trinket_Title[awardedTrinket]);
		
	}else{
		Format(chatMessage, sizeof(chatMessage), "\x01\x04[TEST] \x03%s\x04 obtained: (\x03%s\x04)\x01 %s \x04Trinket", name, trinket_TierID[awardedTrinket][variant], trinket_Title[awardedTrinket]);
	}
	
	RTDCredits[client] -= rtd_trinketPrice;
	
	PrintToChatSome(chatMessage, client);
	
	Format(chatMessage, sizeof(chatMessage), "Obtained: (%s) %s Trinket", trinket_TierID[awardedTrinket][variant], trinket_Title[awardedTrinket]);
	PrintCenterText(client, chatMessage);
	EmitSoundToClient(client, SOUND_OPEN_TRINKET);
	
	//debug
	//PrintToChatAll("Trinket saved in slot: %i | Tier: %i", availableSlot, variant);
}

public SortAscend(x[], y[], array[][], Handle:data)
{
    if (x[1] > y[1])
        return -1;
	else if (x[1] < y[1])
		return 1;
    return 0;
}

public Action:Timer_DelayTrinketEquip(Handle:Timer, any:UserID)
{
	new client = GetClientOfUserId(UserID);
	
	if(client < 1)
		return Plugin_Stop;
	
	if(!IsClientAuthorized(client))
		return Plugin_Stop;
	
	equipActiveTrinket(client);
	
	return Plugin_Stop;
}

public eraseTrinket(client, slot)
{
	//used when player trades or destroys trinket
	
	if(RTD_Trinket_DB_ID[client][slot] != 0)
	{
		new String:buffer[255];
		Format(buffer, sizeof(buffer), "DELETE FROM `trinkets_v2` WHERE ID = '%i'", RTD_Trinket_DB_ID[client][slot]);
		SQL_TQuery(db, SQLErrorCheckCallback, buffer);
		
		//LogError("%s", buffer);
	}
	
	
	RTD_TrinketActive[client][RTD_TrinketIndex[client][slot]] = 0;
	RTD_TrinketBonus[client][RTD_TrinketIndex[client][slot]] = 0;
	
	Format(RTD_TrinketUnique[client][slot], 32, "");
	Format(RTD_TrinketTitle[client][slot], 32, "");
	
	RTD_TrinketEquipped[client][slot] = 0;
	RTD_Trinket_DB_ID[client][slot] = 0;
	
	RTD_TrinketTier[client][slot] = 0;
	RTD_TrinketExpire[client][slot] = 0;
	RTD_TrinketIndex[client][slot] = 0;
}