

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
public W3ONLY(){} //unload this?
new thisRaceID;

new Handle:ultCooldownCvar;

new Float:TeleportDistance[5]={0.0,300.0,350.0,400.0,450.0};


stock ULT_TELEPORT;


public Plugin:myinfo = 
{
	name = "Race - Twilight SPARKELLLLEEEE",
	author = "Ownz",
	description = "",
	version = "1.0",
	url = "http://war3source.com"
};

public OnPluginStart()
{
	
	ultCooldownCvar=CreateConVar("war3_twilight_teleport_cd","5.0","Cooldown between teleports");
	
//	LoadTranslations("w3s.race.human.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{

	
	if(num==240)
	{
	
		
		
		
		thisRaceID=War3_CreateNewRace("Twilight Sparkle (TEST)","twilight");
		
		
		new Handle:genericSkillOptions=CreateArray(5,2); //block size, 5 can store an array of 5 cells
		SetArrayArray(genericSkillOptions,0,TeleportDistance,sizeof(TeleportDistance));
		SetArrayCell(genericSkillOptions,1,ultCooldownCvar);
		//ULT_TELEPORT=
		War3_UseGenericSkill(thisRaceID,"g_teleport",genericSkillOptions,"TeleportTW","TeleportTWskilldesc");
		
		
		
		War3_CreateRaceEnd(thisRaceID);
		
	}
}
