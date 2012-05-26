#pragma semicolon 1

#include <sourcemod>
//#include <sdktools_functions>
#include "W3SIncs/War3Source_Interface"

new thisItem;

public Plugin:myinfo= {
	name="War3Source Shopitem - (Medic Only) Insta Uber",
	author="El Diablo",
	description="War3Source",
	version="1.0",
	url="http://www.nguclan.com/"
};



public OnPluginStart()
{
	LoadTranslations("w3s.item.uberme.phrases");
}
public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==10)
	{
		thisItem=War3_CreateShopItemT("uberme",100,3000);
	}	
}

public OnWar3Event(W3EVENT:event, client)
{
	if(event == CanBuyItem)
	{
        new item = W3GetVar(EventArg1);
        if(item==thisItem && TF2_GetPlayerClass(client)!=TFClass_Medic)
            {
                W3SetVar(EventArg2, 0);
                War3_ChatMessage(client, "Only Medics can buy this item!");
                //War3_SetGold(client,100);
                //War3_SetOwnsItem(client,item,false);
                //PrintToChat(client,"Store refunded your gold.");
            }
        else W3SetVar(EventArg2, 1);
	}
}

public OnItemPurchase(client,item)
{
	if(item==thisItem&&ValidPlayer(client) && TF2_GetPlayerClass(client)==TFClass_Medic)
        {
        if (GetEntProp(client, Prop_Send, "m_iClass") == 5)
            {
            //`EquipPlayerWeapon(client, tf_weapon_medigun);
            TF_SetUberLevel(client, 100.0);
            War3_SetOwnsItem(client,item,false);
            }
	       //War3_SetOwnsItem(client,item,true);
	       //War3_SetBuffItem(client,fArmorPhysical,item,6.0);
        }
}

stock TF_SetUberLevel(client, Float:uberlevel)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
		SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel*0.01);
}

/*
public OnWar3EventDeath(victim){
	if(War3_GetOwnsItem(victim,thisItem)){
		War3_SetOwnsItem(victim,thisItem,false);
		War3_SetBuffItem(victim,fArmorPhysical,thisItem,0.0);
	}
}
*/