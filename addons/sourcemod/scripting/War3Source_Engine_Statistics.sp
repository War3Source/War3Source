#pragma semicolon 1
#pragma dynamic 20000

#include <sourcemod>
#include "sdkhooks"
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Statistics",
    author = "War3Source Team",
    description = "Collect statistics and send them to Ownz"
};

new war3statsversion = 2;


new reportBugDelayTracker[MAXPLAYERSCUSTOM];
new Handle:hSecondDBCvar;
new Handle:hShowSocketError;


new Handle:hdatabase2;

new String:serverip[16];
new serverport;
new String:game[32];


//new Float:lastErrorTime;

new Float:lastserverinfoupdate;

new bool:collectwlstats; //win loss stats
new bool:collectkdstats;

new Handle:hUpdateTimer;
new Handle:hCollectingStats;

#define bCollectStats GetConVarBool(hCollectingStats )

new Handle:GameAndServerKDR;

public OnPluginStart()
{    
    //just always create it, so we can always close it
    
    GameAndServerKDR=CreateTrie();
    hCollectingStats = CreateConVar("war3_enable_stat_collection", "1", "0/1. Controls if K/D and W/L stats should be collected");
    //HookConVarChange(hCollectingStats, StatCollectionCallback);
    
    collectwlstats=true;
    collectkdstats=true;
    if(GetExtensionFileStatus("cssdm.ext",dummystr,sizeof(dummystr))>0){
        War3_LogInfo("NO WIN LOSS STATS WHEN CSDM IS RUNNING");
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
    hShowSocketError=CreateConVar("war3_show_sockets_error","0","show socket errors");
    
    CreateTimer(180.0,ManyMinTimer,_,TIMER_REPEAT);
    CreateTimer(1.0,ManyMinTimer);
    
    CreateTimer(1.0,ExecOnceTimer);
    
    
    hUpdateTimer=CreateTimer(5.0,UpdateServerInfo,_,TIMER_REPEAT);
    
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
    
    RegConsoleCmd("w3hyperupdate",cmdhyperupdate);
    RegConsoleCmd("w3hyperupdate2",cmdhyperupdate2);
    return;
}




public bool:InitNativesForwards()
{
    CreateNative("W3GetStatsVersion",NW3GetStatsVersion);
    CreateNative("W3GetStatsKDRTrie",NW3GetStatsKDRTrie);
    return true;
}
public NW3GetStatsVersion(Handle:plugin,numParams){
    return war3statsversion;
}
public NW3GetStatsKDRTrie(Handle:plugin,numParams){
    return any:GameAndServerKDR;
}

public Action:cmdcheckupdate(client,args){
    if(client==0){
        ManyMinTimer(INVALID_HANDLE,0);
        
    }
    return Plugin_Handled;
}
public Action:cmdupdatestatus(client,args){
    if(client==0){
        if(args==0){
            UpdateServerInfo(INVALID_HANDLE,0);
        }
        else{
            new String:argzs[6];
            GetCmdArg(1,argzs,sizeof(argzs));
            new intval=StringToInt(argzs);
            PrintToServer("update %d times",intval);
            for(new i=0;i<intval;i++){
                UpdateServerInfo(INVALID_HANDLE,0);
            }
            
        }
    }
}
public Action:cmdhyperupdate(client,args){
    if(args>0&&client==0){
        CloseHandle(hUpdateTimer);
        
        new String:argzs[6];
        GetCmdArg(1,argzs,sizeof(argzs));
        new Float:updateinterval=StringToFloat(argzs);
        PrintToServer("update interval %f ",updateinterval);
        hUpdateTimer=CreateTimer(updateinterval,UpdateServerInfo,_,TIMER_REPEAT);
    }
}
public Action:cmdhyperupdate2(client,args){
    if(client==0){
        for(new i=0;i<3000;i++){
            UpdateServerInfo(Handle:0,0);
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


public Action:PerMapQueries(Handle:h)
{
    W3Socket("w3stat/war3minver.php", SockCallbackMinVersion);
}

public SockCallbackMinVersion(bool:success,fail,String:ret[])
{
    /*
    if(success){
        new String:exploded[2][32];
        ExplodeString(ret, "::", exploded, 2, 32);
        
        
        new minimum=StringToInt(exploded[1]);
        //PrintToServer("%s %d",exploded[1],minimum);
        if(W3GetW3Revision() < minimum)
        {
            War3Failed("War3Source is out of date, please update war3source");
        }
    }
    */
}


public Action:ManyMinTimer(Handle:h,any:a){
    
    new String:ourversion[32];
    W3GetW3Version(ourversion,32); //string version, only used to see if ours is beta etc
    
    if(StrContains(ourversion, "b", false)>-1 || StrContains(ourversion, "rc", false)>-1 || StrContains(ourversion, "dev", false)>-1)
    {
        W3Socket("w3stat/latestbeta.php",SockCallbackVersion);
    }
    else
    {
        W3Socket("w3stat/lateststable.php",SockCallbackVersion);
    }
    UpdateKDR();
}


public SockCallbackVersion(bool:success,fail,String:ret[]){
    /*
    new revour=W3GetW3Revision();
    if(success){
        new String:exploded[2][32];
        ExplodeString(ret, "::", exploded, 2, 32);
        
        new otherversion=StringToInt(exploded[1]);
        if(otherversion>revour){
            UpdateMsg();
        }
    }
    */
}


/*
UpdateMsg(){
    PrintToServer("A newer version of War3Source is available\nPlease download @ www.war3source.com");
    for(new i=1;i<=MaxClients;i++){
        if(ValidPlayer(i)){
            War3_ChatMessage(i,"%T","A newer version of War3Source is available",i);
            War3_ChatMessage(i,"%T","Please download @ www.war3source.com",i);
        }
    }
}
*/



public Action:UpdateServerInfo(Handle:t,any:a){
    
    decl String:hostname[1000];
    GetConVarString(FindConVar("hostname"),hostname,sizeof(hostname));
    URLEncode(hostname,sizeof(hostname));
    
    decl String:ourversion[1000];
    W3GetW3Version(ourversion,sizeof(ourversion));
    URLEncode(ourversion,sizeof(ourversion));
    
    decl String:longquery[1000];
    new clientcount=0;
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i)&&!IsFakeClient(i))
        {
            clientcount++;
        }
    }
    
    decl String:mapname[1000];
    GetCurrentMap(mapname,sizeof(mapname));
    URLEncode(mapname, sizeof(mapname));
    
    decl String:gameencoded[1000];
    Format(gameencoded, sizeof(gameencoded), "%s", game);
    URLEncode(gameencoded, sizeof(gameencoded));
    
    decl String:ipencoded[1000];
    Format(ipencoded, sizeof(ipencoded), "%s", serverip);
    URLEncode(ipencoded, sizeof(ipencoded)); // should work now :D
    
    // This URL follows URLEncode() standards.
    Format(longquery,sizeof(longquery),"hostname=%s&version=%s&game=%s&map=%s&players=%d&maxplayers=%d&ip=%s:%d",hostname,ourversion,gameencoded,mapname,clientcount,MaxClients,ipencoded,serverport);
    
    W3Socket2("w3stat/serverinfo.php",longquery,SockCallbackServerInfo);
    
    
}
public SockCallbackServerInfo(bool:success,fail,String:ret[])
{
}


public bool:OnClientConnect(client,String:rejectmsg[], maxlen)
{
    MayUpdateServerInfo();
    return true;
}
public OnClientPutInServer(client)
{
    MayUpdateServerInfo();
}

MayUpdateServerInfo(){
    if(GetGameTime()>lastserverinfoupdate+1){
        UpdateServerInfo(INVALID_HANDLE,0);
        lastserverinfoupdate=GetGameTime();
    }
}

public OnWar3PlayerAuthed(client)
{
    
    new String:name[1000];
    GetClientName(client,name,sizeof(name));
    URLEncode(name,sizeof(name));
    
    new String:hostname[1000];
    GetConVarString(FindConVar("hostname"),hostname,sizeof(hostname));
    URLEncode(hostname,sizeof(hostname));
    
    
    new String:steamid[1000];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
    URLEncode(steamid, sizeof(steamid));
    
    new String:clientip[1000];
    GetClientIP(client, clientip, sizeof(clientip));
    URLEncode(clientip, sizeof(clientip));
    
    new String:longquery[1000];
    Format(longquery,sizeof(longquery),"w3stat/playerinfo.php?steamid=%s&name=%s&clientip=%s&hostname=%s&ipport=%s:%d&totallevels=%d",steamid,name,clientip,hostname,serverip,serverport,W3GetTotalLevels(client));
    W3Socket(longquery,SockCallbackPlayerInfo);
    
}
public SockCallbackPlayerInfo(suc,fail,String:buf[])
{
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
            SQL_TQuery(hdatabase2,SQLWar3GeneralCallback,"CREATE TABLE IF NOT EXISTS w3bugreport (steamid VARCHAR(64),    name  VARCHAR(64),    clientip VARCHAR(64),    hostname VARCHAR(64),    serverip VARCHAR(64),    version VARCHAR(64),    reportstring VARCHAR(1000) COLLATE utf8_unicode_ci,    time INT,    timestamp timestamp)");
        }
    }
}


