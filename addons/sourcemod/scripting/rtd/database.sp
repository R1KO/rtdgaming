#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

openDatabaseConnection()
{
	new String:error[255];
	g_hDb = SQLite_UseDatabase("rtdcreditsbank", error, sizeof(error));
	
	//if (g_hDb == INVALID_HANDLE && !StrEqual(error, "not an error"))
	//	SetFailState("SQL error: %s", error);
}

public DBConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logPath,"Database failure: %s", error);
		PrintToServer("ERROR - Unable to connect to database");
		return;
	}
	
	g_hDb = hndl;
}
/*
public playerstimeupdateondb(client)
{
	//for some reason players are losing random values at disconnect
	//Sometime its Dice other times its credits
	//maybe moving up the priority que might solve this
	//Also testing storing global variables into local variables
	//maybe?
	
	//Updates the database credits
	//with the amount of RTDCredits the user has
	new tempCreds = RTDCredits[client];
	new tempDice = RTDdice[client];
	new tempOption1 = RTDOptions[client][0];
	new tempOption2 = RTDOptions[client][1];
	new tempOption3 = RTDOptions[client][2];
	new tempOption4 = RTDOptions[client][3];
	new Float:tempHUDxPos = HUDxPos[client];
	new Float:tempHUDyPos = HUDyPos[client];
	
	new String:ConUsrSteamID[MAX_LINE_WIDTH];
	ConUsrSteamID = SteamId[client];
	
	new String:query[512];
	Format(query, sizeof(query), "UPDATE Player SET CREDITS = '%i' WHERE STEAMID = '%s'", tempCreds ,ConUsrSteamID);
	SQL_TQuery(g_hDb,SQLErrorCheckCallback, query);
	
	Format(query, sizeof(query), "UPDATE Player SET DICEFOUND = '%i' WHERE STEAMID = '%s'", tempDice ,ConUsrSteamID);
	SQL_TQuery(g_hDb,SQLErrorCheckCallback, query);
	
	Format(query, sizeof(query), "UPDATE Player SET OPTION1 = '%i' WHERE STEAMID = '%s'", tempOption1, ConUsrSteamID);
	SQL_TQuery(g_hDb,SQLErrorCheckCallback, query);
	
	Format(query, sizeof(query), "UPDATE Player SET OPTION2 = '%i' WHERE STEAMID = '%s'", tempOption2, ConUsrSteamID);
	SQL_TQuery(g_hDb,SQLErrorCheckCallback, query);
	
	Format(query, sizeof(query), "UPDATE Player SET OPTION3 = '%i' WHERE STEAMID = '%s'", tempOption3, ConUsrSteamID);
	SQL_TQuery(g_hDb,SQLErrorCheckCallback, query);
	
	Format(query, sizeof(query), "UPDATE Player SET OPTION4 = '%i' WHERE STEAMID = '%s'", tempOption4, ConUsrSteamID);
	SQL_TQuery(g_hDb,SQLErrorCheckCallback, query);
	
	Format(query, sizeof(query), "UPDATE Player SET HUDXPOS = '%f' WHERE STEAMID = '%s'", tempHUDxPos, ConUsrSteamID);
	SQL_TQuery(g_hDb,SQLErrorCheckCallback, query);
	
	Format(query, sizeof(query), "UPDATE Player SET HUDYPOS = '%f' WHERE STEAMID = '%s'", tempHUDyPos, ConUsrSteamID);
	SQL_TQuery(g_hDb,SQLErrorCheckCallback, query);
}

*/

public InitializeClientonDB(client)
{
	new String:ConUsrSteamID[MAX_LINE_WIDTH];
	new String:userName[128];
	new String:buffer[255];
	if(!IsClientConnected(client))
		return;
	GetClientAuthString(client, ConUsrSteamID, sizeof(ConUsrSteamID));
	GetClientName(client, userName, sizeof(userName));
	SQL_EscapeString(db, userName, userName, sizeof(userName));
	if(strcmp(ConUsrSteamID, "BOT", false) == 0)
	{
		Format(ConUsrSteamID, sizeof(ConUsrSteamID), "%s-%s", ConUsrSteamID, userName);
	}
	//SteamId[client] = ConUsrSteamID;
	
	Format(buffer, sizeof(buffer), "SELECT CREDITS FROM Player WHERE STEAMID = '%s'", ConUsrSteamID);
	new conuserid;
	conuserid = GetClientUserId(client);

	SQL_TQuery(g_hDb, T_CheckConnectingUsr, buffer, conuserid)	;
}

