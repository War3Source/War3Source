#include <sourcemod>
#include <sdktools>
#include "W3SIncs/War3Source_Interface"

#define    GAMEDATA    "war3source.games"
new Handle:g_hIsMeleeWeapon = INVALID_HANDLE;

public Plugin:myinfo = 
{
    name = "War3Source - Engine - GameData",
    author = "War3Source Team",
    description = "Provides natives for GameData based functionality"
};

public bool:InitNativesForwards()
{
    /* PrepSDKCall_SetAddress is only available in 1.6 and above. */
    MarkNativeAsOptional("PrepSDKCall_SetAddress");
    
    CreateNative("War3_IsMeleeWeapon", NativeCall:Native_War3_IsMeleeWeapon);
    return true;
}

Handle:FindIsMeleeWeapon(Handle:hGameConf)
{
    /* See if we can directly tell SDKTools what address we wan't to call. */
    if(GetFeatureStatus(FeatureType_Native, "PrepSDKCall_SetAddress") == FeatureStatus_Available)
    {
        new Address:funcAddr = GameConfGetAddress(hGameConf, "IsMeleeWeapon");
        if(funcAddr != Address_Null)
        {
            /* Get call offset. */
            new callOffset = LoadFromAddress(Address:(any:funcAddr + 1), NumberType_Int32);
            /* We need to use the value of EIP to calculate the VA of the function. */
            funcAddr = Address:((any:funcAddr + 5) + callOffset);
            /* Tell SDKTools to prepare the function call to the specified address. */
            StartPrepSDKCall(SDKCall_Entity);
            PrepSDKCall_SetAddress(funcAddr);
            PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
            return EndPrepSDKCall();
        }
    }
    
    /* We're not on SM >1.6 or failed with the above method! This means we've to use a rather 'unstable' signature. */
    StartPrepSDKCall(SDKCall_Entity);
    if(PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "IsMeleeWeapon"))
    {
        PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
        return EndPrepSDKCall();
    }
    
    return INVALID_HANDLE;
}

public OnPluginStart()
{
    /**
     * We use a SDKCall for the maximum reliability for melee weapons on TF2
     * because the game updates quiet frequently. While it would be technically wise
     * to include the very same call for other games as well because CBaseCombatWeapon::IsMeleeWeapon
     * is a generic source sdk function that has been around for ages(and it's prototype hasn't changed at all)
     * I don't think it's a good idea simply because of the fact that this functions requires a signature lookup in
     * order to function properly. Furthermore, other games mostly have a single(or a small set of) weapon entities
     * so it's really not required to search for this function during runtime.
     */
    if(GameTF())
    {
        new Handle:hGameConf = LoadGameConfigFile(GAMEDATA);
        if(hGameConf == INVALID_HANDLE)
        {
            /* couldn't open gamedata file. */
            SetFailState("Failed to load gamedata \"%s\"", GAMEDATA);
            return;
        }
        
        if((g_hIsMeleeWeapon = FindIsMeleeWeapon(hGameConf)) == INVALID_HANDLE)
        {
            /* failed to prepare sdkcall. */
            LogError("Couldn't finalize SDK call preparation of \"IsMeleeWeapon\"!");
        }
    }
}

public bool:Native_War3_IsMeleeWeapon(Handle:plugin, numParams)
{
    new ent = GetNativeCell(1);
    if(IsValidEntity(ent))
    {
        decl String:sWeaponName[64];
        switch(War3_GetGame())
        {
            case Game_CS:
            {
                GetEdictClassname(ent, sWeaponName, sizeof(sWeaponName));
                return StrEqual(sWeaponName, "weapon_knife", false);
            }
            case Game_CSGO:
            {
                GetEdictClassname(ent, sWeaponName, sizeof(sWeaponName));
                return (StrContains(sWeaponName, "knife", false) != -1);
            }
            case Game_DOD:
            {
                GetEdictClassname(ent, sWeaponName, sizeof(sWeaponName));
                return (StrEqual(sWeaponName, "amerknife") || StrEqual(sWeaponName, "spade") || StrEqual(sWeaponName, "punch"));
            }
            case Game_L4D, Game_L4D2:
            {
                GetEdictClassname(ent, sWeaponName, sizeof(sWeaponName));
                return StrEqual(sWeaponName, "weapon_melee", false);
            }
            case Game_TF:
            {
                if(g_hIsMeleeWeapon == INVALID_HANDLE)
                {
                    War3_LogError("Failed to lookup \"IsMeleeWeapon\" function.");
                    return false;
                }
                return bool:SDKCall(g_hIsMeleeWeapon, ent);
            }
        }
    }
    return false;
}