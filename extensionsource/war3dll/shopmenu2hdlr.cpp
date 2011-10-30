#include "war3dll.h"

//cannot use static here!!
cell_t W3ExtShowShop2(IPluginContext *pCtx, const cell_t *params)
{
	cell_t client=params[1];
	//ERR("in");

	static bool once=true;
	if(!g->helperVerifiedIntegrity){
		ERR("Shop2: helper not verified");
		EXTChatMessage(client,"ERROR: helper not verified. Contact server owner.");
		return 0;
	}
	if(once){
		ERR("Shop2: helper OK");
	}


	
	clienttotranslatecached=client;
	IMenuStyle *style=g->imenus->GetDefaultStyle();
	if(once){
		ERR("Shop2: Style OK");
	}
	//MyMenuHandler *handler=new MyMenuHandler();  //extens IMenuHandler without any implementation for now
	static Shopmenu2Handler *myhandler=new Shopmenu2Handler();

	if(once){	ERR("Shop2: Handler OK");	}


	IBaseMenu *basemenu=style->CreateMenu(myhandler );
	if(once){	ERR("Shop2: CreateMenu OK");	}
	
	char buffer[1000];


	void* param2[7];
	param2[0]=(void*)"[War3Source] Select an item to buy. You have {amount}/{amount} items";
	param2[1]=&client;
	cell_t dum=(NATIVE("GetClientItems2Owned",client));
	param2[2]=&dum;
	cell_t dum2=ITEMS2CANHAVE;
	param2[3]=&dum2;

	param2[4]=(void*)"You have {amount} Diamonds";
	param2[5]=&client;

	if(once){	ERR("Shop2: before GetDiamonds OK");	}
	cell_t dum3=GetDiamonds(client);
	if(once){	ERR("Shop2: after GetDiamonds OK");	}
	param2[6]=&dum3;

	size_t dummy;
	char* failedchar=NULL;
	if(shopitem2count<1){
		ERR("item2 count <1");
	}
	if(!g->myphrasecollection->FormatString(buffer,sizeof(buffer),"%T",param2,4,&dummy,(const char**)&failedchar)){
		ERR("1trans failed %s",failedchar);
	}

	char buffer2[512];
	if(!g->myphrasecollection->FormatString(buffer2,sizeof(buffer2),"%T",param2+4,3,&dummy,(const char**)&failedchar)){
		ERR("2trans failed %s",failedchar);
	}

	char title[512];
	FORMAT(title,sizeof(title),"%s\n%s\n",buffer,buffer2);
	//ERR("%s",title);
	basemenu->SetDefaultTitle(title);
	for(int i=1;i<=shopitem2count;i++){
		GetItem(i);
		FORMAT(buffer,sizeof(buffer),"%s%s %d",GetOwnsItem(client,item->itemid)?">":"",item->name(),item->cost()); //itemid
		ItemDrawInfo mydrawinfo(buffer); //dies on stack
		if(GetOwnsItem(client,item->itemid)||GetDiamonds(client)<item->cost()){
			mydrawinfo.style=ITEMDRAW_DISABLED;
		}
		basemenu->AppendItem(item->itemidstr,mydrawinfo);
	}


	if(once){	ERR("Shop2: before Display OK");	}
	//ERR("1 %d %d",client,shopitem2count);
	basemenu->Display(client,0);

	if(once){	ERR("Shop2: Displayed OK");	}
	//ERR("2");*/

	once=false;
	return 0;
}


