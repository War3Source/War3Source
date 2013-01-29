/**
 * File: War3Source_Attributes.inc
 * Description: Manage War3Source attributes
 * Author(s): War3Source Team  
 */

native War3_RegisterAttribute(String:sAttributeName[], String: sAttributeShortName[], any:DefaultVal);
native War3_GetAttributeName(attributeId, String:sName[], iBufferSize);
native War3_GetAttributeShortname(attributeId, String:sShortname[], iBufferSize);
native War3_GetAttributeIDByShortname(String:sAttributeShortName[]);
native any:War3_GetAttributeValue(client, attributeId);
native War3_SetAttribute(client, attributeId, any:value);
native War3_GetAttributeDescription(client, attributeId, any:value, String:sDescription[], iBufferSize);

forward War3_OnAttributeChanged(client, attributeId, any:oldValue, any:newValue);
forward War3_OnAttributeDescriptionRequested(client, attributeId, any:value, String:sDescription[], iBufferSize);