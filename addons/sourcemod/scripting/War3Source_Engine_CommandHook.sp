#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo =
{
  name = "War3Source - Engine - Command Hooks",
  author = "War3Source Team",
  description = "Command Hooks for War3Source"
};

new Handle:Cvar_ChatBlocking;

new Handle:g_OnUltimateCommandHandle;
new Handle:g_OnAbilityCommandHandle;

public OnPluginStart()
{
  Cvar_ChatBlocking=CreateConVar("war3_command_blocking","0","block chat commands from showing up");

  RegConsoleCmd("say",War3Source_SayCommand);
  RegConsoleCmd("say_team",War3Source_SayCommand);
  RegConsoleCmd("+ultimate",War3Source_UltimateCommand);
  RegConsoleCmd("-ultimate",War3Source_UltimateCommand);
  RegConsoleCmd("+ability",War3Source_NoNumAbilityCommand);
  RegConsoleCmd("-ability",War3Source_NoNumAbilityCommand); //dont blame me if ur race is a failure because theres too much buttons to press
  RegConsoleCmd("+ability1",War3Source_AbilityCommand);
  RegConsoleCmd("-ability1",War3Source_AbilityCommand);
  RegConsoleCmd("+ability2",War3Source_AbilityCommand);
  RegConsoleCmd("-ability2",War3Source_AbilityCommand);
  RegConsoleCmd("+ability3",War3Source_AbilityCommand);
  RegConsoleCmd("-ability3",War3Source_AbilityCommand);
  RegConsoleCmd("+ability4",War3Source_AbilityCommand);
  RegConsoleCmd("-ability4",War3Source_AbilityCommand);

  RegConsoleCmd("ability",War3Source_OldWCSCommand);
  RegConsoleCmd("ability1",War3Source_OldWCSCommand);
  RegConsoleCmd("ability2",War3Source_OldWCSCommand);
  RegConsoleCmd("ability3",War3Source_OldWCSCommand);
  RegConsoleCmd("ability4",War3Source_OldWCSCommand);
  RegConsoleCmd("ultimate",War3Source_OldWCSCommand);

  RegConsoleCmd("shopmenu",War3Source_CmdShopmenu);
}

