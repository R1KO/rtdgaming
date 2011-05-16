#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

#define cMaxClients 			34 //34 for sourcetv
#define MODEL_TELEPORTER		"models/buildables/teleporter.mdl"
#define REQ_ADMINFLAG Admin_Ban

new playerRating[cMaxClients][2];
new currentlyRating[cMaxClients];
new bool:votedFor[cMaxClients][cMaxClients];

//keeps track of the particle entity
//0 = Teleporter Entrance Particle entity
//1 = Teleporter Exit Particle entity
new teleporters[cMaxClients][2]; 

public Plugin:myinfo = 
{
	name = "RateThatTele",
	author = "Fox",
	description = "Allows players to rate teleporters",
	version = "1.0",
	url = "http://www.rtdgaming.com"
}

public OnPluginStart()
{
	HookEvent("player_teleported", Event_Player_Teleported );
	HookEvent("player_builtobject", Event_Player_BuiltObject);
}

public OnMapStart()
{
	CreateTimer(1.0,  Timer_UpdateParticles, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1,  Timer_CheckTeles, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
}

public OnClientPutInServer(client)
{
	//reset ratings for this client
	for(new i=1; i <= MaxClients; i++)
	{
		votedFor[client][i] = false;
	}
}

public Action:Event_Player_Teleported(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new builder = GetClientOfUserId(GetEventInt(event, "builderid"));
	
	//Players can't rate their own teles
	if(client == builder)
		return Plugin_Continue;
	
	//Players must be on the same team
	if(GetClientTeam(client) != GetClientTeam(builder))
		return Plugin_Continue;
	
	//Let's check to see if the player has an active menu displayed
	//if he does then we will not bother the player for a rating
	if(GetClientMenu(client) == MenuSource_None)
	{
		if(votedFor[client][builder] == false)
		{
			//Show rating menu to client
			currentlyRating[client] = builder;
			rateThatTele(client);
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_Player_BuiltObject(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new object = GetEventInt(event, "object");
	new index = GetEventInt(event, "index");
	 
	if (object == 1 || object == 2)
	{
		//reset ratings
		for(new i=1; i <= MaxClients; i++)
		{
			votedFor[i][client] = false;
		}
		CreateTimer(0.0, Timer_CreateParticle, index);
	}
}

public Action:Timer_CreateParticle(Handle:timer, any:index)
{
	if(IsValidEntity(index))
		AttachParticle(index, "star00");
	
	return Plugin_Handled;
}

public OnEntityDestroyed(entity)
{
	new String:classname[256];
	GetEdictClassname(entity, classname, sizeof(classname));
	
	if (StrEqual(classname, "obj_teleporter_entrance", false) || StrEqual(classname, "obj_teleporter_exit", false))
	{
		new tele_owner = GetEntDataEnt2(entity, FindSendPropOffs("CObjectTeleporter","m_hBuilder"));
		if(tele_owner > 0)
		{
			if(IsClientInGame(tele_owner))
			{
				new teleEntrance	= findTeleEntrance(tele_owner);
				new teleExit		= findTeleExit(tele_owner);
				
				playerRating[tele_owner][0] = 0;
				playerRating[tele_owner][1] = 0;
				
				updateTele(teleEntrance, teleExit, tele_owner);
			}
		}
	}
}

AttachParticle(ent, String:particleType[])
{	
	new String:classname[256];
	new tele_owner = GetEntDataEnt2(ent, FindSendPropOffs("CObjectTeleporter","m_hBuilder"));
	if(tele_owner > MaxClients || tele_owner <1)
		return;
	
	GetEdictClassname(ent, classname, sizeof(classname));
	
	//Finally create the particle
	new particle = CreateEntityByName("info_particle_system");

	new String:tName[128];
	if (IsValidEdict(particle))
	{	
		new Float:pos[3]; 
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);
		
		new iTeam = GetClientTeam(tele_owner);
		SetVariantInt(iTeam);
		AcceptEntityInput(ent, "TeamNum", -1, -1, 0);
		
		SetVariantInt(iTeam);
		AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
		
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		//Delete this particle in 1.5 seconds from now
		killEntityIn(particle, 2.0);
		
		//mark the entrance
		if (StrEqual(classname, "obj_teleporter_entrance", false))
			teleporters[tele_owner][0] = particle;
		
		//mark the exit
		if (StrEqual(classname, "obj_teleporter_exit", false))
			teleporters[tele_owner][1] = particle;
	}
}

public Action:rateThatTele(client)
{
	new Handle:hCMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_rateThatTeleMenuHandler);
	
	SetMenuTitle(hCMenu,"Rate That Tele!");

	AddMenuItem(hCMenu,	"Option 1", "Worthless");
	AddMenuItem(hCMenu,	"Option 2", "Poor");
	AddMenuItem(hCMenu,	"Option 3", "Average");
	AddMenuItem(hCMenu,	"Option 4", "Good");
	AddMenuItem(hCMenu,	"Option 5", "Awesome");
	

	DisplayMenu(hCMenu,client,10);
}

public fn_rateThatTeleMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action) 
	{
		case MenuAction_Select: 
		{
			//make sure that the client who built the tele is still here
			if(IsClientInGame(currentlyRating[param1]))
			{
				new teleEntrance	= findTeleEntrance(currentlyRating[param1]);
				new teleExit		= findTeleExit(currentlyRating[param1]);
				
				if(teleEntrance != 0 && teleExit != 0)
				{
					//This is a functioning tele!
					//Update the teles rating
					//but first check to see if user is an admin
					new rating;
					if (GetAdminFlag(GetUserAdmin(param1) , REQ_ADMINFLAG ))
					{
						//calculate the rating
						rating = (param2 + 1) * 3;
						
						//add the player's rating
						playerRating[currentlyRating[param1]][0] += rating;
						
						//Increase the amount of players that have voted for this tele
						//in this case we add 3 because Admins have more sway on ratings
						playerRating[currentlyRating[param1]][1] += 3;
					}else{
						//calculate the rating
						rating = param2 + 1;
						
						//add the player's rating
						playerRating[currentlyRating[param1]][0] += rating;
						
						//Increase the amount of players that have voted for this tele
						playerRating[currentlyRating[param1]][1] ++;
					}
					
					votedFor[param1][currentlyRating[param1]] = true;
					
					updateTele(teleEntrance, teleExit, currentlyRating[param1]);
				}
			}
		}
		
		case MenuAction_Cancel: {
		}
		
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public findTeleEntrance(teleOwner)
{
	//make sure the engineer has a functioning tele
	new tele_ent = -1;
	new foundOwner;
	new currentlevel;
	
	while ((tele_ent = FindEntityByClassname(tele_ent, "obj_teleporter_entrance")) != -1)
	{
		foundOwner = GetEntDataEnt2(tele_ent, FindSendPropOffs("CObjectTeleporter","m_hBuilder"));
		currentlevel = GetEntData(tele_ent, FindSendPropOffs("CObjectTeleporter","m_bPlacing"));
		//PrintToChatAll("Ent: %i | Lvl: %i",tele_ent,currentlevel);
		
		if(foundOwner == teleOwner && currentlevel != 1)
		{
			return tele_ent;
		}
	}
	
	return 0;
}

public findTeleExit(teleOwner)
{
	//make sure the engineer has a functioning tele
	new tele_ent = -1;
	new foundOwner;
	new currentlevel;
	
	while ((tele_ent = FindEntityByClassname(tele_ent, "obj_teleporter_exit")) != -1)
	{
		foundOwner = GetEntDataEnt2(tele_ent, FindSendPropOffs("CObjectTeleporter","m_hBuilder"));
		currentlevel = GetEntData(tele_ent, FindSendPropOffs("CObjectTeleporter","m_bPlacing"));
		
		if(foundOwner == teleOwner && currentlevel != 1)
		{
			return tele_ent;
		}
	}
	
	return 0;
}

public Action:updateTele(teleEntrance, teleExit, builder)
{
	new rating;
	
	if(playerRating[builder][1] <= 0)
	{
		if(teleEntrance > 0)
			AttachParticle(teleEntrance, "star00");
		
		if(teleExit > 0)
			AttachParticle(teleExit, "star00");
		
		return Plugin_Handled;
	}
	
	if(playerRating[builder][1] != 0)
		rating = RoundToNearest(float(playerRating[builder][0]/playerRating[builder][1]));
	
	new String:wantedEffect[128];
	Format(wantedEffect, sizeof(wantedEffect), "star0%i", rating);
	
	AttachParticle(teleEntrance, wantedEffect);
	AttachParticle(teleExit, wantedEffect);
	
	return Plugin_Continue;
}

public Action:Timer_UpdateParticles(Handle:timer)
{
	//This shouldn't be here but I gave up trying to get the tele particles to emit continously even though
	//they are already emitting continuously under their settings! Arrrghh!!!
	new TFClassType:class;
	new teleEntrance;
	new teleExit;
	
	for(new i=1; i <= MaxClients; i++)
	{
		// Check to make sure the player is on the same team
		if(IsClientInGame(i))
		{
			if(IsPlayerAlive(i))
			{
				class = TF2_GetPlayerClass(i);
				if(class == TFClass_Engineer)
				{
					teleEntrance	= findTeleEntrance(i);
					teleExit		= findTeleExit(i);
					
					updateTele(teleEntrance, teleExit, i);
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_CheckTeles(Handle:timer)
{
	//This shouldn't be here but I gave up trying to get the tele particles to emit continously even though
	//they are already emitting continuously under their settings! Arrrghh!!!
	new TFClassType:class;
	new teleEntrance;
	new teleExit;
	new rating = 1;
	new upgradeLevel;
	new Float:oldtime, Float:newtime, Float:normTime;
	
	for(new i=1; i <= MaxClients; i++)
	{
		// Check to make sure the player is on the same team
		if(IsClientInGame(i))
		{
			if(IsPlayerAlive(i))
			{
				class = TF2_GetPlayerClass(i);
				if(class == TFClass_Engineer)
				{
					teleEntrance	= findTeleEntrance(i);
					teleExit		= findTeleExit(i);
					
					if(teleEntrance > 0 && teleExit > 0)
					{
						upgradeLevel = GetEntProp(teleEntrance, Prop_Send, "m_iUpgradeLevel");
						oldtime = GetEntPropFloat(teleEntrance, Prop_Send, "m_flRechargeTime");
						
						if(playerRating[i][1] != 0)
							rating = RoundToNearest(float(playerRating[i][0]/playerRating[i][1]));
						
						//PrintToChat(i, "Time Entrance: %f | UpgradeLevel: %i | Rating: %i", oldtime, upgradeLevel, rating); 
						
						if(rating == 2)
							normTime = 1.01;
						else if(rating == 3)
							normTime = 2.01;
						else if(rating == 4)
							normTime = 3.01;
						else if(rating == 5)
							normTime = 4.01;
						
						
						//if(rating >= 3)
						//	time = float(6 - rating);
						
						newtime = oldtime - (normTime/upgradeLevel);
						
						if (newtime <= 0.0)
							continue;
						
						if( float(RoundFloat(oldtime)) == oldtime)
							continue;
						
						SetEntPropFloat(teleEntrance, Prop_Send, "m_flRechargeTime", float(RoundFloat(newtime)));
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}