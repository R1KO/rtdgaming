#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2>
#include <rtd_rollinfo>

public Action:Spawn_Snorlax(client, health, maxhealth)
{
	new Float:pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	
	new Float:angle[3];
	GetClientAbsAngles(client, angle);
	
	new box = CreateEntityByName("prop_physics_override");
	
	if ( box == -1 )
	{
		ReplyToCommand( client, "Failed to create a Snorlax Box!" );
		return Plugin_Handled;
	}
	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Cow" );
		return Plugin_Handled;
	}
	
	SetEntityModel(box, MODEL_SNORLAX);
	SetEntityModel(ent, MODEL_SNORLAX);
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	SetEntProp(box, Prop_Data, "m_takedamage", 0);  //default = 2
	
	
	DispatchSpawn(ent);
	DispatchSpawn(box);
	//Our 'sled' collision does not need to be rendered nor does it need shadows
	AcceptEntityInput( box, "DisableShadow" );
	SetEntityRenderMode(box, RENDER_NONE);
	
	//SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
	
	
	new iTeam =  GetEntProp(client, Prop_Data, "m_iTeamNum");
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 

	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	
	////////////////////////////////////////////
	// PLAYERS: SolidType:2 | CollisionGroup:5 | SolidFlags:16
	// Buildings:SolidType:2 | CollisionGroup:21 | SolidFlags:0
	// OBJ_SENTRYGUN: 
	
	//SetEntProp(box, Prop_Data, "m_usSolidFlags", 16);
	//SetEntProp(box, Prop_Send, "m_usSolidFlags", 16);
	
	SetEntProp(box, Prop_Data, "m_CollisionGroup", 1);
	SetEntProp(box, Prop_Send, "m_CollisionGroup", 1);
	
	SetEntProp( box, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( box, Prop_Send, "m_nSolidType", 6 );
	////////////////////////////////////////////////////////
	
	SetEntProp( ent, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 1);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
	
	AcceptEntityInput( box, "DisableCollision" );
	
	AcceptEntityInput( ent, "DisableCollision" );
	AcceptEntityInput( ent, "EnableCollision" );
	
	
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", maxhealth);
	SetEntProp(ent, Prop_Data, "m_iHealth", health);
	
	if(iTeam == RED_TEAM)
	{
		SetVariantString(bluDamageFilter);
		DispatchKeyValue(ent, "skin","1"); 
	}else{
		SetVariantString(redDamageFilter);
		DispatchKeyValue(ent, "skin","0"); 
	}
	
	AcceptEntityInput(ent, "SetDamageFilter", -1, -1, 0); 
	
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	
	/////////////////////////////////////////
	pos[2] += 40.0;
	TeleportEntity(ent, pos, angle, NULL_VECTOR);
	TeleportEntity(box, pos, angle, NULL_VECTOR);
	/////////////////////////////////////////
	
	//name the cow
	new String:cowName[128];
	Format(cowName, sizeof(cowName), "snorlax%i", ent);
	DispatchKeyValue(ent, "targetname", cowName);
	
	//Now lets parent the physics box to the animated spider
	new String:boxName[128];
	Format(boxName, sizeof(boxName), "snorlaxbox%i", box);
	DispatchKeyValue(box, "targetname", boxName);
	
	SetVariantString(boxName);
	AcceptEntityInput(ent, "SetParent");
	
	//Set the box transparent
	SetEntityRenderMode(box, RENDER_TRANSCOLOR);	
	SetEntityRenderColor(box, 0, 0, 0, 0);
	
	//SetEntProp(ent, Prop_Send, "m_bGlowEnabled", 1, 1);	
	
	new Handle:dataPack;
	CreateDataTimer(0.2,Snorlax_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPack, ent); //PackPosition(0) 
	WritePackCell(dataPack, box); //PackPosition(8) 
	WritePackCell(dataPack, 0);		//PackPosition(16), used to emit sounds
	
	HookSingleEntityOutput(ent, "OnHealthChanged", Snorlax_Hurt, false);
	
	//attach_respawnvisualizer(ent, 10.0, boxName);
	//attachPoint_Push(ent, 10.0, boxName);
	Create_phys_keepupright(ent, boxName, -1.0, 1200);
	
	SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	SetEntityRenderColor(ent, 255, 255, 255, 200);
	
	return Plugin_Handled;
}

