/**
 * File: War3Source_Shopitems.inc
 * Description: Stocks regarding Shopitems
 * Author(s): War3Source Team  
 */

//=======================================================================
//                             NATIVE / STOCKS
//=======================================================================

/**
 * Registers a shop item with the War3Source plugin
 * @param name: The name of the item. 
 * @param shortname: the shortname of the item, must be unique
 * @param desc: The description of the item. 
 * @param cost: The cost of the item 
 * @param lost_upon_death: If true the item will automatically be removed when the player dies. Defaults to true
 * @return The return value will be the item index or -1 if there was a problem.
 */
native War3_CreateShopItem(String:name[], String:shortname[], String:desc[], cost, bool:lost_upon_death=true);
//translated
native War3_CreateShopItemT(String:shortname[], cost, bool:lost_upon_death=true);

//see W3ItemProp enum for available properties
native War3_SetItemProperty(itemid,W3ItemProp:ITEM_PROPERTY,value);
native War3_GetItemProperty(itemid,W3ItemProp:ITEM_PROPERTY);

//remember itemid that is valid is more than 0
//returns -1 if not found
native War3_GetItemIdByShortname(String:itemshortname[]);

native W3GetItemName(itemid,String:ret[],maxlen);
native W3GetItemShortname(itemid,String:ret[],maxlen);
native W3GetItemDescription(itemid,String:ret[],maxlen);

native W3GetItemCost(itemid);
native W3GetItemOrder(itemid);
native W3ItemHasFlag(itemid,String:flagsearch[]);
native W3GetItemCategory(itemid,String:retcatagorystr[],maxlen);
native W3GetItemsLoaded(); //how many items are loaded?

native bool:W3IsItemDisabledGlobal(itemid);
native bool:W3IsItemDisabledForRace(race,itemid);

native GetClientItemsOwned(client);
native GetMaxShopitemsPerPlayer();

//max gold a player can have (cvar read)
native W3GetMaxGold();

/**
 * Gets if the player owns a specific item.
 * @param client: Client index
 * @param item: The item ID returned from War3_CreateShopItem
 * @return The return value will be 1 if they own it, if 0 they don't, if -1 then it failed.
 */
native War3_GetOwnsItem(client, item);
native War3_SetOwnsItem(client,item,bool:ownsitem);

/**
 * After a player has died and this command is invoked they will
 * try to buy all their previously owned items again

 * @param client: Client index
 */
native War3_RestoreItemsFromDeath(client);

//=======================================================================
//                             FORWARDS
//=======================================================================

/**
 * Gets called when a player purchases an item.
 * @param client: The client's index.
 * @param item: The item that was purchased.
 * PLAYER ALREADY HAS OWNERSHIP BY THIS POINT  
 */
forward OnItemPurchase(client, item);

/**
 * Gets called when a player loses an item. (after death (ownership to false) or traded it back..)
 * @param client: The client's index.
 * @param item: The item that was purchased.
 * PLAYER ALREADY HAS LOST OWNERSHIP BY THIS POINT   
 */
forward OnItemLost(client, item);
