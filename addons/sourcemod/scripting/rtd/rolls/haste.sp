#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

public Action:ProcessHaste(Handle:Timer, any:client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	//Player isn't using Haste anymore, remove effects
	if(!UsingHaste[client])
	{
		for (new i = 1; i <= MaxClients ; i++)
		{
			if(!IsClientInGame(i) || !IsPlayerAlive(i))
				continue;
			
			if(inHaste[client])
			{
				if(ROFMult[i] == 1.8)
					ROFMult[client] = 0.0;
				//don't reset if player has the Charge & targe or has speed
				if(!UsingSpeed[i])
					ResetClientSpeed(i);
				
				inHaste[i] = 0;
			}
		}
		
		return Plugin_Handled;
	}
	
	new Float:mainClientPos[3];
	new Float:otherClientPos[3];
	new Float:lookupClientPos[3];
	
	new mainPlayerTeam;
	new otherPlayerTeam;
	mainPlayerTeam = GetClientTeam(client);
	GetClientAbsOrigin(client,mainClientPos);
	
	new bool:foundInHaste;
	//new iWeapon;
	//new shieldEquipped;
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		otherPlayerTeam = GetClientTeam(i);
		
		if(otherPlayerTeam != mainPlayerTeam)
			continue;
		
		GetClientAbsOrigin(i,otherClientPos);
		
		foundInHaste = false;
		
		//is the player already in Haste?
		for (new j = 1; j <= MaxClients ; j++)
		{
			if(!IsClientInGame(j) || !IsPlayerAlive(j) || otherPlayerTeam != GetClientTeam(j) || !UsingHaste[j])
				continue;
			
			GetClientAbsOrigin(j,lookupClientPos);
			
			if(GetVectorDistance(lookupClientPos,otherClientPos) < 450.0)
				foundInHaste = true;
		}
			
		if(GetVectorDistance(mainClientPos,otherClientPos) < 450.0)
		{
			inHaste[i] = 1;
			
			if(!UsingBerserker[i])
				ROFMult[i] = 1.8;
			
			SetEntDataFloat(i, FindSendPropInfo("CTFPlayer", "m_flMaxspeed"), 1399.0);
		}else{
			//don't reset if player is caught in some1 else's haste
			if(!foundInHaste)
			{
				if(!UsingBerserker[i])
				{
					ROFMult[i] = 0.0;
				}else{
					ROFMult[i] = 2.0;
				}
				
				if(GetEntDataFloat(i,FindSendPropInfo("CTFPlayer", "m_flMaxspeed")) == 1399.0)
					ResetClientSpeed(i);
				
				inHaste[i] = 0;
			}
			
		}
		
	}
	return Plugin_Continue;
}

public Action:Attach_HasteBanner(client)
{
	UsingHaste[client] = 1;
	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Haste banner!" );
		return Plugin_Handled;
	}
	
	hasteEntityID[client] = ent;
	
	SetEntityModel(ent, MODEL_HASTEBANNER);
	DispatchSpawn(ent);
	
	new String:playerName[128];
	Format(playerName, sizeof(playerName), "target%i", client);
	DispatchKeyValue(client, "targetname", playerName);
	
	//Set the Banner's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	SetVariantString(playerName);
	AcceptEntityInput(ent, "SetParent");
	
	SetVariantString("flag");
	AcceptEntityInput(ent, "SetParentAttachment");
	
	AcceptEntityInput( ent, "DisableCollision" );

	if(GetClientTeam(client) == RED_TEAM)
		DispatchKeyValue(ent, "skin","0"); 
	
	if(GetClientTeam(client) == BLUE_TEAM)
		DispatchKeyValue(ent, "skin","1"); 
	
	EmitSoundToAll(SOUND_BANNERFLAG, ent);
	return Plugin_Handled;
}

public Action:StopHaste(Handle:Timer, any:client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	
	if(IsValidEntity(hasteEntityID[client]))
	{
		StopSound(hasteEntityID[client], SNDCHAN_AUTO, SOUND_BANNERFLAG);
		
		new String:modelname[128];
		GetEntPropString(hasteEntityID[client], Prop_Data, "m_ModelName", modelname, 128);
		if (StrEqual(modelname, MODEL_HASTEBANNER))
		{	
			AcceptEntityInput(hasteEntityID[client],"kill");
		}
	}else{
		new ent = -1;
		new String:modelname[128];
		
		while ((ent = FindEntityByClassname(ent, "prop_dynamic")) != -1)
		{
			GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 128);
			if (StrEqual(modelname, MODEL_HASTEBANNER))
			{
				new owner = GetEntPropEnt(ent, Prop_Data, "m_pParent");
				
				//Check to see if the fire particle entity is valid
				if(owner == client)
				{
					AcceptEntityInput(ent,"kill");
				}
			}
		}
	}
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if(inHaste[i])
		{
			if(!UsingBerserker[i])
			{
				ROFMult[i] = 0.0;
			}else{
				ROFMult[i] = 2.0;
			}
			
			if(GetEntDataFloat(i,FindSendPropInfo("CTFPlayer", "m_flMaxspeed")) == 1399.0)
				ResetClientSpeed(i);
			
			inHaste[i] = 0;
		}
	}
	
	UsingHaste[client] = 0;
	return Plugin_Handled;
}