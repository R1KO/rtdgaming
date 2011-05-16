#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

#define INSTAPORTER_USESLEFT			0
#define INSTAPORTER_CLIENT				8
#define INSTAPORTER_BPORT				16
#define INSTAPORTER_EPORT				24
#define INSTAPORTER_PARTICLE			32
#define INSTAPORTER_SOUNDEMIT			40
#define INSTAPORTER_CURRENTVEC			48
#define INSTAPORTER_VECCOUNT			56
#define INSTAPORTER_VECOFFSET			64
#define DATAPACK_VECTOR_SIZE			24
#define INSTAPORTER_DMGPARTICLEEMIT		88

#define INSTAPORTER_PARTICLE_INTERVAL 	50.0
#define INSTAPORTER_MAX_FEET			30
#define INSTAPORTER_INITIAL_USES		25

public bool:Spawn_Instaporter(client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client)) {
		PrintToChatAll("Cannot spawn instaporter for client %d.", client);
		return false;
	}
	
	new Float:pos[3];
	GetClientEyePosition(client, pos);
	new Float:Direction[3];
	Direction[0] = pos[0];
	Direction[1] = pos[1];
	Direction[2] = pos[2]-1024;
	
	g_FilteredEntity = client;
	new Handle:Trace = TR_TraceRayFilterEx(pos, Direction, MASK_SOLID, RayType_EndPoint, TraceFilter);
	new Float:end[3];
	TR_GetEndPosition(end, Trace);
	CloseHandle(Trace);
	end[2] += 4;
	
	if (closeToModelVec(end, 200.0, "prop_dynamic", MODEL_INSTAPORTER)) {
		PrintCenterText(client, "Too close to another Insta-Porter.");
		return false;
	}
	
	if (client_rolls[client][AWARD_G_INSTAPORTER][1] == 2)
	{
		new instaporter = Instaporter_Create(client, end);
		if (instaporter == -1)
			return false;
		
		SetVariantString("wait");
		AcceptEntityInput(instaporter, "SetAnimation", -1, -1, 0); 
		
		SetEntProp(instaporter, Prop_Data, "m_PerformanceMode", 1);
		
		new particle = CreateEntityByName("info_particle_system");
		if (!IsValidEdict(particle)) {
			PrintToChatAll("Cannot create particle for instaporters.");
			killEntityIn(instaporter, 0.1);
			return false;
		}
		if (GetClientTeam(client) == RED_TEAM)
			DispatchKeyValue(particle, "effect_name", "critical_rocket_red");
		else
			DispatchKeyValue(particle, "effect_name", "critical_rocket_blue");
		DispatchSpawn(particle);
		
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		TeleportEntity(particle, end, NULL_VECTOR, NULL_VECTOR);
		
		//Create the massive timer call :D
		new Handle:data;
		CreateDataTimer(0.1, Timer_Instaporter, data, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(data, 0); //"Time to die" placeholder (0)
		WritePackCell(data, client); //The client...duh (8)
		WritePackCell(data, EntIndexToEntRef(instaporter)); //Placeholder for the beginning instaporter (16)
		WritePackCell(data, -1); //Placeholder for the ending instaporter (24)
		WritePackCell(data, EntIndexToEntRef(particle)); //Placeholder for the particle entity (32)
		WritePackCell(data, 0); //Timeleft before re-emitting teleporter sound (40)
		WritePackCell(data, 0); //Current vector for particle travel (48)
		WritePackCell(data, 1); //Number of vectors (56)
		//The first vector
		WritePackFloat(data, end[0]); //64
		WritePackFloat(data, end[1]); //72
		WritePackFloat(data, end[2]); //80
		WritePackCell(data, 0); //Time to reemit the damaged particles(88)
		
		//We will need a handle to the data when they drop the ending porter pad
		g_instaporter[client] = data;
		
		centerHudText(client, "You have limited wire, so go directly to where you want to place the exit.", 1.0, 8.0, HudMsg3, 0.75);
	}
	else if (client_rolls[client][AWARD_G_INSTAPORTER][1] == 1)
	{
		//Grab the handle that was saved and clear the global variable
		new Handle:data = g_instaporter[client];
		g_instaporter[client] = INVALID_HANDLE;
		
		//Somehow something screws up, so...
		if (data == INVALID_HANDLE)
			return true; //lie
		
		new instaporter = Instaporter_Create(client, end);
		if (instaporter == -1)
		{
			SetPackPosition(data, INSTAPORTER_BPORT);
			new b_porter = EntRefToEntIndex(ReadPackCell(data));
			if (IsValidEntity(b_porter))
				killEntityIn(b_porter, 0.1);
			SetPackPosition(data, INSTAPORTER_PARTICLE);
			new particle = EntRefToEntIndex(ReadPackCell(data));
			if (IsValidEntity(particle))
				killEntityIn(particle, 0.1);
			return false;
		}
		
		SetVariantString("idle");
		AcceptEntityInput(instaporter, "SetAnimation", -1, -1, 0); 
		
		SetEntProp(instaporter, Prop_Data, "m_PerformanceMode", 2);
		
		//Make both of the insta-porters destroyable
		SetPackPosition(data, INSTAPORTER_BPORT);
		SetEntProp(EntRefToEntIndex(ReadPackCell(data)), Prop_Data, "m_takedamage", 2);
		SetEntProp(instaporter, Prop_Data, "m_takedamage", 2);
		//Place the end instaporter in the datapack
		WritePackCell(data, EntIndexToEntRef(instaporter));		
		
		//Set the position of the final vec in the datapack
		SetPackPosition(data, INSTAPORTER_VECCOUNT);
		new totalVecs = ReadPackCell(data);
		SetPackPosition(data, (DATAPACK_VECTOR_SIZE * totalVecs - 1) + INSTAPORTER_VECOFFSET);
		new Float:last[3];
		last[0] = ReadPackFloat(data);
		last[1] = ReadPackFloat(data);
		last[2] = ReadPackFloat(data);
		//A we don't want the last particle point to end up right on top of the one before it
		if (GetVectorDistance(last, end) >= INSTAPORTER_PARTICLE_INTERVAL)
		{
			SetPackPosition(data, INSTAPORTER_VECCOUNT);
			WritePackCell(data, totalVecs + 1);
			SetPackPosition(data, (DATAPACK_VECTOR_SIZE * totalVecs) + INSTAPORTER_VECOFFSET);
			WritePackFloat(data, end[0]);
			WritePackFloat(data, end[1]);
			WritePackFloat(data, end[2]);
		}
		else
		{
			SetPackPosition(data, (DATAPACK_VECTOR_SIZE * totalVecs - 1) + INSTAPORTER_VECOFFSET);
			WritePackFloat(data, end[0]);
			WritePackFloat(data, end[1]);
			WritePackFloat(data, end[2]);
		}
		
		//Finally, update the datapack with when it should die
		ResetPack(data);
		WritePackCell(data, INSTAPORTER_INITIAL_USES + (RTD_PerksLevel[client][30] >= 1 ? 15 : 0)); //Die after so many uses
		
		new String:buf[192];
		Format(buf, 192, "Insta-Porter functional. Your team can now use it %d times :)", INSTAPORTER_INITIAL_USES);
		centerHudText(client, buf, 1.0, 8.0, HudMsg3, 0.75);
	}
	else {
		//PrintToChatAll("[RTD] Error in Spawn_Instaporter(...). Please report this.");
		return false;
	}
	return true;
}

