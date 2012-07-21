

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
public W3ONLY(){} //unload this?
new thisRaceID;

new Handle:ultCooldownCvar;

new Float:TeleportDistance[5]={0.0,300.0,350.0,400.0,450.0};

new SKILL_HEAL;
stock ULT_TELEPORT;

new Float:HealAmount[5]={0.0,0.5,1.0,1.5,2.0};
new AuraID;
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
		
		SKILL_HEAL=War3_AddRaceSkill(thisRaceID,"Connected","Global heal 2hp per second",false,4); 
		War3_CreateRaceEnd(thisRaceID);
		AuraID=W3RegisterAura("fluttershy_healwave",999999.9);
	}
}
public OnW3PlayerAuraStateChanged(client,aura,bool:inAura,level)
{
	if(aura==AuraID)
	{
		War3_SetBuff(client,fHPRegen,thisRaceID,inAura?HealAmount[level]:0.0);
		//DP("%d %f",inAura,HealingWaveAmountArr[level]);
	}
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{	

	if(race==thisRaceID &&skill==SKILL_HEAL) //1
	{
			W3SetAuraFromPlayer(AuraID,client,newskilllevel>0?true:false,newskilllevel);
	}
}
