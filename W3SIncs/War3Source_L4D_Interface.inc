/**
 * File: War3Source_L4D_Interface.inc
 * Description: Functions and stuff to make L4D specific races and whatnot
 * Author(s): Glider  
 * 
 */

#include <sdktools>

#include "W3SIncs/constants"

/**
 * Returns true if a infected is making love to a client.
 * 
 * Bug: If you kick the infected then this function will still return true
 * for the client until he gets properly freed from a infected attack.
 */
native bool:War3_L4D_IsHelpless(client);  

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

stock GetSurvivorTempHealth(client)
{
	new temphp = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate")))) - 1;
	return temphp > 0 ? temphp : 0;
}

stock SetSurvivorTempHealth(client, hp)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	new Float:newOverheal = hp * 1.0;
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", newOverheal);
}

stock GetMaxMagSize(const String:weapon[])
{
	if (War3_IsL4DEngine())
	{
		if ((StrEqual(weapon, "weapon_rifle", false)) || (StrEqual(weapon, "weapon_rifle_sg552", false)))
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
	}
	
	return 0;
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
			return 150;
		}
	}
	
	return 0;
}

#include "W3SIncs/stocks_precache"
#include "W3SIncs/stocks_misc"