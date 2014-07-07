#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Admin Menu",
    author = "War3Source Team",
    description = "Admin menu for War3Source"
};

public OnPluginStart()
{
    RegConsoleCmd("war3admin",War3Source_Admin,"Brings up the War3Source admin panel.");

    RegConsoleCmd("say war3admin",War3Source_Admin,"Brings up the War3Source admin panel.");
    RegConsoleCmd("say_team war3admin",War3Source_Admin,"Brings up the War3Source admin panel.");
}


public Action:War3Source_Admin(client,args)
{
    if(ValidPlayer(client) && HasSMAccess(client, ADMFLAG_ROOT))
    {
        new Handle:adminMenu=CreateMenu(War3Source_Admin_Selected);
        SetMenuExitButton(adminMenu,true);
        SetSafeMenuTitle(adminMenu,"%T","[War3Source] Select a player to administrate",client);
        
        decl String:playername[64];
        decl String:war3playerbuf[4];

        for(new x=1;x<=MaxClients;x++)
        {
            if(ValidPlayer(x)){
                
                Format(war3playerbuf,sizeof(war3playerbuf),"%d",x);
                GetClientName(x,playername,sizeof(playername));
                AddMenuItem(adminMenu,war3playerbuf,playername);
            }
        }
        DisplayMenu(adminMenu,client,20);
    }
    
    return Plugin_Handled;
}

