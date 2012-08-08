#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <attachments>
#include <rtd_rollinfo>

//SOUND_MEDSHOT - played when an item is given to the player from the BackPack
//SOUND_PICKUP  - played when a item is put into the Backpack
//SetEntProp(target, Prop_Send, "m_iObserverMode", observer ? 1 : 0);

//////////////////////////////////////////////////////////////////////////////////////////////////
// Backback Blizzard Variables																	//
// ---------------------------																	//
//																								//
// client_rolls[client][AWARD_G_BLIZZARD][0]	=	Enabled?									//
// client_rolls[client][AWARD_G_BLIZZARD][1]	=	Entity, this refers to the backpackitself	//
// client_rolls[client][AWARD_G_BLIZZARD][2]	=										//
// client_rolls[client][AWARD_G_BLIZZARD][3]	=										//
// client_rolls[client][AWARD_G_BLIZZARD][4]	=										//
// client_rolls[client][AWARD_G_BLIZZARD][5]	=										//
// client_rolls[client][AWARD_G_BLIZZARD][6]	=										//
// client_rolls[client][AWARD_G_BLIZZARD][7]	=	Marks player as frozen						//
///////////////////////////////////////////////////////////////////////////////////////////////////

public Action:SpawnAndAttachBlizzard(client)
{	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Backpack Blizzard!" );
		return Plugin_Handled;
	}
	
	client_rolls[client][AWARD_G_BLIZZARD][0] = 1;
	client_rolls[client][AWARD_G_BLIZZARD][1] = ent; //entity index
	client_rolls[client][AWARD_G_BLIZZARD][5] = GetTime();
	
	SetEntityModel(ent, MODEL_BLIZZARDPACK);
	
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
	CreateDataTimer(0.1, Blizzard_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(ent));   //PackPosition(0);  Backpack Index
	WritePackCell(dataPackHandle, 0);     //PackPosition(24); Time on floor
	WritePackString(dataPackHandle,name); //the wearer's name
	
	if (RTD_PerksLevel[client][23])
		CreateTimer(1.0 * RTD_Perks[client][23], Blizzard_Extinguish, client, TIMER_REPEAT);
	
	EmitSoundToAll(SOUND_ITEM_EQUIP,client);
	
	AttachRTDParticle(client, "SnowBlower_Main_fix", false, 2, 70.0);
	
	SpawnAndAttachClientBlizzard(client);
	return Plugin_Handled;
}

public Action:Blizzard_Extinguish(Handle:timer, any:client)
{
	//The player resets their points while wearing the backpack.
	if (RTD_PerksLevel[client][23] == 0 || client_rolls[client][AWARD_G_BLIZZARD][0] == 0) {
		KillTimer(timer);
		return Plugin_Continue;
	}
	
	if(TF2_IsPlayerInCondition(client, TFCond_OnFire))
	{
		PrintHintText(client, "Your backpack blizzard extinguished you.  Thank it :)");
		EmitSoundToAll(SOUND_FLAMEOUT);
		TF2_RemoveCondition(client, TFCond_OnFire);
	}
	
	return Plugin_Continue;
}

public Action:SpawnAndAttachClientBlizzard(client)
{	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Backpack Blizzard!" );
		return Plugin_Handled;
	}
	
	SetEntityModel(ent, MODEL_BLIZZARDPACK);
	
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
	CreateDataTimer(0.1, Client_Blizzard_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(ent));   //PackPosition(0);  Backpack Index
	
	return Plugin_Handled;
}

