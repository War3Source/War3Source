

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


new levelbank[MAXPLAYERS];
new Handle:hCvar_NewPlayerLevelbank;

new Handle:hCvarPrintLevelBank;


public Plugin:myinfo= 
{
	name="War3source Engine LevelBank",
	author="Ownz",
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
	hCvar_NewPlayerLevelbank=CreateConVar("war3_new_player_levelbank","30","The amount of free levels a person gets that is new to the server (no xp record)");
	W3SetVar(hNewPlayerLevelbankCvar,hCvar_NewPlayerLevelbank);
		
	hCvarPrintLevelBank=CreateConVar("war3_print_levelbank_spawn","0","Print how much you have in your level bank in chat every time you spawn?");


	RegAdminCmd("war3_addlevelbank",War3Source_CMD_addlevelbank,ADMFLAG_RCON,"Add to user(steamid)'s level bank");
	LoadTranslations("w3s.levelbank.phrases");
}

bool:InitNativesForwards()
{
	CreateNative("W3GetLevelBank",NW3GetLevelBank); //these have forwards to handle
	CreateNative("W3SetLevelBank",NW3SetLevelBank); 

	return true;
}
public NW3GetLevelBank(Handle:plugin,numParams){
	
	return levelbank[GetNativeCell(1)];
}
public NW3SetLevelBank(Handle:plugin,numParams){
	
	levelbank[GetNativeCell(1)]=GetNativeCell(2);
}



public OnWar3Event(W3EVENT:event,client){
	if(event==PlayerIsNewToServer){
		GiveNewPlayerLevelBank(client);
	}
	if(event==DoShowLevelBank){
		CmdShowLevelBankMenu(client);
	}
	if(event==ClearPlayerVariables){
		W3SetLevelBank(client,0);
	}
}


GiveNewPlayerLevelBank(client){
	W3SetLevelBank(client,W3GetLevelBank(client)+GetConVarInt(hCvar_NewPlayerLevelbank));
}







public CmdShowLevelBankMenu(client){
	SetTrans(client);
	new Handle:hMenu=CreateMenu(OnSelectShowLevelBankMenu);
	SetMenuTitle(hMenu,"%T","You have {amount} levels in your levelbank",client,W3GetLevelBank(client));
	SetMenuExitButton(hMenu,true);
	
	new String:str[1000],String:racename[64];
	War3_GetRaceName(War3_GetRace(client),racename,sizeof(racename));
	Format(str,sizeof(str),"%T %s","Add a level to current race from bank:",client,racename);
	AddMenuItem(hMenu,"0",str);
	DisplayMenu(hMenu,client,20);
}

public OnSelectShowLevelBankMenu(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		if(selection==0){
			SetTrans(client);
			if(W3GetLevelBank(client)<=0){
				War3_ChatMessage(client,"%T","You do not have any levels in the level bank",client);
				return;
			}
			new race=War3_GetRace(client);
			if(race<=0){
				War3_ChatMessage(client,"%T","You do not have a valid race",client);
				return;
			}
			if(W3GetRaceMaxLevel(race)<=War3_GetLevel(client,race)){
				War3_ChatMessage(client,"%T","Your race is already maxed",client);
				return;
			}
			W3SetLevelBank(client,W3GetLevelBank(client)-1);
			War3_SetLevel(client,race,War3_GetLevel(client,race)+1);
			new String:racename[64];
			War3_GetRaceName(race,racename,sizeof(racename));
			War3_ChatMessage(client,"%T %s","Successfully added a level to race",client,racename);
			CmdShowLevelBankMenu(client);
		}
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
	return;
}




public Action:War3Source_CMD_addlevelbank(client,args){
	if(args!=2){
		ReplyToCommand(client,"parameters: \"steamid\" <amount>      IE: war3_addlevelbank \"STEAM_0:1:12345\" 10");
	}
	else{
		new String:steamid[32];
		GetCmdArg(1, steamid, sizeof(steamid));
		new String:temp[32];
		GetCmdArg(2, temp, sizeof(temp));
		new num=StringToInt(temp);
		
		
		new bool:playerwasingame;
		new ingameoldlevelbank;
		new String:othersteamid[32];
		for(new i=1;i<=MaxClients;i++){
			if(ValidPlayer(i)&&W3IsPlayerXPLoaded(i)){
				GetClientAuthString(i, othersteamid, sizeof(othersteamid));
				if(StrEqual(steamid,othersteamid,false)){
					ReplyToCommand(client,"Found client %d in game with steamid %s, giving adding to level bank levels now",i,steamid);
					ingameoldlevelbank = W3GetLevelBank(i);
					W3SetLevelBank(i,num+W3GetLevelBank(i));
					
					playerwasingame=true;
					break;
				}
			}
		}
		
		new Handle:DBIDB=W3GetDBHandle();
		if(DBIDB){
			SQL_LockDatabase(DBIDB);   //DB must not ERROR! else u will not unlock databaase!!!
			
			
			
			new String:query_buffer[512];
			new oldlevelbank;
			if(!playerwasingame){   ///not in game, we retrieve level bank
				Format(query_buffer,sizeof(query_buffer),"SELECT levelbankV2 FROM war3source WHERE steamid='%s'",steamid);
				new Handle:result=SQL_Query(DBIDB, query_buffer);
				
				if(result!=INVALID_HANDLE&&SQL_MoreRows(result)){
					ReplyToCommand(client,"steamid appears to exist");
				
					SQL_FetchRow(result);
					oldlevelbank=SQL_FetchInt(result, 0);
				}
				else{
					ReplyToCommand(client,"ERR: NO RESULT SET, player never joined the server once? Add Failed");
					SQL_UnlockDatabase(DBIDB);
					return;
				}
			}
			else{   //.he was in game, use old level bank value (but right now has the new levels)
				oldlevelbank= ingameoldlevelbank; 
			}
			
			
			
			new newlevelbank=oldlevelbank+num;

			Format(query_buffer,sizeof(query_buffer),"UPDATE war3source SET levelbankV2='%d' WHERE steamid='%s'",newlevelbank,steamid);
			if(!SQL_FastQueryLogOnError(DBIDB,query_buffer)){
				ReplyToCommand(client,"insert failed");
			}
			else{
				ReplyToCommand(client,"no sql error, success? %s    new level bank: %d",steamid,newlevelbank);
			}
			SQL_UnlockDatabase(DBIDB);
		}
		else{
			ReplyToCommand(client,"Failed: no database connection");
			return;
		}
	}
	return;
}
bool:SQL_FastQueryLogOnError(Handle:DB,const String:query[]){
	if(!SQL_FastQuery(DB,query)){
		new String:error[256];
		SQL_GetError(DB, error, sizeof(error));
		LogError("SQLFastQuery %s failed, Error: %s",query,error);
		return false;
	}
	return true;
}
public OnWar3EventSpawn(client){
	if(GetConVarInt(hCvarPrintLevelBank)&&W3GetLevelBank(client)>0){
		War3_ChatMessage(client,"%T","You have {amount} levels in your levelbank, say levelbank to use them",client,W3GetLevelBank(client));
		
	}
}