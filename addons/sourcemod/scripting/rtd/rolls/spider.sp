#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>

new AFKScore[cMaxClients];
new Float:playerAFKPos[cMaxClients][3];

//////////////////////////////////////////////////////////
// Spawns a spider that interacts with the environment  //
// lookinging for friendlies, enemies and 'waypoints'   //
//                                                      //
//////////////////////////////////////////////////////////

public Action:Spawn_Spider(client, health, MaxHealth)
{
	//LogToFile(logPath,"Spawn_Spider -- Entering");
	
	new box = CreateEntityByName("prop_physics_override");
	if ( box == -1 )
	{
		ReplyToCommand( client, "Failed to create a SpiderBox!" );
		return Plugin_Handled;
	}
	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Spider!" );
		return Plugin_Handled;
	}
	
	SetEntityModel(box, MODEL_SPIDERBOX);
	SetEntityModel(ent, MODEL_SPIDER);
	
	
	//make sure to do this before we actually spawn the P.O.S.
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	SetEntProp(box, Prop_Data, "m_takedamage", 0);  //default = 2
	
	DispatchSpawn(box);
	DispatchSpawn(ent);
	
	//Our 'sled' collision does not need to be rendered nor does it need shadows
	AcceptEntityInput( box, "DisableShadow" );
	SetEntityRenderMode(box, RENDER_NONE);
	
	//client that spawned this spider
	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
	
	//owner entity for the Box tells it its the Spider
	SetEntPropEnt(box, Prop_Data, "m_hOwnerEntity", ent);
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	
	SetEntProp( ent, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 3);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 3);
	
	SetEntProp( box, Prop_Data, "m_nSolidType", 4 );
	SetEntProp( box, Prop_Send, "m_nSolidType", 4 );
	
	//Set the spider's health
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", MaxHealth);
	SetEntProp(ent, Prop_Data, "m_iHealth", health);
	
	SetEntProp(ent, Prop_Data, "m_PerformanceMode", 1);
	
	//argggh F.U. valve
	AcceptEntityInput( ent, "DisableCollision" );
	AcceptEntityInput( ent, "EnableCollision" );
	
	HookSingleEntityOutput(ent, "OnHealthChanged", spider_Hurt, false);
	//HookSingleEntityOutput(ent, "OnBreak", spider_Die, false);
	
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	//new iTeam = GetClientTeam(client);
	new iTeam = GetEntProp(client, Prop_Data, "m_iTeamNum");
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	
	SetVariantInt(iTeam);
	AcceptEntityInput(box, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(box, "SetTeam", -1, -1, 0); 
	
	new Float:pos[3];
	//GetClientEyePosition(client, pos);
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	pos[2] += 80.0; //push it up cause we arent using eye pos anymore
	
	new Float:Direction[3];
	Direction[0] = pos[0];
	Direction[1] = pos[1];
	Direction[2] = pos[2]-1024;
	
	new Float:AmmoPos[3];
	
	new Handle:Trace = TR_TraceRayFilterEx(pos, Direction, MASK_SOLID, RayType_EndPoint, TraceFilterAll, client);
	TR_GetEndPosition(AmmoPos, Trace);
	CloseHandle(Trace);
	
	AmmoPos[2] += 20.0;
	
	TeleportEntity(ent, AmmoPos, NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(box, AmmoPos, NULL_VECTOR, NULL_VECTOR);
	
	//set the default animation
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	
	//name the spider
	new String:boxName[128];
	Format(boxName, sizeof(boxName), "spider%i", ent);
	DispatchKeyValue(ent, "targetname", boxName);
	
	//Now lets parent the physics box to the animated spider
	Format(boxName, sizeof(boxName), "target%i", box);
	DispatchKeyValue(box, "targetname", boxName);
	
	SetVariantString(boxName);
	AcceptEntityInput(ent, "SetParent");
	
	//Set the box transparent
	SetEntityRenderMode(box, RENDER_TRANSCOLOR);	
	SetEntityRenderColor(box, 0, 0, 0, 0);
	
	//filter_team_red
	
	if(iTeam == RED_TEAM)
	{
		SetVariantString(bluDamageFilter);
	}else{
		SetVariantString(redDamageFilter);
	}
	
	AcceptEntityInput(ent, "SetDamageFilter", -1, -1, 0); 
	
	//The Datapack stores all the Spider's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, SpiderThink_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//client name
	new String:name[32];
	if(client > 0 && client <= MaxClients)
	{
		GetClientName(client, name, sizeof(name));
	}
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(ent)); //
	WritePackCell(dataPackHandle, EntIndexToEntRef(box)); //8
	WritePackCell(dataPackHandle, iTeam); //16
	WritePackFloat(dataPackHandle, 40.0); //24 - The range tolerance
	WritePackCell(dataPackHandle, client); //32 - Client that spawned it
	WritePackCell(dataPackHandle, GetEntProp(ent, Prop_Data, "m_iMaxHealth")); //40
	WritePackCell(dataPackHandle, -1); 	//48 - Player ID ubering spider
	WritePackCell(dataPackHandle, -1); 	//56 - Object entity that is the closest
	WritePackCell(dataPackHandle, -1); 	//64 - Object teamnum that is closest
	WritePackCell(dataPackHandle, 1001);//72 - Object distance that is closest
	WritePackCell(dataPackHandle, -1); 	//80 - Player entity that is the closest
	WritePackCell(dataPackHandle, -1); 	//88 - Player teamnum that is closest
	WritePackCell(dataPackHandle, 1001);//96 - Playertdistance that is closest
	WritePackCell(dataPackHandle, -1); 	//104 - Is object closer or is the player closer?
	WritePackCell(dataPackHandle, -1); 	//112 - Flame Entity --pack position = 112
	WritePackCell(dataPackHandle, -1); 	 //PackPosition(120); Last player that the NPC was moving to
	WritePackCell(dataPackHandle, GetTime()+GetRandomInt(30, 80)); 	 //PackPosition(128); Time req. to RTD
	WritePackCell(dataPackHandle, -1); 	 //PackPosition(136); Last player that the NPC was moving to
	WritePackFloat(dataPackHandle, -1.0); //144 - 0 |Pos of last entity
	WritePackFloat(dataPackHandle, -1.0); //152 - 1
	WritePackFloat(dataPackHandle, -1.0); //160 - 2
	WritePackCell(dataPackHandle, GetTime() + 120); 	//168 - Time to KillEntity, this is upped everytime a PLAYER is seen
	WritePackString(dataPackHandle, name); //176
	/*
	for (new i = 144; i <= 200; i++)
	{
		SetPackPosition(dataPackHandle, i);
		PrintToChatAll("Index: %i | Value: %f", i, ReadPackFloat(dataPackHandle));
	}
	*/
	
	return Plugin_Handled;
}
 
public spider_Hurt (const String:output[], caller, activator, Float:delay)
{
	if(IsValidEntity(caller))
	{
		new String:modelname[128];
		GetEntPropString(caller, Prop_Data, "m_ModelName", modelname, 128);
		if (StrEqual(modelname, MODEL_SPIDER) || StrEqual(modelname, MODEL_SPIDERBACK))
		{	
			//attach blood gibs
			new box = GetEntPropEnt(caller, Prop_Data, "m_pParent");
			
			
			if(IsValidEntity(box))
				AttachTempParticle(box,"env_sawblood", 1.0, false,"",0.0, false);
			
			if(GetEntProp(caller, Prop_Data, "m_iHealth") <= 0)
			{
				SendObjectDestroyedEvent(activator, caller, "killedspider");
				//show some chunky blood on death
				AttachTempParticle(caller,"blood_trail_red_01_goop", 1.0, false,"",0.0, false);
				StopSound(caller, SNDCHAN_AUTO, SOUND_SpiderTurn);
				StopSound(caller, SNDCHAN_AUTO, SOUND_FlameLoop);
				EmitSoundToAll(SOUND_SpiderDie,caller);
				
				if(activator <= MaxClients && activator > 0)
				{
					EmitSoundToClient(activator,SOUND_NULL,activator,_,_,_,0.3);
				}
				
				//Let's reward the player for killing a spider
				new rndNum = GetRandomInt(0,20);
				if(rndNum > 10)
				{
					TF_SpawnMedipack(caller, "item_healthkit_medium", true);
				}else{
					TF_SpawnMedipack(caller, "item_ammopack_medium", true);
				}
				
				if(StrEqual(modelname, MODEL_SPIDERBACK))
				{
					new wearer = GetEntPropEnt(caller, Prop_Data, "m_hOwnerEntity");
					if(wearer > 0 && wearer < MaxClients)
					{
						if(IsPlayerAlive(wearer))
						{
							client_rolls[wearer][AWARD_G_SPIDER][1] = 0;
							TF2_MakeBleed(wearer, wearer, 5.0);
						}
					}
				}	
			}else{
				//play hurt sounds
				new rndNum = GetRandomInt(1,8);
				
				if(rndNum == 1)
					EmitSoundToAll(SOUND_SPIDERSHURT01,caller,_,SNDLEVEL_HELICOPTER,_,_,140);
				
				if(rndNum == 2)
					EmitSoundToAll(SOUND_SPIDERSHURT02,caller,_,SNDLEVEL_HELICOPTER,_,_,140);
				
				if(rndNum == 3)
					EmitSoundToAll(SOUND_SPIDERSHURT03,caller,_,SNDLEVEL_HELICOPTER,_,_,140);
				
				if(rndNum == 4)
					EmitSoundToAll(SOUND_SPIDERSHURT04,caller,_,SNDLEVEL_HELICOPTER,_,_,140);
				
				if(rndNum == 5)
					EmitSoundToAll(SOUND_SPIDERSHURT05,caller,_,SNDLEVEL_HELICOPTER,_,_,140);
				
				if(rndNum == 6)
					EmitSoundToAll(SOUND_SPIDERSHURT06,caller,_,SNDLEVEL_HELICOPTER,_,_,140);
					
				if(rndNum == 7)
					EmitSoundToAll(SOUND_SPIDERSHURT07,caller,_,SNDLEVEL_HELICOPTER,_,_,140);
				
				if(rndNum == 8)
					EmitSoundToAll(SOUND_SPIDERSHURT08,caller,_,SNDLEVEL_HELICOPTER,_,_,140);
				
				new spiderSounds = GetEntProp(caller, Prop_Data, "m_PerformanceMode");
				
				//an enemy is within range, lets insult him and such
				if(spiderSounds == 1)
				{
					rndNum = GetRandomInt(0,8);
					
					if(rndNum == 1)
						EmitSoundToAll(SOUND_SPIDERONFIRE01,caller,_,_,_,_,140);
					
					if(rndNum == 2)
						EmitSoundToAll(SOUND_SPIDERONFIRE02,caller,_,_,_,_,140);
					
					if(rndNum >= 1 && rndNum <= 2)
					{
						SetEntProp(caller, Prop_Data, "m_PerformanceMode", 0);
						CreateTimer(2.0, SphereSoundRdy, caller);
					}
				}
			}
		}
	}
	
	//LogToFile(logPath,"spider_Hurt -- Leaving");
}

