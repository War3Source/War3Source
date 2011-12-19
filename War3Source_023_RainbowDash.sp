#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"  
//#include "W3SIncs/War3Source_Effects"

new thisRaceID;
public Plugin:myinfo = 
{
	name = "Race - Rainbow Dash",
	author = "OWNAGE",
	description = "",
	version = "1.0",
	url = "http://ownageclan.com/"
};

new SKILL_EVADE,SKILL_SWIFT,SKILL_SPEED,ULTIMATE;
public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==-230)
	{
		thisRaceID=War3_CreateNewRace("[MLP:FIM] Rainbow Dash","rainbowdash");
		SKILL_EVADE=War3_AddRaceSkill(thisRaceID,"Evasion","");
		SKILL_SWIFT=War3_AddRaceSkill(thisRaceID,"Swiftness","");
		SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Speed","");
		ULTIMATE=War3_AddRaceSkill(thisRaceID,"Sonic Rainboom","",true); 
		War3_CreateRaceEnd(thisRaceID); ///DO NOT FORGET THE END!!!
	}
}

public OnPluginStart()
{

}

public OnMapStart()
{

}
