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

/*public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
    new Oil_item = War3_GetItemIdByShortname("oil");
    new Owns_item = War3_GetOwnsItem(attacker,Oil_item);

	if(Owns_item==1)
    {

    }


if(War3_GetRace(attacker)==thisRaceID)
    {
        if(ARMOR_ENABLED[attacker])
        {
        //W3FlashScreen(attacker,RGBA_COLOR_YELLOW);
        War3_DamageModPercent(1.50);
        }
        else
        {
        War3_DamageModPercent(0.50);
        }
    }

}*/