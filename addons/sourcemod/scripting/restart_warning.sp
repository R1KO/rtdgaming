#pragma semicolon 1

#include <sourcemod>
#include <regex>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Restart Warning",
	author = "Kilandor",
	description = "Specify time of server restarts and warn players.",
	version = PLUGIN_VERSION,
	url = "http://www.kilandor.com/"
};

new Handle:g_Cvar_AutoRestart;
new AutoTimeLeft = -1;
new ManualTimeLeft = -1;


public OnPluginStart()
{
	CreateConVar("sm_restartwarn_ver",PLUGIN_VERSION,"Kilandor's Restart Warning Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_Cvar_AutoRestart = CreateConVar("restartwarn_autorestart", "", "[HH:MM]Time when server restart happens(use 24hour scale)");
	
	HookConVarChange(g_Cvar_AutoRestart,			ConVarChange);
	
	//RegAdminCmd("sm_restart", Command_Restart, ADMFLAG_ROOT, "[minutes] - Restart Server in X minutes.");
	CreateTimer(1.0,Timer_Restart,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnConfigsExecuted()
{
	new String:AutoTime[6];
	GetConVarString(g_Cvar_AutoRestart, AutoTime, sizeof(AutoTime));
	BuildAutoTime(AutoTime);
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == g_Cvar_AutoRestart)
	{
		new String:AutoTime[6];
		GetConVarString(g_Cvar_AutoRestart, AutoTime, sizeof(AutoTime));
		BuildAutoTime(AutoTime);
	}
}

public Action:Timer_Restart(Handle:timer, any:client)
{
	if(ManualTimeLeft > 0)
	{
		ManualTimeLeft--;
	}
	if(AutoTimeLeft > 0)
	{
		AutoTimeLeft--;
		//This shows a warnign starting at 60 minutes, for every 15 minutes left, then 10/5/1
		if(AutoTimeLeft == 3600 || AutoTimeLeft == 2700 || AutoTimeLeft == 1800 || AutoTimeLeft == 900 || AutoTimeLeft == 600
		|| AutoTimeLeft == 300 || AutoTimeLeft == 240 || AutoTimeLeft == 180 || AutoTimeLeft == 120 || AutoTimeLeft == 60)
			ShowWarning(1);
		else if(AutoTimeLeft == 45 || AutoTimeLeft == 30 || AutoTimeLeft == 15) // This shows warning after 1min every 15 seconds
			ShowWarning(2);
		else if(AutoTimeLeft <= 10) //Shows a warning for the last 10 seconds;
			ShowWarning(2);
	}
}
/*
public Action:Command_Restart(client, args)
{
	
	decl String:strArgs[128];
	GetCmdArg(1, strArgs, sizeof(strArgs));
	new restartMinutes = StringToInt(strArgs);
	
	if(!ManualTimeLeft || AutoTimeLeft >= 300)
	{
		if(restartMinutes > 60)
			restartMinutes = 60;
		ManualTimeLeft = restartMinutes * 60;
		PrintToChatAll("\x04[\x03ServerRestart\x04]\x01 Server will be restarted in %d minutes.", restartMinutes);
	}
	return Plugin_Handled;
}
*/
BuildAutoTime(String:AutoTime[])
{
	if(!SimpleRegexMatch(AutoTime, "^([0-9]+):([0-9]+)$", PCRE_CASELESS))
	{
		LogError("Incorrect Format or Time Cvar is not set");
		return;
	}
	LogMessage("Auto Time %s", AutoTime);
	new String:AutoTemp[2][3];
	ExplodeString(AutoTime, ":", AutoTemp, 2, 3);
	new AutoHour = StringToInt(AutoTemp[0]);
	new AutoMin = StringToInt(AutoTemp[1]);
	if(AutoHour < 0 || AutoHour > 23)
	{
		LogError("Incorrect Hour, range should be 0-23");
		return;
	}
	else if(AutoMin < 0 || AutoMin > 60)
	{
		LogError("Incorrect Minute, range should be 0-60");
		return;
	}
	new AutoTimestamp = (AutoHour * 3600) + (AutoMin * 60);
	
	
	new String:CurHour[3], String:CurMin[3], String:CurSec[3];
	FormatTime(CurHour, sizeof(CurHour), "%H", GetTime());
	FormatTime(CurMin, sizeof(CurMin), "%M", GetTime());
	FormatTime(CurSec, sizeof(CurSec), "%S", GetTime());
	
	new CurTimestamp = (StringToInt(CurHour) * 3600) + (StringToInt(CurMin) * 60) + StringToInt(CurSec);
	
	LogMessage("\n\nCurStamp %d \nAutoStamp %d\n", CurTimestamp, AutoTimestamp);
	
	if(CurTimestamp > AutoTimestamp)
		AutoTimeLeft = CurTimestamp - AutoTimestamp;
	if(CurTimestamp < AutoTimestamp)
		AutoTimeLeft = AutoTimestamp - CurTimestamp;
	LogMessage("\n\nTimeLeft %d\n",AutoTimeLeft);
}

/*
Shows the warning to the server
  Type
  1 Minutes
  2 Seconds
 */
ShowWarning(type)
{
	switch(type)
	{
		case 1:
		{
			new String:MinLeft[3];
			FormatTime(MinLeft, sizeof(MinLeft), "%M", AutoTimeLeft);
			LogMessage("Server will be restarted in %d minutes.", StringToInt(MinLeft));
			PrintToChatAll("\x04[\x03ServerRestart\x04]\x01 Server will be restarted in %d minutes.", StringToInt(MinLeft));
		}
		case 2:
		{
			new String:SecLeft[3];
			FormatTime(SecLeft, sizeof(SecLeft), "%S", AutoTimeLeft);
			LogMessage("Server will be restarted in %d seconds.", StringToInt(SecLeft));
			PrintToChatAll("\x04[\x03ServerRestart\x04]\x01 Server will be restarted in %d seconds.", StringToInt(SecLeft));
		}
	}
}
