#pragma semicolon 1

#include "W3SIncs/War3Source_Interface"
#include <regex>

public Plugin:myinfo =
{
    name = "War3Source - Engine - XP Gold",
    author = "War3Source Team",
    description = "Give XP and Gold to those who deserve it"
};

new String:levelupSound[256]; //="war3source/levelupcaster.mp3";

///MAXLEVELXPDEFINED is in constants
new XPLongTermREQXP[MAXLEVELXPDEFINED+1]; //one extra for even if u reached max level
new XPLongTermKillXP[MAXLEVELXPDEFINED+1];
new XPShortTermREQXP[MAXLEVELXPDEFINED+1];
new XPShortTermKillXP[MAXLEVELXPDEFINED+1];

// not game specific
new Handle:HeadshotXPCvar;
new Handle:MeleeXPCvar;
new Handle:RoundWinXPCvar;
new Handle:AssistKillXPCvar;
new Handle:BotIgnoreXPCvar;
new Handle:hBotXPRate;
new Handle:hLevelDifferenceBounus;
new Handle:hMaxLevelDifferenceBounus;
new Handle:hTotalLevelDifferenceBounus;
new Handle:hTotalMaxLevelDifferenceBounus;
new Handle:minplayersXP;
new Handle:NoSpendSkillsLimitCvar;

// l4d
new Handle:KillSmokerXPCvar;
new Handle:KillBoomerXPCvar;
new Handle:KillHunterXPCvar;
new Handle:KillJockeyXPCvar;
new Handle:KillSpitterXPCvar;
new Handle:KillChargerXPCvar;
new Handle:KillCommonXPCvar;
new Handle:KillUncommonXPCvar;

//gold
new Handle:g_hKillCurrencyCvar;
new Handle:g_hAssistCurrencyCvar;

public OnPluginStart()
{
    LoadTranslations("w3s.engine.xpgold.txt");

    BotIgnoreXPCvar = CreateConVar("war3_ignore_bots_xp", "0", "Set to 1 to not award XP for killing bots");
    hBotXPRate = CreateConVar("war3_bot_xp_modifier", "1.0", "The XP gained from killing bots is multiplied with this value");
    HeadshotXPCvar = CreateConVar("war3_percent_headshotxp","20","Percent of kill XP awarded additionally for headshots");
    MeleeXPCvar = CreateConVar("war3_percent_meleexp", "120", "Percent of kill XP awarded additionally for melee/knife kills");
    AssistKillXPCvar = CreateConVar("war3_percent_assistkillxp", "75", "Percent of kill XP awarded for an assist kill.");

    RoundWinXPCvar = CreateConVar("war3_percent_roundwinxp", "100", "Percent of kill XP awarded for being on the winning team");

    hLevelDifferenceBounus = CreateConVar("war3_xp_level_difference_bonus", "0", "Bonus Xp awarded per level if victim has a higher level");
    hMaxLevelDifferenceBounus = CreateConVar("war3_xp_level_difference_max_bonus", "0", "Where to cap the bonus XP at. 0 to disable");

    hTotalLevelDifferenceBounus = CreateConVar("war3_xp_total_level_difference_bonus","0","Bonus XP awarded per level if attacker has a higher total level");
    hTotalMaxLevelDifferenceBounus = CreateConVar("war3_xp_total_level_difference_max_bonus","0","Where to cap the bonus total level XP at. 0.0 to disable");


    minplayersXP = CreateConVar("war3_min_players_xp_gain", "2", "minimum amount of players needed on teams for people to gain xp");

    g_hKillCurrencyCvar = CreateConVar("war3_currency_per_kill", "2");
    g_hAssistCurrencyCvar = CreateConVar("war3_currency_per_assist", "1");

    ParseXPSettingsFile();

    // l4d
    KillSmokerXPCvar = CreateConVar("war3_l4d_smokerxp","50","XP awarded to a player killing a Smoker");
    KillBoomerXPCvar = CreateConVar("war3_l4d_boomerxp","50","XP awarded to a player killing a Boomer");
    KillHunterXPCvar = CreateConVar("war3_l4d_hunterxp","50","XP awarded to a player killing a Hunter");
    KillJockeyXPCvar = CreateConVar("war3_l4d_jockeyexp","50","XP awarded to a player killing a Jockey");
    KillSpitterXPCvar = CreateConVar("war3_l4d_spitterxp","50","XP awarded to a player killing a Spitter");
    KillChargerXPCvar = CreateConVar("war3_l4d_chargerexp","50","XP awarded to a player killing a Charger");
    KillCommonXPCvar = CreateConVar("war3_l4d_commonexp","5","XP awarded to a player killing a common infected");
    KillUncommonXPCvar = CreateConVar("war3_l4d_uncommonexp","10","XP awarded to a player killing a uncommon infected");

    if(GAMECSANY)
    {
        if(!HookEventEx("round_end", War3Source_RoundOverEvent))
        {
            War3_LogError("Could not hook the round_end event.");
        }
    }
    else if(GAMETF)
    {
        if(!HookEventEx("teamplay_round_win",War3Source_RoundOverEvent))
        {
            War3_LogError("Could not hook the teamplay_round_win event.");
        }
    }
}

