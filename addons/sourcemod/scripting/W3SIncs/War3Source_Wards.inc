/**
 * File: War3Source_Wards.inc
 * Description: Interface to the ward engine
 * Author(s): War3Source Team  
 */

#define WARDNAMELEN 32
#define WARDSNAMELEN 16
#define WARDDESCLEN 128
#define MAXWARDDATA 64
#define WARDBELOW -2.0
#define WARDABOVE 160.0

// Bit flags for what a ward should target
// You can pass this to CreateWard like this:
//     WARD_TARGET_SELF & WARD_TARGET_ALLIES -> Ward that targets the owner and his allies
//     WARD_TARGET_ALLIES & WARD_TARGET_ENEMYS -> Ward that targets the allies and enemys of the owner, but not himself
//     etc.

#define WARD_TARGET_SELF            (1 << 0)
#define WARD_TARGET_ALLIES          (1 << 1)
#define WARD_TARGET_ENEMYS          (1 << 2)

// For lazy people.. since this is a pretty obvious thing to do ;)
#define WARD_TARGET_TEAMMATES       WARD_TARGET_SELF & WARD_TARGET_ALLIES

/**
 * Creates a new ward behavior. This will allow us to make ward effects modular, so people
 * can make their own ward types! Currently I don't know what I'm going to do with the name
 * and description fields, but there is definitely room for expansion of features with this
 * model.
 *
 * @param shortname: short name for the behavior
 * @param name: full name for the behavior (unused right now)
 * @param desc: description of ward behavior (unused right now)
 * @return ward behavior ID or 0 if ward behavior limit reached
 */
native War3_CreateWardBehavior(String:shortname[],String:name[],String:desc[]);

/**
 * Gets the number of ward behaviors loaded.
 *
 * @return number of ward behaviors loaded
 */
native War3_GetWardBehaviorsLoaded();
native War3_GetWardBehaviorName(id,String:retstr[],maxlen);
native War3_GetWardBehaviorShortname(id,String:retstr[],maxlen);
native War3_GetWardBehaviorDesc(id,String:retstr[],maxlen);

/**
 * Gets the ID of the ward behavior given its shortname.
 *
 * @param shortname: short name for the behavior
 * @return ward behavior ID or -1 if it does not exist
 */
native War3_GetWardBehaviorByShortname(String:shortname[]);

/**
 * Creates a ward.
 * 
 * Odd/special cases:
 * If a ward is created with selfInflict=false, but affinity=SELF_ONLY, you get a ward that does nothing, essentially.
 * If a ward is created with a negative/zero duration, it will last until round end/manual remove or until the caster is dead
 * 
 * @param client: owner id
 * @param location: ward location
 * @param radius: ward effect radius
 * @param duration: ward duration. If negative or zero, duration is infinite (until map change). Don't forget to remove the ward!
 * @param pulseInterval: time between effect triggerings
 * @param behavior: ward behavior short name. Every time a ward is triggered, this behavior is called on
 * @param skillNum: Skill number of the ward skill (used for determining damage/healing in the data array)
 * @param data: Array of data to pass to the ward. This is used by the ward behavior for things like damage per skill level.
 * @param affinity: the targeting affinity for this ward. Check the bitflags at the top
 * @param useDefaultColors: Chooses whether to use the behaviour's built-in colors or substitute your own
 * @param customColor2: Custom color to use on team 2 (terrorists in CS:S)
 * @param customColor3: Custom color to use on team 3 (counter-terrorists in CS:S)
 * @return ID for the ward created or -1 if the ward was not created
 */
native War3_CreateWard(client, Float:location[], radius, Float:duration, Float:pulseInterval, String:behavior[], skillNum, any:data[], affinity=WARD_TARGET_ENEMYS, bool:useDefaultColors = true, customColor2[] = {0,0,0,0}, customColor3[] = {0,0,0,0});

/**
 * Gets a specific ward's behavior.
 *
 * Important: This refers to a specific instance of a ward. That is, if you know the index of a
 * ward that has been placed inside the game, this will tell you what its behavior ID is.
 *
 * @param wardindex: ward ID
 * @return Ward behavior ID or -1 if the ward does not exist
 */
native War3_GetWardBehavior(wardindex);
native War3_GetWardLocation(wardindex, Float:location[]);
native Float:War3_GetWardInterval(wardindex);
native War3_GetWardRadius(wardindex);
native War3_GetWardOwner(wardindex);
native any:War3_GetWardData(wardindex, any:data[]);

/**
 * Removes a ward given an id
 * @param wardindex: ward id
 * @return True if the ward was removed. False otherwise
 */
native bool:War3_RemoveWard(wardindex);
native bool:War3_GetWardUseDefaultColor(wardindex);
native War3_GetWardColor2(wardindex, color[]);
native War3_GetWardColor3(wardindex, color[]);
native War3_GetWardSkill(wardindex);
native War3_GetWardCount(client);


//Fired every time a ward is created
forward OnWardCreated(wardindex, behaviorID);

//Fired every time a ward "pulses". Only enabled wards pulse
forward OnWardPulse(wardindex, behaviorID);

//Fired every time a ward "pulses" when a valid target is in range
forward OnWardTrigger(wardindex, victim, owner, behaviorID);

//Fired every time a ward is removed
forward OnWardExpire(wardindex, owner, behaviorID);