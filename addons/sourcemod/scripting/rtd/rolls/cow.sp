#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2>
#include <rtd_rollinfo>

public Action:Spawn_Cow(client, health, maxhealth)
{
	if(client > 0 && client <= MaxClients)
	{
		client_rolls[client][AWARD_G_COW][0] = 0;
		client_rolls[client][AWARD_G_COW][3] = GetTime() + 5; //time it can pick up
	}
	
	new box = CreateEntityByName("prop_physics_override");
	if ( box == -1 )
	{
		ReplyToCommand( client, "Failed to create a SpiderBox!" );
		return Plugin_Handled;
	}
	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Cow" );
		return Plugin_Handled;
	}
	
	SetEntityModel(box, MODEL_SPIDERBOX);
	SetEntityModel(ent, MODEL_COW);
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	SetEntProp(box, Prop_Data, "m_takedamage", 0);  //default = 2
	
	DispatchSpawn(ent);
	DispatchSpawn(box);
	//Our 'sled' collision does not need to be rendered nor does it need shadows
	AcceptEntityInput( box, "DisableShadow" );
	SetEntityRenderMode(box, RENDER_NONE);
	
	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
	
	
	new iTeam =  GetEntProp(client, Prop_Data, "m_iTeamNum");
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	
	SetVariantInt(iTeam);
	AcceptEntityInput(box, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(box, "SetTeam", -1, -1, 0); 

	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	

	SetEntProp( ent, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 3);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 3);
	
	SetEntProp( box, Prop_Data, "m_nSolidType", 4 );
	SetEntProp( box, Prop_Send, "m_nSolidType", 4 );
	
	AcceptEntityInput( ent, "DisableCollision" );
	AcceptEntityInput( ent, "EnableCollision" );
	
	
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", maxhealth);
	SetEntProp(ent, Prop_Data, "m_iHealth", health);
	
	if(iTeam == RED_TEAM)
	{
		SetVariantString(bluDamageFilter);
	}else{
		SetVariantString(redDamageFilter);
	}
	AcceptEntityInput(ent, "SetDamageFilter", -1, -1, 0); 
	
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	
	/////////////////////////////////////////
	new Float:angle[3];
	GetClientAbsAngles(client, angle);
	
	new Float:pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	
	pos[2] += 40.0;
	TeleportEntity(ent, pos, angle, NULL_VECTOR);
	TeleportEntity(box, pos, angle, NULL_VECTOR);
	/////////////////////////////////////////
	
	//name the cow
	new String:cowName[128];
	Format(cowName, sizeof(cowName), "cow%i", ent);
	DispatchKeyValue(ent, "targetname", cowName);
	
	//Now lets parent the physics box to the animated spider
	new String:boxName[128];
	Format(boxName, sizeof(boxName), "box%i", box);
	DispatchKeyValue(box, "targetname", boxName);
	
	SetVariantString(boxName);
	AcceptEntityInput(ent, "SetParent");
	
	//Set the box transparent
	SetEntityRenderMode(box, RENDER_TRANSCOLOR);	
	SetEntityRenderColor(box, 0, 0, 0, 0);
	
	//Cow perk
	new cowPerk = 0;
	if(maxhealth > 800)
		cowPerk = 1;
	
	if(iTeam == RED_TEAM)
	{
		SetVariantString("255+120+120");
		AcceptEntityInput(ent, "color", -1, -1, 0);
	}
	else
	{
		SetVariantString("120+120+255");
		AcceptEntityInput(ent, "color", -1, -1, 0);
	}
	
	//SetEntProp(ent, Prop_Send, "m_bGlowEnabled", 1, 1);	
	
	new Handle:dataPack;
	CreateDataTimer(0.5,Cow_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPack, ent); //PackPosition(0) 
	WritePackCell(dataPack, box); //PackPosition(8) 
	WritePackCell(dataPack, 0);		//PackPosition(16), used to emit sounds
	WritePackCell(dataPack, GetTime() + 30); //PackPosition(24), next time it can spawn milk
	WritePackCell(dataPack, cowPerk); //PackPosition(32)
	WritePackCell(dataPack, GetTime() + 2); //40 when it can be picked up
	HookSingleEntityOutput(ent, "OnHealthChanged", Cow_Hurt, false);
	
	return Plugin_Handled;
}

