#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <cstrike>

public Plugin:myinfo =
{
    name = "War3Source - Shopitem - Default Shopitems",
    author = "War3Source Team",
    description = "The default shopitems that come with War3Source"
};

enum {
    ITEM_ANKH = 0,
    ITEM_BOOTS,
    ITEM_CLAW,
    ITEM_CLOAK,
    ITEM_MASK,
    ITEM_NECKLACE,
    ITEM_FROST,
    ITEM_HEALTH,
    ITEM_TOME,
    ITEM_RESPAWN,
    ITEM_SOCK,
    ITEM_GLOVES,
    ITEM_RING,
    ITEM_MOLE,
    ITEM_ANTIWARD,
    ITEM_LAST, // Not a real item, just the last item in the enum!
}

new iShopitem[ITEM_LAST];
new iTomeSoundDelay[MAXPLAYERSCUSTOM];

// Offsets
new iActiveWeaponOffset;
new iOriginOffset;
new iMyWeaponsOffset;

new bool:bDidDie[MAXPLAYERSCUSTOM]; // did they die before spawning?
new bool:bFrosted[MAXPLAYERSCUSTOM];// don't frost before Timer_Unfrosted
new bool:bSpawnedViaScrollRespawn[MAXPLAYERSCUSTOM];// don't allow multiple scroll respawns
new bool:bItemsLoaded;

new Handle:hOrbSlowCvar;
new Handle:hTomeXPCvar;
new Handle:hBootsSpeedCvar;
new Handle:hClawsDamageCvar;
new Handle:hMaskLeechCvar;
new Handle:hSockGravityCvar;
new Handle:hRegenHPCvar;
new Handle:hMoleDeathmatchAllowedCvar;

new String:sOldModel[MAXPLAYERSCUSTOM][256];// reset model after 10 seconds
new String:sBuyTomeSound[256];

