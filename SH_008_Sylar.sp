
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
// War3Source stuff
new thisRaceID;
public Plugin:myinfo = 
{
	name = "SH hero Sylar",
	author = "GGHH3322",
	description = "SH Race",
	version = "1.0.0.0",
	url = "SHmod!"
};

// War3Source Functions

public OnMapStart()
{
}
public OnPluginStart()
{	
	HookEvent("player_death",PlayerDeathEvent);
}
public OnSHLoadHeroOrItemOrdered(num)
{
	if(num==0)
	{
	
	
		
		thisRaceID=SHRegisterHero(
		"Sylar",
		"sylar",
		"Stealing Powers",
		"When kill someone with headshot, Open enemy's head , get +enemymaxhp(50%)",
		false
		);
	}
}

public OnWar3EventSpawn(client)
{
	//PrintToChatAll("SPAWN %d",client);
	if(!SHHasHero(client,thisRaceID))
	{
	}
	if(SHHasHero(client,thisRaceID))
	{
	}
}

public OnRaceSelected(client)
{
	if(!SHHasHero(client,thisRaceID))
	{
	}
	else
	{	
		if(IsPlayerAlive(client)){
		}	
	}
}


public InitPassiveSkills(client){
	if(SHHasHero(client,thisRaceID))
	{
	}
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if (victim > 0)
	{
		new client = GetClientOfUserId(GetEventInt(event,"attacker"));
		if (client > 0 && client != victim)
		{
			if (SHHasHero(client,thisRaceID))
			{
				new bool:headshot;
				headshot = GetEventBool(event, "headshot");
				if(headshot)
				{
				new addHealth = RoundFloat(FloatMul(float(War3_GetMaxHP(victim)),0.50));
				War3_HealToMaxHP(client,addHealth);
				}		
			}
		}
	}
}
				