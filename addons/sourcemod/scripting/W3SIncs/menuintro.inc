/*
File: menus.inc
Description: This file handles the menu aspects of the plugin.
Author(s): Anthony Iacono  
*/

public War3Source_IntroMenu(client)
{
    new Handle:introMenu=CreateMenu(War3Source_IntroMenu_Select);
    
    new String:clanname[32];
    GetConVarString(introclannamecvar,clanname,sizeof(clanname));
    //if(StrContains(clanname,"war3_intro")>-1){
    //    Format(clanname,sizeof(clanname),"war3_introclanname");
    //}
    new String:welcome[512];
    
    if (StrEqual(BRANCH, "{branch}"))
    {
        Format(welcome, sizeof(welcome), "%T\n \n", "WelcomeToServer", client, clanname, "Developer Version", "-");
    }
    else if (StrEqual(BRANCH, "master"))
    {
        Format(welcome, sizeof(welcome), "%T\n \n", "WelcomeToServerMaster", client, clanname, BUILD_NUMBER);
    }
    SetMenuTitle(introMenu,welcome);
    SetMenuExitButton(introMenu,false);
    new String:buf[64];
    Format(buf,sizeof(buf),"%T","ForHelpIntro",client);
    AddMenuItem(introMenu,"exit",buf);
    
    GetConVarString(clanurl,buf,sizeof(buf));
    if(strlen(buf)){
        AddMenuItem(introMenu,"exit",buf);
    }
    Format(buf,sizeof(buf),"www.war3source.com");
    AddMenuItem(introMenu,"exit",buf);
    DisplayMenu(introMenu,client,MENU_TIME_FOREVER);
}

public War3Source_IntroMenu_Select(Handle:menu,MenuAction:action,client,selection)
{
    if(ValidPlayer(client)&&War3_GetRace(client)==0)
    {
        if(W3IsPlayerXPLoaded(client)){
            W3CreateEvent(DoShowChangeRaceMenu,client);
        }
        else{
            War3_ChatMessage(client,"%T","Please be patient while we load your XP",client);
        }
    }
    //PrintToServer("close intro menu select!!!!");
    //if(menu!=INVALID_HANDLE)
    //{
    //    CloseHandle(menu);
    //    PrintToServer("close intro menu");// by %d selected %d",client,selection);
    //}
    if(action==MenuAction_End)
    {
        CloseHandle(menu);
    }
}
