#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>

#define BOOST_AMOUNT 12.5

new g_iVelocity_jetpack = -1;

//Taken from https://forums.alliedmods.net/showthread.php?t=56374.  Written by Knagg0
//Modified by Czech, renamed from AddVelocity to Jetpack_Player
public Jetpack_Player(client, Float:angles[3], buttons)
{
	if (g_iVelocity_jetpack == -1)
		g_iVelocity_jetpack = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
	if (angles[0] < 65.0 || GetActiveWeaponSlot(client) != 0 || TF2_GetPlayerClass(client) != TFClass_Pyro || g_iVelocity_jetpack == -1)
		return;
	
	new cflags = GetEntData(client, m_fFlags);
	
	new Float:vecVelocity[3];
	GetEntDataVector(client, g_iVelocity_jetpack, vecVelocity);
	//PrintToChat(client, "%f", vecVelocity[2]);
	
	vecVelocity[2] += BOOST_AMOUNT;
	
	if(vecVelocity[2] < 0.0)
		vecVelocity[2] = 200.0;
	
	if(cflags & FL_ONGROUND)
	{
		if(buttons & IN_DUCK)
		{
			vecVelocity[2] += 600.0;
		}else{
			vecVelocity[2] += 300.0;
		}
	}
	
	/* TODO: Do a vector calc to allow the player to change direction in the air
	if (angles[0] < 88.0) {
		USE angles[1] HERE FOR DETERMINING ORIENTATION
	}
	*/
	
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}