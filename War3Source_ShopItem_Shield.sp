#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisItem;

public Plugin:myinfo= 
{
	name="War3Source Shop - Shield",
	author="Vulpone&Revan",
	description="War3Source",
	version="1.0",
	url="http://wcs-lagerhaus.de"
};



public OnPluginStart()
{
	LoadTranslations("w3s.item.shield.phrases");
}
public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==24)
	{
	
		thisItem=War3_CreateShopItemT("shield",3,4500);
	}	
}

public OnItemPurchase(client,item)
{
	if(ValidPlayer(client) && item == thisItem)
	{
		War3_SetBuffItem(client,bImmunitySkills,thisItem,true);
		War3_SetOwnsItem(client,item,true);
	}
}

public OnItemLost(client, item)
{
    if(item==thisItem)
    {
        War3_SetBuffItem(client,bImmunitySkills,thisItem,false);
    }
}

public OnWar3EventDeath(victim)
{
	if(War3_GetOwnsItem(victim,thisItem))
	{
		War3_SetOwnsItem(victim,thisItem,false);
		War3_SetBuffItem(victim,bImmunitySkills,thisItem,false);
	}
}
