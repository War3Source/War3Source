/**
 * File: War3Source_Damage.inc
 * Description: Stocks regarding Damage
 * Author(s): War3Source Team  
 */

// The following are bit-flags for War3_DealDamage
// Does not appear useful in any way
#if !defined DMG_GENERIC

#define DMG_GENERIC                    0
#define DMG_CRUSH                      (1 << 0)
#define DMG_BULLET                     (1 << 1)
#define DMG_SLASH                      (1 << 2)
#define DMG_BURN                       (1 << 3)
#define DMG_VEHICLE                    (1 << 4)
#define DMG_FALL                       (1 << 5)
#define DMG_BLAST                      (1 << 6)
#define DMG_CLUB                       (1 << 7)
#define DMG_SHOCK                      (1 << 8)
#define DMG_SONIC                      (1 << 9)
#define DMG_ENERGYBEAM                 (1 << 10)
#define DMG_PREVENT_PHYSICS_FORCE      (1 << 11)
#define DMG_NEVERGIB                   (1 << 12)
#define DMG_ALWAYSGIB                  (1 << 13)
#define DMG_DROWN                      (1 << 14)
#define DMG_TIMEBASED                  (DMG_PARALYZE | DMG_NERVEGAS | DMG_POISON | DMG_RADIATION | DMG_DROWNRECOVER | DMG_ACID | DMG_SLOWBURN)
#define DMG_PARALYZE                   (1 << 15)
#define DMG_NERVEGAS                   (1 << 16)
#define DMG_POISON                     (1 << 17)
#define DMG_RADIATION                  (1 << 18)
#define DMG_DROWNRECOVER               (1 << 19)
#define DMG_ACID                       (1 << 20)
#define DMG_SLOWBURN                   (1 << 21)
#define DMG_REMOVENORAGDOLL            (1 << 22)
#define DMG_PHYSGUN                    (1 << 23)
#define DMG_PLASMA                     (1 << 24)
#define DMG_AIRBOAT                    (1 << 25)
#define DMG_DISSOLVE                   (1 << 26)
#define DMG_BLAST_SURFACE              (1 << 27)
#define DMG_DIRECT                     (1 << 28)
#define DMG_BUCKSHOT                   (1 << 29)

#endif

//=======================================================================
//                             NATIVE / STOCKS
//=======================================================================

//=========================================
//                 DAMAGE
//==========================================

/**
 * Deal damage.
 * @param victim: Victim's client index.
 * @param damage: Damage to be dealt.
 * @param attacker: Optional, attacker client index. Pass 0 for none.
 * @param damage_type: Optional, damage bit-flags. See above for DMG_* defines.
 * @param weaponstr: Optional, weapon name for simulated damage.
 * @param W3DMGOrigin: where the damage came from IE SKILL or ULTIMATE or ITEM  
 * @param WAR3_DMGTYPE: is this damage true (no armor) physical (physical armor/immunity)  or magic (magic armor/immunity)
 * @param respectVictimImmunity: should damage be blocked if victim has that type of immunity, accouts for ORIGIN immunity and DMG type. (SKILL, ULTIMATE, ITEM, |||| MAGIC AND PHYSICAL ) simplifies so that u dont have to check
 * @param countAsFirstDamageRetriggered: should this damage allow to be rehooked (creating a real hurt-event again)? this may cause infinite loops!  Yes to combime with items and other skills only if its not in a damage hook itself. (infinite loop triggering)
 * @param noWarning: Prevent warning print when using DealDamage from a event where it's error prone
 * @return bool: did damage go through, false if player was immune to that damage type or damage was zero or something else failed
 */
native bool:War3_DealDamage(victim,damage,attacker=0,damage_type=DMG_GENERIC|DMG_PREVENT_PHYSICS_FORCE,String:weaponNameStr[], War3DamageOrigin:W3DMGORIGIN=W3DMGORIGIN_UNDEFINED , War3DamageType:W3DMGTYPE=W3DMGTYPE_MAGIC , bool:respectVictimImmunity=true , bool:countAsFirstDamageRetriggered=false, bool:noWarning=false);

