#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Player Class",
    author = "War3Source Team",
    description = "Stores information about a player"
};

new p_xp[MAXPLAYERSCUSTOM][MAXRACES];
new p_level[MAXPLAYERSCUSTOM][MAXRACES];
new p_skilllevel[MAXPLAYERSCUSTOM][MAXRACES][MAXSKILLCOUNT];

new p_properties[MAXPLAYERSCUSTOM][W3PlayerProp];


new bool:bResetSkillsOnSpawn[MAXPLAYERSCUSTOM];
new RaceIDToReset[MAXPLAYERSCUSTOM];


new String:levelupSound[256]; //="war3source/levelupcaster.mp3";



new Handle:g_On_Race_Changed;
new Handle:g_On_Race_Selected;
new Handle:g_OnSkillLevelChangedHandle;

new Handle:g_OnWar3RaceEnabled;
new Handle:g_OnWar3RaceDisabled;

// l4d
new Handle:g_hGameMode;
new bool:bSurvivalStarted;
new bool:bStartingArea[MAXPLAYERS];

new Handle:hRaceEnableOrDisableCvar;
new Handle:hRaceEnableOrDisableFullCvar;

public OnPluginStart()
{
    RegConsoleCmd("war3notdev",cmdwar3notdev);

    RegAdminCmd("war3_all_races_enabled", cmdwar3RaceDynamicLoadingOn, ADMFLAG_ROOT, "war3_all_races_enabled");
    RegAdminCmd("war3_all_races_disabled", cmdwar3RaceDynamicLoadingOff, ADMFLAG_ROOT, "war3_all_races_disabled");

    // sets everything to default loading
    RegAdminCmd("war3_enable_race_dynamic_loading", cmdwar3EnableRaceDynamicLoading, ADMFLAG_ROOT, "war3_enable_race_dynamic_loading");

    // If set to 1, it will enable / disable races automatically.
    // if set to 0, it will enable races automatically and not disable them.
    hRaceEnableOrDisableCvar=CreateConVar("war3_race_dynamic_loading","1","1 to enable, 0 to disable (default 1)");
    
    // does not allow enabling or disabling of races
    // Do not set this to 1 on start up or no races willl be enabled!
    hRaceEnableOrDisableFullCvar=CreateConVar("war3_race_dynamic_loading_fulldisable","0","1 to enable, 0 to disable (default 0)");

    
    HookEvent("player_team", Event_PlayerTeam);

    if(GAMEL4DANY)
    {
        g_hGameMode = FindConVar("mp_gamemode");
        if(!HookEventEx("survival_round_start", War3Source_SurvivalStartEvent))
        {
            PrintToServer("[War3Source] Could not hook the survival_round_start event.");
        }
        if(!HookEventEx("round_end", War3Source_RoundEndEvent))
        {
            PrintToServer("[War3Source] Could not hook the round_end event.");
        }
        if(!HookEventEx("player_entered_checkpoint", War3Source_EnterCheckEvent))
        {
            PrintToServer("[War3Source] Could not hook the player_entered_checkpoint event.");
        }
        if(!HookEventEx("player_left_checkpoint", War3Source_LeaveCheckEvent))
        {
            PrintToServer("[War3Source] Could not hook the player_left_checkpoint event.");
        }
        if(!HookEventEx("player_entered_start_area", War3Source_EnterCheckEvent))
        {
            PrintToServer("[War3Source] Could not hook the player_entered_start_area event.");
        }
        if(!HookEventEx("player_left_start_area", War3Source_LeaveCheckEvent))
        {
            PrintToServer("[War3Source] Could not hook the player_left_start_area event.");
        }
        if(!HookEventEx("player_first_spawn", War3Source_FirstSpawnEvent))
        {
            PrintToServer("[War3Source] Could not hook the player_first_spawn event.");
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
    g_On_Race_Changed=CreateGlobalForward("OnRaceChanged",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);
    g_On_Race_Selected=CreateGlobalForward("OnRaceSelected",ET_Ignore,Param_Cell,Param_Cell);
    g_OnSkillLevelChangedHandle=CreateGlobalForward("OnSkillLevelChanged",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
    
    g_OnWar3RaceEnabled=CreateGlobalForward("OnWar3RaceEnabled",ET_Ignore,Param_Cell);
    g_OnWar3RaceDisabled=CreateGlobalForward("OnWar3RaceDisabled",ET_Ignore,Param_Cell);
    
    CreateNative("War3_SetRace",NWar3_SetRace); 
    CreateNative("War3_GetRace",NWar3_GetRace); 
    
    CreateNative("War3_SetLevel",NWar3_SetLevel); 
    CreateNative("War3_GetLevel",NWar3_GetLevel);
    CreateNative("War3_GetLevelEx",NWar3_GetLevelEx);
    
    CreateNative("War3_SetXP",NWar3_SetXP); 
    CreateNative("War3_GetXP",NWar3_GetXP); 
    
    //these return false if the player is not this race
    //CreateNative("War3_SetSkillLevel",NWar3_SetSkillLevel); 
    CreateNative("War3_GetSkillLevel",NWar3_GetSkillLevel); 
    
    //these return the skill without accounting if there are the current race
    CreateNative("War3_SetSkillLevelINTERNAL",NWar3_SetSkillLevelINTERNAL); 
    CreateNative("War3_GetSkillLevelINTERNAL",NWar3_GetSkillLevelINTERNAL); 
    
    CreateNative("W3SetPlayerProp",NW3SetPlayerProp);
    CreateNative("W3GetPlayerProp",NW3GetPlayerProp);
    
    CreateNative("W3GetTotalLevels",NW3GetTotalLevels);
    CreateNative("W3GetLevelsSpent",NW3GetLevelsSpent);
    CreateNative("W3ClearSkillLevels",NW3ClearSkillLevels);
    
    CreateNative("War3_SpawnPlayer",NWar3_SpawnPlayer);
    return true;
}

EnableRace(newrace)
{
    if(GetConVarBool(hRaceEnableOrDisableFullCvar)) return;
    
    // Enable new race
    Call_StartForward(g_OnWar3RaceEnabled);
    Call_PushCell(newrace);
    Call_Finish(dummy);
}

DisableRace(oldrace)
{
    if(!GetConVarBool(hRaceEnableOrDisableCvar)) return;
    if(GetConVarBool(hRaceEnableOrDisableFullCvar)) return;
    
    new iRaceCount=0;
    for(new i=1;i<=MaxClients;i++)
    {
        if(War3_GetRace(i)==oldrace)
        {
            iRaceCount++;
        }
    }
    
    if(iRaceCount==0)
    {
        // disable unused race
        Call_StartForward(g_OnWar3RaceDisabled);
        Call_PushCell(oldrace);
        Call_Finish(dummy);
    }
}

public Action:cmdwar3RaceDynamicLoadingOn(client,args){
    new RacesLoaded = War3_GetRacesLoaded();
    new String:LongRaceName[64];
    for(new x=1;x<=RacesLoaded;x++)
    {
        Call_StartForward(g_OnWar3RaceEnabled);
        Call_PushCell(x);
        Call_Finish(dummy);
        SetTrans(client);
        War3_GetRaceName(x,LongRaceName,sizeof(LongRaceName));
        PrintToConsole(client,"%s Enabled",LongRaceName);
    }

    return Plugin_Handled;
}

public Action:cmdwar3RaceDynamicLoadingOff(client,args){
    new RacesLoaded = War3_GetRacesLoaded();
    new String:LongRaceName[64];
    for(new x=1;x<=RacesLoaded;x++)
    {
        
        Call_StartForward(g_OnWar3RaceDisabled);
        Call_PushCell(x);
        Call_Finish(dummy);
        SetTrans(client);
        War3_GetRaceName(x,LongRaceName,sizeof(LongRaceName));
        PrintToConsole(client,"%s Disabled",LongRaceName);
    }

    return Plugin_Handled;
}


public Action:cmdwar3EnableRaceDynamicLoading(client,args){
    SetConVarInt(hRaceEnableOrDisableCvar, 1);
    SetConVarInt(hRaceEnableOrDisableFullCvar, 0);
    new RacesLoaded = War3_GetRacesLoaded();
    new String:LongRaceName[64];
    new iRaceCount=0;
    for(new x=1;x<=RacesLoaded;x++)
    {
        iRaceCount=0;
        
        for(new i=1;i<=MaxClients;i++)
        {
            if(War3_GetRace(i)==x)
            {
                iRaceCount++;
            }
        }

        if(iRaceCount==0)
        {
            Call_StartForward(g_OnWar3RaceDisabled);
            Call_PushCell(x);
            Call_Finish(dummy);
            SetTrans(client);
            War3_GetRaceName(x,LongRaceName,sizeof(LongRaceName));
            PrintToConsole(client,"%s Disabled",LongRaceName);
        }
        else
        {
            Call_StartForward(g_OnWar3RaceEnabled);
            Call_PushCell(x);
            Call_Finish(dummy);
            SetTrans(client);
            War3_GetRaceName(x,LongRaceName,sizeof(LongRaceName));
            PrintToConsole(client,"%s Enabled",LongRaceName);
        }
    }

    return Plugin_Handled;
}


public NWar3_SetRace(Handle:plugin,numParams){
    
    //set old race
    new client=GetNativeCell(1);
    new newrace=GetNativeCell(2);
    if(newrace<0||newrace>War3_GetRacesLoaded()){
        //W3LogError("WARNING SET INVALID RACE for client %d to race %d",client,newrace);
        return;
    }
    if (client > 0 && client <= MaxClients)
    {
        new oldrace=p_properties[client][CurrentRace];
        if(oldrace==newrace){
            //WTF ABORT
            return;
        }
        else{
            EnableRace(newrace);
            
            W3SetVar(OldRace,p_properties[client][CurrentRace]);
            
            if(oldrace>0&&ValidPlayer(client)){
                W3SaveXP(client,oldrace);
            }
            
            
            p_properties[client][CurrentRace]=newrace;
            
            if(oldrace>0){
                //we move all the old skill levels (apparrent ones)
                for(new i=1;i<=War3_GetRaceSkillCount(oldrace);i++){
                    Call_StartForward(g_OnSkillLevelChangedHandle);
                    Call_PushCell(client);
                    Call_PushCell(oldrace);
                    Call_PushCell(i); //i is skillid
                    Call_PushCell(0); //force 0
                    Call_Finish(dummy);
                }
            }
            if(newrace>0){
                for(new i=1;i<=War3_GetRaceSkillCount(newrace);i++){
                    Call_StartForward(g_OnSkillLevelChangedHandle);
                    Call_PushCell(client);
                    Call_PushCell(newrace);
                    Call_PushCell(i); //i is skillid
                    Call_PushCell(War3_GetSkillLevelINTERNAL(client,newrace,i)); //i is skillid
                    Call_Finish(dummy);
                }
            }
            
            
            
            
            //announce race change
            Call_StartForward(g_On_Race_Changed);
            Call_PushCell(client);
            Call_PushCell(oldrace);
            Call_PushCell(newrace);
            Call_Finish(dummy);
            
            //REMOVE DEPRECATED
            Call_StartForward(g_On_Race_Selected);
            Call_PushCell(client);
            Call_PushCell(newrace);
            Call_Finish(dummy);
            
            if(newrace>0) {
                if(IsPlayerAlive(client)){
                    EmitSoundToAllAny(levelupSound,client);
                }
                else{
                    EmitSoundToClientAny(client,levelupSound);
                }
                
                if(W3SaveEnabled()){ //save enabled
                }
                else {//if(oldrace>0)
                    War3_SetXP(client,newrace,War3_GetXP(client,oldrace));
                    War3_SetLevel(client,newrace,War3_GetLevel(client,oldrace));
                    W3DoLevelCheck(client);
                }
                
                decl String:buf[64];
                War3_GetRaceName(newrace,buf,sizeof(buf));
                War3_ChatMessage(client,"%T","You are now {racename}",client,buf);
                
                if(oldrace==0){
                    War3_ChatMessage(client,"%T","say war3bug <description> to file a bug report",client);
                }
                W3CreateEvent(DoCheckRestrictedItems,client);
            }
        }
        DisableRace(oldrace);
    }
    
    return;
}
public NWar3_GetRace(Handle:plugin,numParams){
    new client = GetNativeCell(1);
    if (client > 0 && client <= MaxClients)
        return p_properties[client][CurrentRace];
    
    return -2; //return -2 because u usually compare your race
}

public NWar3_SetLevel(Handle:plugin,numParams){
    new client = GetNativeCell(1);
    new race = GetNativeCell(2);
    if (client > 0 && client <= MaxClients && race > 0 && race < MAXRACES)
    {
        //new String:name[32];
        //GetPluginFilename(plugin,name,sizeof(name));
        //DP("SETLEVEL %d %s",GetNativeCell(3),name);
        p_level[client][race]=GetNativeCell(3);
    }
}
public NWar3_GetLevel(Handle:plugin,numParams){
    new client = GetNativeCell(1);
    new race = GetNativeCell(2);
    if (client > 0 && client <= MaxClients && race > 0 && race < MAXRACES)
    {
        //DP("%d",p_level[client][race]);
        new level=p_level[client][race];
        if(level>W3GetRaceMaxLevel(race))
            level=W3GetRaceMaxLevel(race);
        return level;
    }
    //else
    return 0;
}

public NWar3_GetLevelEx(Handle:plugin,numParams){
    new client = GetNativeCell(1);
    new race = GetNativeCell(2);
    new bool:truelevel = GetNativeCell(3); 
    if (client > 0 && client <= MaxClients && race > 0 && race < MAXRACES)
    {
        //DP("%d",p_level[client][race]);
        if(truelevel==true)
        {
            return p_level[client][race];
        }
        else
        {
            new level=p_level[client][race];
            if(level>W3GetRaceMaxLevel(race))
            {
                level=W3GetRaceMaxLevel(race);
                return level;
            }
        }
    }
    //else
    return 0;
}


public NWar3_SetXP(Handle:plugin,numParams){
    new client = GetNativeCell(1);
    new race = GetNativeCell(2);
    if (client > 0 && client <= MaxClients && race > 0 && race < MAXRACES)
        p_xp[client][race]=GetNativeCell(3);
}
public NWar3_GetXP(Handle:plugin,numParams){
    new client = GetNativeCell(1);
    new race = GetNativeCell(2);
    if (client > 0 && client <= MaxClients && race > 0 && race < MAXRACES)
        return p_xp[client][race];
    else
        return 0;
}

///this non INTERNAL may be deprecated
/*
public NWar3_SetSkillLevel(Handle:plugin,numParams){
    new client=GetNativeCell(1);
    new race=GetNativeCell(2);
    new skill=GetNativeCell(3);
    new level=GetNativeCell(4);
    if (client > 0 && client <= MaxClients && race > 0 && race < MAXRACES)
    {
        p_skilllevel[client][race][skill]=level;
        Call_StartForward(g_OnSkillLevelChangedHandle);
        Call_PushCell(client);
        Call_PushCell(race);
        Call_PushCell(skill);
        Call_PushCell(level);
        Call_Finish(dummy);
    }
    
}*/
public NWar3_GetSkillLevel(Handle:plugin,numParams){
    new client=GetNativeCell(1);
    new race=GetNativeCell(2);
    new skill=GetNativeCell(3);
    if (client > 0 && client <= MaxClients && race > 0 && race < MAXRACES && War3_GetRace(client)==race && skill >0 && skill < MAXSKILLCOUNT)
    {
        return p_skilllevel[client][race][skill];
    }
    else
        return 0;
}


public NWar3_SetSkillLevelINTERNAL(Handle:plugin,numParams){
    new client=GetNativeCell(1);
    new race=GetNativeCell(2);
    new skill=GetNativeCell(3);
    new level=GetNativeCell(4);
    if (client > 0 && client <= MaxClients && race > 0 && race < MAXRACES)
    {
        p_skilllevel[client][race][skill]=level;
        if(War3_GetRace(client)==race){
            Call_StartForward(g_OnSkillLevelChangedHandle);
            Call_PushCell(client);
            Call_PushCell(race);
            Call_PushCell(skill);
            Call_PushCell(level);
            Call_Finish(dummy);
        }
    }
    
}
public NWar3_GetSkillLevelINTERNAL(Handle:plugin,numParams){
    new client=GetNativeCell(1);
    new race=GetNativeCell(2);
    new skill=GetNativeCell(3);
    if (client > 0 && client <= MaxClients && race > 0 && race < MAXRACES && skill >0 && skill < MAXSKILLCOUNT)
    {
        return p_skilllevel[client][race][skill];
    }
    else
        return 0;
}


public NW3GetPlayerProp(Handle:plugin,numParams){
    new client=GetNativeCell(1);
    if (client > 0 && client <= MaxClients)
    {
        return p_properties[client][W3PlayerProp:GetNativeCell(2)];        
    }
    else
        return 0;
}
public NW3SetPlayerProp(Handle:plugin,numParams){
    new client=GetNativeCell(1);
    if (client > 0 && client <= MaxClients)
    {    
        p_properties[client][W3PlayerProp:GetNativeCell(2)]=GetNativeCell(3);
    }
}
public NW3GetTotalLevels(Handle:plugin,numParams){
    new client=GetNativeCell(1);
    new total_level=0;
    if (client > 0 && client <= MaxClients)
    {
        new racesLoaded = War3_GetRacesLoaded(); 
        for(new r=1;r<=racesLoaded;r++)
        {
            if(!W3RaceHasFlag(r,"DoNotCountForTotalLevels"))
            {
                total_level+=War3_GetLevel(client,r);
            }
        }
    }
    return  total_level;
}
public NW3ClearSkillLevels(Handle:plugin,numParams){
    new client=GetNativeCell(1);
    if (client > 0 && client <= MaxClients)
    {
        new race=GetNativeCell(2);
        new raceSkillCount = War3_GetRaceSkillCount(race);
        for(new i=1;i<=raceSkillCount;i++)
        {
            War3_SetSkillLevelINTERNAL(client,race,i,0);            
        }
    }
}
public NW3GetLevelsSpent(Handle:plugin,numParams){
    new client=GetNativeCell(1);
    new race=GetNativeCell(2);
    new ret=0;
    if (client > 0 && client <= MaxClients && race > 0 && race < MAXRACES)
    {
        new raceSkillCount = War3_GetRaceSkillCount(race);
        for(new i=1;i<=raceSkillCount;i++)
        {
            ret+=War3_GetSkillLevelINTERNAL(client,race,i);
        }
    }
    return ret;
}

public NWar3_SpawnPlayer(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    new ignore_check=GetNativeCell(2);
    if(ValidPlayer(client,false) && (ignore_check!=0 || !IsPlayerAlive(client)))
    {
        switch(War3_GetGame())
        {
            case Game_CS:
            {
                CS_RespawnPlayer(client);
            }
            case Game_CSGO:
            {
                CS_RespawnPlayer(client);
            }
            case Game_TF:
            {
                TF2_RespawnPlayer(client);
            }
            default:
                return ThrowNativeError(SP_ERROR_NATIVE,"Game does not support respawning");
        }
    }
    return 0;
}

public Event_PlayerTeam(Handle:event,  const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    W3SetPlayerProp(client,LastChangeTeamTime,GetEngineTime());
}


public Action:cmdwar3notdev(client,args){
    if(ValidPlayer(client)){
        W3SetPlayerProp(client,isDeveloper,false);
        
    }
    return Plugin_Handled;
}

public OnClientPostAdminCheck(client)
{
    new String:clientName[256];
    GetClientName(client, clientName, sizeof(clientName));    
    if(CheckCommandAccess(client, "war3_dev_access", ADMFLAG_ROOT, true)) 
    {
        LogMessage("Granted dev access to |%s|",clientName);
        W3SetPlayerProp(client,isDeveloper,true);
    }
}



public OnWar3Event(W3EVENT:event,client)
{
    if(event==ClearPlayerVariables){
        //set xp loaded first, to block saving xp after race change
        W3SetPlayerProp(client,xpLoaded,false);
        for(new i=0;i<MAXRACES;i++)
        {
            War3_SetLevel(client,i,0);
            War3_SetXP(client,i,0);
            for(new x=1;x<MAXSKILLCOUNT;x++){
                War3_SetSkillLevelINTERNAL(client,i,x,0);
            }
        }
        
        if (!GAMEL4DANY)
        {
            for(new i=0;i<MAXITEMS;i++){
                W3SetVar(TheItemBoughtOrLost,i);
                W3CreateEvent(DoForwardClientLostItem,client);
            }
        }
        
        W3SetPlayerProp(client,PendingRace,0);
        War3_SetRace(client,0); //need the race change event fired
        W3SetPlayerProp(client,PlayerGold,0);
        //DP("DERP");
        W3SetPlayerProp(client,iMaxHP,0);
        W3SetPlayerProp(client,bIsDucking,false);
        
        W3SetPlayerProp(client,RaceChosenTime,0.0);
        W3SetPlayerProp(client,RaceSetByAdmin,false);
        W3SetPlayerProp(client,SpawnedOnce,false);
        W3SetPlayerProp(client,sqlStartLoadXPTime,0.0);
        W3SetPlayerProp(client,isDeveloper,false);
        W3SetPlayerProp(client,LastChangeTeamTime,0.0);
        W3SetPlayerProp(client,bStatefulSpawn,true);
        bResetSkillsOnSpawn[client]=false;
    }

    if(event == DoResetSkills)
    {
        new raceid = War3_GetRace(client);
        if(GAMEL4DANY)
        {
            if (ValidPlayer(client, true) && GetClientTeam(client) == TEAM_INFECTED && IsPlayerGhost(client))
            {
                W3ClearSkillLevels(client,raceid);

                War3_ChatMessage(client,"%T","Your skills have been reset for your current race",client);
                if(War3_GetLevel(client,raceid)>0) {
                    W3CreateEvent(DoShowSpendskillsMenu,client);
                }
            }
            else if (ValidPlayer(client, true) && GetClientTeam(client) == TEAM_SURVIVORS)
            {
                decl String:sGameMode[16];
                
                GetConVarString(g_hGameMode, sGameMode, sizeof(sGameMode));
                if ((StrEqual(sGameMode, "survival", false) && !bSurvivalStarted))
                {
                    W3ClearSkillLevels(client,raceid);

                    War3_ChatMessage(client,"%T","Your skills have been reset for your current race",client);
                    if(War3_GetLevel(client,raceid)>0) {
                        W3CreateEvent(DoShowSpendskillsMenu,client);
                    }
                }
                else if (!StrEqual(sGameMode, "survival", false) && bStartingArea[client])
                {
                    W3ClearSkillLevels(client,raceid);

                    War3_ChatMessage(client,"%T","Your skills have been reset for your current race",client);
                    if(War3_GetLevel(client,raceid)>0) {
                        W3CreateEvent(DoShowSpendskillsMenu,client);
                    }
                }
                else
                {
                    bResetSkillsOnSpawn[client]=true;
                    RaceIDToReset[client]=raceid;
                    War3_ChatMessage(client,"%T","Your skills will be reset when you die",client);
                }
            }
        }
        else
        {
            if(IsPlayerAlive(client)){
                bResetSkillsOnSpawn[client]=true;
                RaceIDToReset[client]=raceid;
                War3_ChatMessage(client,"%T","Your skills will be reset when you die",client);
            }
            else
            {
                W3ClearSkillLevels(client,raceid);


                War3_ChatMessage(client,"%T","Your skills have been reset for your current race",client);
                if(War3_GetLevel(client,raceid)>0){
                    W3CreateEvent(DoShowSpendskillsMenu,client);
                }
            }
        }
    }
}

public ResetSkillsAndSetVar(client)
{
    if (ValidPlayer(client))
    {
        if(bResetSkillsOnSpawn[client]==true){
            W3ClearSkillLevels(client,RaceIDToReset[client]);   
            bResetSkillsOnSpawn[client]=false;        

            // Check if the level of the race we reset is > 0 and the current race is still the one we reset
            if((War3_GetLevel(client,RaceIDToReset[client])>0)&&(War3_GetRace(client)==RaceIDToReset[client])){
                War3_ChatMessage(client,"%T","Your skills have been reset for your current race",client);
                W3CreateEvent(DoShowSpendskillsMenu,client);
            }
        }
    }
}

public OnWar3EventSpawn(client)
{
    ResetSkillsAndSetVar(client);
}

public OnWar3EventDeath(victim, attacker)
{
    ResetSkillsAndSetVar(victim);
}

public War3Source_EnterCheckEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetEventInt(event,"userid")>0)
    {
        new client = GetClientOfUserId(GetEventInt(event,"userid"));
        if (ValidPlayer(client, true) && GetClientTeam(client) == TEAM_SURVIVORS)
        {
            bStartingArea[client] = true;
            ResetSkillsAndSetVar(client);
        }
    }
}

public War3Source_LeaveCheckEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetEventInt(event,"userid")>0)
    {
        new client = GetClientOfUserId(GetEventInt(event,"userid"));
        if (ValidPlayer(client, true) && GetClientTeam(client) == TEAM_SURVIVORS)
        {
            bStartingArea[client] = false;
        }
    }
}

public War3Source_SurvivalStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    bSurvivalStarted = true;
}

public War3Source_RoundEndEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    bSurvivalStarted = false;
}

public War3Source_FirstSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetEventInt(event,"userid")>0)
    {
        new client = GetClientOfUserId(GetEventInt(event,"userid"));
        if (ValidPlayer(client))
        {
            for(new i=0;i<MAXITEMS;i++){
                W3SetVar(TheItemBoughtOrLost,i);
                W3CreateEvent(DoForwardClientLostItem,client);
            }
        }
    }
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(ValidPlayer(client)){
        p_properties[client][bIsDucking]=(buttons & IN_DUCK)?true:false; //hope its faster
        
        
        if(W3GetBuffHasTrue(client,bStunned)||W3GetBuffHasTrue(client,bDisarm)){
            if((buttons & IN_ATTACK) || (buttons & IN_ATTACK2))
            {
                buttons &= ~IN_ATTACK;
                buttons &= ~IN_ATTACK2;
            }
        }
    }
    return Plugin_Continue;
}
