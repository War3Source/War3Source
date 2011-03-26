#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"

#pragma dynamic 10000

new war3statsversion = 2;


new reportBugDelayTracker[MAXPLAYERSCUSTOM];
new Handle:hSecondDBCvar;
new Handle:hShowError;


new Handle:hdatabase2;

new String:serverip[16];
new serverport;
new String:game[32];

//new Float:lastErrorTime;

new Float:lastserverinfoupdate;

new bool:collectwlstats; //win loss stats
new bool:collectkdstats;
public Plugin:myinfo= 
{
	name="War3Source Engine Statistics",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};




public OnPluginStart()
{	
	collectwlstats=true;
	collectkdstats=true;
	if(GetExtensionFileStatus("cssdm.ext",dummystr,sizeof(dummystr))>0){
		W3Log("NO WIN LOSS STATS WHEN CSDM IS RUNNING");
		collectwlstats=false;
	}
	
	if(War3_GetGame()==CS){

		if(!HookEventEx("round_end",War3Source_RoundOverEvent))
		{
			PrintToServer("[War3Source] Could not hook the round_end event.");
		}
	}
	else if(War3_GetGame()==Game_TF)
	{
		if(!HookEventEx("teamplay_round_win",War3Source_RoundOverEvent))
		{
			PrintToServer("[War3Source] Could not hook the teamplay_round_win event.");
			
		}
	}
	
	hSecondDBCvar=CreateConVar("war3_bug_to_my_db","0","send war3bug messages to your own database?");
	hShowError=CreateConVar("war3_stats_sql_error","0","LOG SQL errors from statistics plugin");
	
	CreateTimer(180.0,ManyMinTimer,_,TIMER_REPEAT);
	CreateTimer(1.0,ManyMinTimer);
	
	CreateTimer(1.0,ExecOnceTimer);
	
	CreateTimer(10.0,UpdateServerInfo,_,TIMER_REPEAT);
	CreateTimer(5.0,UpdateServerInfo);
	
	CreateTimer(60.0,MinuteTimer,_,TIMER_REPEAT);
	
	//CreateTimer(0.1,ProcessEvent,_,TIMER_REPEAT);
	//CreateTimer(1.1,ProcessEvent); //testings
	//showaggregateprocess=true;
	
	
	RegConsoleCmd("say",cmdsay);
	RegConsoleCmd("say_team",cmdsay);
	
	RegConsoleCmd("w3checkupdate",cmdcheckupdate);
	RegConsoleCmd("w3updateinfo",cmdupdatestatus);
	
	for(new i=1;i<=MaxClients;i++){
		reportBugDelayTracker[i]=War3_RegisterDelayTracker();
	}
	
	
	CreateTimer(3.0,ConnectSecondDB);//need configs to execute
	
	GetGameFolderName(game,32);

	return;
}


public bool:InitNativesForwards()
{
	CreateNative("W3GetStatsVersion",NW3GetStatsVersion);
	return true;
}
public NW3GetStatsVersion(Handle:plugin,numParams){
	return war3statsversion;
}
			

public Action:cmdcheckupdate(client,args){
	if(client==0){
		ManyMinTimer(INVALID_HANDLE,0);
	}
}
public Action:cmdupdatestatus(client,args){
	if(client==0){
		if(args==0){
			UpdateServerInfo(INVALID_HANDLE,0);
		}
		else{
			new String:argzs[6];
			GetCmdArg(1,argzs,sizeof(argzs));
			new int=StringToInt(argzs);
			PrintToServer("update %d times",int);
			for(new i=0;i<int;i++){
				UpdateServerInfo(INVALID_HANDLE,0);
			}
		
		}
	}
}


public OnMapStart(){
	
	new iIp = GetConVarInt(FindConVar("hostip"));
	Format(serverip, sizeof(serverip), "%i.%i.%i.%i", (iIp >> 24) & 0x000000FF,
	(iIp >> 16) & 0x000000FF,
	(iIp >>  8) & 0x000000FF,
	iIp         & 0x000000FF);
	//PrintToServer("%s",ip);
	
	serverport=GetConVarInt(FindConVar("hostport"));
	
	
	
	
	CreateTimer(1.0,PerMapQueries);
	
	lastserverinfoupdate=0.0;
}
	
