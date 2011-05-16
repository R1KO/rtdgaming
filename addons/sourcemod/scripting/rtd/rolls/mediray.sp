#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <attachments>
#include <rtd_rollinfo>

public Action:equipMediray(client)
{
	// Create owner entity.
	new iEntity = CreateEntityByName("prop_dynamic_override");
	if ( iEntity == -1 )
	{
		ReplyToCommand( client, "Failed to create a Mediray!" );
		return Plugin_Handled;
	}
	
	client_rolls[client][AWARD_G_MEDIRAY][0] = 1;
	
	SetEntityModel(iEntity, MODEL_MEDIRAY);
	
	new String:playerName[128];
	Format(playerName, sizeof(playerName), "target%i", client);
	DispatchKeyValue(client, "targetname", playerName);
	
	//Set the Backpack's owner
	SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);
	
	DispatchSpawn(iEntity);
	AcceptEntityInput( iEntity, "DisableShadow" );
	CAttach(iEntity, client, "flag");
	//AcceptEntityInput( iEntity, "DisableCollision" );
	
	SetVariantString("start");
	AcceptEntityInput(iEntity, "SetAnimation", -1, -1, 0); 
	
	new iTeam = GetClientTeam(client);
	SetVariantInt(iTeam);
	AcceptEntityInput(iEntity, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(iEntity, "SetTeam", -1, -1, 0); 
	
	
	new String:name[32];
	GetClientName(client, name, sizeof(name));
	
	//The Datapack stores all the Spider's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, mediRay_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, iEntity); //0   entity
	WritePackCell(dataPackHandle, GetClientUserId(client)); //8   owner
	WritePackCell(dataPackHandle, GetTime()); //16  owner
	
	if(RTD_PerksLevel[client][45] > 0)
	{
		WritePackCell(dataPackHandle, GetTime() + 40); //24
	}else{
		WritePackCell(dataPackHandle, GetTime() + 60); //24
	}
	
	WritePackCell(dataPackHandle, 0); //32 sound playing
	WritePackString(dataPackHandle, name); //40  client userid
	
	EmitSoundToAll(SOUND_ITEM_EQUIP,client);
	
	return Plugin_Handled;
}

