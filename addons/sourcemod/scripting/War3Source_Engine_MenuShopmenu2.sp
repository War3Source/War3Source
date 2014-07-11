



#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

//new Handle:hShopMenu2RequiredFlag;
new Handle:hShop2Enabled;
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
  LoadTranslations("w3s.shopmenu2.phrases.txt");
  //W3CreateCvar("w3shop2menu","loaded","is the shop2 loaded");
  //hShopMenu2RequiredFlag=CreateConVar("war3_shopmenu2_flag","0","Flag(or 0 to disable) which is required to access shopmenu2. Flag name (like kick)");
  hShop2Enabled=CreateConVar("war3_shop2_enabled","1","is shopmenu 2 enabled");
}
Shop2Enabled(){
    return GetConVarInt(hShop2Enabled);
}

//flag to access shop 2
/*
stock bool:HasRequiredFlag2(client) {
  decl String:buffer[4];
  GetConVarString(hShopMenu2RequiredFlag,buffer,sizeof(buffer));
  new AdminFlag:flag;
  if(FindFlagByName(buffer, flag)) {
    if(HasSMAccess(client,FlagToBit(flag))) {
      return true;
    }
    return false;
  }
  return true;
}
*/

new WantsToBuy2[MAXPLAYERSCUSTOM];