/*
 * forces the damage to be multiplied by @num
 * shall only be done inside SDKHOOKS damage forward (when damage hasnt been dealt yet) 
 * @noreturn
 */
native War3_DamageModPercent(Float:num);


//get the actual damage dealt from War3_DealDamage, because real damage is different after taking account to magic/physical armor
//u wana call this immediately after War3_DealDamage cuz this is a single global variable. when someone else calls War3_DealDamage it will be changed
native War3_GetWar3DamageDealt();

///is last damage a bullet first triggered damage? works on posthurt and sdkhookdmgall
native W3GetDamageIsBullet();

//return the game damagetype (burn, laser, etc) of the last damage (TakeDmg forward)
native W3GetDamageType();
//get inflictor of the last damage (TakeDmg forward) (ie sentry gun  is a different object than the attacker itself)
native W3GetDamageInflictor();

native W3ForceDamageIsBullet();
// if u do damage within a takedmg, the original damage may be nullified as non bullet, 
//use this function after you have dealt damage inside a takedmg
//so you can allow other isdmgbullet proc

//get the depth of the damage stack, usually 1 or more
native W3GetDamageStack();

stock War3_DealDamageDelayed(victim,attacker,damage,String:classname[32],Float:delay=0.0,bool:showDamage=false,showDamage_skill=0) {
    new Handle:pack;
    CreateDataTimer(delay, _war3source_Timer_DealDamage, pack);
    WritePackCell(pack, victim);
    WritePackCell(pack, attacker);
    WritePackCell(pack, damage);
    WritePackCell(pack, showDamage);
    WritePackCell(pack, showDamage_skill);
    WritePackString(pack, classname);
}

// In csgo killing 2 players in the same frame causes a crash so we use this dirty workaround
public Action:_war3source_Timer_DealDamage(Handle:timer, Handle:pack)
{
    ResetPack(pack); //resolve the package...
    new victim = ReadPackCell(pack);
    if(!ValidPlayer(victim,true)) {
        // immedialety exit!
        return Plugin_Stop;
    }
    new attacker = ReadPackCell(pack);
    new damage = ReadPackCell(pack);
    new bool:showDamage = bool:ReadPackCell(pack);
    new showDamage_skill = ReadPackCell(pack);
    decl String:classname[32];
    ReadPackString(pack,classname,sizeof(classname));
    
    // Glider: TODO: Figure out if the notification include or the 
    //               DealDamage methods should be held responsible for this
    
    if(War3_DealDamage(victim,damage,attacker,DMG_BULLET,classname) && showDamage) {
        W3PrintSkillDmgConsole(victim,attacker,War3_GetWar3DamageDealt(),showDamage_skill);
    }
    return Plugin_Stop;
}

