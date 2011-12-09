#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>

public Action:Spawn_DarknessCloud(client)
{
	if (!GetConVarInt(c_Enabled))
		return Plugin_Handled;
	
	
	new Float:vicorigvec[3];
	GetClientAbsOrigin(client, Float:vicorigvec);
	
	new ent = CreateEntityByName("prop_dynamic_override");
	
	SetEntityModel(ent,MODEL_SPIDERBOX);
	SetEntProp(ent, Prop_Data, "m_takedamage", 0);  //default = 2
	
	DispatchSpawn(ent);
	
	//Just a placeholder, this does not need to be rendered nor does it need shadows
	AcceptEntityInput( ent, "DisableShadow" );
	SetEntityRenderMode(ent, RENDER_NONE);
	SetEntityRenderMode(ent, RENDER_TRANSCOLOR);	
	SetEntityRenderColor(ent, 0, 0, 0, 0);
	
	//name the darkness cloud
	new String:boxName[128];
	
	new iTeam = GetClientTeam(client);
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	
	if(iTeam == RED_TEAM)
	{
		Format(boxName, sizeof(boxName), "darkcloud_red_%i", ent);
	}else{
		Format(boxName, sizeof(boxName), "darkcloud_blue_%i", ent);
	}
	DispatchKeyValue(ent, "targetname", boxName);
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 0);  //default = 2
	//SetEntProp(ent, Prop_Send, "m_takedamage", 2);  //default = 2
	
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	
	//Set the entity's health
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", 3000);
	SetEntProp(ent, Prop_Data, "m_iHealth", 3000);
	
	//SetEntProp(ent, Prop_Data, "m_CollisionGroup", 1);
	//SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
	
	TeleportEntity(ent, vicorigvec, NULL_VECTOR, NULL_VECTOR);
	
	EmitSoundToAll(SND_DROP, client);
	
	//SetVariantString("idle");
	//AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, DarknessCloud_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(ent)); //entity reference
	WritePackCell(dataPackHandle, GetTime()); //PackPosition(8) time to re-emit particle
	
	//kill in 5 minutes
	killEntityIn(ent, 300.0);
	return Plugin_Continue;
}

public FadeIN(client ,duration ,time ,alpha )
{
	new Handle:hBf=StartMessageOne("Fade",client);
	if(hBf!=INVALID_HANDLE)
	{
		duration *= 400;
		time *= 400;
		BfWriteShort(hBf,duration);
		BfWriteShort(hBf,time);
		BfWriteShort(hBf,FADE_OUT);
		BfWriteByte(hBf,0);
		BfWriteByte(hBf,0);
		BfWriteByte(hBf,0);
		BfWriteByte(hBf,alpha);
		EndMessage();
	}
}  

public stopDarknessCloudTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new darknessCloud = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	if(darknessCloud < 1)
		return true;
	
	if(!IsValidEntity(darknessCloud))
		return true;
	
	return false;
}

public Action:DarknessCloud_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopDarknessCloudTimer(dataPackHandle))
	{	
		return Plugin_Stop;
	}
	
	//////////////////////////////////////////
	//Retrieve the values from the datapack //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new darknessCloud = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new particleEmission = ReadPackCell(dataPackHandle);
	
	new Float: playerPos[3];
	new Float: darknessCloudPos[3];
	new playerTeam;
	new darknessCloudTeam =  GetEntProp(darknessCloud, Prop_Data, "m_iTeamNum");
	
	//////////////////////
	// Re-Emit Particle   //
	//////////////////////
	if(particleEmission < GetTime())
	{
		decl String:cloudName[32];
		
		if(darknessCloudTeam == RED_TEAM)
		{
			Format(cloudName, 32, "darkcloud_red_%i", darknessCloud);
			AttachTempParticle(darknessCloud, "eb_aura_angry01", 18.0, true, cloudName, 30.0, false);
		}else{
			Format(cloudName, 32, "darkcloud_blue_%i", darknessCloud);
			AttachTempParticle(darknessCloud, "eb_aura_calm01", 18.0, true, cloudName, 30.0, false);
		}
		
		SetPackPosition(dataPackHandle,8);
		WritePackCell(dataPackHandle, GetTime() + 15);
	}
	
	GetEntPropVector(darknessCloud, Prop_Data, "m_vecOrigin", darknessCloudPos);
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		playerTeam = GetClientTeam(i);
		
		GetClientAbsOrigin(i,playerPos);
		
		if(playerTeam == darknessCloudTeam)
			continue;
		
		//The user is too far from the cloud
		if(GetVectorDistance(playerPos,darknessCloudPos) > 150.0)
			continue;
		
		//Time darkness cloud will go away for player
		if(client_rolls[i][AWARD_G_DARKNESSCLOUD][4] <= GetTime())
		{
			FadeIN(i ,1 ,5 ,252);
			//PerformDarkness(i, 240);
			//PrintToChatAll("applying blind");
			
			client_rolls[i][AWARD_G_DARKNESSCLOUD][4] = GetTime() + 5;
		}
		
	}
	
	return Plugin_Continue;
}