public Action:cmdsay(client,args){
    decl String:arg1[200];
    GetCmdArg(1,arg1,sizeof(arg1));
    
    if(CommandCheckStartsWith(arg1,"war3bug"))
    {
        if(War3_TrackDelayExpired(reportBugDelayTracker[client]))
        {
            //DP("%s",arg1);
            if(strlen(arg1)<9)
            {
                War3_ChatMessage(client,"%T ","Report a war3source bug: say war3bug <detailed description>",client);
            }
            else
            {
                FileBugReport(client,arg1[8]);
                War3_ChatMessage(client,"Reported: %s",arg1[8]);
                War3_TrackDelay(reportBugDelayTracker[client],10.0); //10 second delay
            }
        }
        else
        {
            War3_ChatMessage(client,"%T","You cannot use war3bug again so soon",client);
        }
    }
}
public bool:CommandCheckStartsWith(String:compare[],String:lookingfor[]) {
    return StrContains(compare, lookingfor, false)==0;
}


FileBugReport(client,String:reportstr[]){
    //DP("REPORT '%s'",reportstr);
    new String:longquery[2000];
    
    new String:name[32];
    GetClientName(client,name,sizeof(name));
    new String:clientip[32];
    GetClientIP(client, clientip, sizeof(clientip));
    new String:steamid[64];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
    //DP("steamid %s",steamid);
    new String:hostname[64]; 
    GetConVarString(FindConVar("hostname"),hostname,64);
    new String:version[32];
    W3GetW3Version(version,sizeof(version));
    
    if(hdatabase2)
    {
        new String:hostname_sql[1000];
        SQL_EscapeString(hdatabase2,hostname,hostname_sql, sizeof(hostname_sql));
        
        new String:client_name_escaped[1000];
        SQL_EscapeString(hdatabase2,name, client_name_escaped, sizeof(client_name_escaped));
        
        new String:serverip_sql[1000];
        SQL_EscapeString(hdatabase2,serverip, serverip_sql, sizeof(serverip_sql));
        
        new String:version_sql[1000];
        SQL_EscapeString(hdatabase2,version, version_sql, sizeof(version_sql));
        
        new String:reportstr_sql[1000];
        SQL_EscapeString(hdatabase2, reportstr, reportstr_sql, sizeof(reportstr_sql));
        
        // lets do this before we escape it all. and technically these should be SQL_EscapeString'ed
        Format(longquery,sizeof(longquery),"INSERT INTO w3bugreport SET steamid='%s' ,name='%s'  ,time='%d' , clientip='%s', hostname='%s',serverip='%s:%d' ,version='%s' ,reportstring='%s'",
        steamid,client_name_escaped,GetTime(),clientip,hostname_sql,serverip_sql,serverport,version_sql,reportstr_sql);
        SQL_TQuery(hdatabase2,SQLTCallbackFileBug,longquery,client);
    }
    decl String:reportstr_url[1000];
    Format(reportstr_url, sizeof(reportstr_url), "%s", reportstr);
    
    decl String:serveripenc[1000];
    Format(serveripenc, 64, "%s", serverip); // good this is for url and is encoded after
    
    URLEncode(reportstr_url,sizeof(reportstr_url));
    URLEncode(name,sizeof(name));
    //DP("encode %s",steamid);
    URLEncode(hostname,sizeof(hostname));
    //DP("encode %s",steamid);
    URLEncode(steamid, sizeof(steamid));
    URLEncode(clientip, sizeof(clientip));
    URLEncode(version,sizeof(version));
    URLEncode(serveripenc, sizeof(serveripenc)); // see
    
    Format(longquery,sizeof(longquery),"w3stat/bugreport.php?steamid=%s&name=%s&clientip=%s&hostname=%s&serverip=%s:%d&version=%s&reportstr=%s",
    steamid,name,clientip,hostname,serveripenc,serverport,version,reportstr_url);
    
    W3Socket(longquery,SockCallbackBufReport);
    
}
public SockCallbackBufReport(bool:success,bool:fail,String:str[]){
    
}

