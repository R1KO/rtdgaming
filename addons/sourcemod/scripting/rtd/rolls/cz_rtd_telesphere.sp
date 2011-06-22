#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>

public Action:AddTeleSphere(client)
{
	decl Float:tempplayerorigin[3];
	GetClientEyePosition(client, tempplayerorigin);
	
	new TeleSphereEnt = CreateEntityByName("prop_dynamic");
	if (TeleSphereEnt == -1)
	{
		PrintToChat(client, "Error in creating prop_dynamic:telesphere");
		return Plugin_Handled;
	}
	
	SetEntityModel(TeleSphereEnt, MODEL_TELESPHERE);
	
	DispatchSpawn(TeleSphereEnt);
	DispatchKeyValue(TeleSphereEnt, "solid", "0");
	DispatchKeyValue(TeleSphereEnt, "rendermode", "1");
	
	SetVariantString("idle");
	AcceptEntityInput(TeleSphereEnt, "setanimation", -1, -1, 0);
	
	SetVariantInt(125);
	AcceptEntityInput(TeleSphereEnt, "alpha", -1, -1, 0);
	
	decl String:TeleSphereTarNam[64];
	Format(TeleSphereTarNam, sizeof(TeleSphereTarNam), "TeleSphere_%i", TeleSphereEnt);
	DispatchKeyValue(TeleSphereEnt, "targetname", TeleSphereTarNam);
	
	new OwnerTeam = GetClientTeam(client);
	SetEntProp(TeleSphereEnt, Prop_Data, "m_iTeamNum", OwnerTeam);
	if (OwnerTeam == 2)
	{
		SetVariantString("255+0+0");
		AcceptEntityInput(TeleSphereEnt, "color", -1, -1, 0);
	}else{
		SetVariantString("0+0+255");
		AcceptEntityInput(TeleSphereEnt, "color", -1, -1, 0);
	}
	
	TeleportEntity(TeleSphereEnt, tempplayerorigin, NULL_VECTOR, NULL_VECTOR);
	
	/////////////////////////////////////////////
	//Initiate the timer.                      //
	//Important variables to keep track of     //
	/////////////////////////////////////////////
	new Handle:dataPack;
	CreateDataTimer(0.1,UpdateTeleSpheres,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPack, EntIndexToEntRef(TeleSphereEnt));
	WritePackCell(dataPack, GetTime() + 120); //PackPosition(8) time to kill the telesphere
	WritePackCell(dataPack, GetTime() + 5);  //PackPosition(16)  time of next cycle
	WritePackCell(dataPack, 1); //PackPosition(32) Telesphere condition: 1 = on | 0 = off
	
	EmitSoundToAll(SOUND_TELEAMB, TeleSphereEnt);
	
	return Plugin_Handled;
}

public stopTeleSphereTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new telesphere = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	if(!IsValidEntity(telesphere))
		return true;
	
	//check to see if its time has expired
	new timeToKill = ReadPackCell(dataPackHandle);
	
	if(GetTime() > timeToKill)
		StopTeleSphere(telesphere);
	
	return false;
}

