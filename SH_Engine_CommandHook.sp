

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"





new Handle:Cvar_ChatBlocking;

new Handle:g_OnPowerCommandHandle;





public Plugin:myinfo= 
{
	name="SH Engine Command Hooks",
	author="Ownz (DarkEnergy)",
	description="SH Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};

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
	Cvar_ChatBlocking=CreateConVar("war3_command_blocking","0");
	if(SH()){

		RegConsoleCmd("say",War3Source_SayCommand);
		RegConsoleCmd("say_team",War3Source_SayCommand);

		RegConsoleCmd("+ultimate",SH_PowerCommand);
		RegConsoleCmd("-ultimate",SH_PowerCommand);
		RegConsoleCmd("+ability",SH_PowerCommand);
		RegConsoleCmd("-ability",SH_PowerCommand);
		RegConsoleCmd("+ability2",SH_PowerCommand);
		RegConsoleCmd("-ability2",SH_PowerCommand);
		RegConsoleCmd("+ability3",SH_PowerCommand);
		RegConsoleCmd("-ability3",SH_PowerCommand);
		RegConsoleCmd("+power1",SH_PowerCommand);
		RegConsoleCmd("-power1",SH_PowerCommand);
		RegConsoleCmd("+power2",SH_PowerCommand);
		RegConsoleCmd("-power2",SH_PowerCommand);
		RegConsoleCmd("+power3",SH_PowerCommand);
		RegConsoleCmd("-power3",SH_PowerCommand);
	}
		
}



public bool:InitNativesForwards()
{
	g_OnPowerCommandHandle=CreateGlobalForward("OnPowerCommand",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);
	
	return true;
}










new String:command2[70];
new String:command3[70];

public bool:CommandCheck(String:compare[],String:command[])
{
	Format(command2,70,"\\%s",command);
	Format(command3,70,"/%s",command);
	if(!strcmp(compare,command,false)||!strcmp(compare,command2,false)||!strcmp(compare,command3,false))
		return true;
	return false;
}

public CommandCheckEx(String:compare[],String:command[])
{
	if(StrEqual(command,"",false))
		return -1;
	Format(command2,70,"\\%s",command);
	Format(command3,70,"/%s",command);
	if(!StrContains(compare,command,false)||!StrContains(compare,command2,false)||!StrContains(compare,command3,false))
	{
		ReplaceString(compare,70,command,"",false);
		ReplaceString(compare,70,command2,"",false);
		ReplaceString(compare,70,command3,"",false);
		new val=StringToInt(compare);
		if(val>0)
			return val;
	}
	return -1;
}
public bool:CommandCheckStartsWith(String:compare[],String:lookingfor[]) {
	return StrContains(compare, lookingfor, false)==0;
}