public Action:SpiderThink_Timer(Handle:timer, Handle:dataPackHandle)
{
	//LogToFile(logPath,"SpiderThink_Timer -- Entering");
	
	/////////////////////////////////////////////////////////////////////
    //           The Basics of Spider AI                               //
	//-----------------------------------------------------------------//
	//                                                                 //
	//Spiders follow and will attack if enemy in this order            //
	//   1.) Closest player enemy                                      //
	//   2.) Closest enemy spider                                      //
	//   3.) Closest enemy buildable                                   //
	//   4.) Closest friendly                                          //
	//   5.) Closest friendly spider                                   //
	//   6.) Closest friendly buildable                                //
	/////////////////////////////////////////////////////////////////////
	
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopSpiderThinkTimer(dataPackHandle))
		return Plugin_Stop;
	
	////////////////////////////////
	//Setup local variables       //
	////////////////////////////////
	new Float:spiderPosition[3];
	new Float:traceRaySpiderPosition[3];
	new Float: rangeTolerance;
	new box;
	new closestEntity = -1;
	new Float:closestDistance = 1001.0;
	new spiderTeam;
	new closestEntityTeam;
	new whoIsCloser = -1;
	new spider;
	new spiderOwner;
	new flameEntity = -1;
	
	///////////////////////////////////////////////////////////////////////////////////
	//RangeTolerance is  used to detect the tolerances the spider is able to find    //
	//someone indicates the line of sight 'fuzziness' that way the spider can see    //
	//partial bodies when shooting the trace ray                                     //
	///////////////////////////////////////////////////////////////////////////////////
	
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	spider = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	box = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	spiderTeam = ReadPackCell(dataPackHandle);
	rangeTolerance = ReadPackFloat(dataPackHandle);
	spiderOwner = ReadPackCell(dataPackHandle);
	
	SetPackPosition(dataPackHandle, 112);
	flameEntity = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	new owner = GetEntPropEnt(spider, Prop_Data, "m_hOwnerEntity");
	spiderRollDice(box, owner, dataPackHandle);
	
	if(flameEntity <= 0)
	{
		flameEntity = -1;
		SetPackPosition(dataPackHandle, 112);
		WritePackCell(dataPackHandle, -1);
	}
	
	if(spiderOwner != spiderTeam)
	{
		SetPackPosition(dataPackHandle, 32);
		WritePackCell(dataPackHandle, -1);
		
		if(owner != spider && owner != 0)
			SetEntPropEnt(spider, Prop_Data, "m_hOwnerEntity", 0);
	}
	
	GetEntPropVector(box, Prop_Send, "m_vecOrigin", spiderPosition);
	closestEntityTeam = spiderTeam;
	
	/////////////////////////////////////////////////////////
	//move the trace beam up away from any possible debris //
	//not neccessary from the spider itself                //
	//this allows more successive hits                     //
	/////////////////////////////////////////////////////////
	traceRaySpiderPosition[0] = spiderPosition[0];
	traceRaySpiderPosition[1] = spiderPosition[1];
	traceRaySpiderPosition[2] = spiderPosition[2] + 25.0;
	
	///////////////////////////////////////////////////
	//Find the closest entities by:                  //
	//  1.) Objects                                  //
	//  2.) Players                                  //
	// This is done by calling seperate modules that //
	// handle this per object type                   //
	//                                               //
	// Results are returned as:                      //
	//   results[0] = closestObject                  //
	//   results[1] = closestDistance                //
	//   results[2] = closestObjectTeam              //
	//                                               //
	// Then they are fltered to find the closest     //
	// entity based on the Spider's AI hierarchy     //
	///////////////////////////////////////////////////
	
	findClosestObject(spider, box, spiderPosition, traceRaySpiderPosition, spiderTeam, rangeTolerance, dataPackHandle);
	findClosestPlayer(spider, box, spiderPosition, traceRaySpiderPosition, spiderTeam, rangeTolerance, dataPackHandle, spiderOwner);
	
	filterClosestResults(dataPackHandle);
	
	////////////////////////
	//Load the results    //
	////////////////////////
	SetPackPosition(dataPackHandle, 104);
	whoIsCloser = ReadPackCell(dataPackHandle);
	
	//an object is closer
	if(whoIsCloser == 1)
	{
		SetPackPosition(dataPackHandle, 56);
		closestEntity = ReadPackCell(dataPackHandle);
		closestEntityTeam = ReadPackCell(dataPackHandle);
		closestDistance = float(ReadPackCell(dataPackHandle));
	}
	
	//a player is closer
	if(whoIsCloser == 2)
	{
		SetPackPosition(dataPackHandle, 80);
		closestEntity = ReadPackCell(dataPackHandle);
		closestEntityTeam = ReadPackCell(dataPackHandle);
		closestDistance = float(ReadPackCell(dataPackHandle));
		
		//save the ClosestEntity
		SetPackPosition(dataPackHandle, 136);
		WritePackCell(dataPackHandle, closestEntity);
	}
	
	processOtherSounds(spider, spiderTeam, closestEntity, closestDistance, closestEntityTeam);
	botherEngineer(closestEntity, spider, spiderTeam, box, closestDistance);
	yellForHelp(spider);
	///////////////////////////////
	//Determine Spider movement	 //
	///////////////////////////////
	
	//are flames needed?
	if(flameEntity > 0)
		validateFlames(spider, closestDistance, flameEntity, dataPackHandle);
	
	new Float:lastKnownPos[3];
	//save location enemy was last seen
	if(closestEntity != -1)
	{
		GetEntPropVector(closestEntity, Prop_Data, "m_vecOrigin", lastKnownPos);
		
		SetPackPosition(dataPackHandle, 144);
		WritePackFloat(dataPackHandle, lastKnownPos[0]);
		WritePackFloat(dataPackHandle, lastKnownPos[1]);
		WritePackFloat(dataPackHandle, lastKnownPos[2]);
		
		//add 60s to Spider's life 
		if(whoIsCloser == 2)
		{
			SetPackPosition(dataPackHandle, 168);
			WritePackCell(dataPackHandle, GetTime() + 60);
		}
	}
	
	if(closestEntity == -1 || closestDistance < 80.0 && closestEntityTeam == spiderTeam)
	{
		SetPackPosition(dataPackHandle, 168);
		new timeToKill = ReadPackCell(dataPackHandle);
		if(timeToKill < GetTime() && timeToKill != 0)
		{
			killEntityIn(box, 0.1);
			//PrintToChatAll("Killing Spider through absense | %i | CurTime:%i", timeToKill, GetTime());
		}
		
		//determine spider interactions with objects
		if(closestEntity != -1)
			findSpiderTouch(spider, closestEntity);
		
		//flames not needed anymore
		if(flameEntity != -1)
		{
			StopSound(spider, SNDCHAN_AUTO, SOUND_FlameLoop);
			killEntityIn(flameEntity, 0.1);
			SetPackPosition(dataPackHandle, 112);
			WritePackCell(dataPackHandle, -1);
		}
		
		new bool:stopMovement = true;
		
		//move to the last location than an enemy was seen
		if(closestEntity == -1)
		{
			SetPackPosition(dataPackHandle, 144);
			lastKnownPos[0] = ReadPackFloat(dataPackHandle);
			lastKnownPos[1] = ReadPackFloat(dataPackHandle);
			lastKnownPos[2] = ReadPackFloat(dataPackHandle);
			
			//PrintToChatAll("%f , %f, %f", lastKnownPos[0], lastKnownPos[1], lastKnownPos[2]);
			
			closestDistance = GetVectorDistance(lastKnownPos,spiderPosition);
			if(lastKnownPos[0] != -1.0 && lastKnownPos[1] != -1.0 && lastKnownPos[2] != -1.0)
			{
				//move towards point
				//PrintToChatAll("moving towards point! %i", GetTime());
				moveSpider_ToPoint(spider, box, spiderTeam, spiderPosition, closestDistance, dataPackHandle);
				stopMovement = false;
				
				//spider reached waypoint
				if(closestDistance < 60.0)
				{
					stopMovement = true;
					SetPackPosition(dataPackHandle, 144);
					WritePackFloat(dataPackHandle, -1.0);
					WritePackFloat(dataPackHandle, -1.0);
					WritePackFloat(dataPackHandle, -1.0);
				}
				
			}
		}
		
		//The spider was running before now let's just wait
		if(GetEntProp(spider, Prop_Data, "m_nSequence") != 0 && stopMovement)
		{
			StopSound(spider, SNDCHAN_AUTO, SOUND_SpiderTurn);
			
			SetVariantString("idle");
			AcceptEntityInput(spider, "SetAnimation", -1, -1, 0); 
		}
		
	}else{
		//move towards entity
		moveSpider(spider, box, spiderTeam, spiderPosition, closestEntity, closestEntityTeam, closestDistance, flameEntity, dataPackHandle);
	}
	
	//LogToFile(logPath,"SpiderThink_Timer -- Leaving");
	return Plugin_Continue;
}

public bool:TraceFilter(ent, contentMask)
{
	return (ent == g_FilteredEntity) ? false : true;
}

public bool:TraceFilterAll(caller, contentsMask, any:entity)
{
	new String:modelname[128];
	GetEntPropString(caller, Prop_Data, "m_ModelName", modelname, 128);
	
	new String:checkclass[64];
	GetEdictClassname(caller,checkclass,sizeof(checkclass));
	
	return !(StrEqual(checkclass, "player", false) || StrEqual(checkclass, "func_respawnroomvisualizer", false) ||(caller==entity) || StrEqual(modelname, MODEL_SPIDER) || StrEqual(modelname, MODEL_SPIDERBOX));
}

stock Float:AngleBetweenVectors(const Float:a[3], const Float:b[3]) {
    return ArcCosine(GetVectorDotProduct(a, b) / (GetVectorLength(a) * GetVectorLength(b)));
} 

public SortDistanceAscend(x[], y[], array[][], Handle:data)
{
    if (Float:x[1] < Float:y[1])
        return -1;
	else if (Float:x[1] > Float:y[1])
		return 1;
    return 0;
}

	
public bool:TraceFilterSpider(caller, contentsMask, any:entity)
{
	new String:modelname[128];
	GetEntPropString(caller, Prop_Data, "m_ModelName", modelname, 128);
	
	new String:checkclass[64];
	GetEdictClassname(caller,checkclass,sizeof(checkclass));
	
	return !(StrEqual(checkclass, "player", false) || StrEqual(checkclass, "func_respawnroomvisualizer", false) ||(caller==entity));
}

stock botherEngineer(client, spider, spiderTeam, box, Float:distance)
{
	if(client < 0 || client > 32)
		return;
	
	if(!IsClientInGame(client))
		return;
	
	if(!IsPlayerAlive(client))
		return;
	
	//LogToFile(logPath,"botherEngineer -- Entering");
	new pitch = 160;
	
	new currIndex = GetEntProp(spider, Prop_Data, "m_nModelIndex");
	for (new i = 0; i <= 10; i++)
	{
		if (currIndex == zombieModelIndex[i])
			pitch = 60;
	}
	
	if(spiderTeam == GetClientTeam(client))
	{
		if( TF2_GetPlayerClass(client) == TFClass_Engineer)
		{	
			//hassle engineer
			new spiderSounds = GetEntProp(spider, Prop_Data, "m_PerformanceMode");
			if(distance < 400.0  && spiderSounds == 1)
			{
				new rndNum = GetRandomInt(0,4);
					
				if(rndNum == 1)
					EmitSoundToAll(SOUND_SPIDERNEEDDISPENSER,spider,_,_,_,_,pitch);
				
				if(rndNum == 2)
					EmitSoundToAll(SOUND_SPIDERNEEDTELE,spider,_,_,_,_,pitch);
				
				if(rndNum == 3)
					EmitSoundToAll(SOUND_SPIDERNEEDSENTRY,spider,_,_,_,_,pitch);
				
				SetEntProp(spider, Prop_Data, "m_PerformanceMode", 0);
				CreateTimer(6.0, SphereSoundRdy, spider);
			}
		}
	}
	
	//LogToFile(logPath,"botherEngineer -- Leaving");
}

