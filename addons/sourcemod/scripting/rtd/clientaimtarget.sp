#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>

#pragma semicolon 1
#include <rtd_rollinfo>

new Float:maxDistanceToSee = 900.0;

////////////////////////////////////////////////////
//Here we determine what the client is looking at //
//and display the appropriate message             //
//                                                //
//the entites that are being looked at must have  //
//Physics models attached to them or else the     //
//function will fail to recognize the entity      //
////////////////////////////////////////////////////
public Action:AimTarget_Timer(Handle:timer, Handle:dataPackHandle)
{
	new lookingAt = -1;
	new iTeam;
	new offsetSearch;
	new objectTeam;
	new objHealth;
	new objMaxHeath;
	new lookingAtModelIndex;
	new Float:lookingAtOrigin[3];
	new Float:clientAbsOrigin[3];
	new String:message[64];
	new String:message2[32];
	new skin;
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	
	for (new i = 1; i <= MaxClients ; i++)
	{	
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		//Get the enityt index the client is looking at
		//this can be called with no worries of affecting performance
		lookingAt = GetClientAimTarget(i, false);
		
		//Reset what the client is looking at
		lookingAtPickup[i][0] = 0;
		lookingAtPickup[i][1] = 0;
		
		if(lookingAt < 1)
			continue;
		
		//PrintCenterText(i, "%i",lookingAt);
		if(lookingAt > MaxClients)  //Ensures this doesn't even check on clients as well as -1, saves time
		{
			
			//get the model index
			lookingAtModelIndex = GetEntProp(lookingAt, Prop_Data, "m_nModelIndex");
			
			iTeam = GetClientTeam(i);
			offsetSearch = FindDataMapOffs(lookingAt,"m_iTeamNum");
			
			//the player is looking at an object that does NOT have a teamNum property
			//let's go on to the next player or else we'll cause errors
			if(offsetSearch == -1)
				continue;
			
			GetEntPropVector(lookingAt, Prop_Data, "m_vecAbsOrigin", lookingAtOrigin);
			GetClientAbsOrigin(i, clientAbsOrigin);
			
			objectTeam = GetEntProp(lookingAt, Prop_Data, "m_iTeamNum");
			objHealth = GetEntProp(lookingAt, Prop_Data, "m_iHealth");
			objMaxHeath = GetEntProp(lookingAt, Prop_Data, "m_iMaxHealth");
			
			//Pickup the stuff
			Pickup_AimTarget(i, lookingAt, objectTeam, iTeam, lookingAtModelIndex);
			
			//PrintToChat(i, "Time of next annotation:%i | Client: %i |  %i", timeForNextAnnotation[i] , i, GetTime());
			
			//determine if annotation can be spawned
			if(timeForNextAnnotation[i]  > GetTime())
				continue;
			
			if(GetVectorDistance(lookingAtOrigin,clientAbsOrigin) > maxDistanceToSee)
				continue;
			
			//determine if player is looking at an RTD object
			if(!isModelRTDObject(lookingAtModelIndex))
				continue;
			
			//Player is looking at an RTD object
			//update the datapack and set the next time
			//an annotations is sent
			timeForNextAnnotation[i]  = GetTime() + 3;
			
			//PrintToChat(i, "Delaying Annotation for client: %i | Time: %i", i, timeForNextAnnotation[i]) ;
			
			//clear it out
			Format(message, sizeof(message), "");
			
			if(lookingAtModelIndex == amplifierModelIndex)
			{
				if(objectTeam == iTeam)
				{
					if(GetEntProp(lookingAt, Prop_Data, "m_PerformanceMode") == i)
					{
						Format(message, sizeof(message), "Your Amplifier (%i/%i hp)", objHealth,objMaxHeath);
					}else{
						Format(message, sizeof(message), "Friendly Amplifier (%i/%i hp)", objHealth,objMaxHeath);
					}
				}else{
					Format(message, sizeof(message), "Enemy Amplifier (%i/%i hp)", objHealth,objMaxHeath);
				}
			}else if(lookingAtModelIndex == crapModelIndex)
			{
				if(objectTeam == iTeam)
				{
					Format(message, sizeof(message), "Friendly Poop (%i/%i hp)", objHealth,objMaxHeath);
				}else{
					Format(message, sizeof(message), "Enemy Poop (%i/%i hp)", objHealth,objMaxHeath);
				}
			}else if(lookingAtModelIndex == bearTrapModelIndex)
			{
				if(objectTeam == iTeam)
				{
					Format(message, sizeof(message), "Friendly Trap (%i/%i hp)", objHealth,objMaxHeath);
				}else{
					Format(message, sizeof(message), "Enemy Trap (%i/%i hp)", objHealth,objMaxHeath);
				}
			}else if(lookingAtModelIndex == jumpPadModelIndex)
			{
				if(objectTeam == iTeam)
				{
					Format(message, sizeof(message), "Friendly Jump Pad (%i/%i hp)", objHealth,objMaxHeath);
				}else{
					Format(message, sizeof(message), "Enemy Jump Pad (%i/%i hp)", objHealth,objMaxHeath);
				}
			}else if(lookingAtModelIndex == spiderIndex)
			{
				if(objectTeam == iTeam)
				{
					if(GetEntPropEnt(lookingAt, Prop_Data, "m_hOwnerEntity") != i)
					{
						Format(message, sizeof(message), "Friendly Spider(%i/%i hp)", objHealth,objMaxHeath);
					}else{
						//this is this player's spider, allow the player to pick it up
						Format(message, sizeof(message), "Your Spider (%i/%i hp)", objHealth,objMaxHeath);
					}
				}else{
					Format(message, sizeof(message), "Enemy Spider");
				}
				
				lookingAt = GetEntPropEnt(lookingAt, Prop_Data, "m_pParent");
			}else if(lookingAtModelIndex == iceModelIndex)
			{
				if(objectTeam == iTeam)
				{
					Format(message, sizeof(message), "Friendly Ice Patch");
				}else{
					Format(message, sizeof(message), "Enemy Ice Patch");
				}
			}else if(lookingAtModelIndex == bombModelIndex)
			{
				skin = GetEntProp(lookingAt, Prop_Data, "m_nSkin");
				
				switch(skin)
				{
					case 0:
						Format(message2, sizeof(message2), "");
						
					case 1:
						Format(message2, sizeof(message2), "Fire ");
						
					case 2:
						Format(message2, sizeof(message2), "Ice ");
				}
				
				if(objectTeam == iTeam)
				{
					Format(message, sizeof(message), "Friendly %sBomb", message2);
				}else{
					Format(message, sizeof(message), "Enemy %sBomb", message2);
				}
			}else if(lookingAtModelIndex == rollermineModelIndex)
			{
				if(objectTeam == iTeam)
				{
					Format(message, sizeof(message), "Friendly Roller (%i/%i hp)", objHealth,objMaxHeath);
				}else{
					Format(message, sizeof(message), "Enemy Roller");
				}
			}else if(lookingAtModelIndex == pumpkinModelIndex)
			{
				if(objectTeam == iTeam)
				{
					Format(message, sizeof(message), "Friendly Pumpkin");
				}else{
					Format(message, sizeof(message), "Enemy Pumpkin");
				}
			}else if(lookingAtModelIndex == groovitronModelIndex)
			{
				if(objectTeam == iTeam)
				{
					Format(message, sizeof(message), "Friendly Groovitron");
				}else{
					Format(message, sizeof(message), "Enemy Groovitron");
				}
			}else if(lookingAtModelIndex == ghostModelIndex[0] || lookingAtModelIndex == ghostModelIndex[1])
			{
				if(objectTeam == iTeam)
				{
					Format(message, sizeof(message), "Friendly Ghost");
				}else{
					Format(message, sizeof(message), "Enemy Ghost");
			}
			}else if(lookingAtModelIndex == zombieModelIndex[0] || lookingAtModelIndex == zombieModelIndex[1] || lookingAtModelIndex == zombieModelIndex[2])
			{
				if(objectTeam == iTeam)
				{
					Format(message, sizeof(message), "Friendly Zombie");
				}else{
					Format(message, sizeof(message), "Enemy Zombie");
				}
				
				lookingAt = GetEntPropEnt(lookingAt, Prop_Data, "m_pParent");
			}else if(lookingAtModelIndex == cloudIndex || lookingAtModelIndex == cloud02Index)
			{
				if(objectTeam == iTeam)
				{
					Format(message, sizeof(message), "Friendly Jarate Cloud");
				}else{
					Format(message, sizeof(message), "Enemy Jarate Cloud");
				}
			}else if(lookingAtModelIndex == sawModelIndex)
			{
				if(objectTeam == iTeam)
				{
					Format(message, sizeof(message), "Friendly Saw");
				}else{
					Format(message, sizeof(message), "Enemy Saw");
				}
			}else if(lookingAtModelIndex == cowModelIndex)
			{
				if(objectTeam == iTeam)
				{
					if(GetEntPropEnt(lookingAt, Prop_Data, "m_hOwnerEntity") != i)
					{
						Format(message, sizeof(message), "Friendly Cow");
					}else{
						//this is this player's spider, allow the player to pick it up
						Format(message, sizeof(message), "Your Cow (%i/%i hp)", objHealth-100,objMaxHeath-100);
					}
				}else{
					Format(message, sizeof(message), "Enemy Cow");
				}
				
				lookingAt = GetEntPropEnt(lookingAt, Prop_Data, "m_pParent");
			}else if(lookingAtModelIndex == diglettModelIndex)
			{
				if(objectTeam == iTeam)
				{
					Format(message, sizeof(message), "Friendly Diglett (%i/%i hp)", objHealth,objMaxHeath);
				}else{
					Format(message, sizeof(message), "Enemy Diglett");
				}
			}else if(lookingAtModelIndex == dummyModelIndex)
			{
				lookingAtOrigin[2] += 85.0;
				
				if(objectTeam == iTeam)
				{	
					Format(message, sizeof(message), "Friendly Dummy (%i/%i hp)", objHealth-200,objMaxHeath-200);
				}else{
					Format(message, sizeof(message), "Enemy Dummy");
				}
			}else if(lookingAtModelIndex == instaPorterModelIndex)
			{
				if(objectTeam == iTeam)
				{
					if(GetEntProp(lookingAt, Prop_Data, "m_PerformanceMode") == 1)
					{
						Format(message, sizeof(message), "Friendly Instaporter Entrance (%i/%i hp)", objHealth,objMaxHeath);
					}else{
						Format(message, sizeof(message), "Friendly Instaporter Exit (%i/%i hp)", objHealth,objMaxHeath);
					}
				}else{
					if(GetEntProp(lookingAt, Prop_Data, "m_PerformanceMode") == 1)
					{
						Format(message, sizeof(message), "Enemy Instaporter Entrance (%i/%i hp)", objHealth,objMaxHeath);
					}else{
						Format(message, sizeof(message), "EnemyInstaporter Exit (%i/%i hp)", objHealth,objMaxHeath);
					}
				}
			}else if(lookingAtModelIndex == brazierModelIndex)
			{
				if(objectTeam == iTeam)
				{
					Format(message, sizeof(message), "Friendly Brazier (%i/%i hp)", objHealth,objMaxHeath);
				}else{
					Format(message, sizeof(message), "Enemy Brazier (%i/%i hp)", objHealth,objMaxHeath);
				}
			}else if(lookingAtModelIndex == angelicModelIndex)
			{
				lookingAtOrigin[2] += 85.0;
				
				if(objectTeam == iTeam)
				{
					Format(message, sizeof(message), "Friendly Angelic Dispenser (%i/%i hp)", objHealth,objMaxHeath);
				}else{
					Format(message, sizeof(message), "Enemy Angelic Dispenser (%i/%i hp)", objHealth,objMaxHeath);
				}
			}
			
			if(!(StrEqual(message, "")))
				SpawnAnnotation(i, lookingAt, message, lookingAtOrigin);
		}
	}
}

