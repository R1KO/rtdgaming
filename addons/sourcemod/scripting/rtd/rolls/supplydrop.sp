#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

public Action:Spawn_Supply(client)
{
	new Float:pos[3];
	new Float:ang[3];
	GetClientEyePosition(client, pos);
	GetClientAbsAngles(client, ang); 
	
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
	
	new supply = CreateEntityByName("prop_dynamic");
	if ( supply == -1 )
	{
		ReplyToCommand(client, "Could not deploy a supply drop." );
		return Plugin_Handled;
	}
	
	decl String:buf[32];
	Format(buf, 32, "supply_%d", supply);
	DispatchKeyValue(supply, "targetname", buf);
	SetEntityModel(supply, MODEL_LOCKER);
	
	DispatchSpawn(supply);
	
	new iTeam = GetClientTeam(client);
	SetVariantInt(iTeam);
	AcceptEntityInput(supply, "TeamNum", -1, -1, 0);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(supply, "SetTeam", -1, -1, 0); 
	
	SetEntProp(supply, Prop_Data, "m_nSolidType", 6 );
	SetEntProp(supply, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(supply, Prop_Data, "m_CollisionGroup", 5);
	SetEntProp(supply, Prop_Send, "m_CollisionGroup", 5);
	
	TeleportEntity(supply, AmmoPos, ang, NULL_VECTOR);
	
	new supplyFunc = CreateEntityByName("func_regenerate");
	if (supplyFunc == -1) {
		ReplyToCommand(client, "Could not deploy a supply drop." );
		AcceptEntityInput(supply, "kill");
		return Plugin_Handled;
	}
	
	DispatchKeyValue(supplyFunc, "associatedmodel", buf);
	Format(buf, 32, "supplyfunc_%d", supplyFunc);
	DispatchKeyValue(supplyFunc, "name", buf);
	if (RTD_Perks[client][32] == 1)
	{
		DispatchKeyValue(supplyFunc, "teamnum", iTeam == 2 ? "2" : "3"); //0=Any team, 2=RED, 3=BLU
		
		if (iTeam == RED_TEAM)
		{
			SetVariantString("255+150+150");
			AcceptEntityInput(supply, "color", -1, -1, 0);
		}
		else
		{
			SetVariantString("150+150+255");
			AcceptEntityInput(supply, "color", -1, -1, 0);
		}
	}
	else
	{
		DispatchKeyValue(supplyFunc, "teamnum", "0"); //0=Any team, 2=RED, 3=BLU
	}
	
	DispatchKeyValue(supplyFunc, "StartDisabled", "false");
	SetEntityModel(supplyFunc, MODEL_LOCKER);
	
	DispatchSpawn(supplyFunc); 
	ActivateEntity(supplyFunc); 

	TeleportEntity(supplyFunc, AmmoPos, ang, NULL_VECTOR); 
	
	new Float:minbounds[3] = {-70.0, -70.0, -70.0}; 
	new Float:maxbounds[3] = {70.0, 70.0, 70.0}; 
	SetEntPropVector(supplyFunc, Prop_Send, "m_vecMins", minbounds); 
	SetEntPropVector(supplyFunc, Prop_Send, "m_vecMaxs", maxbounds); 
		 
	SetEntProp(supplyFunc, Prop_Send, "m_nSolidType", 2);
	
	
	killEntityIn(supply, 60.0);
	killEntityIn(supplyFunc, 60.0);
	
	return Plugin_Handled;
}