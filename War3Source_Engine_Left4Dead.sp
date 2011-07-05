// Left4Dead Engine
// Handles L4D specific stuff 

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo= 
{
	name = "W3S Engine Left4Dead",
	author = "Glider",
	description = "War3Source Core Plugins",
	version = "1.0",
	url = "http://war3source.com/"
};

new bool:g_bIsHelpless[MAXPLAYERS+1];

public bool:InitNativesForwards()
{
	///LIST ALL THESE NATIVES IN INTERFACE
	CreateNative("War3_L4D_IsHelpless", Native_War3_L4D_IsHelpless);
	return true;
}

public OnPluginStart()
{
	if(!GameL4DAny())
		SetFailState("Only works in the L4D engine! %i", War3_GetGame());
	
	// Hunter
	HookEvent("lunge_pounce", Event_IsHelpless);
	HookEvent("pounce_stopped", Event_IsNoLongerHelpless);
	
	// Smoker
	HookEvent("tongue_grab", Event_IsHelpless);
	HookEvent("tongue_release", Event_IsNoLongerHelpless);
	
	// Charger
	HookEvent("charger_carry_start", Event_IsHelpless);
	HookEvent("charger_carry_end", Event_IsNoLongerHelpless);
	// Yes, there is a small time gap between carrying and pummeling that
	// is not accounted for.
	HookEvent("charger_pummel_start", Event_IsHelpless);
	HookEvent("charger_pummel_end", Event_IsNoLongerHelpless);
		
	// Jockey
	HookEvent("jockey_ride", Event_IsHelpless);
	HookEvent("jockey_ride_end", Event_IsNoLongerHelpless);
	
	HookEvent("round_start", Event_ResetHelplessAll);
	HookEvent("round_end", Event_ResetHelplessAll);
	
	HookEvent("player_spawn", Event_ResetHelplessUserID);
	HookEvent("player_death", Event_ResetHelplessUserID);
	HookEvent("player_connect_full", Event_ResetHelplessUserID);
	HookEvent("player_disconnect", Event_ResetHelplessUserID);
}

public Event_IsHelpless (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!victim) return;
	g_bIsHelpless[victim] = true;
}

public Event_IsNoLongerHelpless (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!victim) return;
	g_bIsHelpless[victim] = false;
}

public Event_ResetHelplessAll (Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=1 ; i<=MaxClients ; i++)
	{
		g_bIsHelpless[i] = false;
	}
}

public Event_ResetHelplessUserID (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client) return;
	g_bIsHelpless[client] = false;
}

public Native_War3_L4D_IsHelpless(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return g_bIsHelpless[client];
}