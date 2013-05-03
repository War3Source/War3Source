#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Warcraft Extended - Crit",
    author = "War3Source Team",
    description="Generic crit skill"
};

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePostHook);
}
public OnClientDisconnect(client)
{
    SDKUnhook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePostHook); 
}

public OnTakeDamagePostHook(victim, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3])
{
    // not written to be compatible with left4dead
    if((victim == attacker) || (!ValidPlayer(victim) || !ValidPlayer(attacker)) || (GetClientTeam(victim) == GetClientTeam(attacker)))
    {
        return;
    }

    // It appears we were attacked by a GHOST!
    if (weapon == -1 && inflictor == -1)
    {
        return;
    }
    
    // Figure out what really hit us. A weapon? A sentry gun?
    new String:weaponName[64];
    new realWeapon = weapon == -1 ? inflictor : weapon;
    GetEntityClassname(realWeapon, weaponName, sizeof(weaponName));

    War3_LogInfo("PostHurt called with weapon \"%s\"", weaponName);

    // Typical cases of War3Source damage
    if(StrEqual(weaponName, "crit", false) || StrEqual(weaponName, "bash", false) || 
       StrEqual(weaponName, "weapon_crit", false) || StrEqual(weaponName, "weapon_bash", false))
    {
        return;
    }

    new Float:CritChance = W3GetBuffSumFloat(attacker, fCritChance);
    new Float:CritMultiplier = W3GetBuffSumFloat(attacker,fCritModifier);
    new CritMode = W3GetBuffLastValue(attacker, iCritMode);
    new DamageMode = W3GetBuffLastValue(attacker, iDamageMode);
    new Float:DamageMultiplier = W3GetBuffSumFloat(attacker, fDamageModifier);
    new BonusDamage = W3GetBuffSumInt(attacker,iDamageBonus);
    
    new Float:PercentIncrease = 0.0;
    new DamageIncrease = 0;
    
    if((DamageMultiplier > 0.0) ||(BonusDamage > 0) || (DamageMode > 0))
    {
        switch(DamageMode)
        {
            //0 (all damage qualifies for damage increase)
            case(0):{
                PercentIncrease += DamageMultiplier;
                DamageIncrease = BonusDamage;
            }
            //1 (bullet damage damage increase)
            case(1):{
                if(!W3IsDamageFromMelee(weaponName) && !StrEqual(weaponName,"hegrenade",false))
                {
                    PercentIncrease += DamageMultiplier;
                    DamageIncrease = BonusDamage;
                }
            }
            //2 (grenade damage damage increase) 
            case(2):{
                if(StrEqual(weaponName,"hegrenade",false))
                {
                    PercentIncrease += DamageMultiplier;
                    DamageIncrease = BonusDamage;
                }
            }
            //3 (melee damage damage increase)
            case(3):{
                if(W3IsDamageFromMelee(weaponName))
                {
                    PercentIncrease += DamageMultiplier;
                    DamageIncrease = BonusDamage;
                }
            }
            //4 (melee and bullet damage increase)
            case(4):{
                if(!StrEqual(weaponName,"hegrenade",false))
                {
                    PercentIncrease += DamageMultiplier;
                    DamageIncrease = BonusDamage;
                }
            }
            //5 (melee and grenade damage increase) 
            case(5):{
                if(StrEqual(weaponName,"hegrenade",false)||W3IsDamageFromMelee(weaponName))
                {
                    PercentIncrease += DamageMultiplier;
                    DamageIncrease = BonusDamage;
                }
            }
            //6 (bullet and grenade damage increase)
            case(6):{
                if(StrEqual(weaponName,"hegrenade",false)||!W3IsDamageFromMelee(weaponName))
                {
                    PercentIncrease += DamageMultiplier;
                    DamageIncrease = BonusDamage;
                }
            }
        }
    }
    if(CritChance > 0.0 || CritMode > 0)
    {
        if(War3_Chance(CritChance))
        {
            switch(CritMode)
            {
                //1 (all damage qualifies for damage increase)
                case(1):{
                    CritMultiplier += DamageMultiplier;
                }
                //2 (bullet damage damage increase)
                case(2):{
                    if(!W3IsDamageFromMelee(weaponName) && !StrEqual(weaponName,"hegrenade",false))
                        CritMultiplier += DamageMultiplier;
                }
                //3 (grenade damage damage increase) 
                case(3):{
                    if(StrEqual(weaponName,"hegrenade",false))
                        CritMultiplier += DamageMultiplier;
                }
                //4 (melee damage damage increase)
                case(4):{
                    if(W3IsDamageFromMelee(weaponName))
                        CritMultiplier += DamageMultiplier;
                }
                //5 (melee and bullet damage increase)
                case(5):{
                    if(!StrEqual(weaponName,"hegrenade",false))
                        CritMultiplier += DamageMultiplier;
                }
                //6 (melee and grenade damage increase) 
                case(6):{
                    if(StrEqual(weaponName,"hegrenade",false)||W3IsDamageFromMelee(weaponName))
                        CritMultiplier += DamageMultiplier;
                }
                //7 (bullet and grenade damage increase)
                case(7):{
                    if(StrEqual(weaponName,"hegrenade",false)||!W3IsDamageFromMelee(weaponName))
                        CritMultiplier += DamageMultiplier;
                }
            }
        }
    }
    new newdamage = RoundToFloor(PercentIncrease * damage);
    newdamage = newdamage + DamageIncrease;
    if(newdamage > 0)
    {
        War3_LogInfo("Dealing crit damage %i of player \"{client %i}\" to victim \"{client %i}\"", newdamage, attacker, victim);
        War3_DealDamage(victim, newdamage, attacker, _, "weapon_crit");
    }
}