#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - XP Gold (L4D)",
    author = "War3Source Team",
    description = "Give XP and Gold specific to Left 4 Dead to those who deserve it"
};

new Handle:HealPlayerXPCvar;
new Handle:DeployUpgradeXPCvar;
new Handle:RevivePlayerXPCvar;
new Handle:RescuePlayerXPCvar;
new Handle:HelpTeammateXPCvar;
new Handle:SaveTeammateXPCvar;
new Handle:ProtectTeammateXPCvar;
new Handle:KillTankXPCvar;
new Handle:KillTankSoloXPCvar;
new Handle:KillWitchXPCvar;
new Handle:KillWitchCrownedXPCvar;
new Handle:InfectedDamageModXPCvar;
new Handle:PukeEnemyXPCvar;
new Handle:PukeFatalXPCvar;
new Handle:IncapXPCvar;
new Handle:KillSurvivorXPCvar;

public LoadCheck()
{
    return GameL4DAny();
}


public APLRes:AskPluginLoad2Custom(Handle:plugin,bool:late,String:error[],err_max)
{
    if(!GameL4DAny())
        return APLRes_SilentFailure;
    return APLRes_Success;
}

public OnPluginStart()
{
    LoadTranslations("w3s.engine.xpgold.txt");
    
    HealPlayerXPCvar=CreateConVar("war3_l4d_healxp","100","XP awarded to a player healing another");
    RevivePlayerXPCvar=CreateConVar("war3_l4d_revivexp","300","XP awarded to a player reviving another");
    RescuePlayerXPCvar=CreateConVar("war3_l4d_rescueexp","100","XP awarded to a player rescueing somebody from a closet");
    HelpTeammateXPCvar=CreateConVar("war3_l4d_helpexp","50","XP awarded to a player helping somebody get up");
    SaveTeammateXPCvar=CreateConVar("war3_l4d_saveexp","25","XP awarded to a player saving somebody from a infected");    
    ProtectTeammateXPCvar=CreateConVar("war3_l4d_protectexp","5","XP awarded to a player protecting another");
    DeployUpgradeXPCvar=CreateConVar("war3_l4d_upgradeexp","100","XP awarded to a player deploying a upgrade pack");
    
    KillTankXPCvar=CreateConVar("war3_l4d_tankexp","500","XP awarded to team surviving a Tank");
    KillTankSoloXPCvar=CreateConVar("war3_l4d_solotankexp","1000","XP awarded to player soloing a Tank");
    KillWitchXPCvar=CreateConVar("war3_l4d_witchexp","250","XP awarded to team killing a Witch");
    KillWitchCrownedXPCvar=CreateConVar("war3_l4d_crownwitchexp","100","XP awarded to player crowning a Witch");
    
    InfectedDamageModXPCvar=CreateConVar("war3_l4d_specialdmgexpmod","2.5","Damage * this = XP for a special infected doing damage");
    PukeEnemyXPCvar=CreateConVar("war3_l4d_pukexp","50","XP awarded to a boomer puking on a survivor");
    PukeFatalXPCvar=CreateConVar("war3_l4d_pukefatalxp","100","XP awarded to a boomer who pukes on somebody that gets incapped");
    IncapXPCvar=CreateConVar("war3_l4d_incapxp","100","XP awarded to a infected incapping a survivor");
    KillSurvivorXPCvar=CreateConVar("war3_l4d_killsurvivorxp","200","XP awarded to a infected killing a survivor");

    if(GAMEL4DANY)
    {        
        if(!HookEventEx("heal_success", War3Source_HealSuccessEvent))
        {
            PrintToServer("[War3Source] Could not hook the heal_success event.");
        }
        if(!HookEventEx("survivor_rescued", War3Source_SurvivorRescuedEvent))
        {
            PrintToServer("[War3Source] Could not hook the survivor_rescued event.");
        }
        if(!HookEventEx("witch_killed", War3Source_WitchKilledEvent))
        {
            PrintToServer("[War3Source] Could not hook the witch_killed event.");
        }
        if(!HookEventEx("tank_killed", War3Source_TankKilledEvent))
        {
            PrintToServer("[War3Source] Could not hook the tank_killed event.");
        }
        if(!HookEventEx("revive_success", War3Source_SurvivorRevivedEvent))
        {
            PrintToServer("[War3Source] Could not hook the revive_success event.");
        }
        if(!HookEventEx("choke_stopped", War3Source_SpecialRescueEvent))
        {
            PrintToServer("[War3Source] Could not hook the choke_stopped event.");
        }
        if(!HookEventEx("tongue_pull_stopped", War3Source_SpecialRescueEvent))
        {
            PrintToServer("[War3Source] Could not hook the tongue_pull_stopped event.");
        }
        if(!HookEventEx("jockey_ride_end", War3Source_SpecialRescueEvent))
        {
            PrintToServer("[War3Source] Could not hook the jockey_ride_end event.");
        }
        if(!HookEventEx("pounce_stopped", War3Source_SpecialRescueEvent))
        {
            PrintToServer("[War3Source] Could not hook the pounce_stopped event.");
        }
        if(!HookEventEx("award_earned", War3Source_ProtectMateEvent))
        {
            PrintToServer("[War3Source] Could not hook the award_earned event.");
        }
        if(!HookEventEx("map_transition", War3Source_EndRoundEvent))
        {
            PrintToServer("[War3Source] Could not hook the map_transition event.");
        }
        if(!HookEventEx("player_now_it", War3Source_PlayerBoomedEvent))
        {
            PrintToServer("[War3Source] Could not hook the player_now_it event.");
        }
        if(!HookEventEx("fatal_vomit", War3Source_PlayerFBoomedEvent))
        {
            PrintToServer("[War3Source] Could not hook the fatal_vomit event.");
        }
        if(!HookEventEx("player_incapacitated", War3Source_PlayerIncappedEvent))
        {
            PrintToServer("[War3Source] Could not hook the player_incapacitated event.");
        }
        if(War3_GetGame() == Game_L4D2)
        {
            if(!HookEventEx("defibrillator_used", War3Source_DefibUsedEvent))
            {
                PrintToServer("[War3Source] Could not hook the defibrillator_used event.");
            }
            if(!HookEventEx("upgrade_pack_used", War3Source_DeployUpgrade))
            {
                PrintToServer("[War3Source] Could not hook the upgrade_pack_used event.");
            }
        }
    }
}

