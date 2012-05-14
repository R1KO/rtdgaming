#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <rtd_rollinfo>

//////////////////////////////////////////////////////////////////
//About Presents (Known as Question Blocks internally))			//
//////////////////////////////////////////////////////////////////
//They are randomly spawned at the location of a player's
//death. They do not spawn instantly but instead spawn
//5 seconds after the player's death. 
//
//Chances of one spawning are dependant on the sum of 2 factors:
//1. Random value
//2. Amount of Dice the attacker has
//
//These two factors must equal more than 0.95 
//for a Present to spawn
//
//Logic:
//IF AmountOfDice >= 1000 THEN AddedBonus = 0.10
//ELSE
//AddedBonus = (AmountOfDice/1000.0)
//
//RandomValue = (0.00 to 1.00)
//
//IF (AddedBonus + RandomValue) > 0.95 THEN spawn Question Block
//
//Chances of Present Spawning:
//Between 5% to 20%
//
//
//They have a lifetime of 30 seconds.
//1 of 3 Random effects:
//-Replenish health to full
//-Time reduction, 15s - 45s
//-Gives the use 50+ Armor 

public Spawn_QuestionBlock(client, attacker)
{
	//Determine which model present to spawn
	new randomModel = GetRandomInt(1, 4);
	new String:modelName[128];
	
	switch(randomModel)
	{
		case 1:
			Format(modelName, 128, "%s", MODEL_PRESENT01);
		
		case 2:
		{
			if(GetRandomInt(1,100) < 20 + RTD_TrinketBonus[attacker][TRINKET_PARTYTIME])
			{
				Format(modelName, 128, "%s", MODEL_PRESENT05);
				
				//determine treasure chest spawn
				new rndNumber = GetRandomInt(1, 15);
				if(rndNumber == 5)
				{
					EmitSoundToAll(SOUND_OPEN_TRINKET, client);
					
					spawnOnFloorTreasure(client);
					return;
				}
			}else{
				Format(modelName, 128, "%s", MODEL_PRESENT02);
			}
		}
		
		case 3:
			Format(modelName, 128, "%s", MODEL_PRESENT03);
		
		case 4:
			Format(modelName, 128, "%s", MODEL_PRESENT04);
	}
	
	if(StrEqual(modelName, ""))
	{
		PrintToChatAll("Error in Questionblock.sp: No modelname");
		return;
	}
	
	new Float:vicorigvec[3];
	GetClientAbsOrigin(client, Float:vicorigvec);
	
	new ent = CreateEntityByName("prop_dynamic_override");
	SetEntityModel(ent,modelName);
	SetEntProp(ent, Prop_Data, "m_takedamage", 0);  //default = 2
	
	DispatchSpawn(ent);
	
	//Set the Question's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	new iTeam = GetClientTeam(client);
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 0);  //default = 2
	//SetEntProp(ent, Prop_Send, "m_takedamage", 2);  //default = 2
	
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	
	SetEntProp( ent, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 3);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 3);
	
	AcceptEntityInput( ent, "DisableCollision" );
	
	SetVariantString("spin");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	vicorigvec[2] += 15.0;
	TeleportEntity(ent, vicorigvec, NULL_VECTOR, NULL_VECTOR);
	
	// send "kill" event to the event queue
	killEntityIn(ent, 30.0);
	
	// play sound 
	EmitSoundToAll(SOUND_PRESENT, client);
	
	CreateTimer(0.1, Question_Timer, ent, TIMER_REPEAT |TIMER_FLAG_NO_MAPCHANGE);
	
}

