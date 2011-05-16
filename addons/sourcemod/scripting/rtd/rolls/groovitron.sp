//Last modified: 1/8/2010
#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

public Action:Timer_GroovitronLights(Handle:timer, any:i)
{
	if(!IsValidEntity(i))
	{
		KillTimer(timer);
		return Plugin_Handled;
	}
	
	new Float:pos[3];
	new Float:vec[3];
	
	GetEntPropVector(i, Prop_Data, "m_vecOrigin", vec);
	
	//Move the light origin to the middle of the sphere
	vec[2] -= 25.0;
	
	pos[0] = vec[0] + float(GetRandomInt(50,150) * GetRandomInt(-1, 1));
	pos[1] = vec[1] + float(GetRandomInt(50,150) * GetRandomInt(-1, 1));
	pos[2] = vec[2] + float(GetRandomInt(50,150) * GetRandomInt(-1, 1));
	
	// Basic color arrays for temp entities
	new groovitron_beam_color[4] = {0, 0, 0, 255};
	
	groovitron_beam_color[0] = GetRandomInt(0, 255);
	groovitron_beam_color[1] = GetRandomInt(0, 255);
	groovitron_beam_color[2] = GetRandomInt(0, 255);
	TE_SetupBeamPoints(vec, pos, g_BeamSprite, g_HaloSprite, 0, 1, 1.1, 20.0, 1.0, 20, 0.0, groovitron_beam_color, 10);
	TE_SendToAll();
	return Plugin_Handled;
}

public Action:Timer_GroovitronJump(Handle:timer, Handle:data)
{
	ResetPack(data);
	new ent = EntRefToEntIndex(ReadPackCell(data));
	if(!IsValidEntity(ent))
	{
		return Plugin_Stop;
	}
	
	new client = ReadPackCell(data);
	new Float:groovePos[3];
	
	GetEntPropVector(ent, Prop_Data, "m_vecOrigin", groovePos);
	
	new grooveTeam = GetEntProp(ent, Prop_Data, "m_iTeamNum");
	for (new i = 1; i < MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) == grooveTeam)
			continue;
		
		new Float:pos[3];
		GetClientEyePosition(i, pos);
		
		new Float:distance = GetVectorDistance(groovePos, pos);
		
		if (distance < GetConVarFloat(g_Cvar_DiscoRadius))
		{
			new Float:finalvec[3], appliedPerk = false;
			finalvec[2]=GetConVarFloat(g_Cvar_DiscoHeight)*50.0;
			if (client < cMaxClients && client > 0)
				if(RTD_Perks[client][31]) {
					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, finalvec);
					appliedPerk = true;
				}
			
			if (!appliedPerk) {
				finalvec[0]=GetRandomFloat(100.0, 150.0)*GetRandomInt(-1,1);
				finalvec[1]=GetRandomFloat(100.0, 150.0)*GetRandomInt(-1,1);
				SetEntDataVector(i,BaseVelocityOffset,finalvec,true);
			}
		}
	}
	return Plugin_Handled;
}

public Action:Spawn_Groovitron(client)
{
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Groovitron !" );
		return Plugin_Handled;
	}
	
	SetEntityModel(ent, MODEL_GROOVITRON );
	//SetEntityModel(ent, MODEL_CLOUD );
	
	DispatchSpawn(ent);
	
	new Float:pos[3] ;
	//GetClientAbsOrigin(client,pos);
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
	
	pos[2] += 175.0;
	new Float:groovitron_angle[3] = {0.0, 0.0, 180.0};
	TeleportEntity(ent, pos, groovitron_angle, NULL_VECTOR);
	
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	EmitSoundToAll(SOUND_GROOVITRON, ent, SNDCHAN_AUTO);

	//Used so entities other than clients can spawn
	//new iTeam = GetClientTeam(client);
	new iTeam = GetEntProp(client, Prop_Data, "m_iTeamNum");
	
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	
	if(iTeam == RED_TEAM)
	{
		SetVariantString("255+100+100");
		AcceptEntityInput(ent, "color", -1, -1, 0);
	}
	else
	{
		SetVariantString("100+100+255");
		AcceptEntityInput(ent, "color", -1, -1, 0);
	}
	
	CreateTimer(0.1, Timer_GroovitronLights, ent, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(40.0, Timer_KillGroovitron, ent);
	
	new Handle:data;
	CreateDataTimer(1.5, Timer_GroovitronJump, data, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(data, EntIndexToEntRef(ent));
	WritePackCell(data, client);
	/*
	if(annotation)
	{
		CreateAnnotation(ent, "Friendly", 1, iTeam);
		CreateAnnotation(ent, "Enemy", 2, iTeam);
	}*/
	
	return Plugin_Handled;
}

public Action:Timer_KillGroovitron(Handle:timer, any:i)
{
	if(IsValidEntity(i))
	{	
		StopSound(i, SNDCHAN_AUTO, SOUND_GROOVITRON);
		AcceptEntityInput(i,"kill");
	}
	return Plugin_Handled;
}
