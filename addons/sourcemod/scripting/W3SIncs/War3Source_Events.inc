/**
 * File: War3Source_Events.inc
 * Description: Forwards to hook into
 * Author(s): War3Source Team  
 */

// Generic damage event, derived from SDKHooks
forward OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft);

/**
 * Called when a an entity takes damage, requires SDK Hooks until SM natively supports this.
 * @param victim: Victim entity.
 * @param attacker: Attacker entity.
 * @param damage: How much damage is done.
 * @noreturn
 * 
 * order of execution is
 * damageallpre
 * bulletpre (if bullet)
 * damageall
 * bullet  (if bullet)       
 */
//FF triggers this function!!! even though it didnt damage any teammate
//THIS is a theoretical damage given by the engine, if u want real damage dealt use the hurt-event 
//use natives to retrieve inflictor and game damagetype
//becareful when using this, u should only use this to reduce incoming damage. if you want to return damge, only use on bullet (first trigger damage)(below) or check IsBullet
//you may set damage mod percent HERE  
//you may NOT DAMAGE IN HERE  
forward OnW3TakeDmgAllPre(victim,attacker,Float:damage);
/**
 * Same forward as above, but this is only fired if victim and attacker are both valid, the victim is alive,
 * they are different entitys and they are on different teams
 */
forward OnW3EnemyTakeDmgBulletPre(victim, attacker, Float:damage);

//bullet only 
forward OnW3TakeDmgBulletPre(victim,attacker,Float:damage);

//you may NOT set damage mod percent HERE   
//you may DAMAGE in here, however damage will be engine theoretical damage, not actual damage dealt 
forward OnW3TakeDmgAll(victim,attacker,Float:damage);
// BULLET GAME DAMAGE ONLY or Warcraft damage that is allowed to be retriggered (allow more item and skill modifiers), (FILTERED)
//you may NOT set damage mod percent HERE 
//you may DAMAGE in here
forward OnW3TakeDmgBullet(victim,attacker,Float:damage);