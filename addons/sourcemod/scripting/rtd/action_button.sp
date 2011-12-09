#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>

public Action:Command_DropItem(client, args)
{
	Determine_DropItem(client);
	
	return Plugin_Continue;
}

public Determine_DropItem(client)
{
	//Only build menu if there are active items
	if(client_rolls[client][AWARD_G_BACKPACK][0]	|| 
	client_rolls[client][AWARD_G_BLIZZARD][0]		|| 
	client_rolls[client][AWARD_G_SPIDER][1]			||
	client_rolls[client][AWARD_G_WINGS][0]			||
	client_rolls[client][AWARD_G_STONEWALL][0]		||
	client_rolls[client][AWARD_G_TREASURE][0]		||
	client_rolls[client][AWARD_G_COW][1]			)
	{
		BuildUseableRollsMenu(client);
	}
}

public BuildUseableRollsMenu(client)
{
	//Build menu if user has more than one droppable
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_SpecialDropItem_Menu);
	new String:info[64];
	
	SetMenuTitle(hCMenu,"Select Roll to Activate");
	
	if(client_rolls[client][AWARD_G_TREASURE][0])
	{
		Format(info, sizeof(info), "%i:0", AWARD_G_TREASURE);
		AddMenuItem(hCMenu, info, "Drop Treasure Chest", ITEMDRAW_DEFAULT);
	}
	
	if(client_rolls[client][AWARD_G_BACKPACK][0])
	{
		Format(info, sizeof(info), "%i:0", AWARD_G_BACKPACK);
		AddMenuItem(hCMenu, info, "Drop 1 Ammo Pack", ITEMDRAW_DEFAULT);
		
		Format(info, sizeof(info), "%i:1", AWARD_G_BACKPACK);
		AddMenuItem(hCMenu, info, "Drop 1 Health Pack", ITEMDRAW_DEFAULT);
		
		Format(info, sizeof(info), "%i:2", AWARD_G_BACKPACK);
		AddMenuItem(hCMenu, info, "Drop Entire Backpack", ITEMDRAW_DEFAULT);
	}
	
	if(client_rolls[client][AWARD_G_BLIZZARD][0])
	{
		Format(info, sizeof(info), "%i:0", AWARD_G_BLIZZARD);
		AddMenuItem(hCMenu, info, "Drop Backpack Blizzard", ITEMDRAW_DEFAULT);
	}
	
	if(client_rolls[client][AWARD_G_STONEWALL][0])
	{
		Format(info, sizeof(info), "%i:0", AWARD_G_STONEWALL);
		AddMenuItem(hCMenu, info, "Drop Stonewall", ITEMDRAW_DEFAULT);
	}
	
	//Drop cow or spider
	if(client_rolls[client][AWARD_G_SPIDER][1])
		AddMenuItem(hCMenu, "1002", "Drop Spider", ITEMDRAW_DEFAULT);
	
	if(client_rolls[client][AWARD_G_COW][1])
		AddMenuItem(hCMenu, "1003", "Drop Cow", ITEMDRAW_DEFAULT);
	
	if(client_rolls[client][AWARD_G_WINGS][0])
		AddMenuItem(hCMenu, "1004", "Drop Redbull", ITEMDRAW_DEFAULT);
	
	//Nothing for the user
	if(GetMenuItemCount(hCMenu) == 0)
	{
		PrintToChat(client, "Closed, none found to populate menu");
		CloseHandle(hCMenu);
		return;
	}
	
	
	if(GetMenuItemCount(hCMenu) == 1)
	{
		//PrintToChat(client, "Auto select because 1");
		fn_SpecialDropItem_Menu(hCMenu, MenuAction_Select, client, 0);
	}else{
		DisplayMenu(hCMenu,client, 0);
	}
	
	//Used for 
}


