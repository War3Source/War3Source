/**
 * File: War3Source_Interface.inc
 * Description: The file to be included for creating races and whatnot.
 * Author(s): Anthony Iacono  
 * 
 * 
 * LISTS NATIVES AND FORWARDS, BUT NOT ACTUALLY DEFINES THE CODE
 */

#include <sdktools>

#include "W3SIncs/constants"
#include "W3SIncs/colors"
#include "W3SIncs/aura"
#include "W3SIncs/War3Source_Effects"
//sh include is at the end of this file


//Interface version, change this when the API requirement changes to force a recompile
//There will be a system check to make sure all plugins are compiled to the same interface.
new String:interfaceVersion[]="1.2.2.1";


stock dummy; //variable for dummies! Use this where ever u want for a dummy return
stock String:dummystr[32]; //just a dummy string! 

/**********************
 * CAUTION, THE War3 INTERFACE NOW HANDLES AskPluginLoad2Custom BECAUSE IT IS REQUIRED TO HANDLE CERTAIN TASKS
 * It acually simplifies things for you:
 * Determines game mode
 * Mark Natives optional
 * Calls your own functions (hackish way) if you have them:
 * InitNativesForwards()   
 * AskPluginLoad2CustomCustom(Handle:myself,bool:late,String:error[],err_max);
 * So if you want to do something in AskPluginLoad2, implement public AskPluginLoad2Custom(...) instead. 
 */ 
