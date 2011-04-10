

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo= 
{
	name="SH chooserace",
	author="Ownz",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};



//new WantsRace[MAXPLAYERSCUSTOM];

public APLRes:AskPluginLoad2Custom(Handle:myself,bool:late,String:error[],err_max)
{
	GlobalOptionalNatives();
	if(!InitNativesForwards())
	{
		LogError("[War3Source] There was a failure in creating the native / forwards based functions, definately halting.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	
}
bool:InitNativesForwards(){ 
	CreateNative("SHTryToGiveClientHero",NSHTryToGiveClientHero);
	return true;
}
	
public	NSHTryToGiveClientHero(Handle:plugin,numParams){
	new client=GetNativeCell(1);
	new race_selected=GetNativeCell(2);
	new bool:allowshowchangeraceagain=bool:GetNativeCell(3);
	new maxheroes=SHGetHeroesClientCanHave(client);
	
	new String:heroname[32];
	SHGetHeroName(race_selected,heroname,sizeof(heroname));
	new bool:allowselect=true;
	
	if(allowselect&&SHHasHeroesNum(client)>=maxheroes){
		SH_ChatMessage(client,"You can only have %d heroes",maxheroes);
		allowselect=false;
	}
	
	else if(SHHasHero(client,race_selected)){
		SH_ChatMessage(client,"You already have %s",heroname);
		allowselect=false;
	}
	else if(W3GetRaceMinLevelRequired(race_selected)>SHGetLevel(client)){
		SH_ChatMessage(client,"This Hero requires level %d",W3GetRaceMinLevelRequired(race_selected));
		allowselect=false;
	}
	
	
	
	if(allowselect&&SHGetHeroHasPowerBind(race_selected)){
		
		new bool:foundempty=false;
		for(new i=0;i<3;i++){
			if(SHGetPowerBind(client,i)==0){
				SHSetPowerBind(client,i,race_selected);
				foundempty=true;
				
				SH_ChatMessage(client,"%s has power bind, bounded to +power%d ",heroname,i+1);
				break;
			}
		}
		if(foundempty==false){
			SH_ChatMessage(client,"You can only have max 3 heroes that have power binds");
			allowselect=false;
		}
	}
	
	if(allowselect){
		SHSetHasHero(client,race_selected,true);
		
	}
	if(allowshowchangeraceagain&&SHHasHeroesNum(client)<maxheroes){
		InternalSHChangeRaceMenu(client);
	}
}











public OnWar3Event(W3EVENT:event,client){
	if(SH()){
	
		if(event==SHSelectHeroesMenu){
			InternalSHChangeRaceMenu(client);
		}
		if(event==SHClearPowers){
			InternalClearPowers(client);
		}
		if(event==SHMyHeroes){
			InternalShowMyHeroes(client);
		}
	}
}
InternalSHChangeRaceMenu(client){
	new Handle:crMenu=CreateMenu(War3Source_CRMenu_Selected);
	SetMenuExitButton(crMenu,true);
	
	new String:title[400];
	Format(title,400,"[SuperHero:Source] Select your desired heroes\nYou have %d out of %d heroes",SHHasHeroesNum(client),SHGetHeroesClientCanHave(client)) ;
	//AddMenuItem(crMenu,"0","0");
	for(new raceid=1;raceid<=War3_GetRacesLoaded();raceid++){
		
		decl String:rbuf[5];
		Format(rbuf,sizeof(rbuf),"%d",raceid); //DATA FOR MENU!
		
		decl String:rname[32];
		War3_GetRaceName(raceid,rname,sizeof(rname));
		
		decl String:rdisp[100]
		Format(rdisp,sizeof(rdisp),"%s%s",SHHasHero(client,raceid)?">":"",rname);
		new minlevel=W3GetRaceMinLevelRequired(raceid);
		if(minlevel<0) minlevel=0;
		if(minlevel)
		{
			Format(rdisp,sizeof(rdisp),"%s %T",rdisp,"reqlvl {amount}",GetTrans(),minlevel);
		}
		AddMenuItem(crMenu,rbuf,rdisp);
	}
	
	SetMenuTitle(crMenu,"%s\n \n",title);
	DisplayMenu(crMenu,client,MENU_TIME_FOREVER);
}

public War3Source_CRMenu_Selected(Handle:menu,MenuAction:action,client,selection)
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
			//PrintToChat(client,"selected %d",race_selected);
			
			SHTryToGiveClientHero(client,race_selected,true);
		}
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}



InternalClearPowers(client){
	//if(IsPlayerAlive(client)){
		for(new i=1;i<=War3_GetRacesLoaded();i++){
			SHSetHasHero(client,i,false);
		}
		for(new i=0;i<3;i++){
			SHSetPowerBind(client,i,0);
		}
		InternalSHChangeRaceMenu(client);
	//}
}

InternalShowMyHeroes(client){

	if(SHHasHeroesNum(client)==0){
		
		SH_ChatMessage(client,"You do not have any heroes");
		InternalSHChangeRaceMenu(client);
	}
	else{
		//PrintToChatAll("3");
		new Handle:hMenu=CreateMenu(InternalShowMyHeroesSelected);
		SetMenuExitButton(hMenu,true);
		
		new String:title[400];
		Format(title,400,"%s\n \n[SuperHero:Source] Your Heroes\nSelect the hero to remove",title) ;
		//AddMenuItem(hMenu,"0","0");
		for(new heroid=1;heroid<=War3_GetRacesLoaded();heroid++){
			if(SHHasHero(client,heroid)){
				decl String:rbuf[5];
				Format(rbuf,sizeof(rbuf),"%d",heroid); //DATA FOR MENU!
				
				decl String:rname[32];
				SHGetHeroName(heroid,rname,sizeof(rname));
				
				decl String:rdisp[100]
				Format(rdisp,sizeof(rdisp),">%s",rname);
				
				AddMenuItem(hMenu,rbuf,rdisp);
			}
		}
		//PrintToChatAll("4");
		SetMenuTitle(hMenu,"%s\n \n",title);
		DisplayMenu(hMenu,client,MENU_TIME_FOREVER);
		//PrintToChatAll("5");
	}
}

public InternalShowMyHeroesSelected(Handle:menu,MenuAction:action,client,selection)
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
			
			SHSetHasHero(client,race_selected,false);
			if(SHGetHeroHasPowerBind(race_selected)){
				for(new i=0;i<3;i++){
					if(SHGetPowerBind(client,i)==race_selected){
						SHSetPowerBind(client,i,0);
					}
				}
				for(new i=0;i<2;i++){
					if(SHGetPowerBind(client,i)==0){
						SHSetPowerBind(client,i,SHGetPowerBind(client,i+1));
						SHSetPowerBind(client,i+1,0);
					}
				}
			}
			if(SHHasHeroesNum(client)>0){
				InternalShowMyHeroes(client)
			}
		}
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}