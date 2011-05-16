/**
* File: 
* While we do this, lets document this file. I saw a forum post requesting documentation in this file.
*/


//for all war3source or SH plugins, we define MAXPlAYERS as 66
//just so pigs dont fly when you run a 64 slot server with HLTV
#define MAXPLAYERSCUSTOM 66   //+2 of real for normal servers, add +X number of HLTV slots


//dochecking up to <MAXRACES
//limit check up to >=MAXRACES-1

#define MAXRACES 200 //20 = [1]-[199]  ///can only hold X-1 races, IE 20 can only hold 19 races, we skip zeroth race!

#define MAXITEMS 100  // [1]-[19] //(+1 of real number of items, if there are 8 items to load, use 9!! ignore zeroth rule)
#define MAXITEMS2 100 
//zeroth item not used


#define MAXSKILLCOUNT 8 //[1]-[7]   //if you want 7 skills, use 8. A SKILL IS GENERIC, set the property "ultimate" to true for ultmates

#define DEF_MAX_SKILL_LEVEL 4 //DO NOT CHANGE

#define MAXLEVELXPDEFINED 16 //maximum where level XP is defined, if a race has more than MAXLEVELXPDEFINED levles, xp given and xp to next level is still MAXLEVELXPDEFINED

#define CUSTOMMODIFIERS 3 //how many race indexes extra for modifying buffs without conflicting other races

#define MAXAURAS 100 // [1- ] ignore zeroth index

// The enum W3Var is used with function W3SetVar and W3GetVar.
// It is the first parameter, eg: new deathRace = W3GetVar(DeathRace)
enum W3Var
{
	OldRace, //the race he was before OnRaceChanged //REMOVE DEPRECATED
	DeathRace, //race when player died 
	hDatabase, // Handle to database
	hDatabaseType, // DBI driver, ie sqlite or mysql
	hSaveEnabledCvar, //Handle to war3_savexp
	hRaceLimitEnabledCvar, // war3_racelimit_enable
	hNewPlayerLevelbankCvar, // war3_new_player_levelbank

	TheItemBoughtOrLost, // item in question in events such as item bought or item lost
	hPlayerInfoArgStr, // string argument after player says "playerinfo <arg>" if any
	RaceinfoRaceToShow, // who to show the raceinfo  ....
	EventArg1, //generic war3event arguments
	EventArg2,
	EventArg3,
	
	TransClient,//who to translate
	
	hUseMetricCvar, //handle to cvar
	
	SmEvent, ///usual game events from sm hooked events

}

stock String:W3VarStrings[][32] = {"OldRace",
								"DeathRace",
								"hDatabase",
								"hDatabaseType",
								"hSaveEnabledCvar",
								"hRaceLimitEnabledCvar",
								"hNewPlayerLevelbankCvar",
								"TheItemBoughtOrLost",
								"hPlayerInfoArgStr",
								"RaceinfoRaceToShow",
								"EventArg1",
								"EventArg2",
								"EventArg3",
								"TransClient",
								"hUseMetricCvar",
								"SmEvent"};

//These are just used as constants, and enum orders them incrementally
// They are to be used for War3CreateEvent and OnWar3Event, these constants define the type of the event/
//War3Events are basically used kind of like Natives and Forwards, without the trouble of creating actual natives/forwards
enum W3EVENT
{
	Moled=0,
	BombPlanted,
	BombDefused,
	ToBeRevived,
	DoShowHelpMenu,
	DoShowChangeRaceMenu,
	DoShowShopMenu,
	DoTriedToBuyItem,
	DoShowItemsInfoMenu,
	DoShowRaceinfoMenu,
	DoShowPlayerinfoMenu, 
	DoShowPlayerinfoEntryWithArg,
	DoShowParticularRaceInfo,

	ClearPlayerVariables,
	InitPlayerVariables,
	DoLevelCheck,
	
	
	DoForwardClientBoughtItem, //tell item ownership to call lost and bought forwards
	DoForwardClientLostItem, //uses TheItemBoughtOrLost
	
