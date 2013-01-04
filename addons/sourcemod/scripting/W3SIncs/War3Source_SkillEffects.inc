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
 * Stock for skills that bash
 */
native War3_BashEffect(victim, attacker);