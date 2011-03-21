/**
 * File: War3Source_Interface.inc
 * Description: The file to be included for creating races and whatnot.
 * Author(s): Anthony Iacono  
 * 
 * 
 * LISTS NATIVES AND FORWARDS, BUT NOT ACTUALLY DEFINES THE CODE
 */

#include <sdktools>
#include "W3SIncs/colors"
#include "W3SIncs/constants"


//test 
//native OurTestNative(Float:f,

//sh include is at the end of this file

new String:interfaceVersion[]="1.1.8"; ///this makes sure the race is compatable with the compiled version of war3source.smx


stock dummy; //variable for dummies!
stock String:dummystr[32];



//variables forwarded to every w3 plugin
new W3ForwarededVars[W3ForwardedVarsEnum];
public W3SetForwarededVar(index,value){
	W3ForwarededVars[index]=value;
}
//use this when W3 native hasn't been bound yet, however dont call this before it has been determined
stock W3(){
	return W3ForwarededVars[W3Mode];
}
//use this when SH native hasn't been bound yet,  however dont call this before it has been determined
stock SH(){
	return W3ForwarededVars[SHMode];
}
// dont call this before it has been determined
stock ValveGameEnum:War3_GetGame(){
	return ValveGameEnum:W3ForwarededVars[ValveGame];
}



forward War3InterfaceExec();
public War3InterfaceExec(){ //this runs once, does common tasks
	LoadTranslations("w3s._common.phrases");
}


///call to initiate your forwards, done right after game W3 or SH is determiend and the game CS/TF
//at this point natives are not bound! you must use W3Early and SHEarly W3GetGameEarly...etc
forward bool:InitNativesForwards();

public zzOnPluginEnd() //public OnMapEnd()
{	
	new String:name[64];
	new Handle:plugin=GetMyHandle();
	GetPluginFilename(plugin, name, sizeof(name)); 
	PrintToServer("[War3Source] OnPluginEnd %s",name);
}



/*
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
*/ 


native W3GetW3Version(String:retstr[],maxlen);//str
native W3GetW3Revision();//int
native W3GetStatsVersion();//int
native W3Socket(String:url[],Function:callback);
native W3Socket2(String:url[],String:postdata[],Function:callback);
native W3DropWeapon(client,weaponent);
/**
 * Checks if we are in the freeze time. Certain games support this, like CS.
 * @return True if so, false if not.
 */
native bool:War3_InFreezeTime();    



//creates a new race, returns the race id
native War3_CreateNewRace(String:name[],String:shortname[]);

//adds a skill or a ultimate
native War3_AddRaceSkill(raceid,String:tskillorultname[],String:tskillorultdescription[],bool:isult,maxskilllevel=DEF_MAX_SKILL_LEVEL);


///translated
//creates a new race, returns the race id
native War3_CreateNewRaceT(String:shortname[]);

///translated
//adds a skill or a ultimate
//additional parameters replaces #1# #2# ... in the translation string (max 5)
native War3_AddRaceSkillT(raceid,String:SkillNameIdentifier[],bool:isult,maxskilllevel=DEF_MAX_SKILL_LEVEL,any:...);




//ends race creation!!! MUST CALL THIS!!!
native War3_CreateRaceEnd(raceid);



native War3_GetRaceName(raceid,String:retstr[],maxlen);
native War3_GetRaceShortname(raceid,String:retstr[],maxlen);

native W3GetRaceString(raceid,RaceString:property,String:retstr[],maxlen);
native W3GetRaceSkillString(raceid,skillnum,SkillString:property,String:retstr[],maxlen);

native War3_GetRacesLoaded();
native W3GetRaceMaxLevel(race);

native War3_IsSkillUltimate(raceid,skillnum);
native War3_GetRaceSkillCount(raceid);
native W3GetRaceSkillName(raceid,skillindex,String:retstr[],maxlen);
native W3GetRaceSkillDesc(raceid,skillindex,String:retstr[],maxlen);
native W3GetRaceSkillMaxLevel(raceid,skillnum);
native W3GetRaceOrder(raceid);
native bool:W3RaceHasFlag(raceid,String:flag[]);

//pass array of MAXRACES, returns number of races in the array. starts at 0
///ordered properly
native W3GetRaceList(racelist[]);

native War3_GetRaceIDByShortname(String:raceshortname[]);

native W3GetRaceAccessFlagStr(raceid,String:ret[],maxlen);
native W3GetRaceItemRestrictionsStr(raceid,String:ret[],maxlen);
native W3GetRaceMaxLimitTeam(raceid,team);
native W3GetRaceMaxLimitTeamCvar(raceid,team); //returns the internal cvar pointer
native W3GetRaceMinLevelRequired(raceid);
native W3IsRaceTranslated(raceid);


///retrieves specified values from the main war3 plugin, see W3Var enum in constants.inc, only those values are allowed
//this mostly used for accessing a variable without creating a special native just for it
//this returns any:, you should tag it if return value is not suppose to be normal integer. like Float:W3GetVar( or Handle:W3GetVar(
//most are temporary variables and this function should be called immidiately in the right functions
//examples W3GetVar(OldRace)   W3GetVar(DeathRace)
native any:W3GetVar(W3Var:variabletoretrieve);
native any:W3SetVar(W3Var:variabletoretrieve,any:value);



/**
 * Registers a shop item with the War3Source plugin
 * @param name: The name of the item. 
 * @param shortname: the shortname of the item, must be unique
 * @param desc: The description of the item. 
 * @param cost: The cost of the item 
 * @return The return value will be the item index or -1 if there was a problem.
 */		 
native War3_CreateShopItem(String:name[],String:shortname[],String:desc[],costgold,costmoney);
//translated
native War3_CreateShopItemT(String:shortname[],costgold,costmoney);


native War3_SetItemProperty(itemid,W3ItemProp:ITEM_PROPERTY,value);
native War3_GetItemProperty(itemid,W3ItemProp:ITEM_PROPERTY);

//returns -1 if not found
//remember itemid that is valid is more than 0
native War3_GetItemIdByShortname(String:itemshortname[]) ;


native W3GetItemName(itemid,String:ret[],maxlen);
native W3GetItemShortname(itemid,String:ret[],maxlen);
native W3GetItemDescription(itemid,String:ret[],maxlen);

native W3GetItemCost(itemid,bool:csmoney);
native W3GetItemOrder(itemid);
native W3ItemHasFlag(itemid,String:flagsearch[]);
native W3GetItemCatagory(itemid,String:retcatagorystr[],maxlen);


native bool:W3IsItemDisabledGlobal(itemid);
native bool:W3IsItemDisabledForRace(race,itemid);
/**
 * Registers a help command with the War3Source plugin for war3help
 * @param name: The name of the command. (max 64)
 * @param desc: The description of the command. (max 256) 
 * @noreturn
 */
native War3_CreateHelpCommand(String:name[],String:desc[]);



native W3GetLevelsSpent(client,race);
native W3ClearSkillLevels(client,race);


/**
 * Gets the kill XP for a player, useful for simulating an explosion or anything else.
 * @param client: Client index
 * @param race: The race ID returned from War3_CreateRace
 * @return Will be kill XP, or -1 for failed
 */
native W3GetKillXP(level);
native W3GetReqXP(level); //get required xp for leveling to the level, use (level+1) for xp required for next level


