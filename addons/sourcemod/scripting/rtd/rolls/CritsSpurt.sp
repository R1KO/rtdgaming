#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <rtd_rollinfo>

public Action:Activate_CritsSpurt(client)
{	
	new Handle:dataPack;
	CreateDataTimer(1.0,CritsSpurt_Timer,dataPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dataPack, client); //PackPosition(0) 
	WritePackCell(dataPack, 9);		//PackPosition(8), intitial value
	WritePackCell(dataPack, 10);	//PackPosition(16), start time to allow crits
	WritePackCell(dataPack, 13);	//PackPosition(24), end time to end crits
	WritePackFloat(dataPack, 3.0); //amoutn of time to give crits
	return Plugin_Handled;
}

public Action:CritsSpurt_Timer(Handle:timer, Handle:dataPack)
{	
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPack);
	new client 			= ReadPackCell(dataPack);
	new currentInterval	= ReadPackCell(dataPack);
	new startTime 		= ReadPackCell(dataPack);
	new endTime 		= ReadPackCell(dataPack);
	new Float:totTime	= ReadPackFloat(dataPack);
	
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(!client_rolls[client][AWARD_G_CRITSSPURT][0])
		return Plugin_Stop;
	
	currentInterval ++;
	
	//Give the player Crits
	if(currentInterval == startTime)
		TF2_AddCondition(client,TFCond_Kritzkrieged,totTime);
	
	if(currentInterval >= endTime)
		currentInterval = 0;
	
	SetPackPosition(dataPack, 8);
	WritePackCell(dataPack, currentInterval);
	return Plugin_Continue;
}