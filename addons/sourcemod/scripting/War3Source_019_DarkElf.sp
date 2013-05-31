#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"  

public Plugin:myinfo = 
{
    name = "War3Source - Race - Dark Elf",
    author = "War3Source Team",
    description = "The Dark Elf race for War3Source."
};

new thisRaceID;

new SKILL_FADE,SKILL_SLOWFALL,SKILL_TRIBUNAL,ULTIMATE_DARKORB;

new Float:FadeChance[5]={0.0,0.05,0.10,0.15,0.20};  //done
new Float:SlowfallGravity[5]={1.0,0.85,0.70,0.55,0.40};  //probably too much overhead lololol oh god
new Float:TribunalDecay[5]={0.0,4.0,5.0,6.0,7.0};    //simple
new Float:TribunalSpeed[5]={1.0,1.10,1.20,1.30,1.40}; //simple

new bool:IsInTribunal[MAXPLAYERSCUSTOM];

//new Float:TribunalDuration=3.5;    
//new Float:TribunalCooldownTime=15.0;
new Float:DarkorbDistance=1000.0;
new Float:DarkorbDuration[5]={0.0,1.25,1.5,1.75,2.0};
new Float:DarkorbCooldownTime=10.0;

new Float:darkvec[3]={0.0,0.0,0.0};
new Float:prevdarkvec[3]={0.0,0.0,0.0};
new Float:victimvec[3]={0.0,0.0,0.0};

// Sounds
stock String:tribunal[256]; //="war3source/darkelf/tribunal.mp3";
stock String:darkorb[256]; //="war3source/darkelf/darkorb.mp3";


public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==190)
    {
        thisRaceID=War3_CreateNewRaceT("darkelf_o");
        SKILL_FADE=War3_AddRaceSkillT(thisRaceID,"Fade",false,4);
        SKILL_SLOWFALL=War3_AddRaceSkillT(thisRaceID,"SlowFall",false,4);
        SKILL_TRIBUNAL=War3_AddRaceSkillT(thisRaceID,"Tribunal",false,4);
        ULTIMATE_DARKORB=War3_AddRaceSkillT(thisRaceID,"DarkOrb",true,4); 
        War3_CreateRaceEnd(thisRaceID); ///DO NOT FORGET THE END!!!
    }
}

public OnPluginStart()
{
    CreateTimer(0.1,SlowfallTimer,_,TIMER_REPEAT);
    LoadTranslations("w3s.race.darkelf_o.phrases");
}

public OnMapStart()
{
    War3_AddSoundFolder(tribunal, sizeof(tribunal), "darkelf/tribunal.mp3");
    War3_AddSoundFolder(darkorb, sizeof(darkorb), "darkelf/darkorb.mp3");

    //Only precache them on TF2
    if(War3_GetGame()==Game_TF)
    {
        War3_PrecacheParticle("teleporter_red_entrance");
        War3_PrecacheParticle("teleporter_blue_entrance");
        War3_PrecacheParticle("ghost_smoke");
    }
    //War3_AddCustomSound(tribunal);
    //War3_AddCustomSound(darkorb);
}

public OnUltimateCommand(client,race,bool:pressed)
{
    new userid=GetClientUserId(client);
    if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) )
    {
        new ult_level=War3_GetSkillLevel(client,race,ULTIMATE_DARKORB);
        if(ult_level>0)
        {
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULTIMATE_DARKORB,true))
            {
                //War3_GetTargetInViewCone(client,Float:max_distance=0.0,bool:include_friendlys=false,Float:cone_angle=23.0,Function:FilterFunction=INVALID_FUNCTION);
                new target = War3_GetTargetInViewCone(client,DarkorbDistance,false,23.0,DarkorbFilter);
                new Float:duration = DarkorbDuration[ult_level];
                if(target>0)
                {
                    GetClientAbsOrigin(target,victimvec);
                    //W3FlashScreen(target,RGBA_COLOR_BLACK,duration,0.5,FFADE_OUT); RGBA_COLOR_etc doesn't work.
                    W3FlashScreen(target,{0,0,0,255},duration,0.5,FFADE_OUT);
                    //EmitSoundToAll(darkorb,target);
                    //EmitSoundToAll(darkorb,target);
                    if(War3_GetGame()==Game_TF) {
                        AttachThrowAwayParticle(target, "ghost_smoke", victimvec, "", duration);
                    }
                    War3_CooldownMGR(client,DarkorbCooldownTime,thisRaceID,ULTIMATE_DARKORB,_,_);
                    W3Hint(target,HINT_COOLDOWN_NOTREADY,5.0,"%T","You've been blinded by a Dark Elf!",target);
                    W3Hint(client,HINT_COOLDOWN_NOTREADY,5.0,"%T","DarkOrb blinded Successfully",client);
                }
            }
        }    
    }            
}

