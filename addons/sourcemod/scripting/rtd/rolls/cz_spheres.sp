//Last modified: 1/8/2010
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#pragma semicolon 1

/*
public Plugin:myinfo = 
{
	name = "Carl Attacking Sphere",
	author = "CarlZalph",
	description = "Creates attacking spheres for Admins. ",
	version = PL_VERSION,
	url = "http://www.gamekrib.com/"
}
*/

public Action:AddSphere(client)
{
	decl Float:tempplayerorigin[3];
	GetClientEyePosition(client, tempplayerorigin);
	if (!IsModelPrecached(MODEL_SPHERE))
	{
   		if(!PrecacheModel(MODEL_SPHERE))
   		{
   			PrintToChat(client, "[CarlSPHERE] Model is NOT CACHED and can NOT BE CACHED.");
			return Plugin_Handled;
   		}
 	}
	decl String:TempSphere[64];
	new SphereEnt = CreateEntityByName("prop_sphere");
	if (SphereEnt == -1)
	{
		PrintToChat(client, "[CarlSPHERE] ERR: COULD NOT GENERATE MODEL");
		return Plugin_Handled;
	}
	SetEntityModel(SphereEnt, MODEL_SPHERE);
	SetEntProp(SphereEnt, Prop_Data, "m_takedamage", 2);
	Format(TempSphere, sizeof(TempSphere), "Sphere_%i", SphereEnt);
	DispatchKeyValue(SphereEnt, "targetname", TempSphere);
	DispatchSpawn(SphereEnt);
	SetEntProp(SphereEnt, Prop_Data, "m_takedamage", 2);
	DispatchKeyValue(SphereEnt, "solid", "4");
	SetEntProp(SphereEnt, Prop_Data, "m_iMaxHealth", 350);
	SetEntProp(SphereEnt, Prop_Data, "m_iHealth", 350);
	SetEntProp(SphereEnt, Prop_Data, "m_PerformanceMode", 1);
	HookSingleEntityOutput(SphereEnt, "OnTakeDamage", SphereDamaged, false);
	new OwnerTeam = GetClientTeam(client);
	SetEntProp(SphereEnt, Prop_Data, "m_iTeamNum", OwnerTeam);
	if (OwnerTeam == 2)
	{
		SetVariantString("255+0+0");
		AcceptEntityInput(SphereEnt, "color", -1, -1, 0);
		SetVariantString(bluDamageFilter);
		AcceptEntityInput(SphereEnt, "SetDamageFilter", -1, -1, 0);
	}
	else
	{
		SetVariantString("0+0+255");
		AcceptEntityInput(SphereEnt, "color", -1, -1, 0);
		SetVariantString(redDamageFilter);
		AcceptEntityInput(SphereEnt, "SetDamageFilter", -1, -1, 0);
	}
	SetEntPropEnt(SphereEnt, Prop_Data, "m_hOwnerEntity", client);
	
	TeleportEntity(SphereEnt, tempplayerorigin, NULL_VECTOR, NULL_VECTOR);
	CreateTimer(0.1, UpdateSpheres, SphereEnt, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}

public SphereDamaged(const String:output[], caller, activator, Float:delay)
{
	if(IsValidEntity(caller))
	{
		if(GetEntProp(caller, Prop_Data, "m_iHealth") <= 0)
		{
			if(activator <= MaxClients && activator > 0)
			{
				//Let's reward the player for killing a spider
				new rndNum = GetRandomInt(0,20);
				if(rndNum > 10)
				{
					TF_SpawnMedipack(caller, "item_healthkit_medium", true);
				}else{
					TF_SpawnMedipack(caller, "item_ammopack_medium", true);
				}
				
				//Give Nightmare mode Spider Kill points
				EmitSoundToClient(activator,SOUND_NULL,activator,_,_,_,0.4);
			}
			
			SetVariantString("explosion");
			AcceptEntityInput(caller, "dispatcheffect", -1, -1, 0);
		}
	}
}

public Action:SphereSoundRdy(Handle:timer, any:SphereNum)
{
	if (IsValidEdict(SphereNum))
	{
		
		decl String:modelname[64];
		GetEntPropString(SphereNum, Prop_Data, "m_ModelName", modelname, 64);
		if (StrEqual(modelname, MODEL_SPHERE) || StrEqual(modelname, MODEL_SPIDER) ||
			StrEqual(modelname, MODEL_ZOMBIE_CLASSIC) || StrEqual(modelname, MODEL_ZOMBIE_02) ||
			StrEqual(modelname, MODEL_ZOMBIE_03))
		{
			//PrintToChatAll("Sounds, valid model! Found model: %s",modelname);
		}else{
			//PrintToChatAll("Stopping Sounds invalid model! Found model: %s",modelname);
			return Plugin_Stop;
		}
		
		SetEntProp(SphereNum, Prop_Data, "m_PerformanceMode", 1);
	}
	
	return Plugin_Stop;
}

public Action:UpdateSpheres(Handle:timer, any:SphereNum)
{
	if(!IsValidEntity(SphereNum))
	{
		return Plugin_Stop;
	}
	new String:modelname[128];
	GetEntPropString(SphereNum, Prop_Data, "m_ModelName", modelname, 128);
	if (!StrEqual(modelname, MODEL_SPHERE))
	{
		return Plugin_Stop;
	}
	if(GetEntProp(SphereNum, Prop_Data, "m_iHealth") <= 0)
	{
		return Plugin_Stop;
	}
	new Float:DamageRange;
	new TargetType;
	new HasTarget;
	decl SpyTeam;
	decl tempTargetTeam;
	new Float:SmallestDist = 9001.0;
	decl Float:tempTargetOrig[3];
	decl Float:tempTargetEyes[3];
	decl Float:SphereOrigin[3];
	decl Float:tempDist;
	new SphereTeam = GetEntProp(SphereNum, Prop_Data, "m_iTeamNum");
	new SphereSndRdy = GetEntProp(SphereNum, Prop_Data, "m_PerformanceMode", 1);
	GetEntPropVector(SphereNum, Prop_Send, "m_vecOrigin", SphereOrigin);
	new Float:MaxWHNoAng[3];
	MaxWHNoAng[0] = -90.0;
	decl Float:tempVHigh[3];
	new Handle:trace = TR_TraceRayFilterEx(SphereOrigin, MaxWHNoAng, MASK_SOLID, RayType_Infinite, TraceFilterAll, SphereNum);
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(tempVHigh, trace);
	}
	else
	{
		tempVHigh = SphereOrigin;
	}
	CloseHandle(trace);
	MaxWHNoAng[0] = 90.0;
	decl Float:tempVLow[3];
	trace = TR_TraceRayFilterEx(tempVHigh, MaxWHNoAng, MASK_SOLID, RayType_Infinite, TraceFilterAll, SphereNum);
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(tempVLow, trace);
	}
	else
	{
		tempVLow = SphereOrigin;
	}
	CloseHandle(trace);
	SubtractVectors(tempVHigh, SphereOrigin, tempVHigh);
	SubtractVectors(SphereOrigin, tempVLow, tempVLow);
	AddVectors(tempVHigh, tempVLow, tempVLow);
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i))
		{
			GetClientAbsOrigin(i, tempTargetOrig);
			GetClientEyePosition(i, tempTargetEyes);
			new TFClassType:class = TF2_GetPlayerClass(i);
			decl Float:tempRealOrig[3];
			tempRealOrig = tempTargetOrig;
			new Float:RealDist = GetVectorDistance(SphereOrigin, tempRealOrig, false);
			new Float:tempEyeDist = GetVectorDistance(SphereOrigin, tempTargetEyes, false);
			tempTargetOrig[2] = SphereOrigin[2];
			tempDist = GetVectorDistance(tempTargetOrig, SphereOrigin, false);
			SpyTeam = GetClientTeam(i);
			tempTargetTeam = SpyTeam;
			if (class == TFClass_Spy)
			{
				new DisguiseOffset = FindSendPropInfo("CTFPlayer", "m_nDisguiseTeam");
				SpyTeam = GetEntData(i, DisguiseOffset);
				if (!SpyTeam)
				{
					SpyTeam = tempTargetTeam;
				}
			}
			if (SphereTeam != SpyTeam)
			{
				if (IsPlayerAlive(i))
				{
					new CanSee;
					decl Float:TempLoc[3];
					decl Float:CanSeeDist;
					decl Float:SphereOriginNVert[3];
					SphereOriginNVert = SphereOrigin;
					SphereOriginNVert[2] +=tempVHigh[2];
					trace = TR_TraceRayFilterEx(SphereOrigin, tempTargetOrig, MASK_SOLID, RayType_EndPoint, TraceFilterAll, SphereNum);
					if(!TR_DidHit(trace))
					{
						TR_GetEndPosition(TempLoc, trace);
						CanSeeDist = GetVectorDistance(SphereOrigin, TempLoc);
						if (tempDist == CanSeeDist)
						{
							CanSee = 1;
						}
					}
					CloseHandle(trace);
					trace = TR_TraceRayFilterEx(SphereOriginNVert, tempTargetOrig, MASK_SOLID, RayType_EndPoint, TraceFilterAll, SphereNum);
					if(!TR_DidHit(trace))
					{
						TR_GetEndPosition(TempLoc, trace);
						CanSeeDist = GetVectorDistance(SphereOrigin, TempLoc);
						if (tempDist == CanSeeDist)
						{
							CanSee = 1;
						}
					}
					CloseHandle(trace);
					trace = TR_TraceRayFilterEx(SphereOrigin, tempTargetEyes, MASK_SOLID, RayType_EndPoint, TraceFilterAll, SphereNum);
					if(!TR_DidHit(trace))
					{
						TR_GetEndPosition(TempLoc, trace);
						CanSeeDist = GetVectorDistance(SphereOrigin, TempLoc);
						if (tempEyeDist == CanSeeDist)
						{
							CanSee = 1;
						}
					}
					CloseHandle(trace);
					trace = TR_TraceRayFilterEx(SphereOriginNVert, tempTargetEyes, MASK_SOLID, RayType_EndPoint, TraceFilterAll, SphereNum);
					if(!TR_DidHit(trace))
					{
						TR_GetEndPosition(TempLoc, trace);
						CanSeeDist = GetVectorDistance(SphereOrigin, TempLoc);
						if (tempEyeDist == CanSeeDist)
						{
							CanSee = 1;
						}
					}
					CloseHandle(trace);
					if (CanSee && tempDist < SmallestDist && !(GetEntProp(i, Prop_Send, "m_nPlayerCond")&16) && !(GetEntProp(i, Prop_Send, "m_nPlayerCond")&32))
					{
						HasTarget = i;
						SmallestDist = tempDist;
					}
				}
			}
			else
			{
				if (RealDist < 150.0)
				{
					new RollerFHP = GetEntProp(SphereNum, Prop_Data, "m_iHealth");
					new RollerFHPM = GetEntProp(SphereNum, Prop_Data, "m_iMaxHealth");
					if (class == TFClass_Engineer && RollerFHP < RollerFHPM && RealDist < 40.0)
					{
						decl String:weaponname[32];
						GetClientWeapon(i, weaponname, sizeof(weaponname));
						if (StrEqual(weaponname, "tf_weapon_wrench"))
						{
							if (RollerFHP+5 < RollerFHPM)
							{
								RollerFHP += 5;
							}
							else
							{
								RollerFHP = RollerFHPM;
							}
							SetEntProp(SphereNum, Prop_Data, "m_iHealth", RollerFHP);
							if (SphereSndRdy)
							{
								SetEntProp(SphereNum, Prop_Data, "m_PerformanceMode", 0);
								EmitSoundToAll(SSphere_Heal, SphereNum, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
								CreateTimer(1.0, SphereSoundRdy, SphereNum);
							}
						}
					}
				}
			}
		}
	}
	if (HasTarget && SmallestDist < 800.0)
	{
		tempTargetTeam = GetClientTeam(HasTarget);
		GetClientAbsOrigin(HasTarget, tempTargetOrig);
		TargetType = 1;
		DamageRange = 25.0;
	}
	else
	{
		HasTarget = 0;
		SmallestDist = 9001.0;
		new testSphere = -1;
		while ((testSphere = FindEntityByClassname(testSphere, "prop_sphere")) != -1)
		{
			if (testSphere != SphereNum)
			{
				GetEntPropString(testSphere, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
				if (StrEqual(modelname, MODEL_SPHERE))
				{
					new testSphereTeam = GetEntProp(testSphere, Prop_Data, "m_iTeamNum");
					if (SphereTeam != testSphereTeam)
					{
						new CanSee;
						decl Float:TempLoc[3];
						decl Float:CanSeeDist;
						GetEntPropVector(testSphere, Prop_Send, "m_vecOrigin", tempTargetOrig);
						tempTargetOrig[2] = SphereOrigin[2];
						tempDist = GetVectorDistance(tempTargetOrig, SphereOrigin, false);
						trace = TR_TraceRayFilterEx(SphereOrigin, tempTargetOrig, MASK_SOLID, RayType_EndPoint, TraceFilterAll, SphereNum);
						if(!TR_DidHit(trace))
						{
							TR_GetEndPosition(TempLoc, trace);
							CanSeeDist = GetVectorDistance(SphereOrigin, TempLoc);
							if (tempDist == CanSeeDist)
							{
								CanSee = 1;
							}
						}
						CloseHandle(trace);
						trace = TR_TraceRayFilterEx(SphereOrigin, tempTargetEyes, MASK_SOLID, RayType_EndPoint, TraceFilterAll, SphereNum);
						if(!TR_DidHit(trace))
						{
							TR_GetEndPosition(TempLoc, trace);
							CanSeeDist = GetVectorDistance(SphereOrigin, TempLoc);
							if (tempDist == CanSeeDist)
							{
								CanSee = 1;
							}
						}
						CloseHandle(trace);
						if (CanSee && tempDist < SmallestDist)
						{
							HasTarget = testSphere;
							SmallestDist = tempDist;
						}
					}
				}
			}
		}
		if (HasTarget && SmallestDist < 800.0)
		{
			tempTargetTeam = GetEntProp(HasTarget, Prop_Data, "m_iTeamNum");
			GetEntPropVector(HasTarget, Prop_Send, "m_vecOrigin", tempTargetOrig);
			TargetType = 2;
			DamageRange = 35.0;
		}
	}
	if (HasTarget && SmallestDist < 800.0)
	{
		SmallestDist = GetVectorDistance(SphereOrigin, tempTargetOrig, false);
		if (SmallestDist > 400.0 && SmallestDist < 600 && SphereSndRdy)
		{
			SetEntProp(SphereNum, Prop_Data, "m_PerformanceMode", 0);
			EmitSoundToAll(SSphere_Locked, SphereNum, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
			CreateTimer(2.2, SphereSoundRdy, SphereNum);
		}
		if (SmallestDist < DamageRange)
		{
			SetVariantString("manhacksparks");
			AcceptEntityInput(SphereNum, "dispatcheffect", -1, -1, 0);
			if (SphereTeam != tempTargetTeam)
			{
				switch(TargetType)
				{
					case 1:
					{
						new ownerEnt = GetEntPropEnt(SphereNum, Prop_Data, "m_hOwnerEntity");
						if(ownerEnt != -1)
						{
							DealDamage(HasTarget,3 ,ownerEnt,65536,"tf_weaponbase_melee");
						}else{
							DealDamage(HasTarget,3 ,SphereNum,65536,"tf_weaponbase_melee");
						}
						//dhTakeDamage(HasTarget,SphereNum,HasTarget,6.0,65536);
						//TakeDamageHook(HasTarget,SphereNum,HasTarget,6.0,65536);
					}
					case 2:
					{
						SetVariantFloat(-6.0);
						AcceptEntityInput(HasTarget,"AddHealth",SphereNum,SphereNum,0);
					}
				}
			}
			if (SphereSndRdy)
			{
				SetEntProp(SphereNum, Prop_Data, "m_PerformanceMode", 0);
				new Sphere_Attack_Sound = GetRandomInt(0,1);
				if (Sphere_Attack_Sound)
				{
					EmitSoundToAll(SSphere_AttackA, SphereNum, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
					CreateTimer(1.0, SphereSoundRdy, SphereNum);
				}
				else
				{
					EmitSoundToAll(SSphere_AttackB, SphereNum, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
					CreateTimer(1.0, SphereSoundRdy, SphereNum);
				}
			}
		}
		new Float:VertGain = -175.0;
		new InWater = GetEntProp(SphereNum, Prop_Data, "m_nWaterLevel");
		if (!InWater)
		{
			if ((SphereOrigin[2] - tempVLow[2]) < tempTargetOrig[2] && HasTarget <= MaxClients && SmallestDist > 30.0)
			{
				SphereOrigin[2] -= 10.0;
				decl Float:WallClimbVec[3];
				WallClimbVec = tempTargetOrig;
				WallClimbVec[2] = SphereOrigin[2];
				decl Float:tempVertClimb[3];
				GetVectorAngles(WallClimbVec, tempVertClimb);
				tempVertClimb[0] = 26.0 * Cosine(DegToRad(tempVertClimb[1]));
				tempVertClimb[1] = 26.0 * Sine(DegToRad(tempVertClimb[1]));
				AddVectors(tempVertClimb, WallClimbVec, WallClimbVec);
				WallClimbVec[2] = SphereOrigin[2];
				trace = TR_TraceRayFilterEx(SphereOrigin, WallClimbVec, MASK_SOLID, RayType_EndPoint, TraceFilterAll, SphereNum);
				if(TR_DidHit(trace))
				{
					decl Float:TempLoc[3];
					TR_GetEndPosition(TempLoc, trace);
					new Float:HorDist = GetVectorDistance(TempLoc, SphereOrigin);
					if (HorDist < 80.0)
					{
						VertGain = 175.0;
					}
				}
				CloseHandle(trace);
			}
		}
		else
		{
			if (SphereOrigin[2]-25.0 < tempTargetOrig[2])
			{
				VertGain = 175.0;
			}
		}
		SubtractVectors(tempTargetOrig, SphereOrigin, tempTargetOrig);
		GetVectorAngles(tempTargetOrig, SphereOrigin);
		SphereOrigin[0] = 285.0 * Cosine(DegToRad(SphereOrigin[1]));
		SphereOrigin[1] = 285.0 * Sine(DegToRad(SphereOrigin[1]));
		SphereOrigin[2] = VertGain;
		TeleportEntity(SphereNum, NULL_VECTOR, NULL_VECTOR, SphereOrigin);
	}
	return Plugin_Continue;
}

public bool:TraceFilterAll(caller, contentsMask, any:SphereNum)
{
	new String:modelname[128];
	GetEntPropString(caller, Prop_Data, "m_ModelName", modelname, 128);
	
	new String:checkclass[64];
	GetEdictClassname(caller,checkclass,sizeof(checkclass));
	
	return !(StrEqual(checkclass, "player", false) || StrEqual(checkclass, "func_respawnroomvisualizer", false) ||(caller==SphereNum) || StrEqual(modelname, MODEL_SPIDER) || StrEqual(modelname, MODEL_SPIDERBOX));
}

stock amountOfRollerMines(client)
{
	new foundMines;
	new rollerMineTeam;
	new clientTeam = GetClientTeam(client);
	
	new ent = -1;
	new String:modelname[128];
	
	while ((ent = FindEntityByClassname(ent, "prop_sphere")) != -1)
	{
		GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 128);
		
		if (StrEqual(modelname, MODEL_SPHERE))
		{
			rollerMineTeam = GetEntProp(ent, Prop_Data, "m_iTeamNum");
			
			if(rollerMineTeam == clientTeam)
				foundMines ++;
		}
	}
	
	return foundMines;
}