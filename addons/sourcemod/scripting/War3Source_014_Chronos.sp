#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface" 
#include <sdktools>

public Plugin:myinfo = 
{
    name = "War3Source - Race - Chronos",
    author = "War3Source Team",
    description = "The Chronos race for War3Source."
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

new m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity; //offsets

new bool:bTrapped[MAXPLAYERSCUSTOM];

new SKILL_LEAP, SKILL_REWIND, SKILL_TIMELOCK, ULT_SPHERE;
////we add stuff later

//leap
new Float:leapPower[5]={0.0,350.0,400.0,450.0,500.0};
new Float:leapPowerTF[5]={0.0,500.0,550.0,600.0,650.0};

//rewind
new Float:RewindChance[5]={0.0,0.1,0.15,0.2,0.25}; 
new RewindHPAmount[MAXPLAYERSCUSTOM];

//bash
new Float:TimeLockChance[5]={0.0,0.1,0.15,0.2,0.25};

//sphere
new Float:ultRange=200.0;
new Handle:ultCooldownCvar;
new Float:SphereTime[5]={0.0,3.0,3.5,4.0,4.5};

new String:leapsnd[256]; //="war3source/chronos/timeleap.mp3";
new String:spheresnd[256]; //="war3source/chronos/sphere.mp3";

new Float:sphereRadius=150.0;

new bool:hasSphere[MAXPLAYERSCUSTOM];
new Float:SphereLocation[MAXPLAYERSCUSTOM][3];
new Float:SphereEndTime[MAXPLAYERSCUSTOM];


new BeamSprite;
new HaloSprite;


stock oldbuttons[MAXPLAYERSCUSTOM];
new bool:lastframewasground[MAXPLAYERSCUSTOM];

public OnPluginStart()
{
    ultCooldownCvar=CreateConVar("war3_chronos_ult_cooldown","20");
    
    m_vecVelocity_0 = FindSendPropInfo("CBasePlayer","m_vecVelocity[0]");
    m_vecVelocity_1 = FindSendPropInfo("CBasePlayer","m_vecVelocity[1]");
    m_vecBaseVelocity = FindSendPropInfo("CBasePlayer","m_vecBaseVelocity");
    
    if(GAMECSANY){
        HookEvent("player_jump",PlayerJumpEvent);
    }
    LoadTranslations("w3s.race.chronos.phrases.txt");
}

new glowsprite;
public OnMapStart()
{
    War3_AddSoundFolder(leapsnd, sizeof(leapsnd), "chronos/timeleap.mp3");
    War3_AddSoundFolder(spheresnd, sizeof(spheresnd), "chronos/sphere.mp3");

    War3_AddCustomSound(leapsnd);
    War3_AddCustomSound(spheresnd);
    glowsprite=PrecacheModel("sprites/strider_blackball.spr");
    
    BeamSprite=War3_PrecacheBeamSprite();
    HaloSprite=War3_PrecacheHaloSprite();
}

public OnWar3LoadRaceOrItemOrdered(num)
{    
    if(num==140)
    {
        thisRaceID=War3_CreateNewRaceT("chronos");
        SKILL_LEAP=War3_AddRaceSkillT(thisRaceID,"TimeLeap",false,4);
        SKILL_REWIND=War3_AddRaceSkillT(thisRaceID,"Rewind",false,4);
        SKILL_TIMELOCK=War3_AddRaceSkillT(thisRaceID,"TimeLock",false,4);
        ULT_SPHERE=War3_AddRaceSkillT(thisRaceID,"Chronosphere",true,4); 
        War3_CreateRaceEnd(thisRaceID);
    }
}

public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(RaceDisabled)
    {
        return;
    }

    new client=GetClientOfUserId(GetEventInt(event,"userid"));

    if(ValidPlayer(client,true)){
        new race=War3_GetRace(client);
        if (race==thisRaceID)
        {
            
            new sl=War3_GetSkillLevel(client,race,SKILL_LEAP);
            
            if(!Hexed(client)&&sl>0&&SkillAvailable(client,thisRaceID,SKILL_LEAP,false))
            {
                
                new Float:velocity[3]={0.0,0.0,0.0};
                velocity[0]= GetEntDataFloat(client,m_vecVelocity_0);
                velocity[1]= GetEntDataFloat(client,m_vecVelocity_1);
                new Float:len=GetVectorLength(velocity);
                if(len>3.0){
                    //PrintToChatAll("pre  vec %f %f %f",velocity[0],velocity[1],velocity[2]);
                    ScaleVector(velocity,leapPower[sl]/len);
                    
                    //PrintToChatAll("post vec %f %f %f",velocity[0],velocity[1],velocity[2]);
                    SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
                    W3EmitSoundToAll(leapsnd,client);
                    W3EmitSoundToAll(leapsnd,client);
                    War3_CooldownMGR(client,10.0,thisRaceID,SKILL_LEAP,_,_);
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
            new skill_SKILL_ASSAULT=War3_GetSkillLevel(client,thisRaceID,SKILL_LEAP);
            if (skill_SKILL_ASSAULT)
            {
                //assaultskip[client]--;
                //if(assaultskip[client]<1&&
                new bool:lastwasgroundtemp=lastframewasground[client];
                lastframewasground[client]=bool:(GetEntityFlags(client) & FL_ONGROUND);
                if(!Hexed(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_LEAP) &&  lastwasgroundtemp &&   !(GetEntityFlags(client) & FL_ONGROUND) )
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
                    //    new Float:amt = 1.2 + (float(skill_SKILL_ASSAULT)*0.20);
                        //velocity[0]*=amt;
                    //    velocity[1]*=amt;
                        ScaleVector(velocity,leapPowerTF[skill_SKILL_ASSAULT]/len);
                        velocity[2]=oldz;
                        TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
                        //SetEntDataVector(client,m_vecBaseVelocity,velocity,true); //CS
                    }
                    
                    
                    W3EmitSoundToAll(leapsnd,client);
                    W3EmitSoundToAll(leapsnd,client);
                    
                    
                    //new Float:amt = 1.0 + (float(skill_SKILL_ASSAULT)*0.2);
                    //velocity[0]*=amt;
                    //velocity[1]*=amt;
                    //TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
                    
                    War3_CooldownMGR(client,10.0,thisRaceID,SKILL_LEAP,_,_);
                    //new color[4] = {255,127,0,255};
                    
                }
            }
        }
    }
    return Plugin_Continue;
}

