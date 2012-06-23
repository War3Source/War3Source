
#pragma tabsize 0
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


new bool:playerOwnsItem[MAXPLAYERSCUSTOM][MAXITEMS];
new bool:RestoreItemsFromDeath_playerOwnsItem[MAXPLAYERSCUSTOM][MAXITEMS+1];
new Handle:g_OnItemPurchaseHandle;
new Handle:g_OnItemLostHandle;

new Handle:hitemRestrictionCvar;

new Handle:hCvarMaxShopitems;
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
	hCvarMaxShopitems=CreateConVar("war3_max_shopitems","2");
//    RegConsoleCmd("say", Command_Say);
}

public bool:InitNativesForwards()
{
	g_OnItemPurchaseHandle=CreateGlobalForward("OnItemPurchase",ET_Ignore,Param_Cell,Param_Cell);
	g_OnItemLostHandle=CreateGlobalForward("OnItemLost",ET_Ignore,Param_Cell,Param_Cell);

    CreateNative("War3_RestoreItemsFromDeath",NWar3_RestoreItemsFromDeath);

    CreateNative("War3_GetOwnsItem",NWar3_GetOwnsItem);
	CreateNative("War3_SetOwnsItem",NWar3_SetOwnsItem);
	
	CreateNative("W3IsItemDisabledGlobal",NW3IsItemDisabledGlobal);
	CreateNative("W3IsItemDisabledForRace",NW3IsItemDisabledForRace);
	
	CreateNative("GetMaxShopitemsPerPlayer",NGetMaxShopitemsPerPlayer);
	
	CreateNative("GetClientItemsOwned",NGetClientItemsOwned);
	
	return true;
}

/*public Action:Command_Say(client, args)
{
	new String:text[192]
	GetCmdArgString(text, sizeof(text))

	new startidx = 0
	if (text[0] == '"')
	{
		startidx = 1
		// Strip the ending quote, if there is one
		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0'
		}
	}
	if (StrEqual(text[startidx], "buyprevious"))
	{
        if(War3_GetGame()==Game_TF)
            War3_RestoreItemsFromDeath(client,true,false);
        else if(War3_GetGame()==Game_CS)
            War3_RestoreItemsFromDeath(client,true,true);


		// Block the client's messsage from broadcasting
		//return Plugin_Handled
	}

	// Let say continue normally
	return Plugin_Continue

}     */