/**
 * Shows the XP and race message in chat
 * @param client: Client index
 * @noreturn
 */
native War3_ShowXP(client);

//max gold a player can have (cvar read)
native W3GetMaxGold();


/**
 * Gets if the player owns a specific item.
 * @param client: Client index
 * @param item: The item ID returned from War3_CreateShopItem
 * @return The return value will be 1 if they own it, if 0 they don't, if -1 then it failed.
 */
native War3_GetOwnsItem(client,item);




/**
 * Sets if the player owns a specific item.
 * @param client: Client index
 * @param item: The item ID returned from War3_CreateShopItem
 * @param owns: 1 if you want them to own it, 0 if you want them not to own it 
 * @noreturn
 * 
 *	ITEM IS NOT LOST AUTOMATICALLY ON DEATH  
 */
native War3_SetOwnsItem(client,item,bool:ownsitem);



/**
 * Finds the best target within a player's view cone
 * Can be limited by max distance
 * function perfers closer target over a target that has less degrees 
 * @param client: Client index
 * @param max_distance: Optional, set to 0 to allow unlimited distance
 * @param include_friendlys: Optional, should we look for friendlys too?
 * @param cone_angle: Optional, view cone angle, SDK default is 23.0 degrees.
 * @param FilterFunction: Callback filter function, return false in this function to ignore entity.     
 */
native War3_GetTargetInViewCone(client,Float:max_distance=0.0,bool:include_friendlys=false,Float:cone_angle=23.0,Function:FilterFunction=INVALID_FUNCTION);
 
///traces from client to target and see if they are in view of each other (Line of Signt - LOS)
native W3LOS(client,target);

// The following are bit-flags for War3_DealDamage
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
 * @return bool: did damage go through, false if player was immune to that damage type
 */
native bool:War3_DealDamage(victim,damage,attacker=0,damage_type=DMG_GENERIC,String:weaponNameStr[],    War3DamageOrigin:W3DMGORIGIN=W3DMGORIGIN_UNDEFINED  ,   War3DamageType:W3DMGTYPE=W3DMGTYPE_MAGIC  ,  bool:respectVictimImmunity=true   ,   bool:countAsFirstDamageRetriggered=false);       

//get the actual damage dealt from War3_DealDamage, because real damage is different after taking account to magic/physical armor
//u wana call this immediately after War3_DealDamage cuz this is a single global variable. when someone else calls War3_DealDamage it will be changed
native War3_GetWar3DamageDealt();



/**
 * Flashes a player's screen a certain color for a duration.
 * @param client: Client's index.
 * @param color[4]: RGBA value of the color, see above for presets.
 * @param duration: Length of flash, optional.
 * @param flags: Flags of Fade user message, optional.
 * @noreturn
 */

native W3FlashScreen(client,color[4],Float:holdduration=0.1,Float:fadeduration=0.2,flags=FFADE_IN);

///is last damage a bullet first triggered damage? works on posthurt and dmgall
native W3GetDamageIsBullet();

native W3ForceDamageIsBullet();
// if u do damage within a takedmg, the original damage may be nullified as non bullet, 
//use this function after you have dealt damage inside a takedmg
//so you can allow other isdmgbullet proc

/**
 * Shakes a player's screen at a magnitude and noise for a duration.
 * @param client: Client's index.
 * @param duration: Optional, how long to shake.
 * @param magnitude: Optional magnitude value.
 * @param noise: Optional noise value.
 * @noreturn
 */
native War3_ShakeScreen(client,Float:duration=1.0,Float:magnitude=40.0,Float:noise=30.0);     


stock bool:ValidPlayer(client,bool:check_alive=false){
	if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		if(check_alive && !IsPlayerAlive(client))
		{
			return false;
		}
		return true;
	}
	return false;
}

 
/**
 * Respawns a dead player.
 * @param client: Client's index.
 * @param ignore_dead_check: Optional, ignore dead checking. 
 * @noreturn
 */
native War3_SpawnPlayer(client,bool:ignore_dead_check=false);


/**
 * Stock, checks if a player is near any entity in a datapack of entities, again by name.
 * @param client: Client's index.
 * @param hEnts: Datapack of entity names.
 * @param pack_size: Size of datapack.
 * @param distance: Optional, how far is "near."
 * @return ADT array of results, otherwise INVALID_HANDLE.
 * DO NOT FORGET TO CloseHandle() the results if they don't equal INVALID_HANDLE!!!  
 */
stock Handle:War3_NearEntsByName(client,Handle:hEnts,pack_size,Float:distance=150.0)
{
	new Handle:hResults=CreateArray();
	ResetPack(hEnts);
	for(new x=0;x<pack_size;x++)
	{
		new String:ent_name[128];
		ReadPackString(hEnts,ent_name,sizeof(ent_name));
		new Handle:result_found=War3_NearEntByName(client,ent_name,distance);
		if(result_found!=INVALID_HANDLE)
		{
			new size=GetArraySize(result_found);
			for(new y=0;y<size;y++)
			{
				PushArrayCell(hResults,GetArrayCell(result_found,y));
			}
			CloseHandle(result_found);
		}
	}
	if(GetArraySize(hResults)>0)
		return hResults;
	else
	{
		CloseHandle(hResults);
		return INVALID_HANDLE;
	}
}

stock Handle:War3_NearEntByName(client,String:ent_name[],Float:distance)
{
	if(distance<0.0)
		return INVALID_HANDLE; // wtf? lol
	if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new Handle:hResults=CreateArray();
		new Float:curPos[3];
		GetClientAbsOrigin(client,curPos);
		new ent=0;
		while((ent=FindEntityByClassname(ent,ent_name))>0)
		{
			if(!IsValidEdict(ent)) continue;
			new Float:entPos[3];
			GetEntPropVector(ent,Prop_Send,"m_vecOrigin",entPos);
			new Float:dist=GetVectorDistance(curPos,entPos);
			if(dist<=distance)
			{
				PushArrayCell(hResults,ent);
			}
		}
		if(GetArraySize(hResults)>0)
		{
			return hResults;
		}
		else
		{
			CloseHandle(hResults);
		}
	}
	return INVALID_HANDLE;
}
/**
 * Stock, checks if a player is near an engineer building.
 * @param client: Client's index.
 * @param distance: Optional, how far is "near."
 * @return ADT array of results, otherwise INVALID_HANDLE
 * DO NOT FORGET TO CloseHandle() the results if they don't equal INVALID_HANDLE!!! 
 */
stock Handle:War3_NearBuilding(client,Float:distance=150.0)
{
	if(War3_GetGame()==Game_TF)
	{
		new Handle:hEnts=CreateDataPack();
		WritePackString(hEnts,"obj_dispenser");
		WritePackString(hEnts,"obj_sentrygun");
		WritePackString(hEnts,"obj_teleporter_entrance");
		WritePackString(hEnts,"obj_teleporter_exit");
		new Handle:result=War3_NearEntsByName(client,hEnts,4,distance);
		CloseHandle(hEnts);
		return result;
	}
	return INVALID_HANDLE;
}      
 
// THE FOLLOWING NATIVES RETRIEVE DATA CACHED ONGAMEFRAME!
// THE FUNCTIONS NAMED War3_CachedDead* ARE VALUES SET WHEN THE PLAYER DIES
// THESE ARE ADVANCED FUNCTIONS, CHANCES ARE IF U DON'T KNOW WHAT THEY MEAN
// YOU PROBABLY DON'T HAVE TO USE THEM

