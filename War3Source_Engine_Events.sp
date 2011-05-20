

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



public OnPluginStart()
{
}

public bool:InitNativesForwards()
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
	if(event==SHSelectHeroesMenu){
		DPP(plugin);
		DPP(plugin);
		ThrowNativeError(1,"asdf");
	}
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
