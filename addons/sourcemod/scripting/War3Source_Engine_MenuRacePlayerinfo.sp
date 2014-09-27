//#pragma tabsize 0     // doesn't mess with how you format your lines
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
  name = "War3Source - Engine - Player/Race Info",
  author = "War3Source Team",
  description = "Shows information about players/races"
};

new raceinfoshowskillnumber[MAXPLAYERSCUSTOM];

new Handle:ShowOtherPlayerItemsCvar;

public OnPluginStart()
{
  // No Spendskill level restrictions on non-ultimates (Requires mapchange)
  ShowOtherPlayerItemsCvar=CreateConVar("war3_show_playerinfo_other_player_items","1","0 disables showing other players items using playerinfo. [default 1]");

}     //War3_playertargetItemMenu

public OnWar3Event(W3EVENT:event,client){
  if(event==DoShowRaceinfoMenu){
    ShowMenuRaceinfo(client);
  }
  if(event==DoShowPlayerinfoMenu){
    War3_PlayerInfoMenu(client,"");
  }
  if(event==DoShowPlayerinfoEntryWithArg){
    PlayerInfoMenuEntry(client);
  }
  if(event==DoShowParticularRaceInfo){
    new raceid = W3GetVar(RaceinfoRaceToShow);
    if(ValidRace(raceid)) {
      War3_ShowParticularRaceInfoMenu(client,raceid);
    }
  }
  if(event==DoShowPlayerInfoTarget){
    new target = W3GetVar(EventArg1);
    if(ValidPlayer(target,false)) {
      War3_playertargetMenu(client,target) ;
    }
  }
  if(event==DoShowPlayerItemsOwnTarget){
    new target = W3GetVar(EventArg1);
    if(ValidPlayer(target,false)) {
      War3_playertargetItemMenu(client,target) ;
    }
  }
}
ShowMenuRaceinfo(client){
  SetTrans(client);
  new Handle:hMenu=CreateMenu(War3_raceinfoSelected);
  SetMenuExitButton(hMenu,true);
  SetSafeMenuTitle(hMenu,"%T\n ","[War3Source] Select a race for more info",client);
  // Iteriate through the races and print them out
  
  decl String:rbuf[4];
  decl String:rracename[64];
  decl String:rdisp[128];
  
  new racelist[MAXRACES];
  new racedisplay=W3GetRaceList(racelist);
  //if(GetConVarInt(W3GetVar(hSortByMinLevelCvar))<1){
  //  for(new x=0;x<War3_GetRacesLoaded();x++){//notice this starts at zero!
  //    racelist[x]=x+1;
  //  }
  //}
  
  
    
  
  for(new i=0;i<racedisplay;i++) //notice this starts at zero!
  {
    new raceid=racelist[i];
  
    Format(rbuf,sizeof(rbuf),"%d",raceid); //DATA FOR MENU!
    War3_GetRaceName(raceid,rracename,sizeof(rracename));
    
    
    
    new yourteam,otherteam;
    for(new y=1;y<=MaxClients;y++)
    {
      
      if(ValidPlayer(y,false))
      {
        if(War3_GetRace(y)==raceid)
        {
          if(GetClientTeam(client)==GetClientTeam(y))
          {
            ++yourteam;
          }
          else
          {
            ++otherteam;
          }
        }
      }
    }
    new String:extra[3];
    if(War3_GetRace(client)==raceid)
    {
      Format(extra,sizeof(extra),">");
      
    }
    else if(W3GetPendingRace(client)==raceid){
      Format(extra,sizeof(extra),"<");
      
    }
    
    Format(rdisp,sizeof(rdisp),"%s%s (%d,%d)",extra,rracename,yourteam,otherteam);
    AddMenuItem(hMenu,rbuf,rdisp);
  }
  DisplayMenu(hMenu,client,MENU_TIME_FOREVER);
}


public War3_raceinfoSelected(Handle:menu,MenuAction:action,client,selection)
{
  if(action==MenuAction_Select)
  {
    if(ValidPlayer(client))
    {
      
      decl String:SelectionInfo[4];
      decl String:SelectionDispText[256];
      
      new SelectionStyle;
      GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
      new race_selected=StringToInt(SelectionInfo);
      
      raceinfoshowskillnumber[client]=-1;
      War3_ShowParticularRaceInfoMenu(client,race_selected);
    }
  }
  if(action==MenuAction_End)
  {
    CloseHandle(menu);
  }
}

