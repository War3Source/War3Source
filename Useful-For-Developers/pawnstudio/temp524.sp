/**
 * vim: set ai et ts=4 sw=4 :
 * File: War3Source_Headcrab.sp
 * Description: The HeadCrab race for War3Source.
 * Author(s): Vladislav Dolgov
 */

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks> 

#include <sdkhooks>

new thisRaceID;

new SKILL_LONGJUMP,SKILL_FANGS,SKILL_FOURLEGS,SKILL_LATCH;
new MyWeaponsOffset;

//skill 3
new const FangsInitialDamage=20;
new const FangsTrailingDamage=5;
new Float:FangsChanceArr[]={0.0,0.05,0.1,0.15,0.2};
new FangsTimes[]={0,2,3,4,5};
new BeingFangedBy[66];
new FangsRemaining[66];

//latch
new bool:bround[66];
new BeingLatchedBy[66];
// Target getting killed
new LatchKilled[66];
new Float:LatchChanceArr[]={0.0,0.14,0.16,0.18,0.20};
new Float:LatchonDamageMin[]={0.0,3.0,4.0,5.0,6.0};
new Float:LatchonDamageMax[]={0.0,7.0,8.0,9.0,10.0};

new String:Fangsstr[]={"npc/roller/mine/rmine_blades_out2.wav"};

new g_GameType;

public Plugin:myinfo = 
{
	name = "War3Source Race - Headcrab",
	author = "[Oddity]TeacerCreature",
	description = "Headcrab race for War3Source.",
	version = "1.0.0",
	url = "http://warcraft-source.net/"
};

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==130)
	{
	thisRaceID=War3_CreateNewRace("Headcrab", "headcrab");
	SKILL_LONGJUMP=War3_AddRaceSkill(thisRaceID,"Power legs", "Long jump.",false,4);
	SKILL_FOURLEGS=War3_AddRaceSkill(thisRaceID,"Four legs", "Low gravity.",false,4);
	SKILL_FANGS=War3_AddRaceSkill(thisRaceID,"Fangs", "Poison damage over time",false,4);
	SKILL_LATCH=War3_AddRaceSkill(thisRaceID,"Latch On", "Latch on to killer and respawn",false,4);
	War3_CreateRaceEnd(thisRaceID);
	}
}

public OnPluginStart()
{
	g_GameType = War3_GetGame();
	HookEvent("round_start",RoundStartEvent);
	//HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_jump", Event_PlayerJump);
	MyWeaponsOffset=FindSendPropOffs("CBaseCombatCharacter","m_hMyWeapons");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("SDKHook");
	MarkNativeAsOptional("SDKUnhook");
	return APLRes_Success;
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{
		bround[i]=false;
	}
}

public OnClientPutInServer(client)
{
	//SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponCanUse2);
	SDKHook(client, SDKHook_WeaponSwitch,SDKFWDWeaponSwitch);
}

public Action:OnWeaponCanUse(client, weapon)
{
	PrintToChatAll("OnWeaponCanUse");
	if (War3_GetRace(client)== thisRaceID)
	{
		new String:name[64];
		GetEdictClassname(weapon, name, 64);
		
		PrintToChatAll("weapon: %s",name);
		//if(StrEqual(name, "weapon_knife", false))
		if (IsEquipmentMelee(name))
     	 		return Plugin_Continue;
     	 	return Plugin_Handled;
	}

	return Plugin_Continue;
}
public Action:OnWeaponCanUse2(client, weapon)
{
	PrintToChatAll("OnWeaponCanUse2");
	if (War3_GetRace(client)== thisRaceID)
	{
		new String:name[64];
		GetEdictClassname(weapon, name, 64);
		
		PrintToChatAll("weapon: %s",name);
		//if(StrEqual(name, "weapon_knife", false))
		if (IsEquipmentMelee(name))
     	 		return Plugin_Continue;
     	 	return Plugin_Handled;
	}

	return Plugin_Continue;
}
public Action:SDKFWDWeaponSwitch(client, weapon)
{
	PrintToChatAll("SDKFWDWeaponSwitch");
	if (War3_GetRace(client)== thisRaceID)
	{
		new String:name[64];
		GetEdictClassname(weapon, name, 64);
		
		PrintToChatAll("weapon: %s",name);
		//if(StrEqual(name, "weapon_knife", false))
		if (IsEquipmentMelee(name))
     	 		return Plugin_Continue;
     	 	return Plugin_Handled;
	}

	return Plugin_Continue;
}


public SetWeaponColor(client,r,g,b,o) 
{ 
    new entity = GetPlayerWeaponSlot(client,2); 
    if(entity>0) 
	{ 
		SetEntityRenderMode(entity,RENDER_TRANSCOLOR); 
		SetEntityRenderColor(entity,r,g,b,o); 
	}   
} 

