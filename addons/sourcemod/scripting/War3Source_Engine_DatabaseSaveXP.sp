#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo =
{
    name = "War3Source - Engine - Database Save XP",
    author = "War3Source Team",
    description = "Saves players Experience"
};

new Handle:hDB;

// ConVar definitions
new Handle:m_SaveXPConVar;
new Handle:hSetRaceOnJoinCvar;

new Handle:m_AutosaveTime;
new Handle:hCvarPrintOnSave;

new Handle:g_OnWar3PlayerAuthedHandle;
new desiredRaceOnJoin[MAXPLAYERSCUSTOM];

public bool:InitNativesForwards()
{
    CreateNative("W3SaveXP" ,NW3SaveXP);
    CreateNative("W3SaveEnabled" ,NW3SaveEnabled);

    return true;
}

public OnPluginStart()
{
    m_SaveXPConVar = CreateConVar("war3_savexp", "1");
    hSetRaceOnJoinCvar = CreateConVar("war3_set_race_on_join", "1");
    m_AutosaveTime = CreateConVar("war3_autosavetime", "60");
    hCvarPrintOnSave = CreateConVar("war3_print_on_autosave", "0", "Print a message to chat when xp is auto saved?");

    W3SetVar(hSaveEnabledCvar, m_SaveXPConVar);
    g_OnWar3PlayerAuthedHandle = CreateGlobalForward("OnWar3PlayerAuthed", ET_Ignore, Param_Cell, Param_Cell);

    CreateTimer(GetConVarFloat(m_AutosaveTime),DoAutosave);
}

public NW3SaveXP(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    new race = GetNativeCell(2);

    //saves main also
    War3Source_SavePlayerData(client,race);
}

public NW3SaveEnabled(Handle:plugin,numParams)
{
    return GetConVarInt(m_SaveXPConVar);
}

public OnWar3Event(W3EVENT:event,client)
{
    if(event == DatabaseConnected)
    {
        hDB = W3GetVar(hDatabase);
        Initialize_SQLTable();
    }
}

Initialize_SQLTable()
{
    PrintToServer("[War3Source] Initialize_SQLTable");
    if(hDB != INVALID_HANDLE)
    {
        //non threading operations here, done once on plugin load only, not map change
        SQL_LockDatabase(hDB);

        //main table
        new Handle:query = SQL_Query(hDB, "SELECT * from war3source LIMIT 1");

        if(query == INVALID_HANDLE)
        {
            new String:createtable[3000];
            Format(createtable, sizeof(createtable), "CREATE TABLE war3source (steamid varchar(64) UNIQUE, name varchar(64), currentrace varchar(16), gold int, diamonds int, total_level int, total_xp int, levelbankV2 int, last_seen int) %s", War3SQLType:W3GetVar(hDatabaseType) == SQLType_MySQL ? "DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci" : "" );
            if(!SQL_FastQueryLogOnError(hDB, createtable) ||
               !SQL_FastQueryLogOnError(hDB, "CREATE UNIQUE INDEX war3_steamid ON war3source (steamid)"))
            {
                SetFailState("[War3Source] ERROR in the creation of the SQL table war3source.");
            }
        }
        else
        { 
            //DO NOT DELETE, FOR FUTURE REFRENCE
          if(!SQL_FieldNameToNum(query, "levelbankV2", dummy))
          {
            AddColumn(hDB,"levelbankV2","int","war3source");
          }
          
          if(!SQL_FieldNameToNum(query, "gold", dummy))
          {
             //DO NOT DELETE, FOR FUTURE REFRENCE
            /*if(g_SQLType==SQLType_SQLite){
              //sqlite cannot rename column
              AddColumn(hDB,"gold","INT","war3source");
            }
            else{
              SQL_FastQueryLogOnError(hDB,"ALTER TABLE war3source CHANGE credits gold INT");
              PrintToServer("[War3Source] Tried to change column from 'credits' to 'gold'");
            }*/
          }
          if(!SQL_FieldNameToNum(query, "diamonds", dummy))
          {
            AddColumn(hDB,"diamonds","int","war3source");
          }
        
          CloseHandle(query);
        }
  

        ///NEW DATABASE STRUCTURE
        query = SQL_Query(hDB,"SELECT * from war3source_racedata1 LIMIT 1");
        if(query == INVALID_HANDLE)
        {
            PrintToServer("[War3Source] war3source_racedata1 doesnt exist, creating");
            new String:longquery2[4000];
            Format(longquery2, sizeof(longquery2), "CREATE TABLE war3source_racedata1 (steamid varchar(64), raceshortname varchar(16), level int, xp int, last_seen int)  %s",War3SQLType:W3GetVar(hDatabaseType)==SQLType_MySQL?"DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci":"");

            if(!SQL_FastQueryLogOnError(hDB, longquery2) ||
               !SQL_FastQueryLogOnError(hDB, "CREATE UNIQUE INDEX war3_race_steamid_shortname ON war3source_racedata1 (steamid, raceshortname)") ||
               // The above index doesn't cover single steamid lookups like we do for saving XP
               !SQL_FastQueryLogOnError(hDB, "CREATE INDEX war3_race_steamid ON war3source_racedata1 (steamid)"))
            {
                SetFailState("[War3Source] ERROR in the creation of the SQL table war3source_racedata1");
            }

            
            
        }
        else{
          CloseHandle(query);
        }
        //get another handle for next table check
        //do another check for handle, cuz we may have just created database
        query = SQL_Query(hDB, "SELECT * from war3source_racedata1 LIMIT 1");

        
        if(query == INVALID_HANDLE)
        {
            SetFailState("invalid handle to data");
        }
        else
        {
            //table exists by now, add skill columns if not exists
            new String:columnname[16];
            new dummyfield;

            for(new i=1; i < MAXSKILLCOUNT; i++)
            {
                Format(columnname,sizeof(columnname),"skill%d",i);

                if(!SQL_FieldNameToNum(query, columnname, dummyfield))
                {
                    AddColumn(hDB, columnname, "int", "war3source_racedata1");
                }
            }

            CloseHandle(query);
        }

        SQL_UnlockDatabase(hDB);
    }
    else
    {
        PrintToServer("hDB invalid");
    }
}

