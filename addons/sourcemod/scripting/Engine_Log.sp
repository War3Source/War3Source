#include <regex>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Logging",
    author = "War3Source Team",
    description = "Log messages to a file"
};

enum War3_LogSeverity
{
    SEVERITY_CRITICAL,
    SEVERITY_ERROR,
    SEVERITY_WARNING,
    SEVERITY_INFO
};

new War3_LogLevel:iLogLevel;
new iPrintToConsole;

new Handle:g_hLogLevel = INVALID_HANDLE;
new Handle:g_hPrintToServer = INVALID_HANDLE;
new Handle:hW3Log = INVALID_HANDLE;
new Handle:hGlobalErrorFwd = INVALID_HANDLE;

// Log prettifier
new Handle:hRegexRace = INVALID_HANDLE;
new Handle:hRegexItem = INVALID_HANDLE;
new Handle:hRegexSkill = INVALID_HANDLE;
new Handle:hRegexClient = INVALID_HANDLE;
new Handle:hRegexAttribute = INVALID_HANDLE;
new Handle:hRegexID = INVALID_HANDLE;
new Handle:hRegexTag = INVALID_HANDLE;

public OnPluginStart()
{
    g_hLogLevel = CreateConVar("war3_log_level", "1", "Set the log level for War3Source", FCVAR_PLUGIN, true, 0.0, true, 4.0); // 0 and 4? I know, ugly :(
    g_hPrintToServer = CreateConVar("war3_log_print_to_server", "1", "Toggle logging to the server console. Note that critical errors are always printed to the console", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    
    iLogLevel = War3_LogLevel:GetConVarInt(g_hLogLevel);
    HookConVarChange(g_hLogLevel, ConVarChange_LogLevel);
    
    iPrintToConsole = GetConVarInt(g_hPrintToServer);
    HookConVarChange(g_hPrintToServer, ConVarChange_PrintToServer);
    
    // Sadly sourcemod doesn't handle regex groups x_X
    if(hRegexRace == INVALID_HANDLE)
    {
        hRegexRace = CompileRegex("{race (\\d+)}");
    }
    if(hRegexItem == INVALID_HANDLE)
    {
        hRegexItem = CompileRegex("{item (\\d+)}");
    }
    if(hRegexSkill == INVALID_HANDLE)
    {
        hRegexSkill = CompileRegex("{skill (\\d+)}");
    }
    if(hRegexClient == INVALID_HANDLE)
    {
        hRegexClient = CompileRegex("{client (\\d+)}");
    }
    if(hRegexID == INVALID_HANDLE)
    {
        hRegexID = CompileRegex("\\d+");
    }
    if(hRegexTag == INVALID_HANDLE)
    {
        hRegexTag = CompileRegex("{tag}");
    }
    if(hRegexAttribute == INVALID_HANDLE)
    {
        hRegexAttribute = CompileRegex("{attribute (\\d+)}");
    }
}

public ConVarChange_LogLevel(Handle:convar, const String:oldValue[], const String:newValue[])
{
    iLogLevel = War3_LogLevel:StringToInt(newValue);
}

public ConVarChange_PrintToServer(Handle:convar, const String:oldValue[], const String:newValue[])
{
    iPrintToConsole = StringToInt(newValue);
}

public APLRes:AskPluginLoad2Custom(Handle:myself, bool:late, String:error[], err_max)
{
    new String:sLogPath[1024];
    
    decl String:sLogfilePath[64];
    decl String:sDate[32];
    FormatTime(sDate, sizeof(sDate), "%Y%m%d");
    Format(sLogfilePath, sizeof(sLogfilePath), "logs/war3source_%s.log", sDate);
    
    BuildPath(Path_SM, sLogPath, sizeof(sLogPath), sLogfilePath);
    hW3Log = OpenFile(sLogPath, "a+");

    return APLRes_Success;
}

public bool:InitNativesForwards()
{
    LoadTranslations("w3s._common.phrases.txt");
    
    CreateNative("War3_LogInfo", Native_War3_LogInfo);
    CreateNative("War3_LogWarning", Native_War3_LogWarning);
    CreateNative("War3_LogError", Native_War3_LogError);
    CreateNative("War3_LogCritical", Native_War3_LogCritical);
    CreateNative("War3_GetLogLevel", Native_War3_GetLogLevel);

    CreateNative("CreateWar3GlobalError", NCreateWar3GlobalError);
    hGlobalErrorFwd = CreateGlobalForward("OnWar3GlobalError", ET_Ignore, Param_String);
    
    return true;
}

ReadRawFromString(String:sInput[], maxlength, Handle:hRegex)
{
    GetRegexSubString(hRegex, 0, sInput, maxlength);

    decl String:sDummy[128];
    MatchRegex(hRegexID, sInput);
    GetRegexSubString(hRegexID, 0, sDummy, sizeof(sDummy));

    return StringToInt(sDummy);
}

MakeReadable(String:sUnreadable[], maxlength)
{
    // Replace race ids with their name
    while (MatchRegex(hRegexRace, sUnreadable) > 0)
    {
        decl String:sRaceRaw[64];
        new iRaceID = ReadRawFromString(sRaceRaw, sizeof(sRaceRaw), hRegexRace);
        
        decl String:sRaceName[FULLNAMELEN];
        War3_GetRaceName(iRaceID, sRaceName, sizeof(sRaceName));
        
        ReplaceString(sUnreadable, maxlength, sRaceRaw, sRaceName, true);
    }
    
    // Replace item ids with the name
    while (MatchRegex(hRegexItem, sUnreadable) > 0)
    {
        decl String:sItemRaw[64];
        new iItemID = ReadRawFromString(sItemRaw, sizeof(sItemRaw), hRegexItem);
        
        decl String:sItemName[FULLNAMELEN];
        W3GetItemName(iItemID, sItemName, sizeof(sItemName));
        
        ReplaceString(sUnreadable, maxlength, sItemRaw, sItemName, true);
    }
    
    // TODO: Make skill IDs unique :|
    
    /*
    // Replace skill ids with the name
    if(MatchRegex(hRegexSkill, sUnreadable) > 0)
    {
        decl String:sSkillRaw[64];
        new iSkillID = ReadRawFromString(sSkillRaw, sizeof(sSkillRaw), hRegexSkill);
        
        decl String:sSkillName[FULLNAMELEN];
        W3GetRaceSkillName(iSkillID, sSkillName, sizeof(sSkillName));
        
        ReplaceString(sUnreadable, maxlength, sSkillRaw, sSkillName, true);
    }
    */
    // Replace tag with war3source tag
    while (MatchRegex(hRegexTag, sUnreadable) > 0)
    {
        decl String:sTag[64];
        Format(sTag, sizeof(sTag), "%T", "[war3source]", LANG_SERVER);
        
        ReplaceString(sUnreadable, maxlength, "{tag}", sTag, true);
    }
    
    // Replace client ids with the name
    while (MatchRegex(hRegexClient, sUnreadable) > 0)
    {
        decl String:sNameRaw[64];
        new iClientID = ReadRawFromString(sNameRaw, sizeof(sNameRaw), hRegexClient);
        
        new String:sPlayerName[FULLNAMELEN];
        if (ValidPlayer(iClientID))
        {
            GetClientName(iClientID, sPlayerName, sizeof(sPlayerName));
        }
        else
        {
            strcopy(sPlayerName, sizeof(sPlayerName), "invalidplayer");
        }

        ReplaceString(sUnreadable, maxlength, sNameRaw, sPlayerName, true);
    }
    
    // Replace attribute ids with the name
    while (MatchRegex(hRegexAttribute, sUnreadable) > 0)
    {
        decl String:sAttributeRaw[64];
        new iAttributeId = ReadRawFromString(sAttributeRaw, sizeof(sAttributeRaw), hRegexAttribute);
        
        decl String:sAttributeName[FULLNAMELEN];
        War3_GetAttributeName(iAttributeId, sAttributeName, sizeof(sAttributeName));
        
        ReplaceString(sUnreadable, maxlength, sAttributeRaw, sAttributeName, true);
    }
}

War3_LogGeneric(String:sMessage[], maxlength, Handle:hSourcePlugin, War3_LogSeverity:logSeverity)
{
    if(hW3Log != INVALID_HANDLE)
    {
        MakeReadable(sMessage, maxlength);
        
        decl String:sOutput[1000];
        decl String:sFileName[256];
        decl String:sDate[32];
        
        FormatTime(sDate, sizeof(sDate), "%c");
        GetPluginFilename(hSourcePlugin, sFileName, sizeof(sFileName)); 
        Format(sOutput, sizeof(sOutput), "[%s] <%s>: %s", sDate, sFileName, sMessage);
        
        switch (logSeverity)
        {
            case SEVERITY_CRITICAL:
            {
                Format(sOutput, sizeof(sOutput), "CRITICAL: %s", sOutput);
            }
            case SEVERITY_ERROR:
            {
                Format(sOutput, sizeof(sOutput), "ERROR: %s", sOutput);
            }
            case SEVERITY_WARNING:
            {
                Format(sOutput, sizeof(sOutput), "WARNING: %s", sOutput);
            }
            case SEVERITY_INFO:
            {
                Format(sOutput, sizeof(sOutput), "INFO: %s", sOutput);
            }
        }
        
        WriteFileLine(hW3Log, sOutput);
        FlushFile(hW3Log);
        
        if(iPrintToConsole || logSeverity == SEVERITY_CRITICAL)
        {
            PrintToServer(sOutput);
        }
        
        if (logSeverity == SEVERITY_CRITICAL)
        {
            LogError(sOutput);
        }
    }
}

public Native_War3_LogCritical(Handle:plugin, numParams)
{
    if(iLogLevel >= LOG_LEVEL_CRITICAL)
    {
        decl String:sMessage[1000];
        FormatNativeString(0, 1, 2, sizeof(sMessage), _, sMessage);
        
        War3_LogGeneric(sMessage, sizeof(sMessage), plugin, SEVERITY_CRITICAL);
    }
}

public Native_War3_LogError(Handle:plugin, numParams)
{
    if(iLogLevel >= LOG_LEVEL_ERROR)
    {
        decl String:sMessage[1000];
        FormatNativeString(0, 1, 2, sizeof(sMessage), _, sMessage);
        
        War3_LogGeneric(sMessage, sizeof(sMessage), plugin, SEVERITY_ERROR);
    }
}

public Native_War3_LogWarning(Handle:plugin, numParams)
{
    if(iLogLevel >= LOG_LEVEL_WARNING)
    {
        decl String:sMessage[1000];
        FormatNativeString(0, 1, 2, sizeof(sMessage), _, sMessage);
        
        War3_LogGeneric(sMessage, sizeof(sMessage), plugin, SEVERITY_WARNING);
    }
}

public Native_War3_LogInfo(Handle:plugin, numParams)
{
    if(iLogLevel >= LOG_LEVEL_INFO)
    {
        decl String:sMessage[1000];
        FormatNativeString(0, 1, 2, sizeof(sMessage), _, sMessage);
        
        War3_LogGeneric(sMessage, sizeof(sMessage), plugin, SEVERITY_INFO);
    }
}

public Native_War3_GetLogLevel(Handle:plugin, numParams)
{
    return _:iLogLevel;
}

// what is this even good for
public NCreateWar3GlobalError(Handle:plugin, numParams)
{
    decl String:outstr[1000];
    
    FormatNativeString(0, 1, 2, sizeof(outstr), _, outstr);
            
    Call_StartForward(hGlobalErrorFwd);
    Call_PushString(outstr);
    Call_Finish(dummy);
}