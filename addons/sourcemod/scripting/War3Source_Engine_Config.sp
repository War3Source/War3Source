#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Config",
    author = "War3Source Team",
    description = "Provides interface for loading values from configs."
}

new Handle:g_hDefaultRaceValues = INVALID_HANDLE;
new Handle:g_hDefaultItemValues = INVALID_HANDLE;
new Handle:g_hGlobalRaceDefault = INVALID_HANDLE;
new Handle:g_hGlobalItemDefault = INVALID_HANDLE;
new Handle:g_hActualRaceValues = INVALID_HANDLE;
new Handle:g_hActualItemValues = INVALID_HANDLE;

public bool:InitNativesForwards() 
{
    CreateNative("War3_SetRaceConfigString", Native_War3_SetRaceConfigString);
    CreateNative("War3_SetRaceConfigFloat", Native_War3_SetRaceConfigFloat);
    CreateNative("War3_SetRaceConfigInt", Native_War3_SetRaceConfigInt);
    CreateNative("War3_SetRaceConfigBool", Native_War3_SetRaceConfigBool);
    CreateNative("War3_SetRaceConfigArray", Native_War3_SetRaceConfigArray);
    CreateNative("War3_SetRaceConfigArrayValue", Native_War3_SetRaceConfigArrayValue);
    CreateNative("War3_SetRaceGlobalConfigString", Native_War3_SetRaceGlobalConfigString);
    
    CreateNative("War3_GetRaceConfigString", Native_War3_GetRaceConfigString);
    CreateNative("War3_GetRaceConfigFloat", Native_War3_GetRaceConfigFloat);
    CreateNative("War3_GetRaceConfigInt", Native_War3_GetRaceConfigInt);
    CreateNative("War3_GetRaceConfigBool", Native_War3_GetRaceConfigBool);
    CreateNative("War3_GetRaceConfigArray", Native_War3_GetRaceConfigArray);
    CreateNative("War3_GetRaceConfigArrayValue", Native_War3_GetRaceConfigArrayValue);
    CreateNative("War3_GotoRaceConfigArray", Native_War3_GotoRaceConfigArray);
    CreateNative("War3_GetRaceConfigArrayNextValue", Native_War3_GetRaceConfigArrayNextValue);
    
    CreateNative("War3_SetItemConfigString", Native_War3_SetItemConfigString);
    CreateNative("War3_SetItemConfigFloat", Native_War3_SetItemConfigFloat);
    CreateNative("War3_SetItemConfigInt", Native_War3_SetItemConfigInt);
    CreateNative("War3_SetItemConfigBool", Native_War3_SetItemConfigBool);
    CreateNative("War3_SetItemConfigArray", Native_War3_SetItemConfigArray);
    CreateNative("War3_SetItemConfigArrayValue", Native_War3_SetItemConfigArrayValue);
    CreateNative("War3_SetItemGlobalConfigString", Native_War3_SetItemGlobalConfigString);
    
    CreateNative("War3_GetItemConfigString", Native_War3_GetItemConfigString);
    CreateNative("War3_GetItemConfigFloat", Native_War3_GetItemConfigFloat);
    CreateNative("War3_GetItemConfigInt", Native_War3_GetItemConfigInt);
    CreateNative("War3_GetItemConfigBool", Native_War3_GetItemConfigBool);
    CreateNative("War3_GetItemConfigArray", Native_War3_GetItemConfigArray);
    CreateNative("War3_GetItemConfigArrayValue", Native_War3_GetItemConfigArrayValue); 
    CreateNative("War3_GotoItemConfigArray", Native_War3_GotoItemConfigArray);
    CreateNative("War3_GetItemConfigArrayNextValue", Native_War3_GetItemConfigArrayNextValue);
    if(g_hGlobalRaceDefault != INVALID_HANDLE)
    {
        CloseHandle(g_hGlobalRaceDefault);
    }
    g_hGlobalRaceDefault = CreateKeyValues("Global Race Defaults");
    if(g_hGlobalItemDefault != INVALID_HANDLE)
    {
        CloseHandle(g_hGlobalItemDefault);
    }
    g_hGlobalItemDefault = CreateKeyValues("Global Item Defaults");
    if(g_hDefaultRaceValues != INVALID_HANDLE)
    {
        CloseHandle(g_hDefaultRaceValues);
    }
    g_hDefaultRaceValues = CreateKeyValues("Race Defaults");
    if(g_hDefaultItemValues != INVALID_HANDLE)
    {
        CloseHandle(g_hDefaultItemValues);
    }
    g_hDefaultItemValues = CreateKeyValues("Item Defaults");
    return true;
}

