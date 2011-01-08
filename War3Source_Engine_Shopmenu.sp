



#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


public Plugin:myinfo= 
{
	name="War3Source Menus Shopmenus",
	author="Ownz",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};

new Handle:hBuyItemUseCSMoneCvar;


new Handle:hCvarMaxShopitems;

public APLRes:AskPluginLoad2(Handle:myself,bool:late,String:error[],err_max)
{
	if(!InitNativesForwards())
	{
		LogError("[War3Source] There was a failure in creating the native / forwards based functions, definately halting.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	hBuyItemUseCSMoneCvar=CreateConVar("war3_buyitems_csmoney","0","In CS, use cs money to buy shopmenu items");
	
	hCvarMaxShopitems=CreateConVar("war3_max_shopitems","3");
	
}

bool:InitNativesForwards()
{

	return true;
}
public OnWar3Event(W3EVENT:event,client){
	if(event==DoShowShopMenu){
		ShowMenuShop(client);
	}
	if(event==DoTriedToBuyItem){ //via say?
		War3_TriedToBuyItem(client,W3GetVar(EventArg1));
	}
}
new WantsToBuy[MAXPLAYERS];

ShowMenuShop(client){
	SetTrans(client);
	new Handle:shopMenu=CreateMenu(War3Source_ShopMenu_Selected);
	SetMenuExitButton(shopMenu,true);
	new gold=War3_GetGold(client);
	
	new String:title[300];
	Format(title,sizeof(title),"%T\n","[War3Source] Select an item to buy. You have {amount}/{amount} items",GetTrans(),GetClientItemsOwned(client),GetMaxShopitemsPerPlayer());
	if(BuyUseCSMoney()){
		Format(title,sizeof(title),"%s \n",title);
	}
	else {
		Format(title,sizeof(title),"%s%T\n \n",title,"You have {amount} Gold",GetTrans(),gold);
	}
	SetMenuTitle(shopMenu,title);
	decl String:itemname[64];
	decl String:itembuf[4];
	decl String:linestr[96];
	decl cost;
	for(new x=1;x<=W3GetItemsLoaded();x++)
	{
		//if(W3RaceHasFlag(x,"hidden")){
		//	PrintToServer("hidden %d",x);
		//}
		if(!W3IsItemDisabledGlobal(x)&&!W3ItemHasFlag(x,"hidden")){
			Format(itembuf,sizeof(itembuf),"%d",x);
			W3GetItemName(x,itemname,sizeof(itemname));
			cost=W3GetItemCost(x,BuyUseCSMoney());
			if(War3_GetOwnsItem(client,x)){
				if(BuyUseCSMoney()){
					Format(linestr,sizeof(linestr),"%T",">{itemname} - ${amount}",client,itemname,cost);
				}else{
					Format(linestr,sizeof(linestr),"%T",">{itemname} - {amount} Gold",client,itemname,cost);
				}
			}
			else{
				if(BuyUseCSMoney()){
					Format(linestr,sizeof(linestr),"%T","{itemname} - ${amount}",client,itemname,cost);
				}else{
					Format(linestr,sizeof(linestr),"%T","{itemname} - {amount} Gold",client,itemname,cost);
				}
			}
			AddMenuItem(shopMenu,itembuf,linestr);
		}
	}
	DisplayMenu(shopMenu,client,20);
}
public War3Source_ShopMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		if(ValidPlayer(client))
		{
			decl String:SelectionInfo[4];
			decl String:SelectionDispText[256];
			new SelectionStyle;
			GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
			new item=StringToInt(SelectionInfo);
			War3_TriedToBuyItem(client,item) ;
			
		}
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}
War3_TriedToBuyItem(client,item){
	if(item>0&&item<=W3GetItemsLoaded())
	{	
		SetTrans(client);
		
		decl String:itemname[64];
		W3GetItemName(item,itemname,sizeof(itemname));
		
		
		new cred=War3_GetGold(client);
		new money=GetCSMoney(client);
		new cost_num=W3GetItemCost(item,BuyUseCSMoney());
		
		new bool:canbuy=true;
		
		new race=War3_GetRace(client);
		if(W3IsItemDisabledGlobal(item)){
			War3_ChatMessage(client,"%T","{itemname} is disabled",GetTrans(),itemname);
			canbuy=false;
		}
		
		
		
		else if(W3IsItemDisabledForRace(race,item)){
			
			new String:racename[64];
			War3_GetRaceName(race,racename,sizeof(racename));
			War3_ChatMessage(client,"%T","You may not purchase {itemname} when you are {racename}",GetTrans(),itemname,racename);
			canbuy=false;
		}
		
		else if(War3_GetOwnsItem(client,item)){
			War3_ChatMessage(client,"%T","You already own {itemname}",GetTrans(),itemname);
			canbuy=false;
		}
		else if((BuyUseCSMoney()?money:cred)<cost_num){
			War3_ChatMessage(client,"%T","You cannot afford {itemname}",GetTrans(),itemname);
			ShowMenuShop(client);
			canbuy=false;
		}
		if(canbuy){
			W3SetVar(EventArg1,item);
			W3SetVar(EventArg2,1);
			W3CreateEvent(CanBuyItem,client);
			if(W3GetVar(EventArg2)==0){
				canbuy=false;
			}
		}
		//if its use instantly then let them buy it
		//items maxed out
		if(canbuy&&!War3_GetItemProperty(item,ITEM_USED_ON_BUY)&&GetClientItemsOwned(client)>=GetMaxShopitemsPerPlayer()){
			canbuy=false;
			WantsToBuy[client]=item;
			War3M_ExceededMaxItemsMenuBuy(client);
			
		}
	
		
		
		if(canbuy){
			if(BuyUseCSMoney()){
				SetCSMoney(client,money-cost_num);
			}
			else{
				War3_SetGold(client,cred-cost_num);
			}
			War3_ChatMessage(client,"%T","You have successfully purchased {itemname}",GetTrans(),itemname);
			
			W3SetVar(TheItemBoughtOrLost,item);
			W3CreateEvent(DoForwardClientBoughtItem,client); //old item//forward, and set has item true inside
		}
	}	
}


War3M_ExceededMaxItemsMenuBuy(client)
{
	SetTrans(client);
	new Handle:hMenu=CreateMenu(OnSelectExceededMaxItemsMenuBuy);
	SetMenuExitButton(hMenu,true);
	
	decl String:itemname[64];
	W3GetItemName(WantsToBuy[client],itemname,sizeof(itemname));
	
	SetMenuTitle(hMenu,"%T\n","[War3Source] You already have a max of {amount} items. Choose an item to replace with {itemname}. You will not get gold back",GetTrans(),GetMaxShopitemsPerPlayer(),itemname);
	
	decl String:itembuf[4];
	decl String:linestr[96];
	for(new x=1;x<=W3GetItemsLoaded();x++)
	{
		if(War3_GetOwnsItem(client,x)){
			Format(itembuf,sizeof(itembuf),"%d",x);
			W3GetItemName(x,itemname,sizeof(itemname));
			
			Format(linestr,sizeof(linestr),"%s",itemname);
			AddMenuItem(hMenu,itembuf,linestr);
		}
	}
	DisplayMenu(hMenu,client,20);
}
public OnSelectExceededMaxItemsMenuBuy(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		if(ValidPlayer(client))
		{
			SetTrans(client);
			decl String:SelectionInfo[4];
			decl String:SelectionDispText[256];
			new SelectionStyle;
			GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
			new item=StringToInt(SelectionInfo);
			if(item>0&&item<=W3GetItemsLoaded())
			{	
				
				new cred=War3_GetGold(client);
				new money=GetCSMoney(client);
				new cost_num=W3GetItemCost(WantsToBuy[client],BuyUseCSMoney());
				decl String:itemname[64];
				W3GetItemName(WantsToBuy[client],itemname,sizeof(itemname));
				
			
				if((BuyUseCSMoney()?money:cred)<cost_num){
					War3_ChatMessage(client,"%T","You cannot afford {itemname}",GetTrans(),itemname);
					ShowMenuShop(client);
				}
				else{
					W3SetVar(TheItemBoughtOrLost,item);
					W3CreateEvent(DoForwardClientLostItem,client); //old item
					
					
					if(BuyUseCSMoney()){
						SetCSMoney(client,money-cost_num);
					}
					else{
						War3_SetGold(client,cred-cost_num);
					}
					War3_ChatMessage(client,"%T","You have successfully purchased {itemname}",GetTrans(),itemname);
					
					W3SetVar(TheItemBoughtOrLost,WantsToBuy[client])
					W3CreateEvent(DoForwardClientBoughtItem,client); //old item
				}
			}
		}
	}
}



	
	
	
	
	
	///quick cvar access functions
bool:BuyUseCSMoney(){
	return ((War3_GetGame()==CS)&&GetConVarInt(hBuyItemUseCSMoneCvar)>0)?true:false;
}
	
GetClientItemsOwned(client){
	new num=0;
	for(new i=1;i<=W3GetItemsLoaded();i++){
		if(War3_GetOwnsItem(client,i)){
			num++;
		}
	}
	return num;
}
GetMaxShopitemsPerPlayer(){
	return GetConVarInt(hCvarMaxShopitems);
}
	
	