stock yellForHelp(spider)
{
	//LogToFile(logPath,"yellForHelp -- Entering");
	new pitch = 160;
	
	new currIndex = GetEntProp(spider, Prop_Data, "m_nModelIndex");
	for (new i = 0; i <= 10; i++)
	{
		if (currIndex == zombieModelIndex[i])
			pitch = 60;
	}
	
	new currentHealth = GetEntProp(spider, Prop_Data, "m_iHealth");
	new Float: healthPercent = float(currentHealth)/GetEntProp(spider, Prop_Data, "m_iMaxHealth");
	
	if(healthPercent < 1.0)
	{
		healthPercent *= 30.0;
		
		if(healthPercent < 6.0)
			healthPercent = 8.0;
		
		new botherLevel = RoundFloat(healthPercent);
		
		new spiderSounds = GetEntProp(spider, Prop_Data, "m_PerformanceMode");
		if( spiderSounds == 1)
		{
			new rndNum = GetRandomInt(0,botherLevel);
			new sndChange = -1;
			
			if(rndNum == 1)
			{
				EmitSoundToAll(SOUND_SPIDERHELPME01,spider,_,_,_,_,pitch);
				sndChange = 1;
			}
			
			if(rndNum == 2)
			{
				EmitSoundToAll(SOUND_SPIDERHELPME02,spider,_,_,_,_,pitch);
				sndChange = 1;
			}
			
			if(rndNum == 3)
			{
				EmitSoundToAll(SOUND_SPIDERHELPME03,spider,_,_,_,_,pitch);
				sndChange = 1;
			}
			
			if(rndNum == 4)
			{
				EmitSoundToAll(SOUND_SPIDERHELPME04,spider,_,_,_,_,pitch);
				sndChange = 1;
			}
			
			if(rndNum == 5)
			{
				EmitSoundToAll(SOUND_SPIDERTIRED,spider,_,_,_,_,pitch);
				sndChange = 1;
			}
			
			if(sndChange == 1)
			{
				SetEntProp(spider, Prop_Data, "m_PerformanceMode", 0);
				CreateTimer(4.0, SphereSoundRdy, spider);
			}
		}
	}
}

stock processOtherSounds(spider, spiderTeam, closestEntity, Float:closestDistance, closestEntityTeam)
{
	new spiderSounds = GetEntProp(spider, Prop_Data, "m_PerformanceMode");
	
	if( spiderSounds == 1 && closestEntity != -1)
	{
		new TFClassType:entityClass;
		
		if(closestEntity <= MaxClients && closestEntity > 0 )
			entityClass = TF2_GetPlayerClass(closestEntity);
		
		new pitch = 160;
	
		new currIndex = GetEntProp(spider, Prop_Data, "m_nModelIndex");
		for (new i = 0; i <= 10; i++)
		{
			if (currIndex == zombieModelIndex[i])
				pitch = 60;
		}
		
		//notify others about an enemy spy
		if(entityClass == TFClass_Spy && spiderTeam != closestEntityTeam && spiderSounds == 1)
		{
			new disguiseClass  = GetEntData(closestEntity, m_nDisguiseClass);
			
			//PrintToChatAll("Disguise Class: %i",disguiseClass);
			new rndNum = GetRandomInt(1,3);
				
			if(rndNum == 1)
			{
				//scout
				if(disguiseClass == 1)
					EmitSoundToAll(SOUND_SPIDERCLOAKEDSPY01,spider,_,_,_,_,pitch);
				
				//soldier
				if(disguiseClass == 3)
					EmitSoundToAll(SOUND_SPIDERCLOAKEDSPY02,spider,_,_,_,_,pitch);
				
				//heavy
				if(disguiseClass == 6)
					EmitSoundToAll(SOUND_SPIDERCLOAKEDSPY03,spider,_,_,_,_,pitch);
				
				//pyro
				if(disguiseClass == 7)
					EmitSoundToAll(SOUND_SPIDERCLOAKEDSPY04,spider,_,_,_,_,pitch);
				
				//demo
				if(disguiseClass == 4)
					EmitSoundToAll(SOUND_SPIDERCLOAKEDSPY05,spider,_,_,_,_,pitch);
				
				//spy
				if(disguiseClass == 8)
					EmitSoundToAll(SOUND_SPIDERCLOAKEDSPY06,spider,_,_,_,_,pitch);
				
				//medic
				if(disguiseClass == 5)
					EmitSoundToAll(SOUND_SPIDERCLOAKEDSPY07,spider,_,_,_,_,pitch);
				
				//engineer
				if(disguiseClass == 9)
					EmitSoundToAll(SOUND_SPIDERCLOAKEDSPY08,spider,_,_,_,_,pitch);
				
				//sniper
				if(disguiseClass == 2)
					EmitSoundToAll(SOUND_SPIDERCLOAKEDSPY09,spider,_,_,_,_,pitch);
				
			}
			
			if(rndNum == 2)
			{
				new rndNum2 = GetRandomInt(0,3);
				
				if(rndNum2 == 0)
					EmitSoundToAll(SOUND_SPIDERSPY01,spider,_,_,_,_,pitch);
				
				if(rndNum2 == 1)
					EmitSoundToAll(SOUND_SPIDERSPY02,spider,_,_,_,_,pitch);
				
				if(rndNum2 == 2)
					EmitSoundToAll(SOUND_SPIDERSPY03,spider,_,_,_,_,pitch);
				
				if(rndNum2 == 3)
					EmitSoundToAll(SOUND_SPIDERSPY04,spider,_,_,_,_,pitch);
			}
			
			SetEntProp(spider, Prop_Data, "m_PerformanceMode", 0);
			CreateTimer(4.0, SphereSoundRdy, spider);
			spiderSounds = 0;
		}
		
		//an enemy is within range, lets insult him and such
		if( closestDistance < 200.0 && closestEntity <= MaxClients && closestEntity > 0 && spiderSounds == 1 && spiderTeam != closestEntityTeam)
		{
			new rndNum = GetRandomInt(0,20);
				
			if(rndNum == 1)
				EmitSoundToAll(SOUND_SPIDERMELEEDARE01,spider,_,_,_,_,pitch);
			
			if(rndNum == 2)
				EmitSoundToAll(SOUND_SPIDERMELEEDARE02,spider,_,_,_,_,pitch);
			
			if(rndNum == 3)
				EmitSoundToAll(SOUND_SPIDERMELEEDARE03,spider,_,_,_,_,pitch);
			
			if(rndNum == 4)
				EmitSoundToAll(SOUND_SPIDERMELEEDARE04,spider,_,_,_,_,pitch);
			
			if(rndNum == 5)
				EmitSoundToAll(SOUND_SPIDERMELEEDARE05,spider,_,_,_,_,pitch);
			
			if(rndNum == 6)
				EmitSoundToAll(SOUND_SPIDERMELEEDARE06,spider,_,_,_,_,pitch);
			
			
			if(rndNum >= 1 && rndNum <= 6)
			{
				SetEntProp(spider, Prop_Data, "m_PerformanceMode", 0);
				CreateTimer(2.0, SphereSoundRdy, spider);
				spiderSounds = 0;
			}
			
			
		}
		
		//tell the medic to follow him
		if( closestDistance < 200.0 && closestEntity <= MaxClients && closestEntity > 0 && spiderSounds == 1 && spiderTeam == closestEntityTeam)
		{
			if(TF2_GetPlayerClass(closestEntity)==TFClass_Medic)
			{
				new rndNum = GetRandomInt(45,60);
				if(rndNum == 51)
					EmitSoundToAll(SOUND_SPIDERMEDICFOLLOW01,spider,_,_,_,_,pitch);
				
				if(rndNum == 52)
					EmitSoundToAll(SOUND_SPIDERMEDICFOLLOW02,spider,_,_,_,_,pitch);
				
				if(rndNum == 53)
					EmitSoundToAll(SOUND_SPIDERMEDICFOLLOW03,spider,_,_,_,_,pitch);
				
				if(rndNum == 54)
					EmitSoundToAll(SOUND_SPIDERMEDICFOLLOW04,spider,_,_,_,_,pitch);
				
				if(rndNum >= 51 && rndNum <= 54)
				{
					SetEntProp(spider, Prop_Data, "m_PerformanceMode", 0);
					CreateTimer(2.0, SphereSoundRdy, spider);
					spiderSounds = 0;
				}
			}
		}
		
		//Yell moveup if the closestEntity is a player
		if( closestDistance < 200.0 && closestEntity <= MaxClients && closestEntity > 0 && spiderSounds == 1 && spiderTeam == closestEntityTeam)
		{
			new rndNum = GetRandomInt(0,40);
				
			if(rndNum == 1)
				EmitSoundToAll(SOUND_SPIDERMOVEUP01,spider,_,_,_,_,pitch);
			
			if(rndNum == 2)
				EmitSoundToAll(SOUND_SPIDERMOVEUP02,spider,_,_,_,_,pitch);
			
			if(rndNum == 3)
				EmitSoundToAll(SOUND_SPIDERMOVEUP03,spider,_,_,_,_,pitch);
			
			if(rndNum == 4)
				EmitSoundToAll(SOUND_SPIDERMOVEUP04,spider,_,_,_,_,pitch);
			
			if(rndNum == 5)
				EmitSoundToAll(SOUND_SPIDERMOVEUP05,spider,_,_,_,_,pitch);
			
			if(rndNum == 6)
				EmitSoundToAll(SOUND_SPIDERMOVEUP06,spider,_,_,_,_,pitch);
			
			if(rndNum == 7)
				EmitSoundToAll(SOUND_SPIDERMOVEUP07,spider,_,_,_,_,pitch);
			
			SetEntProp(spider, Prop_Data, "m_PerformanceMode", 0);
			CreateTimer(2.0, SphereSoundRdy, spider);
			spiderSounds = 0;
		}
		
	}
}