public Instaporter_Create(client, Float:pos[3])
{
	new instaporter = CreateEntityByName("prop_dynamic");
	if ( instaporter == -1 )
	{
		ReplyToCommand(client, "Could not create an insta-porter.");
		return -1;
	}
	decl String:buf[32];
	Format(buf, 32, "porter_%d", instaporter);
	DispatchKeyValue(instaporter, "targetname", buf);
	SetEntityModel(instaporter, MODEL_INSTAPORTER);	
	DispatchSpawn(instaporter);
	new iTeam = GetClientTeam(client);
	SetVariantInt(iTeam);
	AcceptEntityInput(instaporter, "TeamNum", -1, -1, 0);
	SetVariantInt(iTeam);
	AcceptEntityInput(instaporter, "SetTeam", -1, -1, 0); 
	
	SetEntProp(instaporter, Prop_Data, "m_nSolidType", 6 );
	SetEntProp(instaporter, Prop_Send, "m_nSolidType", 6 );
	SetEntProp(instaporter, Prop_Data, "m_CollisionGroup", 3);
	SetEntProp(instaporter, Prop_Send, "m_CollisionGroup", 3);
	
	AcceptEntityInput( instaporter, "DisableCollision" );
	AcceptEntityInput( instaporter, "EnableCollision" );
	
	SetEntProp(instaporter, Prop_Data, "m_iMaxHealth", 1500);
	SetEntProp(instaporter, Prop_Data, "m_iHealth", 1500);
	SetVariantString(iTeam == RED_TEAM ? bluDamageFilter : redDamageFilter);
	AcceptEntityInput(instaporter, "SetDamageFilter", -1, -1, 0);
	
	new Float:ang[3];
	GetClientAbsAngles(client, ang);
	ang[1] -= 180.0;
	TeleportEntity(instaporter, pos, ang, NULL_VECTOR);
	
	if(iTeam == RED_TEAM)
		DispatchKeyValue(instaporter, "skin","1"); 
	
	HookSingleEntityOutput(instaporter, "OnHealthChanged", InstaPorter_Hurt, false);
	HookSingleEntityOutput(instaporter, "OnBreak", InstaPorter_Break, false);
	SDKHook(instaporter,	SDKHook_OnTakeDamage, 	InstaPorterHook);
	
	return instaporter;
}

