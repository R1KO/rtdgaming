/*
* Prop Bonus Round (TF2) 
* Author(s): retsam
* File: prop_bonus_round.sp
* Description: Turns the losing team into random props during bonus round!
*
* Credits to: strontiumdog for the idea based off his DODS version.
* Credits to: Antithasys for SMC Parser/SM auto-cmds code and much help!
* 
* 0.5 - Changed deletion code again(Crash issues fixed?). Fixed couple potential issues related to plugin being disabled.
* 0.4.1 - Changed the prop deletion code a bit. 
* 0.4 - Removed sm_forcethird cvar, forgot losing team in TF2 is already put into thirdperson. Changed IsValidEdict to IsValidEntity(possible crash issue?). Added couple more models.
* 0.3 - Added admin command for turning players into props. Moved some stuff around.
* 0.2	- Added admin only cvar and flag.  Added a log debug cvar. Put in a couple checks related to model stuff. 
* 0.1	- Initial release. 
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#include <tf2_stocks>
#include <sdkhooks>

/*
public Plugin:myinfo = 
{
	name = "Prop Bonus Round",
	author = "retsam",
	description = "Turns the losing team into random props during bonus round!",
	version = PLUGIN_VERSION,
	url = "www.multiclangaming.net"
}
*/

public PropOnMapStart()
{
	//Process the models data file and make sure it exists. If not, create default.
	ProcessConfigFile();

	//Precache all models and names.
	decl String:sPath[100], String:sName[128];
	for(new i = 0; i < GetArraySize(g_hModelNames); i++)
	{
		GetArrayString(g_hModelPaths, i, sPath, sizeof(sPath));
		GetArrayString(g_hModelNames, i, sName, sizeof(sName));
		PrecacheModel(sPath, true);
		//PrintToServer("Precached: %s - %s", sName, sPath);
	} 
	
	PrecacheModel("models/gibs/scanner_gib01.mdl", true);
	PrecacheModel("models/gibs/scanner_gib02.mdl", true);
	PrecacheModel("models/gibs/scanner_gib03.mdl", true);
	PrecacheModel("models/gibs/scanner_gib04.mdl", true);
	PrecacheModel("models/gibs/scanner_gib05.mdl", true);
	
	PrecacheModel("models/props_2fort/gibs/miningcrate001_break01.mdl", true);
	PrecacheModel("models/props_2fort/gibs/miningcrate001_chunk01.mdl", true);
	PrecacheModel("models/props_2fort/gibs/miningcrate001_chunk02.mdl", true);
	PrecacheModel("models/props_2fort/gibs/miningcrate001_chunk03.mdl", true);
	PrecacheModel("models/props_2fort/gibs/miningcrate001_chunk04.mdl", true);
	PrecacheModel("models/props_2fort/gibs/miningcrate001_chunk05.mdl", true);
	PrecacheModel("models/props_2fort/gibs/miningcrate001_chunk06.mdl", true);	

	CreateTimer(0.1,  	UpdatePropAlpha, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	g_oFOV = FindSendPropOffs("CBasePlayer", "m_iFOV");
	g_oDefFOV = FindSendPropOffs("CBasePlayer", "m_iDefaultFOV");
}

public CreatePropPlayer(client)
{
	new rndNum;
	new String:sPath[PLATFORM_MAX_PATH], String:sName[128];
	new iTeam = GetClientTeam(client);
	
	if(g_iPlayerModelIndex[client] == -1)
		g_iPlayerModelIndex[client] = GetRandomInt(0, g_iArraySize);
	
	GetArrayString(g_hModelNames, g_iPlayerModelIndex[client], sName, sizeof(sName));
	GetArrayString(g_hModelPaths, g_iPlayerModelIndex[client], sPath, sizeof(sPath));
	
	
	g_PropModel[client][0] = CreateEntityByName("prop_dynamic_override");
	if(g_PropModel[client][0] == -1)
	{
		ReplyToCommand(client, "Failed to create entity!");
		LogToFile(logPath,"[PB] %i Failed to create entity!", client);
		return;
	}
	
	UsingProp[client] = 1;
	decl String:sPlayername[64];
	Format(sPlayername, sizeof(sPlayername), "target%i", client);
	DispatchKeyValue(client, "targetname", sPlayername);
	
	if(IsValidEntity(g_PropModel[client][0]))
	{
		//name the prop
		decl String:sPropName[64];
		Format(sPropName, sizeof(sPropName), "everyoneprop%i", g_PropModel[client][0]);
		DispatchKeyValue(g_PropModel[client][0], "targetname", sPropName);
		DispatchKeyValue(g_PropModel[client][0],"model", sPath);
		
		DispatchKeyValue(g_PropModel[client][0], "disableshadows", "1");
		DispatchKeyValue(g_PropModel[client][0], "solid", "0");
		SetEntityMoveType(g_PropModel[client][0], MOVETYPE_NOCLIP);
		DispatchSpawn(g_PropModel[client][0]);			
		
		decl Float:origin[3], Float:angles[3];
		GetClientAbsOrigin(client, origin);
		GetClientAbsAngles(client, angles);
		
		origin[2] += 1.0;
		if(StrEqual(sName, "Trashcan") || StrEqual(sName, "Weather Vane") || StrEqual(sName, "Wood Barrel") || StrEqual(sName, "Wood Pallet") )
		{
			origin[2] += 29.0;
		}
		
		if(StrEqual(sName, "Combine Scanner"))
		{
			origin[2] += 59.0;
		}
		
		if( StrEqual(sName, "Bomb Cart"))
		{
			origin[2] += 30.0;
		}
		
		if(StrEqual(sName, "Seagull"))
		{
			origin[2] += 56.0;
		}
		
		TeleportEntity(g_PropModel[client][0], origin, angles, NULL_VECTOR);					
		
		SetVariantString(sPlayername);
		AcceptEntityInput(g_PropModel[client][0], "SetParent", g_PropModel[client][0], g_PropModel[client][0], 0);
		
		SetEntPropEnt(g_PropModel[client][0], Prop_Send, "m_hOwnerEntity", client);
		
		Colorize(client, INVIS);
		InvisibleHideFixes(client, TF2_GetPlayerClass(client), 1);
		
		
		//Print Model name info to client
		PrintCenterText(client, "You are a %s!", sName);
		if(g_thirdpersonCvar == 1)
		{
			PrintToChat(client,"\x01You are disguised as a \x04%s\x01", sName);
		}
		else
		{
			PrintToChat(client,"\x01You are disguised as a \x04%s\x01 Go hide!", sName);
		}
		
		SetEntProp(g_PropModel[client][0], Prop_Data, "m_iMaxHealth", 691);
		SetEntProp(g_PropModel[client][0], Prop_Data, "m_iHealth", 691);
		
		SetVariantString("idle");
		AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
		
		if (StrEqual(sName, "Spider"))
		{
			SetVariantString("walk");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
		}
		
		if (StrEqual(sName, "Bomb"))
		{
			new particle = CreateEntityByName("info_particle_system");
			if (IsValidEdict(particle))
			{
				origin[2] += 21.0;
				TeleportEntity(particle, origin, angles, NULL_VECTOR);	
				
				DispatchKeyValue(particle, "targetname", "tf2particle");
				DispatchKeyValue(particle, "parentname", sPropName);
				DispatchKeyValue(particle, "effect_name", "candle_light1");
				DispatchSpawn(particle);
				
				SetVariantString(sPropName);
				AcceptEntityInput(particle, "SetParent", particle, particle, 0);
				
				ActivateEntity(particle);
				AcceptEntityInput(particle, "start");
			}
				
			particle = CreateEntityByName("info_particle_system");
			if (IsValidEdict(particle))
			{
				origin[2] -= 5.0;
				
				TeleportEntity(particle, origin, angles, NULL_VECTOR);	
				
				DispatchKeyValue(particle, "targetname", "tf2particle");
				DispatchKeyValue(particle, "parentname", sPropName);
				if(iTeam == BLUE_TEAM)
				{
					DispatchKeyValue(particle, "effect_name", "critical_pipe_blue");
				}else{
					DispatchKeyValue(particle, "effect_name", "critical_pipe_red");
				}
				DispatchSpawn(particle);
				
				SetVariantString(sPropName);
				AcceptEntityInput(particle, "SetParent", particle, particle, 0);
					
				ActivateEntity(particle);
				AcceptEntityInput(particle, "start");
			}
		}
		
		if (StrEqual(sName, "Dispenser"))
		{
			rndNum = GetRandomInt(0, 1);
			if(rndNum == 0)
			{
				DispatchKeyValue(g_PropModel[client][0], "skin","0"); 
			}else{
				DispatchKeyValue(g_PropModel[client][0], "skin","1"); 
			}
		}
		
		if (StrEqual(sName, "Sticky Bomb"))
		{
			rndNum = GetRandomInt(0, 1);
			if(rndNum == 0)
			{
				DispatchKeyValue(g_PropModel[client][0], "skin","0"); 
			}else{
				DispatchKeyValue(g_PropModel[client][0], "skin","1"); 
			}
		}
		
		if (StrEqual(sName, "Seagull"))
		{
			SetVariantString("fly");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
		}
		
		if (StrEqual(sName, "Alyx"))
		{
			SetVariantString("Crouch_walk_all");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
		}
		
		if (StrEqual(sName, "Headcrab"))
		{
			SetVariantString("hopleft");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
		}
		
		if (StrEqual(sName, "Dog"))
		{
			SetVariantString("pound");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
		}
		
		if (StrEqual(sName, "Antlion"))
		{
			SetVariantString("jump_start");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
		}
		
		SetEntityRenderMode(g_PropModel[client][0], RENDER_TRANSCOLOR);
		SetEntityRenderColor(g_PropModel[client][0], 255, 255, 255, 255);
		
		//if(transparent)
		CreateOtherPropPlayer(client, sPlayername, sPath, sName,rndNum);
	}
	else
	{
		ReplyToCommand(client, "Entity not valid, failed to create entity!");
		LogToFile(logPath,"[PB] %i Entity not valid, failed to create entity!", client);
	}
}

public CreateOtherPropPlayer(client, String:sPlayername[], String:sPath[], String:sName[],rndNum)
{
	new iTeam = GetClientTeam(client);
	//new otherProp;
	
	g_PropModel[client][1] = CreateEntityByName("prop_dynamic_override");
	if(g_PropModel[client][1] == -1)
	{
		ReplyToCommand(client, "Failed to create entity!");
		LogToFile(logPath,"[PB] %i Failed to create entity!", client);
		return;
	}
	
	if(IsValidEntity(g_PropModel[client][1]))
	{
		//this is seen by ONLY the client
		//SDKHook(g_PropModel[client][1],	SDKHook_SetTransmit, 	TransmitHook);
		
		//name the prop
		decl String:sOtherPropName[64];
		Format(sOtherPropName, sizeof(sOtherPropName), "clientonlyprop%i", g_PropModel[client][1]);
		DispatchKeyValue(g_PropModel[client][1], "targetname", sOtherPropName);
		DispatchKeyValue(g_PropModel[client][1],"model", sPath);
		
		DispatchKeyValue(g_PropModel[client][1], "disableshadows", "1");
		DispatchKeyValue(g_PropModel[client][1], "solid", "0");
		SetEntityMoveType(g_PropModel[client][1], MOVETYPE_NOCLIP);
		DispatchSpawn(g_PropModel[client][1]);			
		
		decl Float:origin[3], Float:angles[3];
		GetClientAbsOrigin(client, origin);
		GetClientAbsAngles(client, angles);
		
		origin[2] += 1.0;
		if(StrEqual(sName, "Trashcan") || StrEqual(sName, "Weather Vane") || StrEqual(sName, "Wood Barrel") || StrEqual(sName, "Wood Pallet"))
		{
			origin[2] += 29.0;
		}
		
		if(StrEqual(sName, "Combine Scanner"))
		{
			origin[2] += 59.0;
		}
		
		if(StrEqual(sName, "Seagull"))
		{
			origin[2] += 56.0;
		}
		
		if( StrEqual(sName, "Bomb Cart"))
		{
			origin[2] += 30.0;
		}
		
		TeleportEntity(g_PropModel[client][1], origin, angles, NULL_VECTOR);					
		
		SetVariantString(sPlayername);
		AcceptEntityInput(g_PropModel[client][1], "SetParent", g_PropModel[client][1], g_PropModel[client][1], 0);
		
		SetEntPropEnt(g_PropModel[client][1], Prop_Send, "m_hOwnerEntity", client);
		
		SetEntProp(g_PropModel[client][1], Prop_Data, "m_iMaxHealth", 691);
		SetEntProp(g_PropModel[client][1], Prop_Data, "m_iHealth", 691);
		
		SetVariantString("idle");
		AcceptEntityInput(g_PropModel[client][1], "SetAnimation", -1, -1, 0);
		
		if (StrEqual(sName, "Spider"))
		{
			SetVariantString("walk");
			AcceptEntityInput(g_PropModel[client][1], "SetAnimation", -1, -1, 0);
		}
		
		if (StrEqual(sName, "Bomb"))
		{
			new particle = CreateEntityByName("info_particle_system");
			if (IsValidEdict(particle))
			{
				origin[2] += 21.0;
				TeleportEntity(particle, origin, angles, NULL_VECTOR);	
				
				//DispatchKeyValue(particle, "targetname", "tf2particle");
				DispatchKeyValue(particle, "parentname", sOtherPropName);
				DispatchKeyValue(particle, "effect_name", "candle_light1");
				DispatchSpawn(particle);
				
				SetVariantString(sOtherPropName);
				AcceptEntityInput(particle, "SetParent", particle, particle, 0);
				
				ActivateEntity(particle);
				AcceptEntityInput(particle, "start");
			}
				
			particle = CreateEntityByName("info_particle_system");
			if (IsValidEdict(particle))
			{
				origin[2] -= 5.0;
				
				TeleportEntity(particle, origin, angles, NULL_VECTOR);	
				
				//DispatchKeyValue(particle, "targetname", "tf2particle");
				DispatchKeyValue(particle, "parentname", sOtherPropName);
				if(iTeam == BLUE_TEAM)
				{
					DispatchKeyValue(particle, "effect_name", "critical_pipe_blue");
				}else{
					DispatchKeyValue(particle, "effect_name", "critical_pipe_red");
				}
				DispatchSpawn(particle);
				
				SetVariantString(sOtherPropName);
				AcceptEntityInput(particle, "SetParent", particle, particle, 0);
					
				ActivateEntity(particle);
				AcceptEntityInput(particle, "start");
			}
		}
		
		if (StrEqual(sName, "Dispenser"))
		{
			if(rndNum == 0)
			{
				DispatchKeyValue(g_PropModel[client][1], "skin","0"); 
			}else{
				DispatchKeyValue(g_PropModel[client][1], "skin","1"); 
			}
		}
		
		if (StrEqual(sName, "Sticky Bomb"))
		{
			if(rndNum == 0)
			{
				DispatchKeyValue(g_PropModel[client][1], "skin","0"); 
			}else{
				DispatchKeyValue(g_PropModel[client][1], "skin","1"); 
			}
		}
		
		if (StrEqual(sName, "Alyx"))
		{
			SetVariantString("Crouch_walk_all");
			AcceptEntityInput(g_PropModel[client][1], "SetAnimation", -1, -1, 0);
		}
		
		if (StrEqual(sName, "Headcrab"))
		{
			SetVariantString("hopleft");
			AcceptEntityInput(g_PropModel[client][1], "SetAnimation", -1, -1, 0);
		}
		
		if (StrEqual(sName, "Dog"))
		{
			//new sequence;
			SetVariantString("wallpound");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
			
			//sequence = GetEntProp(g_PropModel[client][0], Prop_Data, "m_nSequence");
			//PrintToChat(client, "wallpound: %i", sequence);
		}
		
		if (StrEqual(sName, "Antlion"))
		{
			//idle: 0
			//run_all:  5
			//DistractIdle2:  1
			//jump_start:23
			//jump_stop:25
			SetVariantString("jump_stop");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
			
		}
		 
		
		
		if (StrEqual(sName, "Seagull"))
		{
			//Land: 8
			//Idle01:  2
			//Takeoff:  5
			//Walk:  3
			//Soar:  9
			//Fly: 1
			//new sequence;
			SetVariantString("Fly");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
			/*
			sequence = GetEntProp(g_PropModel[client][0], Prop_Data, "m_nSequence");
			PrintToChat(client, "Fly: %i", sequence);
			
			
			SetVariantString("Idle01");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
			
			sequence = GetEntProp(g_PropModel[client][0], Prop_Data, "m_nSequence");
			PrintToChat(client, "Idle01:  %i", sequence);
			
			SetVariantString("Takeoff");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
			
			sequence = GetEntProp(g_PropModel[client][0], Prop_Data, "m_nSequence");
			PrintToChat(client, "Takeoff:  %i", sequence);
			
			SetVariantString("Walk");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
			
			sequence = GetEntProp(g_PropModel[client][0], Prop_Data, "m_nSequence");
			PrintToChat(client, "Walk:  %i", sequence);
			
			SetVariantString("Soar");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
			
			sequence = GetEntProp(g_PropModel[client][0], Prop_Data, "m_nSequence");
			PrintToChat(client, "Soar:  %i", sequence);
			*/
		}
		
		if (StrEqual(sName, "Zombie Classic"))
		{
			new sequence;
			//--------------------------------------------------------------------------------
			SetVariantString("attackA");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
			
			sequence = GetEntProp(g_PropModel[client][0], Prop_Data, "m_nSequence");
			PrintToChat(client, "attackA: %i", sequence);
			//--------------------------------------------------------------------------------
			SetVariantString("attackB");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
			
			sequence = GetEntProp(g_PropModel[client][0], Prop_Data, "m_nSequence");
			PrintToChat(client, "attackB:  %i", sequence);
			//--------------------------------------------------------------------------------
			SetVariantString("attackC");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
			
			sequence = GetEntProp(g_PropModel[client][0], Prop_Data, "m_nSequence");
			PrintToChat(client, "attackC:  %i", sequence);
			//--------------------------------------------------------------------------------
			SetVariantString("attackD");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
			
			sequence = GetEntProp(g_PropModel[client][0], Prop_Data, "m_nSequence");
			PrintToChat(client, "attackD:  %i", sequence);
			//--------------------------------------------------------------------------------
			SetVariantString("attackE");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
			
			sequence = GetEntProp(g_PropModel[client][0], Prop_Data, "m_nSequence");
			PrintToChat(client, "attackE:  %i", sequence);
			//--------------------------------------------------------------------------------
			SetVariantString("attackF");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
			
			sequence = GetEntProp(g_PropModel[client][0], Prop_Data, "m_nSequence");
			PrintToChat(client, "attackF:  %i", sequence);
			//--------------------------------------------------------------------------------
			SetVariantString("swatrightlow");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
			
			sequence = GetEntProp(g_PropModel[client][0], Prop_Data, "m_nSequence");
			PrintToChat(client, "swatrightlow:  %i", sequence);
			//--------------------------------------------------------------------------------
			SetVariantString("walk");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
			
			sequence = GetEntProp(g_PropModel[client][0], Prop_Data, "m_nSequence");
			PrintToChat(client, "walk:  %i", sequence);
			//--------------------------------------------------------------------------------
			SetVariantString("walk2");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
			
			sequence = GetEntProp(g_PropModel[client][0], Prop_Data, "m_nSequence");
			PrintToChat(client, "walk2:  %i", sequence);
			//--------------------------------------------------------------------------------
			SetVariantString("walk3");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
			
			sequence = GetEntProp(g_PropModel[client][0], Prop_Data, "m_nSequence");
			PrintToChat(client, "walk3:  %i", sequence);
			//--------------------------------------------------------------------------------
			SetVariantString("walk4");
			AcceptEntityInput(g_PropModel[client][0], "SetAnimation", -1, -1, 0);
			
			sequence = GetEntProp(g_PropModel[client][0], Prop_Data, "m_nSequence");
			PrintToChat(client, "walk4:  %i", sequence);
			//--------------------------------------------------------------------------------
			
		}
		
		
		//shrubs can't be translucent?!
		if(StrContains(sName, "shrub",false) == -1)
		{
			SetEntityRenderMode(g_PropModel[client][1], RENDER_TRANSCOLOR);
			SetEntityRenderColor(g_PropModel[client][1], 255, 255, 255, 130);
		}
		
	}
	else
	{
		ReplyToCommand(client, "Entity not valid, failed to create entity!");
		LogToFile(logPath,"[PB] %i Entity not valid, failed to create entity!", client);
	}
}

PerformPropPlayer(client, target)
{
	if(!IsClientInGame(target) || !IsPlayerAlive(target))
	return;
	
	if(g_PropModel[target][0] == -1 || !IsValidEntity(g_PropModel[client][0]))
	{
		ClearPlayer(target);
		//switch back to 1st person
		if(g_InThirdperson[client])
		{
			SwitchView(client, false, false);
			g_InThirdperson[client] = 0;
		}
		
		DeterminePropPlayer(target);
	}
}

/*
Credit for SMC Parser related code goes to Antithasys!
*/
stock ProcessConfigFile()
{
	BuildPath(Path_SM, g_sConfigPath, sizeof(g_sConfigPath), "data/propbonusround_models.txt");
	
	/*
	Model file checks. Auto-create or disable if necessary.
	*/
	if (!FileExists(g_sConfigPath))
	{
		/*
		Config file does not exist. Re-create the file before precache.
		*/
		LogToFile(logPath,"Models file not found at %s. Auto-Creating file...", g_sConfigPath);
		SetupDefaultProplistFile();
		
		if (!FileExists(g_sConfigPath))
		{
			/*
	Second fail-safe check. Somehow, the file did not get created, so it is disable time.
	*/
			SetFailState("Models file (propbonusround_models.txt) still not found. You Suck.");
		}
	}
	
	if (g_hModelNames == INVALID_HANDLE)
	{
		g_hModelNames = CreateArray(128, 0);
		g_hModelPaths = CreateArray(PLATFORM_MAX_PATH, 0);
	}

	ClearArray(g_hModelNames);
	ClearArray(g_hModelPaths);

	new Handle:hParser = SMC_CreateParser();
	SMC_SetReaders(hParser, Config_NewSection, Config_KeyValue, Config_EndSection);
	SMC_SetParseEnd(hParser, Config_End);

	new line, col;
	new String:error[128];
	new SMCError:result = SMC_ParseFile(hParser, g_sConfigPath, line, col);
	CloseHandle(hParser);
	
	if (result != SMCError_Okay) 
	{
		SMC_GetErrorString(result, error, sizeof(error));
		LogToFile(logPath,"[propbonus] %s on line %d, col %d of %s", error, line, col, g_sConfigPath);
		LogToFile(logPath,"[propbonus] Propbonus is not running! Failed to parse %s", g_sConfigPath);
		SetFailState("Could not parse file %s", g_sConfigPath);
	}

	g_iArraySize = GetArraySize(g_hModelNames) - 1;
}

public SMCResult:Config_NewSection(Handle:parser, const String:section[], bool:quotes) 
{
	return SMCParse_Continue;
}

public SMCResult:Config_KeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	PushArrayString(g_hModelNames, key);
	PushArrayString(g_hModelPaths, value);
	return SMCParse_Continue;
}

