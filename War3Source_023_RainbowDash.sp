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

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==230)
	{
		thisRaceID=War3_CreateNewRace("[MLP:FIM] Rainbow Dash","rainbowdash");
		SKILL_SMITTEN=War3_AddRaceSkill(thisRaceID,"Smitten","");
		SKILL_HEARTACHE=War3_AddRaceSkill(thisRaceID,"Heartache","");
		SKILL_SLEEP=War3_AddRaceSkill(thisRaceID,"Mesmerize","");
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
public OnWar3EventSpawn(client){
	bSmittened[client]=false;
}



public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim)&&ValidPlayer(attacker)&&attacker!=victim &&GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		if(bSmittened[attacker]){
			War3_DamageModPercent(SmittendMultiplier[victim]);
		}
		if(War3_GetRace(attacker)==thisRaceID ){
			new lvl = War3_GetSkillLevel(attacker,thisRaceID,SKILL_SMITTEN);
			if(lvl > 0)
			{
				if(!IsSkillImmune(victim)){
					if(!Hexed(attacker)&&War3_SkillNotInCooldown(attacker,thisRaceID,SKILL_SMITTEN,false))
					{
						bSmittened[victim]=true;
						SmittendMultiplier[victim]=smittenMultiplier[lvl];
						
						CreateTimer(smittenDuration,UnSmitten,victim);
						War3_CooldownMGR(attacker,smittenCooldown,thisRaceID,SKILL_SMITTEN);
						W3Hint(victim,_,_,"You have been Smittened, you do less damage");
						W3Hint(attacker,_,_,"Activated Smitten");
					}
					
				}
			}
		}
	}
	
	///need to do sleep transfer
}

public Action:UnSmitten(Handle:timer,any:client)
{
	bSmittened[client]=false;
}






public OnWar3EventPostHurt(victim,attacker,dmgamount){
	if(W3GetDamageIsBullet() && War3_GetRace(attacker)==thisRaceID ){
		new lvl = War3_GetSkillLevel(attacker,thisRaceID,SKILL_HEARTACHE);
		if(lvl > 0  )
		{
			if(W3Chance(heartacheChance[lvl]*W3ChanceModifier(attacker))    && !IsSkillImmune(victim)  ){
			
				War3_HealToBuffHP(attacker,dmgamount);
				PrintToConsole(attacker,"Heartache +%d HP",dmgamount);
			}
		}
	}
}
















public bool:AbilityFilter(client)
{
	return (!IsSkillImmune(client));
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new lvl = War3_GetSkillLevel(client,thisRaceID,SKILL_SLEEP);
		if(lvl > 0)
		{
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_SLEEP,true))
			{	
			
				
				//War3_GetTargetInViewCone(client,Float:max_distance=0.0,bool:include_friendlys=false,Float:cone_angle=23.0,Function:FilterFunction=INVALID_FUNCTION);
				new target = War3_GetTargetInViewCone(client,sleepDistance,_,_,AbilityFilter);
				if(target>0)
				{	
					new Float:duration=sleepDuration[lvl];
					new Handle:sleepTrie=CreateTrie();
					new Handle:timer=CreateTimer(duration,EndSleep,sleepTrie);
					SetTrieValue(sleepTrie,"timer",timer);
					SetTrieValue(sleepTrie,"victim",target);
					SetTrieValue(sleepTrie,"originalduration",duration);
					//SetTrieValue(sleepTrie,"remainingduration",duration);
					Sleep(target);
					
					
					War3_CooldownMGR(client,sleepCooldown,thisRaceID,SKILL_SLEEP);
				
				}
				else{
					W3MsgNoTargetFound(client,sleepDistance);
				}
			
			}
		}
	}
}
Sleep(client){
	War3_SetBuff(client,bStunned,thisRaceID,true);
	PrintHintText(client,"You are Mesmerized");
	if(GameTF()){
		
	}
}

public Action:EndSleep(Handle:t,any:sleepTrie){
	new client;
	GetTrieValue(sleepTrie,"victim",client);
	UnSleep(client);
}
UnSleep(client){
	War3_SetBuff(client,bStunned,thisRaceID,false);
	PrintHintText(client,"No Longer Mesmerized");
}














public OnUltimateCommand(client,race,bool:pressed)
{
	
	if(race==thisRaceID && pressed && ValidPlayer(client,true) )
	{
		new level=War3_GetSkillLevel(client,race,ULTIMATE);
		if(level>0)
		{
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULTIMATE,true))
			{
				//War3_GetTargetInViewCone(client,Float:max_distance=0.0,bool:include_friendlys=false,Float:cone_angle=23.0,Function:FilterFunction=INVALID_FUNCTION);
				new target = War3_GetTargetInViewCone(client,ultDistance,_,_,UltimateFilter);
				if(target>0)
				{		
					//in case of double hold, release the old one
					if(holdingTimer[client]!=INVALID_HANDLE){
						TriggerTimer(holdingTimer[client]);
					}
					new Float:duration = ultDuration[level];
					///hold it right there
					holdingvictim[client]=target;
					holdingTimer[client]=CreateTimer(duration,EndHold,client);
					War3_SetBuff(client,bStunned,thisRaceID,true);
					War3_SetBuff(target,bStunned,thisRaceID,true);
				}
			}
		}	
	}			
}

//return true to allow targeting
public bool:UltimateFilter(client)
{
	return (!IsUltImmune(client));
}
public Action:EndHold(Handle:t,any:client){
	new victim=holdingvictim[client];
	War3_SetBuff(victim,bStunned,thisRaceID,false);
	War3_SetBuff(client,bStunned,thisRaceID,false);
	holdingvictim[client]=0;
	holdingTimer[client]=INVALID_HANDLE;
}
public OnWar3EventDeath(client){
	if(holdingvictim[client]){
		TriggerTimer(holdingTimer[client]);
		holdingTimer[client]=INVALID_HANDLE;
	}
}