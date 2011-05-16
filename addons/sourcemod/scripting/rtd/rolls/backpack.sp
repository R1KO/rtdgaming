#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <attachments>
#include <rtd_rollinfo>

//SOUND_MEDSHOT - played when an item is given to the player from the BackPack
//SOUND_PICKUP  - played when a item is put into the Backpack

/*
	client_rolls[client][AWARD_G_BACKPACK][0] //is Player using it
	client_rolls[client][AWARD_G_BACKPACK][1] //entity index
	client_rolls[client][AWARD_G_BACKPACK][2] //ammopacks
	client_rolls[client][AWARD_G_BACKPACK][3] //healthpacks
	client_rolls[client][AWARD_G_BACKPACK][6] //mark the time that the player press L
	client_rolls[client][AWARD_G_BACKPACK][7] //Next time the player can drop an item
*/
	
public Action:SpawnAndAttachBackpack(client)
{	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Backpack!" );
		return Plugin_Handled;
	}
	
	client_rolls[client][AWARD_G_BACKPACK][0] = 1;
	client_rolls[client][AWARD_G_BACKPACK][1] = ent; //entity index
	
	new amountOfItems = client_rolls[client][AWARD_G_BACKPACK][2] + client_rolls[client][AWARD_G_BACKPACK][3];
	
	if(amountOfItems <= 2) 
		SetEntityModel(ent, MODEL_BACKPACK01);
	
	if(amountOfItems > 2 && amountOfItems <= 5) 
		SetEntityModel(ent, MODEL_BACKPACK02);
	
	if(amountOfItems > 5 && amountOfItems <= 9) 
		SetEntityModel(ent, MODEL_BACKPACK03);
	
	if(amountOfItems >= 10) 
		SetEntityModel(ent, MODEL_BACKPACK04);
		
	new String:playerName[128];
	Format(playerName, sizeof(playerName), "target%i", client);
	DispatchKeyValue(client, "targetname", playerName);
	
	//Set the Backpack's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	DispatchSpawn(ent);
	
	AcceptEntityInput( ent, "DisableShadow" );
	
	CAttach(ent, client, "flag");
	
	AcceptEntityInput( ent, "DisableCollision" );
	
	new String:name[32];
	GetClientName(client, name, sizeof(name));
	
	//The Datapack stores all the Backpack's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, Backpack_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, ent);   //PackPosition(0);  Backpack Index
	WritePackCell(dataPackHandle, client_rolls[client][AWARD_G_BACKPACK][2]);     //PackPosition(8) ;  Amount of ammopacks
	WritePackCell(dataPackHandle, client_rolls[client][AWARD_G_BACKPACK][3]);     //PackPosition(16); Amount of healthpacks
	WritePackCell(dataPackHandle, 0);     //PackPosition(24); Time on floor
	WritePackCell(dataPackHandle, GetTime());     //PackPosition(32); Last injection time
	WritePackCell(dataPackHandle, TF2_GetPlayerResourceData(client, TFResource_TotalScore));     //PackPosition(40); Old Score
	WritePackString(dataPackHandle,name); //the weare's name
	
	EmitSoundToAll(SOUND_ITEM_EQUIP,client);
	
	//CreateAnnotation(ent, "Backpack", 0, 0);
	
	return Plugin_Handled;
}

