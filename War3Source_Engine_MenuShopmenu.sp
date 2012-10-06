#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo=
{
	name="War3Source Menus Shopmenus",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};

new Handle:hBuyItemUseCSMoneCvar;
new Handle:hUseCategorysCvar;

public bool:InitNativesForwards()
{
	CreateNative("W3BuyUseCSMoney",NW3BuyUseCSMoney);
	return true;
}
public OnPluginStart()
{
	hBuyItemUseCSMoneCvar=CreateConVar("war3_buyitems_csmoney","0","In CS, use cs money and in TF2 use MVM money to buy shopmenu items");
	hUseCategorysCvar=CreateConVar("war3_buyitems_category", "0", "Enable/Disable shopitem categorys", 0, true, 0.0, true, 1.0);
}

public OnWar3Event(W3EVENT:event,client) {
	if(event==DoShowShopMenu) {
		new bool:useCategory = GetConVarBool(hUseCategorysCvar);
		if (useCategory)
		ShowMenuShopCategory(client);
		else
		ShowMenuShop(client);
	}
	if(event==DoTriedToBuyItem) { //via say?
		War3_TriedToBuyItem(client,W3GetVar(EventArg1),W3GetVar(EventArg2)); ///ALWAYS SET ARG2 before calling this event
	}
}
new WantsToBuy[MAXPLAYERSCUSTOM];

ShowMenuShopCategory(client)
{
	SetTrans(client);
	new Handle:shopMenu = CreateMenu(War3Source_ShopMenuCategory_Sel);
	SetMenuExitButton(shopMenu, true);
	new gold = War3_GetGold(client);

	new String:title[300];
	Format(title,sizeof(title),"%T\n","[War3Source] Select an item category to browse. You have {amount}/{amount} items",GetTrans(),GetClientItemsOwned(client),GetMaxShopitemsPerPlayer());

	if(W3BuyUseCSMoney()) {
		Format(title,sizeof(title),"%s \n",title);
	}
	else {
		Format(title,sizeof(title),"%s%T\n \n",title,"You have {amount} Gold", GetTrans(), gold);
	}

	SetMenuTitle(shopMenu, title);

	new Handle:h_ItemCategorys = CreateArray(ByteCountToCells(64));
	decl String:category[64];
	new ItemsLoaded = W3GetItemsLoaded();

	// find all possible categorys and fill the menu
	for(new x=1; x <= ItemsLoaded; x++)
	{
		if(!W3IsItemDisabledGlobal(x) && !W3ItemHasFlag(x,"hidden"))
		{
			W3GetItemCategory(x, category, sizeof(category));

			if ((FindStringInArray(h_ItemCategorys, category) >= 0) || StrEqual(category, ""))
			continue;
			else
			PushArrayString(h_ItemCategorys, category);
		}
	}

	// fill the menu with the categorys
	while(GetArraySize(h_ItemCategorys))
	{
		GetArrayString(h_ItemCategorys, 0, category, sizeof(category));

		AddMenuItem(shopMenu, category, category, ITEMDRAW_DEFAULT);
		RemoveFromArray(h_ItemCategorys, 0);
	}

	CloseHandle( h_ItemCategorys);

	DisplayMenu(shopMenu,client,20);
}

