#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <attachables>
#include <tf2_stocks>

#define VERSION 		"0.0.3"

#define MODEL_HHH		"models/rtdgaming/horsemann/horsemann.mdl"

#define SOUND_SPAWN		"ui/halloween_boss_summoned_fx.wav"
#define SOUND_DEATH		"ui/halloween_boss_defeated_fx.wav"

#define REQUIRED_FLAGS	ADMFLAG_CHEATS

#define RED_TEAM				2
#define BLUE_TEAM				3

new bool:g_bSdkStarted = false;
new Handle:g_hSdkEquipWearable;
new Handle:g_hSdkRemoveWearable;

new Handle:g_hCvarEffects = INVALID_HANDLE;
new bool:g_bEffects;

new Handle:g_hCvarEnabled = INVALID_HANDLE;
new bool:g_bEnabled;

new Handle:g_hCvarDisableOnDeath = INVALID_HANDLE;
new bool:g_bDisableOnDeath;

new bool:g_bIsHHH[MAXPLAYERS+1];
new bool:g_bHasHHHModel[MAXPLAYERS+1];
new g_iEntityOthers[MAXPLAYERS+1];
new g_iEntitySelf[MAXPLAYERS+1];
new bool:roundEnded;

public Plugin:myinfo =
{
	name 		= "tBeTheHHH",
	author 		= "Thrawn",
	description = "Allows players to wear the HHH model",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tbethehhh_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarEnabled = CreateConVar("sm_tbethehhh_enable", "1", "Enable tHHH", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarEnabled, Cvar_Changed);

	g_hCvarDisableOnDeath = CreateConVar("sm_tbethehhh_disableondeath", "1", "Stop being a hhh on death.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarEffects = CreateConVar("sm_tbethehhh_effects", "0", "Enables effects on HHH spawn.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarEffects, Cvar_Changed);
	HookConVarChange(g_hCvarDisableOnDeath, Cvar_Changed);

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("post_inventory_application", Event_Inventory);
	HookEvent("player_changeclass", Event_PlayerSpawn);
	
	RegConsoleCmd("sm_bethehorseman", Command_MakeMeHHH);
	RegConsoleCmd("sm_removethehorseman", Command_RemoveHHH);
	
	HookEvent("teamplay_round_win", Event_RoundWin);
	HookEvent("teamplay_round_active", Event_RoundActive);
	
	
}

 public OnClientPostAdminCheck(client)
{
	g_bIsHHH[client] = false;
	g_bHasHHHModel[client] = false;
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
	g_bDisableOnDeath = GetConVarBool(g_hCvarDisableOnDeath);
	g_bEffects = GetConVarBool(g_hCvarEffects);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();

	if(convar == g_hCvarEnabled && !g_bEnabled) {
		for(new client = 1; client <= MaxClients; client++) {
			if(g_bIsHHH[client]) {
				if(IsClientInGame(client)) {
					RemoveHHHModel(client);
				}

				g_bIsHHH[client] = false;
			}
		}
	}
}

/* ----------------------------------------------
// Commands
// ------------------------------------------- */

public Action:Command_MakeMeHHH(iClient, args) {
	if(iClient > 0)
	{	
		ReplyToCommand(iClient, "This command can only be accessed through RTD");
	}
		
	if(!g_bEnabled && iClient > 0 && iClient < MaxClients)return Plugin_Handled;

	if(!CheckCommandAccess(iClient, "sm_bethehhh", REQUIRED_FLAGS)) {
		ReplyToCommand(iClient, "You don't have access to this command.");
		return Plugin_Handled;
	}
	
	decl String:userid[64];
	GetCmdArg(1, userid, sizeof(userid));
	new client = GetClientOfUserId(StringToInt(userid));
	
	if(client < 1)
		return Plugin_Handled;
	
	//PrintToChatAll("Attempting MakeMeHHH %i", client);
	
	MakeHHH(client);

	return Plugin_Handled;
}