public War3Source_Admin_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new target=StringToInt(SelectionInfo);
        if(ValidPlayer(target))
            War3Source_Admin_Player(client,target);
        else
            War3_ChatMessage(client,"%T","The player you selected has left the server",client);
    }
    if(action==MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public War3Source_Admin_Player(client,target)
{
    new Handle:adminMenu_Player=CreateMenu(War3Source_Admin_Player_Select);
    SetMenuExitButton(adminMenu_Player,true);
    decl String:playername[64];
    GetClientName(target,playername,sizeof(playername));
    
    SetSafeMenuTitle(adminMenu_Player,"%T","[War3Source] Administration options for {player}",client,playername);
    
    decl String:buf[4];
    Format(buf,sizeof(buf),"%d",target);
    new race=War3_GetRace(target);
    
    new String:details[64];
    new String:shopitem[64];
    new String:setrace[64];
    new String:resetskills[64];
    new String:managxp[64];
    new String:managlevel[64];
    new String:managgold[64];
    new String:managlvlbank[64];
    
    Format(details,sizeof(details),"%T","View detailed information",client);
    Format(shopitem,sizeof(shopitem),"%T","Give shop item",client);
    Format(setrace,sizeof(setrace),"%T","Set race",client);
    Format(resetskills,sizeof(resetskills),"%T","Reset skills",client);
    Format(managxp,sizeof(managxp),"%T","Increase/Decrease XP",client);
    Format(managlevel,sizeof(managlevel),"%T","Increase/Decrease Level",client);
    Format(managgold,sizeof(managgold),"%T","Increase/Decrease Gold",client);
    Format(managlvlbank,sizeof(managlvlbank),"%T","Levelbank Managing",client);
        
    AddMenuItem(adminMenu_Player,buf,details);
    AddMenuItem(adminMenu_Player,buf,shopitem);
    AddMenuItem(adminMenu_Player,buf,setrace);
    if(race>0)
    {
        AddMenuItem(adminMenu_Player,buf,resetskills);
        AddMenuItem(adminMenu_Player,buf,managxp);
        AddMenuItem(adminMenu_Player,buf,managlevel);
        AddMenuItem(adminMenu_Player,buf,managgold);
    }
    AddMenuItem(adminMenu_Player,buf,managlvlbank);
    DisplayMenu(adminMenu_Player,client,20);
    
}

public War3Source_Admin_Player_Select(Handle:menu,MenuAction:action,client,selection)
{
    // This is gonna be fun... NOT.
    if(action==MenuAction_Select)
    {
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new target=StringToInt(SelectionInfo);
        

        new String:adminname[64];
        GetClientName(client,adminname,sizeof(adminname));
        if(ValidPlayer(target))
        {
            new String:targetname[64];
            GetClientName(target,targetname,sizeof(targetname));
            // What do they want to do with the player?
            switch(selection)
            {
                case 0:
                {
                    // Player info selected
                    War3Source_Admin_PlayerInfo(client,target);
                }
                case 1:
                {
                    // Give shop item
                    War3Source_Admin_GiveShopItem(client,target);
                }
                case 2:
                {
                    // Set race
                    War3Source_Admin_SetRace(client,target);
                }
                case 3:
                {
                    // Reset skills
                    new race=War3_GetRace(target);
                    W3ClearSkillLevels(target,race);
                    W3DoLevelCheck(target);
                    
                    War3_ChatMessage(target,"%T","Admin {admin} reset your skills",target,adminname);
                    War3_ChatMessage(client,"%T","You reset player {player} skills",client,targetname);
                }
                case 4:
                {
                    // Increase/Decrease XP
                    War3Source_Admin_XP(client,target);
                }
                case 5:
                {
                    // Increase/Decrease Level
                    War3Source_Admin_Level(client,target);
                }
                case 6:
                {
                    // Increase/Decrease Gold
                    War3Source_Admin_Gold(client,target);
                }
                case 7:
                {
                    // Increase/Decrease Levelbank
                    War3Source_Admin_Lvlbank(client,target);
                }
            }
            if(selection==3)
                War3Source_Admin_Player(client,target);
        }
        else
            War3_ChatMessage(client,"%T","The player you selected has left the server",client);
    }
    if(action==MenuAction_End)
    {
        CloseHandle(menu);
    }
    
}

public War3Source_Admin_PlayerInfo(client,target)
{
    
    if(ValidPlayer(target,false))
    {
        SetTrans(client);
        new Handle:playerInfo=CreateMenu(War3Source_Admin_PI_Select);
        SetMenuExitButton(playerInfo,true);
        
        decl String:playername[64];
        GetClientName(target,playername,sizeof(playername));
        new race=War3_GetRace(target);
        
        decl String:race_name[64];
        War3_GetRaceName(race,race_name,sizeof(race_name));
        new gold=War3_GetGold(target);
        new xp=War3_GetXP(target,race);
        new level=War3_GetLevel(target,race);
        new lvlbank=W3GetLevelBank(target);
        SetSafeMenuTitle(playerInfo,"%T","[War3Source] Info for {player}. Race: {racename} Gold: {amount} XP: {amount} Level: {amount} Levelbank: {amount}",client,playername,race_name,gold,xp,level,lvlbank);
        decl String:buf[4];
        Format(buf,sizeof(buf),"%d",target);
        
        new String:backmenu[64];
        
        Format(backmenu,sizeof(backmenu),"%T","Back to options",client);
        
        AddMenuItem(playerInfo,buf,backmenu);
        DisplayMenu(playerInfo,client,20);
    }
    else
        War3_ChatMessage(client,"%T","The player has disconnected from the server",client);
        
}

public War3Source_Admin_PI_Select(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new target=StringToInt(SelectionInfo);
        if(ValidPlayer(target))
            War3Source_Admin_Player(client,target);
        else
            War3_ChatMessage(client,"%T","The player has disconnected from the server",client);
    }
    if(action==MenuAction_End)
    {
        CloseHandle(menu);
    }
    
}

public War3Source_Admin_XP(client,target)
{
    if(ValidPlayer(target,false))
    {
        new Handle:menu=CreateMenu(War3Source_Admin_XP_Select);
        SetMenuExitButton(menu,true);
        
        decl String:playername[64];
        GetClientName(target,playername,sizeof(playername));
        
        SetSafeMenuTitle(menu,"%T","[War3Source] Select an option for {player}",client,playername);
        decl String:buf[4];
        Format(buf,sizeof(buf),"%d",target);
        
        new String:give100xp[64];
        new String:give1000xp[64];
        new String:give10000xp[64];
        new String:remove100xp[64];
        new String:remove1000xp[64];
        new String:remove10000xp[64];
        
        Format(give100xp,sizeof(give100xp),"%T","Give 100 XP",client);
        Format(give1000xp,sizeof(give1000xp),"%T","Give 1000 XP",client);
        Format(give10000xp,sizeof(give10000xp),"%T","Give 10000 XP",client);
        Format(remove100xp,sizeof(remove100xp),"%T","Remove 100 XP",client);
        Format(remove1000xp,sizeof(remove1000xp),"%T","Remove 1000 XP",client);
        Format(remove10000xp,sizeof(remove10000xp),"%T","Remove 10000 XP",client);
        
        AddMenuItem(menu,buf,give100xp);
        AddMenuItem(menu,buf,give1000xp);
        AddMenuItem(menu,buf,give10000xp);
        AddMenuItem(menu,buf,remove100xp);
        AddMenuItem(menu,buf,remove1000xp);
        AddMenuItem(menu,buf,remove10000xp);
        DisplayMenu(menu,client,20);
    }
    else
        War3_ChatMessage(client,"The player has disconnected from the server");

}