public Action:PerMapQueries(Handle:h){
	
	
	
	
	
	new String:longquery[1000];	
	Format(longquery,sizeof(longquery),"w3stat/war3minver.php");
	W3Socket(longquery,SockCallbackMinVersion);
}
public SockCallbackMinVersion(bool:success,fail,String:ret[]){
	
	if(success){
		new String:exploded[2][32];
		ExplodeString(ret, "::", exploded, 2, 32);
		
		
		new minimum=StringToInt(exploded[1]);
		//PrintToServer("%s %d",exploded[1],minimum);
		if(W3GetW3Revision()<minimum){
			War3Failed("War3Source is out of date, please update war3source");
		}

	}
}


public Action:ManyMinTimer(Handle:h,any:a){
	
	new String:ourversion[32];
	W3GetW3Version(ourversion,32); //string version, only used to see if ours is beta etc
	
	new String:longquery[1000];	
	if(StrContains(ourversion, "b", false)>-1 || StrContains(ourversion, "rc", false)>-1 || StrContains(ourversion, "dev", false)>-1){
			
		Format(longquery,sizeof(longquery),"w3stat/latestbeta.php");
		W3Socket(longquery,SockCallbackVersion);
	}
	else{
		Format(longquery,sizeof(longquery),"w3stat/lateststable.php");
		W3Socket(longquery,SockCallbackVersion);
	}
}
public SockCallbackVersion(bool:success,fail,String:ret[]){
	new revour=W3GetW3Revision();
	if(success){
		new String:exploded[2][32];
		ExplodeString(ret, "::", exploded, 2, 32);
		
		
		new otherversion=StringToInt(exploded[1]);
		//PrintToServer("%s %d",exploded[1],otherversion);
		if(otherversion>revour){
			UpdateMsg();
		}

	}
}

UpdateMsg(){
	PrintToServer("A newer version of War3Source is available\nPlease download @ www.war3source.com");
	for(new i=1;i<=MaxClients;i++){
		if(ValidPlayer(i)){
			War3_ChatMessage(i,"%T","A newer version of War3Source is available",i);
			War3_ChatMessage(i,"%T","Please download @ www.war3source.com",i);
		}
	}
}




public Action:UpdateServerInfo(Handle:t,any:a){

	new String:hostname[64];
	GetConVarString(FindConVar("hostname"),hostname,64);
	PHPEscape(hostname,sizeof(hostname));
	
	new String:ourversion[32];
	W3GetW3Version(ourversion,32);
	
	new String:longquery[4000];
	new clientcount=0;
	for(new i=1;i<=MaxClients;i++){
		if(ValidPlayer(i)&&!IsFakeClient(i)){
			clientcount++;
		}
	}
	
	new String:mapname[64];
	GetCurrentMap(mapname,sizeof(mapname));
	Format(longquery,sizeof(longquery),"hostname=%s&version=%s&game=%s&map=%s&players=%d&MAXPLAYERSCUSTOM=%d&ip=%s:%d",hostname,ourversion,game,mapname,clientcount,MaxClients,serverip,serverport);
	
	W3Socket2("w3stat/serverinfo.php",longquery,SockCallbackServerInfo);
	//new Handle:trie=CreateTrie();
	//for(new i=0;i<100;i++){
	//	decl String:str[10];
	//	Format(str,sizeof(str),"z%d",i);
	//	SetTrieString(trie,str,longquery);
	//}
	
	//CreateTimer(1.0,handletest,trie);
}
public SockCallbackServerInfo(bool:success,fail,String:ret[]){
	//PrintToServer("%f suc%d fail%d %s",GetEngineTime(),success, fail,ret);
}
public Action:handletest(Handle:h,any:trie){
	PrintToServer("closing %d",trie);
	CloseHandle(Handle:trie);
}


public bool:OnClientConnect(client,String:rejectmsg[], maxlen){
	MayUpdateServerInfo();
	return true;
}
public OnClientPutInServer(client){
	MayUpdateServerInfo();
}

MayUpdateServerInfo(){
	if(GetGameTime()>lastserverinfoupdate+1){
		UpdateServerInfo(INVALID_HANDLE,0);
		lastserverinfoupdate=GetGameTime();
	}
}

