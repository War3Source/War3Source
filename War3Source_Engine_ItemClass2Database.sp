

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo= 
{
	name="War3Source Engine Item2 Database",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};

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

}

bool:InitNativesForwards()
{
	CreateNative("W3SaveItem2ExpireTime",NW3SaveItem2ExpireTime);
	return true;
}
public OnWar3Event(W3EVENT:event,client){
	if(event==DatabaseConnected){
		new Handle:DB=W3GetVar(hDatabase);
		if(DB!=INVALID_HANDLE){
			CheckTable(DB);
		}
		else{
			LogError("DatabaseConnected called by database is invalid");
		}
	}
	if(event==InitPlayerVariables){ //already cleared, we just set new value
		INTERNALGetItem2ExpireTimes(client);
	}
	
}
public NW3SaveItem2ExpireTime(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new item=GetNativeCell(2);
	INTERNALSaveItem2ExpireTime(client,item);
}


CheckTable(Handle:hDB){
	SQL_LockDatabase(hDB); //non threading operations here, done once on plugin load only, not map change

	// Database conversion methods
	new Handle:query=SQL_Query(hDB,"SELECT * from war3source_item2 LIMIT 1");
	
	
	if(query==INVALID_HANDLE)
	{   //query failed no result, re create table (table doesnt exist)
		PrintToServer("[War3Source] war3source_item2 empty or not found, dropping and re-creating it") ;
		SQL_FastQueryLogOnError(hDB,"DROP TABLE war3source_item2");
		if(!SQL_FastQueryLogOnError(hDB,"CREATE TABLE war3source_item2 (steamid varchar(64) , itemshort varchar(64), expiretime int)"  ))
		{
			War3Failed("[War3Source] ERROR in the creation of the SQL table war3source_item2.");
		}
		if(!SQL_FastQueryLogOnError(hDB,"CREATE UNIQUE INDEX steamid_itemshort ON war3source_item2 (steamid,itemshort)"  ))
		{
			War3Failed("[War3Source] ERROR in the creation of the SQL table war3source_item2.");
		}
	}
	else
	{
		//table exists
		new dummyfield;
		
		//add a column if not exists
		if(!SQL_FieldNameToNum(query, "expiretime", dummyfield))
		{
			AddColumn(hDB,"expiretime","int","war3source_item2");
			PrintToServer("[War3Source] Tried to ADD column in TABLE %s: %s","war3source_item2","expiretime");
		}
		
		CloseHandle(query);
	}
	SQL_UnlockDatabase(hDB);	
}
INTERNALGetItem2ExpireTimes(client){
	new Handle:hDB=W3GetVar(hDatabase);
	if(hDB!=INVALID_HANDLE){
		PrintToConsole(client,"[War3Source] Getting your items");
		new String:longquery[4000];
		
		new String:steamid[32];
		GetClientAuthString(client,steamid,sizeof(steamid));
		
		Format(longquery,sizeof(longquery),"SELECT itemshort,expiretime FROM war3source_item2 WHERE steamid='%s'",steamid);
		SQL_TQuery(hDB,T_CallbackSelectData,longquery,client);
		
	}
}
public T_CallbackSelectData(Handle:owner,Handle:hndl,const String:error[],any:client)
{
	SQLCheckForErrors(hndl,error,"T_CallbackSelectData");
	
	if(!ValidPlayer(client))
		return;
	
	if(hndl==INVALID_HANDLE)
	{
		LogError("[War3Source] ERROR: SELECT player data failed! Check DATABASE settings!");
	}
	
	else
	{
		SQL_Rewind(hndl);
		new loop=SQL_GetRowCount(hndl);
		for(new i=0;i<loop;i++)
		{
			if(!SQL_FetchRow(hndl))
			{
				//This would be pretty fucked to occur here
				LogError("[War3Source] Unexpected error loading player data, could not FETCH row. Check DATABASE settings!");
				return;
			}
			else{
				new String:itemshort[32];
				W3SQLPlayerString(hndl,"itemshort",itemshort,sizeof(itemshort));
				new item=War3_GetItem2IdByShortname(itemshort);
				
				new expiretime=W3SQLPlayerInt(hndl,"expiretime");
				
				if(expiretime>NOW()){
					W3SetVar(TheItemBoughtOrLost,item);
					W3CreateEvent(DoForwardClientBoughtItem2,client);
					W3SetItem2ExpireTime(client,item,expiretime);
					PrintToConsole(client,"[War3Source] You have item: %s %d",itemshort,NOW()-expiretime);
				}
			}
		}
	}
}




INTERNALSaveItem2ExpireTime(client,item){
	new Handle:hDB=W3GetVar(hDatabase);
	if(hDB!=INVALID_HANDLE){
		if(War3_GetOwnsItem2(client,item)){
			new String:longquery[4000];
			
			new String:steamid[32];
			GetClientAuthString(client,steamid,sizeof(steamid));
			
			new String:itemshort[32];
			W3GetItem2Shortname(item,itemshort,sizeof(itemshort));
			
			Format(longquery,sizeof(longquery),"REPLACE INTO war3source_item2 (steamid,itemshort,expiretime) VALUES('%s','%s','%d')",steamid,itemshort,W3GetItem2ExpireTime(client,item));
			SQL_TQuery(hDB,T_CallbackSaveTime,longquery,client);
		}
		else{
			W3LogError("SaveItem2ExpireTime was called but client does not have item");
		}
	}
}
//catch custom errors
public T_CallbackSaveTime(Handle:owner,Handle:hndl,const String:error[],any:client)
{
	SQLCheckForErrors(hndl,error,"T_CallbackSaveTime");
}
