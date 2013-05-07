#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - AttributeBuffs",
    author = "War3Source Team",
    description = "Manages the attributes on a player"
};

// Timed buff attributes
new Handle:g_hAttributeID = INVALID_HANDLE; // this stores the id to the attribute that is modified
new Handle:g_hBuffClient = INVALID_HANDLE; // this stores the id of the client this effect is on
new Handle:g_hBuffSource = INVALID_HANDLE; // this stores the id of the source of the modification
new Handle:g_hBuffSourceType = INVALID_HANDLE; // this stores the type of the source (see W3BuffSourceType)
new Handle:g_hBuffValue = INVALID_HANDLE; // how big the modification is
new Handle:g_hBuffDuration = INVALID_HANDLE; // how long the modification lasts
new Handle:g_hBuffExpireFlag = INVALID_HANDLE; // what kind of events make this modification expire
new Handle:g_hBuffType = INVALID_HANDLE; // if this is a buff or debuff
new Handle:g_hBuffCanStack = INVALID_HANDLE; // bool: Can this modification stack

// Internals
new Handle:g_hBuffExpireTime = INVALID_HANDLE; // Internal: When this modification expires

public OnPluginStart()
{
    g_hAttributeID = CreateArray(1);
    g_hBuffClient = CreateArray(1);
    g_hBuffSource = CreateArray(1);
    g_hBuffSourceType = CreateArray(1);
    g_hBuffValue = CreateArray(1);
    g_hBuffDuration = CreateArray(1);
    g_hBuffExpireTime = CreateArray(1);
    g_hBuffExpireFlag = CreateArray(1);
    g_hBuffType = CreateArray(1);
    g_hBuffCanStack = CreateArray(1);
}

public bool:InitNativesForwards()
{
    CreateNative("War3_ApplyTimedBuff", Native_War3_ApplyTimedBuff); 
    CreateNative("War3_ApplyTimedDebuff", Native_War3_ApplyTimedDebuff); 

    return true;
} 


/* NATIVES */

public Native_War3_ApplyTimedBuff(Handle:plugin, numParams)
{
    ApplyBuffOrDebuff(BUFFTYPE_BUFF);
}

public Native_War3_ApplyTimedDebuff(Handle:plugin, numParams)
{
    ApplyBuffOrDebuff(BUFFTYPE_DEBUFF);
}

ApplyBuffOrDebuff(W3BuffType:buffType)
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
                    return;
                }
            }
        }
    }
    
    PushArrayCell(g_hBuffClient, client);
    PushArrayCell(g_hAttributeID, iAttributeId);
    PushArrayCell(g_hBuffValue, value);
    PushArrayCell(g_hBuffDuration, fDuration);
    PushArrayCell(g_hBuffSource, source);
    PushArrayCell(g_hBuffSourceType, sourceType);
    PushArrayCell(g_hBuffExpireFlag, expireFlag);
    PushArrayCell(g_hBuffType, buffType);
    PushArrayCell(g_hBuffCanStack, bCanStack);
    
    PushArrayCell(g_hBuffExpireTime, GetEngineTime() + fDuration);
    
    War3_ModifyAttribute(client, iAttributeId, value);
}

// FOR GALLIFREY, err, OnGameFrame, I mean...

public OnGameFrame()
{
    new Float:now = GetEngineTime();
    
    new expireFlag;
    new Float:fExpires;
    for(new i = 0; i < GetArraySize(g_hBuffExpireFlag); i++)
    {
        expireFlag = GetArrayCell(g_hBuffExpireFlag, i);
        if (!(expireFlag & BUFF_EXPIRES_ON_TIMER))
        {
            continue;
        }
        
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
    War3_LogInfo("Removing modification %i for attribute %i on client %i", buffIndex, iAttributeId, client);
    
    new any:value = GetArrayCell(g_hBuffValue, buffIndex);
    War3_ModifyAttribute(client, iAttributeId, -value);
    
    RemoveFromArray(g_hAttributeID, buffIndex);
    RemoveFromArray(g_hBuffClient, buffIndex);
    RemoveFromArray(g_hBuffSource, buffIndex);
    RemoveFromArray(g_hBuffSourceType, buffIndex);
    RemoveFromArray(g_hBuffValue, buffIndex);
    RemoveFromArray(g_hBuffDuration, buffIndex);
    RemoveFromArray(g_hBuffExpireTime, buffIndex);
    RemoveFromArray(g_hBuffExpireFlag, buffIndex);
    RemoveFromArray(g_hBuffType, buffIndex);
    RemoveFromArray(g_hBuffCanStack, buffIndex);
}