#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - HP Regen",
    author = "War3Source Team",
    description = "Controls Health regeneration aswell as Health decay"
};

new g_iRegenParticleSkip[MAXPLAYERSCUSTOM];
new g_iDecayParticleSkip[MAXPLAYERSCUSTOM];
new Float:g_fLastTick[MAXPLAYERSCUSTOM];

#define KILL_NAME GameTF() ? "bleed_kill" : "damageovertime"

new iAttributeRegen, iAttributeDecay;

public OnPluginStart()
{
    iAttributeRegen = War3_RegisterAttribute("Regen", "Regen", TYPE_FLOAT, 0.0, 0.0, 1000.0);
    iAttributeDecay = War3_RegisterAttribute("Decay", "Decay", TYPE_FLOAT, 0.0, -1000.0, 0.0); 
}

public OnWar3EventSpawn(client)
{
    g_fLastTick[client] = GetEngineTime();
}

public OnGameFrame()
{
    new Float:now = GetEngineTime();

    for(new client=1; client <= MaxClients; client++)
    {
        if(ValidPlayer(client,true))
        {
            new Float:fRegen = War3_GetAttributeValue(client, iAttributeRegen);
            new Float:fDecay = War3_GetAttributeValue(client, iAttributeDecay);

            War3_ChatMessage(client, "Your regen: %f your decay: %f", fRegen, fDecay);
            
            new Float:fBuffSum = fRegen - fDecay;

            if(fBuffSum < 0.01 && fBuffSum > -0.01)
            {
                g_fLastTick[client] = now;
                continue;
            }

            new Float:period = FloatAbs(1.0 / fBuffSum);
            if(now - g_fLastTick[client] > period)
            {
                g_fLastTick[client] += period;

                if(fBuffSum > 0.01)
                {
                    War3_HealToMaxHP(client, 1);

                    if(GAMETF)
                    {
                        g_iRegenParticleSkip[client]++;
                        if(g_iRegenParticleSkip[client] > 4 && !IsInvis(client))
                        {
                            War3_ShowHealthGainedParticle(client);

                            g_iRegenParticleSkip[client] = 0;
                        }
                    }
                }

                if(fBuffSum < -0.01)
                {
                    if(GAMETF)
                    {
                        g_iDecayParticleSkip[client]++;
                        if(g_iDecayParticleSkip[client] > 2 && !IsInvis(client)) 
                        {
                            War3_ShowHealthLostParticle(client);

                            g_iDecayParticleSkip[client] = 0;
                        }
                    }

                    if(GetClientHealth(client) > 1)
                    {
                        SetEntityHealth(client, GetClientHealth(client) - 1);
                    }
                    else
                    {
                        War3_DealDamage(client, 1, _, _, KILL_NAME, _, W3DMGTYPE_TRUEDMG);
                    }
                }
            }
        }
    }
}