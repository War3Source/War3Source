#define PLUGIN_VERSION "1.0.0.4 (8/15/2013)"
/**
 * A NON-TRANSLATED RACE FOR WAR3SOURCE
 * 
 * This is for an example of how to create a custom race reload race.
*/

#pragma semicolon 1
#pragma tabsize 0

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include "sdkhooks"


new thisRaceID;

new Handle:ultCooldownCvar;

new Float:fDecreasedAttackspeed_NonMeleeWeapons = 1.00;

new Float:fSpeedReduction[5]={0.0,0.85,0.80,0.75,0.70};

new Float:fLastStandUber[5]={0.0,1.0,2.0,3.0,4.0};

new Float:fHumanArmor[5]={0.0,1.0,2.0,3.0,4.0};
new Float:fAdvancedHumanArmor[5]={0.0,5.0,6.0,7.0,8.0};
// siege + armor = total armor
new Float:fSiegeArmor[5]={0.0,1.0,2.0,3.0,4.0};

new DevotionHealth[5]={0,30,60,80,100};

new bool:ARMOR_ENABLED[100];
new bool:ARMOR_BUTTON_PRESSED[100];
new ARMOR_TIMER[100];

// Effects
new BeamSprite,HaloSprite;

new SKILL_SIEGE, SKILL_ARMOR, SKILL_ADVANCED_ARMOR, SKILL_HEALTH, ULT_LASTSTAND;

public Plugin:myinfo =
{
    name = "Race - Dwarven Stronghold",
    author = "El Diablo",
    description = "The Dwarven Stronghold race.",
    version = "1.0",
    url = "http://www.war3source.com"
};

public OnPluginStart()
{
    CreateConVar("war3evo_DwarvenStronghold",PLUGIN_VERSION,"War3Source Dwarven Stronghold",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

    ultCooldownCvar=CreateConVar("war3_Dwarven_ultimate_cooldown","30.0","Cooldown between teleports");
    
    // Needed for Custom Race Reload:
    War3_RaceOnPluginStart("dstronghold");
}

// Needed for Custom Race Reload:
public OnPluginEnd()
{
    if(LibraryExists("RaceClass"))
        War3_RaceOnPluginEnd("dstronghold");
}

// Needed for Custom Race Reload:
public OnWar3LoadRaceOrItemOrderedCRR(num,reloadrace_id,String:shortname[])
{
    // Needed for Custom Race Reload:
    if(num==29||(reloadrace_id>0&&StrEqual("dstronghold",shortname,false)))
    {
        // create a "Race trait comment = You do normal damage with seige and half damage without siege"
        // need to create a race trait thingy that allows you to put comments into the race information
        // without having to create a skill.
        thisRaceID=War3_CreateNewRace("Dwarven Stronghold","dstronghold",reloadrace_id);
        SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"Dwarven Aura",
        "Gives you additional 30/60/80/100 health and Increased Magical resistance 1/2/3/4.\n(Only Works in Siege.)",false,4);
        SKILL_ARMOR=War3_AddRaceSkill(thisRaceID,"Dwarven Armor",
        "1-4 physical armor (always) and when maxed it gives 100% Immunity to crits (only during under siege)\nReduces speed down to 85%/80%/75%/70% (always)",false,4);
        SKILL_SIEGE=War3_AddRaceSkill(thisRaceID,"Siege",
        "You can not move and you do 75% damage while in Siege mode.\nYou Obtain 1-4 Addition Armor and Magical Resistance.\nSlight Health Regeneration(+ability)\nWhile not Siege mode you do 50% damage.",false,4);
        SKILL_ADVANCED_ARMOR=War3_AddRaceSkill(thisRaceID,"Advanced Siege",
        "1-4 additional physical Armor.(Added to Siege Mode Only)",false,4);
        ULT_LASTSTAND=War3_AddRaceSkill(thisRaceID,"Last Stand",
        "Gives Uber and 25% more Attack power to self for 1/2/3/4 seconds.\n(Must be in siege mode)",true,4);
        W3SkillCooldownOnSpawn(thisRaceID,ULT_LASTSTAND,10.0,_);
        War3_CreateRaceEnd(thisRaceID);
        
        // Make Sure this is after War3_CreateRaceEnd and nothing but AddRaceSkill* is before it.
        War3_SetDependency(thisRaceID, SKILL_ADVANCED_ARMOR, SKILL_SIEGE, 4);
    }
}

public OnClientPutInServer(client){
    SDKHook(client,SDKHook_WeaponSwitchPost,SDK_OnWeaponSwitch);
}

public OnClientDisconnect(client){
    SDKUnhook(client,SDKHook_WeaponSwitchPost,SDK_OnWeaponSwitch);
}

