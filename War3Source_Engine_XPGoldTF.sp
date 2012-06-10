

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
new Handle:TeleporterDistanceXPCvar;
new Handle:ExtinguishXPCvar;

new Handle:DestroyedTeleXPCvar;
new Handle:DestroyedDispenserXPCvar;
new Handle:DestroyedSentryXPCvar;
new Handle:DestroyedSapperXPCvar;

public OnPluginStart()
{
	
	if(W3()){
		
		PointCaptureXPCvar=CreateConVar("war3_percent_tf_pointcapturexp","25","Percent of kill XP awarded to the capturing team");
		PointCapBlockXPCvar=CreateConVar("war3_percent_tf_blockcapturexp","20","Percent of kill XP awarded for blocking a capture");
		CaptureFlagXPCvar=CreateConVar("war3_percent_tf_flagcapturexp","100","Percent of kill XP awarded for capturing the flag");
		TeleporterXPCvar=CreateConVar("war3_percent_tf_teleporterxp","10","Percent of kill XP awarded");
		TeleporterDistanceXPCvar=CreateConVar("war3_tf_teleporter_distance","1000.0","Distance to teleport before awarding XP");
		ExtinguishXPCvar=CreateConVar("war3_percent_tf_extinguishxp","10","Percent of kill XP awarded");
		
		DestroyedTeleXPCvar = CreateConVar("war3_percent_tf_telexp","25","Percent of kill XP awarded");
		DestroyedDispenserXPCvar = CreateConVar("war3_percent_tf_dispenserxp","50","Percent of kill XP awarded");
		DestroyedSentryXPCvar = CreateConVar("war3_percent_tf_sentryxp","125","Percent of kill XP awarded");
		DestroyedSapperXPCvar = CreateConVar("war3_percent_tf_sentryxp","10","Percent of kill XP awarded");
		
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
			if(!HookEventEx("object_destroyed", War3Source_ObjectDestroyedEvent))
			{
				PrintToServer("[War3Source] Could not hook the object_destroyed event.");
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
	new teleported=GetClientOfUserId(GetEventInt(event,"userid"));
	new client=GetClientOfUserId(GetEventInt(event,"builderid"));
	new Float:distance=GetEventFloat(event,"dist");

	if(ValidPlayer(client) && (teleported != client) ){
		if( distance>=GetConVarFloat(TeleporterDistanceXPCvar)){
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

public War3Source_ObjectDestroyedEvent(Handle:event, const String:name[], bool:dontBroadcast)
{

	/*short	 userid	 user ID who died
	short	 attacker	 user ID who killed
	short	 assister	 user ID of assister
	string	 weapon	 weapon name killer used
	short	 weaponid	 id of the weapon used
	short	 objecttype	 type of object destroyed
	short	 index	 index of the object destroyed
	bool	 was_building	 object was being built when it died*/
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	new objecttype = GetEventInt(event, "objecttype");
	
	//decl String:weapon[64];
	//GetEventString(event, "weapon", weapon, sizeof(weapon));
	new bool:was_building = GetEventBool(event, "was_building");
	new Float:modifier = 1.0;
	
	if (was_building == true)
	{
		modifier = 0.5;
	}
	
	if(objecttype == 0) 
	{
		if (ValidPlayer(attacker))
		{
			new addxp = RoundToCeil((W3GetKillXP(attacker) * GetConVarInt(DestroyedDispenserXPCvar)) / 100 * modifier);
			W3GiveXPGold(attacker, _, addxp, 0, "Destroying a Dispenser");
		}
		
		if (ValidPlayer(assister))
		{
			new addxp = RoundToCeil((W3GetKillXP(attacker) * GetConVarInt(DestroyedDispenserXPCvar)) / 100 * modifier);
			W3GiveXPGold(assister, _, addxp, 0, "Assisting in destroying a Dispenser");
		}
		
	}
	else if(objecttype == 1) 
	{
		if (ValidPlayer(attacker))
		{
			new addxp = RoundToCeil((W3GetKillXP(attacker) * GetConVarInt(DestroyedTeleXPCvar)) / 100 * modifier);
			W3GiveXPGold(attacker, _, addxp, 0, "Destroying a Teleporter");
		}
		
		if (ValidPlayer(assister))
		{
			new addxp = RoundToCeil((W3GetKillXP(attacker) * GetConVarInt(DestroyedTeleXPCvar)) / 100 * modifier);
			W3GiveXPGold(assister, _, addxp, 0, "Assisting in destroying a Teleporter");
		}
	}
	else if(objecttype == 2) 
	{
		if (ValidPlayer(attacker))
		{
			new addxp = RoundToCeil((W3GetKillXP(attacker) * GetConVarInt(DestroyedSentryXPCvar)) / 100 * modifier);
			W3GiveXPGold(attacker, _, addxp, 0, "Destroying a Sentry");
		}
		
		if (ValidPlayer(assister))
		{
			new addxp = RoundToCeil((W3GetKillXP(attacker) * GetConVarInt(DestroyedSentryXPCvar)) / 100 * modifier);
			W3GiveXPGold(assister, _, addxp, 0, "Assisting in destroying a Sentry");
		}
	}
	else if(objecttype == 3) 
		{
			if (ValidPlayer(attacker))
			{
				new addxp = RoundToCeil((W3GetKillXP(attacker) * GetConVarInt(DestroyedSapperXPCvar)) / 100 * modifier);
				W3GiveXPGold(attacker, _, addxp, 0, "Destroying a Sapper");
			}
			
			if (ValidPlayer(assister))
			{
				new addxp = RoundToCeil((W3GetKillXP(attacker) * GetConVarInt(DestroyedSapperXPCvar)) / 100 * modifier);
				W3GiveXPGold(assister, _, addxp, 0, "Assisting in destroying a Sapper");
			}
		}
}