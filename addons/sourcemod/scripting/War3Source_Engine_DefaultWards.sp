#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Default Wards",
    author = "War3Source Team",
    description = "Default ward implementations"
};

enum {
    BEHAVIOR_DAMAGE=0,
    BEHAVIOR_HEAL,
    BEHAVIOR_LAST, // not a real ward behavior, just for indexing
}

new BehaviorIndex[BEHAVIOR_LAST];

new BeamSprite = -1;
new HaloSprite = -1;

public OnMapStart()
{
    BeamSprite = War3_PrecacheBeamSprite();
    HaloSprite = War3_PrecacheHaloSprite();
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
    if (num == 0)
    {
        BehaviorIndex[BEHAVIOR_DAMAGE] = War3_CreateWardBehavior("damage", "Damage ward", "Deals damage to targets");
        BehaviorIndex[BEHAVIOR_HEAL] = War3_CreateWardBehavior("heal", "Healing ward", "Heals targets");
    }
}

public OnWardPulse(wardindex, behavior)
{
    if(behavior != BehaviorIndex[BEHAVIOR_DAMAGE] && behavior != BehaviorIndex[BEHAVIOR_HEAL])
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
    } 
    else 
    {
        team == TEAM_BLUE ? War3_GetWardColor2(wardindex, beamcolor) : War3_GetWardColor3(wardindex, beamcolor);
    }
    
    doVisualEffect(wardindex, beamcolor);
}

doVisualEffect(wardindex, beamcolor[4]) 
{
    decl Float:fWardLocation[3];
    War3_GetWardLocation(wardindex, fWardLocation);
    new Float:fInterval = War3_GetWardInterval(wardindex);
    new wardRadius = War3_GetWardRadius(wardindex);

    new Float:fStartPos[3];
    new Float:fEndPos[3];
    new Float:tempVec1[] = {0.0, 0.0, WARDBELOW};
    new Float:tempVec2[] = {0.0, 0.0, WARDABOVE};
    
    AddVectors(fWardLocation, tempVec1, fStartPos);
    AddVectors(fWardLocation, tempVec2, fEndPos);

    TE_SetupBeamPoints(fStartPos, fEndPos, BeamSprite, HaloSprite, 0, GetRandomInt(30, 100), fInterval, 70.0, 70.0, 0, 30.0, beamcolor, 10);
    TE_SendToAll();
    
    new Float:StartRadius = wardRadius / 2.0;
    new Speed = RoundToFloor((wardRadius - StartRadius) / fInterval);
    
    TE_SetupBeamRingPoint(fWardLocation, StartRadius, float(wardRadius), BeamSprite, HaloSprite, 0,1, fInterval, 20.0, 1.5, beamcolor, Speed, 0);
    TE_SendToAll();
}

public OnWardTrigger(wardindex, victim, owner, behavior) 
{
    decl data[MAXWARDDATA];
    decl Float:VictimPos[3];
    
    War3_GetWardData(wardindex, data);
    GetClientAbsOrigin(victim, VictimPos);
    
    if (behavior == BehaviorIndex[BEHAVIOR_DAMAGE]) 
    {
        if(W3HasImmunity(victim, Immunity_Wards) || W3HasImmunity(victim, Immunity_Skills))
        {
            W3MsgSkillBlocked(victim, _, "Wards");
        }
        else
        {
            new damage = data[War3_GetSkillLevel(owner, War3_GetRace(owner), War3_GetWardSkill(wardindex))];
            
            War3_DealDamage(victim, damage, owner, _, "weapon_wards");
            VictimPos[2] += 65.0;
            War3_TF_ParticleToClient(0, GetApparentTeam(victim) == TEAM_RED ? "healthlost_red" : "healthlost_blu", VictimPos);
        }
    }
    
    else if (behavior == BehaviorIndex[BEHAVIOR_HEAL]) 
    {
        new healAmount = data[War3_GetSkillLevel(owner, War3_GetRace(owner), War3_GetWardSkill(wardindex))];

        if (War3_HealToMaxHP(victim, healAmount))
        {
            VictimPos[2] += 65.0;
            War3_TF_ParticleToClient(0, GetApparentTeam(victim) == TEAM_RED ? "healthgained_red" : "healthgained_blu", VictimPos);
        }
    }
}