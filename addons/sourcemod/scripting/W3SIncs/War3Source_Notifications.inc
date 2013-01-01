/**
 * File: War3Source_Notifications.inc
 * Description: Easier stocks for notification
 * Author(s): Glider  
 * 
 */

// TODO: Translations

/** 
 * Generic stock to show somebody that they took damage from someone
 */
stock War3_PlayerTookDamage(victim, attacker, damage)
{
	new String:sAttackerName[32];
	GetClientName(attacker, sAttackerName, sizeof(sAttackerName));
	
	W3Hint(victim, HINT_DMG_RCVD, 1.0, "{player} did {amount} damage to you", sAttackerName, damage);
	PrintToConsole(victim, "{player} did {amount} damage to you", sAttackerName, damage);
}

/** 
 * Show somebody that an enemy skill caused them damage
 */
stock War3_PlayerTookDamageFromSkill(victim, attacker, damage, skill)
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