public OnWar3PlayerAuthed(client){
	
		new String:name[32];
		GetClientName(client,name,sizeof(name));
		PHPEscape(name,sizeof(name));
		
		new String:hostname[64];
		GetConVarString(FindConVar("hostname"),hostname,sizeof(hostname));
		PHPEscape(hostname,sizeof(hostname));
		
		
		new String:steamid[32];
		GetClientAuthString(client,steamid,sizeof(steamid));
		
		new String:clientip[32];
		GetClientIP(client, clientip, sizeof(clientip));
		
		new String:longquery[4000];
		Format(longquery,sizeof(longquery),"w3stat/playerinfo.php?steamid=%s&name=%s&clientip=%s&hostname=%s&ipport=%s:%d&totallevels=%d",steamid,name,clientip,hostname,serverip,serverport,W3GetTotalLevels(client));
		W3Socket(longquery,SockCallbackPlayerInfo);
	
}
public SockCallbackPlayerInfo(suc,fail,String:buf[]){
	//PrintToServer(buf);
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
		KvGetString(keyValue,"database",database_connect,sizeof(database_connect),"default");
		decl String:error[256];	
		
		hdatabase2=SQL_Connect(database_connect,true,error,sizeof(error));
		
		if(!hdatabase2)
		{
			LogError("[War3Source] ERROR: hDB invalid handle, Check SourceMod database config, could not connect. ");
			LogError("ERRMSG:(%s)",error);
		}
		else{
			//SQL_TQuery(hdatabase,SQLTCallbackNone,"SET NAMES 'utf8'");
			SQL_TQuery(hdatabase2,SQLWar3GeneralCallback,"CREATE TABLE IF NOT EXISTS w3bugreport (steamid VARCHAR(64),	name  VARCHAR(64),	clientip VARCHAR(64),	hostname VARCHAR(64),	serverip VARCHAR(64),	version VARCHAR(64),	reportstring VARCHAR(1000) COLLATE utf8_unicode_ci,	time INT,	timestamp timestamp)");
		}
	}
}


public Action:cmdsay(client,args){
	decl String:arg1[666];
	GetCmdArg(1,arg1,666);
	
	if(CommandCheckStartsWith(arg1,"war3bug")){
		
		if(War3_TrackDelayExpired(reportBugDelayTracker[client])){
			
			
			if(strlen(arg1)<8){
				War3_ChatMessage(client,"%T ","Report a war3source bug: say war3bug <detailed description>",client);
			}
			else{
				FileBugReport(client,arg1[8]);
				War3_TrackDelay(reportBugDelayTracker[client],1.0);
				
			}
		}
		else{
			War3_ChatMessage(client,"%T","You cannot use war3bug again so soon",client);
		}
	}
}
public bool:CommandCheckStartsWith(String:compare[],String:lookingfor[]) {
	return StrContains(compare, lookingfor, false)==0;
}


FileBugReport(client,String:reportstr[]){
	
	PHPEscape(reportstr,strlen(reportstr));
	
	new String:name[32];
	GetClientName(client,name,sizeof(name));
	PHPEscape(name,sizeof(name));
	
	new String:hostname[64];
	GetConVarString(FindConVar("hostname"),hostname,sizeof(hostname));
	PHPEscape(hostname,sizeof(hostname));
	
	new String:steamid[32];
	GetClientAuthString(client,steamid,sizeof(steamid));
	
	new String:clientip[32];
	GetClientIP(client, clientip, sizeof(clientip));
	
	new String:version[32];
	W3GetW3Version(version,sizeof(version));

	
	new String:longquery[4000];
	
	ReplaceString(hostname,sizeof(hostname),"&","%%26");
	Format(longquery,sizeof(longquery),"w3stat/bugreport.php?steamid=%s&name=%s&clientip=%s&hostname=%s&serverip=%s:%d&version=%s&reportstr=%s",
	steamid,name,clientip,hostname,serverip,serverport,version,reportstr);
	
	W3Socket(longquery,SockCallbackBufReport);
	
	if(hdatabase2){
		Format(longquery,sizeof(longquery),"INSERT INTO w3bugreport SET steamid='%s' ,name='%s'  ,time='%d' , clientip='%s', hostname='%s',serverip='%s:%d' ,version='%s' ,reportstring='%s'",
		steamid,name,GetTime(),clientip,hostname,serverip,serverport,version,reportstr);
	
	
		
		SQL_TQuery(hdatabase2,SQLTCallbackFileBug,longquery,client);
	}

}
public SockCallbackBufReport(bool:success,bool:fail,String:str[]){

}

