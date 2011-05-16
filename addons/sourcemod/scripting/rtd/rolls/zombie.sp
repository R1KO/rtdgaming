#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

//////////////////////////////////////////////////////////
// Spawns a zombie that interacts with the environment  //
// lookinging for friendlies, enemies and 'waypoints'   //
//                                                      //
//////////////////////////////////////////////////////////

//Zombie animations
/*
 Walk:    1
 Idle01:  0
 attackA: 7
 attackB: 8
 attackC: 9
 attackD: 10
* */
//
public Action:Spawn_Zombie(client, typeofZombie)
{	
	//Types of Zombie
	//1 = Classic Zombie
	//2 = Classic torso
	//3 = Poison
	new maxHealth = 500;
	new health = 500;
	
	new box = CreateEntityByName("prop_physics_override");
	if ( box == -1 )
	{
		ReplyToCommand( client, "Failed to create a ZombieBox!" );
		return Plugin_Handled;
	}
	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Classic Zombie!" );
		return Plugin_Handled;
	}
	
	SetEntityModel(box, MODEL_SPIDERBOX);
	//SetEntityModel(box, MODEL_ZOMBIE_CLASSIC);
	if(typeofZombie == 1)
	{
		SetEntityModel(ent, MODEL_ZOMBIE_CLASSIC);
		maxHealth = 800;
		health = 800;
	}else if(typeofZombie ==2)
	{
		SetEntityModel(ent, MODEL_ZOMBIE_02);
		maxHealth = 600;
		health = 600;
	}else{
		SetEntityModel(ent, MODEL_ZOMBIE_03);
		maxHealth = 700;
		health = 700;
	}
	
	
	DispatchSpawn(ent);
	DispatchSpawn(box);
	
	
	//make sure to do this before we actually spawn the P.O.S.
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	SetEntProp(box, Prop_Data, "m_takedamage", 0);  //default = 2
	
	//Our 'sled' collision does not need to be rendered nor does it need shadows
	AcceptEntityInput( box, "DisableShadow" );
	SetEntityRenderMode(box, RENDER_NONE);
	
	//client that spawned this spider
	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
	
	//owner entity for the Box tells it its the Spider
	SetEntPropEnt(box, Prop_Data, "m_hOwnerEntity", ent);
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	
	SetEntProp( ent, Prop_Data, "m_nSolidType", 7 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 7 );
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 3);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 3);
	
	SetEntProp( box, Prop_Data, "m_nSolidType", 4 );
	SetEntProp( box, Prop_Send, "m_nSolidType", 4 );
	
	//Set the zombie's health
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", maxHealth);
	SetEntProp(ent, Prop_Data, "m_iHealth", health);
	
	SetEntProp(ent, Prop_Data, "m_PerformanceMode", 1);
	
	//argggh F.U. valve
	AcceptEntityInput( ent, "DisableCollision" );
	AcceptEntityInput( ent, "EnableCollision" );
	
	HookSingleEntityOutput(ent, "OnHealthChanged", zombie_Hurt, false);
	//HookSingleEntityOutput(ent, "OnTakeDamage", zombie_TakeDamage, false);
	HookSingleEntityOutput(ent, "OnBreak", zombie_Die, false);
	
	SetVariantString("idle01");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	new iTeam = GetClientTeam(client);
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
	//SetVariantString("idle01");
	//AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	
	//name the spider
	new String:boxName[128];
	Format(boxName, sizeof(boxName), "zombieclassic%i", ent);
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
	if(GetClientTeam(client) == RED_TEAM)
		SetVariantString(bluDamageFilter);
	
	if(GetClientTeam(client) == BLUE_TEAM)
		SetVariantString(redDamageFilter);
	
	AcceptEntityInput(ent, "SetDamageFilter", -1, -1, 0); 
	
	if(GetClientTeam(client) == RED_TEAM)
	{
		SetVariantString("255+150+150");
		AcceptEntityInput(ent, "color", -1, -1, 0);
	}
	else
	{
		SetVariantString("150+150+255");
		AcceptEntityInput(ent, "color", -1, -1, 0);
	}
	
	
	//The Datapack stores all the Spider's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, Zombie_Classic_Think_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, ent);   //PackPosition(0);  Enity Index
	WritePackCell(dataPackHandle, box);   //PackPosition(8);  Box (parent) index
	WritePackCell(dataPackHandle, iTeam); //PackPosition(16); Team
	WritePackFloat(dataPackHandle, 40.0); //PackPosition(24); The range tolerance
	WritePackCell(dataPackHandle, client);//PackPosition(32); Client that spawned it
	WritePackCell(dataPackHandle, GetEntProp(ent, Prop_Data, "m_iMaxHealth")); //PackPosition(40); Max Health
	WritePackCell(dataPackHandle, -1); 	 //PackPosition(48);  Player ID ubering NPC
	WritePackCell(dataPackHandle, -1); 	 //PackPosition(56);  Object entity that is the closest
	WritePackCell(dataPackHandle, -1); 	 //PackPosition(64);  Object teamnum that is closest
	WritePackCell(dataPackHandle, 1001); //PackPosition(72);  Object distance that is closest
	WritePackCell(dataPackHandle, -1); 	 //PackPosition(80);  Player entity that is the closest
	WritePackCell(dataPackHandle, -1); 	 //PackPosition(88);  Player teamnum that is closest
	WritePackCell(dataPackHandle, 1001); //PackPosition(96);  Playertdistance that is closest
	WritePackCell(dataPackHandle, -1); 	 //PackPosition(104); Is object closer or is the player closer?
	WritePackCell(dataPackHandle, -1); 	 //PackPosition(112); Particle Enity that belongs to NPC (zombies don't use these)
	WritePackCell(dataPackHandle, -1); 	 //PackPosition(120); Last player that the NPC was moving to
	/*
	if(annotation)
	{
		CreateAnnotation(ent, "Friendly ", 1, iTeam, 1, 1, box);
		CreateAnnotation(ent, "Enemy ", 2, iTeam, 1, 1, box);
	}*/
	
	return Plugin_Handled;
}

