#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

#pragma semicolon 1

public Plugin:myinfo = 
{
    name = "War3Source - Warcraft Extended - Dodge",
    author = "War3Source Team",
    description = "Generic dodge skill"
};

new iFriendlyFire;

new Handle:hFriendlyFireCvar;
new Handle:FHOnW3DodgePre;
new Handle:FHOnW3DodgePost;

new dummyresult;

public bool:InitNativesForwards()
{
    FHOnW3DodgePre = CreateGlobalForward("OnW3DodgePre", ET_Hook, Param_Cell, Param_Cell, Param_Float);
    FHOnW3DodgePost = CreateGlobalForward("OnW3DodgePost", ET_Hook, Param_Cell, Param_Cell);
    
    return true;
}

public OnPluginStart()
{
    hFriendlyFireCvar = FindConVar("mp_friendlyfire");
    
    iFriendlyFire = GetConVarBool(hFriendlyFireCvar);
    HookConVarChange(hFriendlyFireCvar, ConVarChange_FriendlyFire);
}

public ConVarChange_FriendlyFire(Handle:convar, const String:oldValue[], const String:newValue[])
{
    iFriendlyFire = StringToInt(newValue);
}

public OnW3TakeDmgBulletPre(victim, attacker, Float:damage)
{
    if (ValidPlayer(victim) && victim != attacker) 
    {
        new Float:fEvasionChance = W3GetBuffSumFloat(victim, fDodgeChance);
        if(fEvasionChance > 0.0)
        {
            // If friendly fire isn't activated we don't have to try evading ;)
            if(!iFriendlyFire && ValidPlayer(attacker) && GetClientTeam(victim) == GetClientTeam(attacker))
            {
                return;
            }
            
            new Float:chance = GetRandomFloat(0.0, 1.0);
            
            Call_StartForward(FHOnW3DodgePre);
            Call_PushCell(victim);
            Call_PushCell(attacker);
            Call_PushFloat(chance);
            Call_Finish(dummyresult);
            
            if(!Hexed(victim, false) && chance <= fEvasionChance && !W3HasImmunity(attacker, Immunity_Skills))
            {
                War3_EvadeDamage(victim, attacker);
                
                Call_StartForward(FHOnW3DodgePost);
                Call_PushCell(victim);
                Call_PushCell(attacker);
                Call_Finish(dummyresult);
            }
        }
    }
}



