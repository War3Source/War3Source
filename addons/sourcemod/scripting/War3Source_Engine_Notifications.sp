#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Notifications",
    author = "War3Source Team",
    description = "Centralize some notifications"
};

public bool:InitNativesForwards()
{
    CreateNative("War3_NotifyPlayerTookDamageFromSkill", Native_NotifyPlayerTookDamageFromSkill);

    return true;
}

public OnPluginStart()
{
    // Load Translations
}

public Native_NotifyPlayerTookDamageFromSkill(Handle:plugin, numParams)
{
    new victim = GetNativeCell(1);
    new attacker = GetNativeCell(2);
    new damage = GetNativeCell(3);
    new skill = GetNativeCell(4);
    
    if (skill == 0)
    {
        return;
    }
    
    new String:sAttackerName[32];
    GetClientName(attacker, sAttackerName, sizeof(sAttackerName));
        
    new String:sVictimName[32];
    GetClientName(victim, sVictimName, sizeof(sVictimName));
    
    new race = War3_GetRace(victim);
    new String:sSkillName[32];
    
    SetTrans(victim);
    W3GetRaceSkillName(race, skill, sSkillName, sizeof(sSkillName));
    
    W3Hint(victim, HINT_DMG_DEALT, 1.0, "You did +%i damage to %s with %s", damage, sAttackerName, sSkillName);
    PrintToConsole(victim, "You did +%i damage to %s with %s", damage, sAttackerName, sSkillName);

    SetTrans(attacker);
    W3GetRaceSkillName(race, skill, sSkillName, sizeof(sSkillName));
    
    W3Hint(attacker, HINT_DMG_RCVD, 1.0, "%s did %i damage to you with %s", sVictimName, damage, sSkillName);
    PrintToConsole(attacker, "%s did %i damage to you with %s", sVictimName, damage, sSkillName);
}