#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
/////////////////////////////////////////
// Spawns a flame                      //
/////////////////////////////////////////

public Action:createFlame(any:client, Float:timeAlive)
{	
	new Float:pos[3];
	//GetClientAbsOrigin(client,pos);
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
	pos[2] += 5;
	
	new Float:angle[3];
	angle[0] = 270.0;
	
	////////////////////
	//Spawn the flame //
	////////////////////
	new heatwaveParticle = -1;
	new flameParticle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(flameParticle))
	{
		///////////////////////////////////////////////////////////////////////////////////
		//Here we determine if the flame will have the heatwave particle attached to it, //
		//This particle is very intensive so it will only be created if there are        //
		//no other flames nearby                                                         //
		///////////////////////////////////////////////////////////////////////////////////
		new ent = -1;
		new bool:tooClose = false;
		
		while ((ent = FindEntityByClassname(ent, "info_particle_system")) != -1)
		{
			if(GetEntProp(ent, Prop_Data, "m_iHealth") == 799 && ent != flameParticle)
			{
				new Float:flamePos[3];
				GetEntPropVector(ent, Prop_Data, "m_vecOrigin", flamePos);
				if(GetVectorDistance(pos,flamePos) < 600.0)
				{
					tooClose = true;
					break;
				}
			}
		}
		
		/////////////////////////
		// Spawn the heatwaver //
		/////////////////////////
		if (!tooClose)
		{
			heatwaveParticle = CreateEntityByName("info_particle_system");
			if(IsValidEdict(heatwaveParticle))
			{
				pos[2] -= 35;
				
				TeleportEntity(heatwaveParticle, pos, NULL_VECTOR, NULL_VECTOR);
				SetEntProp(heatwaveParticle, Prop_Data, "m_iMaxHealth", 691);
				
				DispatchKeyValue(heatwaveParticle, "effect_name", "main_heatwaver_constant1");
				DispatchSpawn(heatwaveParticle);
				ActivateEntity(heatwaveParticle);
				
				AcceptEntityInput(heatwaveParticle, "start");
				pos[2] += 35;
			}
		}
		
		//////////////////////////
		// Setup the flame      //
		//////////////////////////
		TeleportEntity(flameParticle, pos, angle, NULL_VECTOR);
		
		DispatchKeyValue(flameParticle, "effect_name", "flamethrower");
		
		DispatchSpawn(flameParticle);
		ActivateEntity(flameParticle);
		
		AcceptEntityInput(flameParticle, "start");
		SetEntPropEnt(flameParticle, Prop_Data, "m_hOwnerEntity", client);
		
		EmitSoundToAll(SOUND_FlameLoop,flameParticle,_,_,_,0.5,_,_,_,_,_,120.0);
		
		SetEntProp(flameParticle, Prop_Data, "m_iMaxHealth", 691);
		SetEntProp(flameParticle, Prop_Data, "m_iHealth", 691);
		
		new iTeam = GetEntProp(client, Prop_Data, "m_iTeamNum");
		
		SetVariantInt(iTeam);
		AcceptEntityInput(flameParticle, "TeamNum", -1, -1, 0);
		
		SetVariantInt(iTeam);
		AcceptEntityInput(flameParticle, "SetTeam", -1, -1, 0); 
		
		//The Datapack stores all the Backpack's important values
		new Handle:dataPackHandle;
		CreateDataTimer(0.4, Timer_Flames, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
		
		//Setup the datapack with appropriate information
		WritePackCell(dataPackHandle, flameParticle);   					//PackPosition(0);  Particle entity
		WritePackCell(dataPackHandle, RoundFloat(timeAlive) + GetTime());	//PackPosition(8);  Time to kill flame
		WritePackCell(dataPackHandle, heatwaveParticle);     				//PackPosition(16); Heatwaver effect particle
		WritePackCell(dataPackHandle, 0);     								//PackPosition(24); Used to determine if it can get killed
		WritePackCell(dataPackHandle, GetTime() + 10);     					//PackPosition(32); Time to re-emit sound
		WritePackCell(dataPackHandle, GetTime());     						//PackPosition(40); Time to re-emit annotations to nearby players
	}
}

