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
    name = "War3Source - Race - Corrupted Disciple",
    author = "War3Source Team",
    description = "The Corrupted Disciple race for War3Source."
};

new thisRaceID;
new Handle:ultCooldownCvar;

new SKILL_TIDE, SKILL_CONDUIT, SKILL_STATIC, ULT_OVERLOAD;


// Chance/Data Arrays
new ElectricTideMaxDamage[5]={0,40,60,100,140};
new Float:ElectricTideRadius=375.0;
new Float:AbilityCooldownTime=15.0;

new ConduitPerHit[5]={0,1,1,2,2};
new ConduitDuration=10;
new ConduitCooldown=15;
new ConduitMaxHeal[5]={0,4,6,8,10};

new Float:StaticHealPercent[5]={0.0,0.15,0.30,0.45,0.60};
new StaticHealRadius=800;

new OverloadDuration=60; //HIT TIMES, DURATION DEPENDS ON TIMER
new OverloadRadius=350;
new OverloadDamagePerHit[5]={0,3,6,8,10};
new Float:OverloadDamageIncrease[5]={1.0,1.01,1.015,1.020,1.025};
////


new Float:ElectricTideOrigin[MAXPLAYERSCUSTOM][3];
new ElectricTideLoopCountdown[MAXPLAYERSCUSTOM];

new bool:HitOnForwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; //[VICTIM][ATTACKER]
new bool:HitOnBackwardTide[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM];



new Float:ConduitUntilTime[MAXPLAYERSCUSTOM]; // less than 1.0 is considered not activated, eles if curren ttime is more than  GetGameTime()
new ConduitSubtractDamage[MAXPLAYERSCUSTOM];
new ConduitBy[MAXPLAYERSCUSTOM]; //[VICTIM]


new UltimateZapsRemaining[MAXPLAYERSCUSTOM];
new Float:PlayerDamageIncrease[MAXPLAYERSCUSTOM];

new String:taunt1[256]; //="war3source/cd/feeltheburn2.mp3";
new String:taunt2[256]; //="war3source/cd/feeltheburn3.mp3";

new String:overload1[256]; //="war3source/cd/overload2.mp3";
new String:overloadzap[256]; //="war3source/cd/overloadzap.mp3";
new String:overloadstate[256]; //="war3source/cd/ultstate.mp3";

// Effects
new BeamSprite,HaloSprite; 

public OnPluginStart()
{
    HookEvent("player_hurt",PlayerHurtEvent);
    ultCooldownCvar=CreateConVar("war3_cd_ult_cooldown","30","Cooldown time for CD ult overload.");
    CreateTimer(0.2,CalcConduit,_,TIMER_REPEAT);
    
    LoadTranslations("w3s.race.cd.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==90)
    {
        thisRaceID=War3_CreateNewRaceT("cd");
        SKILL_TIDE=War3_AddRaceSkillT(thisRaceID,"ElectricTide",false,4);
        SKILL_CONDUIT=War3_AddRaceSkillT(thisRaceID,"CorruptedConduit",false,4);
        SKILL_STATIC=War3_AddRaceSkillT(thisRaceID,"StaticDischarge",false,4);
        ULT_OVERLOAD=War3_AddRaceSkillT(thisRaceID,"Overload",true,4); 
        War3_CreateRaceEnd(thisRaceID);
        
        W3SkillCooldownOnSpawn(thisRaceID,ULT_OVERLOAD,10.0,_); //translated doesnt use this "Chain Lightning"
    }

}

public OnMapStart()
{
    War3_AddSoundFolder(taunt1, sizeof(taunt1), "cd/feeltheburn2.mp3");
    War3_AddSoundFolder(taunt2, sizeof(taunt2), "cd/feeltheburn3.mp3");
    War3_AddSoundFolder(overload1, sizeof(overload1), "cd/overload2.mp3");
    War3_AddSoundFolder(overloadzap, sizeof(overloadzap), "cd/overloadzap.mp3");
    War3_AddSoundFolder(overloadstate, sizeof(overloadstate), "cd/ultstate.mp3");

    BeamSprite=War3_PrecacheBeamSprite();
    HaloSprite=War3_PrecacheHaloSprite();
    
    War3_AddCustomSound(taunt1);
    War3_AddCustomSound(taunt2);
    War3_AddCustomSound(overload1);
    War3_AddCustomSound(overloadzap);
    War3_AddCustomSound(overloadstate);
}



public OnAbilityCommand(client,ability,bool:pressed)
{
    if(/*War3_GetRace(client)==thisRaceID &&*/ ability==0 && pressed && ValidPlayer(client, true))
    {
        new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_TIDE);
        if(skill_level>0)
        {
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_TIDE,true))
            {
                GetClientAbsOrigin(client,ElectricTideOrigin[client]);
                ElectricTideOrigin[client][2]+=15.0;
                ElectricTideLoopCountdown[client]=20;
                
                for(new i=1;i<=MaxClients;i++){
                    HitOnBackwardTide[i][client]=false;
                    HitOnForwardTide[i][client]=false;
                }
                //50 IS THE CLOSE CHECK
                TE_SetupBeamRingPoint(ElectricTideOrigin[client], 20.0, ElectricTideRadius+50, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {255,0,255,133}, 60, 0);
                TE_SendToAll();
                
                CreateTimer(0.1,BurnLoop,GetClientUserId(client)); //damage
                CreateTimer(0.13,BurnLoop,GetClientUserId(client)); //damage
                CreateTimer(0.17,BurnLoop,GetClientUserId(client)); //damage
                
                CreateTimer(0.5,SecondRing,GetClientUserId(client));
                
                War3_CooldownMGR(client,AbilityCooldownTime,thisRaceID,SKILL_TIDE,_,_);
                W3EmitSoundToAll(taunt1,client);//,_,SNDLEVEL_TRAIN);
                W3EmitSoundToAll(taunt1,client);//,_,SNDLEVEL_TRAIN);
                W3EmitSoundToAll(taunt2,client);
                
                PrintHintText(client,"%T","Feel the burn!",client);
            }
        }
    }
}

