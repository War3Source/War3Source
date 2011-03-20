/**
* File: War3Source_UndeadScourge.sp
* Description: The Undead Scourge race for War3Source.
* Author(s): Anthony Iacono 
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>


// War3Source stuff
new thisRaceID;


public Plugin:myinfo = 
{
	name = "SH Hero Leech",
	author = "Ownz",
	description = "SH Hero",
	version = "1.0.0.0",
	url = "http://war3source.com"
};

// War3Source Functions
public OnPluginStart()
{
	
}

public OnSHLoadHeroOrItemOrdered(num)
{
	if(num==30)
	{
		
		thisRaceID=SHRegisterHero(
		"Leech",
		"leech",
		"Gain HP when dealing damage",
		"Gain a percent of the damage dealt to enemies as health",
		false
		);
		
	}
}


public OnWar3EventPostHurt(victim,attacker,damage)
{
	if(ValidPlayer(victim)&&ValidPlayer(attacker,true)&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			if(SHHasHero(attacker,thisRaceID))
			{
					new Float:percent_health=0.25;
					new leechhealth=RoundToFloor(damage*percent_health);
					if(leechhealth>40) leechhealth=40; // woah, woah, woah, AWPs!
				
					PrintToConsole(attacker,"Leeched %d HP",leechhealth);
					W3FlashScreen(attacker,RGBA_COLOR_GREEN);	
					War3_HealToBuffHP(attacker,leechhealth);
			}
		}
	}
}    
public OnPowerCommand(client,herotarget,bool:pressed){
	if(herotarget==thisRaceID&&pressed){
		PrintToChatAll("power leech");
	}
}