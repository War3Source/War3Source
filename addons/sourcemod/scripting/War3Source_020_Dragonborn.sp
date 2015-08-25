#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include "W3SIncs/War3Source_Interface"  

public Plugin:myinfo = 
{
    name = "War3Source - Race - Dragonborn",
    author = "War3Source Team",
    description = "The Dragonborn race for War3Source."
};

new thisRaceID;

new bool:RaceDisabled=true;
public OnWar3RaceEnabled(newrace)
{
    if(newrace==thisRaceID)
    {
        RaceDisabled=false;
    }
}
public OnWar3RaceDisabled(oldrace)
{
    if(oldrace==thisRaceID)
    {
        RaceDisabled=true;
    }
}


public LoadCheck(){
    return GameTF();
}

new SKILL_ROAR,SKILL_SCALES,SKILL_DRAGONBORN,ULTIMATE_DRAGONBREATH;
/*
Roar - Stuns targets in a radius and applys the scare effect.
Scales - Gives you a small armor bonus, &  at level 4 makes you invunerable to ultimates due to your magic scales.
Dragonborn - You get increased health from being dragonborn.
Dragonbreath - Breathe fire in an area infront of you.

To Do:
Roar - Finished except for effect        |Fear effect
Dragonborn - Finished                    |No effects
Scales - Finished                        |No effects
Ultimate - Unfinished
Effects - Unfinished
IT'S ALL FINISHED

V. 2.0.0.0
Changed max hp to ability immunitys because tf2 max hp is dumb.

Cool things learned this race:
**W3PrintSkillDmgConsole(i,client,War3_GetWar3DamageDealt(),SKILL_NAME);
**if (TF2_GetClass(client) == TFClass_Scout) etc etc
**new const SkillColor[4] = {255, 255, 255, 155} changing skill colors via array, neato.
**That max health in tf2 is stupid.
*/
new Float:RoarRadius=300.0;
new Float:RoarDuration[5]={0.0,0.2,0.4,0.6,0.7};
new Float:RoarCooldownTime=25.0;
new Float:ScalesPhysical[5]={0.0,1.0,1.66,2.33,3.0};
new Float:ImmunityChance=0.15;
new Float:dragvec[3]={0.0,0.0,0.0};
new Float:victimvec[3]={0.0,0.0,0.0};
new Float:DragonBreathRange[5]={0.0,400.0,500.0,600.0,700.0};

// Sounds
new String:roarsound[256]; //="war3source/dragonborn/roar.mp3";
new String:ultsndblue[256]; //="war3source/dragonborn/ultblue.mp3";
new String:ultsndred[256]; //="war3source/dragonborn/ultred.mp3";


public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==200)
    {
        
        thisRaceID=War3_CreateNewRaceT("dragonborn_o");
        SKILL_ROAR=War3_AddRaceSkillT(thisRaceID,"Roar",false,4);
        SKILL_SCALES=War3_AddRaceSkillT(thisRaceID,"Scales",false,4);
        SKILL_DRAGONBORN=War3_AddRaceSkillT(thisRaceID,"Dragonborn",false,4);
        ULTIMATE_DRAGONBREATH=War3_AddRaceSkillT(thisRaceID,"DragonsBreath",true,4); 
        War3_CreateRaceEnd(thisRaceID); ///DO NOT FORGET THE END!!!
        
        War3_AddSkillBuff(thisRaceID, SKILL_SCALES, fArmorPhysical, ScalesPhysical);
    }
}

public OnPluginStart()
{
    CreateTimer(0.5,HalfSecondTimer,_,TIMER_REPEAT); //The footstep effect
    LoadTranslations("w3s.race.dragonborn_o.phrases.txt");
}

