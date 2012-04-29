#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>

#define BOOST_AMOUNT 8.0


public Jetpack_Player(client, Float:angles[3], buttons)
{
	if(client_rolls[client][AWARD_G_JETPACK][7] == 0)
	{
		return;
	}
	
	new Float:fuelPercent = (float(client_rolls[client][AWARD_G_JETPACK][6])/float(client_rolls[client][AWARD_G_JETPACK][7])) * 100.0;
	if(RoundFloat(fuelPercent) < 1)
		return;
	
	new Float:speed[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", speed);
	
	
	new Float:boost = BOOST_AMOUNT;
	
	if(client_rolls[client][AWARD_G_JETPACK][6] < 100)
		boost = (float(client_rolls[client][AWARD_G_JETPACK][6])/100.0) * BOOST_AMOUNT;
	
	speed[2] += boost;
	
	if(speed[2] < 0.0)
		speed[2] = 200.0;
	
	/* TODO: Do a vector calc to allow the player to change direction in the air
	if (angles[0] < 88.0) {
		USE angles[1] HERE FOR DETERMINING ORIENTATION
	}
	*/
	
	//client_rolls[client][AWARD_G_JETPACK][5] = GetTime();
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, speed);
}

//SOUND_MEDSHOT - played when an item is given to the player from the BackPack
//SOUND_PICKUP  - played when a item is put into the Backpack
//SetEntProp(target, Prop_Send, "m_iObserverMode", observer ? 1 : 0);

//////////////////////////////////////////////////////////////////////////////////////////////////
// Jetpack Variables			        														//
// ---------------------------																	//
//																								//
// client_rolls[client][AWARD_G_JETPACK][0]	=	Enabled?										//
// client_rolls[client][AWARD_G_JETPACK][1]	=	Entity, this refers to the jetpackitself		//
// client_rolls[client][AWARD_G_JETPACK][2]	=													//
// client_rolls[client][AWARD_G_JETPACK][3]	=	Entity that the client sees												//
// client_rolls[client][AWARD_G_JETPACK][4]	=													//
// client_rolls[client][AWARD_G_JETPACK][5]	=													//
// client_rolls[client][AWARD_G_JETPACK][6]	=	Amount of Fuel									//
// client_rolls[client][AWARD_G_JETPACK][7]	=	Total Amount of Fuel					        //
///////////////////////////////////////////////////////////////////////////////////////////////////

public Action:SpawnAndAttachJetpack(client, fuel, totalFuel)
{	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Jetpack!" );
		return Plugin_Handled;
	}
	
	client_rolls[client][AWARD_G_JETPACK][0] = 1;
	client_rolls[client][AWARD_G_JETPACK][1] = EntIndexToEntRef(ent); //entity index
	
	SetEntityModel(ent, MODEL_JETPACK);
	
	new String:playerName[128];
	Format(playerName, sizeof(playerName), "target%i", client);
	DispatchKeyValue(client, "targetname", playerName);
	
	//Set the Jetpack's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	SDKHook(ent, SDKHook_SetTransmit, Hook_EveryoneBlizzard); 
	
	DispatchSpawn(ent);
	
	AcceptEntityInput( ent, "DisableShadow" );
	
	CAttach(ent, client, "flag");
	
	AcceptEntityInput( ent, "DisableCollision" );
	
	new String:name[32];
	GetClientName(client, name, sizeof(name));
	
	//The Datapack stores all the Jetpack's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, Jetpack_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(ent));   //PackPosition(0);  Jetpack Index
	WritePackCell(dataPackHandle, 0);			//PackPosition(8);  Time on floor
	WritePackCell(dataPackHandle, fuel);		//PackPosition(16); Amount of fuel
	WritePackCell(dataPackHandle, totalFuel);	//PackPosition(24); Total Amount of fuel
	WritePackString(dataPackHandle,name); 		//PackPosition(32)  The wearer's name
	WritePackCell(dataPackHandle, -1);	//PackPosition(40); Particle1
	WritePackCell(dataPackHandle, -1);	//PackPosition(48); Particle2
	
	EmitSoundToAll(SOUND_ITEM_EQUIP,client);
	
	client_rolls[client][AWARD_G_JETPACK][6] = fuel;
	client_rolls[client][AWARD_G_JETPACK][7] = totalFuel;
	
	SpawnAndAttachClientJetPack(client);
	
	//name the jetpack
	new String:jetpackName[128];
	Format(jetpackName, sizeof(jetpackName), "jetpack%i", ent);
	DispatchKeyValue(ent, "targetname", jetpackName);
	
	return Plugin_Handled;
}

