#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Warcraft Extended - Vampirism",
    author = "War3Source Team",
    description="Generic vampirism skill"
};

new Handle:h_ForwardOnWar3VampirismPost = INVALID_HANDLE;

public OnPluginStart()
{
    LoadTranslations("w3s.race.undead.phrases.txt");
}

public bool:InitNativesForwards()
{
    h_ForwardOnWar3VampirismPost = CreateGlobalForward("OnWar3VampirismPost", ET_Hook, Param_Cell, Param_Cell, Param_Cell);

    return true;
}

LeechHP(victim, attacker, damage, Float:percentage, bool:bBuff)
{
    new leechhealth = RoundToFloor(damage * percentage);
    if(leechhealth > 40)
    {
        leechhealth = 40;
    }

    new iOldHP = GetClientHealth(attacker);
    
    bBuff ? War3_HealToBuffHP(attacker, leechhealth) : War3_HealToMaxHP(attacker, leechhealth);
    
    new iNewHP = GetClientHealth(attacker);
    
    if (iOldHP  != iNewHP)
    {
        new iHealthLeeched = iNewHP - iOldHP;
        War3_VampirismEffect(victim, attacker, iHealthLeeched);
        
        Call_StartForward(h_ForwardOnWar3VampirismPost);
        Call_PushCell(victim);
        Call_PushCell(attacker);
        Call_PushCell(iHealthLeeched);
        Call_Finish();
    }
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(!isWarcraft && ValidPlayer(victim) && ValidPlayer(attacker, true) && attacker != victim && GetClientTeam(victim) != GetClientTeam(attacker))
    {
        new Float:fVampirePercentage = W3GetBuffSumFloat(attacker, fVampirePercent);
        new Float:fVampirePercentageNoBuff = W3GetBuffSumFloat(attacker, fVampirePercentNoBuff);

        if(!W3HasImmunity(victim, Immunity_Skills) && !Hexed(attacker))
        {
            // This one runs first
            if(fVampirePercentageNoBuff > 0.0)
            {
                LeechHP(victim, attacker, RoundToFloor(damage), fVampirePercentageNoBuff, false);
            }

            if(fVampirePercentage > 0.0)
            {
                LeechHP(victim, attacker, RoundToFloor(damage), fVampirePercentage, true);
            }
        }
    }
}

// PostHurt does not have the inflictor
public OnW3TakeDmgBullet(victim, attacker, Float:damage)
{
    if(W3GetDamageIsBullet() && ValidPlayer(victim) && ValidPlayer(attacker, true) && attacker != victim && GetClientTeam(victim) != GetClientTeam(attacker))
    {
        new Float:fVampirePercentage = 0.0;
        new Float:fVampireNoBuffPercentage = 0.0;

        new inflictor = W3GetDamageInflictor();
        if (attacker == inflictor || !IsValidEntity(inflictor))
        {
            new String:weapon[64];
            GetClientWeapon(attacker, weapon, sizeof(weapon));

            if (W3IsDamageFromMelee(weapon))
            {
                fVampirePercentage += W3GetBuffSumFloat(attacker, fMeleeVampirePercent);
                fVampireNoBuffPercentage += W3GetBuffSumFloat(attacker, fMeleeVampirePercentNoBuff);
            }
        }

        if(!W3HasImmunity(victim, Immunity_Skills) && !Hexed(attacker))
        {
            // This one runs first
            if(fVampireNoBuffPercentage > 0.0)
            {
                LeechHP(victim, attacker, RoundToFloor(damage), fVampireNoBuffPercentage, false);
            }

            if(fVampirePercentage > 0.0)
            {
                LeechHP(victim, attacker, RoundToFloor(damage), fVampirePercentage, true);
            }
        }
    }
}