public War3Source_Admin_XP_Select(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new target=StringToInt(SelectionInfo);

        if(ValidPlayer(target,false))
        {
            new race=War3_GetRace(target);
            decl String:adminname[64];
            GetClientName(client,adminname,sizeof(adminname));
            decl String:targetname[64];
            GetClientName(target,targetname,sizeof(targetname));
            if(selection<3) // Give XP
            {
                new xpadd;
                switch(selection)
                {
                    case 0:
                        xpadd=100;
                    case 1:
                        xpadd=1000;
                    case 2:
                        xpadd=10000;
                }
                new newxp=War3_GetXP(target,race)+xpadd;
                War3_SetXP(target,race,newxp);
                War3_ChatMessage(client,"%T","You gave {player} {amount} XP",client,targetname,xpadd);
                War3_ChatMessage(target,"%T","You recieved {amount} XP from admin {player}",target,xpadd,adminname);
                W3DoLevelCheck(target);
                War3Source_Admin_XP(client,target);
            }
            else
            {
                new xprem;
                switch(selection)
                {
                    case 3:
                        xprem=100;
                    case 4:
                        xprem=1000;
                    case 5:
                        xprem=10000;
                }
                new newxp=War3_GetXP(target,race)-xprem;
                if(newxp<0)
                    newxp=0;
                War3_SetXP(target,race,newxp);
                War3_ChatMessage(client,"%T","You removed {amount} XP from player {player}",client,xprem,targetname);
                War3_ChatMessage(target,"%T","&Admin {player} removed {amount} XP from you",target,adminname,xprem);
                War3Source_Admin_XP(client,target);
            }
        }
        else
            War3_ChatMessage(client,"%T","The player has disconnected from the server",client);
    }
    if(action==MenuAction_End)
    {
        CloseHandle(menu);
    }
    
}

public War3Source_Admin_GiveShopItem(client,target)
{
    if(ValidPlayer(target,false))
    {
        SetTrans(client);
        new Handle:menu=CreateMenu(War3Source_Admin_GSI_Select);
        SetMenuExitButton(menu,true);
        decl String:playername[64];
        GetClientName(target,playername,sizeof(playername));
        SetSafeMenuTitle(menu,"%T","[War3Source] Select an item to give to {player}",client,playername);
        decl String:itemname[64];
        decl String:buf[4];
        Format(buf,sizeof(buf),"%d",target);
        new ItemsLoaded = W3GetItemsLoaded();
        for(new x=1;x<=ItemsLoaded;x++)
        {
            W3GetItemName(x,itemname,sizeof(itemname));
            AddMenuItem(menu,buf,itemname);
        }
        DisplayMenu(menu,client,20);
    }
    else
        War3_ChatMessage(client,"%T","The player has disconnected from the server",client);

}

public War3Source_Admin_GSI_Select(Handle:menu,MenuAction:action,client,selection)
{
    
    if(action==MenuAction_Select)
    {
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new target=StringToInt(SelectionInfo);
        if(ValidPlayer(target))
        {
            new item=selection+1; //hax
            if(!War3_GetOwnsItem(target,item)) 
            {
                W3SetVar(TheItemBoughtOrLost,item);
                W3CreateEvent(DoForwardClientBoughtItem,target);
                
                decl String:itemname[64];
                W3GetItemName(item,itemname,sizeof(itemname));
                
                decl String:adminname[64];
                GetClientName(client,adminname,sizeof(adminname));
                
                decl String:targetname[64];
                GetClientName(target,targetname,sizeof(targetname));
                
                War3_ChatMessage(client,"%T","You gave {player} a {itemname}",client,targetname,itemname);
                War3_ChatMessage(target,"%T","You recieved a {itemname} from admin {player}",target,itemname,adminname);
                War3Source_Admin_Player(client,target);
            }
            else
                War3_ChatMessage(client,"%T","The player already owns this item",client);
        }
        else
            War3_ChatMessage(client,"%T","The player has disconnected from the server",client);
    }
    if(action==MenuAction_End)
    {
        CloseHandle(menu);
    }
    
}

