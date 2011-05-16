
// ------------------------------------------------------------------------
// TF2_RemoveWearable
// ------------------------------------------------------------------------
stock TF2_RemoveWearable(iOwner, iItem)
{
    if (g_bSdkStarted == false) TF2_SdkStartup();
    
    if (TF2_IsEntityWearable(iItem))
    {
        if (GetEntPropEnt(iItem, Prop_Send, "m_hOwnerEntity") == iOwner) SDKCall(g_hSdkRemoveWearable, iOwner, iItem);
        RemoveEdict(iItem);
    }
}

// ------------------------------------------------------------------------
// TF2_SpawnWearable
// ------------------------------------------------------------------------
stock TF2_SpawnWearable(iOwner, iDef=52, iLevel=100, iQuality=0)
{
    new iTeam = GetClientTeam(iOwner);
    new iItem = CreateEntityByName("tf_wearable_item");
    
    if (IsValidEdict(iItem))
    {
        //SetEntProp(iItem, Prop_Send, "m_bInitialized", 1);    // Disabling this avoids the crashes related to spies
        // disguising as someone with hat in Windows.
        
        // Using reference data from Batter's Helmet. Thanks to MrSaturn.
        SetEntProp(iItem, Prop_Send, "m_fEffects",             EF_BONEMERGE|EF_BONEMERGE_FASTCULL|EF_NOSHADOW|EF_PARENT_ANIMATES);
        SetEntProp(iItem, Prop_Send, "m_iTeamNum",             iTeam);
        SetEntProp(iItem, Prop_Send, "m_nSkin",                (iTeam-2));
        SetEntProp(iItem, Prop_Send, "m_CollisionGroup",       11);
        SetEntProp(iItem, Prop_Send, "m_iItemDefinitionIndex", iDef);
        SetEntProp(iItem, Prop_Send, "m_iEntityLevel",         iLevel);
        SetEntProp(iItem, Prop_Send, "m_iEntityQuality",       iQuality);
        
        // Spawn.
        DispatchSpawn(iItem);
    }
    
    return iItem;
}

// ------------------------------------------------------------------------
// TF2_SdkStartup
// ------------------------------------------------------------------------
stock TF2_SdkStartup()
{
    
    new Handle:hGameConf = LoadGameConfigFile("TF2_EquipmentManager");
    if (hGameConf != INVALID_HANDLE)
    {
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"EquipWearable");
        PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
        g_hSdkEquipWearable = EndPrepSDKCall();
        
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"RemoveWearable");
        PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
        g_hSdkRemoveWearable = EndPrepSDKCall();
        
        CloseHandle(hGameConf);
        g_bSdkStarted = true;
    } else {
        SetFailState("Couldn't load SDK functions (TF2_EquipmentManager).");
    }
}

// ------------------------------------------------------------------------
// TF2_EquipWearable
// ------------------------------------------------------------------------
stock TF2_EquipWearable(iOwner, iItem)
{
    if (g_bSdkStarted == false) TF2_SdkStartup();
    
    if (TF2_IsEntityWearable(iItem)) SDKCall(g_hSdkEquipWearable, iOwner, iItem);
    else                             LogMessage("Error: Item %i isn't a valid wearable.", iItem);
}

// ------------------------------------------------------------------------
// TF2_IsEntityWearable
// ------------------------------------------------------------------------
stock bool:TF2_IsEntityWearable(iEntity)
{
    if ((iEntity > 0) && IsValidEdict(iEntity))
    {
        new String:strClassname[32]; GetEdictClassname(iEntity, strClassname, sizeof(strClassname));
        return StrEqual(strClassname, "tf_wearable_item", false);
    }
    
    return false;
}