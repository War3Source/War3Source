#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - AttributeBuffs",
    author = "War3Source Team",
    description = "Manages the attributes on a player"
};

// Buffs in general
new Handle:g_hAttributeID = INVALID_HANDLE; // this stores the id to the attribute that is modified
new Handle:g_hBuffClient = INVALID_HANDLE; // this stores the id of the client this effect is on
new Handle:g_hBuffSource = INVALID_HANDLE; // this stores the id of the source of the modification
new Handle:g_hBuffSourceType = INVALID_HANDLE; // this stores the type of the source (see W3BuffSource)
new Handle:g_hBuffValue = INVALID_HANDLE; // how big the modification is

// Timed buffs
new Handle:g_hBuffDuration = INVALID_HANDLE; // how long the modification lasts
new Handle:g_hBuffExpireFlag = INVALID_HANDLE; // what kind of events make this modification expire
new Handle:g_hBuffCanStack = INVALID_HANDLE; // bool: Can this modification stack

// Race buffs
new Handle:g_hRaceBuffRaceId = INVALID_HANDLE;

// Internals
new Handle:g_hBuffType = INVALID_HANDLE; // if this is a buff or debuff
new Handle:g_hBuffExpireTime = INVALID_HANDLE; // Internal: When this modification expires
new Handle:g_hBuffActive = INVALID_HANDLE; // bool: Internal: Is this buff active or expired?


public OnPluginStart()
{
    // Buffs in general
    g_hAttributeID = CreateArray(1);
    g_hBuffClient = CreateArray(1);
    g_hBuffSource = CreateArray(1);
    g_hBuffSourceType = CreateArray(1);
    g_hBuffValue = CreateArray(1);

    // Timed buffs
    g_hBuffDuration = CreateArray(1);
    g_hBuffCanStack = CreateArray(1);
    g_hBuffExpireFlag = CreateArray(1);

    // Race buffs
    g_hRaceBuffRaceId = CreateArray(1);
    
    // Internals
    g_hBuffActive = CreateArray(1);
    g_hBuffExpireTime = CreateArray(1);
    g_hBuffType = CreateArray(1);
}

public bool:InitNativesForwards()
{
    CreateNative("War3_ApplyTimedBuff", Native_War3_ApplyTimedBuff); 
    CreateNative("War3_ApplyTimedDebuff", Native_War3_ApplyTimedDebuff); 

    CreateNative("War3_ApplyRaceBuff", Native_War3_ApplyRaceBuff);
    CreateNative("War3_ApplyRaceDebuff", Native_War3_ApplyRaceDebuff);
        
    CreateNative("War3_RemoveBuff", Native_War3_RemoveBuff);
    
    return true;
} 

// Natives

public Native_War3_ApplyTimedBuff(Handle:plugin, numParams)
{
    return ApplyTimedBuffOrDebuff(BUFFTYPE_BUFF);
}

public Native_War3_ApplyTimedDebuff(Handle:plugin, numParams)
{
    return ApplyTimedBuffOrDebuff(BUFFTYPE_DEBUFF);
}

public Native_War3_ApplyRaceBuff(Handle:plugin, numParams)
{
    return ApplyRaceBuffOrDebuff(BUFFTYPE_BUFF);
}

public Native_War3_ApplyRaceDebuff(Handle:plugin, numParams)
{
    return ApplyRaceBuffOrDebuff(BUFFTYPE_DEBUFF);
}

public Native_War3_RemoveBuff(Handle:plugin, numParams)
{
    new buffIndex = GetNativeCell(1);
    
    RemoveBuff(buffIndex);
}

// Not natives :P