new AdminMenuSetRaceTarget[MAXPLAYERSCUSTOM];
public War3Source_Admin_SetRace(client,target)
{
    if(ValidPlayer(target,false))
    {
        AdminMenuSetRaceTarget[client]=target;
        SetTrans(client);
        new Handle:menu=CreateMenu(War3Source_Admin_SetRace_Select);
        SetMenuExitButton(menu,true);
        decl String:playername[64];

        GetClientName(target,playername,sizeof(playername));
        SetSafeMenuTitle(menu,"%T","[War3Source] Select a race for {player}",client,playername);
        
        decl String:racefullname[64];
        decl String:raceshortname[32];
        
        
        new racelist[MAXRACES];
        new racecountreturned=W3GetRaceList(racelist); 
        AddMenuItem(menu,"norace","No Race");
        for(new i=0;i<racecountreturned;i++) //notice this starts at zero!
        {
            new    raceid=racelist[i];
            War3_GetRaceName(raceid,racefullname,sizeof(racefullname));
            War3_GetRaceShortname(raceid,raceshortname,sizeof(raceshortname));
            AddMenuItem(menu,raceshortname,racefullname);
        }
        DisplayMenu(menu,client,20);
    }
    else
        War3_ChatMessage(client,"%T","The player has disconnected from the server",client);

}

public War3Source_Admin_SetRace_Select(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        decl String:SelectionInfo[32];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new target=AdminMenuSetRaceTarget[client];

        //selection++; // hacky, should work tho?
        //DP("%s",SelectionInfo);
        new race=War3_GetRaceIDByShortname(SelectionInfo);
        if(ValidPlayer(target))
        {
        
            W3SetPlayerProp(target,RaceChosenTime,GetGameTime());
            W3SetPlayerProp(target,RaceSetByAdmin,true);
            
            War3_SetRace(target,race);
            
            decl String:racename[64];
            War3_GetRaceName(race,racename,sizeof(racename));
            decl String:adminname[64];
            GetClientName(client,adminname,sizeof(adminname));
            decl String:targetname[64];
            GetClientName(target,targetname,sizeof(targetname));
            War3_ChatMessage(client,"%T","You set player {player} to race {racename}",client,targetname,racename);
            War3_ChatMessage(target,"%T","Admin {player} set you to race {racename}",target,adminname,racename);
        }
        else
            War3_ChatMessage(client,"%T","The player has disconnected from the server",client);
    }
    if(action==MenuAction_End)
    {
        CloseHandle(menu);
    }
    
}

public War3Source_Admin_Level(client,target)
{
    if(ValidPlayer(target))
    {
        new Handle:menu=CreateMenu(War3Source_Admin_Level_Select);
        SetMenuExitButton(menu,true);
        decl String:playername[64];
        GetClientName(target,playername,sizeof(playername));
        SetSafeMenuTitle(menu,"%T","&[War3Source] Select an option for {player}",client,playername);
        decl String:buf[4];
        Format(buf,sizeof(buf),"%d",target);
        
        new String:givelevel[64];
        new String:removelevel[64];
        
        Format(givelevel,sizeof(givelevel),"%T","Give a level",client);
        Format(removelevel,sizeof(removelevel),"%T","Remove a level",client);
        
        AddMenuItem(menu,buf,givelevel);
        AddMenuItem(menu,buf,removelevel);
        DisplayMenu(menu,client,20);
    }
    else
        War3_ChatMessage(client,"%T","The player has disconnected from the server",client);

}

