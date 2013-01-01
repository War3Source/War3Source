#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "War3Source - Race - Undead Scourge",
	author = "War3Source Team",
	description = "The Undead Scourge race for War3Source",
};

// War3Source stuff
new thisRaceID;


// Chance/Data Arrays
new Float:SuicideBomberRadius[5]={0.0,250.0,290.0,310.0,333.0}; 

new Float:SuicideBomberDamage[5]={0.0,166.0,200.0,233.0,266.0};
new Float:SuicideBomberDamageTF[5]={0.0,133.0,175.0,250.0,300.0}; 

new Float:UnholySpeed[5]={1.0,1.05,1.10,1.15,1.20};
new Float:LevitationGravity[5]={1.0,0.85,0.7,0.6,0.5};
new Float:VampirePercent[5]={0.0,0.08,0.14,0.20,0.25};

new SKILL_LEECH,SKILL_SPEED,SKILL_LOWGRAV,SKILL_SUICIDE;

// War3Source Functions
public OnPluginStart()
{
	LoadTranslations("w3s.race.undead.phrases");
}
public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==10)
	{
		thisRaceID=War3_CreateNewRaceT("undead");
		SKILL_LEECH=War3_AddRaceSkillT(thisRaceID,"VampiricAura",false,4,"25%");
		SKILL_SPEED=War3_AddRaceSkillT(thisRaceID,"UnholyAura",false,4,"20%");
		SKILL_LOWGRAV=War3_AddRaceSkillT(thisRaceID,"Levitation",false,4,"0.5");
		SKILL_SUICIDE=War3_AddRaceSkillT(thisRaceID,"SuicideBomber",true,4); 
		
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnMapStart()
{
	
}


public OnUltimateCommand(client,race,bool:pressed)
{
	if(pressed && War3_GetRace(client)==thisRaceID && IsPlayerAlive(client) && !Silenced(client))
	{
		new ult_level=War3_GetSkillLevel(client,race,SKILL_SUICIDE);
		if(ult_level>0)
		{
			ForcePlayerSuicide(client);
		}
		else 
		{
		//DP("undad ");
			W3MsgUltNotLeveled(client);
		}
	}
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	InitPassiveSkills(client);
}
public InitPassiveSkills(client){
	if(War3_GetRace(client)==thisRaceID)
	{
		new skilllevel_unholy=War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
		new Float:speed=UnholySpeed[skilllevel_unholy];
		War3_SetBuff(client,fMaxSpeed,thisRaceID,speed);
		
		new skilllevel_levi=War3_GetSkillLevel(client,thisRaceID,SKILL_LOWGRAV);
		new Float:gravity=LevitationGravity[skilllevel_levi];
		War3_SetBuff(client,fLowGravitySkill,thisRaceID,gravity);
		
		new skilllevel_vampire=War3_GetSkillLevel(client,thisRaceID,SKILL_LEECH);
		new Float:percent=VampirePercent[skilllevel_vampire];
		War3_SetBuff(client,fVampirePercent,thisRaceID,percent);
		
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		War3_SetBuff(client, fMaxSpeed, thisRaceID, 1.0);
		War3_SetBuff(client, fLowGravitySkill, thisRaceID, 1.0);
		War3_SetBuff(client, fVampirePercent, thisRaceID, 0.0);
	}
	else
	{	
		if(IsPlayerAlive(client)){
			InitPassiveSkills(client);
			
		}	
	}
}

public OnWar3EventDeath(victim, attacker)
{
	new race=W3GetVar(DeathRace);
	new skill=War3_GetSkillLevel(victim,thisRaceID,SKILL_SUICIDE);
	if(race==thisRaceID && skill>0 && !Hexed(victim))
	{
		decl Float:location[3];
		GetClientAbsOrigin(victim,location);
		if(War3_GetGame()==Game_TF)
		{
			War3_SuicideBomber(victim, location, SuicideBomberDamageTF[skill], SKILL_SUICIDE, SuicideBomberRadius[skill]);
		} else {
			War3_SuicideBomber(victim, location, SuicideBomberDamage[skill], SKILL_SUICIDE, SuicideBomberRadius[skill]);
		}
		
	} 
}

public OnWar3EventSpawn(client)
{
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		InitPassiveSkills(client); //sets suicide
		
	}
}
