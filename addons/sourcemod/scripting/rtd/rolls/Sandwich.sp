#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

public Action:Spawn_Sandwich(client)
{
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Sandwich!" );
		return Plugin_Handled;
	}
	
	SetEntityModel(ent, MODEL_SANDWICH);
	
	//make sure to do this before we actually spawn the P.O.S.
	SetEntProp(ent, Prop_Data, "m_takedamage", 0);  //default = 2
	
	DispatchSpawn(ent);
	
	//Set the Sandwich's owner
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
	
	
	CreateTimer(0.1, Sandwich_Timer, ent, TIMER_REPEAT |TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.0, SandwichEffects_Timer, ent, TIMER_REPEAT |TIMER_FLAG_NO_MAPCHANGE);
	
	new Float:pos[3];
	GetClientAbsOrigin(client,pos);
	
	pos[2] += 10.0;
	
	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	
	//Destroy the Sandwhich in 2 minutes
	killEntityIn(ent, 120.0);
	
	if(iTeam == BLUE_TEAM)
	{
		AttachRTDParticle(ent, "teleporter_blue_charged", true, false, -15.0);
	}else{
		AttachRTDParticle(ent, "teleporter_red_charged", true, false, -15.0);
	}
	
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0);
	
	EmitSoundToAll(SOUND_B, ent);
	
	return Plugin_Handled;
}

public Action:SandwichEffects_Timer(Handle:timer, any:sandwich)
{
	if(!IsValidEntity(sandwich))
	{
		KillTimer(timer);
		return Plugin_Handled;
	}
	
	new String:modelname[128];
	GetEntPropString(sandwich, Prop_Data, "m_ModelName", modelname, 128);
	
	if (!StrEqual(modelname, MODEL_SANDWICH))
	{
		KillTimer(timer);
		return Plugin_Handled;
	}
	
	new sandwichTeam = GetEntProp(sandwich, Prop_Data, "m_iTeamNum");
	
	if(sandwichTeam == BLUE_TEAM)
	{
		AttachRTDParticle(sandwich, "teleporter_blue_charged", true, false, -15.0);
	}else{
		AttachRTDParticle(sandwich, "teleporter_red_charged", true, false, -15.0);
	}
	
	return Plugin_Continue;
}

public Action:Sandwich_Timer(Handle:timer, any:other)
{
	if(!IsValidEntity(other))
	{
		return Plugin_Stop;
	}
	
	new String:modelname[128];
	GetEntPropString(other, Prop_Data, "m_ModelName", modelname, 128);
	
	if (!StrEqual(modelname, MODEL_SANDWICH))
	{
		return Plugin_Stop;
	}
	
	new Float: playerPos[3];
	new Float: SandwichPos[3];
	new Float: distance;
	new playerTeam;
	new SandwichTeam =  GetEntProp(other, Prop_Data, "m_iTeamNum");
	
	GetEntPropVector(other, Prop_Data, "m_vecOrigin", SandwichPos);
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		playerTeam = GetClientTeam(i);
		
		//Check to see if player is close to a Sandwich Pile
		if(playerTeam == SandwichTeam)
		{
			GetClientAbsOrigin(i,playerPos);
			distance = GetVectorDistance( playerPos, SandwichPos);
			
			if(distance < 100.0)
			{
				addHealth(i, 2);
			}
		}
	}
	
	return Plugin_Continue;
}