#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <rtd_rollinfo>

stock TF_AddUberLevel(client, Float:uberlevel)
{
	new weapon = GetPlayerWeaponSlot(client, 1);
	if (IsValidEntity(weapon))
	{
		new String:classname[64];
		GetEdictClassname(weapon, classname, 64);
		
		//is the player holding the medigun?
		if(StrEqual(classname, "tf_weapon_medigun"))
		{
			new Float:curUberLevel = GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel") ;
			curUberLevel = FloatAdd(curUberLevel, uberlevel);
			
			if(curUberLevel > 1.0)
				curUberLevel = 1.0;
			
			SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", curUberLevel);
		}
	}
}

public Action:MedicVirus(Handle:timer, any:client)
{
	if(!IsClientInGame(client))
		return Plugin_Stop;
	
	if(TF2_GetPlayerClass(client) != TFClass_Medic || !client_rolls[client][AWARD_G_MEDICVIRUS][0])
		return Plugin_Stop;
	
	new String:name[32];
	new patient;
	GetClientName(client, name, sizeof(name));
	
	new weapon = GetPlayerWeaponSlot(client, 1);
	if (weapon != -1)
	{
		new String:classname[64];
		GetEdictClassname(weapon, classname, 64);
		
		//is the player holding the medigun?
		if(StrEqual(classname, "tf_weapon_medigun"))
		{
			patient = GetEntDataEnt2(weapon, m_hHealingTarget);
			
			//is he healing someone?
			if (patient >= 1 && patient <= MaxClients)
			{	
				if(GetClientTeam(patient) == GetClientTeam(client))
				{
					if ((GetClientHealth(patient) + 25) < finalHealthAdjustments(client))
						SetEntityHealth(patient,GetClientHealth(patient) + 25);
					
				//Healing a spy
				}else{
					SetHudTextParams(0.35, 0.82, 5.0, 250, 250, 210, 255);
					ShowHudText(patient, HudMsg3, "You are being infected!");
					
					SetHudTextParams(0.35, 0.82, 5.0, 250, 250, 210, 255);
					
					if (GetClientHealth(patient) > 10)
						SetEntityHealth(patient,GetClientHealth(patient) - 10);
				}
			}
		}
	}
	
	return Plugin_Continue;
}

stock IsUbermenchCandidate(client)
{
	if (client_rolls[client][AWARD_G_UBERCHARGER][0] == 0)
		return -5;
	if (TF2_GetPlayerClass(client) != TFClass_Medic || RTD_PerksLevel[client][29] == 0)
		return -4;
	new weapon = GetPlayerWeaponSlot(client, 1);
	if (weapon == -1)
		return -3;
	new String:classname[64];
	GetEdictClassname(weapon, classname, 64);
	if (!StrEqual(classname, "tf_weapon_medigun"))
		return -2;
	new patient = GetEntDataEnt2(weapon, m_hHealingTarget);
	if (IsValidClient(patient) && client_rolls[patient][AWARD_G_UBERCHARGER][0] == 0)
		return weapon;
	return -1;
}

public Action:UberchargerTimer(Handle:timer, any:client)
{
	if(!client_rolls[client][AWARD_G_UBERCHARGER][0])
	{
		KillTimer(timer);
		return Plugin_Handled;
	}
	
	//Check and see if this person can get 2x uber from the perk
	new medigun_id = IsUbermenchCandidate(client);
	if (medigun_id >= 0) {
		new Float:uberLevel = GetEntPropFloat(medigun_id, Prop_Send, "m_flChargeLevel");
		uberLevel += 0.0027;
		if (uberLevel > 1.0)
			uberLevel = 1.0;
		PrintHintText(client, "Your charge rate is being DOUBLED!");
		SetEntPropFloat(medigun_id, Prop_Send, "m_flChargeLevel", uberLevel);
	}
	
	//Now update the rest of the team for this client
	new team = GetClientTeam(client);
	for (new i = 1; i <= MaxClients; i++)
	{
		//ok let's do a couple of checks
		if(!IsClientInGame(i) || client == i)
			continue;
		if (IsUbermenchCandidate(i) >= 0)
			continue;
		if (TF2_GetPlayerClass(i) != TFClass_Medic || GetClientTeam(i) != team)
			continue;
		new weapon = GetPlayerWeaponSlot(i, 1);
		if (weapon == -1)
			continue;
		new String:classname[64];
		GetEdictClassname(weapon, classname, 64);
		//is the player holding the medigun?
		if (!StrEqual(classname, "tf_weapon_medigun"))
			continue;
		new patient = GetEntDataEnt2(weapon, m_hHealingTarget);
		if (patient != client)
			continue;
			
		new Float:currentvalue = GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel");
		currentvalue += 0.004; //tripled = 0.2
		if (currentvalue > 1.0)
			currentvalue = 1.0;
		PrintHintText(i, "Your charge rate is being TRIPLED!");
		SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", currentvalue);
	}
	return Plugin_Continue;
}