public Action:ExecOnceTimer(Handle:h){
    
    if(FindConVar("gs_zombiereloaded_version")!=INVALID_HANDLE){
        collectkdstats=false;
    }
    
    decl String:longquery[16000];
    
    
    new String:racename[100];
    new  String:raceshort[100];
    new RacesLoaded = War3_GetRacesLoaded();
    for(new raceid=1;raceid<=RacesLoaded;raceid++)
    {
        War3_GetRaceShortname(raceid,raceshort,sizeof(raceshort));
        
        new langnum=GetLanguageCount();
        new langengid=-1;
        
        new bool:useserverlang;
        new bool:parseTransFile;
        for(new i=0;i<langnum;i++)
        {
            decl String:langcode[32];
            decl String:langname[32];
            GetLanguageInfo(i, langcode, sizeof(langcode), langname, sizeof(langname));
            if(StrEqual(langcode,"en"))
            {
                langengid=i;
                if(langengid==GetServerLanguage())
                {
                    useserverlang=true;
                    break;
                }
                else if(W3IsRaceTranslated(i))
                {
                    parseTransFile=true;
                    break;
                }
            }
        }
        if(useserverlang)
        {
            SetTrans(0);
            War3_GetRaceName(raceid,racename,sizeof(racename));
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
            
            new String:keyracename[32];
            Format(keyracename,sizeof(keyracename),"%s_RaceName",raceshort);
            if(!KvJumpToKey(keyValue, keyracename)){
                PrintToServer("could not jump to key %s",keyracename);
            }
            CloseHandle(keyValue);
        }
        
        URLEncode(racename,sizeof(racename));
        URLEncode(raceshort,sizeof(raceshort));
        //no english? or no translations? send nothing as racename
        Format(longquery,sizeof(longquery),"w3stat/raceinsertV2.php?racename=%s&raceshort=%s",racename,raceshort);
        
        W3Socket(longquery,RaceInsertCallback);
        
    }
    
    decl String:hostname[1000];
    GetConVarString(FindConVar("hostname"),hostname,sizeof(hostname));
    URLEncode(hostname,sizeof(hostname));
    decl String:version[1000];
    W3GetW3Version(version,sizeof(version));
    Format(longquery,sizeof(longquery),"ip=%s:%d&hostname=%s&version=%s",serverip,serverport,hostname,version);
    W3Socket2("w3stat/crashlog.php",longquery,CrashLogCallback);
    
    
    
    
    
    new Handle:cvarlist=W3CvarList();
    decl String:cvarstr[1000];
    decl String:cvarvalue[1000];
    decl String:concatstr[1000];
    new limit=GetArraySize(cvarlist);
    Format(longquery,sizeof(longquery),"ip=%s:%d&config=",serverip,serverport);
    for(new i=1;i<limit;i++)
    {
        GetArrayString(cvarlist,i,cvarstr,sizeof(cvarstr));
        W3GetCvarByString(cvarstr,cvarvalue,sizeof(cvarvalue));
        if(strlen(cvarvalue)>0)
        {
            URLEncode(cvarstr,sizeof(cvarstr));
            URLEncode(cvarvalue,sizeof(cvarvalue));
            Format(concatstr,sizeof(concatstr),"%s=%s,",cvarstr,cvarvalue);
            StrCat(longquery,sizeof(longquery),concatstr);
        }
    }
    
    W3Socket2("w3stat/serverinfolong.php",longquery,GenericSocketCallback);
    CloseHandle(cvarlist);
    
    //RACES
    Format(longquery,sizeof(longquery),"ip=%s:%d&races=",serverip,serverport);
    for(new i=1;i<=RacesLoaded;i++)
    {
        War3_GetRaceShortname(i,raceshort,sizeof(raceshort));
        URLEncode(raceshort,sizeof(raceshort));
        StrCat(longquery,sizeof(longquery),raceshort);
        StrCat(longquery,sizeof(longquery),",");
        //War3_LogInfo("%d",RacesLoaded);
    }
    W3Socket2("w3stat/serverinfolong.php",longquery,GenericSocketCallback);
    
    
    
    
    
    
    
    
    //ITEMS
    decl String:itemshort[100];
    Format(longquery,sizeof(longquery),"ip=%s:%d&items=",serverip,serverport);
    new ItemsLoaded = W3GetItemsLoaded();
    for(new i=1;i<=ItemsLoaded;i++)
    {
        W3GetItemShortname(i,itemshort,sizeof(itemshort));
        URLEncode(itemshort,sizeof(itemshort));
        StrCat(longquery,sizeof(longquery),itemshort);
        StrCat(longquery,sizeof(longquery),",");
    }
    W3Socket2("w3stat/serverinfolong.php",longquery,GenericSocketCallback);
    
    
    UpdateKDR();
    
}
public RaceInsertCallback(bool:success,bool:fail,String:str[])
{
}
public CrashLogCallback(bool:success,bool:fail,String:str[])
{
}