public Action:SecondRing(Handle:timer,any:userid)
{
    new client=GetClientOfUserId(userid);
    TE_SetupBeamRingPoint(ElectricTideOrigin[client], ElectricTideRadius+50,20.0, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {255,0,255,133}, 60, 0);
    TE_SendToAll();
}
public Action:BurnLoop(Handle:timer,any:userid)
{
    new attacker=GetClientOfUserId(userid);
    if(ValidPlayer(attacker) && ElectricTideLoopCountdown[attacker]>0)
    {
        new team = GetClientTeam(attacker);
        //War3_DealDamage(victim,damage,attacker,DMG_BURN);
        CreateTimer(0.1,BurnLoop,userid);
        
        new Float:damagingRadius=(1.0-FloatAbs(float(ElectricTideLoopCountdown[attacker])-10.0)/10.0)*ElectricTideRadius;
        
        //PrintToChatAll("distance to damage %f",damagingRadius);
        
        ElectricTideLoopCountdown[attacker]--;
        
        new Float:otherVec[3];
        for(new i=1;i<=MaxClients;i++)
        {
            if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Skills))
            {
                if(ElectricTideLoopCountdown[attacker]<10){
                    if(HitOnBackwardTide[i][attacker]==true){
                        continue;
                    }
                }
                else{
                    if(HitOnForwardTide[i][attacker]==true){
                        continue;
                    }
                }    
                    
                GetClientAbsOrigin(i,otherVec);
                otherVec[2]+=30.0;
                new Float:victimdistance=GetVectorDistance(ElectricTideOrigin[attacker],otherVec);
                if(victimdistance<ElectricTideRadius&&FloatAbs(otherVec[2]-ElectricTideOrigin[attacker][2])<25)
                {
                    if(FloatAbs(victimdistance-damagingRadius)<(ElectricTideRadius/10.0))
                    {
                        if(ElectricTideLoopCountdown[attacker]<10){
                            HitOnBackwardTide[i][attacker]=true;
                        }
                        else{
                            HitOnForwardTide[i][attacker]=true;
                        }
                        War3_DealDamage(i,RoundFloat(ElectricTideMaxDamage[War3_GetSkillLevel(attacker,thisRaceID,SKILL_TIDE)]*victimdistance/ElectricTideRadius/2.0),attacker,DMG_ENERGYBEAM,"electrictide");
                    }
                    
                }
            }
        }
    }
    
}


