#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - EasyBuff",
    author = "War3Source Team",
    description = "Easily link together skills + buffs in War3Source"
};

// EasyBuffs for skills
new Handle:g_hSkillBuffs = INVALID_HANDLE; // Holds the W3Buff
new Handle:g_hBuffSkillValues = INVALID_HANDLE; // Holds the values
new Handle:g_hBuffRace = INVALID_HANDLE; // Holds the race id
new Handle:g_hBuffSkill = INVALID_HANDLE; // Holds the skill id

// EasyBuffs auras
new Handle:g_hAuraId = INVALID_HANDLE;

// EasyBuffs for items
new Handle:g_hItemBuffs = INVALID_HANDLE;  // Holds the W3Buff
new Handle:g_hItemBuffValue = INVALID_HANDLE; // Holds the value
new Handle:g_hBuffItem = INVALID_HANDLE; // Holds the item id

public bool:InitNativesForwards()
{
    CreateNative("War3_AddSkillBuff", Native_War3_AddSkillBuff);
    CreateNative("War3_AddAuraSkillBuff", Native_War3_AddSkillAuraBuff);
    CreateNative("War3_AddItemBuff", Native_War3_AddItemBuff);
    
    return true;
}

public OnPluginStart()
{
    g_hSkillBuffs = CreateArray(1);
    g_hBuffSkillValues = CreateArray(32); // If your skill has more than 32 levels you're out of luck 
    g_hBuffRace = CreateArray(1);
    g_hBuffSkill = CreateArray(1);
    
    g_hAuraId = CreateArray(1);
    
    g_hItemBuffs = CreateArray(1);
    g_hBuffItem = CreateArray(1);
    g_hItemBuffValue = CreateArray(1);
}

bool:AddSkillBuff()
{
    new iRace = GetNativeCell(1);
    new iSkill = GetNativeCell(2);
    new W3Buff:buff = GetNativeCell(3);
    
    for(new i = 0; i < GetArraySize(g_hSkillBuffs); i++)
    {
        if(GetArrayCell(g_hBuffRace, i) == iRace && 
           GetArrayCell(g_hBuffSkill, i) == iSkill &&
           GetArrayCell(g_hSkillBuffs, i) == buff)
        {
            War3_LogInfo("[SKILL] Skipping buff %i for skill \"{skill %i}\" in \"{race %i}\": Already exists!", buff, iSkill, iRace);
            return false;
        }
    }
    
    PushArrayCell(g_hBuffRace, iRace);
    PushArrayCell(g_hBuffSkill, iSkill);
    PushArrayCell(g_hSkillBuffs, buff);
    
    new iSkillMaxLevel = W3GetRaceSkillMaxLevel(iRace, iSkill) + 1;
    
    new any:values[iSkillMaxLevel];
    GetNativeArray(4, values, iSkillMaxLevel);

    PushArrayArray(g_hBuffSkillValues, values);

    War3_LogInfo("[SKILL] Created buff %i for skill \"{skill %i}\" in \"{race %i}\"", buff, iSkill, iRace);
    
    return true;
}

public Native_War3_AddSkillBuff(Handle:plugin, numParams)
{
    if(AddSkillBuff())
    {
        // This ain't a aura
        PushArrayCell(g_hAuraId, -1);
    }
}

public Native_War3_AddSkillAuraBuff(Handle:plugin, numParams)
{
    if(AddSkillBuff())
    {
        decl String:auraShortName[32];
        GetNativeString(5, auraShortName, sizeof(auraShortName));
        new Float:distance = GetNativeCell(6);
        new bool:bTrackOtherTeam = GetNativeCell(7);
        
        new iAuraID = W3RegisterAura(auraShortName, distance, bTrackOtherTeam);
        PushArrayCell(g_hAuraId, iAuraID);
        
        War3_LogInfo("[AURA] Registered aura ID %i", iAuraID);
    }
}

public Native_War3_AddItemBuff(Handle:plugin, numParams)
{
    new iItem = GetNativeCell(1);
    new W3Buff:buff = GetNativeCell(2);
    
    for(new i = 0; i < GetArraySize(g_hItemBuffs); i++)
    {
        if(GetArrayCell(g_hBuffItem, i) == iItem && 
           GetArrayCell(g_hItemBuffs, i) == buff)
        {
            War3_LogInfo("[ITEM] Skipping buff %i for item \"{item %i}\": Already exists!", buff, iItem);
            return;
        }
    }
    
    PushArrayCell(g_hBuffItem, iItem);
    PushArrayCell(g_hItemBuffs, buff);
    
    new any:value = GetNativeCell(3);
    PushArrayCell(g_hItemBuffValue, value);
    
    War3_LogInfo("[ITEM] Created buff %i for item \"{item %i}\"", buff, iItem);
}

