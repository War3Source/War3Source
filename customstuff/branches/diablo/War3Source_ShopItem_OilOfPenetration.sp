
#pragma semicolon 1
#pragma tabsize 0     // doesn't mess with how you format your lines

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisItem;

public Plugin:myinfo= {
	name="NGU Clan - Oil of Penetration",
	author="El Diablo (ideas by Axin)",
	description="Coats your weapons with ability to penetrate armor.",
	version="1.0",
	url="http://www.nguclan.com"
};



public OnPluginStart()
{
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==1){

		thisItem=War3_CreateShopItem("Oil of Penetration","oil",
        "Coats your weapons with ability to penetrate armor.",8,3500);
	}
}

public OnWar3EventDeath(victim){
	if(War3_GetOwnsItem(victim,thisItem)){
		War3_SetOwnsItem(victim,thisItem,false);
	}
}
