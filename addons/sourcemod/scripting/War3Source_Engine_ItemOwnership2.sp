

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


new bool:playerOwnsItem2[MAXPLAYERSCUSTOM][MAXITEMS];
//new playerOwnsItemExpireTime[MAXPLAYERSCUSTOM][MAXITEMS];
new Handle:g_OnItemPurchaseHandle;
new Handle:g_OnItemLostHandle;

//new Handle:hitemRestrictionCvar2;
new Handle:hCvarMaxShopitems2;
public Plugin:myinfo= 
{
  name="W3S Engine Item2 Ownership",
  author="Ownz (DarkEnergy)",
  description="War3Source Core Plugins",
  version="1.0",
  url="http://war3source.com/"
};



public OnPluginStart()
{
  //hitemRestrictionCvar2=CreateConVar("war3_item2_restrict","","Disallow items in shopmenu, shortname separated by comma only ie:'claw,orb'");
  hCvarMaxShopitems2=CreateConVar("war3_max_shopitems2","2","max shop2 items a player can hold");
}

public bool:InitNativesForwards()
{
  g_OnItemPurchaseHandle=CreateGlobalForward("OnItem2Purchase",ET_Ignore,Param_Cell,Param_Cell);
  g_OnItemLostHandle=CreateGlobalForward("OnItem2Lost",ET_Ignore,Param_Cell,Param_Cell);

  CreateNative("War3_GetOwnsItem2",NWar3_GetOwnsItem2);
  CreateNative("War3_SetOwnsItem2",NWar3_SetOwnsItem2);

  CreateNative("W3IsItem2DisabledGlobal",NW3IsItem2DisabledGlobal);
  CreateNative("W3IsItem2DisabledForRace",NW3IsItem2DisabledForRace);
  
  //CreateNative("W3GetItem2ExpireTime",NW3GetItem2ExpireTime);
  //CreateNative("W3SetItem2ExpireTime",NW3SetItem2ExpireTime);
  
  
  CreateNative("GetClientItems2Owned",NGetClientItems2Owned);
  CreateNative("GetMaxShopitems2PerPlayer",NGetMaxShopitems2PerPlayer);
  
  return true;
}

public NW3IsItem2DisabledGlobal(Handle:plugin,numParams)
{
  return false;
  /*
  new itemid=GetNativeCell(1);
  decl String:itemShort[16];
  W3GetItem2Shortname(itemid,itemShort,16);
  
  decl String:cvarstr[100];
  decl String:exploded[MAXITEMS][16];
  decl num;
  GetConVarString(hitemRestrictionCvar2,cvarstr,sizeof(cvarstr));
  if(strlen(cvarstr)>0){
    num=ExplodeString(cvarstr,",",exploded,MAXITEMS,16);
    for(new i=0;i<num;i++){
      //PrintToServer("'%s' compared to: '%s' num%d",exploded[i],itemShort,num);
      if(StrEqual(exploded[i],itemShort,false)){
        //PrintToServer("TRUE");
        return true;
      }
    }
  }
  return false;
  */
}
public NW3IsItem2DisabledForRace(Handle:plugin,numParams)
{
  return false;
  /*
  new raceid=GetNativeCell(1);
  new itemid=GetNativeCell(2);
  if(raceid>0){
    decl String:itemShort[16];
    W3GetItem2Shortname(itemid,itemShort,sizeof(itemShort));
    
    decl String:cvarstr[100];
    decl String:exploded[MAXITEMS][16];
    
    W3GetRaceItem2RestrictionsStr(raceid,cvarstr,sizeof(cvarstr));
    
    new num;
    if(strlen(cvarstr)>0){
      num=ExplodeString(cvarstr,",",exploded,MAXITEMS,16);
      for(new i=0;i<num;i++){
        //PrintToServer("'%s' compared to: '%s' num%d",exploded[i],itemShort,num);
        if(StrEqual(exploded[i],itemShort,false)){
          //PrintToServer("TRUE");
          return true;
        }
      }
    }
  }
  return false;*/
}

