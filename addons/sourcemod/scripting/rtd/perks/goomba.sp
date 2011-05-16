#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

#define GOOMBA_REBOUND		300.0
#define GOOMBA_RADIUS 			25.0

public Do_GoombaStomp(any:client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client) || GetEntityFlags(client) & FL_ONGROUND) return;
	
	decl Float:vec[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vec);
	if(vec[2] >= (RTD_PerksLevel[client][26] == 1 ? -300.0 : -200.0)) return;
	
	decl Float:pos[3], Float:checkpos[3], Float:temp[3];
	GetClientAbsOrigin(client, pos);
	GetClientAbsOrigin(client, checkpos);
	g_FilteredEntity = client;
	
	new Handle:TraceEx;
	new HitEnt;
	
	//This code has been optimized by Czech, only change it if you know what you're doing
	new Float:t_1_n = checkpos[1] - GOOMBA_RADIUS;
	//attempt 1
	temp[0] = checkpos[0] - GOOMBA_RADIUS;
	temp[1] = t_1_n;
	temp[2] = checkpos[2] - 30.0;
	TraceEx = TR_TraceRayFilterEx(pos, temp, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter);
	HitEnt = TR_GetEntityIndex(TraceEx);
	CloseHandle(TraceEx);
	if(HitEnt > 0)
	{
		GoombaStomp(client, HitEnt);
		return;
	}
	
	//attempt 2
	temp[1] = checkpos[1] + GOOMBA_RADIUS;
	TraceEx = TR_TraceRayFilterEx(pos, temp, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter);
	HitEnt = TR_GetEntityIndex(TraceEx);
	CloseHandle(TraceEx);
	if(HitEnt > 0)
	{
		GoombaStomp(client, HitEnt);
		return;
	}
	
	//attempt 3
	temp[0] = checkpos[0] + GOOMBA_RADIUS;
	TraceEx = TR_TraceRayFilterEx(pos, temp, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter);
	HitEnt = TR_GetEntityIndex(TraceEx);
	CloseHandle(TraceEx);
	if(HitEnt > 0)
	{
		GoombaStomp(client, HitEnt);
		return;
	}
	
	//attempt 4
	temp[1] = t_1_n;
	TraceEx = TR_TraceRayFilterEx(pos, temp, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter);
	HitEnt = TR_GetEntityIndex(TraceEx);
	CloseHandle(TraceEx);
	if(HitEnt > 0)
	{
		GoombaStomp(client, HitEnt);
		return;
	}
}

//DO NOT CALL THIS DIRECTLY, USE Do_GoombaStomp TO CALCULATE IF client SHOULD STOMP victim
stock GoombaStomp(any:client, any:victim)
{
	//First off, a bunch of checks...
	if(victim == -1) return;
	decl String:edictName[32];
	GetEdictClassname(victim, edictName, sizeof(edictName));
	if(!StrEqual(edictName, "player")) return;	
	if(GetClientTeam(client) == GetClientTeam(victim)) return;
	new cond = TF2_GetPlayerConditionFlags(victim);
	if (
		cond & TF_CONDFLAG_UBERCHARGED
		|| cond & TF_CONDFLAG_DAZED
		//|| cond & TF_CONDFLAG_CLOAKED
		//|| cond & TF_CONDFLAG_DISGUISED
		) return;
	
	/*
	decl String:Attacker[256];
	GetClientName(client, Attacker, sizeof(Attacker));
	decl String:Killed[256];
	GetClientName(victim, Killed, sizeof(Killed));
	*/
	
	//Okay, let's do this...
	EmitSoundToAll(SOUND_MARIO_COIN, victim);
	Goomba_Fakekill[victim] = 1;
	CreateTimer(5.0, Goomba_Timer_Delete, EntIndexToEntRef(Goomba_AttachParticle(victim, "mini_fireworks")), TIMER_FLAG_NO_MAPCHANGE);
	
	if (RTD_PerksInfo[client][26][1] < GetTime())
		RTD_PerksInfo[client][26][2] = 100;
	else
		RTD_PerksInfo[client][26][2] -= 30;
	RTD_PerksInfo[client][26][1] = GetTime() + 2;
	
	new Float:damage = finalHealthAdjustments(client) * (0.01 * RTD_PerksInfo[client][26][2]);
	if (RTD_PerksLevel[client][26] == 1)
		damage *= 0.667;
	if (damage < 50.0)
		damage = 50.0;
	Goomba_DealDamage(victim, RoundToFloor(damage), client);
	
	//Leaving this here incase we decide to allow uber stomping later
	//if(TF2_IsPlayerInvuln(victim))
	//	ForcePlayerSuicide(victim);
	
	Goomba_Fakekill[victim] = 0;
	
	//Might wanna use this later too (Undisguise spy on stomp)
	//if(TF2_IsPlayerDisguised(client))
	//	TF2_DisguisePlayer(client, TFTeam:GetClientTeam(client), TFClass_Spy);
	
	decl Float:vecAng[3], Float:vecVel[3];
	GetClientEyeAngles(client, vecAng);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVel);
	vecAng[0] = DegToRad(vecAng[0]);
	vecAng[1] = DegToRad(vecAng[1]);
	vecVel[0] = GOOMBA_REBOUND*Cosine(vecAng[0])*Cosine(vecAng[1]);
	vecVel[1] = GOOMBA_REBOUND*Cosine(vecAng[0])*Sine(vecAng[1]);
	vecVel[2] = GOOMBA_REBOUND+100.0;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVel);
}