public OnMapStart()
{
	PrecacheModel("models/headcrab.mdl", true);
	PrecacheModel("models/headcrabblack.mdl", true);
	War3_PrecacheSound(Fangsstr);
}

public OnWar3EventSpawn(client)
{
	new race = War3_GetRace(client);
	if (race == thisRaceID)
	{  
		War3_SetMaxHP(client,War3_GetMaxHP(client)-50);
		SetEntityHealth(client, 50); 
		if(GetClientTeam(client) == 3){
			SetEntityModel(client, "models/headcrab.mdl");
		}
		else{
			SetEntityModel(client, "models/headcrabblack.mdl");
		}
		SetWeaponColor(client,0,0,0,0);
		new skill3_fourlegs = War3_GetSkillLevel(client, race, SKILL_FOURLEGS);
		new Float:gravity = 1.00;
		switch (skill3_fourlegs)
		{
			case 0:
				gravity = 1.00;
			case 1:
				gravity = 0.90;
			case 2:
				gravity = 0.80;
			case 3:
				gravity = 0.70;
			case 4:
				gravity = 0.60;
		}
		War3_SetBuff(client,fLowGravitySkill,thisRaceID,gravity);	
	}
}

public OnSkillLevelChanged(client, race, skill, newskilllevel)
{
    if (client > 0)
    {
        if (race == thisRaceID && skill == 1)
        {
            new Float:gravity = 1.00;
            switch (newskilllevel)
            {
                case 0:
                    gravity = 1.00;
                case 1:
                    gravity = 0.90;
                case 2:
                    gravity = 0.80;
                case 3:
                    gravity = 0.70;
                case 4:
                    gravity = 0.60;
            }
            War3_SetBuff(client,fLowGravitySkill,thisRaceID,gravity);	
        }
    }
}

public OnRaceSelected(client,  newrace)
{
    if(newrace != thisRaceID)
    {
        //SetEntityHealth(client, 100);
        War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.0);	
    }
}

public Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event,"userid"));
    if (client > 0)
    {
        new race = War3_GetRace(client);
        if (race == thisRaceID)
        {
            new skill2_longjump = War3_GetSkillLevel(client, race, SKILL_LONGJUMP);
            new Float:long_push = 1.00;
            switch (skill2_longjump)
            {
                case 0:
                    long_push = 1.10;
                case 1:
                    long_push = 1.15;
                case 2:
                    long_push = 1.20;
                case 3:
                    long_push = 1.25;
                case 4:
                    long_push = 1.30;
            }

            if (skill2_longjump > 0)
            {
                new v_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
                new v_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
                new v_b = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
                new Float:finalvec[3];
                finalvec[0] = GetEntDataFloat(client, v_0) * long_push / 2.0;
                finalvec[1] = GetEntDataFloat(client, v_1) * long_push / 2.0;
                finalvec[2] = long_push * 50.0;
                SetEntDataVector(client, v_b, finalvec, true);
            }
        }
    }
}