stock bool:W3IsDamageFromMelee(const String:weapon[])
{
    switch (War3_GetGame())
    {
        case Game_CS:
        {
            return StrEqual(weapon, "knife");
        }
        case Game_DOD:
        {
            return (StrEqual(weapon, "amerknife") ||
                    StrEqual(weapon, "spade") ||
                    StrEqual(weapon, "punch"));
        }
        case Game_TF:
        {
            return (// Logfile names
                    StrEqual(weapon, "shovel") ||
                    StrEqual(weapon, "wrench") ||
                    StrEqual(weapon, "bat") ||
                    StrEqual(weapon, "bonesaw") ||
                    StrEqual(weapon, "bottle") ||
                    StrEqual(weapon, "club") ||
                    StrEqual(weapon, "fireaxe") ||
                    StrEqual(weapon, "fists") ||
                    StrEqual(weapon, "sandman") ||
                    StrEqual(weapon, "pickaxe") ||
                    StrEqual(weapon, "sword") ||
                    StrEqual(weapon, "demoshield") ||
                    StrEqual(weapon, "taunt_scout") ||
                    StrEqual(weapon, "taunt_sniper") ||
                    StrEqual(weapon, "taunt_pyro") ||
                    StrEqual(weapon, "taunt_demoman") ||
                    StrEqual(weapon, "taunt_heavy") ||
                    StrEqual(weapon, "taunt_spy") ||
                    StrEqual(weapon, "taunt_soldier")||
                    StrEqual(weapon, "annihilator") ||
                    StrEqual(weapon, "ubersaw") ||
                    StrEqual(weapon, "axtinguisher") ||
                    StrEqual(weapon, "gloves") ||
                    StrEqual(weapon, "sandman") ||
                    StrEqual(weapon, "unique_pickaxe") ||
                    StrEqual(weapon, "robot_arm") ||
                    StrEqual(weapon, "sledgehammer") ||
                    StrEqual(weapon, "paintrain") ||
                    StrEqual(weapon, "southern_hospitality") ||
                    StrEqual(weapon, "wrench_golden") ||
                    StrEqual(weapon, "tribalkukri") ||
                    StrEqual(weapon, "battleaxe") ||
                    StrEqual(weapon, "battleneedle") ||
                    StrEqual(weapon, "powerjack") ||
                    StrEqual(weapon, "holy_mackerel") ||
                    StrEqual(weapon, "eternal_reward") ||
                    StrEqual(weapon, "bushwacka") ||
                    StrEqual(weapon, "gloves_running_urgently") ||
                    StrEqual(weapon, "fryingpan") ||
                    StrEqual(weapon, "headtaker") ||
                    StrEqual(weapon, "ullapool_caber") ||
                    StrEqual(weapon, "warrior_spirit") ||
                    StrEqual(weapon, "candy_cane") ||
                    StrEqual(weapon, "boston_basher") ||
                    StrEqual(weapon, "back_scratcher") ||
                    StrEqual(weapon, "claidheamohmor") ||
                    StrEqual(weapon, "wrench_jag") ||
                    StrEqual(weapon, "steel_fists") ||
                    StrEqual(weapon, "lava_axe") ||
                    StrEqual(weapon, "lava_bat") ||
                    StrEqual(weapon, "warfan") ||
                    StrEqual(weapon, "kunai") ||
                    StrEqual(weapon, "demokatana") ||
                    StrEqual(weapon, "shahanshah") ||
                    StrEqual(weapon, "persian_persuader") ||
                    StrEqual(weapon, "solemn_vow") ||
                    StrEqual(weapon, "market_gardener") ||
                    StrEqual(weapon, "saxxy") ||
                    StrEqual(weapon, "eviction_notice") ||
                    StrEqual(weapon, "disciplinary_action") ||
                    StrEqual(weapon, "atomizer") ||
                    StrEqual(weapon, "scout_sword") ||
                    StrEqual(weapon, "mailbox") ||
                    StrEqual(weapon, "big_earner") ||
                    StrEqual(weapon, "the_maul") ||
                    StrEqual(weapon, "nonnonviolent_protest") ||
                    StrEqual(weapon, "nessieclub") ||
                    StrEqual(weapon, "unarmed_combat") ||
                    StrEqual(weapon, "voodoo_pin") ||
                    StrEqual(weapon, "apocofists") ||
                    StrEqual(weapon, "eureka_effect") ||
                    StrEqual(weapon, "thirddegree") ||
                    StrEqual(weapon, "scotland_shard") ||
                    StrEqual(weapon, "sharp_dresser") ||
                    StrEqual(weapon, "wrap_assassin") ||
                    StrEqual(weapon, "spy_cicle") ||
                    StrEqual(weapon, "holiday_punch") ||
                    StrEqual(weapon, "black_rose") ||
                    StrEqual(weapon, "lollichop") ||
                    StrEqual(weapon, "unique_pickaxe_escape") ||
                    StrEqual(weapon, "freedom_staff") ||
                    // Weapon names
                    StrEqual(weapon, "tf_weapon_bat") ||
                    StrEqual(weapon, "tf_weapon_bat_wood") ||
                    StrEqual(weapon, "tf_weapon_bat_fish") ||
                    StrEqual(weapon, "tf_weapon_shovel") ||
                    StrEqual(weapon, "saxxy") ||
                    StrEqual(weapon, "tf_weapon_bat_giftwrap") ||
                    StrEqual(weapon, "tf_weapon_fireaxe") ||
                    StrEqual(weapon, "tf_weapon_sword") ||
                    StrEqual(weapon, "tf_weapon_bottle") ||
                    StrEqual(weapon, "tf_weapon_stickbomb") ||
                    StrEqual(weapon, "tf_weapon_katana") ||
                    StrEqual(weapon, "tf_weapon_fists") ||
                    StrEqual(weapon, "tf_weapon_wrench") ||
                    StrEqual(weapon, "tf_weapon_robot_arm") ||
                    StrEqual(weapon, "tf_weapon_bonesaw") ||
                    StrEqual(weapon, "tf_weapon_club") ||
                    StrEqual(weapon, "tf_weapon_knife")
                );
        }
        case Game_L4D2:
        {
            return StrEqual(weapon, "weapon_melee");
        }
        case Game_CSGO:
        {
            // Revan: Seems only to be weapon_knife (normal knife) and weapon_knifegg (golden knife)
            return (StrContains(weapon,"knife",false) != -1);
        }
    }
    return false;
}

