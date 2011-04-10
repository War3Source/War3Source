



#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/SuperHero_Interface"

public Plugin:myinfo= 
{
	name="War3Source war3menu",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};


public OnPluginStart()
{
	LoadTranslations("common.superh");
}

public OnWar3Event(W3EVENT:event,client){
	if(event==DoShowSHMenu){
		ShowSHMenu(client)
	}
}

ShowSHMenu(client){	
	new Handle:war3Menu=CreateMenu(SuperHero_SHMenu_Select);
	SetMenuTitle(war3Menu,"%T","[War3Source] Choose a task",client);
	new limit=9;
	new String:transbuf[32];
	new String:menustr[100];
	new String:numstr[4];
	//for(new i=0;i<=limit;i++){
	
	
	Format(menustr,sizeof(menustr),"Choose Heroes - type showmenu");
	
	Format(numstr,sizeof(numstr),"0");
	
	AddMenuItem(war3Menu,numstr,menustr);
	
	Format(menustr,sizeof(menustr),"View/edit your heroes - type myheroes");
	
	Format(numstr,sizeof(numstr),"1");
	
	AddMenuItem(war3Menu,numstr,menustr);
	
	Format(menustr,sizeof(menustr),"Drop all current heroes - type clearpowers");
	
	Format(numstr,sizeof(numstr),"2");
	
	AddMenuItem(war3Menu,numstr,menustr); 
	
	Format(menustr,sizeof(menustr),"See other player's info - type playerinfo");
	
	Format(numstr,sizeof(numstr),"3");
	
	AddMenuItem(war3Menu,numstr,menustr); 
	
	Format(menustr,sizeof(menustr),"Type !buyxp5/10/15/20 (2.5k/5k/7.5k/10k) to buy some XP with CS money!");
	
	Format(numstr,sizeof(numstr),"4");	
	
	AddMenuItem(war3Menu,numstr,menustr); 
	////so on
	//FOR NOW
	
	
	//}

	DisplayMenu(war3Menu,client,MENU_TIME_FOREVER);
}

public SuperHero_SHMenu_Select(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		//decl String:SelectionInfo[4];
		//decl String:SelectionDispText[256];
		//new SelectionStyle;
	//	GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
		if(ValidPlayer(client))
		{
			switch(selection)
			{
				case 0: // war3help
				{
					W3CreateEvent(DoShowMenuMyInfo,client);
				}
				case 1: // changerace
				{
					W3CreateEvent(SHMyHeroes,client);
				}
				case 2: // skillsinfo
				{
					W3CreateEvent(SHClearPowers,client);
				}
				case 3: // raceinfo
				{
					W3CreateEvent(DoShowPlayerinfoMenu,client);
				}
				case 4: // raceinfo
				{
					W3CreateEvent(DoShowMenuMyInfo,client);
				}
			}
		}
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}

