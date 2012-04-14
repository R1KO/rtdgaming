new Handle:c_Debug   = INVALID_HANDLE;
new Handle:c_Enabled   = INVALID_HANDLE;
new Handle:c_Timelimit = INVALID_HANDLE;
new Handle:c_Mode	   = INVALID_HANDLE;
new Handle:c_Disabled  = INVALID_HANDLE;
new Handle:c_Duration  = INVALID_HANDLE;
new Handle:c_Teamlimit = INVALID_HANDLE;
new Handle:c_Chance	   = INVALID_HANDLE;
new Handle:c_Health	   = INVALID_HANDLE;
new Handle:c_Gravity   = INVALID_HANDLE;
new Handle:c_Trigger   = INVALID_HANDLE;
new Handle:c_CreditsTrigger   = INVALID_HANDLE;
new Handle:c_Dice_MinPlayers   = INVALID_HANDLE;
new Handle:c_Dice_RespawnTime   = INVALID_HANDLE;
new Handle:c_Dice_RareSpawn   = INVALID_HANDLE;
new Handle:c_Dice_Debug   = INVALID_HANDLE;
new Handle:c_Dice_Deposits = INVALID_HANDLE;
new Handle:c_Dice_Multiplier = INVALID_HANDLE;
new Handle:c_CreditRate = INVALID_HANDLE;
new Handle:c_ShopDiscount = INVALID_HANDLE;
new Handle:c_MaxMineAmount = INVALID_HANDLE;
new Handle:c_GiftDiscount = INVALID_HANDLE;
new Handle:c_Increased_Deployable_Enabled = INVALID_HANDLE;
new Handle:c_Increased_Deployable_Amount = INVALID_HANDLE;
new Handle:c_Increased_Deployable_Chance = INVALID_HANDLE;

new Handle:c_AmountToResetPerks = INVALID_HANDLE;
new Handle:c_AmountToResetEventPerks = INVALID_HANDLE;	

new Handle:g_TimerExtendDatapack = INVALID_HANDLE;
new Handle:c_AllowRTDAdminMenu = INVALID_HANDLE;	
new Handle:c_UnusualRoll_Shop_Chance = INVALID_HANDLE;
new Handle:c_Classic = INVALID_HANDLE;
new Handle:c_Trinkets = INVALID_HANDLE;
new Handle:c_TrinketPrice = INVALID_HANDLE;
new Handle:c_TrinketReRollPrice = INVALID_HANDLE;

new Handle:c_Event_MLK = INVALID_HANDLE;

new g_oFOV, g_oDefFOV;

/**
	0 - Is client in a yoshi egg?
	1 - Time they were placed in the yoshi egg.
	2 - Are they in the air about to be killed?
**/
new yoshi_eaten[cMaxClients][3];
new clientSpawnTime[cMaxClients];

new Handle:g_instaporter[cMaxClients] = INVALID_HANDLE;

new Handle:db = INVALID_HANDLE;			/** Database connection */
new bool:g_BCONNECTED = false;
new m_bCarried;

//--My Variables---------------------------
new HudMsg1		= 0; //RTD Time: %i
new HudMsg2		= 1; //Credits: %i
new HudMsg3		= 2; //RTD won text
new HudMsg4		= 3; //RTD Countdown: %i of %i
new HudMsg5		= 4; //Armor %i of %i
new HudMsg6		= 5; //Immunity - Right Click hud

//Offsets Handling
new Handle:g_hDetonate;
new Handle:GameConf = INVALID_HANDLE;

new totalRolls; //used to keep track of amount of rolls loaded from config
//Current limit that can be read from cfg is 200, cause that's a nice number
new roll_isGood[200];
new roll_enabled[200];
new roll_resetOnDeath[200];
new roll_EntLimit[200];
new roll_inBeta[200];
new roll_purchasable[200];
new roll_cost[200];
new roll_amountTriggers[200];
new roll_isDeployable[200];
new roll_amountDeployable[200];
new String:roll_cfgID[200][32]; //this is matched against roll_id
new String:roll_Article[200][8];
new String:roll_Text[200][32];
new String:roll_QuickBuy[200][64];

new String:roll_ActionText[200][32];
new roll_CountDownTimer[200];
new roll_TimerOverride[200];
new String:roll_Particle[200][32];
new bool:roll_AutoKill[200];
new bool:roll_AttachToHead[200];
new roll_ZCorrection[200];
new roll_required_weapon[200];
new roll_itemEquipped_OnBack[200];
new String:roll_OwnerSteamID[200][32];

new String:roll_disabledForMaps[200][64];
new String:roll_AmountDisabledMaps[200];

new roll_Unusual[200];

new isNewUser[cMaxClients];
new TFClassType:roll_ClassRestriction[200];
new TFClassType:roll_ExcludeClass[200];

new client_rolls[cMaxClients][200][11];
//10 = mark unusual

new inTimerBasedRoll[cMaxClients];

