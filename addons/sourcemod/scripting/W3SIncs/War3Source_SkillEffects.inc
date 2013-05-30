/**
 * File: War3Source_SkillEffects.inc
 * Description: Provide effects for certain skills so they feel the same across all races
 * Author(s): War3Source Team  
 */

/** 
 * Evade incoming damage.
 * 
 * Use inside OnW3TakeDmgAllPre or OnW3TakeDmgBulletPre if the victim
 * should evade the incoming damage.
 */
native War3_EvadeDamage(victim, attacker);

/** 
 * Stock for skills that return damage, like Thorns Aura.
 * 
 * Doesn't actually return any damage, only does the effect :)
 * 
 * Note that victim is the guy getting shot and attacker the guy
 * who takes return damage.
 */
native War3_EffectReturnDamage(victim, attacker, damage, skill);

/** 
 * Stock for skills that leech HP
 * 
 * Currently does not show any effect for the victim
 */
native War3_VampirismEffect(victim, attacker, leechhealth);

/**
 * Called after health was leeched from a player
 */
forward OnWar3VampirismPost(victim, attacker, iHealthLeeched);

/** 
 * Stock for skills that bash
 */
native War3_BashEffect(victim, attacker);

/**
 * Stock for wards
 */
native War3_WardVisualEffect(wardindex, beamcolor[4]);

/**
 * Stock for displaying the healthlost particle in TF2
 */
stock War3_ShowHealthLostParticle(client)
{
    if(ValidPlayer(client, true) && War3_GetGame() == Game_TF)
    {
        decl Float:fPlayerPos[3];
        GetClientAbsOrigin(client, fPlayerPos);

        fPlayerPos[2] += 55.0;
        
        War3_TF_ParticleToClient(0, GetApparentTeam(client) == TEAM_RED ? "healthlost_red" : "healthlost_blu", fPlayerPos);
    }
}

/**
 * Stock for displaying the healthgained particle in TF2
 */
stock War3_ShowHealthGainedParticle(client)
{
    if(ValidPlayer(client, true) && War3_GetGame() == Game_TF)
    {
        decl Float:fPlayerPos[3];
        GetClientAbsOrigin(client, fPlayerPos);

        fPlayerPos[2] += 55.0;
        
        War3_TF_ParticleToClient(0, GetApparentTeam(client) == TEAM_RED ? "healthgained_red" : "healthgained_blu", fPlayerPos);
    }
}