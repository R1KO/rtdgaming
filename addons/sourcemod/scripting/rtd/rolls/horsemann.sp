#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <attachments>
#include <rtd_rollinfo>

public Action:Timer_Boo(Handle:timer, Handle:dataPackHandle)
{
	ResetPack(dataPackHandle);
	new client = GetClientOfUserId(ReadPackCell(dataPackHandle));
	
	if(client == 0)
		return Plugin_Stop;
	
	if(!IsClientInGame(client))
		return Plugin_Stop;
	
	if(!client_rolls[client][AWARD_G_HORSEMANN][0])
		return Plugin_Stop;
	
	new Float: enemyPos[3];
	new Float: horsemannPos[3];
	new Float: distance;
	new stunFlag;
	
	if(!inTimerBasedRoll[client])
	{
		if(client_rolls[client][AWARD_G_HORSEMANN][4] != 0 && client_rolls[client][AWARD_G_HORSEMANN][4] > GetTime())
		{
			decl String:message[200];
			Format(message, sizeof(message), "Scare Cool Down: %is", client_rolls[client][AWARD_G_HORSEMANN][4] -GetTime());
			centerHudText(client, message, 0.0, 1.0, HudMsg3, 0.14);
		}
		
		if(client_rolls[client][AWARD_G_HORSEMANN][4] < GetTime() && !hasInvisRolls(client))
		{
			decl String:message[200];
			Format(message, sizeof(message), "Scare Ready! Go Taunt!!");
			centerHudText(client, message, 0.0, 1.0, HudMsg3, 0.14);
		}
	}
	
	if(client_rolls[client][AWARD_G_HORSEMANN][4]  > GetTime())
		return Plugin_Continue;
	
	if(TF2_GetPlayerConditionFlags(client) & TF_CONDFLAG_BONKED)
		return Plugin_Continue;
	
	if(TF2_GetPlayerConditionFlags(client) & TF_CONDFLAG_CRITCOLA)
		return Plugin_Continue;
	
	if(!(TF2_GetPlayerConditionFlags(client) & TF_CONDFLAG_TAUNTING))
		return Plugin_Continue;
	
	//make sure player isn't going to eat something or drink something
	new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if(IsValidEntity(iWeapon))
	{
		new m_iItemDefinitionIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
		
		if(m_iItemDefinitionIndex == 42 || m_iItemDefinitionIndex == 46 || m_iItemDefinitionIndex == 163 || m_iItemDefinitionIndex == 311)
			return Plugin_Continue;
	}
		
	//player can scare again in 60 seconds
	if(RTD_PerksLevel[client][42] == 1)
	{
		client_rolls[client][AWARD_G_HORSEMANN][4] = GetTime() + 60;
	}else{
		client_rolls[client][AWARD_G_HORSEMANN][4] = GetTime() + 90;
	}
	
	GetClientAbsOrigin(client, horsemannPos);
	
	new Float:scareTime = 5.0;
	if(RTD_PerksLevel[client][43] == 1)
		scareTime = 9.0;
	
	for (new j = 1; j <= MaxClients ; j++)
	{
		if(!IsClientInGame(j) || !IsPlayerAlive(j))
			continue;
		
		if(TF2_GetPlayerConditionFlags(j) & TF_CONDFLAG_UBERCHARGED)
			continue;
		
		if(GetClientTeam(client) == GetClientTeam(j))
			continue;
		
		GetClientAbsOrigin(j, enemyPos);
		distance = GetVectorDistance( enemyPos, horsemannPos);
		
		if(distance < 400.0)
		{
			stunFlag = GetEntData(j, m_iStunFlags);
			
			//scare the player
			if(stunFlag != TF_STUNFLAGS_GHOSTSCARE)
			{
				
				new rndNum = GetRandomInt(1,8);
				
				new String:playsound[64];
				Format(playsound, sizeof(playsound), "vo/halloween_scream%i.wav", rndNum);
				EmitSoundToAll(playsound,j);
				
				rndNum = GetRandomInt(1,6);
				Format(playsound, sizeof(playsound), "vo/halloween_boo%i.wav", rndNum);
				EmitSoundToAll(playsound, client);
				
				TF2_StunPlayer(j,scareTime, 0.0, TF_STUNFLAGS_GHOSTSCARE, 0);
				
				Shake2(j, scareTime, 25.0);
				
				//reward player for scaring someone
				addHealthPercentage(client, 0.20, false);
				//addHealth(client, 30);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_DelayHorseMan(Handle:Timer, any:userId)
{
	new client = GetClientOfUserId(userId);
	
	if(client < 1)
		return Plugin_Stop;
	
	if(client_rolls[client][AWARD_G_HORSEMANN][0])
		ServerCommand("sm_bethehorseman %i", userId);
	
	return Plugin_Stop;
}