//native War3_RestoreItemsFromDeath(client,bool:payforit,bool:csmoney);
public NWar3_RestoreItemsFromDeath(Handle:plugin,numParams)
{
// To Do: Fix bug that allows player to use buyprevious when they spawn
//        which also allows them to buy one more item beyond their max items allowed.
new client=GetNativeCell(1);
new bool:payforit=GetNativeCell(2);
new bool:csmoney=GetNativeCell(3);

new ItemsLoaded = W3GetItemsLoaded();
    if (ValidPlayer(client))
        {
		new counter;
		new maxitemsallowed = GetMaxShopitemsPerPlayer() - 1;
		new String:itemName[64];
            //payforit
            if(payforit==true)
            {
                new num = 0;
                // Check to see if they already have exact a copy of these items
                new bool:checkit = false;
                for(new i;i<=ItemsLoaded;i++)
                {
                    if((playerOwnsItem[client][i]==RestoreItemsFromDeath_playerOwnsItem[client][i]) && (playerOwnsItem[client][i]==true))
                    {
                        checkit=true;
						counter++;
                    }
                    else checkit=false;
                }
				if(counter>maxitemsallowed)
				{
					War3_ChatMessage(client,"{red}<<buyprevious>>{default}You have more items than allowed by server.\n{green}<<buyprevious>>{default}Correct adjustments will be made.");
				}
                if(checkit==true)
                {
                    War3_ChatMessage(client,"{red}<<buyprevious>>{default}You already{red} own{default} these items{default}.");
                    return false;
                }
				counter = 0;

                    // Record how much its going to cost
                    for(new i;i<=ItemsLoaded;i++)
                    {
                        if(RestoreItemsFromDeath_playerOwnsItem[client][i]==true)
                        {
                            num = num + W3GetItemCost(i,GetNativeCell(3));
							counter++;
                        }
					if(counter>=maxitemsallowed)
						break;
                    }
                    // Figure out if its gold or cs money
                    new GoldMoney;
                    if(csmoney==true)
                        GoldMoney = GetCSMoney(client);
                    else
                        GoldMoney = War3_GetGold(client);
                    // See if they can afford it
                    if(GoldMoney>=num)
                    {
                        // Do the math
                        new MoneyGoldLeft=(GoldMoney-num);
                        // Charge them for CSMoney or Gold?
                        if(csmoney==true)
                            SetCSMoney(client,MoneyGoldLeft);
                        else
                            War3_SetGold(client,MoneyGoldLeft);
                        // Find the Items
						counter = 0;
                        for(new i;i<=ItemsLoaded;i++)
                        {
                            //playerOwnsItem[client][i]=RestoreItemsFromDeath_playerOwnsItem[client][i];
						if(counter>=maxitemsallowed)
							break;
                            if(RestoreItemsFromDeath_playerOwnsItem[client][i]==true)
                            {
                                War3_SetOwnsItem(client,i,true);
                                W3GetItemName(i,itemName,64);
                                War3_ChatMessage(client,"{red}<<buyprevious>>{default}You bought {green}%s{default}.",itemName);
								counter++;
                            }
                            if(RestoreItemsFromDeath_playerOwnsItem[client][i]==false && War3_GetOwnsItem(client,i))
							{
                                War3_SetOwnsItem(client,i,false);
                                W3GetItemName(i,itemName,64);
                                War3_ChatMessage(client,"{red}<<buyprevious>>{default}Item Discarded: {green}%s{default} (You didn't own this item on death).",itemName);
							}
                        }
                        // Tell them the total cost
                        // To do: if cost == 0 then tell them they didn't buy anything.
                        if(csmoney==true)
                            War3_ChatMessage(client,"{red}<<buyprevious>>{default}Total cost ${green}%i {default}.",num);
                        else
                            War3_ChatMessage(client,"{red}<<buyprevious>>{default}Total cost {green}%i {default}gold.",num);
                    }
                    else
                    {
                        War3_ChatMessage(client,"{red}<<buyprevious>>{default}You can not afford your previous items.")
                    }
            }
            else
            {
            //no cost
			counter = 0;
				for(new i;i<=ItemsLoaded;i++)
				{
					//playerOwnsItem[client][i]=RestoreItemsFromDeath_playerOwnsItem[client][i];
					if(RestoreItemsFromDeath_playerOwnsItem[client][i]==true)
						{
							War3_SetOwnsItem(client,i,true);
							W3GetItemName(i,itemName,64);
							War3_ChatMessage(client,"{red}<<buyprevious>>{default}You receive {green}%s{default}.",itemName);
							counter++;
						}
	  				if(RestoreItemsFromDeath_playerOwnsItem[client][i]==false && War3_GetOwnsItem(client,i))
						{
							War3_SetOwnsItem(client,i,false);
							W3GetItemName(i,itemName,64);
							War3_ChatMessage(client,"{red}<<buyprevious>>{default}Item Discarded: {green}%s{default} (You didn't own this item on death).",itemName);
						}
					if(counter>=maxitemsallowed)
						break;
                }
            }
            return true;
        }
    else
		return false;
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
	new client=GetNativeCell(1);
	new num=0;
	new ItemsLoaded = W3GetItemsLoaded();
	for(new i=1;i<=ItemsLoaded;i++){
		if(War3_GetOwnsItem(client,i)){
			num++;
		}
	}
	return num;
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
    if(event==OnDeathPre){
    new ItemsLoaded = W3GetItemsLoaded();
        for(new i2;i2<=ItemsLoaded;i2++)
        {
         RestoreItemsFromDeath_playerOwnsItem[client][i2]=playerOwnsItem[client][i2];
        }
    }
}

public OnClientPutInServer(client)
{
    ResetArrayVals(client);
}

ResetArrayVals(client)
{
    for(new i;i<=MAXITEMS;i++)
    {
        RestoreItemsFromDeath_playerOwnsItem[client][i]=false;
    }
}

public OnMapStart()
{
// Clear Buy Previous
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