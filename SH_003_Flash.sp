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
	name = "SH hero flash",
	author = "Ownz",
	description = "SH Race",
	version = "1.0.0.0",
	url = "http://ownageclan.com"
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
		"Flash",
		"flash",
		"You Run Faster",
		"You Run Faster",
		false
		);
	}
}

public OnWar3EventSpawn(client)
{
	//PrintToChatAll("SPAWN %d",client);

	if(SHHasHero(client,thisRaceID))
	{
		InitPassiveSkills(client); //sets suicide
	}
}

public OnRaceSelected(client)
{
	if(!SHHasHero(client,thisRaceID))
	{
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
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
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.25);
	}
}

///example only
/*
public OnPowerCommand(client,herotarget,bool:pressed){
	//PrintToChatAll("%d",herotarget);
	if(SHHasHero(client,herotarget)&&herotarget==thisRaceID){
		//PrintToChatAll("1");
		if(pressed){
			//PrintToChatAll("pressed");
		 	War3_SetBuff(client,fMaxSpeed,thisRaceID,9.0);
		}
		else{
			//PrintToChatAll("released");
			War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		}
	}
}
*/