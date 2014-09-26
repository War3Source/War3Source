#pragma dynamic 10000
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Race Class",
    author = "War3Source Team",
    description = "Information about races"
};

new totalRacesLoaded=0;  ///USE raceid=1;raceid<=GetRacesLoaded();raceid++ for looping
///race instance variables
//RACE ID = index of [MAXRACES], raceid 1 is raceName[1][32]

new String:raceName[MAXRACES][32];
new String:raceShortname[MAXRACES][16];
new bool:raceTranslated[MAXRACES];
new bool:ignoreRaceEnd; ///dont do anything on CreateRaceEnd cuz this its already done once

//zeroth skill is NOT  used
new raceSkillCount[MAXRACES];
new String:raceSkillName[MAXRACES][MAXSKILLCOUNT][32];
new String:raceSkillDescription[MAXRACES][MAXSKILLCOUNT][512];
new raceSkillDescReplaceNum[MAXRACES][MAXSKILLCOUNT];
new String:raceSkillDescReplace[MAXRACES][MAXSKILLCOUNT][5][64]; ///MAX 5 params for replacement //64 string length
new bool:skillTranslated[MAXRACES][MAXSKILLCOUNT];

// Seems to serve no purpose at this time, why waste memory?
//new String:raceString[MAXRACES][RaceString][512];
//new String:raceSkillString[MAXRACES][MAXSKILLCOUNT][SkillString][512];

/*
enum SkillRedirect
{
    genericskillid,
}*/
//new bool:bSkillRedirected[MAXRACES][MAXSKILLCOUNT];
new SkillRedirectedToGSkill[MAXRACES][MAXSKILLCOUNT];

new bool:skillIsUltimate[MAXRACES][MAXSKILLCOUNT];
new skillMaxLevel[MAXRACES][MAXSKILLCOUNT];
new skillProp[MAXRACES][MAXSKILLCOUNT][W3SkillProp];

new MinLevelCvar[MAXRACES];
new AccessFlagCvar[MAXRACES];
new RaceOrderCvar[MAXRACES];
new RaceFlagsCvar[MAXRACES];
new RestrictItemsCvar[MAXRACES];
new RestrictLimitCvar[MAXRACES][2];

new Handle:m_MinimumUltimateLevel;
new Handle:hCvarSortByMinLevel;

new bool:racecreationended=true;
new String:creatingraceshortname[16];

new raceCell[MAXRACES][ENUM_RaceObject];

// El Diablo's Custom Race Reload
new bool:ReloadRaces_Id[MAXRACES];
new ReloadRaces_Client_Race[MAXPLAYERSCUSTOM];
new ReloadRaces_Client_UserID[MAXPLAYERSCUSTOM];
new String:ReloadRaces_Shortname[MAXRACES][16];
new String:ReloadRaces_longname[MAXRACES][32];
new Handle:hCvarShowChangeRaceMenu;
new Handle:hCvarSetRaceBack;
// End of El Diablo's Custom Race Reload

// El Diablo's Quick Map change
new Handle:hCvarLoadRacesAndItemsOnMapStart;
new bool:RacesAndItemsLoaded;

new Handle:g_OnWar3PluginReadyHandle; //loadin default races in order
new Handle:g_OnWar3PluginReadyHandle2; //other races
new Handle:g_OnWar3PluginReadyHandle3; //other races backwards compatable
new Handle:g_OnWar3PluginReadyHandleCRR; //El Diablo's Custom Race Reload


//END race instance variables

public OnPluginStart()
{
    //silence compiler error
    skillProp[0][0][0]=0;
    m_MinimumUltimateLevel=CreateConVar("war3_minimumultimatelevel","6");
    hCvarSortByMinLevel=CreateConVar("war3_sort_minlevel","0","Strictly sort by minlevel, (then shortname_raceorder tie breaker)");
    hCvarShowChangeRaceMenu=CreateConVar("war3_changeracemenu_on_racereload","0","0 = Disable | 1 = Enable, Show Change Race Menu when reloading a race to affected clients?");
    hCvarSetRaceBack=CreateConVar("war3_set_players_race_back_after_reload","1","0 = Disable | 1 = Enable, Set a players race back after reload? | Untested from map to map.");
    hCvarLoadRacesAndItemsOnMapStart=CreateConVar("war3_Load_RacesAndItems_every_map","1","0 = Disable | 1 = Enable, May help speed up map changes if disabled.");

    RegServerCmd("war3_reloadrace", CmdReloadRace,"Reload A Race");
    
    RegAdminCmd("war3_racelist",Cmdracelist,ADMFLAG_ROOT);
    // Only loads Custom Reload Races into the server at anytime, even if they didn't make it ontime for mapchange
    RegAdminCmd("war3_crrloadraces",Cmdraceload,ADMFLAG_ROOT);

    RegAdminCmd("war3_assignrace",Cmdassignrace,ADMFLAG_ROOT);
}

public Action:Cmdracelist(client,args){
  new RacesLoaded = GetRacesLoaded();
  new String:LongRaceName[64];
  for(new x=1;x<=RacesLoaded;x++)
  {
    War3_GetRaceName(x,LongRaceName,64);
    if(ValidPlayer(client))
      War3_ChatMessage(client,"RaceList [Debug] Race: %s Race ID: %i",LongRaceName,x);
  }
  return Plugin_Handled;
}

