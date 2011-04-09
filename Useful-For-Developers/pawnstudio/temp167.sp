#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"

#tryinclude "../War3Source_SQL_Password"

#if !defined _war3sqlpass
#include "PLEASE DO NOT COMPILE ENGINE_STATISTICS, USE PRECOMPILED .SMX" //error
#endif

///THIS FILE IS __NOT__ MEANT TO BE COMPILED BY END USERS.
///War3Source_SQL_Password is not distributed for security reasons
///THIS PLUGIN NOTIFIES YOU WHEN AN UPDATE (new version of war3source) IS AVAILABLE
///THIS PLUGIN ONLY COLLECTS PUBLIC STATS (like Game-Monitor) and war3source relates stats, we are not here to hack you. 
///This plugin allows you and war3source developers to recieve bug reports.
///In case you are wondering, War3Source_SQL_Password only contains one function: SetPassword(kv); which sets the mysql password.

new reportBugDelayTracker[MAXPLAYERS];
new Handle:hSecondDBCvar;

new Handle:hdatabase;
new Handle:hdatabase2;

new String:serverip[16];
new serverport;
new String:game[32];

//new bool:AggregateMode;
new bool:showaggregateprocess;
public Plugin:myinfo= 
{
	name="War3Source Engine Statistics",
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

public OnPluginStart()
{
	CreateTimer(180.0,ManyMinTimer,_,TIMER_REPEAT);
	CreateTimer(1.0,ManyMinTimer);
	CreateTimer(20.0,ExecOnceTimer);
	CreateTimer(60.0,MinuteTimer,_,TIMER_REPEAT);
	
	CreateTimer(0.1,ProcessEvent,_,TIMER_REPEAT);
	InitSQL(INVALID_HANDLE,0);
	
	RegConsoleCmd("say",cmdsay);
	RegConsoleCmd("say_team",cmdsay);
	
	RegConsoleCmd("w3checkupdate",cmdcheckupdate);
	
	for(new i=1;i<=MaxClients;i++){
		reportBugDelayTracker[i]=War3_RegisterDelayTracker();
	}
	
	hSecondDBCvar=CreateConVar("war3_bug_to_my_db","0","send war3bug messages to your own database?");
	CreateTimer(3.0,ConnectSecondDB);//need configs to execute
	
	GetGameFolderName(game,32);
	
	RegConsoleCmd("war3statsaggregate",cmdaggregate);
	RegConsoleCmd("showagg",cmdshowagg);
}


bool:InitNativesForwards()
{
	return true;
}
public Action:cmdaggregate(client,args){
	if(args==5){
		//AggregateMode=true;
		PrintToServer("war3statsaggregate enabled");
		CreateTimer(1.0,DangerAggregateLoop);
	}
}

public OnMapStart(){
	if(hdatabase==INVALID_HANDLE){
		InitSQL(INVALID_HANDLE,0);
	}
	else{
		//SQL_TQuery(hdatabase,SQLTCallbackNone,"UPDATE races SET kdr=CAST(kills as decimal)/CAST(deaths as decimal)");
	}

	new iIp = GetConVarInt(FindConVar("hostip"));
	Format(serverip, sizeof(serverip), "%i.%i.%i.%i", (iIp >> 24) & 0x000000FF,
	                                                    (iIp >> 16) & 0x000000FF,
	                                                    (iIp >>  8) & 0x000000FF,
	                                                    iIp         & 0x000000FF);
	//PrintToServer("%s",ip);
	
	serverport=GetConVarInt(FindConVar("hostport"));
}

public InitSQL(Handle:t,any:a){
	
 	new Handle:kv = CreateKeyValues("");
	KvSetString(kv, "driver", "mysql");
	KvSetString(kv, "host", "ownageclan.com");
	
	KvSetString(kv, "database", "set in War3Source_SQL_Password");
	KvSetString(kv, "user", "set in War3Source_SQL_Password");
	KvSetString(kv, "pass", "set in War3Source_SQL_Password");
	
	new bool:zdefined=false;
#if defined _war3sqlpass
	SetPassword(kv);
	zdefined=true;
#endif
	
	new String:error[500];
	hdatabase = SQL_ConnectCustom(kv, error, 500, false);
	if(hdatabase==INVALID_HANDLE){
		LogError("[W3 SQL Engine Statistics] %s",error);
		if(zdefined==true){
			//
		}
		else{
			War3Failed("User compiled Engine Statistics. Please use precompiled Engine Statistics");
		}
	}
	else{
		SQL_TQuery(hdatabase,SQLTCallbackNone,"SET NAMES 'utf8'");
	}
	CloseHandle(kv);
	
	////"timeout"			"0"
		//"port"			"0"


}

public Action:cmdcheckupdate(client,args){
	ManyMinTimer(INVALID_HANDLE,0);
}
public Action:cmdshowagg(client,args){
	showaggregateprocess=true;
}

new String:columnnamez[32];
public Action:ManyMinTimer(Handle:h,any:a){
	if(hdatabase){
	
		new String:ourversion[32];
		W3GetW3Version(ourversion,32);
		
		
		if(StrContains(ourversion, "b", false)>-1 || StrContains(ourversion, "rc", false)>-1 || StrContains(ourversion, "dev", false)>-1){
			Format(columnnamez,32,"latestbeta");
			SQL_TQuery(hdatabase,SQLTCallback,"SELECT latestbeta FROM w3releases LIMIT 1");
			
		}
		//else if(StrContains(ourversion, "rc", false)>-1){
		//	Format(columnnamez,32,"latestrc");
		//	SQL_TQuery(hdatabase,SQLTCallback,"SELECT latestrc FROM w3info LIMIT 1");
		//}
		else{
			Format(columnnamez,32,"lateststable");
			SQL_TQuery(hdatabase,SQLTCallback,"SELECT lateststable FROM w3releases LIMIT 1");
		}
		
		
	}
	ServerData();
}

///-1 = ignore, 0 or higher number = update
public SQLTCallback(Handle:owner,Handle:hndl,const String:error[],any:client){
	SQLCheckForErrors(hndl,error,"SQLTCallback1");
	if(hndl!=INVALID_HANDLE){
		SQL_Rewind(hndl);
		SQL_FetchRow(hndl);
		
		new String:otherversion[32];
		W3GetSQLResultString(hndl,columnnamez,otherversion,32);
		
		new revother=StringToInt(otherversion);
		new revour=W3GetW3Revision();
		
		if(revother==0 ||revother > revour){
			UpdateMsg();
		}
	/*	
		new String:ourversion[32];
		
		
		PrintToServer("our %s other %s",ourversion,otherversion);
		if(!StrEqual(otherversion,ourversion)){
			
		
			if(strlen(otherversion)<2){
				UpdateMsg();
			}
			else{
			
			
				
				new String:ourexplode[4][10];
				ExplodeString(ourversion,".",ourexplode,4,10);
				new String:otherexplode[4][10];
				ExplodeString(otherversion,".",otherexplode,4,10);
				
				for(new i=0;i<4;i++){
					PrintToServer("%s",ourexplode[i]);
				}
				
				new ourver[4];
				new otherver[4];
				new char;
				for(new i=0;i<4;i++){
					for(new j=0;j<10;j++){
						char=ourexplode[i][j];
						if(IsCharAlpha(char)){//StrContains(ourexplode[i][j], "b", false) >-1 || StrContains(ourexplode[i][j], "r", false)  >-1 || StrContains(ourexplode[i][j], "c", false)  >-1){
							continue;
						}
						else{
						
							ourver[i]=StringToInt(ourexplode[i][j]);
							PrintToServer("%d",ourver[i]);
							break;
						}
						
					}
					for(new j=0;j<10;j++){
						char=otherexplode[i][j];
						if(IsCharAlpha(char)){
							continue;
						}
						else{
							otherver[i]=StringToInt(otherexplode[i][j]);
							PrintToServer("%d",otherver[i]);
							break;
						}
					}
				}
				for(new i=0;i<4;i++){
					if(ourver[i]<otherver[i]){
						UpdateMsg();
					}
				}
			}
		}
		new bool:otherbeta;
		new bool:otherrc;
		if(StrContains(otherversion, "b", false)>-1){
			otherbeta=true;
		}
		if(StrContains(otherversion, "rc", false)>-1){
			otherrc=true;
		}
		
		
		
		
		if(*/
	}
}
UpdateMsg(){
	PrintToServer("A newer version of War3Source is available\nPlease download @ www.war3source.com");
	for(new i=1;i<=MaxClients;i++){
		if(ValidPlayer(i)){
			War3_ChatMessage(i,"A newer version of War3Source is available");
			War3_ChatMessage(i,"Please download @ www.war3source.com");
		}
	}
}




ServerData(){
	if(hdatabase){
		new String:hostname[64];
		GetConVarString(FindConVar("hostname"),hostname,64);
		
		new String:hostname2[164];
		SQL_EscapeString(hdatabase,hostname,hostname2,164);
		
		new String:ourversion[32];
		W3GetW3Version(ourversion,32);
		
		new String:longquery[4000];
		Format(longquery,4000,"REPLACE INTO serverinfo (hostname,version,ip,time) VALUES ('%s' ,'%s','%s:%d','%d')",hostname2,ourversion,serverip,serverport,GetTime());
		SQL_TQuery(hdatabase,SQLTCallbackNone,longquery);
		
	}
}



public OnWar3PlayerAuthed(client){
	if(hdatabase){//IsFakeClient(client)
		new String:name[32];
		new String:name2[66];
		GetClientName(client,name,32);
		SQL_EscapeString(hdatabase,name,name2,66);
				
		new String:hostname[64];
		GetConVarString(FindConVar("hostname"),hostname,64);
		
		new String:hostname2[164];
		SQL_EscapeString(hdatabase,hostname,hostname2,164);
		
		new String:steamid[32];
		GetClientAuthString(client,steamid,32);
		
		new String:clientip[32];
		GetClientIP(client, clientip, 32);
		new String:longquery[4000];
		
		//REPLACE statement is also fine
		Format(longquery,4000,"INSERT  INTO playerinfo SET steamid='%s' ,name='%s' , totallevels='%d' , lastseen='%d' , clientip='%s', hostname='%s',ipport='%s:%d' ",steamid,name2,W3GetTotalLevels(client),GetTime(),clientip,hostname2,serverip,serverport);
		Format(longquery,4000,"%s ON DUPLICATE KEY UPDATE  name='%s' , totallevels='%d' , lastseen='%d' , clientip='%s', hostname='%s' ",longquery,name2,W3GetTotalLevels(client),GetTime(),clientip,hostname2,serverip,serverport);
		SQL_TQuery(hdatabase,SQLTCallbackNone,longquery);
		
		Format(longquery,4000,"INSERT INTO playerinfounique SET steamid='%s' , name='%s', clientip='%s' , lastseen='%d', lastserverhostname='%s' , lastserveripport='%s:%d' ",steamid,name2,clientip,GetTime(),hostname2,serverip,serverport);
		Format(longquery,4000,"%s ON DUPLICATE KEY UPDATE  name='%s', clientip='%s' , lastseen='%d', lastserverhostname='%s' , lastserveripport='%s:%d' ",longquery,name2,clientip,GetTime(),hostname2,serverip,serverport);
		SQL_TQuery(hdatabase,SQLTCallbackNone,longquery);
	}
}

public Action:ConnectSecondDB(Handle:h){
	
	if(GetConVarInt(hSecondDBCvar)){

		new Handle:keyValue=CreateKeyValues("War3SourceSettings");
		decl String:path[1024];
		BuildPath(Path_SM,path,sizeof(path),"configs/war3source.ini");
		FileToKeyValues(keyValue,path);
		// Load level configuration
		KvRewind(keyValue);
		new String:database_connect[256];
		KvGetString(keyValue,"database",database_connect,256,"default");
		decl String:error[256];	
		
		hdatabase2=SQL_Connect(database_connect,true,error,256);
		
		if(!hdatabase2)
		{
			LogError("[War3Source] ERROR: DBIDB invalid handle, Check SourceMod database config, could not connect. ");
			LogError("ERRMSG:(%s)",error);
		}
		else{
			SQL_TQuery(hdatabase,SQLTCallbackNone,"SET NAMES 'utf8'");
			SQL_TQuery(hdatabase2,SQLTCallbackNone,"CREATE TABLE IF NOT EXISTS w3bugreport (steamid VARCHAR(64),	name  VARCHAR(64),	clientip VARCHAR(64),	hostname VARCHAR(64),	serverip VARCHAR(64),	version VARCHAR(64),	reportstring VARCHAR(1000) COLLATE utf8_unicode_ci,	time INT,	timestamp timestamp)");
		}
	}
}


public Action:cmdsay(client,args){
	decl String:arg1[666];
	GetCmdArg(1,arg1,666);
	
	if(CommandCheckStartsWith(arg1,"war3bug")){
	
		if(War3_TrackDelayExpired(reportBugDelayTracker[client])){
		
			
			if(strlen(arg1)<8){
				War3_ChatMessage(client,"report a war3source bug: say war3bug <detailed description> ");
			}
			else{
				FileBugReport(client,arg1[8]);
				War3_TrackDelay(reportBugDelayTracker[client],1.0);
				
			}
		}
		else{
			War3_ChatMessage(client,"You cannot use war3bug again so soon");
		}
	}
}
public bool:CommandCheckStartsWith(String:compare[],String:lookingfor[]) {
	return StrContains(compare, lookingfor, false)==0;
}


FileBugReport(client,String:str[]){
	
	new String:name[32];
	new String:name2[66];
	GetClientName(client,name,32);
	SQL_EscapeString(hdatabase,name,name2,66);
			
	new String:hostname[64];
	GetConVarString(FindConVar("hostname"),hostname,64);
	
	new String:hostname2[164];
	SQL_EscapeString(hdatabase,hostname,hostname2,164);
	
	new String:steamid[32];
	GetClientAuthString(client,steamid,32);
	
	new String:clientip[32];
	GetClientIP(client, clientip, 32);

	new String:version[32];
	W3GetW3Version(version,32);
	
	new String:report[2000];
	SQL_EscapeString(hdatabase,str,report,2000);

	new String:longquery[4000];
	Format(longquery,4000,"INSERT INTO w3bugreport SET steamid='%s' ,name='%s'  ,time='%d' , clientip='%s', hostname='%s',serverip='%s:%d' ,version='%s' ,reportstring='%s'",
	steamid,name2,GetTime(),clientip,hostname2,serverip,serverport,version,report);
	if(hdatabase){
		
		SQL_TQuery(hdatabase,SQLTCallbackFileBug,longquery,client);
	}
	if(hdatabase2){
		
		SQL_TQuery(hdatabase2,SQLTCallbackFileBug,longquery,client);
	}
	PrintToServer("%s",longquery);
	if(!hdatabase&&!hdatabase2){
		War3_ChatMessage(client,"Could not file bug report, database not connected");
	}
}


public Action:ExecOnceTimer(Handle:h){
	if(hdatabase){
		for(new i=1;i<=War3_GetRacesLoaded();i++){
			new String:longquery[4000];
			new String:racename[32];
			War3_GetRaceName(i,racename,32);
			new String:raceshort[16];
			War3_GetRaceShortname(i,raceshort,16);
			Format(longquery,4000,"REPLACE INTO races SET  racename='%s' , raceshort='%s'",racename,raceshort);
			SQL_TQuery(hdatabase,SQLTCallbackNone,longquery,999);
		}
	}
}
public Action:MinuteTimer(Handle:h){
	if(hdatabase){
		
		decl String:longquery[8000]; //nees to be long! lots of steamids!!
		Format(longquery,8000,"UPDATE playerinfounique SET timeplayed=timeplayed+1 WHERE ");
		new clientcount;
		for(new i=1;i<=MaxClients;i++){
			if(ValidPlayer(i)){
				clientcount++;
				decl String:steamid[32];
		
				GetClientAuthString(i,steamid,32);
			
				Format(longquery,8000,"%s %s steamid='%s' ",longquery,clientcount==1?"":"OR",steamid);
			
			}
		}
		if(clientcount>0){
			SQL_TQuery(hdatabase,SQLTCallbackNone,longquery);
	
	
		
		
			decl race;
			for(new i=1;i<=MaxClients;i++){
				if(ValidPlayer(i)&&!IsFakeClient(i)&&GetClientTeam(i)>1){
					race=War3_GetRace(i);
					if(race>0){
						decl String:steamid[32];
						GetClientAuthString(i,steamid,32);
						
						decl String:raceshort[16];
						War3_GetRaceShortname(race,raceshort,16);
						decl String:racename[32];
						War3_GetRaceName(race,racename,32);
						Format(longquery,4000,"INSERT INTO racedataevents SET steamid='%s' , raceshort='%s' , ipport='%s:%d' , event='timeplayed' , data1='1' , data2='%s'",steamid,raceshort,serverip,serverport,IsPlayerAlive(i)?"alive":"dead");
						SQL_TQuery(hdatabase,SQLTCallbackNone,longquery,9999);
					}
				}
			}
		}
	}
}
public OnWar3EventDeath(victim,attacker){
	if(ValidPlayer(victim)&&ValidPlayer(attacker)&&War3_GetRace(victim)>0&&War3_GetRace(attacker)>0&&!IsFakeClient(victim)&&!IsFakeClient(attacker)&&victim!=attacker){
		decl String:longquerydd[3000];
		decl String:raceshortatt[16];
		decl String:raceshortvic[16];
		decl String:steamid[32];
		decl String:victimsteamid[32];
		GetClientAuthString(attacker,steamid,32);
		GetClientAuthString(victim,victimsteamid,32);
		new raceatt=War3_GetRace(attacker);
		new racevic=War3_GetRace(victim);
		War3_GetRaceShortname(raceatt,raceshortatt,16);
		War3_GetRaceShortname(racevic,raceshortvic,16);
		Format(longquerydd,3000-1,"INSERT INTO racedataevents SET steamid='%s' , ipport='%s:%d' , raceshort='%s' , game='%s', event='kill' , data1='%s' , data2='%s',killerlvl='%d',victimlvl='%d'",steamid,serverip,serverport,raceshortatt,game,raceshortvic,victimsteamid,War3_GetLevel(attacker,raceatt),War3_GetLevel(victim,racevic));
		SQL_TQuery(hdatabase,SQLTCallbackNone,longquerydd,99999);
		
		//GetClientAuthString(attacker,steamid,32);	
		//War3_GetRaceShortname(War3_GetRace(attacker),raceshort,16);
		//Format(longquery,4000,"UPDATE playerraces SET kills=kills+1 WHERE steamid='%s' AND ipport='%s:%d' AND raceshort='%s'",steamid,serverip,serverport,raceshort);
		//SQL_TQuery(hdatabase,SQLTCallbackNone,longquery);
		
	}
}


public SQLTCallbackFileBug(Handle:owner,Handle:hndl,const String:error[],any:client){
	SQLCheckForErrors(hndl,error,"SQLTCallbackFileBug",client);
	if(hndl==INVALID_HANDLE){
		if(ValidPlayer(client)){
			War3_ChatMessage(client,"Could not file bug report, contact server owner");
		}
	}
	else{
		if(ValidPlayer(client)){
			War3_ChatMessage(client,"Successfully filed bug report");
		}
	}
}



public SQLTCallbackNone(Handle:owner,Handle:hndl,const String:error[],any:client){
	SQLCheckForErrors(hndl,error,"SQLTCallbackNone",client);
}
stock SQLCheckForErrors(Handle:hndl,const String:originalerror[],const String:prependstr[]="",any:client=0){
	if(!StrEqual("", originalerror))
		LogError("SQL error: [%s] (%d) %s", prependstr,client,originalerror);
	else if(hndl == INVALID_HANDLE)
	{
		decl String:err[512];
		SQL_GetError(hndl, err, sizeof(err));
		LogError("SQLCheckForErrors: [%s] (%d) %s", prependstr, client,err);
	}
}


W3SQLPlayerInt(Handle:query,const String:columnname[]) //fech from query
{
	new column;
	SQL_FieldNameToNum(query,columnname,column);
	decl String:result[16];
	SQL_FetchString(query,column,result,sizeof(result));
	return StringToInt(result);
}


W3GetSQLResultString(Handle:query,const String:columnname[],String:out_buffer[],size_out) //fech from query
{
	new column;
	if(SQL_FieldNameToNum(query,columnname,column))
	{
		SQL_FetchString(query,column,out_buffer,size_out);
		return true;
	}
	return false;
}
/*

public Action:DangerAggregateLoop2(Handle:t,any:a)
{
	SQL_LockDatabase(hdatabase);

	for(new i=0;i<1;i++){
		//PrintToServer("loop");
		new Handle:query=SQL_Query(hdatabase,"SELECT * FROM racedataevents WHERE processed='0' ORDER BY uni LIMIT 0,100");//OR timestamp < NOW()- INTERVAL 3 DAY - INTERVAL 1 HOUR LIMIT 0,1");
			
		if(query==INVALID_HANDLE)
		{   
			
		}
		else
		{	
			SQL_Rewind(query);
			while(SQL_MoreRows(query))
			{
				if(SQL_FetchRow(query))
				{
					
					decl String:steamid[32];
					decl String:raceshort[16];
					decl String:ipport[32];
					decl String:gamestr[32];
					decl String:event[32];
					decl String:data1[32];
					decl String:data2[32];
					decl killerlvl;
					decl victimlvl;
					decl String:timestamp[32];
					decl uni;
					decl bool:processed;
					W3GetSQLResultString(query,"steamid",steamid,32);
					W3GetSQLResultString(query,"raceshort",raceshort,16);
					W3GetSQLResultString(query,"ipport",ipport,32);
					W3GetSQLResultString(query,"game",gamestr,32);
					W3GetSQLResultString(query,"event",event,16);
					W3GetSQLResultString(query,"data1",data1,16);
					W3GetSQLResultString(query,"data2",data2,16);
					killerlvl=W3SQLPlayerInt(query,"killerlvl");
					victimlvl=W3SQLPlayerInt(query,"victimlvl");
					W3GetSQLResultString(query,"timestamp",timestamp,32);
					uni=W3SQLPlayerInt(query,"uni");
					//processed=bool:W3SQLPlayerInt(query,"processed");
					decl String:longquery[4000];
					
					new String:printtoserv[4000];
					if(StrEqual(event,"timeplayed",false)){
						
						decl String:aliveordead[16];
						Format(aliveordead,16,"%s",StrEqual(data2,"alive",false)?"alive":"dead");
						Format(longquery,4000,"INSERT INTO perplayerraceplaytime SET steamid='%s' , raceshort='%s' , time%s='1' ON DUPLICATE KEY UPDATE time%s=time%s+1",steamid,raceshort,aliveordead,aliveordead,aliveordead);
						StrCat(printtoserv,4000,longquery);
						StrCat(printtoserv,4000, " \n \n "); //want indent
						
						SQL_FastQueryLogOnError(hdatabase,longquery);	
					}
					if(StrEqual(event,"kill",false)){
						Format(longquery,4000,"UPDATE races SET totalkills=totalkills+1 WHERE raceshort='%s'",raceshort);
						StrCat(printtoserv,4000,longquery);
						StrCat(printtoserv,4000, " \n");
						SQL_FastQueryLogOnError(hdatabase,longquery);	
						
						Format(longquery,4000,"UPDATE races SET totaldeaths=totaldeaths+1 WHERE raceshort='%s'",data1);
						StrCat(printtoserv,4000,longquery);
						SQL_FastQueryLogOnError(hdatabase,longquery);	
						
						
						StrCat(printtoserv,4000, " \n \n "); //want indent
					}
					
					Format(longquery,4000,"UPDATE racedataevents SET processed='1' , timestamp='%s' WHERE uni='%d'",timestamp,uni);
					StrCat(printtoserv,4000,longquery);
					StrCat(printtoserv,4000,"\n \n \n");
					PrintToServer(printtoserv);
					SQL_FastQueryLogOnError(hdatabase,longquery);	
				}
			}
		}
	}
	
	SQL_FastQueryLogOnError(hdatabase,"DELETE FROM racedataevents WHERE event='timeplayed' AND processed='1'");
	
	SQL_UnlockDatabase(hdatabase);
	CreateTimer(0.1,DangerAggregateLoop2);
}
*/
public Action:DangerAggregateLoop(Handle:t,any:a)
{
	SQL_LockDatabase(hdatabase);

	for(new i=0;i<1;i++){
	
		new batchnum=100;
		//PrintToServer("loop");
		PrintToServer("%s:%d:%f",serverip,serverport,GetEngineTime());
		new Float:ff=GetEngineTime();
		new String:longbuf2[4000];
		Format(longbuf2,4000,"UPDATE racedataevents SET tobeprocessed='%f' WHERE tobeprocessed='0'  AND processed='0' AND (event='timeplayed' OR event='kill' ) ORDER BY uni LIMIT %d",ff,batchnum);
		new Handle:query=SQL_Query(hdatabase,longbuf2);
		if(query==INVALID_HANDLE)
		{   
			new String:error[256];
			SQL_GetError(hdatabase, error, 256);
			LogError("q failed, Error: %s",error);
		}
		else if(SQL_GetAffectedRows(hdatabase)){
			CloseHandle(query);
			
			Format(longbuf2,4000,"SELECT * from racedataevents WHERE tobeprocessed='%f' LIMIT %d",ff,batchnum);
			query=SQL_Query(hdatabase,longbuf2);
			if(query==INVALID_HANDLE)
			{   
				new String:error[256];
				SQL_GetError(hdatabase, error, 256);
				LogError("q failed, Error: %s",error);
			}
			else{		
				while(SQL_MoreRows(query)&&SQL_FetchRow(query))
				{
					decl String:steamid[32];
					decl String:raceshort[16];
					decl String:ipport[32];
					decl String:gamestr[32];
					decl String:event[32];
					decl String:data1[32];
					decl String:data2[32];
					decl killerlvl;
					decl victimlvl;
					decl String:timestamp[32];
					decl uni;
					decl bool:processed;
					W3GetSQLResultString(query,"steamid",steamid,32);
					W3GetSQLResultString(query,"raceshort",raceshort,16);
					W3GetSQLResultString(query,"ipport",ipport,32);
					W3GetSQLResultString(query,"game",gamestr,32);
					W3GetSQLResultString(query,"event",event,16);
					W3GetSQLResultString(query,"data1",data1,16);
					W3GetSQLResultString(query,"data2",data2,16);
					killerlvl=W3SQLPlayerInt(query,"killerlvl");
					victimlvl=W3SQLPlayerInt(query,"victimlvl");
					W3GetSQLResultString(query,"timestamp",timestamp,32);
					uni=W3SQLPlayerInt(query,"uni");
					processed=bool:W3SQLPlayerInt(query,"processed");
				
					
					decl String:longquery[4000];
					
					new String:printtoserv[4000];
					
					//SQL_FastQueryLogOnError(hdatabase,"BEGIN WORK");
					
					if(StrEqual(event,"timeplayed",false)){
						
						decl String:aliveordead[16];
						Format(aliveordead,16,"%s",StrEqual(data2,"alive",false)?"alive":"dead");
						Format(longquery,4000,"INSERT INTO perplayerraceplaytimelong SET steamid='%s' , raceshort='%s' , time%s='1' ON DUPLICATE KEY UPDATE time%s=time%s+1",steamid,raceshort,aliveordead,aliveordead,aliveordead);
						//StrCat(printtoserv,4000,longquery);
						//StrCat(printtoserv,4000, " \n \n \n"); //want indent
						//PrintToServer(longquery);
						SQL_FastQueryLogOnError(hdatabase,longquery);	
					}
					if(StrEqual(event,"kill",false)){
						Format(longquery,4000,"UPDATE perplayerraceplaytimelong SET kills=kills+1 WHERE raceshort='%s' AND steamid='%s'",raceshort,steamid);
						//StrCat(printtoserv,4000,longquery);
						//StrCat(printtoserv,4000, " \n");
						//PrintToServer(longquery);
						SQL_FastQueryLogOnError(hdatabase,longquery);	
						
						Format(longquery,4000,"UPDATE perplayerraceplaytimelong SET deaths=deaths+1 WHERE raceshort='%s' AND steamid='%s'",data1,data2);
						//StrCat(printtoserv,4000,longquery);
						//StrCat(printtoserv,4000, " \n");
						//PrintToServer(longquery);
						SQL_FastQueryLogOnError(hdatabase,longquery);
						
						Format(longquery,4000,"INSERT INTO raceplayerrecentkills SET steamid='%s',raceshort='%s', killerlvl='%d',victimrace='%s',victimlvl='%d', victimsteamid='%s',timestamp='%s'",steamid,raceshort,killerlvl,data1,victimlvl,data2,timestamp);
						//StrCat(printtoserv,4000,longquery);
						//StrCat(printtoserv,4000, " \n");
						//PrintToServer(longquery);
						SQL_FastQueryLogOnError(hdatabase,longquery);	
						
						
						//StrCat(printtoserv,4000, "\n "); //want indent
					}
					
					Format(longquery,4000,"UPDATE racedataevents SET processed='1' ,  tobeprocessed='0' WHERE uni='%d' AND tobeprocessed='%f'",uni,ff);
					//StrCat(printtoserv,4000,longquery);
					//StrCat(printtoserv,4000,"\n \n \n");
					//PrintToServer(printtoserv);
					//PrintToServer(longquery);
					PrintToServer("%d",uni);
					new Handle:query2=SQL_Query(hdatabase,longquery);
					if(query2==INVALID_HANDLE)
					{   
						new String:error[256];
						SQL_GetError(hdatabase, error, 256);
						LogError("q failed, Error: %s",error);
					}
					else if(SQL_GetAffectedRows(hdatabase)==0){
						PrintToServer("ERROR, uid changed by other server");
					}
					CloseHandle(query2);
					
				}
				CloseHandle(query);
			}
		}
	}
	//SET autocommit=0
	SQL_FastQueryLogOnError(hdatabase,"DELETE FROM racedataevents WHERE (event='kill' OR event='timeplayed' ) AND processed='1'");
	//SQL_FastQueryLogOnError(hdatabase,"COMMIT");
	SQL_UnlockDatabase(hdatabase);
	CreateTimer(0.1,DangerAggregateLoop);
}
public bool:SQL_FastQueryLogOnError(Handle:DB,const String:query[]){
	if(!SQL_FastQuery(DB,query)){
		new String:error[256];
		SQL_GetError(DB, error, 256);
		LogError("SQLFastQuery %s failed, Error: %s",query,error);
		return false;
	}
	return true;
}


new threadsinqueue;
public Action:ProcessEvent(Handle:t){
	if(hdatabase!=INVALID_HANDLE){
		//PrintToServer("queue %d",threadsinqueue);
		if(threadsinqueue==0){
			decl String:longbuf[4000];
			new batchnum=10;
				
			//PrintToServer("%s:%d:%f",serverip,serverport,GetEngineTime());
			new Float:ff=GetEngineTime();
			if(true){ //event='kill' OR 
			}
			Format(longbuf,4000,"UPDATE racedataevents SET tobeprocessed='%f' WHERE tobeprocessed='0'  AND processed='0' AND ( event='timeplayed' OR event='kill') ORDER BY uni LIMIT %d ",ff,batchnum); 
			threadsinqueue++;
			SQL_TQuery(hdatabase,SQLTProcessEventSelect,longbuf,_:ff);
		}
	}
}
public SQLTProcessEventSelect(Handle:owner,Handle:query,const String:error[],any:ff)
{
	threadsinqueue--;
	SQLCheckForErrors(query,error,"SQLTProcessEventSelect");
	if(query!=INVALID_HANDLE){
		decl String:longbuf[4000];
		Format(longbuf,4000,"SELECT * from racedataevents WHERE tobeprocessed='%f'",ff);
		threadsinqueue++;
		SQL_TQuery(hdatabase,SQLTProcessEventChange,longbuf,ff);
		PrintToServer("1");
	}
}	
	
	
public SQLTProcessEventChange(Handle:owner,Handle:query,const String:error[],any:ff)
{	
	PrintToServer("2");
	threadsinqueue--;
	if(query!=INVALID_HANDLE){
		SQL_Rewind(query);
		
		new aliveinserts;
		new deadinserts;
		decl String:timealiveinsertupdate[9999];
		decl String:timedeadinsertupdate[9999];
		Format(timealiveinsertupdate,9999,"INSERT INTO perplayerraceplaytimelong (steamid,raceshort,timealive) ");
		Format(timedeadinsertupdate,9999,"INSERT INTO perplayerraceplaytimelong (steamid,raceshort,timedead) ");
		
		new killstoinsert;
		decl String:KillInsertQuery[9999];
		Format(KillInsertQuery,9999,"UPDATE perplayerraceplaytimelong (steamid,raceshort,kills) ");
		new deathstoinsert;
		decl String:DeathInsertQuery[4000];
		Format(KillInsertQuery,9999,"UPDATE perplayerraceplaytimelong (steamid,raceshort,deaths) ");
		
		decl String:SetAsProcessedQuery[4000];
		new SetAsProcessedQueryNum;
		Format(SetAsProcessedQuery,4000,"UPDATE racedataevents SET processed='1' ,  tobeprocessed='0' WHERE tobeprocessed='%f' AND (",ff);
		
		//decl String:longquery[4000];
		
		while(SQL_MoreRows(query)&&SQL_FetchRow(query))
		{
			decl String:steamid[32];
			decl String:raceshort[16];
			decl String:ipport[32];
			decl String:gamestr[32];
			decl String:event[32];
			decl String:data1[32];
			decl String:data2[32];
			decl killerlvl;
			decl victimlvl;
			decl String:timestamp[32];
			decl uni;
			decl bool:processed;
			W3GetSQLResultString(query,"steamid",steamid,32);
			W3GetSQLResultString(query,"raceshort",raceshort,16);
			W3GetSQLResultString(query,"ipport",ipport,32);
			W3GetSQLResultString(query,"game",gamestr,32);
			W3GetSQLResultString(query,"event",event,16);
			W3GetSQLResultString(query,"data1",data1,16);
			W3GetSQLResultString(query,"data2",data2,16);
			killerlvl=W3SQLPlayerInt(query,"killerlvl");
			victimlvl=W3SQLPlayerInt(query,"victimlvl");
			W3GetSQLResultString(query,"timestamp",timestamp,32);
			uni=W3SQLPlayerInt(query,"uni");
			processed=bool:W3SQLPlayerInt(query,"processed");
		
			
			//new String:printtoserv[4000];
			
			//SQL_FastQueryLogOnError(hdatabase,"BEGIN WORK");
			
			if(StrEqual(event,"timeplayed",false)){
			
				new bool:alive=StrEqual(data2,"alive",false)?true:false;				
				if(alive){
					if(aliveinserts==0){
						Format(timealiveinsertupdate,9999,"%s VALUES('%s' ,'%s','1' )",timealiveinsertupdate,steamid,raceshort);
					}
					else{
						Format(timealiveinsertupdate,9999,"%s , ('%s' ,'%s','1' )",timealiveinsertupdate,steamid,raceshort);
					}
					aliveinserts++;
				}
				else{ //dead
					if(deadinserts==0){
						Format(timedeadinsertupdate,9999,"%s VALUES('%s' ,'%s','1' )",timedeadinsertupdate,steamid,raceshort);
					}
					else{
						Format(timedeadinsertupdate,9999,"%s , ('%s' ,'%s','1' )",timedeadinsertupdate,steamid,raceshort);
					}
					deadinserts++;
				}
		
			}
			if(StrEqual(event,"kill",false)){
				
				if(killstoinsert==0){
					Format(KillInsertQuery,9999,"%s VALUES('%s' ,'%s','1' )",KillInsertQuery,steamid,raceshort);
				}
				else{
					Format(KillInsertQuery,9999,"%s , ('%s' ,'%s','1' )",KillInsertQuery,steamid,raceshort);
				}
				killstoinsert++;
				
				if(deathstoinsert==0){
					Format(DeathInsertQuery,9999,"%s VALUES('%s' ,'%s','1' )",DeathInsertQuery,steamid,raceshort);
				}
				else{
					Format(DeathInsertQuery,9999,"%s , ('%s' ,'%s','1' )",DeathInsertQuery,steamid,raceshort);
				}
				deathstoinsert++;
				
				
				
				/*
				
				
				Format(longquery,4000,"UPDATE perplayerraceplaytimelong SET kills=kills+1 WHERE raceshort='%s' AND steamid='%s'",raceshort,steamid);
				//StrCat(printtoserv,4000,longquery);
				//StrCat(printtoserv,4000, " \n");
				//PrintToServer(longquery);
				threadsinqueue++;
				SQL_TQuery(hdatabase,SQLTProcessEventEnd,longquery);
				
				Format(longquery,4000,"UPDATE perplayerraceplaytimelong SET deaths=deaths+1 WHERE raceshort='%s' AND steamid='%s'",data1,data2);
				//StrCat(printtoserv,4000,longquery);
				//StrCat(printtoserv,4000, " \n");
				//PrintToServer(longquery);
				threadsinqueue++;
				SQL_TQuery(hdatabase,SQLTProcessEventEnd,longquery);
				
				Format(longquery,4000,"INSERT INTO raceplayerrecentkills SET steamid='%s',raceshort='%s', killerlvl='%d',victimrace='%s',victimlvl='%d', victimsteamid='%s',timestamp='%s'",steamid,raceshort,killerlvl,data1,victimlvl,data2,timestamp);
				//StrCat(printtoserv,4000,longquery);
				//StrCat(printtoserv,4000, " \n");
				//PrintToServer(longquery);
				threadsinqueue++;
				SQL_TQuery(hdatabase,SQLTProcessEventEnd,longquery);
				
				
				//StrCat(printtoserv,4000, "\n "); //want indent*/
			}
			
			if(SetAsProcessedQueryNum==0){
				Format(SetAsProcessedQuery,4000,"%s uni='%d' ",SetAsProcessedQuery,uni);
			}
			else{
				Format(SetAsProcessedQuery,4000,"%s OR uni='%d' ",SetAsProcessedQuery,uni);
			}
			
			//if(showaggregateprocess) { 
			PrintToServer("%d",uni);
			//}
			SetAsProcessedQueryNum++;
			
		}
		Format(SetAsProcessedQuery,4000,"%s )",SetAsProcessedQuery);
		
		
		if(aliveinserts>0){
			Format(timealiveinsertupdate,9999,"%s ON DUPLICATE KEY UPDATE timealive=timealive+1",timealiveinsertupdate);
			threadsinqueue++;
			PrintToServer("%s",timealiveinsertupdate);
			SQL_TQuery(hdatabase,SQLTProcessEventEnd,timealiveinsertupdate);
		}
		if(deadinserts>0){
			Format(timedeadinsertupdate,9999,"%s ON DUPLICATE KEY UPDATE timedead=timedead+1",timedeadinsertupdate);
			
			PrintToServer("%s",timedeadinsertupdate);
			threadsinqueue++;
			SQL_TQuery(hdatabase,SQLTProcessEventEnd,timedeadinsertupdate);
		}
		
		
		
		
		//StrCat(printtoserv,4000,longquery);
		//StrCat(printtoserv,4000,"\n \n \n");
		//PrintToServer(printtoserv);
		//PrintToServer(longquery);
		if(SetAsProcessedQueryNum>0){
			threadsinqueue++;
			SQL_TQuery(hdatabase,SQLTProcessEventEnd,SetAsProcessedQuery);
		}
		
	}
	
	
}

public SQLTProcessEventEnd(Handle:owner,Handle:query,const String:error[],any:ff)
{
	PrintToServer("3");
	threadsinqueue--;
	SQLCheckForErrors(query,error,"SQLTProcessEventEnd");
	//if(SQL_GetAffectedRows(query)==0){
	//	PrintToServer("SQLTProcessEventEnd, no rows affected, ERROR, uid changed by other server");
	//}
}




//threaded shit