//Delay Tracker:
//setting an object's state to false for X seconds, manually retrieve the state




#include <sourcemod>
#include "W3SIncs/War3Source_Interface"



#define MAXTHREADS 2000
new Float:expireTime[MAXTHREADS];
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
	CreateNative("War3_RegisterDelayTracker",NWar3_RegisterDelayTracker);
	CreateNative("War3_TrackDelay",NWar3_TrackDelay);
	CreateNative("War3_TrackDelayExpired",NWar3_TrackDelayExpired);
	return true;
}
public Action:TimerTick(Handle:h,any:data){
	//lol doo nothing?
}


public NWar3_RegisterDelayTracker(Handle:plugin,numParams)
{
	if(threadsLoaded<MAXTHREADS){
		return threadsLoaded++;
	}
	LogError("[War3Source Engine 1] DELAY TRACKER MAXTHREADS LIMIT REACHED! return -1");
	return -1;
}
public NWar3_TrackDelay(Handle:plugin,numParams)
{
	new index=GetNativeCell(1);
	new Float:delay=GetNativeCell(2);
	expireTime[index]=GetGameTime()+;
}
public NWar3_TrackDelayExpired(Handle:plugin,numParams)
{
	return GetGameTime()>expireTime[GetNativeCell(1)];
}
	
	
