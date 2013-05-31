#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

public Plugin:myinfo = 
{
    name = "War3Source - Race - Warden",
    author = "War3Source Team",
    description = "The Warden race for War3Source"
};

new thisRaceID;

new String:sOldModel[MAXPLAYERSCUSTOM][256];
new OriginOffset;

//skill 1
new Float:FanOfKnivesCSChanceArr[]={0.0,0.04,0.07,0.11,0.15}; //mole
new Float:FanOfKnivesTFChanceArr[]={0.0,0.05,0.1,0.15,0.2};  
new const KnivesTFDamage = 50; 
new const Float:KnivesTFRadius = 300.0;
 
//skill 2
new Float:BlinkChanceArr[]={0.00,0.25,0.5,0.75,1.00};

//skill 3
new const ShadowStrikeInitialDamage=20;
new const ShadowStrikeTrailingDamage=5;
new Float:ShadowStrikeChanceArr[]={0.0,0.05,0.1,0.15,0.2};
new ShadowStrikeTimes[]={0,2,3,4,5};
new BeingStrikedBy[MAXPLAYERSCUSTOM];
new StrikesRemaining[MAXPLAYERSCUSTOM];

//ultimate
new Handle:ultCooldownCvar;
new Handle:ultMaxCvar;

new ultUsedTimes[MAXPLAYERSCUSTOM];
new VengenceCSStartHP[]={0,40,50,60,70}; 
new Float:VengenceTFHealHPPercent[]={0.0,0.25,0.5,0.75,1.0}; 

#define IMMUNITYBLOCKDISTANCE 300.0


new SKILL_FANOFKNIVES, SKILL_BLINK,SKILL_SHADOWSTRIKE,ULT_VENGENCE;

//new String:shadowstrikestr[]="war3source/shadowstrikebirth.wav";
//new String:ultimateSound[]="war3source/MiniSpiritPissed1.wav";

new String:shadowstrikestr[256]; //="war3source/shadowstrikebirth.mp3";
new String:ultimateSound[256]; //="war3source/MiniSpiritPissed1.mp3";

new BeamSprite;
new HaloSprite;
new KnifeModel;

// Offsets
new MyWeaponsOffset,AmmoOffset;//,Clip1Offset;

public OnPluginStart()
{
    
    ultCooldownCvar=CreateConVar("war3_warden_vengence_cooldown","20","Cooldown between Warden Vengence (ultimate)");
    
    CreateTimer(0.2,CalcBlink,_,TIMER_REPEAT);
    OriginOffset=FindSendPropOffs("CBaseEntity","m_vecOrigin");
    MyWeaponsOffset=FindSendPropOffs("CBaseCombatCharacter","m_hMyWeapons");
    //Clip1Offset=FindSendPropOffs("CBaseCombatWeapon","m_iClip1");
    AmmoOffset=FindSendPropOffs("CBasePlayer","m_iAmmo");
    
    if(GAMECSANY){
        HookEvent("player_death",PlayerDeathEvent);
        HookEvent("round_start",RoundStartEvent);
        ultMaxCvar=CreateConVar("war3_warden_vengence_max","0","Max number of revivals from vengence per round (CS only), 0 for unlimited");
    }
    
    LoadTranslations("w3s.race.warden.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==70)
    {
        thisRaceID=War3_CreateNewRaceT("warden");
        SKILL_FANOFKNIVES=War3_AddRaceSkillT(thisRaceID,GAMECSANY?"FanOfKnivesCS":"FanOfKnivesTF",false,4);
        SKILL_BLINK=War3_AddRaceSkillT(thisRaceID,"Immunity",false,4);
        SKILL_SHADOWSTRIKE=War3_AddRaceSkillT(thisRaceID,"ShadowStrike",false,4);
        ULT_VENGENCE=War3_AddRaceSkillT(thisRaceID,GAMECSANY?"VengenceCS":"VengenceTF",true,4); 
        War3_CreateRaceEnd(thisRaceID);
    
    }
        
    
}

public OnMapStart()
{
    War3_AddSoundFolder(shadowstrikestr, sizeof(shadowstrikestr), "shadowstrikebirth.mp3");
    War3_AddSoundFolder(ultimateSound, sizeof(ultimateSound), "MiniSpiritPissed1.mp3");

    War3_AddCustomSound(shadowstrikestr);
    War3_AddCustomSound(ultimateSound);
    BeamSprite=War3_PrecacheBeamSprite();
    HaloSprite=War3_PrecacheHaloSprite();
    if(GAMECSANY){
        KnifeModel=PrecacheModel("models/weapons/w_knife.vmt");
        if(GAMECSGO) {
            // Theese models aren't always precached
            PrecacheModel("models/player/ctm_gsg9.mdl");
            PrecacheModel("models/player/tm_leet_variantb.mdl");
        }
    }    
}

public OnWar3EventSpawn(client){
    StrikesRemaining[client]=0;
}

public OnRaceChanged(client,oldrace,newrace)
{
    if(newrace!=thisRaceID)
    {    
        War3_SetBuff(client,bImmunityUltimates,thisRaceID,false);
    }

}


public OnUltimateCommand(client,race,bool:pressed)
{
    // TODO: Increment UltimateUsed[client]
    if(race==thisRaceID && pressed && IsPlayerAlive(client))
    {
        new ult_level=War3_GetSkillLevel(client,race,ULT_VENGENCE);
        if(ult_level>0)
        {
            if(GAMECSANY){
                if(War3_SkillNotInCooldown(client,thisRaceID,ULT_VENGENCE,true)){   //prints
                    W3MsgUltimateNotActivatable(client);
                }

            }
            else if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_VENGENCE,true))
            {
                if(!blockingVengence(client))
                {
                    new maxhp=War3_GetMaxHP(client);
                
                    new heal=RoundToCeil(float(maxhp)*VengenceTFHealHPPercent[ult_level]);
                    War3_HealToBuffHP(client,heal);
                    W3FlashScreen(client,{0,255,0,20},0.5,_,FFADE_OUT);
                    
                    W3EmitSoundToAll(ultimateSound,client);
                    W3EmitSoundToAll(ultimateSound,client);
                    
                    War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_VENGENCE,_,_);
                    
                }
                else
                {
                    W3MsgUltimateBlocked(client);
                }
                
            }
            
        }
        else
        {
            W3MsgUltNotLeveled(client);
        }
    }
}



