#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2>
#include <rtd_rollinfo>

public Action:SpawnAndAttachStonewall(client)
{	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Stonewall" );
		return Plugin_Handled;
	}
	
	client_rolls[client][AWARD_G_STONEWALL][0] = 1;
	client_rolls[client][AWARD_G_STONEWALL][1] = ent; //entity index
	
	SetEntityModel(ent, MODEL_STONEWALL);
	
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
	
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0);
	
	new String:name[32];
	GetClientName(client, name, sizeof(name));
	
	//The Datapack stores all the Backpack's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, Stonewall_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, ent);   //PackPosition(0);  Backpack Index
	WritePackCell(dataPackHandle, 0);     //PackPosition(24); Time on floor
	WritePackString(dataPackHandle,name); //the wearer's name
	WritePackCell(dataPackHandle, 0); //x
	WritePackCell(dataPackHandle, 0); //y
	WritePackCell(dataPackHandle, 0); //z
	WritePackCell(dataPackHandle, 0);     //
	
	EmitSoundToAll(SOUND_ITEM_EQUIP,client);
	
	if(IsValidEntity(client_rolls[client][AWARD_G_STONEWALL][2]))
	{
		new currIndex = GetEntProp(client_rolls[client][AWARD_G_STONEWALL][2], Prop_Data, "m_nModelIndex");
		if(currIndex == stonewallModelIndex[0] || currIndex == stonewallModelIndex[1])
		{
			CDetach(client_rolls[client][AWARD_G_STONEWALL][2]);
			killEntityIn(client_rolls[client][AWARD_G_STONEWALL][2], 0.0);
		}
	}
	
	SpawnAndAttachClientStonewall(client);
	return Plugin_Handled;
}

public Action:SpawnAndAttachClientStonewall(client)
{	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create client Stonewall" );
		return Plugin_Handled;
	}
	
	SetEntityModel(ent, MODEL_STONEWALL);
	
	new String:playerName[128];
	Format(playerName, sizeof(playerName), "target%i", client);
	DispatchKeyValue(client, "targetname", playerName);
	
	//Set the Stonewall's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	SDKHook(ent, SDKHook_SetTransmit, Hook_ClientBlizzard); 
	
	DispatchSpawn(ent);
	
	AcceptEntityInput( ent, "DisableShadow" );
	
	CAttach(ent, client, "flag");
	
	AcceptEntityInput( ent, "DisableCollision" );
	
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0);
	
	//The Datapack stores all the Backpack's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, Client_Stonewall_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, ent);   //PackPosition(0);  Backpack Index
	
	client_rolls[client][AWARD_G_STONEWALL][2] = ent;
	
	return Plugin_Handled;
}

public Action:waitAndAttachStoneWall(Handle:timer, any:userId)
{
	new client = GetClientOfUserId(userId);
	
	if(client < 1)
		return Plugin_Stop;
	
	SpawnAndAttachStonewall(client);
	return Plugin_Stop;
}

public Action:Client_Stonewall_Timer(Handle:timer, Handle:dataPackHandle)
{
	ResetPack(dataPackHandle);
	new stonewall = ReadPackCell(dataPackHandle);
	
	if(!IsValidEntity(stonewall))
		return Plugin_Stop;
	
	new currIndex = GetEntProp(stonewall, Prop_Data, "m_nModelIndex");
	if(currIndex != stonewallModelIndex[0])
		return Plugin_Stop;
	
	new wearer = GetEntPropEnt(stonewall, Prop_Data, "m_hOwnerEntity");
	
	if(wearer < 1)
	{
		CDetach(stonewall);
		killEntityIn(stonewall, 0.0);
		
		return Plugin_Stop;
	}else if(!client_rolls[wearer][AWARD_G_STONEWALL][0])
	{
		CDetach(stonewall);
		killEntityIn(stonewall, 0.0);
		itemEquipped_OnBack[wearer] = 0;
		
		return Plugin_Stop;
	}
	
	itemEquipped_OnBack[wearer] = 1;

	//PrintToChat(wearer, "%i | %i| %i", GetEntPropEnt(wearer, Prop_Send, "m_iObserverMode"), GetEntProp(wearer, Prop_Send, "m_iObserverMode"), GetEntProp(wearer, Prop_Send, "m_bDrawViewmodel"));
	if(TF2_IsPlayerInCondition(wearer, TFCond_Taunting) || GetEntProp(wearer, Prop_Send, "m_iObserverMode") > 0 || TF2_IsPlayerInCondition(wearer, TFCond_Bonked) || roundEnded)
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
				SetEntityRenderMode(stonewall, RENDER_TRANSCOLOR);	
				SetEntityRenderColor(stonewall, 255, 255,255, 0);
			}else{
				SetEntityRenderMode(stonewall, RENDER_TRANSCOLOR);	
				SetEntityRenderColor(stonewall, 255, 255,255, alpha);
			}
		}else{
			SetEntityRenderMode(stonewall, RENDER_TRANSCOLOR);	
			SetEntityRenderColor(stonewall, 255, 255,255, alpha);
		}
		
		////////////////////
		// Determine skin //
		////////////////////
		if(playerCond&32)
		{	
			if(GetEntProp(stonewall, Prop_Data, "m_nSkin") == 0)
			{
				if(GetClientTeam(wearer) == BLUE_TEAM)
				{
					DispatchKeyValue(stonewall, "skin","1"); 
				}else{
					DispatchKeyValue(stonewall, "skin","2"); 
				}
			}
		}else{
			if(GetEntProp(stonewall, Prop_Data, "m_nSkin") != 0)
				DispatchKeyValue(stonewall, "skin","0"); 
		}
	}else{
		SetEntityRenderMode(stonewall, RENDER_TRANSCOLOR);	
		SetEntityRenderColor(stonewall, 255, 255,255, 0);
	}
	
	return Plugin_Continue;
}

public stopStonewallTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new stonewall = ReadPackCell(dataPackHandle);
	
	if(!IsValidEntity(stonewall))
		return true;
	
	new currIndex = GetEntProp(stonewall, Prop_Data, "m_nModelIndex");
	if(currIndex != stonewallModelIndex[0] && currIndex != stonewallModelIndex[1])
		return true;
	
	return false;
}

public Action:Stonewall_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopStonewallTimer(dataPackHandle))
		return Plugin_Stop;
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new stonewall = ReadPackCell(dataPackHandle);
	new timeonFloor = ReadPackCell(dataPackHandle);
	new String:backpackname[32];
	ReadPackString(dataPackHandle,backpackname,sizeof(backpackname));
	
	new Float:lastCoordinates[3];
	lastCoordinates[0] = float(ReadPackCell(dataPackHandle));
	lastCoordinates[1] = float(ReadPackCell(dataPackHandle));
	lastCoordinates[2] = float(ReadPackCell(dataPackHandle));
	new nextTime = ReadPackCell(dataPackHandle);
	
	nextTime ++;
	if(nextTime > 5)
		nextTime = 0;
	
	new wearer = GetEntPropEnt(stonewall, Prop_Data, "m_hOwnerEntity");
	
	//There is no owner entity
	if(wearer == -1)
	{
		
		SetEntityRenderMode(stonewall, RENDER_TRANSCOLOR);	
		SetEntityRenderColor(stonewall, 255, 255,255, 255);
		
		timeonFloor ++;
		
		if(timeonFloor >= 400)
		{
			AcceptEntityInput(stonewall,"kill");
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
			
			GetEntPropVector(stonewall, Prop_Send, "m_vecOrigin", backpackPos);
			
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
					if(itemEquipped_OnBack[client])
					{
						if(denyPickup(client, AWARD_G_STONEWALL, true))
							continue;
					}
					
					wearer = client;
					
					new String:name[32];
					GetClientName(client, name, sizeof(name));
					if(!client_rolls[client][AWARD_G_STONEWALL][0])
					{
						
						if(StrEqual(name, backpackname, false))
						{
							PrintCenterText(client, "You picked up your Stonewall");
						}else{
							PrintCenterText(client, "You picked up %s's Stonewall",backpackname);
						}
						
						attachExistingStonewall(client, stonewall);
					}else{
						PrintCenterText(client, "Stonewall Damage Resistance increased for 30s");
						
						//Add extra speed boost
						client_rolls[client][AWARD_G_STONEWALL][4] = GetTime() + 30;
						EmitSoundToAll(SOUND_ITEM_EQUIP,client);
						
						killEntityIn(stonewall, 0.0);
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
			if(!IsPlayerAlive(wearer) || roundEnded || GetEntProp(stonewall, Prop_Data, "m_PerformanceMode") == 66)
			{
				//following is true when it is killed through the entity handler
				//GetEntProp(stonewall, Prop_Data, "m_PerformanceMode") == 66
				
				//destroy the client only model
				if(IsValidEntity(client_rolls[wearer][AWARD_G_STONEWALL][2]))
				{
					new clientonly = GetEntProp(client_rolls[wearer][AWARD_G_STONEWALL][2], Prop_Data, "m_nModelIndex");
					if(clientonly == stonewallModelIndex[0] || clientonly == stonewallModelIndex[1])
					{
						CDetach(client_rolls[wearer][AWARD_G_STONEWALL][2]);
						killEntityIn(client_rolls[wearer][AWARD_G_STONEWALL][2], 0.0);
					}
				}
				
				if(autoBalanced[wearer])
				{
					CDetach(stonewall);
					killEntityIn(stonewall, 0.0);
					return Plugin_Stop;
				}
				
				detachStonewall(stonewall);
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
					SetEntityRenderMode(stonewall, RENDER_TRANSCOLOR);	
					SetEntityRenderColor(stonewall, 255, 255,255, 0);
				}else{
					SetEntityRenderMode(stonewall, RENDER_TRANSCOLOR);	
					SetEntityRenderColor(stonewall, 255, 255,255, alpha);
				}
			}else{
				SetEntityRenderMode(stonewall, RENDER_TRANSCOLOR);	
				SetEntityRenderColor(stonewall, 255, 255,255, alpha);
			}
			
			////////////////////
			// Determine skin //
			////////////////////
			if(playerCond&32)
			{	
				if(GetEntProp(stonewall, Prop_Data, "m_nSkin") == 0)
				{
					if(GetClientTeam(wearer) == BLUE_TEAM)
					{
						DispatchKeyValue(stonewall, "skin","1"); 
					}else{
						DispatchKeyValue(stonewall, "skin","2"); 
					}
				}
			}else{
				if(GetEntProp(stonewall, Prop_Data, "m_nSkin") != 0)
					DispatchKeyValue(stonewall, "skin","0"); 
			}
		}
	}
	
	ResetPack(dataPackHandle);
	WritePackCell(dataPackHandle, stonewall);    //PackPosition(0);  Backpack Index
	WritePackCell(dataPackHandle, timeonFloor); //PackPosition(24); Time on floor
	WritePackString(dataPackHandle,backpackname);
	WritePackCell(dataPackHandle, RoundFloat(lastCoordinates[0])); 
	WritePackCell(dataPackHandle, RoundFloat(lastCoordinates[1])); 
	WritePackCell(dataPackHandle, RoundFloat(lastCoordinates[2])); 
	WritePackCell(dataPackHandle, nextTime); 
	
	return Plugin_Continue;
}

