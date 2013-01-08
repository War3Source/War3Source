#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Addon - Statspage",
    author = "War3Source Team",
    description = "A helper to generate data for the statspage"
};

new Handle:h_DB = INVALID_HANDLE; 

public OnWar3Event(W3EVENT:event, client)
{
    if(event == DatabaseConnected)
    {
        h_DB = W3GetVar(hDatabase);
        InitializeTable();
    }
}

InitializeTable()
{
    SQL_LockDatabase(h_DB);
    
    new Handle:query = SQL_Query(h_DB, "SELECT * from war3sourceraces LIMIT 1");
    if(query != INVALID_HANDLE)
    {
        SQL_FastQueryLogOnError(h_DB,"DROP TABLE war3sourceraces");
    }

    new String:sQuery[4000];
    Format(sQuery, sizeof(sQuery), "CREATE TABLE war3sourceraces (");
    Format(sQuery, sizeof(sQuery), "%s %s", sQuery, "shortname varchar(16) UNIQUE,");
    Format(sQuery, sizeof(sQuery), "%s %s", sQuery, "name varchar(32)");

    for(new i=1; i < MAXSKILLCOUNT; i++)
    {
        Format(sQuery, sizeof(sQuery), "%s, skill%d varchar(32)", sQuery, i);
        Format(sQuery, sizeof(sQuery), "%s, skilldesc%d varchar(2000)", sQuery, i);
    }

    Format(sQuery, sizeof(sQuery), "%s ) %s", sQuery, War3SQLType:W3GetVar(hDatabaseType) == SQLType_MySQL ? "DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci" : "");
    SQL_FastQueryLogOnError(h_DB, sQuery);
    
    SQL_UnlockDatabase(h_DB);
}

public OnWar3PluginReady()
{
    for(new race=1; race < War3_GetRacesLoaded(); race++)
    {
        InsertRace(race);
    }
}

InsertRace(raceId)
{
    new String:sQuery[4000];
    new String:sShortname[SHORTNAMELEN];
    
    War3_GetRaceShortname(raceId, sShortname, sizeof(sShortname));
    Format(sQuery, sizeof(sQuery), "INSERT %s IGNORE INTO %s (shortname) VALUES ('%s')",
           W3GetVar(hDatabaseType) == SQLType_SQLite ? "OR" : "", "war3sourceraces", sShortname);

    SQL_TQuery(h_DB, Callback_InsertedRace, sQuery, raceId, DBPrio_High);
}

public Callback_InsertedRace(Handle:owner, Handle:hndl, const String:error[], any:raceid)
{
    SQLCheckForErrors(hndl, error, "Callback_InsertedRace");

    new String:sReturn[2000];
    new String:sEscaped[2000];
    new String:sQuery[4000];
    Format(sQuery, sizeof(sQuery), "UPDATE %s SET ","war3sourceraces");

    War3_GetRaceName(raceid, sReturn, sizeof(sReturn));
    SQL_EscapeString(h_DB, sReturn, sEscaped, sizeof(sEscaped));
    Format(sQuery, sizeof(sQuery), "%s name='%s'", sQuery, sEscaped);

    new SkillCount = War3_GetRaceSkillCount(raceid);
    for(new i=1; i <= SkillCount; i++)
    {
        W3GetRaceSkillName(raceid, i, sReturn, sizeof(sReturn));
        SQL_EscapeString(h_DB, sReturn, sEscaped, sizeof(sEscaped));
        Format(sQuery, sizeof(sQuery), "%s, skill%d='%s %s'", sQuery, i, War3_IsSkillUltimate(raceid, i) ? "Ultimate" : "", sEscaped);
        
        W3GetRaceSkillDesc(raceid, i, sReturn, sizeof(sReturn));
        SQL_EscapeString(h_DB, sReturn, sEscaped, sizeof(sEscaped));
        Format(sQuery, sizeof(sQuery), "%s, skilldesc%d='%s'", sQuery, i, sEscaped);
    }

    new String:sShortname[16];
    War3_GetRaceShortname(raceid, sShortname, sizeof(sShortname));

    Format(sQuery, sizeof(sQuery), "%s WHERE shortname = '%s'", sQuery, sShortname);
    SQL_TQuery(h_DB, T_CallbackInsertRace2, sQuery, raceid, DBPrio_High);
}

public T_CallbackInsertRace2(Handle:owner,Handle:hndl,const String:error[],any:raceid)
{
    SQLCheckForErrors(hndl, error, "T_CallbackInsertRace2");
}