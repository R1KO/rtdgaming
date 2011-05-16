#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>

Load_Rolls()
{	
	SetupRoll_IDs();
	
	// Parse the objects list key values text to acquire all the possible
	// wearable items.
	new Handle:kvItemList = CreateKeyValues("RTD_Rolls");
	new String:strLocation[256];
	new String:strLine[256];
	
	totalRolls = 0;
	
	//Setup our arrays that will store the loaded config data
	//afterwards it will be saved to a global array in proper order
	//that matches the order that is 'hard coded'
	new Handle: cfg_ID = CreateArray(32,100);
	new Handle: cfg_isGood = CreateArray(1,100);
	new Handle: cfg_enabled = CreateArray(1,100);
	new Handle: cfg_resetOnDeath = CreateArray(1,100);
	new Handle: cfg_EntLimit = CreateArray(1,100);
	new Handle: cfg_inBeta = CreateArray(1,100);
	new Handle: cfg_purchasable = CreateArray(1,100);
	new Handle: cfg_cost = CreateArray(1,100);
	new Handle: cfg_Article = CreateArray(8,100);
	new Handle: cfg_Text = CreateArray(32,100);
	new Handle: cfg_QuickBuy = CreateArray(64,100);
	new Handle: cfg_ClassRestriction = CreateArray(32,100);
	new Handle: cfg_ExcludeClass = CreateArray(32,100);
	
	new Handle: cfg_deployable = CreateArray(1,100);
	new Handle: cfg_amountdeployable = CreateArray(1,100);
	new Handle: cfg_ActionText = CreateArray(32,100);
	
	new Handle: cfg_CountDownTimer = CreateArray(1,100);
	new Handle: cfg_TimerOverride = CreateArray(1,100);
	new Handle: cfg_Particle = CreateArray(32,100);
	new Handle: cfg_Particle_AutoKill = CreateArray(1,100);
	new Handle: cfg_Particle_AttachToHead = CreateArray(1,100);
	new Handle: cfg_Particle_ZCorrection = CreateArray(1,100);
	new Handle: cfg_required_weapon = CreateArray(1,100);
	new Handle: cfg_itemEquipped_OnBack = CreateArray(1,100);
	
	new Handle: cfg_OwnerSteamID = CreateArray(32,100);
	new Handle: cfg_disabledForMaps = CreateArray(64,100);
	
	// Load the key files.
	BuildPath(Path_SM, strLocation, 256, "configs/rtd/rtd_rolls.cfg");
	FileToKeyValues(kvItemList, strLocation);
	
	// Check if the parsed values are correct
	if (!KvGotoFirstSubKey(kvItemList)) 
	{ 
		LogToFile(logPath,"Error, can't read file containing RTD_Rolls: %s", strLocation);
		return; 
	}
	
	
	// Iterate through all keys.
	do
	{
		KvGetString(kvItemList, "identifier", strLine, sizeof(strLine), "");
		SetArrayString(cfg_ID, totalRolls, strLine);
		
		KvGetString(kvItemList, "isGood", strLine, sizeof(strLine), "");
		SetArrayCell(cfg_isGood, totalRolls, StringToInt(strLine), 0);
		
		KvGetString(kvItemList, "enabled", strLine, sizeof(strLine), "");
		SetArrayCell(cfg_enabled, totalRolls, StringToInt(strLine), 0);
		
		KvGetString(kvItemList, "reset_on_death", strLine, sizeof(strLine), "");
		SetArrayCell(cfg_resetOnDeath, totalRolls, StringToInt(strLine), 0);
		
		KvGetString(kvItemList, "check_entity_lim", strLine, sizeof(strLine), "");
		SetArrayCell(cfg_EntLimit, totalRolls, StringToInt(strLine), 0);
		
		KvGetString(kvItemList, "isDeployable", strLine, sizeof(strLine), "");
		SetArrayCell(cfg_deployable, totalRolls, StringToInt(strLine), 0);
		
		KvGetString(kvItemList, "isInBeta", strLine, sizeof(strLine), "");
		SetArrayCell(cfg_inBeta, totalRolls, StringToInt(strLine), 0);
		
		KvGetString(kvItemList, "indefinite_article", strLine, sizeof(strLine), "");
		SetArrayString(cfg_Article, totalRolls, strLine);
		
		KvGetString(kvItemList, "roll_text", strLine, sizeof(strLine), "");
		SetArrayString(cfg_Text, totalRolls, strLine);
		
		KvGetString(kvItemList, "purchasable", strLine, sizeof(strLine), "");
		SetArrayCell(cfg_purchasable, totalRolls, StringToInt(strLine), 0);
		
		KvGetString(kvItemList, "cost", strLine, sizeof(strLine), "");
		SetArrayCell(cfg_cost, totalRolls, StringToInt(strLine), 0);
		
		KvGetString(kvItemList, "quickBuy", strLine, sizeof(strLine), "");
		SetArrayString(cfg_QuickBuy, totalRolls, strLine);
		
		KvGetString(kvItemList, "classRestrictions", strLine, sizeof(strLine), "");
		SetArrayString(cfg_ClassRestriction, totalRolls, strLine);
		
		KvGetString(kvItemList, "excludeClass", strLine, sizeof(strLine), "");
		SetArrayString(cfg_ExcludeClass, totalRolls, strLine);
		
		KvGetString(kvItemList, "amountDeployable", strLine, sizeof(strLine), "");
		SetArrayCell(cfg_amountdeployable, totalRolls, StringToInt(strLine), 0);
		
		KvGetString(kvItemList, "actionText", strLine, sizeof(strLine), "");
		SetArrayString(cfg_ActionText, totalRolls, strLine);
		
		KvGetString(kvItemList, "countDownTimer", strLine, sizeof(strLine), "");
		SetArrayCell(cfg_CountDownTimer, totalRolls, StringToInt(strLine), 0);
		
		KvGetString(kvItemList, "TimerOverride", strLine, sizeof(strLine), "");
		SetArrayCell(cfg_TimerOverride, totalRolls, StringToInt(strLine), 0);
		
		KvGetString(kvItemList, "particle", strLine, sizeof(strLine), "");
		SetArrayString(cfg_Particle, totalRolls, strLine);
		
		KvGetString(kvItemList, "particle_AutoKill", strLine, sizeof(strLine), "");
		SetArrayCell(cfg_Particle_AutoKill, totalRolls, StringToInt(strLine), 0);
		
		KvGetString(kvItemList, "particle_AttachToHead", strLine, sizeof(strLine), "");
		SetArrayCell(cfg_Particle_AttachToHead, totalRolls, StringToInt(strLine), 0);
		
		KvGetString(kvItemList, "particle_ZCorrection", strLine, sizeof(strLine), "");
		SetArrayCell(cfg_Particle_ZCorrection, totalRolls, StringToInt(strLine), 0);
		
		KvGetString(kvItemList, "required_weapon", strLine, sizeof(strLine), "");
		SetArrayCell(cfg_required_weapon, totalRolls, StringToInt(strLine), 0);
		
		KvGetString(kvItemList, "itemEquipped_OnBack", strLine, sizeof(strLine), "");
		SetArrayCell(cfg_itemEquipped_OnBack, totalRolls, StringToInt(strLine), 0);
		
		KvGetString(kvItemList, "ownerSteamID", strLine, sizeof(strLine), "");
		SetArrayString(cfg_OwnerSteamID, totalRolls, strLine);
		
		KvGetString(kvItemList, "disabledForMaps", strLine, sizeof(strLine), "");
		SetArrayString(cfg_disabledForMaps, totalRolls, strLine);
		
		totalRolls ++;
	}
	while (KvGotoNextKey(kvItemList));
	
	CloseHandle(kvItemList);

	//////////////////////////////////////////////////////
	//Match up the loaded configs with 'hard coded' ids //
	//////////////////////////////////////////////////////
	//lastFound = 0;
	
	//start comparing the 'hard codes' ids
	for(new i = 0; i < MAX_GOOD_AWARDS + MAX_BAD_AWARDS; i++)
	{
		//compare 'hard coded' id with loaded id from config 
		for(new step = 0; step < GetArraySize(cfg_ID); step++)
		{
			//Found a match
			GetArrayString(cfg_ID, step, strLine, 32);
			if(StrEqual(roll_id[i], strLine, false) && !StrEqual(roll_id[i], "", false) && !StrEqual(strLine, "", false))
			{
				//move the temp data into our main array
				GetArrayString(cfg_ID, step, roll_cfgID[i], 32);
				GetArrayString(cfg_Article, step, roll_Article[i], 8);
				GetArrayString(cfg_Text, step, roll_Text[i], 32);
				GetArrayString(cfg_QuickBuy, step, roll_QuickBuy[i], 64);
				GetArrayString(cfg_ActionText, step, roll_ActionText[i], 32);
				GetArrayString(cfg_Particle, step, roll_Particle[i], 32);
				GetArrayString(cfg_OwnerSteamID, step, roll_OwnerSteamID[i], 32);
				
				GetArrayString(cfg_ClassRestriction, step, strLine, 32);
				
				GetArrayString(cfg_disabledForMaps, step, roll_disabledForMaps[i], 64);
				
				//it's done this way so I can utilize TFClass types
				//also makes the config easier to understand
				if(StrEqual(strLine, "Scout", false)){
					roll_ClassRestriction[i] = TFClass_Scout;}
				else if(StrEqual(strLine, "Sniper", false)){
					roll_ClassRestriction[i] = TFClass_Sniper;}
				else if(StrEqual(strLine, "Soldier", false)){
					roll_ClassRestriction[i] = TFClass_Soldier;}
				else if(StrEqual(strLine, "DemoMan", false)){
					roll_ClassRestriction[i] = TFClass_DemoMan;}
				else if(StrEqual(strLine, "Medic", false)){
					roll_ClassRestriction[i] = TFClass_Medic;}
				else if(StrEqual(strLine, "Heavy", false)){
					roll_ClassRestriction[i] = TFClass_Heavy;}
				else if(StrEqual(strLine, "Pyro", false)){
					roll_ClassRestriction[i] = TFClass_Pyro;}
				else if(StrEqual(strLine, "Spy", false)){
					roll_ClassRestriction[i] = TFClass_Spy;}
				else if(StrEqual(strLine, "Engineer", false)){
					roll_ClassRestriction[i] = TFClass_Engineer;}
				else {
					roll_ClassRestriction[i] = TFClass_Unknown;
				}
				
				GetArrayString(cfg_ExcludeClass, step, strLine, 32);
				//it's done this way so I can utilize TFClass types
				//also makes the config easier to understand
				if(StrEqual(strLine, "Scout", false)){
					roll_ExcludeClass[i] = TFClass_Scout;}
				else if(StrEqual(strLine, "Sniper", false)){
					roll_ExcludeClass[i] = TFClass_Sniper;}
				else if(StrEqual(strLine, "Soldier", false)){
					roll_ExcludeClass[i] = TFClass_Soldier;}
				else if(StrEqual(strLine, "DemoMan", false)){
					roll_ExcludeClass[i] = TFClass_DemoMan;}
				else if(StrEqual(strLine, "Medic", false)){
					roll_ExcludeClass[i] = TFClass_Medic;}
				else if(StrEqual(strLine, "Heavy", false)){
					roll_ExcludeClass[i] = TFClass_Heavy;}
				else if(StrEqual(strLine, "Pyro", false)){
					roll_ExcludeClass[i] = TFClass_Pyro;}
				else if(StrEqual(strLine, "Spy", false)){
					roll_ExcludeClass[i] = TFClass_Spy;}
				else if(StrEqual(strLine, "Engineer", false)){
					roll_ExcludeClass[i] = TFClass_Engineer;}
				else {
					roll_ExcludeClass[i] = TFClass_Unknown;
				}
				
				
				roll_isGood[i]		= GetArrayCell(cfg_isGood, step, 0);
				roll_enabled[i]		= GetArrayCell(cfg_enabled, step, 0);
				roll_resetOnDeath[i]= GetArrayCell(cfg_resetOnDeath, step, 0);
				roll_EntLimit[i]	= GetArrayCell(cfg_EntLimit, step, 0);
				roll_inBeta[i]		= GetArrayCell(cfg_inBeta, step, 0);
				roll_purchasable[i] = GetArrayCell(cfg_purchasable, step, 0);
				roll_cost[i] 		= GetArrayCell(cfg_cost, step, 0);
				roll_isDeployable[i]= GetArrayCell(cfg_deployable, step, 0);
				roll_amountDeployable[i] = GetArrayCell(cfg_amountdeployable, step, 0);
				//not doing any replacements just need to know how many colons there are
				roll_amountTriggers[i] = ReplaceString(roll_QuickBuy[i], 64, ":", ":", false);
				//increase it by 1
				roll_amountTriggers[i] ++;
				
				roll_AmountDisabledMaps[i] = ReplaceString(roll_disabledForMaps[i], 64, ":", ":", false);
				if(!StrEqual(roll_disabledForMaps[i], "", false))
				{
					roll_AmountDisabledMaps[i] ++;
				}
				
				roll_CountDownTimer[i]	= GetArrayCell(cfg_CountDownTimer, step, 0);
				roll_TimerOverride[i]	= GetArrayCell(cfg_TimerOverride, step, 0);
				roll_AutoKill[i]		= GetArrayCell(cfg_Particle_AutoKill, step, 0);
				roll_AttachToHead[i]	= GetArrayCell(cfg_Particle_AttachToHead, step, 0);
				roll_ZCorrection[i]		= GetArrayCell(cfg_Particle_ZCorrection, step, 0);
				roll_required_weapon[i]	= GetArrayCell(cfg_required_weapon, step, 0);
				
				roll_itemEquipped_OnBack[i]	= GetArrayCell(cfg_itemEquipped_OnBack, step, 0);
				
				
				
				
				//PrintToServer("%s has %i triggers", roll_QuickBuy[i], roll_amountTriggers[i] );
				//Remove this set of arrays
				RemoveFromArray(cfg_ID, step);
				RemoveFromArray(cfg_isGood, step);
				RemoveFromArray(cfg_enabled, step);
				RemoveFromArray(cfg_resetOnDeath, step);
				RemoveFromArray(cfg_EntLimit, step);
				RemoveFromArray(cfg_inBeta, step);
				RemoveFromArray(cfg_purchasable, step);
				RemoveFromArray(cfg_cost, step);
				RemoveFromArray(cfg_Article, step);
				RemoveFromArray(cfg_Text, step);
				RemoveFromArray(cfg_QuickBuy, step);
				RemoveFromArray(cfg_ClassRestriction, step);
				RemoveFromArray(cfg_ExcludeClass, step);
				RemoveFromArray(cfg_deployable, step);
				RemoveFromArray(cfg_amountdeployable, step);
				RemoveFromArray(cfg_ActionText, step);
				RemoveFromArray(cfg_CountDownTimer, step);
				RemoveFromArray(cfg_TimerOverride, step);
				RemoveFromArray(cfg_Particle, step);
				RemoveFromArray(cfg_Particle_AutoKill, step);
				RemoveFromArray(cfg_Particle_AttachToHead, step);
				RemoveFromArray(cfg_Particle_ZCorrection, step);
				RemoveFromArray(cfg_required_weapon, step);
				RemoveFromArray(cfg_itemEquipped_OnBack, step);
				RemoveFromArray(cfg_OwnerSteamID, step);
				RemoveFromArray(cfg_disabledForMaps, step);
				break;
			}
		}
	}
	
	CloseHandle(cfg_ID);
	CloseHandle(cfg_isGood);
	CloseHandle(cfg_enabled);
	CloseHandle(cfg_resetOnDeath);
	CloseHandle(cfg_EntLimit);
	CloseHandle(cfg_inBeta);
	CloseHandle(cfg_purchasable);
	CloseHandle(cfg_cost);
	CloseHandle(cfg_Article);
	CloseHandle(cfg_Text);
	CloseHandle(cfg_QuickBuy);
	CloseHandle(cfg_ClassRestriction);
	CloseHandle(cfg_ExcludeClass);
	CloseHandle(cfg_deployable);
	CloseHandle(cfg_amountdeployable);
	CloseHandle(cfg_ActionText);	
	CloseHandle(cfg_CountDownTimer);
	CloseHandle(cfg_TimerOverride);
	CloseHandle(cfg_Particle);
	CloseHandle(cfg_Particle_AutoKill);
	CloseHandle(cfg_Particle_AttachToHead);
	CloseHandle(cfg_Particle_ZCorrection);
	CloseHandle(cfg_required_weapon);
	CloseHandle(cfg_itemEquipped_OnBack);
	CloseHandle(cfg_OwnerSteamID);
	CloseHandle(cfg_disabledForMaps);
	
}

