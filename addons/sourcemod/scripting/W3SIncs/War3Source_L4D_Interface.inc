/**
 * File: War3Source_L4D_Interface.inc
 * Description: Functions and stuff to make L4D specific races and whatnot
 * Author(s): War3Source Team  
 */

#include <sdktools>

static const    ASSAULT_RIFLE_OFFSET_IAMMO        = 12;
static const    SMG_OFFSET_IAMMO                  = 20;
static const    PUMPSHOTGUN_OFFSET_IAMMO          = 28;
static const    AUTO_SHOTGUN_OFFSET_IAMMO         = 32;
static const    HUNTING_RIFLE_OFFSET_IAMMO        = 36;
static const    MILITARY_SNIPER_OFFSET_IAMMO      = 40;
static const    GRENADE_LAUNCHER_OFFSET_IAMMO     = 68;

/* Weapon upgrade bit flags */
#define L4D2_WEPUPGFLAG_NONE            (0 << 0)
#define L4D2_WEPUPGFLAG_INCENDIARY      (1 << 0)
#define L4D2_WEPUPGFLAG_EXPLOSIVE       (1 << 1)
#define L4D2_WEPUPGFLAG_LASER           (1 << 2)

enum L4D2UseAction
{
    L4D2UseAction_None              = 0, // No use action active
    L4D2UseAction_Healing           = 1, // Includes healing yourself or a teammate.
    L4D2UseAction_Defibing          = 4, // When defib'ing a dead body.
    L4D2UseAction_GettingDefibed    = 5, // When comming back to life from a dead body.
    L4D2UseAction_PouringGas        = 8, // Pouring gas into a generator
    L4D2UseAction_Cola              = 9, // For Dead Center map 2 cola event, when handing over the cola to whitalker.
    L4D2UseAction_Button            = 10 // Such as buttons, timed buttons, generators, etc.
    /* List is not fully done, these are just the ones I have found so far */
}


enum L4D2GlowType
{
    L4D2Glow_None = 0,
    L4D2Glow_OnUse,
    L4D2Glow_OnLookAt,
    L4D2Glow_Constant
}

#define MODEL_GASCAN    "models/props_junk/gascan001a.mdl"
#define MODEL_PROPANE    "models/props_junk/propanecanister001a.mdl"

/**
 * Returns true if a infected is making love to a client.
 * 
 * Bug: If you kick the infected then this function will still return true
 * for the client until he gets properly freed from a infected attack.
 */
native bool:War3_L4D_IsHelpless(client);  

// TODO: Remove identifier? Clients can only have one progressbar at a time
//         anyway... 

/**
 * Activates a progressbar on the client that stays up there for x seconds.
 * 
 * The progressbar tries to behave like other use events in Left4Dead, stopping
 * when the client shoots or stops pressing the +use key etc.
 * Obviously before starting this you should check the clients buttons for 
 * IN_USE or else it will break off instantly
 * 
 * returns a identifier to clearly identify client - progressbar. 
 * -1 if there was an error
 */
native War3_L4D_ActivateProgressBar(client, Float:time);
/**
 * Cancels the current Progressbar on the given client
 */
native War3_L4D_CancelProgressBar(client);

/**
 * Check if the client is currently in progress bar mode
 */
native bool:War3_L4D_HasProgressBar(client);

/**
 * Forwards for the progress bar. 
 */
forward HasFinishedProgress(client, progress_id);
forward HasAbortedProgress(client, progress_id);

stock bool:War3_SurvivorHittingZombie(victim, attacker)
{
    if ( ValidPlayer(attacker) && GetClientTeam(attacker) == TEAM_SURVIVORS &&
        ( War3_IsL4DZombieEntity(victim) || (ValidPlayer(victim) && GetClientTeam(victim) == TEAM_INFECTED) )  
       )
    {
        return true;
    }
    
    return false;
}

