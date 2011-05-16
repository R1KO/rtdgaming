/*
 * Billboard Manager 
 *
 * Plugin loads a billboard
 *  
 * 
 * Version 1.0
 * - Initial release 
 * 
 * www.rtdgaming.com
 *
 */
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"
#define MaxBillboards 30
#define MODEL_BILLBOARD		"models/rtdgaming/xmas_2010/sign.mdl"

new Handle:c_Enabled   = INVALID_HANDLE;
new Handle:c_SpawnBillBoards   = INVALID_HANDLE;
new Handle:c_Day   = INVALID_HANDLE;
new Handle:c_BillboardTimer	= INVALID_HANDLE;

new currentDay;
new Float:billboardTimer = 10.0;

new billboardModelIndex;

new billboards; //amount of billboards
new Float:billboardsLoc[MaxBillboards][3]; //billboard location
new Float:billboardsAngle[MaxBillboards]; //billboard angle
new bool:speedChanged = false;

public Plugin:myinfo = 
{
	name = "[TF2] Billboard",
	author = "Fox",
	description = "Adds Billboards at predefined locations",
	version = PLUGIN_VERSION,
	url = "http://www.rtdgaming.com"
}

public OnPluginStart()
{
	CreateConVar("sm_billboard_version", PLUGIN_VERSION, "[TF2] Billboard", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	c_Enabled   = CreateConVar("sm_billboard_enable",    "1",        "<0/1> Enable Billboards");
	c_SpawnBillBoards  = CreateConVar("sm_billboard_respawn",    "",        "Respawns Billboards");
	c_Day  = CreateConVar("sm_billboard_day",    "1",        "<1-7> Set the day of the week");
	c_BillboardTimer = CreateConVar("sm_billboard_timer",    "10.0",        "<1.0-x> After X seconds the billboard changes signs");
	HookEvent("teamplay_round_start", Event_RoundStart);
	
	RegAdminCmd("sm_billboard", Command_Billboard, ADMFLAG_BAN, "For Admin Menu/Commands");
}

public Action:Command_Billboard(client, args)
{
	decl String:strMessage[128];
	GetCmdArg(1, strMessage, sizeof(strMessage));
	new String:adminName[128];
	GetClientName(client, adminName, sizeof(adminName));
	
	if(StrEqual("respawn", strMessage, false))
	{
		load_Billboards();
		spawn_Billboards();
		
		LogMessage("Reloading and Spawning Billboards, through chat command");
		return Plugin_Handled;
	}
	
	if(StrEqual("test", strMessage, false))
	{
		spawn_Temp_Billboard(client);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public OnConfigsExecuted()
{	
	HookConVarChange(c_SpawnBillBoards, ConVarChange_SpawnBillBoards);
	HookConVarChange(c_Day, ConVarChange_Day);
	HookConVarChange(c_BillboardTimer, ConVarChange_Timer);
	
	currentDay = GetConVarInt(c_Day);
	billboardTimer = GetConVarFloat(c_BillboardTimer);
	
	//Load the dice spawn points
	load_Billboards();
	spawn_Billboards();
	
	//The Datapack stores all the Entity's important values
	new Handle:dataPackHandle; //our timer
	//LogMessage("Creating timer! OnConfigsExecuted| Timer Interval:%f",billboardTimer);
	CreateDataTimer(billboardTimer, Timer_UpdateBillboards, dataPackHandle, TIMER_REPEAT |TIMER_FLAG_NO_MAPCHANGE);
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, 0); //current skin
}

public ConVarChange_SpawnBillBoards(Handle:convar, const String:oldValue[], const String:newValue[])
{
	load_Billboards();
	spawn_Billboards();
	
	LogMessage("Reloading and Spawning Billboards, through SM command");
}

public ConVarChange_Day(Handle:convar, const String:oldValue[], const String:newValue[])
{
	currentDay = GetConVarInt(c_Day);
}

public ConVarChange_Timer(Handle:convar, const String:oldValue[], const String:newValue[])
{
	billboardTimer = GetConVarFloat(c_BillboardTimer);
	speedChanged = true;
}

public OnMapStart()
{
	AddFileToDownloadsTable("models/rtdgaming/xmas_2010/sign.dx80.vtx");
	AddFileToDownloadsTable("models/rtdgaming/xmas_2010/sign.dx90.vtx");
	AddFileToDownloadsTable("models/rtdgaming/xmas_2010/sign.mdl");
	AddFileToDownloadsTable("models/rtdgaming/xmas_2010/sign.sw.vtx");
	AddFileToDownloadsTable("models/rtdgaming/xmas_2010/sign.vvd");
	
	AddFileToDownloadsTable("materials/models/rtdgaming/xmas_2010/base.vmt");
	AddFileToDownloadsTable("materials/models/rtdgaming/xmas_2010/base.vtf");
	
	AddFileToDownloadsTable("materials/models/rtdgaming/xmas_2010/sign001.vmt");
	AddFileToDownloadsTable("materials/models/rtdgaming/xmas_2010/sign001.vtf");
	AddFileToDownloadsTable("materials/models/rtdgaming/xmas_2010/sign002.vmt");
	AddFileToDownloadsTable("materials/models/rtdgaming/xmas_2010/sign002.vtf");
	AddFileToDownloadsTable("materials/models/rtdgaming/xmas_2010/sign003.vmt");
	AddFileToDownloadsTable("materials/models/rtdgaming/xmas_2010/sign003.vtf");
	
	AddFileToDownloadsTable("materials/models/rtdgaming/xmas_2010/day01.vmt");
	AddFileToDownloadsTable("materials/models/rtdgaming/xmas_2010/day01.vtf");
	AddFileToDownloadsTable("materials/models/rtdgaming/xmas_2010/day02.vmt");
	AddFileToDownloadsTable("materials/models/rtdgaming/xmas_2010/day02.vtf");
	AddFileToDownloadsTable("materials/models/rtdgaming/xmas_2010/day03.vmt");
	AddFileToDownloadsTable("materials/models/rtdgaming/xmas_2010/day03.vtf");
	
	AddFileToDownloadsTable("materials/models/rtdgaming/xmas_2010/icicle.vmt");
	AddFileToDownloadsTable("materials/models/rtdgaming/xmas_2010/icicle_lightwarp.vmt");
	
	billboardModelIndex = PrecacheModel(MODEL_BILLBOARD);
}

public Action:Timer_UpdateBillboards(Handle:timer, Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new skin = ReadPackCell(dataPackHandle);
	
	//Stop this timer if speed changed!
	if(speedChanged)
	{
		PrintToChatAll("Timer stopped! Detected Speed Change");
		speedChanged = false;
		
		//LogMessage("Creating timer! Speed Changed| Timer Interval:%f",billboardTimer);
		new Handle:dataHandle = INVALID_HANDLE; //our timer
		CreateDataTimer(billboardTimer, Timer_UpdateBillboards, dataHandle, TIMER_REPEAT |TIMER_FLAG_NO_MAPCHANGE);
		//Setup the datapack with appropriate information
		WritePackCell(dataHandle, skin); //current skin
		return Plugin_Stop;
	}
	
	new neededSkin;
	
	skin ++;
	
	//determine what skin we actually need
	if(skin == 4)
	{
		neededSkin = 3+currentDay;
	}else{
		neededSkin = skin -1;
	}
	
	//update all billboards skin
	new ent = -1;
	
	while ((ent = FindEntityByClassname(ent, "prop_dynamic")) != -1)
	{	
		new currIndex = GetEntProp(ent, Prop_Data, "m_nModelIndex");
		
		if(currIndex == billboardModelIndex)
		{
			SetVariantInt(neededSkin);
			AcceptEntityInput(ent, "skin", -1, -1, 0);
		}
	}
	
	
	if(skin > 3)
		skin = 0;
	
	ResetPack(dataPackHandle);
	WritePackCell(dataPackHandle, skin); //current skin
	
	return Plugin_Continue;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	spawn_Billboards();
}

public Action:removeBillboards()
{
	new ent = -1;
	
	while ((ent = FindEntityByClassname(ent, "prop_dynamic")) != -1)
	{	
		new currIndex = GetEntProp(ent, Prop_Data, "m_nModelIndex");
		
		if(currIndex == billboardModelIndex)
			killEntityIn(ent, 1.0); 
	}
}

public killEntityIn(entity, Float:seconds)
{
	if(IsValidEdict(entity))
	{
		// send "kill" event to the event queue
		new String:addoutput[64];
		Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::%f:1",seconds);
		SetVariantString(addoutput);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
}

load_Billboards()
{
	if(!GetConVarInt(c_Enabled))
		return;
	
	removeBillboards();
	
	decl String:currentMap[32];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	// Parse the objects list key values text to acquire all the possible
	// wearable items.
	new Handle:kvItemList = CreateKeyValues("Billboards_SpawnPoints");
	new String:strLocation[256];
	new String:strLine[256];
	new String:strMapName[32];
	billboards = 0;
	
	// Load the key files.
	BuildPath(Path_SM, strLocation, 256, "configs/Billboards_SpawnPoints.cfg");
	FileToKeyValues(kvItemList, strLocation);
	
	// Check if the parsed values are correct
	if (!KvGotoFirstSubKey(kvItemList)) { SetFailState("Error, can't read file containing Billboards spawn points : %s", strLocation); return; }
	
	// Iterate through all keys.
	do
	{
		// Retrieve section name, which would be the map name
		KvGetSectionName(kvItemList,       strMapName,  256);
		
		//The sectionName corresponds to the map that the server is currently playing
		if(StrEqual(currentMap,strMapName,false))
		{
			
			do
			{
				KvGotoFirstSubKey(kvItemList);
				
				if(billboards < MaxBillboards)
				{
					KvGetString(kvItemList, "x",   strLine, sizeof(strLine)); billboardsLoc[billboards][0]   = StringToFloat(strLine);
					KvGetString(kvItemList, "y",   strLine, sizeof(strLine)); billboardsLoc[billboards][1]   = StringToFloat(strLine);
					KvGetString(kvItemList, "z",   strLine, sizeof(strLine)); billboardsLoc[billboards][2]   = StringToFloat(strLine);
					KvGetString(kvItemList, "angle",   strLine, sizeof(strLine)); billboardsAngle[billboards]   = StringToFloat(strLine);
				}
				
				billboards ++;
			}
			 while (KvGotoNextKey(kvItemList));
		}
	}
	while (KvGotoNextKey(kvItemList));
	
	if(billboards >= MaxBillboards)
		billboards = MaxBillboards;
	
	LogMessage("Billboards Found: %i",billboards);
	CloseHandle(kvItemList);    
}

spawn_Billboards()
{
	new entity;
	new Float:tempAngle[3];
	
	for(new i=0; i<billboards; i++)
	{
		entity = CreateEntityByName("prop_dynamic_override");
		
		SetEntityModel(entity,MODEL_BILLBOARD);
		SetEntProp(entity, Prop_Data, "m_takedamage", 0);  //no we don't want this to take damage
		
		DispatchSpawn(entity);
		
		SetEntProp(entity, Prop_Data, "m_nSolidType", 0 );
		SetEntProp(entity, Prop_Send, "m_nSolidType", 0 );
		
		SetEntProp(entity, Prop_Data, "m_CollisionGroup", 3);
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 3);
		
		AcceptEntityInput( entity, "DisableCollision" );
		AcceptEntityInput( entity, "EnableCollision" );
		
		tempAngle[1] = billboardsAngle[i];
		TeleportEntity(entity, billboardsLoc[i], tempAngle, NULL_VECTOR);
	}
}

spawn_Temp_Billboard(client)
{
	new entity;
	new Float:tempAngle[3];
	new Float:tempOrigin[3];
	
	GetClientAbsAngles(client, tempAngle);
	//GetClientAbsOrigin(client, tempOrigin);
	GetClientEyePosition(client, tempOrigin);
	
	entity = CreateEntityByName("prop_dynamic_override");
	
	SetEntityModel(entity,MODEL_BILLBOARD);
	SetEntProp(entity, Prop_Data, "m_takedamage", 2);  //no we don't want this to take damage
	
	DispatchSpawn(entity);
	
	SetEntProp(entity, Prop_Data, "m_nSolidType", 6 );
	SetEntProp(entity, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(entity, Prop_Data, "m_CollisionGroup", 0);
	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);
	
	AcceptEntityInput( entity, "DisableCollision" );
	AcceptEntityInput( entity, "EnableCollision" );
	
	tempAngle[1] -= 90.0;
	
	TeleportEntity(entity, tempOrigin, tempAngle, NULL_VECTOR);
	
	killEntityIn(entity, 30.0); 
	
	PrintToChat(client, "        \"SpawnPoint\"");
	PrintToChat(client, "        {");
	PrintToChat(client, "            \"x\"    \"%i\"",RoundFloat(tempOrigin[0]));
	PrintToChat(client, "            \"y\"    \"%i\"",RoundFloat(tempOrigin[1]));
	PrintToChat(client, "            \"z\"    \"%i\"",RoundFloat(tempOrigin[2]));
	PrintToChat(client, "            \"angle\"    \"%i\"",RoundFloat(tempAngle[1]));
	PrintToChat(client, "        }");
}