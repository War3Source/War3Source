#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Skill Dependencys",
    author = "War3Source Team",
    description = "Make skills depend on each other"
};

// holds informations about the skill dependency id(0) and required level(1)
new skillDependency[MAXRACES][MAXSKILLCOUNT][2];

public bool:InitNativesForwards()
{
    // Adds an dependency on the given skill
    CreateNative("War3_SetDependency",NWar3_AddDependency);
    // Removes all dependencys from a skill
    CreateNative("War3_RemoveDependency",NWar3_RemDependency);
    // Returns various informations about the dependency
    CreateNative("War3_GetDependency",NWar3_GetDependency);
    return true;
}

public NWar3_AddDependency(Handle:plugin,numParams)
{
    if(numParams != 4) {
        return ThrowNativeError(SP_ERROR_NATIVE,"numParams is invalid!");
    }
    new iRace = GetNativeCell(1);
    if(iRace>0) {
        new iSkill = GetNativeCell(2);
        new iOtherId = GetNativeCell(3);
        new iOtherLevel = GetNativeCell(4);
        if(iOtherLevel>0) {
            skillDependency[iRace][iSkill][SkillDependency:ID] = iOtherId;
            skillDependency[iRace][iSkill][SkillDependency:LVL] = iOtherLevel;
            return 1;
        }
        return 0;
    }
    else return ThrowNativeError(SP_ERROR_NATIVE,"race is invalid!");
}

public NWar3_RemDependency(Handle:plugin,numParams)
{
    if(numParams != 2) {
        return ThrowNativeError(SP_ERROR_NATIVE,"numParams is invalid!");
    }
    new iRace = GetNativeCell(1);
    if(iRace>0) {
        new iSkill = GetNativeCell(2);
        for(new x=0;x<2;x++)
        {
            skillDependency[iRace][iSkill][x] = INVALID_DEPENDENCY;
        }
        return 1;
    }
    else return ThrowNativeError(SP_ERROR_NATIVE,"race is invalid!");
}

public NWar3_GetDependency(Handle:plugin,numParams)
{
    if(numParams != 3) {
        return ThrowNativeError(SP_ERROR_NATIVE,"numParams is invalid!");
    }
    new iRace = GetNativeCell(1);
    if(iRace>0) {
        new iSkill = GetNativeCell(2);
        new iIndex = GetNativeCell(3);
        return skillDependency[iRace][iSkill][iIndex];
    }
    else return ThrowNativeError(SP_ERROR_NATIVE,"race is invalid!");
}