public bool:InitNativesForwards()
{
    g_OnWar3PluginReadyHandle = CreateGlobalForward("OnWar3LoadRaceOrItemOrdered", ET_Ignore, Param_Cell);//ordered
    g_OnWar3PluginReadyHandle2 = CreateGlobalForward("OnWar3LoadRaceOrItemOrdered2", ET_Ignore, Param_Cell);//ordered
    g_OnWar3PluginReadyHandle3 = CreateGlobalForward("OnWar3PluginReady", ET_Ignore); //unodered rest of the items or races. backwards compatable..
    g_OnWar3PluginReadyHandleCRR = CreateGlobalForward("OnWar3LoadRaceOrItemOrderedCRR", ET_Ignore, Param_Cell, Param_Cell, Param_String); // El Diablo's Custom Race Reload
    
    // Custom Race Reloading Races does not work for translated races.
    CreateNative("War3_RaceOnPluginStart",NWar3_RaceOnPluginStart);
    CreateNative("War3_RaceOnPluginEnd",NWar3_RaceOnPluginEnd);
    CreateNative("War3_IsRaceReloading",NWar3_IsRaceReloading);
    
    CreateNative("War3_CreateNewRace",NWar3_CreateNewRace);
    CreateNative("War3_AddRaceSkill",NWar3_AddRaceSkill);
    
    CreateNative("War3_CreateNewRaceT",NWar3_CreateNewRaceT);
    CreateNative("War3_AddRaceSkillT",NWar3_AddRaceSkillT);
    
    CreateNative("War3_CreateGenericSkill",NWar3_CreateGenericSkill);
    CreateNative("War3_UseGenericSkill",NWar3_UseGenericSkill);
    CreateNative("W3_GenericSkillLevel",NW3_GenericSkillLevel);
    CreateNative("W3_IsSkillUsingGenericSkill",NW3_IsSkillUsingGenericSkill);
    
    CreateNative("War3_CreateRaceEnd",NWar3_CreateRaceEnd);
    
    
    
    
    CreateNative("War3_GetRaceName",Native_War3_GetRaceName);
    CreateNative("War3_GetRaceShortname",Native_War3_GetRaceShortname);
    
    //Seems to serve no purpose:
    //CreateNative("W3GetRaceString",NW3GetRaceString);
    
    
    CreateNative("War3_GetRaceIDByShortname",NWar3_GetRaceIDByShortname);
    CreateNative("War3_GetRacesLoaded",NWar3_GetRacesLoaded);
    CreateNative("W3GetRaceMaxLevel",NW3GetRaceMaxLevel);
    
    CreateNative("War3_GetRaceSkillCount",NWar3_GetRaceSkillCount);
    CreateNative("War3_IsSkillUltimate",NWar3_IsSkillUltimate);
    CreateNative("W3GetRaceSkillName",NW3GetRaceSkillName);
    CreateNative("W3GetRaceSkillDesc",NW3GetRaceSkillDesc);
    
    CreateNative("W3GetRaceOrder",NW3GetRaceOrder);
    CreateNative("W3RaceHasFlag",NW3RaceHasFlag);
    
    CreateNative("W3GetRaceAccessFlagStr",NW3GetRaceAccessFlagStr);
    CreateNative("W3GetRaceItemRestrictionsStr",NW3GetRaceItemRestrictionsStr);
    CreateNative("W3GetRaceMinLevelRequired",NW3GetRaceMinLevelRequired);
    CreateNative("W3GetRaceMaxLimitTeam",NW3GetRaceMaxLimitTeam);
    CreateNative("W3GetRaceMaxLimitTeamCvar",NW3GetRaceMaxLimitTeamCvar);
    CreateNative("W3GetRaceSkillMaxLevel",NW3GetRaceSkillMaxLevel);
    
    CreateNative("W3GetRaceList",NW3GetRaceList);
    
    CreateNative("W3GetMinUltLevel",NW3GetMinUltLevel);
    
    CreateNative("W3IsRaceTranslated",NW3IsRaceTranslated);
    
    CreateNative("W3GetRaceCell",NW3GetRaceCell);
    CreateNative("W3SetRaceCell",NW3SetRaceCell);
    
    RegPluginLibrary("RaceClass");
    return true;
}

public OnMapStart()
{
    if(GetConVarBool(hCvarLoadRacesAndItemsOnMapStart))
    {
        LoadRacesAndItems();
        RacesAndItemsLoaded=true;
    } else if(!RacesAndItemsLoaded)
    {
        LoadRacesAndItems();
        RacesAndItemsLoaded=true;
    }
}
LoadRacesAndItems()
{    
    new Float:fStartTime = GetEngineTime();

    //ordered loads
    new res;
    for(new i; i <= MAXRACES * 10; i++)
    {
        Call_StartForward(g_OnWar3PluginReadyHandle);
        Call_PushCell(i);
        Call_Finish(res);
    }
    
    //orderd loads 2
    for(new i; i <= MAXRACES * 10; i++)
    {
        Call_StartForward(g_OnWar3PluginReadyHandle2);
        Call_PushCell(i);
        Call_Finish(res);
    }
    
    //unorderd loads
    Call_StartForward(g_OnWar3PluginReadyHandle3);
    Call_Finish(res);
    
    // Custom Race Reload Races
    for(new i; i <= MAXRACES * 10; i++)
    {
        Call_StartForward(g_OnWar3PluginReadyHandleCRR);
        Call_PushCell(i);
        Call_PushCell(-1);
        Call_PushString("");
        Call_Finish(res);
    }

    PrintToServer("RACE ITEM LOAD FINISHED IN %.2f seconds", GetEngineTime() - fStartTime);
    
    
}


new Handle:mystack;
new String:arg1_shortname[64];
new String:arg2_plugin[64];
new String:pluginname[256];
new raceid_reload;
public Action:CmdReloadRace(args)
{
    if(args<2){
        DP("Need 2 arguments: <raceshortname> <part of the plugin to reload>");
        return Plugin_Handled;
    }
    GetCmdArg(1, arg1_shortname, sizeof(arg1_shortname));
    DP("Shortrace Name: %s",arg1_shortname);
    
    
    GetCmdArg(2, arg2_plugin, sizeof(arg2_plugin));
    DP("Trying to find plugin with name: %s",arg2_plugin);
    
    new Handle:plugin = FindPluginByFileCustom(arg2_plugin);
    if(plugin==INVALID_HANDLE){
        return Plugin_Handled;
    }
    //plugin valid
    
    GetPluginFilename(plugin, pluginname, sizeof(pluginname));
    DP("Plugin Found (first match, verify this): %s",pluginname);
    
    raceid_reload=War3_GetRaceIDByShortname(arg1_shortname);
    if(raceid_reload==0)
    {
        DP("Race NOT FOUND by shortname '%s'",arg1_shortname);
        return Plugin_Handled;
    }
    
    
    DP("Removing everyone from the race");
    
    
    mystack=CreateStack();
    for(new client=1;client<=MaxClients;client++){
        if(War3_GetRace(client)==raceid_reload)
        {
            DP("client %d",client);
            War3_SetRace(client,0);
            PushStackCell(mystack,client);
        }
    }
    //KILL DA SKILLS!
    raceSkillCount[raceid_reload]=0;
    
    
    DP("UNLOADING %s",arg2_plugin);
    ServerCommand("sm plugins unload \"%s\"",pluginname);
    DP("LOADING %s",arg2_plugin);
    ServerCommand("sm plugins load \"%s\"",pluginname);
    CreateTimer(0.1,ReloadRace2);
    return Plugin_Handled;
}
public Action:ReloadRace2(Handle:t,any:a)
{
    DP("Issuing race load forwards %s",arg2_plugin);
    LoadRacesAndItems();
    
    DP("Putting races back on clients",arg2_plugin);
    while(!IsStackEmpty(mystack))
    {
        
        new client;
        PopStackCell(mystack,client);
        DP("client %d",client);
        War3_SetRace(client, raceid_reload);
    
    }
    CloseHandle(mystack);
    DP("Race reload complete, possible side effects / leaks");
    //return Plugin_Handled;
}


