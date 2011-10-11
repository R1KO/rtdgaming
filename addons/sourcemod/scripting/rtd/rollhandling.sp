#include <sourcemod>
#include <tf2_stocks>
#include <rtd_rollinfo>

stock bool:RollTheDice(client)
{
	EmitSoundToClient(client, SOUND_ROLL);
	
	new bool:goodCommand = false;
	new bound[2];
	
	//determine if roll will be good
	if((GetConVarFloat(c_Chance) + amountOfBadRolls[client] + (float(RTD_Perks[client][1] + RTD_Perks[client][21] + RTD_TrinketBonus[client][TRINKET_LADYLUCK])*0.01)) > GetRandomFloat(0.0, 1.0)) 
		goodCommand = true;
	
	if(goodCommand)
	{
		bound[0] = 0; 
		bound[1] = MAX_GOOD_AWARDS; 
	}else{
		bound[0] = MAX_GOOD_AWARDS; 
		bound[1] = MAX_GOOD_AWARDS + MAX_BAD_AWARDS;
	}
	
	//Store all possible rolls in an array
	new Handle: rollArray;
	new j = 0;
	rollArray = CreateArray(1, (bound[1] + 1) - bound[0]);
	
	//Find rolls that are acceptable
	for(new i=bound[0]; i<bound[1]; i++)
	{
		if(!UnAcceptable(client, i))
		{
			//acceptable roll found, store it in the array
			SetArrayCell(rollArray, j, i, 0);
			
			//increment how many rolls we have found that are acceptable
			j ++;
		}
	}
	
	//this is the award that will be awarded to the user
	new award = GetRandomInt(0, j-1);
	
	//No awards found! Inform user
	if(j == 0)
	{
		CloseHandle(rollArray);
		return false;
	}
	
	GivePlayerEffect(client, GetArrayCell(rollArray, award, 0), 0);
	
	CloseHandle(rollArray);
	
	return true;
}

public bool:UnAcceptable(client, award)
{	
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	if(!roll_enabled[award]) return true;
	
	//client can't roll while in a timer based roll!
	//this is mainly used for the shop
	if(inTimerBasedRoll[client])
		return true;
	
	//client can't roll the same thing twice
	if(client_rolls[client][award][0]) return true;
	
	//Check to see if entity limits have been reached
	if(roll_EntLimit[award] && IsEntLimitReached()) return true;
	
	//Used incase award rolls are given, to prevent infinite duration of a status
	if(client_rolls[client][award][0] && inTimerBasedRoll[client]) return true;
	
	if(roll_inBeta[award] && !isBetaUser[client]) return true;
	
	//Check class restrictions, only this class can roll it
	if(class != roll_ClassRestriction[award] && roll_ClassRestriction[award] != TFClass_Unknown) return true;
	
	//Evry class but this one can roll it
	//Check class restrictions
	
	if(class == roll_ExcludeClass[award] && roll_ExcludeClass[award] != TFClass_Unknown) return true;
	
	if(roll_itemEquipped_OnBack[award] && itemEquipped_OnBack[client])
		return true;
	
	//Hulk is not rollable
	if(award == AWARD_G_HULK && BoughtSomething[client] == 0) return true;
	
	//Fists of Steel + Hulk is a no no
	if(award == AWARD_G_HULK && isPlayerHolding_UniqueWeapon(client, 331)) return true;
	
	if(award == AWARD_G_PROXSTICKIES &&
	 !( isPlayerHolding_UniqueWeapon(client, 20) ||//sticky bomb launcher
	   isPlayerHolding_UniqueWeapon(client, 265) || //sticky jumper
	   isPlayerHolding_UniqueWeapon(client, 130) )) return true;
	
	if(award == AWARD_G_NOCLIP && class == TFClass_Sniper) return true;
	if(award == AWARD_G_NOCLIP && class == TFClass_Engineer) return true;
	if(award == AWARD_G_NOCLIP && GameRules_GetProp("m_bInSetup", 4, 0)) return true;
	
	if(award == AWARD_G_SPEED && class == TFClass_Scout) return true;
	if(award == AWARD_G_WINGS && class == TFClass_Scout) return true;
	
	if(award == AWARD_G_HEAD && 
		!(isPlayerHolding_UniqueWeapon(client, 132) || 
	      isPlayerHolding_UniqueWeapon(client, 266) ||
		  isPlayerHolding_UniqueWeapon(client, 482) )) return true;		  
	
	if(award == AWARD_G_YOSHI && client_rolls[client][AWARD_G_CROUCHINVIS][0]) return true;
	
	if(award == AWARD_G_BACKPACK && client_rolls[client][AWARD_G_SPIDER][1] != 0) return true;
	if(award == AWARD_G_BACKPACK && client_rolls[client][AWARD_G_BLIZZARD][1] != 0) return true;
	
	///////////////////////////////////////////////////////
	//check entity limits for resource intensive rolls   //
	///////////////////////////////////////////////////////
	if(award == AWARD_G_ZOMBIE && amountOfZombies() > 8)
		return true;
	
	if(award == AWARD_G_SPIDER && amountOfSpiders() > 8)
		return true;
	
	if(award == AWARD_G_COW && amountOfCows() > 8)
		return true;
	////////////////////////////////////////////////////////
	
	if(playersInServer() <= 6)
	{
		if(award == AWARD_G_TOXIC) return true;
		if(award == AWARD_G_GODMODE) return true;
		if(award == AWARD_G_INSTANTKILL) return true;
	}
	
	//Check to see if player is required to have a certain weapon equipped
	if(roll_required_weapon[award] != 0 && !isPlayerHolding_UniqueWeapon(client, roll_required_weapon[award]))
		return true;
	
	//Don't award too many heads
	if(award == AWARD_G_HEAD)
	{
		if(GetEntProp(client, Prop_Send, "m_iDecapitations") > 4)
			return true;
	}
	
	//If player has Melee Mode perk
	if(award == AWARD_B_WEAPONS && RTD_Perks[client][18])
		return true;
	
	//Prevent Engineers from rolling melee if they are carrying an object
	if(award == AWARD_B_WEAPONS && GetEntData(client, m_bCarryingObject) == 1)
		return true;
	
	if(award == AWARD_B_DOOM && GameRules_GetProp("m_bInSetup", 4, 0) == 1) return true;
	
	return false;
}