public Action:SpawnAndAttachClientJetPack(client)
{	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Jetpack!" );
		return Plugin_Handled;
	}
	
	SetEntityModel(ent, MODEL_JETPACK);
	
	new String:playerName[128];
	Format(playerName, sizeof(playerName), "target%i", client);
	DispatchKeyValue(client, "targetname", playerName);
	
	//Set the Jetpack's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	SDKHook(ent, SDKHook_SetTransmit, Hook_ClientBlizzard); 
	
	DispatchSpawn(ent);
	
	AcceptEntityInput( ent, "DisableShadow" );
	
	CAttach(ent, client, "flag");
	
	AcceptEntityInput( ent, "DisableCollision" );
	
	//The Datapack stores all the Jetpack's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, Client_Jetpack_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(ent));   //PackPosition(0);  Jetpack Index
	
	client_rolls[client][AWARD_G_JETPACK][3] = EntIndexToEntRef(ent); //entity index
	
	return Plugin_Handled;
}

public Action:Client_Jetpack_Timer(Handle:timer, Handle:dataPackHandle)
{
	ResetPack(dataPackHandle);
	new jetpack = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	if(jetpack < 1)
		return Plugin_Stop;
	
	if(!IsValidEntity(jetpack))
		return Plugin_Stop;
	
	new wearer = GetEntPropEnt(jetpack, Prop_Data, "m_hOwnerEntity");
	
	if(wearer < 1)
	{
		CDetach(jetpack);
		killEntityIn(jetpack, 0.0);
		
		return Plugin_Stop;
	}else if(!client_rolls[wearer][AWARD_G_JETPACK][0])
	{
		CDetach(jetpack);
		killEntityIn(jetpack, 0.0);
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
				SetEntityRenderMode(jetpack, RENDER_TRANSCOLOR);	
				SetEntityRenderColor(jetpack, 255, 255,255, 0);
			}else{
				SetEntityRenderMode(jetpack, RENDER_TRANSCOLOR);	
				SetEntityRenderColor(jetpack, 255, 255,255, alpha);
			}
		}else{
			SetEntityRenderMode(jetpack, RENDER_TRANSCOLOR);	
			SetEntityRenderColor(jetpack, 255, 255,255, alpha);
		}
		
		////////////////////
		// Determine skin //
		////////////////////
		if(playerCond&32)
		{	
			if(GetEntProp(jetpack, Prop_Data, "m_nSkin") == 0)
			{
				if(GetClientTeam(wearer) == BLUE_TEAM)
				{
					DispatchKeyValue(jetpack, "skin","1"); 
				}else{
					DispatchKeyValue(jetpack, "skin","2"); 
				}
			}
		}else{
			if(GetEntProp(jetpack, Prop_Data, "m_nSkin") != 0)
				DispatchKeyValue(jetpack, "skin","0"); 
		}
	}else{
		SetEntityRenderMode(jetpack, RENDER_TRANSCOLOR);	
		SetEntityRenderColor(jetpack, 255, 255,255, 0);
	}
	
	return Plugin_Continue;
}