public GenericSocketCallback(bool:success,bool:fail,String:str[])
{
}


UpdateKDR()
{
    new String:longquery[4000];
    Format(longquery,sizeof(longquery),"serverip=%s:%d&game=",serverip,serverport);
    W3Socket2("w3getstat/getracestats.php",longquery,Sock_getracestats_Callback);
}
public Sock_getracestats_Callback(bool:success,bool:fail,String:str[])
{
    new String:chopped[218];
    
    //DP(str[12000]);
    //DP("%d",strlen(str));
    //STRIP IT!
    if(str[0]=='{' && str[strlen(str)-1]=='}')
    {
        CloseHandle(GameAndServerKDR);
        GameAndServerKDR=CreateTrie();
        str[strlen(str)-1]='\0';
        //DP("got it!");
        
        //shift down
        Format(str,strlen(str),"%s",str[1]);
        
        while(ChopString(str,",",chopped,sizeof(chopped))){
            
            // "game_raceshort_something":0
            // "server_raceshort_something":0
            new String:exploded2[2][64];
            new number2=ExplodeString(chopped, ":", exploded2, 2, 64);
            number2++;//STFU error
            new String:key[64];
            new String:value[64];
            strcopy(key,sizeof(key),exploded2[0]);
            strcopy(value,sizeof(value),exploded2[1]);
            StripQuotes(key);
            SetTrieString(GameAndServerKDR, key, value);
            //DP("%s %s",key,value);
            //DP(str);
        }
        //DP("size %d",GetTrieSize(GameAndServerKDR));
    }
    else
    {
        War3_LogError("Sock_getracestats_Callback no matching braces %s",str);
    }
}

