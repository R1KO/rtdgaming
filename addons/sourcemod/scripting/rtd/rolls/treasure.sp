#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <attachments>
#include <rtd_rollinfo>

//SOUND_MEDSHOT - played when an item is given to the player from the BackPack
//SOUND_PICKUP  - played when a item is put into the Backpack
//SetEntProp(target, Prop_Send, "m_iObserverMode", observer ? 1 : 0);


public Action:SpawnAndAttachTreasure(client)
{	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a treasure Chest!" );
		return Plugin_Handled;
	}
	
	client_rolls[client][AWARD_G_TREASURE][0] = 1;
	client_rolls[client][AWARD_G_TREASURE][1] = EntIndexToEntRef(ent); //entity index
	
	SetEntityModel(ent, MODEL_CHEST_ONBACK);
	
	new String:playerName[128];
	Format(playerName, sizeof(playerName), "target%i", client);
	DispatchKeyValue(client, "targetname", playerName);
	
	//Set the Backpack's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	SDKHook(ent, SDKHook_SetTransmit, Hook_EveryoneBlizzard); 
	
	DispatchSpawn(ent);
	
	AcceptEntityInput( ent, "DisableShadow" );
	
	CAttach(ent, client, "flag");
	
	AcceptEntityInput( ent, "DisableCollision" );
	
	new String:name[32];
	GetClientName(client, name, sizeof(name));
	
	//The Datapack stores all the Backpack's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, treasure_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(ent));   //PackPosition(0);  Backpack Index
	WritePackCell(dataPackHandle, 0);     //PackPosition(24); Time on floor
	
	EmitSoundToAll(SOUND_ITEM_EQUIP,client);
	
	SpawnAndAttachClientTreasure(client);
	return Plugin_Handled;
}

public Action:SpawnAndAttachClientTreasure(client)
{	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Treasure Chest!" );
		return Plugin_Handled;
	}
	
	client_rolls[client][AWARD_G_TREASURE][2] = EntIndexToEntRef(ent); //entity index
	
	SetEntityModel(ent, MODEL_CHEST_ONBACK);
	
	new String:playerName[128];
	Format(playerName, sizeof(playerName), "target%i", client);
	DispatchKeyValue(client, "targetname", playerName);
	
	//Set the Backpack's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	SDKHook(ent, SDKHook_SetTransmit, Hook_ClientBlizzard); 
	
	DispatchSpawn(ent);
	
	AcceptEntityInput( ent, "DisableShadow" );
	
	CAttach(ent, client, "flag");
	
	AcceptEntityInput( ent, "DisableCollision" );
	
	//The Datapack stores all the Backpack's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, Client_Treasure_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(ent));   //PackPosition(0);  Backpack Index
	
	return Plugin_Handled;
}

public Action:Client_Treasure_Timer(Handle:timer, Handle:dataPackHandle)
{
	ResetPack(dataPackHandle);
	new chest = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	if(chest < 1)
		return Plugin_Stop;
	
	if(!IsValidEntity(chest))
		return Plugin_Stop;
	
	new wearer = GetEntPropEnt(chest, Prop_Data, "m_hOwnerEntity");
	
	if(wearer < 1)
	{
		CDetach(chest);
		killEntityIn(chest, 0.0);
		
		return Plugin_Stop;
	}else if(!client_rolls[wearer][AWARD_G_TREASURE][0])
	{
		CDetach(chest);
		killEntityIn(chest, 0.0);
		itemEquipped_OnBack[wearer] = 0;
		
		return Plugin_Stop;
	}
	
	itemEquipped_OnBack[wearer] = 1;
	
	if(TF2_IsPlayerInCondition(wearer, TFCond_Taunting) || TF2_IsPlayerInCondition(wearer, TFCond_Bonked) || GetEntData(wearer, m_iStunFlags) & TF_STUNFLAG_THIRDPERSON)
	{
		/////////////////
		//Update Alpha //
		/////////////////
		new alpha = GetEntData(wearer, m_clrRender + 3, 1);
		new playerCond = GetEntProp(wearer, Prop_Send, "m_nPlayerCond");
		
		if(TF2_GetPlayerClass(wearer) == TFClass_Spy)
		{	
			if(playerCond&16 || playerCond&24)
			{
				SetEntityRenderMode(chest, RENDER_TRANSCOLOR);	
				SetEntityRenderColor(chest, 255, 255,255, 0);
			}else{
				SetEntityRenderMode(chest, RENDER_TRANSCOLOR);	
				SetEntityRenderColor(chest, 255, 255,255, alpha);
			}
		}else{
			SetEntityRenderMode(chest, RENDER_TRANSCOLOR);	
			SetEntityRenderColor(chest, 255, 255,255, alpha);
		}
		
	}else{
		SetEntityRenderMode(chest, RENDER_TRANSCOLOR);	
		SetEntityRenderColor(chest, 255, 255,255, 0);
	}
	
	return Plugin_Continue;
}