public createJetpackFlames(jetpack, Handle:dataPackHandle)
{
	ResetPack(dataPackHandle);
	SetPackPosition(dataPackHandle, 40);
	
	new Float: jetpackPos[3];
	new Float: jetpackAngle[3];
	GetEntPropVector(jetpack, Prop_Send, "m_vecOrigin", jetpackPos);
	GetEntPropVector(jetpack, Prop_Data, "m_angRotation", jetpackAngle);
	
	new flame1 = CreateEntityByName("info_particle_system");
	if (IsValidEntity(flame1))
	{		
		TeleportEntity(flame1, jetpackPos, jetpackAngle, NULL_VECTOR);
		
		DispatchKeyValue(flame1, "effect_name", "flamethrower");
		DispatchSpawn(flame1);
		
		//Now lets parent the flames to the spider
		new String:jetpackName[128];
		Format(jetpackName, sizeof(jetpackName), "jetpack%i", jetpack);
		
		SetVariantString(jetpackName);
		AcceptEntityInput(flame1, "SetParent");
		
		SetVariantString("Right_Fuel");
		AcceptEntityInput(flame1, "SetParentAttachment", flame1, flame1, 0);
		
		ActivateEntity(flame1);
		AcceptEntityInput(flame1, "start");
		
	}
	
	new flame2 = CreateEntityByName("info_particle_system");
	if (IsValidEntity(flame2))
	{
		TeleportEntity(flame2, jetpackPos, jetpackAngle, NULL_VECTOR);
		
		DispatchKeyValue(flame2, "effect_name", "flamethrower");
		DispatchSpawn(flame2);
		
		//Now lets parent the flames to the spider
		new String:jetpackName[128];
		Format(jetpackName, sizeof(jetpackName), "jetpack%i", jetpack);
		
		SetVariantString(jetpackName);
		AcceptEntityInput(flame2, "SetParent");
		
		SetVariantString("Left_Fuel");
		AcceptEntityInput(flame2, "SetParentAttachment", flame1, flame1, 0);
		
		ActivateEntity(flame2);
		AcceptEntityInput(flame2, "start");
	}
	
	WritePackCell(dataPackHandle, EntIndexToEntRef(flame1));	//PackPosition(40); Particle1
	WritePackCell(dataPackHandle, EntIndexToEntRef(flame2));	//PackPosition(48); Particle2
}

