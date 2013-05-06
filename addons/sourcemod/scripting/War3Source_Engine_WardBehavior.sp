#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo =
{
    name = "War3Source - Engine - Ward Behavior",
    author = "War3Source Team",
    description="Ward Behavior controller engine"
};
// Ward behavior data structure
new Handle:g_hBehaviorName = INVALID_HANDLE;
new Handle:g_hBehaviorShortname = INVALID_HANDLE;
new Handle:g_hBehaviorDescription = INVALID_HANDLE;


public bool:InitNativesForwards()
{
    CreateNative("War3_CreateWardBehavior", Native_War3_CreateWardBehavior);
    CreateNative("War3_GetWardBehaviorsLoaded", Native_War3_GetWardBehaviorsLoaded);
    CreateNative("War3_GetWardBehaviorName", Native_War3_GetWardBehaviorName);
    CreateNative("War3_GetWardBehaviorShortname", Native_War3_GetWardBehaviorShortname);
    CreateNative("War3_GetWardBehaviorDesc", Native_War3_GetWardBehaviorDesc);
    CreateNative("War3_GetWardBehaviorByShortname", Native_War3_GetWardBehaviorByShortname);

    g_hBehaviorName = CreateArray(WARDNAMELEN);
    g_hBehaviorShortname = CreateArray(WARDSNAMELEN);
    g_hBehaviorDescription = CreateArray(WARDDESCLEN);
    
    return true;
}

public Native_War3_GetWardBehaviorsLoaded(Handle:plugin, numParams)
{
    return GetArraySize(g_hBehaviorShortname);
}

public Native_War3_GetWardBehaviorName(Handle:plugin, numParams)
{
    new id=GetNativeCell(1);
    new maxlen=GetNativeCell(3);

    new String:name[WARDNAMELEN];
    GetBehaviorName(id,name,sizeof(name));
    SetNativeString(2,name,maxlen);
}

public Native_War3_GetWardBehaviorShortname(Handle:plugin, numParams)
{
    new id=GetNativeCell(1);
    new maxlen=GetNativeCell(3);

    new String:shortname[WARDSNAMELEN];
    GetBehaviorShortname(id, shortname, sizeof(shortname));
    SetNativeString(2,shortname,maxlen);
}

public Native_War3_GetWardBehaviorDesc(Handle:plugin, numParams)
{
    new id=GetNativeCell(1);
    new maxlen=GetNativeCell(3);

    new String:desc[WARDDESCLEN];
    GetBehaviorDesc(id,desc,sizeof(desc));
    SetNativeString(2,desc,maxlen);
}

public Native_War3_GetWardBehaviorByShortname(Handle:plugin, numParams)
{
    new String:shortname[WARDSNAMELEN];
    GetNativeString(1,shortname,sizeof(shortname));
    return _:GetWardBehaviorByShortname(shortname);
}

// Non Native getters :)

GetBehaviorShortname(id,String:retstr[],maxlen)
{
    GetArrayString(g_hBehaviorShortname, id, retstr, maxlen);
}

GetBehaviorName(id,String:retstr[],maxlen)
{
    GetArrayString(g_hBehaviorName, id, retstr, maxlen);
}

GetBehaviorDesc(id,String:retstr[],maxlen)
{
    GetArrayString(g_hBehaviorDescription, id, retstr, maxlen);
}

GetWardBehaviorByShortname(String:shortname[])
{
    return FindStringInArray(g_hBehaviorShortname, shortname);
}

// Constructors

public Native_War3_CreateWardBehavior(Handle:plugin, numParams)
{
    decl String:name[WARDNAMELEN], String:shortname[WARDSNAMELEN], String:desc[WARDDESCLEN];
    GetNativeString(1, shortname, sizeof(shortname));
    GetNativeString(2, name, sizeof(name));
    GetNativeString(3, desc, sizeof(desc));

    return CreateWardBehavior(shortname,name,desc);
}

bool:BehaviorExistsByShortname(String:shortname[])
{
    if(FindStringInArray(g_hBehaviorShortname, shortname) != -1)
    {
        return true;
    }
    
    return false;
}

CreateWardBehavior(String:shortname[], String:name[], String:desc[])
{
    if(BehaviorExistsByShortname(shortname))
    {
        new oldid = GetWardBehaviorByShortname(shortname);

        War3_LogInfo("Ward Behavior already exists: %s, returning old behavior id %d", shortname, oldid);
        
        return oldid;
    }

    if (strlen(name) > WARDNAMELEN)
    {
        War3_LogError("[War3] Ward Behavior (%s) name exceeds max length; truncated to %d characters",name,WARDNAMELEN);
    }
    if (strlen(shortname) > WARDSNAMELEN)
    {
        War3_LogError("[War3] Ward Behavior (%s) shortname exceeds max length; truncated to %d characters",shortname,WARDSNAMELEN);
    }
    if (strlen(desc) > WARDDESCLEN)
    {
        War3_LogError("[War3] Ward Behavior (%s) description exceeds max length; truncated to %d characters",desc,WARDDESCLEN);
    }
    PushArrayString(g_hBehaviorName, name);
    PushArrayString(g_hBehaviorShortname, shortname);
    
    return PushArrayString(g_hBehaviorDescription, desc);
}