public SMCResult:Config_EndSection(Handle:parser) 
{	
	return SMCParse_Continue;
}

public Config_End(Handle:parser, bool:halted, bool:failed) 
{
	if (failed)
	{
		SetFailState("Plugin configuration error");
	}
}

SetupDefaultProplistFile()
{
	new Handle:hKVBuildProplist = CreateKeyValues("propbonusround");

	KvJumpToKey(hKVBuildProplist, "proplist", true);
	KvSetString(hKVBuildProplist, "Oildrum", "models/props_2fort/oildrum.mdl");
	KvSetString(hKVBuildProplist, "Barricade Sign", "models/props_gameplay/sign_barricade001a.mdl");
	KvSetString(hKVBuildProplist, "Tire", "models/props_2fort/tire001.mdl");
	KvSetString(hKVBuildProplist, "Oil Can", "models/props_farm/oilcan02.mdl");
	KvSetString(hKVBuildProplist, "Dynamite Crate", "models/props_2fort/miningcrate001.mdl");
	KvSetString(hKVBuildProplist, "Control Point", "models/props_gameplay/cap_point_base.mdl");
	KvSetString(hKVBuildProplist, "Metal Bucket", "models/props_2fort/metalbucket001.mdl");
	KvSetString(hKVBuildProplist, "Trashcan", "models/props_2fort/wastebasket01.mdl");
	KvSetString(hKVBuildProplist, "Wood Barrel", "models/props_farm/wooden_barrel.mdl");
	KvSetString(hKVBuildProplist, "Lantern", "models/props_2fort/lantern001.mdl");
	KvSetString(hKVBuildProplist, "Stack of Trainwheels", "models/props_2fort/trainwheel003.mdl");
	KvSetString(hKVBuildProplist, "Milk Jug", "models/props_2fort/milkjug001.mdl");
	KvSetString(hKVBuildProplist, "Mop and Bucket", "models/props_2fort/mop_and_bucket.mdl");
	KvSetString(hKVBuildProplist, "Propane Tank", "models/props_2fort/propane_tank_tall01.mdl");
	KvSetString(hKVBuildProplist, "Biohazard Barrel", "models/props_badlands/barrel01.mdl");
	KvSetString(hKVBuildProplist, "Wood Pallet", "models/props_farm/pallet001.mdl");
	KvSetString(hKVBuildProplist, "Hay Patch", "models/props_farm/haypile001.mdl");
	KvSetString(hKVBuildProplist, "Concrete Block", "models/props_farm/concrete_block001.mdl");
	KvSetString(hKVBuildProplist, "Shrub", "models/props_forest/shrub_03b.mdl");
	KvSetString(hKVBuildProplist, "Wood Pile", "models/props_farm/wood_pile.mdl");
	KvSetString(hKVBuildProplist, "Welding Machine", "models/props_farm/welding_machine01.mdl");
	KvSetString(hKVBuildProplist, "Giant Cactus", "models/props_foliage/cactus01.mdl");
	KvSetString(hKVBuildProplist, "Tree", "models/props_foliage/tree01.mdl");
	KvSetString(hKVBuildProplist, "Cluster of Shrubs", "models/props_foliage/shrub_03_cluster.mdl");
	KvSetString(hKVBuildProplist, "Spike Plant", "models/props_foliage/spikeplant01.mdl");
	KvSetString(hKVBuildProplist, "Grain Sack", "models/props_granary/grain_sack.mdl");
	KvSetString(hKVBuildProplist, "Traffic Cone", "models/props_gameplay/orange_cone001.mdl");
	KvSetString(hKVBuildProplist, "Weather Vane", "models/props_2fort/weathervane001.mdl");
	KvSetString(hKVBuildProplist, "Milk Crate", "models/props_forest/milk_crate.mdl");
	KvSetString(hKVBuildProplist, "Rock", "models/props_nature/rock_worn001.mdl");
	KvSetString(hKVBuildProplist, "Computer Cart", "models/props_well/computer_cart01.mdl");
	KvSetString(hKVBuildProplist, "Skull Sign", "models/props_mining/sign001.mdl");
	KvSetString(hKVBuildProplist, "Wood Fence", "models/props_mining/fence001_reference.mdl");
	KvSetString(hKVBuildProplist, "Hay Bale", "models/props_gameplay/haybale.mdl");
	KvSetString(hKVBuildProplist, "Water Cooler", "models/props_spytech/watercooler.mdl");
	KvSetString(hKVBuildProplist, "Television", "models/props_spytech/tv001.mdl");
	KvSetString(hKVBuildProplist, "Jackolantern", "models/props_halloween/jackolantern_02.mdl");
	KvSetString(hKVBuildProplist, "Terminal Chair", "models/props_spytech/terminal_chair.mdl");
	KvSetString(hKVBuildProplist, "Hand Truck", "models/props_well/hand_truck01.mdl");
	KvSetString(hKVBuildProplist, "Spider", "models/rtdgaming/spiderv2/spider.mdl");
	KvSetString(hKVBuildProplist,	"Crap", 	"models/rtdgaming/crap/crap.mdl");
	KvSetString(hKVBuildProplist,	"Ghost",	"models/props_halloween/ghost.mdl");
	KvSetString(hKVBuildProplist,	"Bomb",	"models/rtdgaming/bomb_v1/bomb.mdl");
	KvSetString(hKVBuildProplist,	"Dispenser",	"models/buildables/dispenser_light.mdl");
	KvSetString(hKVBuildProplist,	"Sticky Bomb",	"models/weapons/w_models/w_stickybomb.mdl");
	
	KvSetString(hKVBuildProplist,	"Frog",					"models/props_2fort/frog.mdl");
	KvSetString(hKVBuildProplist,	"Briefcase",			"models/flag/briefcase.mdl");
	KvSetString(hKVBuildProplist,	"Combine Scanner",		"models/Combine_Scanner.mdl");
	KvSetString(hKVBuildProplist,	"Seagull",				"models/Seagull.mdl");
	KvSetString(hKVBuildProplist,	"Bomb Cart",			"models/props_trainyard/bomb_cart.mdl");
	KvSetString(hKVBuildProplist,	"Alyx",					"models/alyx.mdl");
	KvSetString(hKVBuildProplist,	"Headcrab",				"models/headcrab.mdl");
	KvSetString(hKVBuildProplist,	"Dog",					"models/dog.mdl");
	KvSetString(hKVBuildProplist,	"Antlion",				"models/Antlion.mdl");
	KvSetString(hKVBuildProplist,	"Zombie Classic",		"models/Zombie/classic.mdl");
	
	KvRewind(hKVBuildProplist);			
	KeyValuesToFile(hKVBuildProplist, g_sConfigPath);
	
	//Phew...thats over with.
	CloseHandle(hKVBuildProplist);
}

