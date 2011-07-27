stock Blast(victim, attacker)
{	
	new Float:aang[3], Float:vvel[3], Float:pvec[3];
	
	// Knockback
	GetClientAbsAngles(attacker, aang);
	GetEntPropVector(victim, Prop_Data, "m_vecVelocity", vvel);
	
	if (attacker == victim) 
	{
		vvel[2] += 1000.0;
	} else {
		GetAngleVectors(aang, pvec, NULL_VECTOR, NULL_VECTOR);
		
		vvel[0] += pvec[0] * 300.0;
		vvel[1] += pvec[1] * 300.0;
		vvel[2] = 500.0;
	}
	
	TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vvel);
}

public bool:TraceEntityFilterPlayers(entity, contentsMask) 
{
	return entity > GetMaxClients();
}