public Action:treasure_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopTreasureTimer(dataPackHandle))
		return Plugin_Stop;
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new chest = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new timeonFloor = ReadPackCell(dataPackHandle);
	
	new wearer = GetEntPropEnt(chest, Prop_Data, "m_hOwnerEntity");
	
	//There is no owner entity
	if(wearer == -1)
	{
		SetEntityRenderMode(chest, RENDER_TRANSCOLOR);	
		SetEntityRenderColor(chest, 255, 255,255, 255);
		
		timeonFloor ++;
		
		if(timeonFloor >= 600)
		{
			AcceptEntityInput(chest,"kill");
			return Plugin_Stop;
		}
		
		if(timeonFloor > 20)
		{
			//Check to see if there is a nearby player
			new Float: backpackPos[3];
			new Float: clientEyePos[3];
			new Float: clientFeetPos[3];
			new Float: distanceFromEye;
			new Float: distanceFromFeet;
			
			GetEntPropVector(chest, Prop_Send, "m_vecOrigin", backpackPos);
			
			for(new client=1; client <= MaxClients; client++)
			{
				//player is not here let's skip
				if (!IsClientInGame(client) || !IsPlayerAlive(client))
					continue;
				
				if(client_rolls[client][AWARD_G_TREASURE][0])
					continue;
				
				//Get the player's postion
				GetClientEyePosition(client, clientEyePos); 
				GetClientAbsOrigin(client, clientFeetPos);
				
				distanceFromEye = GetVectorDistance(clientEyePos, backpackPos);
				distanceFromFeet = GetVectorDistance(clientFeetPos, backpackPos);
				
				if((distanceFromEye < 70.0 || distanceFromFeet < 50.0))
				{	
					if(client_rolls[client][AWARD_G_SPIDER][1] != 0)
					{
						PrintCenterText(client, "Can't pick up Treasure Chest with Spider on you!");
						continue;
					}
					
					if(client_rolls[client][AWARD_G_BACKPACK][0])
					{
						PrintCenterText(client, "Can't pick up Treasure Chest with Backpack equipped!");
						continue;
					}
					
					if(client_rolls[client][AWARD_G_WINGS][0])
					{
						PrintCenterText(client, "Can't pick up Treasure Chest with Redbull equipped!");
						continue;
					}
					
					if(client_rolls[client][AWARD_G_STONEWALL][0])
					{
						PrintCenterText(client, "Can't pick up Treasure Chest with Stonewall equipped!");
						continue;
					}
					
					if(client_rolls[client][AWARD_G_BLIZZARD][0])
					{
						PrintCenterText(client, "Can't pick up Treasure Chest with Blizzard equipped!");
						continue;
					}
					
					if(itemEquipped_OnBack[client])
					{
						if(denyPickup(client, AWARD_G_TREASURE, true))
							continue;
					}
					
					wearer = client;
					
					if(!client_rolls[client][AWARD_G_TREASURE][0])
					{
						PrintCenterText(client, "Picked up Treasure Chest");
						
						attachExistingTreasure(client, chest);
						
						itemEquipped_OnBack[client] = 1;
					}
					
					EmitSoundToAll(SSphere_Heal,wearer);
					return Plugin_Stop;
				}
			}
		}
	}
	
	if(wearer > 0 && wearer <= MaxClients)
	{	
		if(IsClientInGame(wearer))
		{
			if(!IsPlayerAlive(wearer))
			{
				detachTreasure(chest);
				return Plugin_Stop;
			}
			
			itemEquipped_OnBack[wearer] = 1;
			
			/////////////////
			//Update Alpha //
			/////////////////
			new alpha = GetEntData(wearer, m_clrRender + 3, 1);
			new playerCond = GetEntProp(wearer, Prop_Send, "m_nPlayerCond");
			
			if(TF2_GetPlayerClass(wearer) == TFClass_Spy)
			{	
				if(playerCond&16 || playerCond&24)
				{
					SetEntityRenderMode(chest, RENDER_TRANSCOLOR);	
					SetEntityRenderColor(chest, 255, 255,255, 0);
				}else{
					SetEntityRenderMode(chest, RENDER_TRANSCOLOR);	
					SetEntityRenderColor(chest, 255, 255,255, alpha);
				}
			}else{
				SetEntityRenderMode(chest, RENDER_TRANSCOLOR);	
				SetEntityRenderColor(chest, 255, 255,255, alpha);
			}
		}
	}
	
	
	
	ResetPack(dataPackHandle);
	WritePackCell(dataPackHandle, EntIndexToEntRef(chest));    //PackPosition(0);  Backpack Index
	WritePackCell(dataPackHandle, timeonFloor); //PackPosition(24); Time on floor
	
	return Plugin_Continue;
}

public attachExistingTreasure(client, chest)
{
	AcceptEntityInput(chest, "kill");
	SpawnAndAttachTreasure(client);
	
	EmitSoundToAll(SOUND_ITEM_EQUIP,client);

}

