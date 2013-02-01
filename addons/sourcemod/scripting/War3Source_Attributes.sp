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

public War3_OnAttributeDescriptionRequested(client, attributeId, any:value, String:sDescription[], iBufferSize)
{
    if(attributeId == aSpeed)
    {
        LoadTranslations("w3s.attributes.speed.phrases");
        SetTrans(client);
        
        new Float:fSpeed = value;
        decl String:sBuffer[iBufferSize];
        
        if (fSpeed == 1.0)
        {
            Format(sBuffer, iBufferSize, "%T", "You move at regular speed", GetTrans());
        }
        else if (fSpeed > 1.0)
        {
            new percentage = RoundToFloor((fSpeed - 1.0) * 100.0);
            Format(sBuffer, iBufferSize, "%T", "You move %i percent faster", GetTrans(), percentage);
        }
        else if (fSpeed < 1.0)
        {
            new percentage = RoundToFloor((1.0 - fSpeed) * 100.0);
            Format(sBuffer, iBufferSize, "%T", "You move %i percent slower", GetTrans(), percentage);
        }
        
        strcopy(sDescription, iBufferSize, sBuffer);
    }
}