public Load_DamageFilters()
{
	// Parse the objects list key values text to acquire all the Shop Perks
	new Handle:kvItemList = CreateKeyValues("Map_Damage_Filters");
	new String:strLocation[256];
	decl String:strMapName[32];
	decl String:currentMap[32];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	// Load the key files.
	BuildPath(Path_SM, strLocation, 256, "configs/rtd/map_damage_fiters.cfg");
	FileToKeyValues(kvItemList, strLocation);
	
	// Check if the parsed values are correct
	if (!KvGotoFirstSubKey(kvItemList)) 
	{ 
		LogToFile(logPath,"Error, can't read file containing Map_Damage_Filters: %s", strLocation);
		return; 
	}
	
	do
	{
		// Retrieve section name, which would be the map name
		KvGetSectionName(kvItemList,       strMapName,  32);
		
		//The sectionName corresponds to the map that the server is currently playing
		if(StrEqual(currentMap,strMapName,false))
		{
			KvGetString(kvItemList, "Blu",   bluDamageFilter, sizeof(bluDamageFilter)); 
			
			KvGetString(kvItemList, "Red",   redDamageFilter, sizeof(redDamageFilter)); 
		}
	}
	while (KvGotoNextKey(kvItemList));
	
	if(StrEqual(redDamageFilter, ""))
	{
		LogToFile(logPath,"DamageFilters are not set for map:%s",currentMap);
	}
}

Process_Disabled_Rolls()
{
	decl String:currentMap[64];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	//Load all those rolls that were loaded from the config
	for(new i = 0; i < MAX_GOOD_AWARDS + MAX_BAD_AWARDS; i ++)
	{
		if(roll_AmountDisabledMaps[i] > 0)
		{
			if(StrContains(roll_disabledForMaps[i], currentMap, false) != -1)
			{
				roll_enabled[i] = false;
			}
		}
	}
}