stock bool:War3_ZombieHittingSurvivor(victim, attacker)
{
    if ( ValidPlayer(victim) && GetClientTeam(victim) == TEAM_SURVIVORS &&
        ( War3_IsL4DZombieEntity(attacker) || (ValidPlayer(attacker) && GetClientTeam(attacker) == TEAM_INFECTED) )  
       )
    {
        return true;
    }
    
    return false;
}

//  * type == 0: Fire
//  * type != 0: Explosion
native War3_L4D_Explode(attacker, Float:pos[3], type);

stock bool:War3_IsPlayerIncapped(client)
{
    if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
    return false;
}

stock bool:War3_IsL4DZombieEntity(iEntity) {
    if (GAMEL4DANY) {
        return (War3_IsCommonInfected(iEntity) || War3_IsWitch(iEntity));
    }

    return false;
}

// returns true for both common and uncommon infected
stock bool:War3_IsCommonInfected(iEntity)
{
    if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
    {
        decl String:strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        
        return StrEqual(strClassName, "infected");
    }
    return false;
}  

// Check if a infected is a uncommon one
stock bool:War3_IsUncommonInfected(iEntity)
{
    if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
    {
        decl String:ModelName[128];
        GetEntPropString(iEntity, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));
        
        return (StrEqual(ModelName, "models/infected/common_male_riot.mdl") ||
                StrEqual(ModelName, "models/infected/common_male_ceda.mdl") ||
                StrEqual(ModelName, "models/infected/common_male_clown.mdl") ||
                StrEqual(ModelName, "models/infected/common_male_mud.mdl") ||
                StrEqual(ModelName, "models/infected/common_male_roadcrew.mdl") ||
                StrEqual(ModelName, "models/infected/common_male_jimmy.mdl") ||
                StrEqual(ModelName, "models/infected/common_male_fallen_survivor.mdl"));
    }
    return false;
}

stock bool:War3_IsWitch(iEntity)
{
    if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
    {
        decl String:strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        return StrEqual(strClassName, "witch");
    }
    return false;
}

// To check if an infected in versus hasn't spawned yet
stock bool:IsPlayerGhost(client)
{
    if (GetEntProp(client, Prop_Send, "m_isGhost", 1) == 1)
    {
        return true;
    }
    
    return false;
}

stock Float:GetSurvivorTempHealth(client)
{
    new Float:temphp = GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate")));
    return temphp > 0.0 ? temphp : 0.0;
}

stock SetSurvivorTempHealth(client, Float:hp)
{
    SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
    SetEntPropFloat(client, Prop_Send, "m_healthBuffer", hp);
}

stock GetAmountOfTanks()
{
    new amount;
    decl String:modelName[100];
    for(new i=1; i <= MaxClients; i++) 
    {
        if(ValidPlayer(i, true) && GetClientTeam(i) == TEAM_INFECTED) 
        {
            GetClientModel(i, modelName, sizeof(modelName));
            if (StrContains(modelName, "hulk", false) != -1) {
                amount++;
            }
        }
    }
    
    return amount;
}

stock GetMaxMagSize(const String:weapon[])
{
    if (GAMEL4DANY)
    {
        if ((StrEqual(weapon, "weapon_rifle", false)) || (StrEqual(weapon, "weapon_rifle_sg552", false)) || (StrEqual(weapon, "weapon_smg", false) || StrEqual(weapon, "weapon_smg_silenced", false) || StrEqual(weapon, "weapon_smg_mp5", false)))
        {
            return 50;
        }
        else if (StrEqual(weapon, "weapon_rifle_ak47", false))
        {
            return 40;
        }
        else if (StrEqual(weapon, "weapon_rifle_desert", false))
        {
            return 60;
        }
        else if (StrEqual(weapon, "weapon_autoshotgun", false) || StrEqual(weapon, "weapon_shotgun_spas", false))
        {
            return 10;
        }
        else if (StrEqual(weapon, "weapon_grenade_launcher", false))
        {
            return 1;
        }
        else if (StrEqual(weapon, "weapon_pumpshotgun", false) || StrEqual(weapon, "weapon_shotgun_chrome", false))
        {
            return 8;
        }
        else if (StrEqual(weapon, "weapon_hunting_rifle", false))
        {
            return 15;
        }
        else if (StrEqual(weapon, "weapon_sniper_military", false))
        {
            return 30;
        }
        else if (StrEqual(weapon, "weapon_sniper_awp", false))
        {
            return 20;
        }
        else if (StrEqual(weapon, "weapon_sniper_scout", false))
        {
            return 15;
        }
        else if (StrEqual(weapon, "weapon_rifle_m60", false))
        {
            return 150;
        }
    }
    
    return 0;
}

