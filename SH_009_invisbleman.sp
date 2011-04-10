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
new Float:NewPos[66][3];
new Float:OldPos[66][3];
new now[66];
new Float:temp;

public Plugin:myinfo = 
{
	name = "SH hero invisible man",
	author = "GGHH3322",
	description = "SH Race",
	version = "1.0.0.0",
	url = "war3source.com"
};

// War3Source Functions
public OnPluginStart()
{
	CreateTimer(1.0,Invisble,_,TIMER_REPEAT);	
}
public OnSHLoadHeroOrItemOrdered(num)
{
	if(num==40)
	{
	
	
		
		thisRaceID=SHRegisterHero(
		"Invisible Man",
		"invisibleman",
		"stop 5sec, you are 100% invisble ",
		"stop 5sec, you are 100% invisble ",
		false
		);
	}
}

public OnSHEventSpawn(client)
{
	//PrintToChatAll("SPAWN %d",client);

	if(SHHasHero(client,thisRaceID))
	{
		InitPassiveSkills(client); //sets suicide
	}
}

public OnHeroChanged(client)
{
	if(!SHHasHero(client,thisRaceID))
	{
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
	}
	else
	{	
		if(IsPlayerAlive(client)){
			InitPassiveSkills(client);
		}	
	}
}

public Action:Invisble(Handle:timer,any:userid)
{
	if(thisRaceID>0)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(SHHasHero(i,thisRaceID))
			{
				Invsing(i);
			}
		}
	}
}

public InitPassiveSkills(client){
	if(SHHasHero(client,thisRaceID))
	{
	}
}
public Invsing(client)
{
	new String:weapon[128];//weapon Char Array
	GetClientWeapon(client, weapon, 128);// Get client Weapon(Knife)
	GetClientAbsOrigin(client,NewPos[client]);
	if((NewPos[client][0]!=OldPos[client][0]) || (NewPos[client][1]!=OldPos[client][1]) || (NewPos[client][2]!=OldPos[client][2]))
	{
		now[client]=0;
		temp=(10-now[client])*0.1;
		SetWeaponColor(client,255,255,255,255);
	
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,temp);	
		if(now[client]<1)
		{
			PrintHintText(client,"You are not invisible Man.");
		}
	}
	else
	{
			if(now[client]>=7)
			{
				
				War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.0);
				PrintHintText(client,"You are completely invisible Man.");
				SetWeaponColor(client,255,255,255,0);
			}
			else{
				now[client]+=2;
				temp=now[client]*0.1;
				PrintHintText(client,"Your invisibility is : %.0f",temp*100);
				War3_SetBuff(client,fInvisibilitySkill,thisRaceID,temp);
			}
		}
		else{
			now[client]=0;
		}
	}
	OldPos[client][0]=NewPos[client][0];
	OldPos[client][1]=NewPos[client][1];
	OldPos[client][2]=NewPos[client][2];
}
public SetWeaponColor(client,r,g,b,o) 
{ 
    for(new i=0; i < 4; i++) 
    { 
        new entity = GetPlayerWeaponSlot(client,i); 
        if(entity != -1) 
        { 
            SetEntityRenderMode(entity,RENDER_TRANSCOLOR); 
            SetEntityRenderColor(entity,r,g,b,o); 
        } 
    }     
}  
public OnWeaponFired(client)
{	
	if(SH()){
		new String:weapon[128];//weapon Char Array
		GetClientWeapon(client, weapon, 128);// Get client Weapon(Knife)
		if(SHHasHero(client,thisRaceID))
		{
			now[client]=0;
			temp=(10-now[client])*0.1;
			
			War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0-temp);	
			if(now[client]<1)
			{
				PrintHintText(client,"You are not invisbleman. reason : attacked");
			}
		}
	}
}