public pickupItem(client, award)
{
	new lookingAt = GetClientAimTarget(client, false);
	
	//ensure that client is still looking at pickup
	if(lookingAt != lookingAtPickup[client][1])
	{
		PrintToServer("Tried to pickup item but client is not looking at it!");
		return;
	}
	
	//prevent players from picking up the same item and the same time (dupes)
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if(entityPickedUp[i] == 0)
			continue;
		
		if(i == client)
			continue;
		
		if(EntRefToEntIndex(entityPickedUp[i]) == lookingAt)
		{
			PrintCenterText(i, "Object is being picked up by another player");
			EmitSoundToClient(i, SOUND_DENY);
			return;
		}
	}
	
	switch(award)
	{
		case AWARD_G_SPIDER:
		{
			entityPickedUp[client] = EntIndexToEntRef(lookingAt);
			killEntityIn(lookingAt, 0.0);
			
			StopSound(lookingAt, SNDCHAN_AUTO, SOUND_SpiderTurn);
			StopSound(lookingAt, SNDCHAN_AUTO, SOUND_SpiderTurn);
			
			AttachSpiderToBack(client, GetEntProp(lookingAt, Prop_Data, "m_iHealth"), GetEntProp(lookingAt, Prop_Data, "m_iMaxHealth"));
		}
		
		case AWARD_G_COW:
		{
			entityPickedUp[client] = EntIndexToEntRef(lookingAt);
			killEntityIn(lookingAt, 0.0);
			AttachCowToBack(client, GetEntProp(lookingAt, Prop_Data, "m_iHealth"), GetEntProp(lookingAt, Prop_Data, "m_iMaxHealth"));
		}
		
		case AWARD_G_CRAP:
		{
			entityPickedUp[client] = EntIndexToEntRef(lookingAt);
			StopSound(lookingAt, SNDCHAN_AUTO, SOUND_CRAPIDLE);
			EmitSoundToAll(SOUND_SLURP,client);
			client_rolls[client][AWARD_G_CRAP][0] = 1;
			client_rolls[client][AWARD_G_CRAP][1] ++;
			killEntityIn(lookingAt, 0.0);
		}
		
		case AWARD_G_DUMMY:
		{
			entityPickedUp[client] = EntIndexToEntRef(lookingAt);
			//StopSound(lookingAt, SNDCHAN_AUTO, SOUND_CRAPIDLE);
			//EmitSoundToAll(SOUND_SLURP,client);
			client_rolls[client][AWARD_G_DUMMY][0] = 1;
			client_rolls[client][AWARD_G_DUMMY][1] = 1;
			client_rolls[client][AWARD_G_DUMMY][2] = GetEntProp(lookingAt, Prop_Data, "m_iHealth");
			client_rolls[client][AWARD_G_DUMMY][3] = GetEntProp(lookingAt, Prop_Data, "m_iMaxHealth");
			client_rolls[client][AWARD_G_DUMMY][4] = GetTime() + 3;
			
			client_rolls[client][AWARD_G_DUMMY][5] = GetEntPropEnt(lookingAt, Prop_Data, "m_hOwnerEntity");
			
			AttachRTDParticle(client, "target_break_child_puff", true, false, -45.0);
			
			killEntityIn(lookingAt, 0.0);
		}
		
		case AWARD_G_BOMB:
		{
			entityPickedUp[client] = EntIndexToEntRef(lookingAt);
			killEntityIn(lookingAt, 0.0);
			
			StopSound(lookingAt, SNDCHAN_AUTO, Bomb_Tick);
			
			client_rolls[client][AWARD_G_BOMB][3] = GetTime() + 1;
			
			client_rolls[client][AWARD_G_BOMB][0] = 1;
			client_rolls[client][AWARD_G_BOMB][1] ++;
			
			PrintCenterText(client, "Bomb disarmed!");
		}
		
		case AWARD_G_ICEBOMB:
		{
			entityPickedUp[client] = EntIndexToEntRef(lookingAt);
			killEntityIn(lookingAt, 0.0);
			
			StopSound(lookingAt, SNDCHAN_AUTO, Bomb_Tick);
			
			client_rolls[client][AWARD_G_ICEBOMB][3] = GetTime() + 1;
			
			client_rolls[client][AWARD_G_ICEBOMB][0] = 1;
			client_rolls[client][AWARD_G_ICEBOMB][1] ++;
			
			PrintCenterText(client, "Ice Bomb disarmed!");
		}
		
		case AWARD_G_FIREBOMB:
		{
			entityPickedUp[client] = EntIndexToEntRef(lookingAt);
			killEntityIn(lookingAt, 0.0);
			
			StopSound(lookingAt, SNDCHAN_AUTO, Bomb_Tick);
			
			client_rolls[client][AWARD_G_FIREBOMB][3] = GetTime() + 1;
			
			client_rolls[client][AWARD_G_FIREBOMB][0] = 1;
			client_rolls[client][AWARD_G_FIREBOMB][1] ++;
			
			PrintCenterText(client, "Fire Bomb disarmed!");
		}
		
		case AWARD_G_AMPLIFIER:
		{
			entityPickedUp[client] = EntIndexToEntRef(lookingAt);
			
			client_rolls[client][AWARD_G_AMPLIFIER][0] = 1;
			client_rolls[client][AWARD_G_AMPLIFIER][1] ++; //how many the user has
			client_rolls[client][AWARD_G_AMPLIFIER][2] = GetEntProp(lookingAt, Prop_Data, "m_iHealth");
			client_rolls[client][AWARD_G_AMPLIFIER][3] = GetEntProp(lookingAt, Prop_Data, "m_iMaxHealth");
			client_rolls[client][AWARD_G_AMPLIFIER][4] = GetTime() + 5;
			
			AttachRTDParticle(client, "target_break_child_puff", true, false, -45.0);
			
			killEntityIn(lookingAt, 0.0);
		}
		
		case AWARD_G_BRAZIER:
		{
			entityPickedUp[client] = EntIndexToEntRef(lookingAt);
			
			StopSound(lookingAt, SNDCHAN_AUTO, SOUND_BRAZIER);
			
			client_rolls[client][AWARD_G_BRAZIER][0] = 1;
			client_rolls[client][AWARD_G_BRAZIER][1] ++;
			
			client_rolls[client][AWARD_G_BRAZIER][4] = GetTime() + 5;
			
			killEntityIn(lookingAt, 0.0);
		}
	}
}

public Pickup_AimTarget(client, lookingAt, objectTeam, clientTeam, lookingAtModelIndex)
{
	new Float:distance;
	new Float:playerPos[3];
	new Float:objectPos[3];
	new skin;
	new tempAward;
	new parent = GetEntPropEnt(lookingAt, Prop_Data, "m_pParent");
	new owner = GetEntPropEnt(lookingAt, Prop_Data, "m_hOwnerEntity");
	
	GetClientAbsOrigin(client, playerPos);
	
	if(IsValidEntity(parent))
	{
		GetEntPropVector(parent, Prop_Send, "m_vecOrigin", objectPos);
	}else{
		GetEntPropVector(lookingAt, Prop_Send, "m_vecOrigin", objectPos);
	}
	
	distance = GetVectorDistance(playerPos, objectPos);
	lookingAtPickup[client][1] = -1;
	
	if (lookingAtModelIndex == spiderIndex)
	{
		if(objectTeam == clientTeam)
		{
			if(owner== client)
			{
				
				if(client_rolls[client][AWARD_G_SPIDER][1] == 0 && !itemEquipped_OnBack[client])
				{
					if(distance < 200.0)
					{
						lookingAtPickup[client][0] = AWARD_G_SPIDER;
						lookingAtPickup[client][1] = lookingAt;
						
						if(RTDOptions[client][0] == 0)
						{
							centerHudText(client, "Right Click to pick up your Spider", 1.0, 0.5, HudMsg5, 0.76); 
						}else{
							centerHudText(client, "+Use to pick up your Spider", 1.0, 0.5, HudMsg5, 0.76); 
						}
					}else{
						centerHudText(client, "Spider too far to be picked up!", 0.0, 1.0, HudMsg5, 0.76); 
					}
				}else{
					if(denyPickup(client, AWARD_G_SPIDER, false))
						return;
				}
			}
		}
	}
	else if (lookingAtModelIndex == cowModelIndex)
	{
		if(objectTeam == clientTeam)
		{
			if(!itemEquipped_OnBack[client])
			{
				if(client_rolls[client][AWARD_G_COW][3] <= GetTime())
				{
					if(distance < 200.0)
					{
						lookingAtPickup[client][0] = AWARD_G_COW;
						lookingAtPickup[client][1] = lookingAt;
						
						if(RTDOptions[client][0] == 0)
						{
							centerHudText(client, "Right Click to pick up the Cow", 0.0, 1.0, HudMsg5, 0.76); 
						}else{
							centerHudText(client, "+Use to pick up the Cow", 0.0, 1.0, HudMsg5, 0.76); 
						}
						
					}else{
						centerHudText(client, "Cow too far to be picked up!", 0.0, 1.0, HudMsg5, 0.76); 
					}
				}else{
					new String:message[64];
					Format(message, sizeof(message), "Wait %is before picking up Cow",client_rolls[client][AWARD_G_COW][3] - GetTime()); 
					centerHudText(client, message, 0.0, 1.0, HudMsg5, 0.76); 
				}
			}else{
				if(denyPickup(client, AWARD_G_COW, false))
					return;
			}
		}
	}
	else if (lookingAtModelIndex == crapModelIndex)
	{
		if(objectTeam == clientTeam)
		{
			if(client == GetEntPropEnt(lookingAt, Prop_Data, "m_hOwnerEntity"))
			{
				if(distance < 200.0)
				{
					if(RTD_PerksLevel[client][19])
					{
						lookingAtPickup[client][0] = AWARD_G_CRAP;
						lookingAtPickup[client][1] = lookingAt;
						
						if(RTDOptions[client][0] == 0)
						{
							centerHudText(client, "Right Click to pick up the Crap", 0.0, 1.0, HudMsg5, 0.76); 
						}else{
							centerHudText(client, "+Use to pick up the Crap", 0.0, 1.0, HudMsg5, 0.76); 
						}
					}else{
						centerHudText(client, "Perk required to pickup Crap", 0.0, 1.0, HudMsg5, 0.76); 
					}
					
				}else{
					if(RTD_PerksLevel[client][19])
						centerHudText(client, "Crap too far to be picked up!", 0.0, 1.0, HudMsg5, 0.76);
				}
			}
		}
	}
	else if (lookingAtModelIndex == dummyModelIndex)
	{
		if(objectTeam == clientTeam)
		{
			if(distance < 200.0)
			{
				if(!client_rolls[client][AWARD_G_DUMMY][0])
				{
					if(client_rolls[client][AWARD_G_DUMMY][4] > GetTime())
					{
						centerHudText(client, "Wait 3s before picking up Dummy again!", 0.0, 1.0, HudMsg5, 0.76); 
					}else{
						lookingAtPickup[client][0] = AWARD_G_DUMMY;
						lookingAtPickup[client][1] = lookingAt;
						
						if(RTDOptions[client][0] == 0)
						{
							centerHudText(client, "Right Click to pick up Punching Dummy", 0.0, 1.0, HudMsg5, 0.76); 
						}else{
							centerHudText(client, "+Use to pick up Punching Dummy", 0.0, 1.0, HudMsg5, 0.76); 
						}
					}
				}else{
					centerHudText(client, "Can't pickup another Dummy!", 0.0, 1.0, HudMsg5, 0.76); 
				}	
			}else{
				centerHudText(client, "Punching Dummy too far to be picked up!", 0.0, 1.0, HudMsg5, 0.76);
			}
		}
	}
	else if (lookingAtModelIndex == bombModelIndex)
	{
		if(objectTeam != clientTeam)
		{
			if(distance < 100.0)
			{
				if(RTD_PerksLevel[client][36] > 0)
				{
					skin = GetEntProp(lookingAt, Prop_Data, "m_nSkin");
					
					switch(skin)
					{
						case 0:
							tempAward = AWARD_G_BOMB;
						
						case 1:
							tempAward = AWARD_G_FIREBOMB;
						
						case 2:
							tempAward = AWARD_G_ICEBOMB;
					}
					
					if(GetTime() > client_rolls[client][tempAward][3])
					{
						lookingAtPickup[client][0] = tempAward;
						lookingAtPickup[client][1] = lookingAt;
						
						if(RTDOptions[client][0] == 0)
						{
							centerHudText(client, "Right Click to disarm Bomb", 0.0, 1.0, HudMsg5, 0.76); 
						}else{
							centerHudText(client, "+Use to disarm Bomb", 0.0, 1.0, HudMsg5, 0.76); 
						}
						
					}else{
						centerHudText(client, "Wait 2s before trying to disarm another bomb!", 0.0, 1.0, HudMsg5, 0.76); 
					}
					
				}else{
					centerHudText(client, "Can't disarm bomb! You have not obtained this perk!!", 0.0, 1.0, HudMsg5, 0.76); 
				}	
			}else{
				centerHudText(client, "Bomb too far to disarm!!", 0.0, 1.0, HudMsg5, 0.76);
			}
		}
	}
	else if (lookingAtModelIndex == amplifierModelIndex)
	{
		if(objectTeam == clientTeam && GetEntProp(lookingAt, Prop_Data, "m_PerformanceMode") == client)
		{
			if(client_rolls[client][AWARD_G_AMPLIFIER][4] <= GetTime())
			{
				if(distance < 200.0)
				{
					lookingAtPickup[client][0] = AWARD_G_AMPLIFIER;
					lookingAtPickup[client][1] = lookingAt;
					
					if(RTDOptions[client][0] == 0)
					{
						centerHudText(client, "Right Click to pick up your Amplifier", 0.0, 1.0, HudMsg5, 0.76); 
					}else{
						centerHudText(client, "+Use to pick up your Amplifier", 0.0, 1.0, HudMsg5, 0.76); 
					}
					
				}else{
					centerHudText(client, "Amplifier too far to be picked up!", 0.0, 1.0, HudMsg5, 0.76); 
				}
			}else{
				new String:message[64];
				Format(message, sizeof(message), "Wait %is before picking up Amplifier",client_rolls[client][AWARD_G_AMPLIFIER][4] - GetTime()); 
				centerHudText(client, message, 0.0, 1.0, HudMsg5, 0.76); 
			}
		}
	}
	else if (lookingAtModelIndex == brazierModelIndex)
	{
		if(objectTeam == clientTeam)
		{
			if(client == GetEntPropEnt(lookingAt, Prop_Data, "m_hOwnerEntity"))
			{
				if(distance < 200.0)
				{
					lookingAtPickup[client][0] = AWARD_G_BRAZIER;
					lookingAtPickup[client][1] = lookingAt;
					
					if(RTDOptions[client][0] == 0)
					{
						centerHudText(client, "Right Click to pick up the Brazier", 0.0, 1.0, HudMsg5, 0.76); 
					}else{
						centerHudText(client, "+Use to pick up the Brazier", 0.0, 1.0, HudMsg5, 0.76); 
					}
					
				}else{
					centerHudText(client, "Brazier too far to be picked up!", 0.0, 1.0, HudMsg5, 0.76);
				}
			}
		}
	}
}

