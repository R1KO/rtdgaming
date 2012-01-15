#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

public Action:Spawn_FriedChicken(client)
{
	new chicken = TF_SpawnMedipack(client, "item_healthkit_full", false);	
	if(chicken == -1)
	{
		PrintCenterText(client, "Couldn't spawn the heart, try again later...");
		return Plugin_Stop;
	}
	
	killEntityIn(chicken, 180.0);
	
	//Set the owner to the client
	SetEntPropEnt(chicken, Prop_Data, "m_hOwnerEntity", client);
	
	//Make it a fried chiken
	SetEntityModel(chicken, MODEL_FRIED_CHICKEN);
	
	//Disable the item
	SetEntProp(chicken, Prop_Data, "m_bDisabled", 1);
	
	//Enable the item in 2 seconds
	new String:addoutput[64];
	Format(addoutput, sizeof(addoutput), "OnUser2 !self:enable::%f:1",2.0);
	SetVariantString(addoutput);
	AcceptEntityInput(chicken, "AddOutput");
	AcceptEntityInput(chicken, "FireUser2");
	
	HookSingleEntityOutput(chicken, "OnPlayerTouch", friedChicken_Pickup, false);
	
	return Plugin_Handled;
}

public friedChicken_Pickup (const String:output[], caller, activator, Float:delay)
{
	if(IsValidEntity(caller))
	{
		CreateTimer(0.1, Timer_WaitForFriedChicken, GetClientUserId(activator), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_WaitForFriedChicken(Handle:Timer, any:clientUserID)
{
	new client = GetClientOfUserId(clientUserID);
	
	if(client < 1)
		return Plugin_Stop;
	
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	#define SOUND_EVENT_MLK_07		"vo/demoman_battlecry07.wav"
	
	new rndNum = GetRandomInt(1,7);
	new String:soundToPlay[64];
	Format(soundToPlay, 64, "vo/demoman_battlecry0%i.wav", rndNum);
	
	EmitSoundToClient(client, soundToPlay);

	addHealthPercentage(client, 0.2, true);
	
	return Plugin_Stop;
}