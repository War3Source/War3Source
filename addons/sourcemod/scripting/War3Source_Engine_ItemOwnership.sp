#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Item Ownership",
    author = "War3Source Team",
    description = "Controls who owns what item"
};

new bool:playerOwnsItem[MAXPLAYERSCUSTOM][MAXITEMS];
new bool:g_bPlayerOwnedItemPreviousLife[MAXPLAYERSCUSTOM][MAXITEMS+1];
new Handle:g_OnItemPurchaseHandle;
new Handle:g_OnItemLostHandle;

new Handle:hitemRestrictionCvar;

new Handle:hCvarMaxShopitems;

public OnPluginStart()
{
    hitemRestrictionCvar=CreateConVar("war3_item_restrict","","GLOBAL Disallow items in shopmenu, shortname separated by comma only ie:'claw,orb'");
    hCvarMaxShopitems=CreateConVar("war3_max_shopitems","2","How much shop items can one player have");
}

public bool:InitNativesForwards()
{
    g_OnItemPurchaseHandle=CreateGlobalForward("OnItemPurchase",ET_Ignore,Param_Cell,Param_Cell);
    g_OnItemLostHandle=CreateGlobalForward("OnItemLost",ET_Ignore,Param_Cell,Param_Cell);

    CreateNative("War3_RestoreItemsFromDeath", Native_War3_RestoreItemsFromDeath);

    CreateNative("War3_GetOwnsItem",NWar3_GetOwnsItem);
    CreateNative("War3_SetOwnsItem",NWar3_SetOwnsItem);
    
    CreateNative("W3IsItemDisabledGlobal",NW3IsItemDisabledGlobal);
    CreateNative("W3IsItemDisabledForRace",NW3IsItemDisabledForRace);
    
    CreateNative("GetMaxShopitemsPerPlayer",NGetMaxShopitemsPerPlayer);
    
    CreateNative("GetClientItemsOwned",NGetClientItemsOwned);
    
    return true;
}

public Native_War3_RestoreItemsFromDeath(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    
    if (!ValidPlayer(client))
    {
        return;
    }
    
    new maxAmountOfItemsAllowed = GetMaxShopitemsPerPlayer();
    for(new i; i <= W3GetItemsLoaded(); i++)
    {
        if(GetClientItemsOwned(client) >= maxAmountOfItemsAllowed)
        {
            break;
        }
    
        if(g_bPlayerOwnedItemPreviousLife[client][i] && !War3_GetOwnsItem(client, i))
        {
            W3SetVar(EventArg1, i);
            W3SetVar(EventArg2, false);
            W3CreateEvent(DoTriedToBuyItem,client);
        }
    }
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



public NGetClientItemsOwned(Handle:h,n){
    new client = GetNativeCell(1);
    new amount = 0;
    
    for(new x=1; x <= W3GetItemsLoaded(); x++)
    {
        if(War3_GetOwnsItem(client, x))
        {
            amount++;
        }
    }
    
    return amount;
}

public NGetMaxShopitemsPerPlayer(Handle:h,n){
    return GetConVarInt(hCvarMaxShopitems);
}

// WAR3EVENT
//new bool:BuyPrevious1_playerOwnsItem[MAXPLAYERSCUSTOM][MAXITEMS];
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
    // Record Items before death
    if(event==OnDeathPre)
    {
        //Check to see if Player owns any items, if so.. record those items,
        // otherwise keep the current record.
        if(GetClientItemsOwned(client)>0)
        {
            new ItemsLoaded = W3GetItemsLoaded();
            for(new i2;i2<=ItemsLoaded;i2++)
            {
                    g_bPlayerOwnedItemPreviousLife[client][i2]=playerOwnsItem[client][i2];
            }
        }
    }
}

//Clear Buyprevious items from previous connetion
public OnClientPutInServer(client)
{
    ResetArrayVals(client);
}

ResetArrayVals(client)
{
    for(new i;i<=MAXITEMS;i++)
    {
        g_bPlayerOwnedItemPreviousLife[client][i]=false;
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