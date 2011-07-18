

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo= 
{
	name="W3S Engine XP Gold TF",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};




// tf
new Handle:PointCaptureXPCvar;
new Handle:PointCapBlockXPCvar;
new Handle:CaptureFlagXPCvar;


public OnPluginStart()
{
	
	if(W3()){
		
		PointCaptureXPCvar=CreateConVar("war3_percent_tf_pointcapturexp","25","Percent of kill XP awarded to the capturing team");
		PointCapBlockXPCvar=CreateConVar("war3_percent_tf_blockcapturexp","20","Percent of kill XP awarded for blocking a capture");
		CaptureFlagXPCvar=CreateConVar("war3_percent_tf_flagcapturexp","100","Percent of kill XP awarded for capturing the flag");
		
		if(War3_GetGame()==Game_TF)
		{
			//if(!HookEventEx("teamplay_round_win",War3Source_RoundOverEvent))
			//{
			//	PrintToServer("[War3Source] Could not hook the teamplay_round_win event.");
			//	
			//}
			if(!HookEventEx("teamplay_point_captured",War3Source_PointCapturedEvent))
			{
				PrintToServer("[War3Source] Could not hook the teamplay_point_captured event.");
				
			}
			if(!HookEventEx("teamplay_capture_blocked",War3Source_PointCapBlockedEvent))
			{
				PrintToServer("[War3Source] Could not hook the teamplay_capture_blocked event.");
				
			}
			if(!HookEventEx("teamplay_flag_event",War3Source_FlagEvent))
			{
				PrintToServer("[War3Source] Could not hook the teamplay_flag_event event.");
				
			}
		}
	}	
}

public War3Source_PointCapturedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new team=GetEventInt(event,"team");
	if(team>-1)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			
			if(ValidPlayer(i,true)&&  GetClientTeam(i)==team)
			{

				
				new race=War3_GetRace(i);
				if(race>0)
				{
					new addxp=((W3GetKillXP(War3_GetLevel(i,War3_GetRace(i)))*GetConVarInt(PointCaptureXPCvar))/100);
					
					new String:captureaward[64];
					Format(captureaward,sizeof(captureaward),"%T","being on the capturing team",i);
					W3GiveXPGold(i,race,XPAwardByPointCap,addxp,0,captureaward);
				}
			}
		}
	}
}

public War3Source_PointCapBlockedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new blocker_uid=GetEventInt(event,"blocker");
	if(blocker_uid>0)
	{
		new client=GetClientOfUserId(blocker_uid);

		if(client>0 )
		{
		
			new race=War3_GetRace(client);
			if(race>0)
			{
				new addxp=((W3GetKillXP(War3_GetLevel(client,War3_GetRace(client)))*GetConVarInt(PointCapBlockXPCvar))/100);
				
				new String:pointcaptureaward[64];
				Format(pointcaptureaward,sizeof(pointcaptureaward),"%T","blocking point capture",client);
				W3GiveXPGold(client,race,XPAwardByPointCapBlock,addxp,0,pointcaptureaward);
			}
		}
	}
}

public War3Source_FlagEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new userid=GetEventInt(event,"carrier");
	if(userid>0)
	{
		new client=GetClientOfUserId(userid);
		new type=GetEventInt(event,"eventtype");
		if(client>0  && type==2)
		{
		
			new race=War3_GetRace(client);
			if(race>0)
			{
				new addxp=((W3GetKillXP(War3_GetLevel(client,War3_GetRace(client)))*GetConVarInt(CaptureFlagXPCvar))/100);
				
				new String:pointcaptureaward[64];
				Format(pointcaptureaward,sizeof(pointcaptureaward),"%T","blocking point capture",client);
				W3GiveXPGold(client,race,XPAwardByFlagCap,addxp,0,pointcaptureaward);
			}
		}
	}
}

