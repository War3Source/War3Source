#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Race - Hammerstorm",
    author = "War3Source Team",
    description = "The Hammerstorm race for War3Source."
};

new thisRaceID;
new SKILL_BOLT, SKILL_CLEAVE, SKILL_WARCRY, ULT_STRENGTH;

// Tempents
new g_BeamSprite;
new g_HaloSprite;

// Storm Bolt 
new BoltDamage[5] = {0,5,10,15,20};
new Float:BoltRange[5]={0.0,150.0,175.0,200.0,225.0};
new Float:BoltStunDuration=0.3;
new Float:StormCooldownTime=15.0;


new const StormCol[4] = {255, 255, 255, 155}; // Color of the beacon



// Cleave Multiplayer
new Float:CleaveDistance=150.0;
new Float:CleaveMultiplier[5] = {0.0,0.1,0.2,0.3,0.4};

// Warcry Buffs
new Float:WarcrySpeed[5]={1.0,1.06,1.09,1.12,1.15};
new WarcryArmor[5]={0,1,2,3,4};

// Gods Strength
new Float:GodsStrength[5]={1.0,1.20,1.30,1.40,1.50};
new bool:bStrengthActivated[MAXPLAYERSCUSTOM];
new Handle:ultCooldownCvar; // cooldown

// Sounds
new String:hammerboltsound[256]; //="war3source/hammerstorm/stun.mp3";
new String:ultsnd[256]; //="war3source/hammerstorm/ult.mp3";
//new String:galvanizesnd[]="war3source/hammerstorm/galvanize.mp3";

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==170)
    {
        thisRaceID=War3_CreateNewRaceT("hammerstorm");
        SKILL_BOLT=War3_AddRaceSkillT(thisRaceID,"StormBolt",false,4,"150/175/200/225","5/10/15/20");
        SKILL_CLEAVE=War3_AddRaceSkillT(thisRaceID,"GreatCleave",false,4,"10/20/30/40","150");
        SKILL_WARCRY=War3_AddRaceSkillT(thisRaceID,"Warcry",false,4,"1/2/3/4","6/9/12/15");
        ULT_STRENGTH=War3_AddRaceSkillT(thisRaceID,"GodsStrength",true,4,"20/30/40/50"); 
        War3_CreateRaceEnd(thisRaceID); 

        War3_AddSkillBuff(thisRaceID, SKILL_WARCRY, fMaxSpeed, WarcrySpeed);
        War3_AddSkillBuff(thisRaceID, SKILL_WARCRY, fArmorPhysical, WarcryArmor);
    }
}

public OnPluginStart()
{
    ultCooldownCvar=CreateConVar("war3_hammerstorm_strength_cooldown","25","Cooldown timer.");
    LoadTranslations("w3s.race.hammerstorm.phrases");
}

public OnMapStart()
{
    War3_AddSoundFolder(hammerboltsound, sizeof(hammerboltsound), "hammerstorm/stun.mp3");
    War3_AddSoundFolder(ultsnd, sizeof(ultsnd), "hammerstorm/ult.mp3");

    // Precache the stuff for the beacon ring
    g_BeamSprite = War3_PrecacheBeamSprite();
    g_HaloSprite = War3_PrecacheHaloSprite(); 
    //Sounds
    War3_AddCustomSound(hammerboltsound);
    War3_AddCustomSound(ultsnd);
}

public OnWar3EventSpawn(client)
{
    bStrengthActivated[client] = false;
    W3ResetPlayerColor(client, thisRaceID);
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage){
    if(ValidPlayer(victim,true)&&ValidPlayer(attacker,false)&&GetClientTeam(victim)!=GetClientTeam(attacker))
    {
        if(War3_GetRace(attacker)==thisRaceID)
        {
            new skilllvl;
            if(bStrengthActivated[attacker])
            {
                // GODS STRENGTH!
                skilllvl = War3_GetSkillLevel(attacker,thisRaceID,ULT_STRENGTH);
                War3_DamageModPercent(GodsStrength[skilllvl]);
                
            }
        }
    }
}
            