GivePlayerEffect(client, award, cost)
{
	decl String:chatMessage[200];
	decl String:message[200];
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	new String:name[32];
	GetClientName(client, name, sizeof(name));
	new String:msg[128];
	
	client_rolls[client][award][0] = 1;
	lastRoll[client] = award;
	
	//Unusual variables
	new bool:isUnusual = false;
	new extraTime;
	new extraHealth;
	new extraDeployables;
	
	//Display roll info
	if(BoughtSomething[client])
	{
		//determine if this will be an unusual roll
		if(GetRandomInt(1,100) <= unusualRoll_Shop_Chance)
		{
			client_rolls[client][award][9] = 1; //mark as unusual 
			isUnusual = true;
			
			extraTime = GetRandomInt(1, 10);
			extraHealth = GetRandomInt(100, 300);
			extraDeployables = GetRandomInt(1, 2);
			
			new String:bonus[32];
			if(roll_CountDownTimer[award])
			{
				Format(bonus, sizeof(bonus), "+%i seconds", extraTime);
			}else if(roll_isDeployable[award])
			{
				if(extraDeployables == 1)
				{
					Format(bonus, sizeof(bonus), "+1 deployable");
				}else{
					Format(bonus, sizeof(bonus), "+%i deployable", extraDeployables);
				}
			}else if(roll_itemEquipped_OnBack[award])
			{
				switch(award)
				{
					case AWARD_G_BACKPACK:
					{
						Format(bonus, sizeof(bonus), "Stuffed pack");
					}
					
					case AWARD_G_BLIZZARD:
					{
						Format(bonus, sizeof(bonus), "Shorter Cooldown");
					}
					
					case AWARD_G_WINGS:
					{
						Format(bonus, sizeof(bonus), "Faster Speed");
					}
					
					case AWARD_G_STONEWALL:
					{
						Format(bonus, sizeof(bonus), "Increased Dmg Reduction when activated");
					}
					
					case AWARD_G_ARMOR:
					{
						Format(bonus, sizeof(bonus), "1000 Armor");
					}
				}
				
			}else{
				Format(bonus, sizeof(bonus), "+%i health", extraDeployables);
			}
			
			Format(chatMessage, sizeof(chatMessage), "\x01\x04[Unusual Purchase] \x03%s\x04 bought an Unusual \x03%s\x04. Bonus: \x03%s", name, roll_Text[award], bonus);
			
			Format(message, sizeof(message), "Unusual Purchase: %s%s", roll_Article[award], roll_Text[award]);
			centerHudText(client, message, 0.0, 5.0, HudMsg3, 0.75); 
		}else{
			Format(chatMessage, sizeof(chatMessage), "\x01\x04[SHOP] \x03%s\x04 used \x01%i\x04 CREDITS and bought %s\x03%s.", name, cost, roll_Article[award], roll_Text[award]);
			
			Format(message, sizeof(message), "You bought: %s%s", roll_Article[award], roll_Text[award]);
			centerHudText(client, message, 0.0, 5.0, HudMsg3, 0.75); 
		}
		
	}else{
		if(cost == -1)
		{
			Format(chatMessage, sizeof(chatMessage), "\x01\x04[RTD] \x03%s\x04 was gifted %s\x03%s", name, roll_Article[award], roll_Text[award]);
			
			Format(message, sizeof(message), "You were gifted: %s%s", roll_Article[award], roll_Text[award]);
		}
		
		if(cost == -2)
		{
			Format(chatMessage, sizeof(chatMessage), "\x01\x04[ADMIN FORCE ROLLED] \x03%s\x04 force rolled %s\x03%s", name, roll_Article[award], roll_Text[award]);
			
			Format(message, sizeof(message), "You force rolled: %s%s", roll_Article[award], roll_Text[award]);
		}
		
		if(cost == 0)
		{
			Format(chatMessage, sizeof(chatMessage), "\x01\x04[RTD] \x03%s\x04 rolled %s\x03%s", name, roll_Article[award], roll_Text[award]);
			
			Format(message, sizeof(message), "You rolled: %s%s", roll_Article[award], roll_Text[award]);
		}
		
		centerHudText(client, message, 0.1, 5.0, HudMsg3, 0.82); 
	}
	
	//Display roll info in chat
	PrintToChatSome(chatMessage, client); 
	
	/////////////////////////////////////////
	//Create CountDown timer if required   //
	/////////////////////////////////////////
	if(roll_CountDownTimer[award])
	{
		inTimerBasedRoll[client] = 1;
		
		new Handle:dataPackHandle;
		CreateDataTimer(0.1, Timer_Rolls, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
		
		//Setup the datapack with appropriate information
		WritePackCell(dataPackHandle, GetClientUserId(client)); //0   client
		WritePackCell(dataPackHandle, award); //8   client
		
		if(roll_TimerOverride[award] == 0)
		{
			if(roll_isGood[award])
			{
				WritePackCell(dataPackHandle, GetTime() + GetConVarInt(c_Duration) + RTD_Perks[client][6] + extraTime); //16  end time
			}else{
				WritePackCell(dataPackHandle, GetTime() + GetConVarInt(c_Duration) - RTD_Perks[client][6]); //16  end time
			}
		}else{
			WritePackCell(dataPackHandle, GetTime() + roll_TimerOverride[award]); //16  end time
		}
		
		WritePackString(dataPackHandle, roll_Particle[award]); //24   client
		
		if(!StrEqual(roll_Particle[award], "", true))
			AttachRTDParticle(client, roll_Particle[award], roll_AutoKill[award], roll_AttachToHead[award], float(roll_ZCorrection[award]));
	}
	
	/////////////////////////////////
	// MASSIVE SWITCH STATEMENT    //
	/////////////////////////////////
	if(roll_isGood[award])
	{
		//the user just rolled something good reset the amountofBadRolls
		amountOfBadRolls[client] = 0.0;
		
		//set amount user can deploy
		if(roll_isDeployable[award])
		{
			if(moreDeployables)
			{
				//Chance for users to have more than 1 deployable
				if(GetRandomFloat(0.0, 1.0) < deployables_chance)
				{
					client_rolls[client][award][1] = roll_amountDeployable[award] + deployables_max;
				}else{
					client_rolls[client][award][1] = roll_amountDeployable[award];
				}
			}else{
				if(isUnusual)
				{
					client_rolls[client][award][1] = roll_amountDeployable[award] + extraDeployables;
				}else{
					client_rolls[client][award][1] = roll_amountDeployable[award];
				}
			}
		}
		
		switch(award)
		{		
			case AWARD_G_INSTAPORTER:
				centerHudText(client, "Place the entrance of your teleporter somewhere.", 2.0, 5.0, HudMsg3, 0.75);
		
			case AWARD_G_YOSHI:
				Make_Yoshi(client);
		
			case AWARD_G_HEARTSAPLENTY:
			{
			}
		
			case AWARD_G_JETPACK:
			{
			}
		
			case AWARD_G_SUPPLYDROP:
			{
			}
			
			case AWARD_G_GODMODE:
			{
				SetGodmode(client, true);
			}
			
			case AWARD_G_TOXIC:
			{
			}
			
			case AWARD_G_HEALTH:
				SetEntityHealth(client, RoundToCeil(classHealth[GetEntProp(client, Prop_Send, "m_iClass")] * GetConVarFloat(c_Health)));
			
			case AWARD_G_SPEED:
			{
			}
			
			case AWARD_G_NOCLIP:
			{
				NoClipThisLife[client] = 1;
				SetEntityMoveType(client, MOVETYPE_NOCLIP);
			}
			
			case AWARD_G_GRAVITY:
				SetEntityGravity(client, GetConVarFloat(c_Gravity));
			
			case AWARD_G_UBER:
			{
			}
			
			case AWARD_G_INVIS:
			{
				Colorize(client, INVIS);
				InvisibleHideFixes(client, class, 0);
			}
			
			case AWARD_G_INSTANTKILL:
			{
			}
			
			case AWARD_G_CLOAK:
			{
			}
			
			case AWARD_G_CRITS:
			{
			}
			
			case AWARD_G_SCOUTJUMP:
			{
			}
			
			case AWARD_G_MEDIRAY:
				equipMediray(client);
			
			case AWARD_G_REGEN:
				CreateTimer(0.2,  	RegenerateHealth, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			
			case AWARD_G_INFIAMMO:
			{
				client_rolls[client][award][1] = 0;
				client_rolls[client][award][2] = 0;
			}
			
			case AWARD_G_SENTRYBUILDER:
			{
			}
			
			case AWARD_G_HULK:
			{
				
				client_rolls[client][AWARD_G_ARMOR][0] = 1;
				client_rolls[client][AWARD_G_ARMOR][1] += 500;
				client_rolls[client][AWARD_G_SPEED][0] = 1;
				
				ROFMult[client] = 2.0;
				
				SetEntityGravity(client, 0.6);
				Colorize(client, GREEN);
			}
			
			case AWARD_G_CLASSIMMUNITY:
				GiveClassImmunity(client);
			
			case AWARD_G_MEDICVIRUS:
				CreateTimer(0.1,  	MedicVirus, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			
			case AWARD_G_UBERCHARGER:
			{
				CreateTimer(0.1, UberchargerTimer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				AttachRTDParticle(client, "sapper_sentry1_fx", true, false, 45.0);
			}
			
			case AWARD_G_ARMOR:
			{
				if(isUnusual)
				{
					client_rolls[client][award][1] += (1000 + extraHealth);
				}else{
					client_rolls[client][award][1] += (500 + extraHealth);
				}
				
				if(GetClientTeam(client) == BLUE_TEAM)
				{
					AttachRTDParticle(client, "armor_blue", true, false, 10.0);
				}else{
					AttachRTDParticle(client, "armor_red", true, false, 10.0);
				}
			}
			
			case AWARD_G_TEAMCRITS:
			{	
			}
			
			case AWARD_G_CROUCHINVIS:
			{
			}
			
			case AWARD_G_PROXSTICKIES:
			{	
				client_rolls[client][award][1] = 16;
				CreateTimer(0.2,	proximityStickies_Timer,client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
			
			case AWARD_G_SLOWCUBE:
			{
			}
			
			case AWARD_G_BOMB:
			{	
				EmitSoundToClient(client, SOUND_BOMB);
			}
			
			case AWARD_G_GROOVITRON:
			{
			}
			
			case AWARD_G_CRAP:
			{
				centerHudText(client, "A shiny turd!", 4.0, 10.0, HudMsg3, 0.75); 
			}
			
			case AWARD_G_SPIDER:
				client_rolls[client][AWARD_G_SPIDER][1] = 0;
			
			case AWARD_G_PUMPKIN:
			{	
			}
			
			case AWARD_G_FIREBULLETS:
			{	
			}
			
			case AWARD_G_ICE:
				centerHudText(client, "Ice Patches make enemies slip and slide!", 4.0, 5.0, HudMsg3, 0.75);
			
			case AWARD_G_BERSERKER:
			{	
				ROFMult[client] = 2.0;
				CreateTimer(3.0, berserkerMessage, client);
			}
			
			case AWARD_G_VAMPIRE:
				centerHudText(client, "Attacks on enemies gives you health!", 4.0, 5.0, HudMsg3, 0.75);
			
			case AWARD_G_INVISLOWHEALTH:
			{	
				centerHudText(client, "On low health you will be invisible", 4.0, 5.0, HudMsg3, 0.75); 
				
				new Handle:dataPackHandle;
				CreateDataTimer(0.5, Timer_InvisLowHealth, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
				
				WritePackCell(dataPackHandle, client);
				WritePackCell(dataPackHandle, 0);//PackPosition(8) - This is the last time a fake body was spawned
				WritePackCell(dataPackHandle, 1); //PackPosition(16) - Allow a fake death
			}
			
			case AWARD_G_FLAME:
			{	
			}
			
			case AWARD_G_RAGE:
			{
			}
			
			case AWARD_G_FIREBALL:
			{	
			}
			
			case AWARD_G_GHOST:
				centerHudText(client, "Enemies near ghosts will get scared!", 4.0, 5.0, HudMsg3, 0.75);
			
			case AWARD_G_SANDWICH:
			{	
			}
			
			case AWARD_G_JUMPPAD:
			{	
			}
			
			case AWARD_G_ACCELERATOR:
			{	
			}
			
			case AWARD_G_ZOMBIE:
			{	
			}
			
			case AWARD_G_BACKPACK:
			{	
				client_rolls[client][award][1] = 0; //entity index
				
				if(isUnusual)
				{
					client_rolls[client][award][2] = GetRandomInt(2,15); //ammopacks
					client_rolls[client][award][3] = GetRandomInt(2, 15); //healthpacks
				}else{
					client_rolls[client][award][2] = 2; //ammopacks
					client_rolls[client][award][3] = 2; //healthpacks
				}
				
				SpawnAndAttachBackpack(client);
				
				centerHudText(client, "Every point received adds either ammo or health to your backpack!", 4.0, 10.0, HudMsg3, 0.75); 
			}
			
			case AWARD_G_DIVIDETHESHOT:
				centerHudText(client, "Enemies close to the orginal enemy that you hit get hurt as well!", 4.0, 5.0, HudMsg3, 0.75);
			
			case AWARD_G_AMPLIFIER:
			{
				centerHudText(client, "Allies near the amplifier receive minicrits", 4.0, 10.0, HudMsg3, 0.75);
				client_rolls[client][AWARD_G_AMPLIFIER][2] = 800; //health
				client_rolls[client][AWARD_G_AMPLIFIER][3] = 800; //maxhealth
			}
			
			case AWARD_G_PROXMINES:
			{	
			}
			
			case AWARD_G_BEARTRAP:
			{	
			}
			
			case AWARD_G_REFLECTSHIELD:
			{
				centerHudText(client, "Enemy projectiles will automatically be airblasted!", 4.0, 10.0, HudMsg3, 0.75);
				CreateTimer(0.1, Timer_ReflectShield, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
			
			case AWARD_G_CAGE:
				centerHudText(client, "Enemies close to your cage will be trapped inside!", 4.0, 10.0, HudMsg3, 0.75);
			
			case AWARD_G_CRITSSPURT:
			{
				centerHudText(client, "Every 10s you will receive 3s of CRITS", 4.0, 10.0, HudMsg3, 0.75);
				Activate_CritsSpurt(client);
			}
			
			case AWARD_G_URINECLOUD:
			{
			}
			
			case AWARD_G_DIGLETT:
			{
			}
			
			case AWARD_G_METALMAN:
				Give_MetalMan(client);
			
			case AWARD_G_COW:
				client_rolls[client][AWARD_G_COW][1] = 0;
			
			case AWARD_G_HEAD:
			{
				client_rolls[client][award][0] = 0;
				new decapitations = GetEntProp(client, Prop_Send, "m_iDecapitations");
				SetEntProp(client, Prop_Send, "m_iDecapitations", decapitations + 2);
				centerHudText(client, "Two heads were added!", 4.0, 10.0, HudMsg3, 0.75);
				
				ResetClientSpeed(client);
				addHealth(client, 15);
			}
			
			case AWARD_G_BLIZZARD:
			{	
				client_rolls[client][award][1] = 0; //entity index
				client_rolls[client][award][2] = 2; //ammopacks
				client_rolls[client][award][3] = 2; //healthpacks
				SpawnAndAttachBlizzard(client);
				
				centerHudText(client, "On shot enemies will be frozen!", 4.0, 10.0, HudMsg3, 0.75); 
			}
			
			case AWARD_G_UBERBOW:
				centerHudText(client, "Each hit on enemy from the CrossBow adds +10\% to your Uber", 4.0, 5.0, HudMsg3, 0.75);
			
			case AWARD_G_WINGS:
			{
				Format(msg, sizeof(msg), "These special Wings make you move +%i\%% faster!", RTD_Perks[client][24]);
				centerHudText(client, msg, 4.0, 5.0, HudMsg3, 0.75); 
				SpawnAndAttachWings(client);
			}
			
			case AWARD_G_DUMMY:
			{
				client_rolls[client][AWARD_G_DUMMY][2] = 1200;
				client_rolls[client][AWARD_G_DUMMY][3] = 1200;
				client_rolls[client][AWARD_G_DUMMY][5] = GetClientUserId(client);
			}
			
			case AWARD_G_BRAZIER:
			{
				client_rolls[client][AWARD_G_BRAZIER][4] = GetTime(); //next time it can regenerate
			}
			
			case AWARD_G_STONEWALL:
			{
				client_rolls[client][award][1] = 0; //entity index
				SpawnAndAttachStonewall(client);
				
				centerHudText(client, "Standing still reduces damage taken by 50 percent", 4.0, 5.0, HudMsg3, 0.75); 
			}
			
			case AWARD_G_SENTRYWRENCH:
			{
				client_rolls[client][AWARD_G_SENTRYWRENCH][6] = GetTime(); //next time it's allowed to build 
				centerHudText(client, "Sentry spawned when enemies are killed with Wrench!", 4.0, 5.0, HudMsg3, 0.75); 
			}
			
			case AWARD_G_FLAVOREDDAMAGE:
			{
				client_rolls[client][AWARD_G_FLAVOREDDAMAGE][7] = 1;
				client_rolls[client][AWARD_G_FLAVOREDDAMAGE][6] = GetTime() + 7; //next time it's allowed to build 
				centerHudText(client, "7s damage of each: Milk, Jarate then Fire", 4.0, 5.0, HudMsg3, 0.75); 
			}
			
			case AWARD_G_RUBBERBULLETS:
			{
				centerHudText(client, "On hit, enemies will be knocked back!", 4.0, 5.0, HudMsg3, 0.75); 
			}
			
			case AWARD_G_ANGELIC:
			{
			}
			
			case AWARD_G_TREASURE:
			{	
				client_rolls[client][award][1] = 0; //entity index
				client_rolls[client][award][2] = 2; //ammopacks
				client_rolls[client][award][3] = 2; //healthpacks
				SpawnAndAttachTreasure(client);
				
				centerHudText(client, "Hey you're not supposed to roll this!", 4.0, 10.0, HudMsg3, 0.75); 
			}
			
			case AWARD_G_TIMETHIEF:
			{
			}
			
		}
	}else{ // Bad Command
		//Let's store how many bad rolls the user has received 
		amountOfBadRolls[client] += 0.1;
		
		switch(award)
		{		
			case AWARD_B_DOOM:
			{
				/* Ok, so I need to see if a player already has this roll active on them if
				it was transfered by an attacker.  To do this I need to check client_rolls[][][],
				but the problem is that client_rolls[client][award][0] is set to 1 BEFORE this
				is executed.  Since I do not know the adverse effects of moving that
				assignment to the end of this function, I will employ a simple "hack". */
				client_rolls[client][AWARD_B_DOOM][0] = 0;
				DoomPlayer(client, true);
			}
		
			case AWARD_B_IGNITE:
			{
				DealDamage(client,5, client, 16779264, "flames");
				DealDamage(client,0, client, 2056, "flames");
				client_rolls[client][AWARD_B_IGNITE][0] = 0;
				
			}
			
			case AWARD_B_HEALTH:
			{
				SetEntityHealth(client, 1);
				client_rolls[client][AWARD_B_HEALTH][0] = 0;
			}
			
			case AWARD_B_WEAPONS:
			{	
				if(!client_rolls[client][AWARD_G_ARMOR][0])
					client_rolls[client][AWARD_G_ARMOR][0] = 1;
					
				client_rolls[client][AWARD_G_ARMOR][1] += 50;
				
				TF2_RemoveCond(client, 1);
				
				//mark to restore uber when user touches locker
				new weapon = GetPlayerWeaponSlot(client, 1);
				if (IsValidEntity(weapon))
				{
					new String:classname[64];
					GetEdictClassname(weapon, classname, 64);
					
					//is the player holding the medigun?
					if(StrEqual(classname, "tf_weapon_medigun"))
					{
						new Float:curUberLevel = GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel") ;
						client_rolls[client][AWARD_B_WEAPONS][1] = 1;
						
						client_rolls[client][AWARD_B_WEAPONS][2] =  RoundFloat(curUberLevel * 100.0);
					}
				}
				
				StripToMelee(client);
			}
			
			case AWARD_B_TAUNT:
			{
				EmitSoundToAll(SOUND_JARATE, client);
				AttachRTDParticle(client, "peejar_impact", true, false, 0.0);
			}
			
			case AWARD_B_WAITMORE:
			{
				client_rolls[client][AWARD_B_WAITMORE][0] = 0;
				
				new timeleft;
				
				if(RTD_Timer[client] <= GetTime())
				{
					timeleft = GetConVarInt(c_Timelimit) - ( GetTime() - RTD_Timer[client] ) ;
				}else{
					timeleft = RTD_Timer[client] + GetConVarInt(c_Timelimit) - GetTime();
				}
				
				if(timeleft <= 1)
				{
					RTD_Timer[client] = (GetTime() - GetConVarInt(c_Timelimit)) + 60;
				}else{
					RTD_Timer[client] += 60;
				}
			}
			
			case AWARD_B_BADAIM:
			{
				centerHudText(client, "All your shots will apply half damage!", 4.0, 5.0, HudMsg3, 0.75); 
			}
			
			case AWARD_B_LOSER:
			{
				EmitSoundToAll(SOUND_LOSERHANK, client);
				
				centerHudText(client, "You take 10\% dmg but cannot use your weapons!", 4.0, 5.0, HudMsg3, 0.75); 
				
				TF2_StunPlayer(client,10.0, 0.0, TF_STUNFLAGS_LOSERSTATE, 0);
				ResetClientSpeed(client);
				SetEntData(client, m_iMovementStunAmount, 0 );
			}
			
			case AWARD_B_NOJUMP:
			{
				centerHudText(client, "No jumping for you!", 4.0, 10.0, HudMsg3, 0.75); 
			}
			
			case AWARD_B_SLOWMO:
			{
				EmitSoundToAll(SOUND_SLOWMO, client);
			}
		}
	}

	// Mark the effect that the player is using. Timer_RemovePlayerEffect will read this later
	if(award != AWARD_B_WAITMORE)
		RTD_Timer[client] = GetTime();
	
	BoughtSomething[client] = 0;
	
	return;
}
	
public Action:Timer_Rolls(Handle:timer, Handle:dataPackHandle)
{
	//////////////////////////////////////////////////////////////
	// Used for Timer based effects.                            //
	// This shows the countdown, makes sure the effect stays in //
	// place and then reverses it once time is up or if player  //
	// is invalid (disconnect or died)                          //
	// ///////////////////////////////////////////////////////////
	
	new client;
	new clientUserID;
	new String:particleString[32];
	new String:timeleftString[32];
	new bool:stopTimer = false;
	
	ResetPack(dataPackHandle);
	clientUserID = ReadPackCell(dataPackHandle);
	new award = ReadPackCell(dataPackHandle);
	new endTime = ReadPackCell(dataPackHandle);
	ReadPackString(dataPackHandle, particleString, sizeof(particleString));
	
	client = GetClientOfUserId(clientUserID);
	
	if(client < 1)
		return Plugin_Stop;
	
	if(!IsClientInGame(client))
		return Plugin_Stop;
	
	if(client_rolls[client][award][0] == 0)
		stopTimer = true;
	
	Format(timeleftString, sizeof(timeleftString), "%i seconds left", endTime - GetTime());
	if(endTime - GetTime() > 0)
	{
		centerHudText(client, timeleftString, 0.0, 2.0, HudMsg4, 0.11); 
	}else{
		centerHudText(client, "", 0.0, 2.0, HudMsg4, 0.11); 
	}
	
	if(GetTime() >= endTime || !IsPlayerAlive(client))
	{
		/////////////////////////////////////
		// END EFFECTS. Player has died or //
		// the timer has gone past EndTime //
		/////////////////////////////////////
		
		switch(award)
		{	
			case AWARD_G_YOSHI:
				Remove_Yoshi(client);
		
			case AWARD_G_SPEED:
				ResetClientSpeed(client);
			
			case AWARD_G_GODMODE:
				SetGodmode(client, false);
				
			case AWARD_G_TOXIC:
				Colorize(client, NORMAL);
				
			case AWARD_G_NOCLIP:
				SetEntityMoveType(client, MOVETYPE_WALK);
				
			case AWARD_G_GRAVITY:
				SetEntityGravity(client, 1.0);
				
			case AWARD_G_INVIS:
			{
				Colorize(client, NORMAL);
				InvisibleHideFixes(client, TF2_GetPlayerClass(client), 1);
			}
			
			case AWARD_G_CRITS:
				TF2_RemoveCond(client, 11);
			
			case AWARD_B_TAUNT:
				TF2_RemoveCond(client, 24);
				
			case AWARD_B_NOJUMP:
				SetEntityGravity(client, 1.0);
				
			case AWARD_B_SLOWMO:
			{
				StopSound(client, SNDCHAN_AUTO, SOUND_SLOWMO);
				ResetClientSpeed(client);
			}
			
			case AWARD_B_LOSER:
				StopSound(client, SNDCHAN_AUTO, SOUND_LOSERHANK);
			
		}
		
		stopTimer = true;
	}else{
		
		/////////////////////////////////////////
		// CONTINUING EFFECTS. Actions to be   //
		// done while the player is still alive//
		// and the effect has not ended.       //
		/////////////////////////////////////////
		
		switch(award)
		{
			case AWARD_B_TAUNT:
				TF2_AddCond(client, 24);
			
			case AWARD_G_CRITS:
				TF2_AddCondition(client,TFCond_Kritzkrieged,2.0);
				
			case AWARD_G_UBER:
				TF_AddUberLevel(client, 1.0);
			
			case AWARD_G_RAGE:
			{
				if(TF2_GetPlayerClass(client) == TFClass_Soldier)
				{
					TF_SetRageLevel(client, 100.0);
				}else{
					stopTimer = true;
				}
			}
			
			
			
			case AWARD_G_TOXIC:
				Toxic(client);
			
			case AWARD_G_CLOAK:
			{
			}
			
			case AWARD_G_TEAMCRITS:
			{
				for(new i=1; i <= MaxClients; i++)
				{
					// Check for a valid client  Check to make sure the player is on the same team
					if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(client) == GetClientTeam(i))
					{
						if(GetTime() < (endTime-5)){
							SetHudTextParams(0.35, 0.82, 1.0, 250, 250, 210, 255);
							ShowHudText(i, HudMsg3, "In %i Seconds YOU will have CRITS", (endTime - 5) - GetTime());
						}else{
							SetHudTextParams(0.35, 0.82, 1.0, 250, 250, 210, 255);
							ShowHudText(i, HudMsg3, "Crits will wear off in %i seconds", endTime - GetTime());
							TF2_AddCondition(i,TFCond_Kritzkrieged,2.0);
						}
					}
				}
			}
			
			case AWARD_B_NOJUMP:
				SetEntityGravity(client, 99.0);
			
			case AWARD_G_GRAVITY:
			{
				if(GetClientButtons(client) & IN_DUCK)
				{
					SetEntityGravity(client, 2.0);
				}else{
					SetEntityGravity(client, GetConVarFloat(c_Gravity));
				}
			}
			
			case AWARD_B_SLOWMO:
			{
				new cflags = GetEntData(client, m_fFlags);
				
				if(!(cflags & FL_DUCKING))
				{
					if(GetClientBaseSpeed(client) > 100.0)
						SetEntDataFloat(client, m_flMaxspeed, 100.0);
					
				}else{
					ResetClientSpeed(client);
				}
			}
		}
	}
	
	if(stopTimer)
	{
		inTimerBasedRoll[client] = 0;
		client_rolls[client][award][0] = 0;
		
		if(!StrEqual(particleString, "", false))
			DeleteParticle(client, particleString);
		
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public RemoveLifetimeRolls(client)
{	
	/////////////////////////////////////////////
	// Clears out rolls that are supposed to   //
	// reset on death.                         //
	/////////////////////////////////////////////
	DeleteParticle(client, "all");
	
	NoClipThisLife[client] = 0;
	inBombBlastZone[client] = 0;
	beingSlowCubed[client] = 0;
	inSlowCube[client] = 0;
	inIce[client] = false;
	ROFMult[client] = 0.0;
	
	if(RTD_TrinketActive[client][TRINKET_QUICKDRAW])
		ROFMult[client] = 1.0 + (float(RTD_TrinketBonus[client][TRINKET_QUICKDRAW])/100.0);
	
	new oldValue = client_rolls[client][AWARD_G_BLIZZARD][3];
	
	//Clear out rolls on death
	for(new i = 0; i < MAX_GOOD_AWARDS + MAX_BAD_AWARDS; i ++)
	{
		if(roll_resetOnDeath[i])
		{
			for(new j = 0; j <= 5; j ++)
				client_rolls[client][i][j] = 0;
		}
	}
	
	//restore next time player can get frozen
	client_rolls[client][AWARD_G_BLIZZARD][3] = oldValue;
	itemEquipped_OnBack[client] = 0;
	return;
}

public CleanPlayer(client)
{	
	///////////////////////////////////////////// /////////////////////////
	//Clears all RTD values from the client                              //
	//                                                                   //
	//Section needs cleaning, the purpose of this is to RESET all stats  //
	//on this player. Should be used when client connects/disconnect     //
	///////////////////////////////////////////////////////////////////////
	inTimerBasedRoll[client] = 0;
	RTD_Timer[client] = 0;
	
	OldScore[client] = -1;
	
	nextTimeOfRndFire[client] = 0;
	amountOfBadRolls[client] = 0.0;
	NoClipThisLife[client] = 0;
	inBombBlastZone[client] = 0;
	beingSlowCubed[client] = 0;
	inSlowCube[client] = 0;
	inIce[client] = false;
	ROFMult[client] = 0.0;
	
	DeleteParticle(client, "all");
	
	//Clear out rolls on death
	for(new i = 0; i < MAX_GOOD_AWARDS + MAX_BAD_AWARDS; i ++)
	{
		for(new j = 0; j <= 5; j ++)
			client_rolls[client][i][j] = 0;
	}
	
	credsUsed[client][0] = 0;
	credsUsed[client][1] = 0;
	
	creds_Gifted[client] = 0;
	creds_ReceivedFromGifts[client] = 0;
	giftingTo[client] = 0;
	giftingCost[client] = 0;
	beingGifted[client] = 0;
	acceptedGift[client] = 0;
	inWaitingToGift[client] = 0;

	RTD_Timer[client] = 0;
	
	lastRoll[client] = 0;
	
	RTDCredits[client] = 0;
	RTDdice[client] = 0;
	areStatsLoaded[client] = false;
	movingHUD[client] = false;
	
	//Reset options
	for(new i = 0; i <= 9; i++)
		RTDOptions[client][i] = 0;
	
	g_BeginScore[client] = 0;
	dmgDebug[client] = false;
	diceDebug[client] = false;
	
	//Team Manager
	if(IsClientInGame(client) && IsValidTeam(client) && IsBlocked(client))
	{
		new String:tempStr[32];
		
		IntToString(GetTime() + 300, tempStr, sizeof(tempStr));
		SetClientCookie(client, g_cookie_timeBlocked, tempStr);
		
		IntToString(GetClientTeam(client), tempStr, sizeof(tempStr));
		SetClientCookie(client, g_cookie_teamIndex, tempStr);
		
	}
	
	//reset Dice perks
	for(new i = 0; i < maxPerks; i++)
	{
		RTD_Perks[client][i] = 0;
		RTD_PerksLevel[client][i] = 0;
		for (new j = 0; j < 3; j++)
			RTD_PerksInfo[client][i][j] = 0;
	}
	
	isNewUser[client] = false;
	
	g_BlockTime[client] = -1;
	g_BlockTeam[client] = -1;
	
	showStartupMsg[client] = true;
	
	itemEquipped_OnBack[client] = 0;
	
	return;
}

public SetGodmode(client, bool:playerState)
{
	if(playerState)
	{
		EmitSoundToAll(SOUND_STARMAN, client);
		TF2_AddCond(client, 5);
	}else{
		StopSound(client, SNDCHAN_AUTO, SOUND_STARMAN);
		TF2_RemoveCond(client, 5);
	}
	
	return;
}

stock TF_SetCloak(client, Float:cloaklevel)
{
	SetEntDataFloat(client, g_cloakOffset, cloaklevel);
}

stock TF_AddCloak(client, Float:wantedCloakAmount)
{
	new Float:currentCloak = GetEntDataFloat(client, g_cloakOffset);
	new Float:newCloakLevel;
	
	newCloakLevel = currentCloak + wantedCloakAmount;
	
	if(newCloakLevel < 100.0)
		SetEntDataFloat(client, g_cloakOffset, newCloakLevel);
}

StripToMelee(client) 
{
	if (IsClientInGame(client) && IsPlayerAlive(client)) 
	{
		new TFClassType:class = TF2_GetPlayerClass(client);
		if(class == TFClass_Sniper)
		{
			//Removes Sniper/Bow Slowdowns
			TF2_RemoveCond(client, 0);
			//Removes Sniper Rifle Zoom
			TF2_RemoveCond(client, 1);
			//Fixes Speed for Sniper to normal
		}
		else if(class == TFClass_Spy)
		{
			//Removes Spy Cloak
			TF2_RemoveCond(client, 4);
		}
		
		TF2_RemoveWeaponSlot(client, 0); //remove primary
		TF2_RemoveWeaponSlot(client, 1); //remove secondary
		
		new weapon = GetPlayerWeaponSlot(client, 2);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
}