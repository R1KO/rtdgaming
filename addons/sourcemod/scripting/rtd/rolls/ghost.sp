#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <rtd_rollinfo>

public Action:Ghost_Timer(Handle:timer, any:other)
{
	if(!IsValidEntity(other))
	{
		return Plugin_Stop;
	}
	
	new String:modelname[128];
	GetEntPropString(other, Prop_Data, "m_ModelName", modelname, 128);
	
	if (!StrEqual(modelname, MODEL_SPIDERBOX) )
	{
		return Plugin_Stop;
	}
	
	new Float: playerPos[3];
	new Float: ghostPos[3];
	new Float: distance;
	new playerTeam;
	new stunFlag;
	new ghostTeam =  GetEntProp(other, Prop_Data, "m_iTeamNum");
	GetEntPropVector(other, Prop_Data, "m_vecOrigin", ghostPos);
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if(TF2_GetPlayerConditionFlags(i) & TF_CONDFLAG_UBERCHARGED)
			continue;
		
		playerTeam = GetClientTeam(i);
		
		if(GetTime() < client_rolls[i][AWARD_G_GHOST][2] && client_rolls[i][AWARD_G_GHOST][2] != 0)
			continue;
		
		//Check to see if player is close to a Crap Pile
		if(playerTeam != ghostTeam)
		{
			GetClientAbsOrigin(i,playerPos);
			distance = GetVectorDistance( playerPos, ghostPos);
			
			if(distance < 150.0)
			{
				stunFlag = GetEntData(i, m_iStunFlags);
				
				//scare the player
				if(stunFlag != TF_STUNFLAGS_GHOSTSCARE)
				{
					
					new rndNum = GetRandomInt(1,8);
					
					new String:playsound[64];
					Format(playsound, sizeof(playsound), "vo/halloween_scream%i.wav", rndNum);
					EmitSoundToAll(playsound,i);
					
					rndNum = GetRandomInt(1,6);
					Format(playsound, sizeof(playsound), "vo/halloween_boo%i.wav", rndNum);
					EmitSoundToAll(playsound,other);
					
					TF2_StunPlayer(i,float(RTD_Perks[i][12]), 0.0, TF_STUNFLAGS_GHOSTSCARE, 0);
					
					//Next time the player can get scared
					client_rolls[i][AWARD_G_GHOST][2] = GetTime() + 7;
					
					//PrintToChatAll("CurTime:%i | NextScare:%i", GetTime(), client_rolls[i][AWARD_G_GHOST][2] );
				}
			}
		}
	}
	
	return Plugin_Continue;
}


//////////////////////////////////////////////////////////
// Spawns a ghost that interacts with the environment  //
// lookinging for friendlies, enemies and 'waypoints'   //
//                                                      //
//////////////////////////////////////////////////////////

