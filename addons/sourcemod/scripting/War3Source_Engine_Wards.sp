#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo =
{
    name = "War3Source - Engine - Wards",
    author = "War3Source Team",
    description="Ward controller engine"
};

// Ward data structure
new Handle:g_hWardOwner = INVALID_HANDLE; // Who owns this ward?
new Handle:g_hWardRadius = INVALID_HANDLE; // How big is the ward radius?
new Handle:g_hWardLocation = INVALID_HANDLE; // Where is this ward?
new Handle:g_hWardTarget = INVALID_HANDLE; // What does this ward target?
new Handle:g_hWardInterval = INVALID_HANDLE; // In which interval does this ward pulse?
new Handle:g_hWardDisableOnDeath = INVALID_HANDLE; // Bool: Should this ward be disabled when the owner dies?

// Modular ward data
new Handle:g_hWardBehavior = INVALID_HANDLE; // What is the ward behavior ID?
new Handle:g_hWardSkill = INVALID_HANDLE; // What skill does this ward come from?
new Handle:g_hWardData = INVALID_HANDLE; // Optional array of data to go with the ward
new Handle:g_hWardUseDefaultColors = INVALID_HANDLE; // Bool: Should the ward use the default colors?
new Handle:g_hWardColor2 = INVALID_HANDLE; // Alternate colors for Team 2
new Handle:g_hWardColor3 = INVALID_HANDLE; // Alternate colors for Team 3

// Internal ward data
new Handle:g_hWardNextTick = INVALID_HANDLE; // Internal: When is the next ward pulse?
new Handle:g_hWardExpireTime = INVALID_HANDLE; // Internal: When will the ward expire?
new Handle:g_hWardEnabled = INVALID_HANDLE; // Internal: Is this ward enabled?

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

    CreateNative("War3_CreateWard", Native_War3_CreateWard);
    CreateNative("War3_CreateWardMod", Native_War3_CreateWardMod);
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
    g_hWardTarget = CreateArray(1);
    g_hWardInterval = CreateArray(1);
    g_hWardDisableOnDeath = CreateArray(1);
    g_hWardNextTick = CreateArray(1);
    g_hWardExpireTime = CreateArray(1);
    g_hWardBehavior = CreateArray(1);
    g_hWardSkill = CreateArray(1);
    g_hWardUseDefaultColors = CreateArray(1);
    g_hWardEnabled = CreateArray(1);
    g_hWardColor2 = CreateArray(4);
    g_hWardColor3 = CreateArray(4);
    g_hWardData = CreateArray(MAXWARDDATA);
    
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

// Constructors

public Native_War3_CreateWard(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);

    if(W3Denyable(DN_CanPlaceWard, client))
    {
        new id = PushArrayCell(g_hWardOwner, client);

        new Float:fWardLocation[3];
        GetNativeArray(2, fWardLocation, 3);
        PushArrayArray(g_hWardLocation, fWardLocation);
        
        new iRadius = GetNativeCell(3);
        PushArrayCell(g_hWardRadius, iRadius);
        
        new Float:fDuration = GetNativeCell(4);
               
        new Float:fPulseInterval = GetNativeCell(5);
        PushArrayCell(g_hWardInterval, fPulseInterval);

        new iTarget = GetNativeCell(6);
        PushArrayCell(g_hWardTarget, iTarget);

        new bool:bDisableOnDeath = GetNativeCell(7);
        PushArrayCell(g_hWardDisableOnDeath, bDisableOnDeath);

        g_iPlayerWardCount[client]++;
        Call_StartForward(g_OnWardCreatedHandle);
        Call_PushCell(id);
        Call_PushCell(INVALID_BEHAVIOR);
        Call_Finish();
        PushArrayCell(g_hWardEnabled, 1);
        
        // This ward starts NOW!
        PushArrayCell(g_hWardNextTick, GetEngineTime());
        
        if (fDuration >= 0.0)
        {
            PushArrayCell(g_hWardExpireTime, GetEngineTime() + fDuration);
        }
        else
        {
            PushArrayCell(g_hWardExpireTime, 0.0);
        }
        
        // Modular ward settings we don't use
        PushArrayCell(g_hWardBehavior, INVALID_BEHAVIOR);
        PushArrayCell(g_hWardSkill, -1);
        PushArrayCell(g_hWardData, -1);
        PushArrayCell(g_hWardUseDefaultColors, false);
        PushArrayCell(g_hWardColor2, -1);
        PushArrayCell(g_hWardColor3, -1);
                
        return id;
    }
    
    return INVALID_WARD;
}

