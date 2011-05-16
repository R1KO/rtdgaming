#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2>
#include <rtd_rollinfo>


//turret_shield
//turret_shield_b

public Action:SpawnShield(client, lookingAt)
{
	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Building Shield" );
		return Plugin_Handled;
	}
	
	client_rolls[client][AWARD_G_BUILDINGSHIELD][0] --;
	
	SetEntityModel(ent, MODEL_SENTRYSHIELD);
	
	new String:playerName[128];
	Format(playerName, sizeof(playerName), "target%i", client);
	DispatchKeyValue(client, "targetname", playerName);
	
	new String:buildingName[128];
	if(RTD_PerksLevel[client][50] == 1)
	{
		Format(buildingName, sizeof(buildingName), "perkshield%i", ent);
		DispatchKeyValue(lookingAt, "targetname", buildingName);
	}else{
		Format(buildingName, sizeof(buildingName), "shield%i", ent);
		DispatchKeyValue(lookingAt, "targetname", buildingName);
	}
	
	//Set the Shield's owner
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	DispatchSpawn(ent);
	
	new Float:buildingPosition[3];
	GetEntPropVector(lookingAt, Prop_Send, "m_vecOrigin", buildingPosition);
	
	TeleportEntity(ent, buildingPosition, NULL_VECTOR, NULL_VECTOR);
	
	SetVariantString(buildingName);
	AcceptEntityInput(ent, "SetParent");
	
	//setup the color
	if(GetClientTeam(client) == RED_TEAM)
	{
		DispatchKeyValue(ent, "skin","2"); 
	}else{
		DispatchKeyValue(ent, "skin","1"); 
	}
	
	AcceptEntityInput( ent, "DisableShadow" );
	AcceptEntityInput( ent, "DisableCollision" );
	
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0);
	
	new String:name[32];
	GetClientName(client, name, sizeof(name));
	
	//The Datapack stores all the Backpack's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.5, BuildingShield_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(ent));   //PackPosition(0);  Shield Entity Index
	WritePackCell(dataPackHandle, 0);     //PackPosition(16); time to remit particle
	WritePackCell(dataPackHandle, EntIndexToEntRef(lookingAt));   //PackPosition(0);  Building Entity Index
	WritePackString(dataPackHandle, buildingName);
	WritePackCell(dataPackHandle, GetClientTeam(client));
	//AttachTempParticle(ent,"turret_shield", 15.0, true,buildingName,30.0, false);
	
	return Plugin_Handled;
}

public Action:BuildingShield_Timer(Handle:timer, Handle:dataPackHandle)
{
	ResetPack(dataPackHandle);
	new shieldEnt = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	if(!IsValidEntity(shieldEnt))
		return Plugin_Stop;
	
	new nextParticleTime = ReadPackCell(dataPackHandle);
	
	new buildingEnt = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	new String:buildingName[128];
	ReadPackString(dataPackHandle, buildingName, 128);
	new iTeam = ReadPackCell(dataPackHandle);
	
	if(!IsValidEntity(buildingEnt))
	{
		killEntityIn(shieldEnt, 0.1);
		return Plugin_Stop;
	}
	
	//PrintToChatAll("m_bCarried: %i", GetEntData(buildingEnt, m_bCarried));
	
	//update the alpha
	new alpha = GetEntData(shieldEnt, m_clrRender + 3, 1);
	if(GetEntData(buildingEnt, m_bCarried) == 1)
	{
		if(alpha > 0)
		{
			SetEntityRenderMode(shieldEnt, RENDER_TRANSCOLOR);	
			SetEntityRenderColor(shieldEnt, 255, 255,255, 0);
		}
		return Plugin_Continue;
	}else{
		if(alpha == 0)
		{
			SetEntityRenderMode(shieldEnt, RENDER_TRANSCOLOR);	
			SetEntityRenderColor(shieldEnt, 255, 255,255, 255);
		}
	}
	
	//determine if particle should be spawned
	if(GetTime() > nextParticleTime)
	{
		if(iTeam == RED_TEAM)
		{
			AttachTempParticle(buildingEnt,"turret_shield", 6.0, true,buildingName,30.0, false);
		}else{
			AttachTempParticle(buildingEnt,"turret_shield_b", 6.0, true,buildingName,30.0, false);
		}
		
		SetPackPosition(dataPackHandle, 8);
		WritePackCell(dataPackHandle, GetTime() + 5);     //PackPosition(16); time to remit particle
	}
	
	return Plugin_Continue;
}