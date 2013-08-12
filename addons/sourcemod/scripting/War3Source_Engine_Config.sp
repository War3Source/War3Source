#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Config",
    author = "War3Source Team",
    description = "Provides interface for loading values from configs."
}
new Handle:g_hRaceDefaultValues = INVALID_HANDLE;
new Handle:g_hRaceActualValues = INVALID_HANDLE;
new Handle:g_hRaceCachedValues[MAXRACES] = {INVALID_HANDLE, ...};

public bool:InitNativesForwards() 
{
	g_hRaceDefaultValues = CreateKeyValues("defaults");
    /*
    CreateNative("War3_SetRaceConfigString", Native_War3_SetRaceConfigString);
    CreateNative("War3_SetRaceConfigFloat", Native_War3_SetRaceConfigFloat);
    CreateNative("War3_SetRaceConfigInt", Native_War3_SetRaceConfigInt);
    CreateNative("War3_SetRaceConfigBool", Native_War3_SetRaceConfigBool);
    CreateNative("War3_SetRaceConfigArray", Native_War3_SetRaceConfigArray);
    CreateNative("War3_SetRaceGlobalConfigString", Native_War3_SetRaceGlobalConfigString);
    
    CreateNative("War3_GetRaceConfigString", Native_War3_GetRaceConfigString);
    CreateNative("War3_GetRaceConfigFloat", Native_War3_GetRaceConfigFloat);
    CreateNative("War3_GetRaceConfigInt", Native_War3_GetRaceConfigInt);
    CreateNative("War3_GetRaceConfigBool", Native_War3_GetRaceConfigBool);
    CreateNative("War3_GetRaceConfigArray", Native_War3_GetRaceConfigArray);
    CreateNative("War3_SetItemConfigString", Native_War3_SetItemConfigString);
    CreateNative("War3_SetItemConfigFloat", Native_War3_SetItemConfigFloat);
    CreateNative("War3_SetItemConfigInt", Native_War3_SetItemConfigInt);
    CreateNative("War3_SetItemConfigBool", Native_War3_SetItemConfigBool);
    CreateNative("War3_SetItemConfigArray", Native_War3_SetItemConfigArray);
    CreateNative("War3_SetItemGlobalConfigString", Native_War3_SetItemGlobalConfigString);
    
    CreateNative("War3_GetItemConfigString", Native_War3_GetItemConfigString);
    CreateNative("War3_GetItemConfigFloat", Native_War3_GetItemConfigFloat);
    CreateNative("War3_GetItemConfigInt", Native_War3_GetItemConfigInt);
    CreateNative("War3_GetItemConfigBool", Native_War3_GetItemConfigBool);
    CreateNative("War3_GetItemConfigArray", Native_War3_GetItemConfigArray);
	* */
	return true;
}
public OnRaceAdded(raceid, bool:afterPluginReady)
{
	if(afterPluginReady)
	{
		LoadConfig();
	}
}
LoadConfig()
{
	PrintToServer("Loading config!");
	for(new i = 0; i < sizeof(g_hRaceCachedValues); i++)
	{
		if(g_hRaceCachedValues[i] != INVALID_HANDLE)
		{
			CloseHandle(g_hRaceCachedValues[i]);
		}
		g_hRaceCachedValues[i] = CreateTrie();
	}
	if(g_hRaceActualValues != INVALID_HANDLE)
	{
		CloseHandle(g_hRaceActualValues);
	}
	g_hRaceActualValues = CreateKeyValues("Race Config");
	new String:shortname[SHORTNAMELEN];
	for(new i = 1; i < War3_GetRacesLoaded(); i++)
	{
		KvRewind(g_hRaceActualValues);
		KvRewind(g_hRaceDefaultValues);
		War3_GetRaceShortname(i, shortname, sizeof(shortname));
		KvJumpToKey(g_hRaceActualValues, shortname, true);
		if(KvJumpToKey(g_hRaceDefaultValues, "global", true))
		{
			KvCopySubkeys(g_hRaceDefaultValues, g_hRaceActualValues);
		}
	}
	KvRewind(g_hRaceDefaultValues);
	KvRewind(g_hRaceActualValues);
	KvGotoFirstSubKey(g_hRaceDefaultValues);
	KvMergeSubkeys(g_hRaceDefaultValues, g_hRaceActualValues);
	new String:file[PLATFORM_MAX_PATH];
	new Handle:filekv;
	BuildPath(Path_SM, file, sizeof(file), "configs/war3_races.cfg");
	if(FileExists(file))
	{
		KvRewind(g_hRaceActualValues);
		filekv = CreateKeyValues("Race Config");
		FileToKeyValues(filekv, file);
		KvGotoFirstSubKey(filekv);
		KvMergeSubkeys(filekv, g_hRaceActualValues);
		CloseHandle(filekv);
	}
	KeyValuesToFile(g_hRaceActualValues, file);
	new String:mapname[PLATFORM_MAX_PATH];
	GetCurrentMap(mapname, sizeof(mapname));
	BuildPath(Path_SM, file, sizeof(file), "configs/maps/war3_races_%s.cfg", mapname);
	if(FileExists(file))
    {
        KvRewind(g_hRaceActualValues);
        filekv = CreateKeyValues("Race Config");
        FileToKeyValues(filekv, file);
        KvMergeSubkeys(filekv, g_hRaceActualValues);
        CloseHandle(filekv);
    }
	new String:section[512];
	new String:value[512];
	for(new race = 1; race < War3_GetRacesLoaded(); race++)
	{
		new Handle:keys = CreateArray(ByteCountToCells(512));
		KvRewind(g_hRaceActualValues);
		War3_GetRaceName(race, shortname, sizeof(shortname));
		KvJumpToKey(g_hRaceActualValues, shortname);
		do
		{
			KvGetSectionName(g_hRaceActualValues, section, sizeof(section));
			if(KvGotoFirstSubKey(g_hRaceActualValues, false))
			{
				KvGoBack(g_hRaceActualValues);
			}
			else
			{
				PushArrayString(keys, section);
			}
		} while(KvGotoNextKey(g_hRaceActualValues, false));
		for(new i = 0; i < GetArraySize(keys); i++)
		{
			GetArrayString(keys, i, section, sizeof(section));
			KvGetString(g_hRaceActualValues, section, value, sizeof(value));
			SetTrieString(g_hRaceCachedValues[race], section, value);
		}
	}
}
public OnWar3PluginReady()
{
	SetGlobalRaceValue("level", "10");
	KvRewind(g_hRaceDefaultValues);
	KvJumpToKey(g_hRaceDefaultValues, "global", true);
	KvJumpToKey(g_hRaceDefaultValues, "test", true);
	KvSetString(g_hRaceDefaultValues, "test1", "testing");
	KvSetString(g_hRaceDefaultValues, "test2", "testing");
	LoadConfig();
	KvRewind(g_hRaceActualValues);
	KvJumpToKey(g_hRaceActualValues, "undead");
	KvJumpToKey(g_hRaceActualValues, "test");
	new String:value[512];
	KvGetString(g_hRaceActualValues, "test1", value, sizeof(value));
	PrintToServer("Undead has value: %s", value);
}
KvMergeSubkeys(Handle:origin, Handle:destination)
{
	new Handle:keys = CreateArray(ByteCountToCells(512));
	new String:section[512];
	new String:value[512];
	do
	{
		KvGetSectionName(origin, section, sizeof(section));
		if(KvGotoFirstSubKey(origin, false))
		{
			KvJumpToKey(destination, section, true);
			KvMergeSubkeys(origin, destination);
		}
		else
		{
			PushArrayString(keys, section);
		}
	} while(KvGotoNextKey(origin, false));
	KvGoBack(origin);
	for(new i = 0; i < GetArraySize(keys); i++)
	{
		GetArrayString(keys, i, section, sizeof(section));
		KvGetString(origin, section, value, sizeof(value));
		KvSetString(destination, section, value);
	}
	KvGoBack(destination);
}
SetGlobalRaceValue(const String:key[], const String:value[])
{
	SetRaceValue(0, key, value);
}
SetRaceValue(raceid, const String:key[], const String:value[])
{
	new String:shortname[SHORTNAMELEN];
	War3_GetRaceShortname(raceid, shortname, sizeof(shortname));
	KvRewind(g_hRaceDefaultValues);
	KvJumpToKey(g_hRaceDefaultValues, shortname, true);
	KvSetString(g_hRaceDefaultValues, key, value);
}





