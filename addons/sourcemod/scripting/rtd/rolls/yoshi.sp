#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

public Make_Yoshi(client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client)) {
		PrintToChatAll("Cannot make client %d into a yoshi.", client);
		return;
	}
	addHealth(client, 500);
	//For spies...
	TF2_RemoveCondition(client, TFCond_Disguised);
	TF2_RemoveCondition(client, TFCond_Cloaked);
	//Save their waist size
	client_rolls[client][AWARD_G_YOSHI][3] = RTDOptions[client][3];
	RTDOptions[client][3] = 0;
	UpdateWaist(client);
	Yoshi_Thirdperson(client);
	client_rolls[client][AWARD_G_YOSHI][2] = 650; //Give the yoshi 650 health
	CreateTimer(0.1, Timer_Yoshi, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	//And finally...
	EmitSoundToAll(SOUND_YOSHISONG, client);
	EmitSoundToAll(SOUND_YOSHI_BECOMEYOSHI, client);
	PrintCenterText(client, "Touch enemies to gobble up and place them in eggs!");
}

public Action:Timer_Yoshi(Handle:timer, any:client)
{
	if (!IsValidClient(client)) {
		return Plugin_Stop;
	}
	if (!client_rolls[client][AWARD_G_YOSHI][0]) {
		SetHudTextParams(0.35, 0.82, 5.0, 250, 250, 210, 255);
		ShowHudText(client, HudMsg3, "Your yoshi's time expired.");
		Remove_Yoshi(client);
		return Plugin_Stop;
	} else if (client_rolls[client][AWARD_G_YOSHI][2] <= 0) {
		SetHudTextParams(0.35, 0.82, 5.0, 250, 250, 210, 255);
		ShowHudText(client, HudMsg3, "Your yoshi died!   D:");
		Remove_Yoshi(client);
		return Plugin_Stop;
	}
	
	//Make sure they stay bonked
	TF2_AddCondition(client, TFCond_Bonked, 5.0);
	//Make sure that if they switch weapons they still move fast
	ResetClientSpeed(client, 400.0);
	
	//If yoshi can eat someone
	new time = GetTime();
	if (client_rolls[client][AWARD_G_YOSHI][1] <= time)
	{
		new team = GetClientTeam(client);
		new Float:pos[3];
		GetClientAbsOrigin(client, pos);
		for (new i = 1; i < MaxClients; i++)
		{
			if (!IsValidClient(i) || !IsPlayerAlive(i))
				continue;
			if (team == GetClientTeam(i))
				continue;
			new Float:pos_i[3];
			GetClientEyePosition(i, pos_i);
			if (GetVectorDistance(pos, pos_i) < 120 && !yoshi_eaten[i][0] && !yoshi_eaten[i][2])
			{
				Yoshi_Eat(client, i);
				
				if(RTD_PerksLevel[client][41] == 1)
				{
					client_rolls[client][AWARD_G_YOSHI][1] = time + 2;
				}else{
					client_rolls[client][AWARD_G_YOSHI][1] = time + 4;
				}
				
				CreateTimer(1.0, Timer_Yoshi_CooldownText, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				break;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_Yoshi_CooldownText(Handle:timer, any:client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	new timeleft = client_rolls[client][AWARD_G_YOSHI][1] - GetTime();
	if (timeleft <= 0)
	{
		PrintCenterText(client, "You can now eat someone else!");
		return Plugin_Stop;
	}
	else
		PrintCenterText(client, "Chomp Cooldown: %d sec", timeleft);
	return Plugin_Continue;
}

public Yoshi_Eat(client, victim)
{
	StopSound(victim, SNDCHAN_AUTO , SOUND_YOSHI_BREAKOUT);

	yoshi_eaten[victim][0] = 1;
	yoshi_eaten[victim][1] = GetTime() + 10;
	
	new Handle:data;
	CreateDataTimer(10.0, Yoshi_Eggsplode, data, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(data, victim);
	WritePackCell(data, client);
	CreateTimer(1.0, Yoshi_EggTimer, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	TF2_RemoveCondition(victim, TFCond_Disguised);
	TF2_RemoveCondition(victim, TFCond_Cloaked);
	yoshi_eaten[victim][2] = RTDOptions[client][3];
	RTDOptions[client][3] = 0;
	UpdateWaist(client);
	Yoshi_Thirdperson(victim, true, 1);
	TF2_StunPlayer(victim, 10.0, 0.0, TF_STUNFLAG_BONKSTUCK | TF_STUNFLAG_NOSOUNDOREFFECT);
	SetEntityMoveType(victim, MOVETYPE_NONE); //Should disable NoClip as well
	
	/** Tell the clients what happened **/
	decl String:buf[32];
	GetClientName(client, buf, sizeof(buf));
	PrintToChat(victim, "%s has put you into a yoshi egg!", buf);
	PrintCenterText(victim, "Hopefully your friends bust you out soon...");
	GetClientName(victim, buf, sizeof(buf));
	PrintCenterText(client, "You have put %s into an egg!", buf);
	
	/** Play the sounds **/
	EmitSoundToAll(SOUND_YOSHI_BECOMEEGG, client);
	EmitSoundToAll(SOUND_YOSHI_INSIDEEGG, victim);
}

//Checks if the player gets rescued
public Action:Yoshi_EggTimer(Handle:timer, any:client)
{
	if (!yoshi_eaten[client][0])
		return Plugin_Stop;
	
	if (!IsValidClient(client) || !IsPlayerAlive(client))
	{
		if(IsClientAuthorized(client))
			Yoshi_BreakEgg(client);
		
		return Plugin_Stop;
	}
	
	new Float:pos[3], team;
	GetClientEyePosition(client, pos);
	team = GetClientTeam(client);
	
	for (new i = 1; i < MaxClients; i++)
	{
		if (!IsValidClient(i) || !IsPlayerAlive(i))
			continue;
		
		if (team != GetClientTeam(i) || yoshi_eaten[i][0] || yoshi_eaten[i][2])
			continue;
		new Float:pos_i[3];
		GetClientEyePosition(i, pos_i);
		
		if (GetVectorDistance(pos, pos_i) < 100)
		{
			Yoshi_BreakEgg(client);
			StopSound(client, SNDCHAN_AUTO, SOUND_YOSHI_INSIDEEGG);
			new String:victim_name[32], String:teammate_name[32];
			GetClientName(client, victim_name, 32);
			GetClientName(i, teammate_name, 32);
			PrintCenterText(client, "%s broke you free of the yoshi egg!  Run!", teammate_name);
			PrintCenterText(i, "You broke %s out of a yoshi egg.", victim_name);
			StopSound(client, SNDCHAN_AUTO, SOUND_YOSHI_BREAKOUT);
			StopSound(i, SNDCHAN_AUTO, SOUND_YOSHI_BREAKOUT);
			EmitSoundToClient(client, SOUND_YOSHI_BREAKOUT);
			EmitSoundToClient(i, SOUND_YOSHI_BREAKOUT, client);
			
			return Plugin_Stop;
		}
	}
	
	new timeleft = yoshi_eaten[client][1] - GetTime();
	if (timeleft <= 5 && timeleft >= 0)
		PrintCenterText(client, "Breakout Time: %ds", timeleft);
	
	return Plugin_Continue;
}

//Breaks the egg and sets the timer to kill the victim
public Action:Yoshi_Eggsplode(Handle:timer, Handle:data)
{
	ResetPack(data);
	new victim = ReadPackCell(data);
	
	if(!IsClientInGame(victim))
		return Plugin_Stop;
	
	RTDOptions[victim][3] = yoshi_eaten[victim][2];
	UpdateWaist(victim);
	if (!yoshi_eaten[victim][0])
		return Plugin_Stop;
	
	yoshi_eaten[victim][2] = 1;
	Yoshi_BreakEgg(victim);
	EmitSoundToAll(SOUND_YOSHI_EGGEXPLODE, victim);
	//Launch them into the air
	new Float:vel[] = {0.0, 0.0, 650.0};
	TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vel);
	new Handle:kill_data;
	CreateDataTimer(0.1, Yoshi_KillPlayer, kill_data, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(kill_data, victim);
	WritePackCell(kill_data, ReadPackCell(data));
	//And some particle effects
	AwardFireworks(victim, 2, false);
	
	return Plugin_Stop;
}

//Doesn't actually kill the player anymore
public Action:Yoshi_KillPlayer(Handle:timer, Handle:data)
{
	ResetPack(data);
	new victim = ReadPackCell(data);
	yoshi_eaten[victim][2] = 0;
	
	if (!IsValidClient(victim))
		return Plugin_Stop;
	
	StopSound(victim, SNDCHAN_AUTO, SOUND_YOSHI_INSIDEEGG);
	if (!IsPlayerAlive(victim))
		return Plugin_Stop;
	
	new Float:vel[3];
	GetEntPropVector(victim, Prop_Data, "m_vecAbsVelocity", vel);
	if (vel[2] <= 0) 
	{
		new attacker = ReadPackCell(data);
		if (!IsValidClient(attacker))
			attacker = 0;
		new damageToDeal = GetRandomInt(15, 60);
		if (GetClientHealth(victim) < damageToDeal)
		{
			DealDamage(victim, 1, attacker);
			FakeClientCommandEx(victim, "explode");
		}else{
			DealDamage(victim, damageToDeal, attacker);
		}
		
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Yoshi_BreakEgg(client)
{	
	yoshi_eaten[client][0] = 0;
	Yoshi_Thirdperson(client, false);
	TF2_StunPlayer(client, 0.1, 0.0, TF_STUNFLAG_BONKSTUCK | TF_STUNFLAG_NOSOUNDOREFFECT);
	SetEntityMoveType(client, MOVETYPE_WALK);
}

public Action:Remove_Yoshi_Timer(Handle:timer, any:client)
{
	Remove_Yoshi(client);
	client_rolls[client][AWARD_G_YOSHI][0] = 0;
}

stock Remove_Yoshi(client)
{
	if (!IsValidClient(client)) {
		PrintToChatAll("Cannot remove client %ds yoshi.", client);
		return;
	}
	
	Yoshi_Thirdperson(client, false);
	TF2_RemoveCondition(client, TFCond_Bonked);
	ResetClientSpeed(client);
	//Fix their waist size
	RTDOptions[client][3] = client_rolls[client][AWARD_G_YOSHI][3];
	UpdateWaist(client);
	EmitSoundToAll(SOUND_YOSHI_YOSHIDIE, client);
	
	StopSound(client, SNDCHAN_AUTO, SOUND_YOSHISONG);
	
}

stock Yoshi_Thirdperson(client, bool:apply=true, type=0)
{
	if (!IsValidClient(client)) {
		PrintToChatAll("Cannot apply thirdperson on client %d.", client);
		return;
	}

	if (apply) 
	{
		//Model code
		if (type == 0)
		{
			SetVariantString(GetClientTeam(client) == RED_TEAM ? MODEL_YOSHI_RED : MODEL_YOSHI_BLU);
		}
		else if (type == 1) 
		{
			
			if (GetClientTeam(client) == 2)
			{
				SetVariantString("255+0+0");
				AcceptEntityInput(client, "color", -1, -1, 0);
			}
			else
			{
				SetVariantString("0+0+255");
				AcceptEntityInput(client, "color", -1, -1, 0);
			}
			SetVariantString(MODEL_YOSHI_EGG);
		}
		else
			SetVariantString("");
			
		AcceptEntityInput(client, "SetCustomModel");
		
		SetVariantString("0 0 0");
		AcceptEntityInput(client, "SetCustomModelOffset");
		SetVariantInt(1);
		AcceptEntityInput(client, "SetCustomModelRotates");
		
		new Ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if(Ragdoll > 0)
		{
			AcceptEntityInput(Ragdoll,"kill");
		}
		
		//Third person code
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", client);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		SetEntData(client, g_oFOV, 70, 4, true);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		SetVariantBool(true);
		AcceptEntityInput(client, "SetCustomModelVisibletoSelf");
		
		Colorize(client, INVIS, false);
	} else {
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntData(client, g_oFOV, GetEntData(client, g_oDefFOV, 4), 4, true);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		SetVariantBool(false);
		AcceptEntityInput(client, "SetCustomModelVisibletoSelf");
		
		Colorize(client, NORMAL, true);
	}
}