bool:GetRaceStat(raceid,bool:game=false,String:type[]="kdr",&Float:floatresult){
    new Handle:trie=W3GetStatsKDRTrie();
    
    //new String:result;
    new String:prepend[116];
    new String:raceshort[32];
    War3_GetRaceShortname(raceid,raceshort,sizeof(raceshort));
    
    Format(prepend,sizeof(prepend),"%s_%s_%s",game?"game":"server",raceshort,type);
    //DP("prepend %s",prepend);
    new String:value[32];
    if(GetTrieString(trie,prepend,value,sizeof(value))){
        floatresult=StringToFloat(value);
        return true;
    }
    return false;
}
public War3_ShowParticularRaceInfoMenu(client,raceid){
  SetTrans(client);
  new Handle:hMenu=CreateMenu(War3_particularraceinfoSelected);
  SetMenuExitButton(hMenu,true);
  
  new String:racename[64];
  new String:skilldesc[1000];
  new String:skillname[64];
  //new String:longbuf[7000];
  War3_GetRaceName(raceid,racename,sizeof(racename));


  
  new String:selectioninfo[32];
  
  new String:title[512];
  Format(title,sizeof(title),"%T","[War3Source] Information for race: {racename} (LVL {amount}/{amount})",client,racename,War3_GetLevel(client,raceid),W3GetRaceMaxLevel(raceid));
    
  //DP("%d",raceinfoshowskillnumber[client]);
  if(raceinfoshowskillnumber[client]==-1){
    new Float:ratio;
    
    if(GetRaceStat(raceid,false,"kdr",ratio)){
        Format(title[strlen(title)],sizeof(title),"\nServer Kill/Death: %0.2f",ratio);
        //DP("got ratio");
    }
    if(GetRaceStat(raceid,false,"wlr",ratio)){
        Format(title[strlen(title)],sizeof(title),"\nServer Win/Loss: %0.2f",ratio);
        //DP("got ratio");
    }
    if(GetRaceStat(raceid,true,"kdr",ratio)){
        Format(title[strlen(title)],sizeof(title),"\nGame K/D: %0.2f",ratio);
        //DP("got ratio");
    }
    if(GetRaceStat(raceid,true,"wlr",ratio)){
        Format(title[strlen(title)],sizeof(title),"\nGame W/L: %0.2f",ratio);
        //DP("got ratio");
    }
    
    //DP("%f",ratio);
    
    
    
     
        
  }
  StrCat(title,sizeof(title),"\n \n");
  SetSafeMenuTitle(hMenu,title);
  new level;
  new SkillCount = War3_GetRaceSkillCount(raceid);
  for(new x=1;x<=SkillCount;x++)
  {
    decl String:str[1000];
    W3GetRaceSkillName(raceid,x,skillname,sizeof(skillname));
    level=War3_GetSkillLevelINTERNAL(client,raceid,x) ;
    
    if(War3_IsSkillUltimate(raceid,x))
    {
      Format(str,sizeof(str),"%T","Ultimate: {skillname} (LVL {amount}/{amount})",client,skillname,level,W3GetRaceSkillMaxLevel(raceid,x));
    }
    else
    {
      Format(str,sizeof(str),"%T","{skillname} (LVL {amount}/{amount})",client,skillname,level,W3GetRaceSkillMaxLevel(raceid,x));
    }
    
    Format(selectioninfo,sizeof(selectioninfo),"%d,skill,%d",raceid,x);
    
    
    if(raceinfoshowskillnumber[client]==x){
    
      W3GetRaceSkillDesc(raceid,x,skilldesc,sizeof(skilldesc)) ;
    //  AddMenuItem(hMenu,selectioninfo,skilldesc,ITEMDRAW_RAWLINE); //,ITEMDRAW_DISABLED|ITEMDRAW_RAWLINE
    
      Format(str,sizeof(str),"%s \n%s \n",str,skilldesc);
    //Format(longbuf,sizeof(longbuf),"%s\n%s%s  (Level %d/%d)\n%s\n ",longbuf,,skillname,level,,skilldesc);
    }
    
    if(x==War3_GetRaceSkillCount(raceid)&&raceinfoshowskillnumber[client]==x){
      Format(str,sizeof(str),"%s \n",str); //extend whitespace
    }
    else if(x==War3_GetRaceSkillCount(raceid)){
      Format(str,sizeof(str),"%s \n \n",str); //extend whitespace
    }
    
    AddMenuItem(hMenu,selectioninfo,str);
  }
  
  Format(selectioninfo,sizeof(selectioninfo),"%d,raceinfo,%d",raceid,0);
  new String:str[100];
  Format(str,sizeof(str),"%T \n \n","Back to raceinfo",client);
  AddMenuItem(hMenu,selectioninfo,str);
  
  Format(selectioninfo,sizeof(selectioninfo),"%d,0,%d",raceid,0);
  AddMenuItem(hMenu,selectioninfo,"",ITEMDRAW_NOTEXT); //empty line
  
  new String:selectionDisplayBuff[64];
  Format(selectionDisplayBuff,sizeof(selectionDisplayBuff),"%T \n \n","See all players with race {racename}",client,racename) ;
  Format(selectioninfo,sizeof(selectioninfo),"%d,seeall,%d",raceid,0);  
  AddMenuItem(hMenu,selectioninfo,selectionDisplayBuff);
 
  
  
  DisplayMenu(hMenu,client,MENU_TIME_FOREVER);
}














