#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <rtd_trinkets>
#include <tf2>

public Action:HastyCharge_Timer(Handle:timer)
{
	new TFClassType:class;
	new iWeapon;
	new Float:curLevel;
	new Float:newAddedLevel;
	new weaponInfo[12];
	new totWeaponsFound;
	new weaponID;
	new Float:rechargeTime;
	new Float:timeReduction;
	new Float:totalCalls;
	new Float:incrementPerCall;
	new Float:timeStamp;
	
	new Float:trinketValue;
	new iOffset;
	new iCurAmmo;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		//ok let's make sure that the player really is in the game
		if(IsClientInGame(i))
		{
			if(RTD_TrinketActive[i][TRINKET_HASTYCHARGE])
			{
				trinketValue = float(RTD_TrinketBonus[i][TRINKET_HASTYCHARGE]) / 1000.0;
				totWeaponsFound = 0;
				
				///////////////////////
				// Get weapon entity //
				///////////////////////
				for (new islot = 0; islot < 11; islot++) 
				{
					iWeapon = GetPlayerWeaponSlot(i, islot);
					
					if (IsValidEntity(iWeapon))
					{
						weaponInfo[totWeaponsFound] = iWeapon;
						
						totWeaponsFound ++;
					}	
				}
				
				/////////////////////////////
				// Rare case where player  //
				// has no weapons equipped //
				// no worries, less work   //
				/////////////////////////////
				if(totWeaponsFound < 1)
					continue;
				
				class = TF2_GetPlayerClass(i);
				
				switch(class)
				{
					
					////////////////////
					// SCOUT          //
					////////////////////
					case TFClass_Scout:
					{
						for (new currWeapon = 0; currWeapon < totWeaponsFound; currWeapon++)
						{
							weaponID = GetEntProp(weaponInfo[currWeapon], Prop_Send, "m_iItemDefinitionIndex");
							
							if(weaponID == 44 || weaponID == 222)
							{
								//44  = The Sandman
								//222 = Mad Milk
								if(weaponID == 222)
									rechargeTime = 20.0;
								
								if(weaponID == 44)
									rechargeTime = 15.0;
								
								iOffset = GetEntProp(weaponInfo[currWeapon], Prop_Send, "m_iPrimaryAmmoType", 1)*4;
								iCurAmmo = GetEntData(i, iAmmoTable+iOffset);
								
								if(iCurAmmo == 0)
								{
									timeReduction = rechargeTime * (float(RTD_TrinketBonus[i][TRINKET_HASTYCHARGE])/100.0);
									totalCalls = (rechargeTime - timeReduction) * 10.0;
									
									incrementPerCall = timeReduction / totalCalls;
									
									timeStamp = GetEntPropFloat(weaponInfo[currWeapon], Prop_Send, "m_flEffectBarRegenTime") - incrementPerCall;
									
									SetEntPropFloat(weaponInfo[currWeapon], Prop_Send, "m_flEffectBarRegenTime", timeStamp);
								}
								
								continue;
							}
							
							
							if(weaponID == 46 || weaponID == 163)
							{
								//46  = Bonk! Atomic Punch
								//163 = Crit-a-Cola
								
								trinketValue = float(RTD_TrinketBonus[i][TRINKET_HASTYCHARGE]) / 100.0;
								
								curLevel = GetEntDataFloat(i, m_flEnergyDrinkMeter);
								
								if(!TF2_IsPlayerInCondition(i, TFCond_Bonked))
								{
									newAddedLevel = curLevel + trinketValue;
									
									if(newAddedLevel < 100.0)
									{
										SetEntDataFloat(i, m_flEnergyDrinkMeter, newAddedLevel);
										
										curLevel = GetEntPropFloat(weaponInfo[currWeapon], Prop_Send, "m_flEffectBarRegenTime");
										trinketValue = float(RTD_TrinketBonus[i][TRINKET_HASTYCHARGE]) / 1000.0;
										newAddedLevel = curLevel - trinketValue;
										
										SetEntPropFloat(weaponInfo[currWeapon], Prop_Send, "m_flEffectBarRegenTime", newAddedLevel);
									}
								}
								
								continue;
							}
							
						}
						
						
					}
					
					////////////////////
					// DEMOMAN        //
					////////////////////
					case TFClass_DemoMan:
					{
						if(GetEntProp(i, Prop_Send, "m_bShieldEquipped"))
						{
							//Shields: The Chargin' Targe and the Splendid Screen
							
							curLevel =  GetEntDataFloat(i, m_flChargeMeter);
							
							trinketValue = float(RTD_TrinketBonus[i][TRINKET_HASTYCHARGE]) / 100.0;
							newAddedLevel = curLevel + trinketValue;
							
							if(!TF2_IsPlayerInCondition(i, TFCond_Charging))
							{
								if(newAddedLevel < 100.0)
								{
									SetEntDataFloat(i, m_flChargeMeter, newAddedLevel);
								}
							}
						}
						
						for (new currWeapon = 0; currWeapon < totWeaponsFound; currWeapon++)
						{
							weaponID = GetEntProp(weaponInfo[currWeapon], Prop_Send, "m_iItemDefinitionIndex");
							
							if(weaponID == 20 || weaponID == 130)
							{
								//20  = Stickybomb Launcher
								//130 = Scottish Resistance
								rechargeTime = 4.0;
								
								timeStamp = GetEntPropFloat(weaponInfo[currWeapon], Prop_Send, "m_flChargeBeginTime");
								
								if(timeStamp > 0)
								{
									//PrintToChat(i, "%f", GetEngineTime());
									
									timeReduction = rechargeTime * (float(RTD_TrinketBonus[i][TRINKET_HASTYCHARGE])/100.0);
									totalCalls = (rechargeTime - timeReduction) * 10.0;
									
									incrementPerCall = timeReduction / totalCalls;
									
									timeStamp -= incrementPerCall;
									
									SetEntPropFloat(weaponInfo[currWeapon], Prop_Send, "m_flChargeBeginTime", timeStamp);
								}
								
								continue;
							}
						}
					}
					
					////////////////////
					// SNIPER         //
					////////////////////
					case TFClass_Sniper:
					{	
						for (new currWeapon = 0; currWeapon < totWeaponsFound; currWeapon++)
						{
							weaponID = GetEntProp(weaponInfo[currWeapon], Prop_Send, "m_iItemDefinitionIndex");
							
							if(weaponID == 14 || weaponID == 230)
							{
								//14  = Sniper Rifle
								if(weaponID == 14)
									rechargeTime = 3.0;
								
								//230  = Sydney Sleep
								if(weaponID == 230)
									rechargeTime = 2.4;
								
								curLevel = GetEntPropFloat(weaponInfo[currWeapon], Prop_Send, "m_flChargedDamage");
								
								if(curLevel > 0.0 && curLevel < 150.0)
								{
									timeReduction = rechargeTime * (float(RTD_TrinketBonus[i][TRINKET_HASTYCHARGE])/100.0);
									
									totalCalls = (rechargeTime - timeReduction) * 10.0;
									
									//150 == max damage
									//5 == increments each 0.1s under normal conditions to achieve 150 in 3s
									incrementPerCall = (150 - (totalCalls * 5))/totalCalls;
									
									//PrintToChat(i, "%f | %f", GetEngineTime(), curLevel);
									
									curLevel += incrementPerCall;
									
									SetEntPropFloat(weaponInfo[currWeapon], Prop_Send, "m_flChargedDamage", curLevel);
								}
								
								continue;
							}
							
							if(weaponID == 56)
							{
								//56 == Huntsman
								rechargeTime = 1.0;
								timeStamp = GetEntPropFloat(weaponInfo[currWeapon], Prop_Send, "m_flChargeBeginTime");
								
								if(timeStamp > 0)
								{
									if((GetGameTime() - timeStamp ) < rechargeTime)
									{
										timeReduction = rechargeTime * (float(RTD_TrinketBonus[i][TRINKET_HASTYCHARGE])/100.0);
										totalCalls = (rechargeTime - timeReduction) * 10.0;
										
										incrementPerCall = (timeReduction / totalCalls);
										
										timeStamp -= incrementPerCall;
										
										//PrintToChat(i, "%f", GetEngineTime());
										SetEntPropFloat(weaponInfo[currWeapon], Prop_Send, "m_flChargeBeginTime", timeStamp);
									}
								}
								continue;
							}
							
							if(weaponID == 58)
							{
								//58 == Jarate
								rechargeTime = 20.0;
								
								iOffset = GetEntProp(weaponInfo[currWeapon], Prop_Send, "m_iPrimaryAmmoType", 1)*4;
								iCurAmmo = GetEntData(i, iAmmoTable+iOffset);
								
								if(iCurAmmo == 0)
								{
									//PrintToChat(i, "%f", GetEngineTime());
									
									timeReduction = rechargeTime * (float(RTD_TrinketBonus[i][TRINKET_HASTYCHARGE])/100.0);
									totalCalls = (rechargeTime - timeReduction) * 10.0;
									
									incrementPerCall = timeReduction / totalCalls;
									
									timeStamp = GetEntPropFloat(weaponInfo[currWeapon], Prop_Send, "m_flEffectBarRegenTime") - incrementPerCall;
									
									SetEntPropFloat(weaponInfo[currWeapon], Prop_Send, "m_flEffectBarRegenTime", timeStamp);
								}
								
								
								continue;
							}
						}
					}
					
					////////////////////
					// HEAVY          //
					////////////////////
					case TFClass_Heavy:
					{	
						for (new currWeapon = 0; currWeapon < totWeaponsFound; currWeapon++)
						{
							weaponID = GetEntProp(weaponInfo[currWeapon], Prop_Send, "m_iItemDefinitionIndex");
							
							if(weaponID == 42 || weaponID == 159 || weaponID == 311 || weaponID == 433)
							{
								//42  = The Sandvich
								//159 = The Dalokohs Bar
								//311 = The Buffalo Steak Sandvich
								//433 = Fishcake
								
								rechargeTime = 30.0;
								
								iOffset = GetEntProp(weaponInfo[currWeapon], Prop_Send, "m_iPrimaryAmmoType", 1)*4;
								iCurAmmo = GetEntData(i, iAmmoTable+iOffset);
								
								if(iCurAmmo == 0)
								{
									//PrintToChat(i, "%f", GetEngineTime());
									
									timeReduction = rechargeTime * (float(RTD_TrinketBonus[i][TRINKET_HASTYCHARGE])/100.0);
									totalCalls = (rechargeTime - timeReduction) * 10.0;
									
									incrementPerCall = timeReduction / totalCalls;
									
									timeStamp = GetEntPropFloat(weaponInfo[currWeapon], Prop_Send, "m_flEffectBarRegenTime") - incrementPerCall;
									
									SetEntPropFloat(weaponInfo[currWeapon], Prop_Send, "m_flEffectBarRegenTime", timeStamp);
								}
								
								
								continue;
							}
						}
					}
				}
				
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:rageMeter_DelayTimer(Handle:timer, Handle:dataPackHandle)
{
	ResetPack(dataPackHandle);
	new client = GetClientOfUserId(ReadPackCell(dataPackHandle));
	new Float:pastLevel = ReadPackFloat(dataPackHandle);
	
	if(client < 1)
		return Plugin_Stop;
	
	if(!IsPlayerAlive(client))
		return Plugin_Stop;
	
	if(RTD_TrinketActive[client][TRINKET_HASTYCHARGE])
	{
		////////////////////
		// SOLDIER        //
		////////////////////
		if(TF2_GetPlayerClass(client) == TFClass_Soldier)
		{
			new weaponEntity = GetPlayerWeaponSlot(client, 1);
			
			if(weaponEntity > 0 && !GetEntProp(client, Prop_Send, "m_bRageDraining"))
			{
				new weaponID = GetEntProp(weaponEntity, Prop_Send, "m_iItemDefinitionIndex");
				
				if(weaponID == 129 || weaponID == 226 || weaponID == 354)
				{
					//129 = The Buff Banner
					//226 = The Battalion's Backup
					//354 = The Concheror
					new Float:ragelevel = GetEntPropFloat(client, Prop_Send, "m_flRageMeter");
					
					//make sure rage has changed
					if(pastLevel != ragelevel)
					{
						//don't bother with 
						if(ragelevel < 100.0)
						{
							new Float:adjustedRage = (ragelevel - pastLevel) * (float(RTD_TrinketBonus[client][TRINKET_HASTYCHARGE])/100.0);
							
							//PrintToChat(client, "%f | %f", ragelevel, adjustedRage);
							new Float: finalRage = ragelevel + adjustedRage;
							
							if(finalRage > 100.0)
								finalRage = 100.0;
							
							SetEntPropFloat(client, Prop_Send, "m_flRageMeter", finalRage);
						}
					}else{
						//PrintToChat(client, "Rage has not changed! %f", ragelevel);
					}
					
				}
			}
		}
	}
	
	return Plugin_Stop;
}