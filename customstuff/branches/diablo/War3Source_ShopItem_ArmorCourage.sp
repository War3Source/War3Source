#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisItem;

public Plugin:myinfo= {
	name="War3Source Shopitem - Armor of Courage",
	author="Axin & El Diablo",
	description="War3Source",
	version="1.0",
	url="http://www.nguclan.com/"
};



public OnPluginStart()
{
	LoadTranslations("w3s.item.courage.phrases");
}
public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==10)
	{
		thisItem=War3_CreateShopItemT("courage",4,3000);
	}	
}

public OnItemPurchase(client,item)
{
	if(item==thisItem&&ValidPlayer(client))
	{
		War3_SetOwnsItem(client,item,true);
		War3_SetBuffItem(client,fArmorPhysical,item,7.5);
	}
}

public OnWar3EventDeath(victim){
	if(War3_GetOwnsItem(victim,thisItem)){
		War3_SetOwnsItem(victim,thisItem,false);
		War3_SetBuffItem(victim,fArmorPhysical,thisItem,0.0);
	}
}