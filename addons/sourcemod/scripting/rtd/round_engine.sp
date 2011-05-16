#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Round_AddTime(time)
{
	//Time modification code taken from https://forums.alliedmods.net/showthread.php?p=619837, written by bl4nk
	new entityTimer = FindEntityByClassname(-1, "team_round_timer");
	if (entityTimer > -1)
	{
		decl String:mapName[32];
		GetCurrentMap(mapName, sizeof(mapName));

		if (strncmp(mapName, "pl_", 3) == 0)
		{
			decl String:buffer[32];
			Format(buffer, sizeof(buffer), "0 %i", time);

			SetVariantString(buffer);
			AcceptEntityInput(entityTimer, "AddTeamTime");
		}
		else
		{
			SetVariantInt(time);
			AcceptEntityInput(entityTimer, "AddTime");
		}
	}
	else
	{
		new Handle:timelimit = FindConVar("mp_timelimit");
		SetConVarFloat(timelimit, GetConVarFloat(timelimit) + (time / 60.0));
		CloseHandle(timelimit);
	}
}

public Round_SetTime(time)
{
	//Time modification code taken from https://forums.alliedmods.net/showthread.php?p=619837, written by bl4nk
	if (time < 0) time = 0;
	new entityTimer = FindEntityByClassname(-1, "team_round_timer");
	if (entityTimer > -1)
	{
		SetVariantInt(time);
		AcceptEntityInput(entityTimer, "SetTime");
	}
	else
	{
		new Handle:timelimit = FindConVar("mp_timelimit");
		SetConVarFloat(timelimit, time / 60.0);
		CloseHandle(timelimit);
	}
}