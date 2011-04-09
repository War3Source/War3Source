//Cooldown manager
//keeps track of all cooldowns

//Delay Tracker:
//setting an object's state to false for X seconds, manually retrieve the state




#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


public Plugin:myinfo= 
{
	name="War3Source Engine 2",
	author="Ownz",
	description="Core utilities for War3Source.",
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
	
}

public bool:InitNativesForwards()
{
	///LIST ALL THESE NATIVES IN INTERFACE
	CreateNative("War3_GetAimEndPoint",NWar3_GetAimEndPoint);

	return true;
}

new ignoreClient;
public NWar3_GetAimEndPoint(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new Float:angle[3];
	GetClientEyeAngles(client,angle);
	new Float:endpos[3];
	new Float:startpos[3];
	GetClientEyePosition(client,startpos);
	new Float:dir[3];
	GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
	
	AddVectors(startpos, dir, endpos);
	
	GetClientAbsOrigin(client,oldpos[client]);
	
	
	//PrintToChatAll("1");
	
	ignoreClient=client;
	TR_TraceRayFilter(startpos,endpos,MASK_SOLID,RayType_EndPoint,AimTargetFilter);
	TR_GetEndPosition(endpos);
	
	SetNativeArray(2,endpos,3)
}
public bool:AimTargetFilter(entity,mask)
{
	return !(entity==ClientTracer);
}
public bool:CanHitThis(entityhit, mask, any:data)
{
	if(entityhit == data )
	{// Check if the TraceRay hit the itself.
		return false; // Don't allow self to be hit, skip this result
	}
	if(War3_ValidPlayer(entityhit)&&War3_ValidPlayer(data)&&War3_GetGame()==Game_TF&&GetClientTeam(entityhit)==GetClientTeam(data)){
		return false; //skip result, prend this space is not taken cuz they on same team
	}
	return true; // It didn't hit itself
}