public War3Source_Admin_Level_Select(Handle:menu,MenuAction:action,client,selection)
{
    
    if(action==MenuAction_Select)
    {
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new target=StringToInt(SelectionInfo);
        if(ValidPlayer(target,false))
        {
            decl String:adminname[64];
            GetClientName(client,adminname,sizeof(adminname));
            decl String:targetname[64];
            GetClientName(target,targetname,sizeof(targetname));
            new race=War3_GetRace(target);
            if(selection==0)
            {
                // Give a level
                new newlevel=War3_GetLevel(target,race)+1;
                if(newlevel>W3GetRaceMaxLevel(race))
                    War3_ChatMessage(client,"%T","Player {player} is already at the max level",client,targetname);
                else
                {
                    War3_SetLevel(target,race,newlevel);
                    W3DoLevelCheck(client);
                    War3_ChatMessage(client,"%T","You gave player {player} a level",client,targetname);
                    War3_ChatMessage(target,"%T","&Admin {player} gave you a level",target,adminname);
                }
            }
            else
            {
                // Remove a level
                new newlevel=War3_GetLevel(target,race)-1;
                if(newlevel<0)
                    War3_ChatMessage(client,"%T","Player {player} is already level 0",client,targetname);
                else
                {
                    War3_SetLevel(target,race,newlevel);
                    W3ClearSkillLevels(target,race);
                    
                    War3_ChatMessage(client,"%T","You removed a level from player {player}",client,targetname);
                    War3_ChatMessage(target,"%T","&Admin {player} removed a level from you, re-pick your skills",target,adminname);
                    
                    W3DoLevelCheck(target);
                }
            }
            War3Source_Admin_Level(client,target);
        }
        else
            War3_ChatMessage(client,"%T","The player has disconnected from the server",client);
    }
    if(action==MenuAction_End)
    {
        CloseHandle(menu);
    }
    
}

public War3Source_Admin_Gold(client,target)
{
    
    if(ValidPlayer(target,false))
    {
        new Handle:menu=CreateMenu(War3Source_Admin_Gold_Select);
        SetMenuExitButton(menu,true);
        decl String:playername[64];
        GetClientName(target,playername,sizeof(playername));
        SetSafeMenuTitle(menu,"%T","&&[War3Source] Select an option for {player}",client,playername);
        decl String:buf[4];
        Format(buf,sizeof(buf),"%d",target);
        
        new String:give1gold[64];
        new String:give5gold[64];
        new String:give10gold[64];
        new String:remove1gold[64];
        new String:remove5gold[64];
        new String:remove10gold[64];
        
        Format(give1gold,sizeof(give1gold),"%T","Give 1 gold",client);
        Format(give5gold,sizeof(give5gold),"%T","Give 5 gold",client);
        Format(give10gold,sizeof(give10gold),"%T","Give 10 gold",client);
        Format(remove1gold,sizeof(remove1gold),"%T","Remove 1 gold",client);
        Format(remove5gold,sizeof(remove5gold),"%T","Remove 5 gold",client);
        Format(remove10gold,sizeof(remove10gold),"%T","Remove 10 gold",client);
        
        AddMenuItem(menu,buf,give1gold);
        AddMenuItem(menu,buf,give5gold);
        AddMenuItem(menu,buf,give10gold);
        AddMenuItem(menu,buf,remove1gold);
        AddMenuItem(menu,buf,remove5gold);
        AddMenuItem(menu,buf,remove10gold);
        DisplayMenu(menu,client,20);
    }
    else
        War3_ChatMessage(client,"%T","The player has disconnected from the server",client);

}

