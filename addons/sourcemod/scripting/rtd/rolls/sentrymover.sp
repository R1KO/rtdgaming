#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <rtd_rollinfo>

public Action:SentryMoverTimer(Handle:Timer, any:i)
{
	if(!UsingSentryMover[i][0])
		return Plugin_Stop;
	
	SetHudTextParams(0.35, 0.82, 1.0, 250, 250, 210, 255);
	ShowHudText(i, HudMsg3, "Right click to control your sentry!");
	
	if(GetClientButtons(i) & IN_ATTACK2 && UsingSentryMover[i][1])
	{
		//The Player wants to go back and control his own body
		UsingSentryMover[i][1]=0;
		
		if( (sentryWatcher[i] > 0) && IsValidEntity(sentryWatcher[i]) )
			RemoveEdict(sentryWatcher[i]);
		
		if(IsValidEntity(isRemoting[i]))
		{
			AcceptEntityInput(isRemoting[i], "ClearParent");
			
			new Float:angles[3];
			GetClientEyeAngles(i, angles);	
			angles[0] = 0.0;
			
			TeleportEntity(isRemoting[i], NULL_VECTOR, angles, NULL_VECTOR);	
		}
		
		SetClientViewEntity(i, i);
		SetEntityMoveType(i, MOVETYPE_WALK);
			
		new String:classname[50];
		if(IsValidEdict(isRemoting[i]))
		{
			GetEdictClassname(isRemoting[i], classname, 50);
			if(strcmp(classname, "obj_sentrygun") == 0)
			{
				//SetEntData(isRemoting[i], FindSendPropOffs("CObjectSentrygun","m_CollisionGroup"), 5, 4 , true);
			}
			
			for (new isClientRiding = 1;  isClientRiding <= MaxClients; isClientRiding++) 
			{
				if(ridingSentry[isClientRiding][1] == isRemoting[i])
				{
					ridingSentry[isClientRiding][0] = 0;
					ridingSentry[isClientRiding][1] = 0;
				}
			}
			
			isRemoting[i] = 0;
		}
	}else{
		if(GetClientButtons(i) & IN_ATTACK2 && UsingSentryMover[i][1] == 0)
		{	
			//The player wants to control the sentry
			
			new sentryid = -1;
			new entcount = GetEntityCount();
			for(new j=0;j<entcount;j++)
			{
				if(IsValidEntity(j))
				{
					new String:classname[50];
					GetEdictClassname(j, classname, 50);
					
					if(strcmp(classname, "obj_sentrygun") == 0)
					{
						if(GetEntDataEnt2(j, FindSendPropOffs("CObjectSentrygun","m_hBuilder")) == i)
						{
							new String:modelname[128];
							GetEntPropString(j, Prop_Data, "m_ModelName", modelname, 128);
							//PrintToChatAll("Sntry Lvl: %s",modelname);
							
							if (!StrEqual(modelname, "models/buildables/sentry1_blueprint.mdl"))
							{
								sentryid = j;
								break;
							}
						}
					}
				}
			}
			
			if(sentryid < 0)
			{
				PrintToChat(i, "No sentry gun found!");
				UsingSentryMover[i][1] = 0;
				isRemoting[i] = 0;
			}else{		
				UsingSentryMover[i][1]=1;
				SetEntityMoveType(sentryid, MOVETYPE_STEP);
				
				//SetEntityMoveType(i, MOVETYPE_FLY);
				isRemoting[i] = sentryid;
				
				new String:tWName[128];
				Format(tWName, sizeof(tWName), "target%i", i);
				DispatchKeyValue(i, "targetname", tWName);
				
				sentryWatcher[i] = CreateEntityByName("info_particle_system");
				
				new String:tName[128];
				Format(tName, sizeof(tName), "sentry%i", sentryid);
				DispatchKeyValue(sentryid, "targetname", tName);
				
				new Float:angles[3];
				GetClientEyeAngles(i, angles);
				angles[0] = 0.0;
				
				new Float:fwdvec[3];
				new Float:rightvec[3];
				new Float:upvec[3];
				GetAngleVectors(angles, fwdvec, rightvec, upvec);	
				new Float:sentrypos[3];
				GetEntPropVector(sentryid, Prop_Data, "m_vecOrigin", sentrypos);
				sentrypos[0] += fwdvec[0] * -150.0;
				sentrypos[1] += fwdvec[1] * -150.0;
				sentrypos[2] += upvec[2] * 75.0;
				
				//Teleport the SentryWatcher to the sentry's position
				TeleportEntity(sentryWatcher[i], sentrypos, angles, NULL_VECTOR);
				//Rotate the sentry to match the client's viewing angles
				TeleportEntity(sentryid, NULL_VECTOR, angles, NULL_VECTOR);
				
				//parent the SentryWatcher to the sentry
				//This is for x,y,z movement
				
				SetVariantString(tName);
				AcceptEntityInput(sentryWatcher[i], "SetParent");
				
				SetClientViewEntity(i, sentryWatcher[i]);
			}
		}
	}
	
	//Here we move it
	if(IsClientInGame(i) && (isRemoting[i] != 0))
	{
		if(!IsValidEntity(isRemoting[i]))
		{
			//The sentry was destroyed so let's clear any users that are riding it
			for (new isClientRiding = 1;  isClientRiding <= MaxClients; isClientRiding++) 
			{
				if(ridingSentry[isClientRiding][1] == isRemoting[i]){
					ridingSentry[isClientRiding][0] = 0;
					ridingSentry[isClientRiding][1] = 0;
				}
				
			}
			
			if(isRemoting[i] != 0)
			{
				UsingSentryMover[i][1]=0;
			}
			
			if( (sentryWatcher[i] > 0) && IsValidEntity(sentryWatcher[i]) ) RemoveEdict(sentryWatcher[i]);
			{
				if(IsValidEntity(isRemoting[i]))
				{
					new Float:angles[3];
					GetClientEyeAngles(i, angles);	
					//angles[0] = 0.0;
					
					TeleportEntity(isRemoting[i], NULL_VECTOR, angles, NULL_VECTOR);	
				}
			}
			
			SetClientViewEntity(i, i);
			SetEntityMoveType(i, MOVETYPE_WALK);
			isRemoting[i] = 0;
			
		}
		else
		{
			new Float:angles[3];
			GetClientEyeAngles(i, angles);
			//Prevents Up & Down Camera Movement
			angles[0] = 0.0;
			
			new Float:fwdvec[3];
			new Float:rightvec[3];
			new Float:upvec[3];
			GetAngleVectors(angles, fwdvec, rightvec, upvec);
			
			new Float:vel[3];		
			vel[2] = -300.0;
			new buttons = GetClientButtons(i);
			
			new iLevel;
			new Float: sentrySpeed;
			new Float: sentryFloatSpeed;
			
			iLevel = GetEntData(isRemoting[i], FindSendPropOffs("CObjectSentrygun","m_iUpgradeLevel"), 4);
			
			//22 = we can carry players  :)
			//SetEntData(isRemoting[i], FindSendPropOffs("CObjectSentrygun","m_CollisionGroup"),        22, 4 , true);
			
			//Are any players riding? If they are let's lessen the floatspeed
			//The sentry was destroyed so let's clear any users that are riding it
			new Float:playerRiding;
			/*
			for (new isClientRiding = 1;  isClientRiding <= MaxClients; isClientRiding++) 
			{
				if(ridingSentry[isClientRiding][1] == isRemoting[i])
					playerRiding += 30.0;
			}*/
			
			if(iLevel == 1){
				sentrySpeed = 250.0;
				sentryFloatSpeed = 280.0 + playerRiding;
			}
			if(iLevel == 2){
				sentrySpeed = 155.0;
				sentryFloatSpeed = 130.0 + playerRiding;
			}
			if(iLevel == 3){
				sentrySpeed = 125.0;
				sentryFloatSpeed = 100.0 + playerRiding;
			}
			
			if(buttons & IN_FORWARD)
			{
				vel[0] += fwdvec[0] * sentrySpeed;
				vel[1] += fwdvec[1] * sentrySpeed;
			}
			if(buttons & IN_BACK)
			{
				vel[0] += fwdvec[0] * (-1.0 * sentrySpeed);
				vel[1] += fwdvec[1] * (-1.0 * sentrySpeed);
			}
			if(buttons & IN_MOVELEFT)
			{
				vel[0] += rightvec[0] * (-1.0 * sentrySpeed);
				vel[1] += rightvec[1] * (-1.0 * sentrySpeed);
			}
			if(buttons & IN_MOVERIGHT)
			{
				vel[0] += rightvec[0] * sentrySpeed;
				vel[1] += rightvec[1] * sentrySpeed;
			}
			
			if(buttons & IN_JUMP)
			{
				//new flags = GetEntityFlags(isRemoting[i]);
				//if(flags & FL_ONGROUND)
				//{
				vel[2] = -50.0;
				vel[2] += sentryFloatSpeed;
				//}
			}
			
			if(IsValidEntity(isRemoting[i]))
			{
				new Float:sentrypos[3];
				GetEntPropVector(isRemoting[i], Prop_Data, "m_vecOrigin", sentrypos);
				/*
				decl Float:vVel[3];
				for (new j = 1; j <= MaxClients; j++)
				{
					if(IsClientInGame(j) && j != i)
					{
						new Float:clientPos[3];
						GetClientAbsOrigin(j,clientPos);
						new Float:distance = GetVectorDistance(clientPos, sentrypos);
						
						if(ridingSentry[j][0] && ridingSentry[j][1] == isRemoting[i])
						{
							vVel[0] = sentrypos[0];
							vVel[1] = sentrypos[1];
							vVel[2] = sentrypos[2] + 67.5;
							
							new Float:ridervel[3];
							ridervel[0] = 0.0;//vel[0];
							ridervel[1] = 0.0;//vel[1];
							ridervel[2] = 250.000008;
							TeleportEntity(j, vVel, NULL_VECTOR, ridervel);
						}
						
						if(distance < 75.0)
						{	
							new buttons2 = GetClientButtons(j);
							if(buttons2 & IN_DUCK){
								ridingSentry[j][0] = 1;
								ridingSentry[j][1] = isRemoting[i];
								
								if(TF2_GetPlayerClass(j) == TFClass_Engineer)
									StripToMelee(j);
								
							}
							
							if(buttons2 & IN_JUMP){
								ridingSentry[j][0] = 0;
								ridingSentry[j][1] = 0;
							}
								
							if(ridingSentry[j][0] && ridingSentry[j][1] == isRemoting[i])
							{
								SetHudTextParams(0.35, 0.82, 1.0, 250, 250, 210, 255);
								ShowHudText(j, HudMsg3, "JUMP to get off the sentry");
							}
							if(!ridingSentry[j][0]){
								SetHudTextParams(0.35, 0.82, 1.0, 250, 250, 210, 255);
								ShowHudText(j, HudMsg3, "DUCK to ride the sentry");
							}
						}else{
							//ridingSentry[j][0] = 0;
						}
					}
				}	
				* */
				TeleportEntity(isRemoting[i], NULL_VECTOR, angles, vel);
				//TeleportEntity(i, sentrypos, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
	
	return Plugin_Continue;
}