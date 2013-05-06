#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo =
{
    name = "War3Source - Warcraft Extended - Wards",
    author = "War3Source Team",
    description="Generic ward skill"
};

// Ward data structure... NO COMMENTS~
new Handle:g_hWardOwner = INVALID_HANDLE;
new Handle:g_hWardRadius = INVALID_HANDLE;
new Handle:g_hWardLocation = INVALID_HANDLE;
new Handle:g_hWardDuration = INVALID_HANDLE;
new Handle:g_hWardTimerInterval = INVALID_HANDLE;
new Handle:g_hWardTimerDuration = INVALID_HANDLE;
new Handle:g_hWardSelfInflict = INVALID_HANDLE;
new Handle:g_hWardAffinity = INVALID_HANDLE;
new Handle:g_hWardInterval = INVALID_HANDLE;
new Handle:g_hWardBehavior = INVALID_HANDLE;
new Handle:g_hWardSkill = INVALID_HANDLE;
new Handle:g_hWardData = INVALID_HANDLE;
new Handle:g_hWardUseDefaultColors = INVALID_HANDLE;
new Handle:g_hWardColor2 = INVALID_HANDLE;
new Handle:g_hWardColor3 = INVALID_HANDLE;
new Handle:g_hWardEnabled = INVALID_HANDLE;

// Ward behavior data structure
new Handle:g_hBehaviorName = INVALID_HANDLE;
new Handle:g_hBehaviorShortname = INVALID_HANDLE;
new Handle:g_hBehaviorDescription = INVALID_HANDLE;

// Event handles
new Handle:g_OnWardCreatedHandle = INVALID_HANDLE;
new Handle:g_OnWardPulseHandle = INVALID_HANDLE;
new Handle:g_OnWardTriggerHandle = INVALID_HANDLE;
new Handle:g_OnWardExpireHandle = INVALID_HANDLE;

new g_iPlayerWardCount[MAXPLAYERSCUSTOM];

public OnPluginStart()
{
    HookEvent("round_end", Event_RoundEnd);
}

public OnClientConnected(client)
{
    g_iPlayerWardCount[client] = 0;
}

