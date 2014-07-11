#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
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

public Plugin:myinfo =
{
    name = "War3Source - Race - Night Elf",
    author = "War3Source Team",
    description = "The Night Elf race for War3Source."
};

new ClientTracer;
new BeamSprite, HaloSprite;
new bool:bIsEntangled[MAXPLAYERSCUSTOM];
new String:entangleSound[256];
new Handle:EntangleCooldownCvar;

new SKILL_EVADE, SKILL_THORNS, SKILL_TRUESHOT, ULT_ENTANGLE;

// Chance/Data Arrays
new Float:fEvadeChance[5] = {0.0, 0.05, 0.07, 0.13, 0.15};
new Float:ThornsReturnDamage[5] = {0.0, 0.05, 0.09, 0.13, 0.17};
new Float:TrueshotDamagePercent[5] = {1.0, 1.05, 1.09, 1.13, 1.17};
new Float:EntangleDistance = 600.0;
new Float:EntangleDuration[5] = {0.0, 1.25, 1.5, 1.75, 2.0};

public OnPluginStart()
{
    EntangleCooldownCvar=CreateConVar("war3_nightelf_entangle_cooldown", "20", "Cooldown timer.");

    LoadTranslations("w3s.race.nightelf.phrases.txt");
}

public OnMapStart()
{
    War3_AddSoundFolder(entangleSound, sizeof(entangleSound), "entanglingrootsdecay1.mp3");

    BeamSprite = War3_PrecacheBeamSprite();
    HaloSprite = War3_PrecacheHaloSprite();

    War3_AddCustomSound(entangleSound);
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num == 40)
    {
        thisRaceID = War3_CreateNewRaceT("nightelf");
        SKILL_EVADE = War3_AddRaceSkillT(thisRaceID, "Evasion", false, 4);
        SKILL_THORNS = War3_AddRaceSkillT(thisRaceID, "ThornsAura", false, 4);
        SKILL_TRUESHOT = War3_AddRaceSkillT(thisRaceID, "TrueshotAura", false, 4);
        ULT_ENTANGLE = War3_AddRaceSkillT(thisRaceID, "EntanglingRoots", true, 4);
        
        War3_CreateRaceEnd(thisRaceID);
        
        War3_AddSkillBuff(thisRaceID, SKILL_EVADE, fDodgeChance, fEvadeChance);
    }
}

public bool:AimTargetFilter(entity,mask)
{
    return !(entity==ClientTracer);
}

public bool:ImmunityCheck(client)
{
    if(RaceDisabled)
    {
        return false;
    }

    if(bIsEntangled[client] || W3HasImmunity(client, Immunity_Ultimates))
    {
        return false;
    }
    
    return true;
}

public OnUltimateCommand(client,race,bool:pressed)
{
    if(RaceDisabled)
    {
        return;
    }

    if(race == thisRaceID && ValidPlayer(client, true) && pressed)
    {
        new iEntangleLevel = War3_GetSkillLevel(client, race, ULT_ENTANGLE);
        if(iEntangleLevel > 0)
        {
            if(!Silenced(client) && War3_SkillNotInCooldown(client, thisRaceID, ULT_ENTANGLE, true))
            {
                new Float:distance = EntangleDistance;
                new target; // easy support for both

                new Float:fClientPos[3];
                GetClientAbsOrigin(client,fClientPos);

                target = War3_GetTargetInViewCone(client, distance, false, 23.0, ImmunityCheck);
                if(ValidPlayer(target, true))
                {
                    bIsEntangled[target] = true;

                    War3_SetBuff(target, bNoMoveMode, thisRaceID, true);
                    new Float:fEntangleTime = EntangleDuration[iEntangleLevel];
                    CreateTimer(fEntangleTime, StopEntangle, target);
                    new Float:fEffectPos[3];
                    GetClientAbsOrigin(target, fEffectPos);
                    
                    for (new i=0; i <= 3; i++)
                    {
                        fEffectPos[2] += 15.0;
                        TE_SetupBeamRingPoint(fEffectPos, 45.0, 44.0, BeamSprite,
                                              HaloSprite, 0, 15, fEntangleTime,
                                              5.0, 0.0, {0, 255, 0, 255}, 10, 0);
                        TE_SendToAll();
                    }

                    fClientPos[2] += 25.0;
                    TE_SetupBeamPoints(fClientPos, fEffectPos, BeamSprite,
                                       HaloSprite, 0, 50, 4.0, 6.0, 25.0, 0, 
                                       12.0, {80, 255, 90, 255}, 40);
                    TE_SendToAll();
                    
                    W3EmitSoundToAll(entangleSound, target);
                    W3EmitSoundToAll(entangleSound, target);

                    W3MsgEntangle(target, client);

                    War3_CooldownMGR(client, GetConVarFloat(EntangleCooldownCvar), thisRaceID, ULT_ENTANGLE, _, _);
                }
                else
                {
                    W3MsgNoTargetFound(client, distance);
                }
            }
        }
        else
        {
            W3MsgUltNotLeveled(client);
        }
    }
}