public InstaPorter_Hurt (const String:output[], caller, activator, Float:delay)
{
	if(IsValidEntity(caller))
	{
		if(GetEntProp(caller, Prop_Data, "m_iHealth") <= 0)
		{
			StopSound(caller, SNDCHAN_AUTO, SOUND_INSTAPORT);
			AttachTempParticle(caller,"ExplosionCore_MidAir", 2.0, false,"",0.0, false);
		}
	}
}

public InstaPorter_Break (const String:output[], caller, activator, Float:delay)
{
	if(IsValidEntity(caller))
	{
		if(GetEntProp(caller, Prop_Data, "m_iHealth") <= 0)
		{
			StopSound(caller, SNDCHAN_AUTO, SOUND_INSTAPORT);
			AttachTempParticle(caller,"ExplosionCore_MidAir", 2.0, false,"",0.0, false);
			
			EmitSoundToAll(SOUND_INSTAPORT_EXPLODE, caller);
			
		}
	}
}

public Action:Timer_Instaporter(Handle:timer, Handle:data)
{
	ResetPack(data);
	new usesleft = ReadPackCell(data);
	new client = ReadPackCell(data);
	new b_instaporter = EntRefToEntIndex(ReadPackCell(data));
	new e_instaporter = EntRefToEntIndex(ReadPackCell(data));
	new particle = EntRefToEntIndex(ReadPackCell(data));
	new nextSoundEmission = ReadPackCell(data);
	
	new bool:client_valid = IsValidClient(client);
	new bool:b_ip_valid = IsValidEntity(b_instaporter);
	new bool:e_ip_valid = IsValidEntity(e_instaporter);
	new bool:p_valid = IsValidEntity(particle);
	
	//Preliminary checks
	if (!client_valid
		|| (!client_rolls[client][AWARD_G_INSTAPORTER][0] && !e_ip_valid)
		|| !b_ip_valid 
		|| !p_valid
		|| GetEntProp(b_instaporter, Prop_Data, "m_iHealth") <= 0
		|| (e_ip_valid && GetEntProp(e_instaporter, Prop_Data, "m_iHealth") <= 0)
		|| roundEnded) 
	{		
		if (b_ip_valid)
		{
			killEntityIn(b_instaporter, 0.1);
			StopSound(b_instaporter, SNDCHAN_AUTO, SOUND_INSTAPORT);
		}
		
		if (e_ip_valid)
		{
			killEntityIn(e_instaporter, 0.1);
			StopSound(e_instaporter, SNDCHAN_AUTO, SOUND_INSTAPORT);
		}
		
		if (p_valid)
			killEntityIn(particle, 0.1);
		
		if (client_valid) 
		{
			if (roundEnded && client_rolls[client][AWARD_G_INSTAPORTER][0] && client_rolls[client][AWARD_G_INSTAPORTER][1])
			{
				client_rolls[client][AWARD_G_INSTAPORTER][1] = 2;
			}else if (client_rolls[client][AWARD_G_INSTAPORTER][1] != 2)
			{
				client_rolls[client][AWARD_G_INSTAPORTER][1] = 0;
				client_rolls[client][AWARD_G_INSTAPORTER][0] = 0;
			}
		}
			
		return Plugin_Stop;
	}
	
	//Player died before placing the second insta-porter, refund it.
	if (!IsPlayerAlive(client) && !e_ip_valid)
	{
		if (b_ip_valid) 
		{
			StopSound(b_instaporter, SNDCHAN_AUTO, SOUND_INSTAPORT);
			killEntityIn(b_instaporter, 0.1);
		}
		
		if (p_valid)
			killEntityIn(particle, 0.1);
			
		//Reimburse the first insta-porter
		client_rolls[client][AWARD_G_INSTAPORTER][1]++;
		
		return Plugin_Stop;
	}
	
	if (!e_ip_valid)
	{
		SetPackPosition(data, INSTAPORTER_VECCOUNT);
		new totalVecs = ReadPackCell(data);
		new Float:pos[3], Float:vector[3];
		GetClientAbsOrigin(client, pos);
		
		//Get the last vector
		SetPackPosition(data, (DATAPACK_VECTOR_SIZE * (totalVecs - 1)) + INSTAPORTER_VECOFFSET);
		vector[0] = ReadPackFloat(data);
		vector[1] = ReadPackFloat(data);
		vector[2] = ReadPackFloat(data);
		
		//Check that the player didn't somehow teleport too far away.
		new Float:distance = GetVectorDistance(pos, vector);
		if (distance >= 200) {
			if (b_ip_valid) killEntityIn(b_instaporter, 0.1);
			if (p_valid) killEntityIn(particle, 0.1);
			client_rolls[client][AWARD_G_INSTAPORTER][1]++;
			PrintCenterText(client, "Woops, you traveled too far too fast and your wire broke.  Try again.");
			return Plugin_Stop;
		}
		
		//Add a new vector if they have traveled far enough
		if (distance >= INSTAPORTER_PARTICLE_INTERVAL) {
			new vecsLeft = INSTAPORTER_MAX_FEET - totalVecs;
			if (RTD_PerksLevel[client][30] >= 1)
				vecsLeft += 20;
			if (vecsLeft >= 0)
				PrintCenterText(client, "You have %d feet of Insta-Porter wire left.", vecsLeft);
			else {
				//If the player ran out of wire or then reimburse the first insta-porter
				if (b_ip_valid) killEntityIn(b_instaporter, 0.1);
				if (p_valid) killEntityIn(particle, 0.1);
				client_rolls[client][AWARD_G_INSTAPORTER][1]++;
				PrintCenterText(client, "Woops, you ran out of wire.  Try again.");
				return Plugin_Stop;
			}
		
			SetPackPosition(data, INSTAPORTER_VECCOUNT);
			WritePackCell(data, totalVecs + 1);
			SetPackPosition(data, (DATAPACK_VECTOR_SIZE * totalVecs) + INSTAPORTER_VECOFFSET);
			WritePackFloat(data, pos[0]);
			WritePackFloat(data, pos[1]);
			WritePackFloat(data, pos[2]);
		}
	}
	else
	{
		//make the entrance have the moving animation
		if(GetEntProp(b_instaporter, Prop_Data, "m_nSequence") != 0)
		{
			SetVariantString("idle");
			AcceptEntityInput(b_instaporter, "SetAnimation", -1, -1, 0); 
			
			SetVariantString("idle");
			AcceptEntityInput(e_instaporter, "SetAnimation", -1, -1, 0);
			
		}
		
		//Get the next vector and teleport the particle
		SetPackPosition(data, INSTAPORTER_CURRENTVEC);
		new current = ReadPackCell(data) + 1;
		new total = ReadPackCell(data);
		if (current >= total)
			current = 0;
		SetPackPosition(data, (DATAPACK_VECTOR_SIZE * current) + INSTAPORTER_VECOFFSET);
		new Float:pos[3];
		pos[0] = ReadPackFloat(data);
		pos[1] = ReadPackFloat(data);
		pos[2] = ReadPackFloat(data);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		SetPackPosition(data, INSTAPORTER_CURRENTVEC);
		WritePackCell(data, current);
		
		//Get the vectors needed to teleport clients
		new Float:from_pos[3], Float:to_pos[3], Float:ang[3], Float:no_vel[3];
		SetPackPosition(data, INSTAPORTER_VECOFFSET);
		from_pos[0] = ReadPackFloat(data);
		from_pos[1] = ReadPackFloat(data);
		from_pos[2] = ReadPackFloat(data);
		SetPackPosition(data, (DATAPACK_VECTOR_SIZE * (total - 1)) + INSTAPORTER_VECOFFSET);
		to_pos[0] = ReadPackFloat(data);
		to_pos[1] = ReadPackFloat(data);
		to_pos[2] = ReadPackFloat(data);
		
		to_pos[2] += 25;
		
		GetEntPropVector(e_instaporter, Prop_Data, "m_angAbsRotation", ang);
		ang[1] += 180.0;
		new team = GetEntProp(b_instaporter, Prop_Data, "m_iInitialTeamNum");
		
		new String:client_name[32];
		new bool:haveName = GetClientName(client, client_name, 32);
		
		//Find out if there are enemies on the other end
		new enemyNearExit = false;
		for (new i = 1; i < MaxClients; i++) 
		{
			if (!IsValidClient(i) || !IsPlayerAlive(i))
				continue;
			
			if (team == GetClientTeam(i))
				continue;
			
			new Float:pos_i[3];
			GetClientAbsOrigin(i, pos_i);
			
			if (GetVectorDistance(to_pos, pos_i) > 250)
				continue;
			
			enemyNearExit = true;
			break;
		}
		
		//Check if a client should be teleported
		new Float:pos_i[3];
		new cflags;
		for (new i = 1; i < MaxClients; i++)
		{
			if (!IsValidClient(i) || !IsPlayerAlive(i))
				continue;
			
			GetClientAbsOrigin(i, pos_i);
			if (GetVectorDistance(pos_i, from_pos) > 100)
				continue;
			
			if (team != GetClientTeam(i)) 
			{
				centerHudText(i, "You cannot use another team's Insta-Porter.", 0.1, 1.0, HudMsg3, 0.75);
				continue;			
			}
			
			if (enemyNearExit) 
			{
				centerHudText(i, "Enemies at the exit are preventing you from teleporting.", 0.1, 1.0, HudMsg3, 0.75);
				continue;			
			}
			
			cflags = GetEntData(i, m_fFlags);
			if(!(cflags & FL_DUCKING && cflags & FL_ONGROUND)) {
				//Hopefully this isn't very expensive :/
				centerHudText(i, "Crouch to use this Insta-Porter.", 0.1, 1.0, HudMsg3, 0.75);
				continue;
			}
			
			TeleportEntity(i, to_pos, ang, no_vel);
			EmitSoundToAll(SOUND_INSTAPORT_TELE, i);
			TF2_AddCondition(i, TFCond_TeleportedGlow, 5.0);
			
			if (RTD_PerksLevel[client][30] >= 2) 
			{
				if(!client_rolls[client][AWARD_G_ARMOR][0]) 
				{
					client_rolls[client][AWARD_G_ARMOR][0] = 1;
					client_rolls[client][AWARD_G_ARMOR][1] = 75;//Status of Armor HP
				} else if (client_rolls[client][AWARD_G_ARMOR][1] < 75) {
					client_rolls[client][AWARD_G_ARMOR][1] = 75;//Status of Armor HP
				}
			}
			
			if (i != client && haveName) 
			{
				new String:buf[96];
				Format(buf, 96, "You used %s's Insta-Porter.", client_name);
				centerHudText(i, buf, 1.0, 3.0, HudMsg3, 0.75);
			}
			
			//show effects when teleported player
			AttachTempParticle(b_instaporter,"teleported_flash", 0.5, false,"",0.0, false);
			AttachTempParticle(e_instaporter,"teleported_flash", 0.5, false,"",0.0, false);
			
			if(team == BLUE_TEAM)
			{
				AttachTempParticle(b_instaporter,"teleported_blue", 1.0, false,"",0.0, false);
				AttachTempParticle(e_instaporter,"teleported_blue", 1.0, false,"",0.0, false);
				
				AttachTempParticle(e_instaporter,"teleportedin_blue", 1.0, false, "", 5.0, false);
				
			}else{
				AttachTempParticle(b_instaporter,"teleported_red", 1.0, false,"",0.0, false);
				AttachTempParticle(e_instaporter,"teleported_red", 1.0, false,"",0.0, false);
				
				AttachTempParticle(e_instaporter,"teleportedin_red", 1.0, false, "", 5.0, false);
			}
			
			usesleft--;
			
			//Check if the uses for these instaporters is up
			if (usesleft <= 0) 
			{
				if (b_ip_valid) killEntityIn(b_instaporter, 0.1);
				if (e_ip_valid) killEntityIn(e_instaporter, 0.1);
				if (p_valid) killEntityIn(particle, 0.1);
				return Plugin_Stop;
			}
			
			ResetPack(data);
			WritePackCell(data, usesleft);
		}
		
		/////////////////////////////////////////////
		//Reemit sounds every 15s even though this //
		//sound is already "loopable" this is done //
		//to make sure everyone hears it...        //
		/////////////////////////////////////////////
		if (nextSoundEmission <= GetTime()) 
		{
			StopSound(b_instaporter, SNDCHAN_AUTO, SOUND_INSTAPORT);
			StopSound(e_instaporter, SNDCHAN_AUTO, SOUND_INSTAPORT);
			
			EmitSoundToAll(SOUND_INSTAPORT, b_instaporter);
			EmitSoundToAll(SOUND_INSTAPORT, e_instaporter);
			SetPackPosition(data, INSTAPORTER_SOUNDEMIT);
			WritePackCell(data, GetTime() + 15);
			
			//////////////////////////////////////////////////////////////
			//while we're here let's remit the particle system as well  //
			//////////////////////////////////////////////////////////////
			
			//retrieve instaPorter name for parenting reasons
			decl String:instaName1[32];
			decl String:instaName2[32];
			Format(instaName1, 32, "porter_%d", b_instaporter);
			Format(instaName2, 32, "porter_%d", e_instaporter);
			
			if(team == BLUE_TEAM)
			{
				AttachTempParticle(b_instaporter,"teleporter_blue_entrance_level3", 16.0, true, instaName1, 0.0, false);
				AttachTempParticle(e_instaporter,"teleporter_blue_exit_level3", 16.0, true, instaName2, 0.0, false);
			}else{
				AttachTempParticle(b_instaporter,"teleporter_red_entrance_level3", 16.0, true, instaName1, 0.0, false);
				AttachTempParticle(e_instaporter,"teleporter_red_exit_level3", 16.0, true, instaName2, 0.0, false);
			}
			
			
		}
		
		//////////////////////////
		//Show damage particle  //
		//////////////////////////
		SetPackPosition(data, INSTAPORTER_DMGPARTICLEEMIT);
		new nextDmgParticleEmission = ReadPackCell(data);
		
		if (nextDmgParticleEmission <= GetTime()) 
		{
			SetPackPosition(data, INSTAPORTER_DMGPARTICLEEMIT);
			WritePackCell(data, GetTime() + 1);
			
			new instaPorterHealth[2];
			new instaPorterMaxHealth[2];
			new Float:healthRatio[2];
			new instaPorterEntity[2];
			
			instaPorterEntity[0] = b_instaporter;
			instaPorterHealth[0] = GetEntProp(instaPorterEntity[0], Prop_Data, "m_iHealth");
			instaPorterMaxHealth[0] = GetEntProp(instaPorterEntity[0], Prop_Data, "m_iMaxHealth");
			healthRatio[0] = float(instaPorterHealth[0])/float(instaPorterMaxHealth[0]);
			
			instaPorterEntity[1] = e_instaporter;
			instaPorterHealth[1] = GetEntProp(instaPorterEntity[1], Prop_Data, "m_iHealth");
			instaPorterMaxHealth[1] = GetEntProp(instaPorterEntity[1], Prop_Data, "m_iMaxHealth");
			healthRatio[1] = float(instaPorterHealth[1])/float(instaPorterMaxHealth[1]);
			
			
			for (new i = 0; i <= 1; i++)
			{
				if(healthRatio[i] <= 0.8 && healthRatio[i] > 0.6)
				{
					AttachTempParticle(instaPorterEntity[i],"tpdamage_1" , 2.0, false, "", 5.0, false);
				}else if(healthRatio[i] <= 0.6 && healthRatio[i] > 0.4)
				{
					AttachTempParticle(instaPorterEntity[i],"tpdamage_2" , 2.0, false, "", 5.0, false);
				}else if(healthRatio[i] <= 0.4 && healthRatio[i] > 0.2)
				{
					AttachTempParticle(instaPorterEntity[i],"tpdamage_3" , 2.0, false, "", 5.0, false);
				}else if(healthRatio[i] <= 0.2)
				{
					AttachTempParticle(instaPorterEntity[i],"tpdamage_4" , 2.0, false, "", 5.0, false);
				}
			}
		}
		
		
		
	}
	return Plugin_Continue;
}

