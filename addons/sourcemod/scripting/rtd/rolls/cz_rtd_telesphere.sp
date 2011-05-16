#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>

public Action:RemTeleSphere(client)
{
	new testTeleporter = -1;
	while ((testTeleporter = FindEntityByClassname(testTeleporter, "prop_dynamic")) != -1)
	{
		if (IsValidEdict(testTeleporter))
		{
			decl String:modelname[64];
			GetEntPropString(testTeleporter, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
			if (StrEqual(modelname, MODEL_TELESPHERE))
			{
				StopTeleSphere(testTeleporter);
			}
		}
	}
	ReplyToCommand(client, "[CarlTELESPHERE] Removed all TeleSpheres!");
	return Plugin_Handled;
}

public Action:AddTeleSphere(client)
{
	decl Float:tempplayerorigin[3];
	GetClientEyePosition(client, tempplayerorigin);
	if (!IsModelPrecached(MODEL_TELESPHERE))
	{
   		if(!PrecacheModel(MODEL_TELESPHERE))
   		{
   			PrintToChat(client, "[CarlTELESPHERE] Model is NOT CACHED and can NOT BE CACHED.");
			return Plugin_Handled;
   		}
 	}
	new TeleSphereEnt = CreateEntityByName("prop_dynamic");
	if (TeleSphereEnt == -1)
	{
		PrintToChat(client, "[CarlTELESPHERE] ERR: COULD NOT GENERATE MODEL");
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
	}
	else
	{
		SetVariantString("0+0+255");
		AcceptEntityInput(TeleSphereEnt, "color", -1, -1, 0);
	}
	TeleportEntity(TeleSphereEnt, tempplayerorigin, NULL_VECTOR, NULL_VECTOR);
	EmitSoundToAll(SOUND_TELEAMB, TeleSphereEnt, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
	CreateTimer(0.1, UpdateTeleSpheres, TeleSphereEnt, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	SetEntProp(TeleSphereEnt, Prop_Data, "m_iHammerID", TeleSphereMaxTime);
	return Plugin_Handled;
}

public Action:KillTeleSphere(Handle:timer, any:TeleSphereNum)
{
	if (IsValidEntity(TeleSphereNum))
	{
		StopTeleSphere(TeleSphereNum);
	}
}

public Action:UpdateTeleSpheres(Handle:timer, any:TeleSphereNum)
{
	if(!IsValidEntity(TeleSphereNum))
	{
		return Plugin_Stop;
	}
	new String:modelname[64];
	GetEntPropString(TeleSphereNum, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
	if (!StrEqual(modelname, MODEL_TELESPHERE))
	{
		return Plugin_Stop;
	}
	decl Float:tempClientOrigin[3];
	decl Float:TeleSphereOrigin[3];
	new TeleSphereTeam = GetEntProp(TeleSphereNum, Prop_Data, "m_iTeamNum");
	GetEntPropVector(TeleSphereNum, Prop_Send, "m_vecOrigin", TeleSphereOrigin);
	new TeleSphereTimeLeft = GetEntProp(TeleSphereNum, Prop_Data, "m_iHammerID");
	new TeleSphereMinLeft = TeleSphereTimeLeft/600;
	new TeleSphereSecLeft = (TeleSphereTimeLeft-(TeleSphereMinLeft*600))/10;
	
	if (!IsModelPrecached(SPRITE_TELEGLOW))
	{
		TeleGlowIndex = PrecacheModel(SPRITE_TELEGLOW);
   		if(!TeleGlowIndex)
   		{
   			PrintToChatAll("[CarlTELESPHERE] Sprite Model is NOT CACHED and CAN NOT be cached.");
   		}
 	}
	if (TeleGlowIndex)
	{
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
	}
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i))
		{
			decl Float:tempClientAbs[3];
			GetClientAbsOrigin(i, tempClientAbs);
			GetClientEyePosition(i, tempClientOrigin);
			new TFClassType:class = TF2_GetPlayerClass(i);
			new Float:TeleSphereDist = GetVectorDistance(TeleSphereOrigin, tempClientOrigin, false);
			new Float:tempTestSmallDist = GetVectorDistance(TeleSphereOrigin, tempClientAbs, false);
			if (tempTestSmallDist < TeleSphereDist)
			{
				TeleSphereDist = tempTestSmallDist;
			}
			new RealTeam = GetClientTeam(i);
			new SpyTeam = RealTeam;
			if (class == TFClass_Spy)
			{
				new DisguiseOffset = FindSendPropInfo("CTFPlayer", "m_nDisguiseTeam");
				SpyTeam = GetEntData(i, DisguiseOffset);
				if (!SpyTeam)
				{
					SpyTeam = RealTeam;
				}
			}

			if (IsPlayerAlive(i))
			{
				if (TeleSphereDist < 250.0)
				{
					if (TeleSphereTeam != RealTeam)
					{
						if (RealTeam == SpyTeam || (GetEntProp(i, Prop_Send, "m_nPlayerCond")&16))
						{
							if (TeleSphereDist < 80.0 && WillTeleSphere[i] == 0 && !(GetEntProp(i, Prop_Send, "m_nPlayerCond")&16) && !(GetEntProp(i, Prop_Send, "m_nPlayerCond")&32))
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
								}
								else
								{
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
						else
						{
							if (TeleSphereDist < 40.0)
							{
								decl String:weaponname[32];
								GetClientWeapon(i, weaponname, sizeof(weaponname));
								if (StrEqual(weaponname, "tf_weapon_builder"))
								{
									TeleSphereTimeLeft -= 5;
									SetHudTextParams(0.36, 0.82, 0.1, 255, 50, 50, 255);
									if (TeleSphereSecLeft > 9)
									{
										ShowHudText(i, HudMsg3, "Sapping Enemy TeleSphere! (%i:%i)", TeleSphereMinLeft, TeleSphereSecLeft);
									}
									else
									{
										ShowHudText(i, HudMsg3, "Sapping Enemy TeleSphere! (%i:0%i)", TeleSphereMinLeft, TeleSphereSecLeft);
									}
								}
								else
								{
									SetHudTextParams(0.32, 0.82, 0.1, 255, 50, 50, 255);
									ShowHudText(i, HudMsg3, "Pull Out Your Sapper To Sap The TeleSphere!");
								}
							}
							else
							{
								SetHudTextParams(0.42, 0.82, 0.1, 255, 50, 50, 255);
								ShowHudText(i, HudMsg3, "Tricked Enemy TeleSphere!");
							}
						}
					}
					else
					{
						SetHudTextParams(0.4, 0.82, 0.1, 255, 50, 50, 255);
						if (TeleSphereSecLeft > 9)
						{
							ShowHudText(i, HudMsg3, "Friendly TeleSphere. (%i:%i)", TeleSphereMinLeft, TeleSphereSecLeft);
						}
						else
						{
							ShowHudText(i, HudMsg3, "Friendly TeleSphere. (%i:0%i)", TeleSphereMinLeft, TeleSphereSecLeft);
						}
					}
				}
			}
		}
	}
	TeleSphereTimeLeft -= 1;
	SetEntProp(TeleSphereNum, Prop_Data, "m_iHammerID", TeleSphereTimeLeft);
	if (TeleSphereTimeLeft <= 0)
	{
		StopTeleSphere(TeleSphereNum);
		return Plugin_Stop;
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