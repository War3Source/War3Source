/**
 * File: War3Source_AttributeBuffs.inc
 * Description: Manage War3Source attributes
 * Author(s): War3Source Team  
 */

/**
 * Attributes are supposed to supersede the current War3 buff implementations
 * 
 * They are not functional right now as they're still in development.
 * Some documentation can be found here: https://github.com/War3Source/War3Source/issues/48
 */

enum W3BuffSource {
    BUFF_SKILL,
    BUFF_ITEM,
};

enum W3BuffType {
    BUFFTYPE_BUFF,
    BUFFTYPE_DEBUFF,
};

#define BUFF_EXPIRES_ON_DEATH       (0 << 0)
#define BUFF_EXPIRES_ON_SPAWN       (1 << 0)
#define BUFF_EXPIRES_ON_ROUNDEND    (1 << 1)
#define BUFF_EXPIRES_ON_TIMER       (1 << 2)
#define BUFF_EXPIRES_ON_RACECHANGE  (1 << 3)

// ------------------------------------------------------------------------------------------------------------------------------------------------------


native War3_ApplyTimedBuff(client, attributeId, any:value, Float:fDuration, 
                           W3BuffSource:sourceType, source, expireFlag, 
                           bool:bCanStack);

native War3_ApplyTimedDebuff(client, attributeId, any:value, Float:fDuration, 
                             W3BuffSource:sourceType, source, expireFlag, 
                             bool:bCanStack);