public OnMapStart()
{
    War3_AddSoundFolder(levelupSound, sizeof(levelupSound), "levelupcaster.mp3");
    War3_AddCustomSound(levelupSound);
}

public bool:InitNativesForwards()
{
    CreateNative("W3GetReqXP" ,NW3GetReqXP);
    CreateNative("War3_ShowXP",Native_War3_ShowXP);
    CreateNative("W3GetKillXP",NW3GetKillXP);

    CreateNative("War3_GetKillCurrency", Native_War3_GetKillCurrency);
    CreateNative("War3_GetAssistCurrency",Native_War3_GetAssistCurrency);
    CreateNative("W3GiveXPGold",NW3GiveXPGold);

    CreateNative("W3GiveFakeXPGold",NW3GiveFakeXPGold);

    return true;
}

public NW3GetReqXP(Handle:plugin, numParams)
{
    new level = GetNativeCell(1);
    if(level > MAXLEVELXPDEFINED)
    {
        level = MAXLEVELXPDEFINED;
    }
    return IsShortTerm() ? XPShortTermREQXP[level] : XPLongTermREQXP[level];
}

public NW3GetKillXP(Handle:plugin, numParams)
{
    new client=GetNativeCell(1);
    new race=War3_GetRace(client);
    if(race>0){
        new level=War3_GetLevel(client,race);
        if(level>MAXLEVELXPDEFINED)
            level=MAXLEVELXPDEFINED;
        new leveldiff=    GetNativeCell(2);
        new totalleveldiff = GetNativeCell(3);

        if(leveldiff<0) leveldiff=0;
        if(totalleveldiff<0) totalleveldiff=0;

        new xp_to_give = IsShortTerm() ? XPShortTermKillXP[level] : XPLongTermKillXP[level];
        new bonus_xp = GetConVarInt(hLevelDifferenceBounus) * leveldiff;
        new max_bonus_xp = GetConVarInt(hMaxLevelDifferenceBounus);

        if ((max_bonus_xp != 0) && (max_bonus_xp < bonus_xp))
        {
            bonus_xp = max_bonus_xp;
        }

        new total_bonus_xp = GetConVarInt(hTotalLevelDifferenceBounus) * leveldiff;
        new total_max_bonus_xp = GetConVarInt(hTotalMaxLevelDifferenceBounus);

        if ((total_max_bonus_xp != 0) && (total_max_bonus_xp < total_bonus_xp))
        {
            total_bonus_xp = total_max_bonus_xp;
        }

        return xp_to_give + bonus_xp + total_bonus_xp;
    }
    return 0;
}
public Native_War3_ShowXP(Handle:plugin,numParams)
{
    ShowXP(GetNativeCell(1));
}
public NW3GiveXPGold(Handle:plugin,args){
    new client=GetNativeCell(1);
    new W3XPAwardedBy:awardby=W3XPAwardedBy:GetNativeCell(2);
    new xp=GetNativeCell(3);
    new gold=GetNativeCell(4);
    new String:strreason[64];
    GetNativeString(5,strreason,sizeof(strreason));
    TryToGiveXPGold(client,awardby,xp,gold,strreason,false);
}
public NW3GiveFakeXPGold(Handle:plugin,args){
    new clientIndex=GetNativeCell(1);
    new victimIndex=GetNativeCell(2);
    new assisterIndex=GetNativeCell(3);
    new W3XPAwardedBy:awardby=W3XPAwardedBy:GetNativeCell(4);
    new xp=GetNativeCell(5);
    new gold=GetNativeCell(6);
    new String:strreason[64];
    GetNativeString(7,strreason,sizeof(strreason));
    new bool:extra1=bool:GetNativeCell(8);
    new bool:extra2=bool:GetNativeCell(9);
    const bool:IsFake=true;
    if(awardby==XPAwardByKill && gold==0 && xp==0)
    {
        // extra1 = is_headshot
        // extra2 = is_melee
        GiveKillXPCreds(clientIndex,victimIndex,extra1,extra2, IsFake);
        return;
    }
    if(awardby==XPAwardByAssist && gold==0 && xp==0)
    {
        GiveAssistKillXP(assisterIndex, victimIndex, IsFake);
        return;
    }
    TryToGiveXPGold(clientIndex,awardby,xp,gold,strreason, IsFake);
}