public bool:InitNativesForwards()
{
    g_OnWardCreatedHandle = CreateGlobalForward("OnWardCreated", ET_Ignore, Param_Cell, Param_Cell);
    g_OnWardPulseHandle = CreateGlobalForward("OnWardPulse", ET_Ignore, Param_Cell, Param_Cell);
    g_OnWardTriggerHandle = CreateGlobalForward("OnWardTrigger", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
    g_OnWardExpireHandle = CreateGlobalForward("OnWardExpire", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

    CreateNative("War3_CreateWardBehavior", Native_War3_CreateWardBehavior);
    CreateNative("War3_GetWardBehaviorsLoaded", Native_War3_GetWardBehaviorsLoaded);
    CreateNative("War3_GetWardBehaviorName", Native_War3_GetWardBehaviorName);
    CreateNative("War3_GetWardBehaviorShortname", Native_War3_GetWardBehaviorShortname);
    CreateNative("War3_GetWardBehaviorDesc", Native_War3_GetWardBehaviorDesc);
    CreateNative("War3_GetWardBehaviorByShortname", Native_War3_GetWardBehaviorByShortname);

    CreateNative("War3_CreateWard", Native_War3_CreateWard);
    CreateNative("War3_GetWardBehavior", Native_War3_GetWardBehavior);
    CreateNative("War3_GetWardLocation", Native_War3_GetWardLocation);
    CreateNative("War3_GetWardInterval", Native_War3_GetWardInterval);
    CreateNative("War3_GetWardRadius", Native_War3_GetWardRadius);
    CreateNative("War3_GetWardOwner", Native_War3_GetWardOwner);
    CreateNative("War3_GetWardData", Native_War3_GetWardData);
    CreateNative("War3_GetWardUseDefaultColor", Native_War3_GetWardUseDefaultColor);
    CreateNative("War3_GetWardColor2", Native_War3_GetWardColor2);
    CreateNative("War3_GetWardColor3", Native_War3_GetWardColor3);
    CreateNative("War3_GetWardSkill", Native_War3_GetWardSkill);
    CreateNative("War3_GetWardCount", Native_War3_GetWardCount);
    CreateNative("War3_RemoveWard", Native_War3_RemoveWard);
    
    // Initialize the data structure arrays
    g_hWardOwner = CreateArray(1);
    g_hWardRadius = CreateArray(1);
    g_hWardLocation = CreateArray(3);
    g_hWardDuration = CreateArray(1);
    g_hWardTimerInterval = CreateArray(1);
    g_hWardTimerDuration = CreateArray(1);
    g_hWardSelfInflict = CreateArray(1);
    g_hWardAffinity = CreateArray(1);
    g_hWardInterval = CreateArray(1);
    g_hWardBehavior = CreateArray(1);
    g_hWardSkill = CreateArray(1);
    g_hWardUseDefaultColors = CreateArray(1);
    g_hWardEnabled = CreateArray(1);
    g_hWardColor2 = CreateArray(4);
    g_hWardColor3 = CreateArray(4);
    g_hWardData = CreateArray(MAXWARDDATA);

    g_hBehaviorName = CreateArray(WARDNAMELEN);
    g_hBehaviorShortname = CreateArray(WARDSNAMELEN);
    g_hBehaviorDescription = CreateArray(WARDDESCLEN);
    
    return true;
}

// Native getters to access the data structure
public Native_War3_GetWardCount(Handle:plugin, numParams)
{
    return g_iPlayerWardCount[GetNativeCell(1)];
}

public Native_War3_GetWardUseDefaultColor(Handle:plugin, numParams)
{
    return bool:GetArrayCell(g_hWardUseDefaultColors, GetNativeCell(1));
}

public Native_War3_GetWardSkill(Handle:plugin, numParams)
{
    return GetArrayCell(g_hWardSkill, GetNativeCell(1));
}

public Native_War3_GetWardColor2(Handle:plugin, numParams)
{
    new color[4];
    GetArrayArray(g_hWardColor2, GetNativeCell(1), color);
    SetNativeArray(2, color, sizeof(color));
}

public Native_War3_GetWardColor3(Handle:plugin, numParams)
{
    new color[4];
    GetArrayArray(g_hWardColor3, GetNativeCell(1), color);
    SetNativeArray(2, color, sizeof(color));
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

public Native_War3_GetWardBehavior(Handle:plugin, numParams)
{
    return GetArrayCell(g_hWardBehavior, GetNativeCell(1));
}

public Native_War3_GetWardLocation(Handle:plugin, numParams)
{
    new Float:location[3];
    GetArrayArray(g_hWardLocation, GetNativeCell(1), location);
    SetNativeArray(2,location,3);
}

public Native_War3_GetWardInterval(Handle:plugin, numParams)
{
    return GetArrayCell(g_hWardInterval, GetNativeCell(1));
}

public Native_War3_GetWardRadius(Handle:plugin, numParams)
{
    return GetArrayCell(g_hWardRadius,GetNativeCell(1));
}

public Native_War3_GetWardOwner(Handle:plugin, numParams)
{
    return GetArrayCell(g_hWardOwner, GetNativeCell(1));
}

public Native_War3_GetWardData(Handle:plugin, numParams)
{
    new data[MAXWARDDATA];
    GetArrayArray(g_hWardData, GetNativeCell(1), data);
    SetNativeArray(2,data,MAXWARDDATA);
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

public Native_War3_CreateWard(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);

    if(W3Denyable(DN_CanPlaceWard, client))
    {
        new id = PushArrayCell(g_hWardOwner, client);
        new Float:location[3];
        GetNativeArray(2,location,3);
        PushArrayArray(g_hWardLocation, location);
        PushArrayCell(g_hWardRadius, GetNativeCell(3));
        PushArrayCell(g_hWardDuration, GetNativeCell(4));
        PushArrayCell(g_hWardInterval, GetNativeCell(5));

        new String:behavior[WARDSNAMELEN];
        GetNativeString(6,behavior,sizeof(behavior));
        PushArrayCell(g_hWardBehavior, GetWardBehaviorByShortname(behavior));
        PushArrayCell(g_hWardSkill, GetNativeCell(7));
        new any:data[MAXWARDDATA];
        GetNativeArray(8,data,MAXWARDDATA);
        PushArrayArray(g_hWardData, data);
        PushArrayCell(g_hWardAffinity, GetNativeCell(9));
        PushArrayCell(g_hWardSelfInflict, GetNativeCell(10));
        PushArrayCell(g_hWardTimerInterval, CreateTimer(GetArrayCell(g_hWardInterval, id),WardPulse,id,TIMER_REPEAT));
        PushArrayCell(g_hWardUseDefaultColors, GetNativeCell(11));
        new color[4];
        GetNativeArray(12, color, sizeof(color));
        PushArrayArray(g_hWardColor2, color);
        GetNativeArray(13, color, sizeof(color));
        PushArrayArray(g_hWardColor3, color);
        if (GetArrayCell(g_hWardDuration,id) > 0)
        {
            PushArrayCell(g_hWardTimerDuration, CreateTimer(GetArrayCell(g_hWardDuration,id),TimedRemoveWard,id));
        } else
        {
            PushArrayCell(g_hWardTimerDuration, INVALID_HANDLE);
        }
        g_iPlayerWardCount[client]++;
        Call_StartForward(g_OnWardCreatedHandle);
        Call_PushCell(id);
        Call_PushCell(GetArrayCell(g_hWardBehavior, id));
        Call_Finish();
        PushArrayCell(g_hWardEnabled, 1);
        return id;

    }
    return -1;
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
        new oldid=GetWardBehaviorByShortname(shortname);
        PrintToServer("Ward Behavior already exists: %s, returning old behavior id %d",shortname,oldid);
        return oldid;
    }

    if (strlen(name) > WARDNAMELEN)
    {
        LogError("[War3] Ward Behavior (%s) name exceeds max length; truncated to %d characters",name,WARDNAMELEN);
    }
    if (strlen(shortname) > WARDSNAMELEN)
    {
        LogError("[War3] Ward Behavior (%s) shortname exceeds max length; truncated to %d characters",shortname,WARDSNAMELEN);
    }
    if (strlen(desc) > WARDDESCLEN)
    {
        LogError("[War3] Ward Behavior (%s) description exceeds max length; truncated to %d characters",desc,WARDDESCLEN);
    }
    PushArrayString(g_hBehaviorName, name);
    PushArrayString(g_hBehaviorShortname, shortname);
    return PushArrayString(g_hBehaviorDescription, desc);
}

public Action:WardPulse(Handle:timer,any:id)
{
    if(!bool:GetArrayCell(g_hWardEnabled, id))
    {
        return Plugin_Continue;
    }
    new owner = GetArrayCell(g_hWardOwner, id);

    if (!ValidPlayer(owner, true))
    {
        RemoveWards(owner);
        return Plugin_Continue;
    }

    Call_StartForward(g_OnWardPulseHandle);
    Call_PushCell(id);
    Call_PushCell(GetArrayCell(g_hWardBehavior, id));
    Call_Finish();

    new Float:start_pos[3];
    new Float:vec[3];
    GetArrayArray(g_hWardLocation, id, vec);
    new Float:tempvec[3] =
    {   0.0,0.0,WARDBELOW};
    AddVectors(vec,tempvec,start_pos);
    new Float:BeamXY[3];
    for(new x=0;x<3;x++) BeamXY[x]=start_pos[x]; //only compare xy
    new Float:BeamZ= BeamXY[2];
    BeamXY[2]=0.0;
    new Float:VictimPos[3];
    new Float:tempZ;

    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i,true))
        {
            if (i == owner)
            {
                if (!bool:GetArrayCell(g_hWardSelfInflict, id))
                {
                    continue;
                }
            } else if (GetClientTeam(i) == GetClientTeam(owner))
            {
                if (GetArrayCell(g_hWardAffinity, id) == ENEMIES || GetArrayCell(g_hWardAffinity, id) == SELF_ONLY)
                {
                    continue;
                }
            } else
            {
                if (GetArrayCell(g_hWardAffinity, id) == ALLIES || GetArrayCell(g_hWardAffinity, id) == SELF_ONLY)
                {
                    continue;
                }
            }

            GetClientAbsOrigin(i,VictimPos);
            tempZ=VictimPos[2];
            VictimPos[2]=0.0; //no Z
            if(RoundToFloor(GetVectorDistance(BeamXY,VictimPos)) < GetArrayCell(g_hWardRadius, id))////ward RADIUS
            {
                // now compare z
                if(tempZ>BeamZ+WARDBELOW && tempZ < BeamZ+WARDABOVE)
                {
                    Call_StartForward(g_OnWardTriggerHandle);
                    Call_PushCell(id);
                    Call_PushCell(i);
                    Call_PushCell(owner);
                    Call_PushCell(GetArrayCell(g_hWardBehavior, id));
                    Call_Finish();
                }
            }
        }
    }
    return Plugin_Continue;
}