public Action:ExecOnceTimer(Handle:h){

	if(FindConVar("gs_zombiereloaded_version")!=INVALID_HANDLE){
		collectkdstats=false;
	}

	decl String:longquery[16000];
	
	
	
		
	new String:racename[64];
	new String:raceshort[16];
	new RacesLoaded = War3_GetRacesLoaded();
	for(new raceid=1;raceid<=RacesLoaded;raceid++){
	
		War3_GetRaceShortname(raceid,raceshort,sizeof(raceshort));
		
		new langnum=GetLanguageCount();
		new langengid=-1;
		//new bool:hasenglish=false;
		
		new bool:useserverlang;
		new bool:parseTransFile;
		for(new i=0;i<langnum;i++){
			decl String:langcode[32];
			decl String:langname[32];
			GetLanguageInfo(i, langcode, sizeof(langcode), langname, sizeof(langname));
			if(StrEqual(langcode,"en")){
		//		hasenglish=true;
				langengid=i;
				if(langengid==GetServerLanguage()){
					useserverlang=true;
					break;
				}
				else if(W3IsRaceTranslated(i)){
					parseTransFile=true;
					break;
				}
			}
		}
		//new bool:success=false;
		if(useserverlang){
			SetTrans( 0);
			War3_GetRaceName(raceid,racename,sizeof(racename));
			//success=true;
		}
		else if(parseTransFile){
			new Handle:keyValue=CreateKeyValues("Phrases");
			decl String:path[1024];
			new String:filename[128];
			Format(filename,sizeof(filename),"translations/w3s.race.%s.phrases.txt",raceshort);
			BuildPath(Path_SM,path,sizeof(path),filename);
			PrintToServer(path);
			FileToKeyValues(keyValue,path);
			// Load level configuration
			KvRewind(keyValue);
			
			//KvGetString(keyValue,"en",racename,sizeof(racename));
			//PrintToServer("en %s",racename);
			
			//new String:section[32];
			//KvGetSectionName(keyValue,section,sizeof(section));
			//PrintToServer("section %s",section);
			
			new String:keyracename[32];
			Format(keyracename,sizeof(keyracename),"%s_RaceName",raceshort);
			if(!KvJumpToKey(keyValue, keyracename)){
				PrintToServer("could not jump to key %s",keyracename);
			}
			//else{
			//	PrintToServer("success jump to key %s",keyracename);
			//}
			
			
			//KvGotoFirstSubKey(keyValue); //enter branch
			
			//KvGetSectionName(keyValue,section,sizeof(section));
			//PrintToServer("ur in section %s",section);
		
			//KvGetString(keyValue,"en",racename,sizeof(racename));
			//PrintToServer("en %s",racename);
			//if(strlen(racename)>0){
			//	success=true;
			//}
			
		}
		
		
		//no english? or no translations? send nothing as race
		Format(longquery,sizeof(longquery),"w3stat/raceinsertV2.php?racename=%s&raceshort=%s",racename,raceshort);

		W3Socket(longquery,RaceInsertCallback);
		
		
		
		
		
	}
	
	new String:hostname[64];
	GetConVarString(FindConVar("hostname"),hostname,64);
	PHPEscape(hostname,sizeof(hostname));
	new String:version[32];
	W3GetW3Version(version,sizeof(version));
	Format(longquery,sizeof(longquery),"ip=%s:%d&hostname=%s&version=%s",serverip,serverport,hostname,version);
	W3Socket2("w3stat/crashlog.php",longquery,CrashLogCallback);
	
	
	
	
	
	new Handle:cvarlist=W3CvarList();
	decl String:cvarstr[32];
	decl String:cvarvalue[32];
	decl String:concatstr[256];
	new limit=GetArraySize(cvarlist);
	Format(longquery,sizeof(longquery),"ip=%s:%d&config=",serverip,serverport);
	for(new i=0;i<limit;i++){
		GetArrayString(cvarlist,i,cvarstr,sizeof(cvarstr));
		W3GetCvarByString(cvarstr,cvarvalue,sizeof(cvarvalue));
		if(strlen(cvarvalue)>0){
			PHPEscape(cvarstr,sizeof(cvarstr));
			PHPEscape(cvarvalue,sizeof(cvarvalue));
			Format(concatstr,sizeof(concatstr),"%s=%s,",cvarstr,cvarvalue);
			StrCat(longquery,sizeof(longquery),concatstr);
			//PrintToServer("%s",concatstr);
		}
	}
	for(new i=0;i<limit;i++){
		GetArrayString(cvarlist,i,cvarstr,sizeof(cvarstr));
		W3GetCvarByString(cvarstr,cvarvalue,sizeof(cvarvalue));
		if(strlen(cvarvalue)>0){
			PHPEscape(cvarstr,sizeof(cvarstr));
			PHPEscape(cvarvalue,sizeof(cvarvalue));
			Format(concatstr,sizeof(concatstr),"%s=%s,",cvarstr,cvarvalue);
			StrCat(longquery,sizeof(longquery),concatstr);
			//PrintToServer("%s",concatstr);
		}
	}
	//PrintToServer("SOCKET CALL  %d %s",strlen(longquery),longquery);
	W3Socket2("w3stat/serverinfolong.php",longquery,GenericSocketCallback);
	CloseHandle(cvarlist);
	
	
	
	
	
	
	
	
	
	
	//RACES
	Format(longquery,sizeof(longquery),"ip=%s:%d&races=",serverip,serverport);
	for(new i=1;i<=RacesLoaded;i++){
		 War3_GetRaceShortname(i,raceshort,sizeof(raceshort));
		 PHPEscape(raceshort,sizeof(raceshort));
		 StrCat(longquery,sizeof(longquery),raceshort);
		 StrCat(longquery,sizeof(longquery),",");
	}
	W3Socket2("w3stat/serverinfolong.php",longquery,GenericSocketCallback);
	
	
	
	
	
	
	
	
	//ITEMS
	decl String:itemshort[16];
	Format(longquery,sizeof(longquery),"ip=%s:%d&items=",serverip,serverport);
	new ItemsLoaded = W3GetItemsLoaded();
	for(new i=1;i<=ItemsLoaded;i++){
		 W3GetItemShortname(i,itemshort,sizeof(itemshort));
		 PHPEscape(raceshort,sizeof(itemshort));
		 StrCat(longquery,sizeof(longquery),itemshort);
		 StrCat(longquery,sizeof(longquery),",");
	}
	W3Socket2("w3stat/serverinfolong.php",longquery,GenericSocketCallback);
	//PrintToServer("%s",longquery);
	
	
	
	
}
public RaceInsertCallback(bool:success,bool:fail,String:str[]){
	//PrintToServer(str);
}
public CrashLogCallback(bool:success,bool:fail,String:str[]){
	//PrintToServer(str);
}
public GenericSocketCallback(bool:success,bool:fail,String:str[]){
	//PrintToServer("serverinfolong %s",str);
}
public Action:MinuteTimer(Handle:h){
		
	decl String:longquery[4000];
	decl race;
	for(new i=1;i<=MaxClients;i++){
		if(ValidPlayer(i)&&!IsFakeClient(i)&&GetClientTeam(i)>1){
			race=War3_GetRace(i);
			if(race>0){
				decl String:steamid[32];
				GetClientAuthString(i,steamid,sizeof(steamid));
				
				decl String:raceshort[16];
				War3_GetRaceShortname(race,raceshort,sizeof(raceshort));
				
				//Format(longquery,sizeof(longquery),"INSERT INTO racedataeventsv2 SET steamid='%s' , raceshort='%s' , ipport='%s:%d' , event='timeplayed' , data1='1' , data2='%s'",steamid,raceshort,serverip,serverport,IsPlayerAlive(i)?"alive":"dead");
				//SQL_TQuery(hdatabase,SQLTCallbackNone,longquery,16000);
				
				Format(longquery,sizeof(longquery),"w3stat/timeplayed.php?steamid=%s&raceshort=%s&ip=%s:%d&game=%s&data1=%s&data2=%s",steamid,raceshort,serverip,serverport,game,"1",IsPlayerAlive(i)?"alive":"dead");

				W3Socket(longquery,SockCallbackKill);
				//PrintToServer("socketing %s",longquery);
				
			}
		}
	}
}
public OnWar3EventDeath(victim,attacker){
	if(collectkdstats&&(ValidPlayer(victim)&&ValidPlayer(attacker)&&War3_GetRace(victim)>0&&War3_GetRace(attacker)>0&&!IsFakeClient(victim)&&!IsFakeClient(attacker)&&victim!=attacker)){
		decl String:longquery[2000];
		decl String:raceshortatt[16];
		decl String:raceshortvic[16];
		decl String:steamid[32];
		decl String:victimsteamid[32];
		GetClientAuthString(attacker,steamid,sizeof(steamid));
		GetClientAuthString(victim,victimsteamid,sizeof(victimsteamid));
		new raceatt=War3_GetRace(attacker);
		new racevic=War3_GetRace(victim);
		War3_GetRaceShortname(raceatt,raceshortatt,16);
		War3_GetRaceShortname(racevic,raceshortvic,16);
		//Format(longquerydd,sizeof(longquery),"INSERT INTO racedataeventsv2 SET steamid='%s' , ipport='%s:%d' , raceshort='%s' , game='%s', event='kill' , data1='%s' , data2='%s',killerlvl='%d',victimlvl='%d'",steamid,serverip,serverport,raceshortatt,game,victimsteamid,raceshortvic,War3_GetLevel(attacker,raceatt),War3_GetLevel(victim,racevic));
		//SQL_TQuery(hdatabase,SQLTCallbackNone,longquerydd,160009);
	
		//GetClientAuthString(attacker,steamid,32);	
		//War3_GetRaceShortname(War3_GetRace(attacker),raceshort,16);
		//Format(longquery,sizeof(longquery),"UPDATE playerraces SET kills=kills+1 WHERE steamid='%s' AND ipport='%s:%d' AND raceshort='%s'",steamid,serverip,serverport,raceshort);
		//SQL_TQuery(hdatabase,SQLTCallbackNone,longquery);
		
		
		Format(longquery,sizeof(longquery),"w3stat/kill.php?steamid=%s&raceshort=%s&ip=%s:%d&game=%s&data1=%s&data2=%s&killerlvl=%d&victimlvl=%d",steamid,raceshortatt,serverip,serverport,game,victimsteamid,raceshortvic,War3_GetLevel(attacker,raceatt),War3_GetLevel(victim,racevic));
		
		W3Socket(longquery,SockCallbackKill);
		//PrintToServer("socketing %s",longquery);
	}
}
public SockCallbackKill(bool:success,fail,String:ret[]){
	//PrintToServer("%s",ret);
}


