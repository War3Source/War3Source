/**
 * File: vars.inc
 * Description: many variables, put here so any other includes can use them, this file is read first
 * not all variables needs to be here
 * if a variable is used accross include files, it should be put here
 */

//CVAR variables HANDLES are in cvar.inc
//FORWARD VARIABLES HANDLES ARE IN FORWARDS.INC

new W3VarArr[W3Var];



new dummyreturn; //for your not used return values

/*
 * single event variables 
 * these variables are reset as soon as the event finishes. when the event triggers, 
 * plugins directly call natives to changet value, and the final resulting value is used. 

 * for example. damageModifierPercent is default 1.0. 
 * when a damage event happens, the event is notified to all races, 
 * and each race can modify this like: multiply by 1.20, 
 * and the final value 1.20 is used after all races have 
 * a chance to change it, and the orignal damage is multiplied by 1.20 and dealt to the victim.
*/

new bInFreezeTime; // again, kinda hacky


new Float:LastLoadingHintMsg[MAXPLAYERSCUSTOM];

new bHasDiedThisFrame[MAXPLAYERSCUSTOM]; 
/**********************
 * prevent double kills if the same player in the same frame, 
 * like killed by skill damage is one kill message, killed by original damge is another death message, 
 * woudl cause double xp kill, because skill damage is actually dealt first (nested)
 */ 
 
 