public Cow_Hurt (const String:output[], caller, activator, Float:delay)
{
	if(IsValidEntity(caller))
	{
		new box = GetEntPropEnt(caller, Prop_Data, "m_pParent");
		
		if(IsValidEntity(box))
		{
		
			AttachTempParticle(box,"env_sawblood", 1.0, false,"",0.0, true);
			
			if(GetEntProp(caller, Prop_Data, "m_iHealth") <= 100)
			{
				new client = GetEntPropEnt(caller, Prop_Data, "m_hOwnerEntity");
				if(client > 0 && client <= MaxClients)
				{
					if(IsClientInGame(client))
					{
						new String:name[32];
						if(activator > 0 && activator <= MaxClients)
						{
							GetClientName(activator, name, sizeof(name));
							
							PrintCenterText(client, "%s killed your COW!",name);
							EmitSoundToClient(client, SOUND_COW1);
							
							GetClientName(client, name, sizeof(name));
							PrintCenterText(activator, "You killed %s's COW!",name);
						}
					}
				}
				
				SetVariantString("die");
				AcceptEntityInput(caller, "SetAnimation", -1, -1, 0); 
				
				AcceptEntityInput( caller, "DisableCollision" );
				
				UnhookSingleEntityOutput(caller, "OnHealthChanged", Cow_Hurt);
				
				killEntityIn(box, 20.0);
				
				//killEntityIn(caller, 0.1);
				//Let's reward the player for killing this entity
				new rndNum = GetRandomInt(0,20);
				if(rndNum > 10)
				{
					TF_SpawnMedipack(box, "item_healthkit_medium", true);
				}else{
					TF_SpawnMedipack(box, "item_ammopack_medium", true);
				}	
			}
		}
	}
}

public Action:Cow_Timer(Handle:timer, Handle:dataPack)
{	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPack);
	new cow 			= ReadPackCell(dataPack);
	new box 			= ReadPackCell(dataPack);
	new soundInterval	= ReadPackCell(dataPack);
	new nextSpawn		= ReadPackCell(dataPack);
	new cowPerk			= ReadPackCell(dataPack);
	new pickUpTime		= ReadPackCell(dataPack);
	
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(!IsValidEntity(cow))
		return Plugin_Stop;
	
	new currIndex = GetEntProp(cow, Prop_Data, "m_nModelIndex");
	
	if(currIndex != cowModelIndex)
		return Plugin_Stop;
	
	if(GetEntProp(cow, Prop_Data, "m_iHealth") <= 100)
		return Plugin_Stop;
	
	///////////////////////////////
	//Set if it can be picked up //
	///////////////////////////////
	if(GetEntProp(cow, Prop_Data, "m_PerformanceMode") != 1)
	{
		if(GetTime() > pickUpTime)
			SetEntProp(cow, Prop_Data, "m_PerformanceMode", 1);
	}
	
	//this is to correct the cow's orientation if he gets
	//tipped over or is upside down
	new Float:cowAngle[3];
	GetEntPropVector(box, Prop_Data, "m_angRotation", cowAngle);
	if(cowAngle[0] > 60.0)
		cowAngle[0] =- 5.0;
	
	if(cowAngle[2] > 60.0)
		cowAngle[2] =- 5.0;
	TeleportEntity(box, NULL_VECTOR, cowAngle, NULL_VECTOR);
	
	
	soundInterval ++;
	if(soundInterval > 20)
	{
		soundInterval = 0;
		
		switch (GetRandomInt(1,3))
		{
			case 1:
				EmitSoundToAll(SOUND_COW1, cow);
			
			case 2:
				EmitSoundToAll(SOUND_COW2, cow);
			
			case 3:
				EmitSoundToAll(SOUND_COW3, cow);
		}
	}
	
	SetPackPosition(dataPack, 16);
	WritePackCell(dataPack, soundInterval);		//PackPosition(8), used to restart sounds
	
	if(nextSpawn <= GetTime())
	{
		if(cowPerk)
		{
			Spawn_Milk(box, 70);
		}else{
			Spawn_Milk(box, 50);
		}
		
		SetPackPosition(dataPack, 24);
		WritePackCell(dataPack, GetTime() + 30);		//PackPosition(8), used to restart sounds
	}
	
	new Float: playerPos[3];
	new Float: cowPos[3];
	new Float: distance;
	
	new playerTeam;
	new cowTeam =  GetEntProp(cow, Prop_Data, "m_iTeamNum");
	
	GetEntPropVector(box, Prop_Data, "m_vecOrigin", cowPos);
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		playerTeam = GetClientTeam(i);
		
		//Check to see if player is close to cow
		GetClientAbsOrigin(i,playerPos);
		distance = GetVectorDistance( playerPos, cowPos);
		
		if(distance < 200.0)
		{
			if(playerTeam == cowTeam)
			{
				TF2_RemoveCondition(i, TFCond_Milked);
			}else{
				TF2_AddCondition(i,TFCond_Milked,10.0);
			}
		}
	}
	
	return Plugin_Continue;
}