stock GetCurrentBackupAmmo(client)
{
    decl String:weapon[64];
    new iWeapon = GetPlayerWeaponSlot(client, 0);
    GetEdictClassname(iWeapon, weapon, sizeof(weapon));
    
    new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo");
    new backup_ammo = 0;

    if (StrEqual(weapon, "weapon_rifle", false) || StrEqual(weapon, "weapon_rifle_ak47", false) || StrEqual(weapon, "weapon_rifle_desert", false) || StrEqual(weapon, "weapon_rifle_sg552", false))
    {
        backup_ammo = GetEntData(client, iAmmoOffset + ASSAULT_RIFLE_OFFSET_IAMMO);
    }
    else if (StrEqual(weapon, "weapon_smg", false) || StrEqual(weapon, "weapon_smg_silenced", false) || StrEqual(weapon, "weapon_smg_mp5", false))
    {
        backup_ammo = GetEntData(client, iAmmoOffset + SMG_OFFSET_IAMMO);
    }        
    else if (StrEqual(weapon, "weapon_pumpshotgun", false) || StrEqual(weapon, "weapon_shotgun_chrome", false))
    {
        backup_ammo = GetEntData(client, iAmmoOffset + PUMPSHOTGUN_OFFSET_IAMMO);
    }
    else if (StrEqual(weapon, "weapon_autoshotgun", false) || StrEqual(weapon, "weapon_shotgun_spas", false))
    {
        backup_ammo = GetEntData(client, iAmmoOffset + AUTO_SHOTGUN_OFFSET_IAMMO);
    }
    else if (StrEqual(weapon, "weapon_hunting_rifle", false))
    {
        backup_ammo = GetEntData(client, iAmmoOffset + HUNTING_RIFLE_OFFSET_IAMMO);
    }
    else if (StrEqual(weapon, "weapon_sniper_military", false) || StrEqual(weapon, "weapon_sniper_awp", false) || StrEqual(weapon, "weapon_sniper_scout", false))
    {
        backup_ammo = GetEntData(client, iAmmoOffset + MILITARY_SNIPER_OFFSET_IAMMO);
    }
    else if (StrEqual(weapon, "weapon_grenade_launcher"))
    {
        backup_ammo = GetEntData(client, iAmmoOffset + GRENADE_LAUNCHER_OFFSET_IAMMO);
    }
    
    return backup_ammo;
}

stock GetMaxBackupAmmo(const String:weapon[])
{
    if (GAMEL4DANY)
    {
        if (StrEqual(weapon, "weapon_rifle", false) || StrEqual(weapon, "weapon_rifle_ak47", false) || StrEqual(weapon, "weapon_rifle_desert", false) || StrEqual(weapon, "weapon_rifle_sg552", false))
        {
            return GetConVarInt(FindConVar("ammo_assaultrifle_max"));
        }
        else if (StrEqual(weapon, "weapon_smg", false) || StrEqual(weapon, "weapon_smg_silenced", false) || StrEqual(weapon, "weapon_smg_mp5", false))
        {
            return GetConVarInt(FindConVar("ammo_smg_max"));
        }    
        else if (StrEqual(weapon, "weapon_pumpshotgun", false) || StrEqual(weapon, "weapon_shotgun_chrome", false))
        {
            return GetConVarInt(FindConVar("ammo_shotgun_max"));
        }
        else if (StrEqual(weapon, "weapon_autoshotgun", false) || StrEqual(weapon, "weapon_shotgun_spas", false))
        {
            return GetConVarInt(FindConVar("ammo_autoshotgun_max"));
        }
        else if (StrEqual(weapon, "weapon_hunting_rifle", false))
        {
            return GetConVarInt(FindConVar("ammo_huntingrifle_max"));
        }
        else if (StrEqual(weapon, "weapon_sniper_military", false) || StrEqual(weapon, "weapon_sniper_awp", false) || StrEqual(weapon, "weapon_sniper_scout", false))
        {
            return GetConVarInt(FindConVar("ammo_sniperrifle_max"));
        }
        else if (StrEqual(weapon, "weapon_grenade_launcher", false))
        {
            return GetConVarInt(FindConVar("ammo_grenadelauncher_max"));
        }
        else if (StrEqual(weapon, "weapon_rifle_m60", false))
        {
            return 0;
        }
    }
    
    return 0;
}

