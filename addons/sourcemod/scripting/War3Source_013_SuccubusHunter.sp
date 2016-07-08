#pragma semicolon 1
#include <sourcemod>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_tempents_stocks>
#include <sdktools_entinput>
#include <sdktools_sound>

#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Race - Succubus Hunter",
    author = "War3Source Team",
    description = "The Succubus Hunter race for War3Source."
};

new thisRaceID, SKILL_HEADHUNTER, SKILL_TOTEM, SKILL_ASSAULT, ULT_TRANSFORM;

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

new m_iAccount = -1,m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity; //offsets


//new bool:hurt_flag = true;
new bool:m_IsULT_TRANSFORMformed[MAXPLAYERSCUSTOM];
new skulls[MAXPLAYERSCUSTOM];
new ValveGameEnum:g_GameType;
//Effects
//new BeamSprite;
new Laser;

new bool:lastframewasground[MAXPLAYERSCUSTOM];
new Handle:ultCooldownCvar;
new Handle:totemCurrencyCvar;

new Float:assaultcooldown=10.0;

public OnMapStart()
{
    //PrecacheSound("npc/fast_zombie/claw_strike1.wav");
    PrecacheModel("models/gibs/hgibs.mdl", true);
    //BeamSprite=PrecacheModel("materials/sprites/purpleglow1.vmt");
    Laser=PrecacheModel("materials/sprites/laserbeam.vmt");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==130)
    {
        thisRaceID=War3_CreateNewRaceT("succubus");
        
        SKILL_HEADHUNTER = War3_AddRaceSkillT(thisRaceID, "HeadHunter", false,_,"0-20%");    
        SKILL_TOTEM = War3_AddRaceSkillT(thisRaceID, "TIncantation", false);    
        SKILL_ASSAULT = War3_AddRaceSkillT(thisRaceID, "ATackle", false);
        ULT_TRANSFORM = War3_AddRaceSkillT(thisRaceID, "DTransformation", true);
        War3_CreateRaceEnd(thisRaceID);
        
    }
}

