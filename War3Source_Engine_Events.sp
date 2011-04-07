

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


new Handle:g_War3GlobalEventFH; 

new dummyreturn;
public Plugin:myinfo= 
{
	name="War3Source Events",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};

public APLRes:AskPluginLoad2Custom(Handle:myself,bool:late,String:error[],err_max)
{
	GlobalOptionalNatives();
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

bool:InitNativesForwards()
{
	CreateNative("W3CreateEvent",NW3CreateEvent);//foritems
	g_War3GlobalEventFH=CreateGlobalForward("OnWar3Event",ET_Ignore,Param_Cell,Param_Cell);
	return true;
}
public NW3CreateEvent(Handle:plugin,numParams)
{

	new event=GetNativeCell(1);
	new client=GetNativeCell(2);
	DoFwd_War3_Event(W3EVENT:event,client);
}

DoFwd_War3_Event(W3EVENT:event,client){
	Call_StartForward(g_War3GlobalEventFH);
	Call_PushCell(event);
	Call_PushCell(client);
	Call_Finish(dummyreturn);
}


public OnWar3Event(W3EVENT:event,client){
	if(event==DoShowHelpMenu){
		//War3Source_War3Help(client);
	}
}
