#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <rtd_rollinfo>

#define maxPerks		100
#define maxAttributes	30

//Misc. SQL reset code
//UPDATE `Player` SET `TALENTPOINTS` = '-1'
//
//------------------------------------------
new totalShopDicePerks = 0;
new dicePerk_Index[maxPerks];
new String:dicePerk_Unique[maxPerks][32];
new String:RTD_Perks_Unique[cMaxClients][maxPerks][32];

new dicePerk_Levels[maxPerks];
new dicePerk_Cost[maxPerks][6];
new dicePerk_Value[maxPerks][6];
new String:dicePerk_Msg[maxPerks][128];
new String:dicePerk_Complete[maxPerks][128];
new RTD_Perks[cMaxClients][maxPerks];
new RTD_PerksInfo[cMaxClients][maxPerks][3];
new RTD_PerksLevel[cMaxClients][maxPerks];
new dicePerk_Enabled[maxPerks];
new dicePerk_Reimburse[maxPerks];

//Event only can only perks can only be purchased during certain events
//They are not purchasable once they are Disabled through dicePerk_Enabled
//Users have a seperate option to reset Event Only perks
new dicePerk_EventOnly[maxPerks];
//------------------------------------------

new totalDicePerks = 0;



new dicePerk_need[maxPerks];
new String:dicePerk_title[maxPerks][64];
new String:dicePerk_info[maxPerks][128];

//[0] = attribute Identifier
//[1] = Value
new dicePerk_attributes[maxPerks][2];

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ATTRIBUTES:
//
//NOTE: These cannot change! You can add to them but not delete previous ones!!!
//
//		0. "seconds_reduction"		"Time reduction per point"
//		1. "added_chance" 			"Chance for good roll increase. 5 = 5% base increase"
//		2. "fire_damage"			"Chance for fire damage. 5 = 5% base increase"
//		3. "small_health_drop"		"Chance for a small health drop on killing enemy. 25 = 25% base increase"
//		4. "round_end_immunity" 	"Makes player immune on round end: 0/1"
//		5. "reset_rtd_timer"		"Chance to reset the RTD timer on death. 50 = 50%"
//		6. "extra_rtd_time"			"Adds more time to Good rolls. 1s"
//		7. "extra_presents_creds"	"..."
//		8. "extra_presents_armor"	"..."
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public Action:SetupPerksMenu(client, startAtPage)
{
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_PerksMenuHandler);
	
	SetMenuTitle(hCMenu,"Dice Perks Shopping Menu | Talent Points: %i",talentPoints[client]);
	
	addPerksOnClient(hCMenu, client);
	
	DisplayMenuAtItem(hCMenu, client, startAtPage, MENU_TIME_FOREVER);
	
	if(startAtPage == 0)
		EmitSoundToClient(client, SOUND_SHOP);
	
	return Plugin_Handled;
}

