#define REQ_ADMINFLAG Admin_Ban
#define cDefault				0x01
#define cLightGreen 			0x03
#define cGreen					0x04
#define cDarkGreen  			0x05
#define cMaxClients 			34 //34 for sourcetv

#define DMG_ACID            (1 << 20)

//////ABOUT AWARDS/////////////////////////////////
//The order of the awards must not ever change!  //
//When ading a new award place it at the bottom  //
//and make sure to increase MAX_GOOD_AWARDS      //
///////////////////////////////////////////////////


#define Reset_On_Death			0
#define Check_Ent_Limit			1

#define PLAYER_STATUS			0
#define PLAYER_EFFECT			1
#define PLAYER_ENDTIME			2

#define RED_TEAM				2
#define BLUE_TEAM				3

#define SPAWN_FLAG				100

#define BLACK					{0,0,0,192}
#define GREEN					{0,255,0,255}
#define INVIS					{255,255,255,0}
#define NORMAL					{255,255,255,255}

#define FROZEN					{100,100,255,105}

#define MAX_CHAT_TRIGGERS		15
#define MAX_CHAT_TRIGGER_LENGTH 15

// TF2 Classes
#define TF2_SCOUT 1
#define TF2_SNIPER 2
#define TF2_SOLDIER 3 
#define TF2_DEMOMAN 4
#define TF2_MEDIC 5
#define TF2_HEAVY 6
#define TF2_PYRO 7
#define TF2_SPY 8
#define TF2_ENG 9

#define SOUND_EATSANDVICH 		"vo/SandwichEat09.wav"
#define SOUND_NULL				"vo/null.wav"

#define DECAL_DDR		"materials/rtdgaming/ddr2.vtf"

#define SOUND_SENTRY_EXPLODE	"weapons/sentry_explode.wav"
#define SOUND_A 				"weapons/medigun_no_target.wav"
#define SOUND_B 				"items/spawn_item.wav"
#define SOUND_C 				"ui/hint.wav"
#define SOUND_D 				"weapons/dispenser_heal.wav"
#define SOUND_E 				"weapons/sentry_explode.wav"

#define SlowCube_Enter			"rtdgaming/slowcube_enter.mp3"
#define SlowCube_Exit			"rtdgaming/slowcube_exit.mp3"
#define SlowCube_Idle			"rtdgaming/slowcube0.wav"

#define Bomb_Explode			"weapons/pipe_bomb1.wav"
#define Bomb_Tick				"rtdgaming/bomb_tick.wav"
#define Bomb_Ready				"rtdgaming/alarm_clock_alarm_3.wav"

#define SOUND_FlameStart		"weapons/flame_thrower_start.wav"
#define SOUND_FlameLoop			"weapons/flame_thrower_loop.wav"
#define SOUND_FlameEnd			"weapons/flame_thrower_end.wav"
#define SOUND_SpiderTurn		"rtdgaming/spider_turn.wav"
#define SOUND_SpiderDie			"rtdgaming/spider_die.wav"
#define DiceFound				"misc/achievement_earned.wav"
#define SOUND_DiceAchievement	"rtdgaming/dice_achievement.wav"

#define SOUND_GROOVITRON		"rtdgaming/groovitron01.wav"
#define SOUND_BOUGHTSOMETHING	"rtdgaming/boughtsomething.wav"
#define SOUND_BOMB			    "rtdgaming/pepbombwise.wav"

#define MODEL_MINE				"models/rtdgaming/mines/mines.mdl"
#define MODEL_GROOVITRON		"models/rtdgaming/discoball/discoball.mdl"
#define MODEL_BOMB				"models/rtdgaming/bomb_v2/bomb.mdl"
#define MODEL_DICE				"models/rtdgaming/dice/dice.mdl"
#define MODEL_DICEDEPOSIT		"models/rtdgaming/dicedeposit_v2/dicedeposit.mdl"
#define MODEL_CRAP				"models/rtdgaming/crap_v2/crap.mdl"
#define MODEL_SHIELD04			"models/rtdgaming/shell/shell.mdl"
#define MODEL_SHIELD01			"models/rtdgaming/Shields/lvl01_shield.mdl"
#define MODEL_SHIELD02			"models/rtdgaming/Shields/lvl02_shield.mdl"
#define MODEL_SHIELD03			"models/rtdgaming/Shields/lvl03_shield.mdl"