public Action:Backpack_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopBackPackTimer(dataPackHandle))
		return Plugin_Stop;
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new backpack = ReadPackCell(dataPackHandle);
	new ammopacks = ReadPackCell(dataPackHandle);
	new healthpacks = ReadPackCell(dataPackHandle);
	new timeonFloor = ReadPackCell(dataPackHandle);
	new lastInjection = ReadPackCell(dataPackHandle);
	new temp_oldScore = ReadPackCell(dataPackHandle);
	new String:backpackname[32];
	ReadPackString(dataPackHandle,backpackname,sizeof(backpackname));
	
	new wearer = GetEntPropEnt(backpack, Prop_Data, "m_hOwnerEntity");
	
	//There is no owner entity
	if(wearer == -1)
	{
		SetEntityRenderMode(backpack, RENDER_TRANSCOLOR);	
		SetEntityRenderColor(backpack, 255, 255,255, 255);
		
		timeonFloor ++;
		
		if(timeonFloor >= 350)
		{
			AcceptEntityInput(backpack,"kill");
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
			
			GetEntPropVector(backpack, Prop_Send, "m_vecOrigin", backpackPos);
			
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
					if(denyPickup(client, AWARD_G_BACKPACK, true))
						continue;
					
					wearer = client;
					
					new String:name[32];
					GetClientName(client, name, sizeof(name));
					if(!client_rolls[client][AWARD_G_BACKPACK][0])
					{
						if(StrEqual(name, backpackname, false))
						{
							//PrintToChatAll("\x01\x04[RTD] \x03%s\x04 picked up a backpack that has \x03%i\x04 Ammopacks & \x03%i\x04 Healthpacks.",name, ammopacks, healthpacks);
							PrintCenterText(client, "You picked up your backpack");
						}else{
							//PrintToChatAll("\x01\x04[RTD] \x03%s\x04 picked up \x03%s\x04's backpack that has \x03%i\x04 Ammopacks & \x03%i\x04 Healthpacks.",name,backpackname, ammopacks,healthpacks);
							PrintCenterText(client, "You picked up %s's backpack",backpackname);
						}
						
						client_rolls[wearer][AWARD_G_BACKPACK][2] = ammopacks;
						client_rolls[wearer][AWARD_G_BACKPACK][3] = healthpacks;
						//Format(backpackname, sizeof(backpackname), "%s", name);
						attachExistingBackpack(client, backpack);
					}else{
						//PrintToChatAll("\x01\x04[RTD] \x03%s\x04 picked up \x03%s\x04's backpack that has \x03%i\x04 Ammopacks & \x03%i\x04 Healthpacks.",name,backpackname, ammopacks,healthpacks);
						PrintCenterText(client, "You found %i ammopacks and %i healthpacks",ammopacks, healthpacks);
						
						client_rolls[wearer][AWARD_G_BACKPACK][2] += ammopacks;
						client_rolls[wearer][AWARD_G_BACKPACK][3] += healthpacks;
						
						killEntityIn(backpack, 0.1);
					}
					
					EmitSoundToAll(SSphere_Heal,wearer);
					return Plugin_Stop;
				}
			}
		}
	}
	
	if(wearer > 0 && wearer <= MaxClients)
	{
		ammopacks = client_rolls[wearer][AWARD_G_BACKPACK][2];
		healthpacks = client_rolls[wearer][AWARD_G_BACKPACK][3];
		
		if(IsClientInGame(wearer))
		{
			if(!IsPlayerAlive(wearer))
			{
				detachBackpack(backpack);
				return Plugin_Continue;
			}
			
			itemEquipped_OnBack[wearer] = 1;
			
			timeonFloor = 0;
			new amountOfItems = healthpacks + ammopacks;
			
			new currIndex = GetEntProp(backpack, Prop_Data, "m_nModelIndex");
			
			if(amountOfItems <= 2 && currIndex != backpackModelIndex[0]) 
				SetEntityModel(backpack, MODEL_BACKPACK01);
			
			if(amountOfItems > 2 && amountOfItems <= 5 && currIndex != backpackModelIndex[1]) 
				SetEntityModel(backpack, MODEL_BACKPACK02);
			
			if(amountOfItems > 5 && amountOfItems <= 9 && currIndex != backpackModelIndex[2]) 
				SetEntityModel(backpack, MODEL_BACKPACK03);
			
			if(amountOfItems >= 10  && currIndex != backpackModelIndex[3]) 
				SetEntityModel(backpack, MODEL_BACKPACK04);
			
			///////////////////////////////////////////////////////////////
			////   Add ammopack or health pack on score differences    ////
			///////////////////////////////////////////////////////////////
			new ScoreDiff = 0;
			new CurrentScore = TF2_GetPlayerResourceData(wearer, TFResource_TotalScore)  ;
			
			if (CurrentScore != temp_oldScore && temp_oldScore != -1)
			{
				ScoreDiff = CurrentScore - temp_oldScore;
				
				//add an item to the pack
				if(ScoreDiff > 0)
				{
					for(new giveStuff = 1; giveStuff <= ScoreDiff; giveStuff++)
					{
						if(GetRandomInt(1,2) == 1)
						{
							ammopacks += RTD_Perks[wearer][11];
							client_rolls[wearer][AWARD_G_BACKPACK][2] += RTD_Perks[wearer][11];
							
						}else{
							healthpacks += RTD_Perks[wearer][11];
							client_rolls[wearer][AWARD_G_BACKPACK][3] += RTD_Perks[wearer][11];
						}
					}
					
					temp_oldScore = CurrentScore;
					
					EmitSoundToAll(SOUND_PICKUP,wearer);
				}
			}
			
			///////////////////////////////////////////////////////////////
			////   Inject the wearer with an ammopack or healthpack    ////
			///////////////////////////////////////////////////////////////
			if(GetTime() - lastInjection > 2)
			{
				//PrintCenterTextAll("Time Since Last Injection: %i",GetTime() - lastInjection);
				
				new bool:injected = false;
				
				//Are there any healthpacks?
				if(healthpacks > 0)
				{	
					//Determine if player needs health
					new wearerHealth = GetClientHealth(wearer);
					new newHealth;
					
					//the player needs health
					if (wearerHealth  < RoundFloat(finalHealthAdjustments(wearer) * 0.7))
					{	
						//wearerHealth += 50.0;
						newHealth = wearerHealth + 60; //RoundFloat(wearerHealth);
						
						if (newHealth > finalHealthAdjustments(wearer))
						{
							SetEntityHealth(wearer, finalHealthAdjustments(wearer));
						}else{
							SetEntityHealth(wearer,newHealth);
						}
						
						lastInjection = GetTime();
						healthpacks --;
						client_rolls[wearer][AWARD_G_BACKPACK][3] --;
						injected = true;
						
						EmitSoundToAll(SOUND_MEDSHOT,wearer);
					}
				}
				
				//Are there any ammopacks
				if(ammopacks > 0 && !injected)
				{
					new islot = GetActiveWeaponSlot(wearer);
					if(islot != -1)
					{
						new TFClassType:class = TF2_GetPlayerClass(wearer);
						new maxAmmo = TFClass_MaxAmmo[class][islot];
						new currentAmmo = GetWeaponAmmo(wearer, islot);
						
						if(currentAmmo < (maxAmmo * 0.6))
						{
							GiveAmmoToActiveWeapon(wearer, 0.7);
							lastInjection = GetTime();
							ammopacks --;
							client_rolls[wearer][AWARD_G_BACKPACK][2] --;
							injected = true;
							
							EmitSoundToAll(SOUND_MEDSHOT,wearer);
						}
					}
				}
			}
		}
	}
	
	
	
	ResetPack(dataPackHandle);
	WritePackCell(dataPackHandle, backpack);    //PackPosition(0);  Backpack Index
	WritePackCell(dataPackHandle, ammopacks);   //PackPosition(8);  Amount of ammopacks
	WritePackCell(dataPackHandle, healthpacks); //PackPosition(16); Amount of healthpacks
	WritePackCell(dataPackHandle, timeonFloor); //PackPosition(24); Time on floor
	WritePackCell(dataPackHandle, lastInjection);//PackPosition(24); Last injection time
	WritePackCell(dataPackHandle, temp_oldScore);//PackPosition(24); Last injection time
	WritePackString(dataPackHandle,backpackname);
	
	return Plugin_Continue;
}

