//Delay Tracker:
//setting an object's state to false for X seconds, create for loops or semi cooldowns




#include <sourcemod>
#include "W3SIncs/War3Source_Interface"



#define MAXTHREADS 2000
new threadsLoaded;


public Plugin:myinfo= 
{
	name="War3Source Engine 1",
	author="Ownz",
	description="Core utilities for War3Source.",
	version="1.0",
	url="http://war3source.com/"
};



public APLRes:AskPluginLoad2(Handle:myself,bool:late,String:error[],err_max)
{
	if(!InitNatives())
	{
		LogError("[War3Source] There was a failure in creating the native based functions, definately halting.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateTimer(0.1,TimerTick,_,TIMER_REPEAT);
}
public OnMapStart(){
	for(new i=0;i<threadsLoaded;i++){
		expireTime[i]=0.0;
	}
}

public bool:InitNatives()
{
	///LIST ALL THESE NATIVES IN INTERFACE
	CreateNative("War3_GetGame",Native_War3_GetGame);
	CreateNative("War3_InFreezeTime",Native_War3_InFreezeTime);
	return true;
}
public Action:TimerTick(Handle:h,any:data){
	
}