public Action:mediRay_Timer(Handle:timer, Handle:dataPackHandle)
{
	new String:playerName[128];
	new bool:allowAmmo = false;
	new bool:allowFull = false;
	new client;
	
	ResetPack(dataPackHandle);
	new mediRay = ReadPackCell(dataPackHandle);
	new userID = ReadPackCell(dataPackHandle);
	new lastAmmoTime = ReadPackCell(dataPackHandle);
	new nextFullWaveTime = ReadPackCell(dataPackHandle);
	new soundPlaying = ReadPackCell(dataPackHandle);
	
	client = GetClientOfUserId(userID);
	
	ReadPackString(dataPackHandle, playerName, sizeof(playerName));
	
	
	////////////////////////////////////////
	//Determine if the timer should stop  //
	////////////////////////////////////////
	if(!IsValidEntity(mediRay))
		return Plugin_Stop;
	
	new currIndex = GetEntProp(mediRay, Prop_Data, "m_nModelIndex");
	if(currIndex != mediRayModelIndex)
		return Plugin_Stop;
	
	if(client < 1 || client > MaxClients)
	{
		CDetach(mediRay);
		dropMediRay(mediRay, playerName, -1);
		killEntityIn( mediRay, 0.2);
		return Plugin_Stop;
	}
	
	if(!IsClientInGame(client))
	{
		CDetach(mediRay);
		dropMediRay(mediRay, playerName, -1);
		killEntityIn( mediRay, 0.2);
		return Plugin_Stop;
	}
	
	if(!IsPlayerAlive(client) || !client_rolls[client][AWARD_G_MEDIRAY][0] || TF2_GetPlayerClass(client) != TFClass_Medic)
	{
		CDetach(mediRay);
		dropMediRay(mediRay, playerName, userID);
		killEntityIn( mediRay, 0.2);
		return Plugin_Stop;
	}
	
	//////////////////////////
	// Setup the animations //
	//////////////////////////
	new isFinished = GetEntProp(mediRay, Prop_Data, "m_bSequenceFinished");
	new sequence = GetEntProp(mediRay, Prop_Data, "m_nSequence");
	if(sequence == 0 && isFinished)
	{
		SetVariantString("idle");
		AcceptEntityInput(mediRay, "SetAnimation", -1, -1, 0); 
	}
	
	/////////////////////
	//Update the team  //
	/////////////////////
	new iTeam = GetClientTeam(client);
	if(GetEntProp(mediRay, Prop_Data, "m_iTeamNum") != iTeam)
	{
		SetVariantInt(iTeam);
		AcceptEntityInput(mediRay, "TeamNum", -1, -1, 0);
		
		SetVariantInt(iTeam);
		AcceptEntityInput(mediRay, "SetTeam", -1, -1, 0); 
	}
	
	/////////////////////
	//Give out ammo //
	/////////////////////
	if(GetTime() > lastAmmoTime)
	{
		SetPackPosition(dataPackHandle, 16);
		WritePackCell(dataPackHandle, GetTime() + 5); //16  owner
		allowAmmo =true;
		
		EmitSoundToAll(SOUND_MEDIRAYHEAL, mediRay); 
	}
	
	//////////////////////////
	//Give out lots of ammo //
	//////////////////////////
	if(GetTime() == nextFullWaveTime - 5 && !soundPlaying)
	{
		EmitSoundToAll(SOUND_MEDIRAY, mediRay); 
		SetPackPosition(dataPackHandle, 32);
		WritePackCell(dataPackHandle, 1);
	}
	
	if(GetTime() >= nextFullWaveTime - 5 && GetTime() < nextFullWaveTime)
	{
		PrintCenterText(client, "Mediray Boost in %is", nextFullWaveTime - GetTime());
	}
	
	if(GetTime() > nextFullWaveTime)
	{
		SetPackPosition(dataPackHandle, 24);
		
		if(RTD_PerksLevel[client][45] > 0)
		{
			WritePackCell(dataPackHandle, GetTime() + 40); //16  owner
		}else{
			WritePackCell(dataPackHandle, GetTime() + 60); //16  owner
		}
		
		allowFull =true;
		
		TF_AddUberLevel(client, 0.5);
		
		EmitSoundToAll(SOUND_MEDIRAYHEAL, mediRay); 
		
		SetPackPosition(dataPackHandle, 32);
		WritePackCell(dataPackHandle, 0);
	}
	
	/////////////////////
	//Update the alpha //
	/////////////////////
	new playerAlpha = GetEntData(client, m_clrRender + 3, 1);
	new objectAlpha = GetEntData(mediRay, m_clrRender + 3, 1);
	
	if(playerAlpha != objectAlpha)
	{
		SetEntityRenderMode(mediRay, RENDER_TRANSCOLOR);
		SetEntityRenderColor(mediRay, 255, 255, 255, playerAlpha);
	}
	
	////////////////////
	//Determine Skin  //
	////////////////////
	new cond = GetEntData(client, m_nPlayerCond);
	new skin = GetEntProp(mediRay, Prop_Data, "m_nSkin");
	
	if(GetClientTeam(client) == BLUE_TEAM)
	{
		if(cond & 32)
		{
			if(skin != 3)
			{
				DispatchKeyValue(mediRay, "skin", "3"); 
			}
		}else{
			if(skin != 0)
			{
				DispatchKeyValue(mediRay, "skin", "0"); 
			}
		}
	}
	
	if(GetClientTeam(client) == RED_TEAM)
	{
		if(cond & 32)
		{
			if(skin != 2)
			{
				DispatchKeyValue(mediRay, "skin", "2"); 
			}
		}else{
			if(skin != 1)
			{
				DispatchKeyValue(mediRay, "skin", "1"); 
			}
		}
	}
	
	///////////////////////
	//Heal others nearby //
	///////////////////////
	new Float:ownerPos[3];
	GetClientAbsOrigin(client, ownerPos);
	
	new Float:otherPlayerPos[3];
	new Float:distance;
	new Float:range = 300.0;
	
	if(RTD_PerksLevel[client][46] > 0)
		range = 400.0;
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if(GetClientTeam(i) != GetClientTeam(client))
			continue;
        
		
		GetClientAbsOrigin(i, otherPlayerPos);
		distance = GetVectorDistance(ownerPos, otherPlayerPos);
		
		
		if(distance < range)
		{
			if(!allowFull)
			{
				if(client != i)
				{
					if(RTD_PerksLevel[client][47] > 0)
					{
						addHealth(i, 4);
					}else{
						addHealth(i, 3);
					}
				}
				
				if(allowAmmo)
					GiveAmmoToActiveWeapon(i, 0.3);
			}else{
				addHealth(i, 150);
				GiveAmmoToActiveWeapon(i, 0.9);
			}
		}
	}
	
	return Plugin_Continue;
}

