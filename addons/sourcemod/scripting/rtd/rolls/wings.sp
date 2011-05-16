#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <attachments>
#include <rtd_rollinfo>

//SOUND_MEDSHOT - played when an item is given to the player from the BackPack
//SOUND_PICKUP  - played when a item is put into the Backpack
//SetEntProp(target, Prop_Send, "m_iObserverMode", observer ? 1 : 0);

///////////////////////////////////////////////////////////////////////////////////////////////
// Wings Variables																			//
// ---------------------------																//
//																							//
// client_rolls[client][AWARD_G_WINGS][0]	=	Enabled?									//
// client_rolls[client][AWARD_G_WINGS][1]	=	Entity, this refers to itself 				//
///////////////////////////////////////////////////////////////////////////////////////////////

public Action:SpawnAndAttachWings(client)
{	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create wings!" );
		return Plugin_Handled;
	}
	
	client_rolls[client][AWARD_G_WINGS][0] = 1;
	client_rolls[client][AWARD_G_WINGS][1] = ent; //entity index
	
	SetEntityModel(ent, MODEL_WINGS);
	
	new String:playerName[128];
	Format(playerName, sizeof(playerName), "target%i", client);
	DispatchKeyValue(client, "targetname", playerName);
	
	//Set the wings's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	DispatchSpawn(ent);
	
	AcceptEntityInput( ent, "DisableShadow" );
	//AcceptEntityInput( ent, "DisableShadow" );
	
	CAttach(ent, client, "flag");
	
	AcceptEntityInput( ent, "DisableCollision" );
	
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	new String:name[32];
	GetClientName(client, name, sizeof(name));
	
	//The Datapack stores all the Backpack's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, Wings_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, ent);   //PackPosition(0);  Wings Index
	WritePackCell(dataPackHandle, 0);     //PackPosition(24); Time on floor
	WritePackString(dataPackHandle,name); //the wearer's name
	
	
	EmitSoundToAll(SOUND_ITEM_EQUIP,client);
	
	return Plugin_Handled;
}

