#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

public Plugin:myinfo = 
{
    name = "War3Source - Race - Blood Mage",
    author = "War3Source Team",
    description = "The Blood Mage race for War3Source."
};

// TODO: Effects

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

new SKILL_REVIVE, SKILL_BANISH, SKILL_MONEYSTEAL,ULT_FLAMESTRIKE;

//skill 1
new Float:MaxRevivalChance[MAXPLAYERSCUSTOM]; //chance for first attempt at revival
new Float:CurrentRevivalChance[MAXPLAYERSCUSTOM]; //decays by half per revival attempt, will stay at minimum of 10% after decays
new Float:RevivalChancesArr[]={0.00,0.2,0.3,0.4,0.5};
new RevivedBy[MAXPLAYERSCUSTOM];
new bool:bRevived[MAXPLAYERSCUSTOM];
new Float:fLastRevive[MAXPLAYERSCUSTOM];

// Team switch checker
new bool:Can_Player_Revive[MAXPLAYERSCUSTOM+1];

// TF2 Revive Messages
new Handle:ClientReviveMessage;
new bool:RESwarn[MAXPLAYERSCUSTOM];
 
//skill 2
new Float:BanishChance[MAXPLAYERSCUSTOM];
new Float:BanishChancesArr[5]={0.00,0.05,0.10,0.15,0.20};

//skill 3
new Float:MoneyStealPercent[MAXPLAYERSCUSTOM];
new Float:MoneyStealPercentArr[]={0.00,0.0025,0.0050,0.0075,0.01};  //how much is stolen
//for TF only:
new Float:CreditStealChanceTF[]={0.00,0.02,0.04,0.06,0.08};   //what are the chances of stealing
new Float:TFCreditStealPercent=0.1;  //how much to steal

//ultimate
new Handle:ultCooldownCvar;
new Handle:hrevivalDelayCvar;
new Handle:g_hUltReviveLocationCvar = INVALID_HANDLE;

new Float:UltimateMaxDistance[]={0.0,500.0,500.0,500.0,500.0}; //max distance u can target your ultimate
new UltimateDamageDuration[]={0,4,6,8,10}; ///how many times damage is taken (like pyro's fire)

new BurnsRemaining[MAXPLAYERSCUSTOM]; //burn count for victims
new BeingBurnedBy[MAXPLAYERSCUSTOM];
new UltimateUsed[MAXPLAYERSCUSTOM];

new ULT_DAMAGE_CS = 5;
new ULT_DAMAGE_TF = 10;



new MyWeaponsOffset,AmmoOffset;
//Clip1Offset,; //cs stuff?

new String:reviveSound[256];

new BeamSprite,HaloSprite,FireSprite;
new BloodSpray,BloodDrop;

// CS specific money offset
new MoneyOffsetCS;

public OnPluginStart()
{
    HookEvent("player_spawn",PlayerSpawnEvent);
    HookEvent("round_start",RoundStartEvent);
    ultCooldownCvar=CreateConVar("war3_mage_fire_strike_cooldown","20","Cooldown between fire strikes (ultimate)");
    g_hUltReviveLocationCvar=CreateConVar("war3_mage_revive_at_spawn", "0", "0 : at death position / 1 : at spawn");
    hrevivalDelayCvar=CreateConVar("war3_mage_revive_delay","2.0","Delay when reviving a teammate (since death)");
    
    MoneyOffsetCS=FindSendPropInfo("CCSPlayer","m_iAccount");
    MyWeaponsOffset=FindSendPropInfo("CBaseCombatCharacter","m_hMyWeapons");
//    Clip1Offset=FindSendPropInfo("CBaseCombatWeapon","m_iClip1");
    AmmoOffset=FindSendPropInfo("CBasePlayer","m_iAmmo");
    
    if(War3_GetGame()==Game_TF)
    {
        ClientReviveMessage = CreateHudSynchronizer();
        CreateTimer(0.1,ResWarning,_,TIMER_REPEAT);
    }
    
    HookEvent("player_death",PlayerDeathEvent);
    HookEvent("player_team",PlayerTeamEvent);
    
    LoadTranslations("w3s.race.mage.phrases.txt");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==40)
    {
        thisRaceID=War3_CreateNewRaceT("mage");
        SKILL_REVIVE=War3_AddRaceSkillT(thisRaceID,"Phoenix",false,4,"20-50%","2-8%");
        SKILL_BANISH=War3_AddRaceSkillT(thisRaceID,"Banish",false,4,"20%","0.2");
        SKILL_MONEYSTEAL=War3_AddRaceSkillT(thisRaceID,"SiphonMana",false,4,"8%","1%","10%");
        ULT_FLAMESTRIKE=War3_AddRaceSkillT(thisRaceID,"FlameStrike",true,4,GameTF()?"10":"5", "4-10", "500"); 
        War3_CreateRaceEnd(thisRaceID);
    }
    
}

