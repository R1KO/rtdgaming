#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>

stock bool:IsEntLimitReached()
{
	
	new maxents = GetMaxEntities();
	new i, c = 0;
	
	for(i = MaxClients; i <= maxents; i++)
	{
	 	if(IsValidEntity(i) || IsValidEdict(i))
			c += 1;
		
	}
	
	//PrintToChatAll("%Ent Count: %i", c);
	//PrintToServer("Found: %i | GetEntityCount: %i", c, GetEntityCount());
	
	if (c >= (maxents-450))
	{
		//PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
		//LogError("Entity limit is nearly reached: %d/%d", c, maxents);
		return true;
	}
	else
		return false;
}

public killEntityIn(entity, Float:seconds)
{
	if(IsValidEdict(entity))
	{
		// send "kill" event to the event queue
		new String:addoutput[64];
		Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::%f:1",seconds);
		SetVariantString(addoutput);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
}

public TeleportPlayerToReticle(adminClient, targetClient)
{
    decl Float:adminOrigin[3];
    GetClientEyePosition(adminClient,adminOrigin);
    decl Float:adminAngles[3];
    GetClientEyeAngles(adminClient, adminAngles);
    new Handle:trace = TR_TraceRayFilterEx(adminOrigin, adminAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
    if(TR_DidHit(trace))
    {        
        decl Float:endPos[3];
        TR_GetEndPosition(endPos, trace);
        new Float:tempDist = GetVectorDistance(adminOrigin, endPos, false);
        tempDist -= 30.0;
        endPos[0] = adminOrigin[0] + tempDist*Cosine(DegToRad(adminAngles[1]));
        endPos[1] = adminOrigin[1] + tempDist*Sine(DegToRad(adminAngles[1]));
        decl Float:playerMins[] = {-25.0, -25.0, 0.0};
        decl Float:playerMaxs[] = {25.0, 25.0, 0.0};
        CloseHandle(trace);
        decl Float:endPosTop[3];
        endPosTop = endPos;
        endPosTop[2] += 83.0;
        trace = TR_TraceHullFilterEx(endPos,endPosTop,playerMins,playerMaxs,MASK_PLAYERSOLID,TraceEntityFilterPlayer);
        if(!TR_DidHit(trace))
        {
            new Float:zeroVec[3];
            TeleportEntity(targetClient,endPos,NULL_VECTOR,zeroVec);
        }
        else
        {
            //OpenToPage(adminClient, x);
        }
    }
    CloseHandle(trace);
}

public CloseToEnemySpawnDoors(client)
{
	if(!IsClientConnected(client))
		return true;
	
	if(!IsPlayerAlive(client))
		return true;
	
	new Float:playerOrigin[3];
	new Float:playerEyes[3];
	new Float:objectPos[3];
	new Float:distance;
	
	GetClientAbsOrigin(client, playerOrigin);
	GetClientEyePosition(client, playerEyes);
	
	new foundObjectEnt = -1;
	while ((foundObjectEnt = FindEntityByClassname(foundObjectEnt, "func_respawnroomvisualizer")) != -1) 
	{	
		GetEntPropVector(foundObjectEnt, Prop_Data, "m_vecOrigin", objectPos);
		distance = GetVectorDistance(playerEyes,objectPos);
		
		//Is the func_respawnroomvisualizer even close enough to be bothered with?
		if(distance < 300.0)
		{
			if(GetClientTeam(client) != GetEntProp(foundObjectEnt, Prop_Data, "m_iTeamNum"))
			{
				PrintCenterText(client, "Too close to enemy Spawn");
				return true;
			}
		}
		
		distance = GetVectorDistance(playerOrigin,objectPos);
		
		//Is the func_respawnroomvisualizer even close enough to be bothered with?
		if(distance < 300.0)
		{
			if(GetClientTeam(client) != GetEntProp(foundObjectEnt, Prop_Data, "m_iTeamNum"))
			{
				PrintCenterText(client, "Too close to enemy Spawn");
				return true;
			}
		}
	}
	
	return false;
	
}

public OnEntityCreated(entity, const String:classname[])
{
	// The algorithm must be done next frame so that the entity is fully spawned
	CreateTimer(0.0, ProcessEdict, entity, TIMER_FLAG_NO_MAPCHANGE);
	
	return;
}

public OnEntityDestroyed(entity)
{
	if(!IsValidEdict(entity))
		return;
	
	if(!IsValidEntity(entity))
		return;
	
	new currIndex = GetEntProp(entity, Prop_Data, "m_nModelIndex");
	
	if(currIndex == sliceModelIndex)
		StopSound(entity, SNDCHAN_AUTO, SOUND_SLICE);
	
	if(currIndex == sawModelIndex)
		StopSound(entity, SNDCHAN_AUTO, SOUND_SAW);
	
	if(currIndex == strengthModelIndex[0] || currIndex == strengthModelIndex[1])
		StopSound(entity, SNDCHAN_AUTO, SlowCube_Idle);
	
}

public Action:ProcessEdict(Handle:timer, any:edict)
{
	//This is to dissolve player ragdolls that have feigned death
	if (!IsValidEdict(edict))
		return Plugin_Handled;
		
	new String:netclassname[64];
	GetEntityNetClass(edict, netclassname, sizeof(netclassname));
	//PrintToChatAll("%s", netclassname);
	
	if(StrEqual("CTFRagdoll", netclassname))
	{
		
		new owner = GetEntProp(edict, Prop_Send, "m_iPlayerIndex"); 
		
		//only allow ragdoll for actual players
		if(owner >= cMaxClients)
			return Plugin_Handled;
		
		if(IsClientInGame(owner) && IsValidEntity(owner))
		{
			//We only want Spy's
			if(TF2_GetPlayerClass(owner) != TFClass_Spy)
				return Plugin_Handled;
			
			//PrintToChatAll("owner: %i | lastAttackerOnPlayer: %i",owner, lastAttackerOnPlayer[owner]);
			
			//the last attacker must have been some other player
			if(!IsValidEntity(lastAttackerOnPlayer[owner]) || lastAttackerOnPlayer[owner] < 1 || lastAttackerOnPlayer[owner] > 32)
				return Plugin_Handled;
			
			
			//The Last Attacker must still be in game
			if(IsClientInGame(lastAttackerOnPlayer[owner]))
			{
				//The last attacker must have ragdoll disolves turned on
				if(RTDOptions[lastAttackerOnPlayer[owner]][4])
				{
					new String:dname[32], String:dtype[32];
					Format(dname, sizeof(dname), "dis_%d", edict);
					Format(dtype, sizeof(dtype), "%d", 0);
					
					//Disregard if attacker is using Enternal Reward
					if(isPlayerHolding_UniqueWeapon(lastAttackerOnPlayer[owner], 225))
						return Plugin_Handled;
					
					new ent = CreateEntityByName("env_entity_dissolver");
					if (ent>0)
					{
						DispatchKeyValue(edict, "targetname", dname);
						DispatchKeyValue(ent, "dissolvetype", dtype);
						DispatchKeyValue(ent, "target", dname);
						AcceptEntityInput(ent, "Dissolve");
						AcceptEntityInput(ent, "kill");
						
						return Plugin_Handled;
					}
				}
			}
		}
	}else if(StrEqual("CCaptureFlag", netclassname))
	{
		HookSingleEntityOutput(edict, "OnPickUp", onFlagPickup, false);
		return Plugin_Handled;
	}else if(StrEqual("CObjectSentrygun", netclassname) || StrEqual("CObjectDispenser", netclassname) || StrEqual("CObjectTeleporter", netclassname))
	{
		SDKHook(edict,	SDKHook_OnTakeDamage, 	ObjectTakeDamage);
		
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}


public Action:deleteRTDEntities()
{
	//Delete all active RTD elements, that are prop_dynamics or prop_physics
	//Remove any models that might carry over next map
	new ent = -1;
	new String:modelname[128];
	
	while ((ent = FindEntityByClassname(ent, "prop_dynamic")) != -1)
	{	
		new currIndex = GetEntProp(ent, Prop_Data, "m_nModelIndex");
		
		if(currIndex == mineModelIndex)
		{
			killEntityIn(ent, 2.0); 
			continue;
		}
		
		if(currIndex == backpackModelIndex[0] || currIndex == backpackModelIndex[1] || currIndex == backpackModelIndex[2] || currIndex == backpackModelIndex[3])
		{
			if(!roundEnded)
			{
				killEntityIn(ent, 1.0);
				continue;
			}
		}
		
		if(currIndex == blizzardModelIndex[0] || currIndex == blizzardModelIndex[1])
		{
			if(!roundEnded)
			{
				killEntityIn(ent, 2.0);
				continue;
			}
		}
		
		if(currIndex == diceDepositModelIndex)
		{
			killEntityIn(ent, 2.0);
			continue;
		}
		
		if(currIndex == dugTrioModelIndex)
		{
			killEntityIn(ent, 2.0);
			continue;
		}
		
		if(currIndex == diglettModelIndex)
		{
			killEntityIn(ent, 2.0);
			continue;
		}
		
		if(currIndex == bearTrapModelIndex)
		{
			killEntityIn(ent, 2.0);
			continue;
		}
		
		if(currIndex == dummyModelIndex)
		{
			killEntityIn(ent, 2.0);
			continue;
		}
		
		if(currIndex == amplifierModelIndex)
		{
			StopSound(ent, SNDCHAN_AUTO, SOUND_AMPLIFIER_HUM);
			StopSound(ent, SNDCHAN_AUTO, SOUND_AMPLIFIER_HUM_02);
			killEntityIn(ent, 2.0);
			continue;
		}
		
		if(currIndex == instaPorterModelIndex)
		{
			StopSound(ent, SNDCHAN_AUTO, SOUND_INSTAPORT);
			StopSound(ent, SNDCHAN_AUTO, SOUND_INSTAPORT);
			
			killEntityIn(ent, 2.0);
			continue;
		}
		
		
		if(currIndex == cloudIndex || currIndex == cloud02Index)
		{
			StopSound(ent, SNDCHAN_AUTO, SOUND_RAIN);
			killEntityIn(ent, 2.0);
			continue;
		}
		
		GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 128);
		if (StrEqual(modelname, MODEL_SPIDER))
		{
			new String:classname[256];
			new owner = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");
			new box = GetEntPropEnt(ent, Prop_Data, "m_pParent");
			
			//Check to see if the fire particle entity is valid
			if(IsValidEntity(owner) && IsValidEdict(owner))
			{
				GetEdictClassname(owner, classname, sizeof(classname));
				if (StrEqual(classname, "info_particle_system", false))
				{
					StopSound(ent, SNDCHAN_AUTO, SOUND_FlameLoop);
					StopSound(owner, SNDCHAN_AUTO, SOUND_FlameLoop);
					StopSound(ent, SNDCHAN_AUTO, SOUND_SpiderTurn);
					StopSound(owner, SNDCHAN_AUTO, SOUND_SpiderTurn);
					
					killEntityIn(owner, 1.0);
				}
			}
			
			StopSound(ent, SNDCHAN_AUTO, SOUND_FlameLoop);
			StopSound(ent, SNDCHAN_AUTO, SOUND_SpiderTurn);
			
			UnhookSingleEntityOutput(ent, "OnTakeDamage", spider_Hurt);
			
			//And lastly....
			//Check to see if the box is a valid entity
			if(IsValidEntity(box))
				killEntityIn(box, 1.0);
		}
		if (StrEqual(modelname, MODEL_SPIDERBACK) && !roundEnded)
		{
			CDetach(ent);
			StopSound(ent, SNDCHAN_AUTO, SOUND_SpiderTurn);
			UnhookSingleEntityOutput(ent, "OnTakeDamage", spider_Hurt);
			killEntityIn(ent, 2.0);
			continue;
		}
		
		if (StrEqual(modelname, MODEL_COW))
		{
			new box = GetEntPropEnt(ent, Prop_Data, "m_pParent");
			if(IsValidEntity(box))
			{
				killEntityIn(box, 2.0);
			}
			
			continue;
		}
		
		if (StrEqual(modelname, MODEL_COWONBACK) && !roundEnded)
		{
			CDetach(ent);
			killEntityIn(ent, 2.0);
			
			continue;
		}
		
		if (StrEqual(modelname, MODEL_MILKBOTTLE))
		{
			killEntityIn(ent, 2.0);
			continue;
		}
		
		if (StrEqual(modelname, MDL_JUMP) || StrEqual(modelname, MODEL_HASTEBANNER) || StrEqual(modelname, MODEL_GROOVITRON) ||
			StrEqual(modelname, MODEL_ICE) || StrEqual(modelname, MODEL_SLOWCUBE) ||
			StrEqual(modelname, MODEL_ACCELERATOR) || StrEqual(modelname, MDL_JUMP) || StrEqual(modelname, MODEL_BRAZIER))
		{
			new box = GetEntPropEnt(ent, Prop_Data, "m_pParent");
			if(IsValidEntity(box))
				killEntityIn(box, 1.0);
			
			StopSound(ent, SNDCHAN_AUTO, SOUND_GROOVITRON);
			StopSound(ent, SNDCHAN_AUTO, SOUND_ICE);
			StopSound(ent, SNDCHAN_AUTO, SlowCube_Idle);
			StopSound(ent, SNDCHAN_AUTO, SOUND_CRAPIDLE);
			StopSound(ent, SNDCHAN_AUTO, SOUND_BRAZIER);
			
			for (new i = 1; i <= MaxClients ; i++)
			{
				inIce[i] = false;
				if(!IsClientInGame(i) || !IsPlayerAlive(i))
				{
					continue;
				}
				
				inIce[i] = false;
				SetEntityGravity(i, 1.0);
				ResetClientSpeed(i);
			}
			
			killEntityIn(ent, 2.0);
		}
		
		if (StrEqual(modelname, MODEL_SAW))
		{
			StopSound(ent, SNDCHAN_AUTO, SOUND_SAW);
			killEntityIn(ent, 0.1);
		}
		
		if(currIndex == wingsModelIndex || currIndex == redbullModelIndex)
		{
			killEntityIn(ent, 2.0); 
			continue;
		}
		
		if(currIndex == stonewallModelIndex[0] || currIndex == stonewallModelIndex[1])
		{
			SetEntProp(ent, Prop_Data, "m_PerformanceMode", 66);
			killEntityIn(ent, 2.0); 
			continue;
		}
		
		if(currIndex == angelicModelIndex)
		{
			SetEntProp(ent, Prop_Data, "m_PerformanceMode", 66);
			
			StopSound(ent, SNDCHAN_AUTO, SOUND_FLAP);
			
			killEntityIn(ent, 2.0); 
			continue;
		}
		
		for (new i = 0; i <= totModels ; i++)
		{
			if(currIndex == modelIndex[i])
			{
				StopSound(ent, SNDCHAN_AUTO, SOUND_FlameLoop);
				killEntityIn(ent, 2.0); 
				continue;
			}
		}
		
	}
	
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "prop_physics")) != -1)
	{
		new currIndex = GetEntProp(ent, Prop_Data, "m_nModelIndex");
		
		GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 128);
		
		if (StrEqual(modelname, MODEL_SPIDERBOX) || StrEqual(modelname, MODEL_BOMB) || StrEqual(modelname, MODEL_ICE) || StrEqual(modelname, MODEL_CRAP) || StrEqual(modelname, MODEL_BRAZIER))
		{
			StopSound(ent, SNDCHAN_AUTO, SOUND_CRAPIDLE);
			StopSound(ent, SNDCHAN_AUTO, SOUND_BRAZIER);
			killEntityIn(ent, 0.1);
		}
		
		if (StrEqual(modelname, MODEL_SNORLAX))
		{
			StopSound(ent, SNDCHAN_AUTO, SOUND_SNORLAX);
			killEntityIn(ent, 0.1);
		}
		
		if(StrEqual(modelname, MODEL_DICEDEPOSIT))
		{
			killEntityIn(ent, 2.0);
			continue;
		}
		
		for (new i = 0; i <= totModels ; i++)
		{
			if(currIndex == modelIndex[i])
			{
				killEntityIn(ent, 2.0); 
				continue;
			}
		}
	}
	
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "info_particle_system")) != -1)
	{
		
		GetEntPropString(ent, Prop_Data, "m_iszEffectName", modelname, 128);
		
		if(GetEntProp(ent, Prop_Data, "m_iHealth") == 691 && StrEqual(modelname, "flamethrower"))
		{
			StopSound(ent, SNDCHAN_AUTO, SOUND_FlameLoop);
			killEntityIn(ent, 2.0);
		}
		if(GetEntProp(ent, Prop_Data, "m_iHealth") == 691 && StrEqual(modelname, "main_heatwaver_constant1"))
		{
			killEntityIn(ent, 2.0);
		}
	}
	
	//Rollback Slowcube effects
	for (new i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i))
		{
			if(beingSlowCubed[i])
			{
				inSlowCube[i] = 0;
				beingSlowCubed[i] = 0;
				ResetClientSpeed(i);
				SetEntityGravity(i, 1.0);
			}
		}
	}
}

