#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
/////////////////////////////////////////
// Sets the clients rate of fire       //
//-------------------------------------//
//Default = 0.0 or 1.0                 //
//Slow RoF = 0.0 - 1.0                 //
//Fast RoF = 1.0 - 3.5                 //
/////////////////////////////////////////

public Action:SetROFOnWeapon(Handle:timer, any:client)
{
	new WeaponNum = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (WeaponNum > 0)
	{
		if(IsValidEntity(WeaponNum))
		{
			
			new Float:PrimOff = GetEntPropFloat(WeaponNum, Prop_Data, "m_flNextPrimaryAttack");
			new Float:SecoOff = GetEntPropFloat(WeaponNum, Prop_Data, "m_flNextSecondaryAttack");
			new Float:EngineTick = GetGameTime();
			new Float:WeaponTick = ((PrimOff-EngineTick)*(1.0/ROFMult[client]));
			SetEntPropFloat(WeaponNum, Prop_Data, "m_flNextPrimaryAttack", WeaponTick+EngineTick);
			WeaponTick = ((SecoOff-EngineTick)*(1.0/ROFMult[client]));
			SetEntPropFloat(WeaponNum, Prop_Data, "m_flNextSecondaryAttack", WeaponTick+EngineTick);
		}
	}
	
}

//for berserker
public Action:berserkerMessage(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		SetHudTextParams(0.35, 0.82, 5.0, 250, 250, 210, 255);
		ShowHudText(client, HudMsg3, "Your rate of fire has been increased!");
	}
}