new OldScore[cMaxClients];
new RightClickedDown[cMaxClients]; //Keeps track of whether the user is still holding right-click
new holdingRightClick[cMaxClients]; //Keeps track of whether the user is still holding right-click

new g_jumpOffset;
new Float:amountOfBadRolls[cMaxClients];

new isUserDucking[cMaxClients];
new crouchInvisAlpha[cMaxClients];

//new beingHealed[cMaxClients][3];
new BoughtSomething[cMaxClients];
new idOfReceiver[cMaxClients];

new RTDCredits[cMaxClients];
new RTDdice[cMaxClients];
new RTDOptions[cMaxClients][10];

new Float:HUDxPos[cMaxClients][3];
new Float:HUDyPos[cMaxClients][3];
new bool:movingHUD[cMaxClients];
new moveHUDStage[cMaxClients];
new bool:dmgDebug[cMaxClients];
new bool:diceDebug[cMaxClients];
new lastAttackerOnPlayer[cMaxClients];
new timerMessage;

//Players can now have up to 5 particles attached to them
new RTDParticle[cMaxClients][5];


new g_FilteredEntity = -1;
new NoClipThisLife[cMaxClients];
new beingSlowCubed[cMaxClients];
new inSlowCube[cMaxClients];
new lastdamage[cMaxClients];
new inBombBlastZone[cMaxClients];

new credsUsed[cMaxClients][2];
new creds_Gifted[cMaxClients];
new creds_ReceivedFromGifts[cMaxClients];

new giftingTo[cMaxClients];
new giftingCost[cMaxClients];
new beingGifted[cMaxClients];
new acceptedGift[cMaxClients];
new inWaitingToGift[cMaxClients];

new amountToGive[cMaxClients]; //used for givecreds ##

new Float:ROFMult[MAXPLAYERS+1];

new bool:areStatsLoaded[cMaxClients];
new VoiceOptions[cMaxClients];

new bool:roundEnded;
new roundStartTime;
new bool:autoBalanced[cMaxClients];

new bool:inIce[cMaxClients];
new inIceEnt[cMaxClients];

new isBetaUser[cMaxClients];
new talentPoints[cMaxClients];
new nextTimeOfRndFire[cMaxClients];

new clientMaxHealth[cMaxClients];
new lookingAtPickup[cMaxClients][2]; // used to keep track if player is looking at a cow or spider
new itemEquipped_OnBack[cMaxClients]; //keeps track whether player has something on their back
new clientItems[cMaxClients][11]; //keeps track of what items the client has
//---End Of my Variable------------------

new RTD_Timer[cMaxClients]; // 0 for end effects timer & 1 for repeating timer

new classHealth[10] = {0, 125, 125, 200, 175, 150, 300, 175, 125, 125};
new String:chatTriggers[MAX_CHAT_TRIGGERS][MAX_CHAT_TRIGGER_LENGTH];
new String:redDamageFilter[64];
new String:bluDamageFilter[64];

new g_iTriggers = 0;

new String:chatCreditTriggers[MAX_CHAT_TRIGGERS][MAX_CHAT_TRIGGER_LENGTH];
new g_iCreditTriggers = 0;

//Offsets
new g_cloakOffset;
new m_iMovementStunAmount;
new m_iStunFlags;
new m_hHealingTarget;
new m_nPlayerCond;
new m_nDisguiseTeam;
new m_nDisguiseClass;
new m_flMaxspeed;
new m_clrRender;
new m_bCarryingObject;
new m_fFlags;
new m_flEnergyDrinkMeter;
new m_flChargeMeter;
new iAmmoTable;

new bool:lateLoaded = false;

//Model Indexes -- Makes deletion checks so much easier
new modelIndex[200];
new totModels = 0;
new bombModelIndex;
new mineModelIndex;
new amplifierModelIndex;
new presentModelIndex[6];
new zombieModelIndex[11];
new backpackModelIndex[4];
new diceModelIndex;
new diceDepositModelIndex;
new bearTrapModelIndex;
new cageModelIndex;
new iceModelIndex;
new spiderIndex;
new spiderBackIndex;
new cloudIndex;
new cloud02Index;
new diglettModelIndex;
new dugTrioModelIndex;
new crapModelIndex;
new sawModelIndex;
new cowModelIndex;
new cowOnBackModelIndex;
new milkbottleModelIndex;
new jumpPadModelIndex;
new slowcubeModelIndex;
new rollermineModelIndex;
new pumpkinModelIndex;
new groovitronModelIndex;
new ghostModelIndex[2];
new blizzardModelIndex[2];
new wingsModelIndex;
new redbullModelIndex;
new dummyModelIndex;
new snorlaxModelIndex;
new instaPorterModelIndex;
new brazierModelIndex;
new stonewallModelIndex[2];
new shieldModelIndex;
new angelicModelIndex;
new sliceModelIndex;
new strengthModelIndex[2];
new pattycakeModelIndex;

new diceNeeded;
new g_BeginScore[cMaxClients];
new String:lastBoughtRoll[cMaxClients][64];
new lastRoll[cMaxClients];

