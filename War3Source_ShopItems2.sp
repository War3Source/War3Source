/**
 * File: War3Source_ShopItems.sp
 * Description: The shop items that come with War3Source.
 * Author(s): Anthony Iacono
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>

#include <cstrike>

enum ITEMENUM{ ///
	POSTHASTE=0,
	TRINKET,
	LIFETUBE,
	/*
	//basic "Accessories"
	striders
	Fortified Bracelet
	soulscream ring , Alchemist's Bones, charged hammer
	Trinket of Restoration
	sustainer
	
	//support
	ring of the teacher
	Refreshing Ornament
	Shield of the Five
	helm
	headdress
	
	//protective
	Iron Shield
	daemonic breastplate
	frostfield plate	
	behe's heart
	snake bracelet
	barbed armor
	//combata
	spell shards??? needs some recoding
	thunderclaw
	modk of brilliance
	warclept - attack speed
	//morph 
	shiel dbreakder
	frostburn
	some leech 
	
	
	
	
	
	
	*/
}
new ItemID[ITEMENUM];

public Plugin:myinfo = 
{
	name = "W3S - Shopitems2",
	author = "Ownz",
	description = "The shop items that come with War3Source.",
	version = "1.0.0.0",
	url = "http://war3source.com/"
};

public OnPluginStart()
{
	
	
}

public OnWar3LoadRaceOrItemOrdered(num)
{
//DP("%d",EXT());
	if(num==10&&EXT()){
	//War3_CreateShopItem2
	//W3CreateShopItem2
		ItemID[POSTHASTE]=W3CreateShopItem2("Post Hasteut","posthaste","+3% speedut",10,true);
		//new String:foo[32];
		//W3GetItem2Name(ItemID[POSTHASTE],foo,32);
		//DP("%s",foo);
		ItemID[TRINKET]=W3CreateShopItem2("Trinket of Restoration","trinket","+0.5 HP regeneration",15,false);
		ItemID[LIFETUBE]=W3CreateShopItem2("Lifetube","lifetube","+1 HP regeneration",40,false);
	}
}
public OnMapStart()
{
	
}

public OnItem2Purchase(client,item)
{
//DP("purchase %d %d",client,item);
	if(item==ItemID[POSTHASTE] )
	{
		War3_SetBuffItem2(client,fMaxSpeed2,ItemID[POSTHASTE],1.034);
	}
	if(item==ItemID[TRINKET] ) 
	{
		War3_SetBuffItem2(client,fHPRegen,ItemID[TRINKET],0.5);
	}
	if(item==ItemID[LIFETUBE] ) 
	{
		War3_SetBuffItem2(client,fHPRegen,ItemID[LIFETUBE],1.0);
	}
}

public OnItem2Lost(client,item){ //deactivate passives , client may have disconnected
//DP("lost %d %d",client,item);
	if(item==ItemID[POSTHASTE]){
		War3_SetBuffItem2(client,fMaxSpeed2,ItemID[POSTHASTE],1.0);
	}
	if(item==ItemID[TRINKET] ) // boots of speed
	{
		War3_SetBuffItem2(client,fHPRegen,ItemID[TRINKET],0.0);
	}
	if(item==ItemID[LIFETUBE] ) // boots of speed
	{
		War3_SetBuffItem2(client,fHPRegen,ItemID[LIFETUBE],0.0);
	}
}