	DoShowSpendskillsMenu,
	PlayerIsNewToServer,
	DoResetSkills,
	DoShowWar3Menu,
	DoShowLevelBank,
	DoShowWar3Rank,
	DoShowWar3Stats,
	DoShowWar3Top,
	
	PlayerLeveledUp,
	DoCheckRestrictedItems,
	OnPreGiveXPGold, //client, arg1,2,3=W3XPAwardedBy , xp, gold
	OnPostGiveXPGold, ///xp gold already given, same args as pre
	
	CanBuyItem, //client, arg1=itemid, if eventarg2 is non zero, he can buy// you have to do the message on the reason why he can't buy
	
	OnDeathPre, //EventArg1 = attacker.  before w3 actual death forward is called to do some reading ( ie before items are lost)
	DoShowMenuMyInfo,
	DoShowPlayerInfoTarget, ///EventArg1 = target = the person whos info is shown, client=SHOW TO 
	

	
	SHMyHeroes, //select a race to drop
	SHClearPowers, //drop all heroes
	SHSelectHeroesMenu, //sh changerace
	
	//shopmenu2
	DoShowShopMenu2,
	DoTriedToBuyItem2,
	DoForwardClientBoughtItem2, //tell item ownership to call lost and bought forwards
	DoForwardClientLostItem2, //uses TheItemBoughtOrLost
	
	UNLOADPLUGINSBYMODE,//testing plugin unload
	DatabaseConnected,
	
	DoShowSHMenu,
	
}

// Constants for an array, which every War3 Plugin has. When the variables are ready, they will be forwarded to you.
enum W3ForwardedVarsEnum{
	ValveGame, //cs tf2
	W3Mode, //true false
	SHMode, //true false
}

//Used as constants...identifies why a player was rewarded XP/Gold
enum W3XPAwardedBy
{
	XPAwardByGeneric, ///not defined
	XPAwardByKill,
	XPAwardByAssist,
	XPAwardByWin,
	XPAwardByBomb, //defuse / explode
	XPAwardByHostage,
	XPAwardByPointCap,
	XPAwardByPointCapBlock,
	XPAwardByFlagCap,
}

// The types of immunities you can get/set from.
///corresponds to a buff system immunity
enum War3Immunity
{
	Immunity_None = 0, //generic zero
	Immunity_Ultimates, // Immune from ultimates
	Immunity_PhysicalDamage, // Immune from health taking
	Immunity_MagicDamage, // Immune from magic based stuff (doesnt not include ultimates)
	Immunity_Items, // Immune from shop items
	Immunity_Skills, // Immune from all skills
	Immunity_Wards, // Immune ward modifiers/damage. skill immunity includes ward immunity
}; // The last of PimpinJuice's sexy syntax

//where damage is from   skill or ultimate etc
enum War3DamageOrigin
{
	W3DMGORIGIN_UNDEFINED=0,
	W3DMGORIGIN_SKILL,
	W3DMGORIGIN_ULTIMATE,
	W3DMGORIGIN_ITEM,
}

//damage types
enum War3DamageType
{
	W3DMGTYPE_TRUEDMG=0,       //normal damage without accout for physical or magic armor
	W3DMGTYPE_PHYSICAL,
	W3DMGTYPE_MAGIC,
}

// Games that War3Source Supports
enum ValveGameEnum
{
	Game_None=0,
	Game_CS=1,
	Game_DOD=2,
	Game_TF=3,
	
	//Are you feeling Lazy? use this!
	CS=Game_CS,
	DOD=Game_DOD,
	TF=Game_TF,
}

//Basically Instance variables for the Player Class
enum W3PlayerProp
{
	CurrentRace,
	PendingRace,
	PlayerGold,
	PlayerDiamonds,
	iMaxHP,
	bIsDucking,
	
	bool:xpLoaded,
	Float:RaceChosenTime,
	bool:RaceSetByAdmin,
	bool:SpawnedOnce,
	Float:sqlStartLoadXPTime,
	
	bool:isDeveloper,
	Float:LastChangeTeamTime,
}