public bool:InitNativesForwards()
{
  g_OnUltimateCommandHandle=CreateGlobalForward("OnUltimateCommand",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
  g_OnAbilityCommandHandle=CreateGlobalForward("OnAbilityCommand",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);

  return true;
}



//insensitive
//say foo
//say /foo
//say \foo
//returns TRUE if found
public bool:CommandCheck(String:compare[],String:commandwanted[])
{
  new String:commandwanted2[70];
  new String:commandwanted3[70];
  Format(commandwanted2,sizeof(commandwanted2),"\\%s",commandwanted);
  Format(commandwanted3,sizeof(commandwanted3),"/%s",commandwanted);
  if(strcmp(compare,commandwanted,false)==0||strcmp(compare,commandwanted2,false)==0||strcmp(compare,commandwanted3,false)==0)
  {
    return true;
  }

  return false;
}

//RETURNS FINAL INTEGER VALUE IN COMMAND
//war3top10 -> 10 if command is "war3top"
//insensitive
//say foo
//say /foo
//say \foo
//returns -1 if NO COMMAND
public CommandCheckEx(String:compare[],String:commandwanted[])
{
  if(StrEqual(commandwanted,"",false))
  {
    return -1;
  }

  new String:commandwanted2[70];
  new String:commandwanted3[70];
  Format(commandwanted2,sizeof(commandwanted2),"\\%s",commandwanted);
  Format(commandwanted3,sizeof(commandwanted3),"/%s",commandwanted);
  if(StrContains(compare,commandwanted,false)==0||StrContains(compare,commandwanted2,false)==0||StrContains(compare,commandwanted3,false)==0)
  {
    ReplaceString(compare,70,commandwanted,"",false);
    ReplaceString(compare,70,commandwanted2,"",false);
    ReplaceString(compare,70,commandwanted3,"",false);
    new val=StringToInt(compare);
    if(val>0)
    {
      return val;
    }
  }
  return -1;
}

public bool:CommandCheckStartsWith(String:compare[],String:commandwanted[])
{
  new String:commandwanted2[70];
  new String:commandwanted3[70];
  Format(commandwanted2,sizeof(commandwanted2),"\\%s",commandwanted);
  Format(commandwanted3,sizeof(commandwanted3),"/%s",commandwanted);
  //matching at == 0 means string is found and is at index 0
  if(StrContains(compare, commandwanted, false)==0||
     StrContains(compare, commandwanted2, false)==0||
     StrContains(compare, commandwanted3, false)==0)
  {
    return true;
  }
  return false;
}
public Action:War3Source_CmdShopmenu(client,args)
{
  W3CreateEvent(DoShowShopMenu,client);
  return Plugin_Handled;
}

public Action:War3Source_SayCommand(client,args)
{
  //arg0 is say
  //arg1 is argument, ie "playerinfo ownz"
  decl String:arg1[70];
  GetCmdArg(1,arg1,sizeof(arg1));
  TrimString(arg1);
  new top_num;

  new Action:returnblocking = (GetConVarInt(Cvar_ChatBlocking)>0)?Plugin_Handled:Plugin_Continue;
  if(CommandCheck(arg1,"showxp") || CommandCheck(arg1,"xp"))
  {
    War3_ShowXP(client);
    return returnblocking;
  }
  else if(CommandCheckStartsWith(arg1,"changerace")||CommandCheckStartsWith(arg1,"cr ")||CommandCheck(arg1,"cr"))
  {

    //index 2 is right after the changerace word
    new String:changeraceArg[32];
    new bool:succ=StrToken(arg1,2,changeraceArg,sizeof(changeraceArg));
    //DP("%s",changeraceArg);
    new raceFound=0;
    if(succ){

        new String:sRaceName[64];
        new RacesLoaded=War3_GetRacesLoaded();
        SetTrans(client);
        //full name
        for(new race=1;race<=RacesLoaded;race++)
        {
            War3_GetRaceName(race,sRaceName,sizeof(sRaceName));
            if(StrContains(sRaceName,changeraceArg,false)>-1){
                raceFound=race;
                break;
            }
            War3_GetRaceShortname(race,sRaceName,sizeof(sRaceName));
        }
        //shortname
        for(new race=1;raceFound==0&&race<=RacesLoaded;race++)
        {
            War3_GetRaceShortname(race,sRaceName,sizeof(sRaceName));
            if(StrContains(sRaceName,changeraceArg,false)>-1){
                raceFound=race;
                break;
            }
        }
        if(raceFound>0)
        {
            W3UserTriedToSelectRace(client,raceFound,true);
        }
        //no race found, show menu
        else if(!CommandCheckStartsWith(arg1,"cr"))
        {
            W3CreateEvent(DoShowChangeRaceMenu,client);
        }
    }
    else //no second argument, show menu
    {
        W3CreateEvent(DoShowChangeRaceMenu,client);
    }
    return returnblocking;
  }
  else if(CommandCheck(arg1,"war3help")||CommandCheck(arg1,"help")||CommandCheck(arg1,"wchelp"))
  {
    W3CreateEvent(DoShowHelpMenu,client);
    return returnblocking;
  }
  else if(CommandCheck(arg1,"war3version"))
  {
    new String:version[64];
    new Handle:g_hCVar = FindConVar("war3_version");
    if(g_hCVar!=INVALID_HANDLE)
    {
      GetConVarString(g_hCVar, version, sizeof(version));
      War3_ChatMessage(client,"War3Source Current Version: %s",version);
    }
    return returnblocking;
  }
  else if(CommandCheck(arg1,"itemsinfo")||CommandCheck(arg1,"iteminfo"))
  {
    W3CreateEvent(DoShowItemsInfoMenu,client);
    return returnblocking;
  }
  else if(CommandCheck(arg1,"itemsinfo2")||CommandCheck(arg1,"iteminfo2"))
  {
    W3CreateEvent(DoShowItems2InfoMenu,client);
    return returnblocking;
  }
  else if(CommandCheckStartsWith(arg1,"playerinfo"))
  {
    new Handle:array=CreateArray(300);
    PushArrayString(array,arg1);
    W3SetVar(hPlayerInfoArgStr,array);
    W3CreateEvent(DoShowPlayerinfoEntryWithArg,client);

    CloseHandle(array);
    return returnblocking;
  }
  else if(CommandCheck(arg1,"raceinfo"))
  {
    W3CreateEvent(DoShowRaceinfoMenu,client);
    return returnblocking;
  }
  else if(CommandCheck(arg1,"speed"))
  {
    new ClientX=client;
    new bool:SpecTarget=false;
    if(GetClientTeam(client)==1) // Specator
    {
      if (!IsPlayerAlive(client))
      {
        ClientX = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
        if (ClientX == -1)  // if spectator target does not exist then...
        {
          //DP("Spec target does not exist");
          War3_ChatMessage(client,"While being spectator,\nYou must be spectating a player to get player's speed.");
          return returnblocking;
        }
        else
        {
          //DP("Spec target does Exist!");
          SpecTarget=true;
        }
      }
    }
    new Float:currentmaxspeed=GetEntDataFloat(ClientX,War3_GetGame()==Game_TF?FindSendPropInfo("CTFPlayer","m_flMaxspeed"):FindSendPropInfo("CBasePlayer","m_flLaggedMovementValue"));
    if(GameTF())
    {
      if(SpecTarget==true)
      {
        War3_ChatMessage(client,"%T (%.2fx)","Spectating target's max speed is {amount}",client,currentmaxspeed,W3GetSpeedMulti(ClientX));
      }
      else
      {
        War3_ChatMessage(client,"%T (%.2fx)","Your max speed is {amount}",client,currentmaxspeed,W3GetSpeedMulti(client));
      }
    }
    else
    {
      if(SpecTarget==true)
      {
        War3_ChatMessage(client,"%T","Spectating target's max speed is {amount}",client,currentmaxspeed);
      }
      else
      {
        War3_ChatMessage(client,"%T","Your max speed is {amount}",client,currentmaxspeed);
      }
    }
  }
  else if(CommandCheck(arg1,"maxhp"))
  {
    new maxhp = War3_GetMaxHP(client);
    War3_ChatMessage(client,"%T","Your max health is: {amount}",client,maxhp);
  }
  if(War3_GetRace(client)>0)
  {
    if(CommandCheck(arg1,"skillsinfo")||CommandCheck(arg1,"skl"))
    {
      W3ShowSkillsInfo(client);
      return returnblocking;
    }
    else if(CommandCheck(arg1,"resetskills"))
    {
      W3CreateEvent(DoResetSkills,client);
      return returnblocking;
    }
    else if(CommandCheck(arg1,"spendskills"))
    {
      new race=War3_GetRace(client);
      if(W3GetLevelsSpent(client,race)<War3_GetLevel(client,race))
      W3CreateEvent(DoShowSpendskillsMenu,client);
      else
      War3_ChatMessage(client,"%T","You do not have any skill points to spend, if you want to reset your skills use resetskills",client);
      return returnblocking;
    }
    else if(CommandCheck(arg1,"shopmenu")||CommandCheck(arg1,"sh1"))
    {
      W3CreateEvent(DoShowShopMenu,client);
      return returnblocking;
    }
    else if(CommandCheck(arg1,"shopmenu2")||CommandCheck(arg1,"sh2"))
    {
      W3CreateEvent(DoShowShopMenu2,client);
      return returnblocking;
    }
    else if(CommandCheck(arg1,"war3menu")||CommandCheck(arg1,"w3s")||CommandCheck(arg1,"wcs"))
    {
      W3CreateEvent(DoShowWar3Menu,client);
      return returnblocking;
    }
    else if(CommandCheck(arg1,"levelbank"))
    {
      W3CreateEvent(DoShowLevelBank,client);
      return returnblocking;
    }
    else if(CommandCheck(arg1,"war3rank"))
    {
      if(W3SaveEnabled())
      {
        W3CreateEvent(DoShowWar3Rank,client);
      }
      else
      {
        War3_ChatMessage(client,"%T","This server does not save XP, feature disabled",client);
      }
      return returnblocking;
    }
    else if(CommandCheck(arg1,"war3stats"))
    {
      W3CreateEvent(DoShowWar3Stats,client);
      return returnblocking;
    }
    else if(CommandCheck(arg1,"war3dev"))
    {
      War3_ChatMessage(client,"%T","War3Source Developers",client);
      return returnblocking;
    }
    else if(CommandCheck(arg1,"myinfo"))
    {
      W3SetVar(EventArg1,client);
      W3CreateEvent(DoShowPlayerInfoTarget,client);
      return returnblocking;
    }
    else if(CommandCheck(arg1,"buyprevious")||CommandCheck(arg1,"bp"))
    {
      War3_RestoreItemsFromDeath(client);
      return returnblocking;
    }
    else if(CommandCheck(arg1,"myitems"))
    {
      W3SetVar(EventArg1,client);
      W3CreateEvent(DoShowPlayerItemsOwnTarget,client);
      return returnblocking;
    }
    else if((top_num=CommandCheckEx(arg1,"war3top"))>0)
    {
      if(top_num>100) top_num=100;
      if(W3SaveEnabled())
      {
        W3SetVar(EventArg1,top_num);
        W3CreateEvent(DoShowWar3Top,client);
      }
      else
      {
        War3_ChatMessage(client,"%T","This server does not save XP, feature disabled",client);
      }
      return returnblocking;
    }
    new String:itemshort[100];
    new ItemsLoaded = W3GetItemsLoaded();
    for(new itemid=1;itemid<=ItemsLoaded;itemid++) {
      W3GetItemShortname(itemid,itemshort,sizeof(itemshort));
      if(CommandCheckStartsWith(arg1,itemshort)&&!W3ItemHasFlag(itemid,"hidden")) {
        W3SetVar(EventArg1,itemid);
        W3SetVar(EventArg2,false); //dont show menu again
        if(CommandCheckStartsWith(arg1,"tome")) {//item is tome
          new multibuy;
          if( (multibuy=CommandCheckEx(arg1,"tomes"))>0 || (multibuy=CommandCheckEx(arg1,"tome"))>0 )
          {
            //            PrintToChatAll("passed commandx");
            if(multibuy>10) multibuy=10;
            for(new i=1;i<multibuy;i++) { //doesnt itterate if its 1
              W3CreateEvent(DoTriedToBuyItem,client);
            }
          }
          else {
            War3_ChatMessage(client,"%T","say tomes5 to buy many tomes at once, up to 10",client);
          }
        }
        W3CreateEvent(DoTriedToBuyItem,client);
        return returnblocking;
      }
    }
  }
  else
  {
    if(CommandCheck(arg1,"skillsinfo") ||
        CommandCheck(arg1,"skl") ||
        CommandCheck(arg1,"resetskills") ||
        CommandCheck(arg1,"spendskills") ||
        CommandCheck(arg1,"showskills") ||
        CommandCheck(arg1,"shopmenu") ||
        CommandCheck(arg1,"sh1") ||
        CommandCheck(arg1,"war3menu") ||
        CommandCheck(arg1,"w3s") ||
        CommandCheck(arg1,"war3rank") ||
        CommandCheck(arg1,"war3stats") ||
        CommandCheck(arg1,"levelbank")||
        CommandCheckEx(arg1,"war3top")>0)
    {
      if(W3IsPlayerXPLoaded(client))
      {
        War3_ChatMessage(client,"%T","Select a race first!!",client);
        W3CreateEvent(DoShowChangeRaceMenu,client);
      }
      return returnblocking;
    }
  }

  return Plugin_Continue;
}

public Action:War3Source_UltimateCommand(client,args)
{
  //PrintToChatAll("ult cmd");
  decl String:command[32];
  GetCmdArg(0,command,sizeof(command));

  //PrintToChatAll("%s",command) ;


  //PrintToChatAll("ult cmd2");
  new race=War3_GetRace(client);
  if(race>0)
  {
    //PrintToChatAll("ult cmd3");
    new bool:pressed=false;
    if(StrContains(command,"+")>-1)
      pressed=true;
    Call_StartForward(g_OnUltimateCommandHandle);
    Call_PushCell(client);
    Call_PushCell(race);
    Call_PushCell(pressed);
    new result;
    Call_Finish(result);
    //PrintToChatAll("ult cmd4");
  }

  return Plugin_Handled;
}

public Action:War3Source_AbilityCommand(client,args)
{
  decl String:command[32];
  GetCmdArg(0,command,sizeof(command));

  new bool:pressed=false;
  //PrintToChatAll("%s",command) ;

  if(StrContains(command,"+")>-1)
    pressed=true;
  if(!IsCharNumeric(command[8]))
    return Plugin_Handled;
  new num=_:command[8]-48;
  if(num>0 && num<7)
  {
    Call_StartForward(g_OnAbilityCommandHandle);
    Call_PushCell(client);
    Call_PushCell(num);
    Call_PushCell(pressed);
    new result;
    Call_Finish(result);
  }

  return Plugin_Handled;
}

public Action:War3Source_NoNumAbilityCommand(client,args)
{
  decl String:command[32];
  GetCmdArg(0,command,sizeof(command));
  //PrintToChatAll("%s",command) ;

  new bool:pressed=false;
  if(StrContains(command,"+")>-1)
    pressed=true;
  Call_StartForward(g_OnAbilityCommandHandle);
  Call_PushCell(client);
  Call_PushCell(0);
  Call_PushCell(pressed);
  new result;
  Call_Finish(result);

  return Plugin_Handled;
}

public Action:War3Source_OldWCSCommand(client,args) {
  War3_ChatMessage(client,"%T","The proper commands are +ability, +ability1 ... and +ultimate",client);
}
