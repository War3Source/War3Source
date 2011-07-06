



#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/War3Source_L4D_Interface"


new Handle:g_hGameMode;
new bool:bSurvivalStarted;
new bool:bStartingArea[MAXPLAYERS];



public Plugin:myinfo= 
{
	name="War3Source Menus changerace",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};

public OnPluginStart()
{
	 if(War3_IsL4DEngine())
	 {
		g_hGameMode = FindConVar("mp_gamemode");
		if(!HookEventEx("survival_round_start", War3Source_SurvivalStartEvent))
		{
			PrintToServer("[War3Source] Could not hook the survival_round_start event.");
		}
		if(!HookEventEx("round_end", War3Source_RoundEndEvent))
		{
			PrintToServer("[War3Source] Could not hook the round_end event.");
		}
		if(!HookEventEx("player_entered_checkpoint", War3Source_EnterCheckEvent))
		{
			PrintToServer("[War3Source] Could not hook the player_entered_checkpoint event.");
		}
		if(!HookEventEx("player_left_checkpoint", War3Source_LeaveCheckEvent))
		{
			PrintToServer("[War3Source] Could not hook the player_left_checkpoint event.");
		}
		if(!HookEventEx("player_entered_start_area", War3Source_EnterCheckEvent))
		{
			PrintToServer("[War3Source] Could not hook the player_entered_start_area event.");
		}
		if(!HookEventEx("player_left_start_area", War3Source_LeaveCheckEvent))
		{
			PrintToServer("[War3Source] Could not hook the player_left_start_area event.");
		}
	 }
}

public War3Source_EnterCheckEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(GetEventInt(event,"userid")>0)
	{
		new client = GetClientOfUserId(GetEventInt(event,"userid"));
		if (ValidPlayer(client, true))
		{
			W3Hint(client, HINT_LOWEST, 1.0, "You can change your race here!");
			bStartingArea[client] = true;
		}
	}
}

public War3Source_LeaveCheckEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(GetEventInt(event,"userid")>0)
	{
		new client = GetClientOfUserId(GetEventInt(event,"userid"));
		if (ValidPlayer(client, true))
		{
			W3Hint(client, HINT_LOWEST, 1.0, "You can no longer change your race!");
			bStartingArea[client] = false;
		}
	}
}

public War3Source_SurvivalStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	bSurvivalStarted = true;
}

public War3Source_RoundEndEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	bSurvivalStarted = false;
}

