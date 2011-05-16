#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>

public SetupDisguise(client)
{
	new disguiseTeam = GetClientTeam(client);
	new disguisedPlayer = client;
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || i == client || !IsPlayerAlive(i))
			continue;
		
		if(GetClientTeam(i) == GetClientTeam(client))
			continue;
		
		disguiseTeam = GetClientTeam(i);
		disguisedPlayer = i;
	}
	
	SetEntProp(client, Prop_Send, "m_iDisguiseHealth", GetClientHealth(disguisedPlayer));
	SetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex", disguisedPlayer);
	SetEntProp(client, Prop_Send, "m_nDisguiseClass", TF2_GetPlayerClass(client));
	SetEntProp(client, Prop_Send, "m_nDesiredDisguiseClass", TF2_GetPlayerClass(client));
	SetEntProp(client, Prop_Send, "m_nDisguiseTeam", disguiseTeam);
	
}


public Action:Timer_CamoRightClick(Handle:timer, any:client)
{
	if(!IsClientInGame(client))
		return Plugin_Stop;
	
	if(!client_rolls[client][AWARD_G_CAMOUFLAGE][0])
		return Plugin_Stop;
	
	//ehh maybe end of round or something
	if(!IsPlayerAlive(client))
		return Plugin_Continue;
	
	if(client_rolls[client][AWARD_G_CAMOUFLAGE][1] && GetTime() >= client_rolls[client][AWARD_G_CAMOUFLAGE][3])
	{
		SetupDisguise(client);
		TF2_AddCond(client, 3);
	}
	
	if(GetClientButtons(client) & IN_USE)
	{
		BuildUseableRollsMenu(client);
	}
	
	return Plugin_Continue;
}

public Action:Timer_ShowCamoInfo(Handle:timer, any:client)
{
	if(!IsClientInGame(client))
		return Plugin_Stop;
	
	if(!client_rolls[client][AWARD_G_CAMOUFLAGE][0])
		return Plugin_Stop;
	
	//ehh maybe end of round or something
	if(!IsPlayerAlive(client))
		return Plugin_Continue;
	
	if(client_rolls[client][AWARD_G_CAMOUFLAGE][1])
	{
		PrintHintText(client, "Press L to EQUIP camouflage");
	}else{
		PrintHintText(client, "Press L to UNEQUIP camouflage");
	}
	
	return Plugin_Continue;
}


public Action:Timer_DelayDamage(Handle:timer, any:client)
{
	if(!IsClientInGame(client))
		return Plugin_Stop;
	
	if(!client_rolls[client][AWARD_G_CAMOUFLAGE][0])
		return Plugin_Stop;
	
	if(GetTime() >= client_rolls[client][AWARD_G_CAMOUFLAGE][3])
	{
		//player can damage others
		client_rolls[client][AWARD_G_CAMOUFLAGE][1] = 0;
		
		SetEntProp(client, Prop_Send, "m_iDisguiseHealth", GetClientHealth(client));
		SetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex", client);
		SetEntProp(client, Prop_Send, "m_nDisguiseClass", TF2_GetPlayerClass(client));
		SetEntProp(client, Prop_Send, "m_nDesiredDisguiseClass", TF2_GetPlayerClass(client));
		SetEntProp(client, Prop_Send, "m_nDisguiseTeam", GetClientTeam(client));
		
		TF2_RemoveCond(client, 3);
		
		PrintCenterText(client, "Camouflage REMOVED!");
		return Plugin_Stop;
	}
	
	PrintCenterText(client, "Camouflage cooldown: %is", client_rolls[client][AWARD_G_CAMOUFLAGE][3] - GetTime());
	
	return Plugin_Continue;
}