public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
    {
        if(IsPlayerAlive(attacker)&&IsPlayerAlive(victim)&&GetClientTeam(victim)!=GetClientTeam(attacker))
        {
            //VICTIM IS WAREN!!! 
            if(War3_GetRace(victim)==thisRaceID)
            {
                new Float:chance_mod=W3ChanceModifier(attacker);
                /// CHANCE MOD BY ATTACKER
                new skill_level = War3_GetSkillLevel(victim,thisRaceID,SKILL_FANOFKNIVES);
                if(War3_GetGame()==Game_TF)
                {
                    if(!Hexed(victim,false)&&GetRandomFloat(0.0,1.0)<=chance_mod*FanOfKnivesTFChanceArr[skill_level])
                    {
                        //knives damage hp around the victim
                        W3MsgThrewKnives(victim);
                        new Float:playerVec[3];
                        GetClientAbsOrigin(victim,playerVec);
                        
                        playerVec[2]+=20;
                        TE_SetupBeamRingPoint(playerVec, 10.0, KnivesTFRadius, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, {255,255,255,155}, 100, 0);
                        TE_SendToAll();
                        playerVec[2]-=20;
                        
                        new Float:otherVec[3];
                        new team = GetClientTeam(victim);
                        for(new i=1;i<=MaxClients;i++)
                        {
                            if(ValidPlayer(i,true)&&GetClientTeam(i)!=team)
                            {
                                GetClientAbsOrigin(i,otherVec);
                                if(GetVectorDistance(playerVec,otherVec)<KnivesTFRadius)
                                {
                                    if(War3_DealDamage(i,KnivesTFDamage,victim,DMG_BULLET,"knives",W3DMGORIGIN_SKILL,W3DMGTYPE_MAGIC))
                                    {
                                        W3FlashScreen(i,RGBA_COLOR_RED);
                                        W3MsgHitByKnives(i);
                                        decl Float:StartPos[3];
                                        GetClientAbsOrigin(victim,StartPos);
                                        StartPos[2]+=40;
                                        if(GAMECSANY){
                                            decl Float:TargetPos[3];
                                            TargetPos[0]=StartPos[0];
                                            TargetPos[1]=StartPos[1];
                                            TargetPos[2]=StartPos[2]+50;
                                            TE_SetupBubbles(StartPos, TargetPos, KnifeModel,180.0,GetRandomInt(8,14),15.0);
                                            TE_SendToAll();
                                        }
                                        TE_SetupBeamRingPoint(StartPos, 150.0, 10.0, BeamSprite, HaloSprite, 0, 10, 0.8, 20.0, 0.0, {255,50,130,255}, 1600, FBEAM_SINENOISE);
                                        TE_SendToAll();
                                        TE_SetupBeamRingPoint(StartPos, 150.0, 10.0, BeamSprite, HaloSprite, 0, 10, 0.8, 20.0, 0.0, {255,50,130,255}, 1600, FBEAM_SINENOISE);
                                        TE_SendToAll(0.3);
                                        TE_SetupBeamRingPoint(StartPos, 150.0, 10.0, BeamSprite, HaloSprite, 0, 10, 0.8, 20.0, 0.0, {255,50,130,255}, 1600, FBEAM_SINENOISE);
                                        TE_SendToAll(0.6);
                                        TE_SetupBeamRingPoint(StartPos, 10.0, 200.0, BeamSprite, HaloSprite, 0, 10, 0.5, 20.0, 0.0, {255,50,130,255}, 1600, FBEAM_SINENOISE);
                                        TE_SendToAll(0.8);
                                    }
                                    else {
                                        W3MsgSkillBlocked(i,_,"Knives");
                                    }
                                }
                            }
                        }
                    }
                }
            }
            //ATTACKER IS WARDEN
            if(War3_GetRace(attacker)==thisRaceID)
            {
                //shadow strike poison
                new Float:chance_mod=W3ChanceModifier(attacker);
                /// CHANCE MOD BY VICTIM
                new skill_level = War3_GetSkillLevel(attacker,thisRaceID,SKILL_SHADOWSTRIKE);
                if(skill_level>0 && StrikesRemaining[victim]==0 && !Hexed(attacker,false)&&GetRandomFloat(0.0,1.0)<=chance_mod*ShadowStrikeChanceArr[skill_level])
                {
                    if(W3HasImmunity(victim,Immunity_Skills))
                    {
                        W3MsgSkillBlocked(victim,attacker,"Shadow Strike");
                    }
                    else
                    {
                        W3MsgAttackedBy(victim,"Shadow Strike");
                        W3MsgActivated(attacker,"Shadow Strike");
                        
                        BeingStrikedBy[victim]=attacker;
                        StrikesRemaining[victim]=ShadowStrikeTimes[skill_level];
                        War3_DealDamage(victim,ShadowStrikeInitialDamage,attacker,DMG_BULLET,"shadowstrike");
                        W3FlashScreen(victim,RGBA_COLOR_RED);
                        
                        W3EmitSoundToAll(shadowstrikestr,attacker);
                        W3EmitSoundToAll(shadowstrikestr,attacker);
                        CreateTimer(1.0,ShadowStrikeLoop,GetClientUserId(victim));
                    }
                }
            }
        }
    }
}
public Action:ShadowStrikeLoop(Handle:timer,any:userid)
{
    new victim = GetClientOfUserId(userid);
    if(StrikesRemaining[victim]>0 && ValidPlayer(BeingStrikedBy[victim]) && ValidPlayer(victim,true))
    {
        War3_DealDamage(victim,ShadowStrikeTrailingDamage,BeingStrikedBy[victim],DMG_BULLET,"shadowstrike");
        StrikesRemaining[victim]--;
        W3FlashScreen(victim,RGBA_COLOR_RED);
        CreateTimer(1.0,ShadowStrikeLoop,userid);
        decl Float:StartPos[3];
        GetClientAbsOrigin(victim,StartPos);
        TE_SetupDynamicLight(StartPos,255,255,100,100,100.0,0.3,3.0);
        TE_SendToAll();
    }
}