public OnWar3Event(W3EVENT:event,client){
	if(W3()){
		if(event==DoShowChangeRaceMenu){
			if(W3Denyable(ChanceRace,client)){
				War3Source_ChangeRaceMenu(client);
			}
		}
	}
}
new String:dbErrorMsg[100];
public OnWar3GlobalError(String:err[]){
	 strcopy(dbErrorMsg,sizeof(dbErrorMsg),err);
}
War3Source_ChangeRaceMenu(client)
{
	if(W3IsPlayerXPLoaded(client))
	{
		SetTrans(client);
		new Handle:crMenu=CreateMenu(War3Source_CRMenu_Selected);
		SetMenuExitButton(crMenu,true);
		
		new String:title[400];
		if(strlen(dbErrorMsg)){
			Format(title,sizeof(title),"%s\n \n",dbErrorMsg);
		}
		Format(title,sizeof(title),"%s%T",title,"[War3Source] Select your desired race",GetTrans()) ;
		if(W3GetLevelBank(client)>0){
			Format(title,sizeof(title),"%s\n%T\n",title,"You Have {amount} levels in levelbank. Say levelbank to use it",GetTrans(), W3GetLevelBank(client));
		}
		SetMenuTitle(crMenu,"%s\n \n",title);
		
		// Iteriate through the races and print them out
		
		decl String:rbuf[4];
		decl String:rname[64];
		decl String:rdisp[128];
		
		
		new racelist[MAXRACES];
		new racedisplay=W3GetRaceList(racelist);
		//if(GetConVarInt(W3GetVar(hSortByMinLevelCvar))<1){
		//	for(new x=0;x<War3_GetRacesLoaded();x++){//notice this starts at zero!
		//		racelist[x]=x+1;
		//	}
		//}
		
		for(new i=0;i<racedisplay;i++) //notice this starts at zero!
		{
			new	x=racelist[i];
			
			Format(rbuf,sizeof(rbuf),"%d",x); //DATA FOR MENU!
			
			War3_GetRaceName(x,rname,sizeof(rname));
			new yourteam,otherteam;
			for(new y=1;y<=MaxClients;y++)
			{
				
				if(ValidPlayer(y,false))
				{
					if(War3_GetRace(y)==x)
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
			if(War3_GetRace(client)==x)
			{
				Format(extra,sizeof(extra),">");
				
			}
			else if(W3GetPendingRace(client)==x){
				Format(extra,sizeof(extra),"<");
				
			}
			Format(rdisp,sizeof(rdisp),"%s%T",extra,"{racename} [L {amount}]",GetTrans(),rname,War3_GetLevel(client,x));
			new minlevel=W3GetRaceMinLevelRequired(x);
			if(minlevel<0) minlevel=0;
			if(minlevel)
			{
				Format(rdisp,sizeof(rdisp),"%s %T",rdisp,"reqlvl {amount}",GetTrans(),minlevel);
			}
			//if(!HasRaceAccess(client,race)){ //show that it is restricted?
			//	Format(rdisp,sizeof(rdisp),"%s\nRestricted",rdisp);
			//}
			
			
			AddMenuItem(crMenu,rbuf,rdisp,(minlevel<=W3GetTotalLevels(client)||W3IsDeveloper(client))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		}
		DisplayMenu(crMenu,client,MENU_TIME_FOREVER);
	}
	else{
		War3_ChatMessage(client,"%T","Your XP Has not been fully loaded yet",GetTrans());
	}
	
}

public War3Source_CRMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		if(ValidPlayer(client))
		{
			SetTrans(client);
			//new menuselectindex=selection+1;
			//if(racechosen>0&&racechosen<=War3_GetRacesLoaded())
			
			decl String:SelectionInfo[4];
			decl String:SelectionDispText[256];
			
			new bool:allowChooseRace=true;
			
			new SelectionStyle;
			GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
			new race_selected=StringToInt(SelectionInfo);
			
			
			// Minimum level?
			
			new total_level=0;
			new RacesLoaded = War3_GetRacesLoaded();
			for(new x=1;x<=RacesLoaded;x++)
			{
				total_level+=War3_GetLevel(client,x);
			}
			new min_level=W3GetRaceMinLevelRequired(race_selected);
			if(min_level<0) min_level=0;
			
			if(min_level!=0&&min_level>total_level&&!W3IsDeveloper(client))
			{
				War3_ChatMessage(client,"%T","You need {amount} more total levels to use this race",GetTrans(),min_level-total_level);
				War3Source_ChangeRaceMenu(client);
				allowChooseRace=false;
			}
				
				
			// GetUserFlagBits(client)&ADMFLAG_ROOT??
			
			new String:requiredflagstr[32];
			
			W3GetRaceAccessFlagStr(race_selected,requiredflagstr,sizeof(requiredflagstr));  ///14 = index, see races.inc
			
			if(!StrEqual(requiredflagstr, "0", false)&&!StrEqual(requiredflagstr, "", false)&&!W3IsDeveloper(client)){
				
				new AdminId:admin = GetUserAdmin(client);
				if(admin == INVALID_ADMIN_ID) //flag is required and this client is not admin
				{
					allowChooseRace=false;
					War3_ChatMessage(client,"%T","Restricted Race. Ask an admin on how to unlock",GetTrans());
					PrintToConsole(client,"%T","No Admin ID found",client);
					War3Source_ChangeRaceMenu(client);
					
				}
				else{
					decl AdminFlag:flag;
					if (!FindFlagByChar(requiredflagstr[0], flag)) //this gets the flag class from the string
					{
						War3_ChatMessage(client,"%T","ERROR on admin flag check {flag}",client,requiredflagstr);
						allowChooseRace=false;
					}
					else
					{
						if (!GetAdminFlag(admin, flag)){
							allowChooseRace=false;
							War3_ChatMessage(client,"%T","Restricted race, ask an admin on how to unlock",GetTrans());
							PrintToConsole(client,"%T","Admin ID found, but no required flag",client);
							War3Source_ChangeRaceMenu(client);
						}
					}
				}
			}
			
			
			
			if(allowChooseRace)
			{
				W3SetPlayerProp(client,RaceChosenTime,GetGameTime());
				W3SetPlayerProp(client,RaceSetByAdmin,false);
				
				//PrintToChatAll("1");
				decl String:buf[192];
				War3_GetRaceName(race_selected,buf,sizeof(buf));
				if(race_selected==War3_GetRace(client)&&(   W3GetPendingRace(client)<1||W3GetPendingRace(client)==War3_GetRace(client)    )){ //has no other pending race, cuz user might wana switch back
					
					War3_ChatMessage(client,"%T","You are already {racename}",GetTrans(),buf);
					if(W3GetPendingRace(client)){
						W3SetPendingRace(client,-1);
					}
					
				}
				else if(GetConVarInt(W3GetVar(hRaceLimitEnabledCvar))>0){
					if(GetRacesOnTeam(race_selected,GetClientTeam(client))>=W3GetRaceMaxLimitTeam(race_selected,GetClientTeam(client))){ //already at limit
						if(!W3IsDeveloper(client)){   
							War3_ChatMessage(client,"%T","Race limit for your team has been reached, please select a different race. (MAX {amount})",GetTrans(),W3GetRaceMaxLimitTeam(race_selected,GetClientTeam(client)));
							
							new cvar=W3GetRaceMaxLimitTeamCvar(race_selected,GetClientTeam(client));
							new String:cvarstr[64];
							if(cvar>-1){
								W3GetCvarActualString(cvar,cvarstr,sizeof(cvarstr));
							}
							cvar=W3FindCvar(cvarstr);
							new String:cvarvalue[64];
							if(cvar>-1){
								W3GetCvar(cvar,cvarvalue,sizeof(cvarvalue));
							}
							
							W3Log("race %d blocked on client %d due to restrictions limit %d (select changeracemenu) %s %s",race_selected,client,W3GetRaceMaxLimitTeam(race_selected,GetClientTeam(client)),cvarstr,cvarvalue);
				
							War3Source_ChangeRaceMenu(client);
							allowChooseRace=false;
							
						}
					}
				}
				
				
				
				
				
				if(allowChooseRace){
					if(War3_GetRace(client)>0&&IsPlayerAlive(client)&&!W3IsDeveloper(client)) //developer direct set (for testing purposes)
					{
						if(War3_IsL4DEngine())
						{
							decl String:sGameMode[16];
							
							GetConVarString(g_hGameMode, sGameMode, sizeof(sGameMode));
							if (StrEqual(sGameMode, "survival", false) && !bSurvivalStarted)
							{
								W3SetPendingRace(client,-1);
								War3_SetRace(client,race_selected);
								W3DoLevelCheck(client);
							}
							else if (bStartingArea[client])
							{
								W3SetPendingRace(client,-1);
								War3_SetRace(client,race_selected);
								W3DoLevelCheck(client);
							}
							else
							{
								W3SetPendingRace(client,race_selected);
								
								War3_ChatMessage(client,"%T","You will be {racename} after death or spawn",GetTrans(),buf);
							}
						}
						else
						{
							W3SetPendingRace(client,race_selected);
							
							War3_ChatMessage(client,"%T","You will be {racename} after death or spawn",GetTrans(),buf);
						}
					}
					//HAS NO RACE, CHANGE NOW
					else //schedule the race change
					{
						W3SetPendingRace(client,-1);
						War3_SetRace(client,race_selected);
						
						//PrintToChatAll("2");
						//print is in setrace
						//War3_ChatMessage(client,"You are now %s",buf);
						
						W3DoLevelCheck(client);
					}
				}
					
			}
		}
//	}
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}