#define MODEL_SPIDER			"models/rtdgaming/spiderv2/spider.mdl"
#define MODEL_SPIDERBACK		"models/rtdgaming/spider_on_back/spider_on_back.mdl"

#define MODEL_SPIDERBOX			"models/rtdgaming/spider/spidercollision.mdl"
#define MODEL_EXPLODINGPUMPKIN	"models/props_halloween/pumpkin_explode.mdl"
#define MODEL_GHOST				"models/props_halloween/ghost.mdl"
#define MODEL_GHOST_RED			"models/rtdgaming/ghost_red/ghost_red.mdl"

#define MODEL_AMPLIFIER			"models/rtdgaming/amplifier/amplifier.mdl"
#define MODEL_SLOWCUBE			"models/rtdgaming/slowcube/slowcube.mdl"
#define MODEL_LOCKER			"models/props_gameplay/resupply_locker.mdl"
#define MODEL_VOLLIGHT			"models/effects/vol_light128x128.mdl"
#define MODEL_ICE				"models/rtdgaming/icepatch_v2/icepatch.mdl"
#define MODEL_PINETREE			"models/props_foliage/tree_pine_extrasmall_snow.mdl"
#define MODEL_BARREL			"models/props_farm/wooden_barrel.mdl"
#define MODEL_STAIRS			"models/props_trainyard/portable_stairs001.mdl"
#define MODEL_HASTEBANNER		"models/rtdgaming/hastebanner/hastebanner.mdl"
#define MODEL_SANDWICH			"models/items/plate.mdl"
#define MODEL_ACCELERATOR		"models/rtdgaming/accelerator/accelerator.mdl"
#define MODEL_HEART				"models/rtdgaming/heart/heart.mdl"

#define MODEL_PRESENT01			"models/rtdgaming/presents/bday_gib01.mdl"
#define MODEL_PRESENT02			"models/rtdgaming/presents/bday_gib02.mdl"
#define MODEL_PRESENT03			"models/rtdgaming/presents/bday_gib03.mdl"
#define MODEL_PRESENT04			"models/rtdgaming/presents/bday_gib04.mdl"
#define MODEL_PRESENT05			"models/props_halloween/halloween_gift.mdl"

#define SOUND_CRAPSTRAIN		"rtdgaming/poop.wav"
#define SOUND_CRAPIDLE			"rtdgaming/buzz.wav"
#define SOUND_SHIELDBREAK		"player/spy_shield_break.wav"
#define SOUND_PUMPKINDROP		"items/pumpkin_drop.wav"

#define SOUND_FLAMEOUT		"player/flame_out.wav"

#define SSphere_Heal 			"items/gunpickup2.wav"
#define SPRITE_PHYSBEAM			"materials/sprites/physbeam.vmt"

//Yoshi stuffs
#define MODEL_YOSHI_RED					"models/yoshi/yoshi2.mdl"
#define MODEL_YOSHI_BLU					"models/yoshi/yoshi3.mdl"
#define MODEL_YOSHI_EGG				"models/yoshi/egg.mdl"
#define SOUND_YOSHI_BECOMEEGG		"rtdgaming/yoshi/BecomeEgg.wav"
#define SOUND_YOSHI_BECOMEYOSHI	"rtdgaming/yoshi/BecomeYoshi.wav"
#define SOUND_YOSHI_BREAKOUT			"rtdgaming/yoshi/Saved.wav"
#define SOUND_YOSHI_EGGEXPLODE		"rtdgaming/yoshi/EggExplode.wav"
#define SOUND_YOSHI_INSIDEEGG			"rtdgaming/yoshi/InsideEgg.wav"
#define SOUND_YOSHI_YOSHIDIE			"rtdgaming/yoshi/YoshiDie.wav"

