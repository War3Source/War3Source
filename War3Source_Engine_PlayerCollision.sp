

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new g_offsCollisionGroup;
public Plugin:myinfo= 
{
	name="W3S Engine Player Collisions",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};





public OnPluginStart()
{
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
}

public bool:InitNativesForwards()
{
	return true;
}

stock SetCollidable(client,bool:collidable){
	SetEntData(entity, g_offsCollisionGroup, collidable?5:2, 4, true);
}