/**
 * File: War3Source_Addon_AmmoControl.sp
 * Description: Ammo Control Addon for War3Source.
 * Author(s): Frenzzy
 * 
 * http://war3source.com/index.php?topic=525.0  
 */

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = {
	name = "W3S Addon - Use Your Damn Gold",
	author = "Ownz ",
	description = "",
	version = "1.0",
	url = "http://www.ownageclan.com/"
};

new Handle:cvaritemtobuy;
public OnPluginStart()
{
	cvaritemtobuy=CreateConVar("war3_autobuy_on_max_gold","lace","automatically buy this item if their gold is full");
}
public OnWar3EventSpawn(client){
	//DP("1 %d %d %d %d",client,!W3BuyUseCSMoney(),W3GetMaxGold()==War3_GetGold(client),IsPlayerAlive(client));
	//W3Hint(client,HINT_NORMAL,5.0,"Your gold is maxed out");
	//W3Hint(client,HINT_NORMAL,5.0,"%s","Your gold is maxed out");
	//W3Hint(client,HINT_LOWEST,5.0,"Your gold is maxed out");
	
	if(!W3BuyUseCSMoney()&&W3GetMaxGold()==War3_GetGold(client)){
		decl String:itemshort[32];
		GetConVarString(cvaritemtobuy,itemshort,sizeof(itemshort));
		new item=War3_GetItemIdByShortname(itemshort);
		//DP("2 %d",item);
		if(item>0){
				//DP("3");
			if(!War3_GetOwnsItem(client,item) && GetClientItemsOwned(client) == 0 ){
					//DP("4");
				W3SetVar(EventArg1,item);
				W3SetVar(EventArg2,false);
				W3CreateEvent(DoTriedToBuyItem,client);
				
				if(War3_GetOwnsItem(client,item)){
					
					War3_ChatMessage(client,"Your gold is maxed out, we bought an item for you. Say shopmenu to use your gold");
					W3Hint(client,_,15.0,"Your gold is maxed out\nSay shopmenu to use your gold!");
					 //blank like forcing refresh after 0.2 sec
				}
			}
		}
	}
}
