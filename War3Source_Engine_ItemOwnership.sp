

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


new bool:playerOwnsItem[MAXPLAYERSCUSTOM][MAXITEMS];
new Handle:g_OnItemPurchaseHandle;
new Handle:g_OnItemLostHandle;

new Handle:hitemRestrictionCvar;

public Plugin:myinfo= 
{
	name="W3S Engine Item Ownership",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};





public OnPluginStart()
{
	hitemRestrictionCvar=CreateConVar("war3_item_restrict","","Disallow items in shopmenu, shortname separated by comma only ie:'claw,orb'");
}

public bool:InitNativesForwards()
{
	g_OnItemPurchaseHandle=CreateGlobalForward("OnItemPurchase",ET_Ignore,Param_Cell,Param_Cell);
	g_OnItemLostHandle=CreateGlobalForward("OnItemLost",ET_Ignore,Param_Cell,Param_Cell);

	CreateNative("War3_GetOwnsItem",NWar3_GetOwnsItem);
	CreateNative("War3_SetOwnsItem",NWar3_SetOwnsItem);
	
	CreateNative("W3IsItemDisabledGlobal",NW3IsItemDisabledGlobal);
	CreateNative("W3IsItemDisabledForRace",NW3IsItemDisabledForRace);
	return true;
}

public NWar3_GetOwnsItem(Handle:plugin,numParams)
{
	if (ValidPlayer(GetNativeCell(1)))
		return _:playerOwnsItem[GetNativeCell(1)][GetNativeCell(2)];
	else
		return false;

}

public NWar3_SetOwnsItem(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new itemid=GetNativeCell(2);
	new bool:old=playerOwnsItem[client][itemid];
	playerOwnsItem[client][itemid]=bool:GetNativeCell(3);
	if(old!=playerOwnsItem[client][itemid]){
		switch(playerOwnsItem[client][itemid]){
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
				ThrowNativeError(0,"set owns item is not true or false");
			}
		}
	}
		
	
}
public NW3IsItemDisabledGlobal(Handle:plugin,numParams)
{
	new itemid=GetNativeCell(1);
	decl String:itemShort[16];
	W3GetItemShortname(itemid,itemShort,16);
	
	decl String:cvarstr[100];
	decl String:exploded[MAXITEMS][16];
	decl num;
	GetConVarString(hitemRestrictionCvar,cvarstr,sizeof(cvarstr));
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
}
public NW3IsItemDisabledForRace(Handle:plugin,numParams)
{
	new raceid=GetNativeCell(1);
	new itemid=GetNativeCell(2);
	if(raceid>0){
		decl String:itemShort[16];
		W3GetItemShortname(itemid,itemShort,sizeof(itemShort));
		
		decl String:cvarstr[100];
		decl String:exploded[MAXITEMS][16];
		
		W3GetRaceItemRestrictionsStr(raceid,cvarstr,sizeof(cvarstr));
		
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
	return false;
}

















public OnWar3Event(W3EVENT:event,client){
	if(event==DoForwardClientBoughtItem){
		new itemid=W3GetVar(TheItemBoughtOrLost);
		War3_SetOwnsItem(client,itemid,true);
	
	}
	if(event==DoForwardClientLostItem){
		new itemid=W3GetVar(TheItemBoughtOrLost);
		War3_SetOwnsItem(client,itemid,false);
	
	}
	if(event==DoCheckRestrictedItems){
		CheckForRestrictedItemsOnRace(client);
	}
}



CheckForRestrictedItemsOnRace(client)
{
	new ItemsLoaded = W3GetItemsLoaded();
	for(new itemid=1;itemid<=ItemsLoaded;itemid++){
		if(War3_GetOwnsItem(client,itemid)){
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
	}
}