public T_CheckConnectingUsr(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
	/* Make sure the client didn't disconnect while the thread was running */
	
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logPath,"Query failed on T_CheckConnectingUsr! %s", error);
	}else{
		
		new String:clientname[MAX_LINE_WIDTH];
		GetClientName( client, clientname, sizeof(clientname) );
		SQL_EscapeString(db, clientName, clientName, sizeof(clientName));
		new String:ClientSteamID[MAX_LINE_WIDTH];
		GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
		if(strcmp(ClientSteamID, "BOT", false) == 0)
		{
			Format(ClientSteamID, sizeof(ClientSteamID), "%s-%s", ClientSteamID, clientname);
		}
		new String:buffer[255];
		
		if (!SQL_GetRowCount(hndl)) 
		{
			//This is a new client! Save directly to cookies!
			if (AreClientCookiesCached(client))
				loadCookiesFor(client);
		}else{
			/*update name*/
			//no longer save to database, only read
			//Format(buffer, sizeof(buffer), "UPDATE Player SET NAME = '%s' WHERE STEAMID = '%s'", clientname, ClientSteamID);
			
			SQL_TQuery(g_hDb,SQLErrorCheckCallback, buffer);
			
			new clientpoints;
			while (SQL_FetchRow(hndl))
			{
				clientpoints = SQL_FetchInt(hndl,0);
				RTDCredits[client] = clientpoints;
				Format(buffer, sizeof(buffer), "SELECT DICEFOUND FROM Player WHERE STEAMID = '%s'", ClientSteamID);
				new conuserid;
				conuserid = GetClientUserId(client);
				SQL_TQuery(g_hDb, T_ShowrankConnectingUsr1, buffer, conuserid);
			}
		}
	}
}

public T_ShowrankConnectingUsr1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
 
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logPath,"Query failed! %s", error);
	}else{
		new rank;
		while (SQL_FetchRow(hndl))
		{
			rank = SQL_FetchInt(hndl,0);
			RTDdice[client] = rank;
			
			new String:buffer[255];
			new String:ClientSteamID[MAX_LINE_WIDTH];
			GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
			
			Format(buffer, sizeof(buffer), "SELECT OPTION1 FROM Player WHERE STEAMID = '%s'", ClientSteamID);
			new conuserid;
			conuserid = GetClientUserId(client);
			SQL_TQuery(g_hDb, T_ShowrankConnectingUsr2, buffer, conuserid);
		}
	}
}

public T_ShowrankConnectingUsr2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
 
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logPath,"Query failed! %s", error);
	}else{
		new rank;
		while (SQL_FetchRow(hndl))
		{
			rank = SQL_FetchInt(hndl,0);
			RTDOptions[client][0] = rank;
			
			new String:buffer[255];
			new String:ClientSteamID[MAX_LINE_WIDTH];
			GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
			
			Format(buffer, sizeof(buffer), "SELECT OPTION2 FROM Player WHERE STEAMID = '%s'", ClientSteamID);
			new conuserid;
			conuserid = GetClientUserId(client);
			SQL_TQuery(g_hDb, T_ShowrankConnectingUsr3, buffer, conuserid);
		}
	}
}

public T_ShowrankConnectingUsr3(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
 
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logPath,"Query failed! %s", error);
	}else{
		new rank;
		while (SQL_FetchRow(hndl))
		{
			rank = SQL_FetchInt(hndl,0);
			RTDOptions[client][1] = rank;
			
			new String:buffer[255];
			new String:ClientSteamID[MAX_LINE_WIDTH];
			GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
			
			Format(buffer, sizeof(buffer), "SELECT OPTION3 FROM Player WHERE STEAMID = '%s'", ClientSteamID);
			new conuserid;
			conuserid = GetClientUserId(client);
			SQL_TQuery(g_hDb, T_ShowrankConnectingUsr4, buffer, conuserid);
		}
	}
}