public Action:Spawn_Milk(cow, healthToGive)
{	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		//ReplyToCommand( client, "Failed to create a Milk Bottle" );
		return Plugin_Handled;
	}
	
	SetEntityModel(ent, MODEL_MILKBOTTLE);
	
	DispatchSpawn(ent);
	
	new iTeam = GetEntProp(cow, Prop_Data, "m_iTeamNum");
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	new Float:pos[3];
	GetEntPropVector(cow, Prop_Send, "m_vecOrigin", pos);
	
	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	
	EmitSoundToAll(SOUND_B, ent);
	
	if(iTeam == RED_TEAM)
	{
		SetVariantString("255+120+120");
		AcceptEntityInput(ent, "color", -1, -1, 0);
	}
	else
	{
		SetVariantString("120+120+255");
		AcceptEntityInput(ent, "color", -1, -1, 0);
	}
	
	new Handle:dataPack;
	CreateDataTimer(0.1,Milk_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPack, ent); //PackPosition(0) 
	WritePackCell(dataPack, healthToGive);		//PackPosition(8), how much health to give user when they pick up bottle
	
	killEntityIn(ent, 20.0);
	
	return Plugin_Handled;
}

public Action:Milk_Timer(Handle:timer, Handle:dataPack)
{	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPack);
	new milkbottle 		= ReadPackCell(dataPack);
	new healthToGive	= ReadPackCell(dataPack);
	
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(!IsValidEntity(milkbottle))
		return Plugin_Stop;
	
	new currIndex = GetEntProp(milkbottle, Prop_Data, "m_nModelIndex");
	
	if(currIndex != milkbottleModelIndex)
		return Plugin_Stop;
	
	
	new Float: playerPos[3];
	new Float: cowPos[3];
	new Float: distance;
	new playerTeam;
	new cowTeam =  GetEntProp(milkbottle, Prop_Data, "m_iTeamNum");
	
	GetEntPropVector(milkbottle, Prop_Data, "m_vecOrigin", cowPos);
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		playerTeam = GetClientTeam(i);
		
		if(playerTeam != cowTeam)
			continue;
		
		//Check to see if player is close to cpw
		GetClientAbsOrigin(i,playerPos);
		distance = GetVectorDistance( playerPos, cowPos);
		
		if(distance < 60.0)
		{	
			PrintCenterText(i, "Yummy! Milk is so good. (+%ihp)",healthToGive);
			
			addHealth(i, healthToGive, false);
			TF2_RemoveCondition(i,TFCond_Milked);
			TF2_RemoveCondition(i,TFCond_OnFire);
			
			EmitSoundToAll(SOUND_MEDSHOT,i);
			
			killEntityIn(milkbottle, 0.1);
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

///////////////////////////////////////////////////////////////
//                                                           //
//             BEGIN CODE FOR COW BACK                       //
//                                                           //
///////////////////////////////////////////////////////////////

AttachCowToBack(client, health, maxHealth)
{
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to attach Cow on Back!" );
		return;
	}
	
	client_rolls[client][AWARD_G_COW][1] = EntIndexToEntRef(ent);
	
	SetEntityModel(ent, MODEL_COWONBACK);
	
	//Set the Spider's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	DispatchSpawn(ent);
	
	AcceptEntityInput( ent, "DisableShadow" );
	
	
	SetEntProp( ent, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 3);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 3);
	
	//Set the cow's health
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", maxHealth);
	SetEntProp(ent, Prop_Data, "m_iHealth", health);
	
	//argggh F.U. valve
	AcceptEntityInput( ent, "DisableCollision" );
	AcceptEntityInput( ent, "EnableCollision" );
	
	
	//new iTeam = GetClientTeam(client);
	new iTeam = GetEntProp(client, Prop_Data, "m_iTeamNum");
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	
	
	//set the default animation
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	CAttach(ent, client, "flag");
	
	if(iTeam == RED_TEAM)
	{
		SetVariantString(bluDamageFilter);
	}else{
		SetVariantString(redDamageFilter);
	}
	
	AcceptEntityInput(ent, "SetDamageFilter", -1, -1, 0); 
	
	//The Datapack stores all the Backpack's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, CowOnBack_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(ent));   //PackPosition(0);  Cow entity
	WritePackCell(dataPackHandle, GetTime() + 30);   //PackPosition(8);  Next time to give milk
	WritePackCell(dataPackHandle, GetTime());   //PackPosition(16);  spawnedTime
	WritePackCell(dataPackHandle, GetTime() + 20);   //PackPosition(24);  spawnedTime
	
	EmitSoundToAll(SOUND_ITEM_EQUIP,client);
}

