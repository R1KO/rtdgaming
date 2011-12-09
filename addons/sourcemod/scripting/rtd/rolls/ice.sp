#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>

public Action:Spawn_Ice(client)
{
	//-------------------------------------------------------------------
	new ent = CreateEntityByName("prop_physics_override");
	SetEntityModel(ent,MODEL_ICE);
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 0);  //default = 2
	
	DispatchSpawn(ent);
	
	//Set the Ice's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	new iTeam = GetClientTeam(client);
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	
	//SetEntProp(ent, Prop_Data, "m_takedamage", 0);  //default = 2
	
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	
	SetEntProp( ent, Prop_Data, "m_nSolidType", 4 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 4 );
	//------------------------------------------------------------------------
	
	new Float:pos[3];
	
	GetClientEyePosition(client,pos);
	
	pos[2] += 20.0;
	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	
	
	AcceptEntityInput( ent, "DisableShadow" );
	
	//name the ice
	new String:iceName[128];
	Format(iceName, sizeof(iceName), "ice%i", ent);
	DispatchKeyValue(ent, "targetname", iceName);
	
	
	EmitSoundToAll(SOUND_ICE, ent);
	
	//The Datapack stores all the Spider's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, Ice_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(ent)); //entity
	WritePackCell(dataPackHandle, 120); //8 liveTime
	WritePackCell(dataPackHandle, GetTime()); //16 currentTime
	
	new String:mapName[128];
	GetCurrentMap(mapName, 128);
	if(StrContains(mapName, "pl_", false) != -1)
	{
		WritePackCell(dataPackHandle, -1); //24 time to freeze
	}else{
		WritePackCell(dataPackHandle, GetTime() + 10); //24 time to freeze
	}
	
	AttachTempParticle(ent,"rtd_snowfall_groundLOW_fix", 115.0, true,iceName,0.0, false);
	
	return Plugin_Handled;
}

public stopIceTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new ice = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new liveTime =  ReadPackCell(dataPackHandle);
	new startTime =  ReadPackCell(dataPackHandle);
	
	if(!IsValidEntity(ice))
		return true;
	
	
	if(ice < 1)
	{
		return true;
	}
	
	if(GetTime() > startTime + liveTime)
	{
		StopSound(ice, SNDCHAN_AUTO, SOUND_ICE);
		AcceptEntityInput(ice,"kill");
		
		return true;
	}
	
	return false;
}

public Action:Ice_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopIceTimer(dataPackHandle))
	{	
		for (new i = 1; i <= MaxClients ; i++)
		{
			inIce[i] = false;
			if(!IsClientInGame(i) || !IsPlayerAlive(i))
			{
				continue;
			}
			
			inIce[i] = false;
			SetEntityGravity(i, 1.0);
			ResetClientSpeed(i);
		}
		
		return Plugin_Stop;
	}
	
	ResetPack(dataPackHandle);
	new ent = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	//should the ice patch freeze in place?
	SetPackPosition(dataPackHandle, 24);
	new timeToFreeze = ReadPackCell(dataPackHandle);
	if(timeToFreeze != -1)
	{
		if(Phys_IsMotionEnabled(ent))
		{
			if(GetTime() > timeToFreeze)
			{
				Phys_EnableMotion(ent, false);
			}
		}
	}
	
	new Float: icePos[3];
	new playerTeam;
	new Float:clientpos[3];
	new iceTeam = GetEntProp(ent, Prop_Data, "m_iTeamNum");
	
	//Check the owner
	new owner = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");
	
	if(owner > 0)
	{
		if(GetClientTeam(owner) != iceTeam)
		{
			owner = -1;
		}
	}
	
	GetEntPropVector(ent, Prop_Data, "m_vecOrigin", icePos);
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		playerTeam = GetClientTeam(i);
		
		//Check to see if player is close to a Crap Pile
		//is Ducking, on the ground, etc.
		new cflags = GetEntData(i, m_fFlags);
		
		//let's see if player position is valid to drop ice
		new bool:foundInIce = false;
		
		GetClientAbsOrigin(i,clientpos);
		new shieldEquipped = GetEntProp(i, Prop_Send, "m_bShieldEquipped");
		
		if(isPlayerHolding_UniqueWeapon(i, 128) || isPlayerHolding_UniqueWeapon(i, 239))
			shieldEquipped = 1;
	
		if(!inIce[i] && GetEntityGravity(i) == 5.0)
			SetEntityGravity(i, 1.0);
		
		//Loop
		if(GetVectorDistance(clientpos,icePos) < 150.0)
		{
			if(playerTeam == iceTeam)
				TF2_RemoveCondition(i, TFCond_OnFire);
			
			//Push the player down ONLY if they are above it
			if(playerTeam != iceTeam && icePos[2] < clientpos[2] && (clientpos[2] - icePos[2]) < 100.0)
				SetEntityGravity(i, 5.0);
			
			//PrintCenterText(i,"Ice:%f | Player:%f",icePos[2],clientpos[2]);
			if(cflags & FL_ONGROUND && (icePos[2] - 30.0) <= clientpos[2])
			{
				inIce[i] = true;
				inIceEnt[i] = ent;
				foundInIce = true;
			}
		}
		
		if(foundInIce == false)
		{
			inIce[i] = false;
			inIceEnt[i] = 0;
			
			
			if(!client_rolls[i][AWARD_G_SPEED][0] && !shieldEquipped)
				ResetClientSpeed(i);
		}
		
		if(inIce[i] && playerTeam != iceTeam && inIceEnt[i] == ent)
		{
			//chance to freeze client
			if(owner > 0 && owner <= MAXPLAYERS)
			{
				if(RTD_Perks[owner][20] && client_rolls[i][AWARD_G_BLIZZARD][7] == 0 && GetTime() > client_rolls[i][AWARD_G_BLIZZARD][3] )
				{
					//PrintToChat(i, "owner can freeze!");
					if(GetRandomInt(0, 10) >= 8)
					{
						
						//mark the next time the client can get frozen
						client_rolls[i][AWARD_G_BLIZZARD][3] = GetTime() + 15;
						
						//mark the client as frozen
						client_rolls[i][AWARD_G_BLIZZARD][7] = 1;
						
						FreezeClient(i, i, 1.5);
					}
				}
			}
			
			//Make the user slide faster
			SetEntDataFloat(i, m_flMaxspeed, 1400.0);
			new Float:playerspeed[3];
			
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", playerspeed);
			
			ScaleVector(playerspeed, 100.0);
			playerspeed[2] = 0.0;
			
			TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, playerspeed);
			SetEntityGravity(i, 100.5);
			
			if(clientOverlay[i] == false)
				ShowOverlay(i, "effects/dodge_overlay", 5.0);
			
		}
		
		if(!inIce[i] && GetEntityGravity(i) == 100.5)
		{
			SetEntityGravity(i, 1.1);
			
			if(shieldEquipped)
				ResetClientSpeed(i);
		}
		
	}
	
	return Plugin_Continue;
}