public War3_particularraceinfoSelected(Handle:menu,MenuAction:action,client,selection)
{
  if(action==MenuAction_Select)
  {
    if(ValidPlayer(client))
    {
      
      new String:exploded[3][32];
      
      decl String:SelectionInfo[32];
      decl String:SelectionDispText[256];
      new SelectionStyle;
      GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
      
      ExplodeString(SelectionInfo, ",", exploded, 3, 32);
      new raceid=StringToInt(exploded[0]);
      
      if(StrEqual(exploded[1],"skill")){ //OR ULT
        new skillnum=StringToInt(exploded[2]);
        if(raceinfoshowskillnumber[client]==skillnum){ //cancel
          raceinfoshowskillnumber[client]=-1;
        }
        else{
          raceinfoshowskillnumber[client]=skillnum;
        }
        War3_ShowParticularRaceInfoMenu(client,raceid);
    
      }
      else if(StrEqual(exploded[1],"raceinfo")){
        ShowMenuRaceinfo(client);
      }
      else if(StrEqual(exploded[1],"seeall")){
        //show all players with this raceid
        
        
        War3_playersWhoAreThisRaceMenu(client,raceid);
      }
      
    }
  }
  if(action==MenuAction_End)
  {
    CloseHandle(menu);
  }
}













War3_playersWhoAreThisRaceMenu(client,raceid){
  new Handle:hMenu=CreateMenu(War3_playersWhoAreThisRaceSel);
  SetMenuExitButton(hMenu,true);
  
  new String:racename[64];
  War3_GetRaceName(raceid,racename,sizeof(racename));
  
  SetSafeMenuTitle(hMenu,"%T\n \n","[War3Source] People who are race: {racename}",client,racename);
  
  decl String:playername[64];
  decl String:war3playerbuf[4];
  
  for(new x=1;x<=MaxClients;x++)
  {
    if(ValidPlayer(x)&&War3_GetRace(x)==raceid){
      
      Format(war3playerbuf,sizeof(war3playerbuf),"%d",x);  //target index
      GetClientName(x,playername,sizeof(playername));
      decl String:menuitemstr[100];
      decl String:teamname[10];
      GetShortTeamName( GetClientTeam(x),teamname,sizeof(teamname));
      Format(menuitemstr,sizeof(menuitemstr),"%T","{player} (Level {amount}) [{team}]",client,playername,War3_GetLevel(x,raceid),teamname);
      AddMenuItem(hMenu,war3playerbuf,menuitemstr);
    }
  }
  DisplayMenu(hMenu,client,MENU_TIME_FOREVER);
  
}
public War3_playersWhoAreThisRaceSel(Handle:menu,MenuAction:action,client,selection)
{
  if(action==MenuAction_Select)
  {
    
    decl String:SelectionInfo[4];
    decl String:SelectionDispText[256];
    new SelectionStyle;
    GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
    new target=StringToInt(SelectionInfo);
    if(ValidPlayer(target))
      War3_playertargetMenu(client,target);
    else
      War3_ChatMessage(client,"%T","Player has left the server",client);
  
  }
  if(action==MenuAction_End)
  {
    CloseHandle(menu);
  }
}





PlayerInfoMenuEntry(client){
  new String:arg[32];
  new Handle:dataarray=W3GetVar(hPlayerInfoArgStr); //should always be created, upper plugin closes handle
  GetArrayString(dataarray,0,arg,sizeof(arg));
  War3_PlayerInfoMenu(client,arg);
}