public Snorlax_Hurt (const String:output[], caller, activator, Float:delay)
{
	if(IsValidEntity(caller))
	{
		new box = GetEntPropEnt(caller, Prop_Data, "m_pParent");
		
		if(IsValidEntity(box))
		{
			//PrintCenterText(activator, "You hurt a Snorlax!");
			AttachTempParticle(box,"env_sawblood", 1.0, false,"", 80.0, false);
			
			if(GetEntProp(caller, Prop_Data, "m_PerformanceMode") < GetTime())
			{
				SetEntProp(caller, Prop_Data, "m_PerformanceMode", GetTime() + 1);
				
				if(GetEntProp(caller, Prop_Data, "m_iTeamNum") == RED_TEAM)
				{
					DispatchKeyValue(caller, "skin","5"); 
				}else{
					DispatchKeyValue(caller, "skin","4"); 
				}
			}
				
			if(GetEntProp(caller, Prop_Data, "m_iHealth") <= 100)
			{
				new client = GetEntPropEnt(caller, Prop_Data, "m_hOwnerEntity");
				
				if(client > 0 && client <= MaxClients)
				{
					if(IsClientInGame(client))
					{
						if(activator > 0 && activator <= MaxClients)
						{
							new String:name[32];
							GetClientName(activator, name, sizeof(name));
							
							PrintCenterText(client, "%s killed your Snorlax!",name);
							EmitSoundToClient(client, SOUND_COW1);
							
							GetClientName(client, name, sizeof(name));
							PrintCenterText(activator, "You killed %s's Snorlax!",name);
						}
					}
				}else{
					if(activator > 0 && activator <= MaxClients)
					{
						//original owner no longer here
						PrintCenterText(activator, "You killed a Snorlax!");
					}
				}
				
				SetVariantString("die");
				AcceptEntityInput(caller, "SetAnimation", -1, -1, 0); 
				
				AcceptEntityInput( caller, "DisableCollision" );
				AcceptEntityInput( box, "DisableCollision" );
				
				UnhookSingleEntityOutput(caller, "OnHealthChanged", Snorlax_Hurt);
				
				killEntityIn(box, 20.0);
				
				//killEntityIn(caller, 0.1);
				//Let's reward the player for killing this entity
				TF_SpawnMedipack(box, "item_healthkit_full", true);
				TF_SpawnMedipack(box, "item_ammopack_full", true);
				
				StopSound(caller, SNDCHAN_AUTO, SOUND_SNORLAX);
				
				SetEntityRenderMode(caller, RENDER_TRANSCOLOR);
				SetEntityRenderColor(caller, 255, 255, 255, 255);
				
				if(GetEntProp(caller, Prop_Data, "m_iTeamNum") == RED_TEAM)
				{
					DispatchKeyValue(caller, "skin","5"); 
				}else{
					DispatchKeyValue(caller, "skin","4"); 
				}
				
				SetEntProp(caller, Prop_Data, "m_PerformanceMode", GetTime() + 10);
			}
		}
	}
}

public Action:Snorlax_Timer(Handle:timer, Handle:dataPack)
{	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPack);
	new snorlax			= ReadPackCell(dataPack);
	new box 			= ReadPackCell(dataPack);
	new soundInterval	= ReadPackCell(dataPack);
	
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(!IsValidEntity(box))
		return Plugin_Stop;
	
	if(!IsValidEntity(snorlax))
		return Plugin_Stop;
	
	new currIndex = GetEntProp(snorlax, Prop_Data, "m_nModelIndex");
	
	if(currIndex != snorlaxModelIndex)
		return Plugin_Stop;
	
	new snorlaxTeam = GetEntProp(snorlax, Prop_Data, "m_iTeamNum");
	
	if(GetEntProp(snorlax, Prop_Data, "m_PerformanceMode") < GetTime())
	{
		if(snorlaxTeam == RED_TEAM)
		{
			if(GetEntProp(snorlax, Prop_Data, "m_nSkin") != 1)
				DispatchKeyValue(snorlax, "skin","1"); 
		}else{
			if(GetEntProp(snorlax, Prop_Data, "m_nSkin") != 0)
				DispatchKeyValue(snorlax, "skin","0"); 
		}
	}
	
	//close the eyes once it dies and it's done animating
	if(GetEntProp(snorlax, Prop_Data, "m_iHealth") <= 100)
	{
		new isFinished = GetEntProp(snorlax, Prop_Data, "m_bSequenceFinished");
		if(isFinished)
		{
			if(snorlaxTeam == RED_TEAM)
			{
				DispatchKeyValue(snorlax, "skin","3"); 
			}else{
				DispatchKeyValue(snorlax, "skin","2"); 
			}
			
			return Plugin_Stop;
		}
		
		return Plugin_Continue;
	}
	
	
	soundInterval ++;
	if(soundInterval > 40)
	{
		soundInterval = 0;
		
		EmitSoundToAll(SOUND_SNORLAX, snorlax);
	}
	
	SetPackPosition(dataPack, 16);
	WritePackCell(dataPack, soundInterval);		//PackPosition(8), used to restart sounds
	
	/////////////////////////
	// Find nearby enemies //
	/////////////////////////
	
	new Float:dummyPos[3];
	new Float:dummyAngle[3];
	
	new Float: playerPos[3];
	new Float: distance;
	
	GetEntPropVector(snorlax, Prop_Data, "m_vecAbsOrigin", dummyPos);
	GetEntPropVector(snorlax, Prop_Data, "m_angRotation", dummyAngle);
	
	new m_CollisionGroup = GetEntProp(snorlax, Prop_Data, "m_CollisionGroup");
	
	//////////////////////////////////////////
	//determine who is close                //
	//////////////////////////////////////////
	new bool:isFriendlyNearby = false;
	new bool:isEnemyNearby = false;
	new Float:distanceFromBelly;
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		GetClientAbsOrigin(i,playerPos);
		distance = GetVectorDistance( playerPos, dummyPos);
		
		//do bouncy
		distanceFromBelly = playerPos[2] - dummyPos[2];
		//PrintToChat(i, "%f", distanceFromBelly);
		
		if(distance < 140.0 && distanceFromBelly > 70.0 && distanceFromBelly < 120.0 && m_CollisionGroup == 0)
			DoBounce(i);
		
		//uh-oh a player is too close!
		if(distance < 100.0)
		{
			//stay unsolid, prevent a lockup
			if(m_CollisionGroup == 1)
			{
				return Plugin_Continue;
			}
		}
		
		if(GetClientTeam(i) == snorlaxTeam)
		{
			if(distance > 150.0)
				continue;
			
			if(distance < 100.0 && isEnemyNearby && m_CollisionGroup == 1)
			{
				PrintCenterText(i, "Snorlax is trying to go solid but you're too close!");
			}
			
			isFriendlyNearby = true;
		}else{
			if(distance > 450.0)
				continue;
			
			isEnemyNearby = true;
		}
	}
	
	//Make the Snorlax solid only if there is an enemy nearby and not a friendly
	if(isEnemyNearby && !isFriendlyNearby)
	{
		if(m_CollisionGroup == 1)
		{
			//CLOSE!
			SetEntProp(snorlax, Prop_Data, "m_CollisionGroup", 0);
			SetEntProp(snorlax, Prop_Send, "m_CollisionGroup", 0);
			//EmitSoundToAll(SOUND_CAGECLOSE,snorlax);
			//return Plugin_Stop;
			SetEntityRenderMode(snorlax, RENDER_TRANSCOLOR);
			SetEntityRenderColor(snorlax, 255, 255, 255, 255);
		}
	}else if(!isEnemyNearby)
	{
		if(m_CollisionGroup == 0)
		{
			//OPEN!
			//Make the Snorlax unsolid
			SetEntProp(snorlax, Prop_Data, "m_CollisionGroup", 1);
			SetEntProp(snorlax, Prop_Send, "m_CollisionGroup", 1);
			SetEntityRenderMode(snorlax, RENDER_TRANSCOLOR);
			SetEntityRenderColor(snorlax, 255, 255, 255, 200);
		}
	}
	
	return Plugin_Continue;
}

