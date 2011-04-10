#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source Race - Sacred Warrior",
    author = "Ted Theodore Logan / modified by Ownz (DarkEnergy)",
    description = "The Sacred Warrior race for War3Source.",
    version = "1.1",
};
public W3ONLY(){} //unload this?
new thisRaceID;
new SKILL_VITALITY, SKILL_SPEAR, SKILL_BLOOD, ULT_BREAK;

// Inner Vitality, HP healed
new VitalityHealed[]={0,1,2,3,4}; // How much HP Vitality heals each second

// Burning Spear stacking effect
new SpearDamage[]={0,1,2,3,4}; // How much damage does a stack do?
new MaxSpearStacks=3; // How many stacks can the attacker dish out?
//new Float:SpearUntil[MAXPLAYERSCUSTOM]; // Until when is the victim affected?
new VictimSpearStacks[MAXPLAYERSCUSTOM]; // How many stacks does the victim have?
new VictimSpearTicks[MAXPLAYERSCUSTOM];
//new bool:bSpeared[MAXPLAYERSCUSTOM]; // Is this player speared (has DoT on him)?
new SpearedBy[MAXPLAYERSCUSTOM]; // Who was the victim speared by?
new bool:bSpearActivated[MAXPLAYERSCUSTOM]; // Does the player have Burning Spear activated?

// Buffs that berserker applys
//new Float:BerserkerBuffDamage[]={0.0,0.005,0.01,0.015,0.02};  // each 7% you add one of these 
new Float:BerserkerBuffASPD[]={0.0,0.01,0.02,0.03,0.04};      // to get the total buff...

// Life Break costs / damage dealt
new Float:LifeBreakHPVictim[]={0.0,0.20,0.30,0.40,0.50}; // Percentage of how much HP the caster loses
new Float:LifeBreakHPCaster[]={0.0,0.10,0.15,0.20,0.25};    // Percentage of how much HP the victim loses


new Handle:ultCooldownCvar;
new Float:ultmaxdistance = 500.0;
public OnPluginStart()
{
    CreateTimer(1.0,InnerVitalityTimer,_,TIMER_REPEAT); // Healing Timer
    CreateTimer(0.3,BerserkerCalculateTimer,_,TIMER_REPEAT);      // Berserker ASPD Buff timer
    CreateTimer(1.0,BurningSpearTimer,_,TIMER_REPEAT);  // Burning Spear DoT Timer
    LoadTranslations("w3s.race.sacredw.phrases");
    ultCooldownCvar=CreateConVar("war3_sacredw_ult_cooldown","20","Cooldown time for ult.");
}
public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==160)
	{
		thisRaceID=War3_CreateNewRaceT("sacredw");
		SKILL_VITALITY=War3_AddRaceSkillT(thisRaceID,"InnerVitality",false,4,"1/2/3/4");
		SKILL_SPEAR=War3_AddRaceSkillT(thisRaceID,"BurningSpear",false,4,"1/2/3/4","3","3");
		SKILL_BLOOD=War3_AddRaceSkillT(thisRaceID,"BerserkersBlood",false,4,"1/2/3/4","7");
		ULT_BREAK=War3_AddRaceSkillT(thisRaceID,"LifeBreak",true,4,"10/15/20/25","20/30/40/50");
		War3_CreateRaceEnd(thisRaceID); ///DO NOT FORGET THE END!!!
	}
}
public OnWar3EventSpawn(client)
{
    
    VictimSpearStacks[client] = 0;  // deactivate Burning Spear
    VictimSpearTicks[client] = 0;
    bSpearActivated[client] = false;  // on spawn
}

public Action:BurningSpearTimer(Handle:h,any:data) //1 sec
{
    new attacker;
    new damage;
    new SelfDamage;
    new skill;
    for(new i=1;i<=MaxClients;i++) // Iterate over all clients
    {
        if(ValidPlayer(i,true))
        {
            if(bSpearActivated[i]) // Client has Burning Spear activated
            {
            	SelfDamage = RoundToCeil(War3_GetMaxHP(i) * 0.05);
            	War3_DealDamage(i,SelfDamage,i,_,"burningspear"); // damage the client for having it activated
            }
        
            if(VictimSpearTicks[i] >0)
            {
                attacker = SpearedBy[i];
                skill = War3_GetSkillLevel(attacker, thisRaceID, SKILL_SPEAR);
                if(ValidPlayer(attacker, true)&&bSpearActivated[attacker]) // Attacker has Burning Spear activated
                {
					damage = VictimSpearStacks[i] * SpearDamage[skill]; // Number of stacks on the client * damage of the attacker
					
					if(War3_GetGame()==Game_TF)
					{
					    War3_DealDamage(i,damage,attacker,_,"bleed_kill"); // Bleeding Icon
					}
					else
					{
					    War3_DealDamage(i,damage,attacker,_,"burningspear"); // Generic skill name
					}
					VictimSpearTicks[i]--;
                }
                else{
                	VictimSpearTicks[i]=0; //attacker deactivated spears
                }
                if(VictimSpearTicks[i]==0){ //last tick
                	VictimSpearStacks[i]=0; // Reset stacks
                }
            }
        }
    }                
}

