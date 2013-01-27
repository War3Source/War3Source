/**
 * File: War3Source_Attributes.inc
 * Description: Manage War3Source attributes
 * Author(s): War3Source Team  
 */

native War3_RegisterAttribute(String:sAttributeName[], String: sAttributeShortName[], any:DefaultVal);
native War3_GetAttributeName(attributeId, String:sName[], iBufferSize);
native War3_GetAttributeShortname(attributeId, String:sShortname[], iBufferSize);
native War3_GetAttributeIDByShortname(String:sAttributeShortName[]);
native War3_GetAttributeValue(client, attributeId);
native War3_SetAttribute(client, attributeId, value);

forward War3_OnAttributeChanged(client, attributeId, any:oldValue, any:newValue);