public Action:War3Source_SayCommand(client,args)
{

	decl String:arg1[70];
	GetCmdArg(1,arg1,70);
	
//	new top_num;
	
	new Action:returnblocking = (GetConVarInt(Cvar_ChatBlocking)>0)?Plugin_Handled:Plugin_Continue;

	
	
	
	if(CommandCheck(arg1,"myheroes")){
		W3CreateEvent(SHMyHeroes,client);
		return returnblocking;
	}
	
	
	if(CommandCheck(arg1,"showxp") || CommandCheck(arg1,"xp"))
	{
		SHShowXP(client);
		return returnblocking;
		
	}
	else if(CommandCheck(arg1,"changerace")||CommandCheck(arg1,"showmenu"))
	{
		W3CreateEvent(SHSelectHeroesMenu,client);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"shhelp")||CommandCheck(arg1,"help")||CommandCheck(arg1,"wchelp"))
	{
		W3CreateEvent(DoShowSHMenu,client);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"itemsinfo"))
	{
		W3CreateEvent(DoShowItemsInfoMenu,client);
		return returnblocking;
	}
	else if(CommandCheckStartsWith(arg1,"playerinfo"))
	{
		new Handle:array=CreateArray(300);
		PushArrayString(array,arg1);
		W3SetVar(hPlayerInfoArgStr,array);
		W3CreateEvent(DoShowPlayerinfoEntryWithArg,client);
		
		CloseHandle(array);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"raceinfo")||CommandCheck(arg1,"heroinfo"))
	{
		W3CreateEvent(DoShowRaceinfoMenu,client);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"speed")){

		new Float:currentmaxspeed=GetEntDataFloat(client,War3_GetGame()==Game_TF?FindSendPropOffs("CTFPlayer","m_flMaxspeed"):FindSendPropOffs("CBasePlayer","m_flLaggedMovementValue"));
		SH_ChatMessage(client,"Your max speed is %.2f",currentmaxspeed);
	}
	else if(CommandCheck(arg1,"maxhp"))
	{
		new maxhp = War3_GetMaxHP(client);
		SH_ChatMessage(client,"Your max health is: %d",maxhp);
	}
	if(SHHasHeroesNum(client)>0)
	{
		/*if(CommandCheck(arg1,"skillsinfo"))
		{
			W3ShowSkillsInfo(client);
			return returnblocking;
		}
		else*/ 
		if(CommandCheck(arg1,"resetskills")||CommandCheck(arg1,"clearpowers"))
		{
			W3CreateEvent(SHClearPowers,client);
			return returnblocking;
		}
		/*else if(CommandCheck(arg1,"spendskills"))
		{
			new race=War3_GetRace(client);
			if(W3GetLevelsSpent(client,race)<War3_GetLevel(client,race))
				W3CreateEvent(DoShowSpendskillsMenu,client);
			else
				SH_ChatMessage(client,"You don't have any skill points to spend, if you want to reset your skills use resetskills.");
			return returnblocking;
		}
		else if(CommandCheck(arg1,"shopmenu"))
		{
			W3CreateEvent(DoShowShopMenu,client);
			return returnblocking;
		}*/
		else if(CommandCheck(arg1,"shmenu"))
		{
			W3CreateEvent(DoShowSHMenu,client);
			return returnblocking;
		}
	/*	else if(CommandCheck(arg1,"levelbank"))
		{
			W3CreateEvent(DoShowLevelBank,client);
			return returnblocking;
		}
		
		else if(CommandCheck(arg1,"war3rank"))
		{
			if(W3SaveEnabled())
			{
				W3CreateEvent(DoShowWar3Rank,client);
			}
			else
			{
				SH_ChatMessage(client,"This server doesn't save XP, feature disabled.");
			}  
			return returnblocking;
		}
		else if(CommandCheck(arg1,"war3stats"))
		{
			W3CreateEvent(DoShowWar3Stats,client);
			return returnblocking;
		}
	*/	
		else if(CommandCheck(arg1,"shdev"))
		{
			SH_ChatMessage(0,"Anthony (PimpinJuice) STEAM_0:1:6121386 and Ownz STEAM_0:1:9724315 are developers for SH:Source.");
			return returnblocking;
		}
		/*else if((top_num=CommandCheckEx(arg1,"war3top"))>0)
		{
			if(top_num>100) top_num=100;
			if(W3SaveEnabled())
			{
				W3SetVar(EventArg1,top_num);
				W3CreateEvent(DoShowWar3Top,client);
			}
			else
			{
				SH_ChatMessage(client,"This server doesn't save XP, feature disabled.");
			}
			return returnblocking;
		}
		new String:itemshort[100];
		
		for(new itemid=1;itemid<=W3GetItemsLoaded();itemid++){
			W3GetItemShortname(itemid,itemshort,100);
			if(CommandCheckStartsWith(arg1,itemshort)){
				W3SetVar(EventArg1,itemid);
				W3CreateEvent(DoTriedToBuyItem,client);
				return returnblocking ;
			}
		}*/
	}
	/*else
	{
		if(CommandCheck(arg1,"skillsinfo") ||
			CommandCheck(arg1,"resetskills") ||
			CommandCheck(arg1,"spendskills") ||
			CommandCheck(arg1,"showskills") ||
			CommandCheck(arg1,"shopmenu") ||
			CommandCheck(arg1,"war3menu") ||
			CommandCheck(arg1,"war3rank") ||
			CommandCheck(arg1,"war3stats") ||
			CommandCheck(arg1,"levelbank")||
			CommandCheckEx(arg1,"war3top")>0)
		{
			if(W3IsPlayerXPLoaded(client))
			{
				SH_ChatMessage(client,"Select a race first!!");
				W3CreateEvent(SHSelectHeroesMenu,client);
			}
			return returnblocking;
		}
	}
	*/
	return Plugin_Continue;
}





public Action:SH_PowerCommand(client,args)
{
	new String:command[32];
	GetCmdArg(0,command,32);
	//PrintToChatAll("%s",command) ;
	
	new powerindex=0; // no number, or 1
	if(StrContains(command,"2")>0){
		//PrintToChatAll("%d",StrContains(command,"2"));
		powerindex=1;
	}
	else if(StrContains(command,"3")>0){
		powerindex=2;
	}
	//PrintToChatAll(" powerindex %d", powerindex);
	
	new bool:pressed=false;
	if(StrContains(command,"+")>-1)
		pressed=true;
	Call_StartForward(g_OnPowerCommandHandle);
	Call_PushCell(client);
	Call_PushCell(SHGetPowerBind(client,powerindex));
	Call_PushCell(pressed);
	Call_Finish(dummy);
	
	return Plugin_Handled;
}