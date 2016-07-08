#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include "W3SIncs/War3Source_Interface"

#include <cstrike>

public Plugin:myinfo = 
{
    name = "War3Source - Addon - Ammo Control",
    author = "War3Source Team",
    description = "",
    url = "http://war3source.com/index.php?topic=525.0"
};

#define PLUGIN_VERSION "1.0"

#define ALLOW_ALL_WEAPONS 777
#define ALLOW_SPECIFIC_WEAPON 333

// Offsets
new g_iOffsetPrimaryAmmoType = -1;
new g_iOffsetActiveWeapon = -1;
new g_iOffsetClip = -1;
new g_iOffsetAmmo = -1;

// Globals
new g_iClip[MAXPLAYERS+1];
new g_iWeapon[MAXPLAYERS+1];
new bool:g_bIsReloading[MAXPLAYERS+1];
new bool:g_bDoneRealoading[MAXPLAYERS+1];

new String:g_sWeaponName[MAXPLAYERS+1][64];
new g_iWeaponAmmo[MAXPLAYERS+1];
new g_iWeaponClip[MAXPLAYERS+1];
new g_iWeaponSlot[MAXPLAYERS+1];

// Convars
new Handle:g_hCvarEnable = INVALID_HANDLE;
new bool:g_bCvar_Enable = true;

public APLRes:AskPluginLoad2Custom(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("War3_GiveWeaponAmmo", Native_GiveWeaponAmmo);
    CreateNative("War3_SetAmmoControl", Native_SetAmmoControl);
    return APLRes_Success;
}

public OnPluginStart()
{
    // Offsets
    g_iOffsetPrimaryAmmoType = FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType");
    g_iOffsetActiveWeapon = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
    g_iOffsetClip = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
    g_iOffsetAmmo = FindSendPropInfo("CCSPlayer", "m_iAmmo");
    
    // Convars
    CreateConVar("war3_ammocontrol_version", PLUGIN_VERSION, "Ammo Control Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    g_hCvarEnable = CreateConVar("war3_ammocontrol_enable", "1", "Enable/Disable Ammo Control", _, true, 0.0, true, 1.0);
    
    // Convar Hooks
    HookConVarChange(g_hCvarEnable, OnConVarChange);
    
    // Commands
    RegConsoleCmd("buy", BuyCheck);
    RegConsoleCmd("rebuy", BuyCheck);
    RegConsoleCmd("autobuy", BuyCheck);
}

public Action:BuyCheck(client, args)
{
    if (!g_bCvar_Enable)
        return Plugin_Continue;
    
    CreateTimer(0.1, UpdateWeaponAmmo, client);
    return Plugin_Continue;
}

public OnClientPutInServer(client)
{
    g_sWeaponName[client] = "";
    g_iWeaponClip[client] = -1;
    g_iWeaponAmmo[client] = -1;
    g_iWeaponSlot[client] = -1;
}

public OnClientDisconnect(client)
{
    g_sWeaponName[client] = "";
    g_iWeaponClip[client] = -1;
    g_iWeaponAmmo[client] = -1;
    g_iWeaponSlot[client] = -1;
}

public OnGameFrame()
{
    if (!g_bCvar_Enable)
        return;
    
    for (new i = 1; i < MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i))
        {
            new iWeapon = GetEntDataEnt2(i, g_iOffsetActiveWeapon);
            if (iWeapon > 0 && IsValidEdict(iWeapon))
            {
                decl String:sWeaponName[64];
                GetEdictClassname(iWeapon, sWeaponName, sizeof(sWeaponName));
                if (StrContains(sWeaponName, "weapon_", false) == -1)
                    continue;
                
                if (g_bDoneRealoading[i])
                {
                    new iCurrentClip = GetEntData(iWeapon, g_iOffsetClip);
                    
                    // Reload success
                    if (iCurrentClip != g_iClip[i])
                        RecalculateWeaponClip(i, iWeapon, g_iClip[i], iCurrentClip);
                    g_bDoneRealoading[i] = false;
                }
                
                new bool:bIsReloading = bool:GetEntProp(iWeapon, Prop_Data, "m_bInReload");
                
                // Player had just started to reload
                if (bIsReloading && !g_bIsReloading[i])
                {
                    new iCurrentClip = GetEntData(iWeapon, g_iOffsetClip);
                    g_iWeapon[i] = iWeapon;
                    g_iClip[i] = iCurrentClip;
                    g_bIsReloading[i] = true;
                    continue;
                }
                // Player had just finished to reload
                else if (!bIsReloading && g_bIsReloading[i])
                {
                    if (g_iWeapon[i] == iWeapon)
                        g_bDoneRealoading[i] = true;
                    g_bIsReloading[i] = false;
                }
            }
        }
    }
}

