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

new Handle:mytimer[MAXPLAYERSCUSTOM]; //INVLAID_HHANDLE is default 0
new Float:LastDamageTime[MAXPLAYERSCUSTOM];
new ORIGINALHP[MAXPLAYERSCUSTOM];
new bool:bHealthAddedThisSpawn[MAXPLAYERSCUSTOM];
new Handle:mytimer2[MAXPLAYERSCUSTOM];

public OnPluginStart()
{
    if(GAMETF)
    {
        CreateTimer(0.1, TFHPBuff, _, TIMER_REPEAT);
    }
}

public OnWar3EventSpawn(client)
{
    if (ValidPlayer(client))
    {
        ORIGINALHP[client]=GetClientHealth(client);
        
        if(mytimer[client]!=INVALID_HANDLE)
        {
            CloseHandle(mytimer[client]);
        }
    
        mytimer[client] = CreateTimer(0.01, CheckHP, EntIndexToEntRef(client));
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
    
    bHealthAddedThisSpawn[victim] = false;
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

public Action:CheckHP(Handle:h, any:clientRef)
{
    new client = EntRefToEntIndex(clientRef);
    mytimer[client]=INVALID_HANDLE;
    if(ValidPlayer(client,true) && !bHealthAddedThisSpawn[client])
    {
        new buff1=W3GetBuffSumInt(client, iAdditionalMaxHealth);
        new curhp = GetClientHealth(client);
        SetEntityHealth(client, curhp + buff1);
        new buff2 = W3GetBuffSumInt(client, iAdditionalMaxHealthNoHPChange);
        War3_SetMaxHP_INTERNAL(client,ORIGINALHP[client] + buff1 + buff2); //set max hp
        LastDamageTime[client]=GetEngineTime()-100.0;
    }
}

public OnWar3Event(W3EVENT:event,client)
{
    if(event==OnBuffChanged)
    {
        if(W3GetVar(EventArg1)==iAdditionalMaxHealth &&ValidPlayer(client,true)){
            if(mytimer2[client]==INVALID_HANDLE){    
                mytimer2[client]=CreateTimer(0.1,CheckHPBuffChange,client);
            }
        }
    }
}

public Action:CheckHPBuffChange(Handle:h,any:client){
    mytimer2[client]=INVALID_HANDLE;
    
    if(ValidPlayer(client,true))
    {
        new newbuff=W3GetBuffSumInt(client,iAdditionalMaxHealth);
        new newbuff2=W3GetBuffSumInt(client,iAdditionalMaxHealthNoHPChange);
        new oldbuff=War3_GetMaxHP(client)-ORIGINALHP[client]-newbuff2;
        War3_SetMaxHP_INTERNAL(client,ORIGINALHP[client]+newbuff+newbuff2); //set max hp
        
        new newhp=GetClientHealth(client)+newbuff-oldbuff; //difference
        if(newhp < 1)
        {
            newhp=1;
        }
        //add or decrease health
        SetEntityHealth(client,newhp);
    }
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if (ValidPlayer(victim)) 
    {
        LastDamageTime[victim]=GetEngineTime();
    }
}

public Action:TFHPBuff(Handle:h,any:data)
{
    new Float:now=GetEngineTime();
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i,true))
        {
            if(now>LastDamageTime[i]+10.0)
            {
                // Devotion Aura
                new curhp =GetClientHealth(i);
                new hpadd= W3GetBuffSumInt(i,iAdditionalMaxHealth);
                new maxhp = War3_GetMaxHP(i)-hpadd; //nomal player hp
                
                if(curhp>=maxhp&&curhp<maxhp+hpadd)
                { 
                    new newhp=curhp+2;
                    if(newhp>maxhp+hpadd)
                    {
                        newhp=maxhp+hpadd;
                    }
                    SetEntityHealth(i, newhp);
                }
            }
        }
    }
}