public OnPluginStart()
{
    if(GAMEL4DANY)
    {
        SetFailState("Not compatible with the Left4Dead games");
    }
    
    if(GameCSANY())
    {
        HookEvent("round_start", Event_RoundStart);
    }

    iOriginOffset = FindSendPropOffs("CBaseEntity", "m_vecOrigin");
    iMyWeaponsOffset = FindSendPropOffs("CBaseCombatCharacter", "m_hMyWeapons");
    iActiveWeaponOffset = FindSendPropOffs("CBaseCombatCharacter", "m_hActiveWeapon");
    
    hBootsSpeedCvar = CreateConVar("war3_shop_boots_speed", "1.2", "Boots speed, 1.2 is default");
    hClawsDamageCvar = CreateConVar("war3_shop_claws_damage", GameTF() ? "10" : "6", "Claws of attack additional damage per bullet (CS) or per second (TF)");
    hMaskLeechCvar = CreateConVar("war3_shop_mask_percent", "0.30", "Percent of damage rewarded for Mask of Death, from 0.0 - 1.0");
    hOrbSlowCvar = CreateConVar("war3_shop_orb_speed","0.6", "Orb of Frost speed, 1.0 is normal speed, 0.6 default for orb.");
    hTomeXPCvar = CreateConVar("war3_shop_tome_xp","100", "Experience awarded for Tome of Experience.");
    hSockGravityCvar = CreateConVar("war3_shop_sock_gravity", "0.4", "Gravity used for Sock of Feather, 0.4 is default for sock, 1.0 is normal gravity");
    hMoleDeathmatchAllowedCvar = CreateConVar("war3_shop_mole_dm", "0", "Set this to 1 if server is deathmatch");
    hRegenHPCvar = CreateConVar("war3_shop_ring_hp", GameTF() ? "4" : "2", "How much HP is regenerated per second");

    CreateTimer(0.1, PointOneSecondLoop, _, TIMER_REPEAT);
    CreateTimer(10.0, GrenadeLoop, _, TIMER_REPEAT);

    for(new i=1; i <= MaxClients; i++)
    {
        iTomeSoundDelay[i] = War3_RegisterDelayTracker();
    }

    LoadTranslations("w3s.item.antiward.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num == 10)
    {
        bItemsLoaded=true;
        for(new i=0; i < ITEM_LAST; i++)
        {
            iShopitem[i] = 0;
        }
        
        if(GAMECSANY)
        {
            iShopitem[ITEM_ANKH] = War3_CreateShopItemT("ankh", 3);
            iShopitem[ITEM_GLOVES] = War3_CreateShopItemT("glove", 5);
            iShopitem[ITEM_MOLE] = War3_CreateShopItemT("mole", 10);
        }

        iShopitem[ITEM_BOOTS] = War3_CreateShopItemT("boot", 3);
        iShopitem[ITEM_CLAW] = War3_CreateShopItemT("claw", 3);
        iShopitem[ITEM_CLOAK] = War3_CreateShopItemT("cloak", 2);
        iShopitem[ITEM_MASK] = War3_CreateShopItemT("mask", 3);
        iShopitem[ITEM_NECKLACE] = War3_CreateShopItemT("lace", 2);
        iShopitem[ITEM_FROST] = War3_CreateShopItemT("orb", 3);
        iShopitem[ITEM_RING] = War3_CreateShopItemT("ring", 3);
        iShopitem[ITEM_ANTIWARD] = War3_CreateShopItemT("antiward", 3);

        iShopitem[ITEM_HEALTH] = War3_CreateShopItemT("health", 3);
        iShopitem[ITEM_RESPAWN] = War3_CreateShopItemT("scroll", 15, false);
        
        War3_AddItemBuff(iShopitem[ITEM_HEALTH], iAdditionalMaxHealth, 50);

        iShopitem[ITEM_TOME] = War3_CreateShopItemT("tome", 10);
        War3_SetItemProperty(iShopitem[ITEM_TOME], ITEM_USED_ON_BUY, true);

        iShopitem[ITEM_SOCK] = War3_CreateShopItemT("sock", 2);
        
        War3_AddItemBuff(iShopitem[ITEM_ANTIWARD], bImmunityWards, true);
        War3_AddItemBuff(iShopitem[ITEM_SOCK], fLowGravityItem, GetConVarFloat(hSockGravityCvar));
        War3_AddItemBuff(iShopitem[ITEM_NECKLACE], bImmunityUltimates, true);
        War3_AddItemBuff(iShopitem[ITEM_RING], fHPRegen, GetConVarFloat(hRegenHPCvar));
        War3_AddItemBuff(iShopitem[ITEM_BOOTS], fMaxSpeed, GetConVarFloat(hBootsSpeedCvar));
        War3_AddItemBuff(iShopitem[ITEM_MASK], fVampirePercent, GetConVarFloat(hMaskLeechCvar));
    }
}

public OnMapStart()
{
    War3_AddSoundFolder(sBuyTomeSound, sizeof(sBuyTomeSound), "tomes.mp3");
    War3_AddCustomSound(sBuyTomeSound);
    
    if(GAMECSGO)
    {
        // These models aren't always precached
        PrecacheModel("models/player/ctm_gsg9.mdl");
        PrecacheModel("models/player/tm_leet_variantb.mdl");
    }
}

public doCloak()
{
    for(new x=1; x <= MaxClients; x++)
    {
        if(ValidPlayer(x, true) && War3_GetOwnsItem(x, iShopitem[ITEM_CLOAK]))
        {
            War3_SetBuffItem(x, fInvisibilityItem, iShopitem[ITEM_CLOAK], 0.6);

            // Melee?
            new ent = GetEntDataEnt2(x, iActiveWeaponOffset);
            if(ent > 0 && IsValidEdict(ent))
            {
                decl String:sWeaponName[64];
                GetEdictClassname(ent, sWeaponName, sizeof(sWeaponName));
                if(StrEqual(sWeaponName, "weapon_knife", false))
                {
                    War3_SetBuffItem(x, fInvisibilityItem, iShopitem[ITEM_CLOAK], 0.4);
                }
            }
        }
    }
}

public OnWar3EventDeath(client)
{
    if (ValidPlayer(client))
    {
        bDidDie[client]=true;

        if(War3_GetOwnsItem(client, iShopitem[ITEM_RESPAWN]))
        {
            CreateTimer(1.25, RespawnPlayerViaScrollRespawn, client); // default orc is 1.0, 1.25 so orc activates first
        }
    }
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(!GetConVarBool(hMoleDeathmatchAllowedCvar))
    {
        for(new x=1; x <= MaxClients; x++)
        {
            if(ValidPlayer(x, true) && GetClientTeam(x) > TEAM_SPECTATOR && 
               War3_GetOwnsItem(x, iShopitem[ITEM_MOLE]))
            {
                StartMole(x);
            }
        }
    }
}

public StartMole(client)
{
    new Float:fMoleTime=5.0;
    
    PrintHintText(client, "%T", "WARNING! MOLE IN {amount} SECONDS (item)!", client, fMoleTime);
    War3_ChatMessage(client, "%T", "WARNING! MOLE IN {amount} SECONDS (item)!", client, fMoleTime);
    
    CreateTimer(0.2 + fMoleTime, DoMole, client);
}

public OnWar3EventSpawn(client)
{
    if(bFrosted[client])
    {
        bFrosted[client] = false;
        War3_SetBuffItem(client, fSlow, iShopitem[ITEM_FROST], 1.0);
    }

    if(GAMECSANY && 
       War3_GetOwnsItem(client, iShopitem[ITEM_ANKH]) && bDidDie[client])
    {
        if(!bSpawnedViaScrollRespawn[client])
        { 
            //only if he didnt already respawn from the "respawn item" cuz that gives items too
            CreateTimer(0.1, DoAnkhAction, client);
        }
    }
    
    if(War3_GetOwnsItem(client, iShopitem[ITEM_HEALTH]))
    {
        War3_SetBuffItem(client, iAdditionalMaxHealth, iShopitem[ITEM_HEALTH], 50);
        War3_ChatMessage(client, "%T", "+50 HP", client);
    }
    
    if(War3_GetOwnsItem(client, iShopitem[ITEM_SOCK]))
    {
        War3_SetBuffItem(client, fLowGravityItem, iShopitem[ITEM_SOCK], GetConVarFloat(hSockGravityCvar));
        War3_ChatMessage(client, "%T", "You pull on your socks", client);
    }
    
    if(War3_GetGame() != Game_TF && 
       War3_GetOwnsItem(client,iShopitem[ITEM_MOLE]) && 
       GetConVarBool(hMoleDeathmatchAllowedCvar)) // deathmatch
    {
        StartMole(client);
    }
    
    bDidDie[client] = false;
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(!isWarcraft && ValidPlayer(victim) && 
       ValidPlayer(attacker, true) && 
       ValidPlayer(victim, true, true) && 
       GetClientTeam(victim) != GetClientTeam(attacker))
    {
        if(!W3HasImmunity(victim, Immunity_Items) && !Perplexed(attacker))
        {
            if(War3_GetOwnsItem(attacker, iShopitem[ITEM_CLAW])) // claws of attack
            {
                new Float:fDMG = GetConVarFloat(hClawsDamageCvar);
                if(fDMG<0.0)
                {
                    fDMG = 0.0;
                }

                if(GameTF())
                {
                    if(W3ChanceModifier(attacker) < 0.99)
                    {
                        fDMG *= W3ChanceModifier(attacker);
                    }
                    else
                    {
                        fDMG *= 0.50;
                    }
                }
                if(War3_DealDamage(victim, RoundFloat(fDMG), attacker, _, 
                                   "claws", W3DMGORIGIN_ITEM, W3DMGTYPE_PHYSICAL))
                {
                    PrintToConsole(attacker, "%T", "+{amount} Claws Damage",
                                   attacker, War3_GetWar3DamageDealt());
                }
            }

            if(War3_GetOwnsItem(attacker, iShopitem[ITEM_FROST]) && !bFrosted[victim])
            {
                new Float:fSpeedMult = GetConVarFloat(hOrbSlowCvar);
                if(fSpeedMult <= 0.0)
                {
                    fSpeedMult = 0.01; // 0.0 for override removes
                }
                if(fSpeedMult > 1.0)
                {
                    fSpeedMult = 1.0;
                }
                War3_SetBuffItem(victim, fSlow, iShopitem[ITEM_FROST], fSpeedMult);
                bFrosted[victim] = true;

                PrintToConsole(attacker, "%T", "ORB OF FROST!", attacker);
                PrintToConsole(victim, "%T", "Frosted, reducing your speed", victim);
                CreateTimer(2.0, Timer_Unfrost, victim);
            }
        }
    }
}

public OnWar3Event(W3EVENT:event, client)
{
    if(event == ClearPlayerVariables)
    {
        bDidDie[client] = false;
    }
}

//=============================================================================
//                             Item Ownership
//=============================================================================

public OnItemPurchase(client,item)
{
    if(!ValidPlayer(client))
    {
        return;
    }

    if(item == iShopitem[ITEM_BOOTS])
    {       
        if(IsPlayerAlive(client))
        {
            War3_ChatMessage(client, "%T", "You strap on your boots", client);
        }
    }
    
    if(item == iShopitem[ITEM_SOCK])
    {
       
        if(IsPlayerAlive(client))
        {
            War3_ChatMessage(client, "%T", "You pull on your socks", client);
        }
    }
    
    if(War3_GetGame() != Game_TF && item == iShopitem[ITEM_HEALTH] && IsPlayerAlive(client))
    {
        War3_ChatMessage(client, "%T", "+50 HP", client);
    }
    
    if(item == iShopitem[ITEM_TOME])
    {
        new iRace = War3_GetRace(client);
        new iBonusXP = GetConVarInt(hTomeXPCvar);
        if(iBonusXP < 0)
        {
            iBonusXP=0;
        }
        
        War3_SetXP(client, iRace, War3_GetXP(client, iRace) + iBonusXP);
        W3DoLevelCheck(client);
        
        War3_SetOwnsItem(client, item, false);
        War3_ChatMessage(client, "%T", "+{amount} XP", client, iBonusXP);
        War3_ShowXP(client);
        
        if(War3_TrackDelayExpired(iTomeSoundDelay[client]))
        {
            if (IsPlayerAlive(client))
            {
                EmitSoundToAll(sBuyTomeSound, client);
            }
            else
            {
                EmitSoundToClient(client, sBuyTomeSound);
            }
            
            War3_TrackDelay(iTomeSoundDelay[client], 0.25);
        }
    }
    
    if(item == iShopitem[ITEM_RESPAWN])
    {
        bSpawnedViaScrollRespawn[client]=false;

        if(!IsPlayerAlive(client) && GetClientTeam(client) > 1)
        {
            War3_ChatMessage(client, "%T", "You will be respawned", client);
            CreateTimer(0.2, RespawnPlayerViaScrollRespawn, client);
        }
        else
        {
            War3_ChatMessage(client, "%T", "Next time you die you will respawn", client);
        }
    }
}

public OnItemLost(client, item)
{ 
    if (!ValidPlayer(client))
    {
        return;
    }

    else if(item == iShopitem[ITEM_HEALTH])
    {
        if(GetClientHealth(client) > War3_GetMaxHP(client))
        {
            SetEntityHealth(client, War3_GetMaxHP(client));
        }
    }
    else if(item == iShopitem[ITEM_CLOAK])
    {
        War3_SetBuffItem(client, fInvisibilityItem, iShopitem[ITEM_CLOAK], 1.0);
    }
}

//=============================================================================
//                             Timer callbacks
//=============================================================================

public Action:Timer_Unfrost(Handle:timer,any:client)
{
    bFrosted[client] = false;

    War3_SetBuffItem(client, fSlow, iShopitem[ITEM_FROST], 1.0);
    if(ValidPlayer(client))
    {
        PrintToConsole(client, "%T", "REGAINED SPEED from frost", client);
    }
}

public Action:NoLongerSpawnedViaScroll(Handle:t, any:client)
{
    bSpawnedViaScrollRespawn[client] = false;
}

public Action:RespawnPlayerViaScrollRespawn(Handle:h, any:client)
{
    if(ValidPlayer(client) && !IsPlayerAlive(client)) //not revived from something else
    {
        // prevent ankh from activating
        bSpawnedViaScrollRespawn[client] = true;
        War3_SpawnPlayer(client);
        
        if(GAMECSANY)
        {
            CreateTimer(0.2, GivePlayerCachedDeathWPNFull, client);
        }
        PrintCenterText(client, "%T", "RESPAWNED!", client);

        bSpawnedViaScrollRespawn[client] = false;
        
        War3_SetOwnsItem(client, iShopitem[ITEM_RESPAWN], false);
        War3_ChatMessage(client, "%T", "Respawned by Scroll of Respawning", client);
        CreateTimer(1.0, NoLongerSpawnedViaScroll, client);
    }
}

public Action:ResetModel(Handle:timer,any:client)
{
    if(ValidPlayer(client, true))
    {
        SetEntityModel(client, sOldModel[client]);
        War3_ChatMessage(client, "%T", "You are no longer disguised", client);
    }
}

public Action:DoAnkhAction(Handle:t,any:client)
{ 
    //just respawned, passed that he didnt respawn from scroll, too bad if he respawned from orc or mage
    GivePlayerCachedDeathWPNFull(INVALID_HANDLE, client);
    War3_SetOwnsItem(client, iShopitem[ITEM_ANKH], false);
    War3_ChatMessage(client, "%T", "You reincarnated with all your gear", client);
}

public Action:GivePlayerCachedDeathWPNFull(Handle:h,any:client)
{
    if(ValidPlayer(client, true))
    {
        for(new s=0; s < 10; s++)
        {
            new ent = GetEntDataEnt2(client, iMyWeaponsOffset + (s * 4));
            if(ent > 0 && IsValidEdict(ent))
            {
                new String:ename[64];
                GetEdictClassname(ent, ename, sizeof(ename));
                if(StrEqual(ename, "weapon_c4") || StrEqual(ename, "weapon_knife"))
                {
                    continue;
                }
                W3DropWeapon(client, ent);
                UTIL_Remove(ent);
            }
        }

        // give them their weapons
        for(new s=0; s < 10; s++)
        {
            new String:sWeaponName[64];
            War3_CachedDeadWeaponName(client, s, sWeaponName, sizeof(sWeaponName));
            if(!StrEqual(sWeaponName,"") && !StrEqual(sWeaponName,"",false) && 
               !StrEqual(sWeaponName,"weapon_c4") && 
               !StrEqual(sWeaponName,"weapon_knife"))
            {
                GivePlayerItem(client, sWeaponName);
            }
        }
        
        if( GAMECSANY )
        {
            War3_RestoreCachedCSArmor(client);
        }
    }
}

public Action:DoMole(Handle:timer, any:client)
{
    if(ValidPlayer(client, true))
    {
        new iPlayerTeam = GetClientTeam(client);
        new iEnemyTeam = (iPlayerTeam == TEAM_T) ? TEAM_CT : TEAM_T;

        new Float:fEmptySpawnPoints[100][3];
        new iAvailableLocations=0;
        new Float:fPlayerPosition[3];
        new Float:fSpawnPosition[3];
        
        new ent = INVALID_ENT_REFERENCE;
        while((ent = FindEntityByClassname(ent, (iEnemyTeam == TEAM_T) ? "info_player_terrorist" : "info_player_counterterrorist")) != INVALID_ENT_REFERENCE)
        {
            if(!IsValidEdict(ent)) 
            {
                continue;
            }
            
            GetEntDataVector(ent, iOriginOffset, fSpawnPosition);

            new bool:bIsConflicting = false;
            for(new i=1; i <= MaxClients; i++)
            {
                if(ValidPlayer(i, true))
                {
                    GetClientAbsOrigin(i, fPlayerPosition);
                    if(GetVectorDistance(fSpawnPosition, fPlayerPosition) < 60.0)
                    {
                        bIsConflicting = true;
                        break;
                    }
                }
            }
            
            if(!bIsConflicting)
            {
                fEmptySpawnPoints[iAvailableLocations][0] = fSpawnPosition[0];
                fEmptySpawnPoints[iAvailableLocations][1] = fSpawnPosition[1];
                fEmptySpawnPoints[iAvailableLocations][2] = fSpawnPosition[2];
                iAvailableLocations++;
            }
        }
        if(iAvailableLocations == 0)
        {
            War3_ChatMessage(client, "%T", "This map does not have enemy spawn points, can not mole!", client);
            return;
        }

        GetClientModel(client, sOldModel[client], 256);

        if(War3_GetGame() == Game_CS)
        {
            SetEntityModel(client, (iEnemyTeam == TEAM_T) ? "models/player/t_leet.mdl" : "models/player/ct_urban.mdl");
        }
        else // CS:GO
        {
            SetEntityModel(client, (iEnemyTeam == TEAM_T) ? "models/player/tm_leet_variantb.mdl" : "models/player/ctm_gsg9.mdl");
        }

        TeleportEntity(client, fEmptySpawnPoints[GetRandomInt(0, iAvailableLocations - 1)], NULL_VECTOR, NULL_VECTOR);

        War3_ChatMessage(client, "%T", "You have moled!", client);
        PrintHintText(client, "%T", "You have moled!", client);
        
        War3_ShakeScreen(client, 1.0, 20.0, 12.0);
        CreateTimer(10.0, ResetModel, client);

        War3_SetOwnsItem(client, iShopitem[ITEM_MOLE], false);
    }
}

public Action:PointOneSecondLoop(Handle:timer, any:data)
{
    if(bItemsLoaded)
    {
        doCloak();
    }
}

//gloves giving nades
public Action:GrenadeLoop(Handle:timer, any:data)
{
    if(bItemsLoaded && GameCSANY())
    {
        for(new x=1; x <= MaxClients; x++)
        {
            if(ValidPlayer(x, true) && War3_GetOwnsItem(x, iShopitem[ITEM_GLOVES]))
            {
                new bool:bHasGrenade = false;
                for(new s=0; s < 10; s++)
                {
                    new ent = War3_CachedWeapon(x, s);
                    if(ent > 0 && IsValidEdict(ent))
                    {
                        decl String:sWeaponName[64];
                        GetEdictClassname(ent, sWeaponName, sizeof(sWeaponName));
                        if(StrEqual(sWeaponName, "weapon_hegrenade", false))
                        {
                            bHasGrenade=true;
                        }
                    }
                }
                if(!bHasGrenade)
                {
                    GivePlayerItem(x, "weapon_hegrenade");
                    PrintHintText(x, "%T", "+HEGRENADE", x);
                }
            }
        }
    }
}
