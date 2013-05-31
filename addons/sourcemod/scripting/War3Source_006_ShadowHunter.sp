
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

public Plugin:myinfo = 
{
    name = "War3Source - Race - Shadow Hunter",
    author = "War3Source Team",
    description = "The Shadow Hunter race for War3Source."
};

new thisRaceID;

new SKILL_HEALINGWAVE, SKILL_HEX, SKILL_WARD, ULT_VOODOO;

//skill 1
new Float:HealingWaveAmountArr[]={0.0,1.0,2.0,3.0,4.0};
new Float:HealingWaveDistance=500.0;
new ParticleEffect[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; // ParticleEffect[Source][Destination]

//skill 2
new Float:HexChanceArr[]={0.00,0.025,0.05,0.075,0.100};

//skill 3
new MaximumWards[]={0,1,2,3,4}; 
new WardDamage[]={0,1,2,3,4};

new Float:LastThunderClap[MAXPLAYERSCUSTOM];

//ultimate
new Handle:ultCooldownCvar;

new Float:UltimateDuration[]={0.0,0.66,1.0,1.33,1.66}; ///big bad voodoo duration



new bool:bVoodoo[65];

//new String:ultimateSound[]="war3source/divineshield.wav";
//new String:wardDamageSound[]="war3source/thunder_clap.wav";

new String:ultimateSound[256]; //="war3source/divineshield.mp3";
new String:wardDamageSound[256]; //="war3source/thunder_clap.mp3";


new bool:particled[MAXPLAYERSCUSTOM]; //heal particle


new AuraID;

public OnPluginStart()
{

    ultCooldownCvar=CreateConVar("war3_hunter_voodoo_cooldown","20","Cooldown between Big Bad Voodoo (ultimate)");
    CreateTimer(1.0,CalcHexHealWaves,_,TIMER_REPEAT);
    
    LoadTranslations("w3s.race.hunter.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==60)
    {
        
        
        thisRaceID=War3_CreateNewRaceT("hunter");
        SKILL_HEALINGWAVE=War3_AddRaceSkillT(thisRaceID,"HealingWave",false,4);
        SKILL_HEX=War3_AddRaceSkillT(thisRaceID,"Hex",false,4);
        SKILL_WARD=War3_AddRaceSkillT(thisRaceID,"SerpentWards",false,4);
        ULT_VOODOO=War3_AddRaceSkillT(thisRaceID,"BigBadVoodoo",true,4); 
        War3_CreateRaceEnd(thisRaceID);
        AuraID=W3RegisterAura("hunter_healwave",HealingWaveDistance);
        
    }

}

public OnMapStart()
{
    War3_AddSoundFolder(wardDamageSound, sizeof(wardDamageSound), "thunder_clap.mp3");
    War3_AddSoundFolder(ultimateSound, sizeof(ultimateSound), "divineshield.mp3");

    War3_AddCustomSound(ultimateSound);
    War3_AddCustomSound(wardDamageSound);
}

public OnWar3PlayerAuthed(client)
{
    bVoodoo[client]=false;
    LastThunderClap[client]=0.0;
}

public OnRaceChanged(client,oldrace,newrace)
{
    if(newrace==thisRaceID)
    {
        new level=War3_GetSkillLevel(client,thisRaceID,SKILL_HEALINGWAVE);
        W3SetAuraFromPlayer(AuraID,client,level>0?true:false,level);
        
    }
    else{
        //PrintToServer("deactivate aura");
        War3_SetBuff(client,bImmunitySkills,thisRaceID,false);
        W3SetAuraFromPlayer(AuraID,client,false);
    }
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    
    if(race==thisRaceID && War3_GetRace(client)==thisRaceID)
    {
        if(skill==SKILL_HEALINGWAVE) //1
        {
            W3SetAuraFromPlayer(AuraID,client,newskilllevel>0?true:false,newskilllevel);
        }
    }
}

public OnUltimateCommand(client,race,bool:pressed)
{
    new userid=GetClientUserId(client);
    if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) )
    {
        new ult_level=War3_GetSkillLevel(client,race,ULT_VOODOO);
        if(ult_level>0)
        {
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_VOODOO,true))
            {
                bVoodoo[client]=true;
                
                W3SetPlayerColor(client,thisRaceID,255,200,0,_,GLOW_ULTIMATE); //255,200,0);
                CreateTimer(UltimateDuration[ult_level],EndVoodoo,client);
                new Float:cooldown=    GetConVarFloat(ultCooldownCvar);
                War3_CooldownMGR(client,cooldown,thisRaceID,ULT_VOODOO,_,_);
                W3MsgUsingVoodoo(client);
                W3EmitSoundToAll(ultimateSound,client);
                W3EmitSoundToAll(ultimateSound,client);
            }

        }
        else
        {
            W3MsgUltNotLeveled(client);
        }
    }
}

public Action:EndVoodoo(Handle:timer,any:client)
{
    bVoodoo[client]=false;
    W3ResetPlayerColor(client,thisRaceID);
    if(ValidPlayer(client,true))
    {
        W3MsgVoodooEnded(client);
    }
}