#define SOUND_MEDIGUNHEAL 				"weapons/medigun_heal.wav"
#define SOUND_SPIDERYELLMEDIC 			"vo/scout_medic02.wav"
#define SOUND_SPIDERTHANKSMEDIC1 		"vo/scout_thanksfortheheal01.wav"
#define SOUND_SPIDERTHANKSMEDIC2 		"vo/scout_thanksfortheheal02.wav"
#define SOUND_SPIDERTHANKSMEDIC3 		"vo/scout_thanksfortheheal03.wav"
#define SOUND_SPIDERTHANKS1 			"vo/scout_thanks01.wav"
#define SOUND_SPIDERTHANKS2 			"vo/scout_thanks02.wav"
#define SOUND_SPIDERKILL01	 			"vo/scout_positivevocalization01.wav"
#define SOUND_SPIDERKILL02	 			"vo/scout_positivevocalization02.wav"
#define SOUND_SPIDERKILL03	 			"vo/scout_positivevocalization03.wav"
#define SOUND_SPIDERKILL04	 			"vo/scout_positivevocalization04.wav"
#define SOUND_SPIDERKILL05	 			"vo/scout_positivevocalization05.wav"
#define SOUND_SPIDERNEEDSENTRY 			"vo/scout_needsentry01.wav"
#define SOUND_SPIDERNEEDDISPENSER 		"vo/scout_needdispenser01.wav"
#define SOUND_SPIDERNEEDTELE 			"vo/scout_needteleporter01.wav"

#define SOUND_SPIDERMEDICFOLLOW01		"vo/scout_medicfollow01.wav"
#define SOUND_SPIDERMEDICFOLLOW02		"vo/scout_medicfollow02.wav"
#define SOUND_SPIDERMEDICFOLLOW03		"vo/scout_medicfollow03.wav"
#define SOUND_SPIDERMEDICFOLLOW04		"vo/scout_medicfollow04.wav"

#define SOUND_SPIDERMELEEDARE01			"vo/scout_meleedare01.wav"
#define SOUND_SPIDERMELEEDARE02			"vo/scout_meleedare02.wav"
#define SOUND_SPIDERMELEEDARE03			"vo/scout_meleedare03.wav"
#define SOUND_SPIDERMELEEDARE04			"vo/scout_meleedare04.wav"
#define SOUND_SPIDERMELEEDARE05			"vo/scout_meleedare05.wav"
#define SOUND_SPIDERMELEEDARE06			"vo/scout_meleedare06.wav"

#define SOUND_SPIDERMOVEUP01			"vo/scout_moveup01.wav"
#define SOUND_SPIDERMOVEUP02			"vo/scout_moveup02.wav"
#define SOUND_SPIDERMOVEUP03			"vo/scout_moveup03.wav"

#define SOUND_SPIDERMOVEUP04			"vo/scout_go01.wav"
#define SOUND_SPIDERMOVEUP05			"vo/scout_go02.wav"
#define SOUND_SPIDERMOVEUP06			"vo/scout_go03.wav"
#define SOUND_SPIDERMOVEUP07			"vo/scout_go04.wav"