/*
public NW3GetItem2ExpireTime(Handle:plugin,numParams)
{

  return _:playerOwnsItemExpireTime[GetNativeCell(1)][GetNativeCell(2)];

}
public NW3SetItem2ExpireTime(Handle:plugin,numParams)
{
  new client=GetNativeCell(1);
  new item=GetNativeCell(2);
  new time=GetNativeCell(3);  
  //new Handle:hDB=W3GetDBHandle();
  //if(hDB){
  
  playerOwnsItemExpireTime[client][item]=time;
}

*/













public OnWar3Event(W3EVENT:event,client){
  if(event==DoForwardClientBoughtItem2){
    new itemid=W3GetVar(TheItemBoughtOrLost);
    War3_SetOwnsItem2(client,itemid,true);
    
    Call_StartForward(g_OnItemPurchaseHandle); 
    Call_PushCell(client);
    Call_PushCell(itemid);
    Call_Finish(dummy);
    
    
  }
  if(event==DoForwardClientLostItem2){
    new itemid=W3GetVar(TheItemBoughtOrLost);
    War3_SetOwnsItem2(client,itemid,false);
    //DP("NO LONGER OWNS %d",itemid);
  
    Call_StartForward(g_OnItemLostHandle); 
    Call_PushCell(client);
    Call_PushCell(itemid);
    Call_Finish(dummy);
  }
  if(event==DoCheckRestrictedItems){
    CheckForRestrictedItemsOnRace(client);
  }
}



CheckForRestrictedItemsOnRace(client)
{
  client=client+0; //silence warning
  /*new ItemsLoaded = W3GetItems2Loaded();
  for(new itemid=1;itemid<=ItemsLoaded;itemid++){
    if(War3_GetOwnsItem2(client,itemid)){
      new race=War3_GetRace(client);
      if(W3IsItemDisabledForRace(race,itemid)){
        
        new String:racename[64];
        War3_GetRaceName(race,racename,sizeof(racename));
        
        new String:itemname[64];
        W3GetItemName(itemid,itemname,sizeof(itemname));
        War3_ChatMessage(client,"%T","{itemname} is restricted on race {racename}, item has been removed",client,itemname,racename);
        
        W3SetVar(TheItemBoughtOrLost,itemid);
        W3CreateEvent(DoForwardClientLostItem,client); //old item
        
      }
      
    }
  }*/
}



public NGetClientItems2Owned(Handle:h,n){
  new client=GetNativeCell(1);
  new num=0;
  new ItemsLoaded = W3GetItems2Loaded();
  for(new i=1;i<=ItemsLoaded;i++){
    if(War3_GetOwnsItem2(client,i)){
      num++;
    }
  }
  //DP("ret %d loaded %d",num,W3GetItems2Loaded());
  return num;
}
public NGetMaxShopitems2PerPlayer(Handle:h,n){
  return GetConVarInt(hCvarMaxShopitems2);
}


public NWar3_GetOwnsItem2(Handle:plugin,numParams)
{
  if (ValidPlayer(GetNativeCell(1)))
    return _:playerOwnsItem2[GetNativeCell(1)][GetNativeCell(2)];
  else
    return false;

}

public NWar3_SetOwnsItem2(Handle:plugin,numParams)
{
  new client=GetNativeCell(1);
  new itemid=GetNativeCell(2);
  new bool:old=playerOwnsItem2[client][itemid];
  playerOwnsItem2[client][itemid]=bool:GetNativeCell(3);
  if(old!=playerOwnsItem2[client][itemid]){
    switch(playerOwnsItem2[client][itemid]){
      case false:{
        Call_StartForward(g_OnItemLostHandle);
        Call_PushCell(client);
        Call_PushCell(itemid);
        Call_Finish(dummy);
      }
      case true:{
        Call_StartForward(g_OnItemPurchaseHandle);
        Call_PushCell(client);
        Call_PushCell(itemid);
        Call_Finish(dummy);
      }
      default: {
        ThrowNativeError(0,"set owns item2 is not true or false");
      }
    }
  }


}