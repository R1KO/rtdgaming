/*
* [TF2] Roll The Dice
* 
* Original Author: linux_lower
* Modded By: Fox, Kilandor, Czech
* 
* Things to remeber: MaxClients will be 32`
* 					 MaxPlayers will be 60-something
*/
#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <clientprefs>
#include <colors>
#include <tf2>
#include <sdktools>
#include <geoip>
#include <regex>
#include <adminmenu>
#include <rtd_rollinfo>
#include <rtd_trinkets>

//Plugin version is the date  :)
#define PLUGIN_VERSION 			"$Rev: 691 $" //DO NOT MODIFY $REV *$ - Commit this file to auto-update

// Include files to keep code sorted
#include "rtd/info/defines.sp"
#include "rtd/info/variables.sp"
#include "rtd/info/cvars.sp"
#include "rtd/info/precache.sp"
#include "rtd/info/downloads.sp"
#include "rtd/load_cfgs.sp"

#include "rtd/donate.sp"
#include "rtd/particles.sp"
#include "rtd/diceperks.sp"
#include "rtd/mysql_db.sp"
#include "rtd/dice.sp"
#include "rtd/commands.sp"
#include "rtd/events.sp"
#include "rtd/timers.sp"
#include "rtd/ShoppingMenu.sp"
#include "rtd/options.sp"
#include "rtd/clientaimtarget.sp"
#include "rtd/OtherMenus.sp"
#include "rtd/dicedeposit.sp"
#include "rtd/awards.sp"
#include "rtd/team_manager.sp"
#include "rtd/entityHandler.sp"
#include "rtd/damage.sp"
#include "rtd/action_button.sp"
#include "rtd/round_engine.sp"
#include "rtd/beacon.sp"
#include "rtd/trinkets/trinkets.sp"

//Rolls
#include "rtd/rollhandling.sp"

#include "rtd/rolls/slowcube.sp"
#include "rtd/rolls/bomb.sp"
#include "rtd/rolls/groovitron.sp"
#include "rtd/rolls/crap.sp"
#include "rtd/rolls/sentrybuilder.sp"
#include "rtd/rolls/medic.sp" //for all the medic rolls
#include "rtd/rolls/invisible.sp" //for all the invisible rolls
#include "rtd/rolls/soldier.sp" //for all the soldier rolls
#include "rtd/rolls/proximitystickies.sp"
#include "rtd/rolls/spider.sp"
#include "rtd/rolls/pumpkins.sp"
#include "rtd/rolls/infiammo.sp"
#include "rtd/rolls/ice.sp"
#include "rtd/rolls/RoF.sp"
#include "rtd/rolls/flame.sp"
#include "rtd/rolls/fireball.sp"
#include "rtd/rolls/ghost.sp"
#include "rtd/rolls/amplifier.sp"
#include "rtd/rolls/sandwich.sp"
#include "rtd/rolls/jumppad.sp"
#include "rtd/rolls/accelerator.sp"
#include "rtd/rolls/questionblock.sp"
#include "rtd/rolls/zombie.sp"
#include "rtd/rolls/backpack.sp"
#include "rtd/rolls/proximitymines.sp"
#include "rtd/rolls/beartrap.sp"
#include "rtd/rolls/mediray.sp"
#include "rtd/rolls/reflectshield.sp"
#include "rtd/rolls/cage.sp"
#include "rtd/rolls/critsspurt.sp"
#include "rtd/rolls/urinecloud.sp"
#include "rtd/rolls/diglett.sp"
#include "rtd/info/PlayerPosition.sp"
#include "rtd/rolls/saws.sp"
#include "rtd/rolls/cow.sp"
#include "rtd/rolls/blizzard.sp"
#include "rtd/rolls/health.sp"
#include "rtd/rolls/wings.sp"
#include "rtd/rolls/supplydrop.sp"
#include "rtd/rolls/jetpack.sp"
#include "rtd/rolls/heartsaplenty.sp"
#include "rtd/rolls/dummy.sp"
#include "rtd/rolls/classimmunity.sp"
#include "rtd/rolls/metalman.sp"
#include "rtd/rolls/yoshi.sp"
#include "rtd/rolls/instaporter.sp"
#include "rtd/rolls/snorlax.sp"
#include "rtd/rolls/doom.sp"
#include "rtd/rolls/brazier.sp"
#include "rtd/rolls/stonewall.sp"
#include "rtd/rolls/buildingshield.sp"
#include "rtd/rolls/rubberbullets.sp"
#include "rtd/rolls/angelic.sp"
#include "rtd/rolls/dynamite.sp"
#include "rtd/trinkets/trinkets_trading.sp"
#include "rtd/rolls/treasure.sp"
#include "rtd/rolls/hastycharge.sp"
#include "rtd/rolls/strengthdrain.sp"
#include "rtd/rolls/darknesscloud.sp"
#include "rtd/rolls/slicendice.sp"
#include "rtd/rolls/groundingbullet.sp"
#include "rtd/rolls/diarhia.sp"
#include "rtd/rolls/horsemann.sp"
#include "rtd/rolls/scaleclient.sp"


