
#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include "W3SIncs/War3Source_Interface"  


new thisRaceID;
public Plugin:myinfo = 
{
	name = "Race - Fluttershy",
	author = "OwnageOwnz - RainbowDash", 
	description = "",
	version = "0",
	url = "ownageclan.com"
};
public LoadCheck(){
	return GameTF();
}

new SKILL_STARE,SKILL_TOLERATE,SKILL_KINDNESS,ULTIMATE_YOUBEGENTLE;
new AuraID;

new Float:starerange=300.0;
new Float:StareDuration[5]={0.0,1.5,2.0,2.5,3.0};
new Float:ArmorPhysical[5]={0.0,0.5,1.0,1.5,2.0};
new Float:HealAmount[5]={0.0,0.5,1.0,1.5,2.0};


new Float:NotBadDuration[5]={0.0,1.0,1.3,1.6,1.8};
new bNoDamage[MAXPLAYERSCUSTOM];
public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==210)
	{
		/////DO NOT TRANSLATE
		thisRaceID=War3_CreateNewRace("[MLP:FIM] Fluttershy","fluttershy");
		SKILL_STARE=War3_AddRaceSkill(thisRaceID,"Stare Master","stare at target, 300 range, disarms and immobilizes you and target for 1.5-3 seconds");
		SKILL_TOLERATE=War3_AddRaceSkill(thisRaceID,"Tolerate","To 2 physical armor"); 
		SKILL_KINDNESS=War3_AddRaceSkill(thisRaceID,"Kindness","Global heal up to 2 hp /s"); 
		ULTIMATE_YOUBEGENTLE=War3_AddRaceSkill(thisRaceID,"Be Gentle","target cannot deal damage for 1-1.8 seconds",true); 
		War3_CreateRaceEnd(thisRaceID); ///DO NOT FORGET THE END!!!
		
		AuraID=W3RegisterAura("fluttershy_healwave",999999.9);
	}
}

public OnPluginStart()
{
	
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true) )
	{
		new ult_level=War3_GetSkillLevel(client,race,ULTIMATE_YOUBEGENTLE);
		if(ult_level>0)
		{
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULTIMATE_YOUBEGENTLE,true))
			{
				new Float:breathrange=0.0;
				//War3_GetTargetInViewCone(client,Float:max_distance=0.0,bool:include_friendlys=false,Float:cone_angle=23.0,Function:FilterFunction=INVALID_FUNCTION);
				new target = War3_GetTargetInViewCone(client,breathrange,false,23.0,UltFilter);
				//new Float:duration = DarkorbDuration[ult_level];
				if(target>0)
				{
					bNoDamage[target]=true;
					CreateTimer(NotBadDuration[ult_level],EndNotBad,target);
					PrintHintText(client,"You be gentle!");
					PrintHintText(target,"You be gentle!\nCannot deal bullet damage");
					War3_CooldownMGR(client,20.0,thisRaceID,ULTIMATE_YOUBEGENTLE);
				}
				else{
					W3MsgNoTargetFound(client,breathrange);
				}
			}
		}	
	}			
}
public Action:EndNotBad(Handle:t,any:client){
	bNoDamage[client]=false;
}
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage){
	if(ValidPlayer(attacker)&&bNoDamage[attacker]){
		War3_DamageModPercent(0.0);
	}
} 

new Handle:StareEndTimer[MAXPLAYERSCUSTOM]; //invalid handle by default
new StareVictim[MAXPLAYERSCUSTOM];

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client,true),War3_GetRace(client)==thisRaceID && ability==0 && pressed )
	{
		if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_STARE,true))
		{
			new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_STARE);
			if(skilllvl > 0)
			{
				//stare
				new target=War3_GetTargetInViewCone(client,starerange,_,_,SkillFilter);
				if(ValidPlayer(target,true)){
					////
					//bash both players
					War3_SetBuff(client,bBashed,thisRaceID,true);
					War3_SetBuff(client,bDisarm,thisRaceID,true);
					War3_SetBuff(target,bBashed,thisRaceID,true);
					War3_SetBuff(target,bDisarm,thisRaceID,true);
					PrintHintText(client,"STOP AND STARE");
					PrintHintText(target,"You are being stared at.\nDon't look at her in the eye!!!");
					StareEndTimer[client]=CreateTimer(StareDuration[skilllvl],EndStare,client);
					StareVictim[client]=target;
					War3_CooldownMGR(client,15.0,thisRaceID,SKILL_STARE);
				}
				else{	
					W3MsgNoTargetFound(client,starerange);
				}
			}
		}
	}
}
public Action:EndStare(Handle:t,any:client){
	War3_SetBuff(client,bBashed,thisRaceID,false);
	War3_SetBuff(client,bDisarm,thisRaceID,false);
	War3_SetBuff(StareVictim[client],bBashed,thisRaceID,false);
	War3_SetBuff(StareVictim[client],bDisarm,thisRaceID,false);
	StareVictim[client]=0;
	StareEndTimer[client]=INVALID_HANDLE;
}
public OnWar3EventDeath(client){ //end stare if fluttershy dies
	if(StareEndTimer[client]){
		TriggerTimer(StareEndTimer[client]);
		StareEndTimer[client]=INVALID_HANDLE;
	}
}



public OnWar3EventSpawn(client){
	InitPassiveSkills(client);
}
public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	if(race==thisRaceID &&ValidPlayer(client,true)){
		InitPassiveSkills(client);
	}
}
InitPassiveSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{

		new level=War3_GetSkillLevel(client,thisRaceID,SKILL_TOLERATE);
		War3_SetBuff(client,fArmorPhysical,thisRaceID,ArmorPhysical[level]);
		
		level=War3_GetSkillLevel(client,thisRaceID,SKILL_KINDNESS);
		W3SetAuraFromPlayer(AuraID,client,level>0?true:false,level);
		
		
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace==thisRaceID)
	{	
		InitPassiveSkills(client);
		
	}
	else if(oldrace==thisRaceID)
	{
	
		War3_SetBuff(client,fArmorPhysical,thisRaceID,0);
		W3SetAuraFromPlayer(AuraID,client,false,0);
		
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