public OnPluginStart()
{
    m_vecVelocity_0 = FindSendPropInfo("CBasePlayer","m_vecVelocity[0]");
    
    //HookEvent("player_hurt",PlayerHurtEvent);
    //HookEvent("player_death",PlayerDeathEvent);
    
    if(GAMECSANY)
    {
        HookEvent("player_jump",PlayerJumpEvent);
        m_vecVelocity_1 = FindSendPropInfo("CBasePlayer","m_vecVelocity[1]");
        m_vecBaseVelocity = FindSendPropInfo("CBasePlayer","m_vecBaseVelocity");
    }
    
    AddCommandListener(SayCommand, "say");
    AddCommandListener(SayCommand, "say_team");
    
    m_iAccount = FindSendPropInfo("CCSPlayer", "m_iAccount");
    
    ultCooldownCvar=CreateConVar("war3_succ_ult_cooldown","20","Cooldown for succubus ultimate");
    totemCurrencyCvar=CreateConVar("war3_succ_totem_currency","0","Currency to use for totem | 0=currency, 1=gold, 2=money");
    
    LoadTranslations("w3s.race.succubus.phrases.txt");
}
public OnRaceChanged(client,oldrace,newrace){
    if(RaceDisabled)
    {
        return;
    }

    if(oldrace==thisRaceID){
        W3ResetAllBuffRace( client, thisRaceID );
    }
}
public OnWar3EventSpawn(client)
{
    if(RaceDisabled)
    {
        return;
    }

    new race=War3_GetRace(client); 
    if (race==thisRaceID) 
    {
        m_IsULT_TRANSFORMformed[client]=false;
        War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
        War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.0);    
        
    
        
        new skillleveltotem=War3_GetSkillLevel(client,race,SKILL_TOTEM); 
        if (skillleveltotem )
        {
            new maxhp = War3_GetMaxHP(client);
            new hp, dollar, xp; 
            switch(skillleveltotem)
            {
                case 1: 
                {
                    hp=RoundToNearest(float(maxhp) * 0.01);
                    dollar=25;
                    xp=1;
                }
                case 2: 
                {
                    hp=RoundToNearest(float(maxhp) * 0.01);
                    dollar=30;
                    xp=2;
                }
                case 3: 
                {
                    hp=RoundToNearest(float(maxhp) * 0.02);
                    dollar=35;
                    xp=3;
                }
                case 4:
                {
                    hp=RoundToNearest(float(maxhp) * 0.02);
                    dollar=50;
                    xp=5;
                }
            }
            
            hp *= skulls[client];
            dollar *= skulls[client];
            xp *= skulls[client];
            
            if(GameCS()){    
                new old_health=GetClientHealth(client);
                SetEntityHealth(client,old_health+hp);
            }
            else{
            
                War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,hp);
            }
            
            new old_XP = War3_GetXP(client,thisRaceID);
            new kill_XP = W3GetKillXP(client);
            if (xp > kill_XP)
                xp = kill_XP;
                
            if(W3GetPlayerProp(client,bStatefulSpawn)){
                War3_SetXP(client,thisRaceID,old_XP+xp);
            }
            
            
            //PrintToChat(client,"new_credits %d",new_credits);
            if(W3GetPlayerProp(client,bStatefulSpawn))
            {
                new totemCurrencySwitch = GetConVarInt(totemCurrencyCvar);
                new oldCash, newCash;
                switch(totemCurrencySwitch)
                {
                    // use system set currency
                    case 0: 
                    {
                        dollar /= 16;
                        oldCash = War3_GetCurrency(client);
                        War3_AddCurrency(client, dollar);
                        newCash = War3_GetCurrency(client);
                        if(!GAMEFOF)
                        {
                            War3_ChatMessage(client,"%T","[Totem Incantation] You gained {amount} HP, {amount} credits and {amount} XP",client,0x04,0x01,hp,newCash - oldCash,xp);
                        }
                        else
                        {
                            War3_ChatMessage(client,"%T","[Totem Incantation FOF] You gained {amount} HP, {amount} credits and {amount} XP",client,hp,(newCash - oldCash),xp);
                        }
                    }
                    // use gold
                    case 1: 
                    {
                        new Handle:g_hMaxCurrency = FindConVar("war3_max_currency");
                        new max;
                        if(g_hMaxCurrency != INVALID_HANDLE)
                        {
                            max=GetConVarInt(g_hMaxCurrency);
                        }
                        else
                        {
                            max = 100;
                        }
                            

                        oldCash=War3_GetGold(client);
                        dollar /= 16;
                        newCash = oldCash + dollar;
                        if (newCash > max)
                            newCash = max;
                        War3_SetGold(client,newCash);
                        
                        War3_ChatMessage(client,"%T","[Totem Incantation] You gained {amount} HP, {amount} gold and {amount} XP",client,0x04,0x01,hp,newCash - oldCash,xp);

                    }
                    // use money
                    case 2: 
                    {
                        oldCash=GetEntData(client, m_iAccount);
                        newCash = oldCash + dollar;
                        SetEntData(client, m_iAccount, newCash);
                        War3_ChatMessage(client,"%T","[Totem Incantation] You gained {amount} HP, {amount} dollars and {amount} XP",client,0x04,0x01,hp,newCash - oldCash,xp);
                    }
                }
            }
        }
    }
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(RaceDisabled)
    {
        return;
    }

    if(!isWarcraft && ValidPlayer(victim, true, true) && ValidPlayer(attacker) && victim != attacker && GetClientTeam( victim ) != GetClientTeam( attacker ))
    {
        new skilllevelheadhunter = War3_GetSkillLevel(attacker, thisRaceID, SKILL_HEADHUNTER);
        if (skilllevelheadhunter > 0 && !W3HasImmunity(victim, Immunity_Skills) && !Hexed(attacker))
        {
            new xdamage= RoundFloat(0.2 * damage * skulls[attacker] / 20);
            War3_DealDamage(victim, xdamage, attacker, _, "headhunter", W3DMGORIGIN_SKILL, W3DMGTYPE_PHYSICAL);
            W3PrintSkillDmgConsole(victim,attacker,War3_GetWar3DamageDealt(),SKILL_HEADHUNTER);
        }
    }
}
/*
public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if (hurt_flag == false)
    {
        hurt_flag=true; //for skipping your own damage?
        return;
    }
    
    new victim = GetClientOfUserId(GetEventInt(event,"userid"));
    new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
    if (victim && attacker && victim!=attacker) // &&hurt_flag==true)
    {
    
        new race=War3_GetRace(attacker);
        if (race==thisRaceID)
        {
            new dmgamount;
            switch (g_GameType)
            {
                case Game_CS: dmgamount = GetEventInt(event,"dmg_health");
                case Game_TF: dmgamount = GetEventInt(event,"damageamount");
                case Game_DOD: dmgamount = GetEventInt(event,"damage");
            }
            
            new totaldamage = dmgamount;
            
            // Head Hunter
            new skilllevelheadhunter = War3_GetSkillLevel(attacker,race,SKILL_HEADHUNTER);
            if (skilllevelheadhunter > 0 && dmgamount > 0 && !W3HasImmunity(victim,Immunity_Skills)&&!Hexed(attacker))
            {
                decl String: weapon[MAX_NAME_LENGTH+1];
                new bool:is_equipment=GetWeapon(event,attacker,weapon,sizeof(weapon));
                new bool:is_melee=IsMelee(weapon, is_equipment, attacker, victim);
                
                new damage;
                if (is_melee)
                {
                    new Float:percent;
                    switch(skilllevelheadhunter)
                    {
                        case 1:
                        percent=0.50;
                        case 2:
                        percent=0.75;
                        case 3:
                        percent=0.90;
                        case 4:
                        percent=1.00;
                    }
                    damage= RoundFloat(float(dmgamount) * percent);
                    totaldamage += damage;
                    
                    new Float:vec[3];
                    GetClientAbsOrigin(attacker,vec);
                    vec[2]+=50.0;
                    TE_SetupGlowSprite(vec, BeamSprite, 2.0, 10.0, 5);
                    TE_SendToAll();
                    W3PrintSkillDmgConsole(victim,attacker,damage,SKILL_HEADHUNTER);
                    //PrintToConsole(attacker,"%T","[Daemonic Knife] You inflicted +{amount} Damage",attacker,0x04,0x01,damage);
                }
                else
                {
                    new percent;
                    switch (skilllevelheadhunter)
                    {
                        case 1:
                        percent=10;
                        case 2:
                        percent=15;
                        case 3:
                        percent=20;
                        case 4:
                        percent=30;
                    }
                    if(GetRandomInt(1,100)<=percent)
                    {
                        damage= RoundFloat(dmgamount * GetRandomFloat(0.20,0.40)); // 1.20-1.00,1.40-1.00
                        totaldamage += damage;
                        W3PrintSkillDmgConsole(victim,attacker,damage,SKILL_HEADHUNTER);
                        //PrintToConsole(attacker,"%T","[Head Hunter] You inflicted +{amount} Damage",attacker,0x04,0x01,damage);
                    }
                }
                
                if (damage>0)
                {
                    
                    hurt_flag = false;
                    War3_DealDamage(victim,damage,attacker,_,"headhunter",W3DMGORIGIN_SKILL,W3DMGTYPE_PHYSICAL);
                }
            }
        }
    }
}
*/
public OnWar3EventDeath(victim,attacker){
    if(RaceDisabled)
    {
        return;
    }

    new skilllevelheadhunter=War3_GetSkillLevel(attacker,thisRaceID,SKILL_HEADHUNTER);
    if (skilllevelheadhunter &&!Hexed(attacker)&&victim!=attacker)
    {
        if (skulls[attacker]<(5*skilllevelheadhunter))
        {
            skulls[attacker]++;
            War3_ChatMessage(attacker,"%T","You gained a SKULL [{amount}/{amount}]",attacker,skulls[attacker],(5*skilllevelheadhunter));
        }                            
        decl Float:Origin[3], Float:Direction[3];
        GetClientAbsOrigin(victim, Origin);
        Direction[0] = GetRandomFloat(-100.0, 100.0);
        Direction[1] = GetRandomFloat(-100.0, 100.0);
        Direction[2] = 300.0;
        Gib(Origin, Direction, "models/gibs/hgibs.mdl");
    }
}
/*
public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
DP("death");
//W3GetVar(SmEvent)
    #define DF_FEIGNDEATH   32
    #define DMG_CRITS       1048576    //crits = DAMAGE_ACID
    
    static const String:tf2_decap_weapons[][] = { "sword",   "club",      "axtinguisher",
    "fireaxe", "battleaxe", "tribalkukri"};
    
    new victim = GetClientOfUserId(GetEventInt(event,"userid"));
    
    if (victim > 0)
    {
        //if (War3_GetRace(victim) == thisRaceID){
        //    if(skulls[victim]>0){
        //        skulls[victim]--;
        //        PrintToConsole(victim,"You lost your own skull");
        //    }
        //}

        new client = GetClientOfUserId(GetEventInt(event,"attacker"));
        if (client > 0 && client != victim)
        {
            if (War3_GetRace(client) == thisRaceID )
            {
                new bool:headshot;
                switch (g_GameType)
                {
                    case Game_CS:
                    {
                        headshot = GetEventBool(event, "headshot");
                    }
                    case Game_TF:
                    {
                        // Don't count dead ringer fake deaths
                        if ((GetEventInt(event, "death_flags") & DF_FEIGNDEATH) == 0)
                        {
                            // Check for headshot or backstab
                            new customkill = GetEventInt(event, "customkill");
                            headshot = (customkill == 1 || customkill == 2);
                        }
                    }
                    case Game_DOD:
                    {
                        headshot = false;
                    }
                }
                
                // Head Hunter
                new skilllevelheadhunter=War3_GetSkillLevel(client,thisRaceID,SKILL_HEADHUNTER);
                if (skilllevelheadhunter &&!Hexed(client))
                {
                    new bool:decap = false;
                    if (g_GameType == Game_TF)
                    {
                        decl String:weapon[128];
                        GetEventString(event, "weapon", weapon, sizeof(weapon));
                        
                        for (new i = 0; i < sizeof(tf2_decap_weapons); i++)
                        {
                            if (StrEqual(weapon,tf2_decap_weapons[i],false))
                            {
                                decap = ((GetEventInt(event, "damagebits") & DMG_CRITS) != 0);
                                break;
                            }
                        }
                    }
                    else
                    decap = false;
                    
                    if(!decap&&!headshot){
                        decl String:weapon[128];
                        GetEventString(event, "weapon", weapon, sizeof(weapon));
                        if(StrEqual(weapon,"headhunter",false)){
                            decap=true;
                        }
                    }
                    
                    ///FORCE ALWAYS GET SKULL
                    headshot=true;
                    
                    if (headshot || decap )
                    {
                        if (skulls[client]<(5*skilllevelheadhunter))
                        {
                            skulls[client]++;
                            War3_ChatMessage(client,"%T","You gained a SKULL [{amount}/{amount}]",client,skulls[client],(5*skilllevelheadhunter));
                        }                            
                        decl Float:Origin[3], Float:Direction[3];
                        GetClientAbsOrigin(victim, Origin);
                        Direction[0] = GetRandomFloat(-100.0, 100.0);
                        Direction[1] = GetRandomFloat(-100.0, 100.0);
                        Direction[2] = 300.0;
                        Gib(Origin, Direction, "models/gibs/hgibs.mdl");
                    }
                }
            }
        }
    }
}
*/
public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(RaceDisabled)
    {
        return;
    }

    new client=GetClientOfUserId(GetEventInt(event,"userid"));
    new race=War3_GetRace(client);
    if (race==thisRaceID)
    {
        
        new skill_SKILL_ASSAULT=War3_GetSkillLevel(client,race,SKILL_ASSAULT);
        
        if (skill_SKILL_ASSAULT){
            //assaultskip[client]--;
            //if(assaultskip[client]<1||
            if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_ASSAULT)&&!Hexed(client))
            {
                //assaultskip[client]+=2;
                new Float:velocity[3]={0.0,0.0,0.0};
                velocity[0]= GetEntDataFloat(client,m_vecVelocity_0);
                velocity[1]= GetEntDataFloat(client,m_vecVelocity_1);
                velocity[0]*=float(skill_SKILL_ASSAULT)*0.25;
                velocity[1]*=float(skill_SKILL_ASSAULT)*0.25;
                
                //new Float:len=GetVectorLength(velocity,false);
                //if(len>100.0){
                //    velocity[0]*=100.0/len;
                //    velocity[1]*=100.0/len;
                //}
                //PrintToChatAll("speed vector length %f cd %d",len,War3_SkillNotInCooldown(client,thisRaceID,SKILL_ASSAULT)?0:1);
                /*len=GetVectorLength(velocity,false);
                PrintToChatAll("speed vector length %f",len);
                */
                
                SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
                War3_CooldownMGR(client,assaultcooldown,thisRaceID,SKILL_ASSAULT,_,_);
                
                new String:wpnstr[32];
                GetClientWeapon(client, wpnstr, 32);
                for(new slot=0;slot<10;slot++){
                    
                    new wpn=GetPlayerWeaponSlot(client, slot);
                    if(wpn>0){
                        //PrintToChatAll("wpn %d",wpn);
                        new String:comparestr[32];
                        GetEdictClassname(wpn, comparestr, 32);
                        //PrintToChatAll("%s %s",wpn, comparestr);
                        if(StrEqual(wpnstr,comparestr,false)){
                            
                            TE_SetupKillPlayerAttachments(wpn);
                            TE_SendToAll();
                            
                            new color[4]={0,25,255,200};
                            if(GetClientTeam(client)==TEAM_T||GetClientTeam(client)==TEAM_RED){
                                color[0]=255;
                                color[2]=0;
                            }
                            TE_SetupBeamFollow(wpn,Laser,0,0.5,2.0,7.0,1,color);
                            TE_SendToAll();
                            break;
                        }
                    }
                }
            }
        }
    }
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(RaceDisabled)
    {
        return Plugin_Continue;
    }


    if (!GAMECSANY && (buttons & IN_JUMP)) //assault for non CS games
    {
        if (War3_GetRace(client) == thisRaceID)
        {
            new skill_SKILL_ASSAULT=War3_GetSkillLevel(client,thisRaceID,SKILL_ASSAULT);
            if (skill_SKILL_ASSAULT)
            {
                //assaultskip[client]--;
                //if(assaultskip[client]<1&&
                new bool:lastwasgroundtemp=lastframewasground[client];
                lastframewasground[client]=bool:(GetEntityFlags(client) & FL_ONGROUND);
                if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_ASSAULT) &&  lastwasgroundtemp &&   !(GetEntityFlags(client) & FL_ONGROUND) &&!Hexed(client) )
                {
                    //assaultskip[client]+=2;
                    
                    
                    if (TF2_HasTheFlag(client))
                        return Plugin_Continue;
                    
                
                    
                    
                    
                    decl Float:velocity[3]; 
                    GetEntDataVector(client, m_vecVelocity_0, velocity); //gets all 3
                    
                    /*if he is not in speed ult
                    if (!(GetEntityFlags(client) & FL_ONGROUND))
                    {
                        new Float:absvel = velocity[0];
                        if (absvel < 0.0)
                            absvel *= -1.0;
                        
                        if (velocity[1] < 0.0)
                            absvel -= velocity[1];
                        else
                            absvel += velocity[1];
                        
                        new Float:maxvel = m_IsULT_TRANSFORMformed[client] ? 1000.0 : 500.0;
                        if (absvel > maxvel)
                            return Plugin_Continue;
                    }*/
                    
                    
                    new Float:oldz=velocity[2];
                    velocity[2]=0.0; //zero z
                    new Float:len=GetVectorLength(velocity);
                    if(len>3.0){
                        new Float:amt = 1.2 + (float(skill_SKILL_ASSAULT)*0.20);
                        velocity[0]*=amt;
                        velocity[1]*=amt;
                        //ScaleVector(velocity,700.0/len);
                        velocity[2]=oldz;
                        TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
                        //SetEntDataVector(client,m_vecBaseVelocity,velocity,true); //CS
                    }
                    
                    
                    
                    
                    
                    //new Float:amt = 1.0 + (float(skill_SKILL_ASSAULT)*0.2);
                    //velocity[0]*=amt;
                    //velocity[1]*=amt;
                    //TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
                    
                    War3_CooldownMGR(client,assaultcooldown,thisRaceID,SKILL_ASSAULT,_,_);
                    //new color[4] = {255,127,0,255};
                    
                    
                    if (!War3_IsCloaked(client))
                    {
                        new String:wpnstr[32];
                        GetClientWeapon(client, wpnstr, 32);
                        for(new slot=0;slot<10;slot++){
                            
                            new wpn=GetPlayerWeaponSlot(client, slot);
                            if(wpn>0){
                                //PrintToChatAll("wpn %d",wpn);
                                new String:comparestr[32];
                                GetEdictClassname(wpn, comparestr, 32);
                                //PrintToChatAll("%s %s",wpn, comparestr);
                                if(StrEqual(wpnstr,comparestr,false)){
                                    
                                    TE_SetupKillPlayerAttachments(wpn);
                                    TE_SendToAll();
                                    
                                    new color[4]={0,25,255,200};
                                    if(GetClientTeam(client)==TEAM_T||GetClientTeam(client)==TEAM_RED){
                                        color[0]=255;
                                        color[2]=0;
                                    }
                                    TE_SetupBeamFollow(wpn,Laser,0,0.5,2.0,7.0,1,color);
                                    TE_SendToAll();
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}

public OnClientPutInServer(client)
{
    skulls[client] = 0;
    m_IsULT_TRANSFORMformed[client]=false;
    
    War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
    War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.0);    
}


public OnUltimateCommand(client,race,bool:pressed)
{
    if(RaceDisabled)
    {
        return;
    }

    if(ValidPlayer(client,true)&&pressed && race==thisRaceID)
    {
        new skill_trans=War3_GetSkillLevel(client,race,ULT_TRANSFORM);
        if (skill_trans>0)
        {
            if (War3_SkillNotInCooldown(client,thisRaceID,ULT_TRANSFORM,true)&&!Silenced(client)){
            
                if (skulls[client] < skill_trans)
                {
                    new required = skill_trans - skulls[client];
                    PrintToChat(client,"%T","[Daemonic transformation] You do not have enough skulls: {amount} more required",client,0x04,0x01,required);
                }
                else
                {
                    skulls[client]-=skill_trans;
                    
                    m_IsULT_TRANSFORMformed[client]=true;
                    
                    
                    War3_SetBuff(client,fMaxSpeed,thisRaceID,float(skill_trans)/5.00+1.00);
                    War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.00-float(skill_trans)/5.00);
                    
                    new old_health=GetClientHealth(client);
                    SetEntityHealth(client,old_health+skill_trans*10);
                    
                    PrintToChat(client,"%T","[Daemonic transformation] Your daemonic powers boost your strength",client,0x04,0x01);
                    CreateTimer(10.0,Finishtrans,client);
                    War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_TRANSFORM,_,_);
                }
            }
        }
        else{
            W3MsgUltNotLeveled(client);
        }
    }
}

public Action:Finishtrans(Handle:timer,any:client)
{
    if(RaceDisabled)
    {
        return;
    }

    
    if(m_IsULT_TRANSFORMformed[client]){
        War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
        War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.0);    
        if(ValidPlayer(client,true)){
            PrintToChat(client,"%T","[Daemonic transformation] You transformed back to normal",client,0x04,0x01);
        }
    }
}












































































stock Gib(Float:Origin[3], Float:Direction[3], String:Model[])
{
    if (!IsEntLimitReached(.message="unable to create gibs"))
    {
        new Ent = CreateEntityByName("prop_physics");
        DispatchKeyValue(Ent, "model", Model);
        SetEntProp(Ent, Prop_Send, "m_CollisionGroup", 1); 
        DispatchSpawn(Ent);
        TeleportEntity(Ent, Origin, Direction, Direction);
        CreateTimer(GetRandomFloat(15.0, 30.0), RemoveGib,EntIndexToEntRef(Ent));
    }
}

public Action:RemoveGib(Handle:Timer, any:Ref)
{
    new Ent = EntRefToEntIndex(Ref);
    if (Ent > 0 && IsValidEdict(Ent))
    {
        RemoveEdict(Ent);
    }
}



/**
* Detect when changing classes in TF2
*/




public Action:SayCommand(client, const String:command[], argc)
{
    if (client > 0 && IsClientInGame(client))
    {
        decl String:text[128];
        GetCmdArg(1,text,sizeof(text));
        
        decl String:arg[2][64];
        ExplodeString(text, " ", arg, 2, 64);
        
        new String:firstChar[] = " ";
        firstChar{0} = arg[0]{0};
        if (StrContains("!/\\",firstChar) >= 0)
            strcopy(arg[0], sizeof(arg[]), arg[0]{1});
        
        if (StrEqual(arg[0],"skulls",false))
        {
            new skilllevelheadhunter = (War3_GetRace(client)==thisRaceID) ? War3_GetSkillLevel(client,thisRaceID,SKILL_HEADHUNTER) : 0;
            if (skilllevelheadhunter)
                War3_ChatMessage(client,"%T","You have ({amount}/{amount}) SKULLs",client,skulls[client],(5*skilllevelheadhunter),0x04,0x01);
            else
            War3_ChatMessage(client,"%T","You have {amount} SKULLs",client,skulls[client],0x04,0x01);
            
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

/**
* Weapons related functions.
*/
#tryinclude <sc/weapons>
#if !defined _weapons_included
stock bool:GetWeapon(Handle:event, index,
String:buffer[], buffersize)
{
    new bool:is_equipment;
    
    buffer[0] = 0;
    GetEventString(event, "weapon", buffer, buffersize);
    
    if (buffer[0] == '\0' && index && IsPlayerAlive(index))
    {
        is_equipment = true;
        GetClientWeapon(index, buffer, buffersize);
    }
    else
    is_equipment = false;
    
    return is_equipment;
}

stock bool:IsEquipmentMelee(const String:weapon[])
{
    switch (g_GameType)
    {
        case Game_CS:
        {
            return StrEqual(weapon,"weapon_knife");
        }
        case Game_DOD:
        {
            return (StrEqual(weapon,"weapon_amerknife") ||
            StrEqual(weapon,"weapon_spade"));
        }
        case Game_TF:
        {
            return (StrEqual(weapon,"tf_weapon_knife") ||
            StrEqual(weapon,"tf_weapon_shovel") ||
            StrEqual(weapon,"tf_weapon_wrench") ||
            StrEqual(weapon,"tf_weapon_bat") ||
            StrEqual(weapon,"tf_weapon_bat_wood") ||
            StrEqual(weapon,"tf_weapon_bonesaw") ||
            StrEqual(weapon,"tf_weapon_bottle") ||
            StrEqual(weapon,"tf_weapon_club") ||
            StrEqual(weapon,"tf_weapon_fireaxe") ||
            StrEqual(weapon,"tf_weapon_fists") ||
            StrEqual(weapon,"tf_weapon_sword"));
        }
    }
    return false;
}


stock bool:IsMelee(const String:weapon[], bool:is_equipment, index, victim, Float:range=100.0)
{
    if (is_equipment)
    {
        if (IsEquipmentMelee(weapon))
            return IsInRange(index,victim,range);
        else
        return false;
    }
    else
    return W3IsDamageFromMelee(weapon);
}
#endif

/**
* Range and Distance functions and variables
*/
#tryinclude <range>
#if !defined _range_included
stock Float:TargetRange(client,index)
{
    new Float:start[3];
    new Float:end[3];
    GetClientAbsOrigin(client,start);
    GetClientAbsOrigin(index,end);
    return GetVectorDistance(start,end);
}

stock bool:IsInRange(client,index,Float:maxdistance)
{
    return (TargetRange(client,index)<maxdistance);
}
#endif


/**
* Description: Function to check the entity limit.
*              Use before spawning an entity.
*/
#tryinclude <entlimit>
#if !defined _entlimit_included
stock IsEntLimitReached(warn=20,critical=16,client=0,const String:message[]="")
{
    new max = GetMaxEntities();
    new count = GetEntityCount();
    new remaining = max - count;
    if (remaining <= warn)
    {
        if (count <= critical)
        {
            PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
            LogError("Entity limit is nearly reached: %d/%d (%d):%s", count, max, remaining, message);
            
            if (client > 0)
            {
                PrintToConsole(client,"%T","Entity limit is nearly reached: {amount}/{amount} ({amount}):{message}",client,
                count, max, remaining, message);
            }
        }
        else
        {
            PrintToServer("Caution: Entity count is getting high!");
            LogMessage("Entity count is getting high: %d/%d (%d):%s", count, max, remaining, message);
            
            if (client > 0)
            {
                PrintToConsole(client,"%T","Entity count is getting high: {amount}/{amount} ({amount}):{message}",client,
                count, max, remaining, message);
            }
        }
        return count;
    }
    else
    return 0;
}
#endif
