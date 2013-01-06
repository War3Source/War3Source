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
    
    if(action==MenuAction_End)
    {
        CloseHandle(menu);
    }
}
