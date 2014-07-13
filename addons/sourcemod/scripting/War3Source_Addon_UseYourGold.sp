#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Addon - Use Your Gold",
    author = "War3Source Team",
    description = "Makes players automatically buy an item when they have maxed out their wallet"
};

new Handle:g_hItemToBuyCvar;

public OnPluginStart()
{
    g_hItemToBuyCvar = CreateConVar("war3_autobuy_on_max_currency", "lace", "Shortname for the item to buy when you have max currency");
    LoadTranslations("w3s.addon.useyourmoney.phrases.txt");
}

public OnWar3EventSpawn(client)
{
    if(War3_GetMaxCurrency() == War3_GetCurrency(client))
    {
        decl String:itemshort[32];
        GetConVarString(g_hItemToBuyCvar, itemshort, sizeof(itemshort));
        new item = War3_GetItemIdByShortname(itemshort);

        if(item <= 0)
        {
            return;
        }
        
        if(!War3_GetOwnsItem(client, item) && GetClientItemsOwned(client) == 0 )
        {
            new cost = W3GetItemCost(item);
            if(cost <= War3_GetCurrency(client))
            {
                W3SetVar(EventArg1, item);
                W3SetVar(EventArg2, false);
                W3CreateEvent(DoTriedToBuyItem, client);
                
                if(War3_GetOwnsItem(client, item))
                {
                    War3_ChatMessage(client,"%T","Your money is maxed out, we bought an item for you. Say shopmenu to use your money", client);
                    W3Hint(client, HINT_LOWEST, 5.0, "%T", "Your money is maxed out\nSay shopmenu to use your money!", client);
                }
            }
        }
    }
}
