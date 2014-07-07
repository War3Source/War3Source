#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Addon - Halloween Boss Horseman XP/Gold",
    author = "War3Source Team",
    description = "Awards players for killing the headless horseman",
    url = "http://war3source.com/index.php?topic=1553.0"
};

// TF only.
public LoadCheck(){
    return GameTF();
}

// global variables
new String:NameClientKilledHorseman[MAX_NAME_LENGTH] = "";
new ClientKilledHorseman;

public OnPluginStart()
{
    // You'll need both hooks to get this to work.
    HookEvent("npc_hurt", Event_NPC);
    HookEvent("pumpkin_lord_killed", Event_HorsemannKilled);
}

public Action:Event_HorsemannKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
    new RandXP=GetRandomInt(100,200);
    new RandGOLD=GetRandomInt(1,10);
    if(ValidPlayer(ClientKilledHorseman))
    {
        W3GiveXPGold(ClientKilledHorseman, XPAwardByGeneric, RandXP, RandGOLD, "killing the headless horseman");
        PrintCenterTextAll("%s killed the Headless Horseman! ",NameClientKilledHorseman);
        PrintToChatAll("%s gained %i XP and %i gold for killing the Headless Horseman!",NameClientKilledHorseman,RandXP,RandGOLD);
    }
    // return Plugin_Continue as we don't
    // changed anything nor wan't to intercept the original func.
    return Plugin_Continue;
}

/*
"npc_hurt"
{
    "entindex" "short"
    "health" "short"
    "attacker_player" "short"
    "weaponid" "short"
    "damageamount" "short"
    "crit" "bool"
}*/

public Action:Event_NPC(Handle:event, const String:name[], bool:dontBroadcast)
{
    //Define what "client" is, since this is an event, and "client" isn't naturally defined
    new NPC = GetEventInt(event, "entindex");

    new String:aName[64];
    GetEntityClassname(NPC, aName, sizeof(aName));

    if(StrEqual(aName,"headless_hatman"))
    {
        ClientKilledHorseman = GetClientOfUserId(GetEventInt(event, "attacker_player"));
        GetClientName (ClientKilledHorseman, NameClientKilledHorseman, sizeof (NameClientKilledHorseman));
    }
    return Plugin_Continue;
}