public Action:MinuteTimer(Handle:h)
{
    
    decl String:longquery[4000];
    decl race;
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i)&&!IsFakeClient(i)&&GetClientTeam(i)>1)
        {
            race=War3_GetRace(i);
            if(race>0)
            {
                decl String:steamid[32];
                GetClientAuthId(i, AuthId_Steam2, steamid, sizeof(steamid));
                
                decl String:raceshort[16];
                War3_GetRaceShortname(race,raceshort,sizeof(raceshort));
                
                Format(longquery,sizeof(longquery),"w3stat/timeplayed.php?steamid=%s&raceshort=%s&ip=%s:%d&game=%s&data1=%s&data2=%s&level=%d",steamid,raceshort,serverip,serverport,game,"1",IsPlayerAlive(i)?"alive":"dead",War3_GetLevel(i,race));
                
                W3Socket(longquery,SockCallbackKill);
            }
        }
    }
}
public OnWar3EventDeath(victim,attacker){
    if(bCollectStats && collectkdstats&&(ValidPlayer(victim)&&ValidPlayer(attacker)&&War3_GetRace(victim)>0&&War3_GetRace(attacker)>0&&!IsFakeClient(victim)&&!IsFakeClient(attacker)&&victim!=attacker)){
        decl String:longquery[4000];
        decl String:raceshortatt[64];
        decl String:raceshortvic[64];
        decl String:steamid[64];
        decl String:victimsteamid[64];
        GetClientAuthId(attacker, AuthId_Steam2, steamid, sizeof(steamid));
        GetClientAuthId(victim, AuthId_Steam2, victimsteamid, sizeof(victimsteamid));
        URLEncode(steamid,sizeof(steamid));
        URLEncode(victimsteamid,sizeof(victimsteamid));
        new raceatt=War3_GetRace(attacker);
        new racevic=War3_GetRace(victim);
        War3_GetRaceShortname(raceatt,raceshortatt,sizeof(raceshortatt));
        War3_GetRaceShortname(racevic,raceshortvic,sizeof(raceshortvic));
        URLEncode(raceshortatt,sizeof(raceshortatt));
        URLEncode(raceshortvic,sizeof(raceshortvic));
        
        Format(longquery,sizeof(longquery),"w3stat/kill.php?steamid=%s&raceshort=%s&ip=%s:%d&game=%s&data1=%s&data2=%s&killerlvl=%d&victimlvl=%d&war3revision=%d&statsversion=%d",steamid,raceshortatt,serverip,serverport,game,victimsteamid,raceshortvic,War3_GetLevel(attacker,raceatt),War3_GetLevel(victim,racevic),W3GetW3Revision(),W3GetStatsVersion());
        
        W3Socket(longquery,SockCallbackKill);
    }
}
public SockCallbackKill(bool:success,fail,String:ret[]){
}