public Action:Command_RemoveHHH(iClient, args) {
	if(iClient > 0)
	{	
		ReplyToCommand(iClient, "This command can only be accessed through RTD");
	}
		
	if(!g_bEnabled && iClient > 0 && iClient < MaxClients)return Plugin_Handled;

	if(!CheckCommandAccess(iClient, "sm_bethehhh", REQUIRED_FLAGS)) {
		ReplyToCommand(iClient, "You don't have access to this command.");
		return Plugin_Handled;
	}
	
	decl String:userid[64];
	GetCmdArg(1, userid, sizeof(userid));
	new client = GetClientOfUserId(StringToInt(userid));
	
	if(client < 1)
		return Plugin_Handled;
	
	//PrintToChatAll("Attempting to remove :%i", client);
	RemoveHHHModel(client);

	return Plugin_Handled;
}
/* ----------------------------------------------
// Initialisation stuff
// ------------------------------------------- */
public OnMapStart() {
	PrecacheModel(MODEL_HHH, true);
	PrecacheSound(SOUND_SPAWN, true);
	PrecacheSound(SOUND_DEATH, true);
	
	for(new client = 1; client <= MaxClients; client++) {
		g_bIsHHH[client] = false;
		g_bHasHHHModel[client] = false;
	}
	
	//////////////////////////////////
	// Downloads                    //
	//////////////////////////////////
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
	
	///////////////////////////////////////
	//Timers                             //
	///////////////////////////////////////
	CreateTimer(0.5,  	Timer_UpdateSkins, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

/* ----------------------------------------------
// HHH creation
// ------------------------------------------- */

public MakeHHH(iClient) {
	if(!g_bIsHHH[iClient]) {
		g_bIsHHH[iClient] = true;
		
		//wait until next frame
		CreateTimer(0.1,timerAssignModel, GetClientUserId(iClient));
		//AssignHHHModel(iClient);

		CreateTimer(0.5, HHHSummonEffects, iClient);
	}
}

public HHHDeath(iClient) {
	if(g_bEffects) {
		new Float:vPos[3];
		GetClientAbsOrigin(iClient, vPos);

		CreateParticle(vPos, "halloween_boss_death", 4.0);
		EmitAmbientSound(SOUND_DEATH, vPos, iClient);
	}

	RemoveHHHModel(iClient);
}

public Action:HHHSummonEffects(Handle:timer, any:iClient) {
	if(g_bEffects) {
		new Float:vPos[3];
		GetClientAbsOrigin(iClient, vPos);

		EmitAmbientSound(SOUND_SPAWN, vPos, iClient);
		CreateParticle(vPos, "halloween_boss_summon", 4.0);
		AttachParticle(iClient, "ghost_firepit_firebits", "flag", 4.0);
		AttachParticle(iClient, "ghost_firepit_wisps", "flag", 4.0);
		AttachParticle(iClient, "ghost_firepit", "flag", 3.0);
	}
}

/* ----------------------------------------------
// HHH Events
// ------------------------------------------- */

public Action:Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundEnded = true;
}

public Action:Event_RoundActive(Handle:event, const String:name[], bool:dontBroadcast)
{
	//When the round is active and players can move
	roundEnded = false;
}

public Event_Inventory(Handle:hEvent, String:strName[], bool:bDontBroadcast) {
	if(!g_bEnabled)return;
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(g_bIsHHH[iClient]) 
	{
		RemoveHHHModel(iClient);
		g_bIsHHH[iClient] = true;
		
		//wait until next frame
		CreateTimer(0.1,timerAssignModel, GetEventInt(hEvent, "userid"));
	}
}

public Event_PlayerDeath(Handle:hEvent, String:strName[], bool:bDontBroadcast) {
	if(!g_bEnabled)return;
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(g_bIsHHH[iClient] && !roundEnded) 
	{
		HHHDeath(iClient);
		
		if(g_bDisableOnDeath) {
			g_bIsHHH[iClient] = false;
		}
	}
}

public Action:Event_PlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bEnabled)return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client)
		return;

	new TFClassType:class = TFClassType:GetEventInt(event, "class");
	new TFClassType:oldclass = TF2_GetPlayerClass(client);
	
	//player is the same class  :P
	if (class == oldclass)
		return;
	
	if(!g_bIsHHH[client])
		return;
	
	if(class == TFClass_Spy)
	{
		RemoveHHHModel(client);
		g_bIsHHH[client] = false;
	}
	
}