public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
    {
        new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_WARD);
        if(skill_level>0)
        {
            if(!Silenced(client)&&War3_GetWardCount(client)<MaximumWards[skill_level])
            {
                new iTeam=GetClientTeam(client);
                new bool:conf_found=false;
                if(War3_GetGame()==Game_TF)
                {
                    new Handle:hCheckEntities=War3_NearBuilding(client);
                    new size_arr=0;
                    if(hCheckEntities!=INVALID_HANDLE)
                        size_arr=GetArraySize(hCheckEntities);
                    for(new x=0;x<size_arr;x++)
                    {
                        new ent=GetArrayCell(hCheckEntities,x);
                        if(!IsValidEdict(ent)) continue;
                        new builder=GetEntPropEnt(ent,Prop_Send,"m_hBuilder");
                        if(builder>0 && ValidPlayer(builder) && GetClientTeam(builder)!=iTeam)
                        {
                            conf_found=true;
                            break;
                        }
                    }
                    if(size_arr>0)
                        CloseHandle(hCheckEntities);
                }
                if(conf_found)
                {
                    W3MsgWardLocationDeny(client);
                }
                else
                {
                    if(War3_IsCloaked(client))
                    {
                        W3MsgNoWardWhenInvis(client);
                        return;
                    }
                    new Float:location[3];
                    GetClientAbsOrigin(client, location);
                    War3_CreateWardMod(client, location, 60, 300.0, 0.5, "damage", SKILL_WARD, WardDamage);
                    
                    W3MsgCreatedWard(client,War3_GetWardCount(client),MaximumWards[skill_level]);
                }
            }
            else
            {
                W3MsgNoWardsLeft(client);
            }    
        }
    }
}




public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0) //block self inflicted damage
    {
        if(bVoodoo[victim]&&attacker==victim){
            War3_DamageModPercent(0.0);
            return;
        }
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        
        
        if(vteam!=ateam)
        {
            if(bVoodoo[victim])
            {
                if(!W3HasImmunity(attacker,Immunity_Ultimates))
                {
                    if(War3_GetGame()==Game_TF){
                        decl Float:pos[3];
                        GetClientEyePosition(victim, pos);
                        pos[2] += 4.0;
                        War3_TF_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos
                    }
                    War3_DamageModPercent(0.0);
                }
                else
                {
                    W3MsgEnemyHasImmunity(victim,true);
                }
            }
        }
    }
    return;
}

// Events
public OnWar3EventSpawn(client){
    bVoodoo[client]=false;
    StopParticleEffect(client, true);
}

public OnClientDisconnect(client)
{
    StopParticleEffect(client, true);
}

public OnWar3EventDeath(victim, attacker)
{
    StopParticleEffect(victim, false);
}

public Action:CalcHexHealWaves(Handle:timer,any:userid)
{
    if(thisRaceID>0)
    {
        for(new i=1;i<=MaxClients;i++)
        {
            particled[i]=false;
            if(ValidPlayer(i,true))
            {
                if(War3_GetRace(i)==thisRaceID)
                {
                    new bool:value=(GetRandomFloat(0.0,1.0)<=HexChanceArr[War3_GetSkillLevel(i,thisRaceID,SKILL_HEX)]&&!Hexed(i,false));
                    War3_SetBuff(i,bImmunitySkills,thisRaceID,value);
                }
            }
        }
    }
}
public OnW3PlayerAuraStateChanged(client,aura,bool:inAura,level)
{
    if(aura==AuraID)
    {
        War3_SetBuff(client,fHPRegen,thisRaceID,inAura?HealingWaveAmountArr[level]:0.0);
    }
}

//=======================================================================
//                  HEALING WAVE PARTICLE EFFECT (TF2 ONLY!)
//=======================================================================

StopParticleEffect(client, bKill)
{
    if(War3_GetGame() == Game_TF)
    {
        for(new i=1; i <= MaxClients; i++)
        {
            decl String:className[64];
            decl String:className2[64];
                
            if(IsValidEdict(ParticleEffect[client][i]))
                GetEdictClassname(ParticleEffect[client][i], className, sizeof(className));
            if(IsValidEdict(ParticleEffect[i][client]))
            GetEdictClassname(ParticleEffect[i][client], className2, sizeof(className2));
            
            if(StrEqual(className, "info_particle_system"))
            {
                AcceptEntityInput(ParticleEffect[client][i], "stop");
                if(bKill)
                {
                    AcceptEntityInput(ParticleEffect[client][i], "kill");
                    ParticleEffect[client][i] = 0;
                }
            }
            
            if(StrEqual(className2, "info_particle_system"))
            {
                AcceptEntityInput(ParticleEffect[i][client], "stop");
                if(bKill)
                {
                    AcceptEntityInput(ParticleEffect[i][client], "kill");
                    ParticleEffect[i][client] = 0;
                }
            }
        }
    }
}