public OnUltimateCommand(client,race,bool:pressed)
{
    if(RaceDisabled)
    {
        return;
    }

    if(race==thisRaceID && IsPlayerAlive(client) && pressed)
    {
        new skill_level=War3_GetSkillLevel(client,race,ULT_SPHERE);
        if(skill_level>0)
        {
            
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_SPHERE,true)){
                
                new Float:endpos[3];
                War3_GetAimTraceMaxLen(client,endpos,ultRange);
                
                new Float:down[3];
                down[0]=endpos[0];
                down[1]=endpos[1];
                down[2]=endpos[2]-200;
                TR_TraceRay(endpos,down,MASK_ALL,RayType_EndPoint);
                TR_GetEndPosition(endpos);
                
                W3EmitSoundToAll(spheresnd,0,_,_,_,_,_,_,endpos);
                W3EmitSoundToAll(spheresnd,0,_,_,_,_,_,_,endpos);
                W3EmitSoundToAll(spheresnd,0,_,_,_,_,_,_,endpos);
                
                new Float:life=SphereTime[skill_level];
                
                for(new i=0;i<3;i++)
                    SphereLocation[client][i]=endpos[i];
                
                SphereEndTime[client]=GetGameTime()+life;
                hasSphere[client]=true;
                CreateTimer(0.1,sphereLoop,client);
                
                //new Float:angles[10]={
                //TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{0,255,0,255},10,0);
                
                new Float:tempdiameter;
                for(new i=-1;i<=8;i++){
                    new Float:rad=float(i*10)/360.0*(3.14159265*2);
                    tempdiameter=sphereRadius*Cosine(rad)*2;
                    new Float:heightoffset=sphereRadius*Sine(rad);
                    
                    //PrintToChatAll("degree %d rad %f sin %f cos %f radius %f offset %f",i*10,rad,Sine(rad),Cosine(rad),radius,heightoffset);
                    
                    new Float:origin[3];
                    origin[0]=endpos[0];
                    origin[1]=endpos[1];
                    origin[2]=endpos[2]+heightoffset;
                    TE_SetupBeamRingPoint(origin, tempdiameter-0.1, tempdiameter, BeamSprite, HaloSprite, 0, 0, life, 2.0, 0.0, {80,200,255,122}, 10, 0);
                    TE_SendToAll();
                }
                
                
                
                
                sphereLoop(INVALID_HANDLE,client);
                
                CreateTimer(life,sphereend,client);
                
                TE_SetupGlowSprite(endpos,glowsprite,life,3.57,255);
                TE_SendToAll();
                War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_SPHERE,_,_);
            }
        }
        else
        {
            W3MsgUltNotLeveled(client);
        }
    }
}
public Action:sphereLoop(Handle:h,any:client){
    if(RaceDisabled)
    {
        return;
    }

    if(hasSphere[client]&&SphereEndTime[client]>GetGameTime()){
        new Float:victimpos[3];
        new team=GetClientTeam(client);
        for(new i=1;i<=MaxClients;i++){
            if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&!bTrapped[i]&&!W3HasImmunity(i,Immunity_Ultimates)){
                GetClientEyePosition(i,victimpos);
                if(GetVectorDistance(SphereLocation[client],victimpos)<sphereRadius+10)
                {
                    CreateTimer(SphereEndTime[client]-GetGameTime(),unBashUlt,i);
                    War3_SetBuff(i,bBashed,thisRaceID,true);
                    
                    if(GAMECSANY){
                        FakeClientCommand(i,"use weapon_knife");
                    }
                    else{
                        War3_SetBuff(i,fAttackSpeed,thisRaceID,0.33);
                    }
                    
                    War3_SetBuff(i,bImmunitySkills,thisRaceID,false);
                    War3_SetBuff(i,bImmunityUltimates,thisRaceID,false);
                    bTrapped[i]=true;
                    PrintHintText(i,"%T","You have been trapped by a Chronosphere! You can only receive Melee damage",i);
                    
                    //EmitSoundToClient(i,spheresnd);
                
                }
            }
        }
    
        CreateTimer(0.1,sphereLoop,client);
    }



    
}
public Action:unBashUlt(Handle:h,any:client){
    if(RaceDisabled)
    {
        return;
    }

    War3_SetBuff(client,bBashed,thisRaceID,false);
    War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
    bTrapped[client]=false;
    War3_SetBuff(client,bImmunitySkills,thisRaceID,false);
    War3_SetBuff(client,bImmunityUltimates,thisRaceID,false);
    
}
public Action:sphereend(Handle:h,any:client){
    if(RaceDisabled)
    {
        return;
    }

    hasSphere[client]=false;
    
}

