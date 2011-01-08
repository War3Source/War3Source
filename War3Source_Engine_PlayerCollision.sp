

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new g_offsCollisionGroup;
public Plugin:myinfo= 
{
	name="War3Source Engine Player Collisions",
	author="Ownz",
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
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
}

bool:InitNativesForwards()
{
	return true;
}

stock SetCollidable(client,bool:collidable){
	SetEntData(entity, g_offsCollisionGroup, collidable?5:2, 4, true);
}