public addPerksOnClient(Handle:hCMenu, client)
{
	//////////////////////////////////////////////////////////////////////
	//About the Item's name:                                            //
	//AddMenuItem(hCMenu,"Cost:Function:Value                           //
	//////////////////////////////////////////////////////////////////////
	
	new String:info[128];
	new String:mMsg[255];
	new String:comp[64];
	new String:rnkMsg[64];
	new String:replace[32];
	new String:modMsg[128];
	new rankValuesAdded;
	
	new String:resetPerksMsg[128];
	new String:resetEventMsg[128];
	
	Format(resetPerksMsg, sizeof(resetPerksMsg), "[%i Credits] Reset Dice Perks!!", reset_PerksCost);
	Format(resetEventMsg, sizeof(resetEventMsg), "[%i Credits] Reset Event Perks!!", reset_EventPerksCost);
	
	AddMenuItem(hCMenu, "0:reset:0", resetPerksMsg, ITEMDRAW_DEFAULT);
	AddMenuItem(hCMenu, "0:resetEvent:0", resetEventMsg, userHasEventPerks(client)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	
	for(new i = 0; i < totalShopDicePerks; i++)
	{
		//Bypass if not enabled and it is not an event perk
		if(dicePerk_Enabled[i] != 1 && dicePerk_EventOnly[i] != 1)
			continue;
		
		Format(info, sizeof(info), "%i:%s:%i", dicePerk_Cost[i][RTD_PerksLevel[client][dicePerk_Index[i]]], dicePerk_Unique[i], dicePerk_Value[i][RTD_PerksLevel[client][dicePerk_Index[i]]]);
		
		if(RTD_PerksLevel[client][dicePerk_Index[i]] >= dicePerk_Levels[i])
		{
			Format(comp, sizeof(comp), "[Completed]");
		}
		else if(RTDdice[client] < 200)
		{
			Format(comp, sizeof(comp), "[Talent Locked]");
		}
		else if(dicePerk_Enabled[i] != 1 && dicePerk_EventOnly[i] == 1)
		{
			Format(comp, sizeof(comp), "[Expired]");
		}
		else
		{
			Format(comp, sizeof(comp), "[%i T.P.]",dicePerk_Cost[i][RTD_PerksLevel[client][dicePerk_Index[i]]]);
		}
		
		Format(rnkMsg, sizeof(rnkMsg), "(%i/%i)", RTD_PerksLevel[client][dicePerk_Index[i]]+1, dicePerk_Levels[i]);
		
		
		if(RTD_PerksLevel[client][dicePerk_Index[i]] >= dicePerk_Levels[i])
		{
			//The user has completed this Talent Tree
			Format(modMsg, sizeof(modMsg), "%s", dicePerk_Complete[i]);
			
			rankValuesAdded = 0;
			
			for(new k = 0; k < dicePerk_Levels[i]; k++)
			{
				rankValuesAdded += dicePerk_Value[i][k];
			}
			
			Format(replace, sizeof(replace), "%i", rankValuesAdded);
			ReplaceString(modMsg, sizeof(modMsg), "**", replace, true);
			
			Format(replace, sizeof(replace), "%i", RTD_Perks[client][dicePerk_Index[i]]);
			ReplaceString(modMsg, sizeof(modMsg), "@@", replace, true);
			
			Format(replace, sizeof(replace), "%i", (RTD_Perks[client][dicePerk_Index[i]] + dicePerk_Value[i][RTD_PerksLevel[client][dicePerk_Index[i]]]));
			ReplaceString(modMsg, sizeof(modMsg), "++", replace, true);
			
			Format(mMsg, sizeof(mMsg), "%s (%i of %i) %s", comp, dicePerk_Levels[i], dicePerk_Levels[i], modMsg);
			AddMenuItem(hCMenu, info, mMsg, ITEMDRAW_DISABLED);
		}else{
			//The User can still purchase ranks from this Talent Tree
			Format(modMsg, sizeof(modMsg), "%s", dicePerk_Msg[i]);
			
			//-----------------------------------------------
			rankValuesAdded = 0;
			
			for(new k = 0; k <= RTD_PerksLevel[client][dicePerk_Index[i]]; k++)
			{
				rankValuesAdded += dicePerk_Value[i][k];
			}
			
			Format(replace, sizeof(replace), "%i", rankValuesAdded);
			ReplaceString(modMsg, sizeof(modMsg), "**", replace, true);
			//-----------------------------------------------
			
			Format(replace, sizeof(replace), "%i", RTD_Perks[client][dicePerk_Index[i]]);
			ReplaceString(modMsg, sizeof(modMsg), "@@", replace, true);
			
			Format(replace, sizeof(replace), "+%i\%%", dicePerk_Value[i][RTD_PerksLevel[client][dicePerk_Index[i]]]);
			ReplaceString(modMsg, sizeof(modMsg), "$$", replace, true);
			
			Format(replace, sizeof(replace), "%i", (RTD_Perks[client][dicePerk_Index[i]] + dicePerk_Value[i][RTD_PerksLevel[client][dicePerk_Index[i]]]));
			ReplaceString(modMsg, sizeof(modMsg), "++", replace, true);
			
			Format(mMsg, sizeof(mMsg), "%s %s %s", comp, rnkMsg, modMsg);
			
			if(dicePerk_Enabled[i] != 1)
			{
				if(dicePerk_EventOnly[i] == 1)
				{
					//Show the roll but disable it because this is a disabled event perk
					//meaning that the event already passed
					AddMenuItem(hCMenu, info, mMsg, ITEMDRAW_DISABLED);
				}
			}else{
				AddMenuItem(hCMenu, info, mMsg, talentPoints[client]<dicePerk_Cost[i][RTD_PerksLevel[client][dicePerk_Index[i]]]?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			}
		}
		
	}
}

public fn_PerksMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{	
	switch (action) 
	{
		case MenuAction_Select: 
		{	
			decl String:MenuInfo[64];
			new String:menuTriggers[4][128];
			new bool:allowPurchase = false;
			decl value;
			decl cost;
			
			new style;
			GetMenuItem(menu, param2, MenuInfo, sizeof(MenuInfo),style);
			ExplodeString(MenuInfo, ":", menuTriggers, 3, 15);
			
			cost = StringToInt(menuTriggers[0]);
			value = StringToInt(menuTriggers[2]);
			
			//Determine if the player is allowed to purchase the selected item
			if(talentPoints[param1] >= cost)
			{
				if(style != ITEMDRAW_DISABLED)
				{
					talentPoints[param1] -= cost;
					allowPurchase = true;
					
				}else{
					
					PrintCenterText(param1, "Requested item is DISABLED!");
					PrintToChat(param1, "Requested item is DISABLED!");
					
					EmitSoundToClient(param1, SOUND_DENY);
				}
			}else{
				PrintCenterText(param1, "You do not have enough TALENT POINTS");
				PrintToChat(param1, "You do have enough TALENT POINTS!");
			}
			
			//Massive If...then statement
			if(allowPurchase)
			{
				EmitSoundToClient(param1, SOUND_BOUGHTSOMETHING);
				
				//new String:message[128];
				new String:message02[128];
				new String:name[32];
				GetClientName(param1, name, sizeof(name));
				
				if(cost == 1)
				{
					Format(message02, sizeof(message02), "TALENT POINT");
				}else{
					Format(message02, sizeof(message02), "TALENT POINTS");
				}
				
				if(StrEqual(menuTriggers[1], "reset", false))
				{
					if(RTDCredits[param1] >= reset_PerksCost)
					{
						ConfirmDicePerksReset(param1);
					}else{
						PrintCenterText(param1, "Not enough Credits!");
					}
				}
				else if(StrEqual(menuTriggers[1], "resetEvent", false))
				{
					if(RTDCredits[param1] >= reset_EventPerksCost)
					{
						ConfirmEventPerksReset(param1);
					}else{
						PrintCenterText(param1, "Not enough Credits!");
					}
				}
				else if(StrContains(menuTriggers[1], "a00", false) != -1)
				{
					RTD_Perks[param1][0] += value;
					RTD_PerksLevel[param1][0] ++;
					
					PrintToChat(param1, "You now have: %i Seconds Reduction/Point", RTD_Perks[param1][0] );
				}
				else if(StrContains(menuTriggers[1], "a01", false) != -1)
				{
					RTD_Perks[param1][1] += value;
					RTD_PerksLevel[param1][1] ++;
					
					PrintToChat(param1, "You now have: %i\%% Chance of Good Roll", RoundFloat((GetConVarFloat(c_Chance) * 100.0)) + RTD_Perks[param1][1] + RTD_Perks[param1][21]);
				}
				else if(StrContains(menuTriggers[1], "a02", false) != -1)
				{
					RTD_Perks[param1][2] += value;
					RTD_PerksLevel[param1][2] ++;
					
					PrintToChat(param1, "You now have: %i\%% Chance of Fire Damage", RTD_Perks[param1][2]);
				}
				else if(StrContains(menuTriggers[1], "a03", false) != -1)
				{
					RTD_Perks[param1][3] += value;
					RTD_PerksLevel[param1][3] ++;
					
					PrintToChat(param1, "You now have: %i\%% Chance of Health drop on kill", RTD_Perks[param1][3]);
				}
				else if(StrContains(menuTriggers[1], "a04", false) != -1)
				{
					RTD_Perks[param1][4] += value;
					RTD_PerksLevel[param1][4] ++;
				}
				else if(StrContains(menuTriggers[1], "a06", false) != -1)
				{	
					RTD_Perks[param1][6] += value;
					RTD_PerksLevel[param1][6] ++;
					
					PrintToChat(param1, "Good Rolls now last: %i secs", RTD_Perks[param1][6] + GetConVarInt(c_Duration));
				}
				else if(StrContains(menuTriggers[1], "a07", false) != -1)
				{
					RTD_Perks[param1][7] += value;
					RTD_PerksLevel[param1][7] ++;
					
					PrintToChat(param1, "You now: Receive up to %i Credits from Presents", RTD_Perks[param1][7]);
				}
				else if(StrContains(menuTriggers[1], "a08", false) != -1)
				{
					RTD_Perks[param1][8] += value;
					RTD_PerksLevel[param1][8] ++;
					
					PrintToChat(param1, "You now: Receive up to %i Armor from Presents", RTD_Perks[param1][8]);
				}
				else if(StrContains(menuTriggers[1], "a09", false) != -1)
				{
					RTD_Perks[param1][9] += value;
					RTD_PerksLevel[param1][9] ++;
					
					PrintToChat(param1, "You now: Take %i\%% less dmg from TOXIC ", RTD_Perks[param1][9]);
				}
				else if(StrContains(menuTriggers[1], "a10", false) != -1)
				{
					RTD_Perks[param1][10] += value;
					RTD_PerksLevel[param1][10] ++;
					
					PrintToChat(param1, "You now: Resist SlowCubes by %i\%%", RTD_Perks[param1][10]);
				}
				else if(StrContains(menuTriggers[1], "a11", false) != -1)
				{
					RTD_Perks[param1][11] += value;
					RTD_PerksLevel[param1][11] ++;
					
					PrintToChat(param1, "Backpacks now: add %i items per point", RTD_Perks[param1][11]);
				}
				else if(StrContains(menuTriggers[1], "a12", false) != -1)
				{
					RTD_Perks[param1][12] += value;
					RTD_PerksLevel[param1][12] ++;
					
					PrintToChat(param1, "Ghosts now: Scare you for only %i seconds", RTD_Perks[param1][12]);
				}
				else if(StrContains(menuTriggers[1], "a13", false) != -1)
				{
					RTD_Perks[param1][13] += value;
					RTD_PerksLevel[param1][13] ++;
					
					PrintToChat(param1, "Amplifiers: Deal Mini Crit dmg, but don't take Mini Crit dmg");
				}
				else if(StrContains(menuTriggers[1], "a14", false) != -1)
				{
					RTD_Perks[param1][14] += value;
					RTD_PerksLevel[param1][14] ++;
					
					PrintToChat(param1, "Your crap now makes enemies bleed!");
				}
				else if(StrContains(menuTriggers[1], "a15", false) != -1)
				{
					RTD_Perks[param1][15] += value;
					RTD_PerksLevel[param1][15] ++;
					
					PrintToChat(param1, "Your Spiders now have %i Max Health", RTD_Perks[param1][15] + 500);
				}
				else if(StrContains(menuTriggers[1], "a16", false) != -1)
				{
					RTD_Perks[param1][16] += value;
					RTD_PerksLevel[param1][16] ++;
					
					PrintToChat(param1, "Your Chance to Mine Dice is now %i%", RTD_Perks[param1][16]);
				}
				else if(StrContains(menuTriggers[1], "a17", false) != -1)
				{
					RTD_Perks[param1][17] += value;
					RTD_PerksLevel[param1][17] ++;
					
					PrintToChat(param1, "Your Cows are now healthier and stronger!");
				}
				else if(StrContains(menuTriggers[1], "a18", false) != -1)
				{
					RTD_Perks[param1][18] += value;
					RTD_PerksLevel[param1][18] ++;
					
					PrintToChat(param1, "You're now immune from Melee Mode!");
				}
				else if(StrContains(menuTriggers[1], "a19", false) != -1)
				{
					RTD_Perks[param1][19] += value;
					RTD_PerksLevel[param1][19] ++;
					
					PrintToChat(param1, "Monkies have taught you well! You can now pickup and throw Crap!");
				}
				else if(StrContains(menuTriggers[1], "a20", false) != -1)
				{
					RTD_Perks[param1][20] += value;
					RTD_PerksLevel[param1][20] ++;
					
					PrintToChat(param1, "Enemies have a chance to freeze on your Ice Patches!");
				}
				else if(StrContains(menuTriggers[1], "z01", false) != -1)
				{
					RTD_Perks[param1][21] += value;
					RTD_PerksLevel[param1][21] ++;
					
					PrintToChat(param1, "You now have: %i\%% Chance of Good Roll", RoundFloat((GetConVarFloat(c_Chance) * 100.0)) + RTD_Perks[param1][1] + RTD_Perks[param1][21] );
				}
				else if(StrContains(menuTriggers[1], "z02", false) != -1)
				{
					RTD_Perks[param1][22] += value;
					RTD_PerksLevel[param1][22] ++;
					
					PrintToChat(param1, "No more bad presents for you!");
				}
				else if (StrContains(menuTriggers[1], "z03", false) != -1)
				{
					RTD_Perks[param1][23] += value;
					RTD_PerksLevel[param1][23] ++;
					
					PrintToChat(param1, "The Backpack Blizzard now extinguishes you every %d seconds!", RTD_Perks[param1][23]);
				}
				else if (StrContains(menuTriggers[1], "a21", false) != -1)
				{
					RTD_Perks[param1][24] += value;
					RTD_PerksLevel[param1][24] ++;
					
					PrintToChat(param1, "Redbull now gives you +%i\%% Speed Boost", RTD_Perks[param1][24]);
				}
				else if (StrContains(menuTriggers[1], "a22", false) != -1)
				{
					RTD_Perks[param1][25] += value;
					RTD_PerksLevel[param1][25] ++;
					
					PrintToChat(param1, "You can now re-spec class immunity every %.1f minutes with \"!respec\".", RTD_Perks[param1][25] / 60.0); //"
				}
				else if (StrContains(menuTriggers[1], "a24", false) != -1)
				{
					RTD_Perks[param1][27] += value;
					RTD_PerksLevel[param1][27] ++;
					
					switch (RTD_PerksLevel[param1][27]) {
						case 1:
							PrintToChat(param1, "You now regenerate metal faster when you roll or buy Metal Man!");
						case 2:
							PrintToChat(param1, "Your enemies will bow to your \x03metal bending madness\0x1!");
						case 3:
							PrintToChat(param1, "How about a bigger budget of 250 to go with that kit?");
						case 4:
							PrintToChat(param1, "Congratulations! You are probably the most OP engineer on the server!");
					}						
				}
				else if (StrContains(menuTriggers[1], "a25", false) != -1)
				{
					RTD_Perks[param1][28] += value;
					RTD_PerksLevel[param1][28] ++;
					
					PrintToChat(param1, "Your Punching Dummies now have a chance to stun enemies!");					
				}
				else if (StrContains(menuTriggers[1], "a26", false) != -1)
				{
					RTD_Perks[param1][29] += value;
					RTD_PerksLevel[param1][29] ++;
					
					PrintToChat(param1, "As a medic with ubercharger you now gain 2x Uber when healing others!");					
				}
				else if (StrContains(menuTriggers[1], "a27", false) != -1)
				{
					RTD_Perks[param1][30] += value;
					RTD_PerksLevel[param1][30] ++;
					
					if (RTD_PerksLevel[param1][30] == 1)
						PrintToChat(param1, "Your Insta-Porters now come packaged with more wire and uses!");
					else
						PrintToChat(param1, "Your Insta-Porters now buff players with 75 armor on use.");
				}
				else if (StrContains(menuTriggers[1], "a28", false) != -1)
				{
					RTD_Perks[param1][31] += value;
					RTD_PerksLevel[param1][31] ++;
					
					PrintToChat(param1, "Groovitrons make your enemies jump straight up in the air now!", RTD_Perks[param1][30]);			
				}
				else if (StrContains(menuTriggers[1], "a29", false) != -1)
				{
					RTD_Perks[param1][32] += value;
					RTD_PerksLevel[param1][32] ++;
					
					PrintToChat(param1, "Your supply drop will now dispense to teammates only!");			
				}
				else if (StrContains(menuTriggers[1], "a30", false) != -1)
				{
					RTD_Perks[param1][33] += value;
					RTD_PerksLevel[param1][33] ++;
					
					PrintToChat(param1, "Your Snorlax now has 2500 HP");			
				}
				else if (StrContains(menuTriggers[1], "a31", false) != -1)
				{
					RTD_Perks[param1][34] += value;
					RTD_PerksLevel[param1][34] ++;
					
					PrintToChat(param1, "Your Ghosts now move faster!");			
				}
				else if (StrContains(menuTriggers[1], "a32", false) != -1)
				{
					RTD_Perks[param1][35] += value;
					RTD_PerksLevel[param1][35] ++;
					
					PrintToChat(param1, "Your Ghosts now live 20s longer");			
				}
				else if (StrContains(menuTriggers[1], "a33", false) != -1)
				{
					RTD_Perks[param1][36] += value;
					RTD_PerksLevel[param1][36] ++;
					
					PrintToChat(param1, "You can now disarm enemy bombs");			
				}
				else if (StrContains(menuTriggers[1], "a34", false) != -1)
				{
					RTD_Perks[param1][37] += value;
					RTD_PerksLevel[param1][37] ++;
					
					PrintToChat(param1, "Backpack Blizzard 20s recharge");			
				}
				else if (StrContains(menuTriggers[1], "a35", false) != -1)
				{
					RTD_Perks[param1][38] += value;
					RTD_PerksLevel[param1][38] ++;
					
					PrintToChat(param1, "Backpack Blizzard: 2s Freeze Time");			
				}
				else if (StrContains(menuTriggers[1], "a36", false) != -1)
				{
					RTD_Perks[param1][39] += value;
					RTD_PerksLevel[param1][39] ++;
					
					PrintToChat(param1, "Air Intake now pulls from 700 units");			
				}
				else if (StrContains(menuTriggers[1], "a37", false) != -1)
				{
					RTD_Perks[param1][40] += value;
					RTD_PerksLevel[param1][40] ++;
					
					PrintToChat(param1, "Air Intake pull is now stronger!");			
				}
				else if (StrContains(menuTriggers[1], "a38", false) != -1)
				{
					RTD_Perks[param1][41] += value;
					RTD_PerksLevel[param1][41] ++;
					
					PrintToChat(param1, "Yoshi: Eat time reduced to 2s (default 4s)");			
				}
				else if (StrContains(menuTriggers[1], "a39", false) != -1)
				{
					RTD_Perks[param1][42] += value;
					RTD_PerksLevel[param1][42] ++;
					
					PrintToChat(param1, "Horsemann: 40s Recharge Scare time (default 60s)");			
				}
				else if (StrContains(menuTriggers[1], "a40", false) != -1)
				{
					RTD_Perks[param1][43] += value;
					RTD_PerksLevel[param1][43] ++;
					
					PrintToChat(param1, "Horsemann: Scares last 9s (default 5s)");			
				}
				else if (StrContains(menuTriggers[1], "a41", false) != -1)
				{
					RTD_Perks[param1][44] += value;
					RTD_PerksLevel[param1][44] ++;
					
					PrintToChat(param1, "Cow: No speed penalty while carrying a Cow");			
				}
				else if (StrContains(menuTriggers[1], "a42", false) != -1)
				{
					RTD_Perks[param1][45] += value;
					RTD_PerksLevel[param1][45] ++;
					
					PrintToChat(param1, "Mediray: Faster Mediray Boost, 40s (60s default)");			
				}
				else if (StrContains(menuTriggers[1], "a43", false) != -1)
				{
					RTD_Perks[param1][46] += value;
					RTD_PerksLevel[param1][46] ++;
					
					PrintToChat(param1, "Mediray: Larger heal radius, 400 (default: 300)");			
				}
				else if (StrContains(menuTriggers[1], "a44", false) != -1)
				{
					RTD_Perks[param1][47] += value;
					RTD_PerksLevel[param1][47] ++;
					
					PrintToChat(param1, "Mediray: Faster heal, 40 HP/s (default: 30HP/s)");			
				}
				else if (StrContains(menuTriggers[1], "a45", false) != -1)
				{
					RTD_Perks[param1][48] += value;
					RTD_PerksLevel[param1][48] ++;
					
					PrintToChat(param1, "Stonewall: No negative effects");			
				}
				else if (StrContains(menuTriggers[1], "a46", false) != -1)
				{
					RTD_Perks[param1][49] += value;
					RTD_PerksLevel[param1][49] ++;
					
					PrintToChat(param1, "Stonewall: +5% Damage resistance");			
				}
				else if (StrContains(menuTriggers[1], "a47", false) != -1)
				{
					RTD_Perks[param1][50] += value;
					RTD_PerksLevel[param1][50] ++;
					
					PrintToChat(param1, "Building Shield: Block 75% damage");			
				}
				else if (StrContains(menuTriggers[1], "a48", false) != -1)
				{
					RTD_Perks[param1][51] += value;
					RTD_PerksLevel[param1][51] ++;
					
					switch(RTD_PerksLevel[param1][51])
					{
						case 1:
						{
							PrintToChat(param1, "Sentry Wrench yields: Level 1 Sentry Gun");
						}
						
						case 2:
						{
							PrintToChat(param1, "Sentry Wrench yields: Level 2 Sentry Gun");
						}
						
						case 3:
						{
							PrintToChat(param1, "Sentry Wrench yields: Level 3 Sentry Gun");
						}
					}			
				}
				else if (StrContains(menuTriggers[1], "a49", false) != -1)
				{
					RTD_Perks[param1][52] += value;
					RTD_PerksLevel[param1][52] ++;
					
					PrintToChat(param1, "Jarate Shower (Piss of the Gods): 50% radius increase");			
				}
				else if(StrContains(menuTriggers[1], "a50", false) != -1)
				{
					RTD_Perks[param1][53] += value;
					RTD_PerksLevel[param1][53] ++;
					
					PrintToChat(param1, "You now have: 10% Chance of Timer reset on death");
				}
				else if(StrContains(menuTriggers[1], "a51", false) != -1)
				{
					RTD_Perks[param1][54] += value;
					RTD_PerksLevel[param1][54] ++;
					
					PrintToChat(param1, "Your traps now cause enemies to bleed");
				}
				else if(StrContains(menuTriggers[1], "a52", false) != -1)
				{
					RTD_Perks[param1][55] += value;
					RTD_PerksLevel[param1][55] ++;
					
					PrintToChat(param1, "Angelic Dispenser heals +150 HP");
				}
				else if(StrContains(menuTriggers[1], "a53", false) != -1)
				{
					RTD_Perks[param1][56] += value;
					RTD_PerksLevel[param1][56] ++;
					
					PrintToChat(param1, "Angelic Dispenser cooldown period: 5s");
				}
				else if(StrContains(menuTriggers[1], "a54", false) != -1)
				{
					RTD_Perks[param1][57] += value;
					RTD_PerksLevel[param1][57] ++;
					
					PrintToChat(param1, "Bear Traps now latch onto enemies!");
				}
				else if(StrContains(menuTriggers[1], "a55", false) != -1)
				{
					RTD_Perks[param1][58] += value;
					RTD_PerksLevel[param1][58] ++;
					
					PrintToChat(param1, "Larger Strength Drain Aura!");
				}
				else
				{
					talentPoints[param1] += cost;
					PrintToChat(param1, "ERROR! Could not find item in shop! TP reimbursed!");
					
				}
			}
			
			if(StrContains(menuTriggers[1], "reset", false) == -1)
				SetupPerksMenu(param1, GetMenuSelectionPosition());
		}
		
		
		case MenuAction_Cancel: {
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
	
	StopSound(param1, SNDCHAN_AUTO, SOUND_SHOP);
}

Load_DicePerks()
{	
	// Parse the objects list key values text to acquire all the possible
	// wearable items.
	new Handle:kvItemList = CreateKeyValues("RTD_Dice_Perks");
	new String:strLocation[256];
	new String:strLine[256];
	
	totalDicePerks = 0;
	
	// Load the key files.
	BuildPath(Path_SM, strLocation, 256, "configs/rtd/dice_perks.cfg");
	FileToKeyValues(kvItemList, strLocation);
	
	// Check if the parsed values are correct
	if (!KvGotoFirstSubKey(kvItemList)) 
	{ 
		LogToFile(logPath,"Error, can't read file containing RTD_Dice_Perks: %s", strLocation);
		return; 
	}
	
	// Iterate through all keys.
	do
	{
		//KvGotoFirstSubKey(kvItemList);
		
		if(totalDicePerks <= maxPerks)
		{
			KvGetString(kvItemList, "need",		strLine, sizeof(strLine));
			dicePerk_need[totalDicePerks]   = StringToInt(strLine);
			
			KvGetString(kvItemList, "title",	strLine, sizeof(strLine));
			Format(dicePerk_title[totalDicePerks], 128, "%s", strLine);
			
			KvGetString(kvItemList, "info",		strLine, sizeof(strLine));
			Format(dicePerk_info[totalDicePerks], 128, "%s", strLine);
			
			//Retrieve attributes----
			new String:strAttributes[20][16]; //clear out our string <--thats why its here
			KvGetString(kvItemList, "seconds_reduction",	strAttributes[0], 16);
			KvGetString(kvItemList, "added_chance", 		strAttributes[1], 16);
			KvGetString(kvItemList, "fire_damage",			strAttributes[2], 16);
			KvGetString(kvItemList, "small_health_drop",	strAttributes[3], 16);
			KvGetString(kvItemList, "round_end_immunity",	strAttributes[4], 16);
			KvGetString(kvItemList, "reset_rtd_timer",		strAttributes[5], 16);
			KvGetString(kvItemList, "extra_rtd_time",		strAttributes[6], 16);
			KvGetString(kvItemList, "extra_presents_creds",	strAttributes[7], 16);
			KvGetString(kvItemList, "extra_presents_armor",	strAttributes[8], 16);
			
			//only one attribute/perk
			for(new i = 0; i <= maxAttributes; i++) 
			{
				if(!StrEqual(strAttributes[i], ""))
				{
					dicePerk_attributes[totalDicePerks][0] = i;
					dicePerk_attributes[totalDicePerks][1] = StringToInt(strAttributes[i]);	
					break;
				}
			}
			
		}
		//LogToFile(logPath,"Perk Found #%i: [%i], %s, %s | Attribute #%i = %i",totalDicePerks, dicePerk_need[totalDicePerks],dicePerk_title[totalDicePerks],dicePerk_info[totalDicePerks],dicePerk_attributes[totalDicePerks][0],dicePerk_attributes[totalDicePerks][1]);
		totalDicePerks ++;
	}
	while (KvGotoNextKey(kvItemList));
	
	if(totalDicePerks > maxPerks)
		totalDicePerks = maxPerks;
	
	//LogToFile(logPath,"Total Perks Found: %i",totalDicePerks);
	CloseHandle(kvItemList);    
}

Load_DicePerks_ShopMenu()
{	
	// Parse the objects list key values text to acquire all the Shop Perks
	new Handle:kvItemList = CreateKeyValues("RTD_Dice_Perks_Shop");
	new String:strLocation[256];
	new String:strLine[256];
	
	totalShopDicePerks = 0;
	
	// Load the key files.
	BuildPath(Path_SM, strLocation, 256, "configs/rtd/dice_perks_shop.cfg");
	FileToKeyValues(kvItemList, strLocation);
	
	// Check if the parsed values are correct
	if (!KvGotoFirstSubKey(kvItemList)) 
	{ 
		LogToFile(logPath,"Error, can't read file containing RTD_Dice_Perks_Shop: %s", strLocation);
		return; 
	}
	
	// Iterate through all keys.
	do
	{
		if(totalShopDicePerks <= maxPerks)
		{
			KvGetString(kvItemList, "index",		strLine, sizeof(strLine));
			dicePerk_Index[totalShopDicePerks]   = StringToInt(strLine);
			
			KvGetString(kvItemList, "unique",	strLine, sizeof(strLine));
			Format(dicePerk_Unique[totalShopDicePerks], 128, "%s", strLine);
			//PrintToServer("Loaded Unique: %s", dicePerk_Unique[totalShopDicePerks]);
			
			KvGetString(kvItemList, "eventonly",		strLine, sizeof(strLine));
			dicePerk_EventOnly[totalShopDicePerks]   = StringToInt(strLine);
			//PrintToChatAll("Index:%i Unique:%s EventOnly:%i", totalShopDicePerks, dicePerk_Unique[totalShopDicePerks], dicePerk_EventOnly[totalShopDicePerks] );
			
			KvGetString(kvItemList, "levels",		strLine, sizeof(strLine));
			dicePerk_Levels[totalShopDicePerks]   = StringToInt(strLine);
			
			KvGetString(kvItemList, "cost",		strLine, sizeof(strLine));
			new String:partsDicePerk[6][32];
			ExplodeString(strLine, ",", partsDicePerk, 6, 10);
			for(new i = 0; i < dicePerk_Levels[totalShopDicePerks]; i++)
			{
				dicePerk_Cost[totalShopDicePerks][i]	= StringToInt(partsDicePerk[i]);
			}
			
			KvGetString(kvItemList, "value",		strLine, sizeof(strLine));
			
			ExplodeString(strLine, ",", partsDicePerk, 6, 10);
			for(new i = 0; i < dicePerk_Levels[totalShopDicePerks]; i++)
			{
				dicePerk_Value[totalShopDicePerks][i]	= StringToInt(partsDicePerk[i]);
			}
			
			KvGetString(kvItemList, "msg",		strLine, sizeof(strLine));
			Format(dicePerk_Msg[totalShopDicePerks], 128, "%s", strLine);
			
			KvGetString(kvItemList, "complete",		strLine, sizeof(strLine));
			Format(dicePerk_Complete[totalShopDicePerks], 128, "%s", strLine);
			
			KvGetString(kvItemList, "enabled",		strLine, sizeof(strLine));
			dicePerk_Enabled[totalShopDicePerks]	= StringToInt(strLine);
			
			KvGetString(kvItemList, "reimburse",		strLine, sizeof(strLine));
			dicePerk_Reimburse[totalShopDicePerks]	= StringToInt(strLine);
		}
		
		totalShopDicePerks ++;
	}
	while (KvGotoNextKey(kvItemList));
	
	if(totalShopDicePerks > maxPerks)
		totalShopDicePerks = maxPerks;
	
	//PrintToServer("Total Shop Perks Loaded: %i", totalShopDicePerks);
	//LogToFile(logPath,"Total Perks Found: %i",totalShopDicePerks);
	CloseHandle(kvItemList);    
}

updatePerksOnClient(client)
{
//		INDEX
//		---------------------------------------------------------------------------
//		0. "seconds_reduction" "Time reduction per point"
//		1. "added_chance" "Chance for good roll increase. 5 = 5% base increase"
//		2. "fire_damage" "Chance for fire damage. 5 = 5% base increase"
//		3. "small_health_drop" "Chance for a small health drop on killing enemy. 25 = 25% base increase"
//		4. "round_end_immunity" "Makes player immune on round end: 0/1"
//		5. "reset_rtd_timer" "Chance to reset the RTD timer on death. 50 = 50%"
//		6. "extra_rtd_time" "Adds more time to Good rolls. 1s"
//		7. "extra_presents_creds" "..."
//		8. "extra_presents_armor" "..."
	
	resetPerkAttributes(client);
	
	//Load perks from file, those up to 200
	for(new i = 0; i <= totalDicePerks; i++)
	{
		if(RTDdice[client] >= dicePerk_need[i] && dicePerk_need[i] < 200)
		{
			//load perks on client
			RTD_Perks[client][dicePerk_attributes[i][0]] += dicePerk_attributes[i][1];
		}
	}
	
	//load Perks from database
	new tIndex;
	new cLvl;
	new reimburseAmount;
	
	for(new i = 0; i <= totalShopDicePerks; i++)
	{
		//If the users perk is blank then let's skip
		if(StrEqual(RTD_Perks_Unique[client][i], "", true))
			continue;
		
		//LogMessage("Staring to compare: %s", RTD_Perks_Unique[client][i]);
		//Find the read unique identifier
		for(new j = 0; j <= totalShopDicePerks; j++)
		{	
			//if the db perk is blank (went over) then skip
			if(StrEqual(dicePerk_Unique[j], "", true))
				continue;
			
			//LogMessage("Saved: %s | player: %s", RTD_Perks_Unique[client][i], dicePerk_Unique[j]);
			if(StrEqual(RTD_Perks_Unique[client][i], dicePerk_Unique[j], false))
			{	
				tIndex = dicePerk_Index[j];
				cLvl = RTD_PerksLevel[client][tIndex] ;
				
				for(new parseLevels = 0; parseLevels < cLvl; parseLevels ++)
					RTD_Perks[client][tIndex] += dicePerk_Value[j][parseLevels];
				
				//LogMessage("Client: %i |Loaded Perk: %s | AmountPerkLevels: %i | Client Value: %i", client, RTD_Perks_Unique[client][i], cLvl, RTD_Perks[client][tIndex]);
				
				if(dicePerk_Enabled[j] != 1)
				{
					//Reimburse player if perk is disabled
					if(dicePerk_Reimburse[j] == 1)
					{	
						//clear it out from the player
						Format(RTD_Perks_Unique[client][i], 32, "");
						
						//reimburse the player
						reimburseAmount = 0;
						for(new parseLevels = 0; parseLevels < cLvl; parseLevels ++)
							reimburseAmount += dicePerk_Cost[j][parseLevels];
						
						talentPoints[client] += reimburseAmount;
						
						//continue clearing out values from player
						RTD_PerksLevel[client][tIndex] = 0;
						RTD_Perks[client][tIndex] = 0;
						
						//show message to user on what just happened
						if(reimburseAmount > 0)
						{
							PrintCenterText(client, "Reimbursed: %i Talent Points from disabled Perk [%s]", reimburseAmount, dicePerk_Msg[j]);
							PrintToChat(client, "Reimbursed: %i Talent Points from disabled Perk [%s]", reimburseAmount, dicePerk_Msg[j]);
						}
					}
				}
				break;
			}
		}
	}
	
	//round end immunity is granted for everyone with more than 200 Dice
	//the rest of the perks must be purchased through the shop
	if(RTDdice[client] >= 200)
		RTD_Perks[client][4] = 1;
}

resetPerkAttributes(client)
{
	//DEFAULT
	//Set default values here
	
	for(new i = 0; i < maxPerks; i++)
	{
		RTD_Perks[client][i] = 0;
	}
	
	//Seconds reduction
	RTD_Perks[client][0] = 5;
	
	//presents credits base
	RTD_Perks[client][7] = 5;
	
	//presents armor base
	RTD_Perks[client][8] = 100;
	
	RTD_Perks[client][11] = 1;
	
	//Ghost Scare
	RTD_Perks[client][12] = 3;
	
	//Base Chance to mine a dice
	RTD_Perks[client][16] = 5;
	
	//Base chance for Redbull
	RTD_Perks[client][24] = 10;
}

//ShowOverlay(client, "debug/yuv", 20.0);ResetDicePerksOnUser(param1);
public Action:ConfirmDicePerksReset(client)
{
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_ConfirmMenuHandler);
	
	SetMenuTitle(hCMenu,"Reset Perks?",talentPoints[client]);
	
	AddMenuItem(hCMenu,"yes", "YES, reset perks", ITEMDRAW_DEFAULT);
	AddMenuItem(hCMenu,"no", "NO!", ITEMDRAW_DEFAULT);
	
	DisplayMenu(hCMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Action:ConfirmEventPerksReset(client)
{
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_EventConfirmMenuHandler);
	
	SetMenuTitle(hCMenu,"Reset Event Perks?",talentPoints[client]);
	
	AddMenuItem(hCMenu,"yes", "YES, reset event perks", ITEMDRAW_DEFAULT);
	AddMenuItem(hCMenu,"no", "NO!", ITEMDRAW_DEFAULT);
	
	DisplayMenu(hCMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public fn_ConfirmMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{	
	switch (action) 
	{
		case MenuAction_Select: 
		{	
			decl String:MenuInfo[64];
			new style;
			
			GetMenuItem(menu, param2, MenuInfo, sizeof(MenuInfo),style);
			
			if(StrEqual(MenuInfo, "yes"))
			{
				decl String:message[200];
				new String:name[32];
				GetClientName(param1, name, sizeof(name));
				
				Format(message, sizeof(message), "\x01\x04[PERKS] \x03%s\x04 used %i CREDITS to respec Talent Points!", name, reset_PerksCost);
				PrintToChatSome(message, param1);
				
				RTDCredits[param1] -= reset_PerksCost;
				ShowOverlay(param1, "debug/yuv", 2.0);
				EmitSoundToClient(param1, SOUND_RESET);
				
				ResetDicePerksOnUser(param1);
			}
			
			if(StrEqual(MenuInfo, "no"))
			{
				SetupPerksMenu(param1, 0);
			}
		}
		
		
		case MenuAction_Cancel: {
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public fn_EventConfirmMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{	
	switch (action) 
	{
		case MenuAction_Select: 
		{	
			decl String:MenuInfo[64];
			new style;
			
			GetMenuItem(menu, param2, MenuInfo, sizeof(MenuInfo),style);
			
			if(StrEqual(MenuInfo, "yes"))
			{
				decl String:message[200];
				new String:name[32];
				GetClientName(param1, name, sizeof(name));
				
				Format(message, sizeof(message), "\x01\x04[PERKS] \x03%s\x04 used %i CREDITS to respec Event Talent Points!", name, reset_EventPerksCost);
				PrintToChatSome(message, param1);
				
				RTDCredits[param1] -= reset_EventPerksCost;
				ShowOverlay(param1, "debug/yuv", 2.0);
				EmitSoundToClient(param1, SOUND_RESET);
				
				ResetEventPerksOnUser(param1);
			}
			
			if(StrEqual(MenuInfo, "no"))
			{
				SetupPerksMenu(param1, 0);
			}
		}
		
		
		case MenuAction_Cancel: {
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

ClearOutAllPerksOnUser(client)
{
	//This is either done on load or if player wants to respec
	for(new i = 0; i < maxPerks; i++)
	{
		RTD_Perks[client][dicePerk_Index[i]] = 0;
		RTD_PerksLevel[client][dicePerk_Index[i]] = 0;
		Format(RTD_Perks_Unique[client][dicePerk_Index[i]], 32, "");
	}
	
	if(talentPoints[client] == -1)
	{
		new diceLevel = RoundToFloor(RTDdice[client]/200.0);
		talentPoints[client] = diceLevel * 2;
	}
}

ResetDicePerksOnUser(client)
{
	new totalTPSpent;
	
	//This is either done on load or if player wants to respec
	for(new i = 0; i < maxPerks; i++)
	{
		//Do NOT reset event perks, this is disabled through another function
		if(RTD_PerksLevel[client][dicePerk_Index[i]] > 0)
		{
			if(dicePerk_EventOnly[i] == 0)
			{	
				for (new level = 1; level <= RTD_PerksLevel[client][dicePerk_Index[i]]; level++)
				{
					totalTPSpent += dicePerk_Cost[i][level-1];
				}
				
				RTD_Perks[client][dicePerk_Index[i]] = 0;
				RTD_PerksLevel[client][dicePerk_Index[i]] = 0;
				Format(RTD_Perks_Unique[client][dicePerk_Index[i]], 32, "");
			}
		}
	}
	
	talentPoints[client] += totalTPSpent;
	
	PrintToChat(client, "You were given %i Talent Points from the Perk Reset.", totalTPSpent);
	updatePerksOnClient(client);
}

ResetEventPerksOnUser(client)
{
	new tpSpentOnEvent;
	
	//This is either done on load or if player wants to respec
	for(new i = 0; i < maxPerks; i++)
	{
		//Do NOT reset event perks, this is disabled through another function
		if(RTD_PerksLevel[client][dicePerk_Index[i]] > 0)
		{
			//PrintToChat(client, "%i %s PerkLevels_Client:%i",i, dicePerk_Unique[i], RTD_PerksLevel[client][dicePerk_Index[i]]);
			
			if(dicePerk_EventOnly[i] == 1)
			{
				for (new level = 1; level <= RTD_PerksLevel[client][dicePerk_Index[i]]; level++)
				{
					//PrintToChat(client, "Perk: %s TotLevels:%i Level: %i Cost:%i", dicePerk_Unique[i], dicePerk_Levels[i], level, dicePerk_Cost[i][level-1]);
					tpSpentOnEvent += dicePerk_Cost[i][level-1];
				}
				
				RTD_Perks[client][dicePerk_Index[i]] = 0;
				RTD_PerksLevel[client][dicePerk_Index[i]] = 0;
				Format(RTD_Perks_Unique[client][dicePerk_Index[i]], 32, "");
			}
		}
	}
	
	talentPoints[client] += tpSpentOnEvent;
	
	PrintToChat(client, "You were given %i Talent Points from the Perk Event Reset.", tpSpentOnEvent);
	
	updatePerksOnClient(client);
}

public bool:userHasEventPerks(client)
{
	for(new i = 0; i < maxPerks; i++)
	{
		//Do NOT reset event perks, this is disabled through another function
		if(RTD_PerksLevel[client][dicePerk_Index[i]] != 0)
		{
			if(dicePerk_EventOnly[i] == 1)
			{
				//PrintToChat(client, "True: Perk: %i %s",`i, dicePerk_Unique[i]);
				return true;
			}
		}
	}
	
	return false;
}