public OnW3TakeDmgAllPre(victim,attacker,Float:damage){
    if(RaceDisabled)
    {
        return;
    }

    if(IS_PLAYER(victim) && bTrapped[victim]){ ///trapped people can only be damaged with knife
        if(ValidPlayer(attacker)){
            new wpnent = W3GetCurrentWeaponEnt(attacker);
            if(!War3_IsMeleeWeapon(wpnent)){
                War3_DamageModPercent(0.0);
                return;
            }
        } else {
            War3_DamageModPercent(0.0);
            return;
        }
    }
    if(ValidPlayer(attacker) && bTrapped[attacker]){ //trapped people can only use knife
        new wpnent = W3GetCurrentWeaponEnt(attacker);
        if(!War3_IsMeleeWeapon(wpnent)){
            PrintHintText(attacker,"%T","You can only damage with knife",attacker);
            War3_DamageModPercent(0.0);
            return;
        }
    }
    if(ValidPlayer(attacker,true)&&IsInOwnSphere(victim)&&!bTrapped[attacker]&&!W3HasImmunity(attacker,Immunity_Ultimates)){ //cant shoot to inside the sphere    
        War3_DamageModPercent(0.0);
    }
    else if(ValidPlayer(attacker,true)&&IsInOwnSphere(attacker)&&!bTrapped[victim]){    //cant shoot outside of your sphere
        War3_DamageModPercent(0.0);    
    }
}
IsInOwnSphere(client){
    if(RaceDisabled)
    {
        return false;
    }

    if(hasSphere[client]){
        new Float:pos[3];
        GetClientEyePosition(client,pos);
        if(GetVectorDistance(SphereLocation[client],pos)<sphereRadius+10.0){ //chronos is in his sphere
            return true;
        }
    }
    return false;
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(RaceDisabled)
    {
        return;
    }

    if(ValidPlayer(victim,true)&&ValidPlayer(attacker,true) &&GetClientTeam(attacker)!=GetClientTeam(victim))
    {    
        
        new skilllevel=War3_GetSkillLevel(victim,thisRaceID,SKILL_REWIND);
        //we do a chance roll here, and if its less than our limit (RewindChance) we proceede i a with u
        // allow self damage rewind
        if(War3_GetRace(victim)==thisRaceID && skilllevel>0&& War3_Chance(RewindChance[skilllevel]) && !W3HasImmunity(attacker,Immunity_Skills)&&!Hexed(victim)) //chance roll, and attacker isnt immune to skills
        {
            RewindHPAmount[victim]+= RoundToFloor(damage);//we create this variable
            PrintHintText(victim,"%T","Rewind +{amount} HP!",victim, RoundToFloor(damage));
            W3FlashScreen(victim,RGBA_COLOR_GREEN);
        }
        
        
        new race_attacker=War3_GetRace(attacker);
        skilllevel=War3_GetSkillLevel(attacker,thisRaceID,SKILL_TIMELOCK);
        if(race_attacker==thisRaceID && skilllevel > 0 && victim!=attacker)
        {
            if(War3_Chance(TimeLockChance[skilllevel])&& !W3HasImmunity(victim,Immunity_Skills) && !Stunned(victim)&&!Hexed(attacker))
            {
                PrintHintText(victim,"%T","You got Time Locked",victim);
                PrintHintText(attacker,"%T","Time Lock!",attacker);
                
                
                W3FlashScreen(victim,RGBA_COLOR_BLUE);
                CreateTimer(0.15,UnfreezeStun,victim);
                
                War3_SetBuff(victim,bStunned,thisRaceID,true);
            }
        }
        
    }
}


public Action:UnfreezeStun(Handle:h,any:client) //always keep timer data generic
{
    if(RaceDisabled)
    {
        return;
    }

    War3_SetBuff(client,bStunned,thisRaceID,false);
}
public OnWar3EventDeath(victim,attacker){
    if(RaceDisabled)
    {
        return;
    }

    RewindHPAmount[victim]=0;
}
new skip;
public OnGameFrame() //this is a sourcemod forward?, every game frame it is called. forwards if u implement it sourcemod will call you
{
    if(RaceDisabled)
    {
        return;
    }

    if(skip==0){
    
        for(new i=1;i<=MaxClients;i++){
            if(ValidPlayer(i,true))//valid (in game and shit) and alive (true parameter)k
            {
                if(RewindHPAmount[i]>0){
                    War3_HealToMaxHP(i,1);
                    RewindHPAmount[i]--;
                }
            }
            
        }
        skip=2;
    }
    skip--;
}