public Action:Jetpack_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopJetpackTimer(dataPackHandle))
	{
		return Plugin_Stop;
	}
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new jetpack = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new timeonFloor = ReadPackCell(dataPackHandle);
	new fuel = ReadPackCell(dataPackHandle);
	new totalFuel = ReadPackCell(dataPackHandle);
	
	new String:jetpackname[32];
	ReadPackString(dataPackHandle,jetpackname,sizeof(jetpackname));
	
	new flame1 = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new flame2 = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	new wearer = GetEntPropEnt(jetpack, Prop_Data, "m_hOwnerEntity");
	
	//There is no owner entity
	if(wearer == -1)
	{
		SetEntityRenderMode(jetpack, RENDER_TRANSCOLOR);	
		SetEntityRenderColor(jetpack, 255, 255,255, 255);
		
		timeonFloor ++;
		
		if(timeonFloor >= 200)
		{
			StopSound(jetpack, SNDCHAN_AUTO, SOUND_FlameLoop);
			AcceptEntityInput(jetpack,"kill");
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
			
			GetEntPropVector(jetpack, Prop_Send, "m_vecOrigin", backpackPos);
			
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
					
					if(client_rolls[client][AWARD_G_JETPACK][0])
					{	
						PrintCenterText(client, "Jetpack refueled!");
						EmitSoundToAll(SOUND_ITEM_EQUIP,client);
						client_rolls[client][AWARD_G_JETPACK][6] = client_rolls[client][AWARD_G_JETPACK][7];
						
						killEntityIn(jetpack, 0.0);
						
						StopSound(jetpack, SNDCHAN_AUTO, SOUND_FlameLoop);
						return Plugin_Stop;
					}
					
					if(client_rolls[client][AWARD_G_SPIDER][1] != 0)
					{
						PrintCenterText(client, "Can't pick up Jetpack with Spider on you!");
						continue;
					}
					
					if(client_rolls[client][AWARD_G_BACKPACK][0])
					{
						PrintCenterText(client, "Can't pick up Jetpack with Backpack equipped!");
						continue;
					}
					
					if(client_rolls[client][AWARD_G_WINGS][0])
					{
						PrintCenterText(client, "Can't pick up Jetpack with Redbull equipped!");
						continue;
					}
					
					if(client_rolls[client][AWARD_G_TREASURE][0])
					{
						PrintCenterText(client, "Can't pick up Jetpack with Treasure Chest equipped!");
						continue;
					}
					
					if(itemEquipped_OnBack[client])
					{
						if(denyPickup(client, AWARD_G_JETPACK, true))
							continue;
						
						//PrintCenterText(client, "Can't pick up while an item is equipped!");
					}
					
					wearer = client;
					
					new String:name[32];
					GetClientName(client, name, sizeof(name));
					if(!client_rolls[client][AWARD_G_JETPACK][0])
					{
						
						if(StrEqual(name, jetpackname, false))
						{
							PrintCenterText(client, "You picked up your Jetpack");
						}else{
							PrintCenterText(client, "You picked up %s's Jetpack",jetpackname);
						}
						
						attachExistingJetpack(client, jetpack, fuel, totalFuel);
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
			if(!IsPlayerAlive(wearer) || !client_rolls[wearer][AWARD_G_JETPACK][0])
			{
				if(GetEntProp(jetpack, Prop_Data, "m_PerformanceMode") != 999)
					detachJetpack(jetpack, fuel, totalFuel);
				
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
					SetEntityRenderMode(jetpack, RENDER_TRANSCOLOR);	
					SetEntityRenderColor(jetpack, 255, 255,255, 0);
				}else{
					SetEntityRenderMode(jetpack, RENDER_TRANSCOLOR);	
					SetEntityRenderColor(jetpack, 255, 255,255, alpha);
				}
			}else{
				SetEntityRenderMode(jetpack, RENDER_TRANSCOLOR);	
				SetEntityRenderColor(jetpack, 255, 255,255, alpha);
			}
			
			////////////////////
			// Determine skin //
			////////////////////
			if(playerCond&32)
			{	
				if(GetEntProp(jetpack, Prop_Data, "m_nSkin") == 0)
				{
					if(GetClientTeam(wearer) == BLUE_TEAM)
					{
						DispatchKeyValue(jetpack, "skin","1"); 
					}else{
						DispatchKeyValue(jetpack, "skin","2"); 
					}
				}
			}else{
				if(GetEntProp(jetpack, Prop_Data, "m_nSkin") != 0)
					DispatchKeyValue(jetpack, "skin","0"); 
			}
			
			new Float:fuelPercent = (float(fuel)/float(totalFuel)) * 100.0;
			if(fuelPercent < 0.0)
				fuelPercent = 0.0;
				
			if(!client_rolls[wearer][AWARD_G_BACKPACK][0] && !inTimerBasedRoll[wearer])
			{	
				SetHudTextParams(0.03, 0.04, 3.0, 250, 250, 210, 255);
				
				ShowHudText(wearer, HudMsg5, "Jetpack Fuel: %i/100", RoundFloat(fuelPercent));
			}
			
			if(client_rolls[wearer][AWARD_G_JETPACK][5] && RoundFloat(fuelPercent) > 0)
			{
				fuel -= 15;
				
				if(flame1 < 1 || flame2 < 1)
				{
					if(flame1 > 1)
						AcceptEntityInput(flame1, "kill");
					
					if(flame2 > 1)
						AcceptEntityInput(flame2, "kill");
					
					createJetpackFlames(jetpack, dataPackHandle);
					
					StopSound(jetpack, SNDCHAN_AUTO, SOUND_FlameLoop);
					
					
					EmitSoundToAll(SOUND_FlameStart,jetpack);
					
					ResetPack(dataPackHandle);
					SetPackPosition(dataPackHandle, 40);
					flame1 = EntRefToEntIndex(ReadPackCell(dataPackHandle));
					flame2 = EntRefToEntIndex(ReadPackCell(dataPackHandle));
					
					CreateTimer(0.4, delay_FlameLoop, EntIndexToEntRef(jetpack), TIMER_FLAG_NO_MAPCHANGE);
					
				}
			}else{
				//destroy flames
				if(flame1 > 1)
				{
					AcceptEntityInput(flame1, "kill");
					flame1 = 0;
					
					//StopSound(jetpack, SNDCHAN_AUTO, SOUND_FlameLoop);
				}
				
				if(flame2 > 1)
				{
					AcceptEntityInput(flame2, "kill");
					flame2 = 0;
					
					//StopSound(jetpack, SNDCHAN_AUTO, SOUND_FlameLoop);
					CreateTimer(0.0, delay_FlameEnd, EntIndexToEntRef(jetpack), TIMER_FLAG_NO_MAPCHANGE);
				}
				
				StopSound(jetpack, SNDCHAN_AUTO, SOUND_FlameLoop);
			}
			
			client_rolls[wearer][AWARD_G_JETPACK][6] = fuel;
			
			if(RTD_Perks[wearer][60])
				fuel += 2;
		}
	}
	
	
	//Increment fuel
	
	fuel += 2;
	if(fuel > totalFuel)
		fuel = totalFuel;
	
	
	
	ResetPack(dataPackHandle);
	WritePackCell(dataPackHandle, EntIndexToEntRef(jetpack));    //PackPosition(0);  Jetpack Index
	WritePackCell(dataPackHandle, timeonFloor); //PackPosition(24); Time on floor
	WritePackCell(dataPackHandle, fuel); //PackPosition(24); Time on floor
	WritePackCell(dataPackHandle, totalFuel); //PackPosition(24); Time on floor
	WritePackString(dataPackHandle,jetpackname);
	
	if(flame1 > 1)
	{
		WritePackCell(dataPackHandle, EntIndexToEntRef(flame1));
	}else{
		WritePackCell(dataPackHandle, -1); 
	}
	
	if(flame2 > 1)
	{
		WritePackCell(dataPackHandle, EntIndexToEntRef(flame2));
	}else{
		WritePackCell(dataPackHandle, -1);
	}
	
	//PrintToChatAll("Jetpack: %i | Fuel:%i |TFuel:%i | CFuel:%i", jetpack, fuel, totalFuel, client_rolls[wearer][AWARD_G_JETPACK][6]);
	
	return Plugin_Continue;
}

