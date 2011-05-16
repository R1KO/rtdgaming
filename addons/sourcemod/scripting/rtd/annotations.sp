#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new g_ViewDist = 600;
/*
see BuildBitString for type
*/

Action:CreateAnnotation(id, String:message[], type=0, team=0, health=0, moving=0, entbox=0)
{
	//Firing this event does not close it's handle :/
}

/*
Action:CreateAnnotation(id, String:message[], type=0, team=0, health=0, moving=0, entbox=0)
{
	if(!annotation)
		return;
	
	decl Float:timeRun;

	new Handle:dataPackHandle;
	if(moving)
		timeRun = 0.1;
	else
		timeRun = 0.3;
	
	CreateDataTimer(timeRun, Timer_Annotation, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE); //4.0 is the delay
	
	WritePackCell(dataPackHandle, id);
	WritePackCell(dataPackHandle, type);
	WritePackCell(dataPackHandle, team);
	WritePackCell(dataPackHandle, health);
	WritePackCell(dataPackHandle, moving);
	WritePackCell(dataPackHandle, entbox);
	WritePackString(dataPackHandle, message);
}


public Action:Timer_Annotation(Handle:timer, any:dataPackHandle)
{
	new Float:pos[3], String:message[256], maxHealth;
	ResetPack(dataPackHandle);
	
	new id = ReadPackCell(dataPackHandle);
	if(!IsValidEntity(id) || !annotation)
		return Plugin_Stop;
	
	//make sure not to show anotations if it's attached to a player
	new parent = GetEntPropEnt(id, Prop_Data, "m_pParent");
	if(parent > 0 && parent <= MaxClients)
	{
		//PrintToChatAll("nono , not a player!");
		return Plugin_Continue;
	}
	
	new type = ReadPackCell(dataPackHandle);
	new team = ReadPackCell(dataPackHandle);
	new health = ReadPackCell(dataPackHandle);
	new moving = ReadPackCell(dataPackHandle);
	new entbox = ReadPackCell(dataPackHandle);
	ReadPackString(dataPackHandle, message, sizeof(message));
	
	if(health)
	{
		health = GetEntProp(id, Prop_Data, "m_iHealth");
		maxHealth = GetEntProp(id, Prop_Data, "m_iMaxHealth");
		FormatEx(message, sizeof(message), "%s%d/%d HP", message, health, maxHealth);
	}
	
	if(entbox != 0)
	{
		GetEntPropVector(entbox, Prop_Data, "m_vecOrigin", pos);
	}else{
		GetEntPropVector(id, Prop_Data, "m_vecOrigin", pos);
	}
	
	pos[2] += 50.0;
	
	if(moving)
	{
		SpawnAnnotation(id, pos, message, 0.7, type, team);
	}else{
		SpawnAnnotation(id, pos, message, 0.7, type, team);
	}
		
	return Plugin_Continue;
}

Action:SpawnAnnotation(id, Float:pos[3], String:message[], Float:lifetime, type=0, team=0)
{
	new Handle:event = CreateEvent("show_annotation", true);
	if (event != INVALID_HANDLE)
	{
		if(team)
		{
			if(team == RED_TEAM && type == 2)
				team = BLUE_TEAM;
			else if(team == BLUE_TEAM && type == 2)
				team = RED_TEAM;
				
		}
		new bitstring = BuildBitString(id, pos, type, team);
		if (bitstring > 1)
		{
			
			pos[2] -= 35.0;
			SetEventFloat(event, "worldPosX", pos[0]);
			SetEventFloat(event, "worldPosY", pos[1]);
			SetEventFloat(event, "worldPosZ", pos[2]);
			SetEventFloat(event, "lifetime", lifetime);
			SetEventInt(event, "id",  id);
			SetEventString(event, "text", message);
			SetEventInt(event, "visibilityBitfield", bitstring);
			FireEvent(event);
			KillTimer(event);
		}
		
	}
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}

public CanPlayerSee(ent, client, Float:position[3])
{
	//new foundParentEnt = GetEntPropEnt(ent, Prop_Data, "m_pParent");

	
	if(GetClientAimTarget(client, false) == ent)
	{
		//PrintToChat(client, "cheese!");
		return true;
	}
	
	return false;
}
/*
 type
 0=all
 1=team
 2=other team
*/

/*
public BuildBitString(ent, Float:position[3], type, team)
{
	new bitstring=1;
	for(new client=1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			if((type == 1 && GetClientTeam(client) != team) || ((type == 2 && GetClientTeam(client) != team)))
				continue;
			
			//if(RTDOptions[client][5] != 2)
			//	continue;
				
			new Float:EyePos[3];
			GetClientEyePosition(client, EyePos);
			
			if (GetVectorDistance(position, EyePos) < g_ViewDist)
			{
				if(CanPlayerSee(ent, client, position))
				{
					bitstring |= RoundFloat(Pow(2.0, float(client)));
				}
			}
		}
	}
	
	return bitstring;
}*/