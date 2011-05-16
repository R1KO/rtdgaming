#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

public GiveClassImmunity(client)
{
	if (!IsValidClient(client)) return;
	
	SetupClassImmunityMenu(client);
	client_rolls[client][AWARD_G_CLASSIMMUNITY][2] = GetTime();
	if (RTD_PerksLevel[client][25] != 0)
		CreateTimer(1.0 * RTD_Perks[client][25], Timer_ClassImmunityPerk, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_ClassImmunityPerk(Handle:timer, any:client)
{
	if (!IsValidClient(client) || client_rolls[client][AWARD_G_CLASSIMMUNITY][0] == 0 || RTD_PerksLevel[client][25] == 0)
		return Plugin_Handled;
	
	new offset = GetTime() - client_rolls[client][AWARD_G_CLASSIMMUNITY][2];
	if (RTD_Perks[client][25] - 5 <= offset && offset <= RTD_Perks[client][25] + 5)
		PrintCenterText(client, "You can now RESPEC class immunity with \"!respec\"");
		
	return Plugin_Handled;
}

public SetupClassImmunityMenu(client)
{
	new Handle:hMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_ClassImmunityMenuHandler);
	
	SetMenuTitle(hMenu,"Select the class you want immunity from:");
	
	AddMenuItem(hMenu,"Option 1","Scout");
	AddMenuItem(hMenu,"Option 2","Soldier");
	AddMenuItem(hMenu,"Option 3","Pyro");
	AddMenuItem(hMenu,"Option 4","Demoman");
	AddMenuItem(hMenu,"Option 5","Heavy");
	AddMenuItem(hMenu,"Option 6","Engineer");
	AddMenuItem(hMenu,"Option 7","Medic");
	AddMenuItem(hMenu,"Option 8","Sniper");
	AddMenuItem(hMenu,"Option 9","Spy");
	DisplayMenu(hMenu,client,MENU_TIME_FOREVER);
}

public fn_ClassImmunityMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	decl String:message[200];
	
	switch (action) 
	{
		case MenuAction_Select: 
		{
			new String:name[32];
			GetClientName(param1, name, sizeof(name));
			client_rolls[param1][AWARD_G_CLASSIMMUNITY][0] = 1;
			
			switch (param2) 
			{
				case 0: {
					client_rolls[param1][AWARD_G_CLASSIMMUNITY][1] = 1;
					Format(message, sizeof(message), "\x01\x04[IMMUNITY] \x03%s\x04 is immune from Scouts.", name); 
					PrintToChatSome(message); 
				}
				case 1: {
					Format(message, sizeof(message), "\x01\x04[IMMUNITY] \x03%s\x04 is immune from Soldiers.", name); 
					PrintToChatSome(message); 
					client_rolls[param1][AWARD_G_CLASSIMMUNITY][1] = 3;
				}
				case 2: {
					Format(message, sizeof(message), "\x01\x04[IMMUNITY] \x03%s\x04 is immune from Pyros.", name); 
					PrintToChatSome(message); 
					client_rolls[param1][AWARD_G_CLASSIMMUNITY][1]= 7;
				}
				case 3: {
					Format(message, sizeof(message), "\x01\x04[IMMUNITY] \x03%s\x04 is immune from Demomen.", name); 
					PrintToChatSome(message); 
					client_rolls[param1][AWARD_G_CLASSIMMUNITY][1] = 4;
				}
				case 4: {
					Format(message, sizeof(message), "\x01\x04[IMMUNITY] \x03%s\x04 is immune from Heavies.", name); 
					PrintToChatSome(message); 
					client_rolls[param1][AWARD_G_CLASSIMMUNITY][1] = 6;
				}
				case 5: {
					Format(message, sizeof(message), "\x01\x04[IMMUNITY] \x03%s\x04 is immune from Engineers.", name); 
					PrintToChatSome(message); 
					client_rolls[param1][AWARD_G_CLASSIMMUNITY][1] = 9;
				}
				case 6: {
					Format(message, sizeof(message), "\x01\x04[IMMUNITY] \x03%s\x04 is immune from Medics.", name); 
					PrintToChatSome(message); 
					client_rolls[param1][AWARD_G_CLASSIMMUNITY][1] = 5;
				}
				case 7: {
					Format(message, sizeof(message), "\x01\x04[IMMUNITY] \x03%s\x04 is immune from Snipers.", name); 
					PrintToChatSome(message); 
					client_rolls[param1][AWARD_G_CLASSIMMUNITY][1] = 2;
				}
				case 8: {
					Format(message, sizeof(message), "\x01\x04[IMMUNITY] \x03%s\x04 is immune from Spies.", name); 
					PrintToChatSome(message); 
					client_rolls[param1][AWARD_G_CLASSIMMUNITY][1] = 8;
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