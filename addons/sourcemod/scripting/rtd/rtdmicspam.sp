/** 
 * vim: set filetype=c :
 *
 * =============================================================================
 * Anti-Micspam
 *
 * Copyright 2008 Ryan Mannion. All Rights Reserved.
 * Copyright 2009-2010 Bor3d Gaming. All Rights Reserved.
 * =============================================================================
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1


/*
public Plugin:myinfo = {
    name = "Anti-Micspam",
    author = "FLOOR_MASTER and Bor3dGaming.com",
    description = "Automatically mute or punish players who engage in HLSS/HLDJ spamming with SourceBans integration",
    version = MICSPAMBG_VERSION,
    url = "http://www.bor3dgaming.com"
};
*/

new micspamTime[65];
new micSpamThreshold = 1; //every x seconds of micspam 1 credit is taken away
new bool:allowAdminsToMicSpam = true;

public Action:Timer_CheckAudio(Handle:timer, any:data) 
{
    new max_clients = GetMaxClients();

    for (new client = 1; client <= max_clients; client++) 
	{
		if (IsClientInGame(client) && !IsFakeClient(client)) 
		{
			QueryClientConVar(client, "voice_inputfromfile", CB_CheckAudio);
		}
    }
}

public CB_CheckAudio(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[]) 
{
    if (result == ConVarQuery_Okay && StringToInt(cvarValue) == 1 && !roundEnded && !inSetup) 
	{
		if (GetTime() - micspamTime[client] > micSpamThreshold) 
		{
			if (GetAdminFlag( GetUserAdmin( client) , REQ_ADMINFLAG ) && allowAdminsToMicSpam) 
				return;
			
			if(RTDCredits[client] < 3)
			{
				PrintHintText(client, "You don't have enough credits to MicSpam. You've been muted!");
				
				if(!(GetClientListeningFlags(client) & VOICE_MUTED))
					SetClientListeningFlags(client, VOICE_MUTED);
			}else{
				RTDCredits[client] -= 3;
				PrintHintText(client, "MicSpamming cost 3 credits/second");
				
				if(GetClientListeningFlags(client) & VOICE_MUTED)
					SetClientListeningFlags(client, VOICE_NORMAL);
			}
			
			micspamTime[client] = GetTime();
		}
    }else {
		micspamTime[client] = GetTime();
    }
}