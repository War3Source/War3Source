#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Warcraft Extended - Generic ward skills",
    author = "War3Source Team",
    description = "Default ward implementations"
};

enum {
    BEHAVIOR_DAMAGE=0,
    BEHAVIOR_HEAL,
    BEHAVIOR_SLOW,
    BEHAVIOR_LAST, // not a real ward behavior, just for indexing
}

new BehaviorIndex[BEHAVIOR_LAST];

public OnWar3LoadRaceOrItemOrdered2(num)
{
    if (num == 0)
    {
        BehaviorIndex[BEHAVIOR_DAMAGE] = War3_CreateWardBehavior("damage", "Damage ward", "Deals damage to targets");
        BehaviorIndex[BEHAVIOR_HEAL] = War3_CreateWardBehavior("heal", "Healing ward", "Heals targets");
        BehaviorIndex[BEHAVIOR_SLOW] = War3_CreateWardBehavior("slow", "Slowing ward", "Slows players");
    }
}

public OnWardPulse(wardindex, behavior)
{
    if(behavior != BehaviorIndex[BEHAVIOR_DAMAGE] && behavior != BehaviorIndex[BEHAVIOR_HEAL] && behavior != BehaviorIndex[BEHAVIOR_SLOW])
    {
        return;
    }
    
    new beamcolor[4];
    new team = GetClientTeam(War3_GetWardOwner(wardindex));

    if(War3_GetWardUseDefaultColor(wardindex)) 
    {
        if (behavior == BehaviorIndex[BEHAVIOR_DAMAGE])
        {
            beamcolor = team == TEAM_BLUE ?  {0, 0, 255, 255} : {255, 0, 0, 255};
        }
        else if (behavior == BehaviorIndex[BEHAVIOR_HEAL])
        {
            beamcolor = team == TEAM_BLUE ? {0, 255, 128, 255} : {128, 255, 0, 255};
        }
        else if (behavior == BehaviorIndex[BEHAVIOR_SLOW])
        {
            beamcolor = team == TEAM_BLUE ? {0, 200, 63, 255} : {255, 89, 246, 255};
        }
        
    } 
    else 
    {
        team == TEAM_BLUE ? War3_GetWardColor2(wardindex, beamcolor) : War3_GetWardColor3(wardindex, beamcolor);
    }
    
    War3_WardVisualEffect(wardindex, beamcolor);
}

public OnWardTrigger(wardindex, victim, owner, behavior) 
{
    decl data[MAXWARDDATA];
    
    War3_GetWardData(wardindex, data);
    
    if (behavior == BehaviorIndex[BEHAVIOR_DAMAGE]) 
    {
        if(W3HasImmunity(victim, Immunity_Wards) || W3HasImmunity(victim, Immunity_Skills))
        {
            W3MsgSkillBlocked(victim, _, "Wards");
        }
        else
        {
            new damage = data[War3_GetSkillLevel(owner, War3_GetRace(owner), War3_GetWardSkill(wardindex))];
            
            if(War3_DealDamage(victim, damage, owner, _, "weapon_wards"))
            {
                War3_ShowHealthLostParticle(victim);
            }
        }
    }
    
    else if (behavior == BehaviorIndex[BEHAVIOR_HEAL]) 
    {
        new healAmount = data[War3_GetSkillLevel(owner, War3_GetRace(owner), War3_GetWardSkill(wardindex))];

        if (War3_HealToMaxHP(victim, healAmount))
        {
            War3_ShowHealthGainedParticle(victim);
        }
    }
    
    else if (behavior == BehaviorIndex[BEHAVIOR_SLOW])
    {
        if(W3HasImmunity(victim, Immunity_Wards) || W3HasImmunity(victim, Immunity_Skills))
        {
            W3MsgSkillBlocked(victim, _, "Wards");
        }
        else
        {
            //new wardskill = War3_GetWardSkill(wardindex);
            //new slow = data[War3_GetSkillLevel(owner, War3_GetRace(owner), wardskill)];
            
            // do actual slowing
        }
    }
}