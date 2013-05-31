#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

public Plugin:myinfo = 
{
    name = "War3Source - Race - Lich",
    author = "War3Source Team",
    description = "The Lich race for War3Source."
};

new thisRaceID;

new SKILL_FROSTNOVA,SKILL_FROSTARMOR,SKILL_DARKRITUAL,ULT_DEATHDECAY;

//skill 1
new Float:FrostNovaArr[]={1.0,0.95,0.9,0.85,0.8,0.75}; 
new Float:FrostNovaRadius=500.0;
new FrostNovaLoopCountdown[MAXPLAYERSCUSTOM];
new bool:HitOnForwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; //[VICTIM][ATTACKER]
new Float:FrostNovaOrigin[MAXPLAYERSCUSTOM][3];
new Float:AbilityCooldownTime=10.0;

//skill 2
new Float:FrostArmorAmount[]={0.0,1.0,2.0,3.0,4.0}; 

//skill 3
new DarkRitualAmt[]={0,1,2,3,4};

//ultimate
new Handle:ultCooldownCvar;
new Handle:ultRangeCvar;
new DeathDecayAmt[]={0,2,4,6,8};
new String:ultsnd[256]; //="npc/antlion/attack_single2.wav";
new String:novasnd[256]; //="npc/combine_gunship/ping_patrol.wav";
new BeamSprite,HaloSprite; 

public OnPluginStart()
{
    
    ultCooldownCvar=CreateConVar("war3_lich_deathdecay_cooldown","30","Cooldown between ultimate usage");
    ultRangeCvar=CreateConVar("war3_lich_deathdecay_range","99999","Range of death and decay ultimate");
    
    LoadTranslations("w3s.race.lich_o.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==150)
    {
        thisRaceID=War3_CreateNewRaceT("lich_o");
        SKILL_FROSTNOVA=War3_AddRaceSkillT(thisRaceID,"FrostNova",false,4);
        SKILL_FROSTARMOR=War3_AddRaceSkillT(thisRaceID,"FrostArmor",false,4);
        SKILL_DARKRITUAL=War3_AddRaceSkillT(thisRaceID,"DarkRitual",false,4);
        ULT_DEATHDECAY=War3_AddRaceSkillT(thisRaceID,"DeathAndDecay",true,4); 
        War3_CreateRaceEnd(thisRaceID);
        
        War3_AddSkillBuff(thisRaceID, SKILL_FROSTARMOR, fArmorPhysical, FrostArmorAmount);
        War3_AddSkillBuff(thisRaceID, SKILL_FROSTARMOR, fArmorMagic, FrostArmorAmount);
    }

}

public OnMapStart()
{
    War3_AddSoundFolder(ultsnd, sizeof(ultsnd), "lich/attack_single2.mp3");
    War3_AddSoundFolder(novasnd, sizeof(novasnd), "lich/ping_patrol.mp3");

    War3_AddCustomSound(ultsnd);
    War3_AddCustomSound(novasnd);
    BeamSprite=War3_PrecacheBeamSprite();
    HaloSprite=War3_PrecacheHaloSprite();
}

public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
    {
        new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_FROSTNOVA);
        if(skill_level>0)
        {
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_FROSTNOVA,true))
                {
            
                    W3EmitSoundToAll(novasnd,client);
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
                    
                    
                    War3_CooldownMGR(client,AbilityCooldownTime,thisRaceID,SKILL_FROSTNOVA,_,_);
                    //EmitSoundToAll(taunt1,client);//,_,SNDLEVEL_TRAIN);
                    //EmitSoundToAll(taunt1,client);//,_,SNDLEVEL_TRAIN);
                    //EmitSoundToAll(taunt2,client);
                    
                    PrintHintText(client,"%T","Frost Nova!",client);
                
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
        
        new Float:hitRadius=(1.0-FloatAbs(float(FrostNovaLoopCountdown[attacker])-10.0)/10.0)*FrostNovaRadius;
        
        //PrintToChatAll("distance to damage %f",hitRadius);
        
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
                //otherVec[2]+=30.0;
                new Float:victimdistance=GetVectorDistance(FrostNovaOrigin[attacker],otherVec);
                if(victimdistance<FrostNovaRadius&&FloatAbs(otherVec[2]-FrostNovaOrigin[attacker][2])<50)
                {
                    if(FloatAbs(victimdistance-hitRadius)<(FrostNovaRadius/10.0))
                    {
                        
                        HitOnForwardTide[i][attacker]=true;
                        //War3_DealDamage(i,RoundFloat(FrostNovaMaxDamage[War3_GetSkillLevel(attacker,thisRaceID,SKILL_FROSTNOVA)]*victimdistance/FrostNovaRadius/2.0),attacker,DMG_ENERGYBEAM,"FrostNova");
                        War3_SetBuff(i,fSlow,thisRaceID,FrostNovaArr[War3_GetSkillLevel(attacker,thisRaceID,SKILL_FROSTNOVA)]);
                        War3_SetBuff(i,fAttackSpeed,thisRaceID,FrostNovaArr[War3_GetSkillLevel(attacker,thisRaceID,SKILL_FROSTNOVA)]);
                        CreateTimer(5.0,RemoveFrostNova,i);
                        PrintHintText(i,"%T","You were slowed by frost nova!",i);
                    }
                }
            }
        }
    }
}
public Action:RemoveFrostNova(Handle:t,any:client){
    War3_SetBuff(client,fSlow,thisRaceID,1.0);
    War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
}

