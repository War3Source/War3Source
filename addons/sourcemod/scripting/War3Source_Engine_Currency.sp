#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Currency",
    author = "War3Source Team",
    description = "Handle money related things"
};

new Handle:g_hCurrencyMode;
new W3CurrencyMode:g_CurrencyMode;

new Handle:g_hMaxCurrency;
new g_MaxCurrency;

new Handle:g_hOnCurrencyChanged;

public OnPluginStart()
{
    LoadTranslations("w3s.engine.currency.txt");
    
    g_hCurrencyMode = CreateConVar("war3_currency_mode", "0", "Configure the currency that should be used. 0 - war3 gold, 1 - Counter-Strike $ OR Team Fortress 2 MVM $");
    g_hMaxCurrency = CreateConVar("war3_max_currency", "-1", "Configure the maximum amount of currency a player can hold.");
    
    HookConVarChange(g_hCurrencyMode, OnCurrencyModeChanged);
    HookConVarChange(g_hMaxCurrency, OnMaxCurrencyChanged);
    
    InitializeGlobals();
}

InitializeGlobals()
{
    // Apply some sensible default values if these cvars are unset
    g_CurrencyMode = W3CurrencyMode:GetConVarInt(g_hCurrencyMode);
    g_MaxCurrency = GetConVarInt(g_hMaxCurrency);
    
    if(g_CurrencyMode == CURRENCY_MODE_INVALID)
    {
        if(GAMECSANY)
        {
            g_CurrencyMode = CURRENCY_MODE_DORRAR;
        }
        else
        {
            g_CurrencyMode = CURRENCY_MODE_WAR3_GOLD;
        }
    }
    
    if(g_MaxCurrency == -1)
    {
        if(g_CurrencyMode == CURRENCY_MODE_WAR3_GOLD)
        {
            g_MaxCurrency = 100;
        }
        else if(g_CurrencyMode == CURRENCY_MODE_DORRAR)
        {
            if(GAMECSANY)
            {
                g_MaxCurrency = 16000;
            }
            else if(GAMETF)
            {
                g_MaxCurrency = 32767;
            }
        }
    }
}

public bool:InitNativesForwards()
{
    g_hOnCurrencyChanged = CreateGlobalForward("OnCurrencyChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    
    CreateNative("War3_GetCurrencyMode", Native_War3_GetCurrencyMode);
    CreateNative("War3_GetMaxCurrency", Native_War3_GetMaxCurrency);
    CreateNative("War3_GetCurrencyName", Native_War3_GetCurrencyName);
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
    
    War3_LogInfo("CurrencyMode was changed to %i", g_CurrencyMode);
    
    if(g_CurrencyMode == CURRENCY_MODE_DORRAR)
    {
        if(!GAMECSANY && !GAMETF)
        {
            War3_LogInfo("Refusing to change to dorrar mode");
            SetConVarInt(g_hCurrencyMode, _:CURRENCY_MODE_WAR3_GOLD);
        }
    }
    
    InitializeGlobals();
}

public OnMaxCurrencyChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    g_MaxCurrency = StringToInt(newValue);

    War3_LogInfo("MaxCurrency was changed to %i", g_MaxCurrency);
}

public Native_War3_GetCurrencyMode(Handle:plugin, numParams)
{
    return _:g_CurrencyMode;
}

public Native_War3_GetMaxCurrency(Handle:plugin, numParams)
{
    return g_MaxCurrency;
}

public Native_War3_GetCurrencyName(Handle:plugin, numParams)
{
    new amount = GetNativeCell(1);
    new stringBuffer = GetNativeCell(3);

    decl String:currencyName[stringBuffer];
    if (g_CurrencyMode == CURRENCY_MODE_WAR3_GOLD)
    {
        if (amount >= -1 && amount <= 1)
        {
            Format(currencyName, stringBuffer, "%T", "War3_Currency_Singular", GetTrans());
        }
        else
        {
            Format(currencyName, stringBuffer, "%T", "War3_Currency_Plural", GetTrans());
        }
    }
    else if (g_CurrencyMode == CURRENCY_MODE_DORRAR)
    {
        if (amount >= -1 && amount <= 1)
        {
            Format(currencyName, stringBuffer, "%T", "War3_DollarCurrency_Singular", GetTrans());
        }
        else
        {
            Format(currencyName, stringBuffer, "%T", "War3_DollarCurrency_Plural", GetTrans());
        }
    }
    
    SetNativeString(2, currencyName, stringBuffer);
}

public Native_War3_GetCurrency(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    
    return GetCurrency(client);
}

public Native_War3_SetCurrency(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new newCurrency = GetNativeCell(2);
    
    return SetCurrency(client, newCurrency, g_CurrencyMode);
}

public Native_War3_AddCurrency(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new currencyToAdd = GetNativeCell(2);
    
    return SetCurrency(client, GetCurrency(client) + currencyToAdd, g_CurrencyMode);
}

public Native_War3_SubstractCurrency(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new currencyToSubstract = GetNativeCell(2);
    
    return SetCurrency(client, GetCurrency(client) - currencyToSubstract, g_CurrencyMode);
}

public Native_War3_GetGold(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    
    return W3GetPlayerProp(client, PlayerGold);
}

public Native_War3_SetGold(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new newGold = GetNativeCell(2);
    
    return SetCurrency(client, newGold, CURRENCY_MODE_WAR3_GOLD);
}

GetCurrency(client)
{
    new currency = -1;
    if (g_CurrencyMode == CURRENCY_MODE_WAR3_GOLD)
    {
        currency = W3GetPlayerProp(client, PlayerGold);
    }
    else if (g_CurrencyMode == CURRENCY_MODE_DORRAR)
    {
        if(GAMECSANY)
        {
            currency =  GetEntProp(client, Prop_Send, "m_iAccount");
        } 
        else if (GAMETF) 
        {
            currency =  GetEntProp(client, Prop_Send, "m_nCurrency");
        }
    }
    
    if (currency == -1)
    {
        War3_LogError("Player \"{client %i}\" has a invalid money amount!", client);
    }
    
    War3_LogInfo("Player \"{client %i}\" has %i money", client, currency);
    return currency;
}

bool:SetCurrency(client, newCurrency, W3CurrencyMode:currencyMode)
{
    War3_LogInfo("SetCurrency called for player \"{client %i}\" with amount %i", client, newCurrency);
    
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
        War3_LogInfo("Refusing to change the currency of player \"{client %i}\" - no change!", client);
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
    
    Call_StartForward(g_hOnCurrencyChanged);
    Call_PushCell(client);
    Call_PushCell(oldCurrency);
    Call_PushCell(newCurrency);
    Call_Finish();
    
    return true;
}