new credits_rate = 1;
new Float:shop_discount = 0.0;
new Float:gift_discount = 0.0;
new dice_multiplier = 1;
new dice_MinPlayers;
new dice_RespawnTime; //in minutes
new dice_RareSpawn;
new timeOfLastDiceSpawn;
new dicedeposit_timestamp[cMaxClients];
new diceOnMap;
new mineMaxAmount;
new allowRTDAdminMenu;
new unusualRoll_Shop_Chance;
new rtd_classic;
new rtd_trinket_enabled;
new rtd_trinketPrice;
new rtd_trinket_rerollPrice;
new moreDeployables; //enabled/disabled
new deployables_max;
new Float:deployables_chance = 0.5;
new reset_PerksCost;
new reset_EventPerksCost;
	
new currentRound = 1;
new Handle:g_Cvar_DiscoHeight, Handle:g_Cvar_DiscoRadius;

new BaseVelocityOffset;
new String:logPath[256];


new g_BeamSprite;
new g_HaloSprite;

new mediRayModelIndex;

new rtd_debug = 0;
new lastCoughed[cMaxClients];
new bool:showStartupMsg[cMaxClients];
public UserMsg:ShakeID;

new ScoreEnabled[MAXPLAYERS];

new tf2_WinningTeam;
new Float:inBlizzardTime[cMaxClients];
new bool:hasSentryImmunity[cMaxClients];
new Float:cvVSpeed = 600.0;
new Float:cvHSpeed = 2.5;
new Float:cvLife = 120.0;

new const TFClass_MaxAmmo[TFClassType][3] =
{
  {-1, -1, -1}, {32, 36, -1},
  {25, 75, -1}, {20, 32, -1},
  {16, 24, -1}, {150, -1, -1},
  {200, 32, -1}, {200, 32, -1},
  {24, -1, -1}, {32, 200, 200}
};


//Team Manager
new Handle:g_cookie_timeBlocked 	= INVALID_HANDLE,
	Handle:g_cookie_teamIndex		= INVALID_HANDLE;
new bool:g_bBlockDeath,
	g_BlockTime[cMaxClients],
	g_BlockTeam[cMaxClients],
	bool:g_bScramblePending,
	g_iScrambleDelay,
	g_iScrambleVotes,
	g_ScrambleVoted[cMaxClients];
new bool:g_bSaveRollsOnDeath;
new ScrambleMultiplier = 1;

// Timer for blocking overlay command (cheat flags)
new Handle:overlayTimer = INVALID_HANDLE;

// Whether a client is having an overlay shown
new bool:clientOverlay[MAXPLAYERS + 1];
new m_nWaterLevel;
new m_hOwnerEntity;
new lastSummon[MAXPLAYERS + 1];
new timeForNextAnnotation[MAXPLAYERS + 1];

////////////////
//  TRINKETS  //
////////////////
//trinket variables
new totalTrinkets = 0;

new String:trinket_Unique[MAX_TRINKETS][32];
new String:trinket_Title[MAX_TRINKETS][32];
new String:trinket_Identifier[MAX_TRINKETS][64];
new String:trinket_Description[MAX_TRINKETS][128];
new String:trinket_TierID[MAX_TRINKETS][5][32];

new trinket_Enabled[MAX_TRINKETS];
new trinket_Rarity[MAX_TRINKETS];
new trinket_Tiers[MAX_TRINKETS];
new trinket_BonusAmount[MAX_TRINKETS][4];
new trinket_TierChance[MAX_TRINKETS][4];
new trinket_Index[MAX_TRINKETS];
new trinket_TotalChance[MAX_TRINKETS];
new trinketChanceBounds[MAX_TRINKETS][4];

new RTD_TrinketActive[cMaxClients][MAX_TRINKETS + 1];
new RTD_TrinketBonus[cMaxClients][MAX_TRINKETS + 1];
new RTD_TrinketLevel[cMaxClients][MAX_TRINKETS + 1];
new RTD_TrinketMisc[cMaxClients][MAX_TRINKETS + 1];
new RTD_TrinketMisc_02[cMaxClients][MAX_TRINKETS + 1];

//player variables
new String:RTD_TrinketUnique[cMaxClients][50][32];
new RTD_TrinketTier[cMaxClients][50];
new RTD_TrinketIndex[cMaxClients][50];
new RTD_TrinketEquipped[cMaxClients][50];
new String:RTD_TrinketTitle[cMaxClients][32];
new RTD_TrinketEquipTime[cMaxClients];

new trading[cMaxClients][6];
new smelting[cMaxClients][3];

new donate_Amount[cMaxClients];
new String:donate_SteamID[cMaxClients][64];
new timeExpireScare[cMaxClients];
new wasJumping[cMaxClients];

new entityPickedUp[cMaxClients];
new rtd_TimeLimit;

new rtd_Event_MLK;
new rtd_Event_MLK_Data[cMaxClients];

new seedingLimit[cMaxClients];

new Float:superJumpVelocity[cMaxClients][3];