public T_ShowrankConnectingUsr4(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
 
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logPath,"Query failed! %s", error);
	}else{
		new rank;
		while (SQL_FetchRow(hndl))
		{
			rank = SQL_FetchInt(hndl,0);
			RTDOptions[client][2] = rank;
			
			new String:buffer[255];
			new String:ClientSteamID[MAX_LINE_WIDTH];
			GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
			
			Format(buffer, sizeof(buffer), "SELECT OPTION4 FROM Player WHERE STEAMID = '%s'", ClientSteamID);
			new conuserid;
			conuserid = GetClientUserId(client);
			SQL_TQuery(g_hDb, T_ShowrankConnectingUsr5, buffer, conuserid);
		}
	}
}

public T_ShowrankConnectingUsr5(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
 
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logPath,"Query failed! %s", error);
	}else{
		new rank;
		while (SQL_FetchRow(hndl))
		{
			rank = SQL_FetchInt(hndl,0);
			RTDOptions[client][3] = rank;
			
			new String:buffer[255];
			new String:ClientSteamID[MAX_LINE_WIDTH];
			GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
			
			Format(buffer, sizeof(buffer), "SELECT HUDXPOS FROM Player WHERE STEAMID = '%s'", ClientSteamID);
			new conuserid;
			conuserid = GetClientUserId(client);
			SQL_TQuery(g_hDb, T_ShowrankConnectingUsr6, buffer, conuserid);
		}
	}
}

public T_ShowrankConnectingUsr6(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
 
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logPath,"Query failed! %s", error);
	}else{
		new Float:rank;
		while (SQL_FetchRow(hndl))
		{
			rank = SQL_FetchFloat(hndl,0);
			HUDxPos[client] = rank;
			
			if(HUDxPos[client] == 0.0)
				HUDxPos[client] = 0.68;
			
			new String:buffer[255];
			new String:ClientSteamID[MAX_LINE_WIDTH];
			GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
			
			Format(buffer, sizeof(buffer), "SELECT HUDYPOS FROM Player WHERE STEAMID = '%s'", ClientSteamID);
			new conuserid;
			conuserid = GetClientUserId(client);
			SQL_TQuery(g_hDb, T_ShowrankConnectingUsr7, buffer, conuserid);
		}
	}
}

public T_ShowrankConnectingUsr7(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
 
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logPath,"Query failed! %s", error);
	}else{
		new Float:rank;
		while (SQL_FetchRow(hndl))
		{
			rank = SQL_FetchFloat(hndl,0);
			HUDyPos[client] = rank;
			
			if(HUDyPos[client] == 0.0)
				HUDyPos[client] = 0.97;
		}
	}
}

public GotDatabase(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logPath,"Database failure: %s", error);
	} else {
		g_hDb = hndl;
	}
}

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
		LogToFile(logPath,"SQL Error: %s", error);
	
}

createdb()
{
	createdbplayersqllite();
}

