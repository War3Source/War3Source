



#include <sourcemod>
#include "W3SIncs/War3Source_Interface"







public Plugin:myinfo= 
{
	name="War3Source Menu spendskills",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};



public APLRes:AskPluginLoad2(Handle:myself,bool:late,String:error[],err_max)
{
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

bool:InitNativesForwards()
{

	return true;
}
public OnWar3Event(W3EVENT:event,client){
	if(event==DoShowSpendskillsMenu){
		War3Source_SkillMenu(client);
	}
}

War3Source_SkillMenu(client)
{
	
	// HACK: Supress this menu until loaded player data
	if(W3IsPlayerXPLoaded(client))
	{
		SetTrans(client);
		new race_num=War3_GetRace(client);
		if(!(W3GetLevelsSpent(client,race_num)<War3_GetLevel(client,race_num))){
			War3_ChatMessage(client,"%T","You do not have any skill points to spend, if you want to reset your skills use resetskills",client);
		}

		else if(race_num>0)
		{
			new Handle:sMenu=CreateMenu(War3Source_SMenu_Selected);
			new skillcount=W3GetLevelsSpent(client,race_num);
			new level=War3_GetLevel(client,race_num);
			SetMenuExitButton(sMenu,true);
			SetMenuTitle(sMenu,"%T\n \n","[War3Source] Select your desired skill. ({amount}/{amount})",client,skillcount,level);
			decl String:skillname[64];
			new curskilllevel;
			
			decl String:sbuf[4];
			decl String:buf[192];
			new SkillCount = War3_GetRaceSkillCount(race_num);
			for(new x=0;x<SkillCount;x++)
			{
				
				
				curskilllevel=War3_GetSkillLevel(client,race_num,x);
				if(curskilllevel<W3GetRaceSkillMaxLevel(race_num,x)){
				
					W3GetRaceSkillName(race_num,x,skillname,sizeof(skillname));
					
					if(!War3_IsSkillUltimate(race_num,x))
					{
						//if(level>=curskilllevel*2+1){
						Format(sbuf,sizeof(sbuf),"%d",x);
						Format(buf,sizeof(buf),"%T","{skillname} (Skill Level {amount})",client,skillname,curskilllevel+1);
						AddMenuItem(sMenu,sbuf,buf,(level>=curskilllevel*2+1)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
						//}
					}
					else{
						//if(level>=curskilllevel*2+1+){
						Format(sbuf,sizeof(sbuf),"%d",x);
						Format(buf,sizeof(buf),"%T ","Ultimate: {skillname} (Skill Level {amount})",client,skillname,curskilllevel+1);
						if((level<W3GetMinUltLevel())){
							Format(buf,sizeof(buf),"%s %T",buf,"[Requires lvl {amount}]",client,W3GetMinUltLevel());
						}
						AddMenuItem(sMenu,sbuf,buf,(level>=curskilllevel*2+1+W3GetMinUltLevel()-1)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
					}
					//if(curskilllevel<W3GetRaceSkillMaxLevel(race_num,x)) //, show if 3 when maxlevel is 4 not max level
				}

			}
			DisplayMenu(sMenu,client,MENU_TIME_FOREVER);
		}
	}
}

public War3Source_SMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		
		if(ValidPlayer(client,false))
		{
			new raceid=War3_GetRace(client);
			if(selection>=0&&selection<War3_GetRaceSkillCount(raceid))
			{
				// OPTIMZE THIS
				decl String:SelectionInfo[4];
				decl String:SelectionDispText[256];
				new SelectionStyle;
				GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
				new skill=StringToInt(SelectionInfo);
			
				if(War3_IsSkillUltimate(raceid,selection))
				{
					new race=War3_GetRace(client);
					new level=War3_GetLevel(client,race);
					if(level>=W3GetMinUltLevel())
					{
						if(W3GetLevelsSpent(client,race)<War3_GetLevel(client,race))
						{
							War3_SetSkillLevel(client,race,skill,War3_GetSkillLevel(client,race,skill)+1);
							decl String:skillname[64];
							W3GetRaceSkillName(race,skill,skillname,sizeof(skillname));
							War3_ChatMessage(client,"%T","{skillname} is now level {amount}",client,skillname,War3_GetSkillLevel(client,race,skill));
						}
						else
							War3_ChatMessage(client,"%T","You can not choose a skill without gaining another level",client);
					}
					else{
						War3_ChatMessage(client,"%T","You need to be at least level {amount} to choose an ultimate",client,W3GetMinUltLevel());
					}
					
				}
				else
				{
					new race=War3_GetRace(client);
					if(W3GetLevelsSpent(client,race)<War3_GetLevel(client,race))
					{
						War3_SetSkillLevel(client,race,skill,War3_GetSkillLevel(client,race,skill)+1);
						decl String:skillname[64];
						W3GetRaceSkillName(race,skill,skillname,sizeof(skillname));
						War3_ChatMessage(client,"%T","{skillname} is now level {amount}",client,skillname,War3_GetSkillLevel(client,race,skill));
					}
					else{
						War3_ChatMessage(client,"%T","You can not choose a skill without gaining another level",client);
					}
				}
				W3DoLevelCheck(client);
			}
			
		}
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}