/**
 * Get last cached player eye angle.
 * @param client: Client index
 * @param angle[3]: Output array
 * @noreturn
 */    
native War3_CachedAngle(client,Float:angle[3]);

/**
 * Get last cached player position.
 * @param client: Client index
 * @param position[3]: Output array
 * @noreturn
 */
native War3_CachedPosition(client,Float:position[3]);

/**
 * Get last cached player ducking state.
 * @param client: Client index
 * @return True or false.
 */
native bool:War3_CachedDucking(client);

/**
 * Get cached weapon entity based on iterator.
 * This function is usually called from a loop. 
 * @param client: Client index
 * @param weapon_iterator: Number from 0-9. 
 * @return Weapon entity, 0 if none.
 */
native War3_CachedWeapon(client,weapon_iterator);

/**
 * Get cached weapon entity "clip1" based on iterator.
 * This function is usually called from a loop. 
 * @param client: Client index
 * @param weapon_iterator: Number from 0-9. 
 * @return Value of clip1.
 */
native War3_CachedClip1(client,weapon_iterator);

/**
 * Get cached ammo of a player with a specific weapon ID.
 * This function is usually called from a loop. 
 * @param client: Client index
 * @param game_weapon_id: Game specific weapon identifier, this is constant for each weapon. 
 * @return Value of iAmmo.
 */
native War3_CachedAmmo(client,game_weapon_id);

/**
 * Get cached weapon entity "clip1" of iterator, only changes when a player dies.
 * This function is usually called from a loop. 
 * @param client: Client index
 * @param weapon_iterator: Number from 0-9. 
 * @return Value of clip1 from last death.
 */
native War3_CachedDeadClip1(client,weapon_iterator);

/**
 * Get cached ammo of a player with a specific weapon ID, only changes when a player dies.
 * This function is usually called from a loop. 
 * @param client: Client index
 * @param game_weapon_id: Game specific weapon identifier, this is constant for each weapon. 
 * @return Value of iAmmo from last death.
 */
native War3_CachedDeadAmmo(client,game_weapon_id);

/**
 * Get cached weapon name of iterator, only changes when a player dies.
 * This function is usually called from a loop, sets output_buffer to "" if no weapon at iterator. 
 * @param client: Client index
 * @param weapon_iterator: Number from 0-9.
 * @param output_buffer: Output buffer
 * @param output_size: Size of output buffer.   
 * @noreturn
 */ 
native War3_CachedDeadWeaponName(client,weapon_iterator,String:output_buffer[],output_size);



/**
 * Is player ubered (TF2)
 * @param client:
 * @return: true false
 */  
   
native bool:War3_IsUbered(client);




/**
 * Is player carrying intellegence
 * @param client:
 * @return: true false
 */  
native bool:War3_HasFlag(client);





/**
 * Is player cloaked
 * @param client:
 * @return: true false
 */  
   
native bool:War3_IsCloaked(client);

/*
 * forces the damage to be multiplied by @num
 * shall only be done inside SDKHOOKS damage forward (when damage hasnt been dealt yet) 
 * @noreturn
 */      
native War3_DamageModPercent(Float:num);  



native War3_TF_ParticleToClient(clienttoshowto,String:particlestr[],Float:pos[3]);  


/**
 * heals with the limit of (warcraft ) max hp
 * @noreturn
 */  
native War3_HealToMaxHP(client,addhp);  

/**
 * heals to max hp * 1.5 buff in tf2
 * @noreturn
 */  
native War3_HealToBuffHP(client,addhp);  

/* direcly decreases the player's hp by X amount
//WILL NOT GO BELOW 1 (cs glitch)
*/
native War3_DecreaseHP(client,decrease);

//LO AND BEHOLD THE COOLDOWN MANAGER, YOUR LIFE SIMPLIFIED!!!
//we essentially move the cooldown system out of our races into our main plugin
/**
 * cooldown manager
 * basically self explainatory parameters, creates a cooldown for a skill (term skill used here is generic for skill/ability/ultimate)
 * printMsgOnExpireByTime prints message to client (if alive and same race) when this skill expires by time (will not print when expired by spawn or death or force reset)
 * CooldownPrintMsgName[] is the name of the skill that will be printed: ie Voodoo is ready. You pass "Voodoo".  
 * If left empty, it will say "Ability" for skillnum 0-2 and "Ultimate"
 * This string will also be used in War3_PrintSkillIsNotReady and is the only way to set it. you should never call  War3_PrintSkillIsNotReady before calling this manager
 * If there is a skill that has cooldown but not counted as an ability, you should not have it print on expiration
 * 
 * when a cooldown expires (by time, by death, by spawn, by force reset), it will forward to OnCooldownExpired(....) forward, use if u need to
 * @noreturn
 */  
 //REMOVE uneeded arguments
native War3_CooldownMGR(client,Float:cooldownTime,raceid,skillNum,bool:resetOnSpawn=true,bool:printMsgOnExpireByTime=true);  

//tells the cooldown manager to create a predefined cooldown time when player spawns. 
//cooldown is created regardless of resetOnSpawn in War3_CooldownMGR(...) calls
//cooldown is created regardless of race of the client
//only prints if client is that race
//set this when u register your skills
native W3SkillCooldownOnSpawn(raceid,skillnum,Float:cooldownTime,bool:printmsgonexpire=true);
/**
 * how much time is left on this particular cooldown?
 * returns an int (rounted up from the float)
 */  
native War3_CooldownRemaining(client,raceid,skillNum);  


/**
 * basically make this cooldown expire, expiring is not considered "by time"
 */  
native War3_CooldownReset(client,raceid,skillNum);  


/**
 * is this skill NOT in COOLDOWN? YOU NEED TO CHECK IF CLIENT HAS LEVELED THIS SKILL FIRST, THIS IS ONLY COOLDOWN RELATED
 * you would only do this if this skill has a cooldown and u called War3_CooldownMGR
 * printTextIfNotReady=true will print a not ready message
 */  
native bool:War3_SkillNotInCooldown(client,raceid,skillNum,bool:printTextIfNotReady=false);  


/**
 * prints Ability/Ultimate Is Not Ready or something
 * the String can replace "Ultimate", its copied from the creation of CooldownMGR
 */  
native War3_PrintSkillIsNotReady(client,raceid,skillNum);




/*
* set a buff, identified as coming from a race
* value can be int float bool, but has to be consistant, agreed upon by war3 main plugin
* 
*/
native War3_SetBuff(client,W3Buff:buffindex,raceid,any:value);

/*
* set a buff, identified as coming from a item
* 
*/
native War3_SetBuffItem(client,W3Buff:buffindex,itemid,any:value);

native W3ApplyBuffSimple(client,W3Buff:buffindex,raceid,any:initialbuffvalue,Float:duration);

///RESETS a particular buff from your race on this client
native W3ResetBuffRace(client,W3Buff:buffindex,raceid);

///RESETS ALL BUFFS PERTAIINGIN TO THIS CLIENT AND RACE, basically fully getting rid if all buffs attatched to this player from your race
native W3ResetAllBuffRace(client,raceid);

