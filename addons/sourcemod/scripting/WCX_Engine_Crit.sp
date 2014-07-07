#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Warcraft Extended - Crit",
    author = "War3Source Team",
    description="Generic crit skill"
};

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    // not written to be compatible with left4dead
    if((victim == attacker) || (!ValidPlayer(victim) || !ValidPlayer(attacker)) || (GetClientTeam(victim) == GetClientTeam(attacker)))
    {
        return;
    }

    // Typical cases of War3Source damage
    if(StrEqual(weapon, "crit", false) || StrEqual(weapon, "bash", false) || 
       StrEqual(weapon, "weapon_crit", false) || StrEqual(weapon, "weapon_bash", false))
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
                if(!W3IsDamageFromMelee(weapon) && !StrEqual(weapon,"hegrenade",false))
                {
                    PercentIncrease += DamageMultiplier;
                    DamageIncrease = BonusDamage;
                }
            }
            //2 (grenade damage damage increase) 
            case(2):{
                if(StrEqual(weapon,"hegrenade",false))
                {
                    PercentIncrease += DamageMultiplier;
                    DamageIncrease = BonusDamage;
                }
            }
            //3 (melee damage damage increase)
            case(3):{
                if(W3IsDamageFromMelee(weapon))
                {
                    PercentIncrease += DamageMultiplier;
                    DamageIncrease = BonusDamage;
                }
            }
            //4 (melee and bullet damage increase)
            case(4):{
                if(!StrEqual(weapon,"hegrenade",false))
                {
                    PercentIncrease += DamageMultiplier;
                    DamageIncrease = BonusDamage;
                }
            }
            //5 (melee and grenade damage increase) 
            case(5):{
                if(StrEqual(weapon,"hegrenade",false)||W3IsDamageFromMelee(weapon))
                {
                    PercentIncrease += DamageMultiplier;
                    DamageIncrease = BonusDamage;
                }
            }
            //6 (bullet and grenade damage increase)
            case(6):{
                if(StrEqual(weapon,"hegrenade",false)||!W3IsDamageFromMelee(weapon))
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
                    if(!W3IsDamageFromMelee(weapon) && !StrEqual(weapon,"hegrenade",false))
                        CritMultiplier += DamageMultiplier;
                }
                //3 (grenade damage damage increase) 
                case(3):{
                    if(StrEqual(weapon,"hegrenade",false))
                        CritMultiplier += DamageMultiplier;
                }
                //4 (melee damage damage increase)
                case(4):{
                    if(W3IsDamageFromMelee(weapon))
                        CritMultiplier += DamageMultiplier;
                }
                //5 (melee and bullet damage increase)
                case(5):{
                    if(!StrEqual(weapon,"hegrenade",false))
                        CritMultiplier += DamageMultiplier;
                }
                //6 (melee and grenade damage increase) 
                case(6):{
                    if(StrEqual(weapon,"hegrenade",false)||W3IsDamageFromMelee(weapon))
                        CritMultiplier += DamageMultiplier;
                }
                //7 (bullet and grenade damage increase)
                case(7):{
                    if(StrEqual(weapon,"hegrenade",false)||!W3IsDamageFromMelee(weapon))
                        CritMultiplier += DamageMultiplier;
                }
            }
        }
    }
    new newdamage = RoundToFloor(PercentIncrease * damage);
    newdamage = newdamage + DamageIncrease;
    if(newdamage > 0 && ValidPlayer(victim, true))
    {
        new victimHealth = GetClientHealth(victim);
        War3_LogInfo("Dealing crit damage %i of player \"{client %i}\" to victim \"{client %i}\" (%i hp)", newdamage, attacker, victim, victimHealth);
        War3_DealDamage(victim, newdamage, attacker, _, "weapon_crit");
    }
}