public findClosestObject(spider, box, Float:spiderPosition[3], Float:traceRaySpiderPosition[3],spiderTeam, Float:rangeTolerance, Handle:dataPackHandle)
{
	///////////////////////////////////////
	//    Find The Closest Object        //
	//                                   //
	//returns = building entity          //
	//returns = along with the distance  //
	//returns = and what team it was on  //
	///////////////////////////////////////
	new String:objectName[50];
	
	new foundObjectEnt = -1;
	new Float:foundObjectPos[3];
	new Float:traceEndPos[3];
	new Float:objectDistances[201][2];
	
	new Float:distance;
	new foundObjects;
	new closestObject = -1;
	new Float:closestDistance;
	new closestObjectTeam;
	new bool:processObject = true;
	new String:modelname[128];
	new Float:foundRange;
	
	new spiderHealth = GetEntProp(spider, Prop_Data, "m_iHealth");
	new spiderMaxHealth = GetEntProp(spider, Prop_Data, "m_iMaxHealth");
	
	for (new step = 1; step <= 11; step++)
	{
		foundObjects = 0;
		
		//target spiders
		if(step == 1)
			objectName = "prop_dynamic";
		
		//target lockers
		if(step == 2)
			objectName = "prop_dynamic";
		
		//target zombies
		if(step == 3)
			objectName = "prop_dynamic";
		
		//target rollermines
		if(step == 4)
			objectName = "prop_sphere";
		
		if(step == 5)
			objectName = "item_healthkit_small";
		
		if(step == 6)
			objectName = "item_healthkit_medium";
		
		if(step == 7)
			objectName = "item_healthkit_full";
			
		if(step == 8)
			objectName = "obj_sentrygun";
		
		if(step == 9)
			objectName = "obj_dispenser";
		
		if(step == 10)
			objectName = "obj_teleporter";
		
		if(step == 11)
			objectName = "team_control_point";
		
		
		if(closestObject == -1)
		{
			while ((foundObjectEnt = FindEntityByClassname(foundObjectEnt, objectName)) != -1) 
			{	
				
				processObject = true;
				
				//we need to verify the model
				GetEntPropString(foundObjectEnt, Prop_Data, "m_ModelName", modelname, 128);
				
				//Find spiders
				if(step == 1)
				{
					if (StrEqual(modelname, MODEL_SPIDER) && foundObjectEnt != spider)
					{
						//look for the parent entity
						new foundParentEnt = GetEntPropEnt(foundObjectEnt, Prop_Data, "m_pParent");
						
						//Entity has no parent. Its origin position are those of the real world
						if(foundParentEnt == -1)
							foundParentEnt = foundObjectEnt;
						
						GetEntPropVector(foundParentEnt, Prop_Send, "m_vecOrigin", foundObjectPos);
						
						objectDistances[foundObjects][0] = float(foundObjectEnt);
						distance = GetVectorDistance(spiderPosition,foundObjectPos);
					}else{
						processObject = false;
					}
				}
				
				//Find lockers
				if(step == 2)
				{
					if (StrEqual(modelname, MODEL_LOCKER))
					{
						//look for the parent entity
						//new foundParentEnt = GetEntPropEnt(foundObjectEnt, Prop_Data, "m_pParent");
						
						//Entity has no parent. Its origin position are those of the real world
						//if(foundParentEnt == -1)
						//	foundParentEnt = foundObjectEnt;
						
						GetEntPropVector(foundObjectEnt, Prop_Send, "m_vecOrigin", foundObjectPos);
						
						objectDistances[foundObjects][0] = float(foundObjectEnt);
						distance = GetVectorDistance(spiderPosition,foundObjectPos);
						
					}else{
						processObject = false;
					}
				}
				
				//Find zombies
				if(step == 3)
				{
					if ((StrEqual(modelname, MODEL_ZOMBIE_CLASSIC) || StrEqual(modelname, MODEL_ZOMBIE_02) || StrEqual(modelname, MODEL_ZOMBIE_03)) 
						&& foundObjectEnt != spider)
					{
						//look for the parent entity
						new foundParentEnt = GetEntPropEnt(foundObjectEnt, Prop_Data, "m_pParent");
						
						//Entity has no parent. Its origin position are those of the real world
						if(foundParentEnt == -1)
							foundParentEnt = foundObjectEnt;
						
						GetEntPropVector(foundParentEnt, Prop_Send, "m_vecOrigin", foundObjectPos);
						
						objectDistances[foundObjects][0] = float(foundParentEnt);
						distance = GetVectorDistance(spiderPosition,foundObjectPos);
					}else{
						processObject = false;
					}
				}
				
				//Find rollermines
				if(step == 4)
				{
					processObject = false;
				}
				
				if(step > 4)
				{
					//no model verification needed
					objectDistances[foundObjects][0] = float(foundObjectEnt);
					GetEntPropVector(foundObjectEnt, Prop_Send, "m_vecOrigin", foundObjectPos);
					distance = GetVectorDistance(spiderPosition,foundObjectPos);
					
					//spider is full of health so let's ignore health kits
					if(foundObjectEnt != -1 && (StrContains(objectName, "item_healthkit",false) >= 0)  && spiderHealth >= spiderMaxHealth)
						processObject = false;
					
					//the healthkit is disabled so we can't focus on it
					if(foundObjectEnt != -1 && (StrContains(objectName, "item_healthkit",false) >= 0)  && GetEntProp(foundObjectEnt, Prop_Data, "m_bDisabled") == 1)
						processObject = false;
					
				}
				
				
				if(processObject)
				{
					foundObjectPos[2] += 40.0;
					objectDistances[foundObjects][1] = 1001.0;
					
					//Is the other building even close enough to be bothered with?
					if(distance < 1000.0)
					{
						//begin our trace from our main spider to the found buildable
						new Handle:Trace = TR_TraceRayFilterEx(traceRaySpiderPosition, foundObjectPos, MASK_SOLID, RayType_EndPoint, TraceFilterAll, spider);
						TR_GetEndPosition(traceEndPos, Trace);
						CloseHandle(Trace);
						
						foundRange = GetVectorDistance(foundObjectPos,traceEndPos);
						
						//Was the trace close to a buildable? If not the let's shoot from this buildable
						//back to our main spider. This makes sure that none of the entites saw each other
						if(foundRange > rangeTolerance)
						{
							Trace = TR_TraceRayFilterEx(foundObjectPos, spiderPosition, MASK_SOLID, RayType_EndPoint, TraceFilterAll, foundObjectEnt);
							TR_GetEndPosition(traceEndPos, Trace);
							CloseHandle(Trace);
							
							//did the player see a building?
							foundRange = GetVectorDistance(spiderPosition, traceEndPos);
						}
							
						if (foundRange <= rangeTolerance)
							objectDistances[foundObjects][1] = distance;
					}
					
					foundObjects ++;
				}
			}
			
			//we found all our objects for this thread now sort them
			if(foundObjects > 0)
			{
				SortCustom2D(_:objectDistances, foundObjects, SortDistanceAscend);
				closestObject = RoundFloat(objectDistances[0][0]);
				closestDistance = objectDistances[0][1];
				closestObjectTeam = spiderTeam;
				
				if(closestDistance > 1000.0)
					closestObject = -1;
				
				if(closestObject > 0)
				{
					GetEntPropString(closestObject, Prop_Data, "m_ModelName", modelname, 128);
					//PrintToChatAll("modelname: %s",modelname);
					
					//buildables that are team independent, might be enemies
					if(StrEqual(objectName, "obj_sentrygun") || StrEqual(objectName, "obj_dispenser") || StrEqual(objectName,"obj_teleporter") ||
						StrEqual(objectName, MODEL_SPIDER) || StrEqual(objectName, MODEL_ZOMBIE_CLASSIC) ||
						StrEqual(objectName, MODEL_ZOMBIE_02) || StrEqual(objectName, MODEL_ZOMBIE_03))
					{
						new tempBuildableTeam;
						//focus on closest enemies first!
						for (new i = 1; i <= foundObjects; i++)
						{
							tempBuildableTeam = GetEntProp(RoundFloat(objectDistances[i-1][0]), Prop_Data, "m_iTeamNum");
							
							//PrintToChatAll("Spiderteam: %i , TempEnemyTeam: %i", spiderTeam,tempBuildableTeam);
							
							if( tempBuildableTeam != spiderTeam && objectDistances[i-1][1] < 1000.0 )
							{
								closestObject = RoundFloat(objectDistances[i-1][0]);
								closestDistance = objectDistances[i-1][1];
								closestObjectTeam = GetEntProp(closestObject, Prop_Data, "m_iTeamNum");
								
								//PrintToChatAll("Spiderteam: %i , EnemyTeam: % , TempEnemyTeam: %i", spiderTeam,closestObjectTeam,tempBuildableTeam);
								break;
							}
						}
					}
				}
				
				//spider is full of health so let's ignore lockers
				if(closestObject > 0 && step == 2 && spiderHealth >= spiderMaxHealth)
					closestObject = -1;
			}
		}
		
		if(closestObject != -1)
		{
			//PrintToChatAll("Found Something in step: %i with the name of %s",step,objectName);
			break;
		}
		
		//reset variables for next lookup
		
		for (new ji = 0; ji <= 200; ji++)
		{
			objectDistances[ji][0] = -1.0;
			objectDistances[ji][1] = 1001.0;
		}
	}
	
	//PrintToChatAll("Close Obj: %i |Foun in Step: %s",closestObject, objectName);
	ResetPack(dataPackHandle);
	SetPackPosition(dataPackHandle, 56);
	WritePackCell(dataPackHandle,  closestObject);
	WritePackCell(dataPackHandle, closestObjectTeam);
	WritePackCell(dataPackHandle,  RoundFloat(closestDistance));
	
	//LogToFile(logPath,"findClosestObject -- Leaving");
}

public findClosestPlayer(spider, box, Float:spiderPosition[3], Float:traceRaySpiderPosition[3],spiderTeam, Float:rangeTolerance, Handle:dataPackHandle, spiderOwner)
{
	///////////////////////////////////////
	//    Find The Closest Player        //
	//                                   //
	//returns = player entity            //
	//returns = along with the distance  //
	//returns = and what team it was on  //
	///////////////////////////////////////
	new lastTarget = -1;
	
	if(GetEntProp(spider, Prop_Data, "m_nModelIndex") == spiderIndex)
	{
		SetPackPosition(dataPackHandle, 136);
		lastTarget = ReadPackCell(dataPackHandle);
	}else{
		SetPackPosition(dataPackHandle, 120);
		lastTarget = ReadPackCell(dataPackHandle);
	}
	
	new Float:playerDistances[MaxClients + 1][2];
	new Float:enemyPosition[3];
	new Float:endingRayPos[3];
	new Float:distance;
	new Float:foundRange;
	
	new closestPlayer = -1;
	new closestDistance;
	new closestPlayerTeam;
	
	new bool:isSpider = false;
	new bool:allowSounds = true;
	
	new String:modelname[128];
	GetEntPropString(spider, Prop_Data, "m_ModelName", modelname, 128);
	
	if (StrEqual(modelname, MODEL_SPIDER) )
		isSpider = true;
	
	
	///////////////////////////////////////////////////
	//medicPartner is the one player on the spider's //
	//team that receives the highest priority        //
	//This can be the spawner or the person that grabbed
	//its attention 1st
	///////////////////////////////////////////////////
	new medicPartner = -1;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		playerDistances[i-1][0] = float(i);
		playerDistances[i-1][1] = 1001.0;
		distance = 1001.0;
		
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if(GetClientTeam(i) == spiderTeam && AFKScore[i] > 8)
			continue;
		
		//spider can't see invis players
		if (GetEntData(i, m_clrRender + 3,1) < 100)
			continue;
		
		
		GetClientEyePosition(i, enemyPosition);
		
		new Handle:Trace = TR_TraceRayFilterEx(traceRaySpiderPosition, enemyPosition, MASK_SOLID, RayType_EndPoint, TraceFilterAll, spider);
		TR_GetEndPosition(endingRayPos, Trace);
		CloseHandle(Trace);
		
		foundRange = GetVectorDistance(enemyPosition,endingRayPos);
		
		//trace a ray from the player to the spider
		if(foundRange > rangeTolerance)
		{
			Trace = TR_TraceRayFilterEx(enemyPosition, spiderPosition, MASK_SOLID, RayType_EndPoint, TraceFilterAll, spider);
			TR_GetEndPosition(endingRayPos, Trace);
			CloseHandle(Trace);
			
			//did the player see a spider?
			foundRange = GetVectorDistance(spiderPosition, endingRayPos);
		}
		
		//do we see the enemy?
		if(foundRange <= rangeTolerance)
		{	
			distance = GetVectorDistance(traceRaySpiderPosition, enemyPosition);
			
			//Always try to focus on the person that spawned the NPC
			if(spiderOwner == i && GetClientTeam(i) == spiderTeam)
			{
				medicPartner = i;
				distance = 0.0;
			}
			
			//Always focus on the last player that we were focusing on
			if(lastTarget == i)
			{
				medicPartner = i;
				distance = 0.1;
			}
			
			//Heal the spider if client is a medic
			new maybeHealing = -1;
			
			if(isSpider)
				maybeHealing = healSpider(i, spider, spiderTeam, box, distance);
			
			if(maybeHealing != -1 && medicPartner == -1)
			{
				medicPartner = maybeHealing;
				distance = 1.0; 
			}
			
			if(allowSounds)
			{
				//botherEngineer(i, spider, spiderTeam, box, distance);
				//yellForHelp(spider);
			}
			
			//player is not cloaked | cloaked = 16
			if (distance < 1000.0 && !(GetEntProp(i, Prop_Send, "m_nPlayerCond")&16))
			{
				playerDistances[i-1][1] = distance;
			}
			
			if(isSpider)
			{
				//Burn the enemy if he is too close
				
				new DisguiseTeam;
				new TFClassType:class;
				DisguiseTeam = GetClientTeam(i);
				//////////////////////////////////////////////////////////
				// Do not auto burn cloaked spies who are very close    //
				//////////////////////////////////////////////////////////
				class = TF2_GetPlayerClass(i);
				
				if(class == TFClass_Spy)
				{
					DisguiseTeam  = GetEntData(i, m_nDisguiseTeam);
					
					if(DisguiseTeam == 0)
						DisguiseTeam = GetClientTeam(i);
				}
				
				//the player is too close to the spider and will be ignited regardless if flame particle is present
				if(distance < 35.0 &&  GetClientTeam(i) != spiderTeam && DisguiseTeam == spiderTeam && GetEntData(i, m_clrRender + 3,1) > 100 && class != TFClass_Spy)
				{
					if(!client_rolls[i][AWARD_G_GODMODE][0])
					{
						if(GetEntProp(i, Prop_Send, "m_nPlayerCond")&32)
						{
							//Dont hurt the friendly disguised spies
							//PrintToChatAll("bypassing!");
						}else{
							if(dmgDebug[i])
							{
								PrintToChat(i,"Dealing Damage to: %i | Distancet: %f", i, distance ); ///DEBUG remove before publishing
							}
							
							DealDamage(i, RoundFloat((300.0-closestDistance)/30.0), spider, 16779264, "spider");
							DealDamage(i,0,spider,2056,"tf_weapon_flamethrower");
						}
					}
				}
			}
		}
	}
	
	//Find the closest player
	//BUT if they are a friendly and an enemy is close by then lets
	//focus our attention to the enemy instead...no time for distractions  :D
	
	SortCustom2D(_:playerDistances, MaxClients, SortDistanceAscend);
	
	if(playerDistances[0][0] != -1 )
	{
		
		closestPlayer = RoundFloat(playerDistances[0][0]);
		closestDistance = RoundFloat(playerDistances[0][1]);
		
		if(closestDistance > 1000)
			closestPlayer = -1;
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if(RoundFloat(playerDistances[i-1][0]) < 1)
				continue;
			
			if (!IsClientInGame(RoundFloat(playerDistances[i-1][0])) || !IsPlayerAlive(RoundFloat(playerDistances[i-1][0])))
				continue;
			
			if(GetClientTeam(RoundFloat(playerDistances[i-1][0])) != spiderTeam && playerDistances[i-1][1] < 1000.0)
			{
				closestPlayer = RoundFloat(playerDistances[i-1][0]);
				closestDistance = RoundFloat(playerDistances[i-1][1]);
				
				
				break;
			}
		}
		
		if(closestPlayer != -1)
			closestPlayerTeam = GetClientTeam(closestPlayer);
		
		if(closestDistance > 1000.0)
			closestPlayer = -1;
	}
	
	//reevaluate closestDistance because medicPartner sets it to 0 for high priority
	if(medicPartner != -1 && closestPlayer == medicPartner)
	{
		GetClientEyePosition(medicPartner, enemyPosition);
		closestDistance = RoundFloat(GetVectorDistance(spiderPosition, enemyPosition));
	}
	
	//PrintToChatAll("cls ply: %i",closestPlayer);
	
	SetPackPosition(dataPackHandle,80);
	WritePackCell(dataPackHandle, closestPlayer);
	WritePackCell(dataPackHandle, closestPlayerTeam);
	WritePackCell(dataPackHandle, closestDistance);
	
	//LogToFile(logPath,"findClosestPlayer -- Leaving");
}
	