public zombie_Die (const String:output[], caller, activator, Float:delay)
{
	if(IsValidEntity(caller))
	{
		new parentBox = GetEntPropEnt(caller, Prop_Data, "m_pParent");
		if(IsValidEntity(parentBox))
			AcceptEntityInput(parentBox,"kill");
	}
}

public zombie_Hurt (const String:output[], caller, activator, Float:delay)
{
	if(IsValidEntity(caller))
	{
		//attach blood gibs
		new box = GetEntPropEnt(caller, Prop_Data, "m_pParent");
		if(IsValidEntity(box))
		{
			AttachTempParticle(box,"env_sawblood", 1.0, false,"",0.0, false);
		}
		
		if(GetEntProp(caller, Prop_Data, "m_iHealth") <= 100 && IsValidEntity(box))
		{
			SendObjectDestroyedEvent(activator, caller, "killedzombie");
			//show some chunky blood on death
			AttachTempParticle(caller,"blood_trail_red_01_goop", 1.0, false,"",0.0, false);
			
			AcceptEntityInput(caller,"BecomeRagdoll");
			
			//Let's reward the player for killing a Zombie
			new rndNum = GetRandomInt(0,20);
			if(rndNum > 10)
			{
				TF_SpawnMedipack(box, "item_healthkit_medium", true);
			}else{
				TF_SpawnMedipack(box, "item_ammopack_medium", true);
			}
			
			//AcceptEntityInput(box,"Kill");
			killEntityIn(box, 0.1);
			if(activator <= MaxClients && activator > 0)
			{
				ServerCommand("gameme_player_action %i zombie_kill",activator);
				//log_player_event(activator, "triggered", "zombie_kill");
			}
			
			UnhookSingleEntityOutput(caller, "OnHealthChanged", zombie_Hurt);
			
		}else{
			
			//play hurt sounds
			new rndNum = GetRandomInt(1,6);
			
			if(rndNum == 1)
				EmitSoundToAll(SOUND_ZOMBIE_PAIN_01,caller,_,SNDLEVEL_HELICOPTER);
			
			if(rndNum == 2)
				EmitSoundToAll(SOUND_ZOMBIE_PAIN_02,caller,_,SNDLEVEL_HELICOPTER);
			
			if(rndNum == 3)
				EmitSoundToAll(SOUND_ZOMBIE_PAIN_03,caller,_,SNDLEVEL_HELICOPTER);
			
			if(rndNum == 4)
				EmitSoundToAll(SOUND_ZOMBIE_PAIN_04,caller,_,SNDLEVEL_HELICOPTER);
			
			if(rndNum == 5)
				EmitSoundToAll(SOUND_ZOMBIE_PAIN_05,caller,_,SNDLEVEL_HELICOPTER);
			
			if(rndNum == 6)
				EmitSoundToAll(SOUND_ZOMBIE_PAIN_06,caller,_,SNDLEVEL_HELICOPTER);
				
			
			//EmitSoundToAll(SOUND_ZOMBIE_STRIKE_01,activator,_,SNDLEVEL_HELICOPTER);
			
		}
	}
}

