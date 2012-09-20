/* ========================================================================== */
/*                                                                            */
/*   War3source_001_Vanilla.sp                                              */
/*   (c) 2012 El Diablo                                                       */
/*                                                                            */
/*   Description  A Race for developers whom want to test vanilla             */
/*                players (players without any modifications) vs              */
/*                what ever race they wish to go against.                     */
/* ========================================================================== */
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
public W3ONLY(){} //unload this?

// War3Source stuff
new thisRaceID;

new SKILL_REVIVE, ABILITY_BLIND, SKILL_UNHOLY, ABILITY_FAN, ULT_SOULSWAP;

public Plugin:myinfo =
{
	name = "Race - Vanilla",
	author = "El Diablo",
	description = "A Race without Nothing. Skills mean nothing.",
	version = "1.0.0.0",
	url = "http://Www.war3source.Com"
};
public OnPluginStart()
{
	// To do: add translations
	//LoadTranslations("w3s.race.mage.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==1)
	{
		thisRaceID=War3_CreateNewRace("Vanilla","vanilla");
		SKILL_REVIVE=War3_AddRaceSkill(thisRaceID,"No skill 1",
		"No Skill info",false,1);
		SKILL_UNHOLY=War3_AddRaceSkill(thisRaceID,"No skill 2",
		"No Skill info 2",false,1);
		ABILITY_FAN=War3_AddRaceSkill(thisRaceID,"No Skill 3",
		"No skill info 3",false,1);
		ABILITY_BLIND=War3_AddRaceSkill(thisRaceID,"No Skill 4",
		"No Skill info 4",false,1);
		ULT_SOULSWAP=War3_AddRaceSkill(thisRaceID,"No Ultimate",
		"No Ultimate info",true,1);
		W3SkillCooldownOnSpawn(thisRaceID,ULT_SOULSWAP,10.0,_);
		W3SkillCooldownOnSpawn(thisRaceID,ABILITY_BLIND,10.0,_);
		W3SkillCooldownOnSpawn(thisRaceID,SKILL_UNHOLY,10.0,_);
		W3SkillCooldownOnSpawn(thisRaceID,ABILITY_FAN,10.0,_);
		War3_CreateRaceEnd(thisRaceID);
		//thisAuraID=W3RegisterAura("UnholyAura",UnholyRange,true);
		War3_SetDependency(thisRaceID, ULT_SOULSWAP, SKILL_REVIVE, 1);
	}

}

public OnMapStart()
{
//
}
/* ***************************  OnRaceChanged *************************************/

public OnRaceChanged(client,oldrace,newrace)
{
    if(newrace==thisRaceID)
    {
       InitPassiveSkills(client);
    }
    else
    {
        RemovePassiveSkills(client);
    }
}
/* ****************************** OnSkillLevelChanged ************************** */

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    InitPassiveSkills(client);
}

public InitPassiveSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
	//nothing
	}

}

/* ****************************** RemovePassiveSkills ************************** */

public RemovePassiveSkills(client)
{
// nothing
}