#define SOUND_SPIDERHELPME01			"vo/scout_helpme01.wav"
#define SOUND_SPIDERHELPME02			"vo/scout_helpme02.wav"
#define SOUND_SPIDERHELPME03			"vo/scout_helpme03.wav"
#define SOUND_SPIDERHELPME04			"vo/scout_helpme04.wav"
#define SOUND_SPIDERTIRED				"player/pl_scout_dodge_tired.wav"
#define SOUND_SPIDERACTIVATECHARGE01	"vo/scout_activatecharge01.wav"
#define SOUND_SPIDERACTIVATECHARGE02	"vo/scout_activatecharge01.wav"
#define SOUND_SPIDERACTIVATECHARGE03	"vo/scout_activatecharge01.wav"
#define SOUND_SPIDERCLOAKEDSPY01		"vo/scout_cloakedspyidentify01.wav"
#define SOUND_SPIDERCLOAKEDSPY02		"vo/scout_cloakedspyidentify02.wav"
#define SOUND_SPIDERCLOAKEDSPY03		"vo/scout_cloakedspyidentify03.wav"
#define SOUND_SPIDERCLOAKEDSPY04		"vo/scout_cloakedspyidentify04.wav"
#define SOUND_SPIDERCLOAKEDSPY05		"vo/scout_cloakedspyidentify05.wav"
#define SOUND_SPIDERCLOAKEDSPY06		"vo/scout_cloakedspyidentify06.wav"
#define SOUND_SPIDERCLOAKEDSPY07		"vo/scout_cloakedspyidentify07.wav"
#define SOUND_SPIDERCLOAKEDSPY08		"vo/scout_cloakedspyidentify08.wav"
#define SOUND_SPIDERCLOAKEDSPY09		"vo/scout_cloakedspyidentify09.wav"
#define SOUND_SPIDERSPY01				"vo/scout_cloakedspy01.wav"
#define SOUND_SPIDERSPY02				"vo/scout_cloakedspy02.wav"
#define SOUND_SPIDERSPY03				"vo/scout_cloakedspy03.wav"
#define SOUND_SPIDERSPY04				"vo/scout_cloakedspy04.wav"

#define SOUND_SPIDERSHURT01			"vo/scout_painsharp01.wav"
#define SOUND_SPIDERSHURT02			"vo/scout_painsharp02.wav"
#define SOUND_SPIDERSHURT03			"vo/scout_painsharp03.wav"
#define SOUND_SPIDERSHURT04			"vo/scout_painsharp04.wav"
#define SOUND_SPIDERSHURT05			"vo/scout_painsharp05.wav"
#define SOUND_SPIDERSHURT06			"vo/scout_painsharp06.wav"
#define SOUND_SPIDERSHURT07			"vo/scout_painsharp07.wav"
#define SOUND_SPIDERSHURT08			"vo/scout_painsharp08.wav"

#define SOUND_SPIDERLAUGH01			"vo/scout_laughevil01.wav"
#define SOUND_SPIDERLAUGH02			"vo/scout_laughevil02.wav"
#define SOUND_SPIDERLAUGH03			"vo/scout_laughevil03.wav"

#define SOUND_SPIDERONFIRE01		"vo/scout_autoonfire01.wav"
#define SOUND_SPIDERONFIRE02		"vo/scout_autoonfire02.wav"

#define SOUND_DENY					"common/wpn_denyselect.wav"

#define SOUND_ICE					"ambient/windwinter.wav"

#define SOUND_REGENERATE		"items/regenerate.wav"
#define SOUND_PICKUP			"items/ammo_pickup.wav"
#define SOUND_MEDSHOT			"items/medshot4.wav"

#define SOUND_INSTAPORT				"weapons/teleporter_spin3.wav"
#define SOUND_INSTAPORT_TELE		"weapons/teleporter_ready.wav"
#define SOUND_INSTAPORT_EXPLODE		"weapons/teleporter_explode.wav"

#define SOUND_RTDREADY			"ui/item_acquired.wav"
#define SOUND_ROLL				"rtdgaming/diceroll.wav"

#define SOUND_BANNERFLAG		"weapons/buff_banner_flag.wav"
#define SOUND_HORN_BLUE			"weapons/buff_banner_horn_blue.wav"
#define SOUND_HORN_RED			"weapons/buff_banner_horn_red.wav"

