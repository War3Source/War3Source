/**
 * File: War3Source_Damage.inc
 * Description: Stocks regarding Damage
 * Author(s): Glider  
 * 
 */

// The following are bit-flags for War3_DealDamage
// Does not appear useful in any way
#define DMG_GENERIC					0
#define DMG_CRUSH					(1 << 0)
#define DMG_BULLET					(1 << 1)
#define DMG_SLASH					(1 << 2)
#define DMG_BURN					(1 << 3)
#define DMG_VEHICLE					(1 << 4)
#define DMG_FALL					(1 << 5)
#define DMG_BLAST					(1 << 6)
#define DMG_CLUB					(1 << 7)
#define DMG_SHOCK					(1 << 8)
#define DMG_SONIC					(1 << 9)
#define DMG_ENERGYBEAM				(1 << 10)
#define DMG_PREVENT_PHYSICS_FORCE	(1 << 11)
#define DMG_NEVERGIB				(1 << 12)
#define DMG_ALWAYSGIB				(1 << 13)
#define DMG_DROWN					(1 << 14)
#define DMG_TIMEBASED				(DMG_PARALYZE | DMG_NERVEGAS | DMG_POISON | DMG_RADIATION | DMG_DROWNRECOVER | DMG_ACID | DMG_SLOWBURN)
#define DMG_PARALYZE				(1 << 15)
#define DMG_NERVEGAS				(1 << 16)
#define DMG_POISON					(1 << 17)
#define DMG_RADIATION				(1 << 18)
#define DMG_DROWNRECOVER			(1 << 19)
#define DMG_ACID					(1 << 20)
#define DMG_SLOWBURN				(1 << 21)
#define DMG_REMOVENORAGDOLL			(1 << 22)
#define DMG_PHYSGUN					(1 << 23)
#define DMG_PLASMA					(1 << 24)
#define DMG_AIRBOAT					(1 << 25)
#define DMG_DISSOLVE				(1 << 26)
#define DMG_BLAST_SURFACE			(1 << 27)
#define DMG_DIRECT					(1 << 28)
#define DMG_BUCKSHOT				(1 << 29)

//=======================================================================
//                             NATIVE / STOCKS
//=======================================================================

/**
 * Deal damage.
 * @param victim: Victim's client index.
 * @param damage: Damage to be dealt.
 * @param attacker: Optional, attacker client index. Pass 0 for none.
 * @param damage_type: Optional, damage bit-flags. See above for DMG_* defines.
 * @param weaponstr: Optional, weapon name for simulated damage.
 * @param W3DMGOrigin: where the damage came from IE SKILL or ULTIMATE or ITEM  
 * @param WAR3_DMGTYPE: is this damage true (no armor) physical (physical armor/immunity)  or magic (magic armor/immunity)
 * @param respectVictimImmunity: should damage be blocked if victim has that type of immunity, accouts for ORIGIN immunity and DMG type. (SKILL, ULTIMATE, ITEM, |||| MAGIC AND PHYSICAL ) simplifies so that u dont have to check
 * @param countAsFirstDamageRetriggered: should this damage allow to be rehooked (creating a real hurt-event again)? this may cause infinite loops!  Yes to combime with items and other skills only if its not in a damage hook itself. (infinite loop triggering)
 * @param noWarning: Prevent warning print when using DealDamage from a event where it's error prone
 * @return bool: did damage go through, false if player was immune to that damage type or damage was zero or something else failed
 */
native bool:War3_DealDamage(victim,damage,attacker=0,damage_type=DMG_GENERIC,String:weaponNameStr[], War3DamageOrigin:W3DMGORIGIN=W3DMGORIGIN_UNDEFINED , War3DamageType:W3DMGTYPE=W3DMGTYPE_MAGIC , bool:respectVictimImmunity=true , bool:countAsFirstDamageRetriggered=false, bool:noWarning=false);

/*
 * forces the damage to be multiplied by @num
 * shall only be done inside SDKHOOKS damage forward (when damage hasnt been dealt yet) 
 * @noreturn
 */
native War3_DamageModPercent(Float:num);


//get the actual damage dealt from War3_DealDamage, because real damage is different after taking account to magic/physical armor
//u wana call this immediately after War3_DealDamage cuz this is a single global variable. when someone else calls War3_DealDamage it will be changed
native War3_GetWar3DamageDealt();

///is last damage a bullet first triggered damage? works on posthurt and sdkhookdmgall
native W3GetDamageIsBullet();

//return the game damagetype (burn, laser, etc) of the last damage (TakeDmg forward)
native W3GetDamageType();
//get inflictor of the last damage (TakeDmg forward) (ie sentry gun  is a different object than the attacker itself)
native W3GetDamageInflictor();

native W3ForceDamageIsBullet();
// if u do damage within a takedmg, the original damage may be nullified as non bullet, 
//use this function after you have dealt damage inside a takedmg
//so you can allow other isdmgbullet proc

//get the depth of the damage stack, usually 1 or more
native W3GetDamageStack();

stock War3_DealDamageDelayed(victim,attacker,damage,String:classname[32],Float:delay=0.0,bool:showDamage=false,showDamage_skill=0) {
	new Handle:pack;
	CreateDataTimer(delay, _war3source_Timer_DealDamage, pack);
	WritePackCell(pack, victim);
	WritePackCell(pack, attacker);
	WritePackCell(pack, damage);
	WritePackCell(pack, showDamage);
	WritePackCell(pack, showDamage_skill);
	WritePackString(pack, classname);
}

// In csgo killing 2 players in the same frame causes a crash so we use this dirty workaround
public Action:_war3source_Timer_DealDamage(Handle:timer, Handle:pack)
{
	ResetPack(pack); //resolve the package...
	new victim = ReadPackCell(pack);
	if(!ValidPlayer(victim,true)) {
		// immedialety exit!
		return Plugin_Stop;
	}
	//new attacker = ReadPackCell(pack);
	//new damage = ReadPackCell(pack);
	//new bool:showDamage = bool:ReadPackCell(pack);
	//new showDamage_skill = ReadPackCell(pack);
	decl String:classname[32];
	ReadPackString(pack,classname,sizeof(classname));
	
	// Glider: I'm commenting this out until I figured out if the notification
	// 		   engine or the DealDamage methods should be held responsible for this
	
	//if(War3_DealDamage(victim,damage,attacker,DMG_BULLET,classname) && showDamage) {
	//	W3PrintSkillDmgConsole(victim,attacker,War3_GetWar3DamageDealt(),showDamage_skill);
	//}
	return Plugin_Stop;
}

//=======================================================================
//                             FORWARDS
//=======================================================================

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
//bullet only 
forward OnW3TakeDmgBulletPre(victim,attacker,Float:damage);

//you may NOT set damage mod percent HERE   
//you may DAMAGE in here, however damage will be engine theoretical damage, not actual damage dealt 
forward OnW3TakeDmgAll(victim,attacker,Float:damage);
// BULLET GAME DAMAGE ONLY or Warcraft damage that is allowed to be retriggered (allow more item and skill modifiers), (FILTERED)
//you may NOT set damage mod percent HERE 
//you may DAMAGE in here
forward OnW3TakeDmgBullet(victim,attacker,Float:damage);