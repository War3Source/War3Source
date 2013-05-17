#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>

public Plugin:myinfo = 
{
    name = "War3Source - Race - Scout",
    author = "War3Source Team",
    description = "The Scout race for War3Source"
};

new thisRaceID;


new SKILL_INVIS, SKILL_TRUESIGHT, SKILL_DISARM, ULT_MARKSMAN;

// Chance/Data Arrays
new Float:InvisDrain=0.05; //as a percent of your health
new Float:InvisDuration[5]={0.0,5.0,6.0,7.0,8.0};
new Handle:InvisEndTimer[MAXPLAYERSCUSTOM];
new bool:InInvis[MAXPLAYERSCUSTOM];

new Float:EyeRadius[5]={0.0,400.0,500.0,700.0,800.0};

new Float:DisarmChance[5]={0.0,0.06,0.10,0.13,0.15};
new Float:MarksmanCrit[5]={0.0,0.15,0.3,0.45,0.6};
new const STANDSTILLREQ=10;


new bool:bDisarmed[MAXPLAYERSCUSTOM];
new Float:lastvec[MAXPLAYERSCUSTOM][3];
new standStillCount[MAXPLAYERSCUSTOM];

// Effects
//new BeamSprite,HaloSprite;

new auras[5];

public OnPluginStart()
{
    

    //UltCooldownCvar=CreateConVar("war3_scout_ult_cooldown","20","Cooldown timer.");
    
    LoadTranslations("w3s.race.scout_o.phrases");
    CreateTimer(0.1,DeciSecondTimer,_,TIMER_REPEAT);
}

public OnMapStart()
{
    //BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
    //HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
    
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==180)
    {
        thisRaceID=War3_CreateNewRaceT("scout_o");
        SKILL_INVIS=War3_AddRaceSkillT(thisRaceID,"Vanish",false,4,"5%","5-8");
        SKILL_TRUESIGHT=War3_AddRaceSkillT(thisRaceID,"TrueSight",false,4,"400-800");
        
        SKILL_DISARM=War3_AddRaceSkillT(thisRaceID,"Disarm",false,4,"6/10/13/15%");
        ULT_MARKSMAN=War3_AddRaceSkillT(thisRaceID,"Marksman",true,4,"1.2-1.6"); 
    
        War3_CreateRaceEnd(thisRaceID);
        
        auras[1] =W3RegisterAura("scout_reveal1",EyeRadius[1],true);
        auras[2] =W3RegisterAura("scout_reveal2",EyeRadius[2],true);
        auras[3] =W3RegisterAura("scout_reveal3",EyeRadius[3],true);    
        auras[4] =W3RegisterAura("scout_reveal4",EyeRadius[4],true);

        //ServerCommand("war3 scout_flags hidden");
        //ServerExecute();
    }
}

