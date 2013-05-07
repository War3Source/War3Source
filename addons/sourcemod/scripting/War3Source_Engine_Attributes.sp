#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Attributes",
    author = "War3Source Team",
    description = "Manages the attributes on a player"
};

// Stores data about a attribute
new Handle:g_hAttributeName = INVALID_HANDLE;
new Handle:g_hAttributeShortname = INVALID_HANDLE;
new Handle:g_hAttributeDefault = INVALID_HANDLE;

// Stores the attributes of a player
new Handle:g_hAttributeValue[MAXPLAYERS] = INVALID_HANDLE;

// Forward handles
new Handle:g_War3_OnAttributeChanged = INVALID_HANDLE;
new Handle:g_War3_OnAttributeDescriptionRequested = INVALID_HANDLE;

public OnPluginStart()
{
    // Attribute data storage
    g_hAttributeName = CreateArray(FULLNAMELEN);
    g_hAttributeDefault = CreateArray(1);
    g_hAttributeShortname = CreateArray(SHORTNAMELEN);
    
    for (new i=0; i < MAXPLAYERS; i++)
    {
        g_hAttributeValue[i] = CreateArray(1);
    }
}

public bool:InitNativesForwards()
{
    g_War3_OnAttributeChanged = CreateGlobalForward("War3_OnAttributeChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Any, Param_Any);
    g_War3_OnAttributeDescriptionRequested = CreateGlobalForward("War3_OnAttributeDescriptionRequested", ET_Ignore, Param_Cell, Param_Cell, Param_Any, Param_String, Param_Cell);
        
    CreateNative("War3_RegisterAttribute", Native_War3_RegisterAttribute);
    
    CreateNative("War3_GetAttributeName", Native_War3_GetAttributeName);
    CreateNative("War3_GetAttributeShortname", Native_War3_GetAttributeShortname);
    CreateNative("War3_GetAttributeIDByShortname", Native_War3_GetAttributeIDByShortname);
    CreateNative("War3_GetAttributeValue", Native_War3_GetAttributeValue);
    CreateNative("War3_GetAttributeDescription", Native_War3_GetAttributeDescription);

    CreateNative("War3_SetAttribute", Native_War3_SetAttribute);
    CreateNative("War3_ModifyAttribute", Native_War3_ModifyAttribute);

    return true;
} 


/* NATIVES */

public Native_War3_RegisterAttribute(Handle:plugin, numParams)
{
    decl String:sName[FULLNAMELEN];
    GetNativeString(1, sName, sizeof(sName));

    decl String:sShortname[SHORTNAMELEN];
    GetNativeString(2, sShortname, sizeof(sShortname));

    new any:DefaultVal = GetNativeCell(3);
    
    return RegisterAttribute(sName, String: sShortname, DefaultVal);
}

public Native_War3_GetAttributeName(Handle:plugin, numParams)
{
    new iAttributeId = GetNativeCell(1);
    new iBufferSize = GetNativeCell(3);
    
    decl String:sName[FULLNAMELEN];
    GetAttributeName(iAttributeId, sName, sizeof(sName));
    
    SetNativeString(2, sName, iBufferSize);
}

public Native_War3_GetAttributeShortname(Handle:plugin, numParams)
{
    new iAttributeId = GetNativeCell(1);
    new iBufferSize = GetNativeCell(3);
    
    decl String:sName[SHORTNAMELEN];
    GetAttributeShortname(iAttributeId, sName, sizeof(sName));
    
    SetNativeString(2, sName, iBufferSize);
}

public Native_War3_GetAttributeIDByShortname(Handle:plugin, numParams)
{
    decl String:sShortname[SHORTNAMELEN];
    GetNativeString(1, sShortname, sizeof(sShortname));
    
    return GetAttributeIDByShortname(sShortname);
}
 
public Native_War3_GetAttributeValue(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new iAttributeId = GetNativeCell(2);
    
    return any:GetAttributeValue(client, iAttributeId);
}

public Native_War3_SetAttribute(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new iAttributeId = GetNativeCell(2);
    new any:value = GetNativeCell(3);
    
    SetAttribute(client, iAttributeId, value);
}

public Native_War3_ModifyAttribute(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new iAttributeId = GetNativeCell(2);
    new any:value = GetNativeCell(3);
    
    ModifyAttribute(client, iAttributeId, value);
}

public Native_War3_GetAttributeDescription(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new iAttributeId = GetNativeCell(2);
    new any:Value = GetNativeCell(3);
    new iBufferSize = GetNativeCell(5);
    
    new String:sDescription[iBufferSize];
   
    // GetAttributeDescription(client, attributeId, any:value, String:sDescription[], iBufferSize);
    Call_StartForward(g_War3_OnAttributeDescriptionRequested);
    Call_PushCell(client);
    Call_PushCell(iAttributeId);
    Call_PushCell(Value);
    Call_PushStringEx(sDescription, iBufferSize, SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(iBufferSize);
    Call_Finish();
    
    // Nobody wanted to take care of our attributes description :(
    if(StrEqual(sDescription, ""))
    {
        strcopy(sDescription, iBufferSize, "No description");
    }
    
    SetNativeString(4, sDescription, iBufferSize);
}

/* ACTUAL IMPLEMENTATIONS FOR THE NATIVES TO CALL */

RegisterAttribute(String:sAttributeName[], String: sAttributeShortName[], any:DefaultVal)
{
    new attributeId = GetAttributeIDByShortname(sAttributeShortName);
    
    if (attributeId != -1)
    {
        War3_LogInfo("Skipping attribute generation - attribute %i \"{attribute %i}\" already exist!", attributeId, attributeId);
        return attributeId;
    }
    
    PushArrayString(g_hAttributeName, sAttributeName);
    PushArrayString(g_hAttributeShortname, sAttributeShortName);
    PushArrayCell(g_hAttributeDefault, DefaultVal);

    attributeId = GetArraySize(g_hAttributeName) - 1;

    War3_LogInfo("Created new attribute: %i - \"{attribute %i}\"", attributeId, attributeId);
       
    for (new i=0; i < MAXPLAYERS; i++)
    {
        AddNewAttributes(i);
    }
    
    return attributeId;
}

ModifyAttribute(client, attributeID, value)
{
    new oldValue = GetAttributeValue(client, attributeID);
    SetAttribute(client, attributeID, oldValue - value);
    
    War3_LogInfo("Modifying attribute %i for client %i by value %f", attributeID, client, value);
}

GetAttributeName(attributeId, String:sName[], iBufferSize)
{
    if(GetArraySize(g_hAttributeName) < attributeId)
    {
        strcopy(sName, iBufferSize, "invalid");
    }
    else
    {
        GetArrayString(g_hAttributeName, attributeId, sName, iBufferSize);
    }
}

GetAttributeShortname(attributeId, String:sShortname[], iBufferSize)
{
    
    if(GetArraySize(g_hAttributeShortname) < attributeId)
    {
        strcopy(sShortname, iBufferSize, "invalid");
    }
    else
    {
        GetArrayString(g_hAttributeShortname, attributeId, sShortname, sizeof(iBufferSize));
    }
}

GetAttributeIDByShortname(String:sAttributeShortName[])
{
    return FindStringInArray(g_hAttributeShortname, sAttributeShortName);
}

AddNewAttributes(client)
{
    if (!ValidPlayer(client))
    {
        return;
    }
    
    new iAttributes = GetArraySize(g_hAttributeValue[client]);
    new iRegisteredAttributes = GetArraySize(g_hAttributeDefault);
    
    if (iAttributes == iRegisteredAttributes)
    {
        return;
    }
    
    War3_LogInfo("Adding new attributes on \"{client %i}\" - %i attributes registered, %i on client", client, iRegisteredAttributes, iAttributes);
    for(new i = iAttributes; i < iRegisteredAttributes; i++)
    {
        War3_LogInfo("Adding attribute \"{attribute %i}\" on client \"{client %i}\" with default value", i, client);
        PushArrayCell(g_hAttributeValue[client], GetArrayCell(g_hAttributeDefault, i));
    }
}

ResetAttributesForPlayer(client)
{
    if (!ValidPlayer(client))
    {
        return;
    }
    
    AddNewAttributes(client);

    War3_LogInfo("Resetting Attributes on \"{client %i}\"", client);
    for(new i = 0; i < GetArraySize(g_hAttributeDefault); i++)
    {
        War3_LogInfo("Changing attribute \"{attribute %i}\" on client \"{client %i}\" to default value", i, client);
        SetArrayCell(g_hAttributeValue[client], i, any:GetArrayCell(g_hAttributeDefault, i));
    }
}

any:GetAttributeValue(client, attributeId)
{
    if(!ValidPlayer(client))
    {
        return -1;
    }
    
    return GetArrayCell(g_hAttributeValue[client], attributeId);
}

SetAttribute(client, attributeId, any:value)
{
    if(!ValidPlayer(client))
    {
        return;
    }
    
    Call_StartForward(g_War3_OnAttributeChanged);
    Call_PushCell(client);
    Call_PushCell(attributeId);
    Call_PushCell(any:GetAttributeValue(client, attributeId));
    Call_PushCell(value);
    Call_Finish();
}

// Cleanup

/**
 * Revert the attributes to the default values whenever a player connects
 */
public OnClientPutInServer(client)
{
    ResetAttributesForPlayer(client);
}