public OnWar3PluginReady()
{
    War3_SetRaceGlobalConfigString("restricted_items","Some");
    War3_SetRaceGlobalConfigString("restricted_maps","None");
    War3_SetRaceGlobalConfigString("restricted_other","Some");
    War3_SetRaceGlobalConfigString("restricted_hugalug","None");
    War3_SetRaceGlobalConfigString("restricted_blah","Some");
    War3_SetRaceGlobalConfigString("restricted_blah23","Some");
    //ReloadConfig();
}

ReloadConfig()
{
    if(g_hActualRaceValues != INVALID_HANDLE) 
    {
        CloseHandle(g_hActualRaceValues);
    }
    g_hActualRaceValues = CreateKeyValues("Race Config");
    KvRewind(g_hGlobalRaceDefault);
    // Adds global defaults to each race's KV section
    new String:shortname[SHORTNAMELEN];
    new String:name[FULLNAMELEN];
    for(new i = 1; i < War3_GetRacesLoaded(); i++) 
    {
        KvRewind(g_hActualRaceValues);
        War3_GetRaceShortname(i, shortname, sizeof(shortname));
        KvJumpToKey(g_hActualRaceValues, shortname, true);
        KvCopySubkeys(g_hGlobalRaceDefault, g_hActualRaceValues);
        War3_GetRaceName(i, name, sizeof(name));
        KvSetString(g_hActualRaceValues, "name", name);
    }
    KvRewind(g_hActualRaceValues);
    KvRewind(g_hDefaultRaceValues);
    KvGotoFirstSubKey(g_hDefaultRaceValues);
    // Merges specific race defaults to the global KV
    KvMergeSubkeys(g_hDefaultRaceValues, g_hActualRaceValues);
    new String:file[PLATFORM_MAX_PATH];
    new Handle:kv;
    BuildPath(Path_SM, file, sizeof(file), "configs/war3source_races.cfg");
    if(FileExists(file))
    {
        KvRewind(g_hActualRaceValues);
        kv = CreateKeyValues("Race Config");
        FileToKeyValues(kv, file);
        KvGotoFirstSubKey(kv);
        // Merges in the server specific race config (ideally overriding only keys 
        KvMergeSubkeys(kv, g_hActualRaceValues);
        CloseHandle(kv);
    }
    KvRewind(g_hActualRaceValues);
    KeyValuesToFile(g_hActualRaceValues, file);
    /*
    new String:mapname[32];
    GetCurrentMap(mapname, sizeof(mapname));
    BuildPath(Path_SM, file, sizeof(file), "configs/maps/war3source_races_%s.cfg", mapname);
    if(FileExists(file))
    {
        KvRewind(g_hActualRaceValues);
        kv = CreateKeyValues("Race Config");
        FileToKeyValues(kv, file);
        KvMergeSubkeys(kv, g_hActualRaceValues);
        CloseHandle(kv);
    } */
 /*   
    if(g_hActualItemValues != INVALID_HANDLE) 
    {
        CloseHandle(g_hActualItemValues);
    }
    g_hActualItemValues = CreateKeyValues("Item Values");
    KvRewind(g_hGlobalItemDefault);
    for(new i = 1; i < W3GetItemsLoaded(); i++) 
    {
        KvRewind(g_hActualItemValues);
        W3GetItemShortname(i, shortname, sizeof(shortname));
        KvJumpToKey(g_hActualItemValues, shortname, true);
        KvMergeSubkeys(g_hGlobalItemDefault,g_hActualItemValues);
    }
    KvRewind(g_hActualItemValues);
    KvRewind(g_hDefaultItemValues);
    KvMergeSubkeys(g_hDefaultItemValues, g_hActualItemValues);
    BuildPath(Path_SM, file, sizeof(file), "configs/war3source_items.cfg");
    if(FileExists(file))
    {
        kv = CreateKeyValues("Item Config");
        FileToKeyValues(kv, file);
        KvMergeSubkeys(kv, g_hActualItemValues);
        CloseHandle(kv);
    }
    KeyValuesToFile(g_hActualItemValues, file);
    GetCurrentMap(mapname, sizeof(mapname));
    BuildPath(Path_SM, file, sizeof(file), "configs/maps/war3source_Items_%s.cfg", mapname);
    if(FileExists(file))
    {
        kv = CreateKeyValues("Item Config");
        FileToKeyValues(kv, file);
        KvMergeSubkeys(kv, g_hActualItemValues);
        CloseHandle(kv);
    }*/
}

