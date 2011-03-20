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
new BurnSprite,HaloSprite;
new shots[66];

public Plugin:myinfo = 
{
	name = "SH hero Human Torch",
	author = "Ownz",
	description = "SH Race",
	version = "1.0.0.0",
	url = "http://ownageclan.com"
};

// War3Source Functions
public OnPluginStart()
{
	
}
public OnMapStart()
{
	BurnSprite=PrecacheModel("materials/sprites/fire1.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}

public OnSHLoadHeroOrItemOrdered(num)
{
	if(num==30)
	{
		
		
		
		thisRaceID=SHRegisterHero(
		"Human Torch",
		"Torch",
		"You shoot out fire",
		"You shoot out fire",
		true
		);
	}
}
public OnWar3EventSpawn(client)
{
	//PrintToChatAll("SPAWN %d",client);
	
	if(SHHasHero(client,thisRaceID))
	{
		shots[client]=0;
	}
}

public OnPowerCommand(client,herotarget,bool:pressed){
	//PrintToChatAll("%d",herotarget);
	if(SHHasHero(client,herotarget)&&herotarget==thisRaceID){
		//PrintToChatAll("1");
		new time=10; 
		if(pressed && shots[client]<time){
			new Float:pos[3];
			GetClientAbsOrigin(client,pos);
			pos[2]+=30;
			new target = War3_GetTargetInViewCone(client,9999.0,false,5.0);
			if(target>0)
			{
				new Float:targpos[3];
				GetClientAbsOrigin(target,targpos);
				TE_SetupBeamPoints(pos, targpos, BurnSprite, BurnSprite, 0, 8, 0.5, 10.0, 10.0, 10, 10.0, {255,255,255,255}, 70); 
				TE_SendToAll();
				IgniteEntity(target,3);
				targpos[2]+=50;
				TE_SetupGlowSprite(targpos,BurnSprite,1.0,1.9,255);
				TE_SendToAll();
				shots[client]++;
				PrintHintText(target,"You have %d bursts of fire remaining",time-shots[client]);
				//sprites/640_logo.vmt server_var(wcs_x1) server_var(wcs_y1) server_var(wcs_z1) server_var(wcs_x2) server_var(wcs_y2) server_var(wcs_z2) 1 2 2 255 225 255 255
			}
			else
			{
				new Float:targpos[3];
				War3_GetAimEndPoint(client,targpos);
				shots[client]++;
				TE_SetupBeamPoints(pos, targpos, BurnSprite, BurnSprite, 0, 8, 0.5, 10.0, 10.0, 10, 10.0, {255,255,255,255}, 70); 
				TE_SendToAll();
				targpos[2]+=50;
				TE_SetupGlowSprite(targpos,BurnSprite,1.0,1.9,255);
				TE_SendToAll();
			}
		}
	}
}