public OnRaceChanged(client,oldrace,newrace)
{
    if(newrace==thisRaceID)
    {
        new level=War3_GetSkillLevel(client,thisRaceID,SKILL_TRUESIGHT);
        if(level>0){
            W3SetAuraFromPlayer(auras[level],client,true,level);
        }
    }
    else if(oldrace==thisRaceID){
        ClearAura(client);
    }
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    
    if(race==thisRaceID && War3_GetRace(client)==thisRaceID)
    {
        if(skill==SKILL_TRUESIGHT) //1
        {
            ClearAura(client);
            if(newskilllevel>0){
                W3SetAuraFromPlayer(auras[newskilllevel],client,true,newskilllevel);
            }
        }
    }
}
ClearAura(client){
    W3SetAuraFromPlayer(auras[1],client,false);
    W3SetAuraFromPlayer(auras[2],client,false);
    W3SetAuraFromPlayer(auras[3],client,false);
    W3SetAuraFromPlayer(auras[4],client,false);
}
public OnWar3EventSpawn(client){
    if(bDisarmed[client]){
        EndInvis2(INVALID_HANDLE,client);
    }
    if(InInvis[client]){
        War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
        War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
        InInvis[client]=false;
    }
}
public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID &&  pressed && IsPlayerAlive(client))
    {
        new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_INVIS);
        if(skilllvl > 0)
        {
            if(InInvis[client]){
                TriggerTimer(InvisEndTimer[client]);
                
            }
        
            else if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_INVIS,true))
            {       
            
                War3_SetBuff(client,bDisarm,thisRaceID,true);
                bDisarmed[client]=true;
                War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.03);
                War3_SetBuff(client,fHPDecay,thisRaceID,War3_GetMaxHP(client)*InvisDrain);
                InvisEndTimer[client]=CreateTimer(InvisDuration[skilllvl],EndInvis,client);
                
                
                PrintHintText(client,"%T","You sacrificed part of yourself for invis",client);
                InInvis[client]=true;
                War3_CooldownMGR(client,15.0,thisRaceID,SKILL_INVIS);
                
            }
        }
    }
}
public Action:EndInvis(Handle:timer,any:client)
{
    InInvis[client]=false;
    War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
    War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
    CreateTimer(1.0,EndInvis2,client);
    PrintHintText(client,"%T","No Longer Invis! Cannot shoot for 1 sec!",client);
    
}
public Action:EndInvis2(Handle:timer,any:client){
    War3_SetBuff(client,bDisarm,thisRaceID,false);
    bDisarmed[client]=false;
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
    if(ValidPlayer(victim)&&ValidPlayer(attacker))
    {
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        if(vteam!=ateam)
        {
            if(War3_GetRace(attacker)==thisRaceID && !W3HasImmunity(victim,Immunity_Skills)){
                new lvl=War3_GetSkillLevel(attacker,thisRaceID,ULT_MARKSMAN);
                if(lvl>0&& standStillCount[attacker]>=STANDSTILLREQ){ //stood still for 1 second
                    new Float:vicpos[3];
                    new Float:attpos[3];
                    GetClientAbsOrigin(victim,vicpos);
                    GetClientAbsOrigin(attacker,attpos);
                    new Float:distance=GetVectorDistance(vicpos,attpos);
                    
                    if(distance>1000.0){ //0-512 normal damage 512-1024 linear increase, 1024-> maximum
                        distance=1000.0;
                    }
                    new Float:multi=distance*MarksmanCrit[lvl]/1000.0;
                    War3_DamageModPercent(multi+1.0);
                    PrintToConsole(attacker,"[W3S] %.2fX dmg by marksman shot",multi);
                    
                }
            }
        }
    }
}


public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(!isWarcraft && ValidPlayer(victim,true)&&ValidPlayer(attacker,true)&&GetClientTeam(victim)!=GetClientTeam(attacker))
    {    
        if(War3_GetRace(attacker)==thisRaceID)
        {
            new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_DISARM);
            if(skill_level>0&&!Hexed(attacker,false))
            {
                if(!W3HasImmunity(victim,Immunity_Skills) && !bDisarmed[victim]){
                
                    if(  W3Chance(DisarmChance[skill_level]*W3ChanceModifier(attacker))  ){
                        War3_SetBuff(victim,bDisarm,thisRaceID,true);
                        CreateTimer(0.5,Undisarm,victim);
                    }
                }
            }
        }
    }           
}
public Action:Undisarm(Handle:t,any:client){
    War3_SetBuff(client,bDisarm,thisRaceID,false);
}


public Action:DeciSecondTimer(Handle:t){
    for(new client=1;client<=MaxClients;client++){\
        if(ValidPlayer(client,true)&&War3_GetRace(client)==thisRaceID){
            static Float:vec[3];
            GetClientAbsOrigin(client,vec);
            if(GetVectorDistance(vec,lastvec[client])>1.0){
                standStillCount[client]=0;
            }
            else{
                standStillCount[client]++;
            }
            lastvec[client][0]=vec[0];
            lastvec[client][1]=vec[1];
            lastvec[client][2]=vec[2];
        }
    }
}

public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && IsPlayerAlive(client) && pressed)
    {
        new skill_level=War3_GetSkillLevel(client,race,SKILL_TRUESIGHT);
        if(skill_level>0)
        {
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_TRUESIGHT,true)){
                
                
            }
        }
        else
        {
            //print no eyes availabel
        }
    }
}
public OnW3PlayerAuraStateChanged(client,tAuraID,bool:inAura,level){
    if(tAuraID==auras[1]||
    tAuraID==auras[2]||
    tAuraID==auras[3]||
    tAuraID==auras[4]){
        War3_SetBuff(client,bInvisibilityDenyAll,thisRaceID,inAura);
        
    }
    
}