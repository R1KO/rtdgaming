#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2>

public Action:Spawn_Saw(client)
{
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Saw" );
		return Plugin_Handled;
	}
	
	SetEntityModel(ent, MODEL_SAW);
	
	//make sure to do this before we actually spawn the P.O.S.
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	DispatchSpawn(ent);
	
	
	new iTeam = GetEntProp(client, Prop_Data, "m_iTeamNum");
	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0); 
	
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);  //default = 2
	
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	
	SetEntProp( ent, Prop_Data, "m_nSolidType", 6 );
	SetEntProp( ent, Prop_Send, "m_nSolidType", 6 );
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 3);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 3);
	
	AcceptEntityInput( ent, "DisableCollision" );
	AcceptEntityInput( ent, "EnableCollision" );
	
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", 1000);
	SetEntProp(ent, Prop_Data, "m_iHealth", 1000);
	
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	//////////////////////////////////
	//create our "point hurts"      //
	//////////////////////////////////
	new Float:Origin[3];
	new Float:Rotation[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", Origin);
	GetEntPropVector(ent, Prop_Send, "m_angRotation", Rotation);
	
	new String:tName[128];
	new String:pointhurtName[64];
	new String:sawHurtName[64];
	Format(tName, sizeof(tName), "target%i", ent);
	
	
	
	DispatchKeyValue(ent, "targetname", tName);
	
	new pointhurt = CreateEntityByName("info_particle_system");
	if (IsValidEntity(pointhurt)) 
	{
		//set the bloods entity
		Format(pointhurtName, sizeof(pointhurtName), "target%i", pointhurt);
		DispatchKeyValue(pointhurt, "targetname", pointhurtName);
		
		TeleportEntity(pointhurt, Origin, Rotation, NULL_VECTOR);
		
		DispatchKeyValue(pointhurt, "effect_name", "env_sawblood");
		
		
		DispatchKeyValue(pointhurt, "parentname", tName);
		
		SetVariantString(tName);
		AcceptEntityInput(pointhurt, "SetParent", pointhurt, pointhurt, 0);
		
		SetVariantString("hurt1");
		AcceptEntityInput(pointhurt, "SetParentAttachment", pointhurt, pointhurt, 0);
		
		ActivateEntity(pointhurt);
		AcceptEntityInput(pointhurt, "stop");
    }
	
	new pointhurt2 = CreateEntityByName("info_particle_system");
	if (IsValidEntity(pointhurt2)) 
	{
		//set the bloods entity
		Format(sawHurtName, sizeof(sawHurtName), "target%i", pointhurt2);
		DispatchKeyValue(pointhurt2, "targetname", sawHurtName);
		
		TeleportEntity(pointhurt2, Origin, Rotation, NULL_VECTOR);
		
		DispatchKeyValue(pointhurt2, "effect_name", "blood_trail_red_01_goop");
		
		
		DispatchKeyValue(pointhurt2, "parentname", tName);
		
		SetVariantString(tName);
		AcceptEntityInput(pointhurt2, "SetParent", pointhurt, pointhurt, 0);
		
		SetVariantString("hurt2");
		AcceptEntityInput(pointhurt2, "SetParentAttachment", pointhurt, pointhurt, 0);
		
		ActivateEntity(pointhurt2);
		AcceptEntityInput(pointhurt2, "stop");
    }
	
	if(GetClientTeam(client) == RED_TEAM)
	{
		SetVariantString(bluDamageFilter);
	}else{
		SetVariantString(redDamageFilter);
	}
	AcceptEntityInput(ent, "SetDamageFilter", -1, -1, 0); 
	
	/////////////////////////////////////////////
	//Initiate the timer.                      //
	//Important variables to keep track of     //
	/////////////////////////////////////////////
	new Handle:dataPack;
	CreateDataTimer(0.2,Saw_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPack, ent);
	WritePackCell(dataPack, GetTime() + 120);//PackPosition(8)  --kill time
	WritePackCell(dataPack, GetTime() + 20);//PackPosition(16)  --next sound emission
	WritePackCell(dataPack, GetTime());//PackPosition(24)  --last hurt sound
	WritePackCell(dataPack, pointhurt);//PackPosition(32)  --pointhurt entity
	WritePackCell(dataPack, pointhurt2);//PackPosition(40)  --pointhurt entity
	WritePackCell(dataPack, GetClientUserId(client));//PackPosition(48)  --original client owner
	
	HookSingleEntityOutput(ent, "OnHealthChanged", Saw_Hurt, false);
	
	
	
	
	EmitSoundToAll(SOUND_SAW, ent);
	
	///////////////////////////////
	// Teleport it to the ground //
	///////////////////////////////
	new Float:pos[3];
	new Float:angl[3];
	
	GetEntPropVector(client, Prop_Data, "m_angRotation", angl);
	GetClientEyePosition(client, pos);
	
	new Float:Direction[3];
	Direction[0] = pos[0];
	Direction[1] = pos[1];
	Direction[2] = pos[2]-1024;
	
	new Float:floorPos[3];
	
	new Handle:Trace = TR_TraceRayFilterEx(pos, Direction, MASK_SOLID, RayType_EndPoint, TraceFilterAll, client);
	TR_GetEndPosition(floorPos, Trace);
	CloseHandle(Trace);
	
	TeleportEntity(ent, floorPos, angl, NULL_VECTOR);
	
	killEntityIn(ent, float(GetTime() + 120));
	
	return Plugin_Handled;
}