public War3Source_Admin_Gold_Select(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new target=StringToInt(SelectionInfo);
        if(ValidPlayer(target,false))
        {
            decl String:adminname[64];
            GetClientName(client,adminname,sizeof(adminname));
            decl String:targetname[64];
            GetClientName(target,targetname,sizeof(targetname));
            if(selection<3) // Give gold
            {
                new credadd;
                switch(selection)
                {
                    case 0:
                        credadd=1;
                    case 1:
                        credadd=5;
                    case 2:
                        credadd=10;
                }
                new newcred=War3_GetGold(target)+credadd;
                new maxgold=War3_GetMaxCurrency();
                if(newcred>maxgold)
                    newcred=maxgold;
                War3_SetGold(target,newcred);
                War3_ChatMessage(client,"%T","You gave {player} {amount} gold(s)",client,targetname,credadd);
                War3_ChatMessage(target,"%T","You recieved {amount} gold(s) from admin {player}",target,credadd,adminname);
                War3Source_Admin_Gold(client,target);
            }
            else
            {
                new credrem;
                switch(selection)
                {
                    case 3:
                        credrem=1;
                    case 4:
                        credrem=5;
                    case 5:
                        credrem=10;
                }
                new newcred=War3_GetGold(target)-credrem;
                if(newcred<0)
                    newcred=0;
                War3_SetGold(target,newcred);
                War3_ChatMessage(client,"%T","You removed {amount} gold(s) from player {player}",client,credrem,targetname);
                War3_ChatMessage(target,"%T","Admin {player} removed {amount} gold(s) from you",target,adminname,credrem);
                War3Source_Admin_Gold(client,target);
            }
        }
        else
            War3_ChatMessage(client,"%T","The player has disconnected from the server",client);
    }
    if(action==MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public War3Source_Admin_Lvlbank(client,target)
{
    
    if(ValidPlayer(target,false))
    {
        new Handle:menu=CreateMenu(War3Source_Admin_Lvlbank_Select);
        SetMenuExitButton(menu,true);
        decl String:playername[64];
        GetClientName(target,playername,sizeof(playername));
        SetSafeMenuTitle(menu,"%T","&&&[War3Source] Select an option for {player}",client,playername);
        decl String:buf[4];
        Format(buf,sizeof(buf),"%d",target);
        
        new String:give1lvlb[64];
        new String:give5lvlb[64];
        new String:give10lvlb[64];
        new String:remove1lvlb[64];
        new String:remove5lvlb[64];
        new String:remove10lvlb[64];
        
        Format(give1lvlb,sizeof(give1lvlb),"%T","Give 1 level in levelbank",client);
        Format(give5lvlb,sizeof(give5lvlb),"%T","Give 5 levels in levelbank",client);
        Format(give10lvlb,sizeof(give10lvlb),"%T","Give 10 levels in levelbank",client);
        Format(remove1lvlb,sizeof(remove1lvlb),"%T","Remove 1 level from levelbank",client);
        Format(remove5lvlb,sizeof(remove5lvlb),"%T","Remove 5 levels from levelbank",client);
        Format(remove10lvlb,sizeof(remove10lvlb),"%T","Remove 10 levels from levelbank",client);
        
        AddMenuItem(menu,buf,give1lvlb);
        AddMenuItem(menu,buf,give5lvlb);
        AddMenuItem(menu,buf,give10lvlb);
        AddMenuItem(menu,buf,remove1lvlb);
        AddMenuItem(menu,buf,remove5lvlb);
        AddMenuItem(menu,buf,remove10lvlb);
        DisplayMenu(menu,client,20);
    }
    else
        War3_ChatMessage(client,"%T","The player has disconnected from the server",client);

}

public War3Source_Admin_Lvlbank_Select(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        decl String:SelectionInfo[4];
        decl String:SelectionDispText[256];
        new SelectionStyle;
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
        new target=StringToInt(SelectionInfo);
        if(ValidPlayer(target,false))
        {
            decl String:adminname[64];
            GetClientName(client,adminname,sizeof(adminname));
            decl String:targetname[64];
            GetClientName(target,targetname,sizeof(targetname));
            if(selection<3)
            {
                new lvlbadd;
                switch(selection)
                {
                    case 0:
                        lvlbadd=1;
                    case 1:
                        lvlbadd=5;
                    case 2:
                        lvlbadd=10;
                }
                new newlvlb=W3GetLevelBank(target)+lvlbadd;
                W3SetLevelBank(target,newlvlb);
                War3_ChatMessage(client,"%T","You gave {player} {amount} level(s) in levelbank",client,targetname,lvlbadd);
                War3_ChatMessage(target,"%T","You recieved {amount} level(s) in levelbank from admin {player}",target,lvlbadd,adminname);
                War3Source_Admin_Lvlbank(client,target);
            }
            else
            {
                new lvlbrem;
                switch(selection)
                {
                    case 3:
                        lvlbrem=1;
                    case 4:
                        lvlbrem=5;
                    case 5:
                        lvlbrem=10;
                }
                new newlvlb=W3GetLevelBank(target)-lvlbrem;
                if(newlvlb<0)
                    newlvlb=0;
                W3SetLevelBank(target,newlvlb);
                War3_ChatMessage(client,"%T","You removed {amount} level(s) from levelbank of {player}",client,lvlbrem,targetname);
                War3_ChatMessage(target,"%T","Admin {player} removed {amount} level(s) from your levelbank",target,adminname,lvlbrem);
                War3Source_Admin_Lvlbank(client,target);
            }
        }
        else
            War3_ChatMessage(client,"%T","The player has disconnected from the server",client);
    }
    if(action==MenuAction_End)
    {
        CloseHandle(menu);
    }
}