//Thx to pimpinjuice for his great DealDamage function.
Goomba_DealDamage(victim, damage, attacker = 0, dmg_type = 0)
{
	if ( victim <= 0
		|| !IsValidEdict(victim)
		|| !IsClientInGame(victim)
		|| !IsPlayerAlive(victim)
		|| damage <= 0)
		return;
	if (IsValidClient(attacker) &&
		client_rolls[victim][AWARD_G_CLASSIMMUNITY][0] &&
		client_rolls[victim][AWARD_G_CLASSIMMUNITY][1] == GetEntProp(attacker, Prop_Send, "m_iClass")) {
		new String:victimname[32];
		GetClientName(victim, victimname, sizeof(victimname));
		SetHudTextParams(0.32, 0.82, 1.0, 250, 250, 210, 255);
		ShowHudText(attacker, HudMsg3, "%s is immune to your stomps.", victimname);
		return;
	}
	
	new String:dmg_str[16];
	IntToString(damage, dmg_str, 16);
	
	new String:dmg_type_str[32];
	IntToString(dmg_type,dmg_type_str,32);

	new pointHurt = CreateEntityByName("point_hurt");
	
	if(pointHurt)
	{
		DispatchKeyValue(victim, "targetname", "goomba_hurtme");
		DispatchKeyValue(pointHurt, "DamageTarget", "goomba_hurtme");
		DispatchKeyValue(pointHurt, "Damage", dmg_str);
		DispatchKeyValue(pointHurt, "DamageType", dmg_type_str);

		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt, "Hurt", (attacker>0)?attacker:-1);
		DispatchKeyValue(pointHurt, "classname", "point_hurt");
		DispatchKeyValue(victim, "targetname", "goomba_donthurtme");
		RemoveEdict(pointHurt);
	}
}

public Action:Goomba_Timer_Delete(Handle:timer, any:particle)
{
	Goomba_DeleteParticle(EntRefToEntIndex(particle));
}

Goomba_DeleteParticle(any:particle)
{
    if (IsValidEntity(particle))
    {
        decl String:classname[256];
        GetEdictClassname(particle, classname, sizeof(classname));
		
        if (StrEqual(classname, "info_particle_system", false))
        {
            RemoveEdict(particle);
        }
    }
}

public Goomba_AttachParticle(ent, String:particleType[])
{
	new particle = CreateEntityByName("info_particle_system");
	if (!IsValidEdict(particle)) return -1;

	decl Float:pos[3] ;
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
	pos[2] += 74;
	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
	
	decl String:tName[128];
	Format(tName, sizeof(tName), "target%i", ent);
	
	DispatchKeyValue(ent, "targetname", tName);
	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", tName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	
	SetVariantString(tName);
	SetVariantString("flag");
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	
	return particle;
}