public OnMapStart()
{
    War3_AddSoundFolder(reviveSound, sizeof(reviveSound), "reincarnation.mp3");

    BeamSprite=War3_PrecacheBeamSprite();
    HaloSprite=War3_PrecacheHaloSprite();
    //we gonna use theese bloodsprite as "money blood"(change color)
    BloodSpray = PrecacheModel("sprites/bloodspray.vmt");
    
    if(GAMETF) {
        PrecacheSoundAny("weapons/explode1.wav",false);
    } else if(GAMECSGO) {
        BloodDrop = PrecacheModel("decals/blood1.vmt");
        FireSprite     = PrecacheModel("materials/sprites/glow07.vmt");
        War3_PrecacheParticle("molotov_explosion");
        PrecacheSoundAny("weapons/incgrenade/inc_grenade_detonate_swt_01.wav",false);
    }
    else {
        // CS:S and other games that share these assets
        BloodDrop = PrecacheModel("sprites/blood.vmt");
        FireSprite     = PrecacheModel("materials/sprites/fireburst.vmt");
        PrecacheSoundAny("weapons/explode5.wav",false);
        if(GAMECS) {
            // This is CS:S only
            War3_PrecacheParticle("env_fire_medium_smoke");
        }
    }
    
    War3_AddCustomSound(reviveSound);

    // Reset Can Player Revive
    for(new i=1;i<=MAXPLAYERSCUSTOM;i++)
    {
        Can_Player_Revive[i]=true;
    }
}


public OnWar3PlayerAuthed(client)
{
    fLastRevive[client]=0.0;
    Can_Player_Revive[client]=true;
    RESwarn[client]=false;
}

public Action:ResWarning(Handle:timer,any:userid)
{
    if(RaceDisabled)
    {
        return;
    }

    for(new client=1;client<=MaxClients;client++)
    {
        if(War3_GetGame()==Game_TF && RESwarn[client] && ValidPlayer(client))
        {
            SetHudTextParams(-1.0, -1.0, 0.1, 255, 255, 0, 255);
            ShowSyncHudText(client, ClientReviveMessage, "PREPARE FOR RESPAWN!");
        }
    }
}

public OnClientDisconnect(client)
{
    if(RaceDisabled)
    {
        return;
    }

    RESwarn[client]=false;
}