public Native_War3_GetRaceConfigString(Handle:plugin, numParams)
{
    new raceid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    War3_GetRaceShortname(raceid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultRaceValues);
    KvJumpToKey(g_hDefaultRaceValues, shortname);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    GetNativeString(2, key, keylen);
    new valuelen;
    GetRealNativeStringLength(3, valuelen);
    new String:value[valuelen];
    KvGetString(g_hDefaultRaceValues, key, value, valuelen);
    SetNativeString(3, value, valuelen);
}

public Native_War3_GetRaceConfigFloat(Handle:plugin, numParams)
{
    new raceid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    War3_GetRaceShortname(raceid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultRaceValues);
    KvJumpToKey(g_hDefaultRaceValues, shortname);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    GetNativeString(2, key, keylen);
    return _:KvGetFloat(g_hDefaultRaceValues, key);
}

public Native_War3_GetRaceConfigInt(Handle:plugin, numParams)
{
    new raceid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    War3_GetRaceShortname(raceid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultRaceValues);
    KvJumpToKey(g_hDefaultRaceValues, shortname);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    GetNativeString(2, key, keylen);
    return KvGetNum(g_hDefaultRaceValues, key);
}

public Native_War3_GetRaceConfigBool(Handle:plugin, numParams)
{
    new raceid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    War3_GetRaceShortname(raceid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultRaceValues);
    KvJumpToKey(g_hDefaultRaceValues, shortname);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    GetNativeString(2, key, keylen);
    return bool:KvGetNum(g_hDefaultRaceValues, key);
}

public Native_War3_GetRaceConfigArray(Handle:plugin, numParams)
{
    new raceid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    War3_GetRaceShortname(raceid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultRaceValues);
    KvJumpToKey(g_hDefaultRaceValues, shortname);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    GetNativeString(2, key, keylen);
    new arraylen = GetNativeCell(4);
    new KvDataTypes:type = GetNativeCell(5);
    new any:array[arraylen];
    KvJumpToKey(g_hDefaultRaceValues, key);
    new index = 0;
    new String:section[32];
    if(KvGotoFirstSubKey(g_hDefaultRaceValues, false))
    {
        do
        {
            if(index < arraylen)
            {
                KvGetSectionName(g_hDefaultRaceValues, section, sizeof(section));
                if(type == KvData_Float)
                {
                    array[index] = KvGetFloat(g_hDefaultRaceValues, section);
                } else if(type == KvData_Int) {
                    array[index] = KvGetNum(g_hDefaultRaceValues, section);
                } else {
                    return -1;
                }
            } else {
                break;
            }
            index ++;
        } while(KvGotoNextKey(g_hDefaultRaceValues, false));
    }
    SetNativeArray(3, array, arraylen);
    return 1;
}

public Native_War3_GetRaceConfigArrayValue(Handle:plugin, numParams)
{
    new raceid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    War3_GetRaceShortname(raceid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultRaceValues);
    KvJumpToKey(g_hDefaultRaceValues, shortname);
    new arraylen;
    GetRealNativeStringLength(2, arraylen);
    new String:array[arraylen];
    GetNativeString(2, array, arraylen);
    new keylen;
    GetRealNativeStringLength(3, keylen);
    new String:key[keylen];
    GetNativeString(3, key, keylen);
    new valuelen;
    GetRealNativeStringLength(4, valuelen);
    new String:value[valuelen];
    GetNativeString(4, value, valuelen);
    KvJumpToKey(g_hDefaultRaceValues, array);
    KvGetString(g_hDefaultItemValues, key, value, valuelen);
}

public Native_War3_SetRaceConfigString(Handle:plugin, numParams)
{
    new raceid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    War3_GetRaceShortname(raceid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultRaceValues);
    KvJumpToKey(g_hDefaultRaceValues, shortname);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    GetNativeString(2, key, keylen);
    new valuelen;
    GetRealNativeStringLength(3, valuelen);
    new String:value[valuelen];
    GetNativeString(3, value, valuelen);
    KvSetString(g_hDefaultRaceValues, key, value);
}

