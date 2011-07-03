#pragma semicolon 1

#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "War3Source - Addon - L4D - Fix Buggy Map Starts",
	author = "Glider",
	description = "There are some maps wich don't have the saferoom volumes properly mapped.",
	version = "1.0",
};

new Handle:fixTimer = INVALID_HANDLE;
new Handle:killTimer = INVALID_HANDLE;

/* TODO: ADD CVAR */

public OnMapStart()
{	
	if(GameL4DAny()){
		startNewTimer();
		
		HookEvent("round_end", RoundEndEvent);
		HookEvent("mission_lost", MissionLostEvent);
	}
}

public Action:FixRaceTimer(Handle:timer, any:userid)
{
	for(new client=1; client <= MaxClients; client++)
	{
		if(ValidPlayer(client, true))
		{
			new goal_race = W3GetPendingRace(client);
			if (goal_race > 0)
			{
				W3Hint(client, HINT_LOWEST, 1.0, "This map is buggy - allowing race change for the first 2 minutes...");
				War3_SetRace(client, goal_race);
				W3SetPendingRace(client, -1);
			}
		}
	}
}

public Action:DelayedStartTimer(Handle:timer, any:userid)
{
	startNewTimer();
}

/* LITTLE STUFF */

stock bool:IsFuckedUpMap()
{
	decl String:mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));
	
	if (StrEqual(mapName, "c2m1_highway") || StrEqual(mapName, "c1m1_hotel") ||
		StrEqual(mapName, "c3m1_plankcountry") || StrEqual(mapName, "c4m1_milltown_a") || 
		StrEqual(mapName, "c5m1_waterfront") || StrEqual(mapName, "c2m3_coaster"))
	{
		return true;
	}
	return false;
}

startNewTimer()
{
	killAll();
	
	if ( IsFuckedUpMap() )
	{
		fixTimer = CreateTimer(0.1, FixRaceTimer, _, TIMER_REPEAT);
		killTimer = CreateTimer(120.0, TimerKiller, _, TIMER_REPEAT);
	}
}

/* Fun fact: Sourcemod doesnt allow me to pass the variable through a parameter
 * 			 and then set it to invalid_handle. fuck your reference system
 * 			 bitches.
 */
killFixTimer()
{
	if (fixTimer != INVALID_HANDLE)
	{
		KillTimer(fixTimer);
		fixTimer = INVALID_HANDLE;
	}
}

killKillTimer()
{
	if (killTimer != INVALID_HANDLE)
	{
		KillTimer(killTimer);
		killTimer = INVALID_HANDLE;
	}
}

killAll()
{
	killFixTimer();
	killKillTimer();
}

/* EVENTS */

public Action:TimerKiller(Handle:timer, any:userid)
{
	PrintToChatAll("RACE CHANGE REVERTED TO NORMAL!");
	killAll();
}

public Action:RoundEndEvent(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	killAll();
}

public Action:MissionLostEvent(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	// The round ends so the killing is done there
	CreateTimer(5.0, DelayedStartTimer);
}
	