public Action:InnerVitalityTimer(Handle:timer,any:userid) //1 sec
{
    if(thisRaceID>0)
    {
        for(new i=1;i<=MaxClients;i++)
        {
            if(ValidPlayer(i,true))
            {
                if((War3_GetRace(i)==thisRaceID) && (!bSpearActivated[i])) // client playing Sacred Warrior and not in Burning Spear mode
                {
                    new skill = War3_GetSkillLevel(i,thisRaceID,SKILL_VITALITY);
                    new VictimCurHP = GetClientHealth(i);
                    new VictimMaxHP = War3_GetMaxHP(i);
                    new Float:DoubleTrigger = VictimMaxHP * 0.4;
                    new HPtoHeal = 0;
                    if(VictimCurHP<VictimMaxHP)
                    {
                        if(VictimCurHP<=DoubleTrigger) // Victim is below or at 40% health
                        {
                            HPtoHeal = VitalityHealed[skill] * 2;
                        }
                        else
                        {
                            HPtoHeal = VitalityHealed[skill];
                        }
                        War3_HealToMaxHP(i, HPtoHeal);
                    }
                }
            }
        }
    }
}

public Action:BerserkerCalculateTimer(Handle:timer,any:userid) // Check each 0.5 second if the conditions for Berserkers Blood have changed
{
    if(thisRaceID>0)
    {
        for(new i=1;i<=MaxClients;i++)
        {
            if(ValidPlayer(i,true))
            {
                if(War3_GetRace(i)==thisRaceID)
                {
					new client=i;
					
					
					new Float:ASPD;
					
					new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_BLOOD);
					new VictimCurHP = GetClientHealth(client);
					new MaxHP=War3_GetMaxHP(client);
					if(VictimCurHP>=MaxHP){
						ASPD=1.0;
					}
					else{
						new missing=MaxHP-VictimCurHP;
						new Float:percentmissing=float(missing)/float(MaxHP);
						ASPD=1.0+BerserkerBuffASPD[skilllvl]*(percentmissing/0.07);
					}
					//PrintToChat(client,"%f",ASPD);
					War3_SetBuff(client,fAttackSpeed,thisRaceID,ASPD); // Set the buff
                }
            }
        }
    }
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage){
    if(ValidPlayer(victim,true)&&ValidPlayer(attacker,false)&&GetClientTeam(victim)!=GetClientTeam(attacker))
    {
        if(War3_GetRace(attacker)==thisRaceID)
        {
			// Apply Blood buff
			new skilllvl = War3_GetSkillLevel(attacker,thisRaceID,SKILL_SPEAR);
			if(skilllvl>0&&!Hexed(attacker)&&!W3HasImmunity(attacker,Immunity_Skills)){
			
				if(W3Chance(W3ChanceModifier(attacker))){
					if(VictimSpearStacks[victim]<MaxSpearStacks){
						VictimSpearStacks[victim]++; //stack if less than max stacks
					}
					VictimSpearTicks[victim] =3 ; //always three ticks
				
					SpearedBy[victim] = attacker;
				
				}
			}
        }
    }
}

public OnRaceSelected(client,race)
{
    if(race!=thisRaceID)
    {
        War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0); // Remove ASPD buff when changing races
    }
}

public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client)&&!Silenced(client))
    {
        if(!bSpearActivated[client])
        {
            PrintHintText(client,"%T","Activated Burning Spear",client);
            bSpearActivated[client] = true;
        }
        else
        {
            PrintHintText(client,"%T","Deactivated Burning Spear",client);
            bSpearActivated[client] = false;
        }
    }
}
public OnUltimateCommand(client,race,bool:pressed)
{

	if(race==thisRaceID && pressed && ValidPlayer(client,true) &&!Silenced(client) )
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_BREAK);
		if(ult_level>0)
		{
            new Float:AttackerMaxHP = float(War3_GetMaxHP(client));
            new AttackerCurHP = GetClientHealth(client);
            new SelfDamage = RoundToCeil(AttackerMaxHP * LifeBreakHPCaster[ult_level]);
            new bool:bUltPossible = SelfDamage < AttackerCurHP;
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_BREAK,true))
            {
                if(!bUltPossible)
                {
					PrintHintText(client,"%T","You do not have enough HP to cast that...",client);
                }
                else
                {
					
					
					new target = War3_GetTargetInViewCone(client,ultmaxdistance,false,23.0,ConeTargetFilter);
					if(target>0)
					{
					
					    new Float:VictimMaxHP = float(War3_GetMaxHP(target));
					    new Damage = RoundToFloor(LifeBreakHPVictim[ult_level] * VictimMaxHP);
					    
					    if(War3_DealDamage(target,Damage,client,DMG_BULLET,"lifebreak")) // do damage to nearest enemy
					    {
					        W3PrintSkillDmgHintConsole(target,client,War3_GetWar3DamageDealt(),"Life Break"); // print damage done
					        W3FlashScreen(target,RGBA_COLOR_RED); // notify victim he got hurt
					        W3FlashScreen(client,RGBA_COLOR_RED); // notify he got hurt
					        
					        //EmitSoundToAll(ultimateSound,client);
					        War3_DealDamage(client,SelfDamage,client,DMG_BULLET,"lifebreak"); // Do damage to attacker
					        War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_BREAK,_,_); // invoke cooldown
					        
					        PrintHintText(client,"%T","Life Break",client);
					    }
					}
					else{
					    W3MsgNoTargetFound(client,ultmaxdistance);
					}
					
}
            }
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}
public bool:ConeTargetFilter(client)
{
	return (!W3HasImmunity(client,Immunity_Ultimates));
}