/* SKILLS */

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

public OnRaceChanged(client, oldrace, newrace)
{
    ResetSkills(client, oldrace);
    InitSkills(client, newrace);
}

ResetSkills(client, race)
{
    for(new i = 0; i < GetArraySize(g_hSkillBuffs); i++)
    {
        if(GetArrayCell(g_hBuffRace, i) == race)
        {
            new iAuraID = GetArrayCell(g_hAuraId, i);
            
            if (iAuraID == -1)
            {
                new W3Buff:buff = W3Buff:GetArrayCell(g_hSkillBuffs, i);
                War3_LogInfo("[SKILL] Resetting the buff %i from race \"{race %i}\" on \"{client %i}\"", buff, race, client);
    
                W3ResetBuffRace(client, buff, race);
            }
            else 
            {
                War3_LogInfo("[AURA] Turning off aura %i from race \"{race %i}\" on \"{client %i}\"", iAuraID, race, client);

                W3SetAuraFromPlayer(iAuraID, client, false);
            }
        }
    }
}

InitSkills(client, race)
{
    for(new i = 0; i < GetArraySize(g_hSkillBuffs); i++)
    {
        if(GetArrayCell(g_hBuffRace, i) == race)
        {
            new iAuraID = GetArrayCell(g_hAuraId, i);
            new iSkill = GetArrayCell(g_hBuffSkill, i);
            new iLevel = War3_GetSkillLevel(client, race, iSkill);
            
            // Not a aura
            if (iAuraID == -1)
            {
                new W3Buff:buff = W3Buff:GetArrayCell(g_hSkillBuffs, i);
                new any:value = GetArrayCell(g_hBuffSkillValues, i, iLevel);
                War3_LogInfo("[SKILL] Giving buff %i with a magnitude of %f to player \"{client %i}\" (Playing race \"{race %i}\" with skill \"{skill %i}\" at level %i)", buff, value, client, race, iSkill, iLevel);

                War3_SetBuff(client, buff, race, value);
            }
            else
            {
                War3_LogInfo("[AURA] Activating aura %i on player \"{client %i}\" (Playing race \"{race %i}\" with skill \"{skill %i}\" at level %i)", iAuraID, client, race, iSkill, iLevel);

                W3SetAuraFromPlayer(iAuraID, client, true, iLevel);
            }
        }
    }
}

public OnW3PlayerAuraStateChanged(client, tAuraID, bool:inAura, level)
{
    for(new i = 0; i < GetArraySize(g_hSkillBuffs); i++)
    {
        if(GetArrayCell(g_hAuraId, i) == tAuraID)
        {
            new race = GetArrayCell(g_hBuffRace, i);
            new W3Buff:buff = W3Buff:GetArrayCell(g_hSkillBuffs, i);
            new iSkill = GetArrayCell(g_hBuffSkill, i);
            
            if(inAura)
            {
                new any:value = GetArrayCell(g_hBuffSkillValues, i, level);
                
                War3_SetBuff(client, buff, race, value);
                War3_LogInfo("[AURA] Giving buff %i with a magnitude of %f to player \"{client %i}\" (Aura from skill \"{skill %i}\" of race \"{race %i}\" at level %i)", buff, value, client, iSkill, race, level);
            }
            else
            {
                W3ResetBuffRace(client, buff, race);
                War3_LogInfo("[AURA] Resetting the buff %i caused by skill \"{skill %i}\" of race \"{race %i}\" on \"{client %i}\"", buff, iSkill, race, client);
            }
        }
    }
}

/* ITEMS */

public OnItemPurchase(client, item)
{
    InitItems(client, item);
}

public OnItemLost(client, item)
{ 
    ResetItems(client, item);
}

ResetItems(client, item)
{
    for(new i = 0; i < GetArraySize(g_hItemBuffs); i++)
    {
        if(GetArrayCell(g_hBuffItem, i) == item)
        {
            new W3Buff:buff = W3Buff:GetArrayCell(g_hItemBuffs, i);
            War3_LogInfo("[ITEM] Resetting the buff %i from item \"{item %i}\" on \"{client %i}\"", buff, item, client);

            W3ResetBuffItem(client, buff, item);
        }
    }
}

InitItems(client, item)
{
    for(new i = 0; i < GetArraySize(g_hItemBuffs); i++)
    {
        if(GetArrayCell(g_hBuffItem, i) == item)
        {
            new any:value = GetArrayCell(g_hItemBuffValue, i);
            new W3Buff:buff = W3Buff:GetArrayCell(g_hItemBuffs, i);
            
            War3_LogInfo("[ITEM] Giving buff %i with a magnitude of %f to player \"{client %i}\" (Owning item \"{item %i}\")", buff, value, client, item);
            War3_SetBuffItem(client, buff, item, value);
        }
    }
}