public Native_War3_SetRaceConfigFloat(Handle:plugin, numParams)
{
    new raceid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    War3_GetRaceShortname(raceid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultRaceValues);
    KvJumpToKey(g_hDefaultRaceValues, shortname);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    GetNativeString(2, key, keylen);
    KvSetFloat(g_hDefaultRaceValues, key, GetNativeCell(3));
}

public Native_War3_SetRaceConfigInt(Handle:plugin, numParams)
{
    new raceid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    War3_GetRaceShortname(raceid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultRaceValues);
    KvJumpToKey(g_hDefaultRaceValues, shortname);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    GetNativeString(2, key, keylen);
    KvSetNum(g_hDefaultRaceValues, key, GetNativeCell(3));
}

public Native_War3_SetRaceConfigBool(Handle:plugin, numParams)
{
    new raceid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    War3_GetRaceShortname(raceid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultRaceValues);
    KvJumpToKey(g_hDefaultRaceValues, shortname);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    GetNativeString(2, key, keylen);
    KvSetNum(g_hDefaultRaceValues, key, GetNativeCell(3));
}

public Native_War3_SetRaceConfigArray(Handle:plugin, numParams)
{
    new raceid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    War3_GetRaceShortname(raceid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultRaceValues);
    KvJumpToKey(g_hDefaultRaceValues, shortname);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    GetNativeString(2, key, keylen);
    new arraylen = GetNativeCell(4);
    new KvDataTypes:type = GetNativeCell(5);
    new any:array[arraylen];
    KvJumpToKey(g_hDefaultRaceValues, key);
    new String:index[8];
    for(new i = 0; i < arraylen; i++)
    {
        IntToString(i, index, sizeof(index));
        if(type == KvData_Float)
        {
            KvSetFloat(g_hDefaultRaceValues, index, array[i]);
        } else if(type == KvData_Int) {
            KvSetNum(g_hDefaultRaceValues, index, array[i]);
        } else {
            return -1;
        }
    }
    return 1;
}

public Native_War3_SetRaceConfigArrayValue(Handle:plugin, numParams)
{
    new raceid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    War3_GetRaceShortname(raceid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultRaceValues);
    KvJumpToKey(g_hDefaultRaceValues, shortname);
    new arraylen;
    GetRealNativeStringLength(2, arraylen);
    new String:array[arraylen];
    GetNativeString(2, array, arraylen);
    new keylen;
    GetRealNativeStringLength(3, keylen);
    new String:key[keylen];
    GetNativeString(3, key, keylen);
    new valuelen;
    GetRealNativeStringLength(4, valuelen);
    new String:value[valuelen];
    GetNativeString(4, value, valuelen);
    KvJumpToKey(g_hDefaultRaceValues, array);
    KvSetString(g_hDefaultItemValues, key, value);
}

public Native_War3_SetRaceGlobalConfigString(Handle:plugin, numParams)
{
    KvRewind(g_hGlobalRaceDefault);
    new keylen;
    GetRealNativeStringLength(1, keylen);
    new String:key[keylen];
    GetNativeString(1, key, keylen);
    new valuelen;
    GetRealNativeStringLength(2, valuelen);
    new String:value[valuelen];
    GetNativeString(2, value, valuelen);
    KvSetString(g_hGlobalRaceDefault, key, value);
    PrintToServer("Adding new global key: %s and value: %s", key, value);
}

public Native_War3_GotoRaceConfigArray(Handle:plugin, numParams)
{
    new Raceid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    War3_GetRaceShortname(Raceid, shortname, sizeof(shortname));
    KvRewind(g_hActualRaceValues);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    KvJumpToKey(g_hActualRaceValues, shortname);
    KvJumpToKey(g_hActualRaceValues, key);
}

public Native_War3_GetRaceConfigArrayNextValue(Handle:plugin, numParams)
{
    if(KvGotoNextKey(g_hActualRaceValues, false))
    {
        new String:key[32];
        new valuelen;
        GetRealNativeStringLength(1, valuelen);
        new String:value[valuelen];
        KvGetSectionName(g_hActualRaceValues, key, sizeof(key));
        KvGetString(g_hActualRaceValues, key, value, valuelen);
        return true;
    }
    return false;
}

