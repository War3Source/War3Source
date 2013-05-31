#include <sourcemod>
#include <sdktools>
#include "W3SIncs/War3Source_Interface"
#include "sdkhooks"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Model CS",
    author = "War3Source Team",
    description = "Custom Models for Counter Strike"
};

#define EF_NODRAW 32
//max amount of custom modelchanges this plugin can handle. change value and recompile to change it
#define CS_WEAPONCOUNT 28
/*#define MDLTYPE_VIEWMODEL 0
#define MDLTYPE_WORLDMODEL 1
#define MDLTYPE_GRENADE 2*/

new String:custom_weapons[MAXPLAYERSCUSTOM][CS_WEAPONCOUNT][2][64];
new CustomModels[MAXPLAYERSCUSTOM][CS_WEAPONCOUNT][2];
new CurPos[MAXPLAYERSCUSTOM][2];
new bool:SpawnCheck[MAXPLAYERSCUSTOM];
new ClientVM[MAXPLAYERSCUSTOM][2];
new bool:IsCustom[MAXPLAYERSCUSTOM];

public bool:InitNativesForwards()
{
    //native bool:War3_AddCustomModel(client,String:weapon[],modelIndex,mdltype);
    CreateNative("War3_CSAddCustomModel",NWar3_SetModel);
    //native bool:War3_RemoveCustomModel(client,String:weapon[],mdltype);
    CreateNative("War3_CSRemoveCustomModel",NWar3_DelModel);
    return true;
}

// Silent Failure if non CS:S
public LoadCheck(){
    return (GameCS() || GameCSGO());
}

public _:NWar3_SetModel(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    decl String:weapon[64];
    GetNativeString(2,weapon,sizeof(weapon));
    new modelIndex = GetNativeCell(3);
    new mdltype = GetNativeCell(4);
    return AddCustomModel(client,weapon,modelIndex,mdltype);
}

public _:NWar3_DelModel(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    decl String:weapon[64];
    GetNativeString(2,weapon,sizeof(weapon));
    new mdltype = GetNativeCell(3);
    return RemoveCustomModel(client,weapon,mdltype);
}

public bool:AddCustomModel(client,String:weapon[],modelIndex,arraypos)
{
    if(HasCustomReplacement(client,weapon,arraypos)!=-1) {
        return false;
    }
    if(CurPos[client][arraypos]<CS_WEAPONCOUNT) {
        CurPos[client][arraypos]++;
        //DP("adding %s on %i",weapon,CurPos[client][arraypos]);
        strcopy(custom_weapons[client][CurPos[client][arraypos]][arraypos],64,weapon);
        CustomModels[client][CurPos[client][arraypos]][arraypos]=modelIndex;
        return true;
    }
    return false;
}

public bool:RemoveCustomModel(client,String:weapon[],arraypos)
{
    for(new i=0;i<CS_WEAPONCOUNT;i++)
    {
        if(strcmp(custom_weapons[client][i][arraypos], weapon, false)==0) {
            RestoreDefault(client,i,arraypos);
            return true;
        }
    }
    return false;
}

public HasCustomReplacement(client,String:weapon[],arraypos)
{
    new modelIndex = -1;
    for(new i=0;i<CS_WEAPONCOUNT;i++)
    {
        if(strcmp(custom_weapons[client][i][arraypos], weapon, false)==0) {
            modelIndex = CustomModels[client][i][arraypos];
            if(modelIndex>=0)
            break;
        }
    }
    return modelIndex;
}

/*public bool:IsCustom(client,arraypos)
{
    new bool:ret = false;
    for(new i=0;i<CS_WEAPONCOUNT;i++)
    {
        if(CustomModels[client][i][arraypos] != -1) {
            ret = true;
            break;
        }
    }
    return ret;
}*/

RestoreDefault(client,i=-1,arraypos=MDLTYPE_VIEWMODEL)
{
    if(i==-1) {
        for(i=0;i<CS_WEAPONCOUNT;i++)
        {
            CurPos[client][arraypos]=-1;
            CustomModels[client][i][arraypos]=-1;
            strcopy(custom_weapons[client][i][arraypos],64,"");
        }
    }
    else {
        for(arraypos=0;arraypos<2;arraypos++)
        {
            CurPos[client][arraypos]=-1;
            CustomModels[client][i][arraypos]=-1;
            strcopy(custom_weapons[client][i][arraypos],64,"");
        }
    }
}

