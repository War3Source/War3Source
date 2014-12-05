#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Race Restrictions",
    author = "War3Source Team",
    description = "Restrict players from selecting races"
};
public OnPluginStart()
{
}
public OnW3Denyable(W3DENY:event,client){
    if(event==DN_CanSelectRace)
    {
        new race_selected=W3GetVar(EventArg1);
        if(race_selected<=0)
        {
            ThrowError(" DN_CanSelectRace CALLED WITH INVALID RACE [%d]",race_selected);
            return W3Deny();
        }
        //MIN LEVEL CHECK
        new total_level=W3GetTotalLevels(client);
        new min_level=W3GetRaceMinLevelRequired(race_selected);
        if(min_level<0) min_level=0;

        if(min_level!=0&&min_level>total_level)
        {
            if(!W3GetPlayerProp(client,RaceSetByAdmin))
            {
                War3_ChatMessage(client,"%T","You need {amount} more total levels to use this race",GetTrans(),min_level-total_level);
                return W3Deny();
            }
        }
        //FLAG CHECK
        new String:requiredflagstr[32];
        W3GetRaceAccessFlagStr(race_selected,requiredflagstr,sizeof(requiredflagstr));  ///14 = index, see races.inc
        
        if(!StrEqual(requiredflagstr, "0", false)&&!StrEqual(requiredflagstr, "", false))
        {
        
            new AdminId:admin = GetUserAdmin(client);
            if(admin == INVALID_ADMIN_ID) //flag is required and this client is not admin
            {
                War3_ChatMessage(client,"%T","Restricted Race. Ask an admin on how to unlock",GetTrans());
                PrintToConsole(client,"%T","No Admin ID found",client);
                return W3Deny();
            }
            else
            {
                new AdminFlag:flag;
                if (!FindFlagByChar(requiredflagstr[0], flag)) //this gets the flag class from the string
                {
                    War3_ChatMessage(client,"%T","ERROR on admin flag check {flag}",client,requiredflagstr);
                    return W3Deny();
                }
                else
                {
                    if (!GetAdminFlag(admin, flag))
                    {
                    
                        War3_ChatMessage(client,"%T","Restricted race, ask an admin on how to unlock",GetTrans());
                        PrintToConsole(client,"%T","Admin ID found, but no required flag",client);
                        return W3Deny();
                    }
                }
            }
        }
        
        ///MAX PER TEAM CHECK
        if(GetConVarInt(W3GetVar(hRaceLimitEnabledCvar))>0)
        {
            //if player is already this race, this is not what it does and its up to gameevents to kick the player
            if(War3_GetRace(client)!=race_selected&&GetRacesOnTeam(race_selected,GetClientTeam(client))>=W3GetRaceMaxLimitTeam(race_selected,GetClientTeam(client))) //already at limit
            {
                //if(!W3IsDeveloper(client)){
                //    DP("racerestricitons.sp");
                War3_ChatMessage(client,"%T","Race limit for your team has been reached, please select a different race. (MAX {amount})",GetTrans(),W3GetRaceMaxLimitTeam(race_selected,GetClientTeam(client)));
            
                new cvar=W3GetRaceMaxLimitTeamCvar(race_selected,GetClientTeam(client));
                new String:cvarstr[64];
                if(cvar>-1)
                {
                    W3GetCvarActualString(cvar,cvarstr,sizeof(cvarstr));
                }
                cvar=W3FindCvar(cvarstr);
                new String:cvarvalue[64];
                if(cvar>-1)
                {
                    W3GetCvar(cvar,cvarvalue,sizeof(cvarvalue));
                }
                
                War3_LogInfo("race %d blocked on client %d due to restrictions limit %d  %s %s",race_selected,client,W3GetRaceMaxLimitTeam(race_selected,GetClientTeam(client)),cvarstr,cvarvalue);
                return W3Deny();
            }
            ////TF CLASS CHECK
            if(GameTF())
            {
                new String:classlist[][32]={"unknown","scout","sniper","soldier","demoman","medic","heavy","pyro","spy","engineer"};
                new class=_:TF2_GetPlayerClass(client);
                new String:classstring[32];
                strcopy(classstring,sizeof(classstring),classlist[class]);
            
                new cvarid=W3GetRaceCell(race_selected,ClassRestrictionCvar);
                //DP("cvar %d %s",cvarid,cvarstring);
                if(W3FindStringInCvar(cvarid,classstring,2))
                {
                    //DP("deny");
                    War3_ChatMessage(client,"Race restricted due to class restriction: %s",classstring);
                    return W3Deny();
                }
            }
        
        //DP("passed");
    
        }
    }
    return false;
}
