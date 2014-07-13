#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"  

public Plugin:myinfo = 
{
    name = "War3Source - Addon - XP Multiplier",
    author = "War3Source Team",
    description = "Easy XP/Gold rate handling with convars"
};

new Handle:MultiplierCVars[2];

public OnPluginStart()
{
    MultiplierCVars[0] = CreateConVar("war3_xp_multipler","1.0","XP multiplier");
    MultiplierCVars[1] = CreateConVar("war3_gold_multipler","1.0","Gold multiplier");
}


public OnWar3Event(W3EVENT:event,client)
{
    if(event==OnPreGiveXPGold)
    {
        W3SetVar(EventArg2,RoundToCeil(FloatMul(float(W3GetVar(EventArg2)),GetConVarFloat(MultiplierCVars[0]))));
        W3SetVar(EventArg3,RoundToCeil(FloatMul(float(W3GetVar(EventArg3)),GetConVarFloat(MultiplierCVars[1]))));
    }
}
