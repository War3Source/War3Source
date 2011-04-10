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
new BeamSprite,HaloSprite;

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
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}

public OnSHLoadHeroOrItemOrdered(num)
{
	if(num==30)
	{
		
		thisRaceID=SHRegisterHero(
		"Dracula",
		"dracula",
		"Leech",
		"Gain a percent of the damage dealt to enemies as health",
		false
		);
		
	}
}


public OnW3TakeDmgBullet(victim,attacker,Float:damage)
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
				
				PrintToConsole(attacker,"Leeched %d health",leechhealth);
				new Float:victim_pos[3];
				new Float:attacker_pos[3];
				GetClientAbsOrigin(victim,victim_pos);
				GetClientAbsOrigin(attacker,attacker_pos);
				War3_HealToBuffHP(attacker,leechhealth);
				victim_pos[2]+=30.0;
				attacker_pos[2]+=30.0;
				TE_SetupBeamPoints(attacker_pos,victim_pos,BeamSprite,HaloSprite,0,35,1.0,7.5,7.5,0,4.0,{180,20,20,225},40);
				TE_SendToAll();
				attacker_pos[0]+=20;
				TE_SetupBeamPoints(attacker_pos,victim_pos,BeamSprite,HaloSprite,0,35,1.0,7.5,7.5,0,4.0,{180,20,20,225},40);
				TE_SendToAll();
				attacker_pos[0]-=40;
				TE_SetupBeamPoints(attacker_pos,victim_pos,BeamSprite,HaloSprite,0,35,1.0,7.5,7.5,0,4.0,{180,20,20,225},40);
				TE_SendToAll();
				TE_SetupBeamRingPoint(victim_pos,1.0,500.0,BeamSprite,HaloSprite,0,15,0.5,200.0,0.5,{180,20,20,185},1,0);
				TE_SendToAll();
			}
		}
	}
}   