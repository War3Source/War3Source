/**
 * File: War3Source_L4D_Interface.inc
 * Description: Functions and stuff to make L4D specific races and whatnot
 * Author(s): Glider  
 * 
 */

#include <sdktools>
#include "W3SIncs/constants"

static const	ASSAULT_RIFLE_OFFSET_IAMMO		= 12;
static const	SMG_OFFSET_IAMMO				= 20;
static const	PUMPSHOTGUN_OFFSET_IAMMO		= 28;
static const	AUTO_SHOTGUN_OFFSET_IAMMO		= 32;
static const	HUNTING_RIFLE_OFFSET_IAMMO		= 36;
static const	MILITARY_SNIPER_OFFSET_IAMMO	= 40;
static const	GRENADE_LAUNCHER_OFFSET_IAMMO	= 68;

#define MODEL_GASCAN	"models/props_junk/gascan001a.mdl"
#define MODEL_PROPANE	"models/props_junk/propanecanister001a.mdl"

/**
 * Returns true if a infected is making love to a client.
 * 
 * Bug: If you kick the infected then this function will still return true
 * for the client until he gets properly freed from a infected attack.
 */
native bool:War3_L4D_IsHelpless(client);  

native War3_L4D_Explode(attacker, Float:pos[3], type);

stock bool:War3_IsL4DEngine() {
	return (War3_GetGame() == Game_L4D || War3_GetGame() == Game_L4D2);
}

stock bool:War3_IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}

stock bool:War3_IsL4DZombieEntity(iEntity) {
	if (War3_IsL4DEngine()) {
		return (War3_IsCommonInfected(iEntity) || War3_IsWitch(iEntity));
	}

	return false;
}

stock bool:War3_IsCommonInfected(iEntity)
{
	if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		decl String:strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		
		return StrEqual(strClassName, "infected");
	}
	return false;
}  

stock bool:War3_IsUncommonInfected(iEntity)
{
	if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		decl String:ModelName[128];
		GetEntPropString(iEntity, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));
		
		return (StrEqual(ModelName, "models/infected/common_male_riot.mdl") ||
				StrEqual(ModelName, "models/infected/common_male_ceda.mdl") ||
				StrEqual(ModelName, "models/infected/common_male_clown.mdl") ||
				StrEqual(ModelName, "models/infected/common_male_mud.mdl") ||
				StrEqual(ModelName, "models/infected/common_male_roadcrew.mdl") ||
				StrEqual(ModelName, "models/infected/common_male_jimmy.mdl") ||
				StrEqual(ModelName, "models/infected/common_male_fallen_survivor.mdl"));
	}
	return false;
}

stock bool:War3_IsWitch(iEntity)
{
	if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		decl String:strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "witch");
	}
	return false;
}

// To check if an infected in versus hasn't spawned yet
stock bool:IsPlayerGhost(client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost", 1) == 1)
	{
		return true;
	}
	
	return false;
}

stock Float:GetSurvivorTempHealth(client)
{
	new Float:temphp = GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate")));
	return temphp > 0.0 ? temphp : 0.0;
}

stock SetSurvivorTempHealth(client, Float:hp)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", hp);
}

