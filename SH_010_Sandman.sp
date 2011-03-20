#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>


// War3Source stuff
new thisRaceID;
new bool:bDucking[MAXPLAYERS];
new Float:burypos[66][3];
new Float:oldpos[66][3];
new SKILL_BURY;
public Plugin:myinfo = 
{
	name = "SH hero Sandman",
	author = "GGHH3322",
	description = "SH Race",
	version = "1.0.0.0",
	url = "not"
};
// War3Source Functions
public OnPluginStart()
{
}
public OnSHLoadHeroOrItemOrdered(num)
{
	if(num==40)
	{
	
	
		
		thisRaceID=SHRegisterHero(
		"Sandman",
		"sandman",
		"Bury enemy during 5sec",
		"Bury enemy during 5sec, enemy can't use weapon and move",
		true
		);
	}
}

public OnWar3EventSpawn(client)
{
	//PrintToChatAll("SPAWN %d",client);

	if(SHHasHero(client,thisRaceID))
	{
		War3_SetBuff(client,bStunned,thisRaceID,false);
		W3ResetPlayerColor(client,thisRaceID);
	}
	else{
		War3_SetBuff(client,bStunned,thisRaceID,false);
		W3ResetPlayerColor(client,thisRaceID);
	}
}

public OnRaceSelected(client)
{
	if(!SHHasHero(client,thisRaceID))
	{
	}
	else
	{	
		if(IsPlayerAlive(client)){
		}	
	}
}

public InitPassiveSkills(client){
	if(SHHasHero(client,thisRaceID))
	{
	}
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	
	bDucking[client]=(buttons & IN_DUCK)?true:false;
	return Plugin_Continue;
}
public OnPowerCommand(client,herotarget,bool:pressed){
	//PrintToChatAll("%d",herotarget);
	if(SHHasHero(client,herotarget)&&herotarget==thisRaceID){
		//PrintToChatAll("1");
		if(pressed && War3_SkillNotInCooldown(client,thisRaceID,SKILL_BURY,true)){
			new target = War3_GetTargetInViewCone(client,800.0,false,23.0);
			if(target>0)
			{
				if(bDucking[target]){
					PrintHintText(client,"You can't bury when enemy ducking!");
				}
				else{
					GetClientAbsOrigin(target,oldpos[target]);
					GetClientAbsOrigin(target,burypos[target]);
					CreateTimer(0.1,Buried,target);
					PrintHintText(client,"Bury enemy!");
					PrintHintText(target,"You are buring!");
					War3_SetBuff(target,bStunned,thisRaceID,true);
					War3_CooldownMGR(client,30.0,thisRaceID,SKILL_BURY,_,_,_,"Bury");
					W3SetPlayerColor(target,thisRaceID,255,200,0,_,GLOW_ULTIMATE); //255,200,0);
				}
			}
			else{
				PrintHintText(client,"Can't find enemy.");
			}
		}
	}
}

public Action:Buried(Handle:h,any:client){
	burypos[client][2]--;
	TeleportEntity(client,burypos[client],NULL_VECTOR,NULL_VECTOR);
	if(burypos[client][2]>oldpos[client][2]-55 && IsPlayerAlive(client)){
		CreateTimer(0.1,Buried,client);
	}
	else if(!IsPlayerAlive(client)){
	}
	else{
		CreateTimer(4.0,Buriedout,client);
	}
}
public Action:Buriedout(Handle:h,any:client){
	TeleportEntity(client,oldpos[client],NULL_VECTOR,NULL_VECTOR);
	War3_SetBuff(client,bStunned,thisRaceID,false);
}