public Action:CowOnBack_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stop_CowOnBack_Timer(dataPackHandle))
		return Plugin_Stop;
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new cow = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new nextMilkTime = ReadPackCell(dataPackHandle);
	new nextMooTime = ReadPackCell(dataPackHandle);
	nextMooTime = ReadPackCell(dataPackHandle);
	
	new client = GetEntPropEnt(cow, Prop_Data, "m_hOwnerEntity");
	
	/////////////////
	//Update Alpha //
	/////////////////
	new alpha = GetEntData(client, m_clrRender + 3, 1);
	new playerCond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	if(class == TFClass_Spy)
	{	
		if(playerCond&16 || playerCond&24)
		{
			SetEntityRenderMode(cow, RENDER_TRANSCOLOR);	
			SetEntityRenderColor(cow, 255, 255,255, 0);
		}
	}else{
		if(hasInvisRolls(client))
		{
			SetEntityRenderMode(cow, RENDER_TRANSCOLOR);	
			SetEntityRenderColor(cow, 255, 255,255, 0);
		}else{
			SetEntityRenderMode(cow, RENDER_TRANSCOLOR);	
			SetEntityRenderColor(cow, 255, 255,255, 255);
		}
	}
	
	////////////////////
	// Determine skin //
	////////////////////
	if(playerCond&32)
	{
		SetEntProp(cow, Prop_Data, "m_takedamage", 0);
		
		if(GetEntProp(cow, Prop_Data, "m_nSkin") == 0)
		{
			if(GetClientTeam(client) == BLUE_TEAM)
			{
				DispatchKeyValue(cow, "skin","1"); 
			}else{
				DispatchKeyValue(cow, "skin","2"); 
			}
		}
	}else{
		if(GetEntProp(cow, Prop_Data, "m_nSkin") != 0)
			DispatchKeyValue(cow, "skin","0"); 
	}
	
	//////////////////////////////////
	// Determine health adjustments //
	//////////////////////////////////
	new cowHealth = GetEntProp(cow, Prop_Data, "m_iHealth");
	new cowMaxHealth = GetEntProp(cow, Prop_Data, "m_iMaxHealth");
	
	if(!client_rolls[client][AWARD_G_BACKPACK][0] && !inTimerBasedRoll[client])
	{	
		SetHudTextParams(0.03, 0.04, 3.0, 250, 250, 210, 255);
		ShowHudText(client, HudMsg5, "Cow Health: %i/%i", cowHealth-100, cowMaxHealth-100);
	}
	
	//////////////////////////////////
	// Next Moo Time                //
	//////////////////////////////////
	if(GetTime() > nextMooTime)
	{	
		switch (GetRandomInt(1,3))
		{
			case 1:
				EmitSoundToAll(SOUND_COW1, cow);
			
			case 2:
				EmitSoundToAll(SOUND_COW2, cow);
			
			case 3:
				EmitSoundToAll(SOUND_COW3, cow);
		}
		
		SetPackPosition(dataPackHandle, 24);
		WritePackCell(dataPackHandle, GetTime() + 20);   //PackPosition(8);  Next yell time
	}
	
	//////////////////////////////////
	// Give the user some milk      //
	//////////////////////////////////
	TF2_RemoveCondition(client,TFCond_Milked);
	if(GetTime() > nextMilkTime)
	{
		new addedHealth;
		
		//cow Perk
		//User with cow perk gets for milk
		if(RTD_Perks[client][17])
		{
			addedHealth = 70;
		}else{
			addedHealth = 50;
		}
		
		SetPackPosition(dataPackHandle, 8);
		WritePackCell(dataPackHandle, GetTime() + 30);   //PackPosition(8);  Next yell time
		
		cowHealth = GetEntProp(cow, Prop_Data, "m_iHealth");
		cowHealth += addedHealth;
		if(cowHealth >= cowMaxHealth)
			cowHealth = cowMaxHealth;
		
		SetEntProp(cow, Prop_Data, "m_iHealth", cowHealth);
		
		addHealth(client, addedHealth, false);
		
		//PrintCenterText(client, "Yummy! Milk is soooooo good");
		TF2_RemoveCondition(client,TFCond_OnFire);
		
		EmitSoundToAll(SOUND_MEDSHOT,cow);
		
		SetPackPosition(dataPackHandle, 8);
		WritePackCell(dataPackHandle, GetTime() + 30);   //PackPosition(8);  Next yell time
	}
	
	/////////////////////////////////////////////////
	// Coat nearby enemies with milk               //
	// The range is smaller than a cow that is not //
	// being carried                               //
	/////////////////////////////////////////////////
	new Float: playerPos[3];
	new Float: cowPos[3];
	new Float: distance;
	new playerTeam;
	new cowTeam =  GetEntProp(cow, Prop_Data, "m_iTeamNum");
	
	GetEntPropVector(cow, Prop_Data, "m_vecAbsOrigin", cowPos);
	
	//Cow's can't milk enemies if invis
	if(!(playerCond&16 || playerCond&24) || alpha != 0)
	{
		for (new i = 1; i <= MaxClients ; i++)
		{
			if(!IsClientInGame(i) || !IsPlayerAlive(i))
				continue;
			
			playerTeam = GetClientTeam(i);
			
			if(playerTeam == cowTeam)
				continue;
			
			//Check to see if player is close to cpw
			GetClientAbsOrigin(i,playerPos);
			distance = GetVectorDistance( playerPos, cowPos);
			
			if(distance < 120.0)
			{
				TF2_AddCondition(i,TFCond_Milked,10.0);
			}
		}
	}
	
	//Cow's are heavy
	//SetEntityGravity(client, 1.3);
	
	itemEquipped_OnBack[client] = 1;
	
	return Plugin_Continue;
}

