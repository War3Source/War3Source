/**
* File: War3Source_NightElf.sp
* Description: The Night Elf race for War3Source.
* Author(s): Anthony Iacono 
*/
 
#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>

public W3ONLY(){} //unload this?

new thisRaceID;


new Handle:UltCooldownCvar; // cooldown

//new Handle:hWeaponDrop;


new SKILL_INVIS, SKILL_TRUESIGHT, SKILL_DISARM, ULT_MARKSMAN;

// Chance/Data Arrays
new Float:InvisDrain=4.0;
new Float:InvisDuration[5]={0.0,5.0,6.0,7.0,8.0};

new Float:EyeRadius[5]={0.0,400.0,550.0,700.0,850.0};

new Float:DisarmChance[5]={0.0,0.06,0.10,0.13,0.15};
new Float:MarksmanCrit[5]={0.0,0.15,0.3,0.45,0.6};
new const STANDSTILLREQ=10;


new bool:bDisarmed[MAXPLAYERSCUSTOM];
new Float:lastvec[MAXPLAYERSCUSTOM][3];
new standStillCount[MAXPLAYERSCUSTOM];

// Effects
new BeamSprite,HaloSprite;
 
public Plugin:myinfo = 
{
	name = "Race - Night Elf",
	author = "PimpinJuice",
	description = "The Night Elf race for War3Source.",
	version = "1.0.0.0",
	url = "http://pimpinjuice.net/"
};

public OnPluginStart()
{
	

	UltCooldownCvar=CreateConVar("war3_scout_ult_cooldown","20","Cooldown timer.");
	
	LoadTranslations("w3s.race.scout.phrases");
}

public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==40)
	{
		thisRaceID=War3_CreateNewRaceT("scout");
		SKILL_INVIS=War3_AddRaceSkillT(thisRaceID,"Vanish",false,4,"to be determined");
		SKILL_TRUESIGHT=War3_AddRaceSkillT(thisRaceID,"TrueSight",false,4,"300/500/700/900");
		SKILL_DISARM=War3_AddRaceSkillT(thisRaceID,"Disarm",false,4,"to be determined");
		ULT_MARKSMAN=War3_AddRaceSkillT(thisRaceID,"Marksman",true,4,"to be determined"); 
	
		War3_CreateRaceEnd(thisRaceID);
		ServerCommand("war3 scout_flags hidden");
	}
}



public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim)&&ValidPlayer(attacker))
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			if(War3_GetRace(attacker)==thisRaceID && !W3HasImmunity(victim,Immunity_Skills)){
				new lvl=War3_GetSkillLevel(attacker,thisRaceID,ULT_MARKSMAN);
				if(lvl>0&& standStillCount[attacker]>=STANDSTILLREQ){ //stood still for 1 second
					new Float:vicpos[3];
					new Float:attpos[3];
					GetClientAbsOrigin(victim,vicpos);
					GetClientAbsOrigin(attacker,attpos);
					new Float:distance=GetVectorDistance(vicpos,attpos);
					
					if(distance>1000.0){ //0-512 normal damage 512-1024 linear increase, 1024-> maximum
						distance=1000.0;
						new Float:multi=distance*MarksmanCrit[lvl]/1000.0;
						War3_DamageModPercent(multi+1.0);
						PrintToConsole(attacker,"[W3S] %.2fX dmg by marksman shot");
					}
				}
			}
		}
	}
}


public OnWar3EventPostHurt(victim,attacker,damage){
	if(W3GetDamageIsBullet()&&ValidPlayer(victim,true)&&ValidPlayer(attacker,true)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_DISARM);
			if(skill_level>0&&!Hexed(attacker,false))
			{
				if(!W3HasImmunity(victim,Immunity_Skills)){
				
					if(  W3Chance(DisarmChance[skill_level]*W3ChanceModifier(attacker))  ){
						War3_SetBuff(victim,bDisarm,thisRaceID,true);
						CreateTimer(0.5,Undisarm,victim);
					}
				}
			}
		}
	}		
}
public Action:Undisarm(Handle:t,any:client){
	War3_SetBuff(client,bDisarm,thisRaceID,false);
}


public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && IsPlayerAlive(client) && pressed)
	{
		new skill_level=War3_GetSkillLevel(client,race,SKILL_EYE);
		if(skill_level>0)
		{
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_TRUESIGHT,true)){
				
				
			}
		}
		else
		{
			//print no eyes availabel
		}
	}
}