//EXCLUSIVE: buffs that do not stack with itself: gravity, invisblity, however to make them stack use a second property ie gravity2, invisibilty2
//////////////////Generally races use "buffvar" and items that wish to stack uses "varbuff2" and the final value is calculated: best of "buffvar" stacked with best of "buffvar2"
//STACKING: buffs that stack with itself
//EACH BUFF SHOULD HAVE A CONCENSUS ON WHAT TYPE OF VALUE IT USES: bool, int, float
///NOT ALL BUFFS HAVE THE SAME DENIES, some only need skill deny or item deny only



enum W3BuffProperties
{
	any:DefaultValue=0, //array index 1
	BuffStackCacheType:BuffStackType=1, //array index 1
}

enum BuffStackCacheType
{ //each buff can only have one stacking operation:aa
	DoNotCache=0,
	bHasOneTrue,
	iAbsolute, //sum
	fAbsolute, //sum
	fStacked, /// all float multiplied
	
	fMaximum,
	fMinimum,
	iMinimum,
	ERRUNDEFINED=-99,
}


enum W3Buff
{
	buffdummy=0,
	bBuffDenyAll, //DENY=not allowed to have any buffs, aka "purge"
	
	fLowGravitySkill, //0.4 ish?
	fLowGravityItem, //0.4 ish?
	bLowGravityDenyAll,
	
	fInvisibilitySkill, //0.4 ish?
	fInvisibilityItem, //0.4 ish?
	bInvisibilityDenyAll,
	bInvisibilityDenySkill,
	bDoNotInvisWeapon,
	bInvisWeaponOverride, //set true to use override amount, ONLY 1 RACE SHALL USE THIS AT A TIME PER CLIENT
	iInvisWeaponOverrideAmount, ///amolunt of 0-255 , do not have to set back to 255, just set bInvisWeaponOverride to false
	
	fMaxSpeed, //for increasing speeds only! MUST BE MORE THAN 1.0
	fMaxSpeed2, //for increasing speeds only!, added onto fMaxSpeed buff, MUST BE MORE THAN 1.0
	
	fSlow, //for decreeasing speeds only! MUST BE LESS THAN 1.0
	fSlow2, //for decreeasing speeds only! MUST BE LESS THAN 1.0. allows a race to have stacking slows
	bSlowImmunity, //immune to slow?
	
	bImmunitySkills, //is immune to skills
	bImmunityUltimates, // is immune to ultimates	
	bImmunityWards, // is immune to wards, skill immunity includes ward immunity
	
	fAttackSpeed, //attack speed multipler!
	
	bStunned, //cannot shoot, cannot cast, cannot move, basically everything below
	bBashed, //cannot move
	bDisarm,//cannot shoot
	bSilenced,  //cannot cast 
	bHexed,  // no skill proc
	bPerplexed, //cannot use items / proc items
	
	bNoMoveMode,//move type none! overrrides all other movestypes
	bFlyMode,   //fly mode
	bFlyModeDeny,
	bNoClipMode,
	
	fArmorPhysical,
	fArmorMagic,
	
	//DO NOT USE GLOW FOR INVIS
	iGlowRed, //glowing the player 0-255
	iGlowGreen,
	iGlowBlue,
	iGlowAlpha, //careful this is like invisiblity
	iGlowPriority, //highest priority takes effect
	fGlowSetTime, //time is recorded, those with same prioirty will compete via time. not something u set
	

	
	fHPRegen, ///float sum! NO NEGATIVES! MINIM regin rate is 0.5 / second
	
	
	
	
	
	MaxBuffLoopLimitTemp, //this is a variable that is for loops, this number is automatically generated fromt the enum. 
}
stock MaxBuffLoopLimit=_:MaxBuffLoopLimitTemp;