///registers a tracker and returns an index that you must keep. usually do this for each each player or once if global
// Register once on plugin start please!
//returns -1 if tracker is full. LogErrors on Full
native War3_RegisterDelayTracker();

//create a delay
native War3_TrackDelay(trackerIndex,Float:delay);

//did the delay expire?
native War3_TrackDelayExpired(trackerIndex);

//get location of where the player is aiming (trace to the end of your crosshair)
native War3_GetAimEndPoint(client,Float:endpos[3]);

//get location of where the player is aiming (trace to the end of your crosshair) limited by distance
native War3_GetAimTraceMaxLen(client,Float:endpos[3],Float:maxdistance);


//simple weapon restriction:    pass "weapon_knife,weapon_hegrenade" to only allow these weapons, separated by comma. 
//pass "" to allow all weapons again
//c4 etc is automatically allowed
//to override other restrictions, use a higher priority
//use 1 priorty for ur base race restrictions, USE AT OWN RISK!
native War3_WeaponRestrictTo(client,raceid,String:onlyallowedweaponsnames[],priority=1);


//set player shell glowish color (blood mage, shadow hunter), highest override priority takes effect, all integers
stock W3SetPlayerColor(client,raceid,r,g,b,a=255,overridepriority=GLOW_DEFAULT){
	War3_SetBuff(client,iGlowRed,raceid,r);
	War3_SetBuff(client,iGlowGreen,raceid,g);
	War3_SetBuff(client,iGlowBlue,raceid,b);
	War3_SetBuff(client,iGlowAlpha,raceid,a);
	War3_SetBuff(client,iGlowPriority,raceid,overridepriority);
	War3_SetBuff(client,fGlowSetTime,raceid,GetGameTime());
}
stock W3ResetPlayerColor(client,raceid){
	W3SetPlayerColor(client,raceid,255,255,255,_,0);
}

native Float:W3GetPhysicalArmorMulti(client); //damage multipler for client by accounting for physical armor (warcraft physical armor, not cs armor)
native Float:W3GetMagicArmorMulti(client); //damage multipler for client by accounting for magic armor
native W3GetItemsLoaded(); //how many items are loaded?
native W3GetCurrentWeaponEnt(client); //get the entity of the current (active) weapon


native any:W3GetBuff(client,W3Buff:buffindex,RaceIDorItemID,IPassedItemID=false);
native bool:W3GetBuffHasTrue(client,W3Buff:buffindex); //does this buff have one true (activated?)
native Float:W3GetBuffStackedFloat(client,W3Buff:buffindex); //get buff stacked value of an buff, use appropriately
native W3GetBuffSumFloat(client,W3Buff:buffindex);
native Float:W3GetBuffMinFloat(client,W3Buff:buffindex);
native Float:W3GetBuffMaxFloat(client,W3Buff:buffindex);
native W3GetBuffMinInt(client,W3Buff:buffindex);

native W3GetMinUltLevel();

//force all supported war3 plugins into failed mode (pause plugin)
native War3Failed(String:reason[]);

//return the game damagetype (burn, laser, etc) of the last damage (TakeDmg forward)
native W3GetDamageType();
//get inflictor of the last damage (TakeDmg forward) (ie sentry gun  is a different object than the attacker itself)
native W3GetDamageInflictor();


/**
 * Use this for getting a chance modifier in OnWar3TakeDamage!!
 * This is a cvar based value used for lowering chance of skill activation when a weapon such as flamethrower inflicts damage many times over a period of time.
 * If you are making a skill that has a high chance, example 1 in 10, it is advised to change it to something like 10 in 100 if using GetRandomInt, however if you are using GetRandomFloat with the chance modifier*original chance then it shouldn't be an issue. 
 * @param attacker: Attacker's client index.
 * @param inflictor: Inflictor entity index. (ie sentry gun)
 * @param damagetype: Type of damage.
 * @return Float modifier, 1.0 for 100% chance otherwise percentage between 0.0 and 1.0
 */  

//helper, directly uses last inflictor and damagetype
native Float:W3ChanceModifier(attacker);


//for activatable skills only
stock bool:SkillAvailable(client,yourRaceID,skillnumber,bool:printCooldown=true,bool:checksilenced=true,bool:printSilenced=true){	
	return War3_SkillNotInCooldown(client,yourRaceID,skillnumber,printCooldown)&& (!checksilenced||!Silenced(client,printSilenced));
}

stock bool:Stunned(client){
	return W3GetBuffHasTrue(client,bStunned);
}
stock bool:Silenced(client,printSilenced=true){
	new bool:silenced=(W3GetBuffHasTrue(client,bSilenced)||Stunned(client));
	if(silenced&&printSilenced){
		if(IsPlayerAlive(client)){
			if(Stunned(client))
			{
				PrintHintText(client,"%T","You are stunned",client);
			}
			else
			{
				PrintHintText(client,"%T","You are silenced",client);
			}
		}
		if(Stunned(client))
		{
			PrintToConsole(client,"%T","You are stunned, cannot activate skill",client);
		}
		else
		{
			PrintToConsole(client,"%T","You are silenced, cannot activate skill",client);
		}
	}
	return silenced;
}
stock bool:Hexed(client,printmsg=true){
	new bool:status=(W3GetBuffHasTrue(client,bHexed)||W3GetBuffHasTrue(client,bStunned));
	if(status&&printmsg){
		
		if(Stunned(client))
		{
			PrintToConsole(client,"%T","You are stunned, cannot proc skill",client);
		}
		else
		{
			PrintToConsole(client,"%T","You are hexed, cannot proc skill",client);
		}
	}
	return status;
}
stock bool:Perplexed(client,printmsg=true){
	new bool:perplexed=(W3GetBuffHasTrue(client,bPerplexed)||W3GetBuffHasTrue(client,bStunned));
	if(perplexed&&printmsg){
		
		if(Stunned(client))
		{
			PrintToConsole(client,"%T","You are stunned, cannot activate item",client);
		}
		else
		{
			PrintToConsole(client,"%T","You are perplexed, cannot activate item",client);
		}
	}
	return perplexed;
}

native War3_GetRace(client);
native War3_SetRace(client,race);

native War3_SetLevel(client,race,level);
native War3_GetLevel(client,race);

native W3GetTotalLevels(client); //sum of each level in each race

native W3GetLevelBank(client);
native W3SetLevelBank(client,newlevelbank);

native War3_SetXP(client,race,newxp);
native War3_GetXP(client,race);

native War3_SetSkillLevel(client,race,skill,newlevel);
native War3_GetSkillLevel(client,race,skill);

native W3SetPlayerProp(client,W3PlayerProp:property,any:value);
native any:W3GetPlayerProp(client,W3PlayerProp:property);

native W3GiveXPGold(client,race,xpamount=0,goldamount=0,String:awardstringreason[]);



//TKV = trie key value , a abstract data storage, emulates cvars for war3
///Creates internal war3 cvars. returns a id to your cvar, store it!
native W3CreateCvar(String:cvarstr[],String:cvarvalue[],String:cvardesc[]);
native W3GetCvar(cvarid,String:returnstr[],maxlen);
native W3SetCvar(cvarid,String:cvarvalue[]);
native W3FindCvar(String:cvar[]);
native Handle:W3CvarList(); //returns a handle arraylist of cvar list (no values, names only
native W3GetCvarByString(String:cvarstr[],String:returnstr[],maxlen);
native W3GetCvarActualString(cvarid,String:returnstr[],maxlen); //get actual cvar name: undead_blah

