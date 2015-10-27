#pragma semicolon 1

#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Addon - Bot Control",
    author = "War3Source Team",
    description = "Make Bots integrate better into War3Source"
};

// ########################## BOT EVASION ################################
new Handle:botEvasionCvar = INVALID_HANDLE;

// ########################## BOT RACE/LEVEL SCRAMBLER ###################
new g_bEnabled;
new const MAX_RACE_PICK_ATTEMPTS = 100;

new Handle:g_hGiveBotsRaces = INVALID_HANDLE;
new Handle:g_hBotLevelCvar = INVALID_HANDLE;
new Handle:g_hBotScrambleRound = INVALID_HANDLE;
new Handle:g_hBotAnnounce = INVALID_HANDLE;
new Handle:g_hBotLevelRandom = INVALID_HANDLE;

// ########################## BOT ITEM CONFIG ############################
new Handle:botBuysItems = INVALID_HANDLE;
new Handle:botBuysRandomChance = INVALID_HANDLE;
new Handle:botBuysRandomMultipleChance = INVALID_HANDLE;
 
public OnPluginStart()
{
    // ########################## BOT EVASION ################################
    botEvasionCvar = CreateConVar("war3_bots_invisibility_gives_evasion", "1", "Should invisibility give evasion against bots?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    
    // ########################## BOT RACE/LEVEL SCRAMBLER ###################
    RegAdminCmd("war3_botscramble", RaceScrambler, ADMFLAG_SLAY, "war3_botscramble - Scrambles the bots races.");
    
    g_hGiveBotsRaces = CreateConVar("war3_bots_use_races", "1", "Enable/Disable races for bots");
    g_hBotLevelCvar = CreateConVar("war3_bots_scramble_level", "-1", "The level the bots should be scrambled to.");
    g_hBotLevelRandom = CreateConVar("war3_bots_scramble_random", "1", "Assign bots a random level up to war3_bots_scramble_level or just the defined level?");
    g_hBotScrambleRound = CreateConVar("war3_bots_scramble_on_round", "1", "Scramble bots each round?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hBotAnnounce = CreateConVar("war3_bots_scramble_announce", "1", "Announce the scrambling?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    
    g_bEnabled = GetConVarBool(g_hGiveBotsRaces);
    HookConVarChange(g_hGiveBotsRaces, ConVarChange_GiveBotsRaces);
    
    switch(War3_GetGame())
    {
        case Game_DOD, Game_CS, Game_CSGO:
        {
            HookEvent("round_start", Event_ScrambleNow);
        }
        case Game_TF:
        {
            HookEvent("teamplay_round_win", Event_ScrambleNow);
        }
        case Game_L4D2:
        {
            HookEvent("round_end", Event_ScrambleNow);
        }
    }
    
    // ########################## BOT ITEM CONFIG ############################
    botBuysItems = CreateConVar("war3_bots_buy_items", "1", "Can bots buy random items?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    botBuysRandomChance = CreateConVar("war3_bots_buy_random_chance", "70","Chance a bot will buy an item on spawn.", FCVAR_PLUGIN, true, 0.0, true, 100.0);
    botBuysRandomMultipleChance = CreateConVar("war3_bots_buy_random_multiple_chance", "0.8","Chance modifier that is applied each time a bot buys a item.", FCVAR_PLUGIN, true, 0.0, true, 100.0);
    
    LoadTranslations ("w3s.addon.botcontrol.phrases.txt");
}

public bool:InitNativesForwards()
{
    CreateNative("War3_bots_distribute_sp", Native_DistributeSkillpoints);
    CreateNative("War3_bots_pickrace", Native_PickRace);

    return true;
}

// ########################## CONVARS ######################################

public ConVarChange_GiveBotsRaces(Handle:convar, const String:oldValue[], const String:newValue[])
{
    g_bEnabled = StringToInt(newValue);
}

// ########################## BOT EVASION ################################
// Invisibility = Evasion
public OnW3TakeDmgAllPre(victim, attacker, Float:damage)
{
    if(ValidPlayer(victim, true) && ValidPlayer(attacker) && IsFakeClient(attacker) && 
       GetConVarBool(botEvasionCvar) && GetClientTeam(victim) != GetClientTeam(attacker) && 
       !W3GetBuffHasTrue(victim, bInvisibilityDenyAll) && !IsFakeClient(victim))
    {
        // Get the actual values
        new Float: fSkillVisibility = W3GetBuffMinFloat(victim, W3Buff:fInvisibilitySkill);
        new Float: fItemVisibility = W3GetBuffMinFloat(victim, W3Buff:fInvisibilityItem);
        new Float: fVictimVisibility;
        
        // Skill denied?
        if(W3GetBuffHasTrue(victim, bInvisibilityDenySkill))
        {
            fSkillVisibility = 1.0;
        }
        
        // Find the better value
        if (fSkillVisibility < fItemVisibility)
        {
            fVictimVisibility = fSkillVisibility;
        }
        else
        {
            fVictimVisibility = fItemVisibility;
        }
        
        // 1.0 = Total Visibility
        // 0.0 = Total Invisibility
        
        // I feel like you should get half your transparency as evasion
        // so 40% Alpha (= 60% "invisibility") should be 30% evasion.
        
        if(fVictimVisibility < 1.0)
        {
            new Float: fEvasion = (1.0 - fVictimVisibility) / 2;
            if(GetRandomFloat(0.0, 1.0) <= fEvasion)
            {
                War3_EvadeDamage(victim, attacker);
            }
        }
    }
}

// ########################## BOT RACE/LEVEL SCRAMBLER ###################
public Event_ScrambleNow(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(GetConVarBool(g_hBotScrambleRound))
    {
        ScrambleBots();
    }
}

public Action:RaceScrambler(client, args)
{
    ScrambleBots();
    
    return Plugin_Handled;
}

/**
 * Makes the bot attempt to pick a race
 */
public PickRace(client)
{
    if (!IsFakeClient(client) || (IsFakeClient(client) && !g_bEnabled))
    {
        return;
    }
    
    new attempts = 0;
    new race = -1;
    new racelist[MAXRACES];
    new size=W3GetRaceList(racelist);  //DOES NOT INCLUDE HIDDEN RACES ANYWAY
    while (attempts <= MAX_RACE_PICK_ATTEMPTS)
    {
        race = racelist[GetRandomInt(0, size-1)];
        
        if (!W3RaceHasFlag(race, "nobots")&&!W3RaceHasFlag(race, "hidden"))
        {
            break; //skip this block and allow the race
        }    
        
        attempts++;
    }
    //does not HANDLE when bot CANNOT select a race.........
    
    new level = 0;
    new race_max_level = W3GetRaceMaxLevel(race);
    new bot_level_allowed = GetConVarInt(g_hBotLevelCvar);
        
    if(bot_level_allowed == -1) // Give him max level?
    {
        level = race_max_level;
    }
    else
    {
        if (bot_level_allowed > race_max_level) // cvar higher than max for this race?
        {
            level = race_max_level;
        }
        else // use cvar value
        {
            level = bot_level_allowed;
        }
    }
    
    if(GetConVarInt(g_hBotLevelRandom) == 1)
    {
        level = GetRandomInt(0, level);
    }
    
    War3_SetRace(client, race);
    War3_SetLevel(client, race, level);
    DistributeSkillPoints(client);
}

ScrambleBots()
{
    if (!g_bEnabled)
    {
        return;
    }
    new bool:bNoBots = true;
    for(new client=1; client <= MaxClients; client++)
    {
        if(ValidPlayer(client) && IsFakeClient(client))
        {
            bNoBots = false;
            break;
        }
    }
    
    if(bNoBots)
    {
        return;
    }

    if(GetConVarBool(g_hBotAnnounce))
    {
        for(new client = 1; client <= MaxClients; ++client)
        {
            if (IsClientConnected(client) && IsClientInGame(client)&& !IsFakeClient(client))
            {
                War3_ChatMessage(client, "%T", "The bots races and levels have been scrambled.", client);
            }
        }
    }
    
    for(new client=1; client <= MaxClients; client++)
    {
        if(ValidPlayer(client) && IsFakeClient(client))
        {
            PickRace(client);
        }
    }
}

public DistributeSkillPoints(client)
{
    new race = War3_GetRace(client);
    new level = War3_GetLevel(client, race);
    new skillpoints = level;
    new ultLevel = W3GetMinUltLevel();

    // Subtract already spent skillpoints
    for(new i=0; i < War3_GetRaceSkillCount(race); i++)
    {
        skillpoints -= War3_GetSkillLevel(client, race, i);
    }
    
    if(skillpoints < 0)
    {
        for(new i=0; i < War3_GetRaceSkillCount(race); i++)
        {
            War3_SetSkillLevelINTERNAL(client, race, i, 0);     // Reset all skill points to zero
        }
        
        DistributeSkillPoints(client); // Start over
    }
    else
    {
        new skill;
        new skill_level;
        new skill_max_level;
        
        /* TODO: PUT INTO CVAR */
        new max_attempts = 50;
        new attempts = 0;
        while skillpoints > 0 && attempts <= max_attempts do
        {
            //PrintToServer("Applying skill points to bot (Attempt %i)", attempts);
            
            skill = GetRandomInt(0, War3_GetRaceSkillCount(race));
            skill_level = War3_GetSkillLevel(client, race, skill);
            skill_max_level = W3GetRaceSkillMaxLevel(race, skill);
            attempts++;
            
            //PrintToServer("Skill: %i, Level: %i, Max Level: %i", skill, skill_level, skill_max_level);
            
            if((War3_IsSkillUltimate(race, skill)) && (level < ultLevel))
            {
                //PrintToServer("STOPPING BECAUSE 1");
                continue;
            }
            else if(skill_level == skill_max_level)
            {
                //PrintToServer("STOPPING BECAUSE 2");
                continue;
            }
            else if(skill_level * 2 > level + 1)
            {
                //PrintToServer("STOPPING BECAUSE 3");
                continue;
            }
            else if(War3_IsSkillUltimate(race, skill) && (skill_level > 0) && ((skill_level * 2 + ultLevel -1) > (level + 1)))
            {
                //PrintToServer("STOPPING BECAUSE 4");
                continue;
            }
            else
            {
                War3_SetSkillLevelINTERNAL(client, race, skill, skill_level + 1);
                skillpoints--;
                attempts = 0;
            }
        }
    }
    
    W3DoLevelCheck(client);
}

public OnWar3Event(W3EVENT:event, client)
{
    if(event == PlayerLeveledUp)
    {
        if(IsFakeClient(client))
        {
            DistributeSkillPoints(client);
        }
    }
}

// ########################## BOT ITEM CONFIG ############################
public OnWar3EventSpawn(client)
{
    if(ValidPlayer(client) && IsFakeClient(client))
    {
        //W3IsPlayerXPLoaded(client) is for skipping until putin server is fired (which cleared variables)
        if(W3IsPlayerXPLoaded(client) && War3_GetRace(client) == 0)
        {
            PickRace(client);
        }
        if(GetConVarBool(botBuysItems))
        {    
            new Float:chance = GetConVarFloat(botBuysRandomChance);
            new Float:multipleChance = GetConVarFloat(botBuysRandomMultipleChance);
            new maxItems = GetConVarInt(FindConVar("war3_max_shopitems"));
            new items_holding = GetClientItemsOwned(client);
            
            while ( (GetRandomFloat(0.0, 100.0) <= chance) && (items_holding < maxItems) )
            {
                new item = GetRandomInt(0, W3GetItemsLoaded());
                
                // Set the event so the engine can still refuse the purchase
                // based on the bots gold or another addon
                W3SetVar(EventArg1, item);
                W3CreateEvent(DoTriedToBuyItem, client);
                
                chance *= multipleChance;
            }
        }
    }
}

// ########################## NATIVES ############################
public Native_PickRace(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    
    PickRace(client);
}

public Native_DistributeSkillpoints(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    
    DistributeSkillPoints(client);
}