public Action:deleteAttachedRTDEntities()
{
	//Delete all active RTD elements, that are Shields or Props
	//Should only be used on late load
	new entity = -1;
	new String:modelname[128];
	
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1)
	{
		decl String:targetname[32];
		GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
		
		GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, 128);
		
		//delete all shields and props
		if(StrEqual(modelname, MODEL_DICE) || StrEqual(modelname, MODEL_MEDIRAY))
		{
			killEntityIn(entity, 1.0);
		}
	}
	
	entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_physics")) != -1)
	{	
		new currIndex = GetEntProp(entity, Prop_Data, "m_nModelIndex");
		
		if(currIndex == cageModelIndex)
		{
			killEntityIn(entity, 1.0);
		}
	}
}

public Action:Dissolve(Handle:timer, any:client)
{
	if (!IsValidEntity(client) || !IsClientInGame(client))
		return;
	
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll<0)
	{
		PrintToServer("[DISSOLVE] Could not get ragdoll for player!");  
		return;
	}
	
	new String:dname[32], String:dtype[32];
	Format(dname, sizeof(dname), "dis_%d", client);
	Format(dtype, sizeof(dtype), "%d", 0);
	
	new ent = CreateEntityByName("env_entity_dissolver");
	if (ent>0)
	{
		DispatchKeyValue(ragdoll, "targetname", dname);
		DispatchKeyValue(ent, "dissolvetype", dtype);
		DispatchKeyValue(ent, "target", dname);
		AcceptEntityInput(ent, "Dissolve");
		AcceptEntityInput(ent, "kill");
	}
}