public OnMapStart()
{
    War3_AddSoundFolder(roarsound, sizeof(roarsound), "dragonborn/roar.mp3");
    War3_AddSoundFolder(ultsndblue, sizeof(ultsndblue), "dragonborn/ultblue.mp3");
    War3_AddSoundFolder(ultsndred, sizeof(ultsndred), "dragonborn/ultred.mp3");

    War3_PrecacheParticle("explosion_trailSmoke");//ultimate trail
    War3_PrecacheParticle("burningplayer_flyingbits"); //Red Team foot effect
    War3_PrecacheParticle("water_bulletsplash01"); //Blue Team foot effect
    War3_PrecacheParticle("waterfall_bottomwaves"); //Blue Team DragonsBreath Effect
    War3_PrecacheParticle("explosion_trailFire");//Red Team DragonsBreath Effect
    War3_PrecacheParticle("yikes_text");//Roar Effect Victim
    War3_PrecacheParticle("particle_nemesis_burst_red");//Red Team Roar Caster
    War3_PrecacheParticle("particle_nemesis_burst_blue");//Blue Team Roar Caster
    War3_AddCustomSound(roarsound);
    War3_AddCustomSound(ultsndblue);
    War3_AddCustomSound(ultsndred);
}

public OnUltimateCommand(client,race,bool:pressed)
{
    if(RaceDisabled)
    {
        return;
    }

    new userid=GetClientUserId(client);
    if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) )
    {
        new ult_level=War3_GetSkillLevel(client,race,ULTIMATE_DRAGONBREATH);
        if(ult_level>0)
        {
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULTIMATE_DRAGONBREATH,true))
            {
                new Float:breathrange= DragonBreathRange[ult_level];
                //War3_GetTargetInViewCone(client,Float:max_distance=0.0,bool:include_friendlys=false,Float:cone_angle=23.0,Function:FilterFunction=INVALID_FUNCTION);
                new target = War3_GetTargetInViewCone(client,breathrange,false,23.0,DragonFilter);
                //new Float:duration = DarkorbDuration[ult_level];
                if(target>0)
                {
                    EmitSoundToAllAny(ultsndblue,client);
                    EmitSoundToAllAny(ultsndblue,client);
                    GetClientAbsOrigin(target,victimvec);
                    TF2_AddCondition(target, TFCond_Jarated, 5.0);
                    AttachThrowAwayParticle(target, "waterfall_bottomwaves", victimvec, "", 2.0);
                    War3_CooldownMGR(client,25.0,thisRaceID,ULTIMATE_DRAGONBREATH,_,_);
                    W3Hint(target,HINT_COOLDOWN_NOTREADY,5.0,"%T","A dragon weakend you with dragon breath",target);                    
                }
                else{
                    W3MsgNoTargetFound(client,breathrange);
                }
            }
        }    
    }            
}

public bool:DragonFilter(client)
{
    if(RaceDisabled)
    {
        return false;
    }

    return (!W3HasImmunity(client,Immunity_Ultimates));
}

public Action:HalfSecondTimer(Handle:timer,any:clientz) //footsy flame/water effects only on ground yay!
{
    if(RaceDisabled)
    {
        return;
    }

    for(new client=1; client <= MaxClients; client++)
    {
        if(ValidPlayer(client, true))
        {
            if(War3_GetRace(client) == thisRaceID&&!IsInvis(client))
            {
                GetClientAbsOrigin(client,dragvec);
                //dragvec[2]+=35.0;  Crotch Level lololol Firecrotch 
                dragvec[2]+=15;
                AttachThrowAwayParticle(client, GetApparentTeam(client) == TEAM_BLUE?"water_bulletsplash01":"burningplayer_flyingbits", dragvec, "", 1.5);
            }
        }
    }
}

