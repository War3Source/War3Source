/**
 * File: War3Source_ShopItems.sp
 * Description: The shop items that come with War3Source.
 * Author(s): Anthony Iacono
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <cstrike>
///not needed #define REQUIRE_EXTENSIONS

enum ITEMENUM{ ///
	POSTHASTE=0,
	
}
new ItemID[ITEMENUM];

public Plugin:myinfo = 
{
	name = "War3Source - Shopitems2",
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
	if(num==10){
		ItemID[POSTHASTE]=War3_CreateShopItem2("Post Haste","posthaste","+3% speed",1);
	}
}
public OnMapStart()
{
	
}

public OnItem2Purchase(client,item)
{
	if(item==ItemID[POSTHASTE] ) // boots of speed
	{
		War3_SetBuffItem2(client,fMaxSpeed2,ItemID[POSTHASTE],1.039);
	}
}

public OnItem2Lost(client,item){ //deactivate passives , client may have disconnected

	if(item==ItemID[POSTHASTE]){
		War3_SetBuffItem2(client,fMaxSpeed2,ItemID[POSTHASTE],1.0);
	}
	
}
