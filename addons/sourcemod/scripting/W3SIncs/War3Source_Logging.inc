/**
 * File: War3Source_Logging.inc
 * Description: Methods regarding logging
 * Author(s): War3Source Team  
 */

enum War3_LogLevel
{
    LOG_LEVEL_OFF,
    LOG_LEVEL_CRITICAL,
    LOG_LEVEL_ERROR,
    LOG_LEVEL_WARNING,
    LOG_LEVEL_INFO 
};

/**
 * General logging documentation:
 * 
 * When you print log messages there's certain keywords that will get replaced
 * to make the log more readable. The keywords are the following:
 * 
 * {race <raceid>} - replaced with the full name of the race.
 * {item <itemid>} - replaced with the full name of the item.
 * {client <clientid>} - replaced with the name of the client.
 * {attribute <attributeid>} - replaced with the name of the attribute.
 * 
 * {tag} - replaced with [War3Source]
 */

/**
 * Log a info message. Info messages are mainly for debugging.
 */
native War3_LogInfo(const String:fmt[], any:...);

/**
 * Log a warning message. No error yet, but what's happening could lead to an error!
 */
native War3_LogWarning(const String:fmt[], any:...);

/**
 * Log a error message. Something has gone wrong, but we can still continue.
 */
native War3_LogError(const String:fmt[], any:...);

/**
 * Log a critical message. Something has gone very wrong and we're unable to handle it.
 * Also writes the message to the Sourcemod error log
 */
native War3_LogCritical(const String:fmt[], any:...);

/**
 * Get the current log level
 */
native War3_LogLevel:War3_GetLogLevel();