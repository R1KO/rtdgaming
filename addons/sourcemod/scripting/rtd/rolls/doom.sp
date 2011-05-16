#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2>
#include <rtd_rollinfo>

stock Action:DoomPlayer(client, bool:activate, time = 10) 
{
	if (activate == false) 
	{
		client_rolls[client][AWARD_B_DOOM][0] = 0;
		if (HasBeacon(client))
			PerformBeacon(client);
		return;
	} 
	else if (client_rolls[client][AWARD_B_DOOM][0])
		return;
		
	client_rolls[client][AWARD_B_DOOM][0] = 1;
	client_rolls[client][AWARD_B_DOOM][1] = GetTime() + (time > 10 || time <= 0 ? 10 : time);
	
	EmitSoundToClient(client, SOUND_EVIL_LAUGH);
	
	new String:clientName[32];
	GetClientName(client, clientName, sizeof(clientName));
	
	if (!HasBeacon(client))
		PerformBeacon(client);
	PrintHintText(client, "You have been doomed!  Hurry and shoot someone!");
	
	CreateTimer(1.0, Timer_Doom, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_Doom(Handle:timer, any:client) 
{
	if (!client_rolls[client][AWARD_B_DOOM][0] || !IsValidClient(client))
		return Plugin_Stop;
	
	new timeleft = client_rolls[client][AWARD_B_DOOM][1] - GetTime();
	
	if (timeleft <= 0) 
	{
		new explosionModel = PrecacheModel("sprites/sprite_fire01.vmt");
		
		if (explosionModel > -1) 
		{
			decl Float:pos[3];
			GetClientAbsOrigin(client, pos);
			TE_SetupExplosion(pos, explosionModel, 1.0, 1, 0, 500, 1000);
			TE_SendToAll();
		}
		
		FakeClientCommandEx(client, "explode");
		DoomPlayer(client, false);
		PrintCenterText(client, "You were doomed to die...");
		return Plugin_Stop;
	}
	
	PrintCenterText(client, "You Are Doomed [%d]", timeleft);
	
	return Plugin_Continue;
}