//create an buffpropertiesarray[W3Buff][W3BuffProperties]; (separate from the array that stores every client's buffs)
//we fill the array with its properties
stock InitiateBuffPropertiesArray(buffpropertiesarray[W3Buff][W3BuffProperties])
{
	
	for(new i=0;i<MaxBuffLoopLimit;i++)
	{
		buffpropertiesarray[W3Buff:i][DefaultValue]=-99;
		buffpropertiesarray[W3Buff:i][BuffStackType]=ERRUNDEFINED;
	}
	
	buffpropertiesarray[buffdummy][DefaultValue]=false;
	buffpropertiesarray[buffdummy][BuffStackType]=bHasOneTrue;
	
	buffpropertiesarray[bBuffDenyAll][DefaultValue]=false;
	buffpropertiesarray[bBuffDenyAll][BuffStackType]=bHasOneTrue;
	
	buffpropertiesarray[fLowGravitySkill][DefaultValue]=1.0;
	buffpropertiesarray[fLowGravitySkill][BuffStackType]=fMinimum;
	
	buffpropertiesarray[fLowGravityItem][DefaultValue]=1.0;
	buffpropertiesarray[fLowGravityItem][BuffStackType]=fMinimum;
	
	buffpropertiesarray[ bLowGravityDenyAll ][DefaultValue]=false;
	buffpropertiesarray[ bLowGravityDenyAll ][BuffStackType]=bHasOneTrue;
	
	buffpropertiesarray[ fInvisibilitySkill ][DefaultValue]=1.0;
	buffpropertiesarray[ fInvisibilitySkill ][BuffStackType]=fMinimum;
	
	buffpropertiesarray[ fInvisibilityItem ][DefaultValue]=1.0;
	buffpropertiesarray[ fInvisibilityItem ][BuffStackType]=fMinimum;
	
	buffpropertiesarray[ bInvisibilityDenyAll ][DefaultValue]=false;
	buffpropertiesarray[ bInvisibilityDenyAll ][BuffStackType]=bHasOneTrue;
	
	buffpropertiesarray[ bInvisibilityDenySkill ][DefaultValue]=false;
	buffpropertiesarray[ bInvisibilityDenySkill ][BuffStackType]=bHasOneTrue;
		
	buffpropertiesarray[ bDoNotInvisWeapon ][DefaultValue]=false;
	buffpropertiesarray[ bDoNotInvisWeapon ][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ bInvisWeaponOverride ][DefaultValue]=false;
	buffpropertiesarray[ bInvisWeaponOverride ][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ iInvisWeaponOverrideAmount ][DefaultValue]=255;
	buffpropertiesarray[ iInvisWeaponOverrideAmount ][BuffStackType]=iMinimum;	
	
	buffpropertiesarray[ fMaxSpeed ][DefaultValue]=1.0;
	buffpropertiesarray[ fMaxSpeed ][BuffStackType]=fMaximum;
	
	buffpropertiesarray[ fMaxSpeed2 ][DefaultValue]=1.0;
	buffpropertiesarray[ fMaxSpeed2 ][BuffStackType]=fMaximum;
	
	
	buffpropertiesarray[ fSlow ][DefaultValue]=1.0;
	buffpropertiesarray[ fSlow ][BuffStackType]=fStacked;	
	
	buffpropertiesarray[ fSlow2 ][DefaultValue]=1.0;
	buffpropertiesarray[ fSlow2 ][BuffStackType]=fStacked;
	
	buffpropertiesarray[ bSlowImmunity ][DefaultValue]=false;
	buffpropertiesarray[ bSlowImmunity ][BuffStackType]=bHasOneTrue;
	
//	buffpropertiesarray[ fIncomingDamage ][DefaultValue]=1.0;
//	buffpropertiesarray[ fIncomingDamage ][BuffStackType]=fStacked;
	
	buffpropertiesarray[ bImmunitySkills ][DefaultValue]=false;
	buffpropertiesarray[ bImmunitySkills ][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ bImmunityWards ][DefaultValue]=false;
	buffpropertiesarray[ bImmunityWards ][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ bImmunityUltimates ][DefaultValue]=false;
	buffpropertiesarray[ bImmunityUltimates ][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ fAttackSpeed ][DefaultValue]=1.0;
	buffpropertiesarray[ fAttackSpeed ][BuffStackType]=fStacked;
	
	buffpropertiesarray[ bStunned ][DefaultValue]=false;
	buffpropertiesarray[ bStunned ][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ bBashed ][DefaultValue]=false;
	buffpropertiesarray[ bBashed ][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ bDisarm ][DefaultValue]=false;
	buffpropertiesarray[ bDisarm ][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ bSilenced ][DefaultValue]=false;
	buffpropertiesarray[ bSilenced ][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ bPerplexed ][DefaultValue]=false;
	buffpropertiesarray[ bPerplexed ][BuffStackType]=bHasOneTrue;	
		
	buffpropertiesarray[ bHexed ][DefaultValue]=false;
	buffpropertiesarray[ bHexed ][BuffStackType]=bHasOneTrue;
		
	buffpropertiesarray[ bNoMoveMode ][DefaultValue]=false;
	buffpropertiesarray[ bNoMoveMode ][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ bFlyMode ][DefaultValue]=false;
	buffpropertiesarray[ bFlyMode ][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ bFlyModeDeny ][DefaultValue]=false;
	buffpropertiesarray[ bFlyModeDeny ][BuffStackType]=bHasOneTrue;	
	
	
	buffpropertiesarray[ bNoClipMode ][DefaultValue]=false;
	buffpropertiesarray[ bNoClipMode ][BuffStackType]=bHasOneTrue;	
	
	
	buffpropertiesarray[ fArmorPhysical ][DefaultValue]=0;
	buffpropertiesarray[ fArmorPhysical ][BuffStackType]=fAbsolute;	
	
	buffpropertiesarray[ fArmorMagic ][DefaultValue]=0;
	buffpropertiesarray[ fArmorMagic ][BuffStackType]=fAbsolute;	
	
	buffpropertiesarray[ iGlowRed ][DefaultValue]=255;
	buffpropertiesarray[ iGlowRed ][BuffStackType]=DoNotCache;
	
	buffpropertiesarray[ iGlowGreen ][DefaultValue]=255;
	buffpropertiesarray[ iGlowGreen ][BuffStackType]=DoNotCache;
	
	buffpropertiesarray[ iGlowBlue ][DefaultValue]=255;
	buffpropertiesarray[ iGlowBlue ][BuffStackType]=DoNotCache;
	
	buffpropertiesarray[ iGlowAlpha ][DefaultValue]=255;
	buffpropertiesarray[ iGlowAlpha ][BuffStackType]=DoNotCache;	
	
	buffpropertiesarray[ iGlowPriority ][DefaultValue]=0;
	buffpropertiesarray[ iGlowPriority ][BuffStackType]=DoNotCache;	
	
	buffpropertiesarray[ fGlowSetTime ][DefaultValue]=0;
	buffpropertiesarray[ fGlowSetTime ][BuffStackType]=DoNotCache;	
	
	
	
	buffpropertiesarray[ fHPRegen][DefaultValue]=0.0;
	buffpropertiesarray[ fHPRegen][BuffStackType]=fAbsolute;	
	//check that all indexes have been set
	for(new i=0;i<MaxBuffLoopLimit;i++)
	{
		if(buffpropertiesarray[W3Buff:i][DefaultValue]==-99)
		{
			SetFailState("Buff index %d [DefaultValue] was not set properly!",i);
		}
		if(buffpropertiesarray[W3Buff:i][BuffStackType]==ERRUNDEFINED)
		{
			SetFailState("Buff index %d [BuffStackType] was not set properly!",i);
		}
	}
	
}

