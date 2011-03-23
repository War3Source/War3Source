

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo= 
{
	name="War3Source Engine Item2 Database",
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
	CreateNative("W3SaveItem2ExpireTime",NW3SaveItem2ExpireTime);
	return true;
}
public OnWar3Event(W3EVENT:event,client){
	if(event==InitPlayerVariables){ //already cleared, we just set new value
	
	}
}
public NW3SaveItem2ExpireTime(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new item=GetNativeCell(2);
	INTERNALSaveItem2ExpireTime(client,item);
}
INTERNALSaveItem2ExpireTime(client,item){
	new Handle:DB=W3GetVar(hDatabase);
	if(DB!=INVALID_HANDLE){
		
	}
}