public War3Source_RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(bCollectStats && collectwlstats&&   PlayersOnTeam(2)+PlayersOnTeam(3)>5)
    {
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
            for(new i=1;i<=MaxClients;i++)
            {
                
                if(ValidPlayer(i) &&!IsFakeClient(i))
                {
                    
                    new race=War3_GetRace(i);
                    if(race>0)
                    {
                        new clientteam=GetClientTeam(i);
                        if(clientteam>1)
                        {
                            decl String:longquery[4000];
                            
                            decl String:steamid[65];
                            GetClientAuthId(i, AuthId_Steam2, steamid, sizeof(steamid));
                            URLEncode(steamid,sizeof(steamid));
                            decl String:raceshort[64];
                            War3_GetRaceShortname(race,raceshort,sizeof(raceshort));
                            URLEncode(raceshort,sizeof(raceshort));
                            Format(longquery,sizeof(longquery),"w3stat/winlossV2.php?steamid=%s&raceshort=%s&game=%s&ip=%s:%d&win=%d&clientteam=%d&lvl=%d",steamid,raceshort,game,serverip,serverport,clientteam==winteam?1:0,clientteam,War3_GetLevel(i,race));
                            W3Socket(longquery,SockCallbackWinLoss);
                        }
                    }
                }
            }
        }
    }
}
public SockCallbackWinLoss(succ,fail,String:buf[]){
}



public SQLTCallbackFileBug(Handle:owner,Handle:hndl,const String:error[],any:client){
    
    SQLCheckForErrors(hndl,error,"SQLTCallbackFileBug");
    
    if(hndl==INVALID_HANDLE)
    {
        if(ValidPlayer(client))
        {
            War3_ChatMessage(client,"%T","Could not file bug report, contact server owner",client);
        }
    }
    else
    {
        if(ValidPlayer(client))
        {
            War3_ChatMessage(client,"%T","Successfully filed bug report",client);
        }
    }
}


// Example usage: index.php?a=URLEncode(param_1)&b=URLEncode(param_2)&c=URLEncode(param_3)
stock URLEncode(String:str[],len)
{
    new String:str2[len*3+1];
    Format(str2,len*3+1,"%s",str);
    // Make sure % is first to avoid collisions.
    new String:ReplaceThis[20][] = {"%", " ", "!", "*", "'", "(", ")", ";", ":", "@", "&", "=", "+", "$", ",", "/", "?", "#", "[", "]"};
    new String:ReplaceWith[20][] = {"%25", "%20", "%21", "%2A", "%27", "%28", "%29", "%3B", "%3A", "%40", "%26", "%3D", "%2B", "%24", "%2C", "%2F", "%3F", "%23", "%5B", "%5D"};
    for(new x=0;x<20;x++)
    {
        //REPLACE STRING BUG https://bugs.alliedmods.net/show_bug.cgi?id=4943
        //DP("%d '%s'",strlen(str2),str2);
        ReplaceString(str2, len, ReplaceThis[x], ReplaceWith[x]);
        
    }
    if(strlen(str2)>len*3){
        War3_LogError("statistics encode url exceeded length (%d): %s",len*3,str2);
        War3Failed("statistics encode url exceeded length"); //this should never happen as ReplaceString was fixed not to overwrite its length
    }
    Format(str,len,"%s",str2);
    if(strlen(str)>len-1){
        War3_LogError("statistics encode url exceeded length (%d): %s",len,str);
        War3Failed("statistics encode url exceeded length"); //this should never happen as ReplaceString was fixed not to overwrite its length
    }
}
stock bool:ShowError(){
    return GetConVarInt(hShowSocketError)>0?true:false;
}