stock TE_SetupDynamicLight(const Float:vecOrigin[3], r,g,b,iExponent,Float:fRadius,Float:fTime,Float:fDecay)
{
    TE_Start("Dynamic Light");
    TE_WriteVector("m_vecOrigin",vecOrigin);
    TE_WriteNum("r",r);
    TE_WriteNum("g",g);
    TE_WriteNum("b",b);
    TE_WriteNum("exponent",iExponent);
    TE_WriteFloat("m_fRadius",fRadius);
    TE_WriteFloat("m_fTime",fTime);
    TE_WriteFloat("m_fDecay",fDecay);
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        ultUsedTimes[i]=0;
        War3_CooldownReset(i,thisRaceID,ULT_VENGENCE);
        
        
        StrikesRemaining[i]=0;
        if(ValidPlayer(i,true)&&War3_GetRace(i)==thisRaceID)
        {
            new skill_level=War3_GetSkillLevel(i,thisRaceID,SKILL_FANOFKNIVES);
            if(GetRandomFloat(0.0,1.0)<=FanOfKnivesCSChanceArr[skill_level])
            {
                StartMole(i);
            }
        }
    }
}


public StartMole(client)
{
    new Float:mole_time=5.0;
    W3MsgMoleIn(client,mole_time);
    CreateTimer(0.2+mole_time,DoMole,client);
}
public Action:DoMole(Handle:timer,any:client)
{
    if(ValidPlayer(client,true))
    {
        new team=GetClientTeam(client);
        new searchteam=(team==2)?3:2;
        
        new Float:emptyspawnlist[100][3];
        new availablelocs=0;
        
        new Float:playerloc[3];
        new Float:spawnloc[3];
        new ent=-1;
        while((ent = FindEntityByClassname(ent,(searchteam==2)?"info_player_terrorist":"info_player_counterterrorist"))!=-1)
        {
            if(!IsValidEdict(ent)) continue;
            GetEntDataVector(ent,OriginOffset,spawnloc);
            
            new bool:is_conflict=false;
            for(new i=1;i<=MaxClients;i++)
            {
                if(ValidPlayer(i,true)){
                    GetClientAbsOrigin(i,playerloc);
                    if(GetVectorDistance(spawnloc,playerloc)<60.0)
                    {
                        is_conflict=true;
                        break;
                    }                
                }
            }
            if(!is_conflict)
            {
                emptyspawnlist[availablelocs][0]=spawnloc[0];
                emptyspawnlist[availablelocs][1]=spawnloc[1];
                emptyspawnlist[availablelocs][2]=spawnloc[2];
                availablelocs++;
            }
        }
        if(availablelocs==0)
        {
            War3_ChatMessage(client,"%T","No suitable location found, can not mole!",client);
            return;
        }
        GetClientModel(client,sOldModel[client],256);
        if(War3_GetGame() == Game_CS) {
            SetEntityModel(client,(searchteam==2)?"models/player/t_leet.mdl":"models/player/ct_urban.mdl");
        }
        else {
            // TODO: probably needs a improvement(models) ?
            SetEntityModel(client,(searchteam==2)?"models/player/tm_leet_variantb.mdl":"models/player/ctm_gsg9.mdl");
        }
        TeleportEntity(client,emptyspawnlist[GetRandomInt(0,availablelocs-1)],NULL_VECTOR,NULL_VECTOR);
        W3MsgMoled(client);
        War3_ShakeScreen(client,1.0,20.0,12.0);
        CreateTimer(10.0,ResetModel,client);
    }
    return;
}
public Action:ResetModel(Handle:timer,any:client)
{
    if(ValidPlayer(client,true))
    {
        SetEntityModel(client,sOldModel[client]);
        W3MsgNoLongerDisguised(client);
    }
}

  