public Action:OnWar3TakeDamage(victim,attacker,inflictor,Float:damage,damagetype)
{
	if(War3_ValidPlayer(attacker,true)&&War3_ValidPlayer(victim,true)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{

		//ATTACKER IS headcrab
		if(War3_GetRace(attacker)==thisRaceID)
		{
			//fangs poison
			new Float:chance_mod=War3_ChanceModifier(attacker,inflictor,damagetype);
			/// CHANCE MOD BY VICTIM
			new skill_level = War3_GetSkillLevel(attacker,thisRaceID,SKILL_FANGS);
			if(skill_level>0 && FangsRemaining[victim]==0 && GetRandomFloat(0.0,1.0)<=chance_mod*FangsChanceArr[skill_level])
			{
				if(War3_GetImmunity(victim,Immunity_Skills))
				{
					PrintHintText(victim,"Immunity to Fangs");
					PrintHintText(attacker,"Fangs Immunity");
				}
				else
				{
					PrintHintText(victim,"You got bitten by enemy with Fangs");
					PrintHintText(attacker,"You bit your enemy with Fangs");
					BeingFangedBy[victim]=attacker;
					FangsRemaining[victim]=FangsTimes[skill_level];
					War3_DealDamage(victim,FangsInitialDamage,attacker,DMG_BULLET,"fangs");
					War3_FlashScreen(victim,RGBA_COLOR_RED);
					
					EmitSoundToAll(Fangsstr,attacker);
					EmitSoundToAll(Fangsstr,victim);
					CreateTimer(1.0,FangsLoop,victim);
				}
			}
		}
	}
}

public OnWar3EventDeath(victim,attacker)
{
	if(War3_ValidPlayer(victim)&&War3_ValidPlayer(attacker))
	{
		new race = War3_GetRace(victim);
		decl skilllevel;
		if(race==thisRaceID)
		{
			skilllevel=War3_GetSkillLevel(victim,thisRaceID,SKILL_LATCH);
			//do a chance here
			if(skilllevel>0&&GetRandomFloat(0.0,1.0)<=LatchChanceArr[skilllevel]&&!War3_GetImmunity(attacker,Immunity_Skills))
			{
				BeingLatchedBy[attacker]=victim;
				PrintHintText(attacker,"You are being latched on by headcrab");
				PrintHintText(victim,"Latched on to your killer");
				EmitSoundToAll(Fangsstr,attacker);
				EmitSoundToAll(Fangsstr,victim);
				CreateTimer(2.0,LatchDamageLoop,attacker);
				bround[victim]=true;
			}
		}
		
		//person who was latched diedright
		new headcrabperson=BeingLatchedBy[victim];
		
		if(War3_ValidPlayer( headcrabperson ))
		{
			if(War3_GetRace(headcrabperson)==thisRaceID && !IsPlayerAlive(headcrabperson))
			{
				War3_ChatMessage( headcrabperson , "Your killer died, you get to respawn");
				LatchKilled[headcrabperson]=victim;
				CreateTimer(0.2,RespawnPlayer,headcrabperson);
			}
			BeingLatchedBy[victim]=0;
		}
	}
}


public Action:LatchDamageLoop(Handle:timer,any:client)
{
	if(War3_ValidPlayer(client,true)&&War3_ValidPlayer(BeingLatchedBy[client])&&bround[client]==true)
	{
		
		decl skilllevel;
		//get level
		skilllevel=War3_GetSkillLevel(BeingLatchedBy[client],thisRaceID,SKILL_LATCH);
		War3_DealDamage(client,RoundFloat(GetRandomFloat(LatchonDamageMin[skilllevel],LatchonDamageMax[skilllevel])),BeingLatchedBy[client],DMG_BULLET,"latch_on");
		War3_FlashScreen(client,RGBA_COLOR_RED);
		// Can I array the timer with a random 2 - 4 seconds between 
		//you can replace 3.0 with an array
		//GetRandomFloat(2.0,4.0)
		CreateTimer(1.5,LatchDamageLoop,client);
	}
}

public Action:FangsLoop(Handle:timer,any:victim)
{
	if(FangsRemaining[victim]>0 && War3_ValidPlayer(BeingFangedBy[victim]) && War3_ValidPlayer(victim,true))
	{
		War3_DealDamage(victim,FangsTrailingDamage,BeingFangedBy[victim],DMG_BULLET,"fangs");
		FangsRemaining[victim]--;
		War3_FlashScreen(victim,RGBA_COLOR_RED);
		CreateTimer(1.0,FangsLoop,victim);
	}
}

public Action:RespawnPlayer(Handle:timer,any:client)
{
	if(client>0&&!IsPlayerAlive(client)&&War3_ValidPlayer(LatchKilled[client]))
	{
		War3_SpawnPlayer(client);
		new Float:pos[3];
		new Float:ang[3];
		War3_CachedAngle(LatchKilled[client],ang);
		War3_CachedPosition(LatchKilled[client],pos);
		TeleportEntity(client,pos,ang,NULL_VECTOR);
		// cool, now remove their weapons EXCEPT knife and c4 
		for(new s=0;s<10;s++)
		{
			new ent=GetEntDataEnt2(client,MyWeaponsOffset+(s*4));
			if(ent>0 && IsValidEdict(ent))
			{
				new String:ename[64];
				GetEdictClassname(ent,ename,64);
				if(StrEqual(ename,"weapon_c4") || StrEqual(ename,"weapon_knife"))
				{
					continue; // don't think we need to delete these
				}
				UTIL_Remove(ent);
			}
		}	
	}
}

/**
 * Weapons related functions.
 */
#tryinclude <sc/weapons>
#if !defined _weapons_included
    stock bool:IsEquipmentMelee(const String:weapon[])
    {
        switch (g_GameType)
        {
            case Game_CS:
            {
                return (StrEqual(weapon,"weapon_c4") ||
						StrEqual(weapon,"weapon_knife"));
            }
            case Game_DOD:
            {
                return (StrEqual(weapon,"weapon_amerknife") ||
                        StrEqual(weapon,"weapon_spade"));
            }
            case Game_TF:
            {
                return (StrEqual(weapon,"tf_weapon_knife") ||
                        StrEqual(weapon,"tf_weapon_shovel") ||
                        StrEqual(weapon,"tf_weapon_wrench") ||
                        StrEqual(weapon,"tf_weapon_bat") ||
                        StrEqual(weapon,"tf_weapon_bat_wood") ||
                        StrEqual(weapon,"tf_weapon_bonesaw") ||
                        StrEqual(weapon,"tf_weapon_bottle") ||
                        StrEqual(weapon,"tf_weapon_club") ||
                        StrEqual(weapon,"tf_weapon_fireaxe") ||
                        StrEqual(weapon,"tf_weapon_fists") ||
                        StrEqual(weapon,"tf_weapon_sword"));
            }
        }
        return false;
    }
#endif