public Action:Client_Blizzard_Timer(Handle:timer, Handle:dataPackHandle)
{
	ResetPack(dataPackHandle);
	new blizzard = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	if(blizzard < 1)
		return Plugin_Stop;
	
	if(!IsValidEntity(blizzard))
		return Plugin_Stop;
	
	new currIndex = GetEntProp(blizzard, Prop_Data, "m_nModelIndex");
	if(currIndex != blizzardModelIndex[0] && currIndex != blizzardModelIndex[1])
		return Plugin_Stop;
	
	new wearer = GetEntPropEnt(blizzard, Prop_Data, "m_hOwnerEntity");
	
	if(wearer < 1)
	{
		CDetach(blizzard);
		killEntityIn(blizzard, 0.0);
		
		return Plugin_Stop;
	}else if(!client_rolls[wearer][AWARD_G_BLIZZARD][0])
	{
		CDetach(blizzard);
		killEntityIn(blizzard, 0.0);
		itemEquipped_OnBack[wearer] = 0;
		
		return Plugin_Stop;
	}
	
	itemEquipped_OnBack[wearer] = 1;
	
	//PrintToChat(wearer, "%i | %i| %i", GetEntPropEnt(wearer, Prop_Send, "m_hObserverTarget"), GetEntProp(wearer, Prop_Send, "m_iObserverMode"), GetEntProp(wearer, Prop_Send, "m_bDrawViewmodel"));
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
				SetEntityRenderMode(blizzard, RENDER_TRANSCOLOR);	
				SetEntityRenderColor(blizzard, 255, 255,255, 0);
			}else{
				SetEntityRenderMode(blizzard, RENDER_TRANSCOLOR);	
				SetEntityRenderColor(blizzard, 255, 255,255, alpha);
			}
		}else{
			SetEntityRenderMode(blizzard, RENDER_TRANSCOLOR);	
			SetEntityRenderColor(blizzard, 255, 255,255, alpha);
		}
		
		////////////////////
		// Determine skin //
		////////////////////
		if(playerCond&32)
		{	
			if(GetEntProp(blizzard, Prop_Data, "m_nSkin") == 0)
			{
				if(GetClientTeam(wearer) == BLUE_TEAM)
				{
					DispatchKeyValue(blizzard, "skin","1"); 
				}else{
					DispatchKeyValue(blizzard, "skin","2"); 
				}
			}
		}else{
			if(GetEntProp(blizzard, Prop_Data, "m_nSkin") != 0)
				DispatchKeyValue(blizzard, "skin","0"); 
		}
	}else{
		SetEntityRenderMode(blizzard, RENDER_TRANSCOLOR);	
		SetEntityRenderColor(blizzard, 255, 255,255, 0);
	}
	
	return Plugin_Continue;
}

