

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
public W3ONLY(){} //unload this?
new thisRaceID;

new Handle:ultCooldownCvar;

new Float:TeleportDistance[5]={0.0,300.0,350.0,400.0,450.0};

new SKILL_HEALINGWAVE;
stock ULT_TELEPORT;
new Float:HealingWaveDistance=100.0;
new Float:HealAmount[5]={0.0,2.0,4.0,6.0,8.0};
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
		SKILL_HEALINGWAVE=War3_AddRaceSkill(thisRaceID,"Friendship is Witchcraft","Heals you and your teammates when you are very close to them, up to 8HP/s");
		War3_CreateRaceEnd(thisRaceID);
		AuraID=W3RegisterAura("twilight_healwave",HealingWaveDistance);
	}
}


public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	if(race==thisRaceID &&skill==SKILL_HEALINGWAVE) //1
	{
			W3SetAuraFromPlayer(AuraID,client,newskilllevel>0?true:false,newskilllevel);
	}
}

public OnW3PlayerAuraStateChanged(client,aura,bool:inAura,level)
{
	if(aura==AuraID&&inAura==false) //lost aura, remove helaing
	{
		War3_SetBuff(client,fHPRegen,thisRaceID,0.0);
		//DP("%d %f",inAura,HealingWaveAmountArr[level]);
	}
}
public OnWar3Event(W3EVENT:event,client){
	if(event==OnAuraCalculationFinished){
		RecalculateHealing();
	//	DP("re");
	}
}
RecalculateHealing(){
	new level;
	new playerlist[66];
	new auralevel[66];
	new auraactivated[66];
	new playercount=0;

	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true)&&W3HasAura(AuraID,client,level)){
			for(new i=0;i<playercount;i++){
				if(GetPlayerDistance(playerlist[i],client)<HealingWaveDistance){
					auraactivated[playercount]++;
					auraactivated[i]++;
				}
			}
			
			playerlist[playercount]=client;
			auralevel[playercount]=level;
			playercount++;
		}
	
	}
	for(new i=0;i<playercount;i++){
		if(auraactivated[i]){
			//DP("client %d %f",playerlist[i],HealAmount[auralevel[i]]);
			War3_SetBuff(playerlist[i],fHPRegen,thisRaceID,HealAmount[auralevel[i]]);
		}
		else{
			//DP("client %d disabled due to no neighbords",playerlist[i]);
			War3_SetBuff(playerlist[i],fHPRegen,thisRaceID,0.0);
		}
	}
}