public stop_CowOnBack_Timer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new cow = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	if(cow < 1)
		return true;
	
	if(!IsValidEntity(cow))
		return true;
	
	new client = GetEntPropEnt(cow, Prop_Data, "m_hOwnerEntity");
	
	//The cow became its own owner
	//this will only happen when it has been dropped
	if(client == cow)
	{
		return true;
	}
	
	//Client either disconnected or died, either way he's not here
	if(client < 1)
	{
		CDetach(cow);
		killEntityIn(cow, 0.3);
		Spawn_Cow(cow, GetEntProp(cow, Prop_Data, "m_iHealth"), GetEntProp(cow, Prop_Data, "m_iMaxHealth"));
		return true;
	}
	
	//Player died
	if(!IsPlayerAlive(client))
	{
		itemEquipped_OnBack[client] = 0;
		
		ResetClientSpeed(client);
		SetEntityGravity(client, 1.0);
		
		CDetach(cow);
		killEntityIn(cow, 0.3);
		
		Spawn_Cow(client, GetEntProp(cow, Prop_Data, "m_iHealth"), GetEntProp(cow, Prop_Data, "m_iMaxHealth"));
		
		
		if(!autoBalanced[client])
		{
			client_rolls[client][AWARD_G_COW][1] = 0;
		}
		
		return true;
	}
	
	return false;
}

public dropCow(client)
{
	new cow = EntRefToEntIndex(client_rolls[client][AWARD_G_COW][1]);
	
	if(cow < 1)
		return;
	
	if(!IsValidEntity(cow))
		return;
	
	new currIndex = GetEntProp(cow, Prop_Data, "m_nModelIndex");
		
	if(currIndex != cowOnBackModelIndex)
		return;
		
	new owner = GetEntPropEnt(cow, Prop_Data, "m_hOwnerEntity");
	
	if(client != owner)
		return;
	
	itemEquipped_OnBack[client] = 0;
	
	new cowHealth = GetEntProp(cow, Prop_Data, "m_iHealth");
	new cowMaxHealth = GetEntProp(cow, Prop_Data, "m_iMaxHealth");
	
	ResetClientSpeed(client);
	SetEntityGravity(client, 1.0);
	
	SetEntPropEnt(cow, Prop_Data, "m_hOwnerEntity", cow);
	
	CDetach(cow);
	killEntityIn(cow, 0.0);
	client_rolls[client][AWARD_G_COW][1] = 0;
	
	Spawn_Cow(client, cowHealth, cowMaxHealth);
}