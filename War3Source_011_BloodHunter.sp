/**
 * 
 * Description:   BH from HON
 * Author(s): Ownz 
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"



new thisRaceID;
new Handle:ultCooldownCvar;

new SKILL_CRAZY, SKILL_FEAST,SKILL_SENSE,ULT_RUPTURE;


// Chance/Data Arrays
new Float:CrazyDuration[5]={0.0,4.0,6.0,8.0,10.0};
new Float:CrazyUntil[MAXPLAYERS];
new bool:bCrazyDot[MAXPLAYERS];
new CrazyBy[MAXPLAYERS];

new Float:FeastAmount[5]={0.0,0.05,0.1,0.15,0.2}; 

new Float:BloodSense[5]={0.0,0.1,0.15,0.2,0.25}; 

new Float:ultRange=300.0;
new Float:ultiDamageMultiPerDistance[5]={0.0,0.06,0.073,0.086,0.10}; 
new Float:ultiDamageMultiPerDistanceCS[5]={0.0,0.09,0.11,0.13,0.15}; 
new Float:lastRuptureLocation[MAXPLAYERS][3];
new Float:RuptureDuration=8.0;
new Float:RuptureUntil[MAXPLAYERS];
new bool:bRuptured[MAXPLAYERS];
new RupturedBy[MAXPLAYERS];

new String:ultsnd[]="war3source/bh/ult.mp3";


public Plugin:myinfo = 
{
	name = "War3Source Race - Blood Hunter",
	author = "Ownz",
	description = "Blood Hunter for War3Source.",
	version = "1.0",
	url = "War3Source.com"
};

public OnPluginStart()
{
	ultCooldownCvar=CreateConVar("war3_bh_ult_cooldown","20","Cooldown time for Ultimate.");
	CreateTimer(0.1,RuptureCheckLoop,_,TIMER_REPEAT);
	CreateTimer(0.5,BloodCrazyDOTLoop,_,TIMER_REPEAT);
	
	RegConsoleCmd("rme",ruptureme);
	
	LoadTranslations("w3s.race.bh.phrases");
}
public Action:ruptureme(client,args){
	bRuptured[client]=true;
	RupturedBy[client]=client;
	RuptureUntil[client]=GetGameTime()+999999.0;
	GetClientAbsOrigin(client,lastRuptureLocation[client]);

	return Plugin_Handled;
}
public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==110){
		
		thisRaceID=War3_CreateNewRaceT("bh");
		SKILL_CRAZY=War3_AddRaceSkillT(thisRaceID,"BloodCrazy",false);
		SKILL_FEAST=War3_AddRaceSkillT(thisRaceID,"Feast",false);
		SKILL_SENSE=War3_AddRaceSkillT(thisRaceID,"BloodSense",false);
		ULT_RUPTURE=War3_AddRaceSkillT(thisRaceID,"Hemorrhage",true);
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnMapStart()
{
	
	War3_PrecacheSound(ultsnd);
}


public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client))
	{
		//if(
		
		new skill=War3_GetSkillLevel(client,race,ULT_RUPTURE);
		if(skill>0)
		{
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_RUPTURE,true))
			{
				new target=War3_GetTargetInViewCone(client,ultRange,false);
				if(ValidPlayer(target,true)&&!W3HasImmunity(target,Immunity_Ultimates))
				{

					bRuptured[target]=true;
					RupturedBy[target]=client;
					RuptureUntil[target]=GetGameTime()+RuptureDuration;
					GetClientAbsOrigin(target,lastRuptureLocation[target]);
					
					
					War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_RUPTURE,true,true,true,"Hemmorrhage");
				
					EmitSoundToAll(ultsnd,client);
					
					EmitSoundToAll(ultsnd,target);
					EmitSoundToAll(ultsnd,target);
					PrintHintText(target,"%T","You have been ruptured! You take damage if you move!",target);
					PrintHintText(client,"%T","Rupture!",client);
				}
				else
				{
					W3MsgNoTargetFound(client,ultRange);
				}
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}

public OnWar3EventSpawn(client){
	bRuptured[client]=false;
	bCrazyDot[client]=false;
}
public OnWar3EventDeath(victim,attacker){
	if(ValidPlayer(attacker,true)){
		if(War3_GetRace(attacker)==thisRaceID){
			new skill=War3_GetSkillLevel(attacker,thisRaceID,SKILL_FEAST);
			if(skill>0&&!Hexed(attacker,false)){
				War3_HealToMaxHP(attacker,RoundFloat(FloatMul(float(War3_GetMaxHP(victim)),FeastAmount[skill])));
				W3FlashScreen(attacker,RGBA_COLOR_GREEN,0.3,_,FFADE_IN);
			}
		}
	}
}

public Action:RuptureCheckLoop(Handle:h,any:data){
	new Float:origin[3];
	new attacker;
	new skilllevel;
	new Float:dist;
	for(new i=1;i<=MaxClients;i++){
		if(ValidPlayer(i,true)){
			if(bRuptured[i]){
				attacker=RupturedBy[i];
				if(ValidPlayer(attacker)){
					
					if(War3_GetGame()==Game_TF){
						Gore(i);
					}
					skilllevel=War3_GetSkillLevel(attacker,thisRaceID,ULT_RUPTURE);
					GetClientAbsOrigin(i,origin);
					dist=GetVectorDistance(origin,lastRuptureLocation[i]);
					
					new damage=RoundFloat(FloatMul(dist,War3_GetGame()==CS?ultiDamageMultiPerDistanceCS[skilllevel]:ultiDamageMultiPerDistance[skilllevel]));
					if(damage>0){
						if(War3_GetGame()==Game_TF){
							War3_DealDamage(i,damage,attacker,_,"rupture",_,W3DMGTYPE_TRUEDMG);
							War3_TF_ParticleToClient(0, GetClientTeam(i)==2?"healthlost_red":"healthlost_blu", origin);
						}
						else{
							if(GetClientHealth(i)>damage){
								War3_DecreaseHP(i,damage);
							}
							else{
								War3_DealDamage(i,damage,attacker,_,"rupture",_,W3DMGTYPE_TRUEDMG);
							}
						}
						lastRuptureLocation[i][0]=origin[0];
						lastRuptureLocation[i][1]=origin[1];
						lastRuptureLocation[i][2]=origin[2];
						W3FlashScreen(i,RGBA_COLOR_RED,1.0,_,FFADE_IN);
					}
				}
				
				if(GetGameTime()>RuptureUntil[i]){
					bRuptured[i]=false;
				}
			}
		}
	}
}
public Action:BloodCrazyDOTLoop(Handle:h,any:data){
	new attacker;
	for(new i=1;i<=MaxClients;i++){
		if(ValidPlayer(i,true)){
			if(bCrazyDot[i]){
				attacker=CrazyBy[i];
				if(ValidPlayer(attacker)){
					if(War3_GetGame()==Game_TF){
						War3_DealDamage(i,1,attacker,_,"bleed_kill");
						
						new Float:pos[3];
						GetClientAbsOrigin(i,pos);
						War3_TF_ParticleToClient(0, GetClientTeam(i)==2?"healthlost_red":"healthlost_blu", pos);
						    
					}
					else{
						if(War3_GetGame()==Game_CS&&GetClientHealth(i)>1){
						    War3_DecreaseHP(i,1);
						}
						else{
						    War3_DealDamage(i,1,attacker,_,"bloodcrazy");
						    
						   
						}
						
					}
				}
				
				if(GetGameTime()>CrazyUntil[i]){
					bCrazyDot[i]=false;
				}
			}
		}
	}
				
}
public OnW3TakeDmgBullet(victim,attacker,Float:damage){
	if(ValidPlayer(victim)&&ValidPlayer(attacker)&&victim!=attacker&&GetClientTeam(victim)!=GetClientTeam(attacker)){
		if(War3_GetRace(attacker)==thisRaceID&&!Hexed(attacker,false)){
			new skilllevel=War3_GetSkillLevel(attacker,thisRaceID,SKILL_CRAZY);
			if(skilllevel>0){
				bCrazyDot[victim]=true;
				CrazyBy[victim]=attacker;
				CrazyUntil[victim]=GetGameTime()+CrazyDuration[skilllevel];
			}
			skilllevel=War3_GetSkillLevel(attacker,thisRaceID,SKILL_SENSE);
			if(skilllevel>0){
				if(FloatDiv(float(GetClientHealth(victim)),float(War3_GetMaxHP(victim)))<BloodSense[skilllevel]){
					W3FlashScreen(victim,RGBA_COLOR_RED,0.3,_,FFADE_IN);
					War3_DamageModPercent(2.0);
					PrintToConsole(attacker,"%T","Double Damage against low HP enemies!",attacker);
				}
			}
		}
	}
}

public Gore(client){
	WriteParticle(client, "blood_spray_red_01_far");
	WriteParticle(client, "blood_impact_red_01");
}
WriteParticle(Ent, String:ParticleName[])
{

	//Declare:
	decl Particle;
	decl String:tName[64];

	//Initialize:
	Particle = CreateEntityByName("info_particle_system");
	
	//Validate:
	if(IsValidEdict(Particle))
	{

		//Declare:
		decl Float:Position[3], Float:Angles[3];

		//Initialize:
		Angles[0] = GetRandomFloat(0.0, 360.0);
		Angles[1] = GetRandomFloat(0.0, 15.0);
		Angles[2] = GetRandomFloat(0.0, 15.0);

		//Origin:
        	GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", Position);
		Position[2] += GetRandomFloat(35.0, 65.0);
        	TeleportEntity(Particle, Position, Angles, NULL_VECTOR);

		//Properties:
		GetEntPropString(Ent, Prop_Data, "m_iName", tName, sizeof(tName));
		StrCat(tName,63,"unambiguate");
		DispatchKeyValue(Particle, "targetname", "TF2Particle");
		DispatchKeyValue(Particle, "parentname", tName);
		DispatchKeyValue(Particle, "effect_name", ParticleName);

		//Spawn:
		DispatchSpawn(Particle);
	
		//Parent:		
		//SetVariantString(tName);
		//AcceptEntityInput(Particle, "SetParent", -1, -1, 0);
		ActivateEntity(Particle);
		AcceptEntityInput(Particle, "start");

		//Delete:
		CreateTimer(6.0, DeleteParticle, Particle);
	}
}

//Delete:
public Action:DeleteParticle(Handle:Timer, any:Particle)
{

	//Validate:
	if(IsValidEntity(Particle))
	{

		//Declare:
		decl String:Classname[64];

		//Initialize:
		GetEdictClassname(Particle, Classname, sizeof(Classname));

		//Is a Particle:
		if(StrEqual(Classname, "info_particle_system", false))
		{

			//Delete:
			RemoveEdict(Particle);
		}
	}
}