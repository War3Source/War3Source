

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public LoadCheck(){
	return GameTF();
}

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
new Handle:TeleporterXPCvar;
new Handle:ExtinguishXPCvar;
public OnPluginStart()
{
	
	if(W3()){
		
		PointCaptureXPCvar=CreateConVar("war3_percent_tf_pointcapturexp","25","Percent of kill XP awarded to the capturing team");
		PointCapBlockXPCvar=CreateConVar("war3_percent_tf_blockcapturexp","20","Percent of kill XP awarded for blocking a capture");
		CaptureFlagXPCvar=CreateConVar("war3_percent_tf_flagcapturexp","100","Percent of kill XP awarded for capturing the flag");
		TeleporterXPCvar=CreateConVar("war3_percent_tf_teleporterxp","10","Percent of kill XP awarded");
		ExtinguishXPCvar=CreateConVar("war3_percent_tf_extinguishxp","10","Percent of kill XP awarded");
		
		if(GameTF())
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
			
			HookEvent("player_teleported",TF_XP_teleported);
			HookEvent("player_extinguished",TF_XP_player_extinguished);
		}
	}	
}

public War3Source_PointCapturedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new team=GetEventInt(event,"team");
	if(team>1)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			
			if(ValidPlayer(i,true)&&  GetClientTeam(i)==team)
			{

				
				new race=War3_GetRace(i);
				if(race>0)
				{
					new addxp=((W3GetKillXP(i)*GetConVarInt(PointCaptureXPCvar))/100);
					
					new String:captureaward[64];
					Format(captureaward,sizeof(captureaward),"%T","being on the capturing team",i);
					W3GiveXPGold(i,XPAwardByPointCap,addxp,0,captureaward);
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

		if(ValidPlayer(client))
		{
		
		
			new addxp=(W3GetKillXP(client)*GetConVarInt(PointCapBlockXPCvar))/100;
			
			new String:pointcaptureaward[64];
			Format(pointcaptureaward,sizeof(pointcaptureaward),"%T","blocking point capture",client);
			W3GiveXPGold(client,XPAwardByPointCapBlock,addxp,0,pointcaptureaward);
		
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
				new addxp=((W3GetKillXP(client)*GetConVarInt(CaptureFlagXPCvar))/100);
				
				new String:pointcaptureaward[64];
				Format(pointcaptureaward,sizeof(pointcaptureaward),"%T","blocking point capture",client);
				W3GiveXPGold(client,XPAwardByFlagCap,addxp,0,pointcaptureaward);
			}
		}
	}
}

public TF_XP_teleported(Handle:event,const String:name[],bool:dontBroadcast)
{	
	//new teleported=GetClientOfUserId(GetEventInt(event,"userid"));

	new client=GetClientOfUserId(GetEventInt(event,"builderid"));
	new Float:distance=GetEventFloat(event,"dist");

	if(ValidPlayer(client) ){
		if( distance>=1000.0){
			new addxp=(W3GetKillXP(client)*GetConVarInt(TeleporterXPCvar))/100;		
			new String:buf[64];
			Format(buf,sizeof(buf),"teleport use");
			W3GiveXPGold(client,_,addxp,0,buf);
		}
		else{
			War3_ChatMessage(client,"Teleporter distance too short, 1000 minimum for XP. Current distance: %.2f",distance);
		}
	}
	
}
public TF_XP_player_extinguished(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"healer"));
	if(ValidPlayer(client)){
		new addxp=(W3GetKillXP(client)*GetConVarInt(ExtinguishXPCvar))/100;		
		new String:buf[64];
		Format(buf,sizeof(buf),"extinguishing fire");
		W3GiveXPGold(client,_,addxp,0,buf);
	}
	
}

