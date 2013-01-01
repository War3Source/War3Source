#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "War3Source - Warcraft Extended - Vampirism",
	author = "War3Source Team",
	description="Generic vampirism skill"
};

public OnPluginStart()
{
	LoadTranslations("w3s.race.undead.phrases");
}

LeechHP(client, damage, Float:percentage, bool:bBuff)
{
	new leechhealth = RoundToFloor(damage * percentage);
	if(leechhealth > 40) leechhealth = 40;

	W3FlashScreen(client, RGBA_COLOR_GREEN);

	if (bBuff)
	{
		War3_HealToBuffHP(client, leechhealth);
	}
	else
	{
		War3_HealToMaxHP(client, leechhealth);
	}
	PrintToConsole(client, "%T", "Leeched +{amount} HP", client, leechhealth);
}

public OnWar3EventPostHurt(victim, attacker, damage)
{
	if(W3GetDamageIsBullet() && ValidPlayer(victim) && ValidPlayer(attacker, true) && attacker != victim && GetClientTeam(victim) != GetClientTeam(attacker))
	{
		new Float:fVampirePercentage = W3GetBuffSumFloat(attacker, fVampirePercent);
		new Float:fVampirePercentageNoBuff = W3GetBuffSumFloat(attacker, fVampirePercentNoBuff);

		if(!W3HasImmunity(victim, Immunity_Skills) && !Hexed(attacker))
		{
			// This one runs first
			if(fVampirePercentageNoBuff > 0.0)
			{
				LeechHP(attacker, damage, fVampirePercentageNoBuff, false);
			}

			if(fVampirePercentage > 0.0)
			{
				LeechHP(attacker, damage, fVampirePercentage, true);
			}
		}
	}
}

// PostHurt does not have the inflictor
public OnW3TakeDmgBullet(victim, attacker, Float:damage)
{
	if(W3GetDamageIsBullet() && ValidPlayer(victim) && ValidPlayer(attacker, true) && attacker != victim && GetClientTeam(victim) != GetClientTeam(attacker))
	{
		new Float:fVampirePercentage = 0.0;
		new Float:fVampireNoBuffPercentage = 0.0;

		new inflictor = W3GetDamageInflictor();
		if (attacker == inflictor || !IsValidEntity(inflictor))
		{
			new String:weapon[64];
			GetClientWeapon(attacker, weapon, sizeof(weapon));

			if (W3IsDamageFromMelee(weapon))
			{
				fVampirePercentage += W3GetBuffSumFloat(attacker, fMeleeVampirePercent);
				fVampireNoBuffPercentage += W3GetBuffSumFloat(attacker, fMeleeVampirePercentNoBuff);
			}
		}

		if(!W3HasImmunity(victim, Immunity_Skills) && !Hexed(attacker))
		{
			// This one runs first
			if(fVampireNoBuffPercentage > 0.0)
			{
				LeechHP(attacker, RoundToFloor(damage), fVampireNoBuffPercentage, false);
			}

			if(fVampirePercentage > 0.0)
			{
				LeechHP(attacker, RoundToFloor(damage), fVampirePercentage, true);
			}
		}
	}
}