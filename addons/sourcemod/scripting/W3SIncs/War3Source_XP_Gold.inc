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

/**
 * Gives Fake XP Gold.
 * @param client: Client index
 * @param victim: Victim index
 * @param assiter: Assist index
 * @param W3XPAwardedBy: A list is below: 
 * XPAwardByGeneric,XPAwardByKill,XPAwardByAssist,XPAwardByWin,XPAwardByBomb,XPAwardByHostage,
 * XPAwardByPointCap,XPAwardByPointCapBlock,XPAwardByFlagCap,XPAwardByHealing,XPAwardByReviving,XPAwardByRescueing
 * @param xpamount: xp
 * @param goldamount: gold
 * @param awardstringreason: reason to award.
 * @param extra1:  Currently used for bool on fake headshot when used along with XPAwardByKill and 0 gold and 0 xp
 * @param extra2:  Currently used for bool on fake melee damage when used along with XPAwardByKill and 0 gold and 0 xp
 * if(awardby==XPAwardByKill && gold==0 && xp==0) then it assigns default xp / gold value for Kill, awardstring preset
 * if(awardby==XPAwardByAssist && gold==0 && xp==0) then it assigns default xp / gold value for assist, awardstring preset
 * Anything else you set will be faked and as is.  It will not give xp or gold, but fakes it.
 */
native W3GiveFakeXPGold(client,victim=-1,assiter=-1,W3XPAwardedBy:awardreason=XPAwardByGeneric,xpamount=0,goldamount=0,String:awardstringreason[],bool:extra1=false,bool:extra2=false);
//=======================================================================
//                             FORWARDS
//=======================================================================
