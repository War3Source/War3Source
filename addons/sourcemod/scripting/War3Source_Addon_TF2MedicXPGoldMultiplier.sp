#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON

#include "W3SIncs/War3Source_Interface"  
#include <tf2_stocks>

public Plugin:myinfo = 
{
    name = "War3Source - Addon - Additional Medic XP/Gold",
    author = "War3Source Team",
    description = "Give medics more XP and gold when they assist someon"
};

public LoadCheck(){
    return GameTF();
}
new Handle:XPMultiplierCVar;
new Handle:GoldMultiplierCVar;

public OnPluginStart()
{
    
    if(War3_GetGame() == Game_TF){
    
        XPMultiplierCVar = CreateConVar("war3_tf2_medic_xp_muli","1.0","XP multiplier when a medic assists in a kill");
        GoldMultiplierCVar = CreateConVar("war3_tf2_medic_gold_muli","1.0","Gold multiplier when a medic assists in a kill");
    }
}

public OnWar3Event(W3EVENT:event,client)
{
    if(War3_GetGame()==Game_TF)
    {
        if(event==OnPreGiveXPGold)
        {
            new W3XPAwardedBy:awardevent = W3GetVar(EventArg1);
            new xp = W3GetVar(EventArg2);
            new gold = W3GetVar(EventArg3);
            
            if((awardevent==XPAwardByAssist)&&(TF2_GetPlayerClass(client) == TFClass_Medic))
            {
                W3SetVar(EventArg2,RoundToFloor(xp * GetConVarFloat(XPMultiplierCVar)));
                W3SetVar(EventArg3,RoundToFloor(gold * GetConVarFloat(GoldMultiplierCVar)));
            }
        }
    }
}