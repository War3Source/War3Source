#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Database Connect",
    author = "War3Source Team",
    description = "Connects War3Source to the database"
};

new Handle:hDB;
new War3SQLType:g_SQLType; 

public OnPluginStart()
{
    
}
public OnAllPluginsLoaded()
{
    ConnectDB();
}

ConnectDB(){
    PrintToServer("[W3S] Connecting to Database");
    new String:sCachedDBIName[256];
    new String:dbErrorMsg[512];
    
    new Handle:keyValue=CreateKeyValues("War3SourceSettings");
    decl String:path[1024];
    BuildPath(Path_SM,path,sizeof(path),"configs/war3source.ini");
    FileToKeyValues(keyValue,path);
    // Load level configuration
    KvRewind(keyValue);
    new String:database_connect[256];
    KvGetString(keyValue,"database",database_connect,sizeof(database_connect),"default");
    decl String:error[256];
    strcopy(sCachedDBIName,256,database_connect);
    
    
    if(StrEqual(database_connect,"",false) || StrEqual(database_connect,"default",false))
    {
        hDB=SQL_DefConnect(error,sizeof(error));    ///use default connect, returns a handle...
    }
    else
    {
        hDB=SQL_Connect(database_connect,true,error,sizeof(error));
    }
    if(!hDB)
    {
        LogError("[War3Source] ERROR: hDB invalid handle, Check SourceMod database config, could not connect. ");
        W3LogError("[War3Source] ERROR: hDB invalid handle, Check SourceMod database config, could not connect. ");
        Format(dbErrorMsg,sizeof(dbErrorMsg),"ERR: Could not connect to DB. \n%s",error);
        LogError("ERRMSG:(%s)",error);
        W3LogError("ERRMSG:(%s)",error);
        CreateWar3GlobalError("ERR: Could not connect to Database");
    }
    else
    {
        
        new String:driver_ident[64];
        SQL_ReadDriver(hDB,driver_ident,sizeof(driver_ident));
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
        PrintToServer("[War3Source] SQL connection successful, driver %s",driver_ident);
        SQL_LockDatabase(hDB);
        SQL_FastQuery(hDB, "SET NAMES \"UTF8\""); 
        SQL_UnlockDatabase(hDB);
        W3SetVar(hDatabase,hDB);
        W3SetVar(hDatabaseType,g_SQLType);
        W3CreateEvent(DatabaseConnected,0);
    }
    return true;
}
