



#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


public Plugin:myinfo= 
{
	name="War3Source Menus Shopmenus 2",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};


public OnPluginStart()
{
	LoadTranslations("w3s.shopmenu2.phrases");
	W3CreateCvar("w3shop2menu","loaded","is the shop2 loaded");
}

public OnWar3Event(W3EVENT:event,client){
	if(event==DoShowShopMenu2){
		if(EXT()){
	
			SetTrans(client); //required
			W3ExtShowShop2(client);
			//ShowMenuShop(client);
			
			//W3ExtShowShop2(client);
		}
		else{
		//DO NOT TRANSLATE
			War3_ChatMessage(client,"EXT not loaded, contact server admin");
		}
		
		
	}
	if(event==DoTriedToBuyItem2){ //via say?
		if(EXT()){
			InternalTriedToBuyItem2(client,W3GetVar(EventArg1),W3GetVar(EventArg2)); ///ALWAYS SET ARG2 before calling this event
		}
		else{
			//DO NOT TRANSLATE
			War3_ChatMessage(client,"EXT not loaded, contact server admin --Do Tried To Buy Item2--");
		}
	}
	
}
new WantsToBuy[MAXPLAYERSCUSTOM];

ShowMenuShop(client){
	SetTrans(client);
	new Handle:shopMenu=CreateMenu(War3Source_ShopMenu_Selected);
	SetMenuExitButton(shopMenu,true);
	new Diamonds=War3_GetDiamonds(client);
	
	new String:title[300];
	Format(title,sizeof(title),"%T\n","[War3Source] Select an item to buy. You have {amount}/{amount} items",GetTrans(),GetClientItemsOwned(client),GetMaxShopitemsPerPlayer());
	Format(title,sizeof(title),"%s%T\n \n",title,"You have {amount} Diamonds",GetTrans(),Diamonds);
	
	SetMenuTitle(shopMenu,title);
	decl String:itemname[64];
	decl String:itembuf[4];
	decl String:linestr[96];
	decl cost;
	new ItemsLoaded = W3GetItems2Loaded();
	for(new x=1;x<=ItemsLoaded;x++)
	{
		//if(W3RaceHasFlag(x,"hidden")){
		//	PrintToServer("hidden %d",x);
		//}
		if(!W3IsItem2DisabledGlobal(x)&&!W3Item2HasFlag(x,"hidden")){
			Format(itembuf,sizeof(itembuf),"%d",x);
			W3GetItem2Name(x,itemname,sizeof(itemname));
			cost=W3GetItem2Cost(x);
			if(War3_GetOwnsItem2(client,x)){
				Format(linestr,sizeof(linestr),"%T",">{itemname} - {amount} Diamonds",client,itemname,cost);
			}
			else{
				Format(linestr,sizeof(linestr),"%T","{itemname} - {amount} Diamonds",client,itemname,cost);
			}
			AddMenuItem(shopMenu,itembuf,linestr,(W3IsItem2DisabledForRace(War3_GetRace(client),x) || W3IsItem2DisabledGlobal(x) || War3_GetOwnsItem2(client,x))?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
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
			InternalTriedToBuyItem2(client,item,true) ;
			
		}
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}
InternalTriedToBuyItem2(client,item,bool:reshowmenu=true){
	if(item>0&&item<=W3GetItemsLoaded())
	{	
		SetTrans(client);
		
		decl String:itemname[64];
		W3GetItem2Name(item,itemname,sizeof(itemname));
		
		
		new cred=War3_GetDiamonds(client);
		new cost_num=W3GetItem2Cost(item);
		
		new bool:canbuy=true;
		
		new race=War3_GetRace(client);
		if(W3IsItem2DisabledGlobal(item)){
			War3_ChatMessage(client,"%T","{itemname} is disabled",GetTrans(),itemname);
			canbuy=false;
		}
		
		
		
		else if(W3IsItem2DisabledForRace(race,item)){
			
			new String:racename[64];
			War3_GetRaceName(race,racename,sizeof(racename));
			War3_ChatMessage(client,"%T","You may not purchase {itemname} when you are {racename}",GetTrans(),itemname,racename);
			canbuy=false;
		}
		
		else if(War3_GetOwnsItem2(client,item)){
			War3_ChatMessage(client,"%T","You already own {itemname}",GetTrans(),itemname);
			canbuy=false;
		}
		else if(cred<cost_num){
			War3_ChatMessage(client,"%T","You cannot afford {itemname}",GetTrans(),itemname);
			if(reshowmenu){
				ShowMenuShop(client);
			}
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
			InternalExceededMaxItemsMenuBuy(client);
			
		}
	
		
		
		if(canbuy){
			War3_SetDiamonds(client,cred-cost_num);

			War3_ChatMessage(client,"%T","You have successfully purchased {itemname}",GetTrans(),itemname);
			
			
			W3SetVar(TheItemBoughtOrLost,item);
			W3CreateEvent(DoForwardClientBoughtItem2,client); //old item//forward, and set has item true inside
			
			W3SetItem2ExpireTime(client,item,NOW()+3600);
			W3SaveItem2ExpireTime(client,item);
		}
	}	
}


InternalExceededMaxItemsMenuBuy(client)
{
	SetTrans(client);
	new Handle:hMenu=CreateMenu(OnSelectExceededMaxItemsMenuBuy);
	SetMenuExitButton(hMenu,true);
	
	decl String:itemname[64];
	W3GetItemName(WantsToBuy[client],itemname,sizeof(itemname));
	
	SetMenuTitle(hMenu,"%T\n","[War3Source] You already have a max of {amount} items. Choose an item to replace with {itemname}. You will not get Diamonds back",GetTrans(),GetMaxShopitemsPerPlayer(),itemname);
	
	decl String:itembuf[4];
	decl String:linestr[96];
	new ItemsLoaded = W3GetItems2Loaded()
	for(new x=1;x<=ItemsLoaded;x++)
	{
		if(War3_GetOwnsItem2(client,x)){
			Format(itembuf,sizeof(itembuf),"%d",x);
			W3GetItem2Name(x,itemname,sizeof(itemname));
			
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
			if(item>0&&item<=W3GetItems2Loaded())
			{	
				
				new cred=War3_GetDiamonds(client);
				new cost_num=W3GetItem2Cost(WantsToBuy[client]);
				decl String:itemname[64];
				W3GetItem2Name(WantsToBuy[client],itemname,sizeof(itemname));
				
			
				if(cred<cost_num){
					War3_ChatMessage(client,"%T","You cannot afford {itemname}",GetTrans(),itemname);
					ShowMenuShop(client);
				}
				else{
					W3SetVar(TheItemBoughtOrLost,item);
					W3CreateEvent(DoForwardClientLostItem2,client); //old item
					
					
					
					War3_SetDiamonds(client,cred-cost_num);
					
					War3_ChatMessage(client,"%T","You have successfully purchased {itemname}",GetTrans(),itemname);
					
					W3SetVar(TheItemBoughtOrLost,WantsToBuy[client])
					W3CreateEvent(DoForwardClientBoughtItem2,client); //old item
				}
			}
		}
	}
}



	

	
	