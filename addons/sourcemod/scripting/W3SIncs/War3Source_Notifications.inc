/**
 * File: War3Source_Notifications.inc
 * Description: Easier stocks for notification
 * Author(s): War3Source Team  
 */

// TODO: Translations

/** 
 * Show somebody that an enemy skill caused them damage
 */
stock War3_NotifyPlayerTookDamageFromSkill(victim, attacker, damage, skill)
{
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