

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"




new Handle:hDB;

stock War3SQLType:g_SQLType; //warning about variable not used...

// ConVar definitions
new Handle:m_SaveXPConVar;
new Handle:hSetRaceOnJoinCvar;

new Handle:m_AutosaveTime;
new Handle:hCvarPrintOnSave;

new Handle:g_OnWar3PlayerAuthedHandle;


public Plugin:myinfo= 
{
	name="SH Engine Database save xp",
	author="Ownz",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};

public bool:InitNativesForwards()
{	
	
	if(SH()){
		PrintToServer("SH MODE");
		//CreateNative("W3SaveXP" ,NW3SaveXP)
		CreateNative("SHSaveXP" ,NW3SaveXP);
		CreateNative("W3SaveEnabled" ,NW3SaveEnabled)
	}
	return true;
}

public OnPluginStart()
{
	if(SH()){
		m_SaveXPConVar=CreateConVar("sh_savexp","1");
		W3SetVar(hSaveEnabledCvar,m_SaveXPConVar);
			
		hSetRaceOnJoinCvar=CreateConVar("sh_set_race_on_join","1");
	
		m_AutosaveTime=CreateConVar("sh_autosavetime","60");
		hCvarPrintOnSave=CreateConVar("sh_print_on_autosave","0","Print a message to chat when xp is auto saved?");
	
		g_OnWar3PlayerAuthedHandle=CreateGlobalForward("OnWar3PlayerAuthed",ET_Ignore,Param_Cell,Param_Cell);

		
		CreateTimer(GetConVarFloat(m_AutosaveTime),DoAutosave);
	}
	
}

public NW3SaveXP(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	
	SH_SavePlayerData(client) //saves main also
}
public NW3SaveEnabled(Handle:plugin,numParams)
{
	return GetConVarInt(m_SaveXPConVar);
}













public OnWar3Event(W3EVENT:event,client){
	if(event==DatabaseConnected)
	{
		if(SH()){
			hDB=W3GetVar(hDatabase);
			g_SQLType=W3GetVar(hDatabaseType);
			
			Initialize_SQLTable();
		}
	}
}

Initialize_SQLTable()
{
	PrintToServer("[SH] Initialize_SQLTable");
	if(hDB!=INVALID_HANDLE)
	{
		// Check if the table exists
		SQL_LockDatabase(hDB); //non threading operations here, done once on plugin load only, not map change
		
		///shheroes
		new Handle:query=SQL_Query(hDB,"SELECT * from shheroes LIMIT 1");
		if(query!=INVALID_HANDLE){
			PrintToServer("[SH] Dropping shheroes and recreating it (normal)") ;
			SQL_FastQueryLogOnError(hDB,"DROP TABLE shheroes");
		}
		
		///always create table
		new String:longquery[4000];
		Format(longquery,4000,"CREATE TABLE shheroes (");
		Format(longquery,4000,"%s %s",longquery,"shortname varchar(16) UNIQUE,");
		Format(longquery,4000,"%s %s",longquery,"name  varchar(32)");
		
		for(new i=1;i<MAXSKILLCOUNT;i++){
			Format(longquery,4000,"%s, skill%d varchar(32)",longquery,i);
			Format(longquery,4000,"%s, skilldesc%d varchar(2000)",longquery,i);
		}
		
		Format(longquery,4000,"%s ) %s",longquery,War3SQLType:W3GetVar(hDatabaseType)==SQLType_MySQL?"DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci":"");
		SQL_FastQueryLogOnError(hDB,longquery);
		
		
		
		
		//main table
		query=SQL_Query(hDB,"SELECT * from shplayer LIMIT 1");
		if(query==INVALID_HANDLE) //table not exists
		{
			PrintToServer("[SH] TABLE shplayer not found, creating");
			new String:createtable[3000];
			Format(createtable,sizeof(createtable),"CREATE TABLE shplayer (steamid varchar(64) UNIQUE , name varchar(64), level int, xp int , heroeschosen varchar(1000),   timestamp TIMESTAMP) %s",War3SQLType:W3GetVar(hDatabaseType)==SQLType_MySQL?"DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci":"");
			if(!SQL_FastQueryLogOnError(hDB,createtable))
			{
				SetFailState("[SH] ERROR in the creation of the SQL table shplayer.");
			}   
		}
		else
		{	 //table exists, check for columns
			
			if(!SQL_FieldNameToNum(query, "heroeschosen", dummy))
			{
				AddColumn(hDB,"heroeschosen","varchar(1000)","shplayer");
				PrintToServer("[War3Source] Tried to ADD column heroeschosen in TABLE shplayer");
			}
			CloseHandle(query);
		}

		SQL_UnlockDatabase(hDB);
	}
	else
		PrintToServer("hDB invalid 123");
}