public OnWar3EventSpawn(client){
    UltimateZapsRemaining[client]=0;
}
public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && IsPlayerAlive(client))
    {
        //if(
        
        new skill=War3_GetSkillLevel(client,thisRaceID,ULT_OVERLOAD);
        if(skill>0)
        {
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_OVERLOAD,true))
            {
                UltimateZapsRemaining[client]=OverloadDuration;
            
                PlayerDamageIncrease[client]=1.0;
                War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_OVERLOAD,_,_);
                
                CreateTimer(0.25,UltimateLoop,GetClientUserId(client)); //damage
                
                W3EmitSoundToAll(overload1,client);
                W3EmitSoundToAll(overload1,client);
                
                W3EmitSoundToAll(overloadstate,client);
                CreateTimer(3.7,UltStateSound,client);
            }
            
        }
        else
        {
            W3MsgUltNotLeveled(client);
        }
    }
}
public Action:UltimateLoop(Handle:timer,any:userid)
{
    new attacker=GetClientOfUserId(userid);
    if(ValidPlayer(attacker) && UltimateZapsRemaining[attacker]>0&&IsPlayerAlive(attacker))
    {
        UltimateZapsRemaining[attacker]--;
        new Float:pos[3];
        new Float:otherpos[3];
        GetClientEyePosition(attacker,pos);
        new team = GetClientTeam(attacker);
        new lowesthp=99999;
        new besttarget=0;

        for(new i=1;i<=MaxClients;i++){
            if(ValidPlayer(i,true)){
                
                if(GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Ultimates)){
                    GetClientAbsOrigin(i,otherpos);
                    //if(War3_GetGame()==Game_CS){
                    //    otherpos[2]-=20.0;
                    //}
                    //PrintToChatAll("%d distance %f",i,GetVectorDistance(pos,otherpos));
                    if(GetVectorDistance(pos,otherpos)<OverloadRadius){
                        
                        //TE_SetupBeamPoints(pos,otherpos,BeamSprite,HaloSprite,0,35,0.15,6.0,5.0,0,1.0,{255,255,255,100},20);
                        //TE_SendToAll();
                        
                        new Float:distanceVec[3];
                        SubtractVectors(otherpos,pos,distanceVec);
                        new Float:angles[3];
                        GetVectorAngles(distanceVec,angles);
                        
                        TR_TraceRayFilter(pos, angles, MASK_PLAYERSOLID, RayType_Infinite, CanHitThis,attacker);
                        new ent;
                        if(TR_DidHit(_))
                        {
                            ent=TR_GetEntityIndex(_);
                            //PrintToChatAll("trace hit: %d      wanted to hit player: %d",ent,i);
                        }
                        
                        if(ent==i&&GetClientHealth(i)<lowesthp){
                            besttarget=i;
                            lowesthp=GetClientHealth(i);
                        }
                    }
                }
            }
        }
        if(besttarget>0){
            pos[2]-=15.0; //ATTACKER EYE 
            
            GetClientEyePosition(besttarget,otherpos); 
            otherpos[2]-=20.0; //THIS IS EYE NOW, NOT ABS
            TE_SetupBeamPoints(pos,otherpos,BeamSprite,HaloSprite,0,35,0.15,6.0,5.0,0,1.0,{255,000,255,255},20);
            TE_SendToAll();
            War3_DealDamage(besttarget,OverloadDamagePerHit[War3_GetSkillLevel(attacker,thisRaceID,ULT_OVERLOAD)],attacker,_,"overload");
            PlayerDamageIncrease[attacker]*=OverloadDamageIncrease[War3_GetSkillLevel(attacker,thisRaceID,ULT_OVERLOAD)];
            
            W3EmitSoundToAll(overloadzap,attacker);
            W3EmitSoundToAll(overloadzap,attacker);
            W3EmitSoundToAll(overloadzap,besttarget);
            W3EmitSoundToAll(overloadzap,besttarget);
            
        }
        CreateTimer(0.25,UltimateLoop,GetClientUserId(attacker)); //damage
    }
    else
    {
        UltimateZapsRemaining[attacker]=0;
    }
}
public Action:UltStateSound(Handle:t,any:attacker){
    if(ValidPlayer(attacker,true)&&UltimateZapsRemaining[attacker]>0){
        W3EmitSoundToAll(overloadstate,attacker);
        CreateTimer(3.7,UltStateSound,attacker);
    }
}

public bool:CanHitThis(entity, mask, any:data)
{
    if(entity == data)
    {// Check if the TraceRay hit the itself.
        return false; // Don't allow self to be hit
    }
    return true; // It didn't hit itself
}







public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
    {
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        if(vteam!=ateam)
        {
            new race_attacker=War3_GetRace(attacker);
            if(race_attacker==thisRaceID&&IsPlayerAlive(attacker)&&UltimateZapsRemaining[attacker]>0)
            {
                //new skill=War3_GetSkillLevel(client,thisRaceID,ULT_OVERLOAD);
                War3_DamageModPercent(PlayerDamageIncrease[attacker]);
                //PrintToConsole(attacker,"Dealing %.1fX base damage from Overload",PlayerDamageIncrease[attacker]);
                W3FlashScreen(victim,RGBA_COLOR_RED);
            
            }
        }
    }
}
    