public stopSpiderThinkTimer(Handle:dataPackHandle)
{
	//LogToFile(logPath,"stopSpiderThinkTimer -- Entering");
	
	ResetPack(dataPackHandle);
	new spider = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new box = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	SetPackPosition(dataPackHandle, 112);
	new flameEntity = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	if(!GetConVarInt(c_Enabled))
		return true;
	
	if(spider <= 0 || box <= 0)
	{
		if(flameEntity > 0)
		{
			StopSound(spider, SNDCHAN_AUTO, SOUND_FlameLoop);
			killEntityIn(flameEntity, 0.1);
		}
		
		return true;
	}
	
	if(GetEntProp(spider, Prop_Data, "m_iHealth") <= 0)
	{
		if(flameEntity > 0)
			killEntityIn(flameEntity, 0.1);
			
		StopSound(spider, SNDCHAN_AUTO, SOUND_FlameLoop);
		StopSound(spider, SNDCHAN_AUTO, SOUND_SpiderTurn);
		return true;
	}
	
	return false;
}

public validateFlames(spider, Float:closestDistance, flameEntity, Handle:dataPackHandle)
{
	//LogToFile(logPath,"validateFlames -- Entering");
	////////////////////////////////////////////
	//Removes flames when enemies are too far //
	////////////////////////////////////////////
	
	//Check to see if the flame particle entity is valid
	if(closestDistance > 300.0 )
	{
		//PrintToChatAll("Removing: Enemies too far!");
		StopSound(spider, SNDCHAN_AUTO, SOUND_FlameLoop);
		//AcceptEntityInput(flameEntity,"kill");
		killEntityIn(flameEntity, 0.1);
		SetPackPosition(dataPackHandle, 112);
		WritePackCell(dataPackHandle, -1);
	}
	
	//LogToFile(logPath,"validateFlames -- Leaving");
}

public findSpiderTouch(spider, closestEntity)
{
	//LogToFile(logPath,"findSpiderTouch -- Entering");
	//////////////////////////////////////////////////
	//Determine if the closest object requires      //
	//special actions to be performed when touched  //
	//by the spider                                 //
	//////////////////////////////////////////////////
	new pitch = 160;
	
	new currIndex = GetEntProp(spider, Prop_Data, "m_nModelIndex");
	for (new i = 0; i <= 10; i++)
	{
		if (currIndex == zombieModelIndex[i])
			pitch = 60;
	}
	
	new String:closestClassName[256];
	new currentHealth = GetEntProp(spider, Prop_Data, "m_iHealth");
	new spiderMaxHealth = GetEntProp(spider, Prop_Data, "m_iMaxHealth");
	new String:modelname[128];
	
	GetEdictClassname(closestEntity, closestClassName, sizeof(closestClassName));
	
	//spider touched a med pack
	if(StrContains(closestClassName, "item_healthkit",false) >= 0)
	{
		new giveHealth;
		
		if(StrEqual(closestClassName, "item_healthkit_small",false))
			giveHealth = 40;
			
		if(StrEqual(closestClassName, "item_healthkit_medium",false))
			giveHealth = 100;
			
		if(StrEqual(closestClassName, "item_healthkit_full",false))
			giveHealth = 200;
		
		if((currentHealth + giveHealth) >= spiderMaxHealth)
		{
			giveHealth = spiderMaxHealth;
		}else{
			giveHealth += currentHealth;
		}
		
		SetEntProp(spider, Prop_Data, "m_iHealth", giveHealth);
		
		//////////////////////////////////////////////
		//Toggle the healthkit so it turns off then //
		//send "toggle" event to the event queue    //
		//so it reappears in a few seconds          //
		//////////////////////////////////////////////
		AcceptEntityInput(closestEntity,"toggle");
		new String:addoutput[64];
		Format(addoutput, sizeof(addoutput), "OnUser1 !self:toggle::8.0:1");
		SetVariantString(addoutput);
		AcceptEntityInput(closestEntity, "AddOutput");
		AcceptEntityInput(closestEntity, "FireUser1");
		
		//emit Regenerate sound from health pack
		EmitSoundToAll(SOUND_REGENERATE,closestEntity);
		
		//say thanks
		new spiderSounds = GetEntProp(spider, Prop_Data, "m_PerformanceMode");
		if(spiderSounds == 1)
		{
			new rndNum = GetRandomInt(0,4);
			
			if(rndNum > 2)
			{
				EmitSoundToAll(SOUND_SPIDERTHANKS1,spider,_,_,_,_,pitch);
			}else{
				EmitSoundToAll(SOUND_SPIDERTHANKS2,spider,_,_,_,_,pitch);
			}
				
			SetEntProp(spider, Prop_Data, "m_PerformanceMode", 0);
			CreateTimer(3.0, SphereSoundRdy, spider);
			
		}
	}	
	
	//spider touched a locker
	if(StrContains(closestClassName, "prop_dynamic",false) >= 0)
	{
		GetEntPropString(closestEntity, Prop_Data, "m_ModelName", modelname, 128);
		if (StrEqual(modelname, MODEL_LOCKER))
		{	
			SetEntProp(spider, Prop_Data, "m_iHealth", spiderMaxHealth);
			
			//say thanks to the locker
			new spiderSounds = GetEntProp(spider, Prop_Data, "m_PerformanceMode");
			if(spiderSounds == 1)
			{
				new rndNum = GetRandomInt(0,3);
				new bool:sndChange = false;
				
				if(rndNum == 1 || rndNum == 2)
					sndChange = true;
				
				if(sndChange)
				{
					if(rndNum == 1)
						EmitSoundToAll(SOUND_SPIDERTHANKS1,spider,_,_,_,_,pitch);
					
					if(rndNum == 2)
						EmitSoundToAll(SOUND_SPIDERTHANKS2,spider,_,_,_,_,pitch);
					
					SetEntProp(spider, Prop_Data, "m_PerformanceMode", 0);
					CreateTimer(3.0, SphereSoundRdy, spider);
				}
			}
		}
	}
	
	//LogToFile(logPath,"findSpiderTouch -- Leaving");
}

public moveSpider_ToPoint(spider, box, spiderTeam, Float:spiderPosition[3], Float:closestDistance, Handle:dataPackHandle)
{
	SetPackPosition(dataPackHandle, 144);
	new Float:enemyPosition[3];
	enemyPosition[0] = ReadPackFloat(dataPackHandle);
	enemyPosition[1] = ReadPackFloat(dataPackHandle);
	enemyPosition[2] = ReadPackFloat(dataPackHandle);
	
	//////////////////////////
	//Setup local variables //
	// Quite a few of them  //
	//////////////////////////
	
	new Float:spiderAngle[3];
	new Float: facingAngle; //this is the angle from the spider to the player on the x-y plane
	
	new Float:diffAng;
	new rotation;
	
	new Float:baseSpeed = 145.0; // Spider's base speed
	new Float:runSpeed  = 170.0; // Spider's running speed
	
	GetEntPropVector(box, Prop_Data, "m_vecOrigin", spiderPosition);
	
	
	GetEntPropVector(box, Prop_Data, "m_angRotation", spiderAngle);
	
	facingAngle = RadToDeg(ArcTangent2(spiderPosition[0] - enemyPosition[0],spiderPosition[1] - enemyPosition[1])) + 90;
	
	//make the spider face the player
	facingAngle *= -1;
	
	//normalizes it to 0 -> 360 degrees
	//instead of -270 -> 90 degrees
	if(facingAngle < 0.0)
		facingAngle += 360.0;
	
	if(spiderAngle[1] >= 360.0)
		spiderAngle[1] -= 360.0;
	
	if(spiderAngle[1] < 0.0)
		spiderAngle[1] += 360.0;
	
	//Get the difference of the angles
	if(facingAngle > spiderAngle[1])
	{	
		//The enemy is to the spider's LEFT
		diffAng = facingAngle - spiderAngle[1];
		rotation = 1;
	}else{
		//The enemy is to the spider's RIGHT
		diffAng = spiderAngle[1] - facingAngle;
		rotation = -1;
	}
	
	if(diffAng > 180.0)
	{
		//Rotate turning direction so we rotate the shortest distance!
		rotation *= -1;
	}
	
	//Spider still hasn't directly faced enemy
	if(diffAng >= 10.0)
		spiderAngle[1] += (17.0 * rotation);
	
	//Spider is pretty close to facing the enemy
	if(diffAng > 5.0 && diffAng < 10.0)
		spiderAngle[1] += (3.0 * rotation);
	
	//run a bit faster cause player is far
	if(closestDistance > 350.0)
		baseSpeed = runSpeed;
		
	new Float:speed[3];
	GetAngleVectors(spiderAngle, speed, NULL_VECTOR, NULL_VECTOR);
	
	/////////////////////////////////////////////////////////////
	//Determine how far from the ground the spider is and apply//
	//down forces if he's far from the ground                  //
	/////////////////////////////////////////////////////////////
	
	//-----Draw a trace from the box to the floor
	g_FilteredEntity = box;
	
	new Float:boxToFloor[3];
	new Float:Direction[3];
	new Float:hullBoxMin[3];
	new Float:hullBoxMax[3];
	
	hullBoxMax[0] = 10.0;
	hullBoxMax[1] = 10.0;
	hullBoxMax[2] = 0.5;
	
	spiderPosition[2] += 10;
	Direction[0] = spiderPosition[0];
	Direction[1] = spiderPosition[1];
	Direction[2] = spiderPosition[2]-1024;
	
	new Handle:Trace = TR_TraceHullFilterEx(spiderPosition, Direction,hullBoxMin,hullBoxMax, MASK_NPCWORLDSTATIC	, TraceFilterAll,box);
	TR_GetEndPosition(boxToFloor, Trace);
	CloseHandle(Trace);
	
	spiderPosition[2] -= 10;
	
	//move the spider up just a bit so he can go over obstacles
	new Float: floorDistance = GetVectorDistance(boxToFloor,spiderPosition);
	
	if((enemyPosition[2] - spiderPosition[2]) > 100.0)
	{
		speed[2] += 1.0;
	}else{
		if(floorDistance < 4.0)
		speed[2]+=0.5;
		
		if(floorDistance >= 4.0)
			speed[2]+=0.1;
		
		if(floorDistance >= 119.0)
			speed[2]-=0.8;	
	}
	//this is to correct the spiders orientation if he gets
	//tipped over or is upside down
	if(spiderAngle[0] > 60.0)
		spiderAngle[0] =- 5.0;
	
	if(spiderAngle[2] > 60.0)
		spiderAngle[2] =- 5.0;
	
	
	speed[0]*=baseSpeed; speed[1]*=baseSpeed; speed[2]*=baseSpeed;
	
	//move the spider
	//dont apply velocities to the rotation angle if its too large
	
	/////////////////////////////////////////////////////////////////
	//Before applying any velocities to the spider we want to make //
	//sure that its not going to fall and be left stranded         //
	/////////////////////////////////////////////////////////////////
	
	
	if(diffAng > 80.0 || closestDistance < 70.0)
	{
		TeleportEntity(box, NULL_VECTOR, spiderAngle, NULL_VECTOR);
	}else{
		TeleportEntity(box, NULL_VECTOR, spiderAngle, speed);
	}
		
}

