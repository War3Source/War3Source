#include <sourcemod>
#include "sdkhooks"
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Death Weapons",
    author = "War3Source Team",
    description = "Stores what weapons a player had when he died"
};

///caching player angles, pos, ducking, weapons etc
new Float:pfAngle[MAXPLAYERSCUSTOM][3];
new Float:pfPos[MAXPLAYERSCUSTOM][3];
new bool:pbDucking[MAXPLAYERSCUSTOM];
new piWeapon[MAXPLAYERSCUSTOM][10]; //10 is probably slot number
new piWeaponClip[MAXPLAYERSCUSTOM][10]; //loaded in gun
new piWeaponAmmo[MAXPLAYERSCUSTOM][32]; //32 types of ammo?
new piWeaponDeadClip[MAXPLAYERSCUSTOM][10]; 
new piWeaponDeadAmmo[MAXPLAYERSCUSTOM][32]; 
new String:psWeaponName[MAXPLAYERSCUSTOM][10][32];//cached weapon name
new iCachedArmor[MAXPLAYERSCUSTOM];
new bool:bCachedHelmet[MAXPLAYERSCUSTOM];

new MyWeaponsOffset; //get weapon per slot
new Clip1Offset;
new AmmoOffset;

public OnPluginStart()
{
    MyWeaponsOffset=FindSendPropInfo("CBaseCombatCharacter","m_hMyWeapons");
    if(MyWeaponsOffset==-1)
    {
        PrintToServer("[War3Source] Error finding weapon list offset.");
    }
    Clip1Offset=FindSendPropInfo("CBaseCombatWeapon","m_iClip1");
    if(Clip1Offset==-1)
    {
        PrintToServer("[War3Source] Error finding clip1 offset.");
    }
    AmmoOffset=FindSendPropInfo("CBasePlayer","m_iAmmo");
    if(AmmoOffset==-1)
    {
        PrintToServer("[War3Source] Error finding ammo offset.");
    }
}

public bool:InitNativesForwards()
{
    CreateNative("War3_CachedAngle",Native_War3_CachedAngle);
    CreateNative("War3_CachedPosition",Native_War3_CachedPosition);
    CreateNative("War3_CachedDucking",Native_War3_CachedDucking);
    CreateNative("War3_CachedWeapon",Native_War3_CachedWeapon);
    CreateNative("War3_CachedClip1",Native_War3_CachedClip1);
    CreateNative("War3_CachedAmmo",Native_War3_CachedAmmo);
    CreateNative("War3_CachedDeadClip1",Native_War3_CachedDeadClip1);
    CreateNative("War3_CachedDeadAmmo",Native_War3_CachedDeadAmmo);
    CreateNative("War3_CachedDeadWeaponName",Native_War3_CDWN);
    CreateNative("War3_RestoreCachedCSArmor",Native_War3_CachedCSArmor);
    return true;
}


public Native_War3_CachedAngle(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);    
    SetNativeArray(2,pfAngle[client],3);
}

public Native_War3_CachedPosition(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    SetNativeArray(2,pfPos[client],3);
}

public Native_War3_CachedDucking(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    return (pbDucking[client])?1:0;
}

public Native_War3_CachedWeapon(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    new iter=GetNativeCell(2);
    if( iter>=0 && iter<10)
    {
        return piWeapon[client][iter];
    }
    return 0;
}

public Native_War3_CachedClip1(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    new iter=GetNativeCell(2);
    if( iter>=0 && iter<10)
    {
        return piWeaponClip[client][iter];
    }
    return 0;
}

public Native_War3_CachedAmmo(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    new id=GetNativeCell(2);
    if( id>=0 && id<32)
    {
        return piWeaponAmmo[client][id];
    }
    return 0;
}

public Native_War3_CachedDeadClip1(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    new iter=GetNativeCell(2);
    if( iter>=0 && iter<10)
    {
        return piWeaponDeadClip[client][iter];
    }
    return 0;
}

public Native_War3_CachedDeadAmmo(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    new id=GetNativeCell(2);
    if( id>=0 && id<32)
    {
        return piWeaponDeadAmmo[client][id];
    }
    return 0;
}

public Native_War3_CDWN(Handle:plugin,numParams) //cached weapon name?
{
    new client=GetNativeCell(1);
    new iter=GetNativeCell(2);
    if( iter>=0 && iter<10)
    {
        SetNativeString(3,psWeaponName[client][iter],GetNativeCell(4));
    }
}

public Native_War3_CachedCSArmor(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if( !GAMECSANY )
    {
        return ThrowNativeError(SP_ERROR_NATIVE,"Invoked on a unsupported game!");
    }
    // Restore them now
    War3_SetCSArmor(client, iCachedArmor[client]);
    War3_SetCSArmorHasHelmet(client, bCachedHelmet[client]);
    return 0;
}

new skipaframe;
// Game Frame tracking
public OnGameFrame()
{
    /*for(new client=1;client<=MaxClients;client++)
    {
        if(ValidPlayer(client,true))//&&!bIgnoreTrackGF[client])
        {
            PrintToServer("1");
            SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", Float:{0.0,0.0,0.0});
        }
    }*/
    skipaframe--;
    if(skipaframe<0){
        skipaframe=1;
        for(new client=1;client<=MaxClients;client++)
        {
            if(ValidPlayer(client,true))//&&!bIgnoreTrackGF[client])
            {
                
                GetClientEyeAngles(client,pfAngle[client]);
                GetClientAbsOrigin(client,pfPos[client]);
                //new cur_wep=0;
                for(new slot=0;slot<10;slot++)
                {
                    // null values
                    piWeapon[client][slot]=0;
                }
                for(new ammotype=0;ammotype<32;ammotype++)
                {
                    piWeaponAmmo[client][ammotype]=GetEntData(client,AmmoOffset+(ammotype*4),4);
                }
                for(new slot=0;slot<10;slot++)
                {
                    new ent=GetEntDataEnt2(client,MyWeaponsOffset+(slot*4));
                    if(ent>0)
                    {
                        piWeapon[client][slot]=ent;
                        piWeaponClip[client][slot]=GetEntData(ent,Clip1Offset,4);
                        //piWeapon[x][cur_wep]=ent;
                        //piWeaponClip[x][cur_wep]=GetEntData(ent,Clip1Offset,4);
                        //++cur_wep;
                    }
                }
            }
        }
    }
}

public OnWar3EventDeath(victim)
{
    if(ValidPlayer(victim))
    {
        for(new slot=0;slot<10;slot++)
        {
            strcopy(psWeaponName[victim][slot],64,"");
            new ent=piWeapon[victim][slot];
            if(ent)
            {
                if(IsValidEdict(ent))
                {
                    piWeaponDeadClip[victim][slot]=GetEntData(ent,Clip1Offset,4);
                    GetEdictClassname(ent,psWeaponName[victim][slot],64);
                }
            }
        }

        for(new ammotype=0;ammotype<32;ammotype++)
        {
            piWeaponDeadAmmo[victim][ammotype]=GetEntData(victim,AmmoOffset+(ammotype*4),4);
        }
    }
}

public OnW3TakeDmgAllPre(client, attacker, Float:damage)
{
    // Revan: We need to track armor here because player_death get's fired too late.
    if( GAMECSANY )
    {
        if( damage >= GetClientHealth(client) )
        {
            iCachedArmor[client] = War3_GetCSArmor(client);
            bCachedHelmet[client] = bool:War3_GetCSArmorHasHelmet(client);
        }
    }
}