public Action:UpdateTeleSpheres(Handle:timer, Handle:dataPackHandle)
{
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(stopTeleSphereTimer(dataPackHandle))
		return Plugin_Stop;
	
	////////////////////////////////
	// Read the datapack values   //
	////////////////////////////////
	ResetPack(dataPackHandle);
	new telesphere = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new timeToKill = ReadPackCell(dataPackHandle);
	new nextTimeCycle = ReadPackCell(dataPackHandle);
	new telesphereCondition = ReadPackCell(dataPackHandle);
	
	//set the color
	new TeleSphereTeam = GetEntProp(telesphere, Prop_Data, "m_iTeamNum");
	new color[3];
	if(TeleSphereTeam == RED_TEAM)
	{
		color[0] = 255; color[1] = 0; color[2] = 0;
	}else{
		color[0] = 0; color[1] = 0; color[2] = 255;
	}
	
	/////////////////////////////////////
	// Determine telesphere condition  //
	// 0 = OFF                         //
	// 1 = ON                          //
	/////////////////////////////////////
	
	//Telesphere is currently off, exit out of here
	if(telesphereCondition == 0 && nextTimeCycle > GetTime())
	{
		return Plugin_Continue;
	}
	
	//Telesphere is on but it needs to be cycled OFF
	if(GetTime() > nextTimeCycle && telesphereCondition == 1)
	{
		StopSound(telesphere, SNDCHAN_AUTO, SOUND_TELEAMB);
		
		SetEntityRenderMode(telesphere, RENDER_TRANSCOLOR);
		SetEntityRenderColor(telesphere, 255, 255, 255, 125);
		
		// stay off for 3 seconds
		SetPackPosition(dataPackHandle, 16);
		WritePackCell(dataPackHandle, GetTime() + 3);
		
		// mark the telesphere as OFF
		WritePackCell(dataPackHandle, 0); 
		
		return Plugin_Continue;
	}
	
	//Telesphere needs to be cyled on
	if(telesphereCondition == 0)
	{
		EmitSoundToAll(SOUND_TELEAMB, telesphere);
		
		SetEntityRenderMode(telesphere, RENDER_TRANSCOLOR);
		SetEntityRenderColor(telesphere, color[0], color[1], color[2], 125);
		
		// stay ON for 6 seconds
		SetPackPosition(dataPackHandle, 16);
		WritePackCell(dataPackHandle, GetTime() + 6);
		
		// mark the telesphere as OFF
		WritePackCell(dataPackHandle, 1); 
	}
	
	
	decl Float:tempClientOrigin[3];
	decl Float:TeleSphereOrigin[3];
	GetEntPropVector(telesphere, Prop_Send, "m_vecOrigin", TeleSphereOrigin);
	
	//Determine minutes and seconds left
	new totalSecondsLeft = timeToKill - GetTime();
	new totalMinutesLeft = totalSecondsLeft/60;
	new secondsSplitLeft = totalSecondsLeft - (totalMinutesLeft*60);
	
	
	//snazzy particles
	for (new j=0;j<2;j++)
	{
		decl Float:tempParticleOrigin[3];
		new Float:RandH = GetRandomFloat(-1.0, 1.0);
		new Float:RandD = DegToRad(GetRandomFloat(0.0, 360.0));
		new Float:RandP = SquareRoot(1.0-(RandH*RandH));
		tempParticleOrigin[0] = Cosine(RandD)*RandP;
		tempParticleOrigin[1] = Sine(RandD)*RandP;
		tempParticleOrigin[2] = RandH;
		ScaleVector(tempParticleOrigin, GetRandomFloat(10.0, 60.0));
		AddVectors(TeleSphereOrigin, tempParticleOrigin, tempParticleOrigin);
		TE_SetupGlowSprite(tempParticleOrigin,TeleGlowIndex,0.5,0.3,255);
		TE_SendToAll();
	}
	
	///////////////////////////////////////
	// Finally, check to see if a player //
	// is near a telesphere              //
	///////////////////////////////////////
	
	new Float:tempClientAbs[3];
	new Float:TeleSphereDist;
	new Float:tempTestSmallDist;
	
	new realTeam;
	new alpha;
	
	new playerConditionBits;
	
	for (new i=1;i<=MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		if(!IsPlayerAlive(i))
			continue;
		
		playerConditionBits = TF2_GetPlayerConditionFlags(i);
		
		//bypass ubers and cloaked
		if(playerConditionBits & TF_CONDFLAG_UBERCHARGED || playerConditionBits & TF_CONDFLAG_CLOAKED || playerConditionBits & TF_CONDFLAG_DISGUISED)
			continue;
		
		//bypass invisble players
		alpha = GetEntData(i, m_clrRender + 3, 1);
		if(alpha == 0)
			continue;
		
		//Determine distances
		GetClientAbsOrigin(i, tempClientAbs);
		GetClientEyePosition(i, tempClientOrigin);
		
		TeleSphereDist = GetVectorDistance(TeleSphereOrigin, tempClientOrigin, false);
		tempTestSmallDist = GetVectorDistance(TeleSphereOrigin, tempClientAbs, false);
		
		if (tempTestSmallDist < TeleSphereDist)
			TeleSphereDist = tempTestSmallDist;
		
		if(TeleSphereDist > 250.0)
			continue;
		
		//Set team variables
		realTeam = GetClientTeam(i);
		
		//show message to players on same team
		if(TeleSphereTeam == realTeam)
		{
			SetHudTextParams(0.4, 0.82, 0.1, 255, 50, 50, 255);
			if (secondsSplitLeft > 9)
			{
				ShowHudText(i, HudMsg3, "Friendly TeleSphere. (%i:%i)", totalMinutesLeft, secondsSplitLeft);
			}else{
				ShowHudText(i, HudMsg3, "Friendly TeleSphere. (%i:0%i)", totalMinutesLeft, secondsSplitLeft);
			}
			continue;
		}
		
		//enemy is too close to telesphere
		if (TeleSphereDist < 80.0 && WillTeleSphere[i] == 0)
		{
			new Handle:message = StartMessageOne("Fade", i, 1);
			BfWriteShort(message, 585);
			BfWriteShort(message, 585);
			BfWriteShort(message, (0x0002));
			if (TeleSphereTeam == 2)
			{
				BfWriteByte(message, 175);
				BfWriteByte(message, 0);
				BfWriteByte(message, 0);
			}else{
				BfWriteByte(message, 0);
				BfWriteByte(message, 0);
				BfWriteByte(message, 175);
			}
			BfWriteByte(message, 255);
			EndMessage();
			
			WillTeleSphere[i] = 1;
			EmitSoundToAll(SOUND_TELEPRE, i, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
			CreateTimer(2.1, TeleSphereRand, i);
		}
		
		SetHudTextParams(0.45, 0.82, 0.1, 255, 50, 50, 255);
		ShowHudText(i, HudMsg3, "Enemy TeleSphere.");
	}
	
	return Plugin_Continue;
}

public Action:TeleSphereRand(Handle:timer, any:client)
{
	WillTeleSphere[client] = 0;
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{	
			EmitSoundToAll(SOUND_TELEPOST, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
			decl Float:ClientOrigin[3];
			GetClientAbsOrigin(client, ClientOrigin);
			decl Float:TargetOrigin[3];
			new Float:GreatestDist = 0.0;
			new CTeam = GetClientTeam(client);
			new HasTarget;
			new AFlagOffset = FindSendPropOffs("CBasePlayer", "m_fFlags");
			new CFlags = GetEntData(client, AFlagOffset);
			new CDuck = (CFlags & FL_DUCKING);
			for(new i=1;i<=MaxClients;i++)
			{
				if (IsClientInGame(i) && client != i)
				{
					new TTeam = GetClientTeam(i);
					if (IsPlayerAlive(i) && TTeam == CTeam)
					{
						new TFlags = GetEntData(i, AFlagOffset);
						new TDuck = (TFlags & FL_DUCKING);
						if (!TDuck || (TDuck && CDuck))
						{
							GetClientAbsOrigin(i, TargetOrigin);
							TargetOrigin[2] = ClientOrigin[2];
							new Float:tempDist = GetVectorDistance(ClientOrigin, TargetOrigin, false);
							if (tempDist > GreatestDist)
							{
								GreatestDist = tempDist;
								HasTarget = i;
							}
						}
					}
				}
			}
			if (HasTarget)
			{
				GetClientAbsOrigin(HasTarget, TargetOrigin);
				TeleportEntity(client, TargetOrigin, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
}

stock StopTeleSphere(any:TeleSphereNum)
{
	StopSound(TeleSphereNum, SNDCHAN_AUTO, SOUND_TELEAMB);
	EmitSoundToAll(SOUND_TELEDIE, TeleSphereNum, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
	SetVariantString("explosion");
	AcceptEntityInput(TeleSphereNum, "dispatcheffect", -1, -1, 0);
	AcceptEntityInput(TeleSphereNum, "break", -1, -1, 0);
}