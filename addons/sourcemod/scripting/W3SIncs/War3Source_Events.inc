/**
 * File: War3Source_Events.inc
 * Description: Forwards to hook into
 * Author(s): War3Source Team  
 */

// Generic damage event, derived from SDKHooks
forward OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft);