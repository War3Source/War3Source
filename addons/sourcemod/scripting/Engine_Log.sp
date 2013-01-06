#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Logging",
    author = "War3Source Team",
    description = "Log messages to a file"
};

new War3_LogLevel:iLogLevel;
new iPrintToConsole;

new Handle:g_hLogLevel = INVALID_HANDLE;
new Handle:g_hPrintToServer = INVALID_HANDLE;
new Handle:hW3Log = INVALID_HANDLE;
new Handle:hGlobalErrorFwd = INVALID_HANDLE;

public OnPluginStart()
{
    g_hLogLevel = CreateConVar("war3_log_level", "1", "Set the log level for War3Source", FCVAR_PLUGIN, true, 0.0, true, 4.0); // 0 and 4? I know, ugly :(
    g_hPrintToServer = CreateConVar("war3_log_print_to_server", "1", "Toggle logging to the server console", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    
    iLogLevel = War3_LogLevel:GetConVarInt(g_hLogLevel);
    HookConVarChange(g_hLogLevel, ConVarChange_LogLevel);
    
    iPrintToConsole = GetConVarInt(g_hPrintToServer);
    HookConVarChange(g_hPrintToServer, ConVarChange_PrintToServer)
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
    Format(sLogfilePath, sizeof(sLogfilePath), "logs/war3source_%s.log", sDate)
    
    BuildPath(Path_SM, sLogPath, sizeof(sLogPath), sLogfilePath);
    hW3Log = OpenFile(sLogPath, "a+");

    return APLRes_Success;
}

public bool:InitNativesForwards()
{
    CreateNative("War3_LogInfo", Native_War3_LogInfo);
    CreateNative("War3_LogWarning", Native_War3_LogWarning);
    CreateNative("War3_LogError", Native_War3_LogError);
    CreateNative("War3_LogCritical", Native_War3_LogCritical);
    CreateNative("War3_GetLogLevel", Native_War3_GetLogLevel);

    CreateNative("CreateWar3GlobalError", NCreateWar3GlobalError);
    hGlobalErrorFwd = CreateGlobalForward("OnWar3GlobalError", ET_Ignore, Param_String);
    
    return true;
}


War3_LogGeneric(String:sMessage[])
{
    if(hW3Log != INVALID_HANDLE)
    {
        decl String:sOutput[256];
        decl String:sDate[32];
        FormatTime(sDate, sizeof(sDate), "%c");
        Format(sOutput, sizeof(sOutput), "[%s] %s", sDate, sMessage);
        
        WriteFileLine(hW3Log, sOutput);
        FlushFile(hW3Log);
        
        if(iPrintToConsole)
        {
            PrintToServer(sOutput);
        }
    }
}

public Native_War3_LogCritical(Handle:plugin, numParams)
{
    if(iLogLevel >= LOG_LEVEL_CRITICAL)
    {
        decl String:sMessage[1000];
        FormatNativeString(0, 1, 2, sizeof(sMessage), _, sMessage);
        
        decl String:sOutput[256];
        Format(sOutput, sizeof(sOutput), "CRITICAL: %s", sMessage);
        
        War3_LogGeneric(sOutput);
    }
}

public Native_War3_LogError(Handle:plugin, numParams)
{
    if(iLogLevel >= LOG_LEVEL_ERROR)
    {
        decl String:sMessage[1000];
        FormatNativeString(0, 1, 2, sizeof(sMessage), _, sMessage);
        
        decl String:sOutput[256];
        Format(sOutput, sizeof(sOutput), "ERROR: %s", sMessage);
        
        War3_LogGeneric(sOutput);
    }
}

public Native_War3_LogWarning(Handle:plugin, numParams)
{
    if(iLogLevel >= LOG_LEVEL_WARNING)
    {
        decl String:sMessage[1000];
        FormatNativeString(0, 1, 2, sizeof(sMessage), _, sMessage);
        
        decl String:sOutput[256];
        Format(sOutput, sizeof(sOutput), "WARNING: %s", sMessage);
        
        War3_LogGeneric(sOutput);
    }
}

public Native_War3_LogInfo(Handle:plugin, numParams)
{
    if(iLogLevel >= LOG_LEVEL_INFO)
    {
        decl String:sMessage[1000];
        FormatNativeString(0, 1, 2, sizeof(sMessage), _, sMessage);
        
        decl String:sOutput[256];
        Format(sOutput, sizeof(sOutput), "INFO: %s", sMessage);
        
        War3_LogGeneric(sOutput);
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