public Action:DoAutosave(Handle:timer,any:data)
{
	if(W3SaveEnabled())
	{
		for(new x=1;x<=MaxClients;x++)
		{
			if(ValidPlayer(x)&& W3IsPlayerXPLoaded(x))
			{
				SHSaveXP(x);
			}
		}
		if(GetConVarInt(hCvarPrintOnSave)>0){
			War3_ChatMessage(0,"Saving all player XP and updating stats.");
		}
		
	}
	CreateTimer(GetConVarFloat(m_AutosaveTime),DoAutosave);
}







//SAVING SECTION






//retrieve//retrieve

//retrieve

//retrieve
//retrieve
public OnClientPutInServer(client)
{
	if(SH()){
		W3SetPlayerProp(client,xpLoaded,false); //set race 0 may trigger unwanted behavior, block it first
		W3CreateEvent(InitPlayerVariables,client); 
		W3SetPlayerProp(client,xpLoaded,false);
		
//		W3CreateEvent(ClearPlayerVariables,client); 
		
		
		if(W3SaveEnabled())
		{
			War3_ChatMessage(client,"Loading player data...");
			SH_LoadPlayerData(client);
		}
		else{
			DoForwardOnWar3PlayerAuthed(client);
		}
		if(!W3SaveEnabled() || hDB==INVALID_HANDLE)
			W3SetPlayerProp(client,xpLoaded,true); // if db failed , or no save xp
	}
}
public OnClientDisconnect(client)
{
	if(SH()){
		if(W3SaveEnabled() && W3IsPlayerXPLoaded(client))
			SHSaveXP(client);
		
		W3SetPlayerProp(client,xpLoaded,false);
		W3CreateEvent(ClearPlayerVariables,client); 
	}
}





//SELECT STATEMENTS HERE
SH_LoadPlayerData(client) //war3source calls this
{
	//need space for steam id
	decl String:steamid[64];
	
	if(hDB && /*!IsFakeClient(client) && */GetClientAuthString(client,steamid,64)) // no bots and steamid
	{
		new String:longquery[4000];
		//Prepare select query for main data
		Format(longquery,256,"SELECT level,xp,heroeschosen FROM shplayer WHERE steamid='%s'",steamid);
		//Pass off to threaded call back at normal prority
		SQL_TQuery(hDB,T_CallbackSelectPDataMain,longquery,client);
		
		PrintToConsole(client,"[War3Source] XP retrieval query: sending MAIN request! Time: %.2f",GetGameTime());
		W3SetPlayerProp(client,sqlStartLoadXPTime,GetGameTime());
	}
}