public Action:DoBounce(any:client)
{
	//new Float:cvVSpeed = 600.0;
	//new Float:cvHSpeed = 2.5;
	//new Float:cvLife = 120.0;
	
	client_rolls[client][AWARD_G_SNORLAX][2] = GetTime() + 1;
	
	// Calculate and apply a new velocity to the player.
	new Float:speed[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", speed);
	speed[0] *= 1.1;
	speed[1] *= 1.1;
	
	speed[2] = 500.0;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, speed);
	
	// play sound 
	EmitSoundToAll(SOUND_BOUNCE, client);
	
	
	//AttachFastParticle(client, "rockettrail", 1.0);
}

public attachPoint_Push(ent, Float:zOffset, String:parentName[])
{
	//use these on the antenna
	//critgun_weaponmodel_red
	//critgun_weaponmodel_blu
	
	
	//Use these to "heal" from 
	//notes: has 2 control points
	//dispenser_beam_red_trail
	//dispenser_beam_blue_trail
	new point_push = CreateEntityByName("point_push");

	if (IsValidEdict(point_push))
	{
		new Float:pos[3]; 
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += zOffset;
		
		
		
		DispatchKeyValue(point_push, "targetname", "tf2particle");
		DispatchKeyValue(point_push, "parentname", parentName);
		
		///VALUES
		DispatchKeyValue(point_push, "enabled", "1");
		DispatchKeyValue(point_push, "magnitude", "1000.0");
		DispatchKeyValue(point_push, "radius", "200.0");
		DispatchKeyValue(point_push, "inner_radius", "200.0");
		DispatchKeyValue(point_push, "spawnflags", "8");
		
		DispatchSpawn(point_push);
		
		new iTeam =  GetEntProp(ent, Prop_Data, "m_iTeamNum");
		SetVariantInt(iTeam);
		AcceptEntityInput(point_push, "TeamNum", -1, -1, 0);
		
		SetVariantInt(iTeam);
		AcceptEntityInput(point_push, "SetTeam", -1, -1, 0);
		
		SetVariantString(parentName);
		AcceptEntityInput(point_push, "SetParent", point_push, point_push, 0);
		
		ActivateEntity(point_push);
		AcceptEntityInput(point_push, "TurnOn");
		
		ActivateEntity(point_push);
		AcceptEntityInput(point_push, "Enable");
		
		
		if(iTeam == RED_TEAM)
		{
			SetVariantString(bluDamageFilter);
		}else{
			SetVariantString(redDamageFilter);
		}
		AcceptEntityInput(point_push, "SetDamageFilter", -1, -1, 0); 
		
		TeleportEntity(point_push, pos, NULL_VECTOR, NULL_VECTOR);
	}
}