#include "rtd/trinkets/trinket_timers.sp"


//Perks
#include "rtd/rolls/friedchicken.sp"

public Plugin:myinfo = 
{
	name = "[TF2] Roll The Dice",
	author = "Fox",
	description = "Let's users roll for special temporary powers.",
	version = PLUGIN_VERSION,
	url = "http://www.rtdgaming.com"
}

public OnPluginStart()
{
	//Handles loading/hooking/getting values from cvars
	rtd_load_cvars();
	
	RegAdminCmd("sm_rtdadmin", Command_rtdadmin, ADMFLAG_BAN, "For Admin Menu/Commands");
	//Please leave this for convenience.  It allows me to /rtd in chat.
	RegAdminCmd("sm_rta", Command_rtdadmin, ADMFLAG_CHAT, "Mysterious command of some sort...");
	
	RegConsoleCmd("dropitem", Command_DropItem);
	RegConsoleCmd("say", Command_rtd);
	RegConsoleCmd("say_team", Command_rtd);
	
	HookEvent("teamplay_round_active", Event_RoundActive);
	HookEvent("teamplay_setup_finished",Event_Setup); 
	HookEvent("player_sapped_object", Event_PlayerSappedObject);
	HookEvent("teamplay_win_panel", Event_Teamplay_Win_Panel);
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundWin);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_changeclass", Event_PlayerChangeClass);
	HookEvent("teamplay_round_selected", Event_RoundSelected);
	HookEvent("teamplay_point_captured", Event_PointCaptured); 
	
	HookEvent("post_inventory_application", Event_Change_Loadout, EventHookMode_Post); 
	
	//Scramble Related Hooks
	HookEvent("player_team", Event_Pre_PlayerTeam, EventHookMode_Pre);
	HookEvent("player_death", Event_Pre_PlayerDeath, EventHookMode_Pre);
	HookEvent("teamplay_teambalanced_player", Event_TeamBalanced);
	
	HookEvent("player_highfive_success", EventHighFiveSuccess);
	
	
	AddCommandListener(JoinTeam_Listener, "jointeam");
	
	//----Store offsets
	g_jumpOffset = FindSendPropInfo("CTFPlayer", "m_iAirDash");
	g_cloakOffset = FindSendPropInfo("CTFPlayer", "m_flCloakMeter");
	
	m_flEnergyDrinkMeter = FindSendPropInfo("CTFPlayer", "m_flEnergyDrinkMeter");
	m_flChargeMeter = FindSendPropInfo("CTFPlayer", "m_flChargeMeter");
	
	m_iStunFlags = FindSendPropInfo("CTFPlayer","m_iStunFlags");
	m_iMovementStunAmount = FindSendPropInfo("CTFPlayer","m_iMovementStunAmount");
	m_hHealingTarget = FindSendPropInfo("CWeaponMedigun", "m_hHealingTarget");
	m_nPlayerCond = FindSendPropInfo("CTFPlayer","m_nPlayerCond");
	m_nDisguiseTeam = FindSendPropInfo("CTFPlayer","m_nDisguiseTeam");
	m_nDisguiseClass = FindSendPropInfo("CTFPlayer","m_nDisguiseClass");
	m_flMaxspeed = FindSendPropInfo("CTFPlayer", "m_flMaxspeed");
	m_bCarryingObject = FindSendPropInfo("CTFPlayer", "m_bCarryingObject");
	m_hOwnerEntity = FindSendPropOffs("CTFWearable", "m_hOwnerEntity");
	
	m_fFlags = FindSendPropOffs("CBasePlayer", "m_fFlags");
	
	m_bCarried = FindSendPropInfo("CBaseObject", "m_bCarried");
	iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	
	ResetStatus();
	
	LoadTranslations("rtd.phrases.txt");
	
	//Insta Detonate stickies
	GameConf = LoadGameConfigFile("rtd");
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(GameConf, SDKConf_Virtual, "Detonate");
	g_hDetonate = EndPrepSDKCall();
	
	//Soundhook to distort sounds
	AddNormalSoundHook(NormalSHook:sound_hook);
	
	//Groovitron Code
	BaseVelocityOffset=FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	if(BaseVelocityOffset==-1)
		SetFailState("[Groovitron] Error: Failed to find the BaseVelocity offset, aborting");		
		
	m_clrRender = FindSendPropOffs("CTFPlayer", "m_clrRender");
	
	//Team Manager Cookies
	g_cookie_timeBlocked = RegClientCookie("time blocked", "time player was blocked", CookieAccess_Private);
	g_cookie_teamIndex = RegClientCookie("team index", "index of the player's team", CookieAccess_Private);

	new String:logTimeStamp[64];
	FormatTime(logTimeStamp, sizeof(logTimeStamp), "%m_%d_%y", GetTime());
	BuildPath(Path_SM, logPath, sizeof(logPath), "logs/rtd_%s.log", logTimeStamp);
	
	ShakeID = GetUserMessageId("Shake");
	
}