ApplyTimedBuffOrDebuff(W3BuffType:buffType)
{
    new client = GetNativeCell(1);
    new iAttributeId = GetNativeCell(2);
    new any:value = GetNativeCell(3);
    new Float:fDuration = GetNativeCell(4);
    new W3BuffSourceType:sourceType = GetNativeCell(5);
    new source = GetNativeCell(6);
    new expireFlag = GetNativeCell(7);
    new bool:bCanStack = GetNativeCell(9);
    
    // Check if the client already has this buff/debuff and if he has check if it's stackable
    if (!bCanStack)
    {
        for(new i = 0; i < GetArraySize(g_hBuffClient); i++)
        {
            new buffedclient = GetArrayCell(g_hBuffClient, i);
            
            if (buffedclient == client)
            {
                new buffedSource = GetArrayCell(g_hBuffSource, i);
                new W3BuffSourceType:buffedSourceType = GetArrayCell(g_hBuffSourceType, i);
                new bool:bBuffedCanStack = GetArrayCell(g_hBuffCanStack, i);
                
                if ((buffedSource != source) || (buffedSourceType != sourceType) || !bBuffedCanStack)
                {
                    return INVALID_BUFF;
                }
            }
        }
    }
    
    // Buffs in general
    new buffindex = PushArrayCell(g_hBuffClient, client);
    PushArrayCell(g_hAttributeID, iAttributeId);
    PushArrayCell(g_hBuffValue, value);
    PushArrayCell(g_hBuffExpireFlag, expireFlag);
    PushArrayCell(g_hBuffType, buffType);
    PushArrayCell(g_hBuffSource, source);
    PushArrayCell(g_hBuffSourceType, sourceType);
    
    // Timed buffs
    PushArrayCell(g_hBuffDuration, fDuration);
    PushArrayCell(g_hBuffCanStack, bCanStack);
    
    // Race buff - not needed here
    PushArrayCell(g_hRaceBuffRaceId, -1);
    
    // Internals
    PushArrayCell(g_hBuffActive, true);
    PushArrayCell(g_hBuffExpireTime, GetEngineTime() + fDuration);
    
    War3_ModifyAttribute(client, iAttributeId, value);
    
    return buffindex;
}

ApplyRaceBuffOrDebuff(W3BuffType:buffType)
{
    new client = GetNativeCell(1);
    new iAttributeId = GetNativeCell(2);
    new any:value = GetNativeCell(3);
    new raceID = GetNativeCell(4);
    new W3BuffSourceType:sourceType = GetNativeCell(5);
    new source = GetNativeCell(6);
    
    // Buffs in general
    new buffindex = PushArrayCell(g_hBuffClient, client);
    PushArrayCell(g_hAttributeID, iAttributeId);
    PushArrayCell(g_hBuffValue, value);
    PushArrayCell(g_hBuffExpireFlag, BUFF_EXPIRES_MANUALLY);
    PushArrayCell(g_hBuffType, buffType);
    PushArrayCell(g_hBuffSource, source);
    PushArrayCell(g_hBuffSourceType, sourceType);
    
    // Timed buffs - not needed here
    PushArrayCell(g_hBuffDuration, 0.0);
    PushArrayCell(g_hBuffCanStack, false);
    
    // Race buff
    PushArrayCell(g_hRaceBuffRaceId, raceID);
    
    // Internals
    PushArrayCell(g_hBuffActive, true);
    PushArrayCell(g_hBuffExpireTime, 0.0);
    
    return buffindex;
}

// FOR GALLIFREY, err, OnGameFrame, I mean...

public OnGameFrame()
{
    new Float:now = GetEngineTime();
    
    new expireFlag;
    new Float:fExpires;
    new bool:bActiveBuff;
    for(new i = 0; i < GetArraySize(g_hBuffActive); i++)
    {
        // Only interact with active buffs
        bActiveBuff = GetArrayCell(g_hBuffActive, i);
        if (!bActiveBuff)
        {
            continue;
        }
        
        // Only expire them if they actually expire on a timer
        expireFlag = GetArrayCell(g_hBuffExpireFlag, i);
        if (!(expireFlag & BUFF_EXPIRES_ON_TIMER))
        {
            continue;
        }
        
        // Check if they have expired
        fExpires = GetArrayCell(g_hBuffExpireTime, i);
        if (fExpires > 0.0 && fExpires <= now)
        {
            RemoveBuff(i);
            continue;
        }
    }
}

// Cleanup

RemoveBuff(buffIndex)
{
    new client = GetArrayCell(g_hBuffClient, buffIndex);
    new iAttributeId = GetArrayCell(g_hAttributeID, buffIndex);
    
    // implement
    War3_LogInfo("Removing buff %i for attribute %i on client %i", buffIndex, iAttributeId, client);
    
    new any:value = GetArrayCell(g_hBuffValue, buffIndex);
    War3_ModifyAttribute(client, iAttributeId, -value);
    
    SetArrayCell(g_hBuffActive, buffIndex, false);
}