stock W3CreateCvarInt(String:cvarstr[],intval,String:cvardesc[]){
	decl String:str[1024];
	Format(str,sizeof(str),"%d",intval);
	return W3CreateCvar(cvarstr,str,cvardesc);
}
stock W3GetCvarInt(cvarid){
	decl String:ret[1024];
	W3GetCvar(cvarid,ret,sizeof(ret));
	//PrintToChatAll("%s %d",ret,StringToInt(ret));
	return StringToInt(ret);
}
stock W3SetCvarInt(cvarid,intval){
	decl String:str[1024];
	Format(str,sizeof(str),"%d",intval);
	return W3SetCvar(cvarid,str);
}
stock W3CreateCvarFloat(String:cvarstr[],intval,String:cvardesc[]){
	decl String:str[1024];
	Format(str,sizeof(str),"%f",intval);
	W3CreateCvar(cvarstr,str,cvardesc);
}
stock W3GetCvarFloat(cvarid){
	decl String:ret[1024];
	W3GetCvar(cvarid,ret,sizeof(ret));
	return StringToFloat(ret);
}
stock W3SetCvarFloat(cvarid,intval){
	decl String:str[1024];
	Format(str,sizeof(str),"%f",intval);
	W3SetCvar(cvarid,str);
}


stock War3_SetMaxHP(client,maxhp){
	W3SetPlayerProp(client,iMaxHP,maxhp);
}
stock War3_GetMaxHP(client){
	return W3GetPlayerProp(client,iMaxHP);
}
stock bool:W3IsPlayerXPLoaded(client){
	return W3GetPlayerProp(client,xpLoaded);
}
stock W3GetPendingRace(client){
	return W3GetPlayerProp(client,PendingRace);
}
stock W3SetPendingRace(client,pendrace){
	W3SetPlayerProp(client,PendingRace,pendrace);
}
stock War3_SetGold(client,newgold){
	W3SetPlayerProp(client,PlayerGold,newgold);
}
stock War3_GetGold(client){
	return W3GetPlayerProp(client,PlayerGold);
}

native W3IsDeveloper(client);

///returns the handle to the database which your xp is saved, so you dont have to connect again for your addon scipts
native Handle:W3GetDBHandle();
native bool:W3SaveEnabled();
native W3SaveXP(client,race);

native W3Log(const String:fmt[],any:...);
native W3LogError(const String:fmt[],any:...);
native W3LogNotError(const String:fmt[],any:...);
/**
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS    
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS    
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS    
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS    
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS    
*/











forward War3FailedSignal(String:str[]);
public War3FailedSignal(String:str[]){
	W3LogError(str);
	SetFailState(str);
}

forward CheckWar3Compatability(String:w3mainInterfVersion[]);
public CheckWar3Compatability(String:w3mainInterfVersion[]){
	if(!StrEqual(interfaceVersion,w3mainInterfVersion)){
		W3LogError("FATAL ERROR, PLUGIN COMPILED INTERFACE VERSION (%s) IS DIFFERENT FROM WAR3SOURCE BASE VERSION (%s). Please Compile With Latest Version!!!",interfaceVersion,w3mainInterfVersion);
		SetFailState("FATAL ERROR, PLUGIN COMPILED INTERFACE VERSION (%s) IS DIFFERENT FROM WAR3SOURCE BASE VERSION (%s). Please Compile With Latest Version!!!",interfaceVersion,w3mainInterfVersion);
	}
}


/**
 * Called when the plugin is ready.
 * this is called many times, increasing num each time 0.0-float(MAXRACES)*10 in 1 increments
 * USED FOR OFFICIAL PLUGINS ONLY
 */
forward OnWar3LoadRaceOrItemOrdered(num);

/**
 * Called when the plugin is ready.
 * this is called many times, increasing num each time 0.0-float(MAXRACES)*10 in 1 increments
 * this is called after all default races have been loaded (OnWar3LoadRaceOrItemOrdered finished)
 */
forward OnWar3LoadRaceOrItemOrdered2(num);

/**
 * Called when the plugin is ready. (after ordered)
 */
forward OnWar3PluginReady();

/**
 * Gets called when after PutInServer, xp retrievcal has started, initial variables may have been set
 * @param client: The client's index.
 */
forward OnWar3PlayerAuthed(client);

/**
 * Gets called when someone changes their race.
 * @param client: The client's index.
 * @param newrace: The player's new race.
 */
forward OnRaceSelected(client,newrace);

/**
 * Gets called when the +ultimate or -ultimate command is called, IT ISNT ALWAYS FOR YOUR RACE, YOU NEED TO CHECK!!!
 * @param client: The client's index.
 * @param race: The race for which it was called.
 * @param pressed: If true, +ultimate, false, -ultimate.
 */
forward OnUltimateCommand(client,race,bool:pressed);

/**
 * Gets called when the +ability# or -ability# command is called.
 * If its +ability or -ability (without a number), 0 is passed to ability. 
 * Isn't always for you, check War3_GetRace(client)==yourRace 
 * @param client: The client's index.
 * @param ability: The ability number.
 * @param pressed: If true, +ability#, false, -ability#.
 */
forward OnAbilityCommand(client,ability,bool:pressed);

/**
 * Gets called when a player purchases an item.
 * @param client: The client's index.
 * @param item: The item that was purchased.
 * PLAYER ALREADY HAS OWNERSHIP BY THIS POINT  
 */
forward OnItemPurchase(client,item);


/**
 * Gets called when a player loses an item. (after death (ownership to false) or traded it back..)
 * @param client: The client's index.
 * @param item: The item that was purchased.
 * PLAYER ALREADY HAS LOST OWNERSHIP BY THIS POINT   
 */
forward OnItemLost(client,item);


/**
 * Gets called when a skill level is changed.
 */
forward OnSkillLevelChanged(client,race,skill,newskilllevel);
 
/**
 * Called when a an entity takes damage, requires SDK Hooks until SM natively supports this.
 * @param victim: Victim entity.
 * @param attacker: Attacker entity.
 * @param damage: How much damage is done.
 * @noreturn
 */ 
//FF triggers this function!!! even though it didnt damage any teammate
//THIS is a theoretical damage given by the engine, if u want real damage dealt use the hurt-event     
forward OnW3TakeDmgAll(victim,attacker,Float:damage);  
//use natives to retrieve inflictor and game damagetype
//becareful when using this, u should only use this to reduce incoming damage. if you want to return damge, only use on bullet (first trigger damage)(below) or check IsBullet

// BULLET GAME DAMAGE ONLY or Warcraft damage that is allowed to be retriggered (allow more item and skill modifiers), (FILTERED)
forward OnW3TakeDmgBullet(victim,attacker,Float:damage);  








/**
 * Called when a cooldown expires (timed, death, or spawn)
 */
forward OnCooldownExpired(client,raceID,skillNum,bool:expiredByTime);

///general events, see W3EVENT enum in constants
///client may not always matter
forward OnWar3Event(W3EVENT:event,client);

native W3CreateEvent(W3EVENT:event,client);

stock ShowChangeRaceMenu(client){
	W3CreateEvent(DoShowChangeRaceMenu,client);
}

