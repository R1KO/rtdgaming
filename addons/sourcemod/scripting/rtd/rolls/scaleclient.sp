#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2>
#include <rtd_rollinfo>

public Action:ScaleClient(client)
{
	//make sure player is here
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	if(client_rolls[client][AWARD_G_TINYBABYMAN][0])
		ScaleClientSize(client, 0.35);
	
	if(client_rolls[client][AWARD_G_LUMBERINGGIANT][0])
		ScaleClientSize(client, 1.65);
	
	return Plugin_Handled;
}

public Action:ScaleClientSize(client, Float:scaledSize)
{
	//make sure player is here
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scaledSize);
	return Plugin_Handled;
}