public Action:Spawn_Ghost(client)
{	
	//LogToFile(logPath,"Spawn_Spider -- Entering");
	
	new box = CreateEntityByName("prop_physics_override");
	if ( box == -1 )
	{
		ReplyToCommand( client, "Failed to create a GhostBox!" );
		return Plugin_Handled;
	}
	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Ghost!" );
		return Plugin_Handled;
	}
	
	SetEntityModel(box, MODEL_SPIDERBOX);
	
	new iTeam = GetClientTeam(client);
	
	if(iTeam == BLUE_TEAM)
	{
		SetEntityModel(ent, MODEL_GHOST);
	}else{
		SetEntityModel(ent, MODEL_GHOST_RED);
	}
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	DispatchSpawn(box);
	DispatchSpawn(ent);
	
	//Our 'sled' collision does not need to be rendered nor does it need shadows
	AcceptEntityInput( box, "DisableShadow" );
	SetEntityRenderMode(box, RENDER_NONE);
	
	//owner entity for the Box tells it its the Spider
	SetEntPropEnt(box, Prop_Data, "m_hOwnerEntity", ent);
	
	SetEntProp( box, Prop_Data, "m_nSolidType", 4 );
	SetEntProp( box, Prop_Send, "m_nSolidType", 4 );
	
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	

	SetEntProp( ent, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 3);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 3);
	
	AcceptEntityInput( ent, "DisableCollision" );
	AcceptEntityInput( ent, "EnableCollision" );
	
	if(iTeam == RED_TEAM)
	{
		SetVariantString(bluDamageFilter);
	}else{
		SetVariantString(redDamageFilter);
	}
	AcceptEntityInput(ent, "SetDamageFilter", -1, -1, 0); 
	
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", 1000);
	SetEntProp(ent, Prop_Data, "m_iHealth", 1000);
	
	
	
	
	SetEntProp(ent, Prop_Data, "m_PerformanceMode", 1);
	
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	
	SetVariantInt(iTeam);
	AcceptEntityInput(box, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(box, "SetTeam", -1, -1, 0); 
	
	new Float:pos[3];
	GetClientEyePosition(client, pos);
	
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
	Format(boxName, sizeof(boxName), "ghost%i", ent);
	DispatchKeyValue(ent, "targetname", boxName);
	
	//Now lets parent the physics box to the animated spider
	Format(boxName, sizeof(boxName), "target%i", box);
	DispatchKeyValue(box, "targetname", boxName);
	
	SetVariantString(boxName);
	AcceptEntityInput(ent, "SetParent");
	
	//Set the box transparent
	SetEntityRenderMode(box, RENDER_TRANSCOLOR);	
	SetEntityRenderColor(box, 0, 0, 0, 0);
	
	// send "kill" event to the event queue
	if(RTD_Perks[client][35])
	{
		killEntityIn(box, 60.0);
	}else{
		killEntityIn(box, 30.0);
	}
	
	SetEntPropFloat(box, Prop_Data, "m_flGravity", 50.0);
	SetEntPropFloat(ent, Prop_Data, "m_flGravity", 50.0);
	SetEntityGravity(box, 50.0);
	SetEntityGravity(ent, 50.0);
	
	new Float:baseSpeed = 85.0;
	new Float:runSpeed = 110.0;
	
	//faster moving ghost speed
	if(RTD_Perks[client][34])
	{
		baseSpeed = 110.0;
		runSpeed = 143.0;
	}
	
	//The Datapack stores all the Spider's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, GhostThink_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	CreateTimer(0.3, Ghost_Timer, box, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, ent);
	WritePackCell(dataPackHandle, box);
	WritePackCell(dataPackHandle, iTeam);
	WritePackFloat(dataPackHandle, 40.0); //The range tolerance
	WritePackCell(dataPackHandle, client); //Client that spawned it
	WritePackCell(dataPackHandle, GetEntProp(ent, Prop_Data, "m_iMaxHealth"));
	WritePackCell(dataPackHandle, -1); 	//Player ID ubering spider
	WritePackCell(dataPackHandle, -1); 	//Object entity that is the closest
	WritePackCell(dataPackHandle, -1); 	//Object teamnum that is closest
	WritePackCell(dataPackHandle, 1001);//Object distance that is closest
	WritePackCell(dataPackHandle, -1); 	//Player entity that is the closest
	WritePackCell(dataPackHandle, -1); 	//Player teamnum that is closest
	WritePackCell(dataPackHandle, 1001);//Playertdistance that is closest
	WritePackCell(dataPackHandle, -1); 	//Is object closer or is the player closer?
	WritePackFloat(dataPackHandle, baseSpeed); 	//[112] walk speed for ghost
	WritePackFloat(dataPackHandle, runSpeed); 	//[120] run speed for ghost
	WritePackFloat(dataPackHandle, runSpeed); 	//[128] 0 | This is the point where a enemy was last seen
	WritePackFloat(dataPackHandle, runSpeed); 	//[136] 1 |
	WritePackFloat(dataPackHandle, runSpeed); 	//[144] 2 |
	HookSingleEntityOutput(ent, "OnHealthChanged", Ghost_Hurt, false);
	
	return Plugin_Handled;
}

