#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisItem;

new MoneyOffsetCS;
new Handle:ShieldRestrictionCvar; 

public Plugin:myinfo= 
{
	name="War3Source Shop - Shield",
	author="Vulpone&Revan",
	description="War3Source item: Holy Shield. Blocks abilities.Thanks to Necavi, Ownz, Glider, Revan & the rest.",
	version="1.0",
	url="http://wcs-lagerhaus.de"
};



public OnPluginStart()
{
	ShieldRestrictionCvar=CreateConVar("war3_shop_shield_restriction","0","Set this to 1 if you want to forbid necklace+shield. 0 default");
	LoadTranslations("w3s.item.shield.phrases");
	if(GAMECSANY){
		MoneyOffsetCS=FindSendPropInfo("CCSPlayer","m_iAccount");
	}
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==24)
	{
		thisItem=War3_CreateShopItemT("shield",3,2000);
	}	
}


public OnItemPurchase(client,item)
{
	if(ValidPlayer(client))
	{
		if(item == thisItem)
		{
			if(GetConVarBool(ShieldRestrictionCvar))
			{
				new lace = War3_GetItemIdByShortname("lace");
				if(!War3_GetOwnsItem(client, lace) || item == lace && !War3_GetOwnsItem(client, thisItem))
				{
					War3_SetBuffItem(client,bImmunitySkills,thisItem,true);
					War3_SetOwnsItem(client,item,true);
				}
				//what if HAS necklace and wants to buy shield?
				else if(item == thisItem && War3_GetOwnsItem(client, lace))
				{
					if(W3BuyUseCSMoney())
					{
						new iShieldCostDollar = W3GetItemCost(thisItem,true);
						SetMoney(client, GetMoney(client)+iShieldCostDollar);
					}
					else
					{
						new iShieldCost = W3GetItemCost(thisItem, false);
						War3_SetGold(client, War3_GetGold(client)+ iShieldCost);
					}
					
		/*Assuming this function now returns the gold/silver/credits/dollar used. If this returns any less or more than the exact cost integer, I'm totally screwed and Glider will burn my ass alive! Not to mention Ownz; he will probably get his Pony army and hug me to death.*/
				
				
					War3_SetBuffItem(client,bImmunitySkills,thisItem,false);
					War3_SetOwnsItem(client,item,false);
				
					War3_ChatMessage(client, "Error purchase Holy Shield! Cannot wear Necklace and Shield at the same time. Refunding...");
				}
				//what if he HAS Shield and wants to buy necklace?
				else if(item == lace && War3_GetOwnsItem(client, thisItem))
				{
					if(W3BuyUseCSMoney())
					{
						new iLaceCostDollar = W3GetItemCost(lace,true);
						SetMoney(client, GetMoney(client)+iLaceCostDollar);
					}
					else
					{
						new iLaceCost = W3GetItemCost(lace, false);
						War3_SetGold(client, War3_GetGold(client)+ iLaceCost);
					}
					
					War3_SetBuffItem(client,bImmunityUltimates,lace,false);
					War3_SetOwnsItem(client, item, false);
					
					War3_ChatMessage(client, "Error purchasing Necklace of Immunity! Cannot wear Necklace and Shield at the same time. Refunding...");
				}
			}
			
			//if he allows both items, thank you! This option saves time and neurons
			else
			{
				War3_SetBuffItem(client,bImmunitySkills,thisItem,true);
				War3_SetOwnsItem(client,item,true);
			}
				
		}
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


stock GetMoney(player)
{
	return GetEntData(player,MoneyOffsetCS);
}

stock SetMoney(player,money)
{
	SetEntData(player,MoneyOffsetCS,money);
}