// Cleanup

public Native_War3_RemoveWard(Handle:plugin, numParams)
{
    return bool:RemoveWard(GetNativeCell(1));
}

public Action:TimedRemoveWard(Handle:timer,any:id)
{
    if(!bool:GetArrayCell(g_hWardEnabled, id))
    {
        return Plugin_Continue;
    }
    RemoveWard(id);
    return Plugin_Continue;
}

public bool:RemoveWard(id)
{
    if(GetArrayCell(g_hWardEnabled, id))
    {
        Call_StartForward(g_OnWardExpireHandle);
        Call_PushCell(id);
        Call_PushCell(GetArrayCell(g_hWardOwner,id));
        Call_PushCell(GetArrayCell(g_hWardBehavior, id));
        Call_Finish();

        g_iPlayerWardCount[GetArrayCell(g_hWardOwner,id)]--;
        SetArrayCell(g_hWardEnabled,id, 0);
        if (GetArrayCell(g_hWardTimerInterval,id) != INVALID_HANDLE)
        {
            TriggerTimer(GetArrayCell(g_hWardTimerInterval,id));
            KillTimer(GetArrayCell(g_hWardTimerInterval,id));
            SetArrayCell(g_hWardTimerInterval, id, INVALID_HANDLE);
        }
        if(GetArrayCell(g_hWardTimerDuration, id) != INVALID_HANDLE)
        {
            TriggerTimer(GetArrayCell(g_hWardTimerDuration,id));
            SetArrayCell(g_hWardTimerDuration, id, INVALID_HANDLE);
        }
        return true;
    }
    return false;
}

public OnClientDisconnect(client)
{
    RemoveWards(client);
}

public RemoveWards(client)
{
    for(new id=0;id<GetArraySize(g_hWardOwner);id++)
    {
        if(GetArrayCell(g_hWardOwner, id) == client)
        {
            RemoveWard(id);
        }
    }
}

public OnWar3EventSpawn(client)
{
    RemoveWards(client);
}
public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    for(new i=0;i<GetArraySize(g_hWardOwner);i++)
    {
        RemoveWard(i);
    }
    
    ClearArray(g_hWardOwner);
    ClearArray(g_hWardRadius);
    ClearArray(g_hWardLocation);
    ClearArray(g_hWardDuration);
    ClearArray(g_hWardTimerInterval);
    ClearArray(g_hWardTimerDuration);
    ClearArray(g_hWardSelfInflict);
    ClearArray(g_hWardAffinity);
    ClearArray(g_hWardInterval);
    ClearArray(g_hWardBehavior);
    ClearArray(g_hWardSkill);
    ClearArray(g_hWardData);
    ClearArray(g_hWardUseDefaultColors);
    ClearArray(g_hWardColor2);
    ClearArray(g_hWardColor3);
    ClearArray(g_hWardEnabled);
}
