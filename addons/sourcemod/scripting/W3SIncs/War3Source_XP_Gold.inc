/**
 * File: War3Source_XP_Gold.inc
 * Description: Stocks regarding XP and Gold
 * Author(s): War3Source Team  
 */

//=======================================================================
//                             NATIVE / STOCKS
//=======================================================================

/**
 * Gets the kill XP for a player depending on his CURRENT level 
 * @param client: Client index
 * adds extra xp per leveldifference if cvar is configured
 */
native W3GetKillXP(client, leveldifference = 0);
native W3GetReqXP(level); //get required xp for leveling to the level, use (level+1) for xp required for next level

/**
 * Shows the XP and race message in chat
 * @param client: Client index
 * @noreturn
 */
native War3_ShowXP(client);

//nothing happens if you give 0 xp 0 gold
//automatically prints gained or lost xp/gold
native W3GiveXPGold(client,W3XPAwardedBy:awardreason=XPAwardByGeneric,xpamount=0,goldamount=0,String:awardstringreason[]);

//=======================================================================
//                             FORWARDS
//=======================================================================