public SpawnAnnotation(client, entity, String:message[], Float:lookingAtOrigin[3])
{
	new bitstring=1;
	bitstring|= RoundFloat(Pow(2.0, float(client)));
	
	if (bitstring > 1 )
	{
		new String:strId[64];
		FormatEx(strId, sizeof(strId), "%d%d", entity, GetClientUserId(client));
		entity= StringToInt(strId);

		new Handle:event = CreateEvent("show_annotation");
		if (event != INVALID_HANDLE)
		{
			SetEventFloat(event, "worldPosX", lookingAtOrigin[0]);
			SetEventFloat(event, "worldPosY", lookingAtOrigin[1]);
			SetEventFloat(event, "worldPosZ", lookingAtOrigin[2]);
			SetEventFloat(event, "lifetime", 2.0);
			SetEventInt(event, "id", entity);
			SetEventString(event, "text", message);
			SetEventInt(event, "visibilityBitfield", bitstring);
			FireEvent(event);
			
			//PrintToChat(client, "Ano Shown: %i", GetTime());
		}
	}
}

public SpawnAnnotationEx(client, entity, String:message[], Float:lookingAtOrigin[3], Float:lifetime)
{
	new bitstring=1;
	bitstring|= RoundFloat(Pow(2.0, float(client)));
	
	if (bitstring > 1 )
	{
		new String:strId[64];
		FormatEx(strId, sizeof(strId), "%d%d", entity, GetClientUserId(client));
		entity= StringToInt(strId);

		new Handle:event = CreateEvent("show_annotation");
		if (event != INVALID_HANDLE)
		{
			SetEventFloat(event, "worldPosX", lookingAtOrigin[0]);
			SetEventFloat(event, "worldPosY", lookingAtOrigin[1]);
			SetEventFloat(event, "worldPosZ", lookingAtOrigin[2]);
			SetEventFloat(event, "lifetime", lifetime);
			SetEventInt(event, "id", entity);
			SetEventString(event, "text", message);
			SetEventInt(event, "visibilityBitfield", bitstring);
			FireEvent(event);
		}
	}
}

