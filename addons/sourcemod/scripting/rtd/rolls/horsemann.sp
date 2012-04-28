#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <attachments>
#include <rtd_rollinfo>

public GiveHorsemann(client)
{	
	ServerCommand("sm_bethehorsemann %i", client);
}