public APLRes:AskPluginLoad2(Handle:plugin,bool:late,String:error[],err_max)
{
	GlobalOptionalNatives();
	DetermineGameMode();
	new Function:func;
	func=GetFunctionByName(plugin, "InitNativesForwards");
	if(func!=INVALID_FUNCTION){ //non war3 plugins dont have this function
		Call_StartFunction(plugin, func);
		Call_Finish(dummy);
		if(!dummy){
			LogError("InitNativesForwards did not return true, possible failure");
		}
	}
	func=GetFunctionByName(plugin, "AskPluginLoad2Custom");
	if(func!=INVALID_FUNCTION){ //non war3 plugins dont have this function
		Call_StartFunction(plugin, func);
		Call_PushCell(plugin);
		Call_PushCell(late);
		Call_PushString(error);
		Call_PushCell(err_max);
		Call_Finish(dummy);
		if(APLRes:dummy==APLRes_SilentFailure){
			return APLRes_SilentFailure;
		}
		if(APLRes:dummy!=APLRes_Success){
			LogError("AskPluginLoad2Custom did not return true, possible failure");
		}
	}
	
	//do not load if these functions exists
	if(GetFunctionByName(plugin, "W3ONLY")!=INVALID_FUNCTION  &&  !W3()){
		return APLRes_SilentFailure;
	}
	if(GetFunctionByName(plugin, "SHONLY")!=INVALID_FUNCTION  &&  !SH()){
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}
/**********************
 * Implement this if you have natives/forwards
 */ 
forward bool:InitNativesForwards();

/**********************
 * Implement this if you need AskPluginLoad2Custom
 */ 
forward APLRes:AskPluginLoad2Custom(Handle:plugin,bool:late,String:error[],err_max);

/**********************
 * Implement this with blank statement if you want this plugin to not load if it is not war3 mode
 */ 
forward W3ONLY();

/**********************
 * Implement this with blank statement if you want this plugin to not load if it is not sh mode
 */ 
forward SHONLY();




//variables forwarded to every w3 plugin
new W3ForwarededVars[W3ForwardedVarsEnum];
public W3SetForwarededVar(index,value){
	//DP("forwarded %d %d",index,value);
	W3ForwarededVars[index]=value;
}
stock EXT(){
	return W3ForwarededVars[EXTAvailable];
}

//INTERFACE ONLY VARIABLES, use for determining game type
stock tValveGame;
stock bool:bWar3Mode;
stock bool:bSHMode;
stock W3(){
	return bWar3Mode;
}
stock SH(){
	return bSHMode;
}
stock ValveGameEnum:War3_GetGame(){
	return ValveGameEnum:tValveGame;
}

//Do not manually call this, this determines the game mode and is called internally in the API
stock DetermineGameMode(){
	//DETERMIE GAME MODE
	#if defined WAR3MAIN
	PrintToServer("[SH] READING shsourcemode.cfg trying to find 'shsource' in the file");
	#endif
	new Handle:file=OpenFile("cfg/shsourcemode.cfg", "a+"); //creates new file if one not exists
	
	bWar3Mode=true; //default
	bSHMode=false; //default
	new String:buffer[256];
	while (ReadFileLine(file, buffer, sizeof(buffer)))
	{
		if(strncmp(buffer, "shsource",strlen( "shsource"), false)==0){
			bWar3Mode=false;
			bSHMode=true;
			#if defined WAR3MAIN
			PrintToServer("[SH] SHSource MODE ENABLED");
			#endif
			break;
		}
	}
	CloseHandle(file);
	#if defined WAR3MAIN
	PrintToServer("[SH] FINISHED READING shsourcemode.cfg");
	#endif
	
	


	//DETERMINE GAME TYPE: CS TF ETC
	new String:gameDir[64];
	GetGameFolderName(gameDir,sizeof(gameDir));
	if(StrContains(gameDir,"cstrike",false)==0)
	{
		tValveGame=_:Game_CS;
		#if defined WAR3MAIN
		PrintToServer("[War3Source] Game set: Counter-Strike Source ValveGame %d",tValveGame);
		#endif
		ServerCommand("sv_allowminmodels 0");
	}
	else if(StrContains(gameDir,"dod",false)==0)
	{
		#if defined WAR3MAIN
		PrintToServer("[War3Source] Game set: Day of Defeat Source (ONLY DEVELOPER SUPPORT!)");
		#endif
		tValveGame=_:Game_DOD;
	}
	else if(StrContains(gameDir,"tf",false)==0)
	{
		#if defined WAR3MAIN
		PrintToServer("[War3Source] Game set: Team Fortress 2");
		#endif
		tValveGame=_:Game_TF;
	}
	else if(StrContains(gameDir,"left4dead2",false)==0)
	{
		#if defined WAR3MAIN
		PrintToServer("[War3Source] Game set: Left 4 Dead 2");
		#endif
		tValveGame=_:Game_L4D2;
	}
	else if(StrContains(gameDir,"left4dead",false)==0)
	{
		#if defined WAR3MAIN
		PrintToServer("[War3Source] Game set: Left 4 Dead");
		#endif
		tValveGame=_:Game_L4D;
	}
	else
	{
		SetFailState("[War3Source] Sorry, this game isn't support by War3Source yet. If you think this is a mistake, you probably renamed your game directory. For example, re-naming cstrike to cstrike2 will cause this error. (folder name: %s)", gameDir);
	}
	//bGameModeDetermined=true;
}
stock GameCS(){
	return War3_GetGame()==Game_CS;
}
stock GameTF(){
	return War3_GetGame()==Game_TF;
}

stock GameL4D1(){
	return (War3_GetGame() == Game_L4D);
}

stock GameL4D2(){
	return ( War3_GetGame() == Game_L4D2);
}

stock GameL4DAny(){
	return (War3_GetGame() == Game_L4D || War3_GetGame() == Game_L4D2);
}
//We mark some natives optional so different plugins can still startup
/**********************
 * CALL THIS IN ASKPLUGINLOAD if you are using any of these or have native errors
 */ 
stock GlobalOptionalNatives(){
	MarkNativeAsOptional("SHHasHero"); 
	MarkNativeAsOptional("SHGetHeroesClientCanHave"); 
	MarkNativeAsOptional("SHHasHero"); 
	
	MarkNativeAsOptional("W3GetReqXP");
	MarkNativeAsOptional("SHGetReqXP");
	
	MarkNativeAsOptional("War3_ShowXP");
	MarkNativeAsOptional("SHShowXP");
	
	MarkNativeAsOptional("W3SaveXP");
	MarkNativeAsOptional("SHSaveXP");
	
	MarkNativeAsOptional("War3Failed"); 
	
	///omfg
	MarkNativeAsOptional("SHHasHero");
	MarkNativeAsOptional("SHSetHasHero");
	MarkNativeAsOptional("SHGetHeroHasPowerBind");
	MarkNativeAsOptional("SHSetHeroHasPowerBind");
	MarkNativeAsOptional("SHGetLevel");
	MarkNativeAsOptional("SHSetLevel");
	MarkNativeAsOptional("SHGetXP");
	MarkNativeAsOptional("SHSetXP");
	MarkNativeAsOptional("SHShowXP");
	MarkNativeAsOptional("SHGetReqXP");
	MarkNativeAsOptional("SHGetHeroesClientCanHave");
	MarkNativeAsOptional("SHGetPowerBind");
	MarkNativeAsOptional("SHSetPowerBind");
	MarkNativeAsOptional("SHMaxLevel");
	MarkNativeAsOptional("SHSaveXP");
	MarkNativeAsOptional("SHTryToGiveClientHero");
	MarkNativeAsOptional("OurTestNative");
	MarkNativeAsOptional("OurTestNative2");
	MarkNativeAsOptional("W3ExtVersion");
	MarkNativeAsOptional("W3ExtTestFunc");
	MarkNativeAsOptional("W3GetW3Version");
	MarkNativeAsOptional("W3GetW3Revision");
	MarkNativeAsOptional("W3GetStatsVersion");
	MarkNativeAsOptional("W3Socket");
	MarkNativeAsOptional("W3Socket2");
	MarkNativeAsOptional("W3DropWeapon");
	MarkNativeAsOptional("War3_InFreezeTime");
	MarkNativeAsOptional("War3_CreateNewRace");
	MarkNativeAsOptional("War3_AddRaceSkill");
	MarkNativeAsOptional("War3_CreateNewRaceT");
	MarkNativeAsOptional("War3_AddRaceSkillT");
	MarkNativeAsOptional("War3_CreateRaceEnd");
	MarkNativeAsOptional("War3_GetRaceName");
	MarkNativeAsOptional("War3_GetRaceShortname");
	MarkNativeAsOptional("W3GetRaceString");
	MarkNativeAsOptional("W3GetRaceSkillString");
	MarkNativeAsOptional("War3_GetRacesLoaded");
	MarkNativeAsOptional("W3GetRaceMaxLevel");
	MarkNativeAsOptional("War3_IsSkillUltimate");
	MarkNativeAsOptional("War3_GetRaceSkillCount");
	MarkNativeAsOptional("W3GetRaceSkillName");
	MarkNativeAsOptional("W3GetRaceSkillDesc");
	MarkNativeAsOptional("W3GetRaceSkillMaxLevel");
	MarkNativeAsOptional("W3GetRaceOrder");
	MarkNativeAsOptional("W3RaceHasFlag");
	MarkNativeAsOptional("W3GetRaceList");
	MarkNativeAsOptional("War3_GetRaceIDByShortname");
	MarkNativeAsOptional("W3GetRaceAccessFlagStr");
	MarkNativeAsOptional("W3GetRaceItemRestrictionsStr");
	MarkNativeAsOptional("W3GetRaceMaxLimitTeam");
	MarkNativeAsOptional("W3GetRaceMaxLimitTeamCvar");
	MarkNativeAsOptional("W3GetRaceMinLevelRequired");
	MarkNativeAsOptional("W3IsRaceTranslated");
	MarkNativeAsOptional("W3GetVar");
	MarkNativeAsOptional("W3SetVar");
	MarkNativeAsOptional("War3_CreateShopItem");
	MarkNativeAsOptional("War3_CreateShopItemT");
	MarkNativeAsOptional("War3_SetItemProperty");
	MarkNativeAsOptional("War3_GetItemProperty");
	MarkNativeAsOptional("War3_GetItemIdByShortname");
	MarkNativeAsOptional("W3GetItemName");
	MarkNativeAsOptional("W3GetItemShortname");
	MarkNativeAsOptional("W3GetItemDescription");
	MarkNativeAsOptional("W3GetItemCost");
	MarkNativeAsOptional("W3GetItemOrder");
	MarkNativeAsOptional("W3ItemHasFlag");
	MarkNativeAsOptional("W3GetItemCatagory");
	MarkNativeAsOptional("W3GetItemsLoaded");
	MarkNativeAsOptional("W3IsItemDisabledGlobal");
	MarkNativeAsOptional("W3IsItemDisabledForRace");
	MarkNativeAsOptional("War3_CreateShopItem2");
	MarkNativeAsOptional("War3_CreateShopItem2T");
	MarkNativeAsOptional("War3_SetItem2Property");
	MarkNativeAsOptional("War3_GetItem2Property");
	MarkNativeAsOptional("War3_GetItem2IdByShortname");
	MarkNativeAsOptional("W3CreateShopItem2");
	MarkNativeAsOptional("W3GetItem2Name");
	MarkNativeAsOptional("W3GetItem2Shortname");
	MarkNativeAsOptional("W3GetItem2Description");
	MarkNativeAsOptional("W3GetItem2Cost");
	MarkNativeAsOptional("W3GetItem2Order");
	MarkNativeAsOptional("W3Item2HasFlag");
	MarkNativeAsOptional("W3GetItem2Catagory");
	MarkNativeAsOptional("W3GetItems2LoadedEXT");
	MarkNativeAsOptional("W3IsItem2DisabledGlobal");
	MarkNativeAsOptional("W3IsItem2DisabledForRace");
	MarkNativeAsOptional("W3SaveItem2ExpireTime");
	MarkNativeAsOptional("War3_CreateHelpCommand");
	MarkNativeAsOptional("W3GetLevelsSpent");
	MarkNativeAsOptional("W3ClearSkillLevels");
	MarkNativeAsOptional("W3GetKillXP");
	MarkNativeAsOptional("W3GetReqXP");
	MarkNativeAsOptional("War3_ShowXP");
	MarkNativeAsOptional("W3GetMaxGold");
	MarkNativeAsOptional("War3_GetOwnsItem");
	MarkNativeAsOptional("War3_GetOwnsItem2");
	MarkNativeAsOptional("W3GetItem2ExpireTime");
	MarkNativeAsOptional("W3SetItem2ExpireTime");
	MarkNativeAsOptional("War3_SetOwnsItem");
	MarkNativeAsOptional("War3_SetOwnsItem2");
	MarkNativeAsOptional("War3_GetTargetInViewCone");
	MarkNativeAsOptional("W3LOS");
	MarkNativeAsOptional("War3_DealDamage");
	MarkNativeAsOptional("War3_GetWar3DamageDealt");
	MarkNativeAsOptional("W3GetDamageIsBullet");
	MarkNativeAsOptional("W3ForceDamageIsBullet");
	MarkNativeAsOptional("W3GetDamageStack");
	MarkNativeAsOptional("W3FlashScreen");
	MarkNativeAsOptional("War3_ShakeScreen");
	MarkNativeAsOptional("War3_SpawnPlayer");
	MarkNativeAsOptional("War3_CachedAngle");
	MarkNativeAsOptional("War3_CachedPosition");
	MarkNativeAsOptional("War3_CachedDucking");
	MarkNativeAsOptional("War3_CachedWeapon");
	MarkNativeAsOptional("War3_CachedClip1");
	MarkNativeAsOptional("War3_CachedAmmo");
	MarkNativeAsOptional("War3_CachedDeadClip1");
	MarkNativeAsOptional("War3_CachedDeadAmmo");
	MarkNativeAsOptional("War3_CachedDeadWeaponName");
	MarkNativeAsOptional("War3_IsUbered");
	MarkNativeAsOptional("War3_HasFlag");
	MarkNativeAsOptional("War3_IsCloaked");
	MarkNativeAsOptional("War3_DamageModPercent");
	MarkNativeAsOptional("War3_TF_ParticleToClient");
	MarkNativeAsOptional("War3_HealToMaxHP");
	MarkNativeAsOptional("War3_HealToBuffHP");
	MarkNativeAsOptional("War3_DecreaseHP");
	MarkNativeAsOptional("War3_CooldownMGR");
	MarkNativeAsOptional("W3SkillCooldownOnSpawn");
	MarkNativeAsOptional("War3_CooldownRemaining");
	MarkNativeAsOptional("War3_CooldownReset");
	MarkNativeAsOptional("War3_SkillNotInCooldown");
	MarkNativeAsOptional("War3_PrintSkillIsNotReady");
	MarkNativeAsOptional("War3_SetBuff");
	MarkNativeAsOptional("War3_SetBuffItem");
	MarkNativeAsOptional("War3_SetBuffItem2");
	MarkNativeAsOptional("W3ApplyBuffSimple");
	MarkNativeAsOptional("W3ResetBuffRace");
	MarkNativeAsOptional("W3ResetAllBuffRace");
	MarkNativeAsOptional("W3GetBuff");
	MarkNativeAsOptional("W3GetBuffHasTrue");
	MarkNativeAsOptional("W3GetBuffStackedFloat");
	MarkNativeAsOptional("W3GetBuffSumFloat");
	MarkNativeAsOptional("W3GetBuffMinFloat");
	MarkNativeAsOptional("W3GetBuffMaxFloat");
	MarkNativeAsOptional("W3GetBuffMinInt");
	MarkNativeAsOptional("War3_RegisterDelayTracker");
	MarkNativeAsOptional("War3_TrackDelay");
	MarkNativeAsOptional("War3_TrackDelayExpired");
	MarkNativeAsOptional("War3_GetAimEndPoint");
	MarkNativeAsOptional("War3_GetAimTraceMaxLen");
	MarkNativeAsOptional("War3_WeaponRestrictTo");
	MarkNativeAsOptional("W3GetPhysicalArmorMulti");
	MarkNativeAsOptional("W3GetMagicArmorMulti");
	MarkNativeAsOptional("W3GetCurrentWeaponEnt");
	MarkNativeAsOptional("W3GetMinUltLevel");
	MarkNativeAsOptional("War3Failed");
	MarkNativeAsOptional("W3GetDamageType");
	MarkNativeAsOptional("W3GetDamageInflictor");
	MarkNativeAsOptional("W3ChanceModifier");
	MarkNativeAsOptional(" W3Hint");
	MarkNativeAsOptional("War3_GetRace");
	MarkNativeAsOptional("War3_SetRace");
	MarkNativeAsOptional("War3_SetLevel");
	MarkNativeAsOptional("War3_GetLevel");
	MarkNativeAsOptional("W3GetTotalLevels");
	MarkNativeAsOptional("W3GetLevelBank");
	MarkNativeAsOptional("W3SetLevelBank");
	MarkNativeAsOptional("War3_SetXP");
	MarkNativeAsOptional("War3_GetXP");
	MarkNativeAsOptional("War3_SetSkillLevel");
	MarkNativeAsOptional("War3_GetSkillLevel");
	MarkNativeAsOptional("W3SetPlayerProp");
	MarkNativeAsOptional("W3GetPlayerProp");
	MarkNativeAsOptional("W3GiveXPGold");
	MarkNativeAsOptional("W3CreateCvar");
	MarkNativeAsOptional("W3GetCvar");
	MarkNativeAsOptional("W3SetCvar");
	MarkNativeAsOptional("W3FindCvar");
	MarkNativeAsOptional("W3CvarList");
	MarkNativeAsOptional("W3GetCvarByString");
	MarkNativeAsOptional("W3GetCvarActualString");
	MarkNativeAsOptional("W3IsDeveloper");
	MarkNativeAsOptional("W3SaveEnabled");
	MarkNativeAsOptional("W3SaveXP");
	MarkNativeAsOptional("W3Log");
	MarkNativeAsOptional("W3LogError");
	MarkNativeAsOptional("W3LogNotError");
	MarkNativeAsOptional("CreateWar3GlobalError");
	MarkNativeAsOptional("W3CreateEvent");
	
	MarkNativeAsOptional("War3_SetDiamondsEXT");
	MarkNativeAsOptional("War3_GetDiamondsEXT");
	MarkNativeAsOptional("War3_GetOwnsItem2EXT");
	MarkNativeAsOptional("War3_SetOwnsItem2EXT");
	
	// L4D
	MarkNativeAsOptional("War3_L4D_IsHelpless");

}

//Warcraft required executions, does common tasks, such as loading translations.
forward War3InterfaceExec();
public War3InterfaceExec(){ 
	LoadTranslations("w3s._common.phrases");
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

//Socket functions
native W3Socket(String:url[],Function:callback);
native W3Socket2(String:url[],String:postdata[],Function:callback);

//forces weapon drop, given a weapon entity
native W3DropWeapon(client,weaponent);


/**
 * Checks if we are in the freeze time. Certain games support this, like CS.
 * @return True if so, false if not.
 *  
 */
#pragma deprecated
native bool:War3_InFreezeTime();    



/* BEGIN Race Class */

//creates a new race, returns the race id
//a valid race is >0
native War3_CreateNewRace(String:name[],String:shortname[]);

//adds a skill or a ultimate
native War3_AddRaceSkill(raceid,String:tskillorultname[],String:tskillorultdescription[],bool:isult,maxskilllevel=DEF_MAX_SKILL_LEVEL);


//translated
//creates a new race, returns the race id
native War3_CreateNewRaceT(String:shortname[]);

//translated
//adds a skill or a ultimate
//additional parameters replaces #1# #2# ... in the translation string (max 5)
native War3_AddRaceSkillT(raceid,String:SkillNameIdentifier[],bool:isult,maxskilllevel=DEF_MAX_SKILL_LEVEL,any:...);

//ends race creation!!! MUST CALL THIS!!!
native War3_CreateRaceEnd(raceid);

native War3_GetRaceName(raceid,String:retstr[],maxlen);
native War3_GetRaceShortname(raceid,String:retstr[],maxlen);

#pragma deprecated Not Fully Implemented, possibly in the future
native W3GetRaceString(raceid,RaceString:property,String:retstr[],maxlen);
#pragma deprecated Not Fully Implemented, possibly in the future
native W3GetRaceSkillString(raceid,skillnum,SkillString:property,String:retstr[],maxlen);

native War3_GetRacesLoaded();
native W3GetRaceMaxLevel(race);

native War3_IsSkillUltimate(raceid,skillnum);
native War3_GetRaceSkillCount(raceid);
native W3GetRaceSkillName(raceid,skillindex,String:retstr[],maxlen);
native W3GetRaceSkillDesc(raceid,skillindex,String:retstr[],maxlen);
native W3GetRaceSkillMaxLevel(raceid,skillnum);
native W3GetRaceOrder(raceid);
//Flag is a generic string. We compare the race_flags cvar to the string you passed
native bool:W3RaceHasFlag(raceid,String:flag[]);

//returns a simple array of race IDs, sorted properly.
//Does not include "hidden" races
//pass array of MAXRACES, returns number of races in the array. starts at 0
//ordered properly
//returns the size of the array
native W3GetRaceList(racelist[]);

//a valid race is >0
native War3_GetRaceIDByShortname(String:raceshortname[]);

native W3GetRaceAccessFlagStr(raceid,String:ret[],maxlen);
native W3GetRaceItemRestrictionsStr(raceid,String:ret[],maxlen);
native W3GetRaceMaxLimitTeam(raceid,team);
native W3GetRaceMaxLimitTeamCvar(raceid,team); //returns the internal cvar id (int not handle)
native W3GetRaceMinLevelRequired(raceid);
native W3IsRaceTranslated(raceid);

/* END RACE CLASS */





/* BEGIN GLOBAL VARS */
//retrieves specified values from the main war3 plugin, see W3Var enum in constants.inc, only those values are allowed
//this mostly used for accessing a variable without creating a special native just for it
//this returns any:, you should tag it if return value is not suppose to be normal integer. like Float:W3GetVar( or Handle:W3GetVar(
//most are temporary variables and this function should be called immidiately in the right functions
//examples W3GetVar(OldRace)   W3GetVar(DeathRace)
//See W3Var enum in constants to get a list
//Do not get/set vars arbitrarily unless you know what you are doing
native any:W3GetVar(W3Var:variabletoretrieve);
native any:W3SetVar(W3Var:variabletoretrieve,any:value);
/* END GLOBAL VARS */


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

//see W3ItemProp enum for available properties
native War3_SetItemProperty(itemid,W3ItemProp:ITEM_PROPERTY,value);
native War3_GetItemProperty(itemid,W3ItemProp:ITEM_PROPERTY);


//remember itemid that is valid is more than 0
//returns -1 if not found
native War3_GetItemIdByShortname(String:itemshortname[]) ;


native W3GetItemName(itemid,String:ret[],maxlen);
native W3GetItemShortname(itemid,String:ret[],maxlen);
native W3GetItemDescription(itemid,String:ret[],maxlen);

native W3GetItemCost(itemid,bool:csmoney);
native W3GetItemOrder(itemid);
native W3ItemHasFlag(itemid,String:flagsearch[]);
native W3GetItemCatagory(itemid,String:retcatagorystr[],maxlen);
native W3GetItemsLoaded(); //how many items are loaded?

native bool:W3IsItemDisabledGlobal(itemid);
native bool:W3IsItemDisabledForRace(race,itemid);



//Shopmenu 2 item class
native War3_CreateShopItem2(String:name[],String:shortname[],String:desc[],cost);
native W3CreateShopItem2(String:name[],String:shortname[],String:desc[],cost,translated);
//translated
native War3_CreateShopItem2T(String:shortname[],cost);

native War3_SetItem2Property(itemid,W3ItemProp:ITEM_PROPERTY,value);
native War3_GetItem2Property(itemid,W3ItemProp:ITEM_PROPERTY);

//returns -1 if not found
//valid itemid if > 0
native War3_GetItem2IdByShortname(String:itemshortname[]) ;


native W3GetItem2Name(itemid,String:ret[],maxlen);
native W3GetItem2Shortname(itemid,String:ret[],maxlen);
native W3GetItem2Description(itemid,String:ret[],maxlen);

native W3GetItem2Cost(itemid);
native W3GetItem2Order(itemid);
native W3Item2HasFlag(itemid,String:flagsearch[]);
native W3GetItem2Catagory(itemid,String:retcatagorystr[],maxlen);
native W3GetItems2LoadedEXT();
stock W3GetItems2Loaded(){ //how many items are loaded?
	return EXT()?W3GetItems2LoadedEXT():0;
}

native bool:W3IsItem2DisabledGlobal(itemid);
native bool:W3IsItem2DisabledForRace(race,itemid);

native W3ExtShowShop2(client);

//Forces a save into database of when the item expires
//client must own item already
native W3SaveItem2ExpireTime(client,itemid);

native GetClientItemsOwned(client);
native GetMaxShopitemsPerPlayer();





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
 * Gets the kill XP for a player depending on his CURRENT level 
 * @param client: Client index
 * adds extra xp per leveldifference if cvar is configured
 */
native W3GetKillXP(client,leveldifference=0);
native W3GetReqXP(level); //get required xp for leveling to the level, use (level+1) for xp required for next level

native W3GetKillGold();
native W3GetAssistGold();

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
native War3_SetOwnsItem(client,item,bool:ownsitem);

native W3GetItem2ExpireTime(client,item);
native W3SetItem2ExpireTime(client,item,time); //use full linux time , ie: NOW()+duration



/**
 * Sets if the player owns a specific item.
 * @param client: Client index
 * @param item: The item ID returned from War3_CreateShopItem
 * @param owns: 1 if you want them to own it, 0 if you want them not to own it 
 * @noreturn
 * 
 *	ITEM IS NOT LOST AUTOMATICALLY ON DEATH  
 */

native War3_GetOwnsItem2EXT(client,item);

native War3_SetOwnsItem2EXT(client,item,bool:ownsitem);
stock War3_GetOwnsItem2(client,item){
	if(EXT()){
		return War3_GetOwnsItem2EXT(client,item);
	}
	return 0;
}
stock War3_SetOwnsItem2(client,item,bool:ownsitem){
	if(EXT()){
		War3_SetOwnsItem2EXT(client,item,bool:ownsitem);
	}
}




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
 * @return bool: did damage go through, false if player was immune to that damage type or damage was zero or something else failed
 */
native bool:War3_DealDamage(victim,damage,attacker=0,damage_type=DMG_GENERIC,String:weaponNameStr[],    War3DamageOrigin:W3DMGORIGIN=W3DMGORIGIN_UNDEFINED  ,   War3DamageType:W3DMGTYPE=W3DMGTYPE_MAGIC  ,  bool:respectVictimImmunity=true   ,   bool:countAsFirstDamageRetriggered=false);       

//get the actual damage dealt from War3_DealDamage, because real damage is different after taking account to magic/physical armor
//u wana call this immediately after War3_DealDamage cuz this is a single global variable. when someone else calls War3_DealDamage it will be changed
native War3_GetWar3DamageDealt();


///is last damage a bullet first triggered damage? works on posthurt and dmgall
native W3GetDamageIsBullet();

native W3ForceDamageIsBullet();
// if u do damage within a takedmg, the original damage may be nullified as non bullet, 
//use this function after you have dealt damage inside a takedmg
//so you can allow other isdmgbullet proc

//get the depth of the damage stack, usually 1 or more
native W3GetDamageStack();


/**
 * Flashes a player's screen a certain color for a duration.
 * @param client: Client's index.
 * @param color[4]: RGBA value of the color, see above for presets.
 * @param duration: Length of flash, optional.
 * @param flags: Flags of Fade user message, optional.
 * @noreturn
 */
native W3FlashScreen(client,color[4],Float:holdduration=0.1,Float:fadeduration=0.2,flags=FFADE_IN);



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

//Sends a particle to client like "miss_text"
native War3_TF_ParticleToClient(clienttoshowto,String:particlestr[],Float:pos[3]);  

/**
 * heals with the limit of (warcraft ) max hp
 * @noreturn
 */  
native War3_HealToMaxHP(client,addhp);  

/**
 * heals to max hp * 1.5 buff in tf2
 * no extra hp in other games 
 * @noreturn
 */  
native War3_HealToBuffHP(client,addhp);  

/** 
 * direcly decreases the player's hp by X amount (Not via damage)
 * //WILL NOT GO BELOW 1 (cs glitch)
 */
native War3_DecreaseHP(client,decrease);

stock Entity_SetHealth(entity, health)
{
	SetEntProp(entity, Prop_Data, "m_iHealth", health);
	ChangeEdictState(entity, 0);
}









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
native War3_CooldownMGR(client,Float:cooldownTime,raceid,skillNum,         bool:resetOnSpawn=true,bool:printMsgOnExpireByTime=true);  

//tells the cooldown manager to create a predefined cooldown time when player spawns with that race. 
//cooldown is created regardless of resetOnSpawn in War3_CooldownMGR(...) calls
//only prints expired if client remains that race
//set this ONCE when u register your skills
native W3SkillCooldownOnSpawn(raceid,skillnum,Float:cooldownTime,bool:printmsgonexpire=true);

/**
 * how much time is left on this particular cooldown?
 * returns an int (rounted up from the float)
 */  
native War3_CooldownRemaining(client,raceid,skillNum);  


/**
 * basically make this cooldown expire, this expiration is not considered "by time"
 */  
native War3_CooldownReset(client,raceid,skillNum);  


/**
 * is this skill NOT in COOLDOWN? YOU NEED TO CHECK IF CLIENT HAS LEVELED THIS SKILL FIRST, THIS IS ONLY COOLDOWN RELATED
 * you would only do this if this skill has a cooldown and u called War3_CooldownMGR
 * printTextIfNotReady=true will print a "not ready" message
 */  
native bool:War3_SkillNotInCooldown(client,raceid,skillNum,bool:printTextIfNotReady=false);  


/**
 * prints Skill Is Not Ready
 */  
native War3_PrintSkillIsNotReady(client,raceid,skillNum);






////BUFF SYSTEM
////BUFF SYSTEM
////BUFF SYSTEM
////BUFF SYSTEM
////BUFF SYSTEM
////BUFF SYSTEM


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
native War3_SetBuffItem2(client,W3Buff:buffindex,itemid,any:value);

//not implemented
native W3ApplyBuffSimple(client,W3Buff:buffindex,raceid,any:initialbuffvalue,Float:duration);

///RESETS a particular buff from your race on this client
native W3ResetBuffRace(client,W3Buff:buffindex,raceid);

///RESETS ALL BUFFS PERTAINGIN TO THIS CLIENT AND RACE, basically fully getting rid if all buffs attatched to this player from your race
native W3ResetAllBuffRace(client,raceid);



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

//getting buffs
native W3GetBuffLoopLimit(); //buff loop size , item count + race count + others, loop from 0 to <this return value
native any:W3GetBuff(client,W3Buff:buffindex,RaceIDorItemID,IPassedItemID=false);
native bool:W3GetBuffHasTrue(client,W3Buff:buffindex); //does this buff have one true (activated?)
native Float:W3GetBuffStackedFloat(client,W3Buff:buffindex); //get buff stacked value of an buff, use appropriately
native Float:W3GetBuffSumFloat(client,W3Buff:buffindex);
native Float:W3GetBuffMinFloat(client,W3Buff:buffindex);
native Float:W3GetBuffMaxFloat(client,W3Buff:buffindex);
native W3GetBuffMinInt(client,W3Buff:buffindex);

//calculate player speed next frame
native W3ReapplySpeed(client);

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


//simple weapon restriction:    pass "weapon_knife,weapon_hegrenade" to only allow these weapons, separated by comma. 
//pass "" to allow all weapons again
//c4 etc is automatically allowed
//to override other restrictions, use a higher priority
//use 1 priorty for ur base race restrictions, USE AT OWN RISK!
native War3_WeaponRestrictTo(client,raceid,String:onlyallowedweaponsnames[],priority=1);



native Float:W3GetPhysicalArmorMulti(client); //damage multipler for client by accounting for physical armor (warcraft physical armor, not cs armor)
native Float:W3GetMagicArmorMulti(client); //damage multipler for client by accounting for magic armor

native W3GetCurrentWeaponEnt(client); //get the entity of the current (active) weapon



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

native  W3Hint(client,W3HintPriority:type=HINT_LOWEST,Float:duration=5.0,String:format[],any:...);

//for activatable skills only
stock bool:SkillAvailable(client,yourRaceID,skillnumber,bool:printCooldown=true,bool:checksilenced=true,bool:printSilenced=true){	
	return War3_SkillNotInCooldown(client,yourRaceID,skillnumber,printCooldown)&& (!checksilenced||!Silenced(client,printSilenced));
}

//statuses
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

native W3GetTotalLevels(client); //sum of  levels in each race

native W3GetLevelBank(client);
native W3SetLevelBank(client,newlevelbank);

native War3_SetXP(client,race,newxp);
native War3_GetXP(client,race);

native War3_SetSkillLevel(client,race,skill,newlevel);
native War3_GetSkillLevel(client,race,skill);

native W3SetPlayerProp(client,W3PlayerProp:property,any:value);
native any:W3GetPlayerProp(client,W3PlayerProp:property);

//nothing happens if you give 0 xp 0 gold
//automatically prints gained or lost xp/gold
native W3GiveXPGold(client,W3XPAwardedBy:awardreason=XPAwardByGeneric,xpamount=0,goldamount=0,String:awardstringreason[]);



//TKV = trie key value , a abstract data storage, emulates cvars for war3
///Creates internal war3 cvars. returns a id to your cvar, store it!
//cvarid of 0 is null null (filled auto)
native W3CreateCvar(String:cvarstr[],String:cvarvalue[],String:cvardesc[]);
native W3GetCvar(cvarid,String:returnstr[],maxlen);
native W3SetCvar(cvarid,String:cvarvalue[]);


//returns -1 if not found, otherwise returns cvar id
native W3FindCvar(String:cvar[]);
native Handle:W3CvarList(); //returns a handle arraylist of cvar list (no values, names only. CLOSE THIS!!!
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

native War3_GetDiamondsEXT(client);
native War3_SetDiamondsEXT(client,newd);

stock War3_GetDiamonds(client){
	if(EXT()){
		return War3_GetDiamondsEXT(client);
	}
	return 0;
}
stock War3_SetDiamonds(client,newd){
	if(EXT()){
		War3_SetDiamondsEXT(client,newd);
	}
}

native W3IsDeveloper(client);

///use W3GetVar(hDatabase) to get the handle to the database which your xp is saved, so you dont have to connect again for your addon scipts

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








//create an error displayed in various places at runtime
native CreateWar3GlobalError(String:str[]);

//forwarded when someone calls CreateWar3GlobalError, store that string for yourself
forward OnWar3GlobalError(String:str[]);

forward War3FailedSignal(String:str[]);
public War3FailedSignal(String:str[]){
	LogError(str); //must be a non dependent native log error
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
 #pragma deprecated Use OnRaceChanged(client,oldrace,newrace);
forward OnRaceSelected(client,newrace); //to be removed

//client is not check if valid or not, still forwarded if client is not present, so you can disable buffs etc
forward OnRaceChanged(client,oldrace,newrace);

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
forward OnItem2Purchase(client,item);


/**
 * Gets called when a player loses an item. (after death (ownership to false) or traded it back..)
 * @param client: The client's index.
 * @param item: The item that was purchased.
 * PLAYER ALREADY HAS LOST OWNERSHIP BY THIS POINT   
 */
forward OnItemLost(client,item);
forward OnItem2Lost(client,item);


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
native W3Denyable(W3DENY:event,client); //returns true if NOT DENIED
native W3Deny();

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
			return StrEqual(weapon,"knife");
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
		case Game_L4D2:
		{
			return StrEqual(weapon, "weapon_melee");
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




/// General callback for threaded queries.  No Actions
public SQLWar3GeneralCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	SQLCheckForErrors(hndl,error,"SQLWar3GeneralCallback");
}

stock SQLCheckForErrors(Handle:hndl,const String:originalerror[],const String:prependstr[]=""){
	if(!StrEqual("", originalerror))
		LogError("SQL error: [%s] %s", prependstr, originalerror);
	else if(hndl == INVALID_HANDLE)
	{
		decl String:err[512];
		SQL_GetError(hndl, err, sizeof(err));
		LogError("SQLCheckForErrors: [%s] %s", prependstr, err);
	}
}

public bool:SQL_FastQueryLogOnError(Handle:DB,const String:query[]){
	if(!SQL_FastQuery(DB,query)){
		new String:error[256];
		SQL_GetError(DB, error, sizeof(error));
		LogError("SQLFastQuery %s failed, Error: %s",query,error);
		return false;
	}
	return true;
}

//normal query like SQL_QUERY, database must be locked 
stock bool:SQL_War3_NormalQuery(Handle:DB,String:querystr[]){
	new Handle:result= SQL_Query(DB, querystr);
	if(result==INVALID_HANDLE) {
		new String:error[256];
		SQL_GetError(DB, error, sizeof(error));
		LogError("SQL_War3_NormalQuery %s failed, Error: %s",querystr,error);
		return false;
	}
	else{
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
stock StrToken(const String:inputstr[],tokennum,String:outputstr[],maxlen)
{
	new String:buf[maxlen+1];
	new cur_idx;
	new idx;
	new curind;
	idx=BreakString(inputstr,buf,maxlen);
	if(tokennum==1)
	{
		strcopy(outputstr,maxlen,buf);
		return;
	}
	curind=1;
	while(idx!=-1)
	{
		cur_idx+=idx;
		idx=BreakString(inputstr[cur_idx],buf,maxlen);
		curind++;
		if(tokennum==curind)
		{
			strcopy(outputstr,maxlen,buf);
			break;
		}
	}
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








//////MESSAGES




//prints [W3S] You did %d damage to %name with SKILLNAME
//prints [W3S] %name did %d damage to you with SKILLNAME
new String:zzname[32];
stock W3PrintSkillDmgConsole(victim=0,attacker,damage,skillnum){
	GetClientName(victim,zzname,sizeof(zzname));
	new race=War3_GetRace(attacker);
	new String:skillname[32];
	SetTrans(attacker);
	W3GetRaceSkillName(race,skillnum,skillname,sizeof(skillname));
	PrintToConsole(attacker,"%T","[W3S] You did +{amount} damage to {player} with {skill}",attacker,damage,zzname,skillname);
	
	if(victim>0){
		SetTrans(victim);
		W3GetRaceSkillName(race,skillnum,skillname,sizeof(skillname)); //get trans again
		GetClientName(attacker,zzname,sizeof(zzname));
		PrintToConsole(victim,"%T","[W3S] {player} did {amount} damage to you with {skill}",victim,zzname,damage,skillname);
	}
}
//+%d damage with skill name
stock W3PrintSkillDmgHint(victim=0,attacker,damage,SKILLNUM){

	new race=War3_GetRace(attacker);
	new String:skillname[32];
	SetTrans(attacker);
	W3GetRaceSkillName(race,SKILLNUM,skillname,sizeof(skillname));
	
	PrintHintText(attacker,"%T","+{amount} damage with {skill}",attacker,damage,skillname);
	
	if(victim>0){
		SetTrans(victim);
		W3GetRaceSkillName(race,SKILLNUM,skillname,sizeof(skillname));
		PrintHintText(victim,"%T","Received {amount} damage from {skill}",victim,damage,skillname);
	}
}
stock W3PrintSkillDmgHintConsole(victim=0,attacker,damage,SKILLNUM){
	W3PrintSkillDmgHint(victim,attacker,damage,SKILLNUM);
	W3PrintSkillDmgConsole(victim,attacker,damage,SKILLNUM);
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
	if(totalwardcount>0){
		Format(print,sizeof(print),"%T","You created a Ward {amount}/{amount}",client,currentwardcount,totalwardcount);
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
 * Prints Message to server and all chat
 * For debugging prints
 */ 
stock DP(const String:szMessage[], any:...)
{
	
	decl String:szBuffer[1000];

	VFormat(szBuffer, sizeof(szBuffer), szMessage, 2);
	PrintToServer("[Debug Print] %s", szBuffer);
	PrintToChatAll("[Debug Print] %s", szBuffer);

}
//prring plugin
stock DPP(Plugin:plugin)
{
	new String:szBuffer[1000];
	GetPluginFilename(Handle:plugin, szBuffer,sizeof(szBuffer));
	DP("[Debug PrintP] %s", szBuffer);
}

stock PrintPlugin(Handle:plugin){
	new String:str[100];
	GetPluginFilename(Handle:plugin, str, sizeof(str));
	W3LogNotError("%s",str);
}
stock PrintPluginError(Handle:plugin){
	new String:str[100];
	GetPluginFilename(Handle:plugin, str, sizeof(str));
	LogError("%s",str);
	W3LogError("%s",str);
}




#include "W3SIncs/stocks_precache"
#include "W3SIncs/stocks_misc"

//SUPER HERO INDLUDE FILE, many stock requires war3 functions to be delcared first...
#include "W3SIncs/SuperHero_Interface"