public Native_War3_GetItemConfigString(Handle:plugin, numParams)
{
    new Itemid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    W3GetItemShortname(Itemid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultItemValues);
    KvJumpToKey(g_hDefaultItemValues, shortname);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    GetNativeString(2, key, keylen);
    new valuelen;
    GetRealNativeStringLength(3, valuelen);
    new String:value[valuelen];
    KvGetString(g_hDefaultItemValues, key, value, valuelen);
    SetNativeString(3, value, valuelen);
}

public Native_War3_GetItemConfigFloat(Handle:plugin, numParams)
{
    new Itemid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    W3GetItemShortname(Itemid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultItemValues);
    KvJumpToKey(g_hDefaultItemValues, shortname);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    GetNativeString(2, key, keylen);
    return _:KvGetFloat(g_hDefaultItemValues, key);
}

public Native_War3_GetItemConfigInt(Handle:plugin, numParams)
{
    new Itemid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    W3GetItemShortname(Itemid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultItemValues);
    KvJumpToKey(g_hDefaultItemValues, shortname);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    GetNativeString(2, key, keylen);
    return KvGetNum(g_hDefaultItemValues, key);
}

public Native_War3_GetItemConfigBool(Handle:plugin, numParams)
{
    new Itemid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    W3GetItemShortname(Itemid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultItemValues);
    KvJumpToKey(g_hDefaultItemValues, shortname);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    GetNativeString(2, key, keylen);
    return bool:KvGetNum(g_hDefaultItemValues, key);
}

public Native_War3_GetItemConfigArray(Handle:plugin, numParams)
{
    new Itemid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    W3GetItemShortname(Itemid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultItemValues);
    KvJumpToKey(g_hDefaultItemValues, shortname);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    GetNativeString(2, key, keylen);
    new arraylen = GetNativeCell(4);
    new KvDataTypes:type = GetNativeCell(5);
    new any:array[arraylen];
    KvJumpToKey(g_hDefaultItemValues, key);
    new index = 0;
    new String:section[32];
    if(KvGotoFirstSubKey(g_hDefaultItemValues, false))
    {
        do
        {
            if(index < arraylen)
            {
                KvGetSectionName(g_hDefaultItemValues, section, sizeof(section));
                if(type == KvData_Float)
                {
                    array[index] = KvGetFloat(g_hDefaultItemValues, section);
                } else if(type == KvData_Int) {
                    array[index] = KvGetNum(g_hDefaultItemValues, section);
                } else {
                    return -1;
                }
            } else {
                break;
            }
            index ++;
        } while(KvGotoNextKey(g_hDefaultItemValues, false));
    }
    SetNativeArray(3, array, arraylen);
    return 1;
}

public Native_War3_GetItemConfigArrayValue(Handle:plugin, numParams)
{
    new Itemid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    W3GetItemShortname(Itemid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultItemValues);
    KvJumpToKey(g_hDefaultItemValues, shortname);
    new arraylen;
    GetRealNativeStringLength(2, arraylen);
    new String:array[arraylen];
    GetNativeString(2, array, arraylen);
    new keylen;
    GetRealNativeStringLength(3, keylen);
    new String:key[keylen];
    GetNativeString(3, key, keylen);
    new valuelen;
    GetRealNativeStringLength(4, valuelen);
    new String:value[valuelen];
    GetNativeString(4, value, valuelen);
    KvJumpToKey(g_hDefaultItemValues, array);
    KvGetString(g_hDefaultItemValues, key, value, valuelen);
}

public Native_War3_SetItemConfigString(Handle:plugin, numParams)
{
    new Itemid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    W3GetItemShortname(Itemid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultItemValues);
    KvJumpToKey(g_hDefaultItemValues, shortname);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    GetNativeString(2, key, keylen);
    new valuelen;
    GetRealNativeStringLength(3, valuelen);
    new String:value[valuelen];
    GetNativeString(3, value, valuelen);
    KvSetString(g_hDefaultItemValues, key, value);
}

public Native_War3_SetItemConfigFloat(Handle:plugin, numParams)
{
    new Itemid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    W3GetItemShortname(Itemid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultItemValues);
    KvJumpToKey(g_hDefaultItemValues, shortname);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    GetNativeString(2, key, keylen);
    KvSetFloat(g_hDefaultItemValues, key, GetNativeCell(3));
}

