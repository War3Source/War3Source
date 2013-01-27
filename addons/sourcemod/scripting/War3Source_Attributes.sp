#pragma semicolon 1

#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Attributes",
    author = "War3Source Team",
    description = "The default attributes that come with War3Source"
};

new aSpeed;

public OnPluginLoad()
{
    aSpeed = War3_RegisterAttribute("speed", "speed", 1.0);
}

public War3_OnAttributeChanged(client, attributeId, any:oldValue, any:newValue)
{
    War3_LogInfo("Player \"{client %i}\" changed attribute {attribute %i} from %s to %s", client, attributeId, oldValue, newValue);

    if (attributeId == aSpeed)
    {
        //new Float:newSpeed = newValue;
        //SetEntDataFloat(client, m_OffsetSpeed, newSpeed);
    }
}