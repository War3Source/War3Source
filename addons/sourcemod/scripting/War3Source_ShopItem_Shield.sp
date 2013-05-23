#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Shopitem - Shield",
    author = "War3Source Team",
    description = "Become immune to abilitys"
};

new thisItem;

new Handle:ShieldRestrictionCvar; 

public OnPluginStart()
{
    ShieldRestrictionCvar=CreateConVar("war3_shop_shield_restriction", "0", "Set this to 1 if you want to forbid necklace + shield. 0 default");
    
    LoadTranslations("w3s.item.shield.phrases");
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
    if(num == 24)
    {
        thisItem = War3_CreateShopItemT("shield", 3);
        
        War3_AddItemBuff(thisItem, bImmunitySkills, true);
    }
}

public OnW3Denyable(W3DENY:event, client)
{
    if(event == DN_CanBuyItem1)
    {
        new itemToPurchase = W3GetVar(EventArg1);
        new lace = War3_GetItemIdByShortname("lace");
        new bool:bItemRestricted = GetConVarBool(ShieldRestrictionCvar);
        if(!bItemRestricted)
        {
            return;
        }
        
        if((itemToPurchase == thisItem && War3_GetOwnsItem(client, lace)) || (itemToPurchase == lace && War3_GetOwnsItem(client, thisItem)))
        {
            W3Deny();
            War3_ChatMessage(client, "Error purchase Holy Shield! Cannot wear Necklace and Shield at the same time.");
        }
    }
}