public War3Source_RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(collectwlstats&&   PlayersOnTeam(2)+PlayersOnTeam(3)>5){
		
	// cs - int winner
	// tf2 - int team
		new winteam=-1;
		if(War3_GetGame()==Game_TF)
		{
			winteam=GetEventInt(event,"team");
		}
		else
		{
			winteam=GetEventInt(event,"winner");
		}
		if(winteam>0)
		{
			//new losingteam=-2;
			//if(winteam==2){
			//	losingteam=3;
			//}
			//else if(winteam==3){
			//	losingteam=2;
			//}
			for(new i=1;i<=MaxClients;i++)
			{
				
				if(ValidPlayer(i) &&!IsFakeClient(i))
				{
					
					new race=War3_GetRace(i);
					if(race>0)
					{
						new clientteam=GetClientTeam(i);
						if(clientteam>1){
							decl String:longquery[4000];
						
							decl String:steamid[32];
							GetClientAuthString(i,steamid,sizeof(steamid));
							
							decl String:raceshort[16];
							War3_GetRaceShortname(race,raceshort,sizeof(raceshort));
					
							Format(longquery,sizeof(longquery),"w3stat/winlossV2.php?steamid=%s&raceshort=%s&game=%s&ip=%s:%d&win=%d&clientteam=%d&lvl=%d",steamid,raceshort,game,serverip,serverport,clientteam==winteam?1:0,clientteam,War3_GetLevel(i,race));
							W3Socket(longquery,SockCallbackWinLoss);
							//PrintToServer("%s",longquery);
						}
					}
				}
			}
		}
	}
}
public SockCallbackWinLoss(succ,fail,String:buf[]){
	//PrintToServer(buf);
}



public SQLTCallbackFileBug(Handle:owner,Handle:hndl,const String:error[],any:client){
	if(GetConVarInt(hShowError)){
		SQLCheckForErrors(hndl,error,"SQLTCallbackFileBug");
	}
	if(hndl==INVALID_HANDLE){
		if(ValidPlayer(client)){
			War3_ChatMessage(client,"%T","Could not file bug report, contact server owner",client);
		}
	}
	else{
		if(ValidPlayer(client)){
			War3_ChatMessage(client,"%T","Successfully filed bug report",client);
		}
	}
}



stock PHPEscape(String:str[],len){
	ReplaceString(str,len,"&","%26");
	ReplaceString(str,len,"#","%23");
	ReplaceString(str,len,"'","\'");
	ReplaceString(str,len," ","%20");
}
