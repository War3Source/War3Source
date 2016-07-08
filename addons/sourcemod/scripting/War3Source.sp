// Release date is based on Month.Day.Year of when it was last changed
#define RELEASE_DATE "5/10/2014"

/*  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    War3source written by PimpinJuice (anthony) and Ownz (Dark Energy)
    All rights reserved.
*/

/*
* File: War3Source.sp
* Description: The main file for War3Source.
* Author(s): Anthony Iacono  & OwnageOwnz (DarkEnergy)
* All handle leaks have been considered.
* If you don't like it, read through the whole thing yourself and prove yourself wrong.
*/

/*
Line by line, coding it together
Unit tests, cutting out the errors bit by bit
Making sure to run it almost nightly
It's parsing and works in SIT
Always gotta keep in mind when tracing
Making sure the code correctly spacing
I'm coding them together.

-

Class by class fussing on the details
IE9, don't you know a better browser saves you time?
Making sure it works for the compiler
Even though I'm coding while tired
Gotta mind those intimate details
Even though the test might fail
It's another new test

-

Programming's easy, for my API's don't stink
Pointers make me queasy
Extend methods and functions
Do you think it breaks easy?

-

System crash, perhaps site fetching
Curse and sigh, this just makes me want to die
Making sure it doesn't deadlock the set
Don't forget the data in the test
Even though my job relies on this task
I won't get it done fast
I'm coding Unit tests

-

File by file, line by line
Public void, is the shit
Class by class, to impress
Working hard, never stressed

And that's the art of the test!

*/
//
// Dear maintainer:
//
// Once you are done trying to 'optimize' this routine,
// and have realized what a terrible mistake that was,
// please increment the following counter as a warning
// to the next guy:
//
// total_hours_wasted_here = 39
//


/**
* For the brave souls who get this far: You are the chosen ones,
* the valiant knights of programming who toil away, without rest,
* fixing our most awful code. To you, true saviors, kings of men,
* I say this: never gonna give you up, never gonna let you down,
* never gonna run around and desert you. Never gonna make you cry,
* never gonna say goodbye. Never gonna tell a lie and hurt you.
*/

//When I wrote this, only God and I understood what I was doing
//Now, God only knows

// sometimes I believe compiler ignores all my comments

/*
 * You may think you know what the following code does.
 * But you dont. Trust me.
 * Fiddle with it, and you'll spend many a sleepless
 * night cursing the moment you thought youd be clever
 * enough to "optimize" the code below.
 * Now close this file and go play with something else.
 */

//Dear future me. Please forgive me.
//I can't even begin to express how sorry I am.

#pragma semicolon 1

#include <sourcemod>
#include "sdkhooks"
//#include <profiler>
#include "W3SIncs/War3Source_Interface"

//THESE are updated less frequently
//JENKINS overwrites these
#define BRANCH "undef"
#define BUILD_NUMBER "undef"
#define VERSION_NUM "2.130"

#tryinclude "../../../jenkins.inc"
// BRANCH and BUILD_NUMBER are set through Jenkins :)
// They will overwrite these VERSION_NUM constants



public Plugin:myinfo =
{
    name = "War3Source",
    author = "War3Source Team",
    description="Brings a Warcraft like gamemode to the Source engine.",
    version=VERSION_NUM
};

//DO NOT REMOVE THE OFFICIAL AUTHORS. YOU SHALL NOT DEPRIVE THEM OF THE CREDIT THEY DESERVE
#define ORIGINAL_AUTHORS "PimpinJuice and Ownz (DarkEnergy)"

new Float:LastLoadingHintMsg[MAXPLAYERSCUSTOM];
new Handle:hRaceLimitEnabled;
new Handle:hChangeGameDescCvar;
new Handle:hUseMetric;
new Handle:introclannamecvar;
new Handle:clanurl;

new Handle:hLoadWar3CFGEveryMapCvar;
new bool:war3source_config_loaded;

new Handle:g_OnWar3EventSpawnFH;
new Handle:g_OnWar3EventDeathFH;

