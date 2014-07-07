#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Warcraft Extended - RPG Text Display",
    author = "War3Source Team",
    description="Generic text display"
};

new Handle:g_hCvarEnable = INVALID_HANDLE;
new Handle:g_hHudSynchronizer = INVALID_HANDLE;

new String:hintstring[4096];

public LoadCheck()
{
    // Revan: keyhinttext works with CS:GO but weird symbols will be displayed
    g_hCvarEnable = CreateConVar("War3_RightTextDisp",(War3_GetGame() == Game_CSGO) ? "0" : "1", "Enables the right-hand text display of war3source information",_,true,0.0,true,1.0);
    g_hHudSynchronizer = CreateHudSynchronizer();
    if(g_hHudSynchronizer == INVALID_HANDLE && GameCSANY()) {
        //SetFailState("This game does not support Hud Synchronizers or KeyHintText.");
        PrintToServer("[W3XDisplay] This game does not support Hud Synchronizers or KeyHintText.");
        return false;
    }
    return true;
}

public OnPluginStart()
{
    // Revan: keyhinttext works with CS:GO but weird symbols will be displayed
    g_hCvarEnable = CreateConVar("War3_RightTextDisp",(War3_GetGame() == Game_CSGO) ? "0" : "1", "Enables the right-hand text display of war3source information",_,true,0.0,true,1.0);
    g_hHudSynchronizer = CreateHudSynchronizer();
    if(g_hHudSynchronizer == INVALID_HANDLE && GameCSANY()) {
        SetFailState("This game does not support Hud Synchronizers or KeyHintText.");
    }
    RegAdminCmd("sm_display", SetHint, ADMFLAG_ROOT, "Sets the hintstring");
}

public OnMapStart()
{
    CreateTimer(1.0,Print_Level,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Print_Level(Handle:timer, any:data)
{
    if(GetConVarBool(g_hCvarEnable) == false) {
        // destroy timer
        return Plugin_Handled;
    }
    for(new i;i<MAXPLAYERS;i++)
    {
        if(ValidPlayer(i,true))
        {
            if(GameCSANY())
            {
                War3_KeyHintText(i, hintstring);
            } else {
                SetHudTextParams(1.0, -1.0, 1.5, 255, 255 ,255, 255);
                ShowSyncHudText(i, g_hHudSynchronizer, hintstring);
            }
        }
    }
    return Plugin_Continue;
}

public Action:SetHint(client, args)
{
    if(GetConVarBool(g_hCvarEnable) == false) {
        return Plugin_Continue;
    }
    new String:buffer[64];
    new String:buffer2[4096];
    for(new i = 1;i<=args;i++)
    {
        GetCmdArg(i,buffer, sizeof(buffer));
        Format(buffer2,sizeof(buffer2),"%s \n %s",buffer2,buffer);
    }
    strcopy(hintstring,sizeof(hintstring),buffer2);
    return Plugin_Handled;
}

/*
public Action:Print_Level(Handle:timer,any:data)
{
    for(new i;i<MAXPLAYERS;i++)
    {
        if(ValidPlayer(i,true))
        {
            new race = War3_GetRace(i);
            if(race==0)
            {
                return;
            }
            new racelevel = War3_GetLevel(i, race);
            decl String:racename[64];
            War3_GetRaceName(race,racename,sizeof(racename));
            
            new level;
            new SkillCount = War3_GetRaceSkillCount(race);
            decl String:str[1000];
            decl String:skill[64];
            decl String:skilldesc[128];
            new String:selectioninfo[32];
            for(new x=1;x<=SkillCount;x++)
            {
                W3GetRaceSkillName(race,x,skill,sizeof(skill));
                level=War3_GetSkillLevel(i,race,x) ;
                
                if(War3_IsSkillUltimate(race,x))
                {
                    Format(str,sizeof(str),"Ultimate: %s (LVL %i/%i)",skill,level,W3GetRaceSkillMaxLevel(race,x));
                }
                else
                {
                    Format(str,sizeof(str),"%s (LVL %i/%i)",skill,level,W3GetRaceSkillMaxLevel(race,x));
                }
                
                Format(selectioninfo,sizeof(selectioninfo),"%d,skill,%d",race,x);
                
                
                if(SkillCount==x){
                    
                    W3GetRaceSkillDesc(race,x,skilldesc,sizeof(skilldesc)) ;
                    
                    Format(str,sizeof(str),"%s \n%s \n",str,skilldesc);
                }
                
                if(x==War3_GetRaceSkillCount(race)&&SkillCount==x){
                    Format(str,sizeof(str),"%s \n",str); //extend whitespace
                }
                else if(x==War3_GetRaceSkillCount(race)){
                    Format(str,sizeof(str),"%s \n \n",str); //extend whitespace
                }
            }
            
            if(level<W3GetRaceMaxLevel(race))
                Client_PrintKeyHintText(i,"%s - Level %i - %i XP / %i XP\n%s",racename,racelevel,War3_GetXP(i,race),W3GetReqXP(level+1),str);
            else
            Client_PrintKeyHintText(i,"%s - Level %i - %i XP\n%s",racename,racelevel,War3_GetXP(i,race),W3GetReqXP(level+1),str);
        }
    }
} */