stock GetMaxMagSize(const String:weapon[])
{
	if (War3_IsL4DEngine())
	{
		if ((StrEqual(weapon, "weapon_rifle", false)) || (StrEqual(weapon, "weapon_rifle_sg552", false)) || (StrEqual(weapon, "weapon_smg", false) || StrEqual(weapon, "weapon_smg_silenced", false) || StrEqual(weapon, "weapon_smg_mp5", false)))
		{
			return 50;
		}
		else if (StrEqual(weapon, "weapon_rifle_ak47", false))
		{
			return 40;
		}
		else if (StrEqual(weapon, "weapon_rifle_desert", false))
		{
			return 60;
		}
		else if (StrEqual(weapon, "weapon_autoshotgun", false) || StrEqual(weapon, "weapon_shotgun_spas", false))
		{
			return 10;
		}
		else if (StrEqual(weapon, "weapon_grenade_launcher", false))
		{
			return 1;
		}
		else if (StrEqual(weapon, "weapon_pumpshotgun", false) || StrEqual(weapon, "weapon_shotgun_chrome", false))
		{
			return 8;
		}
		else if (StrEqual(weapon, "weapon_hunting_rifle", false))
		{
			return 15;
		}
		else if (StrEqual(weapon, "weapon_sniper_military", false))
		{
			return 30;
		}
		else if (StrEqual(weapon, "weapon_sniper_awp", false))
		{
			return 20;
		}
		else if (StrEqual(weapon, "weapon_sniper_scout", false))
		{
			return 15;
		}
		else if (StrEqual(weapon, "weapon_rifle_m60", false))
		{
			return 150;
		}
	}
	
	return 0;
}

stock GetCurrentBackupAmmo(client)
{
	decl String:weapon[64];
	new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	GetEdictClassname(iWeapon, weapon, sizeof(weapon));
	
	new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo");
	new backup_ammo = 0;

	if (StrEqual(weapon, "weapon_rifle", false) || StrEqual(weapon, "weapon_rifle_ak47", false) || StrEqual(weapon, "weapon_rifle_desert", false) || StrEqual(weapon, "weapon_rifle_sg552", false))
	{
		backup_ammo = GetEntData(client, iAmmoOffset + ASSAULT_RIFLE_OFFSET_IAMMO);
	}
	else if (StrEqual(weapon, "weapon_smg", false) || StrEqual(weapon, "weapon_smg_silenced", false) || StrEqual(weapon, "weapon_smg_mp5", false))
	{
		backup_ammo = GetEntData(client, iAmmoOffset + SMG_OFFSET_IAMMO);
	}		
	else if (StrEqual(weapon, "weapon_pumpshotgun", false) || StrEqual(weapon, "weapon_shotgun_chrome", false))
	{
		backup_ammo = GetEntData(client, iAmmoOffset + PUMPSHOTGUN_OFFSET_IAMMO);
	}
	else if (StrEqual(weapon, "weapon_autoshotgun", false) || StrEqual(weapon, "weapon_shotgun_spas", false))
	{
		backup_ammo = GetEntData(client, iAmmoOffset + AUTO_SHOTGUN_OFFSET_IAMMO);
	}
	else if (StrEqual(weapon, "weapon_hunting_rifle", false))
	{
		backup_ammo = GetEntData(client, iAmmoOffset + HUNTING_RIFLE_OFFSET_IAMMO);
	}
	else if (StrEqual(weapon, "weapon_sniper_military", false) || StrEqual(weapon, "weapon_sniper_awp", false) || StrEqual(weapon, "weapon_sniper_scout", false))
	{
		backup_ammo = GetEntData(client, iAmmoOffset + MILITARY_SNIPER_OFFSET_IAMMO);
	}
	else if (StrEqual(weapon, "weapon_grenade_launcher"))
	{
		backup_ammo = GetEntData(client, iAmmoOffset + GRENADE_LAUNCHER_OFFSET_IAMMO);
	}
	
	return backup_ammo;
}