createdbplayersqllite()
{	
	new len = 0;
	decl String:query[10000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Player`");
	len += Format(query[len], sizeof(query)-len, " (`STEAMID` TEXT, `NAME` TEXT,");
	len += Format(query[len], sizeof(query)-len, "  `CREDITS` INTEGER,`DICEFOUND` INTEGER,'OPTION1' INTEGER,'OPTION2' INTEGER,'OPTION3' INTEGER,'OPTION4' INTEGER,'HUDXPOS' REAL,'HUDYPOS' REAL");
	len += Format(query[len], sizeof(query)-len, ");");
	
	SQL_LockDatabase(g_hDb);
	SQL_FastQuery(g_hDb, query);
	SQL_UnlockDatabase(g_hDb);
}
/*
public initonlineplayers()
{
	
	//new l_maxplayers;
	//l_maxplayers = GetMaxClients();
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			updateplayername(i);
			InitializeClientonDB(i);
		}
	}
}
* */

/*
public updateplayername(client)
{
	new String:steamId[MAX_LINE_WIDTH];
	GetClientAuthString(client, steamId, sizeof(steamId));
	new String:name[MAX_LINE_WIDTH];
	GetClientName( client, name, sizeof(name) );
	ReplaceString(name, sizeof(name), "'", "");
	ReplaceString(name, sizeof(name), "<?", "");
	ReplaceString(name, sizeof(name), "?>", "");
	ReplaceString(name, sizeof(name), "\"", "");
	ReplaceString(name, sizeof(name), "<?PHP", "");
	ReplaceString(name, sizeof(name), "<?php", "");
	new String:query[512];
	Format(query, sizeof(query), "UPDATE Player SET NAME = '%s' WHERE STEAMID = '%s'",name ,steamId);
	SQL_TQuery(g_hDb,SQLErrorCheckCallback, query);
}
*/

createdbtables()
{
	new len = 0;
	decl String:query[2048];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `data`");
	len += Format(query[len], sizeof(query)-len, "(`name` TEXT, `datatxt` TEXT, `dataint` INTEGER);");
	SQL_TQuery(g_hDb, T_CheckDBUptodate1, query);
}


public T_CheckDBUptodate1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logPath,"Query failed in T_CheckDBUptodate1! %s", error);
	} else {
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT dataint FROM `data` where `name` = 'dbversion'");
	SQL_TQuery(g_hDb, T_CheckDBUptodate2, buffer);
	}
	
}
public T_CheckDBUptodate2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logPath,"Query failed in T_CheckDBUptodate2! %s", error);
	} else {
		if (!SQL_GetRowCount(hndl)){
			LogToFile(logPath,"creating database!");
			createdb();
			new String:buffer[255];
			Format(buffer, sizeof(buffer), "INSERT INTO data (`name`,`dataint`) VALUES ('dbversion',%i)", DBVERSION);
			SQL_TQuery(g_hDb, SQLErrorCheckCallback, buffer);
		}else{
			new tmpdbversion;
			while (SQL_FetchRow(hndl))
			{
				tmpdbversion = SQL_FetchInt(hndl,0);
			}
			
			LogToFile(logPath,"tmpdbversion: %i",tmpdbversion);
			if (tmpdbversion == 4)
			{
				new String:buffer[255];
				Format(buffer, sizeof(buffer), "ALTER table Player add OPTION3 INTEGER;");
				SQL_TQuery(g_hDb, SQLErrorCheckCallback, buffer);
				
				Format(buffer, sizeof(buffer), "ALTER table Player add OPTION4 INTEGER;");
				SQL_TQuery(g_hDb, SQLErrorCheckCallback, buffer);
				
				Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 6 where `name` = 'dbversion'");
				SQL_TQuery(g_hDb,SQLErrorCheckCallback, buffer);
				
				Format(buffer, sizeof(buffer), "ALTER table Player add OPTION4 INTEGER;");
				SQL_TQuery(g_hDb, SQLErrorCheckCallback, buffer);
				
				Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 6 where `name` = 'dbversion'");
				SQL_TQuery(g_hDb,SQLErrorCheckCallback, buffer);
			}	
			
			if (tmpdbversion == 5)
			{
				new String:buffer[255];
				Format(buffer, sizeof(buffer), "ALTER table Player add OPTION4 INTEGER;");
				SQL_TQuery(g_hDb, SQLErrorCheckCallback, buffer);
				
				Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 6 where `name` = 'dbversion'");
				SQL_TQuery(g_hDb,SQLErrorCheckCallback, buffer);
			}
			
			if (tmpdbversion == 6)
			{
				new String:buffer[255];
				Format(buffer, sizeof(buffer), "ALTER table Player add HUDXPOS REAL;");
				SQL_TQuery(g_hDb, SQLErrorCheckCallback, buffer);
				
				Format(buffer, sizeof(buffer), "ALTER table Player add HUDYPOS REAL;");
				SQL_TQuery(g_hDb, SQLErrorCheckCallback, buffer);
				
				Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 7 where `name` = 'dbversion'");
				SQL_TQuery(g_hDb,SQLErrorCheckCallback, buffer);
			}
		}
		//initonlineplayers();
	}
}