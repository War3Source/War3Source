#if defined _stamm_included
  #endinput
#endif
#define _stamm_included

/**
 * Executes when a player becomes VIP
 *
 * @param client		Client.
 */
forward OnClientBecomeVip(client);

/**
 * Executes when Stamm is fully loaded
 */
forward OnStammReady();

/**
 * Executes when a player is fully initialized by Stamm after connecting
 *
 * @param client		Client.
 */
forward OnStammClientReady(client);

/**
 * Executes when a player is saved
 *
 * @param client		Client.
 */
forward OnStammSaveClient(client);

/**
 * Executes when a player switched a Feature on/off
 *
 * @param client		Client.
 * @param basename		Basename of the Feature he changed.
 * @param mode			1 = Switched on, 0 = Switched off.
 */
forward OnClientChangeStammFeature(client, String:basename[], mode);

/**
 * Executes when a player gets Stamm Points
 *
 * @param client		Client.
 * @param number		The number of points, the player gets.
 */
forward OnClientGetStammPoints(client, number);

/**
 * Executes when Happy Hour starts
 *
 * @param time			runtime in seconds 
 * @param factor		factor.
 */
forward OnHappyHourStart(time, factor);

/**
 * Executes when Happy Hour ends
 *
 */
forward OnHappyHourEnd();


/**
 * Adds a new Stamm Feature
 *
 * @param basename		Your Plugin basename, without .smx.
 * @param name			Short Name of the Plugin.
 * @param description	What Feature it is (this will be added on the Feature list, so start with: VIP's get... or similar and add it to the stamm-feature Phrase!).
 * @return				level need for this Feature, -1 = fail, x = level
 */
native AddStammFeature(String:basename[], String:name[], String:description[]);

/**
 * Return the Number of Points of a player
 *
 * @param client		Client.
 * @return				Points of Player or -1 on error.
 * @error				Client is invalid, BOT or not connected!
 */
native GetClientStammPoints(client);

/**
 * Return the name of a specific Level
 *
 * @param type			0 = Normal VIP, x = Level.
 * @param name			String to save name in
 * @param maxlength		maxlength of string
 * @noreturn
 * @error				Stamm Level is OFF and stamm level enable.
 */
native GetStammLevelName(type, String:name[], maxlength);

/**
 * Return how much Points a player need for a specific Level
 *
 * @param type			0 = Normal VIP, x = Level.
 * @return				How much Points a Client needs, or -1 on Error.
 * @error				Stamm Level is OFF and stamm level enable.
 */
native GetStammLevelPoints(type);

/**
 * Return how much levels are set
 *
 * @return				How much levels are set
 */
native GetStammLevelCount();

/**
 * Return how to get Points
 *
 * @return				0 = Error, 1 = Kills, 2 = Rounds, 3 = Time.
 */
native GetStammType();

/**
 * Set Points of a player
 *
 * @param client		Client.
 * @param number		Number of Points to set.
 * @noreturn
 * @error				Client is invalid, BOT or not connected! Invalid number!
 */
native SetClientStammPoints(client, number);

/**
 * Add Points to a player
 *
 * @param client		Client.
 * @param number		Number of Points to add.
 * @noreturn
 * @error				Client is invalid, BOT or not connected! Invalid number!
 */
native AddClientStammPoints(client, number);

/**
 * Delete Points from a player
 *
 * @param client		Client.
 * @param number		Number of Points to delete.
 * @noreturn
 * @error				Client is invalid, BOT or not connected! Invalid number!
 */
native DelClientStammPoints(client, number);

/**
 * Return true when the specific player is VIP, otherwise false
 *
 * @param client		Client.
 * @param type			0 = normal VIP, x = Level.
 * @param min			true = Minimum rang, false = Exact Rang.
 * @return				true if Client is VIP, otherwise false.
 * @error				Client is invalid, BOT or not connected! Stamm Level is OFF.
 */
native bool:IsClientVip(client, type, bool:min=true);

/**
 * Return true when the specific player is complete loaded by Stamm, otherwise false
 *
 * @param client		Client.
 * @return				true if fully loaded, otherwise false.
 */
native bool:IsStammClientValid(client);

/**
 * Return true when the specific player is a Stamm admin, otherwise false
 *
 * @param client		Client.
 * @return				true if admin, otherwise false.
 */
native bool:IsClientStammAdmin(client);

/**
 * Return true when the specific player enabled this feature, false otherwise
 *
 * @param client		Client.
 * @param basename		Your Plugin Basename.
 * @return				true if the player wants, otherwise false.
 */
native bool:ClientWantStammFeature(client, String:basename[]);

/**
 * Return true when Stamm Level is ON, otherwise false
 *
 * @return				true if Stamm Level is on, otherwise false.
 */
native bool:IsStammLevelOn();

/**
 * Starts Happy Hour
 *
 * @param time			Time in minutes (> 1).
 * @param factor		factor.
 * @noreturn
 * @error				time, factor invalid or happy our already active.
 */
native StartHappyHour(time, factor);

/**
 * Ends Happy Hour
 *
 * @noreturn
 * @error				happy our not active.
 */
native EndHappyHour();

/**
 * Loads a Stamm Feature
 *
 * @param basename		Basename of the Feature
 * @return				-1 = already loaded, 0 = no such Feature, 1 = success
 */
native LoadFeature(String:basename[]);

/**
 * Unloads a Stamm Feature
 *
 * @param basename		Basename of the Feature
 * @return				-1 = already unloaded, 0 = no such Feature, 1 = success
 */
native UnloadFeature(String:basename[]);

/**
 * Logs a Message to the Stamm Log File
 *
 * @param fmt         Format string.
 * @param ...         Format arguments.
 *
 * @noreturn
 */
native WriteToStammLog(const String:fmt[], any:...);

public SharedPlugin:__pl_stamm = 
{
	name = "stamm",
	file = "stamm.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_stamm_SetNTVOptional()
{
	MarkNativeAsOptional("AddStammFeature");
	MarkNativeAsOptional("GetClientStammPoints");
	MarkNativeAsOptional("GetStammLevelName");
	MarkNativeAsOptional("GetStammLevelPoints");
	MarkNativeAsOptional("GetStammLevelCount");
	MarkNativeAsOptional("GetStammType");
	MarkNativeAsOptional("SetClientStammPoints");
	MarkNativeAsOptional("AddClientStammPoints");
	MarkNativeAsOptional("DelClientStammPoints");
	MarkNativeAsOptional("IsClientVip");
	MarkNativeAsOptional("IsStammClientValid");
	MarkNativeAsOptional("IsClientStammAdmin");
	MarkNativeAsOptional("ClientWantStammFeature");
	MarkNativeAsOptional("IsStammLevelOn");
	MarkNativeAsOptional("StartHappyHour");
	MarkNativeAsOptional("EndHappyHour");
	MarkNativeAsOptional("LoadFeature");
	MarkNativeAsOptional("UnloadFeature");
	MarkNativeAsOptional("WriteToStammLog");
}
#endif