public Action:CalcBlink(Handle:timer,any:userid)
{
    if(thisRaceID>0)
    {
        for(new i=1;i<=MaxClients;i++)
        {
            if(ValidPlayer(i,true)&&War3_GetRace(i)==thisRaceID)
            {
                War3_SetBuff(i,bImmunityUltimates,thisRaceID, (GetRandomFloat(0.0,1.0)<BlinkChanceArr[War3_GetSkillLevel(i,thisRaceID,SKILL_BLINK)]) ? true:false);
            }
        }
    }
}


public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new victim=GetClientOfUserId(GetEventInt(event,"userid"));
    new attacker=GetClientOfUserId(GetEventInt(event,"attacker"));
    new bool:should_vengence=false;
    
    if(victim>0 && attacker>0 && attacker!=victim)
    {
        if(W3GetVar(DeathRace)==thisRaceID && War3_GetSkillLevel(victim,thisRaceID,ULT_VENGENCE)>0 && War3_SkillNotInCooldown(victim,thisRaceID,ULT_VENGENCE,false) )
        {
            if(ValidPlayer(attacker,true)&&W3HasImmunity(attacker,Immunity_Ultimates))
            {
                W3MsgSkillBlocked(attacker,_,"Vengence");
                W3MsgVengenceWasBlocked(victim,"attacker immunity");
            }
            else
            {
                should_vengence=true;
            }
        }
    }
    else if(victim>0)
    {
        if(War3_GetRace(victim)==thisRaceID && War3_GetSkillLevel(victim,thisRaceID,ULT_VENGENCE)>0)
        {
            if(War3_SkillNotInCooldown(victim,thisRaceID,ULT_VENGENCE,false) )
            {
                should_vengence=true;
            }
            else{
                W3MsgVengenceWasBlocked(victim,"cooldown");
            }
        }
    }
    
    //did he use it too much?
    if(victim>0){
        if(ultUsedTimes[victim]>=GetConVarInt(ultMaxCvar)&&GetConVarInt(ultMaxCvar)>0){
            should_vengence=false;
            new String:str[100];
            Format(str,sizeof(str),"max %d times per round",GetConVarInt(ultMaxCvar));
            W3MsgVengenceWasBlocked(victim,str);
        }
    }
    if(should_vengence)
    {
        new victimTeam=GetClientTeam(victim);
        new playersAliveSameTeam;
        for(new i=1;i<=MaxClients;i++)
        {
            if(i!=victim&&ValidPlayer(i,true)&&GetClientTeam(i)==victimTeam)
            {
                playersAliveSameTeam++;
            }
        }
        if(playersAliveSameTeam>0)
        {
            // In vengencerespawn do we actually make cooldown
            CreateTimer(0.2,VengenceRespawn,GetClientUserId(victim));
        }
        else{
            W3MsgVengenceWasBlocked(victim,"last one alive");
        }
    }
}

