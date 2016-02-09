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
            new Float:fbuffsum = 0.0;
            if(!W3GetBuffHasTrue(client, bBuffDenyAll) && !W3GetBuffHasTrue(client, bHPRegenDeny))
            {
                fbuffsum += W3GetBuffSumFloat(client, fHPRegen);
            }

            if(!W3GetBuffHasTrue(client, bHPDecayDeny))
            {
                fbuffsum -= W3GetBuffSumFloat(client, fHPDecay);
            }

            if(fbuffsum < 0.01 && fbuffsum > -0.01)
            {
                g_fLastTick[client] = now;
                continue;
            }

            new Float:period = FloatAbs(1.0 / fbuffsum);
            if(now - g_fLastTick[client] > period)
            {
                g_fLastTick[client] += period;

                if(fbuffsum > 0.01)
                {
                    War3_HealToMaxHP(client, 1);

                    if(GameTF())
                    {
                        g_iRegenParticleSkip[client]++;
                        if(g_iRegenParticleSkip[client] > 4 && !IsInvis(client))
                        {
                            War3_ShowHealthGainedParticle(client);

                            g_iRegenParticleSkip[client] = 0;
                        }
                    }
                }

                if(fbuffsum < -0.01)
                {
                    if(GameTF())
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