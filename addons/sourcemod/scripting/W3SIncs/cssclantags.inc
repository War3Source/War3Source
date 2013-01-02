#if defined __in_cssclantags_stock
  #endinput
#endif
#define __in_cssclantags_stock

#include <sdktools>

stock CS_GetClientClanTag(client, String:buffer[], size)
{
    static String:startprop[64];
    static offset = -1;
    
    if (startprop[0] == '\0' || offset == -1)
    {
        PrintToServer("Loading css clan tags");
        new Handle:conf = LoadGameConfigFile("cssclantags");
        if (conf == INVALID_HANDLE)
        {
            ThrowError("Cannot find gamedata/cssclantags.txt");
            return;
        }
        
        if (!GameConfGetKeyValue(conf, "ClanTagStart", startprop, sizeof(startprop))
            || (offset = GameConfGetOffset(conf, "ClanTagStartOffset")) == -1)
        {
            CloseHandle(conf);
            ThrowError("Could not find either ClanTagStart or ClanTagStartOffset in gamedata file");
            return;
        }
        
        CloseHandle(conf);
        
        new start = FindSendPropInfo("CCSPlayer", startprop);
        if (start == -1)
        {
            ThrowError("Could not find netprop \"%s\" on CCSPlayer", startprop);
            return;
        }
        
        offset += start;
    }
    
    GetEntDataString(client, offset, buffer, size);
}

stock CS_SetClientClanTag(client, const String:tag[])
{
    static Handle:settag;
    if (settag == INVALID_HANDLE)
    {
        new Handle:conf = LoadGameConfigFile("cssclantags");
        if (conf == INVALID_HANDLE)
        {
            CloseHandle(conf);
            ThrowError("Cannot find gamedata/cssclantag.txt");
            return;
        }
        
        StartPrepSDKCall(SDKCall_Player);
        if (!PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "SetClanTag"))
        {
            CloseHandle(conf);
            ThrowError("SetClanTag not found");
        }
        PrepSDKCall_AddParameter(SDKType_String, SDKPass_Plain);
        settag = EndPrepSDKCall();
        
        CloseHandle(conf);
        
        if (settag == INVALID_HANDLE)
        {
            ThrowError("Failed to create SetClanTag sdkcall");
        }
    }
    
    SDKCall(settag, client, tag);
}
stock FloatToCutString(Float:value, String:target[], targetSize, DecPlaces) {
    decl String:fmt[8];
    FormatEx(fmt, sizeof(fmt), "%%.%df", DecPlaces); // e.g., 2 places = %.2f
    FormatEx(target, targetSize, fmt, value);
}