public bool:DarkorbFilter(client)
{
    return (!W3HasImmunity(client,Immunity_Ultimates));
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
    {
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        if(vteam!=ateam)
        {
            new race_victim=War3_GetRace(victim);
            if(race_victim==thisRaceID) 
            {
                new skill_level_fade=War3_GetSkillLevel(victim,thisRaceID,SKILL_FADE);
                if( skill_level_fade>0 &&!Hexed(victim,false) && GetRandomFloat(0.0,1.0)<=FadeChance[skill_level_fade] && !W3HasImmunity(attacker,Immunity_Skills))
                {
                    
                    W3FlashScreen(victim,{244,244,244,50},0.2,0.2,FFADE_OUT);
                    
                    War3_SetBuff(victim,fInvisibilitySkill,thisRaceID,0.1);
                    CreateTimer(1.2,FadeTimer,victim);
                    
                }
            }
        }
    }
}

public Action:FadeTimer(Handle:timer,any:victim)
{

    War3_SetBuff(victim,fInvisibilitySkill,thisRaceID,1.0);
    
}

public OnWar3EventSpawn(client)
{
    StopTribunal(client);
}

public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
    {
        new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_TRIBUNAL);
        if(skilllvl > 0)
        {
            new Float:speed = TribunalSpeed[skilllvl];
            new Float:decay = TribunalDecay[skilllvl];
            if(!Silenced(client))
            {    //W3SetPlayerColor(client,raceid,r,g,b,a=255,overridepriority=GLOW_DEFAULT)
                //W3SetPlayerColor(client,thisRaceID,128,0,128,255); //purple:D not sure if works
                //EmitSoundToAll(tribunal,client);
                if(IsInTribunal[client]){
                    StopTribunal(client);    
                }
                else{
                    IsInTribunal[client]=true;
                    War3_SetBuff(client,fMaxSpeed,thisRaceID,speed);
                    War3_SetBuff(client,fHPDecay,thisRaceID,decay);
                    
            //        CreateTimer(TribunalDuration,TribunalTimer,client);
                    W3Hint(client,HINT_NORMAL,5.0,"%T","You sacrificed for speed.",client);
                }
                //War3_CooldownMGR(client,TribunalCooldownTime,thisRaceID,SKILL_TRIBUNAL,_,_);
            }
        }
    }
}

/*
public Action:TribunalTimer(Handle:timer,any:client)
{
    War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
    War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
    W3ResetPlayerColor(client,thisRaceID);
}*/

public Action:SlowfallTimer(Handle:timer,any:zclient)
{
    for(new client=1; client <= MaxClients; client++)
    {
        if(ValidPlayer(client, true))
        {
            if(War3_GetRace(client) == thisRaceID)
            {
                GetClientAbsOrigin(client,prevdarkvec);
                CreateTimer(0.1,Slowfall2Timer,client);
            }
        }
        
    }
}
public Action:Slowfall2Timer(Handle:timer,any:client)
{
    if(ValidPlayer(client, true)){
        GetClientAbsOrigin(client,darkvec);
        new flags = GetEntityFlags(client);
        if ( !(flags & FL_ONGROUND) )
        {
            
            if (darkvec[2]<prevdarkvec[2])
            {
                new skilllevel_levi=War3_GetSkillLevel(client,thisRaceID,SKILL_SLOWFALL);
                new Float:gravity=SlowfallGravity[skilllevel_levi];
                //DP("set %f",gravity);
                War3_SetBuff(client,fLowGravitySkill,thisRaceID,gravity);
                if(!IsInvis(client)&&War3_GetGame()==Game_TF){
                    AttachThrowAwayParticle(client, GetApparentTeam(client)==TEAM_RED?"teleporter_red_entrance":"teleporter_blue_entrance", darkvec, "", 1.0);
                }
            }
            else
            {
                War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.0);
                //DP("nograv2");
                //previousvec[2]=vec[2];
            }
        }
    }
}


public OnRaceChanged(client,oldrace,newrace)
{
    if(oldrace==thisRaceID)
    {
        War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.0);
        //DP("nograv");
        War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
        W3ResetPlayerColor(client,thisRaceID);
        IsInTribunal[client]=false;
    }
    if(IsInTribunal[client]){
        StopTribunal(client);    
    }
}

StopTribunal(client)
{
    IsInTribunal[client]=false;
    War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
    War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
}



