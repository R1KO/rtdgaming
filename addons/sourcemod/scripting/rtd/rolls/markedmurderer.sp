#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

#define MARKED_MURDERER_COOLDOWN					600.0 /* in seconds */
#define MARKED_MURDERER_KILL_LIMIT		5
#define MARKED_MURDERER_STRING_WON "\x04Marked Murderer:\x01 Disabled for 10 minutes."
#define MARKED_MURDERER_STRING_LOST "\x04Marked Murderer:\x01 No dice given out this time."

/* 0 - Last time of dice reward from this roll.
	1 - Die entity.
	2 - Particle entity.
	3 - Kill count.
	4 - Someone currently has this roll. */
new gMarkedMurderer[5];

public Queue_MarkedMurderer(client)
{
	if (gMarkedMurderer[4]) return; //Shouldn't need, but being safe
	gMarkedMurderer[4] = client; //Lock MM
	centerHudText(client, "In a moment you will have 30 seconds to kill 5 players to win 2 dice.", 2.0, 8.0, HudMsg3, 0.75); 
	CreateTimer(10.0, Give_MarkedMurderer, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Give_MarkedMurderer(Handle:timer, any:client)
{
	new die = CreateEntityByName("prop_dynamic");
	if (!IsValidEntity(die)) {
		PrintToChatAll("Marked Murderer: Failed to create die.");
		return Plugin_Continue;
	}
	DispatchKeyValue(die, "model", MODEL_DICE);
	DispatchSpawn(die);
	SetVariantString("idle");
	AcceptEntityInput(die, "SetAnimation", -1, -1, 0);
	CAttach(die, client, "flag");
	
	//Create the particle effect
	new particle = CreateEntityByName("info_particle_system");
	if (!IsValidEdict(particle)) {
		killEntityIn(die, 0.1);
		PrintToChatAll("Marked Murderer: Failed to create particle.");
		return Plugin_Continue;
	}
	
	if (GetClientTeam(client) == RED_TEAM)
		DispatchKeyValue(particle, "effect_name", "critical_rocket_red");
	else
		DispatchKeyValue(particle, "effect_name", "critical_rocket_blue");
	DispatchSpawn(particle);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	CAttach(particle, client, "flag");

	gMarkedMurderer[1] = EntIndexToEntRef(die);
	gMarkedMurderer[2] = EntIndexToEntRef(particle);
	gMarkedMurderer[3] = 0;
	
	centerHudText(client, "GO NOW!  You have 30 seconds!", 0.0, 3.0, HudMsg3, 0.75);
	
	new Handle:data;
	CreateDataTimer(10.0, Timer_MarkedMurderer, data, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(data, 1);
	WritePackCell(data, client);
	
	return Plugin_Continue;
}

//Automatically removes the roll if anything screws up or the player satisfied the constraints to gain dice
stock Satisfied_MarkedMurderer(assister=0)
{
	new client = gMarkedMurderer[4];
	if (client == 0) return;
	new die = EntRefToEntIndex(gMarkedMurderer[1]);
	new particle = EntRefToEntIndex(gMarkedMurderer[2]);
	if (!IsValidClient(client) || !IsPlayerAlive(client)
		|| !client_rolls[client][AWARD_G_MARKEDMURDERER][0]
		|| !IsValidEntity(die) || !IsValidEntity(particle)) {
		Remove_MarkedMurderer();
		PrintToChatAll(MARKED_MURDERER_STRING_LOST);
	} else if (gMarkedMurderer[3] >= MARKED_MURDERER_KILL_LIMIT) {
		addDice(client, 6, 2);
		if (assister > 0)
			if (IsValidClient(assister))
				addDice(assister, 6, 1);
		gMarkedMurderer[0] = GetTime();
		Remove_MarkedMurderer();
		PrintToChatAll(MARKED_MURDERER_STRING_WON);
		new Handle:data;
		CreateDataTimer(600.0, Timer_MarkedMurderer, data, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(data, 0);
		WritePackCell(data, 0);
	}
}

public Action:Timer_MarkedMurderer(Handle:timer, Handle:d)
{
	ResetPack(d);
	new message = ReadPackCell(d);
	new client = ReadPackCell(d);
	if (message == 0) {
		PrintToChatAll("\x04Marked Murderer is once again roll-able.");
		return Plugin_Stop;
	}
	if (gMarkedMurderer[4] == 0)
		return Plugin_Stop;
		
	switch (message)
	{
		case 1:
		{
			centerHudText(client, "20 seconds left...", 0.0, 5.0, HudMsg3, 0.75);
		}
		case 2:
		{
			centerHudText(client, "10 seconds left...", 0.0, 5.0, HudMsg3, 0.75);
		}
		case 3:
		{
			if (gMarkedMurderer[4])
				PrintToChatAll(MARKED_MURDERER_STRING_LOST);
			Remove_MarkedMurderer();
			return Plugin_Stop;
		}
		default:
			return Plugin_Stop;
	}
	ResetPack(d);
	WritePackCell(d, message+1);
	return Plugin_Continue;
}

public Remove_MarkedMurderer()
{
	new die = EntRefToEntIndex(gMarkedMurderer[1]);
	new particle = EntRefToEntIndex(gMarkedMurderer[2]);
	
	if (IsValidEntity(die) && gMarkedMurderer[1] != 0)
	{
		CDetach(die);
		killEntityIn(die, 0.1);
	}
	
	if (IsValidEntity(particle) && gMarkedMurderer[2] != 0)
		killEntityIn(particle, 0.1);
	
	client_rolls[gMarkedMurderer[4]][AWARD_G_MARKEDMURDERER][0] = 0;
	gMarkedMurderer[4] = 0;
}