// Todo, Hook convar changed
public Native_War3_GetKillCurrency(Handle:plugin, args)
{
    return GetConVarInt(g_hKillCurrencyCvar);
}

public Native_War3_GetAssistCurrency(Handle:plugin, args)
{
    return GetConVarInt(g_hAssistCurrencyCvar);
}
int ExplodeStringEx(const char[] text, char split, char[][] buffer, int maxStrings, int maxStringLength)
{
    int i;
    int j;
    int index;
    bool inString = false;
    while(text[index] != '\0')
    {
        if(i == maxStrings)
        {
            break;
        }
        if(text[index] != split)
        {
            inString = true;
            if(j == maxStringLength - 2)
            {
                buffer[i][j] = '\0';
                j++;
            }
            else
            {
                buffer[i][j] = text[index];
                j++;
            }
        }
        else
        {
            if(inString)
            {
                if(j != maxStringLength -1)
                {
                    buffer[i][j] = '\0';
                }
                i++;
                j = 0;
                inString = false;
            }
        }
        index++;
    }
    return i;
}
void LevelStringToArray(char[] levelString, int[] levelArray)
{
    char buffer[MAXLEVELXPDEFINED][16];
    int tokencount = ExplodeStringEx(levelString, ' ', buffer, sizeof(buffer), sizeof(buffer[]));
    for(new x = 0; x < MAXLEVELXPDEFINED; x++)
    {
        if(x < tokencount)
        {
            levelArray[x] = StringToInt(buffer[x]);
        }
        else
        {
            levelArray[x] = StringToInt(buffer[tokencount - 1]);   
        }
    }
}
ParseXPSettingsFile(){
    new Handle:keyValue=CreateKeyValues("War3SourceSettings");
    decl String:path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM,path,sizeof(path),"configs/war3source.ini");
    FileToKeyValues(keyValue,path);
    // Load level configuration
    KvRewind(keyValue);

    if(!KvJumpToKey(keyValue,"levels"))
	{
        SetFailState("error, key value for levels configuration not found");
        return false;
	}


    decl String:buffer[2048];
    if(!KvGotoFirstSubKey(keyValue))
    {
        SetFailState("sub key failed");
        return false;
    }

    // required xp, long term
    KvGetString(keyValue, "required_xp", buffer, sizeof(buffer));
    LevelStringToArray(buffer, XPLongTermREQXP);
    
    // kill xp, long term
    KvGetString(keyValue, "kill_xp", buffer, sizeof(buffer));
    LevelStringToArray(buffer, XPLongTermKillXP);

    if(!KvGotoNextKey(keyValue))
	{
		SetFailState("XP No Next key");
		return false;
	}
    
    // required xp, short term
    KvGetString(keyValue, "required_xp", buffer, sizeof(buffer));
    LevelStringToArray(buffer, XPShortTermREQXP);

    // kill xp, short term
    KvGetString(keyValue, "kill_xp", buffer, sizeof(buffer));
    LevelStringToArray(buffer, XPShortTermKillXP);

    return true;
}




