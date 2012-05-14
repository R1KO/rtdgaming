#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>


public Action:ObjectTakeDamage(object, &attacker, &inflictor, &Float:damage, &damagetype)
{
	//this is only for objects
	//mainly this is used to change the amount of damage invisible people
	//do to buildings
	
	//only want objects not clients
	if(object <= MaxClients)
		return Plugin_Continue;
	
	//only valid when the attacker is a player
	if(attacker > MaxClients)
		return Plugin_Continue;
	// && (client_rolls[cli][AWARD_G_CLASSIMMUNITY][0] == 0 && client_rolls[attacker][AWARD_G_CLASSIMMUNITY][1] != GetEntProp(object, Prop_Send, "m_iClass"))
	if(hasInvisRolls(attacker))
	{
		new alpha = GetEntData(attacker, m_clrRender + 3, 1);
		
		if(alpha == 0)
			damage *= 0.0;
		
		return Plugin_Changed;
	}
	
	//check to see if it has a shield
	decl String:strName[50];
	GetEntPropString(object, Prop_Data, "m_iName", strName, sizeof(strName));
	
	if(StrContains(strName, "perkshield", false) != -1)
	{
		//block 66% of incoming damage
		damage *= 0.34;
		return Plugin_Changed;
	}
	
	if(StrContains(strName, "shield", false) != -1)
	{
		//block 50% of incoming damage
		damage *= 0.50;
		return Plugin_Changed;
	}
	
	//strength drain enemy attacking building
	if(client_rolls[attacker][AWARD_G_STRENGTHDRAIN][5] > GetTime() && client_rolls[attacker][AWARD_G_STRENGTHDRAIN][5] != 0)
	{
		if(!TF2_IsPlayerInCondition(attacker, TFCond_Ubercharged))
		{
			damage *= 0.5;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public Action:MeleeOnlyDamage_Hook(object, &attacker, &inflictor, &Float:damage, &damagetype)
{
	//only valid when the attacker is a player
	if(attacker > MaxClients || attacker < 1)
		return Plugin_Stop;
	
	if(GetClientTeam(attacker) != GetEntProp(object, Prop_Data, "m_iTeamNum"))
		return Plugin_Stop;

	if(!(damagetype&DMG_CLUB))
	{
		damage = 0.0;
		return Plugin_Stop;
	}
	
	damage *= 100.0;
	return Plugin_Changed;
}

// Note that damage is BEFORE modifiers are applied by the game for
// things like crits, hitboxes, etc.  The damage shown here will NOT
// match the damage shown in player_hurt (which is after crits, hitboxes,
// etc. are applied).
public Action:TakeDamageHook(client, &attacker, &inflictor, &Float:damage, &damagetype)
{	
	//LogToFile(logPath,"Entering: %i, %i, %i, %f, %i",client, attacker, inflictor, damage, damagetype);
	//////////////////////////////
	// Useful debugging message //
	//////////////////////////////
	new Float:oldDamage = damage;
	
	if(dmgDebug[client])
	{
		new String:infclassname[256];
		GetEdictClassname(inflictor, infclassname, sizeof(infclassname));
		//Client: 2 | Atkr: 354| AtkrTeam: 0 | InfClass: headless_hatman | Infl: 354 | InflTeam: 0 |DMG: 220.000000 | damagetype: 128
		PrintToChat(client, "Client: %i | Atkr: %i| AtkrTeam: %i | InfClass: %s | Infl: %i | InflTeam: %i |DMG: %f | damagetype: %i",client,attacker,GetEntProp(attacker, Prop_Data, "m_iTeamNum"),infclassname, inflictor,GetEntProp(inflictor, Prop_Data, "m_iTeamNum"),damage,damagetype);
	}
	
	/*-----|Weapon			Normal
	* Crits | DMG_ACID =	1048576
	* 
	* Scout| Sandman Ball = 128	 \
	* 
	* Pyro | Flamethrower =	16779264 \
	* Pyro | Flaregun = 	16777218 \
	* 
	* Demoman | Grenade		262208 \
	* Demoman | Stickies	2490432 \
	* 
	* Heavy | Minigun		2097154 \ 
	* 
	* Engineer | Sentry 	4098 \
	* 
	* Medic | Gun			2230274 \
	* 
	* Universal | Melee		4226 \
	* Universal | Shotgun	538968064 \
	* Universal | Pistol	2097154 \
	* Universal	| Rocket	2359360 \
	* 
	* DMG_ACID is always applied to these
	* damagetype: 1052802  = backstab
	* damagetype: 34603010 = headshot
	* * damagetype: 2097152 = headshot
	* if(damagetype == 2097152 || damagetype == 34603010)
	* */
	
	lastAttackerOnPlayer[client] = attacker;
	
	new bool:sameTeam = false;
	new bool:isAttackerSelf = false;
	new bool:isAttackerPlayer = false;
	
	//2048 GetMaxEntities
	if(attacker > -1 && attacker < 2048)
	{
		if(GetClientTeam(client) == GetEntProp(attacker, Prop_Data, "m_iTeamNum"))
			sameTeam = true;
	}else{
		//only valid entites will count
		return Plugin_Continue;
	}
	
	if(attacker == client)
		isAttackerSelf = true;
	
	if(attacker > 0 && attacker <= MaxClients)
		isAttackerPlayer = true;
	
	///////////////////////
	//Round End Immunity //
	///////////////////////
	if(roundEnded)
	{
		if (tf2_WinningTeam != GetClientTeam(client))
		{
			if(isAttackerPlayer)
			{
				if(RoundToNearest(RTDdice[client]/200.0) > RoundToNearest(RTDdice[attacker]/200.0))
				{
					
					damage = 0.0;
					return Plugin_Changed;
				}
			}else{
				//something else other than a player did damage to this client.
				//maybe this entity has an owner?
				new owner = GetEntPropEnt(attacker, Prop_Data, "m_hOwnerEntity");
				if(IsValidEntity(owner))
				{
					//is the owner a player?
					if(owner > 0 && owner <= MaxClients)
					{
						if(RoundToNearest(RTDdice[client]/200.0) > RoundToNearest(RTDdice[owner]/200.0))
						{
							damage = 0.0;
							return Plugin_Changed;
						}
					}
				}
			}
		}
	}
	
	///////////////////////////////////////////////////////////
	//Special cases that prevent Fall Damage                 //
	///////////////////////////////////////////////////////////
	if(damagetype & DMG_FALL)
	{
		if(damage >= float(GetClientHealth(client)))
			return Plugin_Continue;
			
		if(client_rolls[client][AWARD_B_NOJUMP][0])
		{
			return Plugin_Stop;
		}
		
		if(GetEntityGravity(client) == 1.1)
		{
			SetEntityGravity(client, 1.0);
			return Plugin_Stop;
		}
		
		if(inIce[client])
		{
			return Plugin_Stop;
		}
		
		if(client_rolls[client][AWARD_G_JUMPPAD][2])
		{
			client_rolls[client][AWARD_G_JUMPPAD][2] = 0;
			return Plugin_Stop;
		}
		
		if(client_rolls[client][AWARD_G_GRAVITY][0])
			return Plugin_Stop;
		
		if(client_rolls[client][AWARD_G_STONEWALL][0])
		{
			if(GetEntityGravity(client) >= 100.0)
				return Plugin_Stop;
		}
	}
	
	////////////////////////////////////////////////////////////////
	//Special case for bombs making sure it doesnt hurt its owner //
	////////////////////////////////////////////////////////////////
	if(isAttackerSelf && damagetype == 64)
		return Plugin_Stop;
		
	if (client_rolls[client][AWARD_G_YOSHI][0]) {
		SetHudTextParams(0.07, 1.0, 1.0, 250, 250, 210, 255);
		ShowHudText(client, HudMsg5, "YOSHI'S HEALTH: %i", client_rolls[client][AWARD_G_YOSHI][2]);
		client_rolls[client][AWARD_G_YOSHI][2] -= RoundFloat(damage);
		if(client_rolls[client][AWARD_G_YOSHI][2] < 0)
		{
			damage = float(client_rolls[client][AWARD_G_YOSHI][2]) * -1.0;
			client_rolls[client][AWARD_G_YOSHI][2] = 0;
		}
		else return Plugin_Stop;
	}
		
	//Decrease self-damage perk
	//if (isAttackerSelf && RTD_PerksLevel[client][30] != 0)
	//	damage *= 1.0 - (RTD_Perks[client][30] * 0.01);
	
	///////////////////////////////////////////////////////////
	//Attacker must be a PLAYER and cannot be SELF           //
	///////////////////////////////////////////////////////////
	if(isAttackerPlayer && !isAttackerSelf && !sameTeam)
	{	
		if (yoshi_eaten[client][0] || yoshi_eaten[attacker][0])
		{
			damage = 0.0;
			return Plugin_Changed;
		}
		
		if(client_rolls[client][AWARD_G_BLIZZARD][7])
		{
			//PrintToChatAll("%i", damagetype);
			//reduce sentry damage while frozen
			if(damagetype  == 4098 || damagetype == 2359360)
				damage *= 0.05;
			
			if(damagetype & DMG_BURN)
				damage *= 0.02;
		}
		
		//Following is when user is burned when while still frozen by Blizzard
		if(damagetype & DMG_BURN && inBlizzardTime[client] != 0.0)
		{
			if(GetGameTime() <= inBlizzardTime[client])
			{
				//reduce flame damage
				damage *= 0.5;
				
			}else{
				//player is out of range
				inBlizzardTime[client] = 0.0;
			}
		}
		
		if(client_rolls[attacker][AWARD_G_BLIZZARD][0] && GetTime() > client_rolls[attacker][AWARD_G_BLIZZARD][4])
		{
			if(!TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
			{
				//can we freeze client
				if(GetTime() > client_rolls[client][AWARD_G_BLIZZARD][3])
				{
					//mark the next time the blizardee can freeze someone
					if(RTD_PerksLevel[attacker][37] == 1)
					{
						client_rolls[attacker][AWARD_G_BLIZZARD][4] = GetTime() + 20;
					}else{
						client_rolls[attacker][AWARD_G_BLIZZARD][4] = GetTime() + 30;
					}
					
					//remove the particle from the blizardee
					DeleteParticle(attacker, "SnowBlower_Main_fix");
					
					//mark the next time the client can get frozen
					client_rolls[client][AWARD_G_BLIZZARD][3] = GetTime() + 40;
					
					//mark the client as frozen
					client_rolls[client][AWARD_G_BLIZZARD][7] = 1;
					
					if(RTD_PerksLevel[attacker][38] == 1)
					{
						FreezeClient(client, attacker, 2.0);
					}else{
						FreezeClient(client, attacker, 1.0);
					}
				}
			}
		}
		
		if(client_rolls[attacker][AWARD_B_BADAIM][0])
		{
			damage *= 0.5;
		}
		
		if(client_rolls[attacker][AWARD_G_VAMPIRE][0] && damage > 5.0)
			addHealth(attacker, RoundFloat(damage*0.8), false);
		
		// If attacking player has instant kills
		if(client_rolls[attacker][AWARD_G_INSTANTKILL][0] && damage != 9999.0)
		{
			new cond = GetEntData(client, m_nPlayerCond);
			
			if(cond != 32 && cond != 327712)
			{
				
				SetHudTextParams(0.39, 0.82, 5.0, 250, 250, 210, 255);
				ShowHudText(client, HudMsg3, "You were insta-killed!");
				
				client_rolls[client][AWARD_G_ARMOR][0] = 0;
				client_rolls[client][AWARD_G_ARMOR][1] = 0;
				
				new Float:randomVec[3];
				randomVec[0]=GetRandomFloat(200.0, 300.0)*GetRandomInt(-2,2);
				randomVec[1]=GetRandomFloat(200.0, 300.0)*GetRandomInt(-2,2);
				randomVec[2]=GetConVarFloat(g_Cvar_DiscoHeight)*40.0;
				SetEntDataVector(client ,BaseVelocityOffset,randomVec,true);
				
				//Wait a little bit
				new Handle:dataPackHandle;
				CreateDataTimer(0.1, delayInstaKill, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
				
				WritePackCell(dataPackHandle, client); //
				WritePackCell(dataPackHandle, attacker); //8
				damage *= 0.0;
				
				return Plugin_Changed;
			}
		}
		
		//Player is loser
		if(client_rolls[client][AWARD_B_LOSER][0])
		{
			damage *= 0.1;
			return Plugin_Changed;
		}
		
		/*
		if(timeExpireScare[client] > GetTime())
		{
			damage *= 0.6;
			
			//PrintToChatAll("damagetype %i", damagetype);
		}*/
		
		//less damage on ice
		if(inIce[attacker] && damagetype == 16779264 || inIce[attacker] && damagetype == 2056)
		{
			damage *= 0.1;
			TF2_RemoveCond(attacker, 17);
		}
		
		//Coat enemies with milk if player is carrying Cow
		//Small chanc for this to happen
		if(client_rolls[attacker][AWARD_G_COW][1] != 0)
		{
			if(GetTime() > client_rolls[attacker][AWARD_G_COW][2])
			{
				client_rolls[attacker][AWARD_G_COW][2] = GetTime() + 15;
				
				if(RTD_Perks[attacker][17])
					client_rolls[attacker][AWARD_G_COW][2] -= 10;
				
				if(GetRandomInt(1, 5) == 1)
					TF2_AddCondition(client,TFCond_Milked,10.0);
				
			}
		}
		
		//Fire Bullets
		if(client_rolls[attacker][AWARD_G_FIREBULLETS][0])
		{
			//131072 = Burning
			if(!(GetEntProp(client, Prop_Send, "m_nPlayerCond")&131072))
			{
				TF2_IgnitePlayer(client, attacker);
			}
		}
		
		//Jarate Bullets
		if(client_rolls[attacker][AWARD_G_JARATEBULLETS][0])
		{
			TF2_AddCondition(client, TFCond_Jarated, 10.0);
		}
		
		//Using Collateral Damage
		if(client_rolls[attacker][AWARD_G_DIVIDETHESHOT][0] && damagetype != 1234)
		{
			new Float:vec[3];
			new Float:pos[3];
			new Float:distance;
			new cond;
			new rndDmg = RoundFloat(damage);
			
			GetClientEyePosition(client, vec);   
			
			for (new i = 1; i <= MaxClients ; i++)
			{
				if(!IsClientInGame(i) || i == client || !IsPlayerAlive(i))
					continue;
				
				if(GetClientTeam(i) != GetClientTeam(client))
					continue;
					
				GetClientEyePosition(i, pos);
				distance = GetVectorDistance(vec, pos);
				
				cond = GetEntData(i, m_nPlayerCond);
				
				if(client_rolls[i][AWARD_G_GODMODE][0])
					continue;
				
				if(cond == 32 || cond == 327712)
					continue;
				
				if(distance > 375.0)
						continue;
				
				DealDamage(i,(rndDmg/6), attacker, 1234, "collateral");
				
				SetHudTextParams(0.385, 0.82, 5.0, 255, 50, 50, 255);
				ShowHudText(i, HudMsg3, "You were hurt by Collateral Damage.");
			}
		}
		
		if(client_rolls[client][AWARD_G_CLASSIMMUNITY][0])
		{
			if(client_rolls[client][AWARD_G_CLASSIMMUNITY][1] == GetEntProp(attacker, Prop_Send, "m_iClass"))
			{
				new String:inflictorname[32];
				GetClientName(client, inflictorname, sizeof(inflictorname));
				
				SetHudTextParams(0.32, 0.82, 1.0, 250, 250, 210, 255);
				ShowHudText(attacker, HudMsg3, "%s is immune to your attacks", inflictorname);
				
				// block damage
				//4098 = Sentry damage
				
				if(damagetype != 4098 || damagetype != 2359360)
					damage *= 0.05;
			}
		}
		
		//mark to restore uber when user touches locker
		if(client_rolls[attacker][AWARD_B_WEAPONS][1])
		{
			//only update ubercharge if player is holding the ubersaw
			//cause that's when this value changes
			if(isPlayerHolding_UniqueWeapon(attacker, 37))
			{
				new weapon = GetPlayerWeaponSlot(attacker, 1);
				if (IsValidEntity(weapon))
				{
					new String:classname[64];
					GetEdictClassname(weapon, classname, 64);
					
					//is the player holding the medigun?
					if(StrEqual(classname, "tf_weapon_medigun"))
					{
						new Float:curUberLevel = GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel") ;
						
						client_rolls[attacker][AWARD_B_WEAPONS][2] =  RoundFloat(curUberLevel * 100.0);
					}
				}
			}
		}
		
		//Add +10% to ubercharge on enemy hit
		if(client_rolls[attacker][AWARD_G_UBERBOW][0])
		{
			if(isPlayerHolding_UniqueWeapon(attacker, 305))
			{
				TF_AddUberLevel(attacker, 0.1);
			}
		}
		
		//allow fire damage from Brazier
		if(client_rolls[attacker][AWARD_G_BRAZIER][5] > GetTime() && damagetype != 2056)
		{
			if(!(GetEntProp(client, Prop_Send, "m_nPlayerCond")&131072))
			{
				client_rolls[attacker][AWARD_G_BRAZIER][5] = 0;
				TF2_IgnitePlayer(client, attacker);
			}
		}
		
		//If the attacker is dooming another player
		if (client_rolls[attacker][AWARD_B_DOOM][0]) 
		{
			new time = client_rolls[attacker][AWARD_B_DOOM][1] - GetTime() + 4;
			DoomPlayer(attacker, false);
			DoomPlayer(client, true, time);
			PrintCenterText(attacker, "You have doomed another player, good job!");
		}
		
		if(hasInvisRolls(attacker))
		{
			//30% less damage if player is invisble
			new alpha = GetEntData(attacker, m_clrRender + 3, 1);
			
			if(alpha == 0)
				damage *= 0.7;
		}
		
		//If the attacker is dooming another player
		if (client_rolls[client][AWARD_G_MIRROR][0] && damagetype != 1235) 
		{
			new Float:rndDamage = damage * GetRandomFloat(0.5, 1.0);
			
			new  damageDealt = RoundFloat(rndDamage);
			
			//mirror damage cannot kill the attacker
			if((GetClientHealth(attacker) - damageDealt) > 1)
			{
				DealDamage(attacker, damageDealt, client, 1235, "mirror");
				
				SetHudTextParams(0.385, 0.82, 5.0, 255, 50, 50, 255);
				ShowHudText(attacker, HudMsg3, "You were hurt by Mirror Damage.");
			}
		}
		
		if(client_rolls[attacker][AWARD_G_FLAVOREDDAMAGE][0])
		{
			if(GetTime() > client_rolls[attacker][AWARD_G_FLAVOREDDAMAGE][6])
			{
				client_rolls[attacker][AWARD_G_FLAVOREDDAMAGE][6] = GetTime() + 7;
				client_rolls[attacker][AWARD_G_FLAVOREDDAMAGE][7] ++;
			}
			
			switch(client_rolls[attacker][AWARD_G_FLAVOREDDAMAGE][7])
			{
				case 1:
					TF2_AddCondition(client,TFCond_Jarated,5.0);
					
				case 2:
					TF2_AddCondition(client,TFCond_Milked,5.0);
					
				case 3:
					TF2_IgnitePlayer(client, attacker);
			}
		}
		
		if(client_rolls[attacker][AWARD_G_RUBBERBULLETS][0])
		{
			if(!(damagetype & 2056))
			{
				if(!TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
				{
					if(GetTime() > client_rolls[client][AWARD_G_RUBBERBULLETS][6])
					{
						client_rolls[client][AWARD_G_RUBBERBULLETS][6] = GetTime() + 1;
						Blast(client, attacker);
						EmitSoundToAll(SOUND_BOUNCE, client);
					}
				}
			}
		}
		
		if(RTD_TrinketActive[attacker][TRINKET_UNUSUALMELEE] && (damagetype & DMG_CLUB))
		{
			if(GetRandomInt(1,100) <= RTD_TrinketBonus[attacker][TRINKET_UNUSUALMELEE] && RTD_TrinketMisc[attacker][TRINKET_UNUSUALMELEE] < GetTime())
			{
				RTD_TrinketMisc[attacker][TRINKET_UNUSUALMELEE] = GetTime() + 5;
				
				//Jarate,Bleed,Fire,Stun"
				switch(RTD_TrinketLevel[attacker][TRINKET_UNUSUALMELEE])
				{
					case 0:
					{
						PrintHintText(client, "Attacker used: Jarate Melee Trinket");
						TF2_AddCondition(client, TFCond_Jarated, 5.0);
					}
					
					case 1:
					{
						PrintHintText(client, "Attacker used: Bleed Melee Trinket");
						TF2_MakeBleed(client, client, 5.0);
					}
					
					case 2:
					{
						PrintHintText(client, "Attacker used: Fire Melee Trinket");
						TF2_IgnitePlayer(client, attacker);
						DealDamage(client,0,attacker,2056,"tf_weapon_flamethrower");
					}
					
					case 3:
					{
						PrintHintText(client, "Attacker used: Stun Melee Trinket");
						PrintCenterText(client, "Attacker used: Stun melee Trinket");
						
						TF2_StunPlayer(client,2.5, 0.0, TF_STUNFLAGS_SMALLBONK, 0);
						//TF2_StunPlayer(client,2.0, 0.0, TF_STUNFLAGS_LOSERSTATE, 0);
						ResetClientSpeed(client);
						SetEntData(client, m_iMovementStunAmount, 0 );
					}
				}
			}
		}
		
		if(RTD_TrinketActive[attacker][TRINKET_HEAVYHITTER])
		{
			if(GetClientTeam(attacker) == BLUE_TEAM)
			{
				damage *= 1.0 + (float(RTD_TrinketBonus[attacker][TRINKET_HEAVYHITTER]) / 100.0);
				//PrintToChat(attacker, "Pre: %f | New: %f", oldDamage, damage);
			}
		}
		
		if(client_rolls[attacker][AWARD_G_STRENGTHDRAIN][5] > GetTime() && client_rolls[attacker][AWARD_G_STRENGTHDRAIN][5] != 0)
		{
			if(!TF2_IsPlayerInCondition(attacker, TFCond_Ubercharged))
			{
				damage *= 0.5;
			}
		}
		
		//Martin Luther King event
		if(rtd_Event_MLK)
		{
			if(TF2_GetPlayerClass(client) == TFClass_DemoMan)
			{
				if(TF2_GetPlayerClass(attacker) != TFClass_DemoMan)
					damage *= 0.90;
				
				if(damagetype == 2097152 || damagetype == 34603010)
				{
					damage = 0.0;
					PrintCenterText(client, "Headshot DODGED!");
					PrintCenterText(attacker, "Demomen are immune from headshots!");
					
				}
			}
		}
		
		if(client_rolls[attacker][AWARD_G_GROUNDINGBULLET][0])
		{
			if(!(damagetype & 2056))
			{
				if(!TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
				{
					if(GetTime() > client_rolls[client][AWARD_G_GROUNDINGBULLET][1])
					{
						GroundPlayer(client);
					}
				}
			}
		}
		
		//////////////////////////
		//Attacker is Horsemann //
		//////////////////////////
		
		//damage bonuses do not apply to spies
		if(!TF2_IsPlayerInCondition(attacker, TFCond_Disguised) && !TF2_IsPlayerInCondition(attacker, TFCond_Cloaked))
		{	
			//client deals 25% more damage
			if(client_rolls[attacker][AWARD_G_HORSEMANN][0])
			{
				damage *= 1.25;
			}
		}
	}
	
	////////////////////////
	//Client is Horsemann //
	////////////////////////
	
	//damage bonuses do not apply to spies
	if(!TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_IsPlayerInCondition(client, TFCond_Disguising) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !isAttackerSelf)
	{
		//client receives 50% less damage
		if(client_rolls[client][AWARD_G_HORSEMANN][0])
		{
			damage *= 0.25;
		}
	}
	
	////////////////////////
	//attacker
	if(client_rolls[client][AWARD_G_STONEWALL][0])
	{
		if(RTD_PerksLevel[client][49] > 0)
		{
			damage *= 0.65;
		}else{
			damage *= 0.8;
		}
		
		//additional 25% damage reistance
		if(client_rolls[client][AWARD_G_STONEWALL][4] > GetTime())
			damage *= 0.75;
		
		new rnd = GetRandomInt(1,3);
		switch(rnd)
		{
			case 1:
				EmitSoundToAll(SOUND_CONCRETE_IMPACT_01,client);
			
			case 2:
				EmitSoundToAll(SOUND_CONCRETE_IMPACT_02,client);
				
			case 3:
				EmitSoundToAll(SOUND_CONCRETE_IMPACT_03,client);
		}
	}
	
	//pumpkin damage
	if(damagetype == 393280)
	{
		new Float:angle[3];
		GetEntPropVector(inflictor, Prop_Data, "m_angRotation", angle);
		if(angle[0] == angle[1] && angle[1] == angle[2])
		{
			if(angle[0] == GetClientTeam(client))
				damage = 0.0;
		}
	}
	
	lastdamage[client] = damagetype;
	
	//Armor
	if(client_rolls[client][AWARD_G_ARMOR][0] && !sameTeam && !isAttackerSelf && !TF2_IsPlayerInCondition(client, TFCond_Ubercharged) && !TF2_IsPlayerInCondition(client, TFCond_Bonked))
	{		
		SetHudTextParams(0.07, 1.0, 1.0, 250, 250, 210, 255);
		ShowHudText(client, HudMsg5, "ARMOR: %i", client_rolls[client][AWARD_G_ARMOR][1]);
		
		client_rolls[client][AWARD_G_ARMOR][1] -= (RoundFloat(damage) - (RoundFloat(damage * 0.1)));
		
		if(client_rolls[client][AWARD_G_ARMOR][1] < 0)
		{
			damage = float(client_rolls[client][AWARD_G_ARMOR][1]) * -1.0;
			client_rolls[client][AWARD_G_ARMOR][0] = 0;
			client_rolls[client][AWARD_G_ARMOR][1] = 0;
			SetHudTextParams(0.35, 0.82, 5.0, 250, 250, 210, 255);
			ShowHudText(client, HudMsg3, "You no longer have Armor");
			DeleteParticle(client, "armor_blue");
			DeleteParticle(client, "armor_red");
			EmitSoundToAll(SOUND_ARMOR_BREAK_01,client);
		}else{
			new rnd = GetRandomInt(1,4);
			switch(rnd)
			{
				case 1:
					EmitSoundToAll(SOUND_ARMOR_IMPACT_01,client);
				
				case 2:
					EmitSoundToAll(SOUND_ARMOR_IMPACT_02,client);
					
				case 3:
					EmitSoundToAll(SOUND_ARMOR_IMPACT_03,client);
				
				case 4:
					EmitSoundToAll(SOUND_ARMOR_IMPACT_04,client);
			}
			
			if(clientOverlay[client] == false)
				ShowOverlay(client, "effects/com_shield002a.vmt ", 0.6);
			
			//10% damage taken
			damage *= 0.1;
		}
	}
	
	//No damage difference
	if(isAttackerPlayer)
	{
		if(dmgDebug[attacker])
		{
			new String:infclassname[256];
			GetEdictClassname(inflictor, infclassname, sizeof(infclassname));
			//Client: 2 | Atkr: 354| AtkrTeam: 0 | InfClass: headless_hatman | Infl: 354 | InflTeam: 0 |DMG: 220.000000 | damagetype: 128
			PrintToChat(attacker, "Client: %i | Atkr: %i| AtkrTeam: %i | InfClass: %s | Infl: %i | InflTeam: %i |DMG: %f | damagetype: %i",client,attacker,GetEntProp(attacker, Prop_Data, "m_iTeamNum"),infclassname, inflictor,GetEntProp(inflictor, Prop_Data, "m_iTeamNum"),damage,damagetype);
		}
	}
	
	
	//damage sensitive rolls
	if(isAttackerPlayer && !isAttackerSelf && !sameTeam)
	{
		if(client_rolls[attacker][AWARD_G_TIMETHIEF][0] && client_rolls[attacker][AWARD_G_TIMETHIEF][1] < GetTime())
		{
			client_rolls[attacker][AWARD_G_TIMETHIEF][1] = GetTime() + 5;
			new timeRedux;
			
			timeRedux = RoundFloat(damage/ 5.0);
			
			if(timeRedux > 0)
			{
				if(timeRedux > 20)
					timeRedux = 20;
				
				decl String:message[200];
				
				new String:attackerName[32];
				GetClientName(attacker, attackerName, sizeof(attackerName));
				
				SetHudTextParams(0.32, 0.82, 2.0, 250, 250, 210, 255);
				Format(message, 200, "%s stole %is from your Timer!", attackerName, timeRedux);
				centerHudText(client, message, 0.0, 2.0, HudMsg3, 0.79); 
				
				SetHudTextParams(0.32, 0.82, 2.0, 250, 250, 210, 255);
				Format(message, 200, "You stole: %is", timeRedux);
				
				centerHudText(attacker, message, 0.0, 2.0, HudMsg3, 0.79); 
				
				new timeleft;
				
				////////////////////////////////
				// ATTACKER TIME MANIPULATION //
				////////////////////////////////
				if(RTD_Timer[attacker] <= GetTime())
				{
					timeleft = GetConVarInt(c_Timelimit) - ( GetTime() - RTD_Timer[attacker] ) ;
				}else{
					timeleft = RTD_Timer[attacker] + GetConVarInt(c_Timelimit) - GetTime();
				}
				
				if(timeleft > 0)
				{
					RTD_Timer[attacker] -= timeRedux;	
				}
				
				////////////////////////////////
				// CLIENT TIME MANIPULATION   //
				////////////////////////////////
				if(RTD_Timer[client] <= GetTime())
				{
					timeleft = rtd_TimeLimit - ( GetTime() - RTD_Timer[client] ) ;
				}else{
					timeleft = RTD_Timer[client] + rtd_TimeLimit - GetTime();
				}
				
				if(timeleft > 0)
				{
					RTD_Timer[client] += timeRedux;
				}else{
					RTD_Timer[client] = (GetTime() - rtd_TimeLimit) + timeRedux;
				}
				
			}
			
		}
		
		//////////////////////////
		// HASTY CHARGE TRINKET //
		//////////////////////////
		if(RTD_TrinketActive[attacker][TRINKET_HASTYCHARGE])
		{
			if(TF2_GetPlayerClass(attacker) == TFClass_Soldier)
			{
				new weaponEntity = GetPlayerWeaponSlot(attacker, 1);
				
				if(weaponEntity > 0 && !GetEntProp(attacker, Prop_Send, "m_bRageDraining"))
				{
					new weaponID = GetEntProp(weaponEntity, Prop_Send, "m_iItemDefinitionIndex");
					
					if(weaponID == 129 || weaponID == 354)
					{
						//129 = The Buff Banner
						//354 = The Concheror
						new Float:ragelevel = GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
						
						new Handle:dataPackHandle;
						CreateDataTimer(0.0, rageMeter_DelayTimer, dataPackHandle, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
						
						//Setup the datapack with appropriate information
						WritePackCell(dataPackHandle, GetClientUserId(attacker));   //PackPosition(0);  Backpack Index
						WritePackFloat(dataPackHandle, ragelevel);   //PackPosition(0);  Backpack Index
						
					}
				}
			}
		}
		
	}
	
	if(!isAttackerSelf && !sameTeam)
	{
		/////////////////////////////////////////////////
		// HASTY CHARGE TRINKET: The Battalion's Backup//
		/////////////////////////////////////////////////
		//incoming damage to client
		if(RTD_TrinketActive[client][TRINKET_HASTYCHARGE])
		{
			if(TF2_GetPlayerClass(client) == TFClass_Soldier)
			{
				new weaponEntity = GetPlayerWeaponSlot(client, 1);
				
				if(weaponEntity > 0 && !GetEntProp(client, Prop_Send, "m_bRageDraining"))
				{
					new weaponID = GetEntProp(weaponEntity, Prop_Send, "m_iItemDefinitionIndex");
					
					if(weaponID == 226)
					{
						//226 = The Battalion's Backup
						new Float:ragelevel = GetEntPropFloat(client, Prop_Send, "m_flRageMeter");
						
						new Handle:dataPackHandle;
						CreateDataTimer(0.0, rageMeter_DelayTimer, dataPackHandle, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
						
						//Setup the datapack with appropriate information
						WritePackCell(dataPackHandle, GetClientUserId(client));   //PackPosition(0);  Backpack Index
						WritePackFloat(dataPackHandle, ragelevel);   //PackPosition(0);  Backpack Index
						
					}
				}
			}
		}
	}
	
	if(oldDamage == damage)
	{
		return Plugin_Continue;
	}else{
		return Plugin_Changed;
	}
}

DealDamage(victim,damage,attacker=0,dmg_type=DMG_GENERIC,String:weapon[]="")
{
	if(victim>0 && IsValidEdict(victim) && damage>0)
	{	
		new String:dmg_str[16];
		IntToString(damage,dmg_str,16);
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		new pointHurt=CreateEntityByName("point_hurt");
		if(pointHurt)
		{
			DispatchKeyValue(victim,"targetname","war3_hurtme");
			DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
			DispatchKeyValue(pointHurt,"Damage",dmg_str);
			DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,""))
			{
				DispatchKeyValue(pointHurt,"classname",weapon);
			}
			DispatchSpawn(pointHurt);
			
			if(IsValidEntity(attacker))
			{
				decl Float:origin[3];
				decl Float:angle[3];
				GetEntPropVector(attacker, Prop_Data, "m_vecOrigin", origin);
				GetEntPropVector(attacker, Prop_Data, "m_angRotation", angle);
				TeleportEntity(pointHurt, origin, angle, NULL_VECTOR);
			}
			
			AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
			DispatchKeyValue(pointHurt,"classname","point_hurt");
			DispatchKeyValue(victim,"targetname","war3_donthurtme");
			AcceptEntityInput(pointHurt,"kill");
		}
	}
}