public Action:Question_Timer(Handle:timer, any:other)
{
	if(!IsValidEntity(other))
	{
		KillTimer(timer);
		return Plugin_Handled;
	}
	
	new String:modelname[128];
	GetEntPropString(other, Prop_Data, "m_ModelName", modelname, 128);
	
	if (!StrEqual(modelname, MODEL_PRESENT01) && !StrEqual(modelname, MODEL_PRESENT02) && !StrEqual(modelname, MODEL_PRESENT03) && !StrEqual(modelname, MODEL_PRESENT04) && !StrEqual(modelname, MODEL_PRESENT05))
	{
		KillTimer(timer);
		return Plugin_Handled;
	}
	
	new Float: playerPos[3];
	new Float: otherPos[3];
	new Float: distanceFromFeet;
	new Float: distanceFromHead;
	
	GetEntPropVector(other, Prop_Data, "m_vecOrigin", otherPos);
	new ownerEntity = GetEntPropEnt(other, Prop_Data, "m_hOwnerEntity");
		
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		//Invalid attacker, possible reasons player left
		//attacker must be a client!
		if(ownerEntity < 1 || ownerEntity > MaxClients)
		{
			ownerEntity = i;
		}
		
		GetClientAbsOrigin(i,playerPos);
		distanceFromFeet = GetVectorDistance( playerPos, otherPos);
		
		GetClientEyePosition(i,playerPos);
		distanceFromHead = GetVectorDistance( playerPos, otherPos);
		
		if(distanceFromFeet < 50.0 || distanceFromHead < 50)
		{
			EmitSoundToAll(SSphere_Heal, i);
			
			new special = 0;
			if(StrEqual(modelname, MODEL_PRESENT05))
				special = 1;
			
			GiveRandomEffect(i, ownerEntity, special);
			
			AcceptEntityInput(other,"kill");
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public bool:DetermineQuestionBlockSpawn(client, attacker)
{	
	new Float:randomValue = GetRandomFloat(0.0, 1.0);
	new Float:addedBonus;
	
	if(client == attacker)
		return false;
	
	if(RTDdice[attacker] >= 1000)
	{
		addedBonus = 0.25;
	}else{
		addedBonus = RTDdice[attacker] / 4000.0;
	}
	
	new Float:trinketBonus;
	if(RTD_TrinketActive[attacker][TRINKET_PARTYTIME])
		trinketBonus = float(RTD_TrinketBonus[attacker][TRINKET_PARTYTIME]) / 100.0;
	
	//PrintToChat(attacker, "addedBonus: %f | randomValue: %f | trinketBonus: %f || %f", addedBonus, randomValue, trinketBonus, (addedBonus + randomValue + trinketBonus));
	if((addedBonus + randomValue + trinketBonus) >= 0.9)
	{
		Spawn_QuestionBlock(client, attacker);
		return true;
	}
	
	return false;
}

GiveSpecialPresent(client)
{
	PrintCenterText(client, "Received: Full Health & Ammo, 100 Armor, 5 Credits");
	TF2_RegeneratePlayer(client);
	
	if(!client_rolls[client][AWARD_G_ARMOR][0])
	{
		client_rolls[client][AWARD_G_ARMOR][0] = 1;
		client_rolls[client][AWARD_G_ARMOR][1] = 100;//Status of Armor HP
	}else{
		client_rolls[client][AWARD_G_ARMOR][1] += 100;//Status of Armor HP
	}
	
	TF2_AddCondition(client,TFCond_Kritzkrieged,2.0);
	new Handle:dataPack;
	CreateDataTimer(1.0,giveCrits_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	WritePackCell(dataPack, client);
	WritePackCell(dataPack, 0); //starting time
	WritePackCell(dataPack, 6); //max time
	
	RTDCredits[client] += 5;
}

GiveRandomEffect(client, attacker, special)
{	
	new isGood = GetRandomInt(1, 10);
	new randomValue;
	new reward;
	
	if(special)
	{
		GiveSpecialPresent(client);
		
		return;
	}
	
	if(isGood >= 8 && RTD_Perks[client][22] == 0)
	{
		//Give the player something BAD
		
		reward = GetRandomInt(1, 3);
		randomValue = GetRandomInt(10, 40);
		switch(reward)
		{
			case 1:
			{
				PrintCenterText(client, "You've been naughty! Have a BAD present!");
				DealDamage(client,5, attacker, 128, "present");
				DealDamage(client,1, attacker, 2056, "present");
			}
			
			case 2:
			{
				PrintCenterText(client, "+%is were added to your RTD timer", randomValue);
				new timeleft;
				
				if( RTD_Timer[client] <= GetTime())
				{
					timeleft = GetConVarInt(c_Timelimit) - ( GetTime() - RTD_Timer[client]) ;
				}else{
					timeleft = RTD_Timer[client] +  GetConVarInt(c_Timelimit) - GetTime();
				}
				
				if(timeleft <= 1)
				{
					RTD_Timer[client] = (GetTime() - GetConVarInt(c_Timelimit)) + randomValue;
				}else{
					RTD_Timer[client] += randomValue;
				}
			}
			
			case 3:
			{
				PrintCenterText(client, "You've been naughty! Have a BAD present!");
				randomValue = GetRandomInt(10, 100);
				DealDamage(client, randomValue, attacker, 128, "present");
			}
		}
	}else{
		//Reward the player with something GOOD
		reward = GetRandomInt(1, 20);
		
		if(reward <= 5)
		{	
			if(RTD_PerksLevel[client][62])
			{
				randomValue = GetRandomInt(50, 125);
				addHealth(client, randomValue, true);
			}else{
				randomValue = GetRandomInt(50, 100);
				addHealth(client, randomValue, false);
			}
			
			PrintCenterText(client, "You were given +%i HP", randomValue);
			
			return;
		}
		
		if(reward > 5 && reward <= 8)
		{
			randomValue = GetRandomInt(50, RTD_Perks[client][8]);
			PrintCenterText(client, "You were given +%i Armor", randomValue);
			
			if(!client_rolls[client][AWARD_G_ARMOR][0])
			{
				client_rolls[client][AWARD_G_ARMOR][0] = 1;
				client_rolls[client][AWARD_G_ARMOR][1] = randomValue;//Status of Armor HP
			}else{
				client_rolls[client][AWARD_G_ARMOR][1] += randomValue;//Status of Armor HP
			}
			
			return;
		}
		
		if(reward > 8 && reward <= 11)
		{
			randomValue = GetRandomInt(50, 100);
			PrintCenterText(client, "Time Reduction of %is", randomValue);
			RTD_Timer[client] -= randomValue;
			
			return;
		}
		
		if(reward > 11 && reward < 18)
		{
			randomValue = GetRandomInt(50, 100);
			PrintCenterText(client, "Ammo replenished", randomValue);
			GiveAmmo(client, 200);
			
			return;
		}
			
		if(reward == 18)
		{
			randomValue = GetRandomInt(1, RTD_Perks[client][7]);
			
			PrintCenterText(client, "Found %i CREDITS!", randomValue);
			
			
			RTDCredits[client] += randomValue;
			
			EmitSoundToAll(SOUND_CREDITFOUND, client);
			
			return;
		}
			
		if(reward > 18)
		{
			PrintCenterText(client, "You were given CRITS for 6s");
			TF2_AddCondition(client,TFCond_Kritzkrieged,2.0);
			new Handle:dataPack;
			CreateDataTimer(1.0,giveCrits_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
			
			WritePackCell(dataPack, client);
			WritePackCell(dataPack, 0); //starting time
			WritePackCell(dataPack, 6); //max time
			
			return;
		}
	}
}


public Action:giveCrits_Timer(Handle:Timer, Handle:dataPack)
{	
	ResetPack(dataPack);
	new client = ReadPackCell(dataPack);
	new interval = ReadPackCell(dataPack);
	new maxtime = ReadPackCell(dataPack);
	
	if(!IsClientInGame(client))
		return Plugin_Stop;
	
	if(!IsPlayerAlive(client) || interval >= maxtime)
	{
		return Plugin_Stop;
	}
	
	interval ++;
	
	ResetPack(dataPack);
	WritePackCell(dataPack, client);
	WritePackCell(dataPack, interval);
	
	TF2_AddCondition(client,TFCond_Kritzkrieged,2.0);
	
	return Plugin_Continue;
}

public bool:determineCoinSpawn(client, attacker, isAssister)
{
	new randomNumber = GetRandomInt(1, 100);
	
	if(randomNumber >= 50)
		return false;
	
	if(client_rolls[attacker][AWARD_G_TREASURE][3] > GetTime())
		return false;
	
	//next time a coin will have chance to spawn
	client_rolls[attacker][AWARD_G_TREASURE][3] = GetTime() + 30;
	
	//small chance to spawn a dice	
	if(randomNumber <= 5)
	{
		SpawnDiceAtClient(client);
		return true;
	}
	
	new Float:vicorigvec[3];
	GetClientAbsOrigin(client, Float:vicorigvec);
	
	new ent = CreateEntityByName("prop_dynamic_override");
	
	SetEntityModel(ent,MODEL_COIN_SMALL);
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 0);  //default = 2
	
	new String:coinName[128];
	Format(coinName, sizeof(coinName), "target%i", ent);
	DispatchKeyValue(ent, "targetname", coinName);
	
	DispatchSpawn(ent);
	
	
	new iTeam = GetClientTeam(client);
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 0);  //default = 2
	
	SetEntProp( ent, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 3);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 3);
	
	AcceptEntityInput( ent, "DisableCollision" );
	
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	vicorigvec[2] += 15.0;
	TeleportEntity(ent, vicorigvec, NULL_VECTOR, NULL_VECTOR);
	
	// send "kill" event to the event queue
	killEntityIn(ent, 30.0);
	
	// play sound 
	EmitSoundToAll(SOUND_PRESENT, client);
	
	
	//The Datapack stores all the Backpack's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, Coin_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(ent));   //PackPosition(0);  entity index
	WritePackCell(dataPackHandle, GetClientUserId(attacker));     //PackPosition(8); attacker id
	WritePackCell(dataPackHandle, isAssister);     //PackPosition(16); was the attacker an assister
	
	AttachTempParticle(ent,"superrare_beams1",30.0, true, coinName,0.0, false);
	
	return true;
}

public Action:Coin_Timer(Handle:timer, Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	
	new coinEntity = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new attacker = GetClientOfUserId(ReadPackCell(dataPackHandle));
	new isAssister = ReadPackCell(dataPackHandle);
	
	/////////////////////////////
	//validate the coin entity //
	/////////////////////////////
	if(coinEntity < 1)
		return Plugin_Stop;
	
	if(!IsValidEntity(coinEntity))
		return Plugin_Stop;
	
	//////////////////////////
	//validate the attacker //
	//////////////////////////
	if(attacker < 1)
		attacker = -1;
	
	if(!IsClientInGame(attacker))
		attacker = -1;
	
	
	new Float: playerPos[3];
	new Float: otherPos[3];
	new Float: distanceFromFeet;
	new Float: distanceFromHead;
	
	GetEntPropVector(coinEntity, Prop_Data, "m_vecOrigin", otherPos);
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		GetClientAbsOrigin(i,playerPos);
		distanceFromFeet = GetVectorDistance( playerPos, otherPos);
		
		GetClientEyePosition(i,playerPos);
		distanceFromHead = GetVectorDistance( playerPos, otherPos);
		
		if(distanceFromFeet < 50.0 || distanceFromHead < 50)
		{
			EmitSoundToAll(SOUND_COIN, i);
			
			//determine how many credits get distributed
			new totalCredits = 5;
			
			if(isAssister)
				totalCredits = 3;
			
			if(attacker == -1 || attacker == i)
			{
				//////////////////////////////////////////////////////
				//the attacker (client that had the treasure chest) //
				//is no longer here award full credits on pickup    //
				//////////////////////////////////////////////////////
				
				RTDCredits[i] += totalCredits;
				
				PrintCenterText(i, "%i CREDITS!", totalCredits);
			}else{
				////////////////////////////////////////////
				//split up the difference between the     //
				//player that picked up the coin and the  // 
				//client that had the treasure chest      //
				////////////////////////////////////////////
				
				//player that picked up
				RTDCredits[i] += 1;
				PrintCenterText(i, "1 CREDIT!");
				
				//player that forced the drop
				RTDCredits[attacker] += (totalCredits - 1);
				PrintCenterText(attacker, "Received %i CREDITS!", (totalCredits - 1));
				EmitSoundToClient(attacker, SOUND_COIN);
			}
			
			AcceptEntityInput(coinEntity,"kill");
			
			return Plugin_Stop;
		}
	}

	return Plugin_Continue;
}