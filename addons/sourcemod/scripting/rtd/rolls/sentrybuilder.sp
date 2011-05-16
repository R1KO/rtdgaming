#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <rtd_rollinfo>

BuildSentry(iBuilder, m_bMiniBuilding, sentryLevel, lifeTime)							//Not my code, credit goes to The JCS and Muridas
{
	new Float:fOrigin[3];
	new Float:fAngle[3];
	GetClientAbsOrigin(iBuilder, fOrigin);
	GetClientAbsAngles(iBuilder, fAngle); 
	
	fAngle[0] = 0.0;
	fAngle[2] = 0.0;
	
	new Float:fBuildMaxs[3] = {24.0, 24.0, 66.0};
	new iTeam = GetClientTeam(iBuilder);
	new iShells, iHealth, iRockets;
	new Float:timerLength;
	//Mini Sentry Stats
	
	new Float:fMdlWidth[3];
	fMdlWidth[0] = 1.0;
	fMdlWidth[1] = 0.5;
	fMdlWidth[2] = 0.0;
	
	new iSentry = CreateEntityByName("obj_sentrygun");
	
	
	DispatchSpawn(iSentry);
	ActivateEntity(iSentry); 
	TeleportEntity(iSentry, fOrigin, fAngle, NULL_VECTOR);
	
	
	SetEntityRenderMode(iSentry, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iSentry, 255, 255, 255, 0);
	
	switch(sentryLevel)
	{
		case 1:
		{
			iShells = 100;
			iHealth = 150;
			iRockets = 20; // Eh it has the value so why not
			SetEntityModel(iSentry, "models/buildables/sentry1.mdl");
		}
		case 2:
		{
			iShells = 120;
			iHealth = 180;
			iRockets = 20; // Eh it has the value so why not
			SetEntityModel(iSentry, "models/buildables/sentry2.mdl");
			timerLength = 2.0;
		}
		case 3:
		{
			iShells = 144;
			iHealth = 216;
			iRockets = 20; // Eh it has the value so why not
			SetEntityModel(iSentry, "models/buildables/sentry3.mdl");
			timerLength = 2.0;
		}
	}
	

	SetEntProp(iSentry, Prop_Data, "m_CollisionGroup", 5); //players can walk through sentry so they dont get stuck

	SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_flAnimTime"),                 51, 4 , true);
	SetEntProp(iSentry, Prop_Send, "m_bMiniBuilding",					m_bMiniBuilding);
	SetEntProp(iSentry, Prop_Send, "m_iMaxHealth",					iHealth);
	SetEntProp(iSentry, Prop_Send, "m_iHealth",						iHealth);
	SetEntProp(iSentry, Prop_Send, "m_bDisabled",						1);
	SetEntProp(iSentry, Prop_Send, "m_iObjectType",					2);
	SetEntProp(iSentry, Prop_Send, "m_iUpgradeLevel",					sentryLevel);
	SetEntProp(iSentry, Prop_Send, "m_iAmmoRockets",					iRockets);
	SetEntProp(iSentry, Prop_Send, "m_iAmmoShells",					iShells);
	
	if(m_bMiniBuilding)
	{
		SetEntProp(iSentry, Prop_Send, "m_nSkin",							iTeam);
	}else{
		SetEntProp(iSentry, Prop_Send, "m_nSkin",							iTeam - 2);
	}
	SetEntProp(iSentry, Prop_Send, "m_iObjectMode",					0);
	SetEntProp(iSentry, Prop_Send, "m_iUpgradeMetal",					0);
	SetEntProp(iSentry, Prop_Send, "m_bBuilding",						0);
	SetEntProp(iSentry, Prop_Send, "m_bPlacing",						0);
	SetEntProp(iSentry, Prop_Send, "m_iState",						1);
	SetEntProp(iSentry, Prop_Send, "m_bHasSapper",					0);
	
	SetEntProp(iSentry, Prop_Send, "m_nNewSequenceParity",			3+sentryLevel);
	SetEntProp(iSentry, Prop_Send, "m_nResetEventsParity",			3+sentryLevel);
	SetEntProp(iSentry, Prop_Send, "m_bServerOverridePlacement",		0);
	SetEntProp(iSentry, Prop_Send, "m_nSequence",						0);

	SetEntPropEnt(iSentry, Prop_Send, "m_hBuilder",					iBuilder);
	SetEntPropFloat(iSentry, Prop_Send, "m_flCycle",					0.0);
	SetEntPropFloat(iSentry, Prop_Send, "m_flPlaybackRate",			1.0);
	SetEntPropFloat(iSentry, Prop_Send, "m_flPercentageConstructed",	1.0);
	//SetEntPropFloat(iSentry, Prop_Send, "m_flModelWidthScale",		1.0);
	
	//fOrigin[2] + 10.0;
	//SetEntPropVector(iSentry, Prop_Send, "m_vecOrigin",				fOrigin);
	//SetEntPropVector(iSentry, Prop_Send, "m_angRotation",			fAngle);
	//SetEntPropVector(iSentry, Prop_Send, "m_vecBuildMaxs",			fBuildMaxs);
	//SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_vecOrigin"),             fOrigin, true);
	//SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_angRotation"),         fAngle, true);
	SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_vecBuildMaxs"),         fBuildMaxs, true);
	SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_flModelWidthScale"),     fMdlWidth, true);
	
	new Float:minbounds[3] = {-70.0, -70.0, -70.0}; 
	new Float:maxbounds[3] = {70.0, 70.0, 70.0}; 
	SetEntPropVector(iSentry, Prop_Send, "m_vecMins", minbounds); 
	SetEntPropVector(iSentry, Prop_Send, "m_vecMaxs", maxbounds); 
	
	
	//GetClientAbsOrigin(iBuilder, fOrigin);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(iSentry, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(iSentry, "SetTeam", -1, -1, 0); 
	
	new String:addoutput[64];
	Format(addoutput, sizeof(addoutput), "OnUser1 !self:RemoveHealth:2000:%i:1",lifeTime);
	SetVariantString(addoutput);
	
	AcceptEntityInput(iSentry, "AddOutput");
	AcceptEntityInput(iSentry, "FireUser1");
	
	new Handle:dataPackHandle;
	CreateDataTimer(timerLength, Timer_FakeBuild, dataPackHandle, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(iSentry));
	
	new sentry = CreateEntityByName("prop_dynamic_override");
	
	switch(sentryLevel)
	{
		case 1:
		{
			SetEntityModel(sentry, "models/buildables/sentry1_heavy.mdl");
		}
		case 2:
		{
			SetEntityModel(sentry, "models/buildables/sentry2_heavy.mdl");
		}
		case 3:
		{
			SetEntityModel(sentry, "models/buildables/sentry3_heavy.mdl");
		}
	}
	
	DispatchSpawn(sentry);
	TeleportEntity(sentry, fOrigin, fAngle, NULL_VECTOR);
	
	if(m_bMiniBuilding)
	{
		SetVariantInt(iTeam);
	}else{
		SetVariantInt(iTeam-2);
	}
	AcceptEntityInput(sentry, "skin", -1, -1, 0);
	
	switch(sentryLevel)
	{
		case 1:
		{
			SetVariantString("build");
		}
		case 2:
		{
			SetVariantString("upgrade");
		}
		case 3:
		{
			SetVariantString("upgrade");
		}
	}
	
	AcceptEntityInput(sentry, "SetAnimation", -1, -1, 0); 
	
	Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::%i:1",RoundFloat(timerLength));
	SetVariantString(addoutput);
	AcceptEntityInput(sentry, "AddOutput");
	AcceptEntityInput(sentry, "FireUser1");
}

public Action:Timer_FakeBuild(Handle:Timer, any:dataPackHandle)
{
	ResetPack(dataPackHandle);
	new iSentry = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	if(!IsValidEntity(iSentry))
		return Plugin_Stop;
	
	SetEntProp(iSentry, Prop_Send, "m_bDisabled",						0);
	SetEntityRenderMode(iSentry, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iSentry, 255, 255, 255, 255);
	
	return Plugin_Stop;
}