public fn_SpecialDropItem_Menu(Handle:menu, MenuAction:action, param1, param2)
{
	if(param1 > 0)
	{
		if(IsClientInGame(param1))
		{
			if(!IsPlayerAlive(param1))
			{
				PrintCenterText(param1, "You must be alive and in game!");
				PrintToChat(param1, "You must be alive and in game!");
				action = MenuAction_Cancel;
			}
		}
	}
	
	switch (action) 
	{
		case MenuAction_Select: 
		{
			decl String:MenuInfo[64];
			
			new style;
			new String:menuTriggers[2][16];
			new triggersFound;
			
			GetMenuItem(menu, param2, MenuInfo, sizeof(MenuInfo),style);
			triggersFound = ExplodeString(MenuInfo, ":", menuTriggers, 2, 5);
			
			new itemSelection[2];
			itemSelection[0] = StringToInt(menuTriggers[0]);
			itemSelection[1] = StringToInt(menuTriggers[1]);
			
			//make sure player still has item
			if(triggersFound > 1)
			{
				if(client_rolls[param1][itemSelection[0]][0] == 0)
				{
					//Player no longer has item
					PrintCenterText(param1, "You no longer have %s", roll_Text[itemSelection[0]]);
					PrintToChat(param1, "You no longer have %s", roll_Text[itemSelection[0]]);
					EmitSoundToClient(param1, SOUND_DENY);
					return;
				}
			}
			
			//Player has item, allow action
			
			//this is for deployables
			if(itemSelection[1] == 9)
			{
				deployRoll(param1, itemSelection[0]);
				return;
			}
			
			switch(itemSelection[0])
			{
				case AWARD_G_BACKPACK:
				{
					switch(itemSelection[1])
					{
						case 0:
						{
							//Drop Ammo pack = 2
							DropItem_From_Backpack(param1, 2);
						}
						case 1:
						{
							//Drop Health pack = 3
							DropItem_From_Backpack(param1, 3);
						}
						case 2:
						{
							//Drop entire backpack
							Drop_Backpack(param1);
						}
					}
				}
				
				case AWARD_G_TREASURE:
				{
					Drop_Treasure(param1);
				}
				
				case AWARD_G_BLIZZARD:
				{
					Drop_Blizzard(param1);
				}
				
				case AWARD_G_STONEWALL:
				{
					Drop_Stonewall(param1);
				}
				
				//Drop Spider
				case 1002:
				{
					dropSpider(param1);
				}
				
				//Drop Cow
				case 1003:
				{
					dropCow(param1);
				}
				
				//Drop Redbull
				case 1004:
				{
					Drop_Wings(param1);
				}
			}
		}
		
		case MenuAction_Cancel: 
		{
		}
		
		case MenuAction_End: 
		{
			CloseHandle(menu);
		}
	}
}