public War3Source_DeployUpgrade(Handle:event,const String:name[],bool:dontBroadcast)
{    
    new userid = GetEventInt(event, "userid");
    
    if (userid > 0)
    {
        new client = GetClientOfUserId(userid);
        
        new addxp = GetConVarInt(DeployUpgradeXPCvar);
                
        //new String:healaward[64];
        //Format(healaward,sizeof(healaward),"%T","deplo a player",client);
        W3GiveXPGold(client,XPAwardByGeneric,addxp,0,"deploying a upgradepack");
    }

}

public War3Source_HealSuccessEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new healer = GetEventInt(event, "userid");
    new healee = GetEventInt(event, "subject");
    if(((healer > 0) && (healee > 0)) && (healer != healee))
    {
        new client = GetClientOfUserId(healer);
        
        new addxp = GetConVarInt(HealPlayerXPCvar);
        
        new String:healaward[64];
        Format(healaward,sizeof(healaward),"%T","healing a player",client);
        W3GiveXPGold(client,XPAwardByHealing,addxp,0,healaward);
    }
}

public War3Source_DefibUsedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new healer = GetEventInt(event, "userid");
    if(healer > 0)
    {
        new client = GetClientOfUserId(healer);
        new addxp = GetConVarInt(RevivePlayerXPCvar);
        
        new String:reviveaward[64];
        Format(reviveaward,sizeof(reviveaward),"%T","reviving a player",client);
        W3GiveXPGold(client,XPAwardByReviving,addxp,0,reviveaward);
    }
}

public War3Source_SurvivorRescuedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new rescuer = GetEventInt(event, "rescuer");
    if(rescuer > 0)
    {
        new client = GetClientOfUserId(rescuer);
        
        new addxp =  GetConVarInt(RescuePlayerXPCvar);
        
        new String:rescueaward[64];
        Format(rescueaward,sizeof(rescueaward),"%T","rescueing a player",client);
        W3GiveXPGold(client,XPAwardByRescueing,addxp,0,rescueaward);
    }
}

public War3Source_ProtectMateEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new protector = GetEventInt(event, "userid");
    new award = GetEventInt(event, "award");
    
    if( (protector > 0) && (award == 67))
    { 
        new client = GetClientOfUserId(protector);
        
    
        new addxp = GetConVarInt(ProtectTeammateXPCvar);
        
        new String:rescueaward[64];
        Format(rescueaward,sizeof(rescueaward),"%T","protecting a player",client);
        W3GiveXPGold(client,XPAwardByRescueing,addxp,0,rescueaward);
    }
}

public War3Source_EndRoundEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    // Reward survivors for being excellent :)
    RewardInOrder("m_checkpointZombieKills", 1.0);
    RewardInOrder("m_checkpointDamageToTank", 0.03);
    RewardInOrder("m_checkpointDamageToWitch", 0.05);
}