public moveSpider(spider, box, spiderTeam, Float:spiderPosition[3], closestEntity, closestEntityTeam, Float:closestDistance, flameEntity, Handle:dataPackHandle)
{
	//LogToFile(logPath,"moveSpider -- Entering");
	///////////////////////////////////////////////////
	//            ABOUT SPIDER MOVEMENT               //
	//------------------------------------------------//
	// Here the spider moves towards the closest      //
	// entity. If the entity is an enemy then a flame //
	// particle is created and damage is sent.        //
	//                                                //
	// All processes regarding whether that           //
	// entity is in our line of sight have already    //
	// been done.                                     //
	////////////////////////////////////////////////////
	
	//////////////////////////
	//Setup local variables //
	// Quite a few of them  //
	//////////////////////////
	new Float:enemyPosition[3];
	new Float:enemyAbsOrigin[3];
	
	new Float:enemyEyeAngle[3];
	new Float:enemyAngle[3];
	
	new Float:spiderAngle[3];
	new Float: facingAngle; //this is the angle from the spider to the player on the x-y plane
	
	new Float: facingZAngle;
	new Float: tempSpiderPos[3];
	new Float: tempEnemyPos[3];
	new Float: hypotenuse;
	new Float: adjacent;
	
	new Float:diffAng;
	new rotation;
	
	new TFClassType:class;
	new DisguiseTeam;
	
	
	new Float:baseSpeed = 145.0; // Spider's base speed
	new Float:runSpeed  = 170.0; // Spider's running speed
	new Float:uberedSpeed  = 210.0; // Spider's speed when ubered
	new owner = GetEntPropEnt(spider, Prop_Data, "m_hOwnerEntity");
	
	//The spider needs to play WALK animation
	if(GetEntProp(spider, Prop_Data, "m_nSequence") != 1)
	{
		EmitSoundToAll(SOUND_SpiderTurn,spider);
		
		SetVariantString("walk");
		AcceptEntityInput(spider, "SetAnimation", -1, -1, 0);
	}
	
	GetEntPropVector(box, Prop_Send, "m_vecOrigin", spiderPosition);
	
	if(closestEntity > MaxClients)
	{
		//Special Case for Spiders
		new String:modelname[128];
		GetEntPropString(closestEntity, Prop_Data, "m_ModelName", modelname, 128);
		if (StrEqual(modelname, MODEL_SPIDER))
		{
			//look for the parent entity
			new foundParentEnt = GetEntPropEnt(closestEntity, Prop_Data, "m_pParent");
			
			//Entity has no parent. Its origin position are those of the real world
			if(foundParentEnt == -1)
				foundParentEnt = closestEntity;
			
			//The closestPlayer is not a player
			GetEntPropVector(foundParentEnt, Prop_Send, "m_vecOrigin", enemyAbsOrigin);
			enemyPosition[0] = enemyAbsOrigin[0];
			enemyPosition[1] = enemyAbsOrigin[1];
			enemyPosition[2] = enemyAbsOrigin[2] + 45.0;
			
			GetEntPropVector(foundParentEnt, Prop_Data, "m_angRotation", enemyAngle);
			enemyEyeAngle[0] = enemyAngle[0];
			enemyEyeAngle[1] = enemyAngle[1];
			enemyEyeAngle[2] = enemyAngle[2];
		}else{
			//The closestPlayer is not a player
			GetEntPropVector(closestEntity, Prop_Send, "m_vecOrigin", enemyAbsOrigin);
			enemyPosition[0] = enemyAbsOrigin[0];
			enemyPosition[1] = enemyAbsOrigin[1];
			enemyPosition[2] = enemyAbsOrigin[2] + 45.0;
			
			GetEntPropVector(closestEntity, Prop_Data, "m_angRotation", enemyAngle);
			enemyEyeAngle[0] = enemyAngle[0];
			enemyEyeAngle[1] = enemyAngle[1];
			enemyEyeAngle[2] = enemyAngle[2];
		}
			
	}else{
		GetClientEyePosition(closestEntity, enemyPosition);
		GetClientAbsOrigin(closestEntity,enemyAbsOrigin);
		
		GetClientEyeAngles(closestEntity,enemyEyeAngle);
		GetClientAbsAngles(closestEntity,enemyAngle);
	}
	
	//verify closestdistance
	//closestDistance GetVectorDistance(spiderPosition,enemyAbsOrigin);
	
	GetEntPropVector(box, Prop_Data, "m_angRotation", spiderAngle);
	
	facingAngle = RadToDeg(ArcTangent2(spiderPosition[0] - enemyPosition[0],spiderPosition[1] - enemyPosition[1])) + 90;
	
	//Calculate the PITCH (up - down) angle the Flame should shoot out at
	tempSpiderPos[0] = spiderPosition[0];
	tempSpiderPos[1] = spiderPosition[1];
	tempSpiderPos[2] = 0.0;
	
	tempEnemyPos[0] = enemyAbsOrigin[0];
	tempEnemyPos[1] = enemyAbsOrigin[1];
	tempEnemyPos[2] = 0.0;
	
	hypotenuse = GetVectorDistance(spiderPosition,enemyAbsOrigin);
	closestDistance = hypotenuse;
	
	adjacent = GetVectorDistance(tempSpiderPos,tempEnemyPos);	
	
	//this is the angle from the spider to the player x-z plane
	facingZAngle =RadToDeg(ArcCosine(adjacent/hypotenuse));
	
	if(spiderPosition[2] > enemyAbsOrigin[2])
		facingZAngle *= -1;
	
	//make the spider face the player
	facingAngle *= -1;
	
	//normalizes it to 0 -> 360 degrees
	//instead of -270 -> 90 degrees
	if(facingAngle < 0.0)
		facingAngle += 360.0;
	
	if(spiderAngle[1] >= 360.0)
		spiderAngle[1] -= 360.0;
	
	if(spiderAngle[1] < 0.0)
		spiderAngle[1] += 360.0;
	
	//Get the difference of the angles
	if(facingAngle > spiderAngle[1])
	{	
		//The enemy is to the spider's LEFT
		diffAng = facingAngle - spiderAngle[1];
		rotation = 1;
	}else{
		//The enemy is to the spider's RIGHT
		diffAng = spiderAngle[1] - facingAngle;
		rotation = -1;
	}
	
	if(diffAng > 180.0)
	{
		//Rotate turning direction so we rotate the shortest distance!
		rotation *= -1;
	}
	
	//Spider still hasn't directly faced enemy
	if(diffAng >= 10.0)
		spiderAngle[1] += (17.0 * rotation);
	
	//Spider is pretty close to facing the enemy
	if(diffAng > 5.0 && diffAng < 10.0)
		spiderAngle[1] += (3.0 * rotation);
	
	//this is for the flames
	spiderAngle[0] -= facingZAngle ;
	
	/////////////////////////////////////
	// Setup to fake flame spies       //
	/////////////////////////////////////
	if(closestEntity <= MaxClients)
	{
		class = TF2_GetPlayerClass(closestEntity);
		DisguiseTeam = closestEntityTeam;
		
		if(class == TFClass_Spy)
		{
			DisguiseTeam  = GetEntData(closestEntity, m_nDisguiseTeam);
			
			if(DisguiseTeam == 0)
				DisguiseTeam = GetClientTeam(closestEntity);
		}
		
	}else{
		DisguiseTeam = closestEntityTeam;
	}
	
	
	////////////////////////////////////////////////
	//Flame handler                               //
	//--------------------------------------------//
	//Here the flame is moved or spawned if neccessary
	//////////////////////////////////////////////////
	if(diffAng < 35.0 && closestDistance < 300.0)
	{	
		if(DisguiseTeam != spiderTeam)
		{
			//Move the flames origin up (Z-Axis)
			spiderPosition[2] += 8.0;
			
			new Float:tempZAngle[3];
			tempZAngle[0] = spiderAngle[0];
			tempZAngle[1] = 0.0;
			tempZAngle[2] = 0.0;
			
			if(tempZAngle[0] > 50.0 )
				tempZAngle[0]  = 50.0;
					
			if(tempZAngle[0] < -65.0)
				tempZAngle[0]  = -50.0;
			
			//Create the flames
			if(flameEntity <= 0)
			{
				new particle = CreateEntityByName("info_particle_system");
				if (IsValidEntity(particle))
				{	
					//new Float:flameStartPos[3];
					//flameStartPos[0] = 
					
					TeleportEntity(particle, spiderPosition, tempZAngle, NULL_VECTOR);
					
					DispatchKeyValue(particle, "effect_name", "flamethrower");
					DispatchSpawn(particle);
					
					//Now lets parent the flames to the spider
					new String:boxName[128];
					Format(boxName, sizeof(boxName), "target%i", box);
					
					SetVariantString(boxName);
					AcceptEntityInput(particle, "SetParent");
					
					//DispatchSpawn(particle);
					ActivateEntity(particle);
					AcceptEntityInput(particle, "start");
					
					//SetEntPropEnt(spider, Prop_Data, "m_hOwnerOwnerEntity", particle);
					SetPackPosition(dataPackHandle, 112);
					WritePackCell(dataPackHandle, EntIndexToEntRef(particle));
					
					EmitSoundToAll(SOUND_FlameLoop,spider);
				}
			}else{
					TeleportEntity(flameEntity, NULL_VECTOR, tempZAngle, NULL_VECTOR);
					//Move the flames back to origin (Z-Axis)
					spiderPosition[2] -= 8.0;
			}
		}else{
			//The spider was shooting flames but now the ENEMY is no longer
			//in sight. So remove the flames particle.
			if(flameEntity > 0)
			{	
				EmitSoundToAll(SOUND_FlameEnd,spider);
				StopSound(spider, SNDCHAN_AUTO, SOUND_FlameLoop);
				AcceptEntityInput(flameEntity,"kill");
				
				SetPackPosition(dataPackHandle, 112);
				WritePackCell(dataPackHandle, -1);
			}
		}
	}
	
	//The enemy is close enough so damage can be applied
	if(diffAng < 35.0 && closestDistance < 170.0 &&  DisguiseTeam != spiderTeam)
	{
		//16779264 = Flamethrower damage
		
		//Makes sure to only apply damage to enemies. This allows the spider to flame
		//a disguised spy but not hurt him..THUS fooling others  :D
		if(spiderTeam != closestEntityTeam)
		{	
			if(closestEntity <= MaxClients)
			{
				if(!client_rolls[closestEntity][AWARD_G_GODMODE][0])
				{
					if(GetEntProp(closestEntity, Prop_Send, "m_nPlayerCond")&32)
					{
						//Dont hurt the friendly disguised spies
						//PrintToChatAll("bypassing!");
					}else{
						new spiderSounds = GetEntProp(spider, Prop_Data, "m_PerformanceMode");
						
						if(GetClientHealth(closestEntity) <= 20)
						{
							//hooray sounds
							new rndNum = GetRandomInt(1,5);
							
							switch(rndNum)
							{
								case 1:
									EmitSoundToAll(SOUND_SPIDERKILL01,spider,_,_,_,_,150);
									
								case 2:
									EmitSoundToAll(SOUND_SPIDERKILL02,spider,_,_,_,_,150);
								
								case 3:
									EmitSoundToAll(SOUND_SPIDERKILL03,spider,_,_,_,_,150);
								
								case 4:
									EmitSoundToAll(SOUND_SPIDERKILL04,spider,_,_,_,_,150);
								
								case 5:
									EmitSoundToAll(SOUND_SPIDERKILL05,spider,_,_,_,_,150);
							}
						}else{
							if(GetClientHealth(closestEntity) > 20 && spiderSounds == 1)
							{
								new rndNum = GetRandomInt(0,5);
								
								switch(rndNum)
								{
									case 0:
										EmitSoundToAll(SOUND_SPIDERLAUGH01,spider,_,_,_,_,150);
									
									case 1:
										EmitSoundToAll(SOUND_SPIDERLAUGH02,spider,_,_,_,_,150);
									
									case 2:
										EmitSoundToAll(SOUND_SPIDERLAUGH03,spider,_,_,_,_,150);
								}
								SetEntProp(spider, Prop_Data, "m_PerformanceMode", 0);
								CreateTimer(1.0, SphereSoundRdy, spider);
								spiderSounds = 0;
							}
						}
						
						
						if(GetEntProp(spider, Prop_Data, "m_nSkin") != 0)
						{
							//does more damage while ubered
							DealDamage(closestEntity,RoundFloat((300.0-closestDistance)/20.0),owner,16779264,"spider");
							
							DealDamage(closestEntity,0,owner,2056,"tf_weapon_flamethrower");
						}else{
							DealDamage(closestEntity,RoundFloat((300.0-closestDistance)/30.0),owner,16779264,"spider");
							DealDamage(closestEntity,0,owner,2056,"tf_weapon_flamethrower");
						}
						
						if(owner < cMaxClients && owner > 0)
						{
							if(dmgDebug[owner])
							{
								PrintToChat(owner, "Dealing Damage to: %i | Distancet: %f | RealDist: %f", closestEntity, closestDistance, hypotenuse ); ///DEBUG remove before publishing
							}
						}
					}
				}
			}else{
				//spiders is about to hurt an object
				new rndNum = GetRandomInt(0,15);
				if(rndNum == 10)
				{
					SetVariantInt(1);
					
					AcceptEntityInput(closestEntity, "RemoveHealth");
				}
			}
		}
	}
	
	spiderAngle[0] += facingZAngle;
	
	//run a bit faster cause player is far
	if(closestDistance > 350.0)
		baseSpeed = runSpeed;
	
	if(GetEntProp(spider, Prop_Data, "m_nSkin") != 0)
		baseSpeed = uberedSpeed;
		
	new Float:speed[3];
	GetAngleVectors(spiderAngle, speed, NULL_VECTOR, NULL_VECTOR);
	
	/////////////////////////////////////////////////////////////
	//Determine how far from the ground the spider is and apply//
	//down forces if he's far from the ground                  //
	/////////////////////////////////////////////////////////////
	
	//-----Draw a trace from the box to the floor
	g_FilteredEntity = box;
	
	new Float:boxToFloor[3];
	new Float:Direction[3];
	new Float:hullBoxMin[3];
	new Float:hullBoxMax[3];
	
	hullBoxMax[0] = 10.0;
	hullBoxMax[1] = 10.0;
	hullBoxMax[2] = 0.5;
	
	spiderPosition[2] += 10;
	Direction[0] = spiderPosition[0];
	Direction[1] = spiderPosition[1];
	Direction[2] = spiderPosition[2]-1024;
	
	new Handle:Trace = TR_TraceHullFilterEx(spiderPosition, Direction,hullBoxMin,hullBoxMax, MASK_NPCWORLDSTATIC	, TraceFilterAll,box);
	TR_GetEndPosition(boxToFloor, Trace);
	CloseHandle(Trace);
	
	spiderPosition[2] -= 10;
	
	//move the spider up just a bit so he can go over obstacles
	new Float: floorDistance = GetVectorDistance(boxToFloor,spiderPosition);
	
	if(floorDistance < 4.0)
		speed[2]+=0.5;
	
	if(floorDistance >= 4.0 && floorDistance < 9.0)
		speed[2]+=0.3;
	
	if(floorDistance >= 9.0)
		speed[2]-=1.6;	
	
	//this is to correct the spiders orientation if he gets
	//tipped over or is upside down
	if(spiderAngle[0] > 60.0)
		spiderAngle[0] =- 5.0;
	
	if(spiderAngle[2] > 60.0)
		spiderAngle[2] =- 5.0;
	
	
	speed[0]*=baseSpeed; speed[1]*=baseSpeed; speed[2]*=baseSpeed;
	
	//move the spider
	//dont apply velocities to the rotation angle if its too large
	
	/////////////////////////////////////////////////////////////////
	//Before applying any velocities to the spider we want to make //
	//sure that its not going to fall and be left stranded         //
	/////////////////////////////////////////////////////////////////
	
	
	if(diffAng > 80.0 || closestDistance < 70.0)
	{
		TeleportEntity(box, NULL_VECTOR, spiderAngle, NULL_VECTOR);
	}else{
		TeleportEntity(box, NULL_VECTOR, spiderAngle, speed);
	}
		
	//show the spider's angle
	//PrintToChatAll("0:%f 1:%f 2:%f",spiderAngle[0],spiderAngle[1], spiderAngle[2]);
	
	//LogToFile(logPath,"moveSpider -- Leaving");
}

