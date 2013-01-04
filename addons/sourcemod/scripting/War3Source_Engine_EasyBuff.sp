#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - EasyBuff",
    author = "War3Source Team",
    description = "Easily link together skills + buffs in War3Source"
};

new Handle:g_hBuffs = INVALID_HANDLE;
new Handle:g_hBuffArray = INVALID_HANDLE;
new Handle:g_hBuffRace = INVALID_HANDLE;
new Handle:g_hBuffSkill = INVALID_HANDLE;

public bool:InitNativesForwards()
{
    CreateNative("War3_AddSkillBuff", Native_War3_AddSkillBuff);
    
    return true;
}

public OnPluginStart()
{
    g_hBuffs = CreateArray(1);
    g_hBuffArray = CreateArray(32);
    g_hBuffRace = CreateArray(1);
    g_hBuffSkill = CreateArray(1);
}

public Native_War3_AddSkillBuff(Handle:plugin, numParams)
{
    new iRace = GetNativeCell(1);
    new iSkill = GetNativeCell(2);
    new W3Buff:Buff = GetNativeCell(3);
    
    PushArrayCell(g_hBuffRace, iRace);
    PushArrayCell(g_hBuffSkill, iSkill);
    PushArrayCell(g_hBuffs, Buff);
    
    new iSkillMaxLevel = W3GetRaceSkillMaxLevel(iRace, iSkill) + 1;
    
    new any:values[iSkillMaxLevel];
    GetNativeArray(4, values, iSkillMaxLevel);

    PushArrayArray(g_hBuffArray, values);
}

public OnWar3EventSpawn(client)
{
    InitSkills(client, War3_GetRace(client));
}

public OnSkillLevelChanged(client, race, skill, newskilllevel)
{
    InitSkills(client, race);
}

public OnWar3EventDeath(victim, client, deathrace)
{
    ResetSkills(victim, deathrace);
}

ResetSkills(client, race)
{
    for(new i = 0; i < GetArraySize(g_hBuffs); i++)
    {
        if(GetArrayCell(g_hBuffRace, i) == race)
        {
            W3ResetBuffRace(client, W3Buff:GetArrayCell(g_hBuffs, i), race);
        }
    }
}
public OnRaceChanged(client, oldrace, newrace)
{
	ResetSkills(client, oldrace);
	InitSkills(client, newrace);
}
InitSkills(client, race)
{
    for(new i = 0; i < GetArraySize(g_hBuffs); i++)
    {
        if(GetArrayCell(g_hBuffRace, i) == race)
        {
            new skill = War3_GetSkillLevel(client, race, GetArrayCell(g_hBuffSkill, i));
            
            War3_SetBuff(client, W3Buff:GetArrayCell(g_hBuffs, i), race, GetArrayCell(g_hBuffArray, i, skill));
        }
    }
}



