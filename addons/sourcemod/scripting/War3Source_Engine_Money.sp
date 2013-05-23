#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Money",
    author = "War3Source Team",
    description = "Handle money related things"
};

new Handle:g_hCurrencyMode;
new W3CurrencyMode:g_CurrencyMode;

new Handle:g_hMaxCurrency;
new g_MaxCurrency;

public OnPluginStart()
{
    g_hCurrencyMode = CreateConVar("war3_currency_mode", "0", "Configure the currency that should be used. 0 - war3 gold, 1 - Counter-Strike $ / Team Fortress 2 MVM $");
    g_hMaxCurrency = CreateConVar("war3_max_currency", "100", "Configure the maximum amount of currency a player can hold.");
    
    HookConVarChange(g_hCurrencyMode, OnCurrencyModeChanged);
    HookConVarChange(g_hMaxCurrency, OnMaxCurrencyChanged);
}

public bool:InitNativesForwards()
{
    CreateNative("War3_GetCurrencyMode", Native_War3_GetCurrencyMode);
    CreateNative("War3_GetMaxCurrency", Native_War3_GetMaxCurrency);
    CreateNative("War3_GetCurrency", Native_War3_GetCurrency);
    CreateNative("War3_SetCurrency", Native_War3_SetCurrency);
    CreateNative("War3_AddCurrency", Native_War3_AddCurrency);
    CreateNative("War3_SubstractCurrency", Native_War3_SubstractCurrency);
    
    CreateNative("War3_GetGold", Native_War3_GetGold);
    CreateNative("War3_SetGold", Native_War3_SetGold);
    
    return true;
}

public OnCurrencyModeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    g_CurrencyMode = W3CurrencyMode:StringToInt(newValue);
}

public OnMaxCurrencyChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    g_MaxCurrency = StringToInt(newValue);
}

public Native_War3_GetCurrencyMode(Handle:plugin, numParams)
{
    return _:g_CurrencyMode;
}

public Native_War3_GetMaxCurrency(Handle:plugin, numParams)
{
    return g_MaxCurrency;
}

public Native_War3_GetCurrency(Handle:plugin, numParams)
{
    new client = GetNativeCell(0);
    
    return GetCurrency(client);
}

public Native_War3_SetCurrency(Handle:plugin, numParams)
{
    new client = GetNativeCell(0);
    new newCurrency = GetNativeCell(1);
    
    return SetCurrency(client, newCurrency, g_CurrencyMode);
}

public Native_War3_AddCurrency(Handle:plugin, numParams)
{
    new client = GetNativeCell(0);
    new currencyToAdd = GetNativeCell(1);
    
    return SetCurrency(client, GetCurrency(client) + currencyToAdd, g_CurrencyMode);
}

public Native_War3_SubstractCurrency(Handle:plugin, numParams)
{
    new client = GetNativeCell(0);
    new currencyToSubstract = GetNativeCell(1);
    
    return SetCurrency(client, GetCurrency(client) - currencyToSubstract, g_CurrencyMode);
}

public Native_War3_GetGold(Handle:plugin, numParams)
{
    new client = GetNativeCell(0);
    
    return W3GetPlayerProp(client, PlayerGold);
}

public Native_War3_SetGold(Handle:plugin, numParams)
{
    new client = GetNativeCell(0);
    new newGold = GetNativeCell(1);
    
    return SetCurrency(client, newGold, CURRENCY_MODE_WAR3_GOLD);
}

GetCurrency(client)
{
    if (g_CurrencyMode == CURRENCY_MODE_WAR3_GOLD)
    {
        return W3GetPlayerProp(client, PlayerGold);
    }
    else if (g_CurrencyMode == CURRENCY_MODE_DORRAR)
    {
        if(GAMECSANY)
        {
            return GetEntProp(client, Prop_Send, "m_iAccount");
        } 
        else if (GAMETF) 
        {
            return GetEntProp(client, Prop_Send, "m_nCurrency");
        }
    }

    return 0;
}

bool:SetCurrency(client, newCurrency, W3CurrencyMode:currencyMode)
{
    new oldCurrency = GetCurrency(client);
    if(newCurrency > g_MaxCurrency)
    {
        newCurrency = g_MaxCurrency;
    }
    else if (newCurrency < 0)
    {
        newCurrency = 0;
    }
    
    // Oops, nothing to do here~!
    if(oldCurrency == newCurrency)
    {
        return false;
    }
    
    War3_LogInfo("Setting the currency of player \"{client %i}\" to %i", client, newCurrency);
    if (currencyMode == CURRENCY_MODE_WAR3_GOLD)
    {
        W3SetPlayerProp(client, PlayerGold, newCurrency);
    }
    else if (currencyMode == CURRENCY_MODE_DORRAR)
    {
        if(GAMECSANY)
        {
            SetEntProp(client, Prop_Send, "m_iAccount", newCurrency);
        } 
        else if (GAMETF) 
        {
            if(newCurrency > oldCurrency)
            {
                War3_LogWarning("Not giving money to player \"{client %i}\" due to a MVM bug", client);
                return false;
            }
            SetEntProp(client, Prop_Send, "m_nCurrency", newCurrency);
        }
    }
    
    return true;
}