stock W3DoLevelCheck(client){
	W3CreateEvent(DoLevelCheck,client);
}


//when player spawns, fires only in war3 mode
forward OnWar3EventSpawn(client);

//when player dies, fires only in war3 mode
forward OnWar3EventDeath(victim,attacker);

//very generic damage event
forward OnWar3EventPostHurt(victim,attacker,dmgamount);







/*
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
*/


#define MAX_MESSAGE_LENGTH 250

/** 
 * Prints a message in the chat area with [War3Source] pre-appended.
 * Support color tags: {default}, {green}, {lightgreen}, {red}, {blue}, {olive}.
 * 
 * @param client      Client index, pass 0 for message to all.
 * @param szMessage   Message (formatting rules).
 * @return            No return
 */
stock War3_ChatMessage(client, const String:szMessage[], any:...)
{
	if (client == 0)
	{
		decl String:szBuffer[MAX_MESSAGE_LENGTH];
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				SetGlobalTransTarget(i);
				VFormat(szBuffer, sizeof(szBuffer), szMessage, 3);
				Format(szBuffer, sizeof(szBuffer), "%T%s", "[War3Source]", i, szBuffer);
				CPrintToChat(i, szBuffer);
			}
		}
	}
	else
	{
		decl String:szBuffer[MAX_MESSAGE_LENGTH];
		SetGlobalTransTarget(client);
		VFormat(szBuffer, sizeof(szBuffer), szMessage, 3);
		Format(szBuffer, sizeof(szBuffer), "%T%s", "[War3Source]", client, szBuffer);
		CPrintToChat(client, szBuffer);
	}
}

/** 
 * Prints a message in the chat area with [War3Source] pre-appended.
 * Support color tags: {default}, {green}, {olive}, {teamcolor}.
 * 
 * @param client      Client index, pass 0 for message to all.
 * @param author      Author index whose color will be used for teamcolor tag.
 * @param szMessage   Message (formatting rules).
 * @return            No return
 */
stock War3_ChatMessageEx(client, author, const String:szMessage[], any:...)
{
	if (client == 0)
	{
		if (author < 0 || author > MaxClients)
			ThrowError("Invalid client index %d", author);
		
		if (!IsClientInGame(author))
			ThrowError("Client %d is not in game", author);
		
		decl String:szBuffer[MAX_MESSAGE_LENGTH];
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				SetGlobalTransTarget(i);
				VFormat(szBuffer, sizeof(szBuffer), szMessage, 4);
				Format(szBuffer, sizeof(szBuffer), "%T%s", "[War3Source]", i, szBuffer);
				CPrintToChatEx(i, author, szBuffer);
			}
		}
	}
	else
	{
		decl String:szBuffer[MAX_MESSAGE_LENGTH];
		SetGlobalTransTarget(client);
		VFormat(szBuffer, sizeof(szBuffer), szMessage, 4);
		Format(szBuffer, sizeof(szBuffer), "%T%s", "[War3Source]", client, szBuffer);
		CPrintToChatEx(client, author, szBuffer);
	}
}

//who should the tanslated phrase be translated to, 0 = server default language
stock SetTrans(client){
	W3SetVar(TransClient,client);
}
stock GetTrans(){
	return W3GetVar(TransClient);
}



stock bool:IS_PLAYER(x)
{
	if(x>0&&x<=MaxClients)
		return true;
	return false;
}

stock HasSMAccess(client,flag)
{
	new flags = GetUserFlagBits(client);
	if (flags & flag) //ADMFLAG_ROOT
	{
		return true;
	}
	
	
	return W3IsDeveloper(client);
}

//precache sound    and adds to download table
stock bool:War3_PrecacheSound(String:sound[]){
	new String:longsound[512];
	
	Format(longsound,sizeof(longsound), "sound/%s", sound);
	AddFileToDownloadsTable(longsound); 
	
	if(PrecacheSound(sound, true)){
		//PrintToServer("TWar3_PrecacheSound %s",longsound);
		return true;
	}
	else{
		PrintToServer("Fail War3_PrecacheSound %s",longsound);	
	}
	return false;
}

stock bool:W3HasImmunity(client,War3Immunity:immunityindex){

	//add magic immunity etc later
	if(immunityindex==Immunity_Skills){
		return W3GetBuffHasTrue(client,bImmunitySkills);
	}
	if(immunityindex==Immunity_Ultimates){
		return W3GetBuffHasTrue(client,bImmunityUltimates);
	}
	if(immunityindex==Immunity_Wards){
		return W3GetBuffHasTrue(client,bImmunityWards)||W3GetBuffHasTrue(client,bImmunitySkills);
	}

	
	return false;
	
}
stock bool:IsSkillImmune(client){
	return W3GetBuffHasTrue(client,bImmunitySkills);
}
stock bool:IsUltImmune(client){
	return W3GetBuffHasTrue(client,bImmunityUltimates);
}

//returns true/false on a chance cast. 1.0=100%, 0.1 = 10% chance
stock bool:War3_Chance(Float:chancepercent=1.0) {
	return (GetRandomFloat(0.0,1.0)<=chancepercent);
}
stock bool:W3Chance(Float:chancepercent=1.0) {
	return (GetRandomFloat(0.0,1.0)<=chancepercent);
}

//sets armor, but does not give any helm
stock War3_SetCSArmor(client,amount){
	if(War3_GetGame()==Game_CS){
		if(amount>125){
			amount=125;
		}
		SetEntProp(client,Prop_Send,"m_ArmorValue",amount);
	}
}
stock War3_GetCSArmor(client){
	if(War3_GetGame()==Game_CS){
		return GetEntProp(client,Prop_Send,"m_ArmorValue");
	}
	return 0;
}
stock War3_GetCSArmorHasHelmet(client){
	return GetEntProp(client, Prop_Send, "m_bHasHelmet")
}
stock War3_SetCSArmorHasHelmet(client,bool:hashelmet){
	return SetEntProp(client, Prop_Send, "m_bHasHelmet",hashelmet? 1:0, 1);
}
stock GetCSMoney(client){
	if(War3_GetGame()!=CS){
		return 0;
	}
	return GetEntProp(client, Prop_Send, "m_iAccount");
}
stock SetCSMoney(client,newamount){

	SetEntProp(client, Prop_Send, "m_iAccount",newamount);
}


stock UTIL_Remove(entity)
{
	if(IsValidEdict(entity))	AcceptEntityInput(entity, "Kill");
}

stock W3ShowSkillsInfo(client)
{
	if(War3_GetRace(client)>0){
		W3SetVar(RaceinfoRaceToShow,War3_GetRace(client));
		W3CreateEvent(DoShowParticularRaceInfo,client);
	}
	else{
		War3_ChatMessage(client,"%T","Select a race first!",client);
		W3CreateEvent(DoShowChangeRaceMenu,client);
	}
}

//get numver of players on the specified team (integer team)
stock PlayersOnTeam(team)
{
	new num;
	for(new x=1;x<=MaxClients;x++)
	{
		if(IsClientInGame(x)&&GetClientTeam(x)==team){
			num++;
		}
	}
	return num;
}