RewardInOrder(const String:netprop[], Float:final_multiplier)
{
    new iAmountList[MAXPLAYERS];
    new iAmount;
    new iAmountOfPlayers = 0;
    
    // Get everybodys values
    for(new client=1; client <= MaxClients; client++)
    {
        if(ValidPlayer(client, true) && GetClientTeam(client) == TEAM_SURVIVORS)
        {
            iAmount = GetEntProp(client, Prop_Send, netprop);
            iAmountList[client] = iAmount;
            
            iAmountOfPlayers++;
        }
    }
    
    SortIntegers(iAmountList, sizeof(iAmountList), Sort_Descending);
    
    new place = 0;
    new previous_amount = 0;
    new rewarded_players = 0;
    new reward_multiplier = 0;
    new addxp = 0;
    
    // Reward them
    while (rewarded_players < iAmountOfPlayers)
    {        
        for(new client=1; client <= MaxClients; client++)
        {
            if(ValidPlayer(client, true) && GetClientTeam(client) == TEAM_SURVIVORS)
            {
                iAmount = GetEntProp(client, Prop_Send, netprop);
                
                // Sorry, you were no asset to the team ;(
                if (iAmount == 0)
                {
                    rewarded_players++;
                    continue;
                }
                
                // Player has as much!
                if (iAmountList[place] == iAmount)
                {
                    place++;
                    // Previous place had just as much!
                    if (previous_amount == iAmount)
                    {
                        place--;
                    }
                
                    reward_multiplier = iAmountOfPlayers + 1 - place;
                    addxp = RoundToCeil((iAmount * reward_multiplier) * final_multiplier);
                    
                    if (StrEqual(netprop, "m_checkpointZombieKills"))
                        W3GiveXPGold(client, XPAwardByGeneric, addxp, 0, "Zombie kills");
                    else if (StrEqual(netprop, "m_checkpointDamageToTank"))
                        W3GiveXPGold(client, XPAwardByGeneric, addxp, 0, "Tank damage");
                    else if (StrEqual(netprop, "m_checkpointDamageToWitch"))
                        W3GiveXPGold(client, XPAwardByGeneric, addxp, 0, "Witch damage");
                                        
                    rewarded_players++;
                    previous_amount = iAmount;
                }
            }
        }
    }
}


public War3Source_SurvivorRevivedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    /*Help someone get up*/
    new reviver = GetClientOfUserId(GetEventInt(event, "userid")); 
    if(GetClientTeam(reviver) == TEAM_SURVIVORS)
    {
        new addxp = GetConVarInt(HelpTeammateXPCvar);
        
        new String:killaward[64];
        Format(killaward,sizeof(killaward),"%T","helping a teammate", reviver);
        W3GiveXPGold(reviver,  XPAwardByRescueing, addxp, 0, killaward);
    }
}

public War3Source_SpecialRescueEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new reviver;
    new victim = GetClientOfUserId(GetEventInt(event, "victim"));
    if (StrEqual(name, "jockey_ride_end"))
    {
        reviver = GetClientOfUserId(GetEventInt(event, "rescuer"));
    }
    else
    {
        reviver = GetClientOfUserId(GetEventInt(event, "userid"));    
    }
        
    if(ValidPlayer(reviver) && ValidPlayer(victim) && (reviver != victim) &&
       GetClientTeam(reviver) == TEAM_SURVIVORS)
    {
        new addxp = GetConVarInt(SaveTeammateXPCvar);
        
        new String:killaward[64];
        Format(killaward,sizeof(killaward),"%T","helping a teammate", reviver);
        W3GiveXPGold(reviver,  XPAwardByRescueing, addxp, 0, killaward);
    }
}

public War3Source_WitchKilledEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new killer = GetEventInt(event, "userid");
    if (killer > 0)
    {
        killer = GetClientOfUserId(killer);
        if(killer > 0 && GetClientTeam(killer) == TEAM_SURVIVORS)
        {
            new String:killaward[64];
            new bool:crowned = GetEventBool(event,"oneshot");    
            
            if (crowned)
            {
                new addxp = GetConVarInt(KillWitchCrownedXPCvar);
                Format(killaward,sizeof(killaward),"%T","crowning a Witch", killer);
                
                W3GiveXPGold(killer, XPAwardByKill, addxp, 0, killaward);
            }
            else
            {
                new addxp = GetConVarInt(KillWitchXPCvar);
                Format(killaward,sizeof(killaward),"%T","surviving a Witch", killer);
        
                for(new client=1; client <= MaxClients; client++)
                    if(ValidPlayer(client, true) && GetClientTeam(client) == TEAM_SURVIVORS && !War3_IsPlayerIncapped(client))
                    {
                        W3GiveXPGold(client,  XPAwardByGeneric, addxp, 0, killaward);
                    }
            }
        }
    }
}

public War3Source_TankKilledEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new killer = GetEventInt(event, "attacker");
    if (killer > 0)
    {
        killer = GetClientOfUserId(killer);
        //new victim = GetEventInt(event, "userid");
        if(killer > 0 && GetClientTeam(killer) == TEAM_SURVIVORS)
        {
            new String:killaward[64];
            new bool:solo = GetEventBool(event,"solo");    
            if (solo)
            {
                new addxp = GetConVarInt(KillTankSoloXPCvar);
                Format(killaward,sizeof(killaward),"%T","soloing a Tank",killer);
                
                W3GiveXPGold(killer, XPAwardByKill, addxp, 0, killaward);
                /*if (ValidPlayer(victim) && IsFakeClient(victim))
                    W3GiveXPGold(killer, War3_GetRace(killer), XPAwardByKill, addxp, 0, killaward);
                else
                    GiveKillXPCreds(killer, victim, false, false);*/
            }
            
            new addxp = GetConVarInt(KillTankXPCvar);
            for(new client=1; client <= MaxClients; client++)
                if(ValidPlayer(client, true) && GetClientTeam(client) == TEAM_SURVIVORS && !War3_IsPlayerIncapped(client) && (!solo || (client != killer)))
                {
                    Format(killaward,sizeof(killaward),"%T","surviving a Tank", client);
                    W3GiveXPGold(client, XPAwardByGeneric, addxp, 0, killaward);
                    /*if (ValidPlayer(victim) && IsFakeClient(victim))
                        W3GiveXPGold(client, War3_GetRace(client), XPAwardByKill, addxp, 0, killaward);
                    else
                        GiveKillXPCreds(client, victim, false, false);*/
                }
        }
    }
}




// Zombies, Specials, Versus Mode...

/* XP for doing damage as special infected */
public OnW3TakeDmgAllPre(victim, attacker, Float:damage)
{
    if( ValidPlayer(attacker) && (GetClientTeam(attacker) == TEAM_INFECTED) )
    {
        if( ValidPlayer(victim, true) && (GetClientTeam(victim) == TEAM_SURVIVORS) )
        {
            new addxp = RoundToCeil(damage * GetConVarFloat(InfectedDamageModXPCvar));
            
            if (addxp > 0)
            {
                W3GiveXPGold(attacker, XPAwardByGeneric, addxp, 0, "doing damage");
            }
        }
    }
}

public War3Source_PlayerBoomedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    
    new bool:by_boomer = GetEventBool(event, "by_boomer");
    
    if( by_boomer && ValidPlayer(victim) && ValidPlayer(attacker) )
    { 
        new addxp = GetConVarInt(PukeEnemyXPCvar);
        
        //new String:rescueaward[64];
        //Format(rescueaward,sizeof(rescueaward),"%T","protecting a player",client);
        W3GiveXPGold(attacker,XPAwardByGeneric,addxp,0,"puking on a enemy");
    }
}

public War3Source_PlayerFBoomedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if( ValidPlayer(victim) && ValidPlayer(attacker) )
    { 
        new addxp = GetConVarInt(PukeFatalXPCvar);
        
        //new String:rescueaward[64];
        //Format(rescueaward,sizeof(rescueaward),"%T","protecting a player",client);
        W3GiveXPGold(attacker,XPAwardByKill,addxp,0,"helping to incap a survivor");
    }
}

public War3Source_PlayerIncappedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if( ValidPlayer(victim) && ValidPlayer(attacker) && (GetClientTeam(attacker) == TEAM_INFECTED) )
    { 
        new addxp = GetConVarInt(IncapXPCvar);
        
        //new String:rescueaward[64];
        //Format(rescueaward,sizeof(rescueaward),"%T","protecting a player",client);
        W3GiveXPGold(attacker,XPAwardByKill,addxp,0,"incapping a survivor");
    }
}

public OnWar3EventDeath(victim, attacker)
{
    if( ValidPlayer(victim) && ValidPlayer(attacker) && (GetClientTeam(attacker) == TEAM_INFECTED) && (GetClientTeam(victim) == TEAM_SURVIVORS) )
    { 
        new addxp = GetConVarInt(KillSurvivorXPCvar);
        
        //new String:rescueaward[64];
        //Format(rescueaward,sizeof(rescueaward),"%T","protecting a player",client);
        W3GiveXPGold(attacker,XPAwardByKill,addxp,0,"killing a survivor");
    }
}