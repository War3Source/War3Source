

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"









new Handle:hDB;
//new Handle:vecLevelConfiguration;
new String:sCachedDBIName[256];
new String:dbErrorMsg[512];

new War3SQLType:g_SQLType; 

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

public APLRes:AskPluginLoad2(Handle:myself,bool:late,String:error[],err_max)
{
	if(!InitNativesForwards())
	{
		LogError("[War3Source] There was a failure in creating the native / forwards based functions, definately halting.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}
bool:InitNativesForwards()
{	
	CreateNative("SHSaveXP" ,NW3SaveXP)
	if(SHEarly()){
		PrintToServer("SH MODE");
		CreateNative("W3SaveXP" ,NW3SaveXP)
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
public OnMapStart(){
	
}
public OnAllPluginsLoaded() //called once only, will not call again when map changes
{
	if(SH()){
		ConnectDB();
	}
	if(hDB){
		SH_SQLTable();
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
public NW3GetDBHandle(Handle:plugin,numParams)
{
	return _:hDB;
}















ConnectDB(){

	new Handle:keyValue=CreateKeyValues("War3SourceSettings");
	decl String:path[1024];
	BuildPath(Path_SM,path,sizeof(path),"configs/war3source.ini");
	FileToKeyValues(keyValue,path);
	// Load level configuration
	KvRewind(keyValue);
	new String:database_connect[256];
	KvGetString(keyValue,"database",database_connect,256,"default");
	decl String:error[256];
	strcopy(sCachedDBIName,256,database_connect);
	
	
	if(StrEqual(database_connect,"",false) || StrEqual(database_connect,"default",false))
	{
		hDB=SQL_DefConnect(error,256);	///use default connect, returns a handle...
	}
	else
	{
		hDB=SQL_Connect(database_connect,true,error,256);
	}
	if(!hDB)
	{
		LogError("[War3Source] ERROR: hDB invalid handle, Check SourceMod database config, could not connect. ");
		Format(dbErrorMsg,200,"ERR: Could not connect to DB. \n%s",error);
		LogError("ERRMSG:(%s)",error);
	}
	else
	{
		
		new String:driver_ident[64];
		SQL_ReadDriver(hDB,driver_ident,64);
		if(StrEqual(driver_ident,"mysql",false))
		{
			g_SQLType=SQLType_MySQL;
		}
		else if(StrEqual(driver_ident,"sqlite",false))
		{
			g_SQLType=SQLType_SQLite;
		}
		else
		{
			g_SQLType=SQLType_Unknown;
		}
		PrintToServer("[SH] SQL connection successful, driver %s",driver_ident);
		
		W3SetVar(hDatabase,hDB);
		W3SetVar(hDatabaseType,g_SQLType);
	}
	return true;
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







SH_SQLTable()
{
	PrintToServer("SH_SQLTable table check handling");
	if(hDB!=INVALID_HANDLE)
	{
		// Check if the table exists
		SQL_LockDatabase(hDB); //non threading operations here, done once on plugin load only, not map change
		
		//war3sourceraces
		PrintToServer("[SH] Dropping shheroes and recreating it (normal)") ;
		if(!SQL_FastQueryLogOnError(hDB,"DROP TABLE shheroes")){
			PrintToServer("[SH] Table: shheroes didnt exist or failed to drop it");
		}
		
		new String:longquery[4000];
		Format(longquery,4000,"CREATE TABLE shheroes (");
		Format(longquery,4000,"%s %s",longquery,"shortname varchar(16) UNIQUE,");
		Format(longquery,4000,"%s %s",longquery,"name  varchar(32)");
		
		for(new i=0;i<MAXSKILLCOUNT;i++){
			Format(longquery,4000,"%s, skill%d varchar(32)",longquery,i);
			Format(longquery,4000,"%s, skilldesc%d varchar(2000)",longquery,i);
		}
		
		Format(longquery,4000,"%s )",longquery);
		
		SQL_FastQueryLogOnError(hDB,longquery);
		
		
		
		
		//war3source main table
		new bool:dropandcreatetable=false;
		// Database conversion methods
		new Handle:query=SQL_Query(hDB,"SELECT * from shplayer LIMIT 1");
		
		
		if(query==INVALID_HANDLE)
		{   //query failed no result, re create table (table doesnt exist)
			dropandcreatetable=true;
		}
		else
		{	//ok table exists
			SQL_Rewind(query);
			//SQL_FetchRow(query);
			if(SQL_FetchRow(query))
			{
					//new count=SQL_GetFieldCount(query);
			
				///if column not there then add
				new dummyfield;
				if(!SQL_FieldNameToNum(query, "heroeschosen", dummyfield))
				{
					AddColumn(hDB,"heroeschosen","varchar(1000)","shplayer");
					PrintToServer("[War3Source] Tried to ADD column heroeschosen in TABLE shplayer");
				}
			}
			
			else{   ///zero rows, just drop and recreate
				dropandcreatetable=true;
			}
			CloseHandle(query);
		}
		
		
		
		if(dropandcreatetable)
		{
			PrintToServer("[SH] Dropping shplayer main table and recreating it!!!") ;
			SQL_FastQueryLogOnError(hDB,"DROP TABLE shplayer");
			if(!SQL_FastQueryLogOnError(hDB,"CREATE TABLE shplayer (steamid varchar(64) UNIQUE , name varchar(64), level int, xp int , heroeschosen varchar(1000),   timestamp TIMESTAMP)"  ))
			{
				SetFailState("[SH] ERROR in the creation of the SQL table shplayer.");
			}
		}
		
		
		/*
		
		///NEW DATABASE STRUCTURE
		new bool:createtablexpdata=false;
		query=SQL_Query(hDB,"SELECT * from war3source_racedata1 LIMIT 1");
		if(query==INVALID_HANDLE)
		{   
			//query failed no result, re create table (table doesnt exist)
			//best not to drop our xp rables
			PrintToServer("[War3Source] war3source_racedata1 doesnt exist or has no entries, recreating!!!") ;
			createtablexpdata=true;
			
		}
		//implement later to check for skill# columns
		else
		{	//ok table exists
			
			new String:columnname[16];
			new dummyfield;
			
			for(new i=0;i<MAXSKILLCOUNT;i++){
				Format(columnname,16,"skill%d",i);
				
				if(!SQL_FieldNameToNum(query, columnname , dummyfield))
				{
					AddColumn(hDB,columnname,"int","war3source_racedata1");
					PrintToServer("Tried to ADD column in TABLE %s: %s ","war3source_racedata1",columnname);
				}
				
			}
			CloseHandle(query);
		}
		if(createtablexpdata){
			
			//sqlite and mysql compatable
			
			//last_seen int
			new String:longquery2[4000];
			Format(longquery2,4000,"CREATE TABLE war3source_racedata1 (steamid varchar(64)  , raceshortname varchar(16),   level int,  xp int");
			
			
			for(new skillid=0;skillid<MAXSKILLCOUNT ;skillid++){
				Format(longquery2,4000,"%s, skill%d int ",longquery2,skillid);
			}
			Format(longquery2,4000,"%s, last_seen int)",longquery2);
			
			
			if(!SQL_FastQueryLogOnError(hDB,longquery2)
			||
			!SQL_FastQueryLogOnError(hDB,"CREATE UNIQUE INDEX steamid ON war3source_racedata1 (steamid,raceshortname)")
			)
			{
				SetFailState("[War3Source] ERROR in the creation of the SQL table war3source_racedata1");
			}
		}
		
		
		
		*/
		
		
		
		SQL_UnlockDatabase(hDB);
	}
	else
		PrintToServer("hDB invalid 123");
}

//SAVING SECTION






//retrieve//retrieve

//retrieve

//retrieve
//retrieve
public OnClientPutInServer(client)
{
	if(SH()){
		W3SetPlayerProp(client,xpLoaded,false);
		
		W3CreateEvent(ClearPlayerVariables,client); 
		
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



