#pragma semicolon 1

#undef REQUIRE_EXTENSIONS 
#include <tf2>
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS

#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Buff Max HP",
    author = "War3Source Team",
    description = "Controls a players Max HP via Buffs"
};

new Float:fLastDamageTime[MAXPLAYERSCUSTOM];
new iClientSpawnHP[MAXPLAYERSCUSTOM];
new Handle:hCheckBuffTimer[MAXPLAYERSCUSTOM];

#define TF_BUFF_INTERVAL 0.1
new Float:fNextTFHPBuffTick[MAXPLAYERSCUSTOM];

public OnWar3EventSpawn(client)
{
    if (ValidPlayer(client))
    {
        fNextTFHPBuffTick[client] = GetEngineTime();
        iClientSpawnHP[client] = GetClientHealth(client);
        
        new iAdditionalHP = W3GetBuffSumInt(client, iAdditionalMaxHealth);
        new curhp = GetClientHealth(client);
        SetEntityHealth(client, curhp + iAdditionalHP);
        
        iAdditionalHP += W3GetBuffSumInt(client, iAdditionalMaxHealthNoHPChange);
        War3_SetMaxHP_INTERNAL(client, iClientSpawnHP[client] + iAdditionalHP);
        fLastDamageTime[client] = 0.0;
    }
}

public OnWar3EventDeath(victim, attacker)
{
    if(GAMETF && ValidPlayer(attacker))
    {
        // This isn't written for randomizer or TF2Items shenanigans in general, sorry :-)
        if (TF2_GetPlayerClass(attacker) == TFClass_DemoMan)
        {
            // We hook player_death in PreMode and I'm too lazy to add a new forward for post right now :|
            // Note the ATTACKER is being checked
            CreateTimer(0.1, checkHeadsTimer, EntIndexToEntRef(attacker));
        }
    }
    
}

public Action:checkHeadsTimer(Handle:h, any:attackerRef)
{
    new attacker = EntRefToEntIndex(attackerRef);
    if(!ValidPlayer(attacker, true))
    {
        return;
    }
    
    // Increase the internally stored max health 
    // There is a limit to how many heads that can be counted toward health
    new heads = GetEntProp(attacker, Prop_Send, "m_iDecapitations");
    if (heads > 0 && heads <= 4)
    {
        War3_SetMaxHP_INTERNAL(attacker, War3_GetMaxHP(attacker) + 15);
    }
}

public OnWar3Event(W3EVENT:event,client)
{
    if(event == OnBuffChanged)
    {
        if(W3GetVar(EventArg1) == iAdditionalMaxHealth && ValidPlayer(client, true))
        {
            // Only queue this once
            if(hCheckBuffTimer[client] == INVALID_HANDLE)
            {    
                hCheckBuffTimer[client] = CreateTimer(0.1, CheckHPBuffChange, client);
            }
        }
    }
}

public Action:CheckHPBuffChange(Handle:h,any:client)
{
    hCheckBuffTimer[client] = INVALID_HANDLE;
    
    if(ValidPlayer(client, true))
    {
        new iAdditionalHP = W3GetBuffSumInt(client, iAdditionalMaxHealth);
        new iAdditionalHPNoBuff = W3GetBuffSumInt(client, iAdditionalMaxHealthNoHPChange);
        new iOldBuff = War3_GetMaxHP(client) - iClientSpawnHP[client] - iAdditionalHPNoBuff;
        War3_SetMaxHP_INTERNAL(client, iClientSpawnHP[client] + iAdditionalHP + iAdditionalHPNoBuff); //set max hp
        
        new newhp = GetClientHealth(client) + iAdditionalHP - iOldBuff; //difference
        if(newhp < 1)
        {
            newhp = 1;
        }

        SetEntityHealth(client, newhp);
    }
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if (ValidPlayer(victim)) 
    {
        fLastDamageTime[victim] = GetEngineTime();
    }
}

// FOR GALLIFREY, err, OnGameFrame, I mean...

public OnGameFrame()
{
    new Float:now = GetEngineTime();
    
    for(new i = 0; i < MaxClients; i++)
    {
        if(!ValidPlayer(i, true))
        {
            continue;
        }
        
        if(GAMETF)
        {
            if((now >= fLastDamageTime[i] + 10.0) && (now >= fNextTFHPBuffTick[i]))
            {
                new curhp = GetClientHealth(i);
                new hpadd = W3GetBuffSumInt(i, iAdditionalMaxHealth);
                new maxhp = War3_GetMaxHP(i) - hpadd; //nomal player hp
                
                if(curhp >= maxhp && curhp < maxhp + hpadd)
                { 
                    new newhp = curhp + 2;
                    if(newhp > maxhp + hpadd)
                    {
                        newhp = maxhp + hpadd;
                    }
                    SetEntityHealth(i, newhp);
                }
                
                fNextTFHPBuffTick[i] += TF_BUFF_INTERVAL;
            }
        }
    }
}