ShowMenuShop2(client){
  SetTrans(client);
  new Handle:shopMenu2=CreateMenu(War3Source_ShopMenu2_Selected);
  SetMenuExitButton(shopMenu2,true);
  new Diamonds=War3_GetDiamonds(client);
  
  new String:title[300];
  Format(title,sizeof(title),"%T\n","[War3Source] Select an item to buy. You have {amount}/{amount} items",GetTrans(),GetClientItems2Owned(client),GetMaxShopitems2PerPlayer());
  Format(title,sizeof(title),"%s%T\n \n",title,"You have {amount} Diamonds",GetTrans(),Diamonds);
  
  SetMenuTitle(shopMenu2,title);
  decl String:itemname2[64];
  decl String:itembuf2[4];
  decl String:linestr2[96];
  decl cost;
  new Items2Loaded = W3GetItems2Loaded();
  //DP("Items2Loaded = %i",Items2Loaded);
  for(new x=1;x<=Items2Loaded;x++)
  {
    //if(W3RaceHasFlag(x,"hidden")){
    //  PrintToServer("hidden %d",x);
    //}
      //if(!W3IsItem2DisabledGlobal(x)&&!W3Item2HasFlag(x,"hidden")){
      new war3e=1;
      if(war3e==1){
      Format(itembuf2,sizeof(itembuf2),"%d",x);
      W3GetItem2Name(x,itemname2,sizeof(itemname2));
      //DP("W3GetItem2Name = %s",itemname2);
      cost=W3GetItem2Cost(x);
      //DP("W3GetItem2Cost = %i",cost);
      if(War3_GetOwnsItem2(client,x)){
        Format(linestr2,sizeof(linestr2),"%T",">{itemname} - {amount} Diamonds",client,itemname2,cost);
      }
      else{
        Format(linestr2,sizeof(linestr2),"%T","{itemname} - {amount} Diamonds",client,itemname2,cost);
      }
      //AddMenuItem(shopMenu2,itembuf2,linestr2,(W3IsItem2DisabledForRace(War3_GetRace(client),x) || W3IsItem2DisabledGlobal(x) || War3_GetOwnsItem2(client,x))?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
      AddMenuItem(shopMenu2,itembuf2,linestr2,War3_GetOwnsItem2(client,x)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
    }
  }
  DisplayMenu(shopMenu2,client,20);
}
public War3Source_ShopMenu2_Selected(Handle:menu,MenuAction:action,client,selection)
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
  if(item>0&&item<=W3GetItems2Loaded())
  { 
    SetTrans(client);
    
    decl String:itemname2[64];
    W3GetItem2Name(item,itemname2,sizeof(itemname2));
    
    
    new cred=War3_GetDiamonds(client);
    new cost_num=W3GetItem2Cost(item);
    
    new bool:canbuy=true;
    
    new race=War3_GetRace(client);
    if(W3IsItem2DisabledGlobal(item)){
      War3_ChatMessage(client,"%T","{itemname} is disabled",GetTrans(),itemname2);
      canbuy=false;
    }
    else if(W3IsItem2DisabledForRace(race,item)){
      
      new String:racename2[64];
      War3_GetRaceName(race,racename2,sizeof(racename2));
      War3_ChatMessage(client,"%T","You may not purchase {itemname} when you are {racename}",GetTrans(),itemname2,racename2);
      canbuy=false;
    }
    
    else if(War3_GetOwnsItem2(client,item)){
      War3_ChatMessage(client,"%T","You already own {itemname}",GetTrans(),itemname2);
      canbuy=false;
    }
    else if(cred<cost_num){
      War3_ChatMessage(client,"%T","You cannot afford {itemname}",GetTrans(),itemname2);
      if(reshowmenu){
        ShowMenuShop2(client);
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
    if(canbuy&&!War3_GetItemProperty(item,ITEM_USED_ON_BUY)&&GetClientItems2Owned(client)>=GetMaxShopitems2PerPlayer()){
      canbuy=false;
      WantsToBuy2[client]=item;
      InternalExceededMaxItemsMenuBuy(client);
      
    }
  
    
    
    if(canbuy){
      War3_SetDiamonds(client,cred-cost_num);

      War3_ChatMessage(client,"%T","You have successfully purchased {itemname}",GetTrans(),itemname2);
      
      
      W3SetVar(TheItemBoughtOrLost,item);
      W3CreateEvent(DoForwardClientBoughtItem2,client); //old item//forward, and set has item true inside
      
      //W3SetItem2ExpireTime(client,item,NOW()+3600);
      //W3SaveItem2ExpireTime(client,item);
    }
  } 
}


InternalExceededMaxItemsMenuBuy(client)
{
  SetTrans(client);
  new Handle:hMenu=CreateMenu(OnSelectExceededMaxItemsMenuBuy);
  SetMenuExitButton(hMenu,true);
  
  decl String:itemname2[64];
  W3GetItemName(WantsToBuy2[client],itemname2,sizeof(itemname2));
  
  SetMenuTitle(hMenu,"%T\n","[War3Source] You already have a max of {amount} items. Choose an item to replace with {itemname}. You will not get Diamonds back",GetTrans(),GetMaxShopitems2PerPlayer(),itemname2);
  
  decl String:itembuf2[4];
  decl String:linestr2[96];
  new ItemsLoaded = W3GetItems2Loaded();
  for(new x=1;x<=ItemsLoaded;x++)
  {
    if(War3_GetOwnsItem2(client,x)){
      Format(itembuf2,sizeof(itembuf2),"%d",x);
      W3GetItem2Name(x,itemname2,sizeof(itemname2));
      
      Format(linestr2,sizeof(linestr2),"%s",itemname2);
      AddMenuItem(hMenu,itembuf2,linestr2);
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
      decl String:SelectionInfo2[4];
      decl String:SelectionDispText2[256];
      new SelectionStyle2;
      GetMenuItem(menu,selection,SelectionInfo2,sizeof(SelectionInfo2),SelectionStyle2, SelectionDispText2,sizeof(SelectionDispText2));
      new item=StringToInt(SelectionInfo2);
      if(item>0&&item<=W3GetItems2Loaded())
      { 
        
        new cred=War3_GetDiamonds(client);
        new cost_num=W3GetItem2Cost(WantsToBuy2[client]);
        decl String:itemname2[64];
        W3GetItem2Name(WantsToBuy2[client],itemname2,sizeof(itemname2));
        
      
        if(cred<cost_num){
          War3_ChatMessage(client,"%T","You cannot afford {itemname}",GetTrans(),itemname2);
          ShowMenuShop2(client);
        }
        else{
          W3SetVar(TheItemBoughtOrLost,item);
          W3CreateEvent(DoForwardClientLostItem2,client); //old item
          
          
          
          War3_SetDiamonds(client,cred-cost_num);
          
          War3_ChatMessage(client,"%T","You have successfully purchased {itemname}",GetTrans(),itemname2);
          
          W3SetVar(TheItemBoughtOrLost,WantsToBuy2[client]);
          W3CreateEvent(DoForwardClientBoughtItem2,client); //old item
        }
      }
    }
  }
}

public OnWar3Event(W3EVENT:event,client){
  if(event==DoShowShopMenu2)
    {
      if(Shop2Enabled())
      {
        ShowMenuShop2(client);
      }
      else
      {
        War3_ChatMessage(client,"Shopmenu 2 is disabled on this server");
      }
  }

  if(event==DoTriedToBuyItem2){ //via say?
    InternalTriedToBuyItem2(client,W3GetVar(EventArg1),W3GetVar(EventArg2)); ///ALWAYS SET ARG2 before calling this event
  }
}


  

  
  