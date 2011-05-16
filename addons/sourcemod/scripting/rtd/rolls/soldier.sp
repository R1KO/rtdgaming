stock TF_SetRageLevel(client, Float:ragelevel)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if(index > 0 && !GetEntProp(client, Prop_Send, "m_bRageDraining"))
		SetEntPropFloat(client, Prop_Send, "m_flRageMeter", ragelevel);
}