/**
 * File: War3Source_Wards.inc
 * Description: Interface to the ward engine
 * Author(s): War3Source Team  
 */

#define WARDNAMELEN                 32
#define WARDSNAMELEN                16
#define WARDDESCLEN                 128
#define MAXWARDDATA                 64
#define WARDBELOW                   -2.0
#define WARDABOVE                   160.0

// Bit flags for what a ward should target
#define WARD_TARGET_NOBODY          (0 << 0)
#define WARD_TARGET_SELF            (1 << 0)
#define WARD_TARGET_ALLIES          (1 << 1)
#define WARD_TARGET_ENEMYS          (1 << 2)

// For lazy people.. since this is a pretty obvious thing to do ;)
#define WARD_TARGET_TEAMMATES       WARD_TARGET_SELF | WARD_TARGET_ALLIES

#define INVALID_BEHAVIOR            -1
#define INVALID_WARD                -1

/**
 * Creates a simple ward. 
 * 
 * This is the function you'd use if you want to implement wards with custom logic in your race.
 * This function only creates the ward data structure and keeps track of it internally, allowing you
 * to interact with it via the events and getters. 
 * 
 * @param client: The id of the client that places this wards
 * @param location: The location where the ward should go
 * @param radius: The radius of effect this ward has
 * @param duration: How long this ward should stay. Pass 0 for no expire time.
 * @param disableOnDeath: Disables the ward when the owner dies
 * @param pulseInterval: time between effect triggerings
 * @param wardTarget: What clients this ward should affect. Check the bitflags at the top

 * @return ID for the ward created or INVALID_WARD if the ward was not created
 */
native War3_CreateWard(client, Float:location[], radius, Float:duration, Float:pulseInterval, wardTarget=WARD_TARGET_ENEMYS, bool:disableOnDeath=true);

/**
 * Removes a ward given an id
 * 
 * @param wardindex: ward id
 * @return True if the ward was removed. False otherwise
 */
native bool:War3_RemoveWard(wardindex);


// WARD EVENTS

//Fired every time a ward is created
forward OnWardCreated(wardindex, behaviorID);

//Fired every time a ward "pulses". Only enabled wards pulse
forward OnWardPulse(wardindex, behaviorID);

//Fired every time a ward "pulses" when a valid target is in range
forward OnWardTrigger(wardindex, victim, owner, behaviorID);

//Fired every time a ward is removed
forward OnWardExpire(wardindex, owner, behaviorID);

// ------------------------------------------------------------------------------------------------------------------------------------------------------

// If you're a bit lazy you can reuse different ward implementations that come with War3Source :-)

/**
 * Creates a modular ward.
 * 
 * The main logic of this ward is already implemented somewhere and can be reused
 * as long as you know the "behavior" id of the ward implementation. This function
 * comes with a few additional parameters to customize the ward to your liking
 * 
 * @param client: The id of the client that places this wards
 * @param location: The location where the ward should go
 * @param radius: The radius of effect this ward has
 * @param duration: How long this ward should stay. Pass 0 for no expire time.
 * @param pulseInterval: time between effect triggerings
 * @param behavior: ward behavior short name. Every time a ward is triggered, this behavior is called on
 * @param skillNum: Skill number of the ward skill (used for determining damage/healing in the data array)
 * @param data: Array of data to pass to the ward. This is used by the ward behavior for things like damage per skill level.
 * @param wardTarget: What clients this ward should affect. Check the bitflags at the top
 * @param disableOnDeath: Disables the ward when the owner dies
 * @param useDefaultColors: Chooses whether to use the behaviour's built-in colors or substitute your own
 * @param customColor2: Custom color to use on team 2 (terrorists in CS:S)
 * @param customColor3: Custom color to use on team 3 (counter-terrorists in CS:S)
 * @return ID for the ward created or -1 if the ward was not created
 */
native War3_CreateWardMod(client, Float:location[], radius, Float:duration, Float:pulseInterval, String:behavior[], skillNum, any:data[], 
                          wardTarget=WARD_TARGET_ENEMYS, bool:disableOnDeath=true, 
                          bool:useDefaultColors = true, customColor2[] = {0,0,0,0}, customColor3[] = {0,0,0,0});

// ------------------------------------------------------------------------------------------------------------------------------------------------------

// Getters for the basic internal ward data structure

native War3_GetWardLocation(wardindex, Float:location[]);
native War3_GetWardRadius(wardindex);
native War3_GetWardOwner(wardindex);
native War3_GetWardCount(client);
native Float:War3_GetWardInterval(wardindex);

// ------------------------------------------------------------------------------------------------------------------------------------------------------

// If you're really brave (or a core developer) these are the functions you need
// to implement ward logic that can be reused by other plugins

/**
 * Creates a new ward behavior. 
 *
 * @param shortname: short name for the behavior
 * @param name: full name for the behavior (unused right now)
 * @param desc: description of ward behavior (unused right now)
 * 
 * @return ward behavior ID
 */
native War3_CreateWardBehavior(String:shortname[], String:name[], String:desc[]);

/**
 * Gets the number of ward behaviors loaded.
 *
 * @return number of ward behaviors loaded
 */
native War3_GetWardBehaviorsLoaded();

native War3_GetWardBehaviorName(id, String:retstr[], maxlen);
native War3_GetWardBehaviorShortname(id, String:retstr[], maxlen);
native War3_GetWardBehaviorDesc(id, String:retstr[], maxlen);
native War3_GetWardBehaviorByShortname(String:shortname[]);

// ------------------------------------------------------------------------------------------------------------------------------------------------------

// Getters for the ward behavior data structure

native War3_GetWardBehavior(wardindex);
native War3_GetWardColor2(wardindex, color[]);
native War3_GetWardColor3(wardindex, color[]);
native War3_GetWardSkill(wardindex);
native any:War3_GetWardData(wardindex, any:data[]);
native bool:War3_GetWardUseDefaultColor(wardindex);
