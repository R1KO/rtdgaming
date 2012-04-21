#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>

#define PLUGIN_VERSION "1.1"

#define HHH "models/bots/headless_hatman.mdl"
//#define HHH "models/rtdgaming/horsemann/horsemann.mdl"
#define AXE "models/weapons/c_models/c_bigaxe/c_bigaxe.mdl"
#define SPAWN "ui/halloween_boss_summoned_fx.wav"
#define SPAWNRUMBLE "ui/halloween_boss_summon_rumble.wav"
#define SPAWNVO "vo/halloween_boss/knight_spawn.wav"
#define BOO "vo/halloween_boss/knight_alert.wav"
#define DEATH "ui/halloween_boss_defeated_fx.wav"
#define DEATHVO "vo/halloween_boss/knight_death02.wav"
#define DEATHVO2 "vo/halloween_boss/knight_dying.wav"
#define LEFTFOOT "player/footsteps/giant1.wav"
#define RIGHTFOOT "player/footsteps/giant2.wav"

new bool:g_IsModel[MAXPLAYERS+1] = {false, ...};
new bool:g_bIsTP[MAXPLAYERS+1] = {false, ...};
new bool:g_bIsHHH[MAXPLAYERS + 1] = {false, ...};
//new bool:g_bLeftFootstep[MAXPLAYERS + 1] = {0, ...};

public Plugin:myinfo = 
{
	name = "[TF2] Be the Horsemann",
	author = "FlaminSarge",
	description = "Be the Horsemann",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("bethehorsemann_version", PLUGIN_VERSION, "[TF2] Be the Horsemann version", FCVAR_REPLICATED|FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY);
	RegAdminCmd("sm_bethehorsemann", Command_Horsemann, ADMFLAG_VOTE, "It's a good time to run"); //ADMFLAG_ROOT,
	AddNormalSoundHook(HorsemannSH);
	HookEvent("post_inventory_application", EventInventoryApplication,  EventHookMode_Post);
	HookEvent("player_death", Event_Death,  EventHookMode_Post);
}
public OnClientPutInServer(client)
{
	OnClientDisconnect_Post(client);
}
public OnClientDisconnect_Post(client)
{
	g_IsModel[client] = false;
	g_bIsTP[client] = false;
	g_bIsHHH[client] = false;
}
public OnMapStart()
{
	PrecacheModel(HHH, true);
	PrecacheModel(AXE, true);
	PrecacheSound(BOO, true);
	PrecacheSound(SPAWN, true);
	PrecacheSound(SPAWNRUMBLE, true);
	PrecacheSound(SPAWNVO, true);
	PrecacheSound(DEATH, true);
	PrecacheSound(DEATHVO, true);
	PrecacheSound(LEFTFOOT, true);
	PrecacheSound(RIGHTFOOT, true);
//	TF2Items_CreateWeapon(8266, "tf_weapon_sword", 266, 2, 5, 100, "15 ; 0 ; 26 ; 750.0 ; 2 ; 999.0 ; 107 ; 4.0 ; 109 ; 0.0 ; 62 ; 0.09 ; 205 ; 0.05 ; 206 ; 0.05 ; 68 ; -2 ; 236 ; 1.0 ; 53 ; 1.0 ; 27 ; 1.0 ; 180 ; -25 ; 219 ; 1.0", _, "models/weapons/c_models/c_bigaxe/c_bigaxe.mdl", true);
}

public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	RemoveModel(client)
	SwitchView(client, false, true, true);
	g_bIsHHH[client] = false;
}
public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new deathflags = GetEventInt(event, "death_flags");
	if (!(deathflags & TF_DEATHFLAG_DEADRINGER))
	{
		if (IsValidClient(client) && g_bIsHHH[client])
		{
//			DoHorsemannDeath(client);
			EmitSoundToAll(DEATH);
			EmitSoundToAll(DEATHVO);
		}
	}
}
public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);

		g_IsModel[client] = true;
	}
}
public Action:RemoveModel(client)
{
	if (IsValidClient(client) && g_IsModel[client])
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		g_IsModel[client] = false;
	}
