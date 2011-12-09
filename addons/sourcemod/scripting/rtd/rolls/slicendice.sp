#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2>

public Action:Spawn_Slice(client)
{
	new ent = CreateEntityByName("prop_dynamic_override");
	if ( ent == -1 )
	{
		ReplyToCommand( client, "Failed to create a Slice N Dice" );
		return Plugin_Handled;
	}
	
	SetEntityModel(ent, MODEL_SLICE);
	
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
	
	SetEntProp(ent, Prop_Data, "m_iMaxHealth", 1200);
	SetEntProp(ent, Prop_Data, "m_iHealth", 1200);
	
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	if(GetClientTeam(client) == RED_TEAM)
	{
		SetVariantString(bluDamageFilter);
		DispatchKeyValue(ent, "skin","0"); 
	}else{
		SetVariantString(redDamageFilter);
		DispatchKeyValue(ent, "skin","1"); 
	}
	AcceptEntityInput(ent, "SetDamageFilter", -1, -1, 0); 
	
	/////////////////////////////////////////////
	//Initiate the timer.                      //
	//Important variables to keep track of     //
	/////////////////////////////////////////////
	new Handle:dataPack;
	CreateDataTimer(0.2,Slice_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPack, EntIndexToEntRef(ent));
	WritePackCell(dataPack, GetTime() + 300);//PackPosition(8)  --kill time
	WritePackCell(dataPack, GetTime() + 20);//PackPosition(16)  --next sound emission
	WritePackCell(dataPack, GetTime());//PackPosition(24)  --last hurt sound
	WritePackCell(dataPack, GetClientUserId(client));//PackPosition(48)  --original client owner
	
	HookSingleEntityOutput(ent, "OnHealthChanged", Slice_Hurt, false);
	
	
	
	
	EmitSoundToAll(SOUND_SLICE, ent);
	
	///////////////////////////////
	// Teleport it to the ground //
	///////////////////////////////
	new Float:pos[3];
	
	GetClientEyePosition(client, pos);
	
	new Float:Direction[3];
	Direction[0] = pos[0];
	Direction[1] = pos[1];
	Direction[2] = pos[2]-1024;
	
	new Float:floorPos[3];
	
	new Handle:Trace = TR_TraceRayFilterEx(pos, Direction, MASK_SOLID, RayType_EndPoint, TraceFilterAll, client);
	TR_GetEndPosition(floorPos, Trace);
	CloseHandle(Trace);
	
	TeleportEntity(ent, floorPos, NULL_VECTOR, NULL_VECTOR);
	
	killEntityIn(ent, 120.0);
	
	return Plugin_Handled;
}

public Slice_Hurt (const String:output[], caller, activator, Float:delay)
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
			StopSound(caller, SNDCHAN_AUTO, SOUND_SLICE);
		}
	}
}

public Action:Slice_Timer(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopSliceTimer(dataPackHandle))
	{
		return Plugin_Stop;
	}
	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new slice = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	SetPackPosition(dataPackHandle, 16);
	new soundEmission = ReadPackCell(dataPackHandle);
	
	new lastHurtSound = ReadPackCell(dataPackHandle);
	new clientUserID = ReadPackCell(dataPackHandle);
	
	new Float: playerPos[3];
	new Float: slicePos[3];
	new Float: distance;
	new cond;
	
	new client = GetClientOfUserId(clientUserID);
	if(client < 1)
	{
		client = slice;
	}else if(!IsClientInGame(client))
	{
		client = slice;
	}
	
	/////////////////////////
	//Regenerate Our sound //
	/////////////////////////
	if(soundEmission < GetTime())
	{
		StopSound(slice, SNDCHAN_AUTO, SOUND_SLICE);
		CreateTimer(0.0, Timer_Slice_Sound, slice);
		
		SetPackPosition(dataPackHandle, 16);
		WritePackCell(dataPackHandle, GetTime() + 20);//PackPosition(16)  --next sound emission
	}
	
	GetEntPropVector(slice, Prop_Data, "m_vecAbsOrigin", slicePos);
	
	///////////////////////////
	//Find nearby players    //
	///////////////////////////
	new sliceTeam = GetEntProp(slice, Prop_Data, "m_iTeamNum");
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if(sliceTeam == GetClientTeam(i))
			continue;
		
		cond = GetEntData(i, m_nPlayerCond);
		if(cond == 32 || cond == 327712)
			continue;
		
		GetClientAbsOrigin(i,playerPos);
		distance = GetVectorDistance( playerPos, slicePos);
		
		if(distance < 90.0)
		{
			if(lastHurtSound< GetTime())
			{
				SetPackPosition(dataPackHandle, 24);
				WritePackCell(dataPackHandle, GetTime() + 1);//PackPosition(24)  --last hurt sound
				EmitSoundToAll(SOUND_SAW_HIT, i);
				
				AttachTempParticle(slice,"env_sawblood", 1.0, false,"",0.0, false);
				AttachTempParticle(slice,"blood_trail_red_01_goop", 1.0, false,"",0.0, false);
				
			}
			
			DealDamage(i,30 ,client,65536,"killed_by_saw");
			knockback(i, slice, 600.0, 200.0);
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_Slice_Sound(Handle:Timer, any:slice)
{
	EmitSoundToAll(SOUND_SLICE, slice);
}

public stopSliceTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new slice = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new liveTime = ReadPackCell(dataPackHandle);
	
	if(slice < 1)
		return true;
	
	if(!IsValidEntity(slice))
		return true;
	
	if(GetTime() > liveTime)
	{
		StopSound(slice, SNDCHAN_AUTO, SOUND_SLICE);
		killEntityIn(slice, 0.1);
		return true;
	}
	
	if(roundEnded)
	{
		StopSound(slice, SNDCHAN_AUTO, SOUND_SLICE);
		killEntityIn(slice, 0.1);
		return true;
	}
	
	return false;
}