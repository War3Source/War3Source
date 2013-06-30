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
native War3_CreateShopItem2(String:name[], String:shortname[], String:desc[], cost, bool:lost_upon_death=true);
//translated
native War3_CreateShopItem2T(String:shortname[], cost, bool:lost_upon_death=true);

//see W3ItemProp enum for available properties
native War3_SetItem2Property(itemid,W3ItemProp:ITEM_PROPERTY,value);
native War3_GetItem2Property(itemid,W3ItemProp:ITEM_PROPERTY);

//remember itemid that is valid is more than 0
//returns -1 if not found
native War3_GetItem2IdByShortname(String:itemshortname[]);

native W3GetItem2Name(itemid,String:ret[],maxlen);
native W3GetItem2Shortname(itemid,String:ret[],maxlen);
native W3GetItem2Desc(itemid,String:ret[],maxlen);

native W3GetItem2Cost(itemid);
native W3GetItem2Order(itemid);
native W3Item2HasFlag(itemid,String:flagsearch[]);
native W3GetItem2Category(itemid,String:retcatagorystr[],maxlen);
native W3GetItems2Loaded(); //how many items are loaded?

native bool:W3IsItem2DisabledGlobal(itemid);
native bool:W3IsItem2DisabledForRace(race,itemid);

/**
 * Gets if the player owns a specific item.
 * @param client: Client index
 * @param item: The item ID returned from War3_CreateShopItem
 * @return The return value will be 1 if they own it, if 0 they don't, if -1 then it failed.
 */
native War3_GetOwnsItem2(client, item);
native War3_SetOwnsItem2(client,item,bool:ownsitem);


native GetClientItems2Owned(client);
native GetMaxShopitems2PerPlayer();


//=======================================================================
//                             FORWARDS
//=======================================================================

/**
 * Gets called when a player purchases an item.
 * @param client: The client's index.
 * @param item: The item that was purchased.
 * PLAYER ALREADY HAS OWNERSHIP BY THIS POINT  
 */
forward OnItem2Purchase(client, item);

/**
 * Gets called when a player loses an item. (after death (ownership to false) or traded it back..)
 * @param client: The client's index.
 * @param item: The item that was purchased.
 * PLAYER ALREADY HAS LOST OWNERSHIP BY THIS POINT   
 */
forward OnItem2Lost(client, item);