public RecalculateWeaponClip(client, weapon, oldclip, newclip)
{
    if (g_iWeaponClip[client] == -1)
        return;
    
    decl String:sWeaponName[64];
    GetEdictClassname(weapon, sWeaponName, sizeof(sWeaponName));
    
    decl String:sObserveWeaponName[64];
    new iObserveWeapon = GetPlayerWeaponSlot(client, g_iWeaponSlot[client]);
    if (iObserveWeapon > 0 && IsValidEdict(iObserveWeapon))
        GetEdictClassname(iObserveWeapon, sObserveWeaponName, sizeof(sObserveWeaponName));
    
    if (g_iWeaponSlot[client] == ALLOW_ALL_WEAPONS || StrEqual(sWeaponName, g_sWeaponName[client], false) || StrEqual(sWeaponName, sObserveWeaponName, false))
    {
        new ammotype = GetEntData(weapon, g_iOffsetPrimaryAmmoType);
        new newammo = GetEntData(client, g_iOffsetAmmo + (ammotype * 4));
        new addclip = g_iWeaponClip[client] - newclip;
        new allowadd = newammo < addclip ? newammo : addclip;
        newammo -= oldclip > newclip ? g_iWeaponClip[client] - oldclip : allowadd;
        newclip += allowadd;
        
        SetEntData(client, g_iOffsetAmmo + (ammotype * 4), newammo);
        SetEntData(weapon, g_iOffsetClip, newclip);
    }
}

public Action:UpdateWeaponAmmo(Handle:timer, any:client)
{
    if (!IsClientInGame(client))
        return;
    
    if (!IsPlayerAlive(client))
        return;
    
    if (g_iWeaponSlot[client] < 0)
        return;
    
    for (new i = 0; i < 4; i++)
    {
        new weapon = GetPlayerWeaponSlot(client, i);
        if (weapon > 0 && IsValidEdict(weapon))
        {
            decl String:sWeaponName[64];
            GetEdictClassname(weapon, sWeaponName, sizeof(sWeaponName));
            
            decl String:sObserveWeaponName[64];
            new iObserveWeapon = GetPlayerWeaponSlot(client, g_iWeaponSlot[client]);
            if (iObserveWeapon > 0 && IsValidEdict(iObserveWeapon))
                GetEdictClassname(iObserveWeapon, sObserveWeaponName, sizeof(sObserveWeaponName));
            
            if (StrEqual(sWeaponName, g_sWeaponName[client], false) || g_iWeaponSlot[client] == ALLOW_ALL_WEAPONS || StrEqual(sWeaponName, sObserveWeaponName, false))
            {
                if (g_iWeaponAmmo[client] != -1)
                {
                    new ammotype = GetEntData(weapon, g_iOffsetPrimaryAmmoType);
                    if (i != CS_SLOT_GRENADE)
                    {
                        SetEntData(client, g_iOffsetAmmo + (ammotype * 4), g_iWeaponAmmo[client]);
                    }
                    else
                    {
                        if (g_iWeaponSlot[client] == ALLOW_ALL_WEAPONS || g_iWeaponSlot[client] == CS_SLOT_GRENADE)
                        {
                            SetEntData(client, g_iOffsetAmmo + (11 * 4), g_iWeaponAmmo[client]);
                            SetEntData(client, g_iOffsetAmmo + (12 * 4), g_iWeaponAmmo[client]);
                            SetEntData(client, g_iOffsetAmmo + (13 * 4), g_iWeaponAmmo[client]);
                        }
                        else if (StrEqual(sWeaponName, "weapon_hegrenade", false))
                            SetEntData(client, g_iOffsetAmmo + (11 * 4), g_iWeaponAmmo[client]);
                        else if (StrEqual(sWeaponName, "weapon_flashbang", false))
                            SetEntData(client, g_iOffsetAmmo + (12 * 4), g_iWeaponAmmo[client]);
                        else if (StrEqual(sWeaponName, "weapon_smokegrenade", false))
                            SetEntData(client, g_iOffsetAmmo + (13 * 4), g_iWeaponAmmo[client]);
                    }
                }
                if (i != CS_SLOT_GRENADE && g_iWeaponClip[client] != -1)
                    SetEntData(weapon, g_iOffsetClip, g_iWeaponClip[client]);
            }
        }
    }
}