public Action:Zombie_Classic_Think_Timer(Handle:timer, Handle:dataPackHandle)
{
	//LogToFile(logPath,"Zombie_Classic_Think_Timer -- Entering = %f",GetEngineTime());
	
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
	if(stopZombieClassicThinkTimer(dataPackHandle))
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
	
	if(spiderOwner != -1)
	{	
		if(IsClientInGame(spiderOwner))
		{
			if(GetClientTeam(spiderOwner) != spiderTeam)
			{
				spiderOwner = -1;
				SetPackPosition(dataPackHandle, 32);
				WritePackCell(dataPackHandle, spiderOwner);
				
				SetEntPropEnt(spider, Prop_Data, "m_hOwnerEntity", spiderOwner);
			}
		}else{
			spiderOwner = -1;
			SetPackPosition(dataPackHandle, 32);
			WritePackCell(dataPackHandle, spiderOwner);
			
			SetEntPropEnt(spider, Prop_Data, "m_hOwnerEntity", spiderOwner);
		}
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
		SetPackPosition(dataPackHandle, 120);
		WritePackCell(dataPackHandle, closestEntity);
	}
	
	processOtherSounds(spider, spiderTeam, closestEntity, closestDistance, closestEntityTeam);
	
	/////////////////////////////////////////////////////////////////////////////////
	//Because I was unable to get melee or the flamethrower to register correctly  //
	//I had to add this check to see if a player has that weapon out and is        //
	//currently firing at the NPC. Dirty hack ye  :(                               //
	/////////////////////////////////////////////////////////////////////////////////
	new Float:clientEyeOrigin[3];
	new Float:zombieOrigin[3];
	new Float:traceEndPos[3];
	new Float:foundRange;
	new Float:distance;
	
	GetEntPropVector(box, Prop_Send, "m_vecOrigin", zombieOrigin);
	zombieOrigin[2] += 25.0;
	
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if(GetEntProp(spider, Prop_Data, "m_iTeamNum") == GetClientTeam(i))
			continue;
		
		if(GetClientButtons(i) & IN_ATTACK)
		{
			new iWeapon = GetEntDataEnt2(i, FindSendPropInfo("CTFPlayer", "m_hActiveWeapon"));
			new String:classname[64];
			if(IsValidEntity(iWeapon))
			{
				GetEdictClassname(iWeapon, classname, 64);
				//PrintToChatAll("%s",classname);
				
				if(StrEqual(classname, "tf_weapon_bat_wood") || 
					StrEqual(classname, "tf_weapon_shovel") ||
					StrEqual(classname, "tf_weapon_fireaxe") ||
					StrEqual(classname, "tf_weapon_bottle") ||
					StrEqual(classname, "tf_weapon_fists") ||
					StrEqual(classname, "tf_weapon_wrench") ||
					StrEqual(classname, "tf_weapon_bonesaw") ||
					StrEqual(classname, "tf_weapon_club") ||
					StrEqual(classname, "tf_weapon_knife") ||
					StrEqual(classname, "tf_weapon_flamethrower")) 
				{
					GetClientEyePosition(i, clientEyeOrigin);
					
					//begin our trace from our main spider to the found buildable
					new Handle:Trace = TR_TraceRayFilterEx(zombieOrigin, clientEyeOrigin, MASK_SOLID, RayType_EndPoint, TraceFilterAll, spider);
					TR_GetEndPosition(traceEndPos, Trace);
					CloseHandle(Trace);
					
					foundRange = GetVectorDistance(clientEyeOrigin,traceEndPos);
					
					//Was the trace close to a buildable? If not the let's shoot from this buildable
					//back to our main spider. This makes sure that none of the entites saw each other
					if(foundRange > 35.0)
					{
						Trace = TR_TraceRayFilterEx(clientEyeOrigin, zombieOrigin, MASK_SOLID, RayType_EndPoint, TraceFilterAll, i);
						TR_GetEndPosition(traceEndPos, Trace);
						CloseHandle(Trace);
						
						//did the player see a building?
						foundRange = GetVectorDistance(zombieOrigin, traceEndPos);
					}
					
					distance = GetVectorDistance(clientEyeOrigin,zombieOrigin);
					//PrintToChatAll("distance: %f",distance);
					if(foundRange < 35.0 && distance < 100.0)
					{
						new lookingAt = -1;
						lookingAt = GetClientAimTarget(i, false);
						
						if(lookingAt == spider)
						{
							if(StrEqual(classname, "tf_weapon_flamethrower"))
							{
								DealDamage(spider,6,i,16779264,"zombie");
							}else{
								DealDamage(spider,8,i,16779264,"zombie");
							}
						}
					}
				}
			}
		}
	}
	
	////////////////////////////////
	//Determine Monster movement  //
	////////////////////////////////
	if(closestEntity == -1 || closestDistance < 80.0 && closestEntityTeam == spiderTeam)
	{
		
		//determine spider interactions with objects
		if(closestEntity != -1)
			findSpiderTouch(spider, closestEntity);
		
		new currIndex = GetEntProp(spider, Prop_Data, "m_nModelIndex");
		
		//The spider was running before now let's just wait
		new isFinished = GetEntProp(spider, Prop_Data, "m_bSequenceFinished");
		
		if(isFinished)
		{
			if(currIndex == zombieModelIndex[0] || currIndex == zombieModelIndex[1])
			{
				if(GetEntProp(spider, Prop_Data, "m_nSequence") != 0)
				{
					SetVariantString("idle01");
					AcceptEntityInput(spider, "SetAnimation", -1, -1, 0); 
				}
			}
			
			if(currIndex == zombieModelIndex[2])
			{
				//idle01: 1
				//walk:  3
				//melee_01:  7
				
				if(GetEntProp(spider, Prop_Data, "m_nSequence") != 1)
				{
					SetVariantString("idle01");
					AcceptEntityInput(spider, "SetAnimation", -1, -1, 0); 
				}
			}
		}
	}else{
		//move towards entity
		moveZombie(spider, box, spiderTeam, spiderPosition, closestEntity, closestEntityTeam, closestDistance, dataPackHandle);
	}
	
	////////////////////////////////////////////////
	//Woot we're done with the NPC for this pass  //
	////////////////////////////////////////////////
	//LogToFile(logPath,"Zombie_Classic_Think_Timer -- Leaving = %f",GetEngineTime());
	return Plugin_Continue;
}
	
public stopZombieClassicThinkTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new spider = ReadPackCell(dataPackHandle);
	new box = ReadPackCell(dataPackHandle);
	
	if(!GetConVarInt(c_Enabled))
		return true;
	
	if(!IsValidEntity(spider) || !IsValidEntity(box))
	{	
		return true;
	}
	
	new String:modelname[128];
	new String:boxmodelname[128];
	GetEntPropString(spider, Prop_Data, "m_ModelName", modelname, 128);
	GetEntPropString(box, Prop_Data, "m_ModelName", boxmodelname, 128);
	
	if (!StrEqual(boxmodelname, MODEL_SPIDERBOX) )
	{	
		//LogToFile(logPath,"Killing stopZombieClassicThinkTimer handle! Reason: Invalid Model");
		return true;
	}
	
	if(GetEntProp(spider, Prop_Data, "m_iHealth") <= 100)
	{
		//LogToFile(logPath,"Killing Zombie_Think handle! Reason: Zombie is dead");
		return true;
	}
	
	return false;
}

public moveZombie(spider, box, spiderTeam, Float:spiderPosition[3], closestEntity, closestEntityTeam, Float:closestDistance, Handle:dataPackHandle)
{
	//LogToFile(logPath,"moveSpider -- Entering");
	///////////////////////////////////////////////////
	//            ABOUT ZOMBIE MOVEMENT               //
	//------------------------------------------------//
	// Here the zombie moves towards the closest      //
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
	
	//new Float: facingZAngle;
	//new Float: tempSpiderPos[3];
	//new Float: tempEnemyPos[3];
	//new Float: hypotenuse;
	//new Float: adjacent;
	
	new Float:diffAng;
	new rotation;
	
	//new TFClassType:class;
	//new DisguiseTeam;
	new bool:isWalking = true;
	
	new Float:baseSpeed = 135.0; // Spider's base speed
	new Float:runSpeed  = 190.0; // Spider's running speed
	new Float:attackingDistance = 80.0; //distance the zombie will start attacking
	
	new isFinished = GetEntProp(spider, Prop_Data, "m_bSequenceFinished");
	new sequence = GetEntProp(spider, Prop_Data, "m_nSequence");
	new currIndex = GetEntProp(spider, Prop_Data, "m_nModelIndex");
	
	if(closestEntity > MaxClients)
	{
		//Special Case for Spiders
		new String:modelname[128];
		GetEntPropString(closestEntity, Prop_Data, "m_ModelName", modelname, 128);
		
		if (StrEqual(modelname, MODEL_ZOMBIE_CLASSIC) || StrEqual(modelname, MODEL_ZOMBIE_02) || StrEqual(modelname, MODEL_ZOMBIE_03))
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
		spiderAngle[1] += (18.0 * rotation);
	
	//Spider is pretty close to facing the enemy
	if(diffAng > 5.0 && diffAng < 10.0)
		spiderAngle[1] += (4.0 * rotation);
	
	new damageAmount;
	
	if(closestEntity <= MaxClients)
	{
		damageAmount = GetRandomInt(10,30);
	}else{
		damageAmount = GetRandomInt(10,25);
	}
	
	//The enemy is close enough so damage can be applied
	new Float:zombieOrigin[3];
	new Float:clientOrigin[3];
	new Float:absoluteDistance;
	GetEntPropVector(closestEntity, Prop_Send, "m_vecOrigin", clientOrigin);
	GetEntPropVector(box, Prop_Send, "m_vecOrigin", zombieOrigin);
	absoluteDistance = GetVectorDistance(clientOrigin,zombieOrigin);
	
	if(diffAng < 50.0 && closestDistance < attackingDistance &&  GetEntProp(closestEntity, Prop_Data, "m_iTeamNum")!= spiderTeam && absoluteDistance < 100.0)
	{
		//no need to move any closer we are already attacking!
		baseSpeed = 70.0;
		
		isWalking = false;
		
		if(currIndex == zombieModelIndex[0])
		{
			if(sequence >= 0 && sequence <= 4)
			{
				//attackA: 7
				//attackB:  8	
				//attackC:  9
				//attackD:  10
				//attackE:  11
				//attackF:  12
				//swatrightlow:  16
				
				new randAnim = GetRandomInt(1,7);
				
				switch(randAnim)
				{
					case 1:
						SetVariantString("attackA");
						
					case 2:
						SetVariantString("attackB");
					
					case 3:
						SetVariantString("attackC");
					
					case 4:
						SetVariantString("attackD");
					
					case 5:
						SetVariantString("attackE");
					
					case 6:
						SetVariantString("attackF");
					
					case 7:
						SetVariantString("swatrightlow");
					
				}
				AcceptEntityInput(spider, "SetAnimation");
				
				
				new attacker = GetEntPropEnt(spider, Prop_Data, "m_hLastAttacker");
				DealDamage(closestEntity,damageAmount,attacker,4226,"zombie");
				
				EmitSoundToAll(SOUND_ZOMBIE_MISS_01,spider);
				
			}
		}
		
		else if(currIndex == zombieModelIndex[1])
		{
			//Crawl: 2
			//attack:  3
			//idle01:  0
			if(sequence == 0 || sequence == 2 )
			{
				SetVariantString("attack");
				AcceptEntityInput(spider, "SetAnimation");
				
				new attacker = GetEntPropEnt(spider, Prop_Data, "m_hLastAttacker");
				DealDamage(closestEntity,damageAmount,attacker,4226,"zombie");
			}
		}
		
		else if(currIndex == zombieModelIndex[2])
		{
			//idle01: 1
			//walk:  3
			//melee_01:  7
			
			if(sequence == 1 || sequence == 3 )
			{
				SetVariantString("melee_01");
				AcceptEntityInput(spider, "SetAnimation");
				
				new attacker = GetEntPropEnt(spider, Prop_Data, "m_hLastAttacker");
				DealDamage(closestEntity,damageAmount,attacker,4226,"zombie");
			}
		}
		
		//Makes sure to only apply damage to enemies. This allows the spider to flame
		//a disguised spy but not hurt him..THUS fooling others  :D
		if(spiderTeam != closestEntityTeam)
		{	
			//Apply damage
			if(closestEntity <= MaxClients)
			{
				if(!client_rolls[closestEntity][AWARD_G_GODMODE][0])
				{
					if(GetEntProp(closestEntity, Prop_Send, "m_nPlayerCond")&32)
					{
						//Dont hurt the friendly disguised spies
						//PrintToChatAll("bypassing!");
					}else{
						if(GetClientHealth(closestEntity) <= 20)
						{
							//hooray sounds
							new rndNum = GetRandomInt(0,5);
								
							if(rndNum == 0)
								EmitSoundToAll(SOUND_SPIDERKILL01,spider,_,_,_,_,50);
									
							if(rndNum == 1)
								EmitSoundToAll(SOUND_SPIDERKILL02,spider,_,_,_,_,50);
								
							if(rndNum == 2)
								EmitSoundToAll(SOUND_SPIDERKILL03,spider,_,_,_,_,50);
								
							if(rndNum == 3)
								EmitSoundToAll(SOUND_SPIDERKILL04,spider,_,_,_,_,50);
								
							if(rndNum == 4)
								EmitSoundToAll(SOUND_SPIDERKILL05,spider,_,_,_,_,50);
						}
						
						new spiderSounds = GetEntProp(spider, Prop_Data, "m_PerformanceMode");
						//laugh while hurting enemy
						if(GetClientHealth(closestEntity) > 20 && spiderSounds == 1)
						{
							//hooray sounds
							new rndNum = GetRandomInt(0,5);
								
							if(rndNum == 0)
								EmitSoundToAll(SOUND_SPIDERLAUGH01,spider,_,_,_,_,50);
									
							if(rndNum == 1)
								EmitSoundToAll(SOUND_SPIDERLAUGH02,spider,_,_,_,_,50);
								
							if(rndNum == 2)
								EmitSoundToAll(SOUND_SPIDERLAUGH03,spider,_,_,_,_,50);
							
							SetEntProp(spider, Prop_Data, "m_PerformanceMode", 0);
							CreateTimer(1.0, SphereSoundRdy, spider);
							spiderSounds = 0;
						}
						
						//DealDamage(closestEntity,RoundFloat((attackingDistance-closestDistance)/30.0),spider,4226,"tf_weapon_flamethrower");
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
	
	//The monster needs to play WALK animation
	if(currIndex == zombieModelIndex[0])
	{
		if(sequence != 1 && isFinished || sequence != 1 && isWalking && isFinished ||
			sequence != 2 && isFinished || sequence != 2 && isWalking && isFinished ||
			sequence != 3 && isFinished || sequence != 3 && isWalking && isFinished ||
			sequence != 4 && isFinished || sequence != 4 && isWalking && isFinished )
		{
			//walk:  1
			//walk2:  2
			//walk3:  3
			//walk4:  4
			
			new randWalk = GetRandomInt(1,4);
			
			if(randWalk == 1)
				SetVariantString("walk");
			
			if(randWalk == 2)
				SetVariantString("walk2");
			
			if(randWalk == 3)
				SetVariantString("walk3");
			
			if(randWalk == 4)
				SetVariantString("walk4");
			
			AcceptEntityInput(spider, "SetAnimation", -1, -1, 0);
		}
	}
	
	//PrintToChatAll("Sequence:%i | isFinisehd:%i | isWalking:%i",sequence,isFinished,isWalking);
	if(currIndex == zombieModelIndex[1])
	{
		//Crawl: 2
		//attack:  3
		//idle01:  0
		if(sequence != 2 && isFinished || sequence != 2 && isWalking)
		{	
			SetVariantString("crawl");
			AcceptEntityInput(spider, "SetAnimation", -1, -1, 0);
		}
	}
	
	if(currIndex == zombieModelIndex[2])
	{
		//idle01: 1
		//walk:  3
		//melee_01:  7
		if(sequence != 3 && isFinished || sequence != 3  && isWalking)
		{	
			SetVariantString("walk");
			AcceptEntityInput(spider, "SetAnimation", -1, -1, 0);
		}
	}
	
	//spiderAngle[0] += facingZAngle;
		
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
	
	if(floorDistance < 4.0)
		speed[2]+=0.55;
	
	if(floorDistance >= 4.0 && floorDistance < 9.0)
		speed[2]+=0.4;
	
	if(floorDistance >= 9.0)
		speed[2]-=1.0;	
	
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