//public Action:stopspeed(Handle:t,any:client){
//W3ResetBuffRace(client,fMaxSpeed,thisRaceID);
//TF2_StunPlayer(client,0.0, 0.0,TF_STUNFLAGS_LOSERSTATE,0);
//}
//Roar - If it's too overpowered I might add in an adrenaline effect to all clients effect afterward (Increased speed during thirdperson stun animation)
public OnAbilityCommand(client,ability,bool:pressed)
{
    if(RaceDisabled)
    {
        return;
    }

    //TF2_StunPlayer(client,5.0, 0.0,TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_THIRDPERSON,0);
    //War3_SetBuff(client,fMaxSpeed,thisRaceID,2.0);
    //CreateTimer(1.0,stopspeed,client);
    if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
    {
        if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_ROAR,true))
        {
            new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_ROAR);
            if(skilllvl > 0)
            {
                new Float:AttackerPos[3];
                GetClientAbsOrigin(client,AttackerPos);
                new AttackerTeam = GetClientTeam(client);
                new Float:VictimPos[3];
                for(new i=1;i<=MaxClients;i++)
                {
                    if(ValidPlayer(i,true))
                    {
                        GetClientAbsOrigin(i,VictimPos);
                        if(GetVectorDistance(AttackerPos,VictimPos)<RoarRadius)
                        {
                            if(GetClientTeam(i)!=AttackerTeam && !W3HasImmunity(i,Immunity_Skills))
                            {
                                //TF2_StunPlayer(client, Float:duration, Float:slowdown=0.0, stunflags, attacker=0);
                                EmitSoundToAll(roarsound,client);
                                EmitSoundToAll(roarsound,client);
                                TF2_StunPlayer(i, RoarDuration[skilllvl], _, TF_STUNFLAGS_GHOSTSCARE,client);
                                War3_CooldownMGR(client,RoarCooldownTime,thisRaceID,SKILL_ROAR,_,_);
                                GetClientAbsOrigin(client,dragvec);
                                dragvec[2]+=70;
                                if(GetClientTeam(client) == TEAM_RED)
                                {
                                    AttachThrowAwayParticle(client, "particle_nemesis_burst_red", dragvec, "", 1.5);
                                    W3Hint(i,HINT_COOLDOWN_NOTREADY,1.5,"%T","OH GOD A DRAGON",i);
                                }
                                if(GetClientTeam(client) == TEAM_BLUE)
                                {
                                    AttachThrowAwayParticle(client, "particle_nemesis_burst_blue", dragvec, "", 1.5);
                                    W3Hint(i,HINT_COOLDOWN_NOTREADY,1.5,"%T","OH GOD A DRAGON",i);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

public InitPassiveSkills(client)
{
    if(RaceDisabled)
    {
        return;
    }

    if(War3_GetRace(client)==thisRaceID)
    {
        //dragonborn
        new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_DRAGONBORN);
        new bool:value=(GetRandomFloat(0.0,1.0)<=ImmunityChance&&!Hexed(client,false));
        if(value && skilllvl > 0)
        {
            War3_SetBuff(client,bImmunityWards,thisRaceID,1);
            if (skilllvl > 1)
            {
                War3_SetBuff(client,bSlowImmunity,thisRaceID,1);
            }
            if (skilllvl >2)
            {
                War3_SetBuff(client,bImmunitySkills,thisRaceID,1);
            }
            if (skilllvl >3)
            {
                War3_SetBuff(client,bImmunityUltimates,thisRaceID,1);
            }
        }    
        else{
            RemoveImmunity(client);
        }
    }
}
RemoveImmunity(client){
    if(RaceDisabled)
    {
        return;
    }

    War3_SetBuff(client,bImmunityWards,thisRaceID,0);
    War3_SetBuff(client,bImmunitySkills,thisRaceID,0);
    War3_SetBuff(client,bSlowImmunity,thisRaceID,0);
    War3_SetBuff(client,bImmunityUltimates,thisRaceID,0);
}
public OnRaceChanged(client,oldrace,newrace)
{
    if(RaceDisabled)
    {
        return;
    }

    if(newrace==thisRaceID)
    {    
        InitPassiveSkills(client);
    }
    else if(oldrace==thisRaceID)
    {
        War3_SetBuff(client,fArmorPhysical,thisRaceID,0);
        RemoveImmunity(client);
    }
}