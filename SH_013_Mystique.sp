#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

public SHONLY(){}

// War3Source stuff
new change[66];
new SKILL_CHANGE;
new thisRaceID;
public Plugin:myinfo = 
{
	name = "SH Hero Mystique",
	author = "GGHH3322",
	description = "SH Hero",
	version = "1.0.0.0",
	url = "http://war3source.com"
};

// War3Source Functions
public OnPluginStart()
{
}
public OnMapStart()
{
}

public OnSHLoadHeroOrItemOrdered(num)
{
	if(num==30)
	{
		
		thisRaceID=SHRegisterHero(
		"Mystique",
		"mystique",
		"Disguise like enemy",
		"Turn on/off press powerkey",
		true
		);
		
	}
}

public OnSHEventSpawn(client)
{
	if(!SHHasHero(client,thisRaceID))
	{
	}
	if(SHHasHero(client,thisRaceID))
	{
		change[client]=0;
		if(GetClientTeam(client)==3)
		{
			SetEntityModel(client, "models/player/ct_urban.mdl");
		}
		if(GetClientTeam(client)==2)
		{
			SetEntityModel(client, "models/player/t_leet.mdl");
		}	
	}
}

public OnPowerCommand(client,herotarget,bool:pressed){
	//PrintToChatAll("%d",herotarget);
	if(SHHasHero(client,herotarget)&&herotarget==thisRaceID){
		//PrintToChatAll("1");
		if(pressed && War3_SkillNotInCooldown(client,thisRaceID,SKILL_CHANGE,true)){
			if(GetClientTeam(client)==3)
			{
				if(change[client]==1){
					SetEntityModel(client, "models/player/ct_urban.mdl");
					change[client]=0;
					PrintHintText(client,"Disguise : Off");
				}
				else{
					SetEntityModel(client, "models/player/t_leet.mdl");
					change[client]=1;
					PrintHintText(client,"Disguise : On");
				}
			}
			if(GetClientTeam(client)==2)
			{
				if(change[client]==1){
					SetEntityModel(client, "models/player/t_leet.mdl");
					change[client]=0;
					PrintHintText(client,"Disguise : Off");
				}
				else{
					SetEntityModel(client, "models/player/ct_urban.mdl");
					change[client]=1;
					PrintHintText(client,"Disguise : On");
				}
			}				
			SH_CooldownMGR(client,10.0,thisRaceID,_,_);
		}
	}
}