stock bool:isModelRTDObject(lookingAtModelIndex)
{
	for (new i = 0; i < totModels ; i++)
	{
		if(modelIndex[i] < 1)
			continue;
		
		if(modelIndex[i] == lookingAtModelIndex)
			return true;
	}
	
	return false;
}

public denyPickup(client, lookingAtObject, bool:bypassSame)
{
	
	new String:message[64];
	new String:wearing[32];
	
	new wantsToPickup = -1;
	
	if(client_rolls[client][AWARD_G_BACKPACK][0])
	{
		if((bypassSame && lookingAtObject != AWARD_G_BACKPACK) || !bypassSame)
		{
			Format(wearing, sizeof(wearing), "wearing");
			
			wantsToPickup = AWARD_G_BACKPACK;
		}
	}
	
	if(client_rolls[client][AWARD_G_BLIZZARD][0])
	{
		if((bypassSame && lookingAtObject != AWARD_G_BLIZZARD) || !bypassSame)
		{
			Format(wearing, sizeof(wearing), "wearing");
			
			wantsToPickup = AWARD_G_BLIZZARD;
		}
	}
	
	if(client_rolls[client][AWARD_G_SPIDER][1] != 0)
	{
		if((bypassSame && lookingAtObject != AWARD_G_SPIDER) || !bypassSame)
		{
			Format(wearing, sizeof(wearing), "carrying");
			
			wantsToPickup = AWARD_G_SPIDER;
		}
	}
	
	if(client_rolls[client][AWARD_G_COW][1] != 0)
	{
		if((bypassSame && lookingAtObject != AWARD_G_COW) || !bypassSame)
		{
			Format(wearing, sizeof(wearing), "carrying");
			
			wantsToPickup = AWARD_G_COW;
		}
	}
	
	if(client_rolls[client][AWARD_G_WINGS][0])
	{
		if((bypassSame && lookingAtObject != AWARD_G_WINGS) || !bypassSame)
		{
			Format(wearing, sizeof(wearing), "wearing");
			
			wantsToPickup = AWARD_G_WINGS;
		}
	}
	
	if(client_rolls[client][AWARD_G_STONEWALL][0])
	{
		if((bypassSame && lookingAtObject != AWARD_G_STONEWALL) || !bypassSame)
		{
			Format(wearing, sizeof(wearing), "carrying");
			
			wantsToPickup = AWARD_G_STONEWALL;
		}
	}
	
	if(wantsToPickup != -1)
	{
		if(wantsToPickup == lookingAtObject)
		{
			Format(message, sizeof(message), "Can't pickup another %s!", roll_Text[lookingAtObject]);
		}else{
			Format(message, sizeof(message), "Can't pickup %s%s while %s %s%s", roll_Article[lookingAtObject], roll_Text[lookingAtObject], wearing, roll_Article[wantsToPickup], roll_Text[wantsToPickup]);
		}
		
		centerHudText(client, message, 0.0, 1.0, HudMsg3, 0.8);
		
		return true;
	}
	
	return false;
}