public Action:DoAutosave(Handle:timer, any:data)
{
    if(W3SaveEnabled())
    {
        for(new x=1;x<=MaxClients;x++)
        {
            if(ValidPlayer(x))
            {
                War3Source_SavePlayerData(x, War3_GetRace(x));
            }
        }
        if(GetConVarInt(hCvarPrintOnSave) > 0)
        {
            War3_ChatMessage(0, "%t", "Saving all player XP and updating stats");
        }
    }

    CreateTimer(GetConVarFloat(m_AutosaveTime) ,DoAutosave);
}

//=======================================================================
//                             SAVING
//=======================================================================

War3Source_SavePlayerData(client, race)
{
    if(hDB && !IsFakeClient(client) && W3IsPlayerXPLoaded(client))
    {
        //only save their current race
        War3_SavePlayerRace(client, race);

        //main data
        War3_SavePlayerMainData(client);
    }
}

//save a race using new db style
War3_SavePlayerRace(client,race)
{
    //DP("save");
    if(hDB && W3SaveEnabled() && W3GetPlayerProp(client,xpLoaded)&&race>0)
    {
        //DP("save2");
        //PrintToServer("race %d client %d",race,client);
        decl String:steamid[64];

        if(GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
        {

            new level=War3_GetLevelEx(client,race,true);
            new xp=War3_GetXP(client,race);
            //DP("%d,%d,",level,xp);
            new String:raceshortname[16];
            War3_GetRaceShortname(race,raceshortname,sizeof(raceshortname));

            new String:longquery[4000];
            Format(longquery,sizeof(longquery),"UPDATE war3source_racedata1 SET level='%d',xp='%d' ",level,xp);

            new SkillCount = War3_GetRaceSkillCount(race);
            for(new skillid=1;skillid<=SkillCount;skillid++)
            {
                Format(longquery,sizeof(longquery),"%s, skill%d=%d ",longquery,skillid,War3_GetSkillLevelINTERNAL(client,race,skillid));
            }

            new last_seen=GetTime();
            Format(longquery,sizeof(longquery),"%s , last_seen='%d' WHERE steamid='%s' AND raceshortname='%s'",longquery,last_seen,steamid,raceshortname);

            new String:racename[64];
            War3_GetRaceName(race,racename,sizeof(racename));
            PrintToConsole(client,"%T","[War3Source] Saving XP for race {racename}: LVL {amount} XP {amount}",client,racename,level,xp);

            //XP safety?
            //    new level=War3_GetLevel(client,x);
            //    if(level<W3GetRaceMaxLevel(x)){
            //        Format(longquery,sizeof(longquery),"%s AND level<='%d'",query_buffer,templevel); //only level restrict if not max, iif max or over do not restrict
            //    }

            new Handle:querytrie=CreateTrie();
            SetTrieString(querytrie,"query",longquery);
            SQL_TQuery(hDB,T_CallbackSavePlayerRace,longquery,querytrie);
            //DP("%s",longquery);
            //ThrowError("END SAVE");
        }
    }
}
public T_CallbackSavePlayerRace(Handle:owner,Handle:hndl,const String:error[],any:trie)
{
    SQLCheckForErrors(hndl,error,"T_CallbackSavePlayerRace",trie);
}

War3_SavePlayerMainData(client)
{
    if(hDB &&W3IsPlayerXPLoaded(client))
    {
        decl String:steamid[64];
        decl String:name[64];
        if(GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)) && GetClientName(client, name, sizeof(name)))
        {
            ReplaceString(name, sizeof(name), "'","", true); //REMOVE IT //double escape because \\ turns into -> \ after the %s insert into sql statement

            new String:szSafeName[(sizeof(name) * 2) - 1];
            SQL_EscapeString(hDB, name, szSafeName, sizeof(szSafeName));

            new String:longquery[4000];
            new total_level = W3GetTotalLevels(client);
            new total_xp = 0;
            new RacesLoaded = War3_GetRacesLoaded();
            for(new z=1; z <= RacesLoaded; z++)
            {
                total_xp += War3_GetXP(client, z);
            }

            new last_seen=GetTime();
            new String:short[16];
            War3_GetRaceShortname(War3_GetRace(client),short,sizeof(short));
            Format(longquery,sizeof(longquery),"UPDATE war3source SET name='%s',currentrace='%s',gold='%d',diamonds='%d',total_level='%d',total_xp='%d',last_seen='%d',levelbankV2='%d' WHERE steamid = '%s'", szSafeName, short, War3_GetGold(client), War3_GetDiamonds(client), total_level, total_xp, last_seen, W3GetLevelBank(client), steamid);
            new Handle:querytrie=CreateTrie();
            SetTrieString(querytrie,"query",longquery);
            SQL_TQuery(hDB,T_CallbackUpdatePDataMain,longquery,querytrie);
        }
    }
}