public ShowXP(client)
{
    SetTrans(client);
    new race=War3_GetRace(client);
    if(race==0)
    {
        //if(bXPLoaded[client])
        War3_ChatMessage(client,"%T","You must first select a race with changerace!",client);
        return;
    }
    new level=War3_GetLevel(client,race);
    decl String:racename[64];
    War3_GetRaceName(race,racename,sizeof(racename));
    if(level<W3GetRaceMaxLevel(race))
        War3_ChatMessage(client,"%T","{racename} - Level {amount} - {amount} XP / {amount} XP",client,racename,level,War3_GetXP(client,race),W3GetReqXP(level+1));
    else
        War3_ChatMessage(client,"%T","{racename} - Level {amount} - {amount} XP",client,racename,level,War3_GetXP(client,race));
}
//main plugin forwards this, does not forward on spy dead ringer, blocks double forward within same frame of same victim
public OnWar3EventDeath(victim,attacker){
    new Handle:event=W3GetVar(SmEvent);
    new bool:killed_by_headshot=false,bool:killed_by_melee=false;
    const bool:is_reward_fake=false;
    if(GAMEL4DANY)
    {
        if (attacker > 0 && GetClientTeam(attacker) == TEAM_SURVIVORS)
        {

            new bool:is_headshot = GetEventBool(event,"headshot");

            decl String:victimclass[32];
            GetEventString(event, "victimname", victimclass, sizeof(victimclass));

            if (StrEqual(victimclass, "Infected"))
            {
                if (War3_IsUncommonInfected(GetEventInt(event, "entityid")))
                {
                    new addxp = GetConVarInt(KillUncommonXPCvar);
                    if(is_headshot) addxp += ((addxp*GetConVarInt(HeadshotXPCvar))/100);

                    new String:killaward[64];
                    Format(killaward,sizeof(killaward),"%T","killing a uncommon infected",attacker);
                    W3GiveXPGold(attacker,XPAwardByKill,addxp,0,killaward);
                }
                else
                {
                    new addxp = GetConVarInt(KillCommonXPCvar);
                    if(is_headshot) addxp += ((addxp*GetConVarInt(HeadshotXPCvar))/100);

                    new String:killaward[64];
                    Format(killaward,sizeof(killaward),"%T","killing a common infected",attacker);
                    W3GiveXPGold(attacker,XPAwardByKill,addxp,0,killaward);
                }
            }
            else if (StrEqual(victimclass, "Smoker"))
            {
                new addxp = GetConVarInt(KillSmokerXPCvar);
                new currencyToAdd = GetConVarInt(g_hKillCurrencyCvar);
                if(is_headshot) addxp += ((addxp*GetConVarInt(HeadshotXPCvar))/100);

                new String:killaward[64];
                Format(killaward,sizeof(killaward),"%T","killing a Smoker",attacker);

                if (ValidPlayer(victim) && IsFakeClient(victim))
                    W3GiveXPGold(attacker,XPAwardByKill,addxp,currencyToAdd,killaward);
                else
                    GiveKillXPCreds(attacker, victim, killed_by_headshot, killed_by_melee, is_reward_fake);
            }
            else if (StrEqual(victimclass, "Boomer"))
            {
                new addxp = GetConVarInt(KillBoomerXPCvar);
                new currencyToAdd = GetConVarInt(g_hKillCurrencyCvar);
                if(is_headshot) addxp += ((addxp*GetConVarInt(HeadshotXPCvar))/100);

                new String:killaward[64];
                Format(killaward,sizeof(killaward),"%T","killing a Boomer",attacker);

                if (ValidPlayer(victim) && IsFakeClient(victim))
                    W3GiveXPGold(attacker,XPAwardByKill,addxp,currencyToAdd,killaward);
                else
                    GiveKillXPCreds(attacker, victim, killed_by_headshot, killed_by_melee, is_reward_fake);
            }
            else if (StrEqual(victimclass, "Witch"))
            {
                return; // witch is handled in its own event
            }
            else if (StrEqual(victimclass, "Tank"))
            {
                return; // tank is handled in its own event
            }
            else if (StrEqual(victimclass, "Hunter"))
            {
                new addxp = GetConVarInt(KillHunterXPCvar);
                new currencyToAdd = GetConVarInt(g_hKillCurrencyCvar);
                if(is_headshot) addxp += ((addxp*GetConVarInt(HeadshotXPCvar))/100);

                new String:killaward[64];
                Format(killaward,sizeof(killaward),"%T","killing a Hunter",attacker);

                if (ValidPlayer(victim) && IsFakeClient(victim))
                    W3GiveXPGold(attacker,XPAwardByKill,addxp,currencyToAdd,killaward);
                else
                    GiveKillXPCreds(attacker, victim, killed_by_headshot, killed_by_melee, is_reward_fake);
            }
            else if (StrEqual(victimclass, "Spitter"))
            {
                new addxp = GetConVarInt(KillSpitterXPCvar);
                new currencyToAdd = GetConVarInt(g_hKillCurrencyCvar);
                if(is_headshot) addxp += ((addxp*GetConVarInt(HeadshotXPCvar))/100);

                new String:killaward[64];
                Format(killaward,sizeof(killaward),"%T","killing a Spitter",attacker);

                if (ValidPlayer(victim) && IsFakeClient(victim))
                    W3GiveXPGold(attacker,XPAwardByKill,addxp,currencyToAdd,killaward);
                else
                    GiveKillXPCreds(attacker, victim, killed_by_headshot, killed_by_melee, is_reward_fake);
            }
            else if (StrEqual(victimclass, "Jockey"))
            {
                new addxp = GetConVarInt(KillJockeyXPCvar);
                new currencyToAdd = GetConVarInt(g_hKillCurrencyCvar);
                if(is_headshot) addxp += ((addxp*GetConVarInt(HeadshotXPCvar))/100);

                new String:killaward[64];
                Format(killaward,sizeof(killaward),"%T","killing a Jockey",attacker);

                if (ValidPlayer(victim) && IsFakeClient(victim))
                    W3GiveXPGold(attacker,XPAwardByKill,addxp,currencyToAdd,killaward);
                else
                    GiveKillXPCreds(attacker, victim, killed_by_headshot, killed_by_melee, is_reward_fake);
            }
            else if (StrEqual(victimclass, "Charger"))
            {
                new addxp = GetConVarInt(KillChargerXPCvar);
                new currencyToAdd = GetConVarInt(g_hKillCurrencyCvar);
                if(is_headshot) addxp += ((addxp*GetConVarInt(HeadshotXPCvar))/100);

                new String:killaward[64];
                Format(killaward,sizeof(killaward),"%T","killing a Charger",attacker);

                if (ValidPlayer(victim) && IsFakeClient(victim))
                    W3GiveXPGold(attacker,XPAwardByKill,addxp,currencyToAdd,killaward);
                else
                    GiveKillXPCreds(attacker, victim, killed_by_headshot, killed_by_melee, is_reward_fake);
            }
        }
        // finished with l4d xp stuff, everything else is related to other games
        return;
    }

    //DP("get event %d",event);
    new assister=0;
    if(War3_GetGame()==Game_TF)
    {
        assister=GetClientOfUserId(GetEventInt(event,"assister"));
    }

    if(victim!=attacker&&ValidPlayer(attacker))
    {

        if(GetClientTeam(attacker)!=GetClientTeam(victim))
        {
            decl String:weapon[64];
            GetEventString(event,"weapon",weapon,sizeof(weapon));
            if(IsFakeClient(victim) && GetConVarBool(BotIgnoreXPCvar))
                return;
            if(War3_GetGame()==Game_TF)
            {
                killed_by_headshot=(GetEventInt(event,"customkill")==1);

            }
            else
            {
                killed_by_headshot=GetEventBool(event,"headshot");

            }
            //DP("wep %s",weapon);
            killed_by_melee=W3IsDamageFromMelee(weapon);
            //DP("me %d",is_melee);
            /*(StrEqual(weapon,"bat",false) ||
                    StrEqual(weapon,"bat_wood",false) ||
                    StrEqual(weapon,"bonesaw",false) ||
                    StrEqual(weapon,"bottle",false) ||
                    StrEqual(weapon,"club",false) ||
                    StrEqual(weapon,"fireaxe",false) ||
                    StrEqual(weapon,"fists",false) ||
                    StrEqual(weapon,"knife",false) ||
                    StrEqual(weapon,"lunchbox",false) ||
                    StrEqual(weapon,"shovel",false) ||
                    StrEqual(weapon,"wrench",false));

                    is_melee=StrEqual(weapon,"knife");*/

            if(assister>=0 && War3_GetRace(assister)>0)
            {
                GiveAssistKillXP(assister, victim, is_reward_fake);
            }

            GiveKillXPCreds(attacker, victim, killed_by_headshot, killed_by_melee, is_reward_fake);
        }
    }

}
public War3Source_RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{

// cs - int winner
// tf2 - int team
    new team=-1;
    if(War3_GetGame()==Game_TF)
    {
        team=GetEventInt(event,"team");
    }
    else
    {
        team=GetEventInt(event,"winner");
    }
    if(team>-1)
    {
        for(new i=1;i<=MaxClients;i++)
        {

            if(ValidPlayer(i)&&  GetClientTeam(i)==team)
            {
                new addxp=((  W3GetKillXP(i)*GetConVarInt(RoundWinXPCvar)  )/100);

                new String:teamwinaward[64];
                Format(teamwinaward,sizeof(teamwinaward),"%T","being on the winning team",i);
                W3GiveXPGold(i,XPAwardByWin,addxp,0,teamwinaward);

            }
        }
    }
}