///not yet used
enum RaceString
{
	RaceName,
	RaceShortname,
	RaceStory,
	RaceDescription,
	RaceTechnical,
}

enum SkillString
{
	SkillName,
	SkillStory,
	SkillDescription,
	SkillTechnical,
}

enum W3SkillType{
	NORMALSKILL=0,
	ULTIMATE,
	ABILITY,
	ABILITY1,
	ABILITY2,
	ABILITY3,
	ABILITY4,
}

// War3 Glow constants
enum  
{
	GLOW_NONE=0,
	GLOW_BASE=1, //if ur race needs a glow
	GLOW_BASE2, //temporary glow of ur race over ur orignal glow? like mole u can add a glow for another priority
	GLOW_DEFAULT,
	GLOW_SKILL, //if skill activates on u  or others
	GLOW_ULTIMATE, //if ultimate actiavates on u or others
	GLOW_OVERRIDE=255, //override all glow
}

enum W3ItemProp 
{
	ITEM_USED_ON_BUY=0,
	ITEM_SELFSTACK,
}

enum War3SQLType
{
	SQLType_Unknown = 0,
	SQLType_MySQL,
	SQLType_SQLite,
}


enum W3HintPriority{
	HINT_NORMAL, //things that are attached from non hint engine hints
	HINT_SKILL_STATUS, //"TELEPORTED!"
	HINT_DMG_DEALT,
	HINT_DMG_RCVD,
	HINT_COOLDOWN_NOTREADY,
	HINT_COOLDOWN_EXPIRED,
	HINT_COOLDOWN_COUNTDOWN,
	HINT_LOWEST,
	
