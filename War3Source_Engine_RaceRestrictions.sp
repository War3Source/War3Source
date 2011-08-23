
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


public Plugin:myinfo= 
{
	name="War3Source - Race Restrictions",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://ownageclan.com/ http://war3source.com"
};

public OnPluginStart()
{
}
public OnW3Denyable(W3DENY:event,client){
	if(event==DN_CanSelectRace){
		new race_selected=W3GetVar(EventArg1);
		
		//MIN LEVEL CHECK
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
			return W3Deny();
		}
		
		
		
		//FLAG CHECK
		new String:requiredflagstr[32];
		W3GetRaceAccessFlagStr(race_selected,requiredflagstr,sizeof(requiredflagstr));  ///14 = index, see races.inc
		
		if(!StrEqual(requiredflagstr, "0", false)&&!StrEqual(requiredflagstr, "", false)&&!W3IsDeveloper(client)){
			
			new AdminId:admin = GetUserAdmin(client);
			if(admin == INVALID_ADMIN_ID) //flag is required and this client is not admin
			{
				War3_ChatMessage(client,"%T","Restricted Race. Ask an admin on how to unlock",GetTrans());
				PrintToConsole(client,"%T","No Admin ID found",client);
				return W3Deny();
				
			}
			else{
				new AdminFlag:flag;
				if (!FindFlagByChar(requiredflagstr[0], flag)) //this gets the flag class from the string
				{
					War3_ChatMessage(client,"%T","ERROR on admin flag check {flag}",client,requiredflagstr);
					return W3Deny();
				}
				else
				{
					if (!GetAdminFlag(admin, flag)){
						
						War3_ChatMessage(client,"%T","Restricted race, ask an admin on how to unlock",GetTrans());
						PrintToConsole(client,"%T","Admin ID found, but no required flag",client);
						return W3Deny();
					}
				}
			}
		}
		//DP("passed");
	
	}
	return 0;
}