War3_PlayerInfoMenu(client,String:arg[]){
  SetTrans(client);
  //PrintToChatAll("%s",arg);
  if(strlen(arg)>10){   //has argument (space after)
    new String:arg2[32];
    Format(arg2,sizeof(arg2),"%s",arg[11]);
    //PrintToChatAll("%s",arg2);
    
    
    new found=0;
    new targetlist[MAXPLAYERSCUSTOM];
    new String:name[32];
    for(new i=1;i<=MaxClients;i++){
      if(ValidPlayer(i)){
        GetClientName(i,name,sizeof(name));
        if(StrContains(name,arg2,false)>-1){
          targetlist[found++]=i;
        }
      }
    }
    if(found==0){
      War3_ChatMessage(client,"%T","playerinfo <optional name>: No target found",client);
    }
    else if(found>1){
      War3_ChatMessage(client,"%T","playerinfo <optional name>: More than one target found",client);
      //redundant code..maybe we should optmize?
      new Handle:hMenu=CreateMenu(War3_playerinfoSelected1);
      SetMenuExitButton(hMenu,true);
      SetSafeMenuTitle(hMenu,"%T\n ","[War3Source] Select a player to view its information",client);
      // Iteriate through the players and print them out
      decl String:playername[32];
      decl String:war3playerbuf[4];
      decl String:racename[64];
      decl String:menuitem[100] ;
      for(new i=0;i<found;i++)
      {
        new clientindex=targetlist[i];
        Format(war3playerbuf,sizeof(war3playerbuf),"%d",clientindex);  //target index
        GetClientName(clientindex,playername,sizeof(playername));
        War3_GetRaceName(War3_GetRace(clientindex),racename,sizeof(racename));
        if(War3_GetRace(clientindex)>0)
        {
          Format(menuitem,sizeof(menuitem),"%T","{player} ({racename} LVL {amount})",GetTrans(),playername,racename,War3_GetLevel(clientindex,War3_GetRace(clientindex)));
        }
        else
        {
          Format(menuitem,sizeof(menuitem),"%T","{player} ({racename})",GetTrans(),playername,racename);
        }
        AddMenuItem(hMenu,war3playerbuf,menuitem);
        
      }
      DisplayMenu(hMenu,client,MENU_TIME_FOREVER);
       
    }
    else {
      War3_playertargetMenu(client,targetlist[0]);
    }
  }
  else
  {
    
    new Handle:hMenu=CreateMenu(War3_playerinfoSelected1);
    SetMenuExitButton(hMenu,true);
    SetSafeMenuTitle(hMenu,"%T\n ","[War3Source] Select a player to view its information",client);
    // Iteriate through the players and print them out
    decl String:playername[32];
    decl String:war3playerbuf[4];
    decl String:racename[64];
    decl String:menuitem[100] ;
    for(new x=1;x<=MaxClients;x++)
    {
      if(ValidPlayer(x)){
        
        Format(war3playerbuf,sizeof(war3playerbuf),"%d",x);  //target index
        GetClientName(x,playername,sizeof(playername));
        War3_GetRaceName(War3_GetRace(x),racename,sizeof(racename));
        if(War3_GetRace(x)>0)
        {
          Format(menuitem,sizeof(menuitem),"%T","{player} ({racename} LVL {amount})",GetTrans(),playername,racename,War3_GetLevel(x,War3_GetRace(x)));
        }
        else
        {
          Format(menuitem,sizeof(menuitem),"%T","{player} ({racename})",GetTrans(),playername,racename);
        }
        AddMenuItem(hMenu,war3playerbuf,menuitem);
      }
    }
    DisplayMenu(hMenu,client,MENU_TIME_FOREVER);
  }
}

public War3_playerinfoSelected1(Handle:menu,MenuAction:action,client,selection)
{
  if(action==MenuAction_Select)
  {
    decl String:SelectionInfo[4];
    decl String:SelectionDispText[256];
    new SelectionStyle;
    GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
    new target=StringToInt(SelectionInfo);
    if(ValidPlayer(target))
      War3_playertargetMenu(client,target);
    else
      War3_ChatMessage(client,"%T","Player has left the server",client);
  }
  if(action==MenuAction_End)
  {
    CloseHandle(menu);
  }
}