stock GiveWeaponAmmo(client, weapon, ammo = -1, clip = -1)
{
    new ammotype = GetEntData(weapon, g_iOffsetPrimaryAmmoType);
    if (ammotype > 0)
    {
        if (ammo >= 0)
            SetEntData(client, g_iOffsetAmmo + (ammotype * 4), ammo);
        if (clip >= 0 && ammotype != 11 && ammotype != 12 && ammotype != 13)
            SetEntData(weapon, g_iOffsetClip, clip);
    }
}

stock SetAmmoControl(client, String:weapon[64], ammo = -1, clip = -1, bool:update = false)
{
    if (!IsClientInGame(client))
        return;
    
    if (ammo < 0 && clip < 0)
    {
        g_sWeaponName[client] = "";
        g_iWeaponAmmo[client] = -1;
        g_iWeaponClip[client] = -1;
        g_iWeaponSlot[client] = -1;
        return;
    }
    
    if (ammo < 0)
        ammo = -1;
    else
        g_iWeaponAmmo[client] = ammo;
    if (clip < 0)
        clip = -1;
    else
        g_iWeaponClip[client] = clip;
    
    if (StrContains(weapon, "weapon_", false) == -1)
        Format(weapon, sizeof(weapon), "weapon_%s", weapon);
    
    if (StrContains(weapon, "weapon_all", false) == 0)
        g_iWeaponSlot[client] = ALLOW_ALL_WEAPONS;
    else if (StrContains(weapon, "weapon_primary", false) == 0)
        g_iWeaponSlot[client] = CS_SLOT_PRIMARY;
    else if (StrContains(weapon, "weapon_secondary", false) == 0)
        g_iWeaponSlot[client] = CS_SLOT_SECONDARY;
    else if (StrContains(weapon, "weapon_grenade", false) == 0)
        g_iWeaponSlot[client] = CS_SLOT_GRENADE;
    else
        g_iWeaponSlot[client] = ALLOW_SPECIFIC_WEAPON;
    
    strcopy(g_sWeaponName[client], sizeof(g_sWeaponName), weapon);
    
    if (update)
        CreateTimer(0.1, UpdateWeaponAmmo, client);
}

public OnConVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
    g_bCvar_Enable = GetConVarBool(g_hCvarEnable);
}

public OnConfigsExecuted()
{
    g_bCvar_Enable = GetConVarBool(g_hCvarEnable);
}

public Native_GiveWeaponAmmo(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new weapon = GetNativeCell(2);
    new ammo = -1;
    new clip = -1;
    
    if (numParams > 2)
    {
        ammo = GetNativeCell(3);
        if (numParams > 3)
            clip = GetNativeCell(4);
    }
    
    GiveWeaponAmmo(client, weapon, ammo, clip);
}

public Native_SetAmmoControl(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    decl String:weapon[64];
    new ammo = -1;
    new clip = -1;
    new bool:update = false;
    
    if (numParams > 1)
    {
        GetNativeString(2, weapon, sizeof(weapon));
        if (numParams > 2)
        {
            ammo = GetNativeCell(3);
            if (numParams > 3)
            {
                clip = GetNativeCell(4);
                if (numParams > 4)
                    update = GetNativeCell(5);
            }
        }
    }
    
    SetAmmoControl(client, weapon, ammo, clip, update);
}