public Action:delay_FlameLoop(Handle:timer, any:entRef)
{
	new jetpack = EntRefToEntIndex(entRef);
	
	if(jetpack < 1)
		return Plugin_Stop;
	
	//PrintToChatAll("Starting flame loop");
	
	StopSound(jetpack, SNDCHAN_AUTO, SOUND_FlameStart);
	EmitSoundToAll(SOUND_FlameLoop,jetpack);
	
	return Plugin_Stop;
}

public Action:delay_FlameEnd(Handle:timer, any:entRef)
{
	new jetpack = EntRefToEntIndex(entRef);
	
	if(jetpack < 1)
		return Plugin_Stop;
	
	//PrintToChatAll("Starting flame loop");
	
	StopSound(jetpack, SNDCHAN_AUTO, SOUND_FlameStart);
	EmitSoundToAll(SOUND_FlameEnd,jetpack);
	
	return Plugin_Stop;
}

public attachExistingJetpack(client, jetpack, fuel, totalFuel)
{
	AcceptEntityInput(jetpack, "kill");
	StopSound(jetpack, SNDCHAN_AUTO, SOUND_FlameLoop);
	
	SpawnAndAttachJetpack(client, fuel, totalFuel);
	
	EmitSoundToAll(SOUND_ITEM_EQUIP,client);

}

public spawnJetpack(Float:pos[3], fuel, totalFuel, String:name[])
{
	///////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Create jetpack on floor                                                                               //
	///////////////////////////////////////////////////////////////////////////////////////////////////////////
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		//ReplyToCommand( client, "Failed to create a Jetpack!" );
		return;
	}
	
	SetEntityModel(ent, MODEL_JETPACK);
	
	//Set the Jetpack's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", -1);
	
	DispatchSpawn(ent);
	
	AcceptEntityInput( ent, "DisableShadow" );
	
	AcceptEntityInput( ent, "DisableCollision" );
	
	//The Datapack stores all the Jetpack's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, Jetpack_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(ent));   //PackPosition(0);  Jetpack Index
	WritePackCell(dataPackHandle, 0);			//PackPosition(8);  Time on floor
	WritePackCell(dataPackHandle, fuel);		//PackPosition(16); Amount of fuel
	WritePackCell(dataPackHandle, totalFuel);	//PackPosition(24); Total Amount of fuel
	WritePackString(dataPackHandle,name); 		//PackPosition(32)  The wearer's name
	WritePackCell(dataPackHandle, -1);	//PackPosition(40); Particle1
	WritePackCell(dataPackHandle, -1);	//PackPosition(48); Particle2
	
	//name the jetpack
	new String:jetpackName[128];
	Format(jetpackName, sizeof(jetpackName), "jetpack%i", ent);
	DispatchKeyValue(ent, "targetname", jetpackName);
	
	SetVariantString("rotate");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	
	EmitSoundToAll(SOUND_ITEM_EQUIP_02,ent);
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
}