//we just tried inserting main data
public T_CallbackUpdatePDataMain(Handle:owner,Handle:query,const String:error[],any:trie)
{
    SQLCheckForErrors(query,error,"T_CallbackUpdatePDataMain",trie);
}

//=======================================================================
//                             RETRIEVING
//=======================================================================

public OnClientPutInServer(client)
{
    //set race 0 may trigger unwanted behavior, block it first
    W3SetPlayerProp(client, xpLoaded, false);
    //stateful entry
    W3SetPlayerProp(client, bPutInServer, true);
    W3CreateEvent(InitPlayerVariables, client);
    W3SetPlayerProp(client, xpLoaded, false);

    if(IsFakeClient(client))
    {
        W3SetPlayerProp(client, xpLoaded, true);

        return;
    }

    if(W3SaveEnabled())
    {
        War3_ChatMessage(client, "%T", "Loading player data...", client);
        War3Source_LoadPlayerData(client);
    }
    else
    {
        DoForwardOnWar3PlayerAuthed(client);
    }
    if(!W3SaveEnabled() || hDB == INVALID_HANDLE)
    {
        // if db failed , or no save xp
        W3SetPlayerProp(client, xpLoaded, true);
    }
}

public OnClientDisconnect(client)
{
    if(W3GetPlayerProp(client,bPutInServer))
    {
        //he must have joined (not just connected) server already
        if(W3SaveEnabled() && W3IsPlayerXPLoaded(client))
        {
            War3Source_SavePlayerData(client, War3_GetRace(client));
        }

        W3CreateEvent(ClearPlayerVariables, client);
        W3SetPlayerProp(client, bPutInServer, false);
        desiredRaceOnJoin[client] = 0;
    }
}

//=======================================================================
//                          RETRIEVING / SQL STATEMENTS
//=======================================================================