public isClientOwnerOf(client, String:modelname[])
{
	new owner;
	new ent = -1;
	new String:foundmodelname[128];
	
	while ((ent = FindEntityByClassname(ent, "prop_dynamic")) != -1)
	{	
		GetEntPropString(ent, Prop_Data, "m_ModelName", foundmodelname, 128);
		
		if(StrEqual(foundmodelname, modelname, true))
		{
			owner = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");
			if(client == owner)
				return 1;
		}
	}
	
	return -1;
}

public teleportToOwner(client)
{
	//---duke tf2nades
	// get position and angles
	new Float:gnSpeed = 700.0;
	new Float:startpt[3];
	GetClientEyePosition(client, startpt);
	new Float:angle[3];
	new Float:speed[3];
	new Float:playerspeed[3];
	GetClientEyeAngles(client, angle);
	GetAngleVectors(angle, speed, NULL_VECTOR, NULL_VECTOR);
	speed[2] += 0.2;
	speed[0]*=gnSpeed; speed[1]*=gnSpeed; speed[2]*=gnSpeed;
	
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
	AddVectors(speed, playerspeed, speed);
	
	angle[0] = 0.0;
	angle[1] = GetRandomFloat(-180.0, 180.0);
	angle[2] = GetRandomFloat(-180.0, 180.0);
	//////////////////////////////
	
	new owner;
	new ent = -1;
	
	new currIndex;
	new iTeam;
	new playerTeam;
	
	playerTeam = GetEntProp(client, Prop_Data, "m_iTeamNum");
	
	while ((ent = FindEntityByClassname(ent, "prop_dynamic")) != -1)
	{	
		currIndex = GetEntProp(ent, Prop_Data, "m_nModelIndex");
		
		if(currIndex == spiderIndex || currIndex == zombieModelIndex[0] || currIndex == zombieModelIndex[1] || currIndex == zombieModelIndex[2] || currIndex == zombieModelIndex[3])
		{
			owner = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");
			
			//PrintToChat(client, "Found an object: client:%i | owner:%i", client, owner);
			
			if(client == owner)
			{
				//make sure spider and entity are on the same team
				iTeam = GetEntProp(ent, Prop_Data, "m_iTeamNum");
				
				if(playerTeam == iTeam)
				{
					//PrintToChat(client, "Found a match");
					
					//find parent
					new parent = GetEntPropEnt(ent, Prop_Data, "m_pParent");
					if(IsValidEntity(parent))
						TeleportEntity(parent, startpt, angle, speed);
				}
			}
		}
	}
}