War3_playertargetMenu(client,target) {
  SetTrans(client);
  new Handle:hMenu=CreateMenu(War3_playertargetMenuSelected);
  SetMenuExitButton(hMenu,true);

  new String:targetname[32];
  GetClientName(target,targetname,sizeof(targetname));
  
  new String:racename[64];
  new String:skillname[64];
  
  new raceid=War3_GetRace(target);
  War3_GetRaceName(raceid,racename,sizeof(racename));
   
  new level;
  level=War3_GetLevel(target,raceid);
  
  new String:title[3000];

  Format(title,sizeof(title),"%T\n \n","[War3Source] Information for {player}",client,targetname);
  Format(title,sizeof(title),"%s%T\n \n",title,"Total levels: {amount}",client,W3GetTotalLevels(target));
  
  if(level<W3GetRaceMaxLevel(raceid)){
    Format(title,sizeof(title),"%s%T",title,"Current Race: {racename} (LVL {amount}/{amount}) XP: {amount}/{amount}",client,racename,level,W3GetRaceMaxLevel(raceid),War3_GetXP(target,raceid),W3GetReqXP(level+1));
  }else{
    Format(title,sizeof(title),"%s%T",title,"Current Race: {racename} (LVL {amount}/{amount}) XP: {amount}",client,racename,level,W3GetRaceMaxLevel(raceid),War3_GetXP(target,raceid));
  }
  Format(title,sizeof(title),"%s\n",title);
  
  new SkillCount = War3_GetRaceSkillCount(raceid);
  for(new x=1;x<=SkillCount;x++)
  {
    W3GetRaceSkillName(raceid,x,skillname,sizeof(skillname));
    level=War3_GetSkillLevelINTERNAL(target,raceid,x) ;
    if(War3_IsSkillUltimate(raceid,x))
    {
      Format(title,sizeof(title),"%s%T\n",title,"Ultimate: {skillname} (LVL {amount}/{amount})",client,skillname,level,W3GetRaceSkillMaxLevel(raceid,x));
    }
    else
    {
      Format(title,sizeof(title),"%s%T\n",title,"{skillname} (LVL {amount}/{amount})",client,skillname,level,W3GetRaceSkillMaxLevel(raceid,x));
    }
  }
  // IF FALSE:
  // ONLY SHOW ITEMS IF YOU ARE OWNER
  // DON'T SHOW OTHER PLAYERS ITEMS
//  if(client==target)
  if(GetConVarBool(ShowOtherPlayerItemsCvar)&&client!=target)
  {
    Format(title,sizeof(title),"%s\n \n%T\n",title,"Items:",client);
  
    new String:itemname[64];
    new moleitemid=War3_GetItemIdByShortname("mole");
    new ItemsLoaded = W3GetItemsLoaded();
    for(new itemid=1;itemid<=ItemsLoaded;itemid++)
    {
      if(War3_GetOwnsItem(target,itemid)&&itemid!=moleitemid)
      {
       W3GetItemName(itemid,itemname,sizeof(itemname));
       Format(title,sizeof(title),"%s\n%s",title,itemname);
      }
    }
  }
  else if(client==target)
  {
    Format(title,sizeof(title),"%s\n \n%T\n",title,"Items:",client);

    new String:itemname[64];
    new moleitemid=War3_GetItemIdByShortname("mole");
    new ItemsLoaded = W3GetItemsLoaded();
    for(new itemid=1;itemid<=ItemsLoaded;itemid++)
    {
      if(War3_GetOwnsItem(target,itemid)&&itemid!=moleitemid)
      {
       W3GetItemName(itemid,itemname,sizeof(itemname));
       Format(title,sizeof(title),"%s\n%s",title,itemname);
      }
    }
  }
  new Float:armorred=(1.0-W3GetPhysicalArmorMulti(target))*100;
  Format(title,sizeof(title),"%s\n \n%T",title,"Physical Armor: {amount} (+-{amount}%)",client,W3GetBuffSumFloat(target,fArmorPhysical),armorred<0.0?"+":"-",armorred<0.0?armorred*-1.0:armorred);
  
  armorred=(1.0-W3GetMagicArmorMulti(target))*100;
  Format(title,sizeof(title),"%s\n%T",title,"PImagicArmor: {amount} (+-{amount}%)",client,W3GetBuffSumFloat(target,fArmorMagic),armorred<0.0?"+":"-",armorred<0.0?armorred*-1.0:armorred);
  
  Format(title,sizeof(title),"%s\n \n",title);
  
  
  SetSafeMenuTitle(hMenu,"%s",title);
  // Iteriate through the races and print them out
  
  
  
  
  new String:buf[3];
  
  IntToString(target,buf,sizeof(buf));
  new String:str[100];
  Format(str,sizeof(str),"%T","Refresh",client);
  AddMenuItem(hMenu,buf,str);
  
  new String:selectionDisplayBuff[64];
  Format(selectionDisplayBuff,sizeof(selectionDisplayBuff),"%T","See {racename} Race information",client,racename)  ;
  AddMenuItem(hMenu,buf,selectionDisplayBuff); 
  
  Format(selectionDisplayBuff,sizeof(selectionDisplayBuff),"%T","See all players with race {racename}",client,racename) ;
  AddMenuItem(hMenu,buf,selectionDisplayBuff); 
  
  Format(selectionDisplayBuff,sizeof(selectionDisplayBuff),"%T","Spectate Player",client) ;
  AddMenuItem(hMenu,buf,selectionDisplayBuff); 
  
  DisplayMenu(hMenu,client,MENU_TIME_FOREVER);
}