public Action:RightClick_Timer(Handle:Timer)
{
	if (!GetConVarInt(c_Enabled))
		return Plugin_Handled;
	
	new iButtons;
	
	new totalActiveRolls;
	new activeRoll[totalRolls];
	
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		iButtons = GetClientButtons(i);
		
		if(movingHUD[i])
		{	
			if(iButtons & IN_FORWARD)
				HUDyPos[i][moveHUDStage[i]] -= 0.002;
			
			if(iButtons & IN_BACK)
				HUDyPos[i][moveHUDStage[i]] += 0.002;
			
			if(iButtons & IN_MOVELEFT)
				HUDxPos[i][moveHUDStage[i]] -= 0.002;
			
			if(iButtons & IN_MOVERIGHT)
				HUDxPos[i][moveHUDStage[i]] += 0.002;
			
			if(iButtons & IN_ATTACK)
			{
				if(!RightClickedDown[i])
				{
					RightClickedDown[i] = 1;
					EmitSoundToClient(i, SOUND_RESET);
					ShowOverlay(i, "rtdgaming/movehud02", 0.2);
					
					moveHUDStage[i] ++;
					if(moveHUDStage[i] > 1)
					{
						PrintCenterText(i, "Saved!");
						movingHUD[i] = false;
						SetEntityMoveType(i, MOVETYPE_WALK);
					}
				}
			}else{
				RightClickedDown[i] = 0;
			}
			
			continue;
		}
		
		//User is not given the ability to do anything if they are in a yoshi egg!
		if (yoshi_eaten[i][0])
			return Plugin_Continue;
		
		///////////////////////////////////////////////////////////////
		///    -ONLY THE FIRST TRUE STATEMENT WILL GET CALLED-       //
		///                                                          //
		///    The rest of the stuff will be be displayed on a       //
		///    first come first serve priority. For example If       //
		///    the player has more than 1 droppable item then        //
		///    it will drop the first item it encounters in the      //
		///    proceeding block of code.                             //
		//                                                           //
		//     Once the condition is true, it executes the code      //
		//     and goes to the next client!                          //
		///////////////////////////////////////////////////////////////
		
		//Figure out if the user is right cliking
		if(RTDOptions[i][0] == 0 && iButtons & IN_ATTACK2 && !RightClickedDown[i] || RTDOptions[i][0] == 1 && iButtons & IN_USE && !RightClickedDown[i] )
		{
			RightClickedDown[i] = 1;
		}else{
			if(!(RTDOptions[i][0] == 0 && iButtons & IN_ATTACK2 || RTDOptions[i][0] == 1 && iButtons & IN_USE ))
			{
				RightClickedDown[i] = 0;
				holdingRightClick[i] = 0;
			}
		}
		
		
		totalActiveRolls = 0;
		//Find the first active roll
		for(new tempAward = 0; tempAward < MAX_GOOD_AWARDS; tempAward ++)
		{
			if(roll_isDeployable[tempAward] && client_rolls[i][tempAward][0])
			{
				activeRoll[totalActiveRolls] = tempAward;
				totalActiveRolls ++;
				break;
			}
		}
		
		//Determine if player want to pickup an item
		if(lookingAtPickup[i][1] !=0 && RightClickedDown[i])
		{
			if(IsValidEntity(lookingAtPickup[i][1]))
			{
				if(GetEntProp(lookingAtPickup[i][1], Prop_Data, "m_PerformanceMode") == 1 || lookingAtPickup[i][0] == AWARD_G_SPIDER || lookingAtPickup[i][0] == AWARD_G_AMPLIFIER)
				{
					//Player wants to pickup item
					pickupItem(i, lookingAtPickup[i][0]);
					holdingRightClick[i] = 1;
					continue;
				}else{
					EmitSoundToClient(i, SOUND_DENY);
				}
			}else{
				lookingAtPickup[i][0] = 0;
				lookingAtPickup[i][1] = 0;
			}
		}
		
		//user has no active deployable rolls
		if(totalActiveRolls == 0)
		{	
			if(RightClickedDown[i] && iButtons & IN_USE && holdingRightClick[i] == 0)
			{
				holdingRightClick[i] = 1;
				Determine_DropItem(i);
			}
			
			continue;
		}
		
		//Show info pertaining to the roll
		if(!RightClickedDown[i] && client_rolls[i][activeRoll[0]][0])
		{
			if(!(iButtons & IN_SCORE))
				showRollMessage(i, activeRoll[0]);
			
			continue;
		}
		
		//User is holding down the action button
		if(RightClickedDown[i] && holdingRightClick[i] == 0)
		{
			//mark that the user has the action button pressed
			holdingRightClick[i] = 1;
			
			//make sure entity limit isn't reached before deploying this roll
			//deployables usually have entites attached to them and too many will crash server
			if(roll_EntLimit[activeRoll[0]] && IsEntLimitReached())
			{
				PrintCenterText(i, "Entity Limit reached! Please wait befor trying to deploy roll!");
				PrintToChat(i, "Entity Limit reached! Please wait befor trying to deploy roll!");
			}else{
				deployRoll(i, activeRoll[0]);
			}
		}
	}
	
	return Plugin_Continue;
}