SummonObject(client)
{	
	//player must wait 10 seconds between summonings
	if(lastSummon[client] > GetTime())
	{
		PrintCenterText(client, "You must wait: %i seconds before summoning your minions!", lastSummon[client] - GetTime());
		return;
	}
	
	lastSummon[client] = GetTime() + 30;
	
	teleportToOwner(client);
	
	EmitSoundToAll(SOUND_WHISTLE, client);
}

public amountOfZombies()
{
	new ent = -1;
	new numZombies;
	new currIndex;
	
	while ((ent = FindEntityByClassname(ent, "prop_dynamic")) != -1)
	{	
		currIndex = GetEntProp(ent, Prop_Data, "m_nModelIndex");
		if(currIndex == zombieModelIndex[1] || currIndex == zombieModelIndex[2] || currIndex == zombieModelIndex[3])
			numZombies ++;
	}
	
	return numZombies;
}

public amountOfCows()
{
	new ent = -1;
	new numCows;
	new currIndex;
	
	while ((ent = FindEntityByClassname(ent, "prop_dynamic")) != -1)
	{	
		currIndex = GetEntProp(ent, Prop_Data, "m_nModelIndex");
		if(currIndex == cowModelIndex)
			numCows ++;
	}
	
	return numCows;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask) {
 	return entity > MaxClients;
}