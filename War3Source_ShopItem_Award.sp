#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisItem;

public Plugin:myinfo= {
	name="War3Source Shopitem - AntiWard",
	author="[I]Loki",
	description="War3Source",
	version="1.0",
	url="http://Arsenall.NET/"
};



public OnPluginStart()
{
	LoadTranslations("w3s.item.award.phrases");
}
public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==12)
	{
		thisItem=War3_CreateShopItemT("award",3,3000);
	}	
}

public OnItemPurchase(client,item)
{
	if(item==thisItem&&ValidPlayer(client))
	{
		War3_SetOwnsItem(client,item,true);
		War3_SetBuffItem(client,bImmunityWards,item,true);
	}
}

public OnWar3EventDeath(victim){
	if(War3_GetOwnsItem(victim,thisItem)){
		War3_SetOwnsItem(victim,thisItem,false);
		War3_SetBuffItem(victim,bImmunityWards,thisItem,false);
	}
}