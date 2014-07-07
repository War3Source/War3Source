#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - XP Gold (CS)",
    author = "War3Source Team",
    description = "Give XP and Gold specific to Counter Strike to those who deserve it"
};

public LoadCheck(){
    return (GameCS() || GameCSGO());
}

// cs
new Handle:DefuseXPCvar;
new Handle:PlantXPCvar;
new Handle:RescueHostageXPCvar;


//10 hostages?
new Handle:touchedHostage[MAXPLAYERSCUSTOM];


public OnPluginStart()
{
    LoadTranslations("w3s.engine.xpgold.txt");
    
    for(new i=0;i<MAXPLAYERSCUSTOM;i++){
        touchedHostage[i]=CreateArray();
    }
    DefuseXPCvar=CreateConVar("war3_percent_cs_defusexp","200","Percent of kill XP awarded for defusing the bomb");
    PlantXPCvar=CreateConVar("war3_percent_cs_plantxp","200","Percent of kill XP awarded for planting the bomb");
    RescueHostageXPCvar=CreateConVar("war3_percent_cs_hostagerescuexp","100","Percent of kill XP awarded for rescuing a hostage");
     
    if(GAMECSANY){
        if(!HookEventEx("bomb_defused",War3Source_BombDefusedEvent))
        {
            PrintToServer("[War3Source] Could not hook the bomb_defused event.");
            
        }
        if(!HookEventEx("bomb_planted",War3Source_BombPlantedEvent))
        {
            PrintToServer("[War3Source] Could not hook the bomb_planted event.");
            
        }
        if(!HookEventEx("hostage_follows",War3Source_HostageFollow))
        {
            PrintToServer("[War3Source] Could not hook the hostage_rescued event.");
            
        }
        if(!HookEventEx("hostage_rescued",War3Source_HostageRescuedEvent))
        {
            PrintToServer("[War3Source] Could not hook the hostage_rescued event.");
            
        }
        if(!HookEventEx("hostage_killed",War3Source_HostageKilled))
        {
            PrintToServer("[War3Source] Could not hook the hostage_rescued event.");
            
        }
        
        //for clearing hostage touch
        if(!HookEventEx("round_start",War3Source_RoundOverEvent))
        {
            PrintToServer("[War3Source] Could not hook the round_end event.");
        }
    }
}

public War3Source_RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++){
        ClearArray(touchedHostage[i]);
    }
}
public War3Source_BombDefusedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetEventInt(event,"userid")>0)
    {
        new client=GetClientOfUserId(GetEventInt(event,"userid"));
        
        
        new Float:origin[3];
        GetClientAbsOrigin(client,origin);
        new team=GetClientTeam(client);
        new Float:otherorigin[3];
        for(new i=1;i<=MaxClients;i++){
            if(ValidPlayer(i,true)&&GetClientTeam(i)==team){
                
                GetClientAbsOrigin(i,otherorigin);
                if(GetVectorDistance(origin,otherorigin)<1000.0&&War3_GetRace(i)>0){
            
                    // Called when a player defuses the bomb
                
                    //new race=War3_GetRace(i);
                    new addxp=(W3GetKillXP(i)*GetConVarInt(DefuseXPCvar))/100;
                    
                    new String:defusaward[64];
                    new String:helpdefusaward[64];
                    Format(defusaward,sizeof(defusaward),"%T","defusing the bomb",i);
                    Format(helpdefusaward,sizeof(helpdefusaward),"%T","being near bomb defuse",i);
                    W3GiveXPGold(i,XPAwardByBomb,addxp,0,i==client?defusaward:helpdefusaward);
                }
            }
        }
        
    }
}

public War3Source_BombPlantedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetEventInt(event,"userid")>0)
    {
        new client=GetClientOfUserId(GetEventInt(event,"userid"));
    
        new Float:origin[3];
        GetClientAbsOrigin(client,origin);
        new team=GetClientTeam(client);
        new Float:otherorigin[3];
        for(new i=1;i<=MaxClients;i++){
            if(ValidPlayer(i,true)&&GetClientTeam(i)==team){
                
                GetClientAbsOrigin(i,otherorigin);
                if(GetVectorDistance(origin,otherorigin)<1000.0&&War3_GetRace(i)>0){
        
                    // Called when a player plants the bomb
                
                    //new race=War3_GetRace(i);
                    new addxp=(W3GetKillXP(i)*GetConVarInt(PlantXPCvar))/100;
                    
                    new String:plantaward[64];
                    new String:helpplantaward[64];
                    Format(plantaward,sizeof(plantaward),"%T","planting the bomb",i);
                    Format(helpplantaward,sizeof(helpplantaward),"%T","being near bomb plant",i);
                    W3GiveXPGold(i,XPAwardByBomb,addxp,0,i==client?plantaward:helpplantaward);
                }
            }
        }
    
    }
}

public War3Source_HostageFollow(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetEventInt(event,"userid")>0)
    {
        new client=GetClientOfUserId(GetEventInt(event,"userid"));
        new hostage=GetEventInt(event,"hostage");
        if(FindValueInArray(touchedHostage[client],hostage)==-1){ 
            PushArrayCell(touchedHostage[client],hostage);
            //new race=War3_GetRace(client);
            new addxp=(W3GetKillXP(client)*GetConVarInt(RescueHostageXPCvar))/100;
            
            new String:hostageaward[64];
            Format(hostageaward,sizeof(hostageaward),"%T","touching a hostage",client);
            W3GiveXPGold(client,XPAwardByHostage,addxp,0,hostageaward);
        }
    }
}

public War3Source_HostageRescuedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetEventInt(event,"userid")>0)
    {
        new client=GetClientOfUserId(GetEventInt(event,"userid"));
    
        // Called when a player rescues a hostage
        //new race=War3_GetRace(client);
        new addxp=(W3GetKillXP(client)*GetConVarInt(RescueHostageXPCvar))/100;
        
        new String:hostageaward[64];
        Format(hostageaward,sizeof(hostageaward),"%T","rescuing a hostage",client);
        W3GiveXPGold(client,XPAwardByHostage,addxp,0,hostageaward);
    }
}

public War3Source_HostageKilled(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetEventInt(event,"userid")>0)
    {
        new client=GetClientOfUserId(GetEventInt(event,"userid"));
        
        // Called when a player rescues a hostage
        //new race=War3_GetRace(client);
        new addxp=-2*(W3GetKillXP(client)*GetConVarInt(RescueHostageXPCvar))/100;
        
        new String:hostageaward[64];
        Format(hostageaward,sizeof(hostageaward),"%T","killing a hostage",client);
        W3GiveXPGold(client,XPAwardByHostage,addxp,0,hostageaward);

    }
}