public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new userid=GetEventInt(event,"userid");
    new attacker_userid=GetEventInt(event,"attacker");
    new dmg=GetEventInt(event,"dmg_health");
    //new weaponidTF;
    if(War3_GetGame()==Game_TF){
        dmg=GetEventInt(event,"damageamount");
        //weaponidTF=GetEventInt(event,"weaponid");
        //PrintToChatAll("weaponid %d",weaponidTF);
    }
    if(userid&&attacker_userid&&userid!=attacker_userid)
    {
        new victim=GetClientOfUserId(userid);
        new attacker=GetClientOfUserId(attacker_userid);
        if(victim>0&&attacker>0)
        {
            /*new race_attacker=War3_GetRace(attacker);*/
            if(/*race_attacker==thisRaceID&&*/!W3HasImmunity(victim,Immunity_Skills)){
                
                new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_CONDUIT);
                
                if(W3GetDamageIsBullet()&&skill_level>0&&!Hexed(attacker,false)){
                    
                    if(ConduitUntilTime[victim]>1.0&&W3Chance(W3ChanceModifier(attacker))){
                        //do nothing, already on conduit
                        ConduitSubtractDamage[victim]+=ConduitPerHit[skill_level];
                    }
                    else if(War3_SkillNotInCooldown(attacker,thisRaceID,SKILL_CONDUIT))
                    {
                        //activate conduit on this victim
                        
                        
                        ConduitUntilTime[victim]=GetGameTime()+float(ConduitDuration);    
                        ConduitSubtractDamage[victim]+=ConduitPerHit[skill_level];
                        ConduitBy[victim]=attacker;
                        War3_CooldownMGR(attacker,float(ConduitCooldown),thisRaceID,SKILL_CONDUIT,_,false);
                        
                        PrintHintText(victim,"%T","Conduit activated on you!",victim);
                        PrintHintText(attacker,"%T","Activated Conduit!",attacker);
                    }
                }
            }
            
            ///attacker has conduit:
            if(ConduitSubtractDamage[attacker]){
                if(ValidPlayer(ConduitBy[attacker],false)){
                    //PrintToChatAll("dmg: %d back hp: %d",dmg,ConduitSubtractDamage[attacker]);
                    new heal=ConduitSubtractDamage[attacker]-dmg;
                    if(heal>ConduitMaxHeal[War3_GetSkillLevel(ConduitBy[attacker],thisRaceID,SKILL_CONDUIT)])
                    {
                        heal=ConduitMaxHeal[War3_GetSkillLevel(ConduitBy[attacker],thisRaceID,SKILL_CONDUIT)];
                    }
                    War3_HealToBuffHP(victim,ConduitSubtractDamage[attacker]);
                    if(heal>=0){
                        if(War3_GetGame()==Game_TF){
                            decl Float:pos[3];
                            GetClientEyePosition(victim, pos);
                            pos[2] += 4.0;
                            War3_TF_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos
                        }
                    }
                }
            }
            
            //new race_victim=War3_GetRace(victim);
            //if(race_victim==thisRaceID){
            new skill = War3_GetSkillLevel(victim,thisRaceID,SKILL_STATIC);
            if(skill>0){
                if(!Hexed(victim,false)&&GetRandomFloat(0.0,1.0)<0.5){
                    new heal=RoundFloat(StaticHealPercent[skill]*dmg);
                    new team=GetClientTeam(victim);
                    
                    new Float:pos[3];
                    GetClientAbsOrigin(victim,pos);
                    new Float:otherVec[3];
                    for(new i=1;i<=MaxClients;i++)
                    {
                        if(ValidPlayer(i,true)&&GetClientTeam(i)!=team)
                        {
                            GetClientAbsOrigin(i,otherVec);
                            if(GetVectorDistance(pos,otherVec)<StaticHealRadius){
                                War3_HealToBuffHP(i,heal);
                            }
                        }
                    }
                }
            //}
            }
        }
    }
}




public Action:CalcConduit(Handle:timer,any:userid)
{
    new Float:time = GetGameTime();
    for(new i=1;i<=MaxClients;i++){
        if(time>ConduitUntilTime[i]){
            ConduitUntilTime[i]=0.0;
            ConduitSubtractDamage[i]=0;
            ConduitBy[i]=0;
        }
    }
}
public OnClientPutInServer(i){
    ConduitBy[i]=0;
    ConduitUntilTime[i]=0.0;
    ConduitSubtractDamage[i]=0;
}