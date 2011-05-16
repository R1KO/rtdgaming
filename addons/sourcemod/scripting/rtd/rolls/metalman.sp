#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

public Give_MetalMan(client)
{
	CreateTimer(2.0, Timer_MetalMan, client, TIMER_REPEAT);
}

public Action:Timer_MetalMan(Handle:timer, any:client)
{
	if (!IsValidClient(client) || !client_rolls[client][AWARD_G_METALMAN][0]) {
		KillTimer(timer);
		return Plugin_Handled;
	}
	
	new metal = GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 12);
	new maxMetal;
	switch(RTD_PerksLevel[client][27]) {
		case 1: {
			maxMetal = 200;
			metal += 10;
		}
		case 2: {
			maxMetal = 200;
			metal += 15;
		}
		case 3: {
			maxMetal = 250;
			metal += 20;
		}
		case 4: {
			maxMetal = 250;
			metal += 25;
		}
		default: {
			maxMetal = 200;
			metal += 5;
		}
	}
	if (metal > maxMetal) metal = maxMetal;
	SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 12, metal, 4, true);
	return Plugin_Handled;
}