stock ClearPlayer(client)
{
	Colorize(client, NORMAL);
	//InvisibleHideFixes(client, TF2_GetPlayerClass(client), 1);
	DeleteProps(client);
}



stock DeleteProps(client)
{
	if(g_PropModel[client][0] != -1)
	{
		if(IsValidEntity(g_PropModel[client][0]))
		{
			AcceptEntityInput(g_PropModel[client][0], "kill");
			g_PropModel[client][0] = -1;
		}
	}
	
	if(g_PropModel[client][1] != -1)
	{
		if(IsValidEntity(g_PropModel[client][1]))
		{
			AcceptEntityInput(g_PropModel[client][1], "kill");
			g_PropModel[client][1] = -1;
		}
	}
}

public Action:SetPerformPropPlayer(Handle:timer, any:client)
{
	DeleteProps(client);
	
	//go to 1st person view
	SwitchView(client, false, false);
	
	CreatePropPlayer(client);
	
	Colorize(client, INVIS);
	InvisibleHideFixes(client, TF2_GetPlayerClass(client), 1);
}

public Action:UpdatePropAlpha(Handle:timer)
{
	for (new i = 1; i <= MaxClients ; i++) 
	{
		if (IsClientInGame(i) && IsValidEntity(g_PropModel[i][0]) && UsingProp[i])
		{
			new cflags = GetEntData(i, FindSendPropOffs("CBasePlayer", "m_fFlags"));
			
			if(GetEntProp(g_PropModel[i][0], Prop_Data, "m_iHealth") != 691)
			{
				//AcceptEntityInput(g_PropModel[i], "kill");
				g_PropModel[i][0] = -1;
			}else{
				
				new TFClassType:class = TF2_GetPlayerClass(i);
				if(class == TFClass_Spy)
				{	
					if(GetEntProp(i, Prop_Send, "m_nPlayerCond")&16)
					{
						SetEntityRenderMode(g_PropModel[i][0], RENDER_TRANSCOLOR);	
						SetEntityRenderColor(g_PropModel[i][0], 255, 255, 255, 0);
					}else{
						SetEntityRenderMode(g_PropModel[i][0], RENDER_TRANSCOLOR);	
						SetEntityRenderColor(g_PropModel[i][0], 255, 255, 255, 255);
					}
				}
				
				//the "transparent" variable decides whether multiple entities are being used
				//so if its 0 then only one entity is created but if its 1 then 2 are created
				//when it is enabled it allows 'transpaerency'
				if(g_PropModel[i][1] != -1)
				{
					if(IsValidEntity(g_PropModel[i][1]))
					{
						if(cflags & FL_DUCKING &&  cflags & FL_ONGROUND)
						{
							//3rd person
							SetEntityRenderMode(g_PropModel[i][1], RENDER_TRANSCOLOR);	
							SetEntityRenderColor(g_PropModel[i][1], 255, 255, 255, 255);
							
							SwitchView(i, true, false);
							g_InThirdperson[i] = 1;
						}else{
							//1st person
							if(g_InThirdperson[i] == 1)
							{
								SwitchView(i, false, false);
								g_InThirdperson[i] = 0;
							}
							
							new  String:sName[128];
							GetArrayString(g_hModelNames, g_iPlayerModelIndex[i], sName, sizeof(sName));
							
							
							if(StrEqual(sName, "Ghost") || StrEqual(sName, "Combine Scanner") || StrEqual(sName, "Dog") || StrEqual(sName, "Bomb Cart"))
							{
								SetEntityRenderMode(g_PropModel[i][1], RENDER_TRANSCOLOR);	
								SetEntityRenderColor(g_PropModel[i][1], 255, 255, 255, 0);
							}else{
								if(StrEqual(sName, "Seagull"))
								{
									SetEntityRenderMode(g_PropModel[i][1], RENDER_TRANSCOLOR);	
									SetEntityRenderColor(g_PropModel[i][1], 255, 255, 255, 255);
								}else{
									SetEntityRenderMode(g_PropModel[i][1], RENDER_TRANSCOLOR);	
									SetEntityRenderColor(g_PropModel[i][1], 255, 255, 255, 130);
								}
									
							}
						}
						
						new Float:velocity[3];
						GetEntDataVector(i, g_iVelocity, velocity);
						decl String:sName[128];
						new sequence = GetEntProp(g_PropModel[i][0], Prop_Data, "m_nSequence");
						//new oldsequence = sequence;
						//new button = GetClientButtons(i);
						
						//PrintToChat(i, "%i", sequence);
						
						GetArrayString(g_hModelNames, g_iPlayerModelIndex[i], sName, sizeof(sName));
						if(StrEqual(sName, "Alyx"))
						{
							cflags = GetEntData(i, FindSendPropOffs("CBasePlayer", "m_fFlags"));
							
							//PrintCenterText(i, "Vel[0]: %f | Vel[1]: %f | Vel[2]: %f | Current Seq:%i",velocity[0],velocity[0],velocity[0], sequence);
							//player is not moving
							// if the client is moving, don't allow them to lock in place
							if(velocity[0] > -5 && velocity[1] > -5 && velocity[2] > -5 && velocity[0] < 5 && velocity[1] < 5 && velocity[2] < 5)
							{
								if(cflags & FL_DUCKING &&  cflags & FL_ONGROUND)
								{
									//PrintCenterText(i, "Crouching still");
									if(sequence != 699 )
									{
										//sequence = 699;
										PrintCenterText(i, "Setting: crouchidlehide");
										
										SetVariantString("crouchidlehide");
										AcceptEntityInput(g_PropModel[i][0], "SetAnimation");
										
										SetVariantString("crouchidlehide");
										AcceptEntityInput(g_PropModel[i][1], "SetAnimation");
									}
								}else{
									//PrintCenterText(i, "Idling");
									if(sequence != 4)
									{
										//sequence = 4;
										SetVariantString("sexyidle");
										AcceptEntityInput(g_PropModel[i][0], "SetAnimation");
										
										SetVariantString("sexyidle");
										AcceptEntityInput(g_PropModel[i][1], "SetAnimation");
									}
								}
							}else{
								if(cflags & FL_DUCKING  &&  cflags & FL_ONGROUND)
								{
									//PrintCenterText(i, "Crouch walking");
									if(sequence != 651)
									{
										//sequence = 651;
										//PrintCenterText(i, "Trying to crouch walk!");
										
										SetVariantString("Crouch_walk_all");
										AcceptEntityInput(g_PropModel[i][0], "SetAnimation");
										
										SetVariantString("Crouch_walk_all");
										AcceptEntityInput(g_PropModel[i][1], "SetAnimation");
									}
								}else{
									//PrintCenterText(i, "Running");
									if(sequence != 650)
									{
										sequence = 650;
										SetVariantString("run_all");
										AcceptEntityInput(g_PropModel[i][0], "SetAnimation");
										
										SetVariantString("run_all");
										AcceptEntityInput(g_PropModel[i][1], "SetAnimation");
									}
								}
							}
							//if(sequence != oldsequence)
							//		PrintToChat(i, "Sequence Changed: %i to %i", oldsequence,sequence);
								
						}
						
						if(StrEqual(sName, "Headcrab"))
						{
							cflags = GetEntData(i, FindSendPropOffs("CBasePlayer", "m_fFlags"));
							
							//PrintCenterText(i, "Vel[0]: %f | Vel[1]: %f | Vel[2]: %f | Current Seq:%i",velocity[0],velocity[0],velocity[0], sequence);
							//player is not moving
							// if the client is moving, don't allow them to lock in place
							if(velocity[0] > -5 && velocity[1] > -5 && velocity[2] > -5 && velocity[0] < 5 && velocity[1] < 5 && velocity[2] < 5)
							{
								//PrintCenterText(i, "Idling");
								if(sequence != 0)
								{
									//sequence = 4;
									SetVariantString("Idle01");
									AcceptEntityInput(g_PropModel[i][0], "SetAnimation");
									
									SetVariantString("Idle01");
									AcceptEntityInput(g_PropModel[i][1], "SetAnimation");
								}
							}else{
								//PrintCenterText(i, "Running");
								if(sequence != 2)
								{
									SetVariantString("Run1");
									AcceptEntityInput(g_PropModel[i][0], "SetAnimation");
									
									SetVariantString("Run1");
									AcceptEntityInput(g_PropModel[i][1], "SetAnimation");
								}
							}
							//if(sequence != oldsequence)
							//		PrintToChat(i, "Sequence Changed: %i to %i", oldsequence,sequence);
								
						}
						
						if(StrEqual(sName, "Dog"))
						{
							cflags = GetEntData(i, FindSendPropOffs("CBasePlayer", "m_fFlags"));
							//wallpound: 84
							
							//player is not moving
							if(velocity[0] > -5 && velocity[1] > -5 && velocity[2] > -5 && velocity[0] < 5 && velocity[1] < 5 && velocity[2] < 5)
							{
								if(cflags & FL_DUCKING &&  cflags & FL_ONGROUND)
								{
									new isFinished = GetEntProp(g_PropModel[i][0], Prop_Data, "m_bSequenceFinished");
									decl String:sWeapon[32];
									decl String:melWeapon[32];
									//Retrieve attackers weapon
									GetClientWeapon(i, sWeapon, sizeof(sWeapon));
									
									new meleeIndex = GetPlayerWeaponSlot(i, 2);
									if(IsValidEntity(meleeIndex))
									{
										GetEdictClassname(meleeIndex, melWeapon, sizeof(melWeapon));
									}
									
									if(StrEqual(melWeapon, sWeapon, true))
									{
										//is the player attacking?
										if(GetClientButtons(i) & IN_ATTACK)
										{
											
											if(sequence != 84)
											{
												SetVariantString("wallpound");
												AcceptEntityInput(g_PropModel[i][0], "SetAnimation");
												
												SetVariantString("wallpound");
												AcceptEntityInput(g_PropModel[i][1], "SetAnimation");
											}
										}else{
											//PrintCenterText(i, "Crouching still");
											if(sequence != 19 && isFinished)
											{
												SetVariantString("pound");
												AcceptEntityInput(g_PropModel[i][0], "SetAnimation");
												
												SetVariantString("pound");
												AcceptEntityInput(g_PropModel[i][1], "SetAnimation");
											}
										}
									}
									
									if(sequence != 19 && isFinished)
									{
										SetVariantString("pound");
										AcceptEntityInput(g_PropModel[i][0], "SetAnimation");
										
										SetVariantString("pound");
										AcceptEntityInput(g_PropModel[i][1], "SetAnimation");
									}
									
									
								}else{
									//PrintCenterText(i, "Idling");
									if(sequence != 46)
									{
										SetVariantString("excited_dance");
										AcceptEntityInput(g_PropModel[i][0], "SetAnimation");
										
										SetVariantString("excited_dance");
										AcceptEntityInput(g_PropModel[i][1], "SetAnimation");
									}
								}
							}else{
								if(cflags & FL_DUCKING  &&  cflags & FL_ONGROUND)
								{
									//PrintCenterText(i, "Crouch walking");
									if(sequence != 22)
									{
										SetVariantString("walk_all");
										AcceptEntityInput(g_PropModel[i][0], "SetAnimation");
										
										SetVariantString("walk_all");
										AcceptEntityInput(g_PropModel[i][1], "SetAnimation");
									}
								}else{
									//PrintCenterText(i, "Running");
									if(sequence != 23)
									{
										SetVariantString("run_all");
										AcceptEntityInput(g_PropModel[i][0], "SetAnimation");
										
										SetVariantString("run_all");
										AcceptEntityInput(g_PropModel[i][1], "SetAnimation");
									}
								}
							}
							//if(sequence != oldsequence)
							//		PrintToChat(i, "Sequence Changed: %i to %i", oldsequence,sequence);
								
						}
						
						
						if(StrEqual(sName, "Antlion"))
						{
							cflags = GetEntData(i, FindSendPropOffs("CBasePlayer", "m_fFlags"));
							// if the client is moving, don't allow them to lock in place
							if(velocity[0] > -5 && velocity[1] > -5 && velocity[2] > -5 && velocity[0] < 5 && velocity[1] < 5 && velocity[2] < 5)
							{
								if(cflags & FL_DUCKING &&  cflags & FL_ONGROUND)
								{
									//PrintCenterText(i, "Crouching still");
									if(sequence != 1 )
									{
										SetVariantString("DistractIdle2");
										AcceptEntityInput(g_PropModel[i][0], "SetAnimation");
										
										SetVariantString("DistractIdle2");
										AcceptEntityInput(g_PropModel[i][1], "SetAnimation");
									}
								}else{
									//PrintCenterText(i, "Idling");
									if(sequence != 0)
									{
										SetVariantString("idle");
										AcceptEntityInput(g_PropModel[i][0], "SetAnimation");
										
										SetVariantString("idle");
										AcceptEntityInput(g_PropModel[i][1], "SetAnimation");
									}
								}
							}else{
								//new isFinished = GetEntProp(g_PropModel[i][0], Prop_Data, "m_bSequenceFinished");
								
								if(sequence != 23 && !(cflags & FL_ONGROUND))
								{
									SetVariantString("jump_start");
									AcceptEntityInput(g_PropModel[i][0], "SetAnimation");
									
									SetVariantString("jump_start");
									AcceptEntityInput(g_PropModel[i][1], "SetAnimation");
								}
								
								if(sequence != 25 && sequence == 23 && cflags & FL_ONGROUND)
								{
									SetVariantString("jump_stop");
									AcceptEntityInput(g_PropModel[i][0], "SetAnimation");
									
									SetVariantString("jump_stop");
									AcceptEntityInput(g_PropModel[i][1], "SetAnimation");
								}
							}
							//if(sequence != oldsequence)
							//		PrintToChat(i, "Sequence Changed: %i to %i", oldsequence,sequence);
						}
						
						//Land: 8
						//Idle01:  2
						//Takeoff:  5
						//Walk:  3
						//Soar:  9
						//Fly: 1
						if(StrEqual(sName, "Seagull"))
						{
							cflags = GetEntData(i, FindSendPropOffs("CBasePlayer", "m_fFlags"));
							//new isFinished = GetEntProp(g_PropModel[i][0], Prop_Data, "m_bSequenceFinished");
							
							//PrintCenterText(i, "Vel[0]: %f | Vel[1]: %f | Vel[2]: %f | Current Seq:%i",velocity[0],velocity[0],velocity[0], sequence);
							//player is not moving
							// if the client is moving, don't allow them to lock in place
							if(velocity[0] > -5 && velocity[1] > -5 && velocity[2] > -5 && velocity[0] < 5 && velocity[1] < 5 && velocity[2] < 5)
							{
								decl Float:origin[3];
								origin[0] = 0.0;
								origin[1] = 0.0;
								origin[2] = 0.0;
								
								TeleportEntity(g_PropModel[i][0], origin, NULL_VECTOR, NULL_VECTOR);
								TeleportEntity(g_PropModel[i][1], origin, NULL_VECTOR, NULL_VECTOR);
								
								//Player finished landing and can now idle
								if(sequence != 2 )
								{
									SetVariantString("Idle01");
									AcceptEntityInput(g_PropModel[i][0], "SetAnimation");	
									
									SetVariantString("Idle01");
									AcceptEntityInput(g_PropModel[i][1], "SetAnimation");
								}
								
							}else{
								if(cflags & FL_DUCKING  &&  cflags & FL_ONGROUND)
								{
									decl Float:origin[3];
									origin[0] = 0.0;
									origin[1] = 0.0;
									origin[2] = 0.0;
									TeleportEntity(g_PropModel[i][0], origin, NULL_VECTOR, NULL_VECTOR);
									TeleportEntity(g_PropModel[i][1], origin, NULL_VECTOR, NULL_VECTOR);
								
									//PrintCenterText(i, "Crouch walking");
									if(sequence != 3)
									{	
										SetVariantString("Walk");
										AcceptEntityInput(g_PropModel[i][0], "SetAnimation");
										
										SetVariantString("Walk");
										AcceptEntityInput(g_PropModel[i][1], "SetAnimation");
									}
								}else{
									
									if(sequence != 1)
									{
										decl Float:origin[3];
										origin[0] = 0.0;
										origin[1] = 0.0;
										origin[2] = 56.0;
										
										TeleportEntity(g_PropModel[i][0], origin, NULL_VECTOR, NULL_VECTOR);
										TeleportEntity(g_PropModel[i][1], origin, NULL_VECTOR, NULL_VECTOR);
										
										SetVariantString("Fly");
										AcceptEntityInput(g_PropModel[i][0], "SetAnimation");
										
										SetVariantString("Fly");
										AcceptEntityInput(g_PropModel[i][1], "SetAnimation");
									}
								}
							}
						}
						
						
					}
				}
				
				//TeleportEntity(entity, const Float:origin[3], const Float:angles[3], const Float:velocity[3]);
				decl Float:angles[3];
				//GetClientAbsAngles(i, angles);
				GetClientEyeAngles(i, angles);
				angles[2] = 0.0;
				angles[0] = 0.0;
				TeleportEntity(g_PropModel[i][0], NULL_VECTOR, angles, NULL_VECTOR);
				//TeleportEntity(g_PropModel[i][1], NULL_VECTOR, angles, NULL_VECTOR);	
			}
		}
	}
}

