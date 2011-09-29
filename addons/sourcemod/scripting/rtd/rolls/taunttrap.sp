#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

//https://forums.alliedmods.net/showthread.php?t=75480, Bit and pieces taken from Lebson506th.

public Action:Place_Trap(client)
{
	new Float:pos[3];
	if(IsClientInGame(client) && GetPlayerEye(client, pos)) {
		TE_Start("World Decal");
		TE_WriteVector("m_vecOrigin", pos);
		TE_WriteNum("m_nIndex", g_DDRDecal);
		TE_SendToAll();
		PrintToChatAll("Sprayed!");
	}
}

stock bool:GetPlayerEye(client, Float:pos[3]) {
	new Float:vAngles[3], Float:vOrigin[3];

	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace)) {
	 	//This is the first function i ever saw that anything comes before the handle
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return true;
	}

	CloseHandle(trace);
	return false;
}

