#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <rtd_rollinfo>

AttachRTDParticle(client, String:particleType[], bool:autoKill, attachToHead, Float:zCorrection)
{	
	//PrintToChat(client, "AttachRTDParticle: %s", particleType);
	new availableSlot;
	
	//find available particle slot
	if(client <= MaxClients)
	{
		availableSlot = NextAvailableParticleSlot(client);
		
		if(availableSlot == -1)
			return;
	}
	
	new particle = CreateEntityByName("info_particle_system");

	new String:tName[128];
	if (IsValidEdict(particle))
	{
		new Float:pos[3]; 
		new Float:angle[3]; 
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		//GetEntPropVector(client, Prop_Data, "m_angRotation", angle);
		
		pos[2] += zCorrection;
		
		
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(tName, sizeof(tName), "target%i", client);
		DispatchKeyValue(client, "targetname", tName);
		
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", client);
		
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		
		if(client <= MaxClients)
		{
			if(attachToHead == 1)
			{
				SetVariantString("head");
				AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
			}
			if(attachToHead == 2)
			{
				SetVariantString("flag");
				AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
				
				angle[2] = 70.0;
				TeleportEntity(particle, NULL_VECTOR, angle, NULL_VECTOR);
			}
			
			RTDParticle[client][availableSlot] = particle;
			
		}
		
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		if(StrEqual(particleType, "ghost_pumpkin", false))
		{
			if (GetClientTeam(client) == 2)
			{
				SetVariantString("155+0+0");
				AcceptEntityInput(particle, "color", -1, -1, 0);
			}
		}
		//if(!StrEqual(particleType, "rockettrail", false) && !StrEqual(particleType, "cart_flashinglight", false) && !StrEqual(particleType, "toxictrails_medic_red", false) && !StrEqual(particleType, "jaratee_rain", false) && !StrEqual(particleType, "superrare_circling_skull", false))
		
		if(autoKill)
			killEntityIn(particle, 1.0);
	}
}

public NextAvailableParticleSlot(client)
{
	//Delete all RTD based particles from client
	new String:classname[256];
	
	for(new i = 0; i < 3; i++)
	{
		if(IsValidEntity(RTDParticle[client][i]))
		{
			GetEdictClassname(RTDParticle[client][i], classname, sizeof(classname));
			if (!StrEqual(classname, "info_particle_system", false))
			{
				return i;
			}
		}else{
			return i;
		}
	}
	
	return -1;
}

HasParticle(client,String:particleName[])
{
	//Delete all RTD based particles from client
	new String:classname[256];
	new String:effectname[128];
	
	for(new i = 0; i < 3; i++)
	{
		//LogToFile(logPath,"--Starting to delete particle");
		if(IsValidEntity(RTDParticle[client][i]))
		{
			GetEdictClassname(RTDParticle[client][i], classname, sizeof(classname));
			if (StrEqual(classname, "info_particle_system", false))
			{
				GetEntPropString(RTDParticle[client][i], Prop_Data, "m_iszEffectName", effectname, 128);
				//PrintToChat(client, "%s", effectname);
				if(StrEqual(effectname, particleName, false))
				{
					return 1;
				}
			}
		}
	}
	
	return 0;
}

DeleteParticle(client,String:particleName[])
{
	//Delete all RTD based particles from client
	new String:classname[256];
	new String:effectname[128];
	
	for(new i = 0; i < 3; i++)
	{
		//LogToFile(logPath,"--Starting to delete particle");
		if(IsValidEntity(RTDParticle[client][i]))
		{
			GetEdictClassname(RTDParticle[client][i], classname, sizeof(classname));
			if (StrEqual(classname, "info_particle_system", false))
			{
				GetEntPropString(RTDParticle[client][i], Prop_Data, "m_iszEffectName", effectname, 128);
				//PrintToChat(client, "%s", effectname);
				if(StrEqual(effectname, particleName, false) || StrEqual("all", particleName, false))
				{
					AcceptEntityInput(RTDParticle[client][i],"kill");
					RTDParticle[client][i] = -1;
				}
			}
		}
	}
}