public Action:InstaPorterHook(instaporter, &attacker, &inflictor, &Float:damage, &damagetype)
{
	//////////////////////////////////////////////////////////////////////////////////////
	//Repair InstaPorter                                                                //
	//                                                                                  //
	//Here we take metal from the Engineer if they hit the instaporter with the wrench  //
	//////////////////////////////////////////////////////////////////////////////////////
	
	//Check that the attacker is on same team
	if(GetEntProp(instaporter, Prop_Data, "m_iTeamNum") != GetEntProp(attacker, Prop_Data, "m_iTeamNum"))
		return Plugin_Continue;
	
	damage = 0.0;
	
	//only Engineer's can repair the building
	if(TF2_GetPlayerClass(attacker) != TFClass_Engineer)
		return Plugin_Changed;
	
	//Verify that the Engineer hit the InstaPorter with the Wrench
	if(!(damagetype&DMG_CLUB))
		return Plugin_Changed;
	
	//check to see if the InstaPorter needs to be repaired
	new instaPorterHealth = GetEntProp(instaporter, Prop_Data, "m_iHealth");
	new instaPorterMaxHealth = GetEntProp(instaporter, Prop_Data, "m_iMaxHealth");
	
	if(instaPorterHealth >= instaPorterMaxHealth)
		return Plugin_Changed;
	
	//make sure Engineer has metal to repair the InstaPorter
	new metalAmount = AmmoInActiveWeapon(attacker);
	
	if(metalAmount <= 0)
		return Plugin_Changed;
	
	//each swing can repair up to 30HP at the cost of 10 metal
	//1 Metal = 3HP
	new neededHealth = instaPorterMaxHealth - instaPorterHealth;
	
	//the insta porter needs as much health as allowed per swing
	if(neededHealth > 30)
	{
		//make sure Engineer has enough metal
		if(metalAmount >= 10)
		{
			SetVariantInt(30);
			AcceptEntityInput(instaporter, "AddHealth");
			
			metalAmount -= 10;
			SetActiveWeaponAmmo(attacker, metalAmount);
			
		}else{
			//engineer does not have enough metal to heal it 30HP
			SetVariantInt(metalAmount * 3);
			AcceptEntityInput(instaporter, "AddHealth");
			
			metalAmount = 0;
			SetActiveWeaponAmmo(attacker, metalAmount);
		}
	}else{
		//The instaporter just needs a little bit of health
		
		//make sure Engineer has enough metal
		new costToRepair = RoundFloat(float(neededHealth)/3.0);
		
		if(metalAmount >= costToRepair)
		{
			SetVariantInt(neededHealth);
			AcceptEntityInput(instaporter, "AddHealth");
			
			metalAmount -= costToRepair;
			SetActiveWeaponAmmo(attacker, metalAmount);
			
		}else{
			//engineer does not have enough metal to heal it 30HP
			SetVariantInt(metalAmount * 3);
			AcceptEntityInput(instaporter, "AddHealth");
			
			metalAmount = 0;
			SetActiveWeaponAmmo(attacker, metalAmount);
		}
	}
	
	return Plugin_Changed;
}