new bool:is_hooked[MAXPLAYERSCUSTOM];
public OnPluginStart()
{
    //support late loading
    for (new client = 1; client <= MaxClients; client++) 
    { 
        if (IsClientInGame(client) && !IsFakeClient(client)) 
        {
            if(!is_hooked[client]) {
                RestoreDefault(client);
                
                SDKHook(client, SDKHook_WeaponSwitch, WeaponHook);
                SDKHook(client, SDKHook_WeaponEquip, WeaponHook);
                SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
            }
            
            //find both of the clients viewmodels
            ClientVM[client][0] = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
            
            new PVM = -1;
            while ((PVM = FindEntityByClassname(PVM, "predicted_viewmodel")) != -1)
            {
                if (GetEntPropEnt(PVM, Prop_Send, "m_hOwner") == client)
                {
                    if (GetEntProp(PVM, Prop_Send, "m_nViewModelIndex") == 1)
                    {
                        ClientVM[client][1] = PVM;
                        break;
                    }
                }
            }
        } 
    }
}

public OnClientPutInServer(client) {
    if(IS_PLAYER(client) && !is_hooked[client]) {
        RestoreDefault(client);
        SDKHook(client, SDKHook_WeaponSwitch, WeaponHook);
        SDKHook(client, SDKHook_WeaponEquip, WeaponHook);
        SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
    }
}

public OnEntityCreated(entity, const String:classname[])
{
    if (strcmp(classname, "predicted_viewmodel", false)==0) {
        SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
    }
    /*else if(StrContains(classname, "_projectile", false)) {
        CreateTimer(0.1, Timer_CheckNadeModel, entity);
    }*/
}

//find both of the clients viewmodels
public OnEntitySpawned(entity)
{
    new Owner = GetEntPropEnt(entity, Prop_Send, "m_hOwner");
    if ((Owner > 0) && (Owner <= MaxClients)) {
        if (GetEntProp(entity, Prop_Send, "m_nViewModelIndex") == 0)
        {
            ClientVM[Owner][0] = entity;
        }
        else if (GetEntProp(entity, Prop_Send, "m_nViewModelIndex") == 1)
        {
            ClientVM[Owner][1] = entity;
        }
    }
}

//decl String:ClassName[30];
//GetEdictClassname(WeaponIndex, ClassName, sizeof(ClassName));

public Action:WeaponHook(client, weapon)
{
    if(IsClientInGame(client) && CurPos[client][MDLTYPE_WORLDMODEL]!=-1)
    {
        CreateTimer(0.1, Timer_CheckWorldModel, client);
        return Plugin_Continue;
    }
    return Plugin_Continue;
}

