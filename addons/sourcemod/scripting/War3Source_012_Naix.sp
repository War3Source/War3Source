#include <sourcemod>
#include <sdktools_functions>    //For teleport
#include <sdktools_sound>        //For sound effect
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Race - Naix",
    author = "War3Source Team",
    description = "The Naix Mage race for War3Source."
};

// Colors
#define COLOR_DEFAULT 0x01
#define COLOR_LIGHTGREEN 0x03
#define COLOR_GREEN 0x04 // DOD = Red //kinda already defiend in war3 interface

//Skills Settings
 
new Float:HPPercentHealPerKill[5] = { 0.0,0.05,  0.10,  0.15,  0.20 }; //SKILL_INFEST settings
//Skill 1_1 really has 5 settings, so it's not a mistake
new HPIncrease[5]       = { 0, 10, 20, 30, 40 };     //Increases Maximum health

new Float:feastPercent[5] = { 0.0, 0.04,  0.06,  0.08,  0.10 };   //Feast ratio (leech based on current victim hp


new Float:RageAttackSpeed[5] = {1.0, 1.15,  1.25,  1.3334,  1.4001 };   //Rage Attack Rate
new Float:RageDuration[5] = {0.0, 3.0,  4.0,   5.0,  6.0 };   //Rage duration

new bool:bDucking[MAXPLAYERSCUSTOM];
//End of skill Settings

new Handle:ultCooldownCvar;

new thisRaceID, SKILL_INFEST, SKILL_BLOODBATH, SKILL_FEAST, ULT_RAGE;

new bool:RaceDisabled=true;
public OnWar3RaceEnabled(newrace)
{
    if(newrace==thisRaceID)
    {
        RaceDisabled=false;
    }
}
public OnWar3RaceDisabled(oldrace)
{
    if(oldrace==thisRaceID)
    {
        RaceDisabled=true;
    }
}

new String:skill1snd[256]; //="war3source/naix/predskill1.mp3";
new String:ultsnd[256]; //="war3source/naix/predult.mp3";

public OnPluginStart()
{
    ultCooldownCvar=CreateConVar("war3_naix_ult_cooldown","20","Cooldown time for Rage.");
    
    LoadTranslations("w3s.race.naix.phrases.txt");
}
public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==120)
    {
        thisRaceID=War3_CreateNewRaceT("naix");


        SKILL_INFEST = War3_AddRaceSkillT(thisRaceID, "Infest", false,4,"5-20%");
        SKILL_BLOODBATH = War3_AddRaceSkillT(thisRaceID, "BloodBath", false,4,"10-40");
        SKILL_FEAST = War3_AddRaceSkillT(thisRaceID, "Feast", false,4,"4-10%");
        ULT_RAGE = War3_AddRaceSkillT(thisRaceID, "Rage", true,4,"15-40%","3-6");
        
        War3_CreateRaceEnd(thisRaceID);
    }
}

stock bool:IsOurRace(client) {
    if(RaceDisabled)
    {
        return false;
    }

    return (War3_GetRace(client)==thisRaceID);
}


