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

enum W3AttributeModificationSourceType {
    MODIFICATION_SKILL,
    MODIFICATION_ITEM,
};

enum W3AttributeModificationType {
    MODIFICATION_TYPE_BUFF,
    MODIFICATION_TYPE_DEBUFF,
};

#define MODIFICATION_EXPIRES_ON_DEATH      (0 << 0)
#define MODIFICATION_EXPIRES_ON_SPAWN      (1 << 0)
#define MODIFICATION_EXPIRES_ON_ROUNDEND   (1 << 1)
#define MODIFICATION_EXPIRES_ON_TIMER      (1 << 2)

// ------------------------------------------------------------------------------------------------------------------------------------------------------

// Create new attributes

native War3_RegisterAttribute(String:sAttributeName[], String: sAttributeShortName[], any:DefaultVal);

// ------------------------------------------------------------------------------------------------------------------------------------------------------

// Getters to access the data structure

native War3_GetAttributeName(attributeId, String:sName[], iBufferSize);
native War3_GetAttributeShortname(attributeId, String:sShortname[], iBufferSize);
native War3_GetAttributeIDByShortname(String:sAttributeShortName[]);
native War3_GetAttributeDescription(client, attributeId, any:value, String:sDescription[], iBufferSize);
native any:War3_GetAttributeValue(client, attributeId);

// ------------------------------------------------------------------------------------------------------------------------------------------------------



// Natives for modifying

native War3_ModifyAttributeTimed(client, attributeId, any:value, Float:fDuration, 
                                 W3AttributeModificationSourceType:sourceType, source, expireFlag, 
                                 W3AttributeModificationType:modificationType, bool:bCanStack);

// This adds the given value to the current value of the attribute
// So passing -5 to the function would reduce the current value by 5, etc.
// this is permanent, so handle with care!
native War3_ModifyAttribute(client, attributeId, any:value);

// This sets attribute directly. Designed for internal usage, be careful with this one!
native War3_SetAttribute(client, attributeId, any:value);

// ------------------------------------------------------------------------------------------------------------------------------------------------------

// Events

forward War3_OnAttributeChanged(client, attributeId, any:oldValue, any:newValue);
forward War3_OnAttributeDescriptionRequested(client, attributeId, any:value, String:sDescription[], iBufferSize);