public OnRaceChanged(client,oldrace,newrace)
{
    if(RaceDisabled)
    {
        return;
    }

    if( newrace!=thisRaceID)
    {
        new userid=GetClientUserId(client);
        for(new i=1;i<=MaxClients;i++)
        {
            if(ValidPlayer(i) && BurnsRemaining[i]>0)
            {
                if(BeingBurnedBy[i]==userid)
                {
                    BurnsRemaining[i]=0;
                    W3ResetPlayerColor(i,thisRaceID);
                }
            }
        }
    }
}
new FireEntityEffect[MAXPLAYERSCUSTOM];
public OnUltimateCommand(client,race,bool:pressed)
{
    if(RaceDisabled)
    {
        return;
    }

    new userid=GetClientUserId(client);
    if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) )
    {
        new ult_level=War3_GetSkillLevel(client,race,ULT_FLAMESTRIKE);
        if(ult_level>0)
        {
            
            //if(War3_InFreezeTime())
            //{
            //    W3MsgNoCastDuringFreezetime(client);
            //}
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_FLAMESTRIKE,true))
            {
                /////Flame Strike
                new target = War3_GetTargetInViewCone(client,UltimateMaxDistance[ult_level],false,23.0,IsBurningFilter);
                if(target>0)
                {
                    ++UltimateUsed[client];
                    BeingBurnedBy[target]=GetClientUserId(client);
                    BurnsRemaining[target]=UltimateDamageDuration[ult_level];
                    CreateTimer(1.0,BurnLoop,GetClientUserId(target));
                    War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_FLAMESTRIKE,_,_);
                    PrintHintText(client,"%T","Flame Strike!",client);
                    PrintHintText(target,"%T","You have been struck with Flame Strike!",target);
                    W3SetPlayerColor(target,thisRaceID,255,128,0,_,GLOW_ULTIMATE);
                    decl Float:effect_vec[3];
                    GetClientAbsOrigin(target, effect_vec);
                    effect_vec[2]+=150.0;
                    TE_SetupGlowSprite(effect_vec, FireSprite, 2.0, 4.0, 255);
                    TE_SendToAll();
                    if(GAMECSGO) {
                        decl Float:effect_angles[3];
                        GetClientEyeAngles(target, effect_angles);
                        effect_angles[0]=-90.0;
                        effect_vec[2]-=130;
                        ThrowAwayParticle("molotov_explosion", effect_vec, 3.5, effect_angles);
                    } else if(GAMECS) {
                        //I'm unsure about how it works in other games than cs:source
                        effect_vec[2]-180;
                        new ent = AttachParticle(target, "env_fire_medium_smoke", effect_vec, "rfoot");
                        FireEntityEffect[target]=ent;
                    }
                    
                    if(GAMECSGO) {
                        EmitSoundToAllAny("weapons/incgrenade/inc_grenade_detonate_swt_01.wav", target);
                    } else if(GAMETF) {
                        EmitSoundToAllAny("weapons/explode1.wav", target);
                    } else {
                        EmitSoundToAllAny("weapons/explode5.wav", target);
                    }
                }
                else
                {
                    W3MsgNoTargetFound(client,UltimateMaxDistance[ult_level]);
                }
            }
            
        }
        else
        {
            W3MsgUltNotLeveled(client);
        }
    }
}
public bool:IsBurningFilter(client)
{
    if(RaceDisabled)
    {
        return false;
    }

    return (BurnsRemaining[client]<=0 && !W3HasImmunity(client,Immunity_Ultimates));
}
public Action:BurnLoop(Handle:timer,any:userid)
{
    if(RaceDisabled)
    {
        return;
    }

    new victim=GetClientOfUserId(userid);
    new attacker=GetClientOfUserId(BeingBurnedBy[victim]);
    if(victim>0 && attacker>0 && BurnsRemaining[victim]>0 && IsClientInGame(victim) && IsClientInGame(attacker) && IsPlayerAlive(victim))
    {
        BurnsRemaining[victim]--;
        new damage = War3_GetGame()==Game_TF? ULT_DAMAGE_TF:ULT_DAMAGE_CS;
        War3_DealDamage(victim,damage,attacker,DMG_BURN,"flamestrike",_,W3DMGTYPE_MAGIC);
        CreateTimer(1.0,BurnLoop,userid);
        W3FlashScreen(victim,RGBA_COLOR_ORANGE);
        if(BurnsRemaining[victim]<=0)
        {
            W3ResetPlayerColor(victim,thisRaceID);
            if(War3_GetGame()==Game_CS)
            {
                if (FireEntityEffect[victim] > 0 && IsValidEdict(FireEntityEffect[victim]))
                {
                    AcceptEntityInput(FireEntityEffect[victim], "Kill");
                    FireEntityEffect[victim]=-1;
                }
            }
        } 
    }
}


public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    if(RaceDisabled)
    {
        return;
    }

    if(race==thisRaceID)
    {
        if(newskilllevel>=0)
        {
            if(skill==SKILL_REVIVE) //1
            {
                MaxRevivalChance[client]=RevivalChancesArr[newskilllevel];
            }
            if(skill==SKILL_BANISH) //2
            {
                BanishChance[client]=BanishChancesArr[newskilllevel];
            }
            if(skill==SKILL_MONEYSTEAL) //3
            {
                //cs only
                MoneyStealPercent[client]=MoneyStealPercentArr[newskilllevel];
            }
        }
    }
}


