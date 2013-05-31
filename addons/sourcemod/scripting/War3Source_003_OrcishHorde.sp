/**
 * File: War3Source_OrcishHorde.sp
 * Description: The Orcish Horde race for War3Source.
 * Author(s): Anthony Iacono 
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

#include <cstrike>

public Plugin:myinfo = 
{
    name = "War3Source - Race - Orcish Horde",
    author = "War3Source Team",
    description = "The Orcish Horde race for War3Source."
};

new thisRaceID;
new bool:bHasRespawned[MAXPLAYERSCUSTOM]; //cs
new Handle:RespawnDelayCvar;
new Handle:ultCooldownCvar;

new bool:bBeenHit[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; // [caster][victim] been hit this chain lightning?


new MyWeaponsOffset,AmmoOffset;

// Chance/Data Arrays
new Float:ReincarnationChance[5]={0.0,0.15,0.37,0.59,0.8};
new Float:CriticalStrikePercent[5]={0.0,0.33,0.66,1.01,1.33}; 
new Float:CriticalGrenadePercent[5]={0.0,0.7,1.2,1.7,2.2};
new Float:ChainDistance[5]={0.0,150.0,200.0,250.0,300.0};


new Float:WindWalkAlpha[5]={1.0,0.84,0.68,0.56,0.40};
new Float:WindWalkVisibleDuration[5]={5.0,4.2,3.4,2.6,2.0};
// TF2 Specific
new Float:WindWalkReinvisTime[MAXPLAYERSCUSTOM]; //when can he invis again?

new Handle:hCvarDisableCritWithGloves;

new MaximumWards[]={0,1,2,3,4}; 
new HealAmount[]={0,1,2,3,5};

new String:lightningSound[256]; //="war3source/lightningbolt.mp3";

new SKILL_CRIT,SKILL_NADE_INVIS,SKILL_RECARN_WARD,ULT_LIGHTNING;
// Effects
new BeamSprite,HaloSprite,BloodSpray,BloodDrop; 

public OnPluginStart()
{  

    HookEvent("round_start",RoundStartEvent);
    RespawnDelayCvar=CreateConVar("war3_orc_respawn_delay","1","How long before spawning for reincarnation?");
    ultCooldownCvar=CreateConVar("war3_orc_chain_cooldown","20","Cooldown time for chain lightning.");

    hCvarDisableCritWithGloves=CreateConVar("war3_orc_nocritgloves","1","Disable nade crit with gloves");
    
    MyWeaponsOffset=FindSendPropOffs("CBaseCombatCharacter","m_hMyWeapons");
    AmmoOffset=FindSendPropOffs("CBasePlayer","m_iAmmo");
    CreateTimer(0.1,DeciSecondTimer,_,TIMER_REPEAT);
    
    LoadTranslations("w3s.race.orc.phrases");
}  
   

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==30)
    {
    
        new String:skill1_name[64]="CriticalGrenade";
        new String:skill2_name[64]="Reincarnation";
        if(War3_GetGame()==Game_TF)
        {
            strcopy(skill1_name,sizeof(skill1_name),"WindWalker");
            strcopy(skill2_name,sizeof(skill2_name),"HealingWard");
        }
        
        thisRaceID=War3_CreateNewRaceT("orc");
        SKILL_CRIT=War3_AddRaceSkillT(thisRaceID,"CriticalStrike",false,4);
        SKILL_NADE_INVIS=War3_AddRaceSkillT(thisRaceID,skill1_name,false,4);
        SKILL_RECARN_WARD=War3_AddRaceSkillT(thisRaceID,skill2_name,false,4);
        ULT_LIGHTNING=War3_AddRaceSkillT(thisRaceID,"ChainLightning",true,4); //TEST
        
        
        W3SkillCooldownOnSpawn(thisRaceID,ULT_LIGHTNING,10.0,_); //translated doesnt use this "Chain Lightning"?
        War3_CreateRaceEnd(thisRaceID);
    
    }
}

public OnMapStart()
{
    War3_AddSoundFolder(lightningSound, sizeof(lightningSound), "lightningbolt.mp3");

    BeamSprite=War3_PrecacheBeamSprite(); 
    HaloSprite=War3_PrecacheHaloSprite(); 
    
    
    BloodSpray = PrecacheModel("sprites/bloodspray.vmt");
    if(GAMECSGO) {
        BloodDrop = PrecacheModel("decals/blood1.vmt");
    }
    else {
        BloodDrop = PrecacheModel("sprites/blood.vmt");
    }

    War3_AddCustomSound(lightningSound);
}

public OnRaceChanged(client,oldrace,newrace)
{
    if(oldrace==thisRaceID && War3_GetGame()==Game_TF)
    {
        War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0); // for tf2, remove alpha
        War3_SetBuff(client,bInvisibilityDenySkill,thisRaceID,false);
        WindWalkReinvisTime[client]=0.0;
    }
}



public DoChain(client,Float:distance,dmg,bool:first_call,last_target)
{
    new target=0;
    new Float:target_dist=distance+1.0; // just an easy way to do this
    new caster_team=GetClientTeam(client);
    new Float:start_pos[3];
    if(last_target<=0)
        GetClientAbsOrigin(client,start_pos);
    else
        GetClientAbsOrigin(last_target,start_pos);
    for(new x=1;x<=MaxClients;x++)
    {
        if(ValidPlayer(x,true)&&!bBeenHit[client][x]&&caster_team!=GetClientTeam(x)&&!W3HasImmunity(x,Immunity_Ultimates))
        {
            new Float:this_pos[3];
            GetClientAbsOrigin(x,this_pos);
            new Float:dist_check=GetVectorDistance(start_pos,this_pos);
            if(dist_check<=target_dist)
            {
                // found a candidate, whom is currently the closest
                target=x;
                target_dist=dist_check;
            }
        }
    }
    if(target<=0)
    {
    //DP("no target");
        // no target, if first call dont do cooldown
        if(first_call)
        {
            W3MsgNoTargetFound(client,distance);
        }
        else
        {
            // alright, time to cooldown
            new Float:cooldown=GetConVarFloat(ultCooldownCvar);
            War3_CooldownMGR(client,cooldown,thisRaceID,ULT_LIGHTNING,_,_);
            //DP("CD %f %d %d",cooldown,thisRaceID,ULT_LIGHTNING);
        }
    }
    else
    {
        // found someone
        bBeenHit[client][target]=true; // don't let them get hit twice
        War3_DealDamage(target,dmg,client,DMG_ENERGYBEAM,"chainlightning");
        PrintHintText(target,"%T","Hit by Chain Lightning -{amount} HP",target,War3_GetWar3DamageDealt());
        start_pos[2]+=30.0; // offset for effect
        decl Float:target_pos[3],Float:vecAngles[3];
        GetClientAbsOrigin(target,target_pos);
        target_pos[2]+=30.0;
        TE_SetupBeamPoints(start_pos,target_pos,BeamSprite,HaloSprite,0,35,1.0,25.0,25.0,0,10.0,{255,100,255,255},40);
        TE_SendToAll();
        GetClientEyeAngles(target,vecAngles);
        TE_SetupBloodSprite(target_pos, vecAngles, {200, 20, 20, 255}, 28, BloodSpray, BloodDrop);
        TE_SendToAll();
        EmitSoundToAll( lightningSound , target,_,SNDLEVEL_TRAIN);
        new new_dmg=RoundFloat(float(dmg)*0.66);
        
        DoChain(client,distance,new_dmg,false,target);
    }
}

public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && IsPlayerAlive(client))
    {
        new skill=War3_GetSkillLevel(client,race,ULT_LIGHTNING);
        if(skill>0)
        {
            
            if(War3_SkillNotInCooldown(client,thisRaceID,ULT_LIGHTNING,true)&&!Silenced(client))
            {
                    
                for(new x=1;x<=MaxClients;x++)
                    bBeenHit[client][x]=false;
                
                new Float:distance=ChainDistance[skill];
                
                DoChain(client,distance,60,true,0); // This function should also handle if there aren't targets
            }
        }
        else
        { 
            W3MsgUltNotLeveled(client);
        }
    }
}


public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetGame()==Game_TF && War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
    {
        new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_RECARN_WARD);
        if(skill_level>0&&!Silenced(client))
        {
            if(War3_GetWardCount(client) < MaximumWards[skill_level])
            {
                new Float:location[3];
                GetClientAbsOrigin(client, location);
                War3_CreateWardMod(client, location, 70, 300.0, 1.0, "heal", SKILL_RECARN_WARD, HealAmount, WARD_TARGET_TEAMMATES);
                
                W3MsgCreatedWard(client,War3_GetWardCount(client),MaximumWards[skill_level]);
            }
            else
            {
                W3MsgNoWardsLeft(client);
            }    
        }
    }
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    if(War3_GetGame()==Game_TF&&race==thisRaceID&&skill==SKILL_NADE_INVIS&&newskilllevel>=0&&War3_GetRace(client)==thisRaceID)
    {
        new Float:alpha=WindWalkAlpha[newskilllevel];
        War3_SetBuff(client,fInvisibilitySkill,thisRaceID,alpha);
        War3_SetBuff(client,bInvisibilityDenySkill,thisRaceID,false);
        WindWalkReinvisTime[client]=0.0;
        if(newskilllevel>0 && IsPlayerAlive(client)) // dont tell them if they are dead
        {
            if(newskilllevel==1)
            {
                War3_ChatMessage(client,"%T","You fade slightly into the backdrop",client);
            }
            else if(newskilllevel==2)
            {
                War3_ChatMessage(client,"%T","You fade well into the backdrop",client);
            }
            else if(newskilllevel==3)
            {
                War3_ChatMessage(client,"%T","You fade greatly into the backdrop",client);
            }
            else
            {
                War3_ChatMessage(client,"%T","You fade dramatically into the backdrop",client);
            }
        }
    }
}

public OnWar3EventSpawn(client)
{
    for(new x=1;x<=MaxClients;x++)
        bBeenHit[client][x]=false;
    
    if(War3_GetGame()==Game_TF && War3_GetRace(client)==thisRaceID)
    {
        new skill_wind=War3_GetSkillLevel(client,thisRaceID,SKILL_NADE_INVIS);
        if(skill_wind>0)
        {
            new Float:alpha=WindWalkAlpha[skill_wind];
            War3_SetBuff(client,fInvisibilitySkill,thisRaceID,alpha);
            War3_SetBuff(client,bInvisibilityDenySkill,thisRaceID,false);
        }
    }
    WindWalkReinvisTime[client]=0.0; 
}

new damagestackcritmatch=-1;
new Float:critpercent=0.0;
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
    {
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        if(vteam!=ateam)
        {
            new race_attacker=War3_GetRace(attacker);
            new Float:chance_mod=W3ChanceModifier(attacker);
            if(race_attacker==thisRaceID)
            {
                new skill_cs_attacker=War3_GetSkillLevel(attacker,race_attacker,SKILL_CRIT);
                if(skill_cs_attacker>0&&!Hexed(attacker,false))
                {
                    new Float:chance=0.15*chance_mod;
                    if( GetRandomFloat(0.0,1.0)<=chance && !W3HasImmunity(victim,Immunity_Skills))
                    {
                        damagestackcritmatch=W3GetDamageStack();
                        new Float:percent=CriticalStrikePercent[skill_cs_attacker]; //0.0 = zero effect -1.0 = no damage 1.0=double damage
                        War3_DamageModPercent(percent+1.0);
                        critpercent=percent;
                    }
                }
            }
        }
    }
}

//need event for weapon string
public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(victim>0&&attacker>0&&victim!=attacker)
    {
        new race_attacker=War3_GetRace(attacker);
        
        if(race_attacker==thisRaceID)
        {
            if(damagestackcritmatch==W3GetDamageStack()){
                damagestackcritmatch=-1;
                W3PrintSkillDmgHintConsole(victim,attacker,RoundFloat(damage*critpercent/(critpercent+1.0)),SKILL_CRIT);    
                W3FlashScreen(victim,RGBA_COLOR_RED);    
            }
        }
            
            
        if(War3_GetGame()==Game_TF)
        {
            if(race_attacker==thisRaceID)
            {
                //hurt someone else, no invis
                new skill_wind=War3_GetSkillLevel(attacker,thisRaceID,SKILL_NADE_INVIS);
                if(skill_wind>0)
                {
                    new Float:fix_delay=WindWalkVisibleDuration[skill_wind];
                    War3_SetBuff(attacker,bInvisibilityDenySkill,thisRaceID,true); // make them visible, override so shop can't screw up
                    WindWalkReinvisTime[attacker]=GetGameTime()+fix_delay;
                }
                
                
                
            }
            //getting hurt = no invis allowed
            if(War3_GetRace(victim)==thisRaceID){
                new skill_wind=War3_GetSkillLevel(victim,thisRaceID,SKILL_NADE_INVIS);
                if(skill_wind>0)
                {
                    new Float:fix_delay=WindWalkVisibleDuration[skill_wind];
                    War3_SetBuff(victim,bInvisibilityDenySkill,thisRaceID,true); // make them visible, override so shop can't screw up
                    WindWalkReinvisTime[victim]=GetGameTime()+fix_delay;
                }
            }
        }
        else   //cs
        {
            
            new skill_cg_attacker=War3_GetSkillLevel(attacker,race_attacker,SKILL_NADE_INVIS);
            if(race_attacker==thisRaceID && skill_cg_attacker>0 && !Hexed(attacker,false))
            {
                new gloveitem=War3_GetItemIdByShortname("glove");
                if(GetConVarInt(hCvarDisableCritWithGloves)>0&&gloveitem>0&&War3_GetOwnsItem(attacker,gloveitem)){
                    ///no crit nade of he has gloves
                }
                else
                {
                    if(StrEqual(weapon,"hegrenade",false) && !W3HasImmunity(victim,Immunity_Skills))
                    {
                        new Float:percent=CriticalGrenadePercent[skill_cg_attacker];
                        new originaldamage=RoundToFloor(damage);
                        new health_take=RoundFloat((damage*percent));
                        
                        new onehp=false;
                        ///you cannot die from orc nade unless the usual nade damage kills you
                        if(GetClientHealth(victim)>originaldamage&&health_take>GetClientHealth(victim)){
                                health_take=GetClientHealth(victim) -1;
                                onehp=true;
                        }
                        ////new new_health=GetClientHealth(victim)-health_take;
                        //if(new_health<0)
                        //    new_health=0;
                        //SetEntityZHealth(victim,new_health);
                        if(War3_DealDamage(victim,health_take,attacker,_,"criticalnade",W3DMGORIGIN_SKILL,W3DMGTYPE_TRUEDMG))
                        {
                            W3PrintSkillDmgHintConsole(victim,attacker,War3_GetWar3DamageDealt(),SKILL_NADE_INVIS);
                            W3FlashScreen(victim,RGBA_COLOR_RED);
                            if(onehp){
                                SetEntityHealth(victim,1); 
                            }
                            decl Float:fPos[3];
                            GetClientAbsOrigin(victim,fPos);
                            new Float:fx_delay = 0.35;
                            for(new i=0;i<4;i++)
                            {
                                TE_SetupExplosion(fPos, BeamSprite, 4.5, 1, 4, 0, TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_ROTATE);
                                TE_SendToAll(fx_delay);
                                fx_delay += GetRandomFloat(0.30,0.50);
                            }
                        }
                        
                    }
                }
            }
        }
    }
}


public OnWar3EventDeath(index,attacker)
{    
    if(ValidPlayer(index)){
        new race=W3GetVar(DeathRace); //get  immediate variable, which indicates the race of the player when he died
        if(race==thisRaceID&&!bHasRespawned[index]&&War3_GetGame()!=Game_TF)
        {
            new skill=War3_GetSkillLevel(index,race,SKILL_RECARN_WARD);
            if(skill) //let them revive even if hexed
            {
                new Float:percent=ReincarnationChance[skill];
                if(GetRandomFloat(0.0,1.0)<=percent)
                {
                    new Float:delay_spawn=GetConVarFloat(RespawnDelayCvar);
                    if(delay_spawn<0.25)
                        delay_spawn=0.25;
                    CreateTimer(delay_spawn,RespawnPlayer,index);
                    PrintHintText(index,"%T","REINCARNATION IN {amount} SECONDS!",index,delay_spawn);
                    
                }
            }
        }
    }
}

public Action:RespawnPlayer(Handle:timer,any:client)
{
    if(ValidPlayer(client)&&!IsPlayerAlive(client)&&GetClientTeam(client)>1)
    {
        War3_SpawnPlayer(client);
        new Float:pos[3];
        new Float:ang[3];
        War3_CachedAngle(client,ang);
        War3_CachedPosition(client,pos);
        TeleportEntity(client,pos,ang,NULL_VECTOR);
        // cool, now remove their weapons besides knife and c4 
        for(new slot=0;slot<10;slot++)
        {
            new ent=GetEntDataEnt2(client,MyWeaponsOffset+(slot*4));
            if(ent>0 && IsValidEdict(ent))
            {
                new String:ename[64];
                GetEdictClassname(ent,ename,64);
                if(StrEqual(ename,"weapon_c4") || StrEqual(ename,"weapon_knife"))
                {
                    continue; // don't think we need to delete these
                }
                W3DropWeapon(client,ent);
                UTIL_Remove(ent);
            }
        }
        // restore iAmmo
        for(new ammotype=0;ammotype<32;ammotype++)
        {
            SetEntData(client,AmmoOffset+(ammotype*4),War3_CachedDeadAmmo(client,ammotype),4);
        }
        // give them their weapons
        for(new slot=0;slot<10;slot++)
        {
            new String:wep_check[64];
            War3_CachedDeadWeaponName(client,slot,wep_check,64);
            //PrintToChatAll("zz %s",wep_check);
            if(!StrEqual(wep_check,"weapon_c4") && !StrEqual(wep_check,"weapon_knife"))
            {
                new wep_ent=GivePlayerItem(client,wep_check);
                if(wep_ent>0) 
                {
                    ///dont set clip
                    //SetEntData(wep_ent,Clip1Offset,War3_CachedDeadClip1(client,slot),4);
                }
            }
        }
        bHasRespawned[client]=true;
        War3_ChatMessage(client,"%T","Reincarnated via skill",client);
    }
    else{
        //gone or respawned via some other race/item
        bHasRespawned[client]=false;
    }
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new x=1;x<=64;x++)
        bHasRespawned[x]=false;
}

public Action:DeciSecondTimer(Handle:h)
{
    if(War3_GetGame()==Game_TF){
        
        for(new x=1;x<=MaxClients;x++)
        {
            if(ValidPlayer(x,true))
            {
                if(WindWalkReinvisTime[x]!=0.0 && GetGameTime()>WindWalkReinvisTime[x])
                {
                    War3_SetBuff(x,bInvisibilityDenySkill,thisRaceID,false);//can invis again
                    WindWalkReinvisTime[x]=0.0;
                }
            }
        }
    }
}
