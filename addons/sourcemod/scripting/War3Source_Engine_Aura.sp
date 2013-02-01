#pragma dynamic 30000

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Aura",
    author = "War3Source Team",
    description = "Aura Engine for War3Source"
};

new bool:AuraOrigin[MAXPLAYERSCUSTOM][MAXAURAS];
new bool:AuraOriginLevel[MAXPLAYERSCUSTOM][MAXAURAS];

new HasAura[MAXPLAYERSCUSTOM][MAXAURAS]; //int, we just count up
new HasAuraLevel[MAXPLAYERSCUSTOM][MAXAURAS];

new String:AuraShort[MAXAURAS][32];
new Float:AuraDistance[MAXAURAS];
new bool:AuraTrackOtherTeam[MAXAURAS];
new AuraCount=0;

new Handle:g_Forward;

new Float:lastCalcAuraTime;

public OnPluginStart()
{
    CreateTimer(0.5,CalcAura,_,TIMER_REPEAT);
}
public bool:InitNativesForwards()
{
    
    
    CreateNative("W3RegisterAura",NW3RegisterAura);//for races
    CreateNative("W3SetAuraFromPlayer",NW3SetAuraFromPlayer);
    CreateNative("W3HasAura",NW3HasAura);
    
    g_Forward=CreateGlobalForward("OnW3PlayerAuraStateChanged",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
    return true;
}

public NW3RegisterAura(Handle:plugin,numParams)
{
    new String:taurashort[32];
    GetNativeString(1,taurashort,32);
    
    for(new aura=1; aura <= AuraCount; aura++)
    {
        if(StrEqual(taurashort, AuraShort[aura], false))
        {
            return aura; //already registered
        }
    }
    if(AuraCount + 1 < MAXAURAS)
    {
        AuraCount++;
        strcopy(AuraShort[AuraCount], 32, taurashort);
        
        AuraDistance[AuraCount] = Float:GetNativeCell(2);
        AuraTrackOtherTeam[AuraCount] = bool:GetNativeCell(3);
        
        War3_LogInfo("Registered aura \"%s\" with a distance of \"%f\". TrackOtherTeam: %i", AuraShort[AuraCount], AuraDistance[AuraCount], AuraTrackOtherTeam[AuraCount]);
        return AuraCount;
    }
    else
    {
        ThrowError("CANNOT REGISTER ANY MORE AURAS");
    }
    
    return -1;
}
public NW3SetAuraFromPlayer(Handle:plugin,numParams)
{
    new aura=GetNativeCell(1);
    new client=GetNativeCell(2);
    AuraOrigin[client][aura]=bool:GetNativeCell(3);
    AuraOriginLevel[client][aura]=GetNativeCell(4);
}
public NW3HasAura(Handle:plugin,numParams)
{
    new aura=GetNativeCell(1);
    new client=GetNativeCell(2);
    
    //new data=GetNativeCellRef(3); //we dont have to get
    SetNativeCellRef(3, HasAuraLevel[client][aura]); 
    return ValidPlayer(client,true)&&HasAura[client][aura];
}
public OnWar3Event(W3EVENT:event,client){
    if(event==ClearPlayerVariables){
        InternalClearPlayerVars(client);
    }
}
InternalClearPlayerVars(client){
    for(new aura=1;aura<=AuraCount;aura++)
    {
        AuraOrigin[client][aura]=false;
    }
}
//re calculate auras when one of these things happen, however a 0.1 delay minimum (like 32 players spawn at round start, we dont calculate 32 times)
public OnWar3EventSpawn(){ ShouldCalcAura();}
public OnWar3EventDeath(){ ShouldCalcAura();}
ShouldCalcAura(){
    if(GetEngineTime()>lastCalcAuraTime+0.1){
        CalcAura(INVALID_HANDLE);
    }
}
public Action:CalcAura(Handle:t)
{
    lastCalcAuraTime=GetEngineTime();
    //store old aura count
    decl OldHasAura[MAXPLAYERSCUSTOM][MAXAURAS];
    decl OldHasAuraLevel[MAXPLAYERSCUSTOM][MAXAURAS];
    for(new client=1;client<=MaxClients;client++)
    {
        for(new aura=1;aura<=AuraCount;aura++){
            OldHasAura[client][aura]=HasAura[client][aura];
            OldHasAuraLevel[client][aura]=HasAuraLevel[client][aura];
            HasAura[client][aura]=0; //clear
            HasAuraLevel[client][aura]=0; 
        }
    }
    
    
//    new Float:Distances[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM];
    decl Float:vec1[3];
    decl Float:vec2[3];
    decl teamtarget;
    decl teamclient;
    for(new client=1;client<=MaxClients;client++)
    {
        if(ValidPlayer(client,true))
        {
            for(new target=client;target<=MaxClients;target++) //client can be target
            {
                if(ValidPlayer(target,true))
                {
                    teamtarget=GetClientTeam(target);
                    teamclient=GetClientTeam(client);
                    GetClientAbsOrigin(client,vec1);
                    GetClientAbsOrigin(target,vec2);
                    new Float:dis=GetVectorDistance(vec1,vec2);
                    //Distances[client][target]=dis;
                    //Distances[target][client]=dis;
                    //DP("aura %d  %f",client,dis);
                    for(new aura=1;aura<=AuraCount;aura++){
                        if(dis<AuraDistance[aura]){
                            
                            //boolean magic!!!!!!!! De Morgan wuz here
                            //client originating an aura
                            if(AuraOrigin[client][aura] ){ 
                                //DP("aura origin %d",client);
                                if( (!AuraTrackOtherTeam[aura])==(teamclient==teamtarget)) 
                                // || (AuraTrackOtherTeam[aura]&&teamclient!=teamtarget)
                                
                                {
                                    //DP("aura target on %d",target);
                                    HasAura[target][aura]++;
                                    HasAuraLevel[target][aura]=IntMax(HasAuraLevel[target][aura],AuraOriginLevel[client][aura]); //what level is larger, old level or new level brought by the new origin player
                                }
                            }
                            
                            
                            //target originating an aura
                            if(AuraOrigin[target][aura] &&target!=client ){  //skip if client is target, which we already did up top
                                if( (!AuraTrackOtherTeam[aura])==(teamclient==teamtarget)   ) 
                                 //|| (AuraTrackOtherTeam[aura]&&teamclient!=teamtarget)
                                
                                {
                                    HasAura[client][aura]++;
                                    HasAuraLevel[client][aura]=IntMax(HasAuraLevel[client][aura],AuraOriginLevel[target][aura]);
                                }
                            }
                        }
                    }
                }
            }
        }    
    }
    for(new client=1;client<=MaxClients;client++)
    {
        for(new aura=1;aura<=AuraCount;aura++)
        {
            if(HasAura[client][aura]>1){ //overlapped from different people
                HasAura[client][aura]=1;
            }
            //stat changed?
            if(  (OldHasAura[client][aura]!=HasAura[client][aura])
            ||   (OldHasAuraLevel[client][aura]!=HasAuraLevel[client][aura])
            )
            {
                //DP("NEW AURA %d %d %d",aura,client,HasAuraLevel[client][aura]);
                Call_StartForward(g_Forward);
                Call_PushCell(client);
                Call_PushCell(aura);
                Call_PushCell(HasAura[client][aura]);
                Call_PushCell(HasAuraLevel[client][aura]);
                Call_Finish(dummy);
            }
        }
    }
    W3CreateEvent(OnAuraCalculationFinished,0);
    
}


