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
new BeamSprite;

public Plugin:myinfo = 
{
	name = "SH Hero Dracula",
	author = "Ownz",
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
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
}

public OnSHLoadHeroOrItemOrdered(num)
{
	if(num==30)
	{
		
		thisRaceID=SHRegisterHero(
		"Dracula",
		"leech",
		"Suck some of your victims blood draining their health",
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
				
					PrintToConsole(attacker,"%T","Leeched",attacker,leechhealth);
					new Float:victimoriginp[3];
					new Float:attackeroriginp[3];
					GetClientAbsOrigin(victim,victimoriginp);
					GetClientAbsOrigin(attacker,attackeroriginp);
					attackeroriginp[2]+=15.0;
					victimoriginp[2]+=15.0;
					TE_SetupBeamPoints(attackeroriginp,victimoriginp,BeamSprite,0,0,0,0.75,1.5,2.0,10,4.0,{238,44,44,255},20);
					TE_SendToAll();	
					War3_HealToBuffHP(attacker,leechhealth);
			}
		}
	}
}    