public showRollMessage(client, tempAward)
{
	decl String:buttonToPress[64];
	decl String:dropIdent[64];
	decl String:message[64];
	
	/////////////////////////////////////////////////
	//Display user message on what they can deploy //
	/////////////////////////////////////////////////
	if(!RightClickedDown[client] && client_rolls[client][tempAward][0])
	{
		if(RTDOptions[client][0] == 0)
		{
			Format(buttonToPress, sizeof(buttonToPress), "Right Click");
		}else{
			Format(buttonToPress, sizeof(buttonToPress), "+USE");
		}
		
		if(roll_amountDeployable[tempAward] > 1)
		{
			returnOrdinal(client_rolls[client][tempAward][1], dropIdent, sizeof(dropIdent));
			Format(dropIdent, sizeof(dropIdent), "%i%s ", client_rolls[client][tempAward][1], dropIdent);
			
			if(client_rolls[client][tempAward][1] == 1)
				Format(dropIdent, sizeof(dropIdent), "last ");
				
			if(client_rolls[client][tempAward][1] == roll_amountDeployable[tempAward])
				Format(dropIdent, sizeof(dropIdent), "first ");
			
			Format(message, sizeof(message), "%s to %s%s%s!", buttonToPress, roll_ActionText[tempAward], dropIdent, roll_Text[tempAward]);
		}else
		{
			Format(message, sizeof(message), "%s to %s%s%s!", buttonToPress, roll_ActionText[tempAward], roll_Article[tempAward], roll_Text[tempAward]);
		}
		
		centerHudText(client, message, 0.0, 1.0, HudMsg6, 0.79); 
	}
}

