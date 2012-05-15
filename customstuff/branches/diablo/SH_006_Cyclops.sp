/**
* File: War3Source_UndeadScourge.sp
* Description: The Undead Scourge race for War3Source.
* Author(s): Anthony Iacono 
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>


public SHONLY(){}

new count[66];
// War3Source stuff
new thisRaceID;
new BeamSprite,HaloSprite; 

public Plugin:myinfo = 
{
	name = "SH hero Cyclops",
	author = "Ownz",
	description = "SH Race",
	version = "1.0.0.0",
	url = "http://ownageclan.com"
};

// War3Source Functions

public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}
public OnPluginStart()
{
	
}
public OnSHLoadHeroOrItemOrdered(num)
{
	if(num==30)
	{
	
	
		
		thisRaceID=SHRegisterHero(
		"Cyclops",
		"Cyclops",
		"You can shot laser 3times",
		"You can shot laser 3times",
		true
		);
	}
}

public OnSHEventSpawn(client)
{
	//PrintToChatAll("SPAWN %d",client);

	if(SHHasHero(client,thisRaceID))
	{
		count[client]=0;
	}
}

public OnHeroChanged(client)
{
	if(!SHHasHero(client,thisRaceID))
	{
	}
	else
	{	
		if(IsPlayerAlive(client)){
			InitPassiveSkills(client);	
		}	
	}
}


public InitPassiveSkills(client){
	if(SHHasHero(client,thisRaceID))
	{
	}
}

public OnPowerCommand(client,herotarget,bool:pressed){
	//PrintToChatAll("%d",herotarget);
	if(SHHasHero(client,herotarget)&&herotarget==thisRaceID){
		new time=3;  // laser remain
		//PrintToChatAll("1");
		if(pressed && count[client]<time){
			new dmg=10; // laser damage
			new target = War3_GetTargetInViewCone(client,2000.0,false,23.0);
			new Float:pos[3];
			new Float:otherpos[3];
			if(target>0)
			{
				GetClientEyePosition(client,pos);
				GetClientEyePosition(target,otherpos);
				pos[2]-=30.0;
				otherpos[2]-=30.0;
				pos[1]-=10.0;
				otherpos[1]-=10.0;
				pos[0]-=10.0;
				otherpos[0]-=10.0;
				count[client]++;
				War3_DealDamage(target,dmg,client,DMG_ENERGYBEAM,"stormbolt");
				for(new i=0;i<30;i++)
				{
					TE_SetupBeamPoints(pos,otherpos,BeamSprite,HaloSprite,0,35,0.5,1.0,1.0,0,0.0,{255,0,0,255},700);
					TE_SendToAll();
				}
				PrintHintText(target,"Remain laser : %d times",time-count[client]);
				PrintHintText(target,"Attacked by Laser(Cyclops)");
			}
			else{
				PrintHintText(client,"Can't find enemy");
			}
		}
		if(count[client]>=time)
		{
			PrintHintText(client,"You already shot all laser");
		}
	}
}