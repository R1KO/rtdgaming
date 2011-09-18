#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <rtd_rollinfo>

//////////////////////////////////////////////////////////////////
//About Question Blocks											//
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
//for a Question Block to spawn
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
//Chances of Block Spawning:
//Between 5% to 20%
//
//
//They have a lifetime of 30 seconds.
//1 of 3 Random effects:
//-Replenish health to full
//-Time reduction, 15s - 45s
//-Gives the use 50+ Armor 

public Action:Spawn_QuestionBlock(client, attacker)
{
	new Float:vicorigvec[3];
	GetClientAbsOrigin(client, Float:vicorigvec);
	
	new ent = CreateEntityByName("prop_dynamic_override");
	
	new randomModel = GetRandomInt(1, 4);
	
	switch(randomModel)
	{
		case 1:
			SetEntityModel(ent,MODEL_PRESENT01);
		
		case 2:
		{
			if(GetRandomInt(1,100) < 20 + RTD_TrinketBonus[attacker][TRINKET_PARTYTIME])
			{
				SetEntityModel(ent,MODEL_PRESENT05);
			}else{
				SetEntityModel(ent,MODEL_PRESENT02);
			}
		}
		
		case 3:
			SetEntityModel(ent,MODEL_PRESENT03);
		
		case 4:
			SetEntityModel(ent,MODEL_PRESENT04);
	}
	
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
	
	return Plugin_Continue;
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

GiveRandomEffect(client, attacker, special)
{	
	new isGood = GetRandomInt(1, 10);
	new randomValue;
	new reward;
	
	if(special)
	{
		PrintCenterText(client, "You were given lots of stuff!", randomValue);
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
		reward = GetRandomInt(1, 6);
		
		switch(reward)
		{
			case 1:
			{
				randomValue = GetRandomInt(50, 100);
				addHealth(client, randomValue);
				PrintCenterText(client, "You were given +%i HP", randomValue);
			}
			
			case 2:
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
				
			}
			
			case 3:
			{
				randomValue = GetRandomInt(50, 100);
				PrintCenterText(client, "Time Reduction of %is", randomValue);
				RTD_Timer[client] -= randomValue;
			}
			
			case 4:
			{
				randomValue = GetRandomInt(50, 100);
				PrintCenterText(client, "Ammo replenished", randomValue);
				GiveAmmo(client, 200);
			}
			
			case 5:
			{
				randomValue = GetRandomInt(1, RTD_Perks[client][7]);
				PrintCenterText(client, "Found %i CREDITS!", randomValue);
				
				
				RTDCredits[client] += randomValue;
				
				EmitSoundToAll(SOUND_CREDITFOUND, client);
			}
			
			case 6:
			{
				PrintCenterText(client, "You were given CRITS for 6s");
				TF2_AddCondition(client,TFCond_Kritzkrieged,2.0);
				new Handle:dataPack;
				CreateDataTimer(1.0,giveCrits_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
				
				WritePackCell(dataPack, client);
				WritePackCell(dataPack, 0); //starting time
				WritePackCell(dataPack, 6); //max time
			}
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