	HINT_SIZE, //do not use this as priority
}
enum W3HintPriorityMultiType{
	HINT_TYPE_SINGLE=0,	//show single, overrides old
	HINT_TYPE_ALL,		//show all of them
	HINT_TYPE_QUEUE,	//queue each one
}
//functio to retreve these constants
stock any:W3GetHintPriorityType(W3HintPriority:priority){
	switch(priority){
		case HINT_NORMAL:  return HINT_TYPE_ALL;
		case HINT_SKILL_STATUS: return HINT_TYPE_ALL;
		case HINT_DMG_DEALT: return HINT_TYPE_ALL;
		case HINT_DMG_RCVD: return HINT_TYPE_ALL;
		case HINT_COOLDOWN_NOTREADY: return HINT_TYPE_SINGLE;
		case HINT_COOLDOWN_EXPIRED:  return HINT_TYPE_ALL;
		case HINT_COOLDOWN_COUNTDOWN:  return HINT_TYPE_SINGLE;
		case HINT_LOWEST:  return HINT_TYPE_ALL;
	}
	return -1;
}


// The following are color presets for the War3_FlashScreen function
#define RGBA_COLOR_RED		{255,0,0,4}
#define RGBA_COLOR_GREEN	{0,255,0,3}
#define RGBA_COLOR_BLUE		{0,0,255,3}
#define RGBA_COLOR_YELLOW	{255,255,0,3}
#define RGBA_COLOR_ORANGE	{255,69,0,3}
#define RGBA_COLOR_PURPLE	{128,0,128,3}
#define RGBA_COLOR_CYAN		{255,0,255,3}
#define RGBA_COLOR_WHITE	{255,255,255,3}
#define RGBA_COLOR_BLACK	{0,0,0,3}
#define RGBA_COLOR_GREY		{128,128,128,3}
#define RGBA_COLOR_PINK		{255,20,147,3}
#define RGBA_COLOR_MAROON	{128,0,0,3}
#define RGBA_COLOR_SKYBLUE	{135,206,25,3}
#define RGBA_COLOR_GOLD		{255,215,0,3}
#define RGBA_COLOR_BROWN	{139,69,19,3}
#define RGBA_COLOR_VIOLET	{238,130,238,3}

// The following are from the SourceSDK, used for the optional flags field of War3_FlashScreen
#define FFADE_IN			0x0001		// Just here so we don't pass 0 into the function, YOUR SCREEN DECAYS AND YOU SEE CLEARLY SLOWLY
#define FFADE_OUT			0x0002		// Fade out (not in)
#define FFADE_MODULATE		0x0004		// Modulate (don't blend)
#define FFADE_STAYOUT		0x0008		// ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE			0x0010		// Purges all other fades, replacing them with this one

// Team ID's for the Valve specific game
#define  TEAM_T 2
#define  TEAM_CT 3
#define  TEAM_RED 2
#define  TEAM_BLUE 3