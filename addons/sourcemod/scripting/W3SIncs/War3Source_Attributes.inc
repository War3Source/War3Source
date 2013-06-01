/**
 * File: War3Source_Attributes.inc
 * Description: Manage War3Source attributes
 * Author(s): War3Source Team  
 */

/**
 * Attributes are supposed to supersede the current War3 buff implementations
 * 
 * They are not functional right now as they're still in development.
 * Some documentation can be found here: https://github.com/War3Source/War3Source/issues/48
 */

enum AttributeType {
    TYPE_FLOAT,
    TYPE_INTEGER,
    TYPE_BOOLEAN
};

#define INVALID_ATTRIBUTE           -1

// ------------------------------------------------------------------------------------------------------------------------------------------------------

// Create new attributes

native War3_RegisterAttribute(String:sAttributeName[], String: sAttributeShortName[], AttributeType:AttrType, any:DefaultVal, any:MinValue, any:MaxValue);

// ------------------------------------------------------------------------------------------------------------------------------------------------------

// Getters to access the data structure

native War3_GetAttributeName(attributeId, String:sName[], iBufferSize);
native War3_GetAttributeShortname(attributeId, String:sShortname[], iBufferSize);
native War3_GetAttributeIDByShortname(String:sAttributeShortName[]);
native War3_GetAttributeDescription(client, attributeId, any:value, String:sDescription[], iBufferSize);
native any:War3_GetAttributeValue(client, attributeId);

// ------------------------------------------------------------------------------------------------------------------------------------------------------

// Functions to modify the values of an attribute. You usually don't want to use these,
// instead have a look at War3Source_AttributeBuffs.inc on how to make buffs that modify a attribute!

native War3_AddToAttribute(client, attributeId, any:value);
native War3_SubstractFromAttribute(client, attributeId, any:value);

// This sets attribute directly. Designed for internal usage, be careful with this one!
//native War3_SetAttribute(client, attributeId, any:value);

// Reset all attributes to their default
native War3_ResetAttributes(client);

// ------------------------------------------------------------------------------------------------------------------------------------------------------

// Events

forward War3_OnAttributeChanged(client, attributeId, any:oldValue, any:newValue);
forward War3_OnAttributeDescriptionRequested(client, attributeId, any:value, String:sDescription[], iBufferSize);