public Ghost_Hurt (const String:output[], caller, activator, Float:delay)
{
	if(IsValidEntity(caller))
	{
		//attach blood gibs
		new box = GetEntPropEnt(caller, Prop_Data, "m_pParent");
		
		
		if(IsValidEntity(box))
			AttachTempParticle(box,"env_sawblood", 1.0, false,"",20.0, false);
		
		if(GetEntProp(caller, Prop_Data, "m_iHealth") <= 0)
		{
			//show some chunky blood on death
			AttachTempParticle(caller,"blood_trail_red_01_goop", 1.0, false,"",0.0, false);
				
			//Let's reward the player for killing a spider
			new rndNum = GetRandomInt(0,20);
			if(rndNum > 10)
			{
				TF_SpawnMedipack(caller, "item_healthkit_medium", true);
			}else{
				TF_SpawnMedipack(caller, "item_ammopack_medium", true);
			}
		}
	}
}

public Action:GhostThink_Timer(Handle:timer, Handle:dataPackHandle)
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
	if(stopGhostThinkTimer(dataPackHandle))
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
	spider = ReadPackCell(dataPackHandle);
	box = ReadPackCell(dataPackHandle);
	spiderTeam = ReadPackCell(dataPackHandle);
	rangeTolerance = ReadPackFloat(dataPackHandle);
	spiderOwner = ReadPackCell(dataPackHandle);
	
	if(spiderOwner != spiderTeam)
	{
		SetPackPosition(dataPackHandle, 32);
		WritePackCell(dataPackHandle, -1);
	}
	
	GetEntPropVector(box, Prop_Data, "m_vecOrigin", spiderPosition);
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
	
	findClosestObjectToGhost(spider, box, spiderPosition, traceRaySpiderPosition, spiderTeam, rangeTolerance, dataPackHandle);
	findClosestPlayerToGhost(spider, box, spiderPosition, traceRaySpiderPosition, spiderTeam, rangeTolerance, dataPackHandle, spiderOwner);
	
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
	}
	
	new Float:lastKnownPos[3];
	//save location enemy was last seen
	if(closestEntity != -1)
	{
		GetEntPropVector(closestEntity, Prop_Data, "m_vecOrigin", lastKnownPos);
		
		SetPackPosition(dataPackHandle, 128);
		WritePackFloat(dataPackHandle, lastKnownPos[0]);
		WritePackFloat(dataPackHandle, lastKnownPos[1]);
		WritePackFloat(dataPackHandle, lastKnownPos[2]);
	}
	///////////////////////////////
	//Determine Ghost movement	 //
	///////////////////////////////
	if(closestEntity == -1 || closestDistance < 80.0 && closestEntityTeam == spiderTeam)
	{
		//move to the last location than an enemy was seen
		if(closestEntity == -1)
		{
			SetPackPosition(dataPackHandle, 128);
			lastKnownPos[0] = ReadPackFloat(dataPackHandle);
			lastKnownPos[1] = ReadPackFloat(dataPackHandle);
			lastKnownPos[2] = ReadPackFloat(dataPackHandle);
			
			closestDistance = GetVectorDistance(lastKnownPos,spiderPosition);
			if(closestDistance < 600.0 && lastKnownPos[0] != 0.0 && lastKnownPos[1] != 0.0 && lastKnownPos[2] != 0.0)
			{
				//move towards point
				//PrintToChatAll("moving towards point! %i", GetTime());
				moveGhost_ToPoint(spider, box, spiderTeam, spiderPosition, closestDistance, dataPackHandle);
			}
		}
	}else{
		//move towards entity
		moveGhost(spider, box, spiderTeam, spiderPosition, closestEntity, closestEntityTeam, closestDistance, dataPackHandle);
	}
	return Plugin_Continue;
}

