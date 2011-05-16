#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

public Action:Spawn_Heart(client)
{
	new heart = TF_SpawnMedipack(client, "item_healthkit_full", false);	
	if(heart == -1)
	{
		PrintCenterText(client, "Couldn't spawn the heart, try again later...");
		client_rolls[client][AWARD_G_HEARTSAPLENTY][1]++; //Re-imburse it
		return Plugin_Stop;
	}
	killEntityIn(heart, 180.0);
	
	//Set the owner to the client
	SetEntPropEnt(heart, Prop_Data, "m_hOwnerEntity", client);
	new iTeam = GetClientTeam(client);
	
	if(iTeam == BLUE_TEAM)
		DispatchKeyValue(heart, "skin","1"); 
	
	SetVariantInt(iTeam);
	AcceptEntityInput(heart, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(heart, "SetTeam", -1, -1, 0); 
	
	//Make it a heart
	SetEntityModel(heart, MODEL_HEART);
	
	//Disable the item
	SetEntProp(heart, Prop_Data, "m_bDisabled", 1);
	
	//Enable the item in 2 seconds
	new String:addoutput[64];
	Format(addoutput, sizeof(addoutput), "OnUser2 !self:enable::%f:1",2.0);
	SetVariantString(addoutput);
	AcceptEntityInput(heart, "AddOutput");
	AcceptEntityInput(heart, "FireUser2");
	
	return Plugin_Handled;
}