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
 * @return The return value will be the item index or -1 if there was a problem.
 */
native War3_CreateShopItem(String:name[],String:shortname[],String:desc[],costgold,costmoney);
//translated
native War3_CreateShopItemT(String:shortname[],costgold,costmoney);

//see W3ItemProp enum for available properties
native War3_SetItemProperty(itemid,W3ItemProp:ITEM_PROPERTY,value);
native War3_GetItemProperty(itemid,W3ItemProp:ITEM_PROPERTY);

//remember itemid that is valid is more than 0
//returns -1 if not found
native War3_GetItemIdByShortname(String:itemshortname[]);

native W3GetItemName(itemid,String:ret[],maxlen);
native W3GetItemShortname(itemid,String:ret[],maxlen);
native W3GetItemDescription(itemid,String:ret[],maxlen);

native W3GetItemCost(itemid,bool:csmoney);
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
 * When a player dies, this command record's their shopmenu1 items.
 * When you use this command, you are telling it to restore their items from death.
 * It does all the math as far as taking gold or cs money for items restored.
 * It will let the client know what items are discarded and/or bought.
 * It will also only buy until the client goes broke.
 * If the client already owns some items from the list from death, it will not charge them.
 * It only charges for the items that the client must buy to match the items from death.
 * It discards items that does not match from the previous death list.
 * Note: The no cost method still needs work.
 * @param client: Client index
 * @param payforit: false = no cost, true = charge
 * @param csmoney: true is cs money, false for gold.
 * @return The return value will be true if it is successful.
 */
native War3_RestoreItemsFromDeath(client,bool:payforit=true,bool:csmoney=false);

native bool:W3BuyUseCSMoney();

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