public OnW3TakeDmgBullet(victim,attacker,Float:damage){
    if(ValidPlayer(victim,true)&&ValidPlayer(attacker,false)&&GetClientTeam(victim)!=GetClientTeam(attacker))
    {
        if(War3_GetRace(attacker)==thisRaceID)
        {
            // Cleave
            new skilllvl = War3_GetSkillLevel(attacker,thisRaceID,SKILL_CLEAVE);
            new splashdmg = RoundToFloor(damage * CleaveMultiplier[skilllvl]);
            // AWP? AWP!
            if(splashdmg>40)
            {
                splashdmg = 40;
            }
            new Float:dist = CleaveDistance;
            new AttackerTeam = GetClientTeam(attacker);
            new Float:OriginalVictimPos[3];
            GetClientAbsOrigin(victim,OriginalVictimPos);
            new Float:VictimPos[3];
            
            if(attacker>0)
            {
                for(new i=1;i<=MaxClients;i++)
                {
                    if(ValidPlayer(i,true)&&(GetClientTeam(i)!=AttackerTeam)&&(victim!=i))
                    {
                        GetClientAbsOrigin(i,VictimPos);
                        if(GetVectorDistance(OriginalVictimPos,VictimPos)<=dist)
                        {
                            War3_DealDamage(i,splashdmg,attacker,_,"greatcleave");
                            W3PrintSkillDmgConsole(i,attacker,War3_GetWar3DamageDealt(),SKILL_CLEAVE);
                        }
                    }
                }
            }
        }
    }
}

public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
    {
        new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_BOLT);
        if(skilllvl > 0)
        {
            
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_BOLT,true))
            {
                new damage = BoltDamage[skilllvl];
                new Float:AttackerPos[3];
                GetClientAbsOrigin(client,AttackerPos);
                new AttackerTeam = GetClientTeam(client);
                new Float:VictimPos[3];
                
                TE_SetupBeamRingPoint(AttackerPos, 10.0, BoltRange[skilllvl]*2.0, g_BeamSprite, g_HaloSprite, 0, 25, 0.5, 5.0, 0.0, StormCol, 10, 0);
                TE_SendToAll();
                AttackerPos[2]+=10.0;
                TE_SetupBeamRingPoint(AttackerPos, 10.0, BoltRange[skilllvl]*2.0, g_BeamSprite, g_HaloSprite, 0, 25, 0.5, 5.0, 0.0, StormCol, 10, 0);
                TE_SendToAll();
                
                W3EmitSoundToAll(hammerboltsound,client);
                W3EmitSoundToAll(hammerboltsound,client);
                
                for(new i=1;i<=MaxClients;i++)
                {
                    if(ValidPlayer(i,true)){
                        GetClientAbsOrigin(i,VictimPos);
                        if(GetVectorDistance(AttackerPos,VictimPos)<BoltRange[skilllvl])
                        {
                            if(GetClientTeam(i)!=AttackerTeam&&!W3HasImmunity(client,Immunity_Skills))
                            {
                                War3_DealDamage(i,damage,client,DMG_BURN,"stormbolt",W3DMGORIGIN_SKILL);
                                W3PrintSkillDmgConsole(i,client,War3_GetWar3DamageDealt(),SKILL_BOLT);
                                
                                W3SetPlayerColor(i,thisRaceID, StormCol[0], StormCol[1], StormCol[2], StormCol[3]); 
                                War3_SetBuff(i,bStunned,thisRaceID,true);

                                W3FlashScreen(i,RGBA_COLOR_RED);
                                CreateTimer(BoltStunDuration,UnstunPlayer,i);
                                
                                PrintHintText(i,"%T","You were stunned by Storm Bolt",i);
                                
                            }
                        }
                    }
                }
                //EmitSoundToAll(hammerboltsound,client);
                War3_CooldownMGR(client,StormCooldownTime,thisRaceID,SKILL_BOLT);
            }
        }
    }
}

public Action:UnstunPlayer(Handle:timer,any:client)
{
    War3_SetBuff(client,bStunned,thisRaceID,false);
    W3ResetPlayerColor(client, thisRaceID);
}

public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && ValidPlayer(client,true))
    {
        new skilllvl = War3_GetSkillLevel(client,thisRaceID,ULT_STRENGTH);
        if(skilllvl>0)
        {    
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_STRENGTH,true ))
            {
                W3EmitSoundToAll(ultsnd,client);
                W3EmitSoundToAll(ultsnd,client);
                PrintHintText(client,"%T","The gods lend you their strength",client);
                bStrengthActivated[client] = true;
                CreateTimer(5.0,stopUltimate,client);
                
                //EmitSoundToAll(ultsnd,client);  
                War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_STRENGTH);
            }
        }
    }
}


public Action:stopUltimate(Handle:t,any:client){
    bStrengthActivated[client] = false;
    if(ValidPlayer(client,true)){
        PrintHintText(client,"%T","You feel less powerful",client);
    }
}