public filterClosestResults(Handle: dataPackHandle)
{
	//LogToFile(logPath,"filterClosestResults -- Entering");
	
	new spiderTeam;
	new results1[3];
	new results2[3];
	new whoIsCloser;
	
	ResetPack(dataPackHandle);
	new spider = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	SetPackPosition(dataPackHandle, 16);
	spiderTeam = ReadPackCell(dataPackHandle);
	
	SetPackPosition(dataPackHandle, 56);
	results1[0] = ReadPackCell(dataPackHandle); //object entity
	results1[1] = ReadPackCell(dataPackHandle); //object teamnum
	results1[2] = ReadPackCell(dataPackHandle); //object distance
	
	results2[0] = ReadPackCell(dataPackHandle); //player entity
	results2[1] = ReadPackCell(dataPackHandle); //player teamnum
	results2[2] = ReadPackCell(dataPackHandle); //player distance
	
	//PrintToChatAll("Obj Ent: %i, Obj team: %i, Obj Dist: %i",results1[0] ,results1[1] ,results1[2]);
	//PrintToChatAll("PLy Ent: %i, PLy team: %i, PLy Dist: %i",results2[0] ,results2[1] ,results2[2]);
	
	//an object is closer
	//whoIsCloser == 1
	
	//an player is closer
	//whoIsCloser == 2
	
	//////////////////////////////////////////////////////////////
	//Here we will determine who deserves our attention.        //
	//Is it the enemy that is down the field or the friendly    //
	//teleporter that is right beside us. Or how about is it    //
	//the player beside us that decided to go AFK while everyone//
	//else passes by                                            //
	//////////////////////////////////////////////////////////////
	
	
	//get some health first, preservation is what matters!
	new spiderHealth = GetEntProp(spider, Prop_Data, "m_iHealth");
	new spiderMaxHealth = GetEntProp(spider, Prop_Data, "m_iMaxHealth");
	
	if(spiderHealth < spiderMaxHealth && GetRandomInt(1,100) > 70 && results1[0] != -1)
	{
		new String:closestClassName[256];
		GetEdictClassname(results1[0], closestClassName, sizeof(closestClassName));
		
		//spider touched a med pack
		if(StrContains(closestClassName, "item_healthkit",false) >= 0)
		{
			whoIsCloser = 1;
		}
	}
	
	//the objects is on the enemy team but the player is on our team
	if(results1[1] != spiderTeam && results2[1] == spiderTeam)
	{
		//then move towards this enemy object
		whoIsCloser = 1;
	}
	
	//the objects is on the enemy team and the player is an enemy as well
	if(results1[1] != spiderTeam && results2[1] != spiderTeam)
	{
		//find out who's closer
		
		//the player is closer
		if(results2[2] <= results1[2])
		{
			whoIsCloser = 2;       
		}else{
			//turns out the object is the closest enemy
			whoIsCloser = 1;
		}
	}
	
	//the objects is on our team but the player is not
	if(results1[1] == spiderTeam && results2[1] != spiderTeam)
	{
		//then move towards the enemy player
		whoIsCloser = 2;
	}
	
	//both the object and player are on the same team
	if(results1[1] == spiderTeam && results2[1] == spiderTeam && results1[0] != -1)
	{
		whoIsCloser = 2;
	}
	
	//umm no1 is there
	if(results1[0] == -1)
	{
		whoIsCloser = 2;
	}
	
	if(results2[0] == -1)
	{
		whoIsCloser = 1;
	}
	
	SetPackPosition(dataPackHandle, 104);
	WritePackCell(dataPackHandle, whoIsCloser);
	
	//LogToFile(logPath,"filterClosestResults -- Leaving");
}

public Action:isPlayerAFK_Timer(Handle:timer)
{
	///////////////////////////////////////////////////////////
	// Set an ignore flag on a player                        //
	//                                                       //
	// HOW---------------------------------------------------// 
	// Simple AFK Detection, if player has not moved then his//
	//afk score gets one point, 5 points = ignore            //
	///////////////////////////////////////////////////////////
	new Float:tempPos[3];
	
	for(new i=1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i,tempPos);
			if(GetVectorDistance(tempPos,playerAFKPos[i]) > 20.0)
			{
				AFKScore[i] --;
			}else{
				AFKScore[i] ++;
			}
			
			if(AFKScore[i] < 0)
				AFKScore[i] = 0;
			
			if(AFKScore[i] > 10)
			{
				AFKScore[i] = 10;
				
			}
			
			GetClientAbsOrigin(i,playerAFKPos[i]);
		}else{
			//set to zero
			playerAFKPos[i][0] = 0.0;
			playerAFKPos[i][1] = 0.0;
			playerAFKPos[i][2] = 0.0;
		}
	}
}

