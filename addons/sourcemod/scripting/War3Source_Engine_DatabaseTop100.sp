#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Database Top 100",
    author = "War3Source Team",
    description = "Display the top players on your server"
};


new bool:bRankCached[MAXPLAYERSCUSTOM];
new iRank[MAXPLAYERSCUSTOM];
new iTotalPlayersDB[MAXPLAYERSCUSTOM]; // this is also cached per client, eg one player might see 1/20 when another sees 2/21

new iTopCount; // there might not be 100 in the array.


new String:Top100Name[101][64];
new String:Top100Steamid[101][64];
new Top100totallevel[101];
new Top100totalxp[101];

public OnMapStart(){
    War3Source_UpdateStats();
}


public OnWar3Event(W3EVENT:event,client){
    if(event==DoShowWar3Rank){
        GetRank(client);
    }
    if(event==DoShowWar3Stats){
        War3Source_Stats(client);
    }
    if(event==DoShowWar3Top){
        new num=W3GetVar(EventArg1);
        War3Source_War3Top(client,num);
    }
}







War3Source_UpdateStats()
{
    new Handle:hDB=W3GetVar(hDatabase);
    if(hDB)
    {
        for(new x=0;x<=MaxClients;x++)
        {
            bRankCached[x]=false;
        }
        //for(new x=0;x<iTopCount;x++)
    //    {
        //    CloseHandle(hTop100[x]);
    //        hTop100[x]=INVALID_HANDLE;
    //    }
        iTopCount=0;
        SQL_TQuery(hDB,T_RetrieveTopCallback,"SELECT steamid,name,total_level,total_xp FROM war3source ORDER BY total_level DESC,total_xp DESC LIMIT 0,100");
    }
}

public T_RetrieveTopCallback(Handle:owner,Handle:query,const String:error[],any:data)
{
    if(query!=INVALID_HANDLE)
    {
        //PrintToServer("T_RetrieveTopCallback");
        SQL_Rewind(query);
        while(SQL_FetchRow(query) && iTopCount < 100) //sqlite leak?
        {
            
            new String:steamid[64];
            new String:name[64];
            if(!W3SQLPlayerString(query,"steamid",steamid,sizeof(steamid)))
                continue;
            if(!W3SQLPlayerString(query,"name",name,sizeof(name)) || StrEqual(name,"",false) || StrEqual(name,"0",false))
            {
                strcopy(name,sizeof(name),steamid);
            }
            Format(Top100Name[iTopCount],sizeof(Top100Name),name);
        
            Format(Top100Steamid[iTopCount],sizeof(Top100Steamid),steamid);
            Top100totallevel[iTopCount]=W3SQLPlayerInt(query,"total_level");
            Top100totalxp[iTopCount]=W3SQLPlayerInt(query,"total_xp");

            ++iTopCount;
        }
        CloseHandle(query);
    }
}
GetRank(client)
{
    
    if(bRankCached[client])
    {
        War3_ChatMessage(client,"%T","Ranked {amount} of {amount}",client,iRank[client],iTotalPlayersDB[client]);
    }
    else
    {
        new Handle:hDB=W3GetVar(hDatabase);
        SQL_TQuery(hDB,T_RetrieveRankCache,"SELECT steamid FROM war3source ORDER BY total_level DESC,total_xp DESC",GetClientUserId(client));
    }
}

public T_RetrieveRankCache(Handle:owner,Handle:query,const String:error[],any:userid)
{
    new client=GetClientOfUserId(userid);
    if(client<=0)
        return; // fuck it, the player left
    new String:client_steamid[64];
    if(!GetClientAuthId(client, AuthId_Steam2, client_steamid, sizeof(client_steamid)))
        return; // invalid auth string, probably a fake steam account
    if(IsFakeClient(client))
        return; // why the fuck is a bot requesting their rank?
    if(query!=INVALID_HANDLE)
    {
        SQL_Rewind(query);
        new iCurRank=0;
        iTotalPlayersDB[client]=0;
        while(SQL_FetchRow(query))
        {
            ++iCurRank;
            new String:steamid[64];
            if(!W3SQLPlayerString(query,"steamid",steamid,sizeof(steamid)))
                continue;
            if(StrEqual(steamid,client_steamid,false))
            {
                iRank[client]=iCurRank;
            }
            ++iTotalPlayersDB[client];
        }
        CloseHandle(query);
        if(iRank[client]>0)
        {
            bRankCached[client]=true;
            War3_ChatMessage(client,"%T","Ranked {amount} of {amount}",client,iRank[client],iTotalPlayersDB[client]);
        }
    }
}