#define SOUND_AMPLIFIER_HUM			"rtdgaming/amplifier_hum.wav"
#define SOUND_AMPLIFIER_HUM_02		"ambient/nucleus_electricity.wav"

#define SOUND_DISPENSER_GENERATE	"weapons/dispenser_generate_metal.wav"
#define SOUND_GHOST_MOAN1			"vo/halloween_moan1.wav"
#define SOUND_GHOST_MOAN2			"vo/halloween_moan2.wav"
#define SOUND_GHOST_MOAN3			"vo/halloween_moan3.wav"
#define SOUND_GHOST_MOAN4			"vo/halloween_moan4.wav"

#define SOUND_GHOST_BOO1			"vo/halloween_boo1.wav"
#define SOUND_GHOST_BOO2			"vo/halloween_boo2.wav"
#define SOUND_GHOST_BOO3			"vo/halloween_boo3.wav"
#define SOUND_GHOST_BOO4			"vo/halloween_boo4.wav"
#define SOUND_GHOST_BOO5			"vo/halloween_boo5.wav"
#define SOUND_GHOST_BOO6			"vo/halloween_boo6.wav"
#define SOUND_GHOST_BOO7			"vo/halloween_boo7.wav"

#define SOUND_GHOST_SCREAM1			"vo/halloween_scream1.wav"
#define SOUND_GHOST_SCREAM2			"vo/halloween_scream2.wav"
#define SOUND_GHOST_SCREAM3			"vo/halloween_scream3.wav"
#define SOUND_GHOST_SCREAM4			"vo/halloween_scream4.wav"
#define SOUND_GHOST_SCREAM5			"vo/halloween_scream5.wav"
#define SOUND_GHOST_SCREAM6			"vo/halloween_scream6.wav"
#define SOUND_GHOST_SCREAM7			"vo/halloween_scream7.wav"
#define SOUND_GHOST_SCREAM8			"vo/halloween_scream8.wav"

#define SOUND_WHOOSH				"rtdgaming/whoosh.wav"
#define SOUND_CREDITFOUND			"rtdgaming/creditfound.wav"
#define SOUND_PRESENT 				"misc/happy_birthday.wav"

#define MDL_JUMP "models/props_combine/combine_mine01.mdl"
#define SND_DROP "weapons/grenade_throw.wav"
#define SND_JUMP "weapons/airboat/airboat_gun_energy1.wav"
#define SND_JUMPEXPLODE "weapons/rocket_directhit_explode1.wav"

#define MODEL_ZOMBIE_CLASSIC			"models/Zombie/classic.mdl"
#define MODEL_ZOMBIE_02					"models/Zombie/classic_torso.mdl"
#define MODEL_ZOMBIE_03					"models/Zombie/poison.mdl"

#define MODEL_BACKPACK01				"models/rtdgaming/backpack/backpack.mdl"
#define MODEL_BACKPACK02				"models/rtdgaming/backpack/backpack_medium.mdl"
#define MODEL_BACKPACK03				"models/rtdgaming/backpack/backpack_heavy.mdl"
#define MODEL_BACKPACK04				"models/rtdgaming/backpack/backpack_veryheavy.mdl"

#define SOUND_ZOMBIE_PAIN_01			"npc/zombie/zombie_pain1.wav"
#define SOUND_ZOMBIE_PAIN_02			"npc/zombie/zombie_pain2.wav"
#define SOUND_ZOMBIE_PAIN_03			"npc/zombie/zombie_pain3.wav"
#define SOUND_ZOMBIE_PAIN_04			"npc/zombie/zombie_pain4.wav"
#define SOUND_ZOMBIE_PAIN_05			"npc/zombie/zombie_pain5.wav"
#define SOUND_ZOMBIE_PAIN_06			"npc/zombie/zombie_pain6.wav"