TryToGiveXPGold(client, W3XPAwardedBy:XPAwardEvent, baseXPToAdd, baseCurrencyToAdd, String:awardedprintstring[], bool:IsFake)
{
    SetTrans(client);
    new race = War3_GetRace(client);
    if(race <= 0)
    {
        ShowChangeRaceMenu(client);
        return;
    }

    if(GetConVarInt(minplayersXP) > PlayersOnTeam(2) + PlayersOnTeam(3))
    {
        War3_ChatMessage(client, "%T", "No XP is given when less than {amount} players are playing", client, GetConVarInt(minplayersXP));
        return;
    }

    W3SetVar(EventArg1, XPAwardEvent);
    W3SetVar(EventArg2, baseXPToAdd);
    W3SetVar(EventArg3, baseCurrencyToAdd);
    W3CreateEvent(OnPreGiveXPGold, client);

    new XPToAdd = W3GetVar(EventArg2);
    new currencyToAdd = W3GetVar(EventArg3);

    if(XPToAdd < 0 && War3_GetXP(client, War3_GetRace(client)) + XPToAdd < 0)
    {
        XPToAdd = -1 * War3_GetXP(client, War3_GetRace(client));
    }
    new bool:bAddedCurrency;
    if(!IsFake)
    {
        War3_SetXP(client, race, War3_GetXP(client, War3_GetRace(client)) + XPToAdd);
        bAddedCurrency = War3_AddCurrency(client, currencyToAdd);
    }
    else
    {
        bAddedCurrency=true;
    }

    decl String:currencyName[MAX_CURRENCY_NAME];
    War3_GetCurrencyName(currencyToAdd, currencyName, sizeof(currencyName));

    // This needs to be redone at some point, so you can GAIN experience and at the same time LOSE money without it looking awkward
    if(XPToAdd > 0 && bAddedCurrency)
    {
        War3_ChatMessage(client, "%T", "You have gained {amount} XP and {amount} {currencyName} for {award}", client, XPToAdd, currencyToAdd, currencyName, awardedprintstring);
    }
    else if(XPToAdd > 0)
    {
        War3_ChatMessage(client,"%T","You have gained {amount} XP for {award}",client, XPToAdd, awardedprintstring);
    }
    else if(bAddedCurrency)
    {
        War3_ChatMessage(client, "%T", "You have gained {amount} {currencyName} for {award}", client, currencyToAdd, currencyName, awardedprintstring);
    }

    else if(XPToAdd < 0 && bAddedCurrency)
    {
        War3_ChatMessage(client, "%T","You have lost {amount} XP and {amount} {currencyName} for {award}", client, XPToAdd, currencyToAdd, currencyName, awardedprintstring);
    }
    else if(XPToAdd < 0)
    {
        War3_ChatMessage(client, "%T", "You have lost {amount} XP for {award}", client, XPToAdd, awardedprintstring);
    }
    else if(bAddedCurrency)
    {
        War3_ChatMessage(client, "%T", "You have lost {amount} {currencyName} for {award}", client, currencyToAdd, currencyName, awardedprintstring);
    }

    // in case they didn't level any skills
    W3DoLevelCheck(client);
    W3CreateEvent(OnPostGiveXPGold, client);
}

