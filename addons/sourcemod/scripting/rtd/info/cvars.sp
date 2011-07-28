rtd_load_cvars()
{
	CreateConVar("sm_rtd_version", PLUGIN_VERSION, "Current RTD Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	c_Enabled						= CreateConVar("sm_rtd_enable",							"1",		"<0/1> Enable RTD");
	c_Timelimit						= CreateConVar("sm_rtd_timelimit",						"120",		"<0-x> Time in seconds between RTDs");
	c_Mode							= CreateConVar("sm_rtd_mode",							"1",		"<0/1/2> See plugin's webpage for description");
	c_Disabled						= CreateConVar("sm_rtd_disabled",						"",			"All the effects you want disabled - Seperated by commas");
	c_Duration						= CreateConVar("sm_rtd_duration",						"20.0",		"<0.1-x> Time in seconds the RTD effects last.");
	c_Teamlimit						= CreateConVar("sm_rtd_teamlimit",						"1",		"<1-x> Number of players on the same team that can RTD in mode 1");
	c_Chance						= CreateConVar("sm_rtd_chance",							"0.5",		"<0.1-1.0> Chance of a good award.");
	
	c_Health						= CreateConVar("sm_rtd_health",							"4.0",		"<0.1-x> Health buff multiplier.");
	c_Gravity						= CreateConVar("sm_rtd_gravity",						"0.1",		"<0.1-x> Gravity multiplier.");
	c_Dice_MinPlayers				= CreateConVar("sm_rtd_dice_minplayers",				"8",		"<0-32> Minimum amount of players needed to spawn dice");
	c_Dice_RespawnTime				= CreateConVar("sm_rtd_dice_respawntime",				"10",		"<1-x> Time in minutes that dice should be respawned");
	c_Dice_Multiplier				= CreateConVar("sm_rtd_dice_multiplier",				"1",		"<1-x> Dice Multiplier, use with care");
	c_Dice_RareSpawn				= CreateConVar("sm_rtd_dice_rarespawn",					"5",		"<0-100> Number <= Roll for a rare dice to spawn(1-100, 3=3% chance)");
	c_Dice_Debug					= CreateConVar("sm_rtd_dice_debug",						"0",		"<0/1> Spawns all DICE and prevents them from being picked up");
	c_Dice_Deposits					= CreateConVar("sm_rtd_dice_deposits",					"1",		"<0/1> Enables deposits to be spawned");
	c_Trigger						= CreateConVar("sm_rtd_trigger",						"rtd,rollthedice,roll,rtdw,rtde,rtda,rtdf,rtds,rtd',rtd],rtd/",					"All the chat triggers - Seperated by commas.");
	c_CreditsTrigger				= CreateConVar("sm_rtd_creditstrigger",					"buy,credits,credit,shop,store,menu",	"All the chat triggers - Seperated by commas.");
	g_Cvar_DiscoHeight				= CreateConVar("groovitron_height",						"9",		"Sets the height to push a player", 0, true, 0.0, false, 0.0);
	g_Cvar_DiscoRadius				= CreateConVar("groovitron_radius",						"325",		"Sets the radius which to cause people to jump", 0, true, 0.0, false, 0.0);
	c_CreditRate					= CreateConVar("sm_rtd_creditrate",						"1",		"Amount of credits to give each minute");
	c_ShopDiscount					= CreateConVar("sm_rtd_shopdiscount",					"0.0",		"<0.0-1.0> Percentage to decrease the cost of shop purcases by");
	c_GiftDiscount					= CreateConVar("sm_rtd_giftdiscount",					"0.0",		"<0.0-1.0> Percentage to decrease the cost of gift purcases by");
	c_Debug							= CreateConVar("sm_rtd_debug",							"0",		"<0/1> Enables thorough Debug messages. Use with care.");
	c_MaxMineAmount					= CreateConVar("sm_rtd_mine_max_amount",				"1",		"<1-x> Max Amount of Dice that can be found from mining Dice Mines");
	
	c_Increased_Deployable_Enabled	= CreateConVar("sm_rtd_deployable_enabled",				"0",		"Allow more deployables than normal?");
	c_Increased_Deployable_Amount	= CreateConVar("sm_rtd_deployable_amount",				"1",		"<1-x> How much more should be allowed");
	c_Increased_Deployable_Chance	= CreateConVar("sm_rtd_deployable_chance",				"0.5",		"<0.0 - 1.0> Chance to give extra deployables");
	
	c_AmountToResetPerks			= CreateConVar("sm_rtd_perks_reset_amount",				"500",		"<1-x> Cost to reset Perks");
	c_AmountToResetEventPerks		= CreateConVar("sm_rtd_perks_event_reset_amount",		"100",		"<1-x> Cost to reset Event Perks");
	
	c_AllowRTDAdminMenu				= CreateConVar("sm_rtd_admin_menu",						"0",		"<0/1> Enable RTD admin menu");
	
	c_UnusualRoll_Shop_Chance		= CreateConVar("sm_rtd_unusualroll_shop",				"5",		"<0-100> Chance of unusual roll for shop");
	
	HookConVarChange(c_Dice_MinPlayers,				ConVarChange_RTD);
	HookConVarChange(c_Dice_RespawnTime,			ConVarChange_RTD);
	HookConVarChange(c_Dice_RareSpawn,				ConVarChange_RTD);
	HookConVarChange(c_Dice_Multiplier,				ConVarChange_RTD);
	HookConVarChange(c_Dice_Debug,					ConVarChange_RTD);
	HookConVarChange(c_Disabled,					ConVarChange_RTD);
	HookConVarChange(c_Trigger,						ConVarChange_RTD);
	HookConVarChange(c_CreditsTrigger,				ConVarChange_RTD);
	HookConVarChange(c_CreditRate,					ConVarChange_RTD);
	HookConVarChange(c_ShopDiscount,				ConVarChange_RTD);
	HookConVarChange(c_Debug,						ConVarChange_RTD);
	HookConVarChange(c_GiftDiscount,				ConVarChange_RTD);
	HookConVarChange(c_MaxMineAmount,				ConVarChange_RTD);
	
	HookConVarChange(c_Increased_Deployable_Enabled,			ConVarChange_RTD);
	HookConVarChange(c_Increased_Deployable_Amount,				ConVarChange_RTD);
	HookConVarChange(c_Increased_Deployable_Chance,				ConVarChange_RTD);
	
	HookConVarChange(c_AmountToResetPerks,			ConVarChange_RTD);
	HookConVarChange(c_AmountToResetEventPerks,		ConVarChange_RTD);
	
	HookConVarChange(c_AllowRTDAdminMenu,			ConVarChange_RTD);
	HookConVarChange(c_UnusualRoll_Shop_Chance,		ConVarChange_RTD);
}

rtd_load_cvar_configs()
{
	new String:strConVar[200];
	
	GetConVarString(c_Trigger, strConVar, sizeof(strConVar));
	Parse_Chat_Triggers(strConVar);
	
	GetConVarString(c_CreditsTrigger, strConVar, sizeof(strConVar));
	Parse_Chat_CreditTriggers(strConVar);
	
	dice_MinPlayers			= GetConVarInt(c_Dice_MinPlayers);
	dice_RespawnTime		= GetConVarInt(c_Dice_RespawnTime) * 60;
	dice_RareSpawn			= GetConVarInt(c_Dice_RareSpawn);
	dice_multiplier			= GetConVarInt(c_Dice_Multiplier);
	credits_rate			= GetConVarInt(c_CreditRate);
	shop_discount			= GetConVarFloat(c_ShopDiscount);
	gift_discount			= GetConVarFloat(c_GiftDiscount);
	rtd_debug				= GetConVarInt(c_Debug);
	mineMaxAmount			= GetConVarInt(c_MaxMineAmount);
	
	moreDeployables			= GetConVarInt(c_Increased_Deployable_Enabled);
	deployables_max			= GetConVarInt(c_Increased_Deployable_Amount);
	deployables_chance		= GetConVarFloat(c_Increased_Deployable_Chance);
	
	reset_PerksCost			= GetConVarInt(c_AmountToResetPerks);
	reset_EventPerksCost	= GetConVarInt(c_AmountToResetEventPerks);
	
	allowRTDAdminMenu = GetConVarInt(c_AllowRTDAdminMenu);
	
	unusualRoll_Shop_Chance =  GetConVarInt(c_UnusualRoll_Shop_Chance);
}

public ConVarChange_RTD(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == c_Dice_MinPlayers)
	{
		dice_MinPlayers = GetConVarInt(c_Dice_MinPlayers);
		if(dice_MinPlayers < 0)
		{
			SetConVarInt(c_Dice_MinPlayers, 0);
			dice_MinPlayers = 0;
		}
		PrintToChatAll("[RTD] Minimum players to spawn dice changed to: %i",dice_MinPlayers);
	}
	else if(convar == c_Dice_RespawnTime)
	{
		dice_RespawnTime = GetConVarInt(c_Dice_RespawnTime) * 60;
		if(dice_RespawnTime < 1)
		{
			SetConVarInt(c_Dice_RespawnTime, 1);
			dice_RespawnTime = 60;
		}
		PrintToChatAll("[RTD] Dice Respawn Time changed to: %i mins",GetConVarInt(c_Dice_RespawnTime));
	}
	else if(convar == c_Dice_RareSpawn)
	{
		dice_RareSpawn = GetConVarInt(c_Dice_RareSpawn);
	}
	else if(convar == c_Dice_Multiplier)
	{
		dice_multiplier = GetConVarInt(c_Dice_Multiplier);
	}
	else if(convar == c_Dice_Debug)
	{
		//respawn the dice when this variable changes
		Item_ParseList();
		SetupDiceSpawns();
	}
	else if(convar == c_Trigger)
	{
		Parse_Chat_Triggers(newValue);
		PrintToChatAll("[RTD] Chat triggers reparsed.");
	}
	else if(convar == c_CreditsTrigger)
	{
		Parse_Chat_CreditTriggers(newValue);
		PrintToChatAll("[RTD] Credits Chat triggers reparsed.");
	}
	else if(convar == c_Dice_Multiplier)
	{
		dice_multiplier = GetConVarInt(c_Dice_Multiplier);
	}
	else if(convar == c_CreditRate)
	{
		credits_rate = GetConVarInt(c_CreditRate);
	}
	else if(convar == c_ShopDiscount)
	{
		shop_discount = GetConVarFloat(c_ShopDiscount);
	}
	else if(convar == c_GiftDiscount)
	{
		gift_discount = GetConVarFloat(c_GiftDiscount);
	}
	else if(convar == c_Debug)
	{
		rtd_debug = GetConVarInt(c_Debug);
	}
	else if(convar == c_MaxMineAmount)
	{
		mineMaxAmount = GetConVarInt(c_MaxMineAmount);
	}else if(convar == c_Increased_Deployable_Enabled)
	{
		moreDeployables	= GetConVarInt(c_Increased_Deployable_Enabled);
	}else if(convar == c_Increased_Deployable_Amount)
	{
		deployables_max	= GetConVarInt(c_Increased_Deployable_Amount);
	}else if(convar == c_Increased_Deployable_Chance)
	{
		deployables_chance	= GetConVarFloat(c_Increased_Deployable_Chance);
	}else if(convar == c_AmountToResetPerks)
	{
		reset_PerksCost	= GetConVarInt(c_AmountToResetPerks);
	}else if(convar == c_AmountToResetEventPerks)
	{
		reset_EventPerksCost	= GetConVarInt(c_AmountToResetEventPerks);
	}else if(convar == c_AllowRTDAdminMenu)
	{
		allowRTDAdminMenu	= GetConVarInt(c_AllowRTDAdminMenu);
	}else if(convar == c_UnusualRoll_Shop_Chance)
	{
		unusualRoll_Shop_Chance =  GetConVarInt(c_UnusualRoll_Shop_Chance);
	}
}