public deployRoll(client, tempAward)
{	
	new bool:denyDrop = false;
	new tooClose = false;
	new Float:clientpos[3];
	
	switch(tempAward)
	{
		case AWARD_G_INSTAPORTER:
			denyDrop = !Spawn_Instaporter(client);
	
		case AWARD_G_HEARTSAPLENTY:
			Spawn_Heart(client);
	
		case AWARD_G_SUPPLYDROP:
			Spawn_Supply(client);
	
		case AWARD_G_BOMB:
			SpawnBomb(client, 1);
		
		case AWARD_G_FIREBOMB:
			SpawnBomb(client, 2);
		
		case AWARD_G_ICEBOMB:
			SpawnBomb(client, 3);
			
		case AWARD_G_GROOVITRON:
			Spawn_Groovitron(client);
		
		case AWARD_G_FLAME:
		{
			//let's see if player position is valid to drop 
			new ent = -1;
			
			GetClientAbsOrigin(client,clientpos);
			while ((ent = FindEntityByClassname(ent, "info_particle_system")) != -1)
			{
				if(GetEntProp(ent, Prop_Data, "m_iHealth") == 799)
				{
					new Float:flamePos[3];
					GetEntPropVector(ent, Prop_Data, "m_vecOrigin", flamePos);
					if(GetVectorDistance(clientpos,flamePos) < 100.0)
						tooClose = true;
				}
			}
			
			if(tooClose || CloseToEnemySpawnDoors(client))
			{
				if(tooClose)
					PrintCenterText(client,"Too close to another Flame");
				
				denyDrop = true;
			}
			
			if(!denyDrop)
				createFlame(client, 60.0);
		}
		
		case AWARD_G_ICE:
		{
			tooClose = closeToModel(client, 100.0, "prop_dynamic", MODEL_ICE);
			
			if(tooClose || CloseToEnemySpawnDoors(client))
			{
				if(tooClose)
					PrintCenterText(client,"Too close to another Ice Patch");
				
				denyDrop = true;
			}else{
				Spawn_Ice(client);
			}
		}
		
		case AWARD_G_SLOWCUBE:
		{
			tooClose = closeToModel(client, 230.0, "prop_dynamic", MODEL_SLOWCUBE);
			
			if(tooClose || CloseToEnemySpawnDoors(client))
			{
				if(tooClose)
					PrintCenterText(client,"Too close to another Slow Cube");
				
				denyDrop = true;
			}else{
				Spawn_SlowCube(client);
			}
		}
		
		case AWARD_G_CRAP:
			Spawn_Crap(client);
		
		case AWARD_G_SANDWICH:
		{
			tooClose = closeToModel(client, 100.0, "prop_dynamic", MODEL_SANDWICH);
			
			if(tooClose || CloseToEnemySpawnDoors(client))
			{
				if(tooClose)
					PrintCenterText(client,"Too close to another Sanwich");
				
				denyDrop = true;
			}else{
				Spawn_Sandwich(client);
			}
		}
		
		case AWARD_G_SPIDER:
		{
			client_rolls[client][AWARD_G_SPIDER][1] = 0;
			Spawn_Spider(client, 500 + RTD_Perks[client][15], 500 + RTD_Perks[client][15]);
		}
		
		case AWARD_G_JUMPPAD:
		{
			if(closeToMainObjects(client))
			{
				denyDrop = true;
			}else{
				Spawn_JumpPad(client);
			}
		}
		
		case AWARD_G_ACCELERATOR:
		{
			if(closeToMainObjects(client))
			{
				denyDrop = true;
			}else{
				Spawn_Accelerator(client);
			}
		}
		
		case AWARD_G_ZOMBIE:
			Spawn_Zombie(client, GetRandomInt(1,3));
		
		case AWARD_G_PROXMINES:
		{
			if(!isCloseToWall(client, 1))
			{
				denyDrop = true;
			}else{
				Spawn_Mine(client);
			}
		}
		
		case AWARD_G_PUMPKIN:
			Spawn_Pumpkin(client);
			
		case AWARD_G_FIREBALL:
		{
			Spawn_Fireball(client);
			createFlame(client, 15.0);
		}
		
		case AWARD_G_AMPLIFIER:
			Spawn_Amplifier(client, client_rolls[client][AWARD_G_AMPLIFIER][2], client_rolls[client][AWARD_G_AMPLIFIER][3]);
		
		case AWARD_G_GHOST:
			Spawn_Ghost(client);
		
		case AWARD_G_BEARTRAP:
		{
			tooClose = closeToModel(client, 100.0, "prop_dynamic", MODEL_BEARTRAP);
			
			if(tooClose)
			{
				if(tooClose)
					PrintCenterText(client,"Too close to another Bear Trap");
				
				denyDrop = true;
			}else{
				Spawn_BearTrap(client);
			}
		}
		
		case AWARD_G_CAGE:
		{
			tooClose = closeToModel(client, 400.0, "prop_physics", MODEL_CAGE);
			
			if(tooClose || CloseToEnemySpawnDoors(client))
			{
				if(tooClose)
					PrintCenterText(client,"Too close to another Cage");
				
				denyDrop = true;
			}else{
				Spawn_Cage(client);
			}
		}
		
		case AWARD_G_URINECLOUD:
		{
			tooClose = closeToModel(client, 200.0, "prop_dynamic", MODEL_CLOUD);
			
			if(tooClose || CloseToEnemySpawnDoors(client))
			{
				if(tooClose)
					PrintCenterText(client,"Too close to another Jarate Shower");
				
				denyDrop = true;
			}else{
				Spawn_UrineCloud(client);
			}
		}
		
		case AWARD_G_DIGLETT:
		{
			tooClose = closeToModel(client, 200.0, "prop_dynamic", MODEL_DIGLETT);
			
			if(tooClose || CloseToEnemySpawnDoors(client))
			{
				if(tooClose)
					PrintCenterText(client,"Too close to another Diglett");
					
				denyDrop = true;
			}else{
				Spawn_Diglett(client);
			}
		}
		
		case AWARD_G_SENTRYBUILDER:
			BuildSentry(client, 1, 1, 45);
		
		case AWARD_G_SAW:
		{
			tooClose = closeToModel(client, 200.0, "prop_dynamic", MODEL_SAW);
			
			if(tooClose || CloseToEnemySpawnDoors(client))
			{
				if(tooClose)
					PrintCenterText(client,"Too close to another Saw");
				
				denyDrop = true;
			}else{
				Spawn_Saw(client);
			}
		}
		
		case AWARD_G_COW:
		{
			if(CloseToEnemySpawnDoors(client))
			{
				denyDrop = true;
			}else{
				//cow perk
				if(RTD_Perks[client][17])
				{
					Spawn_Cow(client, 1000, 1000);
				}else{
					Spawn_Cow(client, 800, 800);
				}
			}
		}
		
		case AWARD_G_DUMMY:
		{
			Spawn_Dummy(client, client_rolls[client][AWARD_G_DUMMY][2], client_rolls[client][AWARD_G_DUMMY][3], client_rolls[client][AWARD_G_DUMMY][5]);
		}
		
		case AWARD_G_SNORLAX:
		{
			tooClose = closeToModel(client, 130.0, "prop_physics", MODEL_SNORLAX);
			
			if(CloseToEnemySpawnDoors(client) || tooClose || closeToMainObjects(client) || closeToCapturePoint(client, 250.0) || isCloseToWall(client, 2) || willCollide(client))
			{
				if(tooClose)
					PrintCenterText(client,"Too close to another Snorlax");
				
				denyDrop = true;
			}else{
				//snorlax perk
				if(RTD_Perks[client][33])
				{
					Spawn_Snorlax(client, 2500, 2500);
				}else{
					Spawn_Snorlax(client, 1500, 1500);
				}
			}
		}
		
		case AWARD_G_BUILDINGSHIELD:
		{
			new lookingAt = GetClientAimTarget(client, false);
			
			//see if player is looking at his building
			if(lookingAt > 0 && lookingAt <= 2048)
			{
				new String:netclassname[64];
				GetEntityNetClass(lookingAt, netclassname, sizeof(netclassname));
				
				if(StrEqual("CObjectSentrygun", netclassname) || StrEqual("CObjectDispenser", netclassname) || StrEqual("CObjectTeleporter", netclassname))
				{
					if(client == GetEntPropEnt(lookingAt, Prop_Send, "m_hBuilder"))
					{
						SpawnShield(client, lookingAt);
					}else{
						PrintCenterText(client,"Look at your OWN building to place a shield!");
						denyDrop = true;
					}
				}else{
					PrintCenterText(client,"Look at your building to place a shield!");
					denyDrop = true;
				}
				
			}else{
				denyDrop = true;
			}
		}
		
		case AWARD_G_BRAZIER:
			Spawn_Brazier(client, client_rolls[client][AWARD_G_BRAZIER][4]);
			
		case AWARD_G_ANGELIC:
		{
			Spawn_AngelicDispenser(client, 400, 400);
			
		}
		
		case AWARD_G_STRENGTHDRAIN:
		{
			tooClose = closeToModel(client, 230.0, "prop_dynamic", MODEL_STRENGTHDRAIN);
			
			if(tooClose || CloseToEnemySpawnDoors(client) || closeToCapturePoint(client, 300.0) )
			{
				if(tooClose)
					PrintCenterText(client,"Too close to another Strength Drain Aura");
				
				denyDrop = true;
			}else{
				Spawn_StrengthDrain(client);
			}
		}
		
		case AWARD_G_DARKNESSCLOUD:
		{
			tooClose = closeToModel(client, 130.0, "prop_dynamic", MODEL_STRENGTHDRAIN);
			
			if(tooClose || CloseToEnemySpawnDoors(client) || closeToCapturePoint(client, 250.0) )
			{
				if(tooClose)
					PrintCenterText(client,"Too close to another Darkness Cloud");
				
				denyDrop = true;
			}else{
				Spawn_DarknessCloud(client);
			}
		}
		
		case AWARD_G_SLICE:
		{
			tooClose = closeToModel(client, 140.0, "prop_dynamic", MODEL_SLICE);
			
			if(tooClose || CloseToEnemySpawnDoors(client))
			{
				if(tooClose)
					PrintCenterText(client,"Too close to another Slice N Dice");
				
				denyDrop = true;
			}else{
				Spawn_Slice(client);
			}
		}
		
	}
	
	/////////////////////////////////////
	//User is allowed to drop item     //
	/////////////////////////////////////
	if(!denyDrop)
	{
		decl String:message[64];
		//Display message on what was dropped
		Format(message, sizeof(message), "%s deployed!", roll_Text[tempAward]);
		centerHudText(client, message, 0.0, 5.0, HudMsg3, 0.82);
		
		EmitSoundToAll(SOUND_B, client);
		
		client_rolls[client][tempAward][1] --;
		if(client_rolls[client][tempAward][1] <= 0)
		{
			client_rolls[client][tempAward][1] = 0;
			client_rolls[client][tempAward][0] = 0;
		}
		
		//unmark unusual attribute
		client_rolls[client][tempAward][9] = 0;
	}else{
		EmitSoundToAll(SOUND_DENY, client);
	}
}