//=========================================
//                 HEALING
//==========================================

/**
 * heals with the limit of (warcraft ) max hp
 * @noreturn
 */
stock bool:War3_HealToMaxHP(client, health)
{
    new maxhp = War3_GetMaxHP(client);
    new currenthp = GetClientHealth(client);
    if(currenthp < maxhp)
    {
        new newhp = GetClientHealth(client) + health;
        if (newhp > maxhp)
        {
            newhp = maxhp;
        }
        return nsEntity_SetHealth(client, newhp);
    }
    
    return false;
}

/**
 * heals with the limit of your specified HP
 * @noreturn
 */
stock bool:War3HealToHP(client, addhp, maximumHP) {
    new currenthp = GetClientHealth(client);
    new newhp = currenthp + addhp;
    if (newhp > maximumHP) 
    {
        newhp = maximumHP;
    }
    
    SetEntityHealth(client, newhp);
    if (currenthp < newhp)
    {
        War3_TFHealingEvent(client, newhp - currenthp);
        return true;
    }
    return false;
}

/**
 * heals to max hp * 1.5 buff in tf2
 * no extra hp in other games 
 * @noreturn
 */
stock bool:War3_HealToBuffHP(client, health)
{
    new maxhp = (War3_GetGame() == Game_TF) ? RoundFloat(float(War3_GetMaxHP(client)) * 1.5) : War3_GetMaxHP(client);
    new currenthp = GetClientHealth(client);
    if(currenthp < maxhp)
    {
        new newhp = GetClientHealth(client) + health;
        if (newhp > maxhp)
        {
            newhp = maxhp;
        }
        
        return nsEntity_SetHealth(client, newhp);
    }
    
    return false;
}


/** 
 * direcly decreases the player's hp by X amount (Not via damage)
 * this health removal is "non lethal"
 */
stock bool:War3_DecreaseHP(client, amount)
{
    new iHealth = GetClientHealth(client)-amount;
    if(iHealth < 1)
    {
        iHealth = 1;
    }
    
    return nsEntity_SetHealth(client, iHealth);
}

// The actual internal setHealth function. Returns if the health has changed
stock bool:nsEntity_SetHealth(entity, health) 
{
    new currenthp = GetEntProp(entity, Prop_Data, "m_iHealth");
    
    if (currenthp == health)
    {
        return false;
    }
    
    SetEntProp(entity, Prop_Data, "m_iHealth", health);
    ChangeEdictState(entity, 0);
    
    if (currenthp < health)
    {
        War3_TFHealingEvent(entity, health - currenthp);
        return true;
    }
    
    return false;
}

/** 
 * Creates a event to show a player in the HUD how much HP he has healed
 */
stock War3_TFHealingEvent(client, amount_healed)
{
    if (War3_GetGame() != Game_TF || !ValidPlayer(client, true) || IsFakeClient(client))
    {
        return;
    }
    
    new Handle:event = CreateEvent("player_healonhit");
    SetEventInt(event, "entindex", client);
    SetEventInt(event, "amount", amount_healed);
    FireEvent(event);
}