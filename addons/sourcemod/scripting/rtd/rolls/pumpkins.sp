//Last modified: 1/8/2010
#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

public Action:Spawn_Pumpkin(client)
{	
	new ent = CreateEntityByName("tf_pumpkin_bomb");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Pumpkin" );
		return Plugin_Handled;
	}
	
	SetEntityModel(ent, MODEL_EXPLODINGPUMPKIN);
	
	DispatchSpawn(ent);
	
	//When set players get credit for kill BUT
	//they can't shoot it their own pumpkins
	//SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
	
	new iTeam = GetClientTeam(client);
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	
	SetEntProp( ent, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 2);
	
	new Float:pos[3];
	GetClientEyePosition(client, pos);
	
	new Float:Direction[3];
	Direction[0] = pos[0];
	Direction[1] = pos[1];
	Direction[2] = pos[2]-1024;
	
	g_FilteredEntity = client;
	
	new Handle:Trace = TR_TraceRayFilterEx(pos, Direction, MASK_SOLID, RayType_EndPoint, TraceFilter);
	new Float:AmmoPos[3];
	TR_GetEndPosition(AmmoPos, Trace);
	CloseHandle(Trace);
	
	AmmoPos[2] += 4;
	
	//This is how we keep track of the pumpkins team
	//all of them are set to the same angle cause of Koth_Harvest pumpkins might have one of the same angles
	new Float:angle[3];
	angle[0] = float(iTeam);
	angle[1] = float(iTeam);
	angle[2] = float(iTeam);
	
	TeleportEntity(ent, AmmoPos, angle, NULL_VECTOR);
	
	EmitSoundToAll(SOUND_PUMPKINDROP,ent);
	/*
	if(annotation)
	{
		CreateAnnotation(ent, "Friendly", 1, iTeam);
		CreateAnnotation(ent, "Enemy", 2, iTeam);
	}*/
	
	return Plugin_Handled;
}