Untangle(client)
{
    bIsEntangled[client] = false;
    War3_SetBuff(client, bNoMoveMode, thisRaceID, false);
}

public Action:StopEntangle(Handle:timer, any:client)
{
    Untangle(client);
}

public OnWar3EventSpawn(client)
{
    if(RaceDisabled)
    {
        return;
    }

    if(bIsEntangled[client])
    {
        Untangle(client);
    }
}

public OnW3TakeDmgBulletPre(victim, attacker, Float:damage)
{
    if(RaceDisabled)
    {
        return;
    }

    if(attacker != victim)
    {
        // Trueshot
        if(ValidPlayer(attacker) && War3_GetRace(attacker) == thisRaceID)
        {
            // Don't increase friendly fire damage
            if(ValidPlayer(victim) && GetClientTeam(victim) == GetClientTeam(attacker))
            {
                return;
            }
            
            new iTrueshotLevel = War3_GetSkillLevel(attacker, thisRaceID, SKILL_TRUESHOT);
            if(iTrueshotLevel > 0 && !Hexed(attacker, false) && !W3HasImmunity(victim, Immunity_Skills))
            {
                War3_DamageModPercent(TrueshotDamagePercent[iTrueshotLevel]);
                W3FlashScreen(victim, RGBA_COLOR_RED);
            }
        }
    }
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(RaceDisabled)
    {
        return;
    }

    if(!isWarcraft && ValidPlayer(victim) && victim != attacker && War3_GetRace(victim) == thisRaceID)
    {
        new iThornsLevel = War3_GetSkillLevel(victim, thisRaceID, SKILL_THORNS );
        if(iThornsLevel > 0 && !Hexed(victim, false))
        {
            // Don't return friendly fire damage
            if(ValidPlayer(attacker) && GetClientTeam(victim) == GetClientTeam(attacker))
            {
                return;
            }
            
            if(!W3HasImmunity(attacker, Immunity_Skills))
            {
                new iDamage = RoundToFloor(damage * ThornsReturnDamage[iThornsLevel]);
                if(iDamage > 0)
                {
                    if(iDamage > 40)
                    {
                        iDamage = 40;
                    }

                    if (GAMECSANY)
                    {
                        // Since this is delayed we don't know if the damage actually went through
                        // and just have to assume... Stupid!
                        War3_DealDamageDelayed(attacker, victim, iDamage, "thorns", 0.1, true, SKILL_THORNS);
                        War3_EffectReturnDamage(victim, attacker, iDamage, SKILL_THORNS);
                    }
                    else
                    {
                        if(War3_DealDamage(attacker, iDamage, victim, _, "thorns", _, W3DMGTYPE_PHYSICAL))
                        {
                            War3_EffectReturnDamage(victim, attacker, War3_GetWar3DamageDealt(), SKILL_THORNS);
                        }
                    }
                }
            }
        }
    }

}