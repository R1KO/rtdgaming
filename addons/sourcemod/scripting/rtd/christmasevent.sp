//Last modified: 1/8/2010
#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

public Action:SetupChristmasModel(client)
{
	new Float:pos[3];
	//new Float:rndLocation[3];
	
	new tree = CreateEntityByName("prop_physics_override");
	SetEntityModel(tree,MODEL_PINETREE);
	
	//name the tree
	new String:treeName[128];
	Format(treeName, sizeof(treeName), "tree%i", tree);
	DispatchKeyValue(tree, "targetname", treeName);
	
	//tree's fixed location
	GetClientAbsOrigin(client,pos);
	pos[0] += 60.0;
	pos[1] += 60.0;
	pos[2] += 45.0;
	
	
	DispatchSpawn(tree);
	
	TeleportEntity(tree, pos, NULL_VECTOR, NULL_VECTOR);
}

public Action:SpawnBarrel(client)
{
	new Float:pos[3];
	new Float:angle[3];
	
	if(IsEntLimitReached())
	{
		PrintToChat(client, "Too many entities!");
		return Plugin_Handled;
	}
	
	//set the position in front of the player
	GetClientAbsOrigin(client,pos);
	GetClientEyeAngles(client,angle);
	
	new Float: startPos[3];
	new Float: endPos[3];
	
	startPos[0] = pos[0];
	startPos[1] = pos[1];
	startPos[2] = pos[2] + 30.0 ;
	
	pos[0] += Cosine(DegToRad(angle[1])) * 60.0;
	pos[1] += Sine(DegToRad(angle[1])) * 60.0;
	pos[2] += 30.0;
	
	endPos[0] = pos[0];
	endPos[1] = pos[1];
	endPos[2] = pos[2];
	
	//is barrel going to collide with something else?
	new Float:hullBoxMin[3];
	new Float:hullBoxMax[3];
	
	hullBoxMin[0] = -17.0;
	hullBoxMin[1] = -17.0;
	hullBoxMin[2] = -17.0;
	
	hullBoxMax[0] = 17.0;
	hullBoxMax[1] = 17.0;
	hullBoxMax[2] = 17.0;
	
	new Handle:Trace = TR_TraceHullFilterEx(startPos, endPos,hullBoxMin,hullBoxMax, MASK_PLAYERSOLID	, TraceFilterAll,client);
	
	if(TR_DidHit(Trace))
	{
		EmitSoundToAll(SOUND_DENY, client);
		CloseHandle(Trace);
		return Plugin_Handled;
	}
	CloseHandle(Trace);
	/////////////////////////////////////////////////////////////////////////////////////////////////////
	
	new box = CreateEntityByName("prop_physics_override");
	if ( box == -1 )
	{
		ReplyToCommand( client, "Failed to create a SpiderBox!" );
		return Plugin_Handled;
	}
	
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Spider!" );
		return Plugin_Handled;
	}
	
	SetEntityModel(box, MODEL_SPIDERBOX);
	SetEntityModel(ent, MODEL_TOUGHSPIDER);
	
	
	//make sure to do this before we actually spawn the P.O.S.
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	SetEntProp(box, Prop_Data, "m_takedamage", 0);  //default = 2
	
	DispatchKeyValueFloat(box, "massScale", 20.0);
	
	DispatchSpawn(box);
	DispatchSpawn(ent);
	
	
	//Our 'sled' collision does not need to be rendered nor does it need shadows
	//AcceptEntityInput( ent, "DisableShadow" );
	//SetEntityRenderMode(ent, RENDER_NONE);
	
	//this is the flame entity
	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", -1);
	
	//owner entity for the Box tells it its the Spider
	SetEntPropEnt(box, Prop_Data, "m_hOwnerEntity", ent);
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	
	SetEntProp( ent, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 3);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 3);
	
	SetEntProp( box, Prop_Data, "m_nSolidType", 4 );
	SetEntProp( box, Prop_Send, "m_nSolidType", 4 );
	
	//Set the spider's health
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", 50);
	SetEntProp(ent, Prop_Data, "m_iHealth", 48);
	
	SetEntProp(ent, Prop_Data, "m_PerformanceMode", 1);
	
	//argggh F.U. valve
	AcceptEntityInput( ent, "DisableCollision" );
	AcceptEntityInput( ent, "EnableCollision" );
	
	//name the spider
	new String:prop_physics[128];
	new String:prop_dynamic[128];
	Format(prop_dynamic, sizeof(prop_dynamic), "spider%i", ent);
	DispatchKeyValue(ent, "targetname", prop_dynamic);
	
	//Now lets parent the physics box to the animated spider
	Format(prop_physics, sizeof(prop_physics), "target%i", box);
	DispatchKeyValue(box, "targetname", prop_physics);
	
	SetVariantString(prop_physics);
	AcceptEntityInput(ent, "SetParent");
	
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	TeleportEntity(box, pos, NULL_VECTOR, NULL_VECTOR);
	EmitSoundToAll(SOUND_B, box);
	
	// send "kill" event to the event queue
	new String:addoutput[64];
	Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::120.0:1");
	SetVariantString(addoutput);
	AcceptEntityInput(box, "AddOutput");
	AcceptEntityInput(box, "FireUser1");
	/*
	if(GetClientTeam(client) == RED_TEAM){
		SetVariantString("filter_blue_team");
	}else{
		SetVariantString("filter_red_team");
	}
	
	AcceptEntityInput(barrel, "SetDamageFilter", -1, -1, 0);
	*/
	DispatchKeyValue(box, "m_nSequence","1"); 
	//SetEntData(box, FindSendPropOffs("CPhysicsProp","m_nSequence "),                 1, 4 , true);
	//SetEntData(box, FindSendPropOffs("CPhysicsProp","m_nNewSequenceParity"),         4, 4 , true);
	//SetEntData(box, FindSendPropOffs("CPhysicsProp","m_nResetEventsParity"),         4, 4 , true);
	
	SetVariantString("walk");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	return Plugin_Handled;
}


public Action:SpawnStairs(client)
{
	new Float:pos[3];
	
	new tree = CreateEntityByName("prop_physics_override");
	SetEntityModel(tree,MODEL_STAIRS);
	
	//tree's fixed location
	GetClientAbsOrigin(client,pos);
	pos[0] += 60.0;
	pos[1] += 60.0;
	pos[2] += 45.0;
	
	DispatchSpawn(tree);
	
	TeleportEntity(tree, pos, NULL_VECTOR, NULL_VECTOR);
}