stock RaceNameSearch(String:changeraceArg[64])
{
        new String:sRaceName[64];
        new RacesLoaded=War3_GetRacesLoaded();
        new race=0;
        //full name
        for(race=1;race<=RacesLoaded;race++)
        {
            War3_GetRaceName(race,sRaceName,sizeof(sRaceName));
            if(StrContains(sRaceName,changeraceArg,false)>-1){
                return race;
            }
        }
        //shortname // checks inside of for() for raceFound==
        for(race=1;race<=RacesLoaded;race++)
        {
            War3_GetRaceShortname(race,sRaceName,sizeof(sRaceName));
            if(StrContains(sRaceName,changeraceArg,false)>-1){
                return race;
            }
        }
        return -1;
}




/*****************************************************************************/
/************El Diablo's assign races function********************************/
/*****************************************************************************/
/*****************************************************************************/

public Action:Cmdassignrace(client,args)
{
    if (args < 2)
    {
        ReplyToCommand(client, "[War3Source] Usage: war3_assignrace <#userid|name> <part of race name>");
        return Plugin_Handled;
    }

    decl String:arg[65];
    GetCmdArg(1, arg, sizeof(arg));

    decl String:arg2[64];
    GetCmdArg(2, arg2, sizeof(arg2));
    
    new RaceID=RaceNameSearch(arg2);
    
    if(RaceID<=0)
    {
        ReplyToCommand(client, "[War3Source] could not find race name.");
        return Plugin_Handled;
    }

    decl String:target_name[MAX_TARGET_LENGTH];
    decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

    if ((target_count = ProcessTargetString(
            arg,
            client,
            target_list,
            MAXPLAYERS,
            COMMAND_FILTER_CONNECTED,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
    {
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }

    decl String:sClientName[128];
    decl String:sRaceName[64];
    War3_GetRaceName(RaceID,sRaceName,sizeof(sRaceName));
    for (new i = 0; i < target_count; i++)
    {
        if(ValidPlayer(target_list[i]))
        {
            War3_SetRace(target_list[i],RaceID);
            GetClientName(target_list[i],sClientName,sizeof(sClientName));
            War3_ChatMessage(client,"%s set to %s",sClientName,sRaceName);
        }
    }
    return Plugin_Handled;
}

/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/







/*****************************************************************************/
/************El Diablo's Custom Race Reload Race Functions********************/
/*****************************************************************************/
/*****************************************************************************/

public Action:Cmdraceload(client,args)
{
    new res;
    
    // Custom Race Load Races
    for(new i; i <= MAXRACES * 10; i++)
    {
        Call_StartForward(g_OnWar3PluginReadyHandleCRR);
        Call_PushCell(i);
        Call_PushCell(-1);
        Call_PushString("");
        Call_Finish(res);
    }

    return Plugin_Handled;
}


public NWar3_IsRaceReloading(Handle:plugin,numParams){

  return Internal_NWar3_IsRaceReloading()==1?true:false;
}

Internal_NWar3_IsRaceReloading()
{
  new RacesLoaded = GetRacesLoaded();
  new bool:findtherace=false;
  for(new x=1;x<=RacesLoaded;x++)
  {
    if(ReloadRaces_Id[x]==true)
      {
        findtherace=true;
        break;
      }
  }
  return findtherace?1:0;
}

public NWar3_RaceOnPluginEnd(Handle:plugin,numParams){
  new String:shortname[16];
  GetNativeString(1,shortname,sizeof(shortname));
  if(StrEqual(shortname,"",false))
    return;
  new RaceOnPluginEndID=GetRaceIDByShortname(shortname);
  if(RaceOnPluginEndID>0)
  {
    new String:LongRaceName[64];
    War3_GetRaceName(RaceOnPluginEndID,LongRaceName,64);
    for(new i=1;i<MaxClients;i++){
      if(ValidPlayer(i))
      {
        if(War3_GetRace(i)==RaceOnPluginEndID)
        {
          ReloadRaces_Client_Race[i]=RaceOnPluginEndID;
          ReloadRaces_Client_UserID[i]=GetClientUserId(i);
          PrintCenterText(i,"%s is being unloaded!",LongRaceName);
          W3Hint(i,HINT_NORMAL,5.0,"%s is being unloaded!",LongRaceName);
        }
      }
    }
    ReloadRaces_Id[RaceOnPluginEndID]=true;
    strcopy(ReloadRaces_longname[RaceOnPluginEndID], 32, raceName[RaceOnPluginEndID]);
    strcopy(ReloadRaces_Shortname[RaceOnPluginEndID], 16, raceShortname[RaceOnPluginEndID]);
    strcopy(raceName[RaceOnPluginEndID], 32, "");
    strcopy(raceShortname[RaceOnPluginEndID], 16, "");
    // erase races skill info here
    for(new i=0;i<MAXSKILLCOUNT;i++){
      strcopy(raceSkillName[RaceOnPluginEndID][i], 32, "");
      strcopy(raceSkillDescription[RaceOnPluginEndID][i], 512, "");
      skillIsUltimate[RaceOnPluginEndID][i]=false;
      skillMaxLevel[RaceOnPluginEndID][i]=0;
      raceSkillDescReplaceNum[RaceOnPluginEndID][i]=0;
      skillTranslated[RaceOnPluginEndID][i]=false;
      skillIsUltimate[RaceOnPluginEndID][i]=false;
      for(new arg=0;arg<4;arg++){
        strcopy(raceSkillDescReplace[RaceOnPluginEndID][i][arg], 64, "");
      }
    }
    War3_RemoveDependency(RaceOnPluginEndID,raceSkillCount[RaceOnPluginEndID]);
    raceSkillCount[RaceOnPluginEndID]=0;
    new String:ClientName[128];
    for(new i=1;i<MaxClients;i++){
      if(ValidPlayer(i))
      {
        if(ReloadRaces_Client_Race[i]==RaceOnPluginEndID)
        {
          War3_SetRace(i,0);
          GetClientName(i,ClientName,sizeof(ClientName));
          PrintToServer("[Race Unload] %s : %d race set to 0",ClientName,i);
          War3_ChatMessage(i,"{lightgreen}[Race Unload] {default} %s is now no race. | client %i | race 0",ClientName,i);
          if(GetConVarBool(hCvarShowChangeRaceMenu))
          {
            War3_ChatMessage(i,"{lightgreen}[Race Unload] {default}%s please choose another race.",ClientName);
            if(GetConVarBool(hCvarSetRaceBack))
            {
              War3_ChatMessage(i,"{lightgreen}[Race Unload] {default}You will be set back to this race once it is loaded back.",ClientName);
            }
            W3CreateEvent(DoShowChangeRaceMenu,i);
          }
        }
      }
    }
  }
}

// NOTE: reloading races to will not work with translated races.
public NWar3_RaceOnPluginStart(Handle:plugin,numParams){

  new String:shortname[16];
  GetNativeString(1,shortname,sizeof(shortname));
  if(!StrEqual(shortname,"",false))
  {
    new RacesLoaded = GetRacesLoaded();
    new x;
    new bool:findtherace=false;
    for(x=1;x<=RacesLoaded;x++)
    {
      if(StrEqual(shortname,ReloadRaces_Shortname[x],false))
        {
          findtherace=true;
          break;
        }
    }
    new res;
    
    if(!findtherace)
      return false;
    raceSkillCount[x]=0;
    
    for(new i=0;i<MAXSKILLCOUNT;i++){
      raceSkillDescReplaceNum[x][i]=0;
    }
    Call_StartForward(g_OnWar3PluginReadyHandleCRR);
    Call_PushCell(-1);
    Call_PushCell(x);
    Call_PushString(shortname);
    Call_Finish(res);
  }
  return true;
}

Race_Finished_Reload(raceid)
{
  new String:LongRaceName[64];
  new String:ClientName[128];
  War3_GetRaceName(raceid,LongRaceName,64);
  
  PrintToChatAll("%s has been updated!",LongRaceName);  
  
  for(new i=1;i<MAXPLAYERSCUSTOM;i++){
    if(ReloadRaces_Client_Race[i]==raceid)
    {
      new ClientID=GetClientOfUserId(ReloadRaces_Client_UserID[i]);
      if(ValidPlayer(ClientID))
      {
        PrintCenterText(ClientID,"%s has been updated.",LongRaceName);
        W3Hint(ClientID,HINT_NORMAL,5.0,"%s has been updated.",LongRaceName);
        if(GetConVarBool(hCvarSetRaceBack))
        {
          War3_SetRace(ClientID,raceid);
          ReloadRaces_Client_Race[i]=0;
          GetClientName(ClientID,ClientName,sizeof(ClientName));
          PrintToServer("[Race Reloaded] %s is now %s. | client %i | race %i",ClientName,LongRaceName,ClientID,raceid);
          War3_ChatMessage(ClientID,"{lightgreen}[Race Reloaded] {default}%s is now %s. | client %i | race %i",ClientName,LongRaceName,ClientID,raceid);
        }
      }
    }
  }
}

/*****************************************************************************/
/******END OF El Diablo's Custom Race Reload Race Functions*******************/
/*****************************************************************************/
/*****************************************************************************/













public NWar3_CreateNewRace(Handle:plugin,numParams){
    
    
    decl String:name[64],String:shortname[16];
    GetNativeString(1,name,sizeof(name));
    GetNativeString(2,shortname,sizeof(shortname));
    new ReloadRaceId_info=GetNativeCell(3);
    
    War3_LogInfo("add race %s %s",name,shortname);
    
    return CreateNewRace(name,shortname,ReloadRaceId_info);
    
}


public NWar3_AddRaceSkill(Handle:plugin,numParams){
    
    
    
    new raceid=GetNativeCell(1);
    if(raceid>0){
        new String:skillname[32];
        new String:skilldesc[2001];
        GetNativeString(2,skillname,sizeof(skillname));
        GetNativeString(3,skilldesc,sizeof(skilldesc));
        new bool:isult=GetNativeCell(4);
        new tmaxskilllevel=GetNativeCell(5);
        
        War3_LogInfo("add skill %s %s",skillname,skilldesc);
        
        return AddRaceSkill(raceid,skillname,skilldesc,isult,tmaxskilllevel);
    }
    return 0;
}

//translated
public NWar3_CreateNewRaceT(Handle:plugin,numParams){
    
    
    
    decl String:name[64],String:shortname[32];
    GetNativeString(1,shortname,sizeof(shortname));
    new newraceid=CreateNewRace(name,shortname,0); // Translated races are not supported in custom race reload
    if(newraceid)
    {
        raceTranslated[newraceid]=true;
        new String:buf[64];
        Format(buf,sizeof(buf),"w3s.race.%s.phrases.txt",shortname);
        LoadTranslations(buf);
    }
    return newraceid;
    
}
//translated
public NWar3_AddRaceSkillT(Handle:plugin,numParams){
    
    
    new raceid=GetNativeCell(1);
    if(raceid>0)
    {
        new String:skillname[32];
        new String:skilldesc[1]; //DUMMY
        GetNativeString(2,skillname,sizeof(skillname));
        new bool:isult=GetNativeCell(3);
        new tmaxskilllevel=GetNativeCell(4);
        
        
        War3_LogInfo("add skill T %d %s",raceid,skillname);
        
        new newskillnum=AddRaceSkill(raceid,skillname,skilldesc,isult,tmaxskilllevel);
        skillTranslated[raceid][newskillnum]=true;
        
        if(ignoreRaceEnd==false){
            for(new arg=5;arg<=numParams;arg++){
                
                GetNativeString(arg,raceSkillDescReplace[raceid][newskillnum][raceSkillDescReplaceNum[raceid][newskillnum]],64);
                raceSkillDescReplaceNum[raceid][newskillnum]++;
            }
        }
        
        return newskillnum;
    }
    return 0;//failed
}

public NWar3_CreateRaceEnd(Handle:plugin,numParams){
    War3_LogInfo("race end %d",GetNativeCell(1));
    CreateRaceEnd(GetNativeCell(1));
}
///this is get raceid, not NAME!
public Native_War3_GetRaceByShortname(Handle:plugin,numParams)
{
    new String:short_lookup[16];
    GetNativeString(1,short_lookup,sizeof(short_lookup));
    new RacesLoaded = GetRacesLoaded();
    for(new x=1;x<=RacesLoaded;x++)
    {
        
        new String:short_name[16];
        GetRaceShortname(x,short_name,sizeof(short_name));
        if(StrEqual(short_name,short_lookup,false))
        {
            return x;
        }
    }
    return 0;
}

public Native_War3_GetRaceName(Handle:plugin,numParams)
{
    new race=GetNativeCell(1);
    new bufsize=GetNativeCell(3);
    if(race>-1 && race<=GetRacesLoaded()) //allow "No Race"
    {
        new String:race_name[64];
        GetRaceName(race,race_name,sizeof(race_name));
        SetNativeString(2,race_name,bufsize);
    }
}
public Native_War3_GetRaceShortname(Handle:plugin,numParams)
{
    new race=GetNativeCell(1);
    new bufsize=GetNativeCell(3);
    if(race>=1 && race<=GetRacesLoaded())
    {
        new String:race_shortname[64];
        GetRaceShortname(race,race_shortname,sizeof(race_shortname));
        SetNativeString(2,race_shortname,bufsize);
    }
}
public NWar3_GetRacesLoaded(Handle:plugin,numParams){
    return GetRacesLoaded();
}

public NW3GetRaceMaxLevel(Handle:plugin,numParams)
{
    return GetRaceMaxLevel(GetNativeCell(1));
}


public NWar3_GetRaceSkillCount(Handle:plugin,numParams)
{
    return GetRaceSkillCount(GetNativeCell(1));
}
public NWar3_IsSkillUltimate(Handle:plugin,numParams)
{
    return IsSkillUltimate(GetNativeCell(1),GetNativeCell(2));
}

/*
// Temporary Removing, as it seem to serve no purpose.
public NW3GetRaceString(Handle:plugin,numParams)
{
    new race=GetNativeCell(1);
    new RaceString:racestringid=GetNativeCell(2);
    
    new String:longbuf[1000];
    Format(longbuf,sizeof(longbuf),raceString[race][RaceString:racestringid]);
    SetNativeString(3,longbuf,GetNativeCell(4));
}
public NW3GetRaceSkillString(Handle:plugin,numParams)
{
    new race=GetNativeCell(1);
    new skill=GetNativeCell(2);
    new SkillString:raceskillstringid=GetNativeCell(3);
    
    
    new String:longbuf[1000];
    Format(longbuf,sizeof(longbuf),raceSkillString[race][skill][raceskillstringid]);
    SetNativeString(4,longbuf,GetNativeCell(5));
} */

public NW3GetRaceSkillName(Handle:plugin,numParams)
{
    new race=GetNativeCell(1);
    new skill=GetNativeCell(2);
    new maxlen=GetNativeCell(4);
    
    if(race<1||race>War3_GetRacesLoaded()){
        ThrowNativeError(1,"bad race %d",race);
    }
    if(skill<1||skill>War3_GetRaceSkillCount(race)){
        ThrowNativeError(1,"bad skillid %d",skill);
    }
    new String:buf[32];
    GetRaceSkillName(race,skill,buf,sizeof(buf));
    SetNativeString(3,buf,maxlen);
}
public NW3GetRaceSkillDesc(Handle:plugin,numParams)
{
    new race=GetNativeCell(1);
    new skill=GetNativeCell(2);
    new maxlen=GetNativeCell(4);
    
    new String:longbuf[1000];
    GetRaceSkillDesc(race,skill,longbuf,sizeof(longbuf));
    SetNativeString(3,longbuf,maxlen);
}
public NWar3_GetRaceIDByShortname(Handle:plugin,numParams)
{
    new String:shortname[32];
    GetNativeString(1,shortname,sizeof(shortname));
    return GetRaceIDByShortname(shortname);
}
public NW3GetRaceAccessFlagStr(Handle:plugin,numParams)
{
    new String:buf[32];
    
    new raceid=GetNativeCell(1);
    W3GetCvar(AccessFlagCvar[raceid],buf,sizeof(buf));
    SetNativeString(2,buf,GetNativeCell(3));
    
}
public NW3GetRaceOrder(Handle:plugin,numParams)
{
    new raceid=GetNativeCell(1);
    //DP("getraceorder race %d cvar %d",raceid,RaceOrderCvar[raceid]);
    return W3GetCvarInt(RaceOrderCvar[raceid]);
    
}
public NW3RaceHasFlag(Handle:plugin,numParams)
{
    new raceid=GetNativeCell(1);
    new String:buf[1000];
    W3GetCvar(RaceFlagsCvar[raceid],buf,sizeof(buf));
    
    new String:flagsearch[32];
    GetNativeString(2,flagsearch,sizeof(flagsearch));
    return (StrContains(buf,flagsearch, false)>-1);
}
public NW3GetRaceList(Handle:plugin,numParams)
{
    new listcount=0;
    new RacesLoaded = War3_GetRacesLoaded();
    new Handle:racesAvailable = CreateArray(1); //1 cell
    
    for(new raceid = 1; raceid <= RacesLoaded; raceid++){
        
        if(!W3RaceHasFlag(raceid,"hidden"))
        {
            PushArrayCell(racesAvailable, raceid);
            listcount++;
        }
    }
    new racelist[MAXRACES];
    SortADTArrayCustom(racesAvailable, SortRacesByRaceOrder,racesAvailable);
    for(new i = 0; i < listcount; i++)
    {
        racelist[i] = GetArrayCell(racesAvailable, i);
    }
    CloseHandle(racesAvailable);
    
    SetNativeArray(1, racelist, MAXRACES);
    return listcount;
}
public NW3GetRaceItemRestrictionsStr(Handle:plugin,numParams)
{
    
    new raceid=GetNativeCell(1);
    new String:buf[64];
    W3GetCvar(RestrictItemsCvar[raceid],buf,sizeof(buf));
    SetNativeString(2,buf,GetNativeCell(3));
}

public NW3GetRaceMaxLimitTeam(Handle:plugin,numParams)
{
    new raceid=GetNativeCell(1);
    if(raceid>0){
        
        new team=GetNativeCell(2);
        if(team==TEAM_T||team==TEAM_RED){
            return W3GetCvarInt(RestrictLimitCvar[raceid][0]);
        }
        if(team==TEAM_CT||team==TEAM_BLUE){
            return W3GetCvarInt(RestrictLimitCvar[raceid][1]);
        }
    }
    return 99;
}
public NW3GetRaceMaxLimitTeamCvar(Handle:plugin,numParams)
{
    new raceid=GetNativeCell(1);
    if(raceid>0){
        
        new team=GetNativeCell(2);
        if(team==TEAM_T||team==TEAM_RED){
            return RestrictLimitCvar[raceid][0];
        }
        if(team==TEAM_CT||team==TEAM_BLUE){
            return RestrictLimitCvar[raceid][1];
        }
    }
    return -1;
}
public NW3GetRaceMinLevelRequired(Handle:plugin,numParams){
    return W3GetCvarInt(MinLevelCvar[GetNativeCell(1)]);
}
public NW3GetRaceSkillMaxLevel(Handle:plugin,numParams){
    return GetRaceSkillMaxLevel(GetNativeCell(1),GetNativeCell(2));
}
public NW3GetMinUltLevel(Handle:plugin,numParams){
    return GetConVarInt(m_MinimumUltimateLevel);
}
public NW3IsRaceTranslated(Handle:plugin,numParams){
    return raceTranslated[GetNativeCell(1)];
}
public NW3SetRaceCell(Handle:plugin,numParams){
    return raceCell[GetNativeCell(1)][GetNativeCell(2)]=GetNativeCell(3);
}
public NW3GetRaceCell(Handle:plugin,numParams){
    return raceCell[GetNativeCell(1)][GetNativeCell(2)];
}









new genericskillcount=0;

//how many skills can use a generic skill, limited for memory
#define MAXCUSTOMERRACES 32
enum GenericSkillClass
{
    String:cskillname[32], 
    redirectedfromrace[MAXCUSTOMERRACES], //theset start from 0!!!!
    redirectedfromskill[MAXCUSTOMERRACES],
    redirectedcount, //how many races are using this generic skill, first is 1, loop from 1 to <=redirected count
    Handle:raceskilldatahandle[MAXCUSTOMERRACES], //handle the customer races passed us
}
//55 generic skills
new GenericSkill[55][GenericSkillClass];
public NWar3_CreateGenericSkill(Handle:plugin,numParams){
    new String:tempgenskillname[32];
    GetNativeString(1,tempgenskillname,32);
    
    //find existing
    for(new i=1;i<=genericskillcount;i++){
        
        if(StrEqual(tempgenskillname,GenericSkill[i][cskillname])){
            return i;
        }
    }
    
    //no existing found, add 
    genericskillcount++;
    GetNativeString(1,GenericSkill[genericskillcount][cskillname],32);
    return genericskillcount;
}
public NWar3_UseGenericSkill(Handle:plugin,numParams){
    new raceid=GetNativeCell(1);
    new String:genskillname[32];
    GetNativeString(2,genskillname,sizeof(genskillname));
    new Handle:genericSkillData=Handle:GetNativeCell(3);
    //start from 1
    for(new genericskillid=1;genericskillid<=genericskillcount;genericskillid++){
        //DP("1 %s %s ]",genskillname,GenericSkill[i][cskillname]);
        if(StrEqual(genskillname,GenericSkill[genericskillid][cskillname])){
            //DP("2");
            if(raceid>0){
                
                
                
                //DP("3");
                new String:raceskillname[2001];
                new String:raceskilldesc[2001];
                GetNativeString(4,raceskillname,sizeof(raceskillname));
                GetNativeString(5,raceskilldesc,sizeof(raceskilldesc));
                
                new bool:istranaslated=GetNativeCell(6);
                
                //native War3_UseGenericSkill(raceid,String:gskillname[],Handle:genericSkillData,String:yourskillname[],String:untranslatedSkillDescription[],bool:translated=false,bool:isUltimate=false,maxskilllevel=DEF_MAX_SKILL_LEVEL,any:...);
                
                new bool:isult=GetNativeCell(7);
                new tmaxskilllevel=GetNativeCell(8);
                
                new newskillnum;
                newskillnum    = AddRaceSkill(raceid,raceskillname,raceskilldesc,isult,tmaxskilllevel);
                if(istranaslated){
                    skillTranslated[raceid][newskillnum]=true;    
                }
                
                //check that the data handle isnt leaking
                new genericcustomernumber=GenericSkill[genericskillid][redirectedcount];
                for(new j=0;j<=genericcustomernumber;j++){
                    if(
                    GenericSkill[genericskillid][redirectedfromrace][j]==raceid
                    &&
                    GenericSkill[genericskillid][redirectedfromskill][j]==newskillnum
                    )
                    {   //EXISTING
                        //NOTE THE HANDLE IS KILLED IF CUSTOM RACE IS KILLED, therefore dont close here
                        //Since function IsValidHandle is not allowed, we have to assume it was killed
                        if(GenericSkill[genericskillid][raceskilldatahandle][j]!=INVALID_HANDLE && GenericSkill[genericskillid][raceskilldatahandle][j] !=genericSkillData){
                            //DP("ERROR POSSIBLE HANDLE LEAK, NEW GENERIC SKILL DATA HANDLE PASSED, CLOSING OLD GENERIC DATA HANDLE");
                            //CloseHandle(GenericSkill[genericskillid][raceskilldatahandle][j]);
                            GenericSkill[genericskillid][raceskilldatahandle][j]=genericSkillData;
                        }    
                    }
                    
                }
                
                
                //first time creating the race, otherwise this data already exists
                if(ignoreRaceEnd==false)
                {
                    //variable args start at 8
                    for(new arg=9;arg<=numParams;arg++){
                        
                        GetNativeString(arg,raceSkillDescReplace[raceid][newskillnum][raceSkillDescReplaceNum[raceid][newskillnum]],64);
                        raceSkillDescReplaceNum[raceid][newskillnum]++;
                    }
                    
                    //bSkillRedirected[raceid][newskillnum]=true;
                    SkillRedirectedToGSkill[raceid][newskillnum]=genericskillid;
                    
                    
                    GenericSkill[genericskillid][raceskilldatahandle][genericcustomernumber]=genericSkillData;
                    GenericSkill[genericskillid][redirectedfromrace][GenericSkill[genericskillid][redirectedcount]]=raceid;
                    
                    GenericSkill[genericskillid][redirectedfromskill][GenericSkill[genericskillid][redirectedcount]]=newskillnum;
                    GenericSkill[genericskillid][redirectedcount]++;
                    //DP("FOUND GENERIC SKILL %d, real skill id for race %d",i,newskillnum);
                }
                
                return newskillnum;
                
            }
        }
    }
    War3_LogError("NO GENERIC SKILL FOUND");
    return 0;
}
public NW3_GenericSkillLevel(Handle:plugin,numParams){
    
    new client=GetNativeCell(1);
    new genericskill=GetNativeCell(2);
    new count=GenericSkill[genericskill][redirectedcount];
    new found=0;
    new level=0;
    new reallevel=0;
    new customernumber=0;
    new clientrace=War3_GetRace(client);
    for(new i=0;i<count;i++){
        if(clientrace==GenericSkill[genericskill][redirectedfromrace][i]){
            level = War3_GetSkillLevel( client, GenericSkill[genericskill][redirectedfromrace][i], GenericSkill[genericskill][redirectedfromskill][i]);
            ////if(level)
            //{ 
            found++;
            reallevel=level;
            customernumber=i;
            //}
        }
    }
    if(found>1){
        War3_LogError("ERR FOUND MORE THAN 1 GERNIC SKILL MATCH");
        return 0;
    }
    if(found){
        SetNativeCellRef(3,GenericSkill[genericskill][raceskilldatahandle][customernumber]);
        if(numParams>=4){
            SetNativeCellRef(4, GenericSkill[genericskill][redirectedfromrace][customernumber]);
        }
        if(numParams>=5){
            SetNativeCellRef(5, GenericSkill[genericskill][redirectedfromskill][customernumber]);
        }
    }
    return reallevel;
    
}
public NW3_IsSkillUsingGenericSkill(Handle:plugin,numParams)
{
    new raceid=GetNativeCell(1);
    new skill_id=GetNativeCell(2);
    return SkillRedirectedToGSkill[raceid][skill_id];
}

CreateNewRace(String:tracename[]  ,  String:traceshortname[], TheReloadRaceId){
    
    
    
    if(RaceExistsByShortname(traceshortname)&&TheReloadRaceId<=0){
        new oldraceid=GetRaceIDByShortname(traceshortname);
        //PrintToServer("Race already exists: %s, returning old raceid %d",traceshortname,oldraceid);
        ignoreRaceEnd=true;
        return oldraceid;
    }
    
    if(totalRacesLoaded+1==MAXRACES&&TheReloadRaceId<=0){ //make sure we didnt reach our race capacity limit
        LogError("MAX RACES REACHED, CANNOT REGISTER %s %s",tracename,traceshortname);
        return 0;
    }
    
    if(racecreationended==false){
        new String:error[512];
        Format(error,sizeof(error),"CreateNewRace was called before previous race creation was ended!!! first race not ended: %s second race: %s ",creatingraceshortname,traceshortname);
        War3Failed(error);
    }
    
    racecreationended=false;
    Format(creatingraceshortname,sizeof(creatingraceshortname),"%s",traceshortname);
    
    //first race registering, fill in the  zeroth race along
    if(totalRacesLoaded==0){
        for(new i=0;i<MAXSKILLCOUNT;i++){
            Format(raceSkillName[totalRacesLoaded][i],31,"ZEROTH RACE SKILL");
            Format(raceSkillDescription[totalRacesLoaded][i],2000,"ZEROTH RACE SKILL DESCRIPTION");
            
        }
        Format(raceName[totalRacesLoaded],31,"No Race");
    }
    
    
    
    new traceid;
    if(TheReloadRaceId>0)
    {
        traceid=TheReloadRaceId;
        strcopy(raceName[traceid], 31, tracename);
        strcopy(raceShortname[traceid], 16, traceshortname);

        //make all skills zero so we can easily debug
        for(new i=0;i<MAXSKILLCOUNT;i++){
            Format(raceSkillName[traceid][i],31,"NO SKILL DEFINED %d",i);
            Format(raceSkillDescription[traceid][i],2000,"NO SKILL DESCRIPTION DEFINED %d",i);
        }
    }
    else
    {
        totalRacesLoaded++;
        traceid=totalRacesLoaded;
        strcopy(raceName[traceid], 31, tracename);
        strcopy(raceShortname[traceid], 16, traceshortname);
    
        //make all skills zero so we can easily debug
        for(new i=0;i<MAXSKILLCOUNT;i++){
            Format(raceSkillName[traceid][i],31,"NO SKILL DEFINED %d",i);
            Format(raceSkillDescription[traceid][i],2000,"NO SKILL DESCRIPTION DEFINED %d",i);
        }
    }
    
    return traceid; //this will be the new race's id / index
}

GetRacesLoaded(){
    return  totalRacesLoaded;
}
IsSkillUltimate(raceid,skill){
    return skillIsUltimate[raceid][skill];
}
GetRaceSkillMaxLevel(raceid,skill){
    return skillMaxLevel[raceid][skill];
}
GetRaceName(raceid,String:retstr[],maxlen){
    
    if(raceTranslated[raceid]){
        new String:buf[64];
        new String:longbuf[1000];
        Format(buf,sizeof(buf),"%s_RaceName",raceShortname[raceid]);
        Format(longbuf,sizeof(longbuf),"%T",buf,GetTrans());
        return strcopy(retstr, maxlen,longbuf);
    }
    new num=strcopy(retstr, maxlen, raceName[raceid]);
    return num;
}
GetRaceShortname(raceid,String:retstr[],maxlen){
    new num=strcopy(retstr, maxlen, raceShortname[raceid]);
    return num;
}

GetRaceSkillName(raceid,skillindex,String:retstr[],maxlen){
    if(skillTranslated[raceid][skillindex]){
        new String:buf[64];
        new String:longbuf[512];
        
        Format(buf,sizeof(buf),"%s_skill_%s",raceShortname[raceid],raceSkillName[raceid][skillindex]);
        Format(longbuf,sizeof(longbuf),"%T",buf,GetTrans());
        return strcopy(retstr, maxlen,longbuf);
    }
    
    new num=strcopy(retstr, maxlen, raceSkillName[raceid][skillindex]);
    return num;
}

GetRaceSkillDesc(raceid,skillindex,String:retstr[],maxlen){
    if(skillTranslated[raceid][skillindex]){
        new String:buf[64];
        new String:longbuf[512]; 
        Format(buf,sizeof(buf),"%s_skill_%s_desc",raceShortname[raceid],raceSkillName[raceid][skillindex]);
        Format(longbuf,sizeof(longbuf),"%T",buf,GetTrans());
        
        new strreplaces=raceSkillDescReplaceNum[raceid][skillindex];
        for(new i=0;i<strreplaces;i++){
            new String:find[10];
            Format(find,sizeof(find),"#%d#",i+1);
            ReplaceString(longbuf,sizeof(longbuf),find,raceSkillDescReplace[raceid][skillindex][i]);
        }
        
        return strcopy(retstr, maxlen,longbuf);
    }
    
    new num=strcopy(retstr, maxlen, raceSkillDescription[raceid][skillindex]);
    return num;
}

GetRaceSkillCount(raceid){
    if(raceid>0){
        return raceSkillCount[raceid];
    }
    else{
        LogError("bad race ID %d",raceid);
        ThrowNativeError(15,"bad race ID %d",raceid);
    }
    return 0;
}

stock GetRaceSkillNonUltimateCount(raceid){
    new num;
    new skillcount = GetRaceSkillCount(raceid);
    for(new i=1;i<=skillcount;i++){
        if(!IsSkillUltimate(raceid,i)) //regular skill
        {
            num++;
        }
    }
    return num;
}
stock GetRaceSkillIsUltimateCount(raceid){
    new num;
    new SkillCount = GetRaceSkillCount(raceid);
    for(new i=1;i<=SkillCount;i++){
        if(IsSkillUltimate(raceid,i)) //regular skill
        {
            num++;
        }
    }
    return num;
}
//gets max level based on the max levels of its skills
GetRaceMaxLevel(raceid){
    new num=0;
    new SkillCount = GetRaceSkillCount(raceid);
    for(new skill=1;skill<=SkillCount;skill++){
        num+=skillMaxLevel[raceid][skill];
    }
    return num;
}





////we add skill or ultimate here, but we have to define if its a skill or ultimate we are adding
AddRaceSkill(raceid,String:skillname[],String:skilldescription[],bool:isUltimate,tmaxskilllevel){
    if(raceid>0){
        //ok is it an existing skill?
        //new String:existingskillname[64];
        new SkillCount = GetRaceSkillCount(raceid);
        for(new i=1;i<=SkillCount;i++){
            //GetRaceSkillName(raceid,i,existingskillname,sizeof(existingskillname));
            if(StrEqual(skillname,raceSkillName[raceid][i],false)){ ////need raw skill name, because of translations
                //PrintToServer("Skill exists %s, returning old skillid %d",skillname,i);
                
                return i;
            }
        }
        //if(ignoreRaceEnd){
        //    W3Log("%s skill not found, REadding for race %d",skillname,raceid);
        //}
        
        //not existing, will it exceeded maximum?
        if(raceSkillCount[raceid]+1==MAXSKILLCOUNT){
            LogError("SKILL LIMIT FOR RACE %d reached!",raceid);
            return -1;
        }
        
        
        raceSkillCount[raceid]++;
        
        strcopy(raceSkillName[raceid][raceSkillCount[raceid]], 32, skillname);
        
        if(ReloadRaces_Id[raceid]==true)
        {
            new String:LongRaceName[64];
            War3_GetRaceName(raceid,LongRaceName,64);
            PrintToServer("Reloading %s: AddRaceSkill: Skill %s skillid %d",LongRaceName,skillname,raceSkillCount[raceid]);

            for(new i=0;i<MaxClients;i++){    // was MAXPLAYERSCUSTOM
                if(War3_GetRace(i)==raceid)
                {
                    PrintToConsole(i,"Reloading %s: AddRaceSkill: Skill %s skillid %d",LongRaceName,skillname,raceSkillCount[raceid]);
                }
            }
        }
        strcopy(raceSkillDescription[raceid][raceSkillCount[raceid]], 2000, skilldescription);
        skillIsUltimate[raceid][raceSkillCount[raceid]]=isUltimate;
        
        skillMaxLevel[raceid][raceSkillCount[raceid]]=tmaxskilllevel;
        
        //We remove all dependencys(atm there aren't any but we need to call this to apply our default value)
        War3_RemoveDependency(raceid,raceSkillCount[raceid]);
        
        return raceSkillCount[raceid]; //return their actual skill number
        
    }
    return 0;
}


CreateRaceEnd(raceid){
    if(raceid>0){
        racecreationended=true;
        Format(creatingraceshortname,sizeof(creatingraceshortname),"");
        ///now we put shit into the database and create cvars
        if(!ignoreRaceEnd&&raceid>0 && ReloadRaces_Id[raceid]==false)  // Dont let reload races over write these variables.
        {
            new String:shortname[16];
            GetRaceShortname(raceid,shortname,sizeof(shortname));
            
            new String:cvarstr[64];
            Format(cvarstr,sizeof(cvarstr),"%s_minlevel",shortname);
            MinLevelCvar[raceid]=W3CreateCvar(cvarstr,"0","Minimum level for race",Internal_NWar3_IsRaceReloading());
            
            Format(cvarstr,sizeof(cvarstr),"%s_accessflag",shortname);
            AccessFlagCvar[raceid]=W3CreateCvar(cvarstr,"0","Admin access flag required for race",Internal_NWar3_IsRaceReloading());
            
            Format(cvarstr,sizeof(cvarstr),"%s_raceorder",shortname);
            new String:buf[16];
            Format(buf,sizeof(buf),"%d",raceid*100);
            RaceOrderCvar[raceid]=W3CreateCvar(cvarstr,buf,"This race's Race Order on changerace menu",Internal_NWar3_IsRaceReloading());
            
            Format(cvarstr,sizeof(cvarstr),"%s_flags",shortname);
            RaceFlagsCvar[raceid]=W3CreateCvar(cvarstr,"","This race's flags, ie 'hidden,etc",Internal_NWar3_IsRaceReloading());
            
            Format(cvarstr,sizeof(cvarstr),"%s_restrict_items",shortname);
            RestrictItemsCvar[raceid]=W3CreateCvar(cvarstr,"","Which items to restrict for people on this race. Separate by comma, ie 'claw,orb'",Internal_NWar3_IsRaceReloading());
            
            Format(cvarstr,sizeof(cvarstr),"%s_team%d_limit",shortname,1);
            RestrictLimitCvar[raceid][0]=W3CreateCvar(cvarstr,"99","How many people can play this race on team 1 (RED/T)",Internal_NWar3_IsRaceReloading());
            Format(cvarstr,sizeof(cvarstr),"%s_team%d_limit",shortname,2);
            RestrictLimitCvar[raceid][1]=W3CreateCvar(cvarstr,"99","How many people can play this race on team 2 (BLU/CT)",Internal_NWar3_IsRaceReloading());
            
            new temp;
            Format(cvarstr,sizeof(cvarstr),"%s_restrictclass",shortname);
            temp=W3CreateCvar(cvarstr,"","Which classes are not allowed to play this race? Separate by comma. MAXIMUM OF 2!! list: scout,sniper,soldier,demoman,medic,heavy,pyro,spy,engineer",Internal_NWar3_IsRaceReloading());
            W3SetRaceCell(raceid,ClassRestrictionCvar,temp);
            
            Format(cvarstr,sizeof(cvarstr),"%s_category",shortname);
            W3SetRaceCell(raceid,RaceCategorieCvar,W3CreateCvar(cvarstr,"default","Determines in which Category the race should be displayed(if cats are active)",Internal_NWar3_IsRaceReloading()));
            
        }
        if(ReloadRaces_Id[raceid]==true)
        {
            Race_Finished_Reload(raceid);
        }
        ReloadRaces_Id[raceid]=false;
        strcopy(ReloadRaces_longname[raceid], 32, "");
        strcopy(ReloadRaces_Shortname[raceid], 16, "");
        ignoreRaceEnd=false;
    }
}




bool:RaceExistsByShortname(String:shortname[]){
    new String:buffer[16];
    
    new RacesLoaded = GetRacesLoaded();
    for(new raceid=1;raceid<=RacesLoaded;raceid++){
        GetRaceShortname(raceid,buffer,sizeof(buffer));
        if(StrEqual(shortname, buffer, false)){
            return true;
        }
    }
    return false;
}
GetRaceIDByShortname(String:shortname[]){
    new String:buffer[16];
    
    new RacesLoaded =GetRacesLoaded();
    for(new raceid=1;raceid<=RacesLoaded;raceid++){
        GetRaceShortname(raceid,buffer,sizeof(buffer));
        if(StrEqual(shortname, buffer, false)){
            return raceid;
        }
    }
    return 0;
}

//return -1 if race1 < race2     race1 earlier on list
//return 1 if race1 > race2      race1 later on the list
//higher order means later in the menu
public SortRacesByRaceOrder(index1, index2, Handle:races, Handle:hndl_optional)
{
    //BLAME: Necavi / glider
    //callback passes indexes, not races dude!
    new race1=GetArrayCell(races,index1);
    new race2=GetArrayCell(races,index2);
    
    if(race1 > 0 && race2 > 0 )
    {
        if(GetConVarInt(hCvarSortByMinLevel)>0)
        {
            new minlevel1=W3GetRaceMinLevelRequired(race1);
            new minlevel2=W3GetRaceMinLevelRequired(race2);
            
            if(minlevel1 < minlevel2)
            {
                return -1;
            } 
            else if(minlevel1 > minlevel2)
            {
                return 1;
            }
            //if TIE, use race order
            
        }
        //race order is the cvar <race>_raceorder
        new order1 = W3GetRaceOrder(race1);
        new order2 = W3GetRaceOrder(race2);
        if(order1 < order2)
        {
            return -1;
        } 
        else if(order2 < order1)
        {
            return 1;
        }
    }
    return 0;  //tie
}