//SELECT STATEMENTS HERE
War3Source_LoadPlayerData(client)
{
    //war3source calls this
    //need space for steam id
    decl String:steamid[64];

    if(hDB && !IsFakeClient(client) && GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
    {
        new String:longquery[4000];

        //Prepare select query for main data
        Format(longquery, sizeof(longquery), "SELECT currentrace, gold, diamonds, levelbankV2 FROM war3source WHERE steamid='%s'", steamid);
        //Pass off to threaded call back at normal prority
        SQL_TQuery(hDB,T_CallbackSelectPDataMain, longquery, client);

        PrintToConsole(client, "%T", "[War3Source] XP retrieval query: sending MAIN and load all races request! Time: {amount}", client, GetGameTime());
        W3SetPlayerProp(client, sqlStartLoadXPTime, GetGameTime());

        //Lets get race data too
        Format(longquery, sizeof(longquery), "SELECT * FROM war3source_racedata1 WHERE steamid='%s'", steamid);
        SQL_TQuery(hDB, T_CallbackSelectPDataRace, longquery, client);

    }
}

public T_CallbackSelectPDataMain(Handle:owner, Handle:hndl, const String:error[], any:client)
{
    SQLCheckForErrors(hndl, error, "T_CallbackSelectPDataMain");

    if(!ValidPlayer(client))
    {
        return;
    }

    if(hndl == INVALID_HANDLE)
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
            else
            {
                new gold = W3SQLPlayerInt(hndl, "gold");
                War3_SetGold(client, gold);
                
                new diamonds=W3SQLPlayerInt(hndl,"diamonds");
                War3_SetDiamonds(client,diamonds);

                new levelbankamount = W3SQLPlayerInt(hndl, "levelbankV2");

                if(W3GetLevelBank(client) > levelbankamount)
                {
                    //whichever is higher
                    levelbankamount = W3GetLevelBank(client);
                }
                W3SetLevelBank(client, levelbankamount);

                //Get the short race string
                new String:currentrace[16];
                if(!W3SQLPlayerString(hndl, "currentrace", currentrace, sizeof(currentrace)))
                {
                    LogError("[War3Source] Unexpected error loading player currentrace. Check DATABASE settings!");

                    return;
                }
                PrintToConsole(client, "%T", "[War3Source] War3 MAIN retrieval: gold {amount} Time {amount}", client, gold, GetGameTime());

                // worst case senario set player to race 0
                new raceFound = 0;
                if(GetConVarInt(hSetRaceOnJoinCvar) > 0)
                {
                    //Scan all the races
                    new RacesLoaded = War3_GetRacesLoaded();
                    for(new x=1; x <= RacesLoaded; x++)
                    {
                        new String:sShortName[16];
                        War3_GetRaceShortname(x, sShortName, sizeof(sShortName));

                        //compare their short names to the one loaded
                        if(StrEqual(currentrace,sShortName,false))
                        {
                            raceFound = x;
                            break;
                        }
                    }

                    desiredRaceOnJoin[client] = raceFound;
                }
            }
        }
        else if(SQL_GetRowCount(hndl) == 0) //he doesnt exist
        {
            //Not in database so add
            decl String:steamid[64];
            decl String:name[64];
            //get their name and steamid
            if(GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)) && GetClientName(client, name, sizeof(name)))
            {
                ReplaceString(name, sizeof(name), "'", "", true); //REMOVE IT//double escape because \\ turns into -> \ after the %s insert into sql statement

                new String:szSafeName[(sizeof(name) * 2) -1];
                SQL_EscapeString(hDB, name, szSafeName, sizeof(szSafeName));

                new total_level = W3GetTotalLevels(client);
                new total_xp = 0;

                // Get data from the player vector I guess this allows the player to play before the queries are
                // done but it is probably zero all the time
                new RacesLoaded = War3_GetRacesLoaded();
                for(new z=1; z <= RacesLoaded; z++)
                {
                    total_xp += War3_GetXP(client, z);
                }

                new String:short_name[16];
                War3_GetRaceShortname(War3_GetRace(client), short_name, sizeof(short_name));

                new String:longquery[4000];
                // Main table query
                Format(longquery, sizeof(longquery), "INSERT INTO war3source (steamid, name, currentrace, total_level, total_xp) VALUES ('%s','%s','%s','%d','%d')", steamid, szSafeName, short_name, total_level, total_xp);
                new Handle:querytrie = CreateTrie();
                SetTrieString(querytrie, "query", longquery);
                SQL_TQuery(hDB, T_CallbackInsertPDataMain, longquery, querytrie);
            }
        }
        else if(SQL_GetRowCount(hndl) > 1)
        {
            // this is a WTF moment here
            //should probably purge these records and get the player to rejoin but I'm lazy
            //and don't want to write that
            LogError("[War3Source] Returned more than 1 record, primary or UNIQUE keys are screwed (main, rows: %d)", SQL_GetRowCount(hndl));
        }
    }
}

//we just tried inserting main data
public T_CallbackInsertPDataMain(Handle:owner,Handle:query,const String:error[],any:querytrie)
{
    SQLCheckForErrors(query,error,"T_CallbackInsertPDataMain",querytrie);
}