public AttachTempParticle(entity, String:particleType[], Float:lifetime, bool:parent, String:parentName[], Float:zOffset, bool:randOffset)
{	
	if(IsEntLimitReached())
		return false;
	
	//Particle is killed at the end of its lifetime
	//Good to use on particles such as Blood spurts, gibs, etc.
	//    Some good particles: 
	//env_sawblood --rain of blood with some mist
	//blood_trail_red_01_goop -- whole mess of blood
	//blood_impact_red_01 -- basic blood impact
	//bday_1balloon Single balloon floating up.
	//bday_balloon01 Two balloons floating up
	//bday_balloon02 Two balloons floating up
	//bday_confetti Confetti.
	//AttachTempParticle(client,"bday_confetti",3.0)
	//AttachTempParticle(client,"bday_balloon02",3.0)
	//AttachTempParticle(client,"bday_balloon02",3.0)
	
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{	
		//set the bloods entity
		DispatchKeyValue(particle, "targetname", "tf2particle");
		SetEntPropEnt(particle, Prop_Data, "m_hOwnerEntity", entity);
		
		new Float: particlePos[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", particlePos);
		
		new Float: particleAng[3];
		GetEntPropVector(entity, Prop_Data, "m_angRotation", particleAng);
		if(randOffset)
		{
			particlePos[0] += GetRandomInt(-40,40);
			particlePos[1] += GetRandomInt(-40,40);
			particlePos[2] += GetRandomInt(-40,40);
		}else{
			particlePos[2] += zOffset;
		}
		
		TeleportEntity(particle, particlePos, particleAng, NULL_VECTOR);
		
		DispatchKeyValue(particle, "effect_name", particleType);
		
		DispatchKeyValue(particle, "parentname", parentName);
		DispatchSpawn(particle);
		
		if(parent)
		{
			SetVariantString(parentName);
			AcceptEntityInput(particle, "SetParent");
			
			//for the medic, lets get this point outta here
			//DispatchKeyValue(particle, "cpoint1", parentName);
			//DispatchKeyValue(particle, "cpoint2", parentName);
		}
		
		
		// send "kill" event to the event queue
		killEntityIn(particle, lifetime);
		
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
	}
	
	return particle;
}


AttachFastParticle(ent, String:particleType[], Float:lifetime)
{
	if(IsEntLimitReached())
		return;
	
	new particle = CreateEntityByName("info_particle_system");

	new String:tName[128];
	if (IsValidEdict(particle))
	{
		new Float:pos[3]; 
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		
		new parent = GetEntPropEnt(ent, Prop_Data, "m_pParent");
		if(parent > 0)
		{
			GetEntPropVector(parent, Prop_Send, "m_vecOrigin", pos);
			pos[2] += 15;
		}
		
		pos[2] -= 10.0;
		
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);
	
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		killEntityIn(particle, lifetime);
	}
}

AttachFastParticle4(ent, String:particleType[], Float:lifetime, Float:zOffset)
{	
	new particle = CreateEntityByName("info_particle_system");

	new String:tName[128];
	if (IsValidEdict(particle))
	{
		new Float:pos[3]; 
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		
		pos[2] += zOffset;
		
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);
	
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		killEntityIn(particle, lifetime);
	}
}

AttachFastParticle2(ent, String:particleType[], Float:zOffset, String:attachmentPoint[])
{
	//this one just has the option for an attachment point
	new particle = CreateEntityByName("info_particle_system");

	new String:tName[128];
	if (IsValidEdict(particle))
	{
		new Float:pos[3]; 
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += zOffset;
		
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);

		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		
		if(!StrEqual(attachmentPoint, ""))
		{
			SetVariantString(attachmentPoint);
			AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		}
		
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
	}
}

public AttachFastParticle3(ent, owner, clientOnly, String:particleType[], Float:zOffset, String:attachmentPoint[])
{	
	//this one just has the option for an attachment point
	new particle = CreateEntityByName("info_particle_system");

	new String:tName[128];
	if (IsValidEdict(particle))
	{
		new Float:pos[3]; 
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += zOffset;
		
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);

		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", owner);
		
		if(clientOnly)
		{	
			SDKHook(particle, SDKHook_SetTransmit, Hook_EveryoneBlizzard); 
		}else{
			SDKHook(particle, SDKHook_SetTransmit, Hook_ClientBlizzard); 
		}
		
		DispatchSpawn(particle);
		
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		
		SetVariantString(attachmentPoint);
		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		return EntIndexToEntRef(particle);
	}
	
	return -1;
}