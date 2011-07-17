/**
 * File: War3Source_Addon_LevelUpParticle.sp
 * Description: Displays particles whenever somebody levels up.
 * Author(s): Glider & xDr.HaaaaaaaXx
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "W3S - Addon - Display Particles on Level Up",
	author = "Glider & xDr.HaaaaaaaXx",
	description = "Displays particles whenever somebody levels up",
	version = "1.2",
};

public OnMapStart()
{
	PrecacheModel("effects/combinemuzzle2.vmt");
	
	if (War3_GetGame() == Game_TF || War3_IsL4DEngine())
	{
		War3_PrecacheParticle("achieved");
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
		War3_GetRaceName(race, racename, sizeof(racename));
		new level = War3_GetLevel(client, race);
		
		if (War3_GetGame() == Game_TF)
		{
			AttachThrowAwayParticle(client, "achieved", NULL_VECTOR, "partyhat", 5.0);
			AttachThrowAwayParticle(client, "bday_1balloon", NULL_VECTOR, "partyhat", 5.0);
			AttachThrowAwayParticle(client, "bday_balloon01", NULL_VECTOR, "partyhat", 5.0);
			AttachThrowAwayParticle(client, "bday_balloon02", NULL_VECTOR, "partyhat", 5.0);
		}
		else if (War3_GetGame() == Game_CS)
		{
			CSParticle(client, level);
		}
		else if (War3_IsL4DEngine())
		{
			// Glider: I never checked if l4d1 has this particle & attachment, l4d2 has 'em
			AttachThrowAwayParticle(client, "achieved", NULL_VECTOR, "eyes", 5.0);
		}	
		War3_ChatMessage(0, "%s has leveled {lightgreen}%s{default} to {lightgreen}%d", name, racename, level);
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