stock GetMoney(player)
{
    if(RaceDisabled)
    {
        return 0;
    }

    return GetEntData(player,MoneyOffsetCS);
}

stock SetMoney(player,money)
{
    if(RaceDisabled)
    {
        return;
    }

    SetEntData(player,MoneyOffsetCS,money);
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
    if(RaceDisabled)
    {
        return;
    }

    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&attacker!=victim&&GetClientTeam(attacker)!=GetClientTeam(victim))
    {
        // W3IsOwnerSentry checks for game tf and returns false if not, so it should go thru if not game tf anyhow.
        // if it is game tf and is sentry owner, it will not proc for sentry.
        if(!W3IsOwnerSentry(attacker) && War3_GetRace(attacker)==thisRaceID)
        {
            new Float:chance_mod=W3ChanceModifier(attacker);    
            if(IsPlayerAlive(attacker)&&IsPlayerAlive(victim))
            {
                if(!W3HasImmunity(victim,Immunity_Skills))
                {
                    
                    new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_BANISH);
                    if(skill_level>0)
                    {
                        if(!Hexed(attacker,false)&&GetRandomFloat(0.0,1.0)<=BanishChancesArr[skill_level]*chance_mod)
                        {
                            if(W3HasImmunity(victim,Immunity_Skills))
                            {
                                W3MsgSkillBlocked(victim,attacker,"Banish");
                            }
                            else 
                            {
                                // TODO: Sound effects?
                                //new Float:oldangle[3];
                                //GetClientEyeAngles(victim,oldangle);
                                //oldangle[0]+=GetRandomFloat(-20.0,20.0);
                                //oldangle[1]+=GetRandomFloat(-20.0,20.0);
                                //TeleportEntity(victim, NULL_VECTOR, oldangle, NULL_VECTOR);
                                W3MsgBanished(victim,attacker);
                                W3FlashScreen(victim,{0,0,0,255},0.4,_,FFADE_STAYOUT);
                                CreateTimer(0.2,Unbanish,GetClientUserId(victim));
                                
                                new Float:effect_vec[3];
                                GetClientAbsOrigin(attacker,effect_vec);
                                new Float:effect_vec2[3];
                                GetClientAbsOrigin(victim,effect_vec2);
                                effect_vec[2]+=40;
                                effect_vec2[2]+=40;
                                TE_SetupBeamPoints(effect_vec,effect_vec2,BeamSprite,BeamSprite,0,50,1.0,30.0,10.0,0,12.0,{140,150,255,255},40);
                                TE_SendToAll();
                                effect_vec2[2]+=18;
                                TE_SetupBeamPoints(effect_vec,effect_vec2,BeamSprite,BeamSprite,0,50,1.0,30.0,10.0,0,12.0,{140,150,255,255},40);
                                TE_SendToAll();
                            }
                        }
                    }
                    skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_MONEYSTEAL);
                    if(skill_level>0&&!Hexed(attacker,false))
                    {
                        if(GAMECSANY)
                        {
                            if(GetRandomFloat(0.0,1.0)<=chance_mod) //normally this is always true in cs
                            {
                                if(W3HasImmunity(victim,Immunity_Skills))
                                {
                                    W3MsgSkillBlocked(victim,attacker,"Siphon Mana");
                                }
                                else 
                                {
                                    new stolen=RoundToCeil(float(GetMoney(victim))*MoneyStealPercent[attacker]);
                                    new new_money=GetMoney(attacker)+stolen;
                                    if(new_money>16000) new_money=16000;
                                    SetMoney(attacker,new_money);
                                    new_money=GetMoney(victim)-stolen;
                                    if(new_money<0) new_money=0; 
                                    SetMoney(victim,new_money);
                                    if(stolen>0)
                                    {
                                        W3FlashScreen(attacker,{0,0,128,80});
                                        W3MsgStoleMoney(victim,attacker,stolen);
                                        siphonsfx(victim);
                                    }
                                }
                            }
                        }
                        else if(War3_GetGame()==Game_TF)
                        {
                            if(GetRandomFloat(0.0,1.0) <= CreditStealChanceTF[skill_level]*chance_mod)
                            {
                                if(W3HasImmunity(victim,Immunity_Skills))
                                {
                                    W3MsgSkillBlocked(victim,attacker,"Siphon Mana");
                                }
                                else 
                                {
                                    new stolen=RoundFloat(float(War3_GetCurrency(victim))*TFCreditStealPercent);
                                    if(stolen<=0&&War3_GetCurrency(victim)>0)
                                    {
                                        stolen=1;
                                    }
                                    if(stolen>0) // no need to do anything otherwise
                                    {
                                        War3_AddCurrency(attacker, stolen);
                                        War3_SubstractCurrency(victim, stolen);

                                        W3MsgStoleGold(victim, attacker, stolen);
                                        W3FlashScreen(attacker,RGBA_COLOR_BLUE);
                                        siphonsfx(victim);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

stock siphonsfx(victim) {
    decl Float:vecAngles[3];
    GetClientEyeAngles(victim,vecAngles);
    decl Float:target_pos[3];
    GetClientAbsOrigin(victim,target_pos);
    target_pos[2]+=45;
    TE_SetupBloodSprite(target_pos, vecAngles, {250, 250, 28, 255}, 35, BloodSpray, BloodDrop);
    TE_SendToAll();
}

stock respawnsfx(target) {
    decl Float:effect_vec[3];
    GetClientAbsOrigin(target,effect_vec);
    effect_vec[2]+=50.0;
    TE_SetupBeamRingPoint(effect_vec,80.0,1.0,BeamSprite,HaloSprite,0,15,1.0,8.0,1.0,{255,255,20,255},10,0);
    TE_SendToAll();
    effect_vec[2]-=15.0;
    TE_SetupBeamRingPoint(effect_vec,60.0,1.0,BeamSprite,HaloSprite,0,15,1.0,8.0,1.0,{255,255,20,255},10,0);
    TE_SendToAll(0.3);
    effect_vec[2]-=15.0;
    TE_SetupBeamRingPoint(effect_vec,40.0,1.0,BeamSprite,HaloSprite,0,15,1.0,8.0,1.0,{255,255,20,255},10,0);
    TE_SendToAll(0.6);
}

// Events
public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(RaceDisabled)
    {
        return;
    }

    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if(client>0)
    {
        
        UltimateUsed[client]=0;
        if(War3_GetRace(client)==thisRaceID)
        {
            if(War3_GetGame()==Game_TF)
            {
                new skill_level_revive=War3_GetSkillLevel(client,thisRaceID,SKILL_REVIVE);
                if(!bRevived[client]&&skill_level_revive)
                {
                    CurrentRevivalChance[client]=RevivalChancesArr[skill_level_revive];
                }
                
            }
        }
        bRevived[client]=false;
    }
    
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(RaceDisabled)
    {
        return;
    }

    
    for(new i=1;i<=MaxClients;i++)
    {
        //Reset revival chance
        new skill_level_revive=War3_GetSkillLevel(i,thisRaceID,SKILL_REVIVE);
        if(ValidPlayer(i) && skill_level_revive)
        {
            CurrentRevivalChance[i]=RevivalChancesArr[skill_level_revive];
        }
        //reset everyone's ultimate
        
    }
}

public Action:DoRevival(Handle:timer,any:userid)
{
    if(RaceDisabled)
    {
        return Plugin_Handled;
    }

    new client=GetClientOfUserId(userid);
    if(Can_Player_Revive[client]==false)
    {
        return Plugin_Handled;
    }
    //new client=GetClientOfUserId(userid);
    if(client>0)
    {
        new savior = RevivedBy[client];
        if(ValidPlayer(savior,true) && ValidPlayer(client))
        {
            if(GetClientTeam(savior)==GetClientTeam(client)&&!IsPlayerAlive(client))
            {
                //PrintToChatAll("omfg remove true");
                //SetEntityMoveType(client, MOVETYPE_NOCLIP);
                War3_SpawnPlayer(client);
                W3EmitSoundToAll(reviveSound,client);
                
                W3MsgRevivedBM(client,savior);
                    
                new Float:VecPos[3];
                new Float:Angles[3];
                War3_CachedAngle(client,Angles);
                War3_CachedPosition(client,VecPos);
                
                
                
                if (GetConVarInt(g_hUltReviveLocationCvar) == 0)
                {
                    TeleportEntity(client, VecPos, Angles, NULL_VECTOR);
                }
                RESwarn[client]=false;
                if(War3_GetGame()==Game_CS){
                    //give weapons CS
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
                                //dont reduce ammo
                                //SetEntData(wep_ent,Clip1Offset,War3_CachedDeadClip1(client,s),4);
                            }
                        }
                    }
                    SetEntProp(client,Prop_Send,"m_ArmorValue",100); //give full armor
                }
                
                
                
                testhull(client);
                
                fLastRevive[client]=GetGameTime();
                //test noclip method
                
                //SetEntityMoveType(client, MOVETYPE_WALK);
                
            }
            else
            {
                //this guy changed team?
                CurrentRevivalChance[savior]*=2.0;
                RevivedBy[client]=0;
                bRevived[client]=false;
                RESwarn[client]=false; 
            }
        }
        else
        {
            // savior left or something? maybe dead?
            RevivedBy[client]=0;
            bRevived[client]=false;
            RESwarn[client]=false; 
        }

    }
    return Plugin_Continue;
}

bool:CooldownRevive(client)
{
    if(RaceDisabled)
    {
        return false;
    }

    if(GetGameTime() >= (fLastRevive[client]+30.0))
        return true;
    return false;
}

public PlayerTeamEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(RaceDisabled)
    {
        return;
    }

// Team Switch checker
    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    // For testing purposes:
    //new String:clientname[64];
    //GetClientName(client, clientname, sizeof(clientname));
    //DP("Player %s Switched Teams (Can not be revived for 15 seconds)",clientname);
    Can_Player_Revive[client]=false;
    RESwarn[client]=false;
    CreateTimer(30.0,PlayerCanRevive,userid);
}

public Action:PlayerCanRevive(Handle:timer,any:userid)
{
    if(RaceDisabled)
    {
        return;
    }

// Team Switch checker
    new client=GetClientOfUserId(userid);
    // For testing purposes:
    //new String:clientname[64];
    //GetClientName(client, clientname, sizeof(clientname));
    //DP("Player %s can be revived by bloodmages",clientname);
    Can_Player_Revive[client]=true;
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(RaceDisabled)
    {
        return;
    }

    new userid=GetEventInt(event,"userid");
    new victim=GetClientOfUserId(userid);
    if(victim>0)
    {
        BurnsRemaining[victim]=0;
        W3ResetPlayerColor(victim,thisRaceID);
        new victimTeam = GetClientTeam(victim);
        new skillevel;
        
        if(War3_GetGame()==Game_CS)
        {
            if (FireEntityEffect[victim] > 0 && IsValidEdict(FireEntityEffect[victim]))
            {
                AcceptEntityInput(FireEntityEffect[victim], "TurnOff");
                FireEntityEffect[victim]=-1;
            }
        }
        
        new deathFlags = GetEventInt(event, "death_flags");
        
        if (War3_GetGame()==Game_TF&&deathFlags & 32)
        {
            //PrintToChat(client,"war3 debug: dead ringer kill");
        }
        else
        {
            
            //
            
            //TEST!! remove!!
            //DP("Auto revival  Remove this line CreateTimer(0.1,DoRevival,victim);");
            //CreateTimer(0.1,DoRevival,victim);
            //RevivedBy[victim]=GetClientOfUserId(userid);
            //PrintToChatAll("blood mage");
            
            //find a revival

            // Can_Player_Revive is the team switch checking variable
            if(CooldownRevive(victim)&&Can_Player_Revive[victim]) {
            //if(Can_Player_Revive[victim]) {
                for(new i=1;i<=MaxClients;i++)
                {
                    if(i!=victim&&ValidPlayer(i,true)&&GetClientTeam(i)==victimTeam&&War3_GetRace(i)==thisRaceID)
                    {
                        skillevel=War3_GetSkillLevel(i,thisRaceID,SKILL_REVIVE);
                        if(skillevel>0&&!Hexed(i,false))
                        {
                            if(GetRandomFloat(0.0,1.0)<=CurrentRevivalChance[i])
                            {
                                CurrentRevivalChance[i]/=2.0;
                                if(CurrentRevivalChance[i]<0.020*skillevel){
                                    CurrentRevivalChance[i]=0.020*skillevel;
                                }
                                RevivedBy[victim]=i;
                                bRevived[victim]=true;
                                RESwarn[victim]=true;
                                if(War3_GetGame()!=Game_TF)
                                {
                                    W3Hint(victim,HINT_SKILL_STATUS,5.0,"PREPARE FOR RESPAWN!");
                                    PrintCenterText(victim,"PREPARE FOR RESPAWN!");
                                    War3_ChatMessage(victim,"PREPARE FOR RESPAWN!");
                                }
                                
                                CreateTimer(GetConVarFloat(hrevivalDelayCvar), DoRevival, GetClientUserId(victim));
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
}



public Action:Unbanish(Handle:timer,any:userid)
{
    if(RaceDisabled)
    {
        return;
    }

    // never EVER use client in a timer. userid is safe
    new client=GetClientOfUserId(userid);
    if(client>0)
    {
        W3FlashScreen(client,{0,0,0,0},0.1,_,(FFADE_IN|FFADE_PURGE));
    }
}

new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25,27,-27,30,-30};//,33,-33,40,-40};

stock bool:testhull(client){
    if(RaceDisabled)
    {
        return;
    }

    
    //PrintToChatAll("BEG");
    new Float:mins[3];
    new Float:maxs[3];
    GetClientMins(client,mins);
    GetClientMaxs(client,maxs);
    
    //PrintToChatAll("min : %.1f %.1f %.1f MAX %.1f %.1f %.1f",mins[0],mins[1],mins[2],maxs[0],maxs[1],maxs[2]);
    new absincarraysize=sizeof(absincarray);
    new Float:originalpos[3];
    GetClientAbsOrigin(client,originalpos);
    
    new limit=5000;
    for(new x=0;x<absincarraysize;x++){
        if(limit>0){
            for(new y=0;y<=x;y++){
                if(limit>0){
                    for(new z=0;z<=y;z++){
                        new Float:pos[3]={0.0,0.0,0.0};
                        AddVectors(pos,originalpos,pos);
                        pos[0]+=float(absincarray[x]);
                        pos[1]+=float(absincarray[y]);
                        pos[2]+=float(absincarray[z]);
                        
                        //PrintToChatAll("hull at %.1f %.1f %.1f",pos[0],pos[1],pos[2]);
                        //PrintToServer("hull at %d %d %d",absincarray[x],absincarray[y],absincarray[z]);
                        TR_TraceHullFilter(pos,pos,mins,maxs,CONTENTS_SOLID|CONTENTS_MOVEABLE,CanHitThis,client);
                        //new ent;
                        if(TR_DidHit(_))
                        {
                            //PrintToChatAll("2");
                            //ent=TR_GetEntityIndex(_);
                            //PrintToChatAll("hit %d self: %d",ent,client);
                        }
                        else{
                            TeleportEntity(client,pos,NULL_VECTOR,NULL_VECTOR);
                            limit=-1;
                            break;
                        }
                    
                        if(limit--<0){
                            break;
                        }
                    }
                    
                    if(limit--<0){
                        break;
                    }
                }
            }
            
            if(limit--<0){
                break;
            }
            
        }
        
    }
    //PrintToChatAll("END");
}

public bool:CanHitThis(entityhit, mask, any:data)
{
    if(RaceDisabled)
    {
        return false;
    }

    if(entityhit == data )
    {// Check if the TraceRay hit the itself.
        return false; // Don't allow self to be hit, skip this result
    }
    if(ValidPlayer(entityhit)&&ValidPlayer(data)&&War3_GetGame()==Game_TF&&GetClientTeam(entityhit)==GetClientTeam(data)){
        return false; //skip result, prend this space is not taken cuz they on same team
    }
    return true; // It didn't hit itself
}