public SDK_OnWeaponSwitch(client, weapon)
{
    if (ValidPlayer(client))
    {
        if(War3_GetRace(client)==thisRaceID)
        {
            if(IsValidEdict(weapon))
            {
                decl String:weaponName[128];
                GetEdictClassname(weapon, weaponName, sizeof(weaponName));
                if(W3IsDamageFromMelee(weaponName))
                {
                    War3_SetBuff(client,fAttackSpeed,thisRaceID,1.20);
                }
                else
                {
                    War3_SetBuff(client,fAttackSpeed,thisRaceID,fDecreasedAttackspeed_NonMeleeWeapons);
                }
            }
            else
            {
                War3_SetBuff(client,fAttackSpeed,thisRaceID,fDecreasedAttackspeed_NonMeleeWeapons);
            }
        }
    }
}

public OnMapStart()
{
    BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
    HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
    
    //War3_PrecacheSound(transform_sound);
    for(new i;i<100;i++)
    {
     ARMOR_TIMER[i]=0;
     ARMOR_ENABLED[i]=false;
     ARMOR_BUTTON_PRESSED[i]=false;
    }
}

public OnRaceChanged(client,oldrace,newrace)
{
    if(newrace!=thisRaceID)
    {
        War3_SetBuff(client,fHPRegen,thisRaceID,0.0);
        War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0); // if we aren't their race anymore we shouldn't be controlling their alpha
        War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
        War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
        War3_SetBuff(client,fArmorMagic,thisRaceID,0.0);
        War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
        War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
        War3_SetBuff(client,fSlow,thisRaceID,1.0);
        War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
        War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
        ARMOR_ENABLED[client]=false;
        ARMOR_BUTTON_PRESSED[client]=false;
        ARMOR_TIMER[client]=0;
    }
    else
    {
        ActivateSkills(client);
        
    }
}

    
public ActivateSkills(client)
{
    // Physical Armor
    new skill_armor=War3_GetSkillLevel(client,thisRaceID,SKILL_ARMOR);
    if(skill_armor>0)
    {
        War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
        War3_SetBuff(client,fSlow,thisRaceID,fSpeedReduction[skill_armor]);
    }
    new Float:humanarmor=fHumanArmor[skill_armor];
    War3_SetBuff(client,fArmorPhysical,thisRaceID,humanarmor);
}
public OnUltimateCommand(client,race,bool:pressed)
{
    new userid=GetClientUserId(client);
    if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) && !Silenced(client))
    {
        new ult_level=War3_GetSkillLevel(client,race,ULT_LASTSTAND);
        if(ult_level>0)
        {
            
            if(War3_SkillNotInCooldown(client,thisRaceID,ULT_LASTSTAND,true)) //not in the 0.2 second delay when we check stuck via moving
            {
    // LAST STAND
    // Gives Uber and 25% more Attack power to self for 2/4/6/8 seconds
    // Must be in siege mode
    if(ARMOR_ENABLED[client])
    {
        // is in siege mode
        TF2_AddCondition(client,TFCond_Ubercharged,fLastStandUber[ult_level]);
        War3_SetBuff(client,fAttackSpeed,thisRaceID,1.25);
        CreateTimer(fLastStandUber[ult_level],Timer_Disable_Ultimate,GetClientUserId(client));
        new Float:cooldown=GetConVarFloat(ultCooldownCvar);
        War3_CooldownMGR(client,cooldown,thisRaceID,ULT_LASTSTAND,_,_);
    }
    else
    {
        W3Hint(client,HINT_SKILL_STATUS,4.0,"Must be Siege Mode");
    }
            }
        }
        else
        {
            W3MsgUltNotLeveled(client);
            
        }
    }
}

public Action:Timer_Disable_Ultimate(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    War3_SetBuff(client,fAttackSpeed,thisRaceID,fDecreasedAttackspeed_NonMeleeWeapons);
}


public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    if(race==thisRaceID)
    {
        ActivateSkills(client); //on a race change, this is called 4 times, but that performance hit is insignificant
    }
}

public OnWar3EventSpawn(client){
    if(War3_GetRace(client)==thisRaceID && ARMOR_ENABLED[client])
    {
        War3_SetBuff(client,fHPRegen,thisRaceID,0.0);
        War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
        War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
        W3Hint(client,HINT_SKILL_STATUS,1.0,"Siege Disabled!");
        ARMOR_ENABLED[client]=false;
        ARMOR_BUTTON_PRESSED[client]=false;
        ActivateSkills(client);
    }
/*  else if(ARMOR_ENABLED)
    {
        War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
        War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
        W3Hint(client,HINT_SKILL_STATUS,1.0,"Siege Disabled! (You changed race)");
        ARMOR_ENABLED=false;
        ARMOR_BUTTON_PRESSED=false;
    }*/
}

/* ***************************  ability *************************************/

