#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Race - Developer",
    author = "War3Source Team",
    description = "A testing race"
};

new thisRaceID;

new SKILL_DEVELOP;

public OnWar3LoadRaceOrItemOrdered(num)
{
    thisRaceID = War3_CreateNewRace("Developer", "develop");
    SKILL_DEVELOP = War3_AddRaceSkill(thisRaceID, "Develop", "DEVELOPERS", false, 1);
    War3_CreateRaceEnd(thisRaceID);
}

public OnUltimateCommand(client, race, bool:pressed)
{
    if(pressed && ValidPlayer(client, true) && War3_GetRace(client) == thisRaceID)
    {
        new regenAttribute = War3_GetAttributeIDByShortname("Regen");
        new buff = War3_ApplyTimedBuff(client, regenAttribute, 10.0, 3.0, BUFF_SKILL, SKILL_DEVELOP, BUFF_EXPIRES_ON_DEATH | BUFF_EXPIRES_ON_SPAWN | BUFF_EXPIRES_ON_TIMER, true);
        
        War3_ChatMessage(0, "Buff %i", buff);
    }
}
