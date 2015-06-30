#pragma semicolon 1

#include <sourcemod>
#include "sdkhooks"
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Damage System",
    author = "War3Source Team",
    description = "Responsible for hooking and dealing damage related things"
};

///would you like to see the damage stack print out?
//#define DEBUG

new Handle:FHOnW3TakeDmgAllPre;
new Handle:FHOnW3TakeDmgBulletPre;
new Handle:FHOnW3EnemyTakeDmgBulletPre;
new Handle:FHOnW3TakeDmgAll;
new Handle:FHOnW3TakeDmgBullet;

new Handle:g_OnWar3EventPostHurtFH;

new g_CurDamageType=-99;
new g_CurInflictor=-99; //variables from sdkhooks, natives retrieve them if needed
new g_CurDamageIsWarcraft=0; //for this damage only
new g_CurDamageIsTrueDamage=0; //not used yet?

new Float:g_CurDMGModifierPercent=-99.9;

new g_CurLastActualDamageDealt=-99;

new bool:g_CanSetDamageMod=false; //default false, you may not change damage percent when there is none to change
new bool:g_CanDealDamage=true; //default true, you can initiate damage out of nowhere
//for deal damage only
new g_NextDamageIsWarcraftDamage=0; 
new g_NextDamageIsTrueDamage=0;

static const String:CLASSNAME_INFECTED[]      = "infected";
static const String:CLASSNAME_WITCH[]         = "witch";

//global
new ownerOffset;

new dummyresult;


new damagestack=0;

new Float:LastDamageDealtTime[MAXPLAYERSCUSTOM];
new Float:ChanceModifier[MAXPLAYERSCUSTOM];

//cvar handle
new Handle:ChanceModifierSentry;
new Handle:ChanceModifierSentryRocket;
public bool:InitNativesForwards()
{
    CreateNative("War3_DamageModPercent",Native_War3_DamageModPercent);

    CreateNative("W3GetDamageType",NW3GetDamageType);
    CreateNative("W3GetDamageInflictor",NW3GetDamageInflictor);
    CreateNative("W3GetDamageIsBullet",NW3GetDamageIsBullet);
    CreateNative("W3ForceDamageIsBullet",NW3ForceDamageIsBullet);
    
    CreateNative("War3_DealDamage",Native_War3_DealDamage);
    CreateNative("War3_GetWar3DamageDealt",Native_War3_GetWar3DamageDealt);

    CreateNative("W3GetDamageStack",NW3GetDamageStack);

    CreateNative("W3ChanceModifier",Native_W3ChanceModifier);

    CreateNative("W3IsOwnerSentry",Native_W3IsOwnerSentry);


    FHOnW3TakeDmgAllPre=CreateGlobalForward("OnW3TakeDmgAllPre",ET_Hook,Param_Cell,Param_Cell,Param_Cell);
    FHOnW3TakeDmgBulletPre=CreateGlobalForward("OnW3TakeDmgBulletPre",ET_Hook,Param_Cell,Param_Cell,Param_Cell);
    FHOnW3EnemyTakeDmgBulletPre=CreateGlobalForward("OnW3EnemyTakeDmgBulletPre",ET_Hook,Param_Cell,Param_Cell,Param_Cell);
    FHOnW3TakeDmgAll=CreateGlobalForward("OnW3TakeDmgAll",ET_Hook,Param_Cell,Param_Cell,Param_Cell);
    FHOnW3TakeDmgBullet=CreateGlobalForward("OnW3TakeDmgBullet",ET_Hook,Param_Cell,Param_Cell,Param_Cell);

    g_OnWar3EventPostHurtFH = CreateGlobalForward("OnWar3EventPostHurt", ET_Ignore, Param_Cell, Param_Cell, Param_Float, Param_String, Param_Cell);


    ChanceModifierSentry=CreateConVar("war3_chancemodifier_sentry","","None to use attack rate dependent chance modifier. Set from 0.0 to 1.0 chance modifier for sentry, this will override time dependent chance modifier");
    ChanceModifierSentryRocket=CreateConVar("war3_chancemodifier_sentryrocket","","None to use attack rate dependent chance modifier. Set from 0.0 to 1.0 chance modifier for sentry, this will override time dependent chance modifier");
    
    
    
    return true;
}

public OnPluginStart()
{
    if(War3_GetGame()==Game_TF)
    {
        ownerOffset = FindSendPropInfo("CBaseObject", "m_hBuilder");
    }
}

