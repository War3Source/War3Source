/**
 * File: War3Source_Addon_XPMultipler.sp
 * Description: Easy XP/Gold rate handling with convars.
 * Author(s): DonRevan
 */
 
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"  

new Handle:MultiplierCVars[2];

public Plugin:myinfo = 
{
	name = "War3Source Addon - XP Multipler",
	author = "DonRevan",
	description = "Easy XP/Gold rate handling with convars",
	version = "1.0",
	url = "http://www.war3source.com/"
};

public OnPluginStart()
{
	MultiplierCVars[0] = CreateConVar("war3_xp_multipler","1.0","XP multiplier");
	MultiplierCVars[1] = CreateConVar("war3_gold_multipler","1.0","Gold multiplier");
}


public OnWar3Event(W3EVENT:event,client)
{
	if(event==OnPreGiveXPGold)
	{
		W3SetVar(EventArg2,FloatMul(W3GetVar(EventArg2),GetConVarFloat(MultiplierCVars[0])));
		W3SetVar(EventArg3,FloatMul(W3GetVar(EventArg3),GetConVarFloat(MultiplierCVars[1])));
	}
}