GiveKillXPCreds(client, playerkilled, bool:headshot, bool:melee, bool:IsFake)
{
    new race = War3_GetRace(client);
    if(race <= 0)
    {
        ShowChangeRaceMenu(client);
        return;
    }

    new killerlevel = War3_GetLevel(client, War3_GetRace(client));
    new victimlevel = War3_GetLevel(playerkilled, War3_GetRace(playerkilled));

    new killertotallevel = W3GetTotalLevels(client);
    new victimtotallevel = W3GetTotalLevels(playerkilled);


    new killxp = W3GetKillXP(client, victimlevel - killerlevel, victimtotallevel - killertotallevel);

    new addxp = killxp;
    if(headshot)
    {
        addxp += ((killxp * GetConVarInt(HeadshotXPCvar)) / 100);
    }
    if(melee)
    {
        addxp += ((killxp * GetConVarInt(MeleeXPCvar)) / 100);
    }

    if(IsFakeClient(playerkilled))
    {
        addxp = RoundToCeil(addxp * GetConVarFloat(hBotXPRate));
    }

    new String:killaward[64];
    Format(killaward, sizeof(killaward), "%T", "a kill", client);
    TryToGiveXPGold(client, XPAwardByKill, addxp, War3_GetKillCurrency(), killaward, IsFake);
}