stock GetShortTeamName(team,String:retstr[],maxlen){
	if(War3_GetGame()==CS){
		if(team==1){
			Format(retstr,maxlen,"%t","CS Spec");
			return;
		}
		if(team==TEAM_T){
			Format(retstr,maxlen,"%t","CS T");
			return;
		}
		if(team==TEAM_CT){
			Format(retstr,maxlen,"%t","CS CT");
			return;
		}
	} 
	else if(War3_GetGame()==TF){
		if(team==1){
			Format(retstr,maxlen,"%t","TF Spec");
			return;
		}
		if(team==TEAM_RED){
			Format(retstr,maxlen,"%t","TF RED");
			return;
		}
		if(team==TEAM_BLUE){
			Format(retstr,maxlen,"%t","TF BLU");
			return;
		}
	}

	Format(retstr,maxlen,"%t","Unknown Team");
	return;
}

stock GetRacesOnTeam(raceid,team,ignoreIfAdminSetRace=false){
	new num;
	for(new y=1;y<=MaxClients;y++)
	{
		
		if(ValidPlayer(y,false))
		{	
			
			if(War3_GetRace(y)==raceid)
			{
				if(GetClientTeam(y)==team)
				{
					if(ignoreIfAdminSetRace&&W3GetPlayerProp(y,RaceSetByAdmin)){
					}
					else{
						num++;
					}
				}
			}
		}
	}
	return num;
}

stock bool:W3IsDamageFromMelee(const String:weapon[])
{
	switch (War3_GetGame())
	{
		case Game_CS:
		{
			return StrEqual(weapon,"weapon_knife");
		}
		case Game_DOD:
		{
			return (StrEqual(weapon,"amerknife") ||
			StrEqual(weapon,"spade") ||
			StrEqual(weapon,"punch"));
		}
		case Game_TF:
		{
			return (
			StrEqual(weapon,"shovel") ||
			StrEqual(weapon,"wrench") ||
			StrEqual(weapon,"bat") ||
			StrEqual(weapon,"bonesaw") ||
			StrEqual(weapon,"bottle") ||
			StrEqual(weapon,"club") ||
			StrEqual(weapon,"fireaxe") ||
			StrEqual(weapon,"axtinguisher") ||
			StrEqual(weapon,"fists") ||
			StrEqual(weapon,"sandman") ||
			StrEqual(weapon,"pickaxe") ||
			StrEqual(weapon,"sword") ||
			StrEqual(weapon,"demoshield") ||
			StrEqual(weapon,"taunt_scout") ||
			StrEqual(weapon,"taunt_sniper") ||
			StrEqual(weapon,"taunt_pyro") ||
			StrEqual(weapon,"taunt_demoman") ||
			StrEqual(weapon,"taunt_heavy") ||
			StrEqual(weapon,"taunt_spy") ||
			StrEqual(weapon,"taunt_soldier")||
			
			StrEqual(weapon,"tf_weapon_knife") ||
			StrEqual(weapon,"tf_weapon_shovel") ||
			StrEqual(weapon,"tf_weapon_wrench") ||
			StrEqual(weapon,"tf_weapon_bat") ||
			StrEqual(weapon,"tf_weapon_bat_wood") ||
			StrEqual(weapon,"tf_weapon_bonesaw") ||
			StrEqual(weapon,"tf_weapon_bottle") ||
			StrEqual(weapon,"tf_weapon_club") ||
			StrEqual(weapon,"tf_weapon_fireaxe") ||
			StrEqual(weapon,"tf_weapon_fists") ||
			StrEqual(weapon,"tf_weapon_sword") ||
			StrEqual(weapon,"tf_weapon_bat_fish") ||
			StrEqual(weapon,"tf_weapon_robot_arm")
			
			);
		}
	}
	return false;
}

