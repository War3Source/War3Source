#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Player Collision",
    author = "War3Source Team",
    description = "Figure it out yourself :)"
};

new g_offsCollisionGroup;

public OnPluginStart()
{
    g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
}

public bool:InitNativesForwards()
{
    return true;
}

stock SetCollidable(client, bool:collidable){
    SetEntData(entity, g_offsCollisionGroup, collidable ? 5 : 2, 4, true);
}