public Action:Blizzard_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopBlizzardTimer(dataPackHandle))
		return Plugin_Stop;
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new blizzard = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new timeonFloor = ReadPackCell(dataPackHandle);
	new String:backpackname[32];
	ReadPackString(dataPackHandle,backpackname,sizeof(backpackname));
	
	new wearer = GetEntPropEnt(blizzard, Prop_Data, "m_hOwnerEntity");
	
	//There is no owner entity
	if(wearer == -1)
	{
		SetEntityRenderMode(blizzard, RENDER_TRANSCOLOR);	
		SetEntityRenderColor(blizzard, 255, 255,255, 255);
		
		timeonFloor ++;
		
		if(timeonFloor >= 200)
		{
			AcceptEntityInput(blizzard,"kill");
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
			
			GetEntPropVector(blizzard, Prop_Send, "m_vecOrigin", backpackPos);
			
			for(new client=1; client <= MaxClients; client++)
			{
				//player is not here let's skip
				if (!IsClientInGame(client) || !IsPlayerAlive(client))
					continue;
				
				//Get the player's postion
				GetClientEyePosition(client, clientEyePos); 
				GetClientAbsOrigin(client, clientFeetPos);
				
				distanceFromEye = GetVectorDistance(clientEyePos, backpackPos);
				distanceFromFeet = GetVectorDistance(clientFeetPos, backpackPos);
				
				if((distanceFromEye < 70.0 || distanceFromFeet < 50.0))
				{
					
					if(client_rolls[client][AWARD_G_BLIZZARD][0])
					{
						//User can freeze someone
						client_rolls[client][AWARD_G_BLIZZARD][4] = 0;
						
						//make it visible that the player can freeze someone
						AttachRTDParticle(client, "SnowBlower_Main_fix", false, 2, 70.0);
						
						PrintCenterText(client, "Freeze READY!");
						EmitSoundToAll(SOUND_ITEM_EQUIP,client);
						
						killEntityIn(blizzard, 0.0);
						return Plugin_Continue;
					}
					
					if(client_rolls[client][AWARD_G_SPIDER][1] != 0)
					{
						PrintCenterText(client, "Can't pick up Blizzard with Spider on you!");
						continue;
					}
					
					if(client_rolls[client][AWARD_G_BACKPACK][0])
					{
						PrintCenterText(client, "Can't pick up Blizzard with Backpack equipped!");
						continue;
					}
					
					if(client_rolls[client][AWARD_G_WINGS][0])
					{
						PrintCenterText(client, "Can't pick up Blizzard with Redbull equipped!");
						continue;
					}
					
					if(client_rolls[client][AWARD_G_TREASURE][0])
					{
						PrintCenterText(client, "Can't pick up Blizzard with Treasure Chest equipped!");
						continue;
					}
					
					if(itemEquipped_OnBack[client])
					{
						if(denyPickup(client, AWARD_G_BLIZZARD, true))
							continue;
						
						//PrintCenterText(client, "Can't pick up while an item is equipped!");
					}
					
					wearer = client;
					
					new String:name[32];
					GetClientName(client, name, sizeof(name));
					if(!client_rolls[client][AWARD_G_BLIZZARD][0])
					{
						
						if(StrEqual(name, backpackname, false))
						{
							//PrintToChatAll("\x01\x04[RTD] \x03%s\x04 picked up his \x03Backpack Blizzard",name);
							PrintCenterText(client, "You picked up your Backpack Blizzard");
						}else{
							//PrintToChatAll("\x01\x04[RTD] \x03%s\x04 picked up \x03%s\x04's Backpack Blizzard",name,backpackname);
							PrintCenterText(client, "You picked up %s's Backpack Blizzard",backpackname);
						}
						
						attachExistingBlizzard(client, blizzard);
					}
					
					itemEquipped_OnBack[client] = 1;
					
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
				//client_rolls[wearer][AWARD_G_BLIZZARD][0] = 0;
				detachBlizzard(blizzard);
				return Plugin_Stop;
			}
			
			itemEquipped_OnBack[wearer] = 1;
			
			///////////////////////////////////
			//Show the Blizzard ready message//
			///////////////////////////////////
			if(GetTime() >= client_rolls[wearer][AWARD_G_BLIZZARD][4] && client_rolls[wearer][AWARD_G_BLIZZARD][4] != 0)
			{
				//User can freeze someone
				client_rolls[wearer][AWARD_G_BLIZZARD][4] = 0;
				
				//make it visible that the player can freeze someone
				AttachRTDParticle(wearer, "SnowBlower_Main_fix", false, 2, 70.0);
			}
			
			if(!inTimerBasedRoll[wearer] && client_rolls[wearer][AWARD_G_SPIDER][1] == 0 && !isUsingHud4(wearer))
			{
				//that extra condition is so we don't override the text
				
				if(client_rolls[wearer][AWARD_G_BLIZZARD][4] != 0)
				{
					decl String:message[200];
					Format(message, sizeof(message), "Blizzard Cool Down: %is", client_rolls[wearer][AWARD_G_BLIZZARD][4] -GetTime());
					centerHudText(wearer, message, 0.0, 1.0, HudMsg4, 0.09);
				}
			}
			
			/////////////////
			//Update Alpha //
			/////////////////
			new alpha = GetEntData(wearer, m_clrRender + 3, 1);
			new playerCond = GetEntProp(wearer, Prop_Send, "m_nPlayerCond");
			
			if(TF2_GetPlayerClass(wearer) == TFClass_Spy)
			{	
				if(playerCond&16 || playerCond&24)
				{
					SetEntityRenderMode(blizzard, RENDER_TRANSCOLOR);	
					SetEntityRenderColor(blizzard, 255, 255,255, 0);
				}else{
					SetEntityRenderMode(blizzard, RENDER_TRANSCOLOR);	
					SetEntityRenderColor(blizzard, 255, 255,255, alpha);
				}
			}else{
				SetEntityRenderMode(blizzard, RENDER_TRANSCOLOR);	
				SetEntityRenderColor(blizzard, 255, 255,255, alpha);
			}
			
			////////////////////
			// Determine skin //
			////////////////////
			if(playerCond&32)
			{	
				if(GetEntProp(blizzard, Prop_Data, "m_nSkin") == 0)
				{
					if(GetClientTeam(wearer) == BLUE_TEAM)
					{
						DispatchKeyValue(blizzard, "skin","1"); 
					}else{
						DispatchKeyValue(blizzard, "skin","2"); 
					}
				}
			}else{
				if(GetEntProp(blizzard, Prop_Data, "m_nSkin") != 0)
					DispatchKeyValue(blizzard, "skin","0"); 
			}
			
			////////////////////////////////////////
			//Reduce fire damage to nearby allies //
			////////////////////////////////////////
			if(alpha != 0)
			{
				
				////////////////////////////////////
				////   Slowdown nearby enemies   ///
				////////////////////////////////////
				new Float: playerPos[3];
				new Float: enemyPos[3];
				new Float: distance;
				
				new playerTeam =  GetEntProp(wearer, Prop_Data, "m_iTeamNum");
				GetEntPropVector(wearer, Prop_Data, "m_vecOrigin", playerPos);
				
				for (new i = 1; i <= MaxClients ; i++)
				{
					if(!IsClientInGame(i) || !IsPlayerAlive(i))
						continue;
					
					if(playerTeam != GetClientTeam(i))
						continue;
					
					//Check to see if player is close to cow
					GetClientAbsOrigin(i,enemyPos);
					distance = GetVectorDistance( playerPos, enemyPos);
					
					if(distance < 300.0)
					{
						//mark the user as being slowed
						
						//SetHudTextParams(0.385, 0.82, 1.0, 255, 50, 50, 255);
						//ShowHudText(i, HudMsg3, "You are being slowed!");
						
						inBlizzardTime[i] = GetGameTime() + 0.2;
						//PrintToChat(i, "%f", GetGameTime() );
					}
				}
			}
		}
	}
	
	
	
	ResetPack(dataPackHandle);
	WritePackCell(dataPackHandle, EntIndexToEntRef(blizzard));    //PackPosition(0);  Backpack Index
	WritePackCell(dataPackHandle, timeonFloor); //PackPosition(24); Time on floor
	WritePackString(dataPackHandle,backpackname);
	
	return Plugin_Continue;
}