stock SetBackupAmmo(client, ammo)
{
    decl String:weapon[64];
    new iWeapon = GetPlayerWeaponSlot(client, 0);
    GetEdictClassname(iWeapon, weapon, sizeof(weapon));
    
    new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo");

    if (StrEqual(weapon, "weapon_rifle", false) || StrEqual(weapon, "weapon_rifle_ak47", false) || StrEqual(weapon, "weapon_rifle_desert", false) || StrEqual(weapon, "weapon_rifle_sg552", false))
    {
        SetEntData(client, iAmmoOffset + ASSAULT_RIFLE_OFFSET_IAMMO, ammo);
    }
    else if (StrEqual(weapon, "weapon_smg", false) || StrEqual(weapon, "weapon_smg_silenced", false) || StrEqual(weapon, "weapon_smg_mp5", false))
    {
        SetEntData(client, iAmmoOffset + SMG_OFFSET_IAMMO, ammo);
    }        
    else if (StrEqual(weapon, "weapon_pumpshotgun", false) || StrEqual(weapon, "weapon_shotgun_chrome", false))
    {
        SetEntData(client, iAmmoOffset + PUMPSHOTGUN_OFFSET_IAMMO, ammo);
    }
    else if (StrEqual(weapon, "weapon_autoshotgun", false) || StrEqual(weapon, "weapon_shotgun_spas", false))
    {
        SetEntData(client, iAmmoOffset + AUTO_SHOTGUN_OFFSET_IAMMO, ammo);
    }
    else if (StrEqual(weapon, "weapon_hunting_rifle", false))
    {
        SetEntData(client, iAmmoOffset + HUNTING_RIFLE_OFFSET_IAMMO, ammo);
    }
    else if (StrEqual(weapon, "weapon_sniper_military", false) || StrEqual(weapon, "weapon_sniper_awp", false) || StrEqual(weapon, "weapon_sniper_scout", false))
    {
        SetEntData(client, iAmmoOffset + MILITARY_SNIPER_OFFSET_IAMMO, ammo);
    }
    else if (StrEqual(weapon, "weapon_grenade_launcher"))
    {
        SetEntData(client, iAmmoOffset + GRENADE_LAUNCHER_OFFSET_IAMMO, ammo);
    }
}

// Client is rendered invisible!
stock GotoThirdPerson(client)
{
    SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
    SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
    SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
}

stock GotoFirstPerson(client)
{
    SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
    SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
    SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
}

stock GotoThirdPersonVisible(client)
{
    SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
    SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
    SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
}

stock GetEntityHP(entity)
{
    return GetEntProp(entity, Prop_Data, "m_iHealth");
}

/* Great if you're restricting a race to a specific weapon and want to block
 * all other weapon pickups. Example:
 * 
 * 1. Give player the weapons he should use on Spawn.
 * 2. SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
 * 
 * public Action:OnWeaponCanUse(client, weapon)
{
    decl String:entityName[64];
    GetEdictClassname(weapon, entityName, sizeof(entityName));
    
    if (IsWeapon(entityName))
        return Plugin_Handled; 
    
    return Plugin_Continue;
}
 * Enjoy!
 */