/* ShowOverlay()
**
** Shows an overlay.
** ------------------------------------------------------------------------- */
public ShowOverlay(client, String:overlay[], Float:time)
{	
	new Handle:pack;
	
	clientOverlay[client] = true;
	
	OverlayCommand(client, overlay);
	
	CreateDataTimer(0.1, Timer_MaintainOverlay, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	WritePackCell(pack, client);
	WritePackString(pack, overlay);
	WritePackFloat(pack, time);
}

/* OverlayCommand()
**
** Runs r_screenoverlay on a client (removing cheat flags and then adding them again quickly).
** ------------------------------------------------------------------------- */
public OverlayCommand(client, String:overlay[])
{	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		new flags; 
		
		flags  = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
		SetCommandFlags("r_screenoverlay", flags);

		ClientCommand(client, "r_screenoverlay %s", overlay);
		
		if (overlayTimer != INVALID_HANDLE) {
			KillTimer(overlayTimer);
		}
		
		overlayTimer = CreateTimer(0.1, Timer_OverlayBlockCommand);
	}
}

/* Timer_MaintainOverlay()
**
** Maintains an overlay on a client for a given time. Otherwise it gets reset by fire, etc.
** ------------------------------------------------------------------------- */
public Action:Timer_MaintainOverlay(Handle:timer, Handle:pack)
{
	new client, String:overlay[64], Float:time;
	
	ResetPack(pack);
	client = ReadPackCell(pack);
	ReadPackString(pack, overlay, 64);
	time = ReadPackFloat(pack);
	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		time -= 0.1;
		
		if(movingHUD[client])
			return Plugin_Continue;
		
		if ((RoundToFloor(time * 10) <= 0) || !clientOverlay[client] || StrEqual("effects/dodge_overlay", overlay, true) && !inIce[client] || !IsPlayerAlive(client) || StrEqual("models/props_combine/portalball001_sheet ", overlay, true) && !client_rolls[client][AWARD_G_STRENGTHDRAIN][3]) 
		{
			OverlayCommand(client, "\"\"");
			clientOverlay[client] = false;
			
			return Plugin_Stop;
		}
		
		OverlayCommand(client, overlay);
		
		ResetPack(pack);
		WritePackCell(pack, client);
		WritePackString(pack, overlay);
		WritePackFloat(pack, time);
		
		return Plugin_Continue;
	} else {
		return Plugin_Stop;
	}
}

/* Timer_OverlayBlockCommand()
**
** Blocks r_screenoverlay command.
** ------------------------------------------------------------------------- */
public Action:Timer_OverlayBlockCommand(Handle:timer)
{
	overlayTimer = INVALID_HANDLE;
	
	new flags = GetCommandFlags("r_screenoverlay") | (FCVAR_CHEAT);
	SetCommandFlags("r_screenoverlay", flags);
}