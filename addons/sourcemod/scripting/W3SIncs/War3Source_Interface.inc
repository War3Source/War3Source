/**
 * File: War3Source_Interface.inc
 * Description: The big one that includes everything else
 * Author(s): War3Source Team  
 */
#pragma semicolon 1

#undef REQUIRE_EXTENSIONS
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <cstrike>

#include "W3SIncs/War3Source_Constants"
#include "W3SIncs/War3Source_Bots"
#include "W3SIncs/colors"
#include "W3SIncs/emitsoundany"
#include "W3SIncs/War3Source_Aura"
#include "W3SIncs/War3Source_Wards"
#include "W3SIncs/War3Source_Races"
#include "W3SIncs/War3Source_Logging"
#include "W3SIncs/War3Source_Gamecheck"

//Interface version, change this when the API requirement changes to force a recompile
//There will be a system check to make sure all plugins are compiled to the same interface.
new String:interfaceVersion[]="1.2.4.1";

stock dummy; //variable for dummies! Use this where ever u want for a dummy return
stock String:dummystr[32]; //just a dummy string! 

/**********************
 * CAUTION, THE War3 INTERFACE NOW HANDLES AskPluginLoad2Custom BECAUSE IT IS REQUIRED TO HANDLE CERTAIN TASKS
 * It acually simplifies things for you:
 * Determines game mode
 * Mark Natives optional
 * Calls your own functions (hackish way) if you have them:
 * InitNativesForwards()   
 * AskPluginLoad2Custom(Handle:myself,bool:late,String:error[],err_max);
 * So if you want to do something in AskPluginLoad2, implement public AskPluginLoad2Custom(...) instead. 
 */
public APLRes:AskPluginLoad2(Handle:plugin,bool:late,String:error[],err_max)
{
  DetermineGameMode();
  new Function:func;
  func=GetFunctionByName(plugin, "InitNativesForwards");
  if(func!=INVALID_FUNCTION) { //non war3 plugins dont have this function
    Call_StartFunction(plugin, func);
    Call_Finish(dummy);
    if(!dummy) {
      LogError("InitNativesForwards did not return true, possible failure");
    }
  }
  func=GetFunctionByName(plugin, "AskPluginLoad2Custom");
  if(func!=INVALID_FUNCTION) { //non war3 plugins dont have this function
    Call_StartFunction(plugin, func);
    Call_PushCell(plugin);
    Call_PushCell(late);
    Call_PushString(error);
    Call_PushCell(err_max);
    Call_Finish(dummy);
    if(APLRes:dummy==APLRes_SilentFailure) {
      return APLRes_SilentFailure;
    }
    if(APLRes:dummy!=APLRes_Success) {
      LogError("AskPluginLoad2Custom did not return true, possible failure");
    }
  }
  func=GetFunctionByName(plugin, "LoadCheck");
  if(func!=INVALID_FUNCTION) { //non war3 plugins dont have this function
    Call_StartFunction(plugin, func);
    Call_Finish(dummy);
    if(dummy==0) {
      return APLRes_SilentFailure;
    }
  }

  return APLRes_Success;
}
/**********************
 * Implement this if you have natives/forwards
 */
forward bool:InitNativesForwards();

/**********************
 * Implement this if you need AskPluginLoad2
 */
forward APLRes:AskPluginLoad2Custom(Handle:plugin,bool:late,String:error[],err_max);


/**********************
 * Checks plugin to allow for silent failure
 * Called from APLRes:AskPluginLoad / War3Source main 
 *  
 * Return true to allow loading
 * Return false to silently disable loading 
 */
forward LoadCheck();


//Called for each category if the user opens the catted cr menu
forward Action:OnW3DrawCategory(client,categoryindex,String:categoryname[]);

//Warcraft required executions, does common tasks, such as loading translations.
forward War3InterfaceExec();
public War3InterfaceExec() {
  LoadTranslations("w3s._common.phrases.txt");
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

stock SetSafeMenuTitle(Handle:menu, const String:fmt[], any:...)
{
  decl String:menuTitle[4096];
  VFormat(menuTitle, sizeof(menuTitle), fmt, 3);

  // There's a silly bug with the Left4Dead engine where menus won't
  // show up if the title starts with [ :(
  if(GAMEL4DANY && menuTitle[0] == '[')
  {
    Format(menuTitle, sizeof(menuTitle), " %s", menuTitle);
  }
  
  SetMenuTitle(menu, menuTitle);
}

native W3GetW3Version(String:retstr[],maxlen);//str
native W3GetW3Revision();//int
native W3GetStatsVersion();//int
//returns the TRIE that contains stats key value pairs, for GAME and SERVER stats
native Handle:W3GetStatsKDRTrie();

//Socket functions
//GET or normal
//URL can be full url with http:// or just path without leading slash
native W3Socket(String:url[],Function:callback);
//POST
//URL can be full url with http:// or just path without leading slash
native W3Socket2(String:url[],String:postdata[],Function:callback);

//forces weapon drop, given a weapon entity
native W3DropWeapon(client, weaponent);

/**
 * Checks if we are in the freeze time. Certain games support this, like CS.
 * @return True if so, false if not.
 *  
 */
#pragma deprecated
native bool:War3_InFreezeTime();


//set / retrieves specified values from the main war3 plugin, see W3Var enum in constants.inc, only those values are allowed
//this mostly used for accessing a variable without creating a special native just for it
//this returns any:, you should tag it if return value is not suppose to be normal integer. like Float:W3GetVar( or Handle:W3GetVar(
//most are temporary variables and this function should be called immidiately in the right functions
//examples W3GetVar(OldRace)   W3GetVar(DeathRace)
//See W3Var enum in constants to get a list
//Do not get/set vars arbitrarily unless you know what you are doing
native any:W3GetVar(W3Var:variabletoretrieve);

//set / retrieves specified values from the main war3 plugin, see W3Var enum in constants.inc, only those values are allowed
//this mostly used for accessing a variable without creating a special native just for it
//this returns any:, you should tag it if return value is not suppose to be normal integer. like Float:W3GetVar( or Handle:W3GetVar(
//most are temporary variables and this function should be called immidiately in the right functions
//examples W3GetVar(OldRace)   W3GetVar(DeathRace)
//See W3Var enum in constants to get a list
//Do not get/set vars arbitrarily unless you know what you are doing
native any:W3SetVar(W3Var:variabletoretrieve,any:value);


/**
 * Registers a help command with the War3Source plugin for war3help
 * @param name: The name of the command. (max 64)
 * @param desc: The description of the command. (max 256) 
 * @noreturn
 */
native War3_CreateHelpCommand(String:name[],String:desc[]);

native W3GetLevelsSpent(client, race);
native W3ClearSkillLevels(client, race);

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

//generic immunity filter for ultimate
public bool:UltFilter(client)
{
  return (!W3HasImmunity(client,Immunity_Ultimates));
}
//generic immunity filter for skills
public bool:SkillFilter(client)
{
  return (!W3HasImmunity(client,Immunity_Skills));
}

///traces from client to target and see if they are in view of each other (Line of Signt - LOS)
native W3LOS(client, target);

stock bool:ValidPlayer(client,bool:check_alive=false,bool:alivecheckbyhealth=false) {
  if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client))
  {
    if(check_alive && !IsPlayerAlive(client))
    {
      return false;
    }
    if(alivecheckbyhealth&&GetClientHealth(client)<1) {
      return false;
    }
    return true;
  }
  return false;
}