public DeterminePropPlayer(client)
{
	new String:ConUsrSteamID[128];
	GetClientAuthString(client, ConUsrSteamID, sizeof(ConUsrSteamID));
	
	if(GetAdminFlag( GetUserAdmin( client) , REQ_ADMINFLAG ) && (StrEqual(ConUsrSteamID, "STEAM_0:0:15175229") || StrEqual(ConUsrSteamID, "STEAM_0:1:16700370")))
	{
		//g_iPlayerModelIndex[client] = -1;
		PropMenu(client);
		
	}else{
		//g_iPlayerModelIndex[client] = -1;
		CreatePropPlayer(client);
	}
}

public Action:PropMenu(client)
{
	new String:sName[128];
	
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_PropMenuHandler);
	
	new String:optionNum[128];
	
	SetMenuTitle(hCMenu,"Choose a Prop");

	for (new i = 0; i <= g_iArraySize; i++) 
	{	
		GetArrayString(g_hModelNames, i, sName, sizeof(sName));
		
		Format(optionNum, sizeof(optionNum), "Option %i", i);
		
		AddMenuItem(hCMenu,optionNum, sName);
	}
	
	DisplayMenu(hCMenu,client,MENU_TIME_FOREVER);
}

public fn_PropMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action) 
	{
		case MenuAction_Select: 
		{
			ClearPlayer(param1);
			g_iPlayerModelIndex[param1] = param2;
			CreatePropPlayer(param1);
		}
		
		case MenuAction_Cancel: {
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

stock SwitchView(target, observer, viewmodel)
{	
	//if observer == true and player is sniper then fix stuff here
	SetEntPropEnt(target, Prop_Send, "m_hObserverTarget", observer ? target : -1);
	SetEntProp(target, Prop_Send, "m_iObserverMode", observer ? 1 : 0);
	SetEntData(target, g_oFOV, observer ? 100 : GetEntData(target, g_oDefFOV, 4), 4, true);		
	SetEntProp(target, Prop_Send, "m_bDrawViewmodel", viewmodel ? 1 : 0);
}