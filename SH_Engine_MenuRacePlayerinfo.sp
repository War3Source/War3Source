

public SHONLY(){}

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


public Plugin:myinfo= 
{
	name="SH Menus",
	author="Ownz",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};

new raceinfoshowskillnumber[MAXPLAYERSCUSTOM];



public OnPluginStart()
{
	
}

public OnWar3Event(W3EVENT:event,client){
	if(SH()){
		if(event==DoShowRaceinfoMenu){
			ShowMenuRaceinfo(client);
		}
		if(event==DoShowPlayerinfoMenu){
			War3_PlayerInfoMenu(client,"")
		}
		if(event==DoShowPlayerinfoEntryWithArg){
			PlayerInfoMenuEntry(client);
		}
		if(event==DoShowParticularRaceInfo){
			War3_ShowParticularRaceInfoMenu(client,W3GetVar(RaceinfoRaceToShow));
		}
	}
}
ShowMenuRaceinfo(client){
	new Handle:hMenu=CreateMenu(War3_raceinfoSelected);
	SetMenuExitButton(hMenu,true);
	SetMenuTitle(hMenu,"[SH] Select a hero to view its information\n ");
	// Iteriate through the races and print them out
	
	decl String:rbuf[4];
	decl String:rracename[64];
	decl String:rdisp[128];
	
	for(new raceid=1;raceid<=War3_GetRacesLoaded();raceid++)
	{
		Format(rbuf,4,"%d",raceid); //DATA FOR MENU!
		War3_GetRaceName(raceid,rracename,64);
		Format(rdisp,128,"%s",rracename);
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

public War3_ShowParticularRaceInfoMenu(client,raceid){
	new Handle:hMenu=CreateMenu(War3_particularraceinfoSelected);
	SetMenuExitButton(hMenu,true);
	
	new String:racename[64];
	new String:racedesc[1000];
	
	//new String:longbuf[7000];
	SHGetHeroName(raceid,racename,64);
	SHGetHeroLongDesc(raceid,racedesc,1000);

	
	new String:selectioninfo[32];
	
	new String:title[500];
	Format(title,500,"[SH] Information for hero: %s \n \n",racename);
	Format(title,500,"%s %s\n \n",title,racedesc);
	SetMenuTitle(hMenu,title);
		
	
	Format(selectioninfo,32,"%d,raceinfo,%d",raceid,0);
	AddMenuItem(hMenu,selectioninfo,"Back to raceinfo\n \n");
	
	Format(selectioninfo,32,"%d,0,%d",raceid,0);
	AddMenuItem(hMenu,selectioninfo,"",ITEMDRAW_NOTEXT); //empty line
	
	new String:selectionDisplayBuff[64];
	Format(selectionDisplayBuff,64,"See all players with hero %s \n \n",racename) ;
	Format(selectioninfo,32,"%d,seeall,%d",raceid,0);	
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
			
			if(StrEqual(exploded[1],"skill")){
				new skillnum=StringToInt(exploded[2]);
				if(raceinfoshowskillnumber[client]==selection){
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
	War3_GetRaceName(raceid,racename,64);
	
	SetMenuTitle(hMenu,"[War3Source] People who are race: %s\n \n",racename);
	
	decl String:playername[64];
	decl String:war3playerbuf[4];
	
	for(new x=1;x<=MaxClients;x++)
	{
		if(ValidPlayer(x)&&War3_GetRace(x)==raceid){
			
			Format(war3playerbuf,4,"%d",x);  //target index
			GetClientName(x,playername,63);
			decl String:menuitemstr[100];
			decl String:teamname[10];
			GetShortTeamName( GetClientTeam(x),teamname,10);
			Format(menuitemstr,100,"%s (Level %d) [%s]",playername,War3_GetLevel(x,raceid),teamname);
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
			War3_ChatMessage(client,"The player you selected has left the server.");
	
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}









PlayerInfoMenuEntry(client){
	new String:arg[32];
	new Handle:dataarray=W3GetVar(hPlayerInfoArgStr); //should always be created, upper plugin closes handle
	GetArrayString(dataarray,0,arg,32);
	War3_PlayerInfoMenu(client,arg);
}


War3_PlayerInfoMenu(client,String:arg[]){
	//PrintToChatAll("%s",arg);
	if(strlen(arg)>10){   //has argument (space after)
		new String:arg2[32];
		Format(arg2,32,"%s",arg[11]);
		//PrintToChatAll("%s",arg2);
		
		new target=0;
		new found=0;
		new String:name[32];
		for(new i=1;i<=MaxClients;i++){
			if(ValidPlayer(i)){
				GetClientName(i,name,32);
				if(StrContains(name,arg2,false)>-1){
					target=i;
					found++;
				}
			}
		}
		if(target==0){
			War3_ChatMessage(client,"playerinfo <optional name>: No target found");
		}
		else if(found>1){
			 War3_ChatMessage(client,"playerinfo <optional name>: More than one target found");
		}
		else {
		    War3_playertargetMenu(client,target);
		}
	}
	else
	{
		
		new Handle:hMenu=CreateMenu(War3_playerinfoSelected1);
		SetMenuExitButton(hMenu,true);
		SetMenuTitle(hMenu,"[War3Source] Select a player to view its information\n ");
		// Iteriate through the players and print them out
		decl String:playername[32];
		decl String:war3playerbuf[4];
		
		decl String:menuitem[100] ;
		for(new x=1;x<=MaxClients;x++)
		{
			if(ValidPlayer(x)){
				
				Format(war3playerbuf,4,"%d",x);  //target index
				GetClientName(x,playername,32);
				
				Format(menuitem,100,"%s  (Lvl %d)",playername,SHGetLevel(x));
				
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
			War3_ChatMessage(client,"The player you selected has left the server.");
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}


War3_playertargetMenu(client,target) {
	new Handle:hMenu=CreateMenu(War3_playertargetMenuSelected);
	SetMenuExitButton(hMenu,true);
	
	new String:targetname[32];
	GetClientName(target,targetname,32);
	
	new String:racename[64];

	
	new String:title[3000];
	Format(title,3000,"[War3Source] Information for %s\n \n",targetname);
	Format(title,3000,"%sLevel: %d\n \nHeroes:\n",title,SHGetLevel(target));
	
	
	for(new i=1;i<=War3_GetRacesLoaded();i++){
		if(SHHasHero(target,i)){
			SHGetHeroName(i,racename,64);
			Format(title,3000,"%s%s\n",title,racename);
		}
	}
	
	new Float:armorred=(1.0-W3GetPhysicalArmorMulti(client))*100;
	Format(title,3000,"%s\n \nPhysical Armor: %.1f (%s%.1f%%)",title,W3GetBuffSumFloat(client,fArmorPhysical),armorred<0.0?"+":"-",armorred<0.0?armorred*-1.0:armorred);
	
	armorred=(1.0-W3GetMagicArmorMulti(client))*100;
	Format(title,3000,"%s\nMagic Armor: %.1f (%s%.1f%%)",title,W3GetBuffSumFloat(client,fArmorMagic),armorred<0.0?"+":"-",armorred<0.0?armorred*-1.0:armorred);
	
	Format(title,3000,"%s\n \n",title);
	
	
	SetMenuTitle(hMenu,"%s",title);
	// Iteriate through the races and print them out
	
	
	
	
	new String:buf[3];
	
	IntToString(target,buf,3);
	AddMenuItem(hMenu,buf,"Refresh");
	
	//new String:selectionDisplayBuff[64];
	////Format(selectionDisplayBuff,64,"See %s Race information",racename)  ;
	//AddMenuItem(hMenu,buf,selectionDisplayBuff); 
	
	//Format(selectionDisplayBuff,64,"See all players with race %s",racename) ;
	//AddMenuItem(hMenu,buf,selectionDisplayBuff); 
	
	DisplayMenu(hMenu,client,MENU_TIME_FOREVER);

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
			War3_ChatMessage(client,"The player you selected has left the server.");
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
		}
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}