public Native_War3_CreateWardMod(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);

    if(W3Denyable(DN_CanPlaceWard, client))
    {
        new id = PushArrayCell(g_hWardOwner, client);

        new Float:fWardLocation[3];
        GetNativeArray(2, fWardLocation, 3);
        PushArrayArray(g_hWardLocation, fWardLocation);
        
        new iRadius = GetNativeCell(3);
        PushArrayCell(g_hWardRadius, iRadius);
        
        new Float:fDuration = GetNativeCell(4);
               
        new Float:fPulseInterval = GetNativeCell(5);
        PushArrayCell(g_hWardInterval, fPulseInterval);
        
        new String:sBehavior[WARDSNAMELEN];
        GetNativeString(6, sBehavior, sizeof(sBehavior));
        PushArrayCell(g_hWardBehavior, War3_GetWardBehaviorByShortname(sBehavior));
        
        new iWardSkill = GetNativeCell(7);
        PushArrayCell(g_hWardSkill, iWardSkill);

        new any:data[MAXWARDDATA];
        GetNativeArray(8, data ,MAXWARDDATA);
        PushArrayArray(g_hWardData, data);
        
        new iTarget = GetNativeCell(9);
        PushArrayCell(g_hWardTarget, iTarget);

        new bool:bDisableOnDeath = GetNativeCell(10);
        PushArrayCell(g_hWardDisableOnDeath, bDisableOnDeath);
        
        new bool:bUseDefaultColors = GetNativeCell(11);
        PushArrayCell(g_hWardUseDefaultColors, bUseDefaultColors);
        
        new color[4];
        GetNativeArray(12, color, sizeof(color));
        PushArrayArray(g_hWardColor2, color);
        
        GetNativeArray(13, color, sizeof(color));
        PushArrayArray(g_hWardColor3, color);

        g_iPlayerWardCount[client]++;
        Call_StartForward(g_OnWardCreatedHandle);
        Call_PushCell(id);
        Call_PushCell(GetArrayCell(g_hWardBehavior, id));
        Call_Finish();
        PushArrayCell(g_hWardEnabled, 1);
        
        // This ward starts NOW!
        PushArrayCell(g_hWardNextTick, GetEngineTime());
        
        if (fDuration >= 0.0)
        {
            PushArrayCell(g_hWardExpireTime, GetEngineTime() + fDuration);
        }
        else
        {
            PushArrayCell(g_hWardExpireTime, 0.0);
        }
        
        return id;
    }
    
    return INVALID_WARD;
}