new Handle:g_CheckCompatabilityFH;
new Handle:g_War3InterfaceExecFH;

public APLRes:AskPluginLoad2Custom(Handle:myself,bool:late,String:error[],err_max)
{
    //DO NOT REMOVE this print, its for spacial separation for the server console output
    //Easier for the developer to see were relevant output begins
    PrintToServer("[W3S] -= LOADING W3S =-");
    PrintToServer("[W3S] #       #    #####     #####  ");
    PrintToServer("[W3S] #   #   #   #     #   #     # ");
    PrintToServer("[W3S] #   #   #         #   #       ");
    PrintToServer("[W3S] #   #   #    #####     #####  ");
    PrintToServer("[W3S] #   #   #         #         # ");
    PrintToServer("[W3S] #   #   #   #     #   #     # ");
    PrintToServer("[W3S]  ### ###     #####     #####  ");


    new String:version[64];
    Format(version, sizeof(version), "%s by the War3Source Team", VERSION_NUM);
    CreateConVar("war3_version", version, "War3Source version.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    CreateConVar("a_war3_version", version, "War3Source version.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    CreateConVar("war3_branch", BRANCH, "War3Source branch.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    CreateConVar("war3_buildnumber", BUILD_NUMBER, "War3Source build number.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    CreateConVar("war3_release", RELEASE_DATE, "War3Source version release date.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

    CreateNative("W3GetW3Version", NW3GetW3Version);
    CreateNative("W3GetW3Revision", NW3GetW3Revision);  

    if(!War3Source_InitForwards())
    {
        War3_LogCritical("There was a failure in creating the forward based functions, definately halting.");
        return APLRes_Failure;
    }

    return APLRes_Success;
}

public OnPluginStart()
{
    if(!War3Source_HookEvents())
    {
        SetFailState("[War3Source] There was a failure in initiating event hooks.");
    }
    if(!War3Source_InitCVars())
    {
        SetFailState("[War3Source] There was a failure in initiating console variables.");
    }

    CreateTimer(0.1, LoadingXPHintTimer, _, TIMER_REPEAT);

    // Developer debug functions
    RegConsoleCmd("war3refresh",refreshcooldowns);
    RegConsoleCmd("armortest",armortest);
}

War3Source_InitCVars()
{
    introclannamecvar = CreateConVar("war3_introclanname", "war3_introclanname", "Intro menu clan name (welcome to 'YOUR CLAN NAME' War3Source server!)");
    clanurl = CreateConVar("war3_clanurl", "www.ownageclan.Com (set war3_clanurl)", "The url to display on intro menu");
    hChangeGameDescCvar = CreateConVar("war3_game_desc", "1", "change game description to war3source? does not affect player connect");

    hLoadWar3CFGEveryMapCvar = CreateConVar("war3_load_war3source_cfg_every_map", "1", "May help speed up map changes if disabled.");

    hRaceLimitEnabled = CreateConVar("war3_racelimit_enable", "1", "Should race limit restrictions per team be enabled");
    W3SetVar(hRaceLimitEnabledCvar, hRaceLimitEnabled);

    hUseMetric = CreateConVar("war3_metric_system", "1", "Do you want use metric system? 1-Yes, 0-No");
    W3SetVar(hUseMetricCvar, hUseMetric);

    return true;
}


bool:War3Source_InitForwards()
{

    g_OnWar3EventSpawnFH = CreateGlobalForward("OnWar3EventSpawn", ET_Ignore, Param_Cell);
    g_OnWar3EventDeathFH = CreateGlobalForward("OnWar3EventDeath", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

    g_CheckCompatabilityFH = CreateGlobalForward("CheckWar3Compatability", ET_Ignore, Param_String);
    g_War3InterfaceExecFH = CreateGlobalForward("War3InterfaceExec", ET_Ignore);

    return true;
}

public Action:LoadingXPHintTimer(Handle:timer)
{
    for(new client=1; client <= MaxClients; client++)
    {
        if(ValidPlayer(client,true))
        {
            if(!W3IsPlayerXPLoaded(client))
            {
                if(GetGameTime() > LastLoadingHintMsg[client] + 4.0)
                {
                    PrintHintText(client, "%T", "Loading XP... Please Wait", client);
                    LastLoadingHintMsg[client] = GetGameTime();
                }
            }
        }
    }
}

public Action:armortest(client, args)
{
    if(W3IsDeveloper(client))
    {
        for(new i=1; i <= MaxClients; i++)
        {
            new String:arg[10];
            GetCmdArg(1, arg, sizeof(arg));
            new Float:num = StringToFloat(arg);

            War3_SetBuff(i, fArmorPhysical, 1, num);
            War3_SetBuff(i, fArmorMagic, 1, num);
        }
    }
}


public Action:refreshcooldowns(client, args)
{
    if(W3IsDeveloper(client))
    {
        new raceid = War3_GetRace(client);
        if(raceid > 0)
        {
            for(new skillnum=1; skillnum <= War3_GetRaceSkillCount(raceid); skillnum++)
            {
                War3_CooldownMGR(client, 0.0, raceid, skillnum, false, false);
            }
        }
    }
}


public OnMapStart()
{
    DoWar3InterfaceExecForward();


    DelayedWar3SourceCfgExecute();
    OneTimeForwards();
}

public Action:OnGetGameDescription(String:gameDesc[64])
{
    if(GetConVarInt(hChangeGameDescCvar) > 0)
    {
        Format(gameDesc, sizeof(gameDesc), "War3Source %s", VERSION_NUM);

        return Plugin_Changed;
    }

    return Plugin_Continue;
}



DelayedWar3SourceCfgExecute()
{
    if(GetConVarBool(hLoadWar3CFGEveryMapCvar))
    {
        if(FileExists("cfg/war3source.cfg"))
        {
            ServerCommand("exec war3source.cfg");
            PrintToServer("[War3Source] Executing war3source.cfg");
            war3source_config_loaded=true;
        }
        else
        {
            PrintToServer("[War3Source] Could not find war3source.cfg, we recommend all servers have this file");
        }
    }
    else if(!war3source_config_loaded)
    {
        if(FileExists("cfg/war3source.cfg"))
        {
            ServerCommand("exec war3source.cfg");
            PrintToServer("[War3Source] Executing war3source.cfg");
            war3source_config_loaded=true;
        }
        else
        {
            PrintToServer("[War3Source] Could not find war3source.cfg, we recommend all servers have this file");
        }
    }
}

public OnClientPutInServer(client)
{
    LastLoadingHintMsg[client] = GetGameTime();
}

public NW3GetW3Revision(Handle:plugin,numParams)
{
    new revision = StringToInt(BUILD_NUMBER);
    if (revision == 0)
    {
        revision = -1;
    }

    // Revision -1 means developer build :P
    return revision;
}
public NW3GetW3Version(Handle:plugin, numParams)
{
    SetNativeString(1, VERSION_NUM, GetNativeCell(2));
}

bool:War3Source_HookEvents()
{
    // Events for all games
    if(!HookEventEx("player_spawn", War3Source_PlayerSpawnEvent, EventHookMode_Pre))
    {
        PrintToServer("[War3Source] Could not hook the player_spawn event.");
        return false;
    }
    if(!HookEventEx("player_death", War3Source_PlayerDeathEvent, EventHookMode_Pre))
    {
        PrintToServer("[War3Source] Could not hook the player_death event.");
        return false;
    }

    return true;

}

public War3Source_PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{

    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(ValidPlayer(client,true))
    {
        War3_SetMaxHP_INTERNAL(client, GetClientHealth(client));

        CheckPendingRace(client);

        new raceid = War3_GetRace(client);
        if(!W3GetPlayerProp(client, SpawnedOnce))
        {
            War3Source_IntroMenu(client);
            W3SetPlayerProp(client, SpawnedOnce, true);
        }
        else if(raceid < 1 && W3IsPlayerXPLoaded(client))
        {
            ShowChangeRaceMenu(client);
        }
        else if(raceid > 0 && GetConVarInt(hRaceLimitEnabled) > 0 && GetRacesOnTeam(raceid, GetClientTeam(client), true) > W3GetRaceMaxLimitTeam(raceid, GetClientTeam(client)))
        {
            CheckRaceTeamLimit(raceid, GetClientTeam(client));  //show changerace inside
        }
        raceid = War3_GetRace(client);//get again it may have changed
        if(raceid > 0)
        {
            W3DoLevelCheck(client);
            War3_ShowXP(client);

            W3CreateEvent(DoCheckRestrictedItems,client);
        }

        //forward to all other plugins last
        DoForward_OnWar3EventSpawn(client);

        W3SetPlayerProp(client, bStatefulSpawn, false); //no longer a "stateful" spawn
    }
}

public Action:War3Source_PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new uid_victim = GetEventInt(event, "userid");
    new uid_attacker = GetEventInt(event, "attacker");
    new uid_entity = GetEventInt(event, "entityid");

    new victimIndex = 0;
    new attackerIndex = 0;

    if(uid_attacker > 0)
    {
        attackerIndex = GetClientOfUserId(uid_attacker);
    }

    if (GAMEL4DANY && War3_IsCommonInfected(uid_entity))
    {
        new death_race = War3_GetRace(victimIndex);
        W3SetVar(DeathRace, death_race);
        new Handle:oldevent = W3GetVar(SmEvent);
        W3SetVar(SmEvent, event); //stacking on stack

        W3SetVar(EventArg1, attackerIndex);

        //post death event actual forward
        DoForward_OnWar3EventDeath(uid_entity, attackerIndex, death_race);

        W3SetVar(SmEvent, oldevent); //restore on stack , if any
        return Plugin_Continue;
    }
    else
    {
        victimIndex = GetClientOfUserId(uid_victim);
    }

    new bool:deadringereath = false;
    if(uid_victim > 0)
    {
        new deathFlags = GetEventInt(event, "death_flags");
        if (GAMETF && deathFlags & TF_DEATHFLAG_DEADRINGER)
        {
            deadringereath = true;

            new assister=GetClientOfUserId(GetEventInt(event,"assister"));

            if(victimIndex!=attackerIndex&&ValidPlayer(attackerIndex))
            {
                if(GetClientTeam(attackerIndex)!=GetClientTeam(victimIndex))
                {
                    decl String:weapon[64];
                    GetEventString(event,"weapon",weapon,sizeof(weapon));
                    new bool:killed_by_headshot,bool:killed_by_melee;
                    killed_by_headshot=(GetEventInt(event,"customkill")==1);
                    //DP("wep %s",weapon);
                    killed_by_melee=W3IsDamageFromMelee(weapon);
                    if(assister>=0 && War3_GetRace(assister)>0)
                    {
                        W3GiveFakeXPGold(attackerIndex,victimIndex,assister,XPAwardByAssist,_,_,"",_,_);
                    }
                    W3GiveFakeXPGold(attackerIndex,victimIndex,assister,XPAwardByKill,0,0,"",killed_by_headshot,killed_by_melee);
                }
            }
        }
        else
        {
            W3DoLevelCheck(victimIndex);
        }
    }

    if(victimIndex && !deadringereath) //forward to all other plugins last
    {
        new death_race = War3_GetRace(victimIndex);
        W3SetVar(DeathRace,death_race);

        new Handle:oldevent=W3GetVar(SmEvent);
        W3SetVar(SmEvent,event); //stacking on stack

        ///pre death event, internal event
        W3SetVar(EventArg1, attackerIndex);
        W3CreateEvent(OnDeathPre, victimIndex);

        //post death event actual forward
        DoForward_OnWar3EventDeath(victimIndex, attackerIndex, death_race);

        W3SetVar(SmEvent,oldevent); //restore on stack , if any

        //then we allow change race AFTER death forward
        W3SetPlayerProp(victimIndex, bStatefulSpawn, true); //next spawn shall be stateful
        CheckPendingRace(victimIndex);
    }

    return Plugin_Continue;
}


CheckPendingRace(client)
{
    new pendingrace = W3GetPendingRace(client);
    if(pendingrace > 0)
    {
        W3SetPendingRace(client,-1);

        if(CanSelectRace(client, pendingrace) || W3IsDeveloper(client))
        {
            War3_SetRace(client, pendingrace);
        }
        else //already at limit
        {
            War3_LogInfo("Race \"{race %i}\" blocked on player \"{client %i}\" due to restrictions limit (CheckPendingRace)", pendingrace, client);
            W3CreateEvent(DoShowChangeRaceMenu, client);
        }

    }
    else if(War3_GetRace(client) == 0) ///wasnt pending
    {
        W3CreateEvent(DoShowChangeRaceMenu, client);
    }
    else if(War3_GetRace(client) > 0)
    {
        if(!CanSelectRace(client, War3_GetRace(client)))
        {
            War3_SetRace(client, 0);
        }
    }
}

War3Source_IntroMenu(client)
{
    new Handle:introMenu = CreateMenu(War3Source_IntroMenu_Select);

    new String:clanname[32];
    GetConVarString(introclannamecvar, clanname, sizeof(clanname));

    new String:welcome[512];

    // locally compiled version
    if (StrEqual(BRANCH, "{branch}"))
    {
        Format(welcome, sizeof(welcome), "%T\n \n", "WelcomeToServer", client, clanname, "Developer Version", "-");
    }
    // Master branch
    else if (StrEqual(BRANCH, "master"))
    {
        Format(welcome, sizeof(welcome), "%T\n \n", "WelcomeToServerMaster", client, clanname, BUILD_NUMBER);
    }
    // Branch autobuild
    else
    {
        Format(welcome, sizeof(welcome), "%T\n \n", "WelcomeToServer", client, clanname, BRANCH, BUILD_NUMBER);
    }

    SetSafeMenuTitle(introMenu, welcome);
    SetMenuExitButton(introMenu, false);

    new String:buf[64];
    Format(buf, sizeof(buf), "%T", "ForHelpIntro", client);
    AddMenuItem(introMenu, "exit", buf);

    GetConVarString(clanurl, buf, sizeof(buf));
    if(strlen(buf))
    {
        AddMenuItem(introMenu, "exit", buf);
    }

    Format(buf, sizeof(buf), "www.war3source.com");
    AddMenuItem(introMenu, "exit", buf);
    DisplayMenu(introMenu, client, MENU_TIME_FOREVER);
}

public War3Source_IntroMenu_Select(Handle:menu, MenuAction:action, client, selection)
{
    if(ValidPlayer(client) && War3_GetRace(client) == 0)
    {
        if(W3IsPlayerXPLoaded(client))
        {
            W3CreateEvent(DoShowChangeRaceMenu, client);
        }
        else
        {
            War3_ChatMessage(client, "%T", "Please be patient while we load your XP", client);
        }
    }

    if(action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

//mapstart
OneTimeForwards()
{
    Call_StartForward(g_CheckCompatabilityFH);
    Call_PushString(interfaceVersion);
    Call_Finish();

}

DoForward_OnWar3EventSpawn(client)
{
    //new Handle:prof=CreateProfiler();
    //StartProfiling(prof);
    Call_StartForward(g_OnWar3EventSpawnFH);
    Call_PushCell(client);
    Call_Finish();
    //StopProfiling(prof);
    //new String:racename[64];
    //War3_GetRaceName(War3_GetRace(client),racename,sizeof(racename));
    //DP("%s %f",racename,GetProfilerTime(prof));
    //CloseHandle(prof);
}

DoForward_OnWar3EventDeath(victim,killer,deathrace)
{
    Call_StartForward(g_OnWar3EventDeathFH);
    Call_PushCell(victim);
    Call_PushCell(killer);
    Call_PushCell(deathrace);
    Call_Finish();
}

DoWar3InterfaceExecForward()
{
    Call_StartForward(g_War3InterfaceExecFH);
    Call_Finish();
}