public Native_War3_SetItemConfigInt(Handle:plugin, numParams)
{
    new Itemid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    W3GetItemShortname(Itemid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultItemValues);
    KvJumpToKey(g_hDefaultItemValues, shortname);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    GetNativeString(2, key, keylen);
    KvSetNum(g_hDefaultItemValues, key, GetNativeCell(3));
}

public Native_War3_SetItemConfigBool(Handle:plugin, numParams)
{
    new Itemid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    W3GetItemShortname(Itemid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultItemValues);
    KvJumpToKey(g_hDefaultItemValues, shortname);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    GetNativeString(2, key, keylen);
    KvSetNum(g_hDefaultItemValues, key, GetNativeCell(3));
}

public Native_War3_SetItemConfigArray(Handle:plugin, numParams)
{
    new Itemid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    W3GetItemShortname(Itemid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultItemValues);
    KvJumpToKey(g_hDefaultItemValues, shortname);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    GetNativeString(2, key, keylen);
    new arraylen = GetNativeCell(4);
    new KvDataTypes:type = GetNativeCell(5);
    new any:array[arraylen];
    KvJumpToKey(g_hDefaultItemValues, key);
    new String:index[8];
    for(new i = 0; i < arraylen; i++)
    {
        IntToString(i, index, sizeof(index));
        if(type == KvData_Float)
        {
            KvSetFloat(g_hDefaultItemValues, index, array[i]);
        } else if(type == KvData_Int) {
            KvSetNum(g_hDefaultItemValues, index, array[i]);
        } else {
            return -1;
        }
    }
    return 1;
}

public Native_War3_SetItemConfigArrayValue(Handle:plugin, numParams)
{
    new Itemid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    W3GetItemShortname(Itemid, shortname, sizeof(shortname));
    KvRewind(g_hDefaultItemValues);
    KvJumpToKey(g_hDefaultItemValues, shortname);
    new arraylen;
    GetRealNativeStringLength(2, arraylen);
    new String:array[arraylen];
    GetNativeString(2, array, arraylen);
    new keylen;
    GetRealNativeStringLength(3, keylen);
    new String:key[keylen];
    GetNativeString(3, key, keylen);
    new valuelen;
    GetRealNativeStringLength(4, valuelen);
    new String:value[valuelen];
    GetNativeString(4, value, valuelen);
    KvJumpToKey(g_hDefaultItemValues, array);
    KvSetString(g_hDefaultItemValues, key, value);
}

public Native_War3_SetItemGlobalConfigString(Handle:plugin, numParams)
{
    KvRewind(g_hGlobalItemDefault);
    new keylen;
    GetRealNativeStringLength(1, keylen);
    new String:key[keylen];
    GetNativeString(1, key, keylen);
    new valuelen;
    GetRealNativeStringLength(2, valuelen);
    new String:value[valuelen];
    GetNativeString(2, value, valuelen);
    KvSetString(g_hGlobalItemDefault, key, value);
}

public Native_War3_GotoItemConfigArray(Handle:plugin, numParams)
{
    new Itemid = GetNativeCell(1);
    new String:shortname[SHORTNAMELEN];
    W3GetItemShortname(Itemid, shortname, sizeof(shortname));
    KvRewind(g_hActualItemValues);
    new keylen;
    GetRealNativeStringLength(2, keylen);
    new String:key[keylen];
    KvJumpToKey(g_hActualItemValues, shortname);
    KvJumpToKey(g_hActualItemValues, key);
}

public Native_War3_GetItemConfigArrayNextValue(Handle:plugin, numParams)
{
    if(KvGotoNextKey(g_hActualItemValues, false))
    {
        new String:key[32];
        new valuelen;
        GetRealNativeStringLength(1, valuelen);
        new String:value[valuelen];
        KvGetSectionName(g_hActualItemValues, key, sizeof(key));
        KvGetString(g_hActualItemValues, key, value, valuelen);
        return true;
    }

    return false;
}

GetRealNativeStringLength(index, &length)
{
    GetNativeStringLength(index, length);
    length++;
}

KvMergeSubkeys(Handle:origin, Handle:dest)
{
    new String:section[256];
    do
    {
        KvGetSectionName(origin, section, sizeof(section));
        KvJumpToKey(dest, section, true);
        KvCopySubkeys(origin, dest);
        PrintToServer("Merging: %s", section);
        
    } while (KvGotoNextKey(origin));
}