//	return Plugin_Handled;
}
stock SwitchView (target, bool:observer, bool:viewmodel, bool:self)
{
	//SetEntPropEnt(target, Prop_Send, "m_hObserverTarget", observer ? target:-1);
	//SetEntProp(target, Prop_Send, "m_iObserverMode", observer ? 1:0);
	//SetEntProp(target, Prop_Send, "m_iFOV", observer ? 100 : GetEntProp(target, Prop_Send, "m_iDefaultFOV"));
	//SetEntProp(target, Prop_Send, "m_bDrawViewmodel", viewmodel ? 1:0);
	
	
	SetVariantBool(self);
	if (self) AcceptEntityInput(target, "SetCustomModelVisibletoSelf");
	g_bIsTP[target] = observer;
}

//Commands
public Action:Command_Horsemann(client, args)
{
	decl String:arg1[32];
	if (args != 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	/**
	 * target_name - stores the noun identifying the target(s)
	 * target_list - array to store clients
	 * target_count - variable to store number of clients
	 * tn_is_ml - stores whether the noun must be translated
	 */
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE, /* Only allow alive players */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		MakeHorsemann(target_list[i]);
		LogAction(client, target_list[i], "\"%L\" made \"%L\" a Horseless Headless Horsemann", client, target_list[i]);
	}
	EmitSoundToAll(SPAWN);
	EmitSoundToAll(SPAWNRUMBLE);
	EmitSoundToAll(SPAWNVO);
	return Plugin_Handled;
}
MakeHorsemann(client)
{
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_minigun", false) == 0) 
	{
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
	CreateTimer(0.0, Timer_Switch, client);
//	TF2Items_GiveWeapon(client, 8266);
	SetModel(client, HHH);
	SwitchView(client, true, false, true);
	TF2_RemoveWeaponSlot(client, 0);
	TF2_RemoveWeaponSlot(client, 1);
	TF2_RemoveWeaponSlot(client, 5);
	TF2_RemoveWeaponSlot(client, 3);
	TF2_SetHealth(client, 2500);
	g_bIsHHH[client] = true;
//	g_bIsTP[client] = true;
}
stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}
public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveAxe(client);
}
stock GiveAxe(client)
{
	//TF2_RemoveWeaponSlot(client, 2);
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION)
	if (hWeapon != INVALID_HANDLE)
	{
		//Nothing here....
	}	
}
stock TF2_SwitchtoSlot(client, slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		decl String:classname[64];
		new wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, classname, sizeof(classname)))
		{
			FakeClientCommandEx(client, "use %s", classname);
		}
	}
}
public Action:HorsemannSH(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
//	decl String:clientModel[64];
	if (!IsValidClient(entity)) return Plugin_Continue;
//	GetClientModel(entity, clientModel, sizeof(clientModel));
	if (!g_bIsHHH[entity]) return Plugin_Continue;
	if (StrContains(sample, "_medic0", false) != -1)
	{
		sample = BOO;
		DoHorsemannScare(entity);
		return Plugin_Changed;
	}
	if (strncmp(sample, "player/footsteps/", 17, false) == 0)
	{
		if (StrContains(sample, "1.wav", false) != -1 || StrContains(sample, "3.wav", false) != -1) sample = LEFTFOOT;
		else if (StrContains(sample, "2.wav", false) != -1 || StrContains(sample, "4.wav", false) != -1) sample = RIGHTFOOT;
		EmitSoundToAll(sample, entity, _, 150);
//		if (g_bLeftFootstep[client]) sample = LEFTFOOT;
//		else sample = RIGHTFOOT;
//		g_bLeftFootstep[client] = !g_bLeftFootstep[client];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
DoHorsemannScare(client)
{
	decl Float:HorsemannPosition[3];
	decl Float:pos[3];
	new HorsemannTeam;

	GetClientAbsOrigin(client, HorsemannPosition);
	HorsemannTeam = GetClientTeam(client);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || !IsPlayerAlive(i) || HorsemannTeam == GetClientTeam(i))
			continue;

		GetClientAbsOrigin(i, pos);
		if (GetVectorDistance(HorsemannPosition, pos) <= 500 && !FindHHHSaxton(i) && !g_bIsHHH[i])
		{
			TF2_StunPlayer(i, 4.0, 0.3, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_SLOWDOWN);
		}
	}
}
stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
//	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
stock bool:FindHHHSaxton(client)
{
	new edict = MaxClients+1;
	while((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if ((idx == 277|| idx == 278) && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				return true;
			}
		}
	}
	return false;
}
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}