War3_playertargetItemMenu(client,target) {

    new Handle:hMenu=CreateMenu(War3_playertargetItemMenuSelected2);
    SetMenuExitButton(hMenu,true);

    new String:title[3000];

    // Items info
    //if(client==target)
    //{
    Format(title,sizeof(title),"%s\n \n%T\n",title,"Items:",client);

    Format(title,sizeof(title),"%s\n \n",title);

    new String:itemname[64];
    new moleitemid=War3_GetItemIdByShortname("mole");
    new ItemsLoaded = W3GetItemsLoaded();
    for(new itemid=1;itemid<=ItemsLoaded;itemid++)
    {
      if(War3_GetOwnsItem(target,itemid)&&itemid!=moleitemid)
      {
        W3GetItemName(itemid,itemname,sizeof(itemname));
        Format(title,sizeof(title),"%s\n%s",title,itemname);
      }
    }
    Format(title,sizeof(title),"%s\n \n",title);
    
    new Items2Loaded = W3GetItems2Loaded();
    for(new itemid=1;itemid<=Items2Loaded;itemid++)
    {
      if(War3_GetOwnsItem2(target,itemid)&&itemid!=moleitemid)
      {
        W3GetItem2Name(itemid,itemname,sizeof(itemname));
        Format(title,sizeof(title),"%s\n%s",title,itemname);
      }
    }
  //}

    Format(title,sizeof(title),"%s\n \n",title);

    SetSafeMenuTitle(hMenu,"%s",title);

    new String:buf[3];

    IntToString(target,buf,sizeof(buf));
    new String:str[100];
    Format(str,sizeof(str),"%T","Refresh",client);
    AddMenuItem(hMenu,buf,str);

    DisplayMenu(hMenu,client,MENU_TIME_FOREVER);
}


public War3_playertargetItemMenuSelected2(Handle:menu,MenuAction:action,client,selection)
  if(action==MenuAction_Select)
  {
    decl String:SelectionInfo[4];
    decl String:SelectionDispText[256];
    new SelectionStyle;
    GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
    new target=StringToInt(SelectionInfo);
    if(!ValidPlayer(target)){
      War3_ChatMessage(client,"%T","Player has left the server",client);
    }
    else
    {
      if(selection==0){
        War3_playertargetItemMenu(client,target);
      }
    }
    if(action==MenuAction_End)
    {
      CloseHandle(menu);
    }
}

public War3_playertargetMenuSelected(Handle:menu,MenuAction:action,client,selection)
{
  if(action==MenuAction_Select)
  {
    decl String:SelectionInfo[4];
    decl String:SelectionDispText[256];
    new SelectionStyle;
    GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
    new target=StringToInt(SelectionInfo);
    if(!ValidPlayer(target)){
      War3_ChatMessage(client,"%T","Player has left the server",client);
    }
    else{
    
      if(selection==0){
        War3_playertargetMenu(client,target);
      }
      if(selection==1){
        new raceid=War3_GetRace(target);
        War3_ShowParticularRaceInfoMenu(client,raceid);
      }
      if(selection==2){
        new raceid=War3_GetRace(target);
        War3_playersWhoAreThisRaceMenu(client,raceid);
      }
      if(selection==3){
        if(ValidPlayer(target,true)){
          SetEntDataEnt2(client, FindSendPropOffs("CBasePlayer", "m_hObserverTarget"),target,true);
        }
        else{
          War3_ChatMessage(client,"%T","Player Not Alive",client);
        }
        War3_playertargetMenu(client,target);
      }
    }
  }
  if(action==MenuAction_End)
  {
    CloseHandle(menu);
  }
}



