#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>
#include <rtd_rollinfo>

public Action:Timer_ShowScore(Handle:timer) 
{	
	new Scores_BLU[MaxClients][3]; //0 = client index | 1 = score
	new Scores_RED[MaxClients][3]; //0 = client index | 1 = score
	new amountOfPlayers[2];//0 = red | 1= blu
	
	// For sorting purpose, start fill Scores[][] array from zero index
	//for (new i = MaxClients -1; i > 0; i--)
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if(GetClientTeam(i) == BLUE_TEAM)
			{
				Scores_BLU[amountOfPlayers[1]][0] = i;
				
				Scores_BLU[amountOfPlayers[1]][1] = TF2_GetPlayerResourceData(i, TFResource_TotalScore) - g_BeginScore[i];
				
				amountOfPlayers[1] ++;
				
			}else if(GetClientTeam(i) == RED_TEAM)
			{
				Scores_RED[amountOfPlayers[0]][0] = i;
				
				Scores_RED[amountOfPlayers[0]][1] = TF2_GetPlayerResourceData(i, TFResource_TotalScore) - g_BeginScore[i];
				
				amountOfPlayers[0] ++;
			}
		}
	}
	
	SortCustom2D(Scores_BLU, amountOfPlayers[1], SortScoreDesc);
	SortCustom2D(Scores_RED, amountOfPlayers[0], SortScoreDesc);
	
	new blu_place;
	new red_place;
	new String:text[16];
	new ptsToCatchUp;
	new String:leading[8];
	
	//do red 1st
	for (new i = 0; i < amountOfPlayers[0]; i++)
	{
		if(Scores_RED[i][0] == 0)
			continue;
		
		if(IsClientInGame(Scores_RED[i][0]))
		{
			ptsToCatchUp = 0;
			Format(leading, sizeof(leading), "");	
			
			red_place ++;
			
			if(ScoreEnabled[Scores_RED[i][0]] && !inTimerBasedRoll[Scores_RED[i][0]] && client_rolls[Scores_RED[i][0]][AWARD_G_BLIZZARD][4] == 0)
			{
				returnOrdinal(red_place, text, sizeof(text));
				
				if(red_place == amountOfPlayers[0])
				{
					if(amountOfPlayers[0] == 1)
					{
						Format(text, sizeof(text), "%s (First)",text);		
					}else{
						Format(text, sizeof(text), "%s (Last)",text);	
					}
				}
					
				if(red_place > 1)
				{
					ptsToCatchUp = Scores_RED[i][1] - Scores_RED[(i - 1)][1];
				}else{
					if(amountOfPlayers[0] > 1)
					{
						Format(leading, sizeof(leading), "+");
						ptsToCatchUp = Scores_RED[i][1] - Scores_RED[(i + 1)][1];
					}
				}
				
				if(!(GetClientButtons(Scores_RED[i][0]) & IN_SCORE))
				{
					SetHudTextParams(0.05, 0.01, 5.0, 250, 250, 210, 255);
					ShowHudText(Scores_RED[i][0], HudMsg4, "%i%s | Score:%i (%s%i)", red_place, text , Scores_RED[i][1], leading, ptsToCatchUp);
				}
			}
		}
	}
	
	//do BLUE 2nd
	for (new i = 0; i < amountOfPlayers[1]; i++)
	{
		if(Scores_BLU[i][0] == 0)
			continue;
		
		if(IsClientInGame(Scores_BLU[i][0]))
		{
			ptsToCatchUp = 0;
			Format(leading, sizeof(leading), "");	
			
			blu_place ++;
			
			if(ScoreEnabled[Scores_BLU[i][0]] && !inTimerBasedRoll[Scores_BLU[i][0]] && client_rolls[Scores_BLU[i][0]][AWARD_G_BLIZZARD][4] == 0)
			{
				returnOrdinal(blu_place, text, sizeof(text));
				
				if(blu_place == amountOfPlayers[1])
					Format(text, sizeof(text), "%s (Last)",text);		
					
				if(blu_place > 1)
				{
					ptsToCatchUp = Scores_BLU[i][1] - Scores_BLU[(i - 1)][1];
				}else{
					if(amountOfPlayers[1] > 1)
					{
						Format(leading, sizeof(leading), "+");
						ptsToCatchUp = Scores_BLU[i][1] - Scores_BLU[(i + 1)][1];
					}
				}
				
				if(!(GetClientButtons(Scores_BLU[i][0]) & IN_SCORE))
				{
					SetHudTextParams(0.05, 0.01, 5.0, 250, 250, 210, 255);
					ShowHudText(Scores_BLU[i][0], HudMsg4, "%i%s | Score:%i (%s%i)", blu_place, text , Scores_BLU[i][1], leading, ptsToCatchUp);
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public returnOrdinal(n, String:text[], iSize)
{
	Format(text, iSize, "");
	
	switch(n % 10) 
	{
		case 1:
		Format(text, iSize, "st");
		
		case 2:
		Format(text, iSize, "nd");
		
		case 3:
		Format(text, iSize, "rd");
	}
	
	// Numbers from 11 to 13 don't have st, nd, rd
	if(n > 10 && n < 14) 
		Format(text, iSize, "th");

	if(StrEqual(text, ""))
		Format(text, iSize, "th");

}