public T_CallbackSelectPDataMain(Handle:owner,Handle:hndl,const String:error[],any:client)
{
	SQLCheckForErrors(hndl,error,"T_CallbackSelectPDataMain");
	
	if(!ValidPlayer(client))
		return;
	
	if(hndl==INVALID_HANDLE)
	{
		//Well the database is fucked up
		//TODO: add retry for select query
		LogError("[War3Source] ERROR: SELECT player data failed! Check DATABASE settings!");
		//Don't hang up the process for now
	}
	
	else
	{
		if(SQL_GetRowCount(hndl) == 1) 
		{
			SQL_Rewind(hndl);
			
			if(!SQL_FetchRow(hndl))
			{
				//This would be pretty fucked to occur here
				LogError("[War3Source] Unexpected error loading player data, could not FETCH row. Check DATABASE settings!");
				return;
			}
			else{
				//Get the gold from the query
				new level=W3SQLPlayerInt(hndl,"level");
				new xp=W3SQLPlayerInt(hndl,"xp");
				
				new String:heroeschosenstr[1000];
				W3SQLPlayerString(hndl,"heroeschosen",heroeschosenstr,sizeof(heroeschosenstr));
				
				
				SHSetLevel(client,level);
				SHSetXP(client,xp);
				
				if(GetConVarInt(hSetRaceOnJoinCvar)){
					new String:exploded[100][32];
					new count=ExplodeString(heroeschosenstr,",",exploded,100,32);
					for(new i=0;i<count;i++){
						new hero=War3_GetRaceIDByShortname(exploded[i]);
						if(hero>0){
							SHTryToGiveClientHero(client,hero,false);
						}
					}
				
				}
				
				PrintToConsole(client,"[War3Source] War3 MAIN retrieval: level %d xp %d heroes ''%s'' Time %.2f",level,xp,heroeschosenstr,GetGameTime());
				
				
				W3SetPlayerProp(client,RaceSetByAdmin,false);
				W3SetPlayerProp(client,xpLoaded,true);
				War3_ChatMessage(client,"XP loaded successfully");
				if(SHHasHeroesNum(client)<SHGetHeroesClientCanHave(client)){
					W3CreateEvent(SHSelectHeroesMenu,client);
				}
			}
		}
		else if(SQL_GetRowCount(hndl) == 0) //he doesnt exist, new player
		{
			//Not in database so add
			decl String:steamid[64];
			decl String:name[64];
			//get their name and steamid
			if(GetClientAuthString(client,steamid,64) && GetClientName(client,name,64)) // steamid
			{
				ReplaceString(name,63, "'","", true);//REMOVE IT//double escape because \\ turns into -> \  after the %s insert into sql statement
				
				new String:longquery[4000];
				// Main table query
				Format(longquery,4000,"INSERT INTO shplayer (steamid,name) VALUES ('%s','%s')",steamid,name);
				SQL_TQuery(hDB,T_CallbackInsertPDataMain,longquery,client);
				
				W3SetPlayerProp(client,RaceSetByAdmin,false);
				W3SetPlayerProp(client,xpLoaded,true);
				War3_ChatMessage(client,"Creating new XP entries");
				
				if(SHHasHeroesNum(client)<SHGetHeroesClientCanHave(client)){
					W3CreateEvent(SHSelectHeroesMenu,client);
				}
			}
			
		}
		else if(SQL_GetRowCount(hndl) >1)
		{
			// this is a WTF moment here
			//should probably purge these records and get the player to rejoin but I'm lazy
			//and don't want to write that
			LogError("[War3Source] Returned more than 1 record, primary or UNIQUE keys are screwed (main, rows: %d)",SQL_GetRowCount(hndl));
		}
	}
}


//we just tried inserting main data
public T_CallbackInsertPDataMain(Handle:owner,Handle:query,const String:error[],any:client)
{
	SQLCheckForErrors(query,error,"T_CallbackInsertPDataMain");
}






///SAVE
///SAVE
///SAVE
///SAVE
///SAVE
///SAVE
///SAVE
///SAVE
///SAVE









//saveing section
//save a race using new db style
SH_SavePlayerData(client)
{
	if(hDB && W3SaveEnabled() && W3GetPlayerProp(client,xpLoaded))
	{
		
		decl String:steamid[64];
		decl String:name[64];
		if(GetClientAuthString(client,steamid,64) && GetClientName(client,name,64))
		{
			new level=SHGetLevel(client);
			new xp=SHGetXP(client);
			
		
			new String:heroeschosenstr[1000];
			new num=0;
			for(new i=0;i<3;i++){
				if(SHGetPowerBind(client,i)>0){
					new hero=SHGetPowerBind(client,i);
					decl String:HeroName[32];
					SHGetHeroShortname(hero,HeroName,sizeof(HeroName));
					Format(heroeschosenstr,sizeof(heroeschosenstr),"%s%s%s",heroeschosenstr,num>0?",":"",HeroName);
					num++;
				}
			}
			for(new i=1;i<=War3_GetRacesLoaded();i++){
				if(SHHasHero(client,i)&&!SHGetHeroHasPowerBind(i)){
					decl String:HeroName[32];
					SHGetHeroShortname(i,HeroName,sizeof(HeroName));
					Format(heroeschosenstr,sizeof(heroeschosenstr),"%s%s%s",heroeschosenstr,num>0?",":"",HeroName);
					num++;
				}
			}
			new String:longquery[4000];
			Format(longquery,4000,"UPDATE shplayer SET level='%d',xp='%d',heroeschosen='%s' WHERE steamid='%s' ",level,xp,heroeschosenstr,steamid);
		
			PrintToConsole(client,"[War3Source] Saving XP : LVL %d XP %d",level,xp);
			
			SQL_TQuery(hDB,T_CallbackSavePlayerRace,longquery,client);
			
		}
	}
}
public T_CallbackSavePlayerRace(Handle:owner,Handle:hndl,const String:error[],any:client)
{
	SQLCheckForErrors(hndl,error,"T_CallbackSavePlayerRace");
}

DoForwardOnWar3PlayerAuthed(client){
	Call_StartForward(g_OnWar3PlayerAuthedHandle);
	Call_PushCell(client);
	Call_Finish(dummy);
}