public GiveDeathWeapons(client)
{
    if(client>0)
    {
        // reincarnate with weapons
        // drop weapons beside c4 and knife
        for(new s=0;s<10;s++)
        {
            new ent=GetEntDataEnt2(client,MyWeaponsOffset+(s*4));
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
        for(new s=0;s<32;s++)
        {
            SetEntData(client,AmmoOffset+(s*4),War3_CachedDeadAmmo(client,s),4);
        }
        // give them their weapons
        for(new s=0;s<10;s++)
        {
            new String:wep_check[64];
            War3_CachedDeadWeaponName(client,s,wep_check,64);
            if(!StrEqual(wep_check,"") && !StrEqual(wep_check,"",false) && !StrEqual(wep_check,"weapon_c4") && !StrEqual(wep_check,"weapon_knife"))
            {
                new wep_ent=GivePlayerItem(client,wep_check);
                if(wep_ent>0)
                {
                        //dont lower ammo
                    //SetEntData(wep_ent,Clip1Offset,War3_CachedDeadClip1(client,s),4);
                }
            }
        }
    }
}

public Action:VengenceRespawn(Handle:t,any:userid)
{
    new client=GetClientOfUserId(userid);
    if(client>0 && War3_GetRace(client)==thisRaceID) //did he become alive?
    {
        if(IsPlayerAlive(client)){
            W3MsgVengenceWasBlocked(client,"you are alive");
        }
        else{
        
            new alivecount;
            new team=GetClientTeam(client);
            for(new i=1;i<=MaxClients;i++){
                if(ValidPlayer(i,true)&&GetClientTeam(i)==team){
                    alivecount++;
                    break;
                }
            }
            if(alivecount==0){
                W3MsgVengenceWasBlocked(client,"last player death or round end");
            }
            else
            {
                War3_SpawnPlayer(client);
                GiveDeathWeapons(client);
                
                War3_ChatMessage(client,"%T","Revived by Vengence",client);
                new ult_level=War3_GetSkillLevel(client,thisRaceID,ULT_VENGENCE);
                //if(GetClientHealth(client)<VengenceCSStartHP[ult_level])
                //{
                SetEntityHealth(client,VengenceCSStartHP[ult_level]);
                War3_SetCSArmor(client,100);
                War3_SetCSArmorHasHelmet(client,true);
                //}    
                ultUsedTimes[client]++;
                War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_VENGENCE,false,true);
            }
        }
    }
    
}

public bool:blockingVengence(client)  //TF2 only
{
    //ELIMINATE ULTIMATE IF THERE IS IMMUNITY AROUND
    new Float:playerVec[3];
    GetClientAbsOrigin(client,playerVec);
    new Float:otherVec[3];
    new team = GetClientTeam(client);

    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Ultimates))
        {
            GetClientAbsOrigin(i,otherVec);
            if(GetVectorDistance(playerVec,otherVec)<IMMUNITYBLOCKDISTANCE)
            {
                return true;
            }
        }
    }
    return false;
}