stock bool:IsWeapon(const String:weaponName[])
{
    return (StrEqual(weaponName, "weapon_rifle", false) || 
            StrEqual(weaponName, "weapon_rifle_ak47", false) || 
            StrEqual(weaponName, "weapon_rifle_desert", false) || 
            StrEqual(weaponName, "weapon_rifle_sg552", false) || 
            StrEqual(weaponName, "weapon_smg", false) || 
            StrEqual(weaponName, "weapon_smg_silenced", false) || 
            StrEqual(weaponName, "weapon_smg_mp5", false) || 
            StrEqual(weaponName, "weapon_pumpshotgun", false) || 
            StrEqual(weaponName, "weapon_shotgun_chrome", false) || 
            StrEqual(weaponName, "weapon_autoshotgun", false) || 
            StrEqual(weaponName, "weapon_shotgun_spas", false) || 
            StrEqual(weaponName, "weapon_hunting_rifle", false) || 
            StrEqual(weaponName, "weapon_sniper_military", false) || 
            StrEqual(weaponName, "weapon_sniper_awp", false) || 
            StrEqual(weaponName, "weapon_sniper_scout", false) || 
            StrEqual(weaponName, "weapon_grenade_launcher", false) || 
            StrEqual(weaponName, "weapon_rifle_m60", false) ||
            StrEqual(weaponName, "weapon_melee", false) ||
            StrEqual(weaponName, "weapon_pistol", false) ||
            StrEqual(weaponName, "weapon_pistol_magnum", false));
}

stock CreateProgressBar(client, Float:fTimeDur)
{
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", fTimeDur);
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
}

stock KillProgressBar(client)
{
    SetEntProp(client, Prop_Send, "m_iCurrentUseAction", L4D2UseAction_None);
    
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
}

/* TAKEN FROM l4d_stocks.inc http://code.google.com/p/l4dstocks/source/browse/l4d_stocks.inc */

/**
 * Returns weapon upgrades of weapon.
 *
 * @param weapon        Weapon entity index.
 * @return                Weapon upgrade bits.
 * @error                Invalid entity index.
 */
stock L4D2_GetWeaponUpgrades(weapon)
{
    return GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
}

/**
 * Set weapon upgrades for weapon.
 *
 * @param weapon        Weapon entity index.
 * @param upgrades        Weapon upgrade bits.
 * @noreturn
 * @error                Invalid entity index.
 */
stock L4D2_SetWeaponUpgrades(weapon, upgrades)
{
    SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", upgrades);
}

/**
 * Returns infected attacker of survivor victim.
 *
 * Note: Infected attacker means the infected player that is currently
 * pinning down the survivor. Such as hunter, smoker, charger and jockey.
 *
 * @param client        Survivor client index.
 * @return                Infected attacker index, -1 if not found.
 * @error                Invalid client index.
 */
stock L4D2_GetInfectedAttacker(client)
{
    new attacker;

    /* Charger */
    attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
    if (attacker > 0) return attacker;

    attacker = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
    if (attacker > 0) return attacker;

    /* Hunter */
    attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
    if (attacker > 0) return attacker;

    /* Smoker */
    attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
    if (attacker > 0) return attacker;

    /* Jockey */
    attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
    if (attacker > 0) return attacker;

    return -1;
}

/**
 * Returns survivor victim of infected attacker.
 *
 * Note: Survivor victim means the survivor player that is currently pinned
 * down by an attacker. Such as hunter, smoker, charger and jockey.
 *
 * @param client        Infected client index.
 * @return                Survivor victim index, -1 if not found.
 * @error                Invalid client index.
 */