public Drop_Stonewall(client)
{
	//Drop entire backpack
	if(!client_rolls[client][AWARD_G_STONEWALL][0])
		return;
	
	if(!IsValidEntity(client_rolls[client][AWARD_G_STONEWALL][1]))
		return;
	
	new currIndex = GetEntProp(client_rolls[client][AWARD_G_STONEWALL][1], Prop_Data, "m_nModelIndex");
	
	if(currIndex == stonewallModelIndex[0]  || currIndex == stonewallModelIndex[1])
	{
		client_rolls[client][AWARD_G_STONEWALL][0] = 0;
		centerHudText(client, "Stonewall Dropped", 0.1, 5.0, HudMsg3, 0.82); 
		detachStonewall(client_rolls[client][AWARD_G_STONEWALL][1]);
	}
	
	if(!IsClientInGame(client))
		return;
	
}

public detachStonewall(stonewall)
{	
	new owner = GetEntPropEnt(stonewall, Prop_Data, "m_hOwnerEntity");
	
	CDetach(stonewall);
	killEntityIn(stonewall, 0.0);
	
	//Prevent backpack from respawning on roundend
	if(roundEnded)
		return;
	
	if(owner > 0 && owner <= MaxClients)
	{
		//StopSound(owner, SNDCHAN_AUTO, SOUND_SUCK_START);
		//StopSound(owner, SNDCHAN_AUTO, SOUND_SUCK_END);
		
		client_rolls[owner][AWARD_G_STONEWALL][0] = 0;
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
		
		floorPos[2] += 10.0;
		
		new ent = CreateEntityByName("prop_dynamic_override");
		if ( ent == -1 )
		{
			ReplyToCommand( owner, "Failed to create a Stonewall" );
			return;
		}
		
		SetEntityModel(ent, MODEL_STONEWALL_FLOOR);
		
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
		CreateDataTimer(0.1, Stonewall_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
		
		//Setup the datapack with appropriate information
		WritePackCell(dataPackHandle, ent);   //PackPosition(0);  Backpack Index
		WritePackCell(dataPackHandle, 0);     //PackPosition(24); Time on floor
		WritePackString(dataPackHandle, name); //the wearer's name
		WritePackCell(dataPackHandle, 0);     //PackPosition(24); Time on floor
		WritePackCell(dataPackHandle, 0);     //PackPosition(24); Time on floor
		WritePackCell(dataPackHandle, 0);     //PackPosition(24); Time on floor
		WritePackCell(dataPackHandle, 0);     //
		
		TeleportEntity(ent, floorPos, angle, NULL_VECTOR);
		
		EmitSoundToAll(SOUND_ITEM_EQUIP_02,ent);
	}
}

public attachExistingStonewall(client, stonewall)
{
	AcceptEntityInput(stonewall, "kill");
	SpawnAndAttachStonewall(client);
	
	EmitSoundToAll(SOUND_ITEM_EQUIP,client);

}