public Native_War3_DamageModPercent(Handle:plugin,numParams)
{
    if(!g_CanSetDamageMod){
        War3_LogWarning("You may not set damage mod percent here, use ....Pre forward");
        ThrowError("You may not set damage mod percent here, use ....Pre forward");
        //PrintPluginError(plugin);
    }

    new Float:num=GetNativeCell(1); 
    #if defined DEBUG
    PrintToServer("percent change %f",num);
    #endif
    g_CurDMGModifierPercent*=num;
    
}



public NW3GetDamageType(Handle:plugin, numParams)
{
    return g_CurDamageType;
}

public NW3GetDamageInflictor(Handle:plugin, numParams
){
    return g_CurInflictor;
}

public NW3GetDamageIsBullet(Handle:plugin, numParams)
{
    return _:(!g_CurDamageIsWarcraft);
}

public NW3ForceDamageIsBullet(Handle:plugin, numParams)
{
    g_CurDamageIsWarcraft = false;
}

public NW3GetDamageStack(Handle:plugin, numParams)
{
    return damagestack;
}

public OnEntityCreated(entity, const String:classname[])
{
    if(GAMEL4DANY)
    {
        if (StrEqual(classname, CLASSNAME_INFECTED, false) || StrEqual(classname, CLASSNAME_WITCH, false))
        {
            SDKHook(entity, SDKHook_OnTakeDamage, SDK_Forwarded_OnTakeDamage);
            SDKHook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePostHook);
        }
    }
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, SDK_Forwarded_OnTakeDamage);
    SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePostHook);
}
public OnClientDisconnect(client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, SDK_Forwarded_OnTakeDamage);
    SDKUnhook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePostHook); 
}

public Native_W3IsOwnerSentry(Handle:plugin,numParams)
{
    if(War3_GetGame()==Game_TF)
    {
        new client=GetNativeCell(1);
        new bool:UseInternalInflictor=GetNativeCell(2);
        new pSentry;
        if(UseInternalInflictor)
            pSentry=g_CurInflictor;
        else
            pSentry=GetNativeCell(3);
        if(ValidPlayer(client))
        {
            if(IsValidEntity(pSentry)&&TF2_GetPlayerClass(client)==TFClass_Engineer)
            {
                decl String:netclass[32];
                GetEntityNetClass(pSentry, netclass, sizeof(netclass));
                if (strcmp(netclass, "CObjectSentrygun") == 0)
                {
                    if (GetEntDataEnt2(pSentry, ownerOffset) == client)
                    return true;
                }
            }
        }
    }
    return false;
}

public Native_W3ChanceModifier(Handle:plugin, numParams)
{
    new attacker = GetNativeCell(1);
    if(!GameTF() || !ValidPlayer(attacker) || !IsValidEdict(attacker)){
        return _:1.0;
    }
    
    return _:ChanceModifier[attacker];
}

new VictimCheck=-666;
new AttackerCheck=-666;
new InflictorCheck=-666;
new Float:DamageCheck=-666.6;
new DamageTypeCheck=-666;
new WeaponCheck=-666;
new Float:damageForceCheck[3];
new Float:damagePositionCheck[3];
new damagecustomCheck = -666;

