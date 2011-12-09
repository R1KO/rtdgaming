#include <rtd_rollinfo>

public Action:Timer_ReflectShield(Handle:Timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client) && client_rolls[client][AWARD_G_REFLECTSHIELD][0])
	{
		new entityCount = GetEntityCount();
		new ent = 0;
		new Float:pos[3];
		new Float:clientPos[3];
		new Float:distance;
		new projectileOwner;
		new String:classname[128];
		new projectileTeam;
		new builder;
		new Float:RocketPos[3];
		new Float:RocketAng[3];
		new Float:RocketVec[3];
		new Float:newRocketVec[3];
		new remote_touched;
		new Float:RocketSpeed;
		
		while(ent < entityCount)
		{
			ent++;
			if(IsValidEntity(ent))
			{
				GetEdictClassname(ent, classname, sizeof(classname));
				if(StrContains(classname, "projectile", false) != -1 && StrContains(classname, "syringe", false) == -1 && !StrEqual(classname, "tf_projectile_energy_ring", false))
				{
					if(SimpleRegexMatch(classname, "(pipe|jar|stun_ball)", PCRE_CASELESS))
					{
						projectileOwner = GetEntPropEnt(ent, Prop_Data, "m_hThrower");
					}
					else
					{
						projectileOwner = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");
					}
					
					if(projectileOwner > MaxClients)
					{
						builder = GetEntDataEnt2(projectileOwner, FindSendPropOffs("CObjectSentrygun","m_hBuilder"));
						if(builder > 0 && builder <= MaxClients)
						{
							if(IsClientInGame(client))
							{
								projectileTeam = GetClientTeam(builder);
							}
						}
					}
					else if(projectileOwner != -1)
					{
						projectileTeam = GetClientTeam(projectileOwner);
					}
					
					GetClientEyePosition(client, clientPos);
					GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos);
					distance = GetVectorDistance(clientPos, pos);

					if(distance < 190.0 && projectileOwner != client && projectileTeam != GetClientTeam(client))
					{
						remote_touched = 0;
						
						GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", RocketPos);
						GetEntPropVector(ent, Prop_Data, "m_angRotation", RocketAng);
						GetEntPropVector(ent, Prop_Data, "m_vecAbsVelocity", RocketVec);
						
						RocketSpeed = GetVectorLength(RocketVec);
						
						if(projectileOwner > 0 && projectileOwner <= MaxClients)
						{
							GetClientEyePosition(projectileOwner, clientPos);
						}
						else if(projectileOwner != -1)
						{
							if(IsValidEntity(projectileOwner))
								GetEntPropVector(projectileOwner, Prop_Data, "m_vecAbsOrigin", clientPos);
						}

						SubtractVectors(clientPos, RocketPos, newRocketVec);

						NormalizeVector(newRocketVec, newRocketVec);
						if(SimpleRegexMatch(classname, "(pipe|jar|stun_ball)", PCRE_CASELESS))
						{
							//Sticky bombs cannot be moved after they have touched the ground
							//I have not found a property that can be used to "un stick" it
							//Also To note, Sticky bombs only change deflected/owner
							//However There is a timer that sets this data back
							//I have been unable to find where or how this timer/property could be duplicated
							//The Owner can be changed and the player can get a kill.
							//But this would be odd
							if(StrContains(classname, "pipe_remote", false) != -1)
								remote_touched = GetEntProp(ent, Prop_Send, "m_bTouched");
							else
							{
								SetEntProp(ent, Prop_Send, "m_iDeflected", GetEntProp(ent, Prop_Send, "m_iDeflected")+1);
								SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(client));
								SetEntPropEnt(ent, Prop_Data, "m_hThrower", client);
								SetEntPropEnt(ent, Prop_Send, "m_hDeflectOwner", client);
							}
							ScaleVector(newRocketVec, 500.0);
							TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, newRocketVec);
						}
						else
						{
							SetEntProp(ent, Prop_Send, "m_iDeflected", GetEntProp(ent, Prop_Send, "m_iDeflected")+1);
							SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(client));
							SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
							GetVectorAngles(newRocketVec, RocketAng);
							SetEntPropVector (ent, Prop_Data, "m_angRotation", RocketAng);
							ScaleVector(newRocketVec, RocketSpeed);
							SetEntPropVector(ent, Prop_Data, "m_vecAbsVelocity", newRocketVec);
						}
						if(!remote_touched)
						{
							AttachTempParticle(ent, "pyro_blast", 3.0, false, "", 0.0, false);
							EmitSoundToAll(SOUND_PYRO_AIRBLAST_REFLECT, ent, SNDCHAN_AUTO);
						}
					}
				}
			}
		}
	}
	else
	{
		client_rolls[client][AWARD_G_REFLECTSHIELD][0] = 0;
		KillTimer(Timer);
	}
}