stock bool:TF2_HasTheFlag(client)
{
	if (War3_GetGame() == Game_TF)
	{
		new ent = -1;
		while ((ent = FindEntityByClassname(ent, "item_teamflag")) != -1)
		{
			if (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity")==client)
				return true;
		}
	}
	return false;
}
stock TE_SetupKillPlayerAttachments(client)
{
	TE_Start("KillPlayerAttachments");
	TE_WriteNum("m_nPlayer",client);
}





























//////MESSAGES




//prints [W3S] You did %d damage to %name with SKILLNAME
//prints [W3S] %name did %d damage to you with SKILLNAME
new String:zzname[32];
stock W3PrintSkillDmgConsole(victim=0,attacker,damage,String:skillname[]){
	GetClientName(victim,zzname,sizeof(zzname));
	PrintToConsole(attacker,"%T","[W3S] You did +{amount} damage to {player} with {skill}",attacker,damage,zzname,skillname);
	
	if(victim>0){
		GetClientName(attacker,zzname,sizeof(zzname));
		PrintToConsole(victim,"%T","[W3S] {player} did {amount} damage to you with {skill}",victim,zzname,damage,skillname);
	}
}
//+%d damage with skill name
stock W3PrintSkillDmgHint(victim=0,attacker,damage,String:skillname[]){
	PrintHintText(attacker,"%T","+{amount} damage with {skill}",attacker,damage,skillname);
	
	if(victim>0){
		PrintHintText(victim,"%T","Received {amount} damage from {skill}",victim,damage,skillname);
	}
}
stock W3PrintSkillDmgHintConsole(victim=0,attacker,damage,String:skillname[]){
	W3PrintSkillDmgHint(victim,attacker,damage,skillname);
	W3PrintSkillDmgConsole(victim,attacker,damage,skillname);
}


//colored
//prints [war3 tag] You did %d damage to %name with SKILLNAME
//prints [war3 tag] %name did %d damage to you with SKILLNAME
///automatically goes into console
stock W3PrintSkillDmgChat(victim,attacker,damage,String:skillname[]){
	GetClientName(victim,zzname,sizeof(zzname));
	War3_ChatMessage(attacker,"%T","You did +{amount} damage to {player} with {skill}",attacker,damage,zzname,skillname);
	
	if(victim>0){
		GetClientName(attacker,zzname,sizeof(zzname));
		War3_ChatMessage(victim,"%T","{player} did {amount} damage to you with {skill}",victim,zzname,damage,skillname);
	}
}


stock W3MsgUltNotLeveled(client){
	new String:buffer[100];
	Format(buffer, sizeof(buffer), "%T", "Your Ultimate is not leveled", client);
	PrintHintText(client,buffer);
}
stock W3MsgNoTargetFound(client,Float:distancegameunits=0.0){
	decl String:print[500];
	Format(print,sizeof(print),"%T","No target found",client);
	if(distancegameunits>0.1){
		if(GetConVarInt(W3GetVar(hUseMetricCvar))==0)
		{
			Format(print,sizeof(print),"%T","No target found within {amount} feet",client,distancegameunits/10.0);
		}
		else
		{
			Format(print,sizeof(print),"%T","No target found within {amount} meters",client,distancegameunits/30.0);
		}
	}
	PrintHintText(client,"%s",print);
}
stock W3MsgCreatedWard(client,currentwardcount=0,totalwardcount=0){
	decl String:print[500];
	Format(print,sizeof(print),"%T","You created a Ward",client);
	if(currentwardcount>0){
		Format(print,sizeof(print),"%T","You created a Ward {amount}",client,currentwardcount);
		if(totalwardcount>0){
			Format(print,sizeof(print),"%T","You created a Ward {amount}/{amount}",client,currentwardcount,totalwardcount);
		}
	}
	PrintHintText(client,"%s",print);
}
stock W3MsgWardLocationDeny(client){
	PrintHintText(client,"%T","You can not build a Ward Here",client);
}
stock W3MsgNoWardsLeft(client){
	PrintHintText(client,"%T","You have used up all your Wards!",client);
}
stock W3MsgNoWardWhenInvis(client){
	PrintHintText(client,"%T","No Ward Placement While Invisible",client);
}
stock W3MsgEvaded(victim,attacker){
	PrintHintText(victim,"%T","You Evaded a Shot",victim);
	PrintHintText(attacker,"%T","Enemy Evaded",attacker);
}
stock W3MsgEntangle(victim,attacker){
	PrintHintText(victim,"%T","You are Entangled!",victim);
	PrintHintText(attacker,"%T","Entangled!",attacker);
}

stock W3MsgNoCastDuringFreezetime(client){
	PrintHintText(client,"%T","Cannot cast during freezetime",client);		
}
stock W3MsgSkillBlocked(victim=0,attacker=0,String:skillname[]){
	if(victim>0){
		PrintHintText(victim,"%T","Blocked enemy {skill}",victim,skillname);	
	}
	if(attacker>0){
		PrintHintText(victim,"%T","Enemy Blocked {skill}",victim,skillname);	
	}
}
stock W3MsgBanished(victim,attacker){
	PrintHintText(victim,"%T","You have been Banished",victim);
	PrintHintText(attacker,"%T","You Banished",attacker);
}
stock W3MsgStoleMoney(victim,attacker,dollars){
	PrintHintText(victim,"%T","Enemy stole {dollars} dollars from you",victim,dollars);
	PrintHintText(attacker,"%T","You Stole {dollars} dollars",attacker,dollars);
}
stock W3MsgStoleGold(victim,attacker,gold){
	PrintHintText(victim,"%T","Enemy stole {gold} gold from you",victim,gold);
	PrintHintText(attacker,"%T","You Stole {gold} gold",attacker,gold);
}
stock W3MsgRevivedBM(playerrevived,savior){
	new String:clientName[64];
	GetClientName(playerrevived,clientName,sizeof(clientName));	
	new String:saviorName[64];
	GetClientName(savior,saviorName,sizeof(saviorName));
		
	PrintHintText(savior,"%T","You revived {player}",savior,clientName);
	War3_ChatMessage(playerrevived,"%T","{player} revived you",playerrevived,saviorName);
}
stock W3MsgUsingVoodoo(client){
	PrintHintText(client,"%T","Activated Voodoo!",client);
}
stock W3MsgVoodooEnded(client){
	PrintHintText(client,"%T","Voodoo has ended",client);
}
stock W3MsgEnemyHasImmunity(client,bool:console=true){
	PrintHintText(client,"%T","Enemy has immunity!",client);
	PrintToConsole(client,"%T","[W3S] Enemy has immunity!",client);
}
stock W3MsgUltimateNotActivatable(client){
	PrintHintText(client,"%T","This ultimate is not activatable",client);    //prints
}
stock W3MsgUltimateBlocked(client){
	PrintHintText(client,"%T","Ultimate Blocked",client);
}
stock W3MsgThrewKnives(client){
	PrintHintText(client,"%T","You threw knives around you",client);
}
stock W3MsgHitByKnives(client){
	PrintHintText(client,"%T","Attacked by Fan of Knives",client);
}
stock W3MsgActivated(client,String:postpendstr[]){
	PrintHintText(client,"%T","Activated {skillname}",client,postpendstr);
}
stock W3MsgAttackedBy(client,String:postpendstr[]){
	PrintHintText(client,"%T","Attacked By {skillname}",client,postpendstr);
}
stock W3MsgMoleIn(client,Float:timetillactivation){
	PrintHintText(client,"%T","WARNING! MOLE IN {amount} SECONDS!",client,timetillactivation);
	War3_ChatMessage(client,"%T","WARNING! MOLE IN {amount} SECONDS!",client,timetillactivation);
}
stock W3MsgMoled(client){
	War3_ChatMessage(client,"%T","You have moled!",client);
	PrintHintText(client,"%T","You have moled!",client);
}
stock W3MsgNoLongerDisguised(client){
	War3_ChatMessage(client,"%T","You are no longer disguised",client);
	PrintHintText(client,"%T","You are no longer disguised",client);
}
stock W3MsgVengenceWasBlocked(client,String:reason[]){
	War3_ChatMessage(client,"%T","Vengence blocked ({reason})",client,reason);
}







/**
 *
 * Description: Manage precaching resources.
 * Author(s): Frenzzy
 */

/**
 * Adds a file to the downloadables network string table.
 *
 * @param filename		File that will be added to downloadables table.
 * @noreturn
 */
stock W3AddFile(const String:filename[])
{
	if (FileExists(filename)) {
		AddFileToDownloadsTable(filename);
	} else {
		ThrowError("File \"%s\" not found", filename);
	}
}

/**
 * Add to downloads table and precaches a given sound.
 *
 * @param sound			Name of the sound to download and precache.
 * @param precache		If precache is true the file will be precached.
 * @param preload		If preload is true the file will be precached before level startup.
 * @return Returns the sound index if precache is true, 0 for error or precache is false. 
 */
stock W3AddSound(const String:sound[], bool:precache = true, bool:preload = true)
{
	decl String:path[PLATFORM_MAX_PATH];
	Format(path, sizeof(path), "sound/%s", sound);
	if (FileExists(path)) {
		AddFileToDownloadsTable(path);
		if (precache){
			return PrecacheSound(sound, preload);
		}
		
	} else {
		ThrowError("Sound file \"%s\" not found", path);
	}
	return 0;
}

/**
 * Add to downloads table and precaches a given model.
 *
 * @param model			Name of the model to download and precache.
 * @param precache		If precache is true the file will be precached.
 * @param preload		If preload is true the file will be precached before level startup.
 * @return Returns the model index if precache is true, 0 for error or precache is false. 
 */
stock W3AddModel(const String:model[], bool:precache = true, bool:preload = true)
{
	if (FileExists(model)) {
		AddFileToDownloadsTable(model);
		if (precache)
			return PrecacheModel(model, preload);
		
	} else {
		ThrowError("Model file \"%s\" not found", model);
	}
	return 0;
}

/**
 * Add to downloads table and precaches a given decal.
 *
 * @param decal			Name of the decal to download and precache.
 * @param precache		If precache is true the file will be precached.
 * @param preload		If preload is true the file will be precached before level startup.
 * @return Returns the Decal index if precache is true, 0 for error or precache is false. 
 */
stock W3AddDecal(const String:decal[], bool:precache = true, bool:preload = true)
{
	if (FileExists(decal)) {
		AddFileToDownloadsTable(decal);
		if (precache)
			return PrecacheModel(decal, preload);
	} else {
		ThrowError("Decal file \"%s\" not found", decal);
	}
	return 0;
}




stock DP(const String:szMessage[], any:...)
{
	
	decl String:szBuffer[100];

	VFormat(szBuffer, sizeof(szBuffer), szMessage, 2);
	PrintToServer("[Debug Print] %s", szBuffer);
	PrintToChatAll("[Debug Print] %s", szBuffer);

}







//SUPER HERO INDLUDE FILE, many stock requires war3 functions to be delcared first...
#include "W3SIncs/SuperHero_Interface"
