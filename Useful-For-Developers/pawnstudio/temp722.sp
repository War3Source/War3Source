/**
 * File: War3Source_Lich.sp
 * Description: The Lich race for War3Source.
 * Author(s): [Oddity]TeacherCreature
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

new thisRaceID;

new SKILL_FROSTNOVA,SKILL_FROSTARMOR,SKILL_DARKRITUAL,ULT_DEATHDECAY;

//skill 1
new Float:FrostNovaArr[]={0.0,0.85,0.8,0.75,0.7,0.65,0.6,0.55,0.5}; 
new Float:FrostNovaRadius=500.0;
new FrostNovaLoopCountdown[66];
new bool:HitOnForwardTide[66][66]; //[VICTIM][ATTACKER]
new Float:FrostNovaOrigin[66][3];
new Float:AbilityCooldownTime=10.0;

//skill 2
new Float:FrostArmorChance[]={0.0,0.3,0.35,0.4,0.45,0.5,0.55,0.6,0.65}; 

//skill 3
new DarkRitualAmt[]={0,1,2,3,4,5,6,7,8};

//ultimate
new Handle:ultCooldownCvar;
new Handle:ultRangeCvar;
new DeathDecayAmt[]={0,1,2,3,4,5,6,7,8};
new String:ultsnd[]="npc/antlion/attack_single2.wav";
new String:novasnd[]="npc/combine_gunship/ping_patrol.wav";
new BeamSprite,HaloSprite; 

public Plugin:myinfo = 
{
	name = "War3Source Race - Lich",
	author = "[Oddity]TeacherCreature",
	description = "The Lich race for War3Source.",
	version = "1.0.0.0",
	url = "warcraft-source.net"
}

public OnPluginStart()
{
	
	ultCooldownCvar=CreateConVar("war3_lich_deathdecay_cooldown","30","Cooldown between ultimate usage");
	ultRangeCvar=CreateConVar("war3_lich_deathdecay_range","99999","Range of death and decay ultimate");
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==42)
	{
		thisRaceID=War3_CreateNewRace("Lich","lich");
		SKILL_FROSTNOVA=War3_AddRaceSkill(thisRaceID,"Frost Nova","AoE Slow attack in a ring of Frost (+ability)",false,8);
		SKILL_FROSTARMOR=War3_AddRaceSkill(thisRaceID,"Frost Armor","Deep freeze your attacker",false,8);
		SKILL_DARKRITUAL=War3_AddRaceSkill(thisRaceID,"Dark Ritual","Gain HP from the sacrifice of teamates",false,8);
		ULT_DEATHDECAY=War3_AddRaceSkill(thisRaceID,"Death and Decay","Damage all enemies on the map",true,8); 
		War3_CreateRaceEnd(thisRaceID);	
	}

}

public OnMapStart()
{	
	War3_PrecacheSound(ultsnd);
	War3_PrecacheSound(novasnd);
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}


public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_FROSTNOVA);
		if(skill_level>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_FROSTNOVA,true))
			{
				EmitSoundToAll(novasnd,client);
				GetClientAbsOrigin(client,FrostNovaOrigin[client]);
				FrostNovaOrigin[client][2]+=15.0;
				FrostNovaLoopCountdown[client]=20;
				
				for(new i=1;i<=MaxClients;i++){
					HitOnForwardTide[i][client]=false;
				}
				
				TE_SetupBeamRingPoint(FrostNovaOrigin[client], 1.0, 650.0, BeamSprite, HaloSprite, 0, 5, 1.0, 50.0, 1.0, {0,0,255,255}, 50, 0);
				TE_SendToAll();
				
				CreateTimer(0.1,BurnLoop,client); //damage
				CreateTimer(0.13,BurnLoop,client); //damage
				CreateTimer(0.17,BurnLoop,client); //damage
				
				
				War3_CooldownMGR(client,AbilityCooldownTime,thisRaceID,SKILL_FROSTNOVA,_,_,_,"Frost Nova");
				//EmitSoundToAll(taunt1,client);//,_,SNDLEVEL_TRAIN);
				//EmitSoundToAll(taunt1,client);//,_,SNDLEVEL_TRAIN);
				//EmitSoundToAll(taunt2,client);
				
				PrintHintText(client,"Frost Nova!");
			}
		}
	}
}

public Action:BurnLoop(Handle:timer,any:attacker)
{

	if(ValidPlayer(attacker) && FrostNovaLoopCountdown[attacker]>0)
	{
		new team = GetClientTeam(attacker);
		//War3_DealDamage(victim,damage,attacker,DMG_BURN);
		CreateTimer(0.1,BurnLoop,attacker);
		
		new Float:damagingRadius=(1.0-FloatAbs(float(FrostNovaLoopCountdown[attacker])-10.0)/10.0)*FrostNovaRadius;
		
		//PrintToChatAll("distance to damage %f",damagingRadius);
		
		FrostNovaLoopCountdown[attacker]--;
		
		new Float:otherVec[3];
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Skills))
			{
		
				if(HitOnForwardTide[i][attacker]==true){
					continue;
				}
					
					
				GetClientAbsOrigin(i,otherVec);
				otherVec[2]+=30.0;
				new Float:victimdistance=GetVectorDistance(FrostNovaOrigin[attacker],otherVec);
				if(victimdistance<FrostNovaRadius&&FloatAbs(otherVec[2]-FrostNovaOrigin[attacker][2])<50)
				{
					if(FloatAbs(victimdistance-damagingRadius)<(FrostNovaRadius/10.0))
					{
						
						HitOnForwardTide[i][attacker]=true;
						//War3_DealDamage(i,RoundFloat(FrostNovaMaxDamage[War3_GetSkillLevel(attacker,thisRaceID,SKILL_FROSTNOVA)]*victimdistance/FrostNovaRadius/2.0),attacker,DMG_ENERGYBEAM,"FrostNova");
						War3_SetBuff(i,fSlow,thisRaceID,FrostNovaArr[War3_GetSkillLevel(attacker,thisRaceID,SKILL_FROSTNOVA)]);
						CreateTimer(5.0,RemoveFrostNova,i);
						PrintHintText(i,"You were slowed by frost nova!");
					}
				}
			}
		}
	}
}
public Action:RemoveFrostNova(Handle:t,any:client){
	War3_SetBuff(client,fSlow,thisRaceID,1.0);
}

public CooldownUltimate(client)
{
	War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_DEATHDECAY,_,_,_,"Death and Decay");
}

public Action:OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
		
	if(War3_GetRace(victim)==thisRaceID&&ValidPlayer(attacker,true))
	{
		if(GetClientTeam(victim)!=GetClientTeam(attacker))
		{
			new Float:chance_mod=W3ChanceModifier(attacker);
			new skill_frostarmor=War3_GetSkillLevel(victim,thisRaceID,SKILL_FROSTARMOR);
			if(skill_frostarmor>0)
			{
				if(GetRandomFloat(0.0,1.0)<=FrostArmorChance[skill_frostarmor]*chance_mod && !W3HasImmunity(attacker,Immunity_Skills))
				{
					War3_SetBuff(attacker,fAttackSpeed,thisRaceID,0.5);
					PrintHintText(attacker,"Frost Armor slows you");
					PrintHintText(victim,"Frost Armor slows your attacker");
					W3FlashScreen(attacker,RGBA_COLOR_BLUE,0.9);
					CreateTimer(2.0,farmor,attacker);
				}
			}
		}
	}
}

public Action: farmor(Handle:timer,any:attacker)
{
	War3_SetBuff(attacker,fAttackSpeed,thisRaceID,1.0);
}
	
public OnWar3EventDeath(victim,attacker)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(War3_GetRace(i)==thisRaceID)
		{
			new team=GetClientTeam(i);
			if(ValidPlayer(i,true)&&GetClientTeam(victim)==team)
			{
				new skill=War3_GetSkillLevel(i,thisRaceID,SKILL_DARKRITUAL);
				if(skill>0)
				{
					new hpadd=DarkRitualAmt[skill];
					SetEntityHealth(i,GetClientHealth(i)+hpadd);
					//War3_HealToMaxHP(i,RoundFloat(FloatMul(float(War3_GetMaxHP(i)),float(DarkRitualAmt[skill]))));
					W3FlashScreen(i,RGBA_COLOR_GREEN,0.9);
					PrintHintText(i,"Dark Ritual heals you");
				}
			}
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	new userid=GetClientUserId(client);			
	if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) )
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_DEATHDECAY);
		if(ult_level>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_DEATHDECAY,true))
			{
				new Float:posVec[3];
				GetClientAbsOrigin(client,posVec);
				new Float:otherVec[3];
				new team = GetClientTeam(client);
				new maxtargets=15;
				new targetlist[66];
				new targetsfound=0;
				new Float:ultmaxdistance=GetConVarFloat(ultRangeCvar);
				for(new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Ultimates))
					{
						GetClientAbsOrigin(i,otherVec);
						new Float:dist=GetVectorDistance(posVec,otherVec);
						if(dist<ultmaxdistance)
						{
							targetlist[targetsfound]=i;
							targetsfound++;
							if(targetsfound>=maxtargets){
								break;
							}
						}
					}
				}
				if(targetsfound==0)
				{
					PrintHintText(client,"No Target Found within %.1f feet",ultmaxdistance/10);
				}
				else
				{
					new damage=DeathDecayAmt[ult_level];
					for(new i=0;i<targetsfound;i++)
					{
						new victim=targetlist[i];
						if(War3_DealDamage(victim,damage,client,DMG_BULLET,"Death and Decay")) //default magic
						{
							W3FlashScreen(victim,RGBA_COLOR_RED);
							PrintHintText(victim,"Attacked by Death and Decay");
						}
					}
					PrintHintText(client,"Death and Decay attacked for %d total damage!",damage*targetsfound);
					CooldownUltimate(client);
					EmitSoundToAll(ultsnd,client);
				}
			}
		}
		else
		{
			PrintHintText(client,"Level Your Ultimate First");
		}
	}
}

