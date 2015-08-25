#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Notifications",
    author = "War3Source Team",
    description = "Centralize some notifications"
};

new iMaskSoundDelay[MAXPLAYERSCUSTOM];
new String:sMaskSound[256];


new BeamSprite = -1;
new HaloSprite = -1;

public bool:InitNativesForwards()
{
    CreateNative("War3_EvadeDamage", Native_EvadeDamage);
    CreateNative("War3_EffectReturnDamage", Native_EffectReturnDamage);
    CreateNative("War3_VampirismEffect", Native_VampirismEffect);
    CreateNative("War3_BashEffect", Native_BashEffect);
    CreateNative("War3_WardVisualEffect", Native_WardVisualEffect);

    return true;
}

public OnPluginStart()
{
    // Yes, this should be a "skilleffects" translation file later ;)
    LoadTranslations("w3s.race.undead.phrases.txt");
    LoadTranslations("w3s.race.human.phrases.txt");
    
    for(new i=1; i <= MaxClients; i++)
    {
        iMaskSoundDelay[i] = War3_RegisterDelayTracker();
    }
}

public OnMapStart()
{
    War3_AddSoundFolder(sMaskSound, sizeof(sMaskSound), "mask.mp3");
    War3_AddCustomSound(sMaskSound);
    
    BeamSprite = War3_PrecacheBeamSprite();
    HaloSprite = War3_PrecacheHaloSprite();
}

public Native_EvadeDamage(Handle:plugin, numParams)
{
    new victim = GetNativeCell(1);
    new attacker = GetNativeCell(2);

    War3_DamageModPercent(0.0);

    if (ValidPlayer(victim))
    {
        W3FlashScreen(victim, RGBA_COLOR_BLUE);
        W3Hint(victim, HINT_SKILL_STATUS, 1.0, "%T", "You Evaded a Shot", victim);

        if(War3_GetGame() == Game_TF)
        {
            decl Float:pos[3];
            GetClientEyePosition(victim, pos);
            pos[2] += 4.0;
            War3_TF_ParticleToClient(0, "miss_text", pos);
        }
    }
    
    if (ValidPlayer(attacker))
    {
        W3Hint(attacker, HINT_SKILL_STATUS, 1.0, "%T", "Enemy Evaded", attacker);
    }
}

public Native_EffectReturnDamage(Handle:plugin, numParams)
{
    // Victim: The guy getting shot
    // Attacker: The guy who takes damage
    new victim = GetNativeCell(1);
    new attacker = GetNativeCell(2);
    new damage = GetNativeCell(3);
    new skill = GetNativeCell(4);

    if (attacker == ATTACKER_WORLD)
    {
        return;
    }
    
    new beamSprite = War3_PrecacheBeamSprite();
    new haloSprite = War3_PrecacheHaloSprite();
    
    decl Float:f_AttackerPos[3];
    decl Float:f_VictimPos[3];

    if (ValidPlayer(attacker))
    {
        GetClientAbsOrigin(attacker, f_AttackerPos);
    }
    else if (IsValidEntity(attacker))
    {
        GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", f_AttackerPos);
    }
    else
    {
        War3_LogError("Invalid attacker for EffectReturnDamage: %i", attacker);
        return;
    }
    
    GetClientAbsOrigin(victim, f_VictimPos);
    
    f_AttackerPos[2] += 35.0;
    f_VictimPos[2] += 40.0;
    
    TE_SetupBeamPoints(f_AttackerPos, f_VictimPos, beamSprite, beamSprite, 0, 45, 0.4, 10.0, 10.0, 0, 0.5, {255, 35, 15, 255}, 30);
    TE_SendToAll();
    
    f_VictimPos[0] = f_AttackerPos[0];
    f_VictimPos[1] = f_AttackerPos[1];
    f_VictimPos[2] = 80.0 + f_AttackerPos[2];
    
    TE_SetupBubbles(f_AttackerPos, f_VictimPos, haloSprite, 35.0, GetRandomInt(6, 8), 8.0);
    TE_SendToAll();
    
    War3_NotifyPlayerTookDamageFromSkill(victim, attacker, damage, skill);
}

public Native_VampirismEffect(Handle:plugin, numParams)
{
    new victim = GetNativeCell(1);
    new attacker = GetNativeCell(2);
    new leechhealth = GetNativeCell(3);
        
    if (leechhealth <= 0)
    {
        return;
    }
    
    W3FlashScreen(victim, RGBA_COLOR_RED);
    W3FlashScreen(attacker, RGBA_COLOR_GREEN);
    
    // Team Fortress shows HP gained in the HUD already
    if(!GameTF())
    {
        W3Hint(attacker, HINT_SKILL_STATUS, 1.0, "%T", "Leeched +{amount} HP", attacker, leechhealth);
    }
    
    if(War3_TrackDelayExpired(iMaskSoundDelay[attacker]))
    {
        EmitSoundToAllAny(sMaskSound, attacker);
        War3_TrackDelay(iMaskSoundDelay[attacker], 0.25);
    }
    
    if(War3_TrackDelayExpired(iMaskSoundDelay[victim]))
    {
        EmitSoundToAllAny(sMaskSound, victim);
        War3_TrackDelay(iMaskSoundDelay[victim], 0.25);
    }
    
    PrintToConsole(attacker, "%T", "Leeched +{amount} HP", attacker, leechhealth);
}

public Native_BashEffect(Handle:plugin, numParams)
{
    new victim = GetNativeCell(1);
    new attacker = GetNativeCell(2);
    
    W3FlashScreen(victim, RGBA_COLOR_RED);

    W3Hint(victim, HINT_SKILL_STATUS, 1.0, "%T", "RcvdBash", victim);
    W3Hint(attacker, HINT_SKILL_STATUS, 1.0, "%T", "Bashed", attacker);
}

public Native_WardVisualEffect(Handle:plugin, numParams)
{
    new wardindex = GetNativeCell(1);
    decl beamcolor[4];
    GetNativeArray(2, beamcolor, sizeof(beamcolor));
    
    decl Float:fWardLocation[3];
    War3_GetWardLocation(wardindex, fWardLocation);
    new Float:fInterval = War3_GetWardInterval(wardindex);
    new wardRadius = War3_GetWardRadius(wardindex);

    new Float:fStartPos[3];
    new Float:fEndPos[3];
    new Float:tempVec1[] = {0.0, 0.0, WARDBELOW};
    new Float:tempVec2[] = {0.0, 0.0, WARDABOVE};
    
    AddVectors(fWardLocation, tempVec1, fStartPos);
    AddVectors(fWardLocation, tempVec2, fEndPos);

    TE_SetupBeamPoints(fStartPos, fEndPos, BeamSprite, HaloSprite, 0, GetRandomInt(30, 100), fInterval, 70.0, 70.0, 0, 30.0, beamcolor, 10);
    TE_SendToAll();
    
    new Float:StartRadius = wardRadius / 2.0;
    new Speed = RoundToFloor((wardRadius - StartRadius) / fInterval);
    
    TE_SetupBeamRingPoint(fWardLocation, StartRadius, float(wardRadius), BeamSprite, HaloSprite, 0,1, fInterval, 20.0, 1.5, beamcolor, Speed, 0);
    TE_SendToAll();
}