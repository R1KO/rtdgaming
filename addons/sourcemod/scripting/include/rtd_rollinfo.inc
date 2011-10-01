/**************************************************************************
 *                        RTD Rolls                          			 *
 *																		 *
 *It's in a include so that it is easier to work in Pawn Studio so that  *
 *when I'm typing it pops up :)                                          *
 *																		 *
 **************************************************************************/

 #if defined _rtd_rollinfo_included
 #endinput
#endif
#define _rtd_rollinfo_included

#define MAX_GOOD_AWARDS			80

#define AWARD_G_GODMODE			0
#define AWARD_G_TOXIC				1
#define AWARD_G_HEALTH			2
#define AWARD_G_SPEED				3
#define AWARD_G_NOCLIP 			4
#define AWARD_G_GRAVITY 			5
#define AWARD_G_UBER				6
#define AWARD_G_INVIS				7
#define AWARD_G_INSTANTKILL		8
#define AWARD_G_CLOAK				9
#define AWARD_G_CRITS				10
#define AWARD_G_SCOUTJUMP			11
#define AWARD_G_MEDIRAY			12
#define AWARD_G_REGEN				13
#define AWARD_G_INFIAMMO			14
#define AWARD_G_SENTRYBUILDER	15
#define AWARD_G_HULK				16
#define AWARD_G_CLASSIMMUNITY	17
#define AWARD_G_MEDICVIRUS		18
#define AWARD_G_UBERCHARGER		19
#define AWARD_G_ARMOR				20
#define AWARD_G_TEAMCRITS			21
#define AWARD_G_CROUCHINVIS		22
#define AWARD_G_PROXSTICKIES		23
#define AWARD_G_SLOWCUBE			24
#define AWARD_G_BOMB				25
#define AWARD_G_GROOVITRON		26
#define AWARD_G_CRAP				27
#define AWARD_G_SPIDER			28
#define AWARD_G_PUMPKIN			29
#define AWARD_G_FIREBULLETS		30
#define AWARD_G_ICE				31
#define AWARD_G_BERSERKER			32
#define AWARD_G_VAMPIRE			33
#define AWARD_G_INVISLOWHEALTH	34
#define AWARD_G_FLAME				35
#define AWARD_G_RAGE				36
#define AWARD_G_FIREBALL			37
#define AWARD_G_GHOST				38
#define AWARD_G_SANDWICH			39
#define AWARD_G_JUMPPAD			40
#define AWARD_G_ACCELERATOR		41
#define AWARD_G_ZOMBIE			42
#define AWARD_G_BACKPACK			43
#define AWARD_G_DIVIDETHESHOT	44
#define AWARD_G_AMPLIFIER			45
#define AWARD_G_PROXMINES			46
#define AWARD_G_BEARTRAP			47
#define AWARD_G_REFLECTSHIELD	48
#define AWARD_G_CAGE				49
#define AWARD_G_CRITSSPURT		50
#define AWARD_G_URINECLOUD		51
#define AWARD_G_DIGLETT			52
#define AWARD_G_METALMAN			53
#define AWARD_G_SAW				54
#define AWARD_G_COW				55
#define AWARD_G_HEAD				56
#define AWARD_G_BLIZZARD			57
#define AWARD_G_UBERBOW			58
#define AWARD_G_WINGS				59
#define AWARD_G_SUPPLYDROP		60
#define AWARD_G_JETPACK			61
#define AWARD_G_HEARTSAPLENTY	62
#define AWARD_G_DUMMY				63
#define AWARD_G_YOSHI				64
#define AWARD_G_MARKEDMURDERER 	65
#define AWARD_G_INSTAPORTER		66
#define AWARD_G_SNORLAX			67
#define AWARD_G_JARATEBULLETS	68
#define AWARD_G_BRAZIER			69
#define AWARD_G_MIRROR			70
#define AWARD_G_STONEWALL			71
#define AWARD_G_BUILDINGSHIELD	72
#define AWARD_G_SENTRYWRENCH		73
#define AWARD_G_FLAVOREDDAMAGE	74
#define AWARD_G_RUBBERBULLETS	75
#define AWARD_G_ICEBOMB			76
#define AWARD_G_FIREBOMB			77
#define AWARD_G_ANGELIC			78
#define AWARD_G_TREASURE			79

#define MAX_BAD_AWARDS			10