/*
void Shopmenu2Handler::OnMenuSelect2(IBaseMenu *menu,
	int client,
	unsigned int menuitem,
	unsigned int item_on_page)
{ 
	if(false){
	static bool once=true;
	ItemDrawInfo info;
	const char* info2=menu->GetItemInfo(menuitem,&info);

	if(once){	ERR("Shop2H: GetItemInfo OK");	}

	int itemid=strtoint(info2);
	//ERR("client %d menuitem %d item.page %d info %d",client,menuitem,item_on_page,itemid);

	//SetTrans(client);
	GetItem(itemid);
	if(once){	ERR("Shop2H: GetItem OK");	}
	int diamonds=GetDiamonds(client);
	if(once){	ERR("Shop2H: GetDiamonds OK");	}
	bool canbuy=true;

	char buf[512];
	//new race=War3_GetRace(client);
	//if(W3IsItem2DisabledGlobal(item)){
	////	War3_ChatMessage(client,"%T","{itemname} is disabled",GetTrans(),itemname);
	//	canbuy=false;
	//}



	//else if(W3IsItem2DisabledForRace(race,item)){
	//
	//	new String:racename[64];
	//	War3_GetRaceName(race,racename,sizeof(racename));
	//	War3_ChatMessage(client,"%T","You may not purchase {itemname} when you are {racename}",GetTrans(),itemname,racename);
	//	canbuy=false;
	//}
	//	ERR("hnldr");
	if(GetOwnsItem(client,itemid)){

		void* param2[3];
		param2[0]=(void*)"You already own {itemname}";
		param2[1]=(void*)&client;
		param2[2]=(void*)item->name();

		char* failedchar=0;
		cell_t client=GetTrans();
		g->myphrasecollection->FormatString(buf,sizeof(buf),"%T",param2,sizeof(param2),NULL,(const char**)&failedchar);

		EXTChatMessage(client,buf);


		canbuy=false;
	}
	else if(GetDiamonds(client)<item->cost()){

		void* param2[3];
		param2[0]=(void*)"You cannot afford {itemname}";
		param2[1]=(void*)&client;
		param2[2]=(void*)item->name();

		char* failedchar=0;
		cell_t client=GetTrans();
		g->myphrasecollection->FormatString(buf,sizeof(buf),"%T",param2,sizeof(param2),NULL,(const char**)&failedchar);

		EXTChatMessage(client,buf);

		//if(reshowmenu){
		//	ShowMenuShop(client);
		//}
		canbuy=false;
	}
	if(canbuy){ //check with deny system?
		//W3SetVar(EventArg1,item);
		//W3SetVar(EventArg2,1);
		//W3CreateEvent(CanBuyItem,client);
		//if(W3GetVar(EventArg2)==0){
		//	canbuy=false;
		//}
	}
	//if its use instantly then let them buy it
	//items maxed out
	if(canbuy &&GetClientItemsOwned(client)>=ITEMS2CANHAVE){
		canbuy=false;
	//	WantsToBuy[client]=item;
	//	InternalExceededMaxItemsMenuBuy(client);
	///
	}



	if(canbuy){

		SetDiamonds(client,GetDiamonds(client)-item->cost());
		if(once){	ERR("Shop2H: SetItem OK");	}
		SetOwnsItem(client,itemid,true);
		if(once){	ERR("Shop2H: SetOwns OK");	}

		void* param2[3];
		param2[0]=(void*)"You have successfully purchased {itemname}";
		param2[1]=(void*)&client;
		param2[2]=(void*)item->name();

		char* failedchar=0;
		cell_t client=GetTrans();
		g->myphrasecollection->FormatString(buf,sizeof(buf),"%T",param2,sizeof(param2),NULL,(const char**)&failedchar);

		EXTChatMessage(client,buf);
		if(once){	ERR("Shop2H: EXTChatOK OK");	}

		//War3_ChatMessage(client,"%T",,GetTrans(),itemname);


		//W3SetVar(TheItemBoughtOrLost,item);
		//W3CreateEvent(DoForwardClientBoughtItem2,client); //old item//forward, and set has item true inside

		//W3SetItem2ExpireTime(client,item,NOW()+3600);
		//W3SaveItem2ExpireTime(client,item);
	}
	once=false;
	}
}
*/

void Shopmenu2Handler::OnMenuEnd(IBaseMenu *menu, MenuEndReason reason)
{
	DP("destroy menu OnMenuEnd");
	menu->Destroy();
	DP("destroy menu OnMenuEnd OK");
}


#ifdef failed
	//public does not work, vformat gets wrong cell values
	IPluginFunction *publicfunc= g->helperplugin->GetRuntime()->GetFunctionByName("myvformat");

	cell_t own=NATIVE("GetClientItemsOwned",client);
	cell_t max=NATIVE("GetMaxShopitemsPerPlayer");

	publicfunc->PushStringEx(buffer,sizeof(buffer),0,SM_PARAM_COPYBACK);
	publicfunc->PushCell(sizeof(buffer));
	publicfunc->PushString("%T");
	publicfunc->PushString("[War3Source] Select an item to buy. You have {amount}/{amount} items");
	publicfunc->PushCell(0);

	publicfunc->PushCell(own);
	publicfunc->PushCell(max);
	publicfunc->Execute(&result);
ERR("%s",buffer);
#endif