public Action:SDK_Forwarded_OnTakeDamage(victim,&attacker,&inflictor,&Float:damage,&damagetype,&weapon,Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
    if(VictimCheck==victim
    &&AttackerCheck==attacker
    &&InflictorCheck==inflictor
    &&DamageCheck==damage
    &&DamageTypeCheck==damagetype
    &&WeaponCheck==weapon
    &&damageForceCheck[0]==damageForce[0]
    &&damageForceCheck[1]==damageForce[1]
    &&damageForceCheck[2]==damageForce[2]
    &&damagePositionCheck[0]==damagePosition[0]
    &&damagePositionCheck[1]==damagePosition[1]
    &&damagePositionCheck[2]==damagePosition[2]
    &&damagecustomCheck==damagecustom
    )
    {
        return Plugin_Continue;
    }

    new String:race[32];
    War3_GetRaceName(War3_GetRace(attacker),race,sizeof(race));
    
    // If we got a l4d infected or witch then this continues instead of checking
    // if its alive since that is not a player and therefor IsPlayerAlive fails
    if(War3_IsL4DZombieEntity(victim) ||  ValidPlayer(victim,true))
    {
        //DP("pre damage %f",damage);
        //store old variables on local stack!
    
        new old_DamageType= g_CurDamageType;
        new old_Inflictor= g_CurInflictor;
        new old_IsWarcraftDamage= g_CurDamageIsWarcraft;
        new Float:old_DamageModifierPercent = g_CurDMGModifierPercent;
        new old_IsTrueDamage = g_CurDamageIsTrueDamage;
        
        //set these to global
        g_CurDamageType=damagetype;
        g_CurInflictor=inflictor;
        g_CurDMGModifierPercent=1.0;
        g_CurDamageIsWarcraft=g_NextDamageIsWarcraftDamage;
        g_CurDamageIsTrueDamage=g_NextDamageIsTrueDamage;

        #if defined DEBUG
        DP2("sdktakedamage %d->%d atrace %s damage [%.2f]",attacker,victim,race,damage);
        #endif
        damagestack++;
        
        if(g_CurDamageIsWarcraft && !War3_IsCommonInfected(victim) && !War3_IsWitch(victim)){
            damage=FloatMul(damage,W3GetMagicArmorMulti(victim));
            //PrintToChatAll("magic %f %d to %d",W3GetMagicArmorMulti(victim),attacker,victim);
        }
        else if(!g_CurDamageIsTrueDamage && !War3_IsCommonInfected(victim) && !War3_IsWitch(victim)){ //bullet 
            damage=FloatMul(damage,W3GetPhysicalArmorMulti(victim));
            
            //PrintToChatAll("physical %f %d to %d",W3GetPhysicalArmorMulti(victim),attacker,victim);
            //g_CurDamageIsWarcraft=false;
        }
        if(!g_CurDamageIsWarcraft && ValidPlayer(attacker)){
            new Float:now=GetGameTime();
            
            new Float:value=now-LastDamageDealtTime[attacker];
            if(value>1.0||value<0.0){
                ChanceModifier[attacker]=1.0;
            }
            else{
                ChanceModifier[attacker]=value;
            }
            //DP("%f",ChanceModifier[attacker]);
            LastDamageDealtTime[attacker]=GetGameTime();
        }
        if(attacker!=inflictor)
        {
            if(inflictor>0 && IsValidEdict(inflictor))
            {
                new String:ent_name[64];
                GetEdictClassname(inflictor,ent_name,64);
            //    DP("ent name %s",ent_name);
                if(StrContains(ent_name,"obj_sentrygun",false)==0    &&!CvarEmpty(ChanceModifierSentry))
                {
                    ChanceModifier[attacker]=GetConVarFloat(ChanceModifierSentry);
                }
                else if(StrContains(ent_name,"tf_projectile_sentryrocket",false)==0 &&!CvarEmpty(ChanceModifierSentryRocket))
                {
                    ChanceModifier[attacker]=GetConVarFloat(ChanceModifierSentryRocket);
                }
                
            }
        }
    //    DP("%f",ChanceModifier[attacker]);
        //else it is true damage
        //PrintToChatAll("takedmg %f BULLET %d   lastiswarcraft %d",damage,isBulletDamage,g_CurDamageIsWarcraft);
        
        new bool:old_CanSetDamageMod=g_CanSetDamageMod;
        new bool:old_CanDealDamage=g_CanDealDamage;
        g_CanSetDamageMod=true;
        g_CanDealDamage=false;
        Call_StartForward(FHOnW3TakeDmgAllPre);
        Call_PushCell(victim);
        Call_PushCell(attacker);
        Call_PushCell(damage);
        Call_Finish(dummyresult); //this will be returned to
        
        if(!g_CurDamageIsWarcraft){
        
        
            Call_StartForward(FHOnW3TakeDmgBulletPre);
            Call_PushCell(victim);
            Call_PushCell(attacker);
            Call_PushCell(damage);
            Call_Finish(dummyresult); //this will be returned to
            
            if(ValidPlayer(victim, true) && ValidPlayer(attacker) && victim != attacker && GetClientTeam(victim) != GetClientTeam(attacker))
            {
                Call_StartForward(FHOnW3EnemyTakeDmgBulletPre);
                Call_PushCell(victim);
                Call_PushCell(attacker);
                Call_PushCell(damage);
                Call_Finish(dummyresult); //this will be returned to
            }
            
        }
        g_CanSetDamageMod=false;
        g_CanDealDamage=true;
        if(g_CurDMGModifierPercent>0.001){ //so if damage is already canceled, no point in forwarding the second part , do we dont get: evaded but still recieve warcraft damage proc)
        
        
            Call_StartForward(FHOnW3TakeDmgAll);
            Call_PushCell(victim);
            Call_PushCell(attacker);
            Call_PushCell(damage);
            Call_Finish(dummyresult); //this will be returned to
            
            
            if(!g_CurDamageIsWarcraft){
                Call_StartForward(FHOnW3TakeDmgBullet);
                Call_PushCell(victim);
                Call_PushCell(attacker);
                Call_PushCell(damage);
                Call_Finish(dummyresult); //this will be returned to
                
            }
        }
        g_CanSetDamageMod=old_CanSetDamageMod;
        g_CanDealDamage=old_CanDealDamage;    
        //modify final damage
        damage=damage*g_CurDMGModifierPercent; ////so we calculate the percent 
    
        //nobobdy retrieves our global variables outside of the forward call, restore old stack vars
        g_CurDamageType= old_DamageType;
        g_CurInflictor= old_Inflictor;
        g_CurDamageIsWarcraft= old_IsWarcraftDamage;
        g_CurDMGModifierPercent = old_DamageModifierPercent;
        g_CurDamageIsTrueDamage = old_IsTrueDamage;
        
        
        
        damagestack--;

        VictimCheck=victim;
        AttackerCheck=attacker;
        InflictorCheck=inflictor;
        DamageCheck=damage;
        DamageTypeCheck=damagetype;
        WeaponCheck=weapon;
        damageForceCheck[0]=damageForce[0];
        damageForceCheck[1]=damageForce[1];
        damageForceCheck[2]=damageForce[2];
        damagePositionCheck[0]=damagePosition[0];
        damagePositionCheck[1]=damagePosition[1];
        damagePositionCheck[2]=damagePosition[2];
        damagecustomCheck=damagecustom;

        #if defined DEBUG
        
        DP2("sdktakedamage %d->%d END dmg [%.2f]",attacker,victim,damage);
        #endif
    
    }
    
    return Plugin_Changed;
}

