/**
* File: War3Source_HumanAlliance.sp
* Description: The Human Alliance race for War3Source.
* Author(s): Anthony Iacono, necavi 
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
public W3ONLY(){} //unload this?
new thisRaceID;

new Handle:ultCooldownCvar;

// Chance/Info Arrays
new Float:BashChance[5]={0.0,0.07,0.13,0.19,0.25};
new Float:TeleportDistance[5]={0.0,600.0,700.0,850.0,1000.0};

new Float:InvisibilityAlphaTF[5]={1.0,0.84,0.68,0.56,0.40};

new Float:InvisibilityAlphaCS[5]={1.0,0.90,0.8,0.7,0.6};


new DevotionHealth[5]={0,15,25,35,45};


// Effects
new BeamSprite,HaloSprite;

new SKILL_INVIS, SKILL_BASH, SKILL_HEALTH,ULT_TELEPORT;

new String:teleportSound[]="war3source/blinkarrival.wav";

public Plugin:myinfo = 
{
	name = "Race - Human Alliance",
	author = "PimpinJuice, necavi",
	description = "The Human Alliance race for War3Source.",
	version = "1.0",
	url = "http://war3source.com"
};

public OnPluginStart()
{
	
	ultCooldownCvar=CreateConVar("war3_human_teleport_cooldown","20.0","Cooldown between teleports");
	
	LoadTranslations("w3s.race.human.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==20)
	{
		
		thisRaceID=War3_CreateNewRaceT("human");
		SKILL_INVIS=War3_AddRaceSkillT(thisRaceID,"Invisibility",false,4,"60% (CS), 40% (TF)");
		SKILL_HEALTH=War3_AddRaceSkillT(thisRaceID,"DevotionAura",false,4,"15/25/35/45");
		SKILL_BASH=War3_AddRaceSkillT(thisRaceID,"Bash",false,4,"7/13/19/25%","0.2");
		ULT_TELEPORT=War3_AddRaceSkillT(thisRaceID,"Teleport",true,4,"600/800/1000/1200");
		W3SkillCooldownOnSpawn(thisRaceID,ULT_TELEPORT,10.0,_);
		War3_CreateRaceEnd(thisRaceID);
		
	}
}

public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	
	War3_PrecacheSound(teleportSound);
	
	
	
	
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0); // if we aren't their race anymore we shouldn't be controlling their alpha
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
		War3_SetBuff(client,fBashChance,thisRaceID,0.0);
		
	}
	else
	{
		ActivateSkills(client);
		
	}
}

	
public ActivateSkills(client)
{
	new skill_devo=War3_GetSkillLevel(client,thisRaceID,SKILL_HEALTH);
	if(skill_devo)
	{
		// Devotion Aura
		new hpadd=DevotionHealth[skill_devo];
		new Float:vec[3];
		GetClientAbsOrigin(client,vec);
		vec[2]+=20.0;
		new ringColor[4]={0,0,0,0};
		new team=GetClientTeam(client);
		if(team==2)
		{
			ringColor={255,0,0,255};
		}
		else if(team==3)
		{
			ringColor={0,0,255,255};
		}
		TE_SetupBeamRingPoint(vec,40.0,10.0,BeamSprite,HaloSprite,0,15,1.0,15.0,0.0,ringColor,10,0);
		TE_SendToAll();
		
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,hpadd);
	}
	
	new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_INVIS);
	new Float:alpha=(War3_GetGame()==Game_CS)?InvisibilityAlphaCS[skilllevel]:InvisibilityAlphaTF[skilllevel];
	
	War3_SetBuff(client,fInvisibilitySkill,thisRaceID,alpha);
	
	new skill_bash=War3_GetSkillLevel(client,thisRaceID,SKILL_BASH);
	new Float:bash=BashChance[skill_bash];
	
	War3_SetBuff(client,fBashChance,thisRaceID,bash);
}
public OnUltimateCommand(client,race,bool:pressed)
{
	new userid=GetClientUserId(client);
	if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) && !Silenced(client))
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_TELEPORT);
		if(ult_level>0)
		{
			
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_TELEPORT,true)) //not in the 0.2 second delay when we check stuck via moving
			{
				new bool:success = War3_Teleport(client,TeleportDistance[ult_level]);
				if(success)
				{
					new Float:cooldown=GetConVarFloat(ultCooldownCvar);
					War3_CooldownMGR(client,cooldown,thisRaceID,ULT_TELEPORT,_,_);
				}
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
			
		}
	}
}



public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	if(race==thisRaceID)
	{
		ActivateSkills(client); //on a race change, this is called 4 times, but that performance hit is insignificant
	}
}

public OnWar3EventSpawn(client){
	if(War3_GetRace(client)==thisRaceID)
	{
		ActivateSkills(client);
	}
}
	