#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>

public Action:Spawn_Fireball(any:client)
{
	new fireball = CreateEntityByName("info_particle_system");
	if(IsValidEntity(fireball))
	{	
		new Float:pos[3];
		GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
		
		//-----Fireball
		DispatchKeyValue(fireball, "effect_name", "cinefx_goldrush");
		TeleportEntity(fireball, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchSpawn(fireball);
		
		ActivateEntity(fireball);
		AcceptEntityInput(fireball, "start");
		EmitSoundToAll(Bomb_Explode, client);
		
		// send "kill" event to the event queue
		killEntityIn(fireball, 10.0);
		
		//Hurt nearby players
		new iTeam = GetClientTeam(client);
		new cond;
		new Float:otherPos[3];
		new Float:distance;
		
		for (new i = 1; i <= MaxClients ; i++)
		{
			if(!IsClientInGame(i) || !IsPlayerAlive(i))
				continue;
			
			if(GetClientTeam(i) == iTeam)
				continue;
			
			GetClientEyePosition(i, otherPos);
			
			distance = GetVectorDistance(pos, otherPos);
			cond = GetEntData(i, m_nPlayerCond);
			
			if(client_rolls[i][AWARD_G_GODMODE][0])
				continue;
			
			if(cond == 32 || cond == 327712)
				continue;
			
			if(distance > 800.0)
				continue;
			
			if(isVisibileCheck(i, fireball))
			{
				DealDamage(i, 40,	client,	16779264,	"fireball");
				DealDamage(i,  0,	client,		2056,	"fireball");
			}
		}
	}
}


public Action:Spawn_Fireball_HurtAll(any:client)
{
	new fireball = CreateEntityByName("info_particle_system");
	if(IsValidEntity(fireball))
	{	
		new Float:pos[3];
		GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
		
		//-----Fireball
		new rnd = GetRandomInt(1, 5);
		switch(rnd)
		{
			case 1:
			{
				DispatchKeyValue(fireball, "effect_name", "cinefx_goldrush");
			}
			case 2:
			{
				DispatchKeyValue(fireball, "effect_name", "fireSmokeExplosion");
			}
			case 3:
			{
				DispatchKeyValue(fireball, "effect_name", "fireSmokeExplosion2");
			}
			case 4:
			{
				DispatchKeyValue(fireball, "effect_name", "fireSmokeExplosion3");
			}
			case 5:
			{
				DispatchKeyValue(fireball, "effect_name", "fireSmokeExplosion4");
			}
		}
		TeleportEntity(fireball, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchSpawn(fireball);
		
		ActivateEntity(fireball);
		AcceptEntityInput(fireball, "start");
		EmitSoundToAll(Bomb_Explode, client);
		
		// send "kill" event to the event queue
		killEntityIn(fireball, 10.0);
		
		//Hurt nearby players
		new cond;
		new Float:otherPos[3];
		new Float:distance;
		
		for (new i = 1; i <= MaxClients ; i++)
		{
			if(!IsClientInGame(i) || !IsPlayerAlive(i))
				continue;
			
			GetClientEyePosition(i, otherPos);
			
			distance = GetVectorDistance(pos, otherPos);
			cond = GetEntData(i, m_nPlayerCond);
			
			if(client_rolls[i][AWARD_G_GODMODE][0])
				continue;
			
			if(cond == 32 || cond == 327712)
				continue;
			
			if(distance > 800.0)
				continue;
			
			DealDamage(i, 5,	i,	16779264,	"fireball");
			DealDamage(i,  0,	i,		2056,	"fireball");
			
			SetHudTextParams(0.405, 0.82, 6.0, 255, 50, 50, 255);
			ShowHudText(i, HudMsg3, "You were hurt by: Hell's Wrath");
			
			Shake2(i, 2.5, 15.0);
			DoSmallJump(i);
		}
	}
}


public Action:DoSmallJump(any:other)
{
	// Calculate and apply a new velocity to the player.
	new Float:speed[3];
	GetEntPropVector(other, Prop_Data, "m_vecVelocity", speed);
	speed[0] *= (cvHSpeed * 0.5);
	speed[1] *= (cvHSpeed * 0.5);
	
	speed[2] = (cvVSpeed * 0.5);
	
	TeleportEntity(other, NULL_VECTOR, NULL_VECTOR, speed);
	
	AttachFastParticle(other, "rockettrail", 1.0);
}