#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <rtd_rollinfo>

public Action:proximityStickies_Timer(Handle:timer, any:client)
{	
	//////////////////////////////////////////////////
	//Do some preliminary checks on the player that //
	//determines if this timer is stopped           //
	//////////////////////////////////////////////////
	if(!IsClientInGame(client) || !IsPlayerAlive(client) || !client_rolls[client][AWARD_G_PROXSTICKIES][0])
	{
		return Plugin_Stop;
	}
	
	//Player is all out of prox stickies
	if(client_rolls[client][AWARD_G_PROXSTICKIES][1] < 1)
	{
		client_rolls[client][AWARD_G_PROXSTICKIES][0]  = 0;
		client_rolls[client][AWARD_G_PROXSTICKIES][1]  = 0;
		
		return Plugin_Stop;
	}
	
	//make sure the player didnt switch class on us
	new TFClassType:class = TF2_GetPlayerClass(client);
	if(class != TFClass_DemoMan)
	{
		client_rolls[client][AWARD_G_PROXSTICKIES][0] = 0;
		client_rolls[client][AWARD_G_PROXSTICKIES][1] = 0;
		
		return Plugin_Stop;
	}else{
		SetHudTextParams(0.61, 0.85, 1.0, 250, 250, 210, 255);
		ShowHudText(client, HudMsg6, "Proximity Stickies: %i/16", client_rolls[client][AWARD_G_PROXSTICKIES][1]);
	}
	
	////////////////////////////////////////////////////
	//Check to see if an enemy is close to the sticky //
	//and if it is, then detonate the sticky          //
	///////////////////////////////////////////////////
	new ent = -1;
	new demomanID;
	new bool:detonatedStickie = false;
	new demomanTeam = GetClientTeam(client);
	new Float:pos[3];
	new Float:distance;
	
	//Thrower's current distance
	new Float:demomanPos[3];
	GetClientEyePosition(client, demomanPos); 
	
	//Enemy's position
	new Float:enemyPos[3];
	
	while ((ent = FindEntityByClassname(ent, "tf_projectile_pipe_remote")) != -1)
	{
		demomanID = GetEntPropEnt(ent, Prop_Send, "m_hThrower");
		
		if(demomanID == client)
		{
			for (new i = 1; i <= MaxClients ; i++)
			{
				if(!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) == demomanTeam)
				{
					continue;
				}
				
				//Get the enemy's postion
				GetClientEyePosition(i, enemyPos); 
				
				//Get the stickie bomb's postion
				GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos);
				
				distance = GetVectorDistance(enemyPos, pos);
				
				if(distance <170.0 && GetVectorDistance(demomanPos, pos) > 300.0)
				{
					SDKCall(g_hDetonate, ent);
					
					detonatedStickie = true;
					//break;
				}
			}
		}
		
		if(detonatedStickie)
		{
			client_rolls[demomanID][AWARD_G_PROXSTICKIES][1] --;
			
			if(client_rolls[demomanID][AWARD_G_PROXSTICKIES][1] <= 0)
			{
				client_rolls[demomanID][AWARD_G_PROXSTICKIES][0] = 0;
				client_rolls[demomanID][AWARD_G_PROXSTICKIES][1] = 0;
				
				return Plugin_Stop;
			}
		}
	}
	
	return Plugin_Continue;
}