#define SOUND_ZOMBIE_STRIKE_01			"npc/zombie/claw_strike1.wav"
#define SOUND_ZOMBIE_STRIKE_02			"npc/zombie/claw_strike2.wav"
#define SOUND_ZOMBIE_STRIKE_03			"npc/zombie/claw_strike3.wav"

#define SOUND_ZOMBIE_MISS_01			"npc/zombie/claw_miss1.wav"
#define SOUND_ZOMBIE_MISS_02			"npc/zombie/claw_miss2.wav"

#define SOUND_ZOMBIE_FOOT_01			"player/footsteps/dirt2.wav"
#define SOUND_ITEM_EQUIP				"player/taunt_equipment_gun1.wav"
#define SOUND_ITEM_EQUIP_02				"player/taunt_equipment_gun2.wav"

#define SOUND_MINEATTACH				"rtdgaming/mines/attach.wav"
#define SOUND_MINETHROW					"rtdgaming/mines/mine_throw1.wav"
#define SOUND_MINEBEEP					"rtdgaming/mines/minedrawbeep.wav"
#define SOUND_MINEREADY					"rtdgaming/mines/proxymineF4C5.wav"

#define SOUND_MINE_RANGE_VERYCLOSE		"rtdgaming/mines/proxymine_range_veryclose.wav"
#define SOUND_MINE_RANGE_CLOSE			"rtdgaming/mines/proxymine_range_close.wav"
#define SOUND_MINE_RANGE_MEDIUM			"rtdgaming/mines/proxymine_range_medium.wav"
#define SOUND_MINE_RANGE_FAR			"rtdgaming/mines/proxymine_range_far.wav"

#define MODEL_BEARTRAP					"models/rtdgaming/beartrap/beartrap.mdl"
#define SOUND_BEARTRAP_OPEN				"rtdgaming/trap_open.wav"
#define SOUND_BEARTRAP_CLOSE			"rtdgaming/trap_close.wav"

#define MODEL_MEDIRAY					"models/rtdgaming/medirayv4/medirayv4.mdl"
#define SOUND_MEDIRAY					"weapons/stickybomblauncher_charge_up.wav"
#define SOUND_MEDIRAYHEAL				"weapons/syringegun_reload_air2.wav"


#define SOUND_PYRO_AIRBLAST_REFLECT		"weapons/flame_thrower_airblast_rocket_redirect.wav"

#define SOUND_CAGECLOSE					"doors/door_chainlink_close1.wav"

#define MODEL_CAGE						"models/rtdgaming/cage/cage.mdl"

#define MODEL_CLOUD						"models/rtdgaming/cloud/cloud.mdl"
#define MODEL_CLOUD_ANGRY				"models/rtdgaming/cloud/cloud_angry.mdl"

#define SOUND_RAIN						"ambient/rain.wav"

#define MODEL_DIGLETT					"models/rtdgaming/Diglett/diglett.mdl"
#define MODEL_DUGTRIO					"models/rtdgaming/Diglett/dugtrio.mdl"

#define SOUND_DIGLETT					"diglett/diglett.mp3"
#define SOUND_DIGLETTDIG01				"diglett/diglettdig1.mp3"
#define SOUND_DIGLETTDIG02				"diglett/diglettdig2.mp3"
#define SOUND_DIGLETTDIG03				"diglett/diglettdig3.mp3"
#define SOUND_DUGTRIO					"diglett/triotriotrio.mp3"

#define SOUND_DIGLETT_UP				"diglett/appear.wav"
#define SOUND_DIGLETT_DOWN				"diglett/disappear.wav"
#define SOUND_RUMBLE01					"ambient/atmosphere/terrain_rumble1.wav"
#define SOUND_RUMBLE02					"diglett/rock1.wav"
#define SOUND_RUMBLE03					"diglett/rock2.wav"
#define SOUND_RUMBLE04					"diglett/rock3.wav"
#define SOUND_EVOLVE					"diglett/evolution.wav"

