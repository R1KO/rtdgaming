#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>

#define PLUGIN_VERSION "1.1"

//#define HHH "models/rtdgaming/horsemann_v2/headless_hatman.mdl"
#define HHH "models/bots/headless_hatman.mdl"

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
	HookEvent("player_changeclass", Event_PlayerChangeClass);
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
	//ProcessDownloads();
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
	
	///////////////////////////////////////
	//Timers                             //
	///////////////////////////////////////
	//CreateTimer(0.5,  	Timer_UpdateSkins, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	for (new i = 1; i <= MaxClients ; i++) 
	{
		if (IsClientInGame(i) )
		{
			RemoveAllModels(i);
		}
	}
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
	
	AddFileToDownloadsTable("models/rtdgaming/horsemann_v2/headless_hatman.dx80.vtx");
	AddFileToDownloadsTable("models/rtdgaming/horsemann_v2/headless_hatman.dx90.vtx");
	AddFileToDownloadsTable("models/rtdgaming/horsemann_v2/headless_hatman.mdl");
	AddFileToDownloadsTable("models/rtdgaming/horsemann_v2/headless_hatman.phy");
	AddFileToDownloadsTable("models/rtdgaming/horsemann_v2/headless_hatman.sw.vtx");
	AddFileToDownloadsTable("models/rtdgaming/horsemann_v2/headless_hatman.vvd");
	AddFileToDownloadsTable("models/rtdgaming/horsemann_v2/headless_hatman_animations.mdl");
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(g_bIsHHH[client])
	{
		RemoveModel(client);
		MakeHorsemann(client);
	}
}

public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(g_bIsHHH[client])
	{
		RemoveModel(client);
		//g_bIsHHH[client] = false;
		
		SwitchView(client, false, true, true);
		
		CreateTimer(0.0, Timer_DelayMake, client);
	}
}

public Action:Event_PlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client)
		return;

	new TFClassType:class = TFClassType:GetEventInt(event, "class");
	new TFClassType:oldclass = TF2_GetPlayerClass(client);
	
	//player is the same class  :P
	if (class == oldclass)
		return;
	
	//player was Hulk before but now he changed class
	if(g_bIsHHH[client])
	{
		if(class != TFClass_DemoMan)
		{
			RemoveModel(client);
			SwitchView(client, false, true, true);
			
			g_bIsHHH[client] = false;
			EmitSoundToAll(DEATH, client);
			EmitSoundToAll(DEATHVO, client);
		}
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
			RemoveModel(client);
			SwitchView(client, false, true, true);
			
			g_bIsHHH[client] = false;
			EmitSoundToAll(DEATH, client);
			EmitSoundToAll(DEATHVO, client);
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

public Action:RemoveAllModels(client)
{
	if (IsValidClient(client))
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
	
	EmitSoundToAll(SPAWN, client);
	EmitSoundToAll(SPAWNRUMBLE, client);
	EmitSoundToAll(SPAWNVO, client);
	return Plugin_Handled;
}

public Action:Timer_DelayMake(Handle:timer, any:client)
{
	MakeHorsemann(client);
	return Plugin_Stop;
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
	TF2_SetHealth(client, 500);
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
	TF2_RemoveWeaponSlot(client, 2);
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION)
	if (hWeapon != INVALID_HANDLE)
	{
		TF2Items_SetClassname(hWeapon, "tf_weapon_sword");
		TF2Items_SetItemIndex(hWeapon, 266);
		TF2Items_SetLevel(hWeapon, 100);
		TF2Items_SetQuality(hWeapon, 5);
		new String:weaponAttribs[] = "15 ; 0 ; 26 ; 750.0 ; 2 ; 999.0 ; 107 ; 4.0 ; 109 ; 0.0 ; 62 ; 0.70 ; 205 ; 0.05 ; 206 ; 0.05 ; 68 ; -2 ; 69 ; 0.0 ; 53 ; 1.0 ; 27 ; 1.0 ; 180 ; -15 ; 219 ; 1.0";
		new String:weaponAttribsArray[32][32];
		new attribCount = ExplodeString(weaponAttribs, " ; ", weaponAttribsArray, 32, 32);
		if (attribCount > 0) {
			TF2Items_SetNumAttributes(hWeapon, attribCount/2);
			new i2 = 0;
			for (new i = 0; i < attribCount; i+=2) {
				TF2Items_SetAttribute(hWeapon, i2, StringToInt(weaponAttribsArray[i]), StringToFloat(weaponAttribsArray[i+1]));
				i2++;
			}
		} else {
			TF2Items_SetNumAttributes(hWeapon, 0);
		}
		new weapon = TF2Items_GiveNamedItem(client, hWeapon);
		EquipPlayerWeapon(client, weapon);
		CloseHandle(hWeapon);
		SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", PrecacheModel(AXE));
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
		EmitSoundToAll(sample, entity);
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

public Action:Timer_UpdateSkins(Handle:timer) 
{
	new skin;
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if(g_bIsHHH[i])
		{
			skin = GetEntProp(i, Prop_Data, "m_nSkin");
			
			if(GetClientTeam(i) == BLUE_TEAM)
			{
				if(TF2_IsPlayerInCondition(i, TFCond_Ubercharged))
				{
					if(skin != 3)
					{
						DispatchKeyValue(i, "skin","3");
					}
				}else{
					if(skin != 0)
					{
						DispatchKeyValue(i, "skin","0");
					}
				}
			}else{
				
				if(TF2_IsPlayerInCondition(i, TFCond_Ubercharged))
				{
					if(skin != 2)
					{
						DispatchKeyValue(i, "skin","2");
					}
				}else{
					if(skin != 1)
					{
						DispatchKeyValue(i, "skin","1");
					}
				}
			}
			
			
		}
		
	}
	
	return Plugin_Continue;
}