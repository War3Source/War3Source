#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo=
{
	name="W3S Engine HP Regen",
	author="Ownz (DarkEnergy) - Fixed up by Glider",
	description="War3Source Core Plugins",
	version="1.1",
	url="http://war3source.com/"
};

new g_iRegenParticleSkip[MAXPLAYERSCUSTOM];
new g_iDecayParticleSkip[MAXPLAYERSCUSTOM];
new Float:g_fLastTick[MAXPLAYERSCUSTOM];

#define HEALTH_GAINED_PARTICLE GetApparentTeam(client) == TEAM_RED ? "healthgained_red" : "healthgained_blu"
#define HEALTH_LOST_PARTICLE GetApparentTeam(client) == TEAM_RED ? "healthlost_red" : "healthlost_blu"
#define KILL_NAME GameTF() ? "bleed_kill" : "damageovertime"

public OnWar3EventSpawn(client)
{
	g_fLastTick[client] = GetEngineTime();
}

public OnGameFrame()
{
	decl Float:playervec[3];
	new Float:now = GetEngineTime();

	for(new client=1; client <= MaxClients; client++)
	{
		if(ValidPlayer(client,true))
		{
			new Float:fbuffsum = 0.0;
			if(!W3GetBuffHasTrue(client, bBuffDenyAll))
			{
				fbuffsum += W3GetBuffSumFloat(client, fHPRegen);
			}

			fbuffsum -= W3GetBuffSumFloat(client, fHPDecay);

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

					if(War3_GetGame() == TF)
					{
						g_iRegenParticleSkip[client]++;
						if(g_iRegenParticleSkip[client] > 4 && !IsInvis(client))
						{
							GetClientAbsOrigin(client, playervec);

							playervec[2] += 55.0;
							War3_TF_ParticleToClient(0, HEALTH_GAINED_PARTICLE, playervec);

							g_iRegenParticleSkip[client] = 0;
						}
					}
				}

				if(fbuffsum < -0.01)
				{
					if(War3_GetGame() == Game_TF)
					{
						g_iDecayParticleSkip[client]++;
						if(g_iDecayParticleSkip[client] > 2 && !IsInvis(client)) 
						{
							GetClientAbsOrigin(client, playervec);

							playervec[2] += 55.0;

							War3_TF_ParticleToClient(0, HEALTH_LOST_PARTICLE, playervec);

							g_iDecayParticleSkip[client] = 0;
						}
					}

					if(GetClientHealth(client) > 1)
					{
						SetEntityHealth(client,GetClientHealth(client) - 1);

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