public findClosestObjectToGhost(spider, box, Float:spiderPosition[3], Float:traceRaySpiderPosition[3],spiderTeam, Float:rangeTolerance, Handle:dataPackHandle)
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
	
	for (new step = 1; step <= 10; step++)
	{
		foundObjects = 0;
		
		//target spiders
		if(step == 1)
			objectName = "prop_dynamic";
		
		//target lockers
		if(step == 2)
			objectName = "prop_dynamic";
		
		if(step == 3)
			objectName = "item_healthkit_small";
		
		if(step == 4)
			objectName = "item_healthkit_medium";
		
		if(step == 5)
			objectName = "item_healthkit_full";
			
		if(step == 6)
			objectName = "obj_sentrygun";
		
		if(step == 7)
			objectName = "obj_dispenser";
		
		if(step == 8)
			objectName = "obj_teleporter_entrance";
		
		if(step == 9)
			objectName = "obj_teleporter_exit";
		
		if(step == 10)
			objectName = "team_control_point";
		
		if(closestObject == -1)
		{
			while ((foundObjectEnt = FindEntityByClassname(foundObjectEnt, objectName)) != -1) 
			{	
				
				processObject = true;
				
				//Find spiders
				if(step == 1)
				{
					//we need to verify the model
					GetEntPropString(foundObjectEnt, Prop_Data, "m_ModelName", modelname, 128);
					
					if (StrEqual(modelname, MODEL_SPIDER) && foundObjectEnt != spider)
					{
						//look for the parent entity
						new foundParentEnt = GetEntPropEnt(foundObjectEnt, Prop_Data, "m_pParent");
						
						//Entity has no parent. Its origin position are those of the real world
						if(foundParentEnt == -1)
							foundParentEnt = foundObjectEnt;
						
						GetEntPropVector(foundParentEnt, Prop_Data, "m_vecOrigin", foundObjectPos);
						
						objectDistances[foundObjects][0] = float(foundObjectEnt);
						distance = GetVectorDistance(spiderPosition,foundObjectPos);
					}else{
						processObject = false;
					}
				}
				
				//Find lockers
				if(step == 2)
				{
					//we need to verify the model
					GetEntPropString(foundObjectEnt, Prop_Data, "m_ModelName", modelname, 128);
					
					if (StrEqual(modelname, MODEL_LOCKER))
					{
						GetEntPropVector(foundObjectEnt, Prop_Data, "m_vecOrigin", foundObjectPos);
						
						objectDistances[foundObjects][0] = float(foundObjectEnt);
						distance = GetVectorDistance(spiderPosition,foundObjectPos);
						
					}else{
						processObject = false;
					}
				}
				
				if(step > 2)
				{
					//no model verification needed
					objectDistances[foundObjects][0] = float(foundObjectEnt);
					GetEntPropVector(foundObjectEnt, Prop_Data, "m_vecOrigin", foundObjectPos);
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
				
				if(closestObject != -1)
				{
					GetEntPropString(closestObject, Prop_Data, "m_ModelName", modelname, 128);
					//PrintToChatAll("modelname: %s",modelname);
					
					//buildables that are team independent, might be enemies
					if(StrEqual(objectName, "obj_sentrygun") || StrEqual(objectName, "obj_dispenser") || StrEqual(objectName,"obj_teleporter_entrance") || StrEqual(objectName, "obj_teleporter_exit") || StrEqual(modelname, MODEL_SPIDER))
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
				if(closestObject != -1 && step == 2 && spiderHealth >= spiderMaxHealth)
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

public findClosestPlayerToGhost(spider, box, Float:spiderPosition[3], Float:traceRaySpiderPosition[3],spiderTeam, Float:rangeTolerance, Handle:dataPackHandle, spiderOwner)
{
	//LogToFile(logPath,"findClosestPlayer -- Entering");
	///////////////////////////////////////
	//    Find The Closest Player        //
	//                                   //
	//returns = player entity            //
	//returns = along with the distance  //
	//returns = and what team it was on  //
	///////////////////////////////////////
	
	new Float:playerDistances[MaxClients + 1][2];
	new Float:enemyPosition[3];
	new Float:endingRayPos[3];
	new Float:distance;
	new Float:foundRange;
	
	new closestPlayer = -1;
	new closestDistance;
	new closestPlayerTeam;
	
	///////////////////////////////////////////////////
	//medicPartner is the one player on the spider's //
	//team that receives the highest priority        //
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
			
			if(spiderOwner == i && GetClientTeam(i) == spiderTeam)
			{
				medicPartner = i;
				distance = 0.0;
			}
				
			//Heal the spider if client is a medic
			new maybeHealing = -1;
			if(maybeHealing != -1 && medicPartner == -1)
			{
				medicPartner = maybeHealing;
				distance = 1.0; 
			}
			
			//player is not cloaked | cloaked = 16
			if (distance < 1000.0 && !(GetEntProp(i, Prop_Send, "m_nPlayerCond")&16))
			{
				playerDistances[i-1][1] = distance;
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
	
public stopGhostThinkTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new ghost = ReadPackCell(dataPackHandle);
	new box = ReadPackCell(dataPackHandle);
	
	if(!GetConVarInt(c_Enabled))
		return true;
	
	if(!IsValidEntity(box))
		return true;
	
	new String:boxmodelname[128];
	GetEntPropString(box, Prop_Data, "m_ModelName", boxmodelname, 128);
	
	if(!IsValidEntity(ghost) && StrEqual(boxmodelname, MODEL_SPIDERBOX))
	{
		killEntityIn(box, 0.0);
		return true;
	}
	
	if(!IsValidEntity(ghost))
		return true;
	
	new String:modelname[128];
	GetEntPropString(ghost, Prop_Data, "m_ModelName", modelname, 128);
	
	
	if (!StrEqual(modelname, MODEL_GHOST) && !StrEqual(boxmodelname, MODEL_SPIDERBOX) )
	{
		return true;
	}
	
	return false;
}

public moveGhost_ToPoint(spider, box, spiderTeam, Float:spiderPosition[3], Float:closestDistance, Handle:dataPackHandle)
{
	SetPackPosition(dataPackHandle, 128);
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
	
	SetPackPosition(dataPackHandle, 112);
	new Float:baseSpeed = ReadPackFloat(dataPackHandle); // Ghost's base speed
	new Float:runSpeed = ReadPackFloat(dataPackHandle); // Ghost's running speed
	
	
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

public moveGhost(spider, box, spiderTeam, Float:spiderPosition[3], closestEntity, closestEntityTeam, Float:closestDistance, Handle:dataPackHandle)
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
	
	new Float:diffAng;
	new rotation;
	
	SetPackPosition(dataPackHandle, 112);
	new Float:baseSpeed = ReadPackFloat(dataPackHandle); // Ghost's base speed
	new Float:runSpeed = ReadPackFloat(dataPackHandle); // Ghost's running speed
	
	
	GetEntPropVector(box, Prop_Data, "m_vecOrigin", spiderPosition);
	
	if(closestEntity > MaxClients)
	{
		GetEntPropVector(closestEntity, Prop_Data, "m_vecOrigin", enemyAbsOrigin);
		enemyPosition[0] = enemyAbsOrigin[0];
		enemyPosition[1] = enemyAbsOrigin[1];
		enemyPosition[2] = enemyAbsOrigin[2] + 45.0;
		
		GetEntPropVector(closestEntity, Prop_Data, "m_angRotation", enemyAngle);
		enemyEyeAngle[0] = enemyAngle[0];
		enemyEyeAngle[1] = enemyAngle[1];
		enemyEyeAngle[2] = enemyAngle[2];
	}else{
		GetClientEyePosition(closestEntity, enemyPosition);
		GetClientAbsOrigin(closestEntity,enemyAbsOrigin);
		
		GetClientEyeAngles(closestEntity,enemyEyeAngle);
		GetClientAbsAngles(closestEntity,enemyAngle);
	}
	
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
		if(closestEntity < MaxClients)
		{
			speed[2] += 1.0;
		}
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
		
	//show the spider's angle
	//PrintToChatAll("0:%f 1:%f 2:%f",spiderAngle[0],spiderAngle[1], spiderAngle[2]);
	
	//LogToFile(logPath,"moveSpider -- Leaving");
}