stock L4D2_GetSurvivorVictim(client)
{
    new victim;

    /* Charger */
    victim = GetEntPropEnt(client, Prop_Send, "m_pummelVictim");
    if (victim > 0) return victim;

    victim = GetEntPropEnt(client, Prop_Send, "m_carryVictim");
    if (victim > 0) return victim;

    /* Hunter */
    victim = GetEntPropEnt(client, Prop_Send, "m_pounceVictim");
    if (victim > 0) return victim;

    /* Smoker */
    victim = GetEntPropEnt(client, Prop_Send, "m_tongueVictim");
    if (victim > 0) return victim;

    /* Jockey */
    victim = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim");
    if (victim > 0) return victim;

    return -1;
}

/**
 * Returns upgraded ammo count for weapon.
 *
 * @param weapon        Weapon entity index.
 * @return                Upgraded ammo count.
 * @error                Invalid entity index.
 */
stock L4D2_GetWeaponUpgradeAmmoCount(weapon)
{
    return GetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
}

/**
 * Set upgraded ammo count in weapon.
 *
 * @param weapon        Weapon entity index.
 * @param count            Upgraded ammo count.
 * @noreturn
 * @error                Invalid entity index.
 */
stock L4D2_SetWeaponUpgradeAmmoCount(weapon, ttcount)
{
    SetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", ttcount);
}

/**
 * Returns player use action.
 *
 * @param client        Client index.
 * @return                Use action.
 * @error                Invalid client index.
 */
stock L4D2UseAction:L4D2_GetPlayerUseAction(client)
{
    return L4D2UseAction:GetEntProp(client, Prop_Send, "m_iCurrentUseAction");
}

/**
 * Returns player use action target.
 *
 * @param client        Client index.
 * @return                Entity index.
 * @error                Invalid client index.
 */
stock L4D2_GetPlayerUseActionTarget(client)
{
    return GetEntPropEnt(client, Prop_Send, "m_useActionTarget");
}

/**
 * Returns player use action owner.
 *
 * @param client        Client index.
 * @return                Entity index.
 * @error                Invalid client index.
 */
stock L4D2_GetPlayerUseActionOwner(client)
{
    return GetEntPropEnt(client, Prop_Send, "m_useActionOwner");
}

/**
 * Returns whether player is using a mounted weapon.
 *
 * @param client        Client index.
 * @return                True if using a mounted weapon, false otherwise.
 * @error                Invalid client index.
 */
stock bool:L4D_IsPlayerUsingMountedWeapon(client)
{
    return bool:GetEntProp(client, Prop_Send, "m_usingMountedWeapon");
}

/**
 * Return player current revive count.
 *
 * @param client        Client index.
 * @return                Survivor's current revive count.
 * @error                Invalid client index.
 */
stock L4D_GetPlayerReviveCount(client)
{
    return GetEntProp(client, Prop_Send, "m_currentReviveCount");
}

/**
 * Set player revive count.
 *
 * @param client        Client index.
 * @param count            Revive count.
 * @noreturn
 * @error                Invalid client index.
 */
stock L4D_SetPlayerReviveCount(client, zzcount)
{
    SetEntProp(client, Prop_Send, "m_currentReviveCount", zzcount);
}

/**
 * Return player intensity.
 *
 * Note: Its percentage. 0.0 - Player is calm, 1.0 - Player is stressed.
 *
 * @param client        Client index.
 * @return                Intensity.
 * @error                Invalid client index.
 */
stock Float:L4D_GetPlayerIntensity(client)
{
    /* This format is used to keep consistency with the Director which also
     * uses 0.0 for calm and 1.0 for stressed */
    return float(GetEntProp(client, Prop_Send, "m_clientIntensity")) / 100.0;
}

/**
 * Returns average survivor intensity.
 *
 * Note: Its percentage. 0.0 - All survivors is calm, 1.0 - All survivors is
 * stressed.
 *
 * @return                Average intensity level for survivors.
 */