public attachExistingBlizzard(client, blizzard)
{
	AcceptEntityInput(blizzard, "kill");
	SpawnAndAttachBlizzard(client);
	
	EmitSoundToAll(SOUND_ITEM_EQUIP,client);

}

public detachBlizzard(blizzard)
{
	new owner = GetEntPropEnt(blizzard, Prop_Data, "m_hOwnerEntity");
	
	
	CDetach(blizzard);
	killEntityIn(blizzard, 0.0);
	
	//Prevent backpack from respawning on roundend
	if(roundEnded)
		return;
	
	if(owner > 0 && owner <= MaxClients)
	{
		client_rolls[owner][AWARD_G_BLIZZARD][0] = 0;
		itemEquipped_OnBack[owner] = 0;
		
		DeleteParticle(owner, "SnowBlower_Main_fix");
		
		//for(new i = 1; i <= 7; i ++)
		//	client_rolls[owner][AWARD_G_BLIZZARD][i] = 0;
		
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
		
		floorPos[2] += 10.0;
		
		new ent = CreateEntityByName("prop_dynamic_override");
		if ( ent == -1 )
		{
			ReplyToCommand( owner, "Failed to create a Backpack Blizzard!" );
			return;
		}
		
		SetEntityModel(ent, MODEL_BLIZZARDPACK_FLOOR);
		
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
		CreateDataTimer(0.1, Blizzard_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
		
		//Setup the datapack with appropriate information
		WritePackCell(dataPackHandle, EntIndexToEntRef(ent));   //PackPosition(0);  Backpack Index
		WritePackCell(dataPackHandle, 0);     //PackPosition(24); Time on floor
		WritePackString(dataPackHandle,name); //the wearer's name
		
		TeleportEntity(ent, floorPos, angle, NULL_VECTOR);
	}
	
	EmitSoundToAll(SOUND_ITEM_EQUIP_02,blizzard);
}

public stopBlizzardTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new blizzard = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	if(blizzard < 1)
		return true;
	
	if(!IsValidEntity(blizzard))
	{
		//PrintToChatAll("Invalid Blizard entity");
		return true;
	}
	
	new currIndex = GetEntProp(blizzard, Prop_Data, "m_nModelIndex");
	if(currIndex != blizzardModelIndex[0] && currIndex != blizzardModelIndex[1])
	{
		//PrintToChatAll("Invalid Blizard model");
		return true;
	}
	
	return false;
}