#define MODEL_PITCHMACHINE				"models/rtdgaming/pitchmachine/pitchmachine.mdl"
#define MODEL_PITCHMACHINE_BLU			"models/rtdgaming/pitchmachine_blu/pitchmachine.mdl"
#define PROJECTILE_BALL					"models/weapons/w_models/w_baseball.mdl"
#define SOUND_PITCHMACHINE_HUM			"ambient/machine_hum2.wav"
#define SOUND_PITCHMACHINE_HIT01		"weapons/bow_shoot.wav"
#define SOUND_PITCHMACHINE_HIT02		"weapons/bow_shoot.wav"

#define SOUND_PITCHMACHINE_STUN			"player/pl_impact_stun.wav"

#define SOUND_COUGH_01		"ambient/voices/cough1.wav"
#define SOUND_COUGH_02		"ambient/voices/cough2.wav"
#define SOUND_COUGH_03		"ambient/voices/cough3.wav"
#define SOUND_COUGH_04		"ambient/voices/cough4.wav"

//#define MODEL_TREX				"models/Dinosaurs/trex.mdl"
#define MODEL_SAW				"models/rtdgaming/saw_blade/saw_blade.mdl"
#define SOUND_SAW				"ambient/sawblade.wav"
#define SOUND_SAW_HIT			"ambient/sawblade_impact1.wav"

#define SOUND_RESET				"misc/freeze_cam_snapshot.wav"

#define SOUND_MELEE_MUSIC		"rtdgaming/melee_time.mp3"
#define SOUND_SPIDER_WEE		"rtdgaming/spider_wee.wav"

#define MODEL_COW		"models/rtdgaming/cow/cow.mdl"
#define MODEL_COWONBACK	"models/rtdgaming/cow/cowonback.mdl"
#define SOUND_COW1		"rtdgaming/cow1.wav"
#define SOUND_COW2		"rtdgaming/cow2.wav"
#define SOUND_COW3		"rtdgaming/cow3.wav"
#define MODEL_MILKBOTTLE		"models/rtdgaming/milk_bottle/milk_bottle.mdl"

#define SOUND_CLOAK		"player/spy_cloak.wav"
#define SOUND_UNCLOAK	"player/spy_uncloak.wav"

#define MODEL_BLIZZARDPACK			"models/rtdgaming/blizzardbackpack/blizzardbackpack.mdl"
#define MODEL_BLIZZARDPACK_FLOOR	"models/rtdgaming/blizzardbackpack/blizzardbackpack_onfloor.mdl"
#define SOUND_FROZEN				"rtdgaming/freezing01.wav"
#define SOUND_GLASSBREAK			"physics/glass/glass_impact_bullet4.wav"

#define SOUND_SLURP		"rtdgaming/slurp.wav"

#define MODEL_WINGS		"models/rtdgaming/redbull/wings.mdl"
#define MODEL_REDBULL	"models/rtdgaming/redbull/redbull.mdl"

#define MODEL_DUMMY			"models/rtdgaming/dummy/dummy.mdl"
#define SOUND_BOXINGHIT01	"weapons/boxing_gloves_swing1.wav"
#define SOUND_BOXINGHIT02	"weapons/boxing_gloves_swing2.wav"
#define SOUND_BOXINGHIT03	"weapons/boxing_gloves_swing3.wav"
#define SOUND_BOXINGHIT04	"weapons/boxing_gloves_swing4.wav"

#define SOUND_JARATE		"weapons/jar_explode.wav"

#define MODEL_SNORLAX		"models/rtdgaming/snorlax/snorlax.mdl"
#define SOUND_SNORLAX		"rtdgaming/snorlax_sleep_v2.wav"
#define SOUND_BOUNCE		"rtdgaming/bounce.wav"

//#define MODEL_FRIED_CHICKEN		"models/rtdgaming/fried_chicken/fried_chicken.mdl"