public OnMapStart() 
{ 
    War3_AddSoundFolder(skill1snd, sizeof(skill1snd), "naix/predskill1.mp3");
    War3_AddSoundFolder(ultsnd, sizeof(ultsnd), "naix/predult.mp3");

    War3_AddCustomSound(skill1snd);
    War3_AddCustomSound(ultsnd);
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(RaceDisabled)
    {
        return;
    }

    if(ValidPlayer(victim)&&W3Chance(W3ChanceModifier(attacker))&&ValidPlayer(attacker)&&IsOurRace(attacker)&&victim!=attacker&&GetClientTeam(attacker)!=GetClientTeam(victim)){
        new level = War3_GetSkillLevel(attacker, thisRaceID, SKILL_FEAST);
        if(level>0&&!Hexed(attacker,false)&&W3Chance(W3ChanceModifier(attacker))){
            if(!W3HasImmunity(victim,Immunity_Skills)){    
                new targetHp = GetClientHealth(victim)+ RoundToFloor(damage);
                new restore = RoundToNearest( float(targetHp) * feastPercent[level] );

                War3HealToHP(attacker,restore,War3_GetMaxHP(attacker)+HPIncrease[War3_GetSkillLevel(attacker,thisRaceID,SKILL_BLOODBATH)]);
            
                PrintToConsole(attacker,"%T","Feast +{amount} HP",attacker,restore);
            }
        }
    }
}
public OnWar3EventSpawn(client){
    if(RaceDisabled)
    {
        return;
    }

    if(IsOurRace(client)){
        new level = War3_GetSkillLevel(client, thisRaceID, SKILL_BLOODBATH);
        if(level>=0){ //zeroth level passive
            //War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,HPIncrease[level]);
            
            //War3_SetMaxHP(client, War3_GetMaxHP(client) + );
            War3_ChatMessage(client,"%T","Your Maximum HP Increased by {amount}",client,HPIncrease[level]);    
        }
    }
}
/*
public OnRaceChanged(client,oldrace,newrace)
{
    if(oldrace==thisRaceID){
        War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
    }

}*/
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(RaceDisabled)
    {
        return Plugin_Continue;
    }

    
    bDucking[client]=(buttons & IN_DUCK)?true:false;
    return Plugin_Continue;
}
//new Float:teleportTo[66][3];
public OnWar3EventDeath(victim,attacker){
    if(RaceDisabled)
    {
        return;
    }

    if(ValidPlayer(victim)&&ValidPlayer(attacker)&&IsOurRace(attacker)){
        new iSkillLevel=War3_GetSkillLevel(attacker,thisRaceID,SKILL_INFEST);
        if (iSkillLevel>0)
        {
            
            if (Hexed(attacker,false))  
            {    
                //decl String:name[50];
                //GetClientName(victim, name, sizeof(name));
                PrintHintText(attacker,"%T","Could not infest, you are hexed",attacker);
            }
            else if (W3HasImmunity(victim,Immunity_Skills))  
            {    
                //decl String:name[50];
                //GetClientName(victim, name, sizeof(name));
                PrintHintText(attacker,"%T","Could not infest, enemy immunity",attacker);
            }
            else{
                
                
                if(bDucking[attacker]){
                    decl Float:location[3];
                    GetClientAbsOrigin(victim,location);
                    //.PrintToChatAll("%f %f %f",teleportTo[attacker][0],teleportTo[attacker][1],teleportTo[attacker][2]);
                    War3_CachedPosition(victim,location);
                    //PrintToChatAll("%f %f %f",teleportTo[attacker][0],teleportTo[attacker][1],teleportTo[attacker][2]);
                    
                    
                    //CreateTimer(0.1,setlocation,attacker);
                    
                    TeleportEntity(attacker, location, NULL_VECTOR, NULL_VECTOR);
                }
                
                new addHealth = RoundFloat(FloatMul(float(War3_GetMaxHP(victim)),HPPercentHealPerKill[iSkillLevel]));
                
                War3HealToHP(attacker,addHealth,War3_GetMaxHP(attacker)+HPIncrease[War3_GetSkillLevel(attacker,thisRaceID,SKILL_BLOODBATH)]);
                //Effects?
                //EmitAmbientSound("npc/zombie/zombie_pain2.wav",location);
                W3EmitSoundToAll(skill1snd,attacker);
            }
        }
    }
}
/*
public Action:setlocation(Handle:t,any:attacker){
    TeleportEntity(attacker, teleportTo[attacker], NULL_VECTOR, NULL_VECTOR);
}*/

public OnUltimateCommand(client,race,bool:pressed)
{
    if(RaceDisabled)
    {
        return;
    }

    if(race==thisRaceID && pressed && ValidPlayer(client,true))
    {
        new ultLevel=War3_GetSkillLevel(client,thisRaceID,ULT_RAGE);
        if(ultLevel>0)
        {    
            //PrintToChatAll("level %d %f %f",ultLevel,RageDuration[ultLevel],RageAttackSpeed[ultLevel]);
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_RAGE,true ))
            {
                War3_ChatMessage(client,"%T","You rage for {amount} seconds, {amount} percent attack speed",client,
                COLOR_LIGHTGREEN, 
                RageDuration[ultLevel],
                COLOR_DEFAULT, 
                COLOR_LIGHTGREEN, 
                (RageAttackSpeed[ultLevel]-1.0)*100.0 ,
                COLOR_DEFAULT
                );

                War3_SetBuff(client,fAttackSpeed,thisRaceID,RageAttackSpeed[ultLevel]);
                
                CreateTimer(RageDuration[ultLevel],stopRage,client);
                W3EmitSoundToAll(ultsnd,client);
                W3EmitSoundToAll(ultsnd,client);
                War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_RAGE,_,_);
                
            }
            
            
        }
        else{
            PrintHintText(client,"%T","No Ultimate Leveled",client);
        }

    }
}
public Action:stopRage(Handle:t,any:client){
    if(RaceDisabled)
    {
        return;
    }

    War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
    if(ValidPlayer(client,true)){
        PrintHintText(client,"%T","You are no longer in rage mode",client);
    }
}
