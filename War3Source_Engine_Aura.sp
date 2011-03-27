#pragma dynamic 30000

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


new bool:AuraOrigin[MAXPLAYERSCUSTOM][MAXAURAS];
new bool:AuraOriginLevel[MAXPLAYERSCUSTOM][MAXAURAS];

new HasAura[MAXPLAYERSCUSTOM][MAXAURAS]; //int, we just count up
new HasAuraLevel[MAXPLAYERSCUSTOM][MAXAURAS];

new String:AuraShort[MAXAURAS][32];
new Float:AuraDistance[MAXAURAS];
new bool:AuraTrackOtherTeam[MAXAURAS];
new AuraCount;

new Handle:g_Forward;

new Float:lastCalcAuraTime;
public Plugin:myinfo= 
{
	name="War3Source Engine Aura",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};
public APLRes:AskPluginLoad2(Handle:myself,bool:late,String:error[],err_max)
{
	if(!InitNativesForwards())
	{
		LogError("[War3Source] There was a failure in creating the native / forwards based functions, definately halting.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}
public OnPluginStart()
{
	CreateTimer(0.5,CalcAura,_,TIMER_REPEAT);
}
bool:InitNativesForwards()
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
	for(new aura=1;aura<=AuraCount;aura++){
		if(StrEqual(taurashort, AuraShort[aura], false)){
			return aura; //already registered
		}
	}
	if(AuraCount+1<MAXAURAS){
		AuraCount++;
		strcopy(AuraShort[AuraCount],32,taurashort);
		
		AuraDistance[AuraCount]=Float:GetNativeCell(2);
		AuraTrackOtherTeam[AuraCount]=bool:GetNativeCell(3);
		return AuraCount;
	}
	else{
		ThrowError("CANNOT REGISTER ANY MORE AURAS");
	}
	return -1;
}
public NW3SetAuraFromPlayer(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new aura=GetNativeCell(2);
	AuraOrigin[client][aura]=bool:GetNativeCell(3);
	AuraOriginLevel[client][aura]=GetNativeCell(4);
}
public NW3HasAura(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new aura=GetNativeCell(2);
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
public OnWar3EventSpawn(){ ShouldCalcAura();}
public OnSHEventSpawn(){ ShouldCalcAura();}
public OnWar3EventDeath(){ ShouldCalcAura();}
public OnSHEventDeath(){ ShouldCalcAura();}
ShouldCalcAura(){
	if(GetEngineTime()>lastCalcAuraTime+0.1){
		CalcAura(INVALID_HANDLE);
	}
}
public Action:CalcAura(Handle:t)
{
	lastCalcAuraTime=GetEngineTime();
	//store old aura count
	new OldHasAura[MAXPLAYERSCUSTOM][MAXAURAS];
	new OldHasAuraLevel[MAXPLAYERSCUSTOM][MAXAURAS];
	for(new client=1;client<=MaxClients;client++)
	{
		for(new aura=1;aura<=AuraCount;aura++){
			OldHasAura[client][aura]=HasAura[client][aura];
			OldHasAuraLevel[client][aura]=HasAuraLevel[client][aura];
			HasAura[client][aura]=0; //clear
			HasAuraLevel[client][aura]=0; 
		}
	}
	
	
	new Float:Distances[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM];
	new Float:vec1[3];
	new Float:vec2[3];
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true))
		{
			for(new target=client;target<=MaxClients;target++) //client can be target
			{
				if(ValidPlayer(target,true))
				{
					GetClientAbsOrigin(client,vec1);
					GetClientAbsOrigin(target,vec2);
					new Float:dis=GetVectorDistance(vec1,vec2);
					Distances[client][target]=dis;
					Distances[target][client]=dis;
					//DP("aura %d  %f",client,dis);
					for(new aura=1;aura<=AuraCount;aura++){
						if(dis<AuraDistance[aura]){
							
							if(AuraOrigin[client][aura] ){ //client originating an aura
								//DP("aura origin %d",client);
								if( (!AuraTrackOtherTeam[aura]&&GetClientTeam(client)==GetClientTeam(target)) 
								 || (AuraTrackOtherTeam[aura]&&GetClientTeam(client)!=GetClientTeam(target))
								)
								{
									//DP("aura target on %d",target);
									HasAura[target][aura]++;
									HasAuraLevel[target][aura]=IntMax(HasAuraLevel[target][aura],AuraOriginLevel[client][aura]);
								}
							}
							if(AuraOrigin[target][aura] ){ //target originating an aura
								if( (!AuraTrackOtherTeam[aura]&&GetClientTeam(client)==GetClientTeam(target)) 
								 || (AuraTrackOtherTeam[aura]&&GetClientTeam(client)!=GetClientTeam(target))
								)
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
			if(HasAura[client][aura]>1){
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

}
