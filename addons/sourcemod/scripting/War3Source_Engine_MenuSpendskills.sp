#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Menu Spendskills",
    author = "War3Source Team",
    description = "Shows the spendskills menu"
};

new Handle:NoSpendSkillsLimitCvar;

public OnPluginStart()
{
 // No Spendskill level restrictions on non-ultimates (Requires mapchange)
 NoSpendSkillsLimitCvar=CreateConVar("war3_no_spendskills_limit","0","Set to 1 to require no limit on non-ultimate spendskills");
}

public OnWar3Event(W3EVENT:event,client){
    if(event==DoShowSpendskillsMenu){
        War3Source_SkillMenu(client);
    }
}

//checks for any active dependencys on the given skill
//TODO: add translation support
stock bool:HasDependency(client,race,skill,String:buffer[],maxlen,bool:is_ult)
{
    //Check if our skill has a dependency
    new dependencyID = War3_GetDependency(race, skill, SkillDependency:ID);
    if( dependencyID != INVALID_DEPENDENCY ) {
        //If so, append our stuff if the skill minlevel is below our current level(otherwhise do just NOTHING)
        //but wait.. is our depending required level valid?
        new requiredLVL = War3_GetDependency(race, skill, SkillDependency:LVL);
        if(requiredLVL > 0) {
            //oh it is.. okay do the stuff i want to do before lol...
            new currentLVL = War3_GetSkillLevelINTERNAL(client,race,dependencyID);
            if(currentLVL < requiredLVL) {
                //Gotcha! now we just need to overwrite that buffer
                decl String:skillname[64]; //original skill
                W3GetRaceSkillName(race,skill,skillname,sizeof(skillname));
                decl String:skillname2[64]; // depending skill
                W3GetRaceSkillName(race,dependencyID,skillname2,sizeof(skillname2));
                if(is_ult)
                    Format(buffer,maxlen,"Ultimate: %s [Requires %d lvl on %s]",skillname,(requiredLVL-currentLVL),skillname2);
                else
                    Format(buffer,maxlen,"%s [Requires %d lvl on %s]",skillname,(requiredLVL-currentLVL),skillname2);
                return true;
            }
        }
    }
    return false;
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
            SetSafeMenuTitle(sMenu,"%T\n \n","[War3Source] Select your desired skill. ({amount}/{amount})",client,skillcount,level);
            decl String:skillname[64];
            new curskilllevel;
            
            decl String:sbuf[4];
            decl String:buf[192];
            new SkillCount = War3_GetRaceSkillCount(race_num);
            for(new x=1;x<=SkillCount;x++)
            {
                curskilllevel=War3_GetSkillLevelINTERNAL(client,race_num,x);
                if(curskilllevel<W3GetRaceSkillMaxLevel(race_num,x)){
                
                    W3GetRaceSkillName(race_num,x,skillname,sizeof(skillname));
                    
                    if(!War3_IsSkillUltimate(race_num,x))
                    {
                        //if(level>=curskilllevel*2+1){
                        Format(sbuf,sizeof(sbuf),"%d",x);
                        Format(buf,sizeof(buf),"%T","{skillname} (Skill Level {amount})",client,skillname,curskilllevel+1);
                        new bool:failed = HasDependency(client,race_num,x,buf,sizeof(buf),false);
                        if(failed)
                            AddMenuItem(sMenu,sbuf,buf,ITEMDRAW_DISABLED);
                        else
                           {
                            // No Spending skills limit
                            if(GetConVarBool(NoSpendSkillsLimitCvar))
                              {
                               AddMenuItem(sMenu,sbuf,buf,ITEMDRAW_DEFAULT);
                              }
                             else
                                 AddMenuItem(sMenu,sbuf,buf,(level>=curskilllevel*2+1)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
                           }
                        //}
                    }
                    else {
                        //if(level>=curskilllevel*2+1+){
                        Format(sbuf,sizeof(sbuf),"%d",x);
                        Format(buf,sizeof(buf),"%T ","Ultimate: {skillname} (Skill Level {amount})",client,skillname,curskilllevel+1);
                        if((level<W3GetMinUltLevel())){
                            Format(buf,sizeof(buf),"%s %T",buf,"[Requires lvl {amount}]",client,W3GetMinUltLevel());
                        }
                        new bool:failed = HasDependency(client,race_num,x,buf,sizeof(buf),true);
                        if(failed)
                            AddMenuItem(sMenu,sbuf,buf,ITEMDRAW_DISABLED);
                        else
                            AddMenuItem(sMenu,sbuf,buf,(level>=curskilllevel*2+1+W3GetMinUltLevel()-1)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
                    }
                    
                    /*if(War3_IsSkillPartOfTree(race_num, x)) //the skill depends on something
                    {
                        Format(sbuf, sizeof(sbuf), "%d", x);
                        Format(buf, sizeof(buf),"%T","{skillname} (Skill Level {amount})",client, skillname, curskilllevel+1);
                        
                        new minlevel = 0; //counter measure: if I define them here and not within the for loop, I don't define them "SkillCount" times. less ressources used
                        new skilllevelinternal = 0; // ^
                        for(new i= 1; i<=SkillCount; i++) //now lets loop again to see if we can find the mysterious skill xyz thats so important!
                        {
                            minlevel = War3_SkillTreeDependencyLevel(race_num, i); //skill x depends on something lvl ??. What's the req.?
                            new i_skillIDdepends = War3_GetSkillTreeDependencyID(race_num, i); //finally, x depends on skill xyz. what's its ID?
             
                            if(i_skillIDdepends == i)
                            { //the skill we need (i_SkillIDdepends) is i! we have a winner! wohoo! now lets apply the stuff!
                                skilllevelinternal = War3_GetSkillLevelINTERNAL(client,race_num,i);
                                
                                if( skilllevelinternal >= minlevel) //has he leveled the skill needed higher than/equal to the required parameter?
                                {
                                    decl String:name[64];
                                    W3GetRaceSkillName(race_num,i,name,sizeof(name));
                                    Format(buf, sizeof(buf),"%s %T",buf,"[Requires {skillname} L{amount}]",client, name, minlevel); 
                                    //finally, apply all necessary changes to the menu
                                }
                            }
                        }
                        AddMenuItem(sMenu, sbuf, buf, (skilllevelinternal >= minlevel)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED); //defines the way the skill is displayed (white: non selectable / yellow: like normal
                    }*/
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
            if(selection>=0&&selection<=War3_GetRaceSkillCount(raceid))
            {
                // OPTIMZE THIS
                decl String:SelectionInfo[4];
                GetMenuItem(menu, selection, SelectionInfo, sizeof(SelectionInfo));
                new skill=StringToInt(SelectionInfo);
                
                
                
                if(War3_IsSkillUltimate(raceid,selection))
                {
                    new race=War3_GetRace(client);
                    new level=War3_GetLevel(client,race);
                    if(level>=W3GetMinUltLevel())
                    {
                        if(W3GetLevelsSpent(client,race)<War3_GetLevel(client,race))
                        {
                            War3_SetSkillLevelINTERNAL(client,race,skill,War3_GetSkillLevelINTERNAL(client,race,skill)+1);
                            decl String:skillname[64];
                            W3GetRaceSkillName(race,skill,skillname,sizeof(skillname));
                            War3_ChatMessage(client,"%T","{skillname} is now level {amount}",client,skillname,War3_GetSkillLevelINTERNAL(client,race,skill));
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
                        War3_SetSkillLevelINTERNAL(client,race,skill,War3_GetSkillLevelINTERNAL(client,race,skill)+1);
                        decl String:skillname[64];
                        W3GetRaceSkillName(race,skill,skillname,sizeof(skillname));
                        War3_ChatMessage(client,"%T","{skillname} is now level {amount}",client,skillname,War3_GetSkillLevelINTERNAL(client,race,skill));
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