/*
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
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
                    W3FlashScreen(attacker,RGBA_COLOR_BLUE,0.5,0.4,FFADE_IN);
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
*/    
public OnWar3EventDeath(victim,attacker)
{
    new team;
    if(ValidPlayer(victim)){
        team=GetClientTeam(victim);
    }
    for(new i=1;i<=MaxClients;i++)
    {
        if(War3_GetRace(i)==thisRaceID)
        {

            if(ValidPlayer(i,true)&&GetClientTeam(i)==team)
            {
                new skill=War3_GetSkillLevel(i,thisRaceID,SKILL_DARKRITUAL);
                if(skill>0 && !Silenced(i))
                {
                    new hpadd=DarkRitualAmt[skill];
                    SetEntityHealth(i,GetClientHealth(i)+hpadd);
                    //War3_HealToMaxHP(i,RoundFloat(FloatMul(float(War3_GetMaxHP(i)),float(DarkRitualAmt[skill]))));
                    W3FlashScreen(i,RGBA_COLOR_GREEN,0.5,0.5,FFADE_IN);
                    PrintHintText(i,"%T","Dark Ritual heals you",i);
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
                if(!Silenced(client))
                {
                    new Float:posVec[3];
                    GetClientAbsOrigin(client,posVec);
                    new Float:otherVec[3];
                    new team = GetClientTeam(client);
                    new maxtargets=15;
                    new targetlist[MAXPLAYERSCUSTOM];
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
                        W3MsgNoTargetFound(client,ultmaxdistance);
                    }
                    else
                    {
                        new damage=DeathDecayAmt[ult_level];
                        new damagedealt;
                        for(new i=0;i<targetsfound;i++)
                        {
                            new victim=targetlist[i];
                            if(War3_DealDamage(victim,damage,client,DMG_BULLET,"Death and Decay")) //default magic
                            {
                                damagedealt+=War3_GetWar3DamageDealt();
                                W3FlashScreen(victim,RGBA_COLOR_RED);
                                PrintHintText(victim,"%T","Attacked by Death and Decay",victim);
                            }
                        }
                        PrintHintText(client,"%T","Death and Decay attacked for {amount} total damage!",client,damage*targetsfound);
                        War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_DEATHDECAY,_,_);
                        W3EmitSoundToAll(ultsnd,client);
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