#define AWARD_B_LOSER				80
#define AWARD_B_NOJUMP			81
#define AWARD_B_IGNITE			82
#define AWARD_B_HEALTH			83
#define AWARD_B_WEAPONS			84
#define AWARD_B_TAUNT				85
#define AWARD_B_WAITMORE			86
#define AWARD_B_BADAIM			87
#define AWARD_B_DOOM				88
#define AWARD_B_SLOWMO			89

new String:roll_id[150][32]; //roll identifiers that match up with ;

stock SetupRoll_IDs()
{
	////////////////////////////////////////////
	// Setup for proper indexing when reading //
	// from roll config                       //
	////////////////////////////////////////////
	Format(roll_id[AWARD_G_GODMODE], 		32, "GODMODE");
	Format(roll_id[AWARD_G_TOXIC],			32, "TOXIC");
	Format(roll_id[AWARD_G_HEALTH],			32, "HEALTH");
	Format(roll_id[AWARD_G_SPEED],			32, "SPEED");
	Format(roll_id[AWARD_G_NOCLIP], 			32, "NOCLIP");
	Format(roll_id[AWARD_G_GRAVITY], 		32, "GRAVITY");
	Format(roll_id[AWARD_G_UBER], 			32, "UBER");
	Format(roll_id[AWARD_G_INVIS], 			32, "INVIS");
	Format(roll_id[AWARD_G_INSTANTKILL],		32, "INSTANTKILL");
	Format(roll_id[AWARD_G_CLOAK],			32, "CLOAK");
	Format(roll_id[AWARD_G_CRITS], 			32, "CRITS");
	Format(roll_id[AWARD_G_SCOUTJUMP], 		32, "SCOUTJUMP");
	Format(roll_id[AWARD_G_MEDIRAY], 		32, "MEDIRAY");
	Format(roll_id[AWARD_G_REGEN],			32, "REGEN");
	Format(roll_id[AWARD_G_INFIAMMO], 		32, "INFIAMMO");
	Format(roll_id[AWARD_G_SENTRYBUILDER], 	32, "SENTRYBUILDER");
	Format(roll_id[AWARD_G_HULK], 			32, "HULK");
	Format(roll_id[AWARD_G_CLASSIMMUNITY],	32, "CLASSIMMUNITY");
	Format(roll_id[AWARD_G_MEDICVIRUS], 		32, "MEDICVIRUS");
	Format(roll_id[AWARD_G_UBERCHARGER],		32, "UBERCHARGER");
	Format(roll_id[AWARD_G_ARMOR],			32, "ARMOR");
	Format(roll_id[AWARD_G_TEAMCRITS],		32, "TEAMCRITS");
	Format(roll_id[AWARD_G_CROUCHINVIS],		32, "CROUCHINVIS");
	Format(roll_id[AWARD_G_PROXSTICKIES], 	32, "PROXSTICKIES");
	Format(roll_id[AWARD_G_SLOWCUBE],		32, "SLOWCUBE");
	Format(roll_id[AWARD_G_BOMB], 			32, "BOMB");
	Format(roll_id[AWARD_G_GROOVITRON], 		32, "GROOVITRON");
	Format(roll_id[AWARD_G_CRAP], 			32, "CRAP");
	Format(roll_id[AWARD_G_SPIDER], 			32, "SPIDER");
	Format(roll_id[AWARD_G_PUMPKIN], 		32, "PUMPKIN");
	Format(roll_id[AWARD_G_FIREBULLETS], 	32, "FIREBULLETS");
	Format(roll_id[AWARD_G_ICE], 				32, "ICE");
	Format(roll_id[AWARD_G_BERSERKER], 		32, "BERSERKER");
	Format(roll_id[AWARD_G_VAMPIRE],			32, "VAMPIRE");
	Format(roll_id[AWARD_G_INVISLOWHEALTH], 32, "INVISLOWHEALTH");
	Format(roll_id[AWARD_G_FLAME], 			32, "FLAME");
	Format(roll_id[AWARD_G_RAGE], 			32, "RAGE");
	Format(roll_id[AWARD_G_FIREBALL], 		32, "FIREBALL");
	Format(roll_id[AWARD_G_GHOST], 			32, "GHOST");
	Format(roll_id[AWARD_G_SANDWICH], 		32, "SANDWICH");
	Format(roll_id[AWARD_G_JUMPPAD], 		32, "JUMPPAD");
	Format(roll_id[AWARD_G_ACCELERATOR], 	32, "ACCELERATOR");
	Format(roll_id[AWARD_G_ZOMBIE], 			32, "ZOMBIE");
	Format(roll_id[AWARD_G_BACKPACK], 		32, "BACKPACK");
	Format(roll_id[AWARD_G_DIVIDETHESHOT], 	32, "DIVIDETHESHOT");
	Format(roll_id[AWARD_G_AMPLIFIER], 		32, "AMPLIFIER");
	Format(roll_id[AWARD_G_PROXMINES], 		32, "PROXMINES");
	Format(roll_id[AWARD_G_BEARTRAP], 		32, "BEARTRAP");
	Format(roll_id[AWARD_G_REFLECTSHIELD], 	32, "REFLECTSHIELD");
	Format(roll_id[AWARD_G_CAGE], 			32, "CAGE");
	Format(roll_id[AWARD_G_CRITSSPURT], 		32, "CRITSSPURT");
	Format(roll_id[AWARD_G_URINECLOUD], 		32, "URINECLOUD");
	Format(roll_id[AWARD_G_DIGLETT], 		32, "DIGLETT");
	Format(roll_id[AWARD_G_METALMAN], 		32, "METALMAN");
	Format(roll_id[AWARD_G_SAW], 				32, "SAW");
	Format(roll_id[AWARD_G_COW], 				32, "COW");
	Format(roll_id[AWARD_G_HEAD], 			32, "HEAD");
	Format(roll_id[AWARD_G_BLIZZARD], 		32, "BLIZZARD");
	Format(roll_id[AWARD_G_UBERBOW], 		32, "UBERBOW");
	Format(roll_id[AWARD_G_WINGS], 			32, "WINGS");
	Format(roll_id[AWARD_G_SUPPLYDROP],		32, "SUPPLYDROP");
	Format(roll_id[AWARD_G_JETPACK],			32, "JETPACK");
	Format(roll_id[AWARD_G_HEARTSAPLENTY],	32, "HEARTSAPLENTY");
	Format(roll_id[AWARD_G_DUMMY],			32, "DUMMY");
	Format(roll_id[AWARD_G_YOSHI],			32, "YOSHI");
	Format(roll_id[AWARD_G_INSTAPORTER],		32, "INSTAPORTER");
	Format(roll_id[AWARD_G_SNORLAX],			32, "SNORLAX");
	Format(roll_id[AWARD_G_JARATEBULLETS],	32, "JARATEBULLETS");
	Format(roll_id[AWARD_G_BRAZIER],			32, "BRAZIER");
	Format(roll_id[AWARD_G_MIRROR],			32, "MIRROR");
	Format(roll_id[AWARD_G_STONEWALL],		32, "STONEWALL");
	Format(roll_id[AWARD_G_BUILDINGSHIELD],	32, "BUILDINGSHIELD");
	Format(roll_id[AWARD_G_SENTRYWRENCH],	32, "SENTRYWRENCH");
	Format(roll_id[AWARD_G_FLAVOREDDAMAGE],	32, "FLAVOREDDAMAGE");
	Format(roll_id[AWARD_G_RUBBERBULLETS],	32, "RUBBERBULLETS");
	Format(roll_id[AWARD_G_ICEBOMB],			32, "ICEBOMB");
	Format(roll_id[AWARD_G_FIREBOMB],		32, "FIREBOMB");
	Format(roll_id[AWARD_G_ANGELIC],			32, "ANGELIC");
	Format(roll_id[AWARD_G_TREASURE],		32, "TREASURE");
	
	Format(roll_id[AWARD_B_WEAPONS], 		32, "WEAPONS");
	Format(roll_id[AWARD_B_TAUNT], 			32, "TAUNT");
	Format(roll_id[AWARD_B_WAITMORE], 		32, "WAITMORE");
	Format(roll_id[AWARD_B_BADAIM], 			32, "BADAIM");
	Format(roll_id[AWARD_B_LOSER], 			32, "LOSER");
	Format(roll_id[AWARD_B_NOJUMP], 			32, "NOJUMP");
	Format(roll_id[AWARD_B_IGNITE], 			32, "IGNITE");
	Format(roll_id[AWARD_B_HEALTH], 			32, "HEALTH");
	Format(roll_id[AWARD_B_DOOM], 			32, "DOOM");
	Format(roll_id[AWARD_B_SLOWMO], 			32, "SLOWMO");
	
	return;
}