stock GetMaxBackupAmmo(const String:weapon[])
{
	if (War3_IsL4DEngine())
	{
		if (StrEqual(weapon, "weapon_rifle", false) || StrEqual(weapon, "weapon_rifle_ak47", false) || StrEqual(weapon, "weapon_rifle_desert", false) || StrEqual(weapon, "weapon_rifle_sg552", false))
		{
			return GetConVarInt(FindConVar("ammo_assaultrifle_max"));
		}
		else if (StrEqual(weapon, "weapon_smg", false) || StrEqual(weapon, "weapon_smg_silenced", false) || StrEqual(weapon, "weapon_smg_mp5", false))
		{
			return GetConVarInt(FindConVar("ammo_smg_max"));
		}	
		else if (StrEqual(weapon, "weapon_pumpshotgun", false) || StrEqual(weapon, "weapon_shotgun_chrome", false))
		{
			return GetConVarInt(FindConVar("ammo_shotgun_max"));
		}
		else if (StrEqual(weapon, "weapon_autoshotgun", false) || StrEqual(weapon, "weapon_shotgun_spas", false))
		{
			return GetConVarInt(FindConVar("ammo_autoshotgun_max"));
		}
		else if (StrEqual(weapon, "weapon_hunting_rifle", false))
		{
			return GetConVarInt(FindConVar("ammo_huntingrifle_max"));
		}
		else if (StrEqual(weapon, "weapon_sniper_military", false) || StrEqual(weapon, "weapon_sniper_awp", false) || StrEqual(weapon, "weapon_sniper_scout", false))
		{
			return GetConVarInt(FindConVar("ammo_sniperrifle_max"));
		}
		else if (StrEqual(weapon, "weapon_grenade_launcher", false))
		{
			return GetConVarInt(FindConVar("ammo_grenadelauncher_max"));
		}
		else if (StrEqual(weapon, "weapon_rifle_m60", false))
		{
			return 0;
		}
	}
	
	return 0;
}

// Client is rendered invisible!
stock GotoThirdPerson(client)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
}

stock GotoFirstPerson(client)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
}

stock GotoThirdPersonVisible(client)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
}

stock GetEntityHP(entity)
{
	return GetEntProp(entity, Prop_Data, "m_iHealth");
}

/* Great if you're restricting a race to a specific weapon and want to block
 * all other weapon pickups. Example:
 * 
 * 1. Give player the weapons he should use on Spawn.
 * 2. SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
 * 
 * public Action:OnWeaponCanUse(client, weapon)
{
	decl String:entityName[64];
	GetEdictClassname(weapon, entityName, sizeof(entityName));
	
	if (IsWeapon(entityName))
		return Plugin_Handled; 
	
	return Plugin_Continue;
}
 * Enjoy!
 */


stock bool:IsWeapon(const String:weaponName[])
{
	return (StrEqual(weaponName, "weapon_rifle", false) || 
			StrEqual(weaponName, "weapon_rifle_ak47", false) || 
			StrEqual(weaponName, "weapon_rifle_desert", false) || 
			StrEqual(weaponName, "weapon_rifle_sg552", false) || 
			StrEqual(weaponName, "weapon_smg", false) || 
			StrEqual(weaponName, "weapon_smg_silenced", false) || 
			StrEqual(weaponName, "weapon_smg_mp5", false) || 
			StrEqual(weaponName, "weapon_pumpshotgun", false) || 
			StrEqual(weaponName, "weapon_shotgun_chrome", false) || 
			StrEqual(weaponName, "weapon_autoshotgun", false) || 
			StrEqual(weaponName, "weapon_shotgun_spas", false) || 
			StrEqual(weaponName, "weapon_hunting_rifle", false) || 
			StrEqual(weaponName, "weapon_sniper_military", false) || 
			StrEqual(weaponName, "weapon_sniper_awp", false) || 
			StrEqual(weaponName, "weapon_sniper_scout", false) || 
			StrEqual(weaponName, "weapon_grenade_launcher", false) || 
			StrEqual(weaponName, "weapon_rifle_m60", false) ||
			StrEqual(weaponName, "weapon_melee", false) ||
			StrEqual(weaponName, "weapon_pistol", false) ||
			StrEqual(weaponName, "weapon_pistol_magnum", false));
		
}

stock CreateProgressBar(client, Float:fTimeDur)
{
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", fTimeDur);
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
}

stock KillProgressBar(client)
{
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
}  

#include "W3SIncs/stocks_precache"
#include "W3SIncs/stocks_misc"