stock bool:ValidRace(raceid_) {
  return bool:(raceid_>0&&raceid_<=War3_GetRacesLoaded());
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
native War3_CachedWeapon(client, weapon_iterator);

/**
 * Get cached weapon entity "clip1" based on iterator.
 * This function is usually called from a loop. 
 * @param client: Client index
 * @param weapon_iterator: Number from 0-9. 
 * @return Value of clip1.
 */
native War3_CachedClip1(client, weapon_iterator);

/**
 * Get cached ammo of a player with a specific weapon ID.
 * This function is usually called from a loop. 
 * @param client: Client index
 * @param game_weapon_id: Game specific weapon identifier, this is constant for each weapon. 
 * @return Value of iAmmo.
 */
native War3_CachedAmmo(client, game_weapon_id);

/**
 * Get cached weapon entity "clip1" of iterator, only changes when a player dies.
 * This function is usually called from a loop. 
 * @param client: Client index
 * @param weapon_iterator: Number from 0-9. 
 * @return Value of clip1 from last death.
 */
native War3_CachedDeadClip1(client, weapon_iterator);

/**
 * Get cached ammo of a player with a specific weapon ID, only changes when a player dies.
 * This function is usually called from a loop. 
 * @param client: Client index
 * @param game_weapon_id: Game specific weapon identifier, this is constant for each weapon. 
 * @return Value of iAmmo from last death.
 */
native War3_CachedDeadAmmo(client, game_weapon_id);

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

//LO AND BEHOLD THE COOLDOWN MANAGER, YOUR LIFE SIMPLIFIED!!!
//we essentially move the cooldown system out of our races into our main plugin
/**
 * cooldown manager
 * basically self explainatory parameters, creates a cooldown for a skill (term skill used here is generic for skill/ability/ultimate)
 * printMsgOnExpireByTime prints message to client (if alive and same race) when this skill expires by time (will not print when expired by spawn or death or force reset)
 * The skill name of the skill will be in ready and not ready messages.
 * when a cooldown expires (by time, by death, by spawn, by force reset), it will forward to OnCooldownExpired(....) forward, use if u need to
 * @noreturn
 * 
 * Usually the first 4 parameters are enough  
 */
native War3_CooldownMGR(client,Float:cooldownTime,raceid,skillNum, bool:resetOnSpawn=true,bool:printMsgOnExpireByTime=true);

//tells the cooldown manager to create a predefined cooldown time when player spawns with that race. 
//cooldown is created regardless of resetOnSpawn in War3_CooldownMGR(...) calls
//only prints expired if client remains that race
//set this ONCE when u register your skills
native W3SkillCooldownOnSpawn(raceid,skillnum,Float:cooldownTime,bool:printmsgonexpire=true);

/**
 * how much time is left on this particular cooldown?
 * returns an int (rounted up from the float)
 */
native War3_CooldownRemaining(client, raceid, skillNum);

/**
 * basically make this cooldown expire, this expiration is not considered "by time"
 */
native War3_CooldownReset(client, raceid, skillNum);

/**
 * is this skill NOT in COOLDOWN? YOU NEED TO CHECK IF CLIENT HAS LEVELED THIS SKILL FIRST, THIS IS ONLY COOLDOWN RELATED
 * you would only do this if this skill has a cooldown and u called War3_CooldownMGR
 * printTextIfNotReady=true will print a "not ready" message
 */
native bool:War3_SkillNotInCooldown(client,raceid,skillNum,bool:printTextIfNotReady=false);

/**
 * prints Skill Is Not Ready
 */
native War3_PrintSkillIsNotReady(client, raceid, skillNum);

//DELAY TRACKER
//DELAY TRACKER
//DELAY TRACKER
//DELAY TRACKER
//DELAY TRACKER
//DELAY TRACKER

///registers a tracker and returns an index that you must keep. usually do this for each each player or once if global
// Register once on plugin start please!
//returns -1 if tracker is full. LogErrors on Full
/*
 usage:

 register tracker
 create delay

 repeat:{
 expired?
 create delay
 }

 */
native War3_RegisterDelayTracker();

//create a delay
native War3_TrackDelay(trackerIndex,Float:delay);

//did the delay expire?
native War3_TrackDelayExpired(trackerIndex);

///PLAYER  TRACE
///PLAYER  TRACE
///PLAYER  TRACE
///PLAYER  TRACE
///PLAYER  TRACE

//get location of where the player is aiming (trace to the end of your crosshair)
native War3_GetAimEndPoint(client,Float:endpos[3]);

//get location of where the player is aiming (trace to the end of your crosshair) limited by distance
native War3_GetAimTraceMaxLen(client,Float:endpos[3],Float:maxdistance);

//simple weapon restriction:  pass "weapon_knife,weapon_hegrenade" to only allow these weapons, separated by comma. 
//pass "" to allow all weapons again
//c4 etc is automatically allowed
//to override other restrictions, use a higher priority
//use 1 priorty for ur base race restrictions, USE AT OWN RISK!
native War3_WeaponRestrictTo(client,raceid,String:onlyallowedweaponsnames[],priority=1);

//get weaponlist
native War3_GetWeaponRestriction(client,raceid,String:buffer[],maxlength);

native Float:W3GetPhysicalArmorMulti(client); //damage multipler for client by accounting for physical armor (warcraft physical armor, not cs armor)
native Float:W3GetMagicArmorMulti(client); //damage multipler for client by accounting for magic armor

native W3GetCurrentWeaponEnt(client); //get the entity of the current (active) weapon

native War3_IsMeleeWeapon(weaponIndex);

native W3GetMinUltLevel();

//force all supported war3 plugins into failed mode (pause plugin)
native War3Failed(String:reason[]);

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

/**
 * Prints a message to the right-hand display
 *
 * @param   client    Client index.
 * @param   szFormat  Formatting rules.
 * @param   ...    Variable number of format parameters.
 */
native War3_KeyHintText(client, const String:szFormat[], any:...);

//print via hint engine. format accepts translations
// W3Hint_Default create lowest priority with 5 second duration (for those of us whom are lazy)
stock W3Hint_Default(client, String:format[], any:...)
{
	decl String:sOutput[128];
	VFormat(sOutput, sizeof(sOutput), format, 3);
	return W3Hint(client, _, _, sOutput);
}

//maximum duration is 20.0
native W3Hint(client,W3HintPriority:type=HINT_LOWEST,Float:duration=5.0,String:format[],any:...);

//for activatable skills only
stock bool:SkillAvailable(client,yourRaceID,skillnumber,bool:printCooldown=true,bool:checksilenced=true,bool:printSilenced=true) {
  return War3_SkillNotInCooldown(client,yourRaceID,skillnumber,printCooldown)&& (!checksilenced||!Silenced(client,printSilenced));
}

native War3_GetRace(client);
native War3_SetRace(client, race);

native War3_SetLevel(client, race, level);
native War3_GetLevel(client, race);
native War3_GetLevelEx(client, race, bool:trueLevel=false);

native W3GetTotalLevels(client); //sum of  levels in each race

native W3GetLevelBank(client);
native W3SetLevelBank(client, newlevelbank);

native War3_SetXP(client, race, newxp);
native War3_GetXP(client, race);

//native War3_SetSkillLevel(client,race,skill,newlevel);
native War3_GetSkillLevel(client, race, skill);

native War3_SetSkillLevelINTERNAL(client, race, skill, newlevel);
native War3_GetSkillLevelINTERNAL(client, race, skill);

/*
Gets the skill level of a generic skill
@client
@g_skill_id = generic skill id
@genericSkillData = array that the customer race passed to you (if any) when attaching itself to this generic skill
@customerRaceID = the matching race that is trying to use this generic skill
@customerSkillID = the matching skill id for the race trying to use this as generic skill

for example, if race 4 skill 3 is redirected as generic skill 2, 
you should have passed 2 as g_skill_id
customerRaceID will be returned as 4
customerSkillID returns 3

*/
native W3_GenericSkillLevel(client,g_skill_id,&Handle:genericSkillData,&customerRaceID=0,&customerSkillID=0);
native W3SetPlayerProp(client,W3PlayerProp:property,any:value);
native any:W3GetPlayerProp(client,W3PlayerProp:property);

//TKV = trie key value , a abstract data storage, emulates cvars for war3
///Creates internal war3 cvars. returns a id to your cvar, store it!
//cvarid of 0 is null null (filled auto)
//make sure native have binded (on plugin start is fine)
native W3CreateCvar(String:cvarstr[],String:cvarvalue[],String:cvardesc[],ReplaceCvar=0);
native W3GetCvar(cvarid,String:returnstr[],maxlen);
native W3SetCvar(cvarid,String:cvarvalue[]);

//returns -1 if not found, otherwise returns cvar id
native W3FindCvar(String:cvar[]);
native Handle:W3CvarList(); //returns a handle arraylist of cvar list (no values, names only. CLOSE THIS!!!

//get cvar value when you have the key
native W3GetCvarByString(String:cvarstr[],String:returnstr[],maxlen);

//get actual cvar name: undead_blah (the KEY)
native W3GetCvarActualString(cvarid,String:returnstr[],maxlen);

stock W3CreateCvarInt(String:cvarstr[],intval,String:cvardesc[]) {
  decl String:str[1024];
  Format(str,sizeof(str),"%d",intval);
  return W3CreateCvar(cvarstr,str,cvardesc);
}
stock W3GetCvarInt(cvarid) {
  decl String:ret[1024];
  W3GetCvar(cvarid, ret, sizeof(ret));
  //PrintToChatAll("%s %d",ret,StringToInt(ret));
  return StringToInt(ret);
}
stock W3SetCvarInt(cvarid, intval) {
  decl String:str[1024];
  Format(str, sizeof(str), "%d", intval);
  return W3SetCvar(cvarid, str);
}
stock W3CreateCvarFloat(String:cvarstr[],intval,String:cvardesc[]) {
  decl String:str[1024];
  Format(str,sizeof(str),"%f",intval);
  W3CreateCvar(cvarstr,str,cvardesc);
}
stock W3GetCvarFloat(cvarid) {
  decl String:ret[1024];
  W3GetCvar(cvarid, ret, sizeof(ret));
  return StringToFloat(ret);
}
stock W3SetCvarFloat(cvarid, intval) {
  decl String:str[1024];
  Format(str, sizeof(str), "%f", intval);
  W3SetCvar(cvarid, str);
}

stock War3_SetMaxHP_INTERNAL(client, maxhp) {
  //  DP("set to %d",maxhp);
  W3SetPlayerProp(client, iMaxHP, maxhp);
}
stock War3_GetMaxHP(client) {
  //DP("add %d",W3GetBuffSumInt(client,iAdditionalMaxHealth));
  return W3GetPlayerProp(client, iMaxHP);//+ W3GetBuffSumInt(client,iAdditionalMaxHealth);
}
stock bool:W3IsPlayerXPLoaded(client) {
  return W3GetPlayerProp(client,xpLoaded);
}
stock W3GetPendingRace(client) {
  return W3GetPlayerProp(client, PendingRace);
}
stock W3SetPendingRace(client, pendrace) {
  W3SetPlayerProp(client, PendingRace, pendrace);
}

stock W3IsDeveloper(client)
{
  if(ValidPlayer(client)){
    return W3GetPlayerProp(client,isDeveloper);
  }
  return false;
}
///use W3GetVar(hDatabase) to get the handle to the database which your xp is saved, so you dont have to connect again for your addon scipts

native bool:W3SaveEnabled();
native W3SaveXP(client, race);

//Skills
native War3_SuicideBomber(client, Float:location[], Float:damage, race_skillid, Float:radius, bool:effect=true);

//disabled due to human race requirements..for now
//native bool:War3_Teleport(client, Float:distance);

native War3_StringMath(String:equation[]);

native W3HasDiedThisFrame(client);

/**
 * Adds a dependency on a skill
 *
 * @param iRaceID    Race ID
 * @param iSkill     Skill on which the dependency should be added onto
 * @param iRequiredSkill Required Skill ID
 * @param iRequiredLevel Required Level Num
 * @return         true on success, otherwhise false!
 * @error        Thrown on invalid param num/race
 */
native bool:War3_SetDependency(iRaceID, iSkill, iRequiredSkill, iRequiredLevel);

/**
 * Removes any known dependency from a skill(if any)
 * NOTE: you should be able to call this safetly without having to bother about anything,
 * since no error will be thrown if there currently aren't any active dependencys on this
 *
 * @param iRaceID    Race ID
 * @param iSkill     Skill on which the dependency should be removed from
 * @noreturn
 * @error        Thrown on invalid param num/race
 */
native War3_RemoveDependency(iRaceID, iSkill);

/**
 * Retrieves various informations about a depending skill
 * NOTE: This can be called to check if there is any dependency or not
 *
 * @param iRaceID    Race ID
 * @param iSkill     Target skill to get informations from
 * @param eInfo      Type of information to retrieve
 * @return         Retrieved information about the dependency
 * @error        Thrown on invalid param num/race
 */
native War3_GetDependency(iRaceID, iSkill, SkillDependency:eInfo=ID);

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

/*create an error displayed in various places at runtime*/
native CreateWar3GlobalError(String:str[]);

//forwarded when someone calls CreateWar3GlobalError, store that string for yourself
forward OnWar3GlobalError(String:str[]);

forward War3FailedSignal(String:str[]);

/* interface side implementation, do not use */
public War3FailedSignal(String:str[]) {
  LogError(str); //must be a non dependent native log error
  SetFailState(str);
}

forward CheckWar3Compatability(String:w3mainInterfVersion[]);

/* interface side implementation, do not use */
public CheckWar3Compatability(String:w3mainInterfVersion[]) {
  if(!StrEqual(interfaceVersion,w3mainInterfVersion)) {
    //War3_LogCritical("FATAL ERROR, PLUGIN COMPILED INTERFACE VERSION (%s) IS DIFFERENT FROM WAR3SOURCE BASE VERSION (%s). Please Compile With Latest Version!!!",interfaceVersion,w3mainInterfVersion);
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
#pragma deprecated Use OnRaceChanged(client,oldrace,newrace);
forward OnRaceSelected(client, newrace); //to be removed

//client is not check if valid or not, still forwarded if client is not present, so you can disable buffs etc
forward OnRaceChanged(client, oldrace, newrace);

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
 * Gets called when a skill level is changed.
 */
forward OnSkillLevelChanged(client, race, skill, newskilllevel);
/**
 * Gets called when a GENERIC skill level is changed.
 */
forward OnGenericSkillLevelChanged(client,generic_skill_id,newlevel,Handle:generic_Skill_Options,customer_race,customer_skill);

//when a weapon fires, via weapon_fire or TF2 Calc critical (which crits must be on)
forward OnWeaponFired(victim,attacker,Float:damage);

/**
 * Called when a cooldown expires (timed, death, or spawn)
 */
forward OnCooldownExpired(client,raceID,skillNum,bool:expiredByTime);

///general events, see W3EVENT enum in constants
///client may not always matter
forward OnWar3Event(W3EVENT:event,client);

native W3CreateEvent(W3EVENT:event,client);

//simple system for stopping actions, send a specific event with optinal player, those hooking can use W3Deny() to deny
forward OnW3Denyable(W3DENY:event,client);
native bool:W3Denied(W3DENY:event,client); //returns FALSE if NOT DENIED
stock bool:W3Denyable(W3DENY:event,client) {
  return !W3Denied(event,client);
}
native W3Deny();

stock bool:CanSelectRace(client,race) {
  W3SetVar(EventArg1,race);
  new bool:value=W3Denyable(DN_CanSelectRace,client);
  //DP("dp %d",value);
  if(value==false && W3IsDeveloper(client)) {
    //DP("dp2 %d",value);
    War3_ChatMessage(client,"You are normally not allowed to select this race, but since you are developer we will allow you to select this race");

    return true;
  }
  return value;
}

stock ShowChangeRaceMenu(client) {
  W3CreateEvent(DoShowChangeRaceMenu, client);
}

stock W3DoLevelCheck(client) {
  W3CreateEvent(DoLevelCheck, client);
}

//when player spawns, fires only in war3 mode
forward OnWar3EventSpawn(client);

//when player dies, fires only in war3 mode
forward OnWar3EventDeath(victim, attacker, deathrace);

//Fired after a player dodges, useful primarily for attaching effects
forward OnW3DodgePost(victim, attacker);

//Fired before a player dodges, you can edit the dodge chance here
forward OnW3DodgePre(victim,attacker,Float:chance);

//Fired every time a ward is created
forward OnWardCreated(wardindex, behaviorID);

//Fired every time a ward "pulses"
forward OnWardPulse(wardindex, behaviorID);

//Fired every time a ward "pulses" when a valid target is in range
forward OnWardTrigger(wardindex, victim, owner, behaviorID);

//Fired every time a ward is removed
forward OnWardExpire(wardindex, owner, behaviorID);

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
 * @param client    Client index, pass 0 for message to all.
 * @param szMessage   Message (formatting rules).
 * @return      No return
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
 * @param client    Client index, pass 0 for message to all.
 * @param author    Author index whose color will be used for teamcolor tag.
 * @param szMessage   Message (formatting rules).
 * @return      No return
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
stock SetTrans(client) {
  W3SetVar(TransClient, client);
}
stock GetTrans() {
  return W3GetVar(TransClient);
}

stock bool:IS_PLAYER(x)
{
  if(x>0&&x<=MaxClients)
  return true;
  return false;
}

/*
 There are two ways to get admin
 //need 
 //good if you need the string to admin flag like "o" -> number
 id= native bool:GetAdminFlag(AdminId:id, AdminFlag:flag, AdmAccessMode:mode=Access_Effective);
 Admin_RCON,      
 Admin_Root,
 
 VS
 
 //good if u know the access level
 GetUserFlagBits(client)  
 
 ADMFLAG_RCON
 ADMFLAG_ROOT
 */

stock HasSMAccess(client, flag) {
  new flags = GetUserFlagBits(client);
  //DP("flags %d",flags);
  if (flags & (flag | ADMFLAG_ROOT)) //ADMFLAG_ROOT is "z"
  {
    return true;
  }

  return W3IsDeveloper(client);
}

/* is a normal engine cvar empty (zero length, "") ? */
stock bool:CvarEmpty(Handle:sourcemod_convar) {
  static String:zzstr[32];
  return (GetConVarString(sourcemod_convar, zzstr, sizeof(zzstr))&&strlen(zzstr)<1);

}

//returns true/false on a chance cast. 1.0=100%, 0.1 = 10% chance
stock bool:War3_Chance(Float:chancepercent=1.0) {
  return (GetRandomFloat(0.0,1.0)<=chancepercent);
}
stock bool:W3Chance(Float:chancepercent=1.0) {
  return (GetRandomFloat(0.0,1.0)<=chancepercent);
}

/**
 * Returns the amount of money you have in CS/CS:GO
 * When used in TF2 it returns the amount of money the player has in MVM
 */
stock GetCSMoney(client) {
  new ValveGameEnum:war3Game = War3_GetGame();
  if (war3Game == Game_CS || war3Game == Game_CSGO) {
    return GetEntProp(client, Prop_Send, "m_iAccount");
  } else if (war3Game == Game_TF) {
    return GetEntProp(client, Prop_Send, "m_nCurrency");
  }

  return 0;
}

/**
 * Sets the amount of money the player has in CS/CS:GO
 * When used in TF2 it sets the amount of money the player has in MVM
 */
stock SetCSMoney(client, newamount) {
  new ValveGameEnum:war3Game = War3_GetGame();
  if (war3Game == Game_CS || war3Game == Game_CSGO) {
    SetEntProp(client, Prop_Send, "m_iAccount", newamount);
  } else if (war3Game == Game_TF) {
    if (newamount < 0)
      newamount = 0;
    if (newamount > 32767)
      newamount = 32767;
    SetEntProp(client, Prop_Send, "m_nCurrency", newamount);
  }
}

stock UTIL_Remove(entity) {
  if (IsValidEdict(entity))
    AcceptEntityInput(entity, "Kill");
}

stock W3ShowSkillsInfo(client) {
  if (War3_GetRace(client) > 0) {
    W3SetVar(RaceinfoRaceToShow, War3_GetRace(client));
    W3CreateEvent(DoShowParticularRaceInfo, client);
  } else {
    War3_ChatMessage(client, "%T", "Select a race first!", client);
    W3CreateEvent(DoShowChangeRaceMenu, client);
  }
}

//get numver of players on the specified team (integer team)
stock PlayersOnTeam(team) {
  new num;
  for (new x = 1; x <= MaxClients; x++) {
    if (IsClientInGame(x) && GetClientTeam(x) == team) {
      num++;
    }
  }
  return num;
}

stock GetShortTeamName(team,String:retstr[],maxlen) {
  if(War3_GetGame()==CS || War3_GetGame()==CSGO) {
    if(team==1) {
      Format(retstr,maxlen,"%t","CS Spec");
      return;
    }
    if(team==TEAM_T) {
      Format(retstr,maxlen,"%t","CS T");
      return;
    }
    if(team==TEAM_CT) {
      Format(retstr,maxlen,"%t","CS CT");
      return;
    }
  }
  else if(War3_GetGame()==TF) {
    if(team==1) {
      Format(retstr,maxlen,"%t","TF Spec");
      return;
    }
    if(team==TEAM_RED) {
      Format(retstr,maxlen,"%t","TF RED");
      return;
    }
    if(team==TEAM_BLUE) {
      Format(retstr,maxlen,"%t","TF BLU");
      return;
    }
  }

  Format(retstr,maxlen,"%t","Unknown Team");
  return;
}

stock GetRacesOnTeam(raceid, team, ignoreIfAdminSetRace = false) {
  new num;
  for (new y = 1; y <= MaxClients; y++) {

    if (ValidPlayer(y, false)) {

      if (War3_GetRace(y) == raceid) {
        if (GetClientTeam(y) == team) {
          if (ignoreIfAdminSetRace&&W3GetPlayerProp(y,RaceSetByAdmin)) {
          } else {
            num++;
          }
        }
      }
    }
  }
  return num;
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
stock TE_SetupKillPlayerAttachments(client) {
  TE_Start("KillPlayerAttachments");
  TE_WriteNum("m_nPlayer", client);
}

/// General callback for threaded queries.  No Actions
public SQLWar3GeneralCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
  SQLCheckForErrors(hndl,error,"SQLWar3GeneralCallback");
}

//pass me a trie with key "query" = your query into originalqueryTrie
stock SQLCheckForErrors(Handle:hndl,const String:originalerror[],const String:prependstr[]="",Handle:originalqueryTrie=Handle:0) {
  new String:orignalquerystr[512];
  if(originalqueryTrie) {
    if(!GetTrieString(originalqueryTrie,"query",orignalquerystr,sizeof(orignalquerystr))) {
      LogError("SQLCheckForErrors: originalqueryTrie is not null but key 'query' not set from trie");
    }
    CloseHandle(originalqueryTrie);
    //DP("closed");
  }

  if(!StrEqual("", originalerror))
  LogError("SQL error: [%s] %s QUERY:%s", prependstr, originalerror,orignalquerystr);
  else if(hndl == INVALID_HANDLE)
  {
    decl String:err[512];
    SQL_GetError(hndl, err, sizeof(err));
    LogError("SQLCheckForErrors: [%s] %s QUERY:%s", prependstr, err,orignalquerystr);
  }
}

public bool:SQL_FastQueryLogOnError(Handle:DB,const String:query[]) {
  if(!SQL_FastQuery(DB,query)) {
    new String:error[256];
    SQL_GetError(DB, error, sizeof(error));
    LogError("SQLFastQuery %s failed, Error: %s",query,error);
    return false;
  }
  return true;
}

//normal query like SQL_QUERY, database must be locked 
stock bool:SQL_War3_NormalQuery(Handle:DB,String:querystr[]) {
  new Handle:result= SQL_Query(DB, querystr);
  if(result==INVALID_HANDLE) {
    new String:error[256];
    SQL_GetError(DB, error, sizeof(error));
    LogError("SQL_War3_NormalQuery %s failed, Error: %s",querystr,error);
    return false;
  }
  else {
    CloseHandle(result);
  }
  return true;
}
//fetch using column string
stock W3SQLPlayerInt(Handle:query,const String:columnname[]) //fech from query
{
  new column;
  SQL_FieldNameToNum(query,columnname,column);
  decl String:result[16];
  SQL_FetchString(query,column,result,sizeof(result));
  return StringToInt(result);
}
//fetch using column string
stock W3SQLPlayerFloat(Handle:query,const String:columnname[]) //fech from query
{
  new column;
  SQL_FieldNameToNum(query,columnname,column);
  decl String:result[16];
  SQL_FetchString(query,column,result,sizeof(result));
  return StringToFloat(result);
}
//fetch using column string
stock W3SQLPlayerString(Handle:query,const String:columnname[],String:out_buffer[],size_out) //fech from query
{
  new column;
  if(SQL_FieldNameToNum(query,columnname,column))
  {
    SQL_FetchString(query,column,out_buffer,size_out);
    return true;
  }
  return false;
}

///add a column to table, be careful of parameters
///table should be locked!!!
stock AddColumn(Handle:DB,const String:columnname[],const String:datatype[],const String:table_name[])
{
  decl String:query[256];
  Format(query,256,"ALTER TABLE %s ADD COLUMN %s %s DEFAULT '0'",table_name,columnname,datatype);
  PrintToServer("[War3Source] Tried to ADD column in TABLE %s: %s",table_name,columnname);
  SQL_FastQueryLogOnError(DB,query);
}

///string?


// Stocks

/******
 * Grabs a section of a string based on the "space" token
 * "changerace foo foo2" will return { 1="changerace",  2="foo",3="foo2" }
 * "changerace " will return {1="changerace"}
 * returns false if given tokenum is invalid (0, or 4 in first example)
 *  
 */ 
stock bool:StrToken(const String:inputstr[],tokennum,String:outputstr[],maxlen)
{
  new String:buf[maxlen+1];
  new cur_idx;
  new idx;
  new curind;
  idx=BreakString(inputstr,buf,maxlen); //DELIMTER IS WHITESPACE OR NULL
  if(tokennum==1)
  {
    strcopy(outputstr,maxlen,buf);
    return true;
  }
  curind=1;
  while(idx!=-1)
  {
    cur_idx+=idx;
    //breakstring starts from a different section of the string
    idx=BreakString(inputstr[cur_idx],buf,maxlen);
    curind++;
    if(tokennum==curind)
    {
      strcopy(outputstr,maxlen,buf);
      return true;
    }
  }
  return false;
}

stock StrTokenCount(const String:input[])
{
  decl String:buf[32];
  new cur_idx;
  new idx;
  new curind;
  while(idx!=-1)
  {
    cur_idx+=idx;
    idx=BreakString(input[cur_idx],buf,sizeof(buf));
    curind++;
  }
  return curind;
}

//Grab the front end of a string, separated by delimter, delimiter example string ","
//foo,bar,lol => chopped=foo AND input=bar,lol 
//case sensitive delimiter
//returns false if nothing is found, or end
stock bool:ChopString(String:input[],String:delimiter[],String:chopped[],choppedmaxlen)
{
    new location=StrContains(input,delimiter);
    if(location==0){ //move one, retry
        return ChopString(input[strlen(delimiter)],delimiter,chopped,choppedmaxlen);
    }
    else if(location >0)
    {
        //notice size MinInt(choppedmaxlen,location+1) limits the copy length
        Format(chopped,MinInt(choppedmaxlen,location+strlen(delimiter)),"%s",input);
        Format(input,strlen(input),"%s",input[location+strlen(delimiter)]);
        return true;
    }
    else{ //strcontains returned -1
        //no more delimters found, return whole string if any
        if(strlen(input)){
            strcopy(chopped,choppedmaxlen,input);
            input[0]='\0';
            return true;
        }
        else
        {
            return false;
        }
    }
    
}
stock MinInt(a,b){
    return a>b?b:a;
}
stock Float:GetPlayerDistance(client1,client2) {
  static Float:vec1[3];
  static Float:vec2[3];
  GetClientAbsOrigin(client1,vec1);
  GetClientAbsOrigin(client2,vec2);
  return GetVectorDistance(vec1,vec2);
}

//////MESSAGES


//prints [W3S] You did %d damage to %name with SKILLNAME
//prints [W3S] %name did %d damage to you with SKILLNAME
new String:zzname[32];
stock W3PrintSkillDmgConsole(victim = 0, attacker, damage, skillnum) {
  GetClientName(victim, zzname, sizeof(zzname));
  new race = War3_GetRace(attacker);
  new String:skillname[32];
  SetTrans( attacker);
  W3GetRaceSkillName(race, skillnum, skillname, sizeof(skillname));
  PrintToConsole(attacker, "%T",
      "[W3S] You did +{amount} damage to {player} with {skill}",
      attacker, damage, zzname, skillname);

  if (victim > 0) {
    SetTrans( victim);
    W3GetRaceSkillName(race, skillnum, skillname, sizeof(skillname)); //get trans again
    GetClientName(attacker, zzname, sizeof(zzname));
    PrintToConsole(victim, "%T",
        "[W3S] {player} did {amount} damage to you with {skill}",
        victim, zzname, damage, skillname);
  }
}
//+%d damage with skill name
stock W3PrintSkillDmgHint(victim = 0, attacker, damage, SKILLNUM) {

  new race = War3_GetRace(attacker);
  new String:skillname[32];
  SetTrans( attacker);
  W3GetRaceSkillName(race, SKILLNUM, skillname, sizeof(skillname));

  PrintHintText(attacker, "%T", "+{amount} damage with {skill}", attacker,
      damage, skillname);

  if (victim > 0) {
    SetTrans( victim);
    W3GetRaceSkillName(race, SKILLNUM, skillname, sizeof(skillname));
    PrintHintText(victim, "%T", "Received {amount} damage from {skill}",
        victim, damage, skillname);
  }
}
stock W3PrintSkillDmgHintConsole(victim = 0, attacker, damage, SKILLNUM) {
  W3PrintSkillDmgHint(victim, attacker, damage, SKILLNUM);
  W3PrintSkillDmgConsole(victim, attacker, damage, SKILLNUM);
}

//colored
//prints [war3 tag] You did %d damage to %name with SKILLNAME
//prints [war3 tag] %name did %d damage to you with SKILLNAME
///automatically goes into console
//removed in favor of console and hint
/*
 stock W3PrintSkillDmgChat(victim,attacker,damage,String:skillname[]){
 GetClientName(victim,zzname,sizeof(zzname));
 War3_ChatMessage(attacker,"%T","You did +{amount} damage to {player} with {skill}",attacker,damage,zzname,skillname);
 
 if(victim>0){
 GetClientName(attacker,zzname,sizeof(zzname));
 War3_ChatMessage(victim,"%T","{player} did {amount} damage to you with {skill}",victim,zzname,damage,skillname);
 }
 }
 */

stock W3MsgUltNotLeveled(client) {
  new String:buffer[100];
  Format(buffer, sizeof(buffer), "%T", "Your Ultimate is not leveled", client);
  PrintHintText(client, buffer);
}

stock W3MsgEvaded(victim,attacker){
  PrintHintText(victim,"%T","You Evaded a Shot",victim);
  PrintHintText(attacker,"%T","Enemy Evaded",attacker);
}

stock W3MsgNoTargetFound(client,Float:distancegameunits=0.0) {
  decl String:print[500];
  Format(print,sizeof(print),"%T","No target found",client);
  if(distancegameunits>0.1) {
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
stock W3MsgCreatedWard(client, currentwardcount = 0, totalwardcount = 0) {
  decl String:print[500];
  Format(print, sizeof(print), "%T", "You created a Ward", client);
  if (totalwardcount > 0) {
    Format(print, sizeof(print), "%T",
        "You created a Ward {amount}/{amount}", client,
        currentwardcount, totalwardcount);
  }
  PrintHintText(client, "%s", print);
}
stock W3MsgWardLocationDeny(client) {
  PrintHintText(client, "%T", "You can not build a Ward Here", client);
}
stock W3MsgNoWardsLeft(client) {
  PrintHintText(client, "%T", "You have used up all your Wards!", client);
}
stock W3MsgNoWardWhenInvis(client) {
  PrintHintText(client, "%T", "No Ward Placement While Invisible", client);
}
stock W3MsgEntangle(victim, attacker) {
  PrintHintText(victim, "%T", "You are Entangled!", victim);
  PrintHintText(attacker, "%T", "Entangled!", attacker);
}

stock W3MsgNoCastDuringFreezetime(client) {
  PrintHintText(client, "%T", "Cannot cast during freezetime", client);
}
stock W3MsgSkillBlocked(victim=0,attacker=0,String:skillname[]) {
  if(victim>0) {
    PrintHintText(victim,"%T","Blocked enemy {skill}",victim,skillname);
  }
  if(attacker>0) {
    PrintHintText(victim,"%T","Enemy Blocked {skill}",victim,skillname);
  }
}
stock W3MsgBanished(victim, attacker) {
  PrintHintText(victim, "%T", "You have been Banished", victim);
  PrintHintText(attacker, "%T", "You Banished", attacker);
}
stock W3MsgStoleMoney(victim, attacker, dollars) {
  PrintHintText(victim, "%T", "Enemy stole {dollars} dollars from you",
      victim, dollars);
  PrintHintText(attacker, "%T", "You Stole {dollars} dollars", attacker,
      dollars);
}
stock W3MsgStoleGold(victim, attacker, gold) {
  PrintHintText(victim, "%T", "Enemy stole {gold} gold from you", victim,
      gold);
  PrintHintText(attacker, "%T", "You Stole {gold} gold", attacker, gold);
}
stock W3MsgRevivedBM(playerrevived, savior) {
  new String:clientName[64];
  GetClientName(playerrevived, clientName, sizeof(clientName));
  new String:saviorName[64];
  GetClientName(savior, saviorName, sizeof(saviorName));

  PrintHintText(savior, "%T", "You revived {player}", savior, clientName);
  War3_ChatMessage(playerrevived, "%T", "{player} revived you",
      playerrevived, saviorName);
}
stock W3MsgUsingVoodoo(client) {
  PrintHintText(client, "%T", "Activated Voodoo!", client);
}
stock W3MsgVoodooEnded(client) {
  PrintHintText(client, "%T", "Voodoo has ended", client);
}
stock W3MsgEnemyHasImmunity(client,bool:console=true) {
  PrintHintText(client,"%T","Enemy has immunity!",client);
  PrintToConsole(client,"%T","[W3S] Enemy has immunity!",client);
}
stock W3MsgUltimateNotActivatable(client) {
  PrintHintText(client, "%T", "This ultimate is not activatable", client); //prints
}
stock W3MsgUltimateBlocked(client) {
  PrintHintText(client, "%T", "Ultimate Blocked", client);
}
stock W3MsgThrewKnives(client) {
  PrintHintText(client, "%T", "You threw knives around you", client);
}
stock W3MsgHitByKnives(client) {
  PrintHintText(client, "%T", "Attacked by Fan of Knives", client);
}
stock W3MsgActivated(client,String:postpendstr[]) {
  PrintHintText(client,"%T","Activated {skillname}",client,postpendstr);
}
stock W3MsgAttackedBy(client,String:postpendstr[]) {
  PrintHintText(client,"%T","Attacked By {skillname}",client,postpendstr);
}
stock W3MsgMoleIn(client,Float:timetillactivation) {
  PrintHintText(client,"%T","WARNING! MOLE IN {amount} SECONDS!",client,timetillactivation);
  War3_ChatMessage(client,"%T","WARNING! MOLE IN {amount} SECONDS!",client,timetillactivation);
}
stock W3MsgMoled(client) {
  War3_ChatMessage(client, "%T", "You have moled!", client);
  PrintHintText(client, "%T", "You have moled!", client);
}
stock W3MsgNoLongerDisguised(client) {
  War3_ChatMessage(client, "%T", "You are no longer disguised", client);
  PrintHintText(client, "%T", "You are no longer disguised", client);
}
stock W3MsgVengenceWasBlocked(client,String:reason[]) {
  War3_ChatMessage(client,"%T","Vengence blocked ({reason})",client,reason);
}

native W3IsBuffInvised(client); //returns true if client alpha is <50

//invisible or cloaked?
stock IsInvis(client) {
  return (GameTF() && (TF2_IsPlayerInCondition(client, TFCond_Cloaked)
      || W3IsBuffInvised(client)));
}

/**
 * Prints Message to server and all chat
 * For debugging prints
 */
stock DP(const String:szMessage[], any:...)
{

  decl String:szBuffer[1000];

  VFormat(szBuffer, sizeof(szBuffer), szMessage, 2);
  PrintToServer("[DebugP %d] %s",RoundFloat(GetGameTime())%100, szBuffer);
  PrintToChatAll("[DebugP %d] %s",RoundFloat(GetGameTime())%100, szBuffer);

}
//prring plugin
stock DPP(Plugin:plugin)
{
  new String:szBuffer[1000];
  GetPluginFilename(Handle:plugin, szBuffer,sizeof(szBuffer));
  DP("[Debug PrintP] %s", szBuffer);
}

//First match bases, insensitive
stock Handle:FindPluginByFileCustom(const String:filename[])
{
    decl String:buffer[256];
    
    new Handle:iter = GetPluginIterator();
    new Handle:pl;
    
    while (MorePlugins(iter))
    {
        pl = ReadPlugin(iter);
        
        GetPluginFilename(pl, buffer, sizeof(buffer));
        //DP("%s",buffer);
        if (StrContains(buffer,filename,false)>-1) //not case sensitive
        {
            CloseHandle(iter);
            return pl;
        }
    }
    
    CloseHandle(iter);
    
    return INVALID_HANDLE;
}

stock PrintPlugin(Handle:plugin) {
  new String:str[100];
  GetPluginFilename(Handle:plugin, str, sizeof(str));
  War3_LogInfo("%s",str);
}
stock PrintPluginError(Handle:plugin) {
  new String:str[100];
  GetPluginFilename(Handle:plugin, str, sizeof(str));
  LogError("%s",str);
  War3_LogError("%s",str);
}

///find a "string" in a war3cvar that is delimited by commas "rubbish,string" = true
stock bool:W3FindStringInCvar(cvarid,String:findme[],max=9999) {
  decl String:cvarstr[100];
  decl String:exploded[32][32];

  W3GetCvar(cvarid,cvarstr,sizeof(cvarstr));

  new num;
  if(strlen(cvarstr)>0) {
    num=ExplodeString(cvarstr,",",exploded,256,256);
    for(new i=0;i<num && i<max;i++) {
      //PrintToServer("'%s' compared to: '%s' num%d",exploded[i],itemShort,num);
      if(StrEqual(exploded[i],findme,false)) {
        //PrintToServer("TRUE");
        return true;
      }
    }
  }
  return false;
}

// Picks a random player currently ingame.
stock W3GetRandomPlayer(team,bool:check_alive=false,War3Immunity:check_immunity=Immunity_None) {

  new clients[MaxClients+1], clientCount;
  for (new i = 1; i <= MaxClients; i++)
    if (IsClientInGame(i) && (GetClientTeam(i) == team) && (!check_alive || IsPlayerAlive(i)) && (!W3HasImmunity(i,check_immunity)))
      clients[clientCount++] = i;
  return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}

// Returns true if a and b are the same
stock bool:VectorEquals(const Float:a[3], const Float:b[3])
{
  if(a[0]==b[0] && a[1]==b[1] && a[2]==b[2]) {
    return true;
  }
  return false;
}

// Revan: This was originally a hotfix for sounds in csgo
// it just ClientCommand("playgamesound")..
// Its not required anymore because a more clean fix
// for sounds has been implemented!
// @deprecated This is here for backwards compatibility only.
stock W3EmitSoundToAll(const String:sample[],
    entity = SOUND_FROM_PLAYER,
    channel = SNDCHAN_AUTO,
    level = SNDLEVEL_NORMAL,
    flags = SND_NOFLAGS,
    Float:volume = SNDVOL_NORMAL,
    pitch = SNDPITCH_NORMAL,
    speakerentity = -1,
    Float:origin[3] = NULL_VECTOR,
    const Float:dir[3] = NULL_VECTOR,
    bool:updatePos = true,
    Float:soundtime = 0.0)
{
  EmitSoundToAllAny(sample,entity,channel,level,flags,volume,pitch,speakerentity,origin,dir,updatePos,soundtime);
}

/**
 * Returns UNIX time (integer)
 */
stock NOW() {
  return GetTime();
}
/**
 * returns the larger integer of the two
 */
stock IntMax(one, two) {
  return one > two ? one : two;
}

//what we want is something that always increments even past map changes
//not intended to matter of game pauses or not (tick)
stock Float:AbsoluteTime() {
  return GetEngineTime();
}

stock CreateTimer_DEBUG(any:f=0,any:ff=0,any:fff=0,any:ffff=0) {}


// PUT THIS WHERE IT MAKES SENSE SOMETIME

//check race limit and force re-choose race
stock CheckRaceTeamLimit(raceid, team){

  new Float:youngest=-1.0;
  new target=0;
  for(new i=1;i<=MaxClients;i++){
    if(ValidPlayer(i))
    {
      if(War3_GetRace(i)==raceid&&!W3IsDeveloper(i))
      {
        if(GetClientTeam(i)==team)
        {
          if(W3GetPlayerProp(i,LastChangeTeamTime)>youngest){
            target=i;
            youngest=W3GetPlayerProp(i,LastChangeTeamTime);
          }
        }
      }
    }
  }
  if(target>0){
    War3_SetRace(target,0);
    new String:racename[64];
    War3_GetRaceName(raceid,racename,sizeof(racename));
    War3_ChatMessage(target,"%T","{race} race team limit has reached (MAX {amount}), please select a different race",target,racename,W3GetRaceMaxLimitTeam(raceid,team));
    PrintToConsole(target,"Your race has been set via raceutils.inc");
    new cvar=W3GetRaceMaxLimitTeamCvar(raceid,team);
    new String:cvarstr[64];
    if(cvar>-1){
      W3GetCvarActualString(cvar,cvarstr,sizeof(cvarstr));
    }
    cvar=W3FindCvar(cvarstr);
    new String:cvarvalue[64];
    if(cvar>-1){
      W3GetCvar(cvar,cvarvalue,sizeof(cvarvalue));
    }
    
    War3_LogInfo("race %s blocked on client %d due to restrictions limit %d (CheckRaceTeamLimit)  %s %s",racename,target,W3GetRaceMaxLimitTeam(raceid,team),cvarstr,cvarvalue);
    
    W3CreateEvent(DoShowChangeRaceMenu,target);
  }
}

/**
 * Extends the path to a sound clip with the correct prefix
 */
stock War3_AddSoundFolder(String:sBaseString[], maxlength, String:sSoundFile[])
{
  Format(sBaseString, maxlength, "war3source/%s", sSoundFile);
  
  War3_LogInfo("Constructed sound path: \"%s\"", sBaseString);
}

/**
 * Get the hint sound effect for the current game
 */
stock War3_GetHintSound(String:sSoundFile[], maxlength)
{
  if(GAMECSGO)
  {
    strcopy(sSoundFile, maxlength, "music/war3source/csgo/ui/hint.mp3");
  }
  else if(GAMEFOF)
  {
    strcopy(sSoundFile, maxlength, "war3source/csgo/ui/hint.mp3");
  }
  else
  {
    strcopy(sSoundFile, maxlength, "UI/hint.wav");
  }
}

#include "W3SIncs/War3Source_L4D_Interface"
#include "W3SIncs/War3Source_CS_Interface"
#include "W3SIncs/War3Source_TF2_Interface"
#include "W3SIncs/War3Source_Notifications"
#include "W3SIncs/War3Source_Health"
#include "W3SIncs/War3Source_SkillEffects"
#include "W3SIncs/War3Source_Shopitems"
#include "W3SIncs/War3Source_Buffs"
#include "W3SIncs/War3Source_XP_Gold"
#include "W3SIncs/War3Source_Config"
#include "W3SIncs/War3Source_Attributes"
#include "W3SIncs/War3Source_AttributeBuffs"
#include "W3SIncs/War3Source_Events"
#include "W3SIncs/War3Source_Currency"
#include "W3SIncs/War3Source_Effects"
#include "W3SIncs/War3Source_PrecacheDownload"
#include "W3SIncs/War3Source_Shopitems2"


/*
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*   - BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-- BACKWARDS COMPATIBILITY-
*/

/**
 * Backwards compatibility for the precaches of a given sound.
 *
 * @param sound     Name of the sound to download and precache.
 * @param precache    If precache is true the file will be precached.
 * @param preload   If preload is true the file will be precached before level startup.
 * 
 * @return True if successfully precached, false otherwise.
 */

stock bool:War3_PrecacheSound(String:sound[])
{
  new String:longsound[512];
  Format(longsound,sizeof(longsound), "sound/%s", sound);

  if(PrecacheSound(sound, true)){
    //PrintToServer("TWar3_PrecacheSound %s",longsound);
    return true;
  }
  else{
    PrintToServer("Fail War3_PrecacheSound %s",longsound);  
  }
  return false;
}

// For Shopmenu 2
stock War3_GetDiamonds(client) {
  return W3GetPlayerProp(client, PlayerDiamonds);
}
// For Shopmenu 2
stock War3_SetDiamonds(client, newd) {
  W3SetPlayerProp(client, PlayerDiamonds, newd);
}