#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"  
//#include "W3SIncs/War3Source_Effects"

public Plugin:myinfo = 
{
    name = "War3Source - Race - Rarity",
    author = "War3Source Team",
    description = "The Rarity race for War3Source."
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


new SKILL_SMITTEN,SKILL_HEARTACHE,SKILL_SLEEP,ULTIMATE;
///based on succubus HON


new Float:smittenCooldown=15.0;
new Float:smittenDuration=10.0;
new Float:smittenMultiplier[]={1.0,0.9,0.83,0.76,0.7};
new bSmittened[MAXPLAYERSCUSTOM];
new Float:SmittendMultiplier[MAXPLAYERSCUSTOM];


new Float:sleepCooldown=15.0;
new Float:sleepDuration[]={0.0,3.0,3.5,4.0,4.5};
new Float:sleepDistance=400.0;

new Handle:SleepHandle[MAXPLAYERSCUSTOM]; //the trie
new Handle:SleepTimer[MAXPLAYERSCUSTOM]; //the timer that ends the sleep

new Float:heartacheChance[]={0.0,0.06,0.9,0.12,0.15};


new Float:ultDuration[]={0.0,1.5,1.75,2.0,2.25};
new Float:ultDistance=500.0;

new holdingvictim[MAXPLAYERSCUSTOM]; //the victim being held
new Handle:holdingTimer[MAXPLAYERSCUSTOM];

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==220)
    {
        thisRaceID=War3_CreateNewRaceT("rarity");
        SKILL_SMITTEN=War3_AddRaceSkillT(thisRaceID,"Smitten",false,4);
        SKILL_HEARTACHE=War3_AddRaceSkillT(thisRaceID,"Heartache",false,4);
        SKILL_SLEEP=War3_AddRaceSkillT(thisRaceID,"Mesmerize",false,4);
        ULTIMATE=War3_AddRaceSkillT(thisRaceID,"Hold",true,4); 
        War3_CreateRaceEnd(thisRaceID); ///DO NOT FORGET THE END!!!
    }
}

public OnPluginStart()
{
    LoadTranslations("w3s.race.rarity.phrases.txt");
}

public OnMapStart()
{

}
public OnWar3EventSpawn(client){
    if(RaceDisabled)
    {
        return;
    }

    bSmittened[client]=false;
}



public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
    if(RaceDisabled)
    {
        return;
    }

    if(ValidPlayer(victim)&&ValidPlayer(attacker)&&attacker!=victim )
    {
        if(GetClientTeam(victim)!=GetClientTeam(attacker))
        {
            if(bSmittened[attacker]){
                War3_DamageModPercent(SmittendMultiplier[attacker]);
            }
            
        }
        if(SleepHandle[victim]){
            KillTimer(SleepTimer[victim]);
            SleepTimer[victim]=INVALID_HANDLE;
            SleepHandle[attacker]=SleepHandle[victim];
            SleepHandle[victim]=INVALID_HANDLE;
            
            UnSleep(victim);
            new Float:duration;
            GetTrieValue(SleepHandle[attacker],"originalduration",duration);
            SleepTimer[attacker]=CreateTimer(duration,EndSleep,attacker);
            Sleep(attacker);
            
        }
    }
    
    ///need to do sleep transfer, beware of sleep trie which you  need to close
}

public Action:UnSmitten(Handle:timer,any:client)
{
    if(RaceDisabled)
    {
        return;
    }

    bSmittened[client]=false;
}






public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(RaceDisabled)
    {
        return;
    }

    if(!isWarcraft && War3_GetRace(attacker)==thisRaceID ){
        new lvl = War3_GetSkillLevel(attacker,thisRaceID,SKILL_HEARTACHE);
        if(lvl > 0  )
        {
            if(W3Chance(heartacheChance[lvl]*W3ChanceModifier(attacker))    && !IsSkillImmune(victim)  ){
            
                War3_HealToBuffHP(attacker, RoundToFloor(damage));
                PrintToConsole(attacker,"Heartache +%d HP", RoundToFloor(damage));
            }
        }
        
        lvl = War3_GetSkillLevel(attacker,thisRaceID,SKILL_SMITTEN);
        if(lvl > 0)
        {
            if(!IsSkillImmune(victim)){
                if(!Hexed(attacker)&&War3_SkillNotInCooldown(attacker,thisRaceID,SKILL_SMITTEN,false)&&GetClientTeam(attacker)!=GetClientTeam(victim))
                {
                    bSmittened[victim]=true;
                    SmittendMultiplier[victim]=smittenMultiplier[lvl];
                    
                    CreateTimer(smittenDuration,UnSmitten,victim);
                    War3_CooldownMGR(attacker,smittenCooldown,thisRaceID,SKILL_SMITTEN);
                    W3Hint(victim,_,_,"%T","You have been Smittened you do less damage",victim);
                    W3Hint(attacker,_,_,"%T","Activated Smitten",attacker);
                }
            }
        }
    }
}




public bool:AbilityFilter(client)
{
    if(RaceDisabled)
    {
        return false;
    }

    return (!IsSkillImmune(client));
}


public OnAbilityCommand(client,ability,bool:pressed)
{
    if(RaceDisabled)
    {
        return;
    }

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
                    SleepHandle[target]=CreateTrie();
                    SleepTimer[target]=CreateTimer(duration,EndSleep,target);
                    //SetTrieValue(sleepTrie,"timer",timer);
                    //SetTrieValue(sleepTrie,"victim",target);
                    SetTrieValue(SleepHandle[target],"originalduration",duration);
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
    if(RaceDisabled)
    {
        return;
    }

    War3_SetBuff(client,bStunned,thisRaceID,true);
    PrintHintText(client,"%T","You are Mesmerized",client);
    if(GameTF()){
        
    }
}

public Action:EndSleep(Handle:t,any:client){
    if(RaceDisabled)
    {
        return;
    }

    SleepTimer[client]=INVALID_HANDLE;
    CloseHandle(SleepHandle[client]);
    SleepHandle[client]=INVALID_HANDLE;
    
    UnSleep(client);
}
UnSleep(client){
    if(RaceDisabled)
    {
        return;
    }

    War3_SetBuff(client,bStunned,thisRaceID,false);
    PrintHintText(client,"%T","No Longer Mesmerized",client);
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
                    
                    War3_CooldownMGR(client,20.0,thisRaceID,ULTIMATE);
                }
                else{
                    W3MsgNoTargetFound(client,ultDistance);
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
    CleanUP(client);
}
public OnClientDisconnect(client){
    CleanUP(client);
}
CleanUP(client){
    if(holdingvictim[client]){
        TriggerTimer(holdingTimer[client]);
        holdingTimer[client]=INVALID_HANDLE;
    }
    if(SleepTimer[client]){
        UnSleep(client);
        KillTimer(SleepTimer[client]);
        SleepTimer[client]=INVALID_HANDLE;
        CloseHandle(SleepHandle[client]);
        SleepHandle[client]=INVALID_HANDLE;
        
    }
}