public OnAbilityCommand(client,ability,bool:pressed)
{
    new skilllevelz = War3_GetSkillLevel(client,thisRaceID,SKILL_SIEGE);
    if(skilllevelz>0 && War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
    {
       if(ARMOR_ENABLED[client]==true && !ARMOR_BUTTON_PRESSED[client])
       {
         // disabled
         W3Hint(client,HINT_SKILL_STATUS,1.0,"Siege Disabling...");
         CreateTimer(1.0,Timer_Disable_Siege,client);
         ARMOR_BUTTON_PRESSED[client]=true;
       }
       else if(ARMOR_ENABLED[client]==false && !ARMOR_BUTTON_PRESSED[client])
       {
         // enabled
          CreateTimer(1.0,Timer_Enable_Siege,client);
          W3Hint(client,HINT_SKILL_STATUS,1.0,"Siege Enabling...");
          ARMOR_BUTTON_PRESSED[client]=true;
       }
    }

}

public Action:Timer_Enable_Siege(Handle:timer, any:client)
{
    ARMOR_TIMER[client]++;
    if(ARMOR_TIMER[client]>=3)
    {
            // Devotion Aura
        new skill_devo=War3_GetSkillLevel(client,thisRaceID,SKILL_HEALTH);
        new Float:magichumanarmor=fHumanArmor[skill_devo];
        if(skill_devo>0)
        {
            // Magical Armor increase for Devotion Aura
            magichumanarmor=fHumanArmor[skill_devo];

            new hpadd=DevotionHealth[skill_devo];
            new Float:vec[3];
            GetClientAbsOrigin(client,vec);
            vec[2]+=20.0;
            new ringColor[4]={0,0,0,0};
            new team=GetClientTeam(client);
            if(team==2)
            {
              ringColor={255,0,0,255};
            }
            else if(team==3)
            {
              ringColor={0,0,255,255};
            }
            TE_SetupBeamRingPoint(vec,40.0,10.0,BeamSprite,HaloSprite,0,15,1.0,15.0,0.0,ringColor,10,0);
            TE_SendToAll();

            War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,hpadd);
        }

        new skilllevel_siege_Armor=War3_GetSkillLevel(client,thisRaceID,SKILL_SIEGE);
        new Float:siegehumanarmor=fSiegeArmor[skilllevel_siege_Armor];
        // Physical Armor
        War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);

        // Magical Armor Buff
        magichumanarmor =  magichumanarmor + siegehumanarmor;
        War3_SetBuff(client,fArmorMagic,thisRaceID,magichumanarmor);

        new skill_armor=War3_GetSkillLevel(client,thisRaceID,SKILL_ARMOR);
        // Check for Immunity to crits at max level
        if(skill_armor>=4)
        {
            TF2_AddCondition(client,TFCond_DefenseBuffed,9999.0);
        }

        new skill_advanced_armor=War3_GetSkillLevel(client,thisRaceID,SKILL_ADVANCED_ARMOR);
        if(skilllevel_siege_Armor>=4 && skill_advanced_armor>0)
        {
            new Float:advancedhumanarmor=fAdvancedHumanArmor[skill_advanced_armor] + siegehumanarmor;
            War3_SetBuff(client,fArmorPhysical,thisRaceID,advancedhumanarmor);
        }
        else
        {
            new Float:humanarmor=fHumanArmor[skill_armor] + siegehumanarmor;
            War3_SetBuff(client,fArmorPhysical,thisRaceID,humanarmor);
        }

        War3_SetBuff(client,fHPRegen,thisRaceID,siegehumanarmor);
        War3_SetBuff(client,bNoMoveMode,thisRaceID,true);
        W3Hint(client,HINT_SKILL_STATUS,1.0,"Siege Enabled!");
        ARMOR_ENABLED[client]=true;
        ARMOR_BUTTON_PRESSED[client]=false;
        ARMOR_TIMER[client]=0;
    }
    else
    {
        new p=(3-ARMOR_TIMER[client]);
        CreateTimer(1.0,Timer_Enable_Siege,client);
        W3Hint(client,HINT_SKILL_STATUS,1.0,"Enabling Siege in %i",p);
    }
}

public Action:Timer_Disable_Siege(Handle:timer, any:client)
{
  ARMOR_TIMER[client]++;
  if(ARMOR_TIMER[client]>=3)
    {
    TF2_RemoveCondition(client,TFCond_Ubercharged);
    TF2_RemoveCondition(client,TFCond_DefenseBuffed);
    War3_SetBuff(client,fArmorMagic,thisRaceID,0.0);
    War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
    War3_SetBuff(client,fHPRegen,thisRaceID,0.0);
    War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
    War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
    W3Hint(client,HINT_SKILL_STATUS,1.0,"Siege Disabled!");
    ActivateSkills(client);
    ARMOR_ENABLED[client]=false;
    ARMOR_BUTTON_PRESSED[client]=false;
    ARMOR_TIMER[client]=0;
    }
    else
    {
    new p=(3-ARMOR_TIMER[client]);
    CreateTimer(1.0,Timer_Disable_Siege,client);
    W3Hint(client,HINT_SKILL_STATUS,1.0,"Disabling Siege in %i",p);
    }
}



public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
if(War3_GetRace(attacker)==thisRaceID)
    {
        if(ARMOR_ENABLED[attacker])
        {
            War3_DamageModPercent(0.50);
        }
        else
        {
            War3_DamageModPercent(0.75);
        }
    }
}