public TF_SpawnMedipack(client, String:name[], killEntAutomatically)
{
	new Float:PlayerPosition[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", PlayerPosition);
	//GetClientAbsOrigin(client, PlayerPosition);
		
	if (PlayerPosition[0] != 0.0 && PlayerPosition[1] != 0.0 && PlayerPosition[2] != 0.0 && IsEntLimitReached() == false)
	{
		PlayerPosition[2] += 4;
		g_FilteredEntity = client;
		
		new Float:Direction[3];
		Direction[0] = PlayerPosition[0];
		Direction[1] = PlayerPosition[1];
		Direction[2] = PlayerPosition[2]-1024;
		new Handle:Trace = TR_TraceRayFilterEx(PlayerPosition, Direction, MASK_SOLID, RayType_EndPoint, TraceFilter);
		
		new Float:MediPos[3];
		TR_GetEndPosition(MediPos, Trace);
		CloseHandle(Trace);
		MediPos[2] += 4;
		
		//LogToFile(logPath,"Attempting to create: %s",name);
		new Medipack = CreateEntityByName(name);
		DispatchKeyValue(Medipack, "OnPlayerTouch", "!self,Kill,,0,-1");
		
		if (killEntAutomatically)
			killEntityIn(Medipack, 15.0);
		// send "kill" event to the event queue
		
		DispatchSpawn(Medipack);
		TeleportEntity(Medipack, MediPos, NULL_VECTOR, NULL_VECTOR);
		EmitSoundToAll(SOUND_B, Medipack);
		
		return Medipack;
		//LogToFile(logPath,"Created [%i]: %s",Medipack, name);
	}
	
	return -1;
}

public TF_SpawnMedipack_Ex(client, String:name[], killEntAutomatically, String:model[])
{
	new Float:PlayerPosition[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", PlayerPosition);
	
	if (PlayerPosition[0] != 0.0 && PlayerPosition[1] != 0.0 && PlayerPosition[2] != 0.0 && IsEntLimitReached() == false)
	{
		PlayerPosition[2] += 4;
		g_FilteredEntity = client;
		
		new Float:Direction[3];
		Direction[0] = PlayerPosition[0];
		Direction[1] = PlayerPosition[1];
		Direction[2] = PlayerPosition[2]-1024;
		new Handle:Trace = TR_TraceRayFilterEx(PlayerPosition, Direction, MASK_SOLID, RayType_EndPoint, TraceFilter);
		
		new Float:MediPos[3];
		TR_GetEndPosition(MediPos, Trace);
		CloseHandle(Trace);
		MediPos[2] += 4;
		
		//LogToFile(logPath,"Attempting to create: %s",name);
		new Medipack = CreateEntityByName(name);
		DispatchKeyValue(Medipack, "OnPlayerTouch", "!self,Kill,,0,-1");
		
		if (killEntAutomatically)
			killEntityIn(Medipack, 15.0);
		// send "kill" event to the event queue
		
		DispatchSpawn(Medipack);
		TeleportEntity(Medipack, MediPos, NULL_VECTOR, NULL_VECTOR);
		EmitSoundToAll(SOUND_B, Medipack);
		
		SetEntityModel(Medipack, model);
		
		return Medipack;
		//LogToFile(logPath,"Created [%i]: %s",Medipack, name);
	}
	
	return -1;
}

stock TF_SpawnTempMedipack(client, String:name[])
{
	new Float:PlayerPosition[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", PlayerPosition);
	//GetClientAbsOrigin(client, PlayerPosition);
		
	if (IsEntLimitReached() == false)
	{	
		new Medipack = CreateEntityByName(name);
		DispatchKeyValue(Medipack, "OnPlayerTouch", "!self,Kill,,0,-1");
		
		killEntityIn(Medipack, 1.0);
		// send "kill" event to the event queue
		
		DispatchSpawn(Medipack);
		TeleportEntity(Medipack, PlayerPosition, NULL_VECTOR, NULL_VECTOR);
		//EmitSoundToAll(SOUND_B, Medipack);
	}
}

public healSpider(client, spider, spiderTeam, box, Float:distance)
{
	new uberingPlayer = -1;
	new particleEnt = GetEntProp(box, Prop_Data, "m_iHammerID");
	new weapon = GetEntDataEnt2(client, FindSendPropInfo("CTFPlayer", "m_hActiveWeapon"));
	if(IsValidEntity(weapon))
	{
		new String:classname[64];
		GetEdictClassname(weapon, classname, 64);
		new foundHealer;
		new patient;
		
		//Does the spider have the ubered skin out?
		//If so and no matching client was found then
		//reset the spider's condition
		if(GetEntProp(spider, Prop_Data, "m_nSkin") != 0)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || !IsPlayerAlive(i))
					continue;
				
				weapon = GetEntDataEnt2(i, FindSendPropInfo("CTFPlayer", "m_hActiveWeapon"));
				if(IsValidEntity(weapon))
				{
					GetEdictClassname(weapon, classname, 64);
					
					//is the player wielding the medigun?
					if(StrEqual(classname, "tf_weapon_medigun"))
					{
						patient = GetEntDataEnt2(weapon, FindSendPropInfo("CWeaponMedigun", "m_hHealingTarget"));
						
						if(patient == box)
						{
							new cond = GetEntData(i, m_nPlayerCond);
							
							//K, we found a medic ubering the spider
							if(cond & 32)
							{
								foundHealer = 1;
								//PrintToChatAll("Being ubered!");
								break;
							}
						}
					}
				}
			}
			
			//No medic found to be ubering the spider
			if(foundHealer == 0)
			{
				//PrintToChatAll("revertin!");
				DispatchKeyValue(spider, "skin","0"); 
				SetEntProp(spider, Prop_Data, "m_takedamage", 2);  //default = 2
			}
		}
		
		if(spiderTeam == GetClientTeam(client))
		{
			if( TF2_GetPlayerClass(client) == TFClass_Medic)
			{
				//PrintToChatAll("callin!");
				
				new currentHealth = GetEntProp(spider, Prop_Data, "m_iHealth");
				patient = -1;
				
				//This is the healing particles being emmitted from the spider
				if(!IsValidEntity(particleEnt))
					particleEnt = -1;
				
				//If the entity found is not a particle then let's
				//start emmitting a new particle
				if(IsValidEntity(particleEnt))
				{
					GetEdictClassname(particleEnt, classname, sizeof(classname));
					
					if (!StrEqual(classname, "info_particle_system", false))
						particleEnt = -1;
				}
				
				GetEdictClassname(weapon, classname, 64);
				//is the player wielding the medigun?
				if(StrEqual(classname, "tf_weapon_medigun"))
				{
					patient = GetEntDataEnt2(weapon, FindSendPropInfo("CWeaponMedigun", "m_hHealingTarget"));
					
					//PrintToChatAll("Patient: %i | Box:%i | Weapon: %s",patient,box,classname);
					
					//let's heal some Spiders :D
					if(patient == -1)
					{
						if(distance < 500.0 && !(GetClientButtons(client) & IN_ATTACK) )
						{
							SetEntDataEnt2(weapon, FindSendPropInfo("CWeaponMedigun", "m_hHealingTarget"),box);
							
							//the medicgunheal sound is loopable so it must be stopped before being emitted
							//StopSound(weapon, SNDCHAN_AUTO, SOUND_MEDIGUNHEAL);
							//EmitSoundToAll(SOUND_MEDIGUNHEAL,weapon);
						}	
					}
					
					if(patient != -1 && patient == box && distance >= 500.0)
						SetEntDataEnt2(weapon, FindSendPropInfo("CWeaponMedigun", "m_hHealingTarget"),-1);
					
					if(patient != -1 && patient == box)
					{
						//refill the medic's ubercharge
						new Float:currentvalue = GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel");
						//PrintToChatAll("%f",currentvalue);
						
						currentvalue += 0.004; //tripled = 0.2
						
						new cond = GetEntData(client, m_nPlayerCond);
						
						//follow the player healing the spider
						uberingPlayer = client;
						
						if(cond & 32)
						{
							SetEntProp(spider, Prop_Data, "m_takedamage", 0);
							
							if(GetEntProp(spider, Prop_Data, "m_nSkin") == 0)
							{
								if(GetClientTeam(client) == BLUE_TEAM)
								{
									DispatchKeyValue(spider, "skin","1"); 
								}else{
									DispatchKeyValue(spider, "skin","2"); 
								}
							}
						}
						
						if (currentvalue >= 1.0){
							SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", 1.0);
						}else{
							SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", currentvalue);
						}
							
						if(currentHealth < GetEntProp(spider, Prop_Data, "m_iMaxHealth"))
						{
							SetEntProp(spider, Prop_Data, "m_iHealth", currentHealth + 4);
							
							if(particleEnt == -1)
							{
								if(spiderTeam == BLUE_TEAM)
									particleEnt = AttachTempParticle(box, "healthgained_blu", 0.3, false,"",0.0, false);
								
								if(spiderTeam == RED_TEAM)
									particleEnt = AttachTempParticle(box, "healthgained_red", 0.3, false,"",0.0, false);
							}
							
						}else{
							
							//overheal
							if(spiderTeam == BLUE_TEAM)
								particleEnt = AttachTempParticle(box, "healhuff_blu", 1.0, false,"",0.0, false);
									
							if(spiderTeam == RED_TEAM)
								particleEnt = AttachTempParticle(box, "healhuff_red", 1.0, false,"",0.0, false);
						}
						
					}
				}
				
				//yell for medic
				if(currentHealth < GetEntProp(spider, Prop_Data, "m_iMaxHealth") - 50 && particleEnt == -1 && distance < 800.0 && patient != box)
				{
					new rndNum = GetRandomInt(0,5);
					if(rndNum == 4)
					{
						StopSound(spider,SNDCHAN_AUTO, SOUND_SPIDERYELLMEDIC);
						EmitSoundToAll(SOUND_SPIDERYELLMEDIC,spider,_,_,_,_,160);
						
						new String:boxName[128];
						Format(boxName, sizeof(boxName), "target%i", box);
						
						particleEnt =  AttachTempParticle(box, "speech_medichurt", 6.0, true, boxName, 25.0, false);
					}
				}
				
				//thanks medic
				new spiderSounds = GetEntProp(spider, Prop_Data, "m_PerformanceMode");
				if(distance < 800.0 && patient == box && spiderSounds == 1 && GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel") < 1.0)
				{
					new rndNum = GetRandomInt(0,7);
					new bool:sndChange = false;
					
					if(rndNum == 2 || rndNum == 4 || rndNum == 6)
						sndChange = true;
					
					if(sndChange)
					{
						StopSound(spider,SNDCHAN_AUTO,SOUND_SPIDERTHANKSMEDIC1);
						StopSound(spider,SNDCHAN_AUTO,SOUND_SPIDERTHANKSMEDIC2);
						StopSound(spider,SNDCHAN_AUTO,SOUND_SPIDERTHANKSMEDIC3);
						
						if(rndNum == 2)
							EmitSoundToAll(SOUND_SPIDERTHANKSMEDIC1,spider,_,_,_,_,160);
					
						if(rndNum == 4)
							EmitSoundToAll(SOUND_SPIDERTHANKSMEDIC2,spider,_,_,_,_,160);
					
						if(rndNum == 6)
							EmitSoundToAll(SOUND_SPIDERTHANKSMEDIC3,spider,_,_,_,_,160);
						
						spiderSounds = 0;
						SetEntProp(spider, Prop_Data, "m_PerformanceMode", 0);
						CreateTimer(6.0, SphereSoundRdy, spider);
					}
				}
				
				//tell medic to ubercharge us
				if(distance < 800.0 && patient == box && spiderSounds == 1 && GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel") >= 1.0)
				{
					new rndNum = GetRandomInt(0,4);
					new bool:sndChange = false;
					
					if(rndNum == 1 || rndNum == 2 || rndNum == 3)
						sndChange = true;
					
					if(sndChange)
					{
						StopSound(spider,SNDCHAN_AUTO,SOUND_SPIDERACTIVATECHARGE01);
						StopSound(spider,SNDCHAN_AUTO,SOUND_SPIDERACTIVATECHARGE02);
						StopSound(spider,SNDCHAN_AUTO,SOUND_SPIDERACTIVATECHARGE03);
						
						if(rndNum == 1)
							EmitSoundToAll(SOUND_SPIDERACTIVATECHARGE01,spider,_,_,_,_,160);
					
						if(rndNum == 2)
							EmitSoundToAll(SOUND_SPIDERACTIVATECHARGE02,spider,_,_,_,_,160);
					
						if(rndNum == 3)
							EmitSoundToAll(SOUND_SPIDERACTIVATECHARGE03,spider,_,_,_,_,160);
					
						SetEntProp(spider, Prop_Data, "m_PerformanceMode", 0);
						CreateTimer(4.0, SphereSoundRdy, spider);
					}
				}
				
				SetEntProp(box, Prop_Data, "m_iHammerID", particleEnt);
			}
		}
	}
	return uberingPlayer;
}