public Event_PlayerSpawn(Handle:hEvent, String:strName[], bool:bDontBroadcast) {
	if(!g_bEnabled)return;
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(g_bIsHHH[iClient])
	{
		
		new TFClassType:class = TF2_GetPlayerClass(iClient);
		if(class == TFClass_Spy)
		{
			RemoveHHHModel(iClient);
			g_bIsHHH[iClient] = false;
			return;
		}
		
		RemoveHHHModel(iClient);
		
		//wait until next frame
		CreateTimer(0.1,timerAssignModel, GetEventInt(hEvent, "userid"));
	}

	return;
}



public Action:timerAssignModel(Handle:Timer, any:userID)
{
	new client = GetClientOfUserId(userID);
	if(client < 1)
		return Plugin_Stop;
	
	if(!g_bIsHHH[client])
		return Plugin_Stop;
	
	AssignHHHModel(client);
	
	return Plugin_Stop;
}

/* ----------------------------------------------
// HHH Model Stuff
// ------------------------------------------- */
#define EF_BONEMERGE            (1 << 0)
#define EF_NOSHADOW             (1 << 4)
#define EF_BONEMERGE_FASTCULL   (1 << 7)
#define EF_PARENT_ANIMATES      (1 << 9)

#define INVISIBLE  {255,255,255,0}
#define NORMAL     {255,255,255,255}


public AssignHHHModel(iClient) {
	if(g_bHasHHHModel[iClient])return;

	ColorizePlayer(iClient, INVISIBLE);
	ColorizePlayerItems(iClient, INVISIBLE);
	
	g_iEntityOthers[iClient] = Attachable_CreateAttachable(iClient, false);
	SetEntityModel(g_iEntityOthers[iClient],MODEL_HHH);
	
	g_iEntitySelf[iClient] = HHHSelf(iClient);
	SetEntityModel(g_iEntitySelf[iClient], MODEL_HHH);

	g_bHasHHHModel[iClient] = true;
	
	//PrintToChatAll("Assigned :%i", iClient);
}

public RemoveHHHModel(iClient) 
{
	if(!g_bHasHHHModel[iClient])return;

	ColorizePlayer(iClient, NORMAL);
	ColorizePlayerItems(iClient, NORMAL);

	if(IsValidEdict(g_iEntitySelf[iClient])) {
		SDKCall(g_hSdkRemoveWearable, iClient, g_iEntitySelf[iClient]);
		RemoveEdict(g_iEntitySelf[iClient]);
	}

	if(IsValidEdict(g_iEntityOthers[iClient])) {
		RemoveEdict(g_iEntityOthers[iClient]);
	}

	g_bHasHHHModel[iClient] = false;
	g_bIsHHH[iClient] = false;
	
	//PrintToChatAll("Removed :%i", iClient);
}

stock HHHSelf(iClient) {
    new iHHH = CreateEntityByName("tf_wearable_item");

    if (IsValidEdict(iHHH))
    {
		SetEntProp(iHHH, Prop_Send, "m_fEffects",             EF_BONEMERGE|EF_BONEMERGE_FASTCULL|EF_NOSHADOW|EF_PARENT_ANIMATES);
		SetEntProp(iHHH, Prop_Send, "m_iTeamNum",             2);
		SetEntProp(iHHH, Prop_Send, "m_nSkin",                0);
		SetEntProp(iHHH, Prop_Send, "m_CollisionGroup",       11);
		SetEntProp(iHHH, Prop_Send, "m_iItemDefinitionIndex", 52);
		SetEntProp(iHHH, Prop_Send, "m_iEntityLevel",         100);
		SetEntProp(iHHH, Prop_Send, "m_iEntityQuality",       0);
		DispatchSpawn(iHHH);

		if (g_bSdkStarted == false)TF2_SdkStartup();
		SDKCall(g_hSdkEquipWearable, iClient, iHHH);
    }

    return iHHH;
}