public spiderRollDice(box, owner, Handle:dataPackHandle)
{
	new String:name[32];
	SetPackPosition(dataPackHandle, 128);
	new neededTime = ReadPackCell(dataPackHandle);
	SetPackPosition(dataPackHandle, 176);
	ReadPackString(dataPackHandle,name, sizeof(name));
	
	//Can the Spider Roll the dice?
	if(neededTime < GetTime())
	{
		if(!IsEntLimitReached())
		{
			Format(name, sizeof(name), "%s's ", name);
			
			decl String:message[200];
			new rndNum = GetRandomInt(1,4);
			
			//prevent too many Spiders
			if(amountOfSpiders() > 2)
				rndNum = GetRandomInt(1,3);
			
			switch(rndNum)
			{
				case 1:
				{
					Format(message, sizeof(message), "\x01\x04[RTD] \x03%s Spider\x04 rolled a \x03Groovitron!",name); 
					Spawn_Groovitron(box);
				}
				case 2:
				{
					Format(message, sizeof(message), "\x01\x04[RTD] \x03%sSpider\x04 dropped a \x03Medium Healthkit!",name); 
					TF_SpawnMedipack(box, "item_healthkit_medium", true);
				}
				case 3:
				{
					Format(message, sizeof(message), "\x01\x04[RTD] \x03%sSpider\x04 dropped a  \x03Medium Ammo",name); 
					TF_SpawnMedipack(box, "item_ammopack_medium", true);
				}
				case 4:
				{
					Format(message, sizeof(message), "\x01\x04[RTD] \x03%sSpider\x04 gave birth to another \x03Spider!",name); 
					new bool:ownerHere = true;
					if(owner > 0 && owner <= MaxClients)
					{
						if(IsClientInGame(owner))
						{
							Spawn_Spider(owner, 500 + RTD_Perks[owner][15], 500 + RTD_Perks[owner][15]);
						}else{
							ownerHere = false;
						}
					}else{
						ownerHere = false;
					}
					
					if(!ownerHere)
						Spawn_Spider(box, 500, 500);
				}
				
			}
			
			PrintToChatSome(message); 
		}
		
		SetPackPosition(dataPackHandle, 128);
		WritePackCell(dataPackHandle, GetTime() + GetRandomInt(30, 80));
	}
}

public amountOfSpiders()
{
	new ent = -1;
	new numSpiders;
	new currIndex;
	
	while ((ent = FindEntityByClassname(ent, "prop_dynamic")) != -1)
	{	
		currIndex = GetEntProp(ent, Prop_Data, "m_nModelIndex");
		if(currIndex == spiderIndex )
			numSpiders ++;
	}
	
	return numSpiders;
}
/*
public attachHatToSpider(client, spider)
{
	new parent;
	new m_nBody;
	
	parent= GetEntPropEnt(client, Prop_Data, "m_pParent");
	
	new entity = -1;
	new String:modelname[128];
	
	while ((entity = FindEntityByClassname(entity, "tf_wearable_item")) != -1)
	{
		parent = GetEntPropEnt(entity, Prop_Data, "m_pParent");
		//prevent false positives
		m_nBody = -1;
		
		//OK we found a wearable now lets make sure its a hat
		if(parent == client)
		{
			m_nBody = GetEntProp(entity, Prop_Data, "m_nBody");
			GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, 128);
			
			//aright we found a hat, or at least something thats parented to the head :)
			if(m_nBody == 0)
			{m_bDisguiseWearable
			}
			//PrintToChat(client, "Found: %s | m_nBody: %i", modelname, parentAttachment);
		}
	}
}*/

AttachSpiderToBack(client, health, maxHealth)
{
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to attach Spider on Back!" );
		return;
	}
	
	client_rolls[client][AWARD_G_SPIDER][1] = EntIndexToEntRef(ent);
	
	SetEntityModel(ent, MODEL_SPIDERBACK);
	
	//Set the Spider's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	DispatchSpawn(ent);
	
	AcceptEntityInput( ent, "DisableShadow" );
	
	
	SetEntProp( ent, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 3);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 3);
	
	//Set the spider's health
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", maxHealth);
	SetEntProp(ent, Prop_Data, "m_iHealth", health);
	
	//argggh F.U. valve
	AcceptEntityInput( ent, "DisableCollision" );
	AcceptEntityInput( ent, "EnableCollision" );
	
	HookSingleEntityOutput(ent, "OnHealthChanged", spider_Hurt, false);
	
	//new iTeam = GetClientTeam(client);
	new iTeam = GetEntProp(client, Prop_Data, "m_iTeamNum");
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	
	
	//set the default animation
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	CAttach(ent, client, "flag");
	
	if(iTeam == RED_TEAM)
	{
		SetVariantString(bluDamageFilter);
	}else{
		SetVariantString(redDamageFilter);
	}
	
	AcceptEntityInput(ent, "SetDamageFilter", -1, -1, 0); 
	
	//The Datapack stores all the Backpack's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, SpiderOnBack_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(ent));   //PackPosition(0);  Spider entity
	WritePackCell(dataPackHandle, GetTime() + 40);   //PackPosition(8);  Next yell time
	WritePackCell(dataPackHandle, GetTime());   //PackPosition(16);  spawnedTime
	
	EmitSoundToAll(SOUND_ITEM_EQUIP,client);
}

public Action:SpiderOnBack_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stop_SpiderOnBack_Timer(dataPackHandle))
		return Plugin_Stop;
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new spider = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new nextYellTime = ReadPackCell(dataPackHandle);
	//new spawnedTime = ReadPackCell(dataPackHandle);
	
	new client = GetEntPropEnt(spider, Prop_Data, "m_hOwnerEntity");
	
	itemEquipped_OnBack[client] = 1;
	
	/////////////////
	//Update Alpha //
	/////////////////
	new alpha = GetEntData(client, m_clrRender + 3, 1);
	new playerCond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	if(alpha == 0)
		StopSound(spider, SNDCHAN_AUTO, SOUND_SPIDER_WEE);
	
	SetEntityRenderMode(spider, RENDER_TRANSCOLOR);	
	SetEntityRenderColor(spider, 255, 255,255, alpha);
	
	if(class == TFClass_Spy)
	{	
		if(playerCond&16 || playerCond&24)
		{
			StopSound(spider, SNDCHAN_AUTO, SOUND_SPIDER_WEE);
			SetEntityRenderMode(spider, RENDER_TRANSCOLOR);	
			SetEntityRenderColor(spider, 255, 255,255, 0);
		}
	}
	
	////////////////////
	// Determine skin //
	////////////////////
	if(playerCond&32)
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
	}else{
		if(GetEntProp(spider, Prop_Data, "m_nSkin") != 0)
			DispatchKeyValue(spider, "skin","0"); 
	}
	
	//////////////////////////////////
	// Determine health adjustments //
	//////////////////////////////////
	new spiderHealth = GetEntProp(spider, Prop_Data, "m_iHealth");
	new spiderMaxHealth = GetEntProp(spider, Prop_Data, "m_iMaxHealth");
	
	new Float:spiderHealthPercentage = float(spiderHealth)/float(spiderMaxHealth);
	new Float:clientHealthPercentage = float(GetClientHealth(client))/float(finalHealthAdjustments(client)) ;
	
	//Spider needs some health and the player has enough
	if(spiderHealthPercentage < 0.5)
	{
		if(clientHealthPercentage > 0.5)
		{
			SetEntProp(spider, Prop_Data, "m_iHealth", spiderHealth + 1);
			DealDamage(client, 1, client, 4226);
			
			centerHudText(client, "Healing Spider", 0.0, 0.2, HudMsg3, 0.72); 
		}
	}else{
		//Player needs some health and the Spider has enough
		if(spiderHealthPercentage > 0.8)
		{
			if(clientHealthPercentage < 0.5)
			{
				SetEntProp(spider, Prop_Data, "m_iHealth", spiderHealth - 1);
				addHealth(client, 1);
				
				centerHudText(client, "Spider is healing you", 0.0, 0.2, HudMsg3, 0.72); 
			}
		}
	}
	
	
	if(!client_rolls[client][AWARD_G_BACKPACK][0] && !inTimerBasedRoll[client])
	{	
		SetHudTextParams(0.03, 0.04, 3.0, 250, 250, 210, 255);
		ShowHudText(client, HudMsg5, "Spider Health: %i/%i", spiderHealth, spiderMaxHealth);
	}
	
	//////////////////////////////////
	// Determine if Spider can yell //
	//////////////////////////////////
	if(GetTime() > nextYellTime)
	{
		EmitSoundToAll(SOUND_SPIDER_WEE, spider,_,_,_,_,110);
		SetPackPosition(dataPackHandle, 8);
		WritePackCell(dataPackHandle, GetTime() + 40);   //PackPosition(8);  Next yell time
		
		spiderHealth = GetEntProp(spider, Prop_Data, "m_iHealth");
		spiderHealth += 50;
		if(spiderHealth >= spiderMaxHealth)
			spiderHealth = spiderMaxHealth;
		
		SetEntProp(spider, Prop_Data, "m_iHealth", spiderHealth);
	}
	
	return Plugin_Continue;
}

public stop_SpiderOnBack_Timer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new spider = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	if(spider <= 0)
		return true;
	
	new client = GetEntPropEnt(spider, Prop_Data, "m_hOwnerEntity");
	
	//Client either disconnected or died, either way he's not here
	if(client < 1)
	{
		StopSound(spider, SNDCHAN_AUTO, SOUND_SPIDER_WEE);
		CDetach(spider);
		killEntityIn(spider, 0.3);
		Spawn_Spider(spider, GetEntProp(spider, Prop_Data, "m_iHealth"), GetEntProp(spider, Prop_Data, "m_iMaxHealth"));
		return true;
	}
	
	//Player died
	if(!IsPlayerAlive(client))
	{
		itemEquipped_OnBack[client] = 0;
		
		StopSound(spider, SNDCHAN_AUTO, SOUND_SPIDER_WEE);
		CDetach(spider);
		killEntityIn(spider, 0.3);
		
		Spawn_Spider(client, GetEntProp(spider, Prop_Data, "m_iHealth"), GetEntProp(spider, Prop_Data, "m_iMaxHealth"));
		client_rolls[client][AWARD_G_SPIDER][1] = 0;
		
		return true;
	}
	
	if(client_rolls[client][AWARD_G_SPIDER][1] == 0)
	{
		return true;
	}
	
	return false;
}

public dropSpider(client)
{
	new spider = EntRefToEntIndex(client_rolls[client][AWARD_G_SPIDER][1]);
	
	if(spider <= 0)
		return;
		
	new currIndex = GetEntProp(spider, Prop_Data, "m_nModelIndex");
		
	if(currIndex != spiderBackIndex)
		return ;
	
	new owner = GetEntPropEnt(spider, Prop_Data, "m_hOwnerEntity");
	
	if(client != owner)
		return;
	
	new spiderHealth = GetEntProp(spider, Prop_Data, "m_iHealth");
	new spiderMaxHealth = GetEntProp(spider, Prop_Data, "m_iMaxHealth");
	
	CDetach(spider);
	killEntityIn(spider, 0.1);
	StopSound(spider, SNDCHAN_AUTO, SOUND_SPIDER_WEE);
	
	client_rolls[client][AWARD_G_SPIDER][1] = 0;
	itemEquipped_OnBack[client] = 0;
	
	Spawn_Spider(client, spiderHealth, spiderMaxHealth);
}

public Action:SphereSoundRdy(Handle:timer, any:entity)
{
	if (IsValidEdict(entity))
	{
		
		decl String:modelname[64];
		GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, 64);
		if (StrEqual(modelname, MODEL_SPIDER) ||
			StrEqual(modelname, MODEL_ZOMBIE_CLASSIC) || StrEqual(modelname, MODEL_ZOMBIE_02) ||
			StrEqual(modelname, MODEL_ZOMBIE_03))
		{
			//PrintToChatAll("Sounds, valid model! Found model: %s",modelname);
		}else{
			//PrintToChatAll("Stopping Sounds invalid model! Found model: %s",modelname);
			return Plugin_Stop;
		}
		
		SetEntProp(entity, Prop_Data, "m_PerformanceMode", 1);
	}
	
	return Plugin_Stop;
}