public Action:Wings_Timer(Handle:timer, Handle:dataPackHandle)
{
	ResetPack(dataPackHandle);
	new wings = ReadPackCell(dataPackHandle);
	new timeonFloor = ReadPackCell(dataPackHandle);
	new String:wingsOwnerName[32];
	ReadPackString(dataPackHandle,wingsOwnerName,sizeof(wingsOwnerName));
	
	if(stopwingsTimer(dataPackHandle))
		return Plugin_Stop;
	
	new wearer = GetEntPropEnt(wings, Prop_Data, "m_hOwnerEntity");
	
	//There is no owner entity
	if(wearer == -1)
	{
		SetEntityRenderMode(wings, RENDER_TRANSCOLOR);	
		SetEntityRenderColor(wings, 255, 255,255, 255);
		
		timeonFloor ++;
		
		if(timeonFloor >= 400)
		{
			AcceptEntityInput(wings,"kill");
			return Plugin_Stop;
		}
		
		if(timeonFloor > 20)
		{
			//Check to see if there is a nearby player
			new Float: wingsPos[3];
			new Float: clientFeetPos[3];
			new Float: distanceFromFeet;
			
			GetEntPropVector(wings, Prop_Send, "m_vecOrigin", wingsPos);
			
			for(new client=1; client <= MaxClients; client++)
			{
				//player is not here let's skip
				if (!IsClientInGame(client) || !IsPlayerAlive(client))
					continue;
				
				//Get the player's postion 
				GetClientAbsOrigin(client, clientFeetPos);
				
				distanceFromFeet = GetVectorDistance(clientFeetPos, wingsPos);
				
				if(distanceFromFeet < 50.0)
				{
					if(denyPickup(client, AWARD_G_WINGS, true))
						continue;	
					
					if(client_rolls[client][AWARD_G_WINGS][0])
					{
						//Add extra speed boost
						client_rolls[client][AWARD_G_WINGS][4] = GetTime() + 20;
						
						PrintCenterText(client, "Extra Speed Boost for 20 seconds! GO!!!");
						EmitSoundToAll(SOUND_ITEM_EQUIP,client);
						
						killEntityIn(wings, 0.0);
						return Plugin_Stop;
					}
					
					wearer = client;
					
					new String:name[32];
					GetClientName(client, name, sizeof(name));
					if(!client_rolls[client][AWARD_G_WINGS][0])
					{
						
						if(StrEqual(name, wingsOwnerName, false))
						{
							PrintCenterText(client, "You picked up your Redbull");
						}else{
							PrintCenterText(client, "You picked up %s's Redbull",wingsOwnerName);
						}
						
						killEntityIn(wings, 0.0);
						SpawnAndAttachWings(client);
						return Plugin_Stop;
					}
					
					EmitSoundToAll(SSphere_Heal,wearer);
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
				detachwings(wings);
				return Plugin_Stop;
			}
			
			itemEquipped_OnBack[wearer] = 1;
			
			new buttons = GetClientButtons(wearer);
			new sequence = GetEntProp(wings, Prop_Data, "m_nSequence");
			if(buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_WALK || buttons & IN_RUN )
			{
				if(sequence != 1)
				{
					SetVariantString("flap");
					AcceptEntityInput(wings, "SetAnimation", -1, -1, 0); 
				}
			}else{
				if(sequence != 0)
				{
					SetVariantString("idle");
					AcceptEntityInput(wings, "SetAnimation", -1, -1, 0); 
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
					SetEntityRenderMode(wings, RENDER_TRANSCOLOR);	
					SetEntityRenderColor(wings, 255, 255,255, 0);
				}else{
					SetEntityRenderMode(wings, RENDER_TRANSCOLOR);	
					SetEntityRenderColor(wings, 255, 255,255, alpha);
				}
			}else{
				if(hasInvisRolls(wearer))
				{
					SetEntityRenderMode(wings, RENDER_TRANSCOLOR);	
					SetEntityRenderColor(wings, 255, 255,255, 0);
				}else{
					SetEntityRenderMode(wings, RENDER_TRANSCOLOR);	
					SetEntityRenderColor(wings, 255, 255,255, 255);
				}
			}
			
			////////////////////
			// Determine skin //
			////////////////////
			if(playerCond&32)
			{	
				if(GetEntProp(wings, Prop_Data, "m_nSkin") != 2 && GetEntProp(wings, Prop_Data, "m_nSkin") != 3)
				{
					if(GetClientTeam(wearer) == BLUE_TEAM)
					{
						if(GetEntProp(wings, Prop_Data, "m_nSkin") != 1)
							DispatchKeyValue(wings, "skin","1"); 
					}else{
						if(GetEntProp(wings, Prop_Data, "m_nSkin") != 2)
							DispatchKeyValue(wings, "skin","2"); 
					}
				}
			}else{
				if(GetEntProp(wings, Prop_Data, "m_nSkin") != 0)
					DispatchKeyValue(wings, "skin","0"); 
			}
			
			if(GetTime() < client_rolls[wearer][AWARD_G_WINGS][4] && client_rolls[wearer][AWARD_G_WINGS][4] != 0)
			{
				PrintCenterText(wearer, "Extra Speed Boost for %i seconds!", client_rolls[wearer][AWARD_G_WINGS][4] - GetTime());
			}
		}
	}
	
	ResetPack(dataPackHandle);
	WritePackCell(dataPackHandle, wings);    //PackPosition(0);  Backpack Index
	WritePackCell(dataPackHandle, timeonFloor); //PackPosition(24); Time on floor
	WritePackString(dataPackHandle, wingsOwnerName);
	
	return Plugin_Continue;
}

public detachwings(wings)
{
	CDetach(wings);
	
	new owner = GetEntPropEnt(wings, Prop_Data, "m_hOwnerEntity");
	SetEntPropEnt(wings, Prop_Send, "m_hOwnerEntity", -1);
	
	EmitSoundToAll(SOUND_ITEM_EQUIP_02,wings);
	
	//Prevent wings from respawning on roundend
	if(roundEnded)
		return;
	
	killEntityIn(wings, 0.0);
	
	if(owner > 0 && owner <= MaxClients)
	{
		client_rolls[owner][AWARD_G_WINGS][0] = 0;
		itemEquipped_OnBack[owner] = 0;
		
		//Create new wings entity---------------------------
		new ent = CreateEntityByName("prop_dynamic_override");
		if ( ent == -1 )
		{
			return;
		}
		
		SetEntityModel(ent, MODEL_REDBULL);
		
		//Set the wings's owner
		SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", -1);
		
		DispatchSpawn(ent);
		
		SetVariantString("idle");
		AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
		
		AcceptEntityInput( ent, "DisableCollision" );
		
		new String:playerName[128];
		GetClientName(owner, playerName, sizeof(playerName));
		new Handle:dataPackHandle;
		CreateDataTimer(0.1, Wings_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
		
		//Setup the datapack with appropriate information
		WritePackCell(dataPackHandle, ent);   //PackPosition(0);  Wings Index
		WritePackCell(dataPackHandle, 0);     //PackPosition(24); Time on floor
		WritePackString(dataPackHandle,playerName); //the wearer's name
		//End of creation-----------------------------------
		
		ResetClientSpeed(owner);
		
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
		
		floorPos[2] += 30.0;
		
		TeleportEntity(ent, floorPos, angle, NULL_VECTOR);
	}
}

public stopwingsTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new wings = ReadPackCell(dataPackHandle);
	
	if(!IsValidEntity(wings))
	{
		//PrintToChatAll("Invalid entity");
		return true;
	}
	
	new currIndex = GetEntProp(wings, Prop_Data, "m_nModelIndex");
	if(currIndex != wingsModelIndex && currIndex != redbullModelIndex )
	{
		//PrintToChatAll("Invalid model");
		return true;
	}
	
	return false;
}

public Drop_Wings(client)
{
	//Drop entire backpack
	if(!client_rolls[client][AWARD_G_WINGS][0])
		return;
	
	if(!IsValidEntity(client_rolls[client][AWARD_G_WINGS][1]))
		return;
	
	new currIndex = GetEntProp(client_rolls[client][AWARD_G_WINGS][1], Prop_Data, "m_nModelIndex");
	
	if(currIndex == wingsModelIndex)
	{
		client_rolls[client][AWARD_G_WINGS][0] = 0;
		centerHudText(client, "Redbull Dropped", 0.1, 5.0, HudMsg3, 0.82); 
		detachwings(client_rolls[client][AWARD_G_WINGS][1]);
		
	}
}