public OnTakeDamagePostHook(victim, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3])
{
    // GHOSTS!!
    if (weapon == -1 && inflictor == -1)
    {
        War3_LogError("OnTakeDamagePostHook: Who was pho^H^H^Hweapon?");
        return;
    }
    
    //Block uber hits (no actual damage)
    if(GAMETF && War3_IsUbered(victim))
    {
        //DP("ubered but SDK OnTakeDamagePostHook called, damage %f",damage);
        return;
    }
    damagestack++;
    
    new bool:old_CanDealDamage=g_CanDealDamage;
    g_CanSetDamageMod=true;
    
    g_CurInflictor = inflictor;
    
    new String:weaponName[64];
    // Revan 29/06/2015:
    // cstrike handles this pretty weird.. basically the inflictor is either a grenade or the player
    // the existing code expects the weapon name without "weapon_" so this works like a translator..
    if(GAMECSANY)
    {
        GetEntityClassname(inflictor, weaponName, sizeof(weaponName));
        if(strcmp(weaponName, "hegrenade_projectile") == 0)
        {
            strcopy(weaponName, sizeof(weaponName), "hegrenade");
        } else if(strcmp(weaponName, "flashbang_projectile") == 0)
        {
            strcopy(weaponName, sizeof(weaponName), "flashbang");
        } else if(strcmp(weaponName, "smokegrenade_projectile") == 0)
        {
            strcopy(weaponName, sizeof(weaponName), "smokegrenade");
        } else if(strcmp(weaponName, "player") == 0) {
            // okay, so the damage was inflicted by the player itself(which means by a weapon)!
            // bullets hit their target instantaneously so we simply use the classname of the players weapon(if any)
            new realWeapon = W3GetCurrentWeaponEnt(inflictor);
            if(realWeapon > 0)
            {
                GetEntityClassname(realWeapon, weaponName, sizeof(weaponName));
                
                // skip the "weapon_" part of the string
                if(strncmp(weaponName, "weapon_", 7) == 0) {
                    strcopy(weaponName, sizeof(weaponName), weaponName[7]);
                }
            }
        }
        // just as a note: if player receives falldamage the inflictor will be "worldspawn"
    } else {
        // Figure out what really hit us. A weapon? A sentry gun?
        new realWeapon = weapon == -1 ? inflictor : weapon;
        GetEntityClassname(realWeapon, weaponName, sizeof(weaponName));
    }
    
    War3_LogInfo("OnTakeDamagePostHook called with weapon \"%s\"", weaponName);

    Call_StartForward(g_OnWar3EventPostHurtFH);
    Call_PushCell(victim);
    Call_PushCell(attacker);
    Call_PushFloat(damage);
    Call_PushString(weaponName);
    Call_PushCell(g_CurDamageIsWarcraft);
    Call_Finish(dummyresult);
    
    g_CanDealDamage=old_CanDealDamage;
    
    damagestack--;
    
    g_CurLastActualDamageDealt = RoundToFloor(damage);
}