public Action:Timer_Flames(Handle:timer, Handle:dataPackHandle)
{
	ResetPack(dataPackHandle);
	new flameParticle = ReadPackCell(dataPackHandle);
	new timeToKill = ReadPackCell(dataPackHandle);
	new heatwaveParticle = ReadPackCell(dataPackHandle);
	new beingHurtTime = ReadPackCell(dataPackHandle);
	new reemitTime = ReadPackCell(dataPackHandle);
	new timeToShowAnnotations =  ReadPackCell(dataPackHandle);
	
	new String:classname[256];
	
	if(!IsValidEntity(flameParticle))
	{
		if(IsValidEntity(heatwaveParticle))
		{
			GetEdictClassname(heatwaveParticle, classname, sizeof(classname));
			
			if(StrEqual(classname, "info_particle_system", false))
				AcceptEntityInput(heatwaveParticle,"kill");
		}
		
		return Plugin_Stop;
	}
	
	GetEdictClassname(flameParticle, classname, sizeof(classname));
	if (!StrEqual(classname, "info_particle_system", false))
		return Plugin_Stop;
	
	///////////////////////
	// Remove flame      //
	///////////////////////
	if(GetTime() > timeToKill || beingHurtTime > 20)
	{
		StopSound(flameParticle, SNDCHAN_AUTO, SOUND_FlameLoop);
		AcceptEntityInput(flameParticle,"kill");
		
		//////////////////////////////
		// Remove Heatwave Particle //
		//////////////////////////////
		if(IsValidEntity(heatwaveParticle))
		{
			GetEdictClassname(heatwaveParticle, classname, sizeof(classname));
			if(StrEqual(classname, "info_particle_system", false))
				AcceptEntityInput(heatwaveParticle,"kill");
		}
		
		return Plugin_Stop;
	}
	
	//////////////////////
	// Reemit the sound //
	//////////////////////
	if(GetTime() > reemitTime)
	{
		StopSound(flameParticle, SNDCHAN_AUTO, SOUND_FlameLoop);
		SetPackPosition(dataPackHandle, 32);
		WritePackCell(dataPackHandle, GetTime() + 10);
		EmitSoundToAll(SOUND_FlameLoop,flameParticle,_,_,_,0.5,_,_,_,_,_,120.0);
	}
	
	////////////////////////////////////////////
	// Determine if annotations will be shown //
	////////////////////////////////////////////
	new bool:showAnnotations = false;
	
	if(timeToShowAnnotations <= GetTime())
	{
		SetPackPosition(dataPackHandle, 40);
		WritePackCell(dataPackHandle, GetTime() + 3); //24, time to show annotations
		showAnnotations = true;
	}
	
	//////////////////////////
	// Find nearby players //
	/////////////////////////
	new Float:flamePosition[3];
	GetEntPropVector(flameParticle, Prop_Data, "m_vecOrigin", flamePosition);
	
	new flameOwner = GetEntPropEnt(flameParticle, Prop_Data, "m_hOwnerEntity");
	new flameTeam = GetEntProp(flameParticle, Prop_Data, "m_iTeamNum");
	
	new Float:distance;
	new Float:pos[3];
	new cond;
	
	flamePosition[2] += 30.0;
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		GetClientEyePosition(i, pos);
		
		distance = GetVectorDistance(flamePosition, pos);
		
		cond = GetEntData(i, m_nPlayerCond);
		
		if(client_rolls[i][AWARD_G_GODMODE][0])
			continue;
		
		if(cond == 32 || cond == 327712)
			continue;
		
		//Make sure that the player is able to see the flame because if not
		//then most likely he should not get burned by it
		
		if(distance < 420.0 && showAnnotations)
		{
			if(GetClientTeam(i) != flameTeam)
			{
				SpawnAnnotationEx(i, flameParticle, "Enemy Flame", flamePosition, 4.0);
			}else{
				SpawnAnnotationEx(i, flameParticle, "Friendly Flame", flamePosition, 4.0);
			}
		}
		
		if(GetClientTeam(i) == flameTeam)
			continue;
		
		if(distance < 150.0 && client_rolls[i][AWARD_G_BLIZZARD][0])
		{
			PrintCenterText(i, "Freezing flame: %i%", RoundFloat((float(beingHurtTime)/20.0) * 100.0));
			beingHurtTime += 3;
		}
		
		if(distance > 100.0)
			continue;
		
		DealDamage(i,5, flameOwner, 16779264, "wallflame");
		DealDamage(i,0, flameOwner, 2056, "wallflame");
		
	}
	
	beingHurtTime --;
	
	if(beingHurtTime < 1)
		beingHurtTime = 0;
	
	SetPackPosition(dataPackHandle, 24);
	WritePackCell(dataPackHandle, beingHurtTime);
	
	return Plugin_Continue;
	
}