// WardPulse is only called for enabled wards
public WardPulse(id)
{
    new owner = GetArrayCell(g_hWardOwner, id);

    Call_StartForward(g_OnWardPulseHandle);
    Call_PushCell(id);
    Call_PushCell(GetArrayCell(g_hWardBehavior, id));
    Call_Finish();

    new Float:fStartPos[3];
    new Float:fWardLocation[3];
    GetArrayArray(g_hWardLocation, id, fWardLocation);

    new Float:tempvec[3] = {0.0, 0.0, WARDBELOW};
    AddVectors(fWardLocation, tempvec, fStartPos);
    
    new Float:BeamXY[3];
    for(new x=0; x < 3; x++)
    {
        BeamXY[x] = fStartPos[x]; //only compare xy
    }
    new Float:BeamZ= BeamXY[2];
    BeamXY[2] = 0.0;
    new Float:VictimPos[3];
    new Float:tempZ;

    new iWardTarget = GetArrayCell(g_hWardTarget, id);
    for(new i=1; i <= MaxClients; i++)
    {
        if(ValidPlayer(i, true))
        {
            if ((i == owner) && !(iWardTarget & WARD_TARGET_SELF))
            {
                continue;
            }
            else if ((GetClientTeam(i) == GetClientTeam(owner)) && !(iWardTarget & WARD_TARGET_ALLIES))
            {
                continue;
            }
            else if ((GetClientTeam(i) != GetClientTeam(owner)) && !(iWardTarget & WARD_TARGET_ENEMYS))
            {
                continue;
            }

            GetClientAbsOrigin(i, VictimPos);
            tempZ = VictimPos[2];
            VictimPos[2] = 0.0; //no Z
            if(RoundToFloor(GetVectorDistance(BeamXY, VictimPos)) < GetArrayCell(g_hWardRadius, id))
            {
                // now compare z
                if(tempZ > BeamZ + WARDBELOW && tempZ < BeamZ + WARDABOVE)
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
    return;
}

// Cleanup

public Native_War3_RemoveWard(Handle:plugin, numParams)
{
    return bool:RemoveWard(GetNativeCell(1));
}

public bool:RemoveWard(id)
{
    // Disable the ward. We can't clean up the arrays here, as their index
    // is the ward identifier and we can't shift that around after different
    // plugins already stored the id on their side ;)
    
    if(GetArrayCell(g_hWardEnabled, id))
    {
        Call_StartForward(g_OnWardExpireHandle);
        Call_PushCell(id);
        Call_PushCell(GetArrayCell(g_hWardOwner, id));
        Call_PushCell(GetArrayCell(g_hWardBehavior, id));
        Call_Finish();

        g_iPlayerWardCount[GetArrayCell(g_hWardOwner, id)]--;
        SetArrayCell(g_hWardEnabled, id, 0);

        return true;
    }
    
    return false;
}

public RemoveWards(client)
{
    for(new id=0; id < GetArraySize(g_hWardOwner); id++)
    {
        if(GetArrayCell(g_hWardOwner, id) == client)
        {
            RemoveWard(id);
        }
    }
}

public  OnWar3EventDeath(victim, attacker)
{
    new bool:bDisableWard;
    for(new i=0; i < GetArraySize(g_hWardOwner); i++)
    {
        if (GetArrayCell(g_hWardOwner, i) == victim)
        {
            bDisableWard = GetArrayCell(g_hWardDisableOnDeath, i);
            if (bDisableWard)
            {
                RemoveWard(i);
            }
        }
    }
}

public OnClientDisconnect(client)
{
    RemoveWards(client);
}

public OnWar3EventSpawn(client)
{
    RemoveWards(client);
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    for(new i=0; i < GetArraySize(g_hWardOwner); i++)
    {
        RemoveWard(i);
    }
    
    ClearArray(g_hWardOwner);
    ClearArray(g_hWardRadius);
    ClearArray(g_hWardLocation);
    ClearArray(g_hWardTarget);
    ClearArray(g_hWardInterval);
    ClearArray(g_hWardNextTick);
    ClearArray(g_hWardExpireTime);
    ClearArray(g_hWardBehavior);
    ClearArray(g_hWardSkill);
    ClearArray(g_hWardData);
    ClearArray(g_hWardUseDefaultColors);
    ClearArray(g_hWardColor2);
    ClearArray(g_hWardColor3);
    ClearArray(g_hWardEnabled);
    ClearArray(g_hWardDisableOnDeath);
}

// FOR GALLIFREY, err, OnGameFrame, I mean...

public OnGameFrame()
{
    new Float:now = GetEngineTime();
    new bool:bEnabled;
    new Float:fNextTick;
    new Float:fInterval;
    new Float:fExpires;
    
    for(new i = 0; i < GetArraySize(g_hWardOwner); i++)
    {
        bEnabled = GetArrayCell(g_hWardEnabled, i);
        if (!bEnabled)
        {
            continue;
        }
        
        fExpires = GetArrayCell(g_hWardExpireTime, i);
        
        if (fExpires > 0.0 && fExpires <= now)
        {
            RemoveWard(i);
            continue;
        }
        else
        {
            fNextTick = GetArrayCell(g_hWardNextTick, i);
            
            if (fNextTick <= now)
            {
                WardPulse(i);
                
                fInterval = GetArrayCell(g_hWardInterval, i);
                
                SetArrayCell(g_hWardNextTick, i, fNextTick + fInterval);
            }
        }
    }
}