public detachJetpack(jetpack, fuel, totalFuel)
{
	new owner = GetEntPropEnt(jetpack, Prop_Data, "m_hOwnerEntity");
	
	SetEntProp(jetpack, Prop_Data, "m_PerformanceMode", 999);
	
	CDetach(jetpack);
	killEntityIn(jetpack, 0.0);
	StopSound(jetpack, SNDCHAN_AUTO, SOUND_FlameLoop);
	
	//Prevent jetpack from respawning on roundend
	if(roundEnded)
		return;
	
	new String:name[32];
	
	if(owner > 0 && owner <= MaxClients)
	{
		client_rolls[owner][AWARD_G_JETPACK][0] = 0;
		itemEquipped_OnBack[owner] = 0;
		
		client_rolls[owner][AWARD_G_JETPACK][1] = 0; //everyone entity
		client_rolls[owner][AWARD_G_JETPACK][3] = 0; //client only entity
		client_rolls[owner][AWARD_G_JETPACK][6] = 0;
		client_rolls[owner][AWARD_G_JETPACK][7] = 0;
		
		GetClientName(owner, name, sizeof(name));
	}
	
	new Float:pos[3];
	GetEntPropVector(jetpack, Prop_Data, "m_vecAbsOrigin", pos);
	
	//PrintToChatAll("%f | %f | %f", pos[0], pos[1], pos[2]);
	
	new Float:Direction[3];
	Direction[0] = pos[0];
	Direction[1] = pos[1];
	Direction[2] = pos[2]-1024;
	
	new Float:floorPos[3];
	
	new Handle:Trace = TR_TraceRayFilterEx(pos, Direction, MASK_SOLID, RayType_EndPoint, TraceFilterAll, owner);
	TR_GetEndPosition(floorPos, Trace);
	CloseHandle(Trace);
	
	floorPos[2] += 10.0;
	
	//////////////////////////
	// Delay spawn          //
	//////////////////////////
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, Delay_JetpackSpawn, dataPackHandle, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackFloat(dataPackHandle, floorPos[0]);   //PackPosition(0);  Jetpack Index
	WritePackFloat(dataPackHandle, floorPos[1]);   //PackPosition(0);  Jetpack Index
	WritePackFloat(dataPackHandle, floorPos[2]);   //PackPosition(0);  Jetpack Index
	WritePackCell(dataPackHandle, fuel);
	WritePackCell(dataPackHandle, totalFuel);
	WritePackString(dataPackHandle, name);
}

public Action:Delay_JetpackSpawn(Handle:timer, Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	
	new Float:floorPos[3];
	new String:name[32];
	
	floorPos[0] = ReadPackFloat(dataPackHandle);
	floorPos[1] = ReadPackFloat(dataPackHandle);
	floorPos[2] = ReadPackFloat(dataPackHandle);
	
	new fuel = ReadPackCell(dataPackHandle);
	new totalFuel = ReadPackCell(dataPackHandle);
	ReadPackString(dataPackHandle, name, sizeof(name));
	
	spawnJetpack(floorPos, fuel, totalFuel, name);
	return Plugin_Stop;
}

public stopJetpackTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new jetpack = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	if(jetpack < 1 )
		return true;
	
	if(!IsValidEntity(jetpack))
	{
		//PrintToChatAll("Invalid Blizard entity");
		return true;
	}
	
	return false;
}

public Drop_Jetpack(client)
{
	//Drop entire Jetpack
	if(!client_rolls[client][AWARD_G_JETPACK][0])
		return;
	
	client_rolls[client][AWARD_G_JETPACK][0] = 0;
	
	new jetpack = EntRefToEntIndex(client_rolls[client][AWARD_G_JETPACK][1]);
	
	if(jetpack < 1)
		return;
	
	if(!IsValidEntity(jetpack))
		return;
	
	//PrintToChatAll("Dropping: %i", jetpack);
	centerHudText(client, "Jetpack Dropped", 0.1, 5.0, HudMsg3, 0.82); 
	
	detachJetpack(jetpack, client_rolls[client][AWARD_G_JETPACK][6], client_rolls[client][AWARD_G_JETPACK][7]);
	
	
	
}