public dropMediRay(entity, String:playerName[], userId)
{
	// Create owner entity.
	new iEntity = CreateEntityByName("prop_dynamic_override");
	if ( iEntity == -1 )
	{
		//ReplyToCommand( client, "Failed to create a Medirayfloor!" );
		return;
	}
	
	new Float:pos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
	
	SetEntityModel(iEntity, MODEL_MEDIRAY);
	
	DispatchSpawn(iEntity);
	
	SetVariantString("floor");
	AcceptEntityInput(iEntity, "SetAnimation", -1, -1, 0); 
	
	new Float:Direction[3];
	Direction[0] = pos[0];
	Direction[1] = pos[1];
	Direction[2] = pos[2]-1024;
	
	new Float:floorPos[3];
	
	new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	new Handle:Trace = TR_TraceRayFilterEx(pos, Direction, MASK_SOLID, RayType_EndPoint, TraceFilterAll, owner);
	TR_GetEndPosition(floorPos, Trace);
	CloseHandle(Trace);
	
	//floorPos[2] += 10.0;
	
	TeleportEntity(iEntity, floorPos, NULL_VECTOR, NULL_VECTOR);
	
	
	new iTeam = GetEntProp(iEntity, Prop_Data, "m_iTeamNum");
	SetVariantInt(iTeam);
	AcceptEntityInput(iEntity, "TeamNum", -1, -1, 0);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(iEntity, "SetTeam", -1, -1, 0); 
	
	new String:mediName[128];
	Format(mediName, sizeof(mediName), "mediName%i", iEntity);
	DispatchKeyValue(iEntity, "targetname", mediName);
	
	AttachTempParticle(iEntity,"coin_blue", 60.0, true,mediName, 0.0, false);
	if(iTeam == BLUE_TEAM)
	{
		DispatchKeyValue(iEntity, "skin", "0"); 
	}else{
		DispatchKeyValue(iEntity, "skin", "1"); 
	}
	
	EmitSoundToAll(SOUND_ITEM_EQUIP_02,iEntity);
	
	
	
	//The Datapack stores all the Spider's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, mediRayFloor_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, iEntity); //0   entity
	WritePackCell(dataPackHandle, userId); //8   original owner
	WritePackString(dataPackHandle, playerName); //16
	killEntityIn(iEntity, 60.0);
	
	
}

public Action:mediRayFloor_Timer(Handle:timer, Handle:dataPackHandle)
{
	ResetPack(dataPackHandle);
	new mediRay = ReadPackCell(dataPackHandle);
	new userId = ReadPackCell(dataPackHandle);
	
	new String:playerName[128];
	ReadPackString(dataPackHandle, playerName, sizeof(playerName));
	
	if(!IsValidEntity(mediRay))
		return Plugin_Stop;
	
	new currIndex = GetEntProp(mediRay, Prop_Data, "m_nModelIndex");
	if(currIndex != mediRayModelIndex)
		return Plugin_Stop;
	
	new Float:mediRayPos[3];
	GetEntPropVector(mediRay, Prop_Send, "m_vecOrigin", mediRayPos);
	
	
	new Float: clientEyePos[3];
	new Float: clientFeetPos[3];
	new Float: distanceFromEye;
	new Float: distanceFromFeet;
	
	for(new client=1; client <= MaxClients; client++)
	{
		//player is not here let's skip
		if (!IsClientInGame(client) || !IsPlayerAlive(client))
			continue;
		
		if(client_rolls[client][AWARD_G_MEDIRAY][0])
			continue;
		
		if(TF2_GetPlayerClass(client) != TFClass_Medic)
			continue;
		
		//Get the player's postion
		GetClientEyePosition(client, clientEyePos); 
		GetClientAbsOrigin(client, clientFeetPos);
		
		distanceFromEye = GetVectorDistance(clientEyePos, mediRayPos);
		distanceFromFeet = GetVectorDistance(clientFeetPos, mediRayPos);
		
		if((distanceFromEye < 70.0 || distanceFromFeet < 50.0))
		{
			EmitSoundToAll(SOUND_PICKUP,client);
			
			new String:name[32];
			GetClientName(client, name, sizeof(name));
			
			centerHudText(client, "Nearby allies will be healed", 5.1, 10.0, HudMsg3, 0.75); 
			centerHudText(client, "They will also receive ammo every 5 secs", 10.1, 20.0, HudMsg3, 0.75); 
			
			killEntityIn(mediRay, 0.0);
			equipMediray(client);
			
			if(userId > 0)
			{
				if(client == GetClientOfUserId(userId))
				{
					PrintToChatAll("\x01\x04[RTD] \x03%s\x04 picked up his \x03MediRay-Dar", name);
					PrintCenterText(client, "You picked up your MediRay-Dar");
					return Plugin_Stop;
				}
			}
			
			PrintToChatAll("\x01\x04[RTD] \x03%s\x04 picked up %s's \x03MediRay-Dar", name, playerName);
			PrintCenterText(client, "You picked up %s's MediRay-Dar", playerName);
			
			if(userId > 0 && GetClientOfUserId(userId) > 0)
			{
				if(IsClientInGame(GetClientOfUserId(userId)))
				{
					if(!client_rolls[GetClientOfUserId(userId)][AWARD_G_MEDIRAY][0] && TF2_GetPlayerClass(GetClientOfUserId(userId)) == TFClass_Medic)
					{
						PrintCenterText(GetClientOfUserId(userId), "%s picked up your MediRay-Dar", name);
						PrintCenterText(client, "You picked up %s's MediRay-Dar", playerName);
						return Plugin_Stop;
					}
				}
			}
			
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}