public OnConfigsExecuted()
{
	//Loads the configs into values
	rtd_load_cvar_configs();
	PrintToServer("[RTD] %T", "Server_Loaded", LANG_SERVER, PLUGIN_VERSION);

	/******************
	 * On late load   *
	 ******************/
	if (lateLoaded)
	{		
		for(new i = 1; i <= MaxClients; i++) 
		{
			if (IsClientInGame(i))
			{
				Colorize(i, NORMAL);
				TF2_RemoveCond(i, 5);
				
				SDKHook(i,	SDKHook_OnTakeDamage, 	TakeDamageHook);
				
				areStatsLoaded[i] = false;
				
				resetPerkAttributes(i);
			}
		}
		
		/************************
		* Delete RTD remants    *
		*************************/
		deleteRTDEntities();
		deleteAttachedRTDEntities();
		
		lateLoaded = false;
	}
	
	/************************
	* Connect to Database   *
	*************************/
	if(!g_BCONNECTED && !rtd_classic)
		openDatabaseConnection();
	
	Item_ParseList();
	DiceDeposit_ParseList();
	Load_DicePerks();
	Load_DicePerks_ShopMenu();
	Load_Rolls();
	Process_Disabled_Rolls();
	Load_Trinkets();
}


public OnMapStart()
{	
	RTDPrecache();
	RTDDownloads();
	ResetStatus();
	Load_Rolls();
	Process_Disabled_Rolls();
	Load_Trinkets();
	
	//Timers galore
	
	CreateTimer(1.0,  	Timer_ShowScore, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.0,  	Timer_ShowInfo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	CreateTimer(0.1,  	UberchargerTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1,  	HastyCharge_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	CreateTimer(0.2,  	GenericTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2,  	TrinketsTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	CreateTimer(60.0, 	CreditsTimer,_, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.5,  	CrouchInvisTimer,_, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(180.0, 	SaveStats_Timer,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1,  	RightClick_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	timeOfLastDiceSpawn = GetTime();
	CreateTimer(1.0,  	SpawnDice_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	//Spider's timer that determines whether player is AFK
	CreateTimer(1.0, 	isPlayerAFK_Timer,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	/////////////////////////////////////////////
	//Client Aim Target Datapack               //
	/////////////////////////////////////////////
	new Handle:aimTargetDataPack;
	CreateDataTimer(0.2, AimTarget_Timer, aimTargetDataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	//following keeps track of when was the last time an annotation was shown to a player
	//an anotation lasts 2 seconds and then another one can be sent to the client
	//Having annotations only appear every 2s reduces "lag"
	for (new i = 1; i < MaxClients ; i++)
	{
		WritePackCell(aimTargetDataPack, 0); //PackPosition(0) Client 1
	}
	
	
	CreateTimer(10.0,  	Timer_RunRTDonBots, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	CreateTimer(10.0,  	Timer_Check_DatabaseOnClient, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	//Load the dice spawn points
	Item_ParseList();
	DiceDeposit_ParseList();
	Load_DicePerks();
	Load_DicePerks_ShopMenu();
	Load_DamageFilters();
	
	currentRound = 1;
}

//This is only Triggerd By SM Unloading, and or Reloading a plugin
public OnPluginEnd()
{
	//Save everythin when plugin ends
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			saveStats(i);
			DeleteParticle(i, "all");
		}
	}
	
	deleteRTDEntities();
	deleteAttachedRTDEntities();
}


public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (ROFMult[client] != 0.0)
	{
		CreateTimer(0.0, SetROFOnWeapon, client);
	}
	
	return Plugin_Continue;
}


public Parse_Chat_Triggers(const String:strTriggers[])
{
	g_iTriggers = ExplodeString(strTriggers, ",", chatTriggers, MAX_CHAT_TRIGGERS, MAX_CHAT_TRIGGER_LENGTH);
}

public Parse_Chat_CreditTriggers(const String:strTriggers[])
{
	g_iCreditTriggers = ExplodeString(strTriggers, ",", chatCreditTriggers, MAX_CHAT_TRIGGERS, MAX_CHAT_TRIGGER_LENGTH);
}

public ResetStatus()
{
	for(new i=1; i<MaxClients+1; i++)
	{
		CleanPlayer(i);
	}
}

Action:PrintToChatSome(String:message[], client=-1, showToEveryone=1, allowedTeam=0)
{	
	//LogToFile(logPath,"%s",message);
	for(new i=1; i <= MaxClients; i++)
	{
		// Check to make sure the player is on the same team
		if(showToEveryone)
		{
			if(IsClientInGame(i) && RTDOptions[i][2] == 0 && client)
				SayText2One(i, client, message);
			else if(IsClientInGame(i) && RTDOptions[i][2] == 0)
				PrintToChat(i,message);
		}else{
			if(IsClientInGame(i))
			{
				if(GetClientTeam(i) == allowedTeam)
				{
					if(RTDOptions[i][2] == 0 && client)
						SayText2One(i, client, message);
					else if(RTDOptions[i][2] == 0)
						PrintToChat(i,message);
				}
			}
		}
	}
}

stock SayText2(author_index , const String:message[] ) 
{
    new Handle:buffer = StartMessageAll("SayText2");
    if (buffer != INVALID_HANDLE) {
        BfWriteByte(buffer, author_index);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
}

stock SayText2One( client_index , author_index , const String:message[] ) 
{
    new Handle:buffer = StartMessageOne("SayText2", client_index);
    if (buffer != INVALID_HANDLE) {
        BfWriteByte(buffer, author_index);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
} 

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(client_rolls[client][AWARD_G_STONEWALL][0])
	{
		//adjust the gravity
		if(client_rolls[client][AWARD_G_STONEWALL][5] >= GetTime())
		{
			if(buttons & IN_JUMP)
				SetEntityGravity(client, 1.2);
		}
	}
	
	if(client_rolls[client][AWARD_G_JETPACK][0])
	{
		if(buttons & IN_JUMP)
		{
			if(!(GetEntityFlags(client) & FL_ONGROUND))
			{
				Jetpack_Player(client, angles, buttons);
				client_rolls[client][AWARD_G_JETPACK][5] = 1;
			}else{
				client_rolls[client][AWARD_G_JETPACK][5] = 0;
			}
		}else{
			client_rolls[client][AWARD_G_JETPACK][5] = 0;
		}
		
		//prevent trinket override
		//return Plugin_Continue;
	}
	
	if(RTD_TrinketActive[client][TRINKET_SUPERJUMP])
	{
		if(buttons & IN_JUMP)
		{
			if(TF2_GetPlayerClass(client) != TFClass_Scout && wasJumping[client] == 0)
			{	
				if((GetEntityFlags(client) & FL_ONGROUND))
				{
					RTD_TrinketMisc[client][TRINKET_SUPERJUMP] = 1;
					wasJumping[client] = 1;
					
					CreateTimer(0.0, recordVelocity, GetClientUserId(client));
				}else
				{
					if(RTD_TrinketMisc[client][TRINKET_SUPERJUMP] == 1 && wasJumping[client] == 0)
						CreateTimer(0.0, doSuperJump, GetClientUserId(client));
				}
			}
		}else{
			wasJumping[client] = 0;
			
			if(GetEntityFlags(client) & FL_ONGROUND)
				RTD_TrinketMisc[client][TRINKET_SUPERJUMP] = 0;
		}
	}
	
	if(RTD_TrinketActive[client][TRINKET_AIRDASH])
	{
		if(buttons & IN_JUMP)
		{
			if(TF2_GetPlayerClass(client) != TFClass_Scout && wasJumping[client] == 0)
			{	
				if((GetEntityFlags(client) & FL_ONGROUND))
				{
					RTD_TrinketMisc[client][TRINKET_AIRDASH] = 1;
					wasJumping[client] = 1;
					//CreateTimer(0.0, doAirDash, GetClientUserId(client));
				}else
				{
					if(RTD_TrinketMisc[client][TRINKET_AIRDASH] == 1 && wasJumping[client] == 0)
						CreateTimer(0.0, doAirDash, GetClientUserId(client));
				}
			}
		}else{
			wasJumping[client] = 0;
			
			if(GetEntityFlags(client) & FL_ONGROUND)
				RTD_TrinketMisc[client][TRINKET_AIRDASH] = 0;
		}
	}
	
	return Plugin_Continue;
}

//Just a convenience method
stock TF2_DoCond(client, cond, add)
{
	if (add)
		TF2_AddCond(client, cond);
	else
		TF2_RemoveCond(client, cond);
}

stock TF2_AddCond(client, cond) 
{
	new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar), flags = GetConVarFlags(cvar);
	if(!enabled) {
		SetConVarFlags(cvar, flags^FCVAR_NOTIFY^FCVAR_REPLICATED);
		SetConVarBool(cvar, true);
	}
	FakeClientCommand(client, "addcond %i", cond);
	//FakeClientCommand(client, "isLoser");
	if(!enabled) {
		SetConVarBool(cvar, false);
		SetConVarFlags(cvar, flags);
	}
}

stock TF2_RemoveCond(client, cond) 
{
    new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar), flags = GetConVarFlags(cvar);
    if(!enabled) 
	{
        SetConVarFlags(cvar, flags^FCVAR_NOTIFY^FCVAR_REPLICATED);
        SetConVarBool(cvar, true);
    }
    FakeClientCommand(client, "removecond %i", cond);
    if(!enabled) 
	{
        SetConVarBool(cvar, false);
        SetConVarFlags(cvar, flags);
    }
}  

public bool:TeleTraceFilter(ent, contentMask)
{
   return (ent == g_FilteredEntity) ? false : true;
}

public Float:GetClientBaseSpeed(client)
{
	new Float:speed;
	new TFClassType:class = TF2_GetPlayerClass(client);
	new cond = GetEntData(client, m_nPlayerCond);
	
	new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if(!IsValidEntity(iWeapon) || iWeapon < 1 || iWeapon > 2048)
	{
		//This will be triggered if the player does a civilian glitch
		//PrintToChatAll("Invalid Active Weapon Index!");
		return 200.0;
	}
	
	//new String:redbulltext[128];
	new String:classname[64];
	GetEdictClassname(iWeapon, classname, 64);
	
	//hmm an edict classname not containing tf_weapon was returned
	//how'd that happen?
	if(StrContains(classname, "tf_weapon", false) == -1)
		return 200.0;
	
	new itemDefinition = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
	
	switch(class)
	{
		case TFClass_Scout:
		{
			speed = 400.0;
		}
			
		case TFClass_Sniper:
		{
			if(TF2_IsPlayerInCondition(client, TFCond_Zoomed))
			{
				if(StrEqual(classname, "tf_weapon_compound_bow"))
				speed = 136.0;
				
				if(StrEqual(classname, "tf_weapon_sniperrifle"))
					speed = 80.0;
				
				//the Cozy Camper
				if(isPlayerHoliding_NonSlotItem(client, 642))
					speed = 32.0;
				
			}else{
				speed = 300.0;
			}
		}
		
		case TFClass_Soldier:
		{
			speed = 240.0;
			
			//The Equalizer
			//the speed of the wielding Soldier is also inversely proportional to his health
			if(itemDefinition == 128)
			{
				new Float: healthPercentage = float(GetClientHealth(client)) / float(clientMaxHealth[client]);
				
				if(healthPercentage >= 0.80)
				{
					speed *= 1.0;
				}else if(healthPercentage >= 0.60)
				{
					speed *= 1.08;
				}else if(healthPercentage >= 0.40)
				{
					speed *= 1.16;
				}else if(healthPercentage >= 0.20)
				{
					speed *= 1.32;
				}else{
					speed *= 1.48;
				}
			}
		}
		
		case TFClass_DemoMan:
		{
			speed = 280.0;
			
			new decapitations = GetEntProp(client, Prop_Send, "m_iDecapitations");
			
			switch(decapitations)
			{
				case 1:
					speed *= 1.08;
				
				case 2:
					speed *= 1.16;
				
				case 3:
					speed *= 1.24;
			}
			
			if(decapitations > 3)
				speed *= 1.31;
			
			//The Scotsman's Skullcutter
			if(itemDefinition == 172)
				speed *= 0.85;
		}
		
		case TFClass_Medic:
		{
			speed = 320.0;
		}
		
		case TFClass_Heavy:
		{
			//Need condition for Buffalo Steak Sandvich  which would be speed *= 1.74
			speed = 230.0;
			
			if(cond & 1)
			{
				//cond = 1
				//spinning minigun
				
				//regular minigun
				speed = 110.0;
				
				//The Brass Beast
				if (itemDefinition == 312 && GetClientButtons(client) & IN_ATTACK2)
					speed = 44.0;
			}else{
				//Gloves of Running Urgently
				if (itemDefinition == 239)
					speed *= 1.3;
			}
		}
		
		case TFClass_Pyro:
		{
			speed = 300.0;
			
			//The Gas Jockey's Gear 
			if(isPlayerHolding_UniqueWeapon(client, 215) && isPlayerHolding_UniqueWeapon(client, 214))
				speed *= 1.10;
		}
		
		case TFClass_Spy:
		{
			speed = 300.0;
			
			new disguiseClass  = GetEntData(client, m_nDisguiseClass);
			
			switch(disguiseClass)
			{	
				//soldier
				case 3:
					speed *= 0.80;
				
				//demoman
				case 4:
					speed *= 0.90;
					
				//heavy
				case 6:
					speed *= 0.77;
			}
		}
		
		case TFClass_Engineer:
		{
			speed = 300.0;
			
			if(GetEntData(client, m_bCarryingObject))
				speed *= 0.75;
		}
	}
	
	//Format(redbulltext, sizeof(redbulltext), "Speed: %i", RoundFloat(speed));
	//centerHudText(client, redbulltext, 0.0, 1.0, HudMsg3, 0.13);
	
	return speed;
}

stock ResetClientSpeed(client, Float:speed=-1.0)
{
	new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsValidEntity(iWeapon)) 
	{
		if (speed < 0)
			SetEntDataFloat(client, m_flMaxspeed, GetClientBaseSpeed(client));
		else
			SetEntDataFloat(client, m_flMaxspeed, speed);
	}
}

public Float:getStartPos(String:message[])
{
	new Float:startPos;
	startPos = (100.0 -  float(strlen(message)) ) / 2.0;
	startPos *= 0.01;
	
	return startPos;
}

public centerHudText(client, String:message[], Float:delay, Float:liveTime, channel, Float:yPos)
{
	new Handle:dataPackHandle;
	CreateDataTimer(delay, customHudMessage, dataPackHandle, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE); //4.0 is the delay
	
	WritePackCell(dataPackHandle, client);
	WritePackFloat(dataPackHandle, liveTime); // Amount of time the message should stay on the screen
	WritePackString(dataPackHandle, message);//The message the user will see
	WritePackCell(dataPackHandle, channel); //the channel that the message will be displayed on
	WritePackFloat(dataPackHandle, yPos); //y-Position of message
}
	
public Action:customHudMessage(Handle:timer, Handle:dataPackHandle)
{
	//Centers and displays a HudText message to a client
	new String:message[128];
	
	ResetPack(dataPackHandle);
	new client = ReadPackCell(dataPackHandle);
	new Float:time = ReadPackFloat(dataPackHandle);
	ReadPackString(dataPackHandle,message,sizeof(message));
	new channel = ReadPackCell(dataPackHandle);
	new Float:yPos = ReadPackFloat(dataPackHandle);
	
	if (IsClientInGame(client))
	{
		//-1.0 significes center
		SetHudTextParams(-1.0, yPos, time, 250, 250, 210, 255);
		ShowHudText(client, channel, message);
	}
	
	return Plugin_Handled;
}

tf2_game_text(const String:message[], Float:timeToLive, activeDice)
{
	new Text_Ent = CreateEntityByName("game_text_tf");
	DispatchKeyValue(Text_Ent,"message",message);
	DispatchKeyValue(Text_Ent,"display_to_team","0");
	DispatchKeyValue(Text_Ent,"icon", "leaderboard_dominated");
	DispatchKeyValue(Text_Ent,"targetname","game_text1");
	DispatchKeyValue(Text_Ent,"background","0");
	DispatchSpawn(Text_Ent);

	AcceptEntityInput(Text_Ent, "Display", Text_Ent, Text_Ent);

	killEntityIn(Text_Ent, timeToLive);
	
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, Timer_Game_Text, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, Text_Ent); //0   client
	WritePackCell(dataPackHandle, activeDice); //8   client
	
}

public Action:Timer_Game_Text(Handle:timer, Handle:dataPackHandle)
{
	ResetPack(dataPackHandle);
	new Text_Ent = ReadPackCell(dataPackHandle);
	new amountofdice = ReadPackCell(dataPackHandle);
	
	if(!IsValidEntity(Text_Ent))
		return Plugin_Stop;
	
	//stop this message once someone has found a dice
	//this prevents the timers from overlapping one another
	if(diceOnMap != amountofdice)
	{
		killEntityIn(Text_Ent, 0.1);
		return Plugin_Stop;
	}
	
	AcceptEntityInput(Text_Ent, "Display", Text_Ent, Text_Ent);
	
	return Plugin_Continue;
}


public playersInServer()
{
	new totPlayers;
	for(new i=1; i <= MaxClients; i++)
	{
		// Check to make sure the player is on the same team
		if(IsClientInGame(i))
		{
			totPlayers++;
		}
	}
	return totPlayers;
}

//TeamManager
public OnClientCookiesCached(client)
{
	if (!IsClientConnected(client) || IsFakeClient(client))
		return;
	
	new String:tempStr[32];

	GetClientCookie(client, g_cookie_timeBlocked, tempStr, sizeof(tempStr));
	g_BlockTime[client] = StringToInt(tempStr);
	
	GetClientCookie(client, g_cookie_teamIndex, tempStr, sizeof(tempStr));
	g_BlockTeam[client] = StringToInt(tempStr);
	
}

public isPlayerHoliding_NonSlotItem(client, m_iItemDefinitionIndex)
{
	// Check items that dont take a slot in players inventory
	//primarily used for weapons such as the razorback
	new edict;
	
	while((edict = FindEntityByClassname(edict, "tf_wearable")) != -1)
	{
		if (GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex") == m_iItemDefinitionIndex)
		{
			if(GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
				return true;
		}
	}
	
	return false;
}

public isPlayerHolding_UniqueWeapon(client, m_iItemDefinitionIndex)
{
	//for weapons that are removed, only one is the shield so far
	if(m_iItemDefinitionIndex == 131 && GetEntProp(client, Prop_Send, "m_bShieldEquipped"))
		return true;
	
	new iWeapon ;
	
	for (new islot = 0; islot < 11; islot++) 
	{
		iWeapon = GetPlayerWeaponSlot(client, islot);
		if (IsValidEntity(iWeapon))
		{
			//PrintToChat(client, "%i", GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"));
			if (GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex") == m_iItemDefinitionIndex)
				return true;
		}
	}
	
	return false;
}

public isPlayerHolding_UniqueWeapon_2(client, m_iItemDefinitionIndex)
{
	//for weapons that are removed, only one is the shield so far
	if(m_iItemDefinitionIndex == 131 && GetEntProp(client, Prop_Send, "m_bShieldEquipped"))
		return true;
	
	new iWeapon ;
	
	for (new islot = 0; islot < 11; islot++) 
	{
		iWeapon = GetPlayerWeaponSlot(client, islot);
		if (IsValidEntity(iWeapon))
		{
			if (GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex") == m_iItemDefinitionIndex)
				return iWeapon;
		}
	}
	
	return -1;
}

public isActiveWeapon(client, m_iItemDefinitionIndex)
{
	new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if(IsValidEntity(iWeapon))
	{
		new itemDefinition = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
		if(itemDefinition == m_iItemDefinitionIndex)
			return true;
	}
	
	return false;
}

ShowWhatIsMOTD(client, String:lookingFor[])
{
	new String:rollTriggers[9][32];
	
	if (StrEqual(lookingFor, "perk", false) || StrEqual(lookingFor, "perks", false))
	{
		new String:url[128];
		Format(url, sizeof(url), "http://wiki.rtdgaming.com/wiki/Dice_Perks");
		ShowMOTDPanel(client, "Something", url, MOTDPANEL_TYPE_URL);
		return;
	}
	
	if (StrEqual(lookingFor, "treasure", false) || StrEqual(lookingFor, "treasurechest", false) || StrEqual(lookingFor, "treasure chest", false))
	{
		new String:url[128];
		Format(url, sizeof(url), "http://wiki.rtdgaming.com/wiki/Treasure");
		ShowMOTDPanel(client, "Something", url, MOTDPANEL_TYPE_URL);
		return;
	}
	
	if (StrEqual(lookingFor, "gift", false))
	{
		new String:url[128];
		Format(url, sizeof(url), "http://wiki.rtdgaming.com/wiki/Gift");
		ShowMOTDPanel(client, "Something", url, MOTDPANEL_TYPE_URL);
		return;
	}
	
	if (StrEqual(lookingFor, "dice", false))
	{
		new String:url[128];
		Format(url, sizeof(url), "http://wiki.rtdgaming.com/wiki/Dice");
		ShowMOTDPanel(client, "Something", url, MOTDPANEL_TYPE_URL);
		return;
	}
	
	if (StrEqual(lookingFor, "present", false) || StrEqual(lookingFor, "presents", false))
	{
		new String:url[128];
		Format(url, sizeof(url), "http://wiki.rtdgaming.com/wiki/Presents");
		ShowMOTDPanel(client, "Something", url, MOTDPANEL_TYPE_URL);
		return;
	}
	
	if (StrEqual(lookingFor, "lastroll", false) || StrEqual(lookingFor, "last", false))
	{
		if(lastRoll[client] != 0)
		{
			new String:url[128];
			Format(url, sizeof(url), "http://wiki.rtdgaming.com/wiki/%s", roll_Text[lastRoll[client]]);
			ShowMOTDPanel(client, "Something", url, MOTDPANEL_TYPE_URL);
		}
		return;
	}
	
	if (StrEqual(lookingFor, "trinket", false) || StrEqual(lookingFor, "trinkets", false))
	{
		new String:url[128];
		Format(url, sizeof(url), "http://wiki.rtdgaming.com/wiki/Trinket");
		ShowMOTDPanel(client, "Something", url, MOTDPANEL_TYPE_URL);
		
		return;
	}
	
	if (StrEqual(lookingFor, "unusual", false) || StrEqual(lookingFor, "unusuals", false))
	{
		new String:url[128];
		Format(url, sizeof(url), "http://wiki.rtdgaming.com/wiki/Unusual_Rolls");
		ShowMOTDPanel(client, "Something", url, MOTDPANEL_TYPE_URL);
		
		return;
	}
	
	for(new i=1; i <= totalRolls; i ++)
	{
		if (StrEqual(lookingFor, roll_Text[i], false))
		{
			new String:url[128];
			Format(url, sizeof(url), "http://wiki.rtdgaming.com/wiki/%s", roll_Text[i]);
			ShowMOTDPanel(client, "Something", url, MOTDPANEL_TYPE_URL);
			return;
		}
		
		ExplodeString(roll_QuickBuy[i], ":", rollTriggers, 15, 32);
		
		for(new j=1; j <= roll_amountTriggers[i]; j ++)
		{
			if (StrEqual(lookingFor, rollTriggers[j-1], false))
			{
				new String:url[128];
				Format(url, sizeof(url), "http://wiki.rtdgaming.com/wiki/%s", roll_Text[i]);
				ShowMOTDPanel(client, "Something", url, MOTDPANEL_TYPE_URL);
				return;
			}
		}
	}
	
	PrintToChat(client, "%s Not found!", lookingFor);
}

showStatsPage(client)
{
	new String:clsteamId[MAX_LINE_WIDTH];
	new String:url[128];
	GetClientAuthString(client, clsteamId, sizeof(clsteamId));
	
	Format(url, sizeof(url), "http://stats.rtdgaming.com/player?&s=rarity&w=asc&q=%s", clsteamId);
	ShowMOTDPanel(client, "Something", url, MOTDPANEL_TYPE_URL);
	
}

stock bool:CheckAdminFlagsByString(client, const String:flagString[])
{
	if (!IsClientInGame(client))
		return false;
	
	if(!StrEqual(flagString, ""))
	{
		new iFlags = ReadFlagString(flagString);
		return bool:(GetUserFlagBits(client) & iFlags);
	}
	
	return bool:(GetUserFlagBits(client) & ADMFLAG_ROOT);
}

public bool:isVisibileCheck(client, entity)
{
	/////////////////////////////////////////////////////////////
	//Draws 2 tracerays from the entity to the client and      //
	//from the client to the entity to see if both can see     //
	//each other.                                              //
	//                                                         //
	//foundRange: the "fuzziness" or variation between each    //
	//  collision that is still allowable                      //
	//                                                         //
	/////////////////////////////////////////////////////////////
	
	//Do dummy checks
	if(!IsValidEntity(entity))
		return false;
	
	if(!IsValidClient(client))
		return false;
	
	new Float:foundRange;
	new Float:traceEndPos[3];
	
	new Float:entityPos[3];
	new Float:clientEyeOrigin[3];
	
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityPos);
	//move it up due to the fact that this position is always at the bottom close to the floor
	entityPos[2] += 30.0;
	
	GetClientEyePosition(client, clientEyeOrigin);
	
	//begin our trace from the entity to the client
	new Handle:Trace = TR_TraceRayFilterEx(entityPos, clientEyeOrigin, MASK_NPCWORLDSTATIC, RayType_EndPoint, TraceFilterAll, entity);
	TR_GetEndPosition(traceEndPos, Trace);
	CloseHandle(Trace);
	
	foundRange = GetVectorDistance(clientEyeOrigin,traceEndPos);
	
	//Was the trace close to the player? If not the let's shoot from the player
	//back to the Amplifier. This makes sure that none of the entites saw each other
	if(foundRange > 35.0)
	{
		Trace = TR_TraceRayFilterEx(clientEyeOrigin, entityPos, MASK_NPCWORLDSTATIC, RayType_EndPoint, TraceFilterAll, client);
		TR_GetEndPosition(traceEndPos, Trace);
		CloseHandle(Trace);
		
		//did the player see a building?
		foundRange = GetVectorDistance(entityPos, traceEndPos);
	}
	
	
	if(foundRange < 35.0)
		return true;
	
	return false;
}

public OnGameFrame()
{
	
}

public bool:isUsingHud4(client)
{	
	//that extra condition is so we don't override the text
	if(RTD_TrinketActive[client][TRINKET_SUPERJUMP])
	{
		if(RTD_TrinketMisc_02[client][TRINKET_SUPERJUMP] + 3 > GetTime())
		{
			//+2 is delay
			return true;
		}
	}
	
	return false;
}	