#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.1"

#define HHH "models/rtdgaming/horsemann/horsemann.mdl"
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

#define RED_TEAM				2
#define BLUE_TEAM				3

new bool:g_IsModel[MAXPLAYERS+1] = {false, ...};
new bool:g_bIsTP[MAXPLAYERS+1] = {false, ...};
new bool:g_bIsHHH[MAXPLAYERS + 1] = {false, ...};
//new bool:g_bLeftFootstep[MAXPLAYERS + 1] = {0, ...};

public Plugin:myinfo = 
{
	name = "[TF2] Be the Horsemann (RTD Mod)",
	author = "FlaminSarge (RTD Modified: John & Fox)",
	description = "Be the Horsemann (RTD Mod)",
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
	ProcessDownloads();
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
}

public OnPluginEnd()
{
	for (new i = 1; i <= MaxClients ; i++) 
	{
		
		if (IsClientInGame(i) )
		{
			if(!IsPlayerAlive(i))
				continue;
			
			if(g_bIsHHH[i])
			{
				RemoveModel(i);
				SwitchView(i, false, true, true);
			}
		}
	}
}

stock ProcessDownloads()
{
	AddFileToDownloadsTable("materials/models/rtdgaming/horsemann/headless_hatman.vmt");
	AddFileToDownloadsTable("materials/models/rtdgaming/horsemann/headless_hatman_red.vmt");
	AddFileToDownloadsTable("materials/models/rtdgaming/horsemann/hhh_pumpkin.vmt");
	AddFileToDownloadsTable("materials/models/rtdgaming/horsemann/invulnfx_blue.vmt");
	AddFileToDownloadsTable("materials/models/rtdgaming/horsemann/invulnfx_red.vmt");
	
	AddFileToDownloadsTable("models/rtdgaming/horsemann/horsemann.dx80.vtx");
	AddFileToDownloadsTable("models/rtdgaming/horsemann/horsemann.dx90.vtx");
	AddFileToDownloadsTable("models/rtdgaming/horsemann/horsemann.mdl");
	AddFileToDownloadsTable("models/rtdgaming/horsemann/horsemann.sw.vtx");
	AddFileToDownloadsTable("models/rtdgaming/horsemann/horsemann.vvd");
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(g_bIsHHH[client])
	{
		MakeHorsemann(client);
	}else{
		RemoveModel(client);
		SwitchView(client, false, true, true);
		g_bIsHHH[client] = false;
	}
}

public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(g_bIsHHH[client])
	{
		MakeHorsemann(client);
	}else{
		RemoveModel(client)
		SwitchView(client, false, true, true);
		g_bIsHHH[client] = false;
	}
}
public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new deathflags = GetEventInt(event, "death_flags");
	if (!(deathflags & TF_DEATHFLAG_DEADRINGER))
	{
		if (IsValidClient(client) && g_bIsHHH[client])
		{
			g_bIsHHH[client] = false;
			
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
		
		if(GetClientTeam(client) == BLUE_TEAM)
		{
			DispatchKeyValue(client, "skin","1"); 
		}else{
			DispatchKeyValue(client, "skin","2"); 
		}
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
public Action:Command_Horsemann(initiator, args)
{
	//can only be called by server
	if(initiator != 0)
	{
		ReplyToCommand(initiator, "Function can't be used through console, use: sm_bethehorsemann <Client Index>");
		PrintToServer("Function can't be used through console, use: sm_bethehorsemann <Client Index>");
	}
	
	decl String:strMessage[128];
	GetCmdArg(1, strMessage, sizeof(strMessage));
	
	new client = StringToInt(strMessage);
	
	//PrintToChatAll("Attempting to give horsemann to: %i", client);
	
	if(client < 1 || client > MAXPLAYERS)
		return Plugin_Handled;
	
	if(!IsClientInGame(client))
		return Plugin_Handled;
	
	if(!IsPlayerAlive(client))
		return Plugin_Handled;
	
	MakeHorsemann(client);
	
	EmitSoundToAll(SPAWN);
	EmitSoundToAll(SPAWNRUMBLE);
	EmitSoundToAll(SPAWNVO);
	return Plugin_Handled;
}

MakeHorsemann(client)
{
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	/*
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
	*/
	
	SetModel(client, HHH);
	SwitchView(client, true, false, true);
	
	/*
	TF2_RemoveWeaponSlot(client, 0);
	TF2_RemoveWeaponSlot(client, 1);
	TF2_RemoveWeaponSlot(client, 5);
	TF2_RemoveWeaponSlot(client, 3);
	* */
	
	//TF2_SetHealth(client, 2500);
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
	//new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION)
	//if (hWeapon != INVALID_HANDLE)
	//{
		//Nothing here....
	//}	
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