public attachExistingBackpack(client, backpack)
{
	AcceptEntityInput(backpack, "kill");
	SpawnAndAttachBackpack(client);
	
	EmitSoundToAll(SOUND_ITEM_EQUIP,client);

}

public detachBackpack(backpack)
{
	new owner = GetEntPropEnt(backpack, Prop_Data, "m_hOwnerEntity");
	
	
	CDetach(backpack);
	//AcceptEntityInput(backpack,"ClearParent");
	SetEntPropEnt(backpack, Prop_Send, "m_hOwnerEntity", -1);
	
	SetVariantString("rotate");
	AcceptEntityInput(backpack, "SetAnimation", -1, -1, 0); 
	
	if(owner > 0 && owner <= MaxClients)
	{
		itemEquipped_OnBack[owner] = 0;
		
		for(new i = 0; i <= 7; i ++)
			client_rolls[owner][AWARD_G_BACKPACK][i] = 0;
		
		new Float:pos[3];
		GetClientEyePosition(owner, pos);
		
		new Float:Direction[3];
		Direction[0] = pos[0];
		Direction[1] = pos[1];
		Direction[2] = pos[2]-1024;
		
		new Float:floorPos[3];
		
		new Handle:Trace = TR_TraceRayFilterEx(pos, Direction, MASK_SOLID, RayType_EndPoint, TraceFilterAll, owner);
		TR_GetEndPosition(floorPos, Trace);
		CloseHandle(Trace);
		
		floorPos[2] += 30.0;
		
		TeleportEntity(backpack, floorPos, NULL_VECTOR, NULL_VECTOR);
		
		SetEntityRenderMode(backpack, RENDER_TRANSCOLOR);	
		SetEntityRenderColor(backpack, 255, 255,255, 255);
	}
	
	EmitSoundToAll(SOUND_ITEM_EQUIP_02,backpack);
}

public stopBackPackTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new backpack = ReadPackCell(dataPackHandle);
	
	if(!IsValidEntity(backpack))
		return true;
	
	new currIndex = GetEntProp(backpack, Prop_Data, "m_nModelIndex");
	if(currIndex != backpackModelIndex[0] && currIndex != backpackModelIndex[1] && currIndex != backpackModelIndex[2] && currIndex != backpackModelIndex[3])
		return true;
	
	return false;
}

public Drop_Backpack(client)
{
	//Drop entire backpack
	if(!client_rolls[client][AWARD_G_BACKPACK][0])
		return;
	
	new currIndex = GetEntProp(client_rolls[client][AWARD_G_BACKPACK][1], Prop_Data, "m_nModelIndex");
	
	if(currIndex == backpackModelIndex[0] || currIndex == backpackModelIndex[1] || currIndex == backpackModelIndex[2] || currIndex == backpackModelIndex[3])
	{
		centerHudText(client, "Backpack Dropped", 0.1, 5.0, HudMsg3, 0.82); 
		detachBackpack(client_rolls[client][AWARD_G_BACKPACK][1]);
		
	}
}

public DropItem_From_Backpack(client, item)
{
	// Item = 2 : Drop Ammo Packs
	// Item = 3 : Drop Health Packs
	
	//Does the player need to wait?
	if(GetTime() < client_rolls[client][AWARD_G_BACKPACK][7])
	{
		PrintCenterText(client, "You must wait: %is", client_rolls[client][AWARD_G_BACKPACK][7]-GetTime());
		return;
	}
	
	///////////////////////////////////////////////////////
	//Default to dropping ammo just in case wrong 'item' //
	//is passed through function                         //
	///////////////////////////////////////////////////////
	if(item != 2 && item != 3)
		item = 2;
	
	
	if(client_rolls[client][AWARD_G_BACKPACK][item] < 1)
	{
		if(item == 2)
		{
			PrintCenterText(client, "You don't have any Ammo Packs!");
		}else{
			PrintCenterText(client, "You don't have any Health Packs!");
		}
		
		return;
	}
	
	new spawnedItem = -1;
	if(item == 2)
	{
		spawnedItem = TF_SpawnMedipack(client, "item_ammopack_small", true);
	}else{
		spawnedItem = TF_SpawnMedipack(client, "item_healthkit_small", true);
	}
	
	if(spawnedItem == -1)
	{
		PrintToChatAll("Failed to drop item (backpack entity): Contact developer!");
		return;
	}
	
	client_rolls[client][AWARD_G_BACKPACK][item] --;
	
	killEntityIn(spawnedItem, 7.0);
	
	//Set the owner to the client
	SetEntPropEnt(spawnedItem, Prop_Data, "m_hOwnerEntity", client);
	
	//Disable the item
	SetEntProp(spawnedItem, Prop_Data, "m_bDisabled", 1);
	
	//Next time the player can drop an item
	client_rolls[client][AWARD_G_BACKPACK][7] = GetTime() + 6;
	
	//Enable the item in 1 second
	new String:addoutput[64];
	Format(addoutput, sizeof(addoutput), "OnUser2 !self:enable::%f:1",2.0);
	SetVariantString(addoutput);
	AcceptEntityInput(spawnedItem, "AddOutput");
	AcceptEntityInput(spawnedItem, "FireUser2");
}