public OnPostThinkPost(client)
{
    if(!IsClientInGame(client)) {
        return;
    }
    if (!IsPlayerAlive(client) || CurPos[client][MDLTYPE_VIEWMODEL]==-1) {
        return;
    }
    
    static OldWeapon[MAXPLAYERSCUSTOM];
    static OldSequence[MAXPLAYERSCUSTOM];
    static Float:OldCycle[MAXPLAYERSCUSTOM];
    
    //new WeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    new WeaponIndex = W3GetCurrentWeaponEnt(client);
    if (WeaponIndex == -1)
    {
        OldWeapon[client] = WeaponIndex;
        return;
    }
    
    new Sequence = GetEntProp(ClientVM[client][0], Prop_Send, "m_nSequence");
    new Float:Cycle = GetEntPropFloat(ClientVM[client][0], Prop_Data, "m_flCycle");
    
    //handle spectators
    if (!IsPlayerAlive(client))
    {
        new spec = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
        if (spec != -1)
        {
            WeaponIndex = GetEntPropEnt(spec, Prop_Send, "m_hActiveWeapon");
            decl String:ClassName[32];
            GetEdictClassname(WeaponIndex, ClassName, sizeof(ClassName));
            new modelIndex = HasCustomReplacement(client,ClassName,MDLTYPE_VIEWMODEL);
            if(modelIndex!=-1)
            {
                SetEntProp(ClientVM[client][1], Prop_Send, "m_nModelIndex", modelIndex);
            }
        }
        
        return;
    }
    
    //handle invalid weapon indizes
    if (WeaponIndex <= 0)
    {
        new EntEffects = GetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects");
        EntEffects |= EF_NODRAW;
        SetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects", EntEffects);
        
        IsCustom[client] = false;
        
        OldWeapon[client] = WeaponIndex;
        OldSequence[client] = Sequence;
        OldCycle[client] = Cycle;
        
        return;
    }
    
    //just stuck the weapon switching in here aswell instead of a separate hook
    if (WeaponIndex != OldWeapon[client])
    {
        decl String:ClassName[32];
        GetEdictClassname(WeaponIndex, ClassName, sizeof(ClassName));
        new modelIndex = HasCustomReplacement(client,ClassName,MDLTYPE_VIEWMODEL);
        if(modelIndex!=-1)
        {
            //hide viewmodel
            AcceptEntityInput(WeaponIndex, "hideweapon");
            //unhide unused viewmodel
            new EntEffects = GetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects");
            EntEffects &= ~EF_NODRAW;
            SetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects", EntEffects);
            
            //set model and copy over props from viewmodel to used viewmodel
            SetEntProp(ClientVM[client][1], Prop_Send, "m_nModelIndex", modelIndex);
            SetEntPropEnt(ClientVM[client][1], Prop_Send, "m_hWeapon", GetEntPropEnt(ClientVM[client][0], Prop_Send, "m_hWeapon"));
            
            SetEntProp(ClientVM[client][1], Prop_Send, "m_nSequence", GetEntProp(ClientVM[client][0], Prop_Send, "m_nSequence"));
            SetEntPropFloat(ClientVM[client][1], Prop_Send, "m_flPlaybackRate", GetEntPropFloat(ClientVM[client][0], Prop_Send, "m_flPlaybackRate"));
            
            //mark client to be recognized as a user with a custom viewmodel
            IsCustom[client] = true;
        }
        else
        {
            //hide unused viewmodel if the current weapon isn't using it
            new EntEffects = GetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects");
            EntEffects |= EF_NODRAW;
            SetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects", EntEffects);
            
            IsCustom[client] = false;
        }
    }
    else
    {
        if (IsCustom[client])
        {
            decl String:ClassName[30];
            GetEdictClassname(WeaponIndex, ClassName, sizeof(ClassName));
            new modelIndex = HasCustomReplacement(client,ClassName,MDLTYPE_VIEWMODEL);
            if(modelIndex!=-1)
            {
                SetEntProp(ClientVM[client][1], Prop_Send, "m_nSequence", GetEntProp(ClientVM[client][0], Prop_Send, "m_nSequence"));
                SetEntPropFloat(ClientVM[client][1], Prop_Send, "m_flPlaybackRate", GetEntPropFloat(ClientVM[client][0], Prop_Send, "m_flPlaybackRate"));
            }
            
            if ((Cycle < OldCycle[client]) && (Sequence == OldSequence[client]))
            {
                SetEntProp(ClientVM[client][1], Prop_Send, "m_nSequence", 0);
            }
        }
    }
    //hide viewmodel a frame after spawning
    if (SpawnCheck[client])
    {
        SpawnCheck[client] = false;
        if (IsCustom[client])
        {
            new EntEffects = GetEntProp(ClientVM[client][0], Prop_Send, "m_fEffects");
            EntEffects |= EF_NODRAW;
            SetEntProp(ClientVM[client][0], Prop_Send, "m_fEffects", EntEffects);
        }
    }
    OldWeapon[client] = WeaponIndex;
    OldSequence[client] = Sequence;
    OldCycle[client] = Cycle;
}

//hide viewmodel on death
public OnWar3EventDeath(client,attacker,deathrace)
{
    new EntEffects = GetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects");
    EntEffects |= EF_NODRAW;
    SetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects", EntEffects);
}

//when a player respawns at round start after surviving previous round the viewmodel is unhidden
public OnWar3EventSpawn(client)
{
    //use to delay hiding viewmodel a frame or it won't work
    SpawnCheck[client] = true;
    
    //check worldmodel
    if(CurPos[client][MDLTYPE_WORLDMODEL]!=-1)
    CreateTimer(0.1, Timer_CheckWorldModel, client);
}

public Action:Timer_CheckWorldModel(Handle:Timer, any:client)
{
    if(IsClientInGame(client) && IsPlayerAlive(client)) {
        new ActiveWeapon = W3GetCurrentWeaponEnt(client);
        if(ActiveWeapon == -1) {
            //abort if active weapon is invalid
            return Plugin_Handled;
        }
        decl String:sWeapon[32];
        GetEdictClassname(ActiveWeapon, sWeapon, sizeof(sWeapon));
        new modelIndex = HasCustomReplacement(client,sWeapon,MDLTYPE_WORLDMODEL);
        if(modelIndex!=-1)
        {
            SetEntProp(ActiveWeapon, Prop_Send, "m_iWorldModelIndex", modelIndex);
        }
    }
    return Plugin_Continue;
}

public Action:Timer_CheckNadeModel(Handle:Timer, any:ent)
{
    new client = GetEntPropEnt(ent, Prop_Send, "m_hThrower");
    if(IS_PLAYER(client) && IsPlayerAlive(client)) {
        decl String:sWeapon[32];
        GetEdictClassname(ent, sWeapon, sizeof(sWeapon));
        new modelIndex = HasCustomReplacement(client,sWeapon,MDLTYPE_GRENADE);
        if(modelIndex!=-1)
        {
            SetEntProp(ent, Prop_Send, "m_iModelIndex", modelIndex);
            //SetEntityModel(ent,modelIndex);
        }
    }
    return Plugin_Continue;
}