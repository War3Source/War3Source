/**
* File: War3Source_Terran_Space_Marine.sp
* Description: The Terran Space Marine race for SourceCraft.
* Author(s): xDr.HaaaaaaaXx
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_tempents_stocks>
#include <sdktools_entinput>
#include <sdktools_sound>
#include "W3SIncs/War3Source_Interface"

// War3Source stuff
new thisRaceID;

// Chance/Data Arrays
new Float:M4A1Chance[6] = { 0.0, 0.2, 0.4, 0.6, 0.8, 1.0 };
new Float:DamageMultiplier[6] = { 0.0, 0.2, 0.4, 0.6, 0.8, 1.0 };
new Float:StimAttackSpeed[6] = { 1.0, 1.1, 1.2, 1.3, 1.4, 1.5 };
new Float:StimSpeed[6] = { 1.0, 1.1, 1.2, 1.3, 1.4, 1.5 };
new Health[6] = { 100, 110, 120, 130, 140, 150 };
new HealthGain[6] = { 0, 5, 10, 15, 20, 25 };
new HaloSprite, BeamSprite;
new bool:bAmmo[MAXPLAYERS];
new Clip1Offset;

new SKILL_M4A1, SKILL_HP, SKILL_DMG, ULT_STIM;

public Plugin:myinfo = 
{
	name = "War3Source Race - Terran Space Marine",
	author = "xDr.HaaaaaaaXx",
	description = "Terran Space Marine race for War3Source.",
	version = "1.0.0.0",
	url = ""
};

public OnMapStart()
{
	HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
	BeamSprite = PrecacheModel( "materials/sprites/lgtning.vmt" );
	HookEvent( "weapon_reload", WeaponReloadEvent );
}

public OnPluginStart()
{
	Clip1Offset = FindSendPropOffs( "CBaseCombatWeapon", "m_iClip1" );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Terran Space Marine", "tsm" );
	
	SKILL_M4A1 = War3_AddRaceSkill( thisRaceID, "Machine Gun", "A chance to create a M4A1.", false, 5 );	
	SKILL_HP = War3_AddRaceSkill( thisRaceID, "Discipline", "You get a bit more HP.", false, 5 );	
	SKILL_DMG = War3_AddRaceSkill( thisRaceID, "Weapon Upgrade", "You can do more dmg to enemy.", false, 5 );
	ULT_STIM = War3_AddRaceSkill( thisRaceID, "Stim Pack", "You can heal your self a bit.", true, 5 );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_STIM, 15.0, _ );
	
	War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		new hp_level = War3_GetSkillLevel( client, thisRaceID, SKILL_HP );
		if( hp_level > 0 )
		{
			War3_SetMaxHP_INTERNAL( client, Health[hp_level] );
		}
		if( War3_GetMaxHP( client ) > GetClientHealth( client ) )
		{
			War3_HealToMaxHP( client, ( War3_GetMaxHP( client ) - GetClientHealth( client ) ) );
		}
		War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
		War3_SetBuff( client, fAttackSpeed, thisRaceID, 1.0 );
		
		new skill_m4a1 = War3_GetSkillLevel( client, thisRaceID, SKILL_M4A1 );
		if( skill_m4a1 > 0 && GetRandomFloat( 0.0, 1.0 ) <= M4A1Chance[skill_m4a1] )
		{
			GivePlayerItem( client, "weapon_m4a1" );
			CreateTimer( 1.0, SetWepAmmo, client );
			bAmmo[client] = true;
		}
	}
}

public OnRaceChanged( client, oldrace, newrace )
{
	if( newrace == thisRaceID )
	{
		if( IsPlayerAlive( client ) )
		{
			InitPassiveSkills( client );
		}
	}
	else
	{
		W3ResetAllBuffRace( client, thisRaceID );
	}
}

public OnSkillLevelChanged( client, race, skill, newskilllevel )
{
	InitPassiveSkills( client );
}

public OnWar3EventSpawn( client )
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		bAmmo[client] = false;
		InitPassiveSkills( client );
	}
}

public OnWar3EventDeath( victim, attacker )
{
	W3ResetAllBuffRace( victim, thisRaceID );
}

public Action:SetWepAmmo( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		new String:weapon[32]; 
		GetClientWeapon( client, weapon, 32 );
		if( StrEqual( weapon, "weapon_m4a1" ) )
		{
			new wep_ent = W3GetCurrentWeaponEnt( client );
			SetEntData( wep_ent, Clip1Offset, 200, 4 );
		}
	}
}

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_dmg = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG );
			if( !Hexed( attacker, false ) && skill_dmg > 0 && GetRandomFloat( 0.0, 1.0 ) <= 0.30 )
			{
				new String:wpnstr[32];
				GetClientWeapon( attacker, wpnstr, 32 );
				if( !StrEqual( wpnstr, "weapon_knife" ) && !W3HasImmunity( victim, Immunity_Skills  ) )
				{
					new Float:start_pos[3];
					new Float:target_pos[3];
				
					GetClientAbsOrigin( attacker, start_pos );
					GetClientAbsOrigin( victim, target_pos );
				
					start_pos[2] += 40;
					target_pos[2] += 40;
				
					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 1.0, 3.0, 6.0, 0, 0.0, { 100, 255, 55, 255 }, 0 );
					TE_SendToAll();
					
					War3_DealDamage( victim, RoundToFloor( damage * DamageMultiplier[skill_dmg] ), attacker, DMG_BULLET, "space_marine_crit" );
				
					W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_DMG );
					W3FlashScreen( victim, RGBA_COLOR_RED );
				}
			}
		}
	}
}

public WeaponReloadEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		new skill_m4a1 = War3_GetSkillLevel( client, race, SKILL_M4A1 );
		if( skill_m4a1 > 0 && bAmmo[client] )
		{
			CreateTimer( 3.5, SetWepAmmo, client );
		}
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_STIM );
		
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_STIM, true ) )
			{
				//War3_GetMaxHP( client );
				//GetClientHealth(client);
				War3HealToHP( client, HealthGain[ult_level], Health[SKILL_HP] );
				//War3_HealToMaxHP( client, HealthGain[ult_level] );
				War3_SetBuff( client, fMaxSpeed, thisRaceID, StimSpeed[ult_level] );
				War3_SetBuff( client, fAttackSpeed, thisRaceID, StimAttackSpeed[ult_level] );
				
				CreateTimer( 8.0, StopStim, client );
				
				War3_CooldownMGR( client, 15.0, thisRaceID, ULT_STIM, _, _ );
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

public Action:StopStim( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
		War3_SetBuff( client, fAttackSpeed, thisRaceID, 1.0 );
	}
}