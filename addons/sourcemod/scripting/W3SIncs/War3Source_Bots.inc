/**
 * File: War3Source_Bots.inc
 * Description: Methods regarding bots
 * Author(s): War3Source Team  
 */

/**
 * Force a fake client to distribute his skillpoints
 *
 * @param client: client index
 */
native bool:War3_bots_distribute_sp(client);

/**
 * Make a fake client pick a random race he has access to and pick a random level
 *
 * @param client: client index
 */
native bool:War3_bots_pickrace(client);
