/*
File: menus.inc
Description: This file handles the menu aspects of the plugin.
Author(s): Anthony Iacono  
*/

public War3Source_IntroMenu(client)
{
	new Handle:introMenu=CreateMenu(War3Source_IntroMenu_Select);
	new String:welcome[512];
	Format(welcome,sizeof(welcome),"%T\n \n","WelcomeToServer",client,VERSION_NUM,AUTHORS);
	SetMenuTitle(introMenu,welcome);
	SetMenuExitButton(introMenu,false);
	new String:letsplay[64];
	Format(letsplay,sizeof(letsplay),"%T","Lets Play!",client);
	AddMenuItem(introMenu,"exit",letsplay);
	DisplayMenu(introMenu,client,MENU_TIME_FOREVER);
}

public War3Source_IntroMenu_Select(Handle:menu,MenuAction:action,client,selection)
{
	if(W3()&&ValidPlayer(client)&&War3_GetRace(client)==0)
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
	//	CloseHandle(menu);
	//	PrintToServer("close intro menu");// by %d selected %d",client,selection);
	//}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}