public willCollide(client)
{
	//set the position in front of the player
	new Float: startPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", startPos);
	
	//is barrel going to collide with something else?
	new Float:hullBoxMin[3];
	new Float:hullBoxMax[3];
	
	hullBoxMin[0] = -40.0;
	hullBoxMin[1] = -40.0;
	hullBoxMin[2] = 10.0;
	
	hullBoxMax[0] = 40.0;
	hullBoxMax[1] = 40.0;
	hullBoxMax[2] = 100.0;
	
	new Handle:Trace = TR_TraceHullFilterEx(startPos, startPos,hullBoxMin,hullBoxMax, MASK_PLAYERSOLID	, TraceFilterAll,client);
	
	if(TR_DidHit(Trace))
	{
		if(client < MaxClients)
		{
			PrintCenterText(client, "Too close to Wall!!");
			EmitSoundToAll(SOUND_DENY, client);
		}
		
		CloseHandle(Trace);
		return 1;
	}
	
	CloseHandle(Trace);
	
	return 0;
}
	
public closeToModel(client, Float:minDistance, String:classname[], String:modelname[])
{
	//closeToModel(i, 500.0, "prop_physics", MODEL_CAGE);
	//let's see if player position is valid to drop entity
	new ent = -1;
	new Float:clientpos[3];
	new String:foundModelName[128];
	new Float:entPos[3];
	
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", clientpos);
	
	if(StrEqual(modelname, ""))
	{
		while ((ent = FindEntityByClassname(ent, classname)) != -1)
		{
			GetEntPropVector(ent, Prop_Data, "m_vecOrigin", entPos);
			if(GetVectorDistance(clientpos,entPos) < minDistance)
				return true;
		}
	}else{
		while ((ent = FindEntityByClassname(ent, classname)) != -1)
		{
			GetEntPropString(ent, Prop_Data, "m_ModelName", foundModelName, 128);
			if (StrEqual(modelname, foundModelName))
			{
				
				GetEntPropVector(ent, Prop_Data, "m_vecOrigin", entPos);
				if(GetVectorDistance(clientpos,entPos) < minDistance)
					return true;
			}
		}
	}
	
	return false;
}