GiveAssistKillXP(client, playerkilled, bool:IsFake)
{
    new addxp=((W3GetKillXP(client)*GetConVarInt(AssistKillXPCvar))/100);

    if(IsFakeClient(playerkilled))
    {
        addxp = RoundToCeil(addxp * GetConVarFloat(hBotXPRate));
    }


    new String:helpkillaward[64];
    Format(helpkillaward, sizeof(helpkillaward), "%T","assisting a kill", client);
    TryToGiveXPGold(client ,XPAwardByAssist, addxp, War3_GetAssistCurrency(), helpkillaward, IsFake);
}

bool:IsShortTerm(){
    return GetConVarInt(Handle:W3GetVar(hSaveEnabledCvar))?false:true;
}















public OnWar3Event(W3EVENT:event,client){
    if(event==DoLevelCheck){
        LevelCheck(client);
    }
}


LevelCheck(client){
    new race=War3_GetRace(client);
    if(race>0){
        new skilllevel;

        new ultminlevel=W3GetMinUltLevel();

        ///skill or ult is more than what he can be? ie level 4 skill when he is only level 4...
        new curlevel=War3_GetLevel(client,race);
        new SkillCount = War3_GetRaceSkillCount(race);
        for(new i=1;i<=SkillCount;i++){
            skilllevel=War3_GetSkillLevelINTERNAL(client,race,i);
            if(!War3_IsSkillUltimate(race,i))
            {
            // El Diablo: I want to be able to allow skills to reach maximum skill level via skill points.
            //            I do not want to put a limit on skill points because of the
            //            direction I'm going with my branch of the war3source.
                NoSpendSkillsLimitCvar=FindConVar("war3_no_spendskills_limit");
                if (!GetConVarBool(NoSpendSkillsLimitCvar))
                {
                    if(skilllevel*2>curlevel+1)
                    {
                     ClearSkillLevels(client,race);
                     War3_ChatMessage(client,"%T","A skill is over the maximum level allowed for your current level, please reselect your skills",client);
                     W3CreateEvent(DoShowSpendskillsMenu,client);
                    }
                }
            }
            else
            {
            // El Diablo: Currently keeping the limit on the ultimates
                if(skilllevel>0&&skilllevel*2+ultminlevel-1>curlevel+1){
                    ClearSkillLevels(client,race);
                    War3_ChatMessage(client,"%T","A ultimate is over the maximum level allowed for your current level, please reselect your skills",client);
                    W3CreateEvent(DoShowSpendskillsMenu,client);
                }
            }
        }



        ///seting xp or level recurses!!! SET XP FIRST!! or you will have a cascading level increment
        new keepchecking=true;
        while(keepchecking)
        {
            curlevel=War3_GetLevel(client,race);
            if(curlevel<W3GetRaceMaxLevel(race))
            {

                if(War3_GetXP(client,race)>=W3GetReqXP(curlevel+1))
                {
                    //PrintToChatAll("LEVEL %d xp %d reqxp=%d",curlevel,War3_GetXP(client,race),ReqLevelXP(curlevel+1));

                    War3_ChatMessage(client,"%T","You are now level {amount}",client,War3_GetLevel(client,race)+1);

                    new newxp=War3_GetXP(client,race)-W3GetReqXP(curlevel+1);
                    War3_SetXP(client,race,newxp); //set xp first, else infinite level!!! else u set level xp is same and it tries to use that xp again

                    War3_SetLevel(client,race,War3_GetLevel(client,race)+1);



                    //War3Source_SkillMenu(client);

                    //PrintToChatAll("LEVEL %d  xp2 %d",War3_GetXP(client,race),ReqLevelXP(curlevel+1));
                    if(IsPlayerAlive(client)){
                        EmitSoundToAllAny(levelupSound,client);
                    }
                    else{
                        EmitSoundToClientAny(client,levelupSound);
                    }
                    W3CreateEvent(PlayerLeveledUp,client);
                }
                else{
                    keepchecking=false;
                }
            }
            else{
                keepchecking=false;
            }

        }

        if(W3GetLevelsSpent(client,race)<War3_GetLevel(client,race)){
            //War3Source_SkillMenu(client);
            W3CreateEvent(DoShowSpendskillsMenu,client);
        }
    }
}


ClearSkillLevels(client,race){
    new SkillCount =War3_GetRaceSkillCount(race);
    for(new i=1; i <= SkillCount; i++)
    {
        War3_SetSkillLevelINTERNAL(client, race, i, 0);
    }
}
