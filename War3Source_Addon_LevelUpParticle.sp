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

new clientParticle[MAXPLAYERSCUSTOM];

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
		if (War3_GetGame() == Game_TF)
		{
			TFParticle(client, 0, "achieved", "partyhat");
		}
		else if (War3_GetGame() == Game_CS)
		{
			CSParticle(client);
		}
		else if (War3_IsL4DEngine())
		{
			TFParticle(client, 0, "achieved", "eyes");
		}	
		new String:name[32];
		GetClientName(client,name,sizeof(name));
		new String:racename[32];
		new race=War3_GetRace(client);
		War3_GetRaceName(race,racename,sizeof(racename));
		War3_ChatMessage(0,"%s has leveled {lightgreen}%s{default} to {lightgreen}%d",name,racename,War3_GetLevel(client,race));
	}
}

// Create Particle for Team Fortress 2:
public Action:TFParticle(const client, const particleNum, const String:effectName[], const String:attachTo[])
{
	clientParticle[particleNum] = CreateEntityByName("info_particle_system");
	new particle = clientParticle[particleNum];
	if (IsValidEdict(particle) && IsClientInGame(client))
	{
		decl String:tName[32], String:pName[12], Float:fPos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
		fPos[2] -= 5.0;
		TeleportEntity(particle, fPos, NULL_VECTOR, NULL_VECTOR);
		
		// Set Entity Keys & Spawn Entity (make sure dispatched entity name does not already exist, otherwise it will not work!!)
		Format(tName, sizeof(tName), "lvlup_cl_%i", client);
		DispatchKeyValue(client, "targetname", tName);
		
		// Set Key Values
		Format(pName, sizeof(pName), "lvlup_pe_%i_%i", particleNum, client);
		DispatchKeyValue(particle, "targetname", pName);
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", effectName);
		DispatchSpawn(particle);
		
		// Set Entity Inputs
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", client, particle, 0);
		SetVariantString(attachTo);
		AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
	}
	else
	{
		LogError("Failed to create info_particle_system!");
	}
}
// Create Effect for Counter Strike Source:
public Action:CSParticle(const client)
{
	new particle = CreateEntityByName("env_smokestack");
	if(IsValidEdict(particle) && IsClientInGame(client))
	{
		decl String:Name[32], Float:fPos[3];
		Format(Name, sizeof(Name), "CSParticle_%i", client);
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
		CreateTimer(3.5, RemoveCSParticle, particle);
	}
	else
	{
		LogError("Failed to create env_smokestack!");
	}
}

public Action:RemoveCSParticle(Handle:timer, any:particle)
{
	if(IsValidEdict(particle))
	{
		AcceptEntityInput(particle, "TurnOff");
		AcceptEntityInput(particle, "Kill");
	}
}