public Saw_Hurt (const String:output[], caller, activator, Float:delay)
{
	if(IsValidEntity(caller))
	{
		if(GetEntProp(caller, Prop_Data, "m_iHealth") <= 0)
		{
			//Let's reward the player for killing a spider
			new rndNum = GetRandomInt(0,20);
			if(rndNum > 10)
			{
				TF_SpawnMedipack(caller, "item_healthkit_medium", true);
			}else{
				TF_SpawnMedipack(caller, "item_ammopack_medium", true);
			}
			StopSound(caller, SNDCHAN_AUTO, SOUND_SAW);
		}
	}
}

public Action:Saw_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopSawTimer(dataPackHandle))
	{
		return Plugin_Stop;
	}
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new saw = ReadPackCell(dataPackHandle);
	
	SetPackPosition(dataPackHandle, 16);
	new soundEmission = ReadPackCell(dataPackHandle);
	
	new lastHurtSound = ReadPackCell(dataPackHandle);
	new pointHurt = ReadPackCell(dataPackHandle);
	new pointHurt2 = ReadPackCell(dataPackHandle);
	new clientUserID = ReadPackCell(dataPackHandle);
	
	new Float: playerPos[3];
	new Float: pointHurtPos[3];
	new Float: pointHurtPos2[3];
	new Float: distance;
	new Float: distance2;
	new cond;
	
	new client = GetClientOfUserId(clientUserID);
	if(client < 1)
	{
		client = saw;
	}else if(!IsClientInGame(client))
	{
		client = saw;
	}
	
	/////////////////////////
	//Regenerate Our sound //
	/////////////////////////
	if(soundEmission < GetTime())
	{
		StopSound(saw, SNDCHAN_AUTO, SOUND_SAW);
		CreateTimer(0.0, Timer_Saw_Sound, saw);
		
		SetPackPosition(dataPackHandle, 16);
		WritePackCell(dataPackHandle, GetTime() + 20);//PackPosition(16)  --next sound emission
	}
	
	GetEntPropVector(pointHurt, Prop_Data, "m_vecAbsOrigin", pointHurtPos);
	GetEntPropVector(pointHurt2, Prop_Data, "m_vecAbsOrigin", pointHurtPos2);
	
	///////////////////////////
	//Find nearby players    //
	///////////////////////////
	new sawTeam = GetEntProp(saw, Prop_Data, "m_iTeamNum");
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if(sawTeam == GetClientTeam(i))
			continue;
		
		cond = GetEntData(i, m_nPlayerCond);
		if(cond == 32 || cond == 327712)
			continue;
		
		GetClientAbsOrigin(i,playerPos);
		distance = GetVectorDistance( playerPos, pointHurtPos);
		distance2 = GetVectorDistance( playerPos, pointHurtPos2);
		
		if(distance < 60.0)
		{
			if(lastHurtSound< GetTime())
			{
				SetPackPosition(dataPackHandle, 24);
				WritePackCell(dataPackHandle, GetTime() + 1);//PackPosition(24)  --last hurt sound
				EmitSoundToAll(SOUND_SAW_HIT, i);
				
				AcceptEntityInput(pointHurt, "start");
				new String:addoutput[64];
				Format(addoutput, sizeof(addoutput), "OnUser1 !self:stop::1.0:1");
				SetVariantString(addoutput);
				AcceptEntityInput(pointHurt, "AddOutput");
				AcceptEntityInput(pointHurt, "FireUser1");
			}
			
			DealDamage(i,12 ,client,65536,"killed_by_saw");
		}else if(distance2 < 60.0)
		{
			if(lastHurtSound< GetTime())
			{
				SetPackPosition(dataPackHandle, 24);
				WritePackCell(dataPackHandle, GetTime() + 1);//PackPosition(24)  --last hurt sound
				EmitSoundToAll(SOUND_SAW_HIT, i);
				
				AcceptEntityInput(pointHurt2, "start");
				new String:addoutput[64];
				Format(addoutput, sizeof(addoutput), "OnUser1 !self:stop::1.0:1");
				SetVariantString(addoutput);
				AcceptEntityInput(pointHurt2, "AddOutput");
				AcceptEntityInput(pointHurt2, "FireUser1");
			}
			
			DealDamage(i,12 ,client,65536,"killed_by_saw");
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_Saw_Sound(Handle:Timer, any:saw)
{
	EmitSoundToAll(SOUND_SAW, saw);
}

public stopSawTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new saw = ReadPackCell(dataPackHandle);
	new liveTime = ReadPackCell(dataPackHandle);
	
	SetPackPosition(dataPackHandle, 32);
	new pointHurt = ReadPackCell(dataPackHandle);
	new pointHurt2 = ReadPackCell(dataPackHandle);
	
	if(!IsValidEntity(saw) || !IsValidEntity(pointHurt) || !IsValidEntity(pointHurt2))
	{	
		return true;
	}
	
	new currIndex = GetEntProp(saw, Prop_Data, "m_nModelIndex");
	
	if(currIndex != sawModelIndex)
	{
		StopSound(saw, SNDCHAN_AUTO, SOUND_SAW);
		return true;
	}
	
	if(GetTime() > liveTime)
	{
		StopSound(saw, SNDCHAN_AUTO, SOUND_SAW);
		killEntityIn(saw, 0.1);
		return true;
	}
	
	if(roundEnded)
	{
		StopSound(saw, SNDCHAN_AUTO, SOUND_SAW);
		killEntityIn(saw, 0.1);
		return true;
	}
	
	return false;
}