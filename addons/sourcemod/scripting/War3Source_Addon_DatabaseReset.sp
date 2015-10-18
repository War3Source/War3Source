#pragma semicolon 1

#include "W3SIncs/War3Source_Interface"

#define CONFIRM_NO 0 // Deletion not initiated
#define CONFIRM_AWAIT 1 // Deletion awaits confirmation
#define CONFIRM_YES 2 // Deletion was confirmed, currently deleting

new Handle:g_hDatabase = INVALID_HANDLE;
new g_iConfirmState[MAXPLAYERSCUSTOM];
new g_iDeleteToken = 0;

public Plugin:myinfo = 
{
    name = "War3Source - Addon - Database Reset",
    author = "War3Source Team",
    description = "Command to reset the database"
};

public OnPluginStart()
{
    AddCommandListener(SayCallback, "say");
    RegAdminCmd("war3_resetdb", Command_ResetDB, ADMFLAG_ROOT, "Reset war3source database.");
}

public Action:SayCallback(client, const String:command[], argc)
{
    if(g_iConfirmState[client] == CONFIRM_AWAIT)
    {
        decl String:szChat[64];
        GetCmdArgString(szChat, sizeof(szChat));
        
        StripQuotes(szChat);
        TrimString(szChat);

        /* !confirmdelete 523 */
        if(strncmp(szChat, "!confirmdelete", 14) == 0)
        {
            /* get token part of the string */
            strcopy(szChat, sizeof(szChat), szChat[15]);
            /* is this the correct token? */
            new iToken = StringToInt(szChat);
            if(iToken == g_iDeleteToken)
            {
                g_iConfirmState[client] = CONFIRM_YES;
                War3Source_DeleteDatabase(client);
            } else {
                /* user entered wrong token, cancel deletion. */
                War3_ChatMessage(client, "Wrong confirmation token! Deletion canceled");
                g_iConfirmState[client] = CONFIRM_NO;
                LogAction(client, -1, "\"%L\" entered wrong war3source database deletion token", client);
            }
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public Action:Command_ResetDB(client,args)
{
    if(g_hDatabase == INVALID_HANDLE)
    {
        ReplyToCommand(client, "[War3Source] No database handle available!");
        return Plugin_Handled;
    }

    if(IS_PLAYER(client))
    {
        if(g_iConfirmState[client] == CONFIRM_NO)
        {
            /* generate confirmation token */
            g_iDeleteToken = GetRandomInt(1, 999);
            g_iConfirmState[client] = CONFIRM_AWAIT;
            
            /* print chatmsgs */
            War3_ChatMessage(client, "You're about to DELETE the entire War3Source database! Are you really sure?");
            War3_ChatMessage(client, "During deletion, all players will be kicked!");
            War3_ChatMessage(client, "Write \"!confirmdelete %d\" in chat to confirm", g_iDeleteToken);
            LogAction(client, -1, "\"%L\" wants to delete war3source database", client);
        } else if(g_iConfirmState[client] == CONFIRM_AWAIT) {
            War3_ChatMessage(client, "Awaiting confirmation... Write \"!confirmdelete %d\" in chat to confirm database deletion", g_iDeleteToken);
        } else if(g_iConfirmState[client] == CONFIRM_YES) {
            War3_ChatMessage(client, "Deletion operation already in progress!");
        }
    } else {
        if(g_iConfirmState[0] == CONFIRM_NO)
        {
            /* show token, wait for confirmation.. */
            g_iDeleteToken = GetRandomInt(1, 999);
            ReplyToCommand(0, "[War3Source] Enter \"war3_resetdb %d\" to confirm war3source database deletion(all players will be kicked)", g_iDeleteToken);
            g_iConfirmState[0] = CONFIRM_AWAIT;
        } else if(g_iConfirmState[client] == CONFIRM_AWAIT) {
            decl String:szToken[64];
            GetCmdArg(1, szToken, sizeof(szToken));
            if(StringToInt(szToken) == g_iDeleteToken)
            {
                ReplyToCommand(0, "[War3Source] Correct token, deletion is in progres..");
                War3Source_DeleteDatabase(0);
            } else {
                ReplyToCommand(0, "[War3Source] Incorrect token, deletion canceled");
                g_iConfirmState[0] = CONFIRM_NO;
            }
        }  else if(g_iConfirmState[client] == CONFIRM_YES) {
            ReplyToCommand(0, "[War3Source] Deletion is already in progress.");
        }
    }
    return Plugin_Handled;
}

public OnClientPutInServer(client)
{
    g_iConfirmState[client] = CONFIRM_NO;
}

public OnWar3Event(W3EVENT:event,client)
{
    if(event == DatabaseConnected)
    {
        g_hDatabase = W3GetVar(hDatabase);
    }
}

// Take care, szTable is not escaped
War3Source_ClearTable(const String:szTable[])
{
    decl String:szQuery[128];
    FormatEx(szQuery, sizeof(szQuery),
        War3SQLType:W3GetVar(hDatabaseType) == SQLType_MySQL ? "TRUNCATE TABLE %s" : "DELETE FROM %s", szTable);
    SQL_FastQueryLogOnError(g_hDatabase, szQuery);
}

War3Source_DeleteDatabase(client)
{
    /* log action before potentially kicking the client */
    LogAction(client, -1, "\"%L\" deleted the war3source database", client);

    /* kick everyone so we can safetly delete their data.. */
    for(new x=1;x<=MaxClients;x++)
    {
        if(ValidPlayer(x))
        {
            /* immediate kick */
            KickClientEx(x, "War3Source Database Reset");
        }
    }

    /* clear the tables */
    War3Source_ClearTable("war3source");
    War3Source_ClearTable("war3source_racedata1");
    if(War3SQLType:W3GetVar(hDatabaseType) == SQLType_SQLite)
    {
        SQL_FastQueryLogOnError(g_hDatabase, "VACUUM");
    }

    g_iConfirmState[client] = CONFIRM_NO;
}