stock ColorizePlayerItems(client, color[4]) {
	new iEnt = MaxClients+1;
	new weaponid;
	
	while((iEnt = FindEntityByClassname(iEnt, "tf_wearable_item")) != -1) 
	{
		weaponid = GetEntProp(iEnt, Prop_Send, "m_iItemDefinitionIndex");
		
		new iOwner = GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity");
		if(iOwner == client) 
		{
			//don't colorize the razorback
			if(weaponid != 57)
			{
				ColorizePlayer(iEnt, color);
			}
		}
	}
}

public ColorizePlayer(client, color[4]) {
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
}

stock TF2_SdkStartup() {
    new Handle:hGameConf = LoadGameConfigFile("TF2_EquipmentManager");
    if (hGameConf != INVALID_HANDLE)
    {
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"EquipWearable");
        PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
        g_hSdkEquipWearable = EndPrepSDKCall();

        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"RemoveWearable");
        PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
        g_hSdkRemoveWearable = EndPrepSDKCall();

        CloseHandle(hGameConf);
        g_bSdkStarted = true;
    } else {
        SetFailState("Couldn't load SDK functions (TF2_EquipmentManager).");
    }
}

public CreateParticle(Float:pos[3], String:particleType[], Float:time) {
	new particle = CreateEntityByName("info_particle_system");

	if (IsValidEdict(particle)) {
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);

		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");

		if(time > 0.0) {
			CreateTimer(time, Timer_DeleteParticles, particle);
		}

		return particle;
	}

	return -1;
}

AttachParticle(entity, const String:particleType[], const String:attachmentPoint[] = "", Float:time = 0.0)
{
	new particle = CreateEntityByName("info_particle_system");

	new String:name[128];
	if (IsValidEdict(particle))
	{
		new Float:position[3];
		if(entity > 0 && entity < MaxClients) {
			GetClientEyePosition(entity, position);
			//position[2] -= 15.0;
		} else {
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
		}

		TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

		Format(name, sizeof(name), "target%i", entity);
		DispatchKeyValue(entity, "targetname", name);

		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", name);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(name);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		if(!StrEqual(attachmentPoint,"")) {
			SetVariantString(attachmentPoint);
			AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		}
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");

		if(time > 0.0) {
			CreateTimer(time, Timer_DeleteParticles, particle);
		}

		return particle;
	}

	return -1;
}

public Action:Timer_DeleteParticles(Handle:timer, any:particle) {
	if (IsValidEntity(particle)) {

		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))	{
			AcceptEntityInput(particle, "Kill");
			RemoveEdict(particle);
		} else {
			LogError("DeleteParticles: not removing entity - not a particle '%s'", classname);
		}
	}
}


public DeleteParticle(particle) {
	if (IsValidEntity(particle)) {

		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))	{
			AcceptEntityInput(particle, "Kill");
			RemoveEdict(particle);
		} else {
			LogError("DeleteParticles: not removing entity - not a particle '%s'", classname);
		}
	}
}

public Action:Timer_UpdateSkins(Handle:timer) 
{
	new skin;
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if(g_bHasHHHModel[i] && g_bIsHHH[i])
		{
			skin = GetEntProp(g_iEntitySelf[i], Prop_Data, "m_nSkin");
			//PrintToChat(i, "skin: %i", skin);
			
			if(GetClientTeam(i) == BLUE_TEAM)
			{
				if(TF2_GetPlayerConditionFlags(i)&TF_CONDFLAG_UBERCHARGED)
				{
					if(skin != 3)
					{
						DispatchKeyValue(g_iEntitySelf[i], "skin","3");
						DispatchKeyValue(g_iEntityOthers[i], "skin","3");
					}
				}else{
					if(skin != 0)
					{
						DispatchKeyValue(g_iEntitySelf[i], "skin","0");
						DispatchKeyValue(g_iEntityOthers[i], "skin","1");
					}
				}
			}else{
				if(TF2_GetPlayerConditionFlags(i)&TF_CONDFLAG_UBERCHARGED)
				{
					if(skin != 2)
					{
						DispatchKeyValue(g_iEntitySelf[i], "skin","2");
						DispatchKeyValue(g_iEntityOthers[i], "skin","2");
					}
				}else{
					if(skin != 1)
					{
						DispatchKeyValue(g_iEntitySelf[i], "skin","1");
						DispatchKeyValue(g_iEntityOthers[i], "skin","0"); //
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}