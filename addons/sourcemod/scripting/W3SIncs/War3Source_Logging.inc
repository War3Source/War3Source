/**
 * File: War3Source_Logging.inc
 * Description: Methods regarding logging
 * Author(s): War3Source Team  
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
 */
native War3_LogCritical(const String:fmt[], any:...);

/**
 * Get the current log level
 */
native War3_LogLevel:War3_GetLogLevel();