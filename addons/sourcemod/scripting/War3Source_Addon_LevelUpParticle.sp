#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Addon - Level Up Particle",
    author = "War3Source Team",
    description = "Display a fancy effect whenever somebody levels up"
};

public OnPluginStart()
{
    LoadTranslations("w3s.addon.levelupparticle.phrases");    
}

public OnMapStart()
{
    if (War3_GetGame() == Game_TF || GAMEL4DANY)
    {
        War3_PrecacheParticle("achieved");
    }
    else if (GameCS() || GameCSGO()) {
        PrecacheModel("effects/combinemuzzle2.vmt");
    }
}

public OnWar3Event(W3EVENT:event, client)
{
    if (event == PlayerLeveledUp)
    {
        new String:name[32];
        GetClientName(client, name, sizeof(name));
        new String:racename[32];
        new race = War3_GetRace(client);
        
        new level = War3_GetLevel(client, race);
        
        new ValveGameEnum:war3Game = War3_GetGame();
        
        if (war3Game == Game_TF)
        {
            AttachThrowAwayParticle(client, "achieved", NULL_VECTOR, "partyhat", 5.0);
            AttachThrowAwayParticle(client, "bday_1balloon", NULL_VECTOR, "partyhat", 5.0);
            AttachThrowAwayParticle(client, "bday_balloon01", NULL_VECTOR, "partyhat", 5.0);
            AttachThrowAwayParticle(client, "bday_balloon02", NULL_VECTOR, "partyhat", 5.0);
        
        }
        else if (war3Game == Game_CS || war3Game == Game_CSGO)
        {
            CSParticle(client, level);
        }
        else if (GAMEL4DANY && GetClientTeam(client) == TEAM_SURVIVORS)
        {
            // Glider: I never checked if l4d1 has this particle & attachment, l4d2 has 'em
            AttachThrowAwayParticle(client, "achieved", NULL_VECTOR, "eyes", 5.0);
        }    
        for(new i=1;i<=MaxClients;i++){
            if(ValidPlayer(i)){
                SetTrans(i);
                War3_GetRaceName(race, racename, sizeof(racename));
                War3_ChatMessage(i, "%T", "{player} has leveled {racename} to {amount}", i, name, racename, level);
            }
        }
        
    }
}

// Create Effect for Counter Strike Source:
public Action:CSParticle(const client, const level)
{
    new particle = CreateEntityByName("env_smokestack");
    if(IsValidEdict(particle) && IsClientInGame(client))
    {
        decl String:Name[32], Float:fPos[3];
        Format(Name, sizeof(Name), "CSParticle_%i_%i", client, level);
        GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
        fPos[2] += 28.0;
        new Float:fAng[3] = {0.0, 0.0, 0.0};
        
        // Set Key Values
        DispatchKeyValueVector(particle, "Origin", fPos);
        DispatchKeyValueVector(particle, "Angles", fAng);
        DispatchKeyValueFloat(particle, "BaseSpread", 15.0);
        DispatchKeyValueFloat(particle, "StartSize", 2.0);
        DispatchKeyValueFloat(particle, "EndSize", 6.0);
        DispatchKeyValueFloat(particle, "Twist", 0.0);
        
        DispatchKeyValue(particle, "Name", Name);
        DispatchKeyValue(particle, "SmokeMaterial", "effects/combinemuzzle2.vmt");
        DispatchKeyValue(particle, "RenderColor", "252 232 131");
        DispatchKeyValue(particle, "SpreadSpeed", "10");
        DispatchKeyValue(particle, "RenderAmt", "200");
        DispatchKeyValue(particle, "JetLength", "13");
        DispatchKeyValue(particle, "RenderMode", "0");
        DispatchKeyValue(particle, "Initial", "0");
        DispatchKeyValue(particle, "Speed", "10");
        DispatchKeyValue(particle, "Rate", "173");
        DispatchSpawn(particle);
        
        // Set Entity Inputs
        SetVariantString("!activator");
        AcceptEntityInput(particle, "SetParent", client, particle, 0);
        AcceptEntityInput(particle, "TurnOn");
        particle = EntIndexToEntRef(particle);
        SetVariantString("OnUser1 !self:Kill::3.5:-1");
        AcceptEntityInput(particle, "AddOutput");
        AcceptEntityInput(particle, "FireUser1");
    }
    else
    {
        LogError("Failed to create env_smokestack!");
    }
}