stock Float:L4D_GetAvgSurvivorIntensity()
{
    new intensityTotal = 0;
    new intensityMaxTotal = 0;
    for (new i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) ||
            L4DTeam:GetClientTeam(i) != L4DTeam_Survivor ||
            !IsPlayerAlive(i) ||
            GetClientHealth(i) < 1)
        {
            continue;
        }

        intensityMaxTotal += 100;
        intensityTotal += GetEntProp(i, Prop_Send, "m_clientIntensity");
    }

    /* This format is used to keep consistency with the Director which also
     * uses 0.0 for calm and 1.0 for stressed */
    return float(intensityTotal) / float(intensityMaxTotal);
}

/**
 * Set player intensity.
 *
 * Note: Its percentage. 0.0 - Player is calm, 1.0 - Player is stressed.
 *
 * @param client        Client index.
 * @param intensity        Intensity.
 * @noreturn
 * @error                Invalid client index.
 */
stock L4D_SetPlayerIntensity(client, Float:intensity)
{
    SetEntProp(client, Prop_Send, "m_clientIntensity", RoundToNearest(intensity * 100.0);
}

/**
 * Returns whether player is calm.
 *
 * Note: Player is calm means that the player have not taken damage or
 * fired their weapon for a while.
 *
 * @param client        Client index.
 * @return                True if player is calm, false otherwise.
 * @error                Invalid client index.
 */
stock bool:L4D_IsPlayerCalm(client)
{
    return bool:GetEntProp(client, Prop_Send, "m_isCalm");
}

/**
 * Set player is calm state.
 *
 * Note: Player is calm means that the player have not taken damage or
 * fired their weapon for a while.
 *
 * @param client        Client index.
 * @param isCalm        Whether player is calm.
 * @noreturn
 * @error                Invalid client index.
 */
stock L4D_SetPlayerCalmState(client, bool:isCalm)
{
    SetEntProp(client, Prop_Send, "m_isCalm", _:isCalm);
}

/**
 * Returns whether player is on third strike.
 *
 * @param client        Client index.
 * @return                True if on third strike, false otherwise.
 * @error                Invalid client index.
 */
stock bool:L4D_IsPlayerOnThirdStrike(client)
{
    return bool:GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike");
}

/**
 * Set player third strike state.
 *
 * @param client        Client index.
 * @param onThirdStrike    Whether survivor is on third strike.
 * @noreturn
 * @error                Invalid client index.
 */
stock L4D_SetPlayerThirdStrikeState(client, bool:onThirdStrike)
{
    SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", _:onThirdStrike);
}

/**
 * Returns whether player is going to die.
 *
 * Note: This is not the same as is player on third strike. While on third
 * strike defines whether player should die next time they get incapacitated,
 * this defines whether the survivor should limp when they hit 1hp and make
 * the character vocalize their "I dont think I'm gonna make it" lines.
 *
 * @param client        Client index.
 * @return                True if player is going to die, false otherwise.
 * @error                Invalid client index.
 */
stock bool:L4D_IsPlayerGoingToDie(client)
{
    return bool:GetEntProp(client, Prop_Send, "m_isGoingToDie");
}

/**
 * Set player is going to die state.
 *
 * @param client        Client index.
 * @param isGoingToDie    Whether player is going to die.
 * @noreturn
 * @error                Invalid client index.
 */
stock L4D_SetPlayerIsGoingToDie(client, bool:isGoingToDie)
{
    SetEntProp(client, Prop_Send, "m_isGoingToDie", _:isGoingToDie);
}

/**
 * Set entity glow flashing state.
 *
 * @param entity        Entity index.
 * @parma flashing        Whether glow will be flashing.
 * @noreturn
 * @error                Invalid entity index or entity does not support glow.
 */
stock L4D2_SetEntGlow_Flashing(entity, bool:flashing)
{
    SetEntProp(entity, Prop_Send, "m_bFlashing", _:flashing);
}

/**
 * Set entity glow color.
 *
 * @param entity        Entity index.
 * @parma colorOverride    Glow color, RGB.
 * @noreturn
 * @error                Invalid entity index or entity does not support glow.
 */
stock L4D2_SetEntGlow_ColorOverride(entity, colorOverride[3])
{
    SetEntProp(entity, Prop_Send, "m_glowColorOverride", colorOverride[0] + (colorOverride[1] * 256) + (colorOverride[2] * 65536));
}

/**
 * Set entity glow min range.
 *
 * @param entity        Entity index.
 * @parma minRange        Glow min range.
 * @noreturn
 * @error                Invalid entity index or entity does not support glow.
 */
stock L4D2_SetEntGlow_MinRange(entity, minRange)
{
    SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", minRange);
}

/**
 * Set entity glow range.
 *
 * @param entity        Entity index.
 * @parma range            Glow range.
 * @noreturn
 * @error                Invalid entity index or entity does not support glow.
 */
stock L4D2_SetEntGlow_Range(entity, range)
{
    SetEntProp(entity, Prop_Send, "m_nGlowRange", range);
}

/**
 * Set entity glow. This is consider safer and more robust over setting each glow
 * property on their own because glow offset will be check first.
 *
 * @param entity        Entity index.
 * @parma type            Glow type.
 * @param range            Glow max range, 0 for unlimited.
 * @param minRange        Glow min range.
 * @param colorOverride Glow color, RGB.
 * @param flashing        Whether the glow will be flashing.
 * @return                True if glow was set, false if entity does not support
 *                        glow.
 */
stock bool:L4D2_SetEntGlow(entity, L4D2GlowType:type, range, minRange, colorOverride[3], bool:flashing)
{
    decl String:netclass[128];
    GetEntityNetClass(entity, netclass, 128);

    new offset = FindSendPropInfo(netclass, "m_iGlowType");
    if (offset < 1)
    {
        return false;    
    }

    L4D2_SetEntGlow_Type(entity, type);
    L4D2_SetEntGlow_Range(entity, range);
    L4D2_SetEntGlow_MinRange(entity, minRange);
    L4D2_SetEntGlow_ColorOverride(entity, colorOverride);
    L4D2_SetEntGlow_Flashing(entity, flashing);
    return true;
}

/**
 * Set entity glow type.
 *
 * @param entity        Entity index.
 * @parma type            Glow type.
 * @noreturn
 * @error                Invalid entity index or entity does not support glow.
 */
stock L4D2_SetEntGlow_Type(entity, L4D2GlowType:type)
{
    SetEntProp(entity, Prop_Send, "m_iGlowType", _:type);
}

/**
 * Returns resource entity.
 *
 * @return                Entity index of resource entity, -1 if not found.
 */
stock L4D_GetResourceEntity()
{
    return FindEntityByClassname(-1, "terror_player_manager");
}

/**
 * Returns whether the finale is active.
 *
 * @return                True if finale is active, false otherwise.
 */
stock bool:L4D_IsFinaleActive()
{
    new entity = L4D_GetResourceEntity();

    if (entity == -1)
    {
        return false;
    }

    return bool:GetEntProp(entity, Prop_Send, "m_isFinale", 1);
}

/**
 * Returns survivor player shove penalty.
 *
 * @param client        Player index.
 * @return                Current shove penalty of player.
 */
stock L4D_GetPlayerShovePenalty(client)
{
    return GetEntProp(client, Prop_Send, "m_iShovePenalty");
}

/**
 * Set survivor player shove penalty.
 *
 * @param client        Player index.
 * @param shovePenalty    Shove penalty.
 * @noreturn
 * @error                Invalid client index.
 */
stock L4D_SetPlayerShovePenalty(client, shovePenalty)
{
    SetEntProp(client, Prop_Send, "m_iShovePenalty", shovePenalty);
}

/**
 * Set player's incapacitated state.
 *
 * @param client        Player index.
 * @param isIncapacitated Whether the player is incapacitated.
 * @noreturn
 * @error                Invalid client index.
 */
stock L4D_SetPlayerIncapacitatedState(client, bool:isIncapacitated)
{
    SetEntProp(client, Prop_Send, "m_isIncapacitated", isIncapacitated, 1);
}