public closeToCapturePoint(client, Float:distance)
{
	new tooClose = closeToModel(client, distance, "team_control_point", "");
	if(tooClose)
	{
		PrintCenterText(client, "Too close to Control Point!");
		return true;
	}
	
	return false;
}

public closeToModelVec(Float:pos[3], Float:minDistance, String:classname[], String:modelname[])
{
	//closeToModel(i, 500.0, "prop_physics", MODEL_CAGE);
	//let's see if player position is valid to drop entity
	new ent = -1;
	new String:foundModelName[128];
	new Float:entPos[3];
	
	if(StrEqual(modelname, ""))
	{
		while ((ent = FindEntityByClassname(ent, classname)) != -1)
		{
			GetEntPropVector(ent, Prop_Data, "m_vecOrigin", entPos);
			if(GetVectorDistance(pos,entPos) < minDistance)
				return true;
		}
	}else{
		while ((ent = FindEntityByClassname(ent, classname)) != -1)
		{
			GetEntPropString(ent, Prop_Data, "m_ModelName", foundModelName, 128);
			if (StrEqual(modelname, foundModelName))
			{
				
				GetEntPropVector(ent, Prop_Data, "m_vecOrigin", entPos);
				if(GetVectorDistance(pos,entPos) < minDistance)
					return true;
			}
		}
	}
	
	return false;
}

public closeToMainObjects(client)
{
	new tooClose = closeToModel(client, 150.0, "obj_dispenser", "");
	if(tooClose)
	{
		PrintCenterText(client, "Too close to dispenser!");
		return true;
	}
	
	tooClose = closeToModel(client, 200.0, "obj_teleporter", "");
	if(tooClose)
	{
		PrintCenterText(client, "Too close to teleporter!");
		return true;
	}
	
	tooClose = closeToModel(client, 150.0, "obj_sentrygun", "");
	if(tooClose)
	{
		PrintCenterText(client, "Too close to teleporter!");
		return true;
	}
	
	tooClose = closeToModel(client, 350.0, "func_respawnroomvisualizer", "");
	if(tooClose)
	{
		PrintCenterText(client, "Too close to spawn room!");
		return true;
	}
	
	tooClose = closeToModel(client, 150.0, "prop_dynamic", MODEL_DICEDEPOSIT);
	if(tooClose)
	{
		PrintCenterText(client, "Too close to Dice Mine!");
		return true;
	}
	
	return false;
}