stock DP2(const String:szMessage[], any:...)
{
    new String:szBuffer[1000];
    new String:pre[132];
    for(new i=0;i<damagestack;i++){
        StrCat(pre,sizeof(pre),"    ");
    }
    VFormat(szBuffer, sizeof(szBuffer), szMessage, 2);
    PrintToServer("[DP2] %s%s %s",pre,szBuffer,W3GetDamageIsBullet()?"B":"",!g_NextDamageIsWarcraftDamage?"NB":"");
    PrintToChatAll("[DP2] %s%s %s", pre, szBuffer,W3GetDamageIsBullet()?"B":"",!g_NextDamageIsWarcraftDamage?"NB":"");
    
}














//dealdamage reaches far into the stack:
/*
[DP2]     playerHurt 1->10  dmg [34]  B
[DP2]     dealdamage 10->1 { 
[DP2]         sdktakedamage 10->1 atrace Night Elf damage [6.00] 
[DP2]         sdktakedamage 10->1 END dmg [6.00] 
[DP2]         PlayerHurt 10->1  dmg [3]  
[DP2]         PlayerHurt 10->1  dmg [3] END  
                ^^^^coplies the damage to global
[DP2]     dealdamage 10->1 } B
[*/
public Native_War3_DealDamage(Handle:plugin,numParams)
{
    new bool:whattoreturn=true;
    
    new bool:noWarning = false;
    if (numParams >= 9)
        noWarning = GetNativeCell(9);
    
    if(!g_CanDealDamage && !noWarning){
        War3_LogError("War3_DealDamage called when DealDamage is not suppose to be called, please use the non PRE forward");
        ThrowError("War3_DealDamage called when DealDamage is not suppose to be called, please use the non PRE forward");
        //LogError("War3_DealDamage called when DealDamage is not suppose to be called, please use the non PRE forward");
        //PrintPluginError(plugin);
    }
    
        
    decl victim;
    victim=GetNativeCell(1);
    decl damage;
    damage=GetNativeCell(2);
    decl attacker;
    attacker=GetNativeCell(3);
        
    
    if((ValidPlayer(victim,true) || War3_IsL4DZombieEntity(victim)) && damage>0 )
    {
        //new old_DamageDealt=g_CurActualDamageDealt;
        new old_IsWarcraftDamage= g_CurDamageIsWarcraft;
        new old_IsTrueDamage = g_CurDamageIsTrueDamage;
        
        new old_NextDamageIsWarcraftDamage=g_NextDamageIsWarcraftDamage; 
        new old_NextDamageIsTrueDamage=g_NextDamageIsTrueDamage;
        
        g_CurLastActualDamageDealt=-88;
        
        
        new dmg_type;
        dmg_type=GetNativeCell(4);  //original weapon damage type
        decl String:weapon[64];
        GetNativeString(5,weapon,64);
        
        
        
        decl War3DamageOrigin:W3DMGORIGIN;
        W3DMGORIGIN=GetNativeCell(6);
        decl War3DamageType:WAR3_DMGTYPE;
        WAR3_DMGTYPE=GetNativeCell(7);
        
        decl bool:respectVictimImmunity;
        respectVictimImmunity=GetNativeCell(8);
        
        if(ValidPlayer(victim) && respectVictimImmunity){
            switch(W3DMGORIGIN){
                case W3DMGORIGIN_SKILL:  {
                    if(W3HasImmunity(victim,Immunity_Skills) ){
                        return false;
                    }
                }
                case W3DMGORIGIN_ULTIMATE:  {
                    if(W3HasImmunity(victim,Immunity_Ultimates) ){
                        return false;
                    }
                }
                case W3DMGORIGIN_ITEM:  {
                    if(W3HasImmunity(victim,Immunity_Items) ){
                        return false;
                    }
                }
                
            }
            
            
            switch(WAR3_DMGTYPE){
                case W3DMGTYPE_PHYSICAL:  {
                    if(W3HasImmunity(victim,Immunity_PhysicalDamage) ){
                        return false;
                    }
                }
                case W3DMGTYPE_MAGIC:  {
                    if(W3HasImmunity(victim,Immunity_MagicDamage) ){
                        return false;
                    }
                }
            }
        }
        new bool:countAsFirstTriggeredDamage;
        countAsFirstTriggeredDamage=GetNativeCell(9);
        
        if(countAsFirstTriggeredDamage){
            g_NextDamageIsWarcraftDamage=false;
        }
        else {
            g_NextDamageIsWarcraftDamage=true;
        }
        g_CurDamageIsWarcraft=g_NextDamageIsWarcraftDamage;
        ///sdk immediately follows, we must expose this to posthurt once sdk exists
        //new bool:settobullet=bool:W3GetDamageIsBullet(); //just in case someone dealt damage inside this forward and made it "not bullet"
     
        
    
        
        decl oldcsarmor;
        if((WAR3_DMGTYPE==W3DMGTYPE_TRUEDMG||WAR3_DMGTYPE==W3DMGTYPE_MAGIC)&&War3_GetGame()==CS){
            oldcsarmor=War3_GetCSArmor(victim);
            War3_SetCSArmor(victim,0) ;
        }
        
        g_NextDamageIsTrueDamage=(WAR3_DMGTYPE==W3DMGTYPE_TRUEDMG);
        g_CurDamageIsTrueDamage=(WAR3_DMGTYPE==W3DMGTYPE_TRUEDMG);
        


        #if defined DEBUG
        DP2("dealdamage %d->%d {",attacker,victim);
        damagestack++;
        #endif
        
        decl String:dmg_str[16];
        IntToString(damage,dmg_str,sizeof(dmg_str));
        decl String:dmg_type_str[32];
        IntToString(dmg_type,dmg_type_str,sizeof(dmg_type_str));
        
        new pointHurt=CreateEntityByName("point_hurt");
        if(pointHurt)
        {
            //    PrintToChatAll("%d %d %d",victim,damage,g_CurActualDamageDealt);
            DispatchKeyValue(victim,"targetname","war3_hurtme"); //set victim as the target for damage
            DispatchKeyValue(pointHurt,"Damagetarget","war3_hurtme");
            DispatchKeyValue(pointHurt,"Damage",dmg_str);
            DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
            if(!StrEqual(weapon,""))
            {
                DispatchKeyValue(pointHurt,"classname",weapon);
            }
            else{
                DispatchKeyValue(pointHurt,"classname","war3_point_hurt");
            }
            DispatchSpawn(pointHurt);
            AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
            //DispatchKeyValue(pointHurt,"classname","point_hurt");
            DispatchKeyValue(victim,"targetname","war3_donthurtme"); //unset the victim as target for damage
            RemoveEdict(pointHurt);
            //    PrintToChatAll("%d %d %d",victim,damage,g_CurActualDamageDealt);
        }
        //removed for now... SDKHooks_TakeDamage(victim, attacker, attacker, float(damage), dmg_type);
        //damage has been dealt BY NOW
        
        if((WAR3_DMGTYPE==W3DMGTYPE_TRUEDMG||WAR3_DMGTYPE==W3DMGTYPE_MAGIC)&&War3_GetGame()==CS){
            War3_SetCSArmor(victim,oldcsarmor);
        }
        
        if(g_CurLastActualDamageDealt==-88){
            g_CurLastActualDamageDealt=0;
            whattoreturn=false;
        }
        #if defined DEBUG
        damagestack--;
        DP2("dealdamage %d->%d }",attacker,victim);
        #endif
        
        g_CurDamageIsWarcraft= old_IsWarcraftDamage;
    
        g_CurDamageIsTrueDamage = old_IsTrueDamage;
        
        g_NextDamageIsWarcraftDamage=old_NextDamageIsWarcraftDamage; 
        g_NextDamageIsTrueDamage=old_NextDamageIsTrueDamage;
        
        War3_LogInfo("War3_DealDamage from attacker \"{client %i}\" to victim \"{client %i}\" (%i dmg)", attacker, victim, damage);
    }
    else{
        //player is already dead
        whattoreturn=false;
        g_CurLastActualDamageDealt=0;
    }

    
    
    return whattoreturn;
}
public Native_War3_GetWar3DamageDealt(Handle:plugin,numParams) {
    return g_CurLastActualDamageDealt;
}
