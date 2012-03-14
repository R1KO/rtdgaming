#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <attachments>
#include <rtd_rollinfo>

stock GroundPlayer(client)
{	
	//mark when the player can be grounded again
	client_rolls[client][AWARD_G_GROUNDINGBULLET][1] = GetTime() + 10;
	SetEntityGravity(client, 99.0);
	
	//The Datapack stores all the Backpack's important values
	new Handle:dataPackHandle;
	CreateDataTimer(0.1, Ground_Timer, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	//Setup the datapack with appropriate information
	WritePackCell(dataPackHandle, EntIndexToEntRef(client));   //PackPosition(0);  Backpack Index
	WritePackCell(dataPackHandle, GetTime() + 5);     //PackPosition(8) ;  Amount of ammopacks
	
	PrintCenterText(client, "You've been grounded!");
}


public Action:Ground_Timer(Handle:timer, Handle:dataPackHandle)
{
	//////////////////////////////////////////
	//Retrieve the values from the dataPack //
	// Set to the beginning and unpack it   //
	//////////////////////////////////////////
	ResetPack(dataPackHandle);
	new client = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	new timeToKill = ReadPackCell(dataPackHandle);
	
	/////////////////////
	//Is client valid  //
	/////////////////////
	if(stopGroundingTimer(dataPackHandle))
	{
		return Plugin_Stop;
	}
	
	////////////////////////////////
	//Should we stop this timer?  //
	////////////////////////////////
	if(GetTime() > timeToKill)
	{
		SetEntityGravity(client, 1.0);
		return Plugin_Stop;
	}
	
	if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
	{
		SetEntityGravity(client, 1.0);
	}else{
		SetEntityGravity(client, 99.0);
	}
	
	return Plugin_Continue;
}

public stopGroundingTimer(Handle:dataPackHandle)
{	
	ResetPack(dataPackHandle);
	new client = EntRefToEntIndex(ReadPackCell(dataPackHandle));
	
	if(!IsClientInGame(client))
		return true;
	
	if(!IsPlayerAlive(client))
		return true;
	
	return false;
}