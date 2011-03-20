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
	name = "SH hero Captain America",
	author = "GGHH3322",
	description = "SH Race",
	version = "1.0.0.0",
	url = "not"
};

// War3Source Functions
public OnPluginStart()
{
}
public OnSHLoadHeroOrItemOrdered(num)
{
	if(num==40)
	{
	
	
		
		thisRaceID=SHRegisterHero(
		"Captain America",
		"Captain America",
		"30% Evade",
		"30% Evade",
		false
		);
	}
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			//evade
			if(SHHasHero(victim,thisRaceID)) 
			{
				if(GetRandomFloat(0.0,1.0)<=0.3)
				{
					PrintHintText(attacker,"Enemy Evade Bullet");
					PrintHintText(victim,"You Evade Bullet");
					W3FlashScreen(victim,RGBA_COLOR_BLUE);
					War3_DamageModPercent(0.0); //NO DAMAMGE		
				}
			}
		}
	}
}

public OnWar3EventSpawn(client)
{
	//PrintToChatAll("SPAWN %d",client);

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
	}
}