public detachTreasure(chest)
{
	new owner = GetEntPropEnt(chest, Prop_Data, "m_hOwnerEntity");
	
	
	CDetach(chest);
	killEntityIn(chest, 0.0);
	
	//Prevent backpack from respawning on roundend
	if(roundEnded)
		return;
	
	if(owner > 0 && owner <= MaxClients)
	{
		client_rolls[owner][AWARD_G_TREASURE][0] = 0;
		itemEquipped_OnBack[owner] = 0;
		
		new Float:pos[3];
		GetClientEyePosition(owner, pos);
		
		new Float:Direction[3];
		new Float:angle[3];
		Direction[0] = pos[0];
		Direction[1] = pos[1];
		Direction[2] = pos[2]-1024;
		
		new Float:floorPos[3];
		
		new Handle:Trace = TR_TraceRayFilterEx(pos, Direction, MASK_SOLID, RayType_EndPoint, TraceFilterAll, owner);
		TR_GetEndPosition(floorPos, Trace);
		CloseHandle(Trace);
		
		floorPos[2] += 20.0;
		
		new ent = CreateEntityByName("prop_dynamic_override");
		if ( ent == -1 )
		{
			ReplyToCommand( owner, "Failed to create a Treasure Chest!" );
			return;
		}
		
		SetEntityModel(ent, MODEL_CHEST);
		
		new String:playerName[128];
		Format(playerName, sizeof(playerName), "target%i", owner);
		DispatchKeyValue(owner, "targetname", playerName);
		
		//Set the Backpack's owner
		SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", -1);
		
		DispatchSpawn(ent);
		
		AcceptEntityInput( ent, "DisableShadow" );
		
		AcceptEntityInput( ent, "DisableCollision" );
		
		new String:name[32];
		GetClientName(owner, name, sizeof(name));
		
		SetVariantString("idle");
		AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
		
		//The Datapack stores all the Backpack's important values
		new Handle:dataPackHandle;
		CreateDataTimer(0.1, treasure_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
		
		//Setup the datapack with appropriate information
		WritePackCell(dataPackHandle, ent);   //PackPosition(0);  Backpack Index
		WritePackCell(dataPackHandle, 0);     //PackPosition(24); Time on floor
		WritePackString(dataPackHandle,name); //the wearer's name
		
		TeleportEntity(ent, floorPos, angle, NULL_VECTOR);
	}
	
	EmitSoundToAll(SOUND_ITEM_EQUIP_02,chest);
}

public stopTreasureTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new chest = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	if(chest < 1)
		return true;
	
	if(!IsValidEntity(chest))
	{
		//PrintToChatAll("Invalid Blizard entity");
		return true;
	}
	
	return false;
}

public Drop_Treasure(client)
{
	//Drop entire backpack
	if(!client_rolls[client][AWARD_G_TREASURE][0])
		return;
	
	new chest = EntRefToEntIndex(client_rolls[client][AWARD_G_TREASURE][1]);
	
	if(chest < 1)
		return;
	
	if(!IsValidEntity(chest))
		return;
	
	new currIndex = GetEntProp(chest, Prop_Data, "m_nModelIndex");
	
	if(currIndex == modelIndex[53]  || currIndex == modelIndex[54])
	{
		client_rolls[client][AWARD_G_TREASURE][0] = 0;
		centerHudText(client, "Treasure Chest Dropped", 0.1, 5.0, HudMsg3, 0.82); 
		detachTreasure(chest);
		
	}
} 

public Action:waitAndAttachTreasure(Handle:timer, any:userId)
{
	new client = GetClientOfUserId(userId);
	
	if(client < 1)
		return Plugin_Stop;
	
	SpawnAndAttachTreasure(client);
	return Plugin_Stop;
}

public spawnOnFloorTreasure(client)
{	
	//Prevent backpack from respawning on roundend
	if(roundEnded)
		return;
	
	new Float:pos[3];
	GetClientEyePosition(client, pos);
	
	new Float:Direction[3];
	new Float:angle[3];
	Direction[0] = pos[0];
	Direction[1] = pos[1];
	Direction[2] = pos[2]-1024;
	
	new Float:floorPos[3];
	
	new Handle:Trace = TR_TraceRayFilterEx(pos, Direction, MASK_SOLID, RayType_EndPoint, TraceFilterAll, client);
	TR_GetEndPosition(floorPos, Trace);
	CloseHandle(Trace);
	
	floorPos[2] += 20.0;
	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Treasure Chest!" );
		return;
	}
	
	SetEntityModel(ent, MODEL_CHEST);
	
	new String:playerName[128];
	Format(playerName, sizeof(playerName), "target%i", client);
	DispatchKeyValue(client, "targetname", playerName);
	
	//Set the Backpack's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", -1);
	
	DispatchSpawn(ent);
	
	AcceptEntityInput( ent, "DisableShadow" );
	
	AcceptEntityInput( ent, "DisableCollision" );
	
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	//The Datapack stores all the Backpack's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, treasure_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(ent));   //PackPosition(0);  Backpack Index
	WritePackCell(dataPackHandle, 0);     //PackPosition(24); Time on floor
	
	TeleportEntity(ent, floorPos, angle, NULL_VECTOR);
}