///callback retrieved individual race xp!!!!!
public T_CallbackSelectPDataRace(Handle:owner,Handle:hndl,const String:error[],any:client)
{
    SQLCheckForErrors(hndl,error,"T_CallbackSelectPDataRace");

    if(!ValidPlayer(client))
    {
        return;
    }

    if(hndl != INVALID_HANDLE)
    {
        new retrievals;
        new usefulretrievals;
        new bool:raceloaded[MAXRACES];
        while(SQL_MoreRows(hndl))
        {
            if(SQL_FetchRow(hndl))
            {
                //SQLITE doesnt properly detect ending
                // Load up the data from a successful query
                // level,xp,skill1,skill2,skill3,ultimate

                new String:raceshortname[16];
                W3SQLPlayerString(hndl, "raceshortname", raceshortname, sizeof(raceshortname));
                new raceid = War3_GetRaceIDByShortname(raceshortname);
                if(raceid > 0)
                {
                    //this race was loaded in war3
                    raceloaded[raceid] = true;
                    new level = W3SQLPlayerInt(hndl, "level");

                    if(level > W3GetRaceMaxLevel(raceid))
                    {
                        level = W3GetRaceMaxLevel(raceid);
                    }

                    War3_SetLevel(client, raceid, level);
                    new pxp = W3SQLPlayerInt(hndl, "xp");
                    War3_SetXP(client, raceid, pxp);

                    new String:column[32];
                    new skilllevel;
                    new RacesSkillCount = War3_GetRaceSkillCount(raceid);
                    for(new skillid = 1; skillid <= RacesSkillCount; skillid++)
                    {
                        Format(column, sizeof(column), "skill%d", skillid);
                        skilllevel = W3SQLPlayerInt(hndl, column);
                        //Prevent Future Problems when we remove skill levels from certain races (EL DIABLO)
                        new SkillMaxLevel=W3GetRaceSkillMaxLevel(raceid,skillid);
                        if(skilllevel>SkillMaxLevel)
                        {
                            skilllevel=SkillMaxLevel;
                        }
                        War3_SetSkillLevelINTERNAL(client,raceid,skillid,skilllevel);
                    }
                    usefulretrievals++;
                }
                retrievals++;
            }
        }
        if(retrievals > 0)
        {
            PrintToConsole(client, "%T", "[War3Source] Successfully retrieved data races, total of {amount} races were returned, {amount} are running on this server", client, retrievals, usefulretrievals);
        }
        else if(retrievals == 0 && War3_GetRacesLoaded() > 0)
        {
            //no xp record
            W3CreateEvent(PlayerIsNewToServer, client);
        }

        new inserts;
        new RacesLoaded = War3_GetRacesLoaded();
        for(new raceid=1; raceid <= RacesLoaded; raceid++)
        {
            if(raceloaded[raceid] == false)
            {
                //no record make one
                decl String:steamid[64];
                if(GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
                {
                    new String:longquery[4000];
                    new String:short[16];
                    War3_GetRaceShortname(raceid,short,sizeof(short));

                    new last_seen=GetTime();
                    Format(longquery,sizeof(longquery),"INSERT INTO war3source_racedata1 (steamid,raceshortname,level,xp,last_seen) VALUES ('%s','%s','%d','%d','%d')",steamid,short,War3_GetLevelEx(client,raceid,true),War3_GetXP(client,raceid),last_seen);

                    SQL_TQuery(hDB,T_CallbackInsertPDataRace,longquery,client);
                    inserts++;
                }
            }

        }
        if(inserts > 0)
        {
            PrintToConsole(client,"%T","[War3Source] Inserting fresh level xp data for {amount} races",client,inserts);
        }

        W3SetPlayerProp(client, xpLoaded, true);
        War3_ChatMessage(client, "%T", "Successfully retrieved save data", client);
        PrintToConsole(client, "%T", "[War3Source] XP RETRIEVED IN {amount} seconds", client, GetGameTime() - Float:W3GetPlayerProp(client, sqlStartLoadXPTime));
        DoForwardOnWar3PlayerAuthed(client);

        if(War3_GetRace(client) <= 0 && desiredRaceOnJoin[client] > 0)
        {
            if(CanSelectRace(client, desiredRaceOnJoin[client]))
            {
                W3SetPlayerProp(client, RaceSetByAdmin, false);
                War3_SetRace(client, desiredRaceOnJoin[client]);
            }
            else
            {
                W3CreateEvent(DoShowChangeRaceMenu,client);
            }
        }
    }
}

public T_CallbackInsertPDataRace(Handle:owner,Handle:query,const String:error[],any:data)
{
    SQLCheckForErrors(query,error,"T_CallbackInsertPDataRace");
}

DoForwardOnWar3PlayerAuthed(client)
{
    Call_StartForward(g_OnWar3PlayerAuthedHandle);
    Call_PushCell (client);
    Call_Finish (dummy);
}