ShowMenuShop(client, const String:category[]="") {
	SetTrans(client);
	new Handle:shopMenu=CreateMenu(War3Source_ShopMenu_Selected);
	SetMenuExitButton(shopMenu,true);

	new gold=War3_GetGold(client);

	new String:title[300];
	Format(title,sizeof(title),"%T\n","[War3Source] Select an item to buy. You have {amount}/{amount} items",GetTrans(),GetClientItemsOwned(client),GetMaxShopitemsPerPlayer());
	if(W3BuyUseCSMoney()) {
		Format(title,sizeof(title),"%s \n",title);
	}
	else {
		Format(title,sizeof(title),"%s%T\n \n",title,"You have {amount} Gold",GetTrans(),gold);
	}
	SetMenuTitle(shopMenu,title);
	decl String:itemname[64];
	decl String:itembuf[4];
	decl String:linestr[96];
	decl String:itemcategory[64];
	decl cost;
	new ItemsLoaded = W3GetItemsLoaded();
	for(new x=1;x<=ItemsLoaded;x++)
	{
		//if(W3RaceHasFlag(x,"hidden")){
		//	PrintToServer("hidden %d",x);
		//}
		if(!W3IsItemDisabledGlobal(x)&&!W3ItemHasFlag(x,"hidden")) {
			W3GetItemCategory(x, itemcategory, sizeof(itemcategory));

			if ((!StrEqual(category, "") && StrEqual(category, itemcategory)) || (StrEqual(category, "")))
			{
				Format(itembuf,sizeof(itembuf),"%d",x);
				W3GetItemName(x,itemname,sizeof(itemname));
				cost=W3GetItemCost(x,W3BuyUseCSMoney());
				if(War3_GetOwnsItem(client,x)) {
					if(W3BuyUseCSMoney()) {
						Format(linestr,sizeof(linestr),"%T",">{itemname} - ${amount}",client,itemname,cost);
					}
					else {
						Format(linestr,sizeof(linestr),"%T",">{itemname} - {amount} Gold",client,itemname,cost);
					}
				}
				else {
					if(W3BuyUseCSMoney()) {
						Format(linestr,sizeof(linestr),"%T","{itemname} - ${amount}",client,itemname,cost);
					}
					else {
						Format(linestr,sizeof(linestr),"%T","{itemname} - {amount} Gold",client,itemname,cost);
					}
				}
				AddMenuItem(shopMenu,itembuf,linestr,(W3IsItemDisabledForRace(War3_GetRace(client),x) || W3IsItemDisabledGlobal(x) || War3_GetOwnsItem(client,x))?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			}
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
			War3_TriedToBuyItem(client,item,true);

		}
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public War3Source_ShopMenuCategory_Sel(Handle:menu, MenuAction:action, client, selection)
{
	if(action==MenuAction_Select)
	{
		if(ValidPlayer(client))
		{
			decl String:SelectionInfo[64];
			decl String:SelectionDispText[256];
			new SelectionStyle;
			GetMenuItem(menu, selection, SelectionInfo, sizeof(SelectionInfo), SelectionStyle, SelectionDispText,sizeof(SelectionDispText));

			ShowMenuShop(client, SelectionInfo);
		}
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}

War3_TriedToBuyItem(client,item,bool:reshowmenu=true) {
	if(item>0&&item<=W3GetItemsLoaded())
	{
		SetTrans(client);

		decl String:itemname[64];
		W3GetItemName(item,itemname,sizeof(itemname));

		new cred=War3_GetGold(client);
		new money=GetCSMoney(client);
		new cost_num=W3GetItemCost(item,W3BuyUseCSMoney());

		new bool:canbuy=true;

		new race=War3_GetRace(client);
		if(W3IsItemDisabledGlobal(item)) {
			War3_ChatMessage(client,"%T","{itemname} is disabled",GetTrans(),itemname);
			canbuy=false;
		}

		else if(W3IsItemDisabledForRace(race,item)) {

			new String:racename[64];
			War3_GetRaceName(race,racename,sizeof(racename));
			War3_ChatMessage(client,"%T","You may not purchase {itemname} when you are {racename}",GetTrans(),itemname,racename);
			canbuy=false;
		}

		else if(War3_GetOwnsItem(client,item)) {
			War3_ChatMessage(client,"%T","You already own {itemname}",GetTrans(),itemname);
			canbuy=false;
		}
		else if((W3BuyUseCSMoney()?money:cred)<cost_num) {
			War3_ChatMessage(client,"%T","You cannot afford {itemname}",GetTrans(),itemname);
			if(reshowmenu) {
				ShowMenuShop(client);
			}
			canbuy=false;
		}
		if(canbuy) {
			W3SetVar(EventArg1,item);
			W3SetVar(EventArg2,1);
			W3CreateEvent(CanBuyItem,client);
			if(W3GetVar(EventArg2)==0) {
				canbuy=false;
			}
		}
		//if its use instantly then let them buy it
		//items maxed out
		if(canbuy&&!War3_GetItemProperty(item,ITEM_USED_ON_BUY)&&GetClientItemsOwned(client)>=GetMaxShopitemsPerPlayer()) {
			canbuy=false;
			WantsToBuy[client]=item;
			War3M_ExceededMaxItemsMenuBuy(client);

		}

		if(canbuy) {
			if(W3BuyUseCSMoney()) {
				SetCSMoney(client,money-cost_num);
			}
			else {
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
	new ItemsLoaded = W3GetItemsLoaded()
	for(new x=1;x<=ItemsLoaded;x++)
	{
		if(War3_GetOwnsItem(client,x)) {
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
			new itemtolose=StringToInt(SelectionInfo);
			if(itemtolose>0&&itemtolose<=W3GetItemsLoaded())
			{
				//check he can afford new item
				new cred=War3_GetGold(client);
				new money=GetCSMoney(client);
				new cost_num=W3GetItemCost(WantsToBuy[client],W3BuyUseCSMoney());
				decl String:itemname[64];
				W3GetItemName(WantsToBuy[client],itemname,sizeof(itemname));

				if((W3BuyUseCSMoney()?money:cred)<cost_num) {
					War3_ChatMessage(client,"%T","You cannot afford {itemname}",GetTrans(),itemname);
					ShowMenuShop(client);
				}
				else {
					W3SetVar(TheItemBoughtOrLost,itemtolose);
					W3CreateEvent(DoForwardClientLostItem,client); //old item


					if(W3BuyUseCSMoney()) {
						SetCSMoney(client,money-cost_num);
					}
					else {
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
public NW3BuyUseCSMoney(Handle:plugin,numParams)
{
	return ((War3_GetGame()==CS || (War3_GetGame() == TF))&&GetConVarInt(hBuyItemUseCSMoneCvar)>0)?true:false;
}