public Drop_Blizzard(client)
{
	//Drop entire backpack
	if(!client_rolls[client][AWARD_G_BLIZZARD][0])
		return;
	
	new currIndex = GetEntProp(client_rolls[client][AWARD_G_BLIZZARD][1], Prop_Data, "m_nModelIndex");
	
	if(currIndex == blizzardModelIndex[0]  || currIndex == blizzardModelIndex[1])
	{
		client_rolls[client][AWARD_G_BLIZZARD][0] = 0;
		centerHudText(client, "Backpack Blizzard Dropped", 0.1, 5.0, HudMsg3, 0.82); 
		detachBlizzard(client_rolls[client][AWARD_G_BLIZZARD][1]);
		
	}
}

public Action:UnfreezeClient_Timer(Handle:timer, Handle:dataPackHandle)
{
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	new Float:playerspeed[3];
	
	ResetPack(dataPackHandle);
	new client = ReadPackCell(dataPackHandle);
	playerspeed[0] = ReadPackFloat(dataPackHandle);
	playerspeed[1] = ReadPackFloat(dataPackHandle);
	playerspeed[2] = ReadPackFloat(dataPackHandle);
	
	client_rolls[client][AWARD_G_BLIZZARD][7] = 0;
	
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	if(GetEntityMoveType(client) == MOVETYPE_NONE)
		SetEntityMoveType(client, MOVETYPE_WALK);
	
	Colorize(client, NORMAL);
	
	SetEntDataVector(client,BaseVelocityOffset,playerspeed,true);
	
	//TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, playerspeed);
	
	return Plugin_Stop;
}

public Action:Hook_EveryoneBlizzard(entity, client)
{
	if(GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") == client)
	{
		return Plugin_Handled;
	}else{
		return Plugin_Continue;
	}
}

public Action:Hook_ClientBlizzard(entity, client)
{
	if(GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") == client)
	{
		return Plugin_Continue;
	}else{
		return Plugin_Handled;
	}
}  

public FreezeClient(client, attacker, Float:length)
{
	if(RTD_TrinketActive[client][TRINKET_ELEMENTALRES])
	{
		if(RTD_TrinketMisc[client][TRINKET_ELEMENTALRES] < GetTime())
		{
			//apply cooldown
			RTD_TrinketMisc[client][TRINKET_ELEMENTALRES] = GetTime() + RTD_TrinketBonus[client][TRINKET_ELEMENTALRES];
      client_rolls[client][AWARD_G_BLIZZARD][7] = 0;
			return;
		}
	}

	
	new Float:playerspeed[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
	
	if(playerspeed[2] == 0.0)
	{
		ScaleVector(playerspeed, 399.0);
	}else{
		ScaleVector(playerspeed, 1.5);
	}
	
	EmitSoundToAll(SOUND_FROZEN, client);
	SetEntityMoveType(client, MOVETYPE_NONE);
	
	Colorize(client, FROZEN);
	
	if(client != attacker)
	{
		new String:attackername[32];
		GetClientName(attacker, attackername, sizeof(attackername));
		
		PrintCenterText(client, "%s froze you!", attackername);
	}
	
	//The Datapack stores all the Backpack's important values
	new Handle:dataPackHandle;
	CreateDataTimer(length, UnfreezeClient_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, client);   //PackPosition(0);  Backpack Index
	WritePackFloat(dataPackHandle, playerspeed[0]);
	WritePackFloat(dataPackHandle, playerspeed[1]);
	WritePackFloat(dataPackHandle, playerspeed[2]);
}