// Stats
War3Source_Stats(client)
{
    
    new Handle:statsMenu=CreateMenu(War3Source_Stats_Selected);
    SetMenuExitButton(statsMenu,true);
    SetSafeMenuTitle(statsMenu,"%T","[War3Source] Select a player to view stats",client);
    decl String:playername[64];
    decl String:war3playerbuf[4];

    for(new x=1;x<=MaxClients;x++)
    {
        if(ValidPlayer(x,false))
        {
            Format(war3playerbuf,sizeof(war3playerbuf),"%d",x);
            GetClientName(x,playername,sizeof(playername));
            AddMenuItem(statsMenu,war3playerbuf,playername);
        }
    }
    DisplayMenu(statsMenu,client,20);
}

public War3Source_Stats_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new target=StringToInt(SelectionInfo);
        if(ValidPlayer(target))
            War3Source_Stats_Player(client,target);
        else
        {
            War3_ChatMessage(client,"%T","The player you selected has left the server",client);
            War3Source_Stats(client);
        }
    }
    if(action==MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public War3Source_Stats_Player(client,target)
{
    if(ValidPlayer(target,false))
    {
        new Handle:playerInfo=CreateMenu(War3Source_Stats_Player_Select);
        SetMenuExitButton(playerInfo,true);
        decl String:playername[64];
        GetClientName(target,playername,sizeof(playername));
        new RacesLoaded = War3_GetRacesLoaded();
        for(new x=1;x<=RacesLoaded;x++)
        {
            
            decl String:race_name[64];
            War3_GetRaceName(x,race_name,sizeof(race_name));
            new String:data_str[16];
            Format(data_str,sizeof(data_str),"%d.%d",target,x);
            AddMenuItem(playerInfo,data_str,race_name);
        }
        
        decl String:race_name[64];
        War3_GetRaceName(War3_GetRace(target),race_name,sizeof(race_name));
        new money = War3_GetCurrency(target);
        SetSafeMenuTitle(playerInfo,"%T\n","[War3Source] Info for {player}. Current Race: {racename} money: {amount}",client,playername,race_name,money);
        DisplayMenu(playerInfo,client,20);
    }
    else
    {
        War3_ChatMessage(client,"%T","The player has disconnected from the server",client);
        War3Source_Stats(client);
    }
}   

public War3Source_Stats_Player_Select(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        decl String:SelectionInfo[16];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new String:buffer_out[2][8];
        ExplodeString(SelectionInfo,".",buffer_out,2,8);
        new index=StringToInt(buffer_out[0]);
        new race_num=StringToInt(buffer_out[1]);
        if(index>0 && race_num>=0)
        {
            War3Source_Stats_Player_Race(client,index,race_num);
        }
    }
    else if(action==MenuAction_Cancel)
    {
        if(selection==MenuCancel_Exit)
        {
            War3Source_Stats(client);
        }
    }
    if(action==MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public War3Source_Stats_Player_Race(client,target,race_num)
{
    if(ValidPlayer(target))
    {
        new Handle:playerInfo=CreateMenu(War3Source_Stats_PRS);
        SetMenuExitButton(playerInfo,true);
        decl String:playername[64];
        GetClientName(target,playername,sizeof(playername));
        
        new String:longbuf[1000];
        
        decl String:race_name[64];
        War3_GetRaceName(race_num,race_name,sizeof(race_name));
        new level=War3_GetLevel(target,race_num);
        new xp=War3_GetXP(target,race_num);
        
        Format(longbuf,sizeof(longbuf),"%T\n","[War3Source] {racename} info for {player}. Level: {amount} XP: {amount}",client,race_name,playername,level,xp);
        
        new SkillCount = War3_GetRaceSkillCount(race_num);
        for(new i=1;i<=SkillCount;i++){
            new String:skillname[64];
            W3GetRaceSkillName(race_num,i,skillname,sizeof(skillname));
            new skilllevel=War3_GetSkillLevelINTERNAL(target,race_num,i);
            Format(longbuf,sizeof(longbuf),"%s%T\n",longbuf,"{skillname} - Level {amount}",client,skillname,skilllevel);
        }
        
        new String:menuback[32];
        Format(menuback,sizeof(menuback),"%T","Back",client);
        
        SetSafeMenuTitle(playerInfo,"%s\n \n",longbuf);
        decl String:target_str[8];
        Format(target_str,sizeof(target_str),"%d",target);
        AddMenuItem(playerInfo,target_str,menuback);
        DisplayMenu(playerInfo,client,20);
    }
    else
    {
        War3_ChatMessage(client,"%T","The player has disconnected from the server",client);
        War3Source_Stats(client);
    }
    
}

public War3Source_Stats_PRS(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new target=StringToInt(SelectionInfo);
        if(ValidPlayer(target))
            War3Source_Stats_Player(client,target);
        else
        {
            War3_ChatMessage(client,"%T","The player you selected has left the server",client);
            War3Source_Stats(client);
        }
    }
    if(action==MenuAction_End)
    {
        CloseHandle(menu);
    }
}




War3Source_War3Top(client,top_num,cur_place=0)
{

    new Handle:topMenu=CreateMenu(War3Source_War3Top_Selected);
    SetMenuExitButton(topMenu,false);
    if(cur_place<0)    cur_place=0;
    new total_display=cur_place+10;
    if(total_display>iTopCount)
        total_display=iTopCount;
    if(total_display>top_num)
        total_display=top_num;
    if(top_num>iTopCount)
        top_num=iTopCount;
    new String:menuText[512];
    Format(menuText,sizeof(menuText),"%T\n","[War3Source] Top {amount} ({amount}-{amount})",client,top_num,cur_place+1,total_display);
    for(new x=cur_place;x<total_display;x++)
    {
        /*new Handle:hPlayer=hTop100[x]; //this is an arraylist created in sql
        new String:name[64];
        GetArrayString(hPlayer,1,name,sizeof(name));
        new level=GetArrayCell(hPlayer,2);
        new xp=GetArrayCell(hPlayer,3);*/
        Format(menuText,sizeof(menuText),"%s%T\n",menuText,"{rank} - {player} (Lvl. {amount}, {amount} XP)",client,x+1,Top100Name[x],Top100totallevel[x],Top100totalxp[x]);
        
        // PrintToServer("1");
    }
    SetSafeMenuTitle(topMenu,menuText);
    new String:data_str[18];
    new String:menuexit[32];
    new String:menunext[32];
    new String:menuprevious[32];
    Format(menuexit,sizeof(menuexit),"%T","Exit",client);
    Format(menunext,sizeof(menunext),"%T","Next",client);
    Format(menuprevious,sizeof(menuprevious),"%T","Previous",client);

    AddMenuItem(topMenu,"",menuexit);
    Format(data_str,sizeof(data_str),"n.%d.%d",top_num,cur_place);
    if(total_display<top_num) AddMenuItem(topMenu,data_str,menunext);
    Format(data_str,sizeof(data_str),"p.%d.%d",top_num,cur_place);
    if(cur_place>0) AddMenuItem(topMenu,data_str,menuprevious);
    
    // PrintToServer("2");
    DisplayMenu(topMenu,client,20);
}

public War3Source_War3Top_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        decl String:SelectionInfo[18];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new String:buffer_out[3][8];
        ExplodeString(SelectionInfo,".",buffer_out,3,8);
        new top_num=StringToInt(buffer_out[1]);
        new cur_place=StringToInt(buffer_out[2]);
        if(buffer_out[0][0]=='n')
        {
            // next
            War3Source_War3Top(client,top_num,cur_place+10);
        }
        else if(buffer_out[0][0]=='p')
        {
            War3Source_War3Top(client,top_num,cur_place-10);
        }
    }
    if(action==MenuAction_End)
    {
        CloseHandle(menu);
    }
}