#define SOUND_ARMOR_IMPACT_01	"physics/metal/metal_solid_impact_bullet1.wav"
#define SOUND_ARMOR_IMPACT_02	"physics/metal/metal_solid_impact_bullet2.wav"
#define SOUND_ARMOR_IMPACT_03	"physics/metal/metal_solid_impact_bullet3.wav"
#define SOUND_ARMOR_IMPACT_04	"physics/metal/metal_solid_impact_bullet4.wav"
#define SOUND_ARMOR_BREAK_01	"weapons/physcannon/energy_disintegrate5.wav"

#define MODEL_INSTAPORTER		"models/rtdgaming/instaporter_v2/instaporter.mdl"

#define MODEL_AIRINTAKE			"models/rtdgaming/air_intake/air_intake.mdl"
#define MODEL_AIRINTAKE_FLOOR	"models/rtdgaming/air_intake/air_intake_floor.mdl"

//#define SOUND_SUCK_START	"rtdgaming/startsuck.wav"
//#define SOUND_SUCK_END		"rtdgaming/endsuck.wav"

#define SOUND_STARMAN		"rtdgaming/starman.wav"

#define SOUND_BOO				"vo/halloween_boss/knight_alert.wav"
#define SOUND_EVIL_LAUGH 		"rtdgaming/evillaugh.wav"
#define SOUND_BLIP				"buttons/blip1.wav"

#define SOUND_BRAZIER		"rtdgaming/fire_small1.wav"
#define SOUND_IGNITE_2		"ambient/fire/gascan_ignite1.wav"
#define SOUND_IGNITE		"ambient/fire/ignite.wav"
#define MODEL_BRAZIER		"models/props_medieval/brazier.mdl"

#define SOUND_SLOWMO		"rtdgaming/slowmo.mp3"

#define MODEL_STONEWALL			"models/rtdgaming/stonewall/stonewall.mdl"
#define MODEL_STONEWALL_FLOOR	"models/rtdgaming/stonewall/stonewall_floor.mdl"

#define SOUND_CONCRETE_IMPACT_01	"physics/concrete/concrete_block_impact_hard1.wav"
#define SOUND_CONCRETE_IMPACT_02	"physics/concrete/concrete_block_impact_hard2.wav"
#define SOUND_CONCRETE_IMPACT_03	"physics/concrete/concrete_block_impact_hard3.wav"

#define MODEL_SENTRYSHIELD		"models/buildables/sentry_shield.mdl"

#define SOUND_WHISTLE			"rtdgaming/whistle.wav"

#define SOUND_DROPCABINET		"rtdgaming/robsupps.wav"

#define MODEL_ANGELIC			"models/rtdgaming/angelic_v2/angelic.mdl"

#define SOUND_FLAP			"rtdgaming/flap.wav"

#define SOUND_OPEN_TRINKET	"rtdgaming/opentrinket.mp3"
#define SOUND_SHOP			"rtdgaming/shop.mp3"

#define SOUND_YOSHISONG 	"rtdgaming/yoshi.mp3"
#define SOUND_LOSERHANK		"rtdgaming/loser.mp3"
#define MODEL_DYNAMITE		"models/rtdgaming/dynamite/dynamite.mdl"

///////////////////////////////////////////////////////////////////////////////////////////////////////
#define MAX_LINE_WIDTH 128

#define SOUND_FIREWORK_EXPLODE1 "weapons/jar_explode.wav"
#define SOUND_FIREWORK_EXPLODE2 "misc/happy_birthday.wav"
#define SOUND_FIREWORK_EXPLODE3 "player/pl_impact_airblast2.wav"
#define EFFECT_FIREWORK "mini_fireworks"
#define EFFECT_FIREWORK_FLARE "mini_firework_flare"
#define EFFECT_FIREWORK_FLASH "teleported_flash"

//Team Manager
#define SCRAMBLE_SOUND "vo/announcer_am_teamscramble03.wav"
#define VOTE_NO "###no###"
#define VOTE_YES "###yes###"