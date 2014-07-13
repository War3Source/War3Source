#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include "W3SIncs/War3Source_Interface"  

public Plugin:myinfo = 
{
    name = "War3Source - Race - Fluttershy",
    author = "War3Source Team",
    description = "The Fluttershy race for War3Source."
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

new SKILL_STARE,SKILL_TOLERATE,SKILL_KINDNESS,ULTIMATE_YOUBEGENTLE;
new AuraID;
new Float:HealingWaveDistance[5]={0.0,100.0,125.0,150.0,175.0};
new Float:starerange=300.0;
new Float:StareDuration[5]={0.0,1.5,2.0,2.5,3.0};
new Float:ArmorPhysical[5]={0.0,0.5,1.0,1.5,2.0};

new Float:HealAmount[5]={0.0,2.0,4.0,6.0,8.0};

new Float:NotBadDuration[5]={0.0,1.0,1.3,1.6,1.8};
new bNoDamage[MAXPLAYERSCUSTOM];
public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==210)
    {
        thisRaceID=War3_CreateNewRaceT("fluttershy");
        SKILL_STARE=War3_AddRaceSkillT(thisRaceID,"StareMaster",false,4);
        SKILL_TOLERATE=War3_AddRaceSkillT(thisRaceID,"Tolerate",false,4); 
        SKILL_KINDNESS=War3_AddRaceSkill(thisRaceID,"Kindness","Heals you and your teammates when both of you are very close, up to 8HP per sec");
    
        ULTIMATE_YOUBEGENTLE=War3_AddRaceSkillT(thisRaceID,"BeGentle",true,4); 
        War3_CreateRaceEnd(thisRaceID); ///DO NOT FORGET THE END!!!
        
        
        AuraID=W3RegisterChangingDistanceAura("fluttershy_healwave");
    }
}

public OnPluginStart()
{
    LoadTranslations("w3s.race.fluttershy.phrases.txt");
}

public OnUltimateCommand(client,race,bool:pressed)
{
    if(RaceDisabled)
    {
        return;
    }

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
                    PrintHintText(client,"%t","You be gentle!",client);
                    PrintHintText(target,"%t","You be gentle!Cannot deal bullet damage",client);
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
    if(RaceDisabled)
    {
        return;
    }

    bNoDamage[client]=false;
}
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage){
    if(RaceDisabled)
    {
        return;
    }

    if(ValidPlayer(attacker)&&bNoDamage[attacker]){
        War3_DamageModPercent(0.0);
    }
} 

new StareVictim[MAXPLAYERSCUSTOM];

public OnAbilityCommand(client,ability,bool:pressed)
{
    if(RaceDisabled)
    {
        return;
    }

    if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && ability==0 && pressed )
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
                    PrintHintText(client,"%t","STOP AND STARE",client);
                    PrintHintText(target,"%t","You are being stared at.Don't look at her in the eye!!!",client);
                    CreateTimer(StareDuration[skilllvl],EndStare,client);
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
    if(RaceDisabled)
    {
        return;
    }

    War3_SetBuff(client,bBashed,thisRaceID,false);
    War3_SetBuff(client,bDisarm,thisRaceID,false);
    War3_SetBuff(StareVictim[client],bBashed,thisRaceID,false);
    War3_SetBuff(StareVictim[client],bDisarm,thisRaceID,false);
    StareVictim[client]=0;
}

public OnWar3EventDeath(client){ //end stare if fluttershy dies
    if(RaceDisabled)
    {
        return;
    }

    if(ValidPlayer(client))
    {
        War3_SetBuff(client,bBashed,thisRaceID,false);
        War3_SetBuff(client,bDisarm,thisRaceID,false);
        War3_SetBuff(StareVictim[client],bBashed,thisRaceID,false);
        War3_SetBuff(StareVictim[client],bDisarm,thisRaceID,false);
        StareVictim[client]=0;
    }
}







public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    if(RaceDisabled)
    {
        return;
    }

    if(race==thisRaceID &&skill==SKILL_TOLERATE)    {
        War3_SetBuff(client,fArmorPhysical,thisRaceID,ArmorPhysical[newskilllevel]);
    }
    if(race==thisRaceID &&skill==SKILL_KINDNESS) //1
    {
        W3RemovePlayerAura(AuraID,client);
        if(newskilllevel>0)
        {
            W3SetPlayerAura(AuraID,client,HealingWaveDistance[newskilllevel],newskilllevel);
        }
    }
}

public OnW3PlayerAuraStateChanged(client,aura,bool:inAura,level)
{
    if(RaceDisabled)
    {
        return;
    }

    if(aura==AuraID&&inAura==false) //lost aura, remove helaing
    {
        War3_SetBuff(client,fHPRegen,thisRaceID,0.0);
        //DP("%d %f",inAura,HealingWaveAmountArr[level]);
    }
}
public OnWar3Event(W3EVENT:event,client){
    if(RaceDisabled)
    {
        return;
    }

    if(event==OnAuraCalculationFinished){
        RecalculateHealing();
    //    DP("re");
    }
}
RecalculateHealing(){
    if(RaceDisabled)
    {
        return;
    }

    new level;
    new playerlist[66];
    new auralevel[66];
    new auraactivated[66];
    new playercount=0;

    for(new client=1;client<=MaxClients;client++)
    {
        if(ValidPlayer(client,true)&&W3HasAura(AuraID,client,level)){
            for(new i=0;i<playercount;i++){
                if(GetPlayerDistance(playerlist[i],client)<HealingWaveDistance[level]){
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
