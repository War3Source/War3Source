/*  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
    War3source written by PimpinJuice (anthony) and Ownz (Dark Energy)
    All rights reserved.
*/	

/*
* File: War3Source.sp
* Description: The main file for War3Source.
* Author(s): Anthony Iacono  & OwnageOwnz (DarkEnergy)
* All handle leaks have been considered.
* If you don't like it, read through the whole thing yourself and prove yourself wrong.
*/

#pragma semicolon 1


#define VERSION_NUM "1.2.2.6"
#define REVISION_NUM 12206 //increment every release


#define AUTHORS "PimpinJuice and Ownz (DarkEnergy)" 

//used for some special things in interface
#define WAR3MAIN

#include <sourcemod>
#include "W3SIncs/sdkhooks"
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/War3SourceMain"







public Plugin:myinfo= 
{
	name="War3Source",
	author=AUTHORS,
	description="Brings a Warcraft like gamemode to the Source engine.",
	version=VERSION_NUM,
	url="http://war3source.com/"
};



public APLRes:AskPluginLoad2Custom(Handle:myself,bool:late,String:error[],err_max)
{
	
	PrintToServer("--------------------------AskPluginLoad2Custom----------------------\n[War3Source] Plugin loading...");
	
	
	new String:version[64];
	Format(version,sizeof(version),"%s by %s",VERSION_NUM,AUTHORS);
	CreateConVar("war3_version",version,"War3Source version.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	
	CreateConVar("a_war3_version",version,"War3Source version.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	
	
	if(!War3Source_InitNatives())
	{
		LogError("[War3Source] There was a failure in creating the native based functions, definately halting.");
		return APLRes_Failure;
	}
	if(!War3Source_InitForwards())
	{
		LogError("[War3Source] There was a failure in creating the forward based functions, definately halting.");
		return APLRes_Failure;
	}
	
	
	//mark some natives
	//MarkNativeAsOptional("TF2_IsPlayerInvuln");
	//TE_ParticleToClient(attacker, "miss_text", pos); //mark?
	
	return APLRes_Success;
}

public OnPluginStart()
{
    
	PrintToServer("--------------------------OnPluginStart----------------------");
	
	if(GetExtensionFileStatus("sdkhooks.ext") < 1)
		SetFailState("SDK Hooks is not loaded.");
	
	if(!War3Source_HookEvents())
		SetFailState("[War3Source] There was a failure in initiating event hooks.");
	if(!War3Source_InitCVars()) //especially sdk hooks
		SetFailState("[War3Source] There was a failure in initiating console variables.");

	if(!War3Source_InitOffset())
		SetFailState("[War3Source] There was a failure in finding the offsets required.");

	CreateTimer(0.1,DeciSecondLoop,_,TIMER_REPEAT);
		
	PrintToServer("[War3Source] Plugin finished loading.\n-------------------END OnPluginStart-------------------");
	
/*	RegServerCmd("loadraces",CmdLoadRaces);
	
	RegConsoleCmd("dmgtest",CmdDmgTest);
	#if defined WAR3DEBUGBUILD
	//testihng commands here
	RegConsoleCmd("flashscreen",FlashTest);
	RegConsoleCmd("ubertest",UberTest);
//	RegConsoleCmd("fullskill",FullSkilltest);
*/
	RegConsoleCmd("war3refresh",refreshcooldowns);
	RegConsoleCmd("armortest",armortest);
/*	RegConsoleCmd("calltest",calltest);
	RegConsoleCmd("calltest2",calltest2);
	
	RegServerCmd("whichmode",cmdwhichmode);
	
	RegConsoleCmd("diamonds",cmddiamonds);
	#endif
	
*/
}

/*
public Action:cmddiamonds(client,args)
{
	if(W3IsDeveloper(client))
	{
		War3_SetDiamonds(client,1000);
	}
}
public Action:cmdwhichmode(args){
	PrintToServer("W3? %d",W3());
	PrintToServer("SH? %d",SH());
}
public Action:calltest(client,args){
	new Handle:plugins[100];
	new Function:funcs[100];
	new length;
	
	new Handle:iter = GetPluginIterator();
	new Handle:pl;
	new Function:func;

	while (MorePlugins(iter))
	{
		pl = ReadPlugin(iter);
		func=GetFunctionByName(pl,"CheckWar3Compatability");
		if(func!=INVALID_FUNCTION){
			plugins[length]=pl;
			funcs[length]=func;
			length++;
			
		}
	}
	CloseHandle(iter);
	
	
	
	for(new i=0;i<1000;i++){
		Call_StartForward(g_CheckCompatabilityFH);
		Call_PushString(interfaceVersion);
		Call_Finish(dummyreturn);
	}
	
}
public Action:calltest2(client,args){
	new Handle:plugins[100];
	new Function:funcs[100];
	new length;
	
	new Handle:iter = GetPluginIterator();
	new Handle:pl;
	new Function:func;
	while (MorePlugins(iter))
	{
		pl = ReadPlugin(iter);
		func=GetFunctionByName(pl,"CheckWar3Compatability");
		if(func!=INVALID_FUNCTION){
			plugins[length]=pl;
			funcs[length]=func;
			length++;
			
		}
	}
	CloseHandle(iter);
	
	for(new i=0;i<1000;i++){
	
		for(new x=0;x<length;x++){
			
			Call_StartFunction(plugins[x],funcs[x]);
			Call_PushString(interfaceVersion);
			Call_Finish(dummyreturn);
		}
	}
}?*/
public Action:armortest(client,args){
	if(W3IsDeveloper(client)){
		for(new i=1;i<=MaxClients;i++){
			new String:arg[10];
			GetCmdArg(1,arg,sizeof(arg));
			new Float:num=StringToFloat(arg);
			War3_SetBuff(i,fArmorPhysical,1,num);
			War3_SetBuff(i,fArmorMagic,1,num);
		}
	}
}/*
public Action:CmdDmgTest(client,args){
	War3_DealDamage(client,50,_,_,"testdmg");
}
public Action:CmdLoadRaces(args){
	PrintToServer("FORCE LOADING ALL RACES AND ITEMS");
	LoadRacesAndItems();
	return Plugin_Handled;
}*/
public Action:refreshcooldowns(client,args){
	if(W3IsDeveloper(client)){
		if(W3()){
			new raceid=War3_GetRace(client);
			if(raceid>0){
				for( new skillnum=1;skillnum<=War3_GetRaceSkillCount(raceid);skillnum++){
					War3_CooldownMGR(client,0.0,raceid,skillnum,false,false);
				}
			}
		}
	}
}
/*
public Action:FlashTest(client,args){
	if(args==6){
		new String:arg[32];
		GetCmdArg(1,arg,sizeof(arg));
		new r=StringToInt(arg);
		GetCmdArg(2,arg,sizeof(arg));
		new g=StringToInt(arg);
		GetCmdArg(3,arg,sizeof(arg));
		new b=StringToInt(arg);
		GetCmdArg(4,arg,sizeof(arg));
		new a=StringToInt(arg);
		GetCmdArg(5,arg,sizeof(arg));
		new Float:duration=StringToFloat(arg);
		
		GetCmdArg(6,arg,sizeof(arg));
		new Float:duration2=StringToFloat(arg);
		
		new Handle:hBf=StartMessageOne("Fade",client);
		if(hBf!=INVALID_HANDLE)
		{
			BfWriteShort(hBf,RoundFloat(duration*255));
			BfWriteShort(hBf,RoundFloat(duration2*255));
			BfWriteShort(hBf,0x0001); 
			BfWriteByte(hBf,r);
			BfWriteByte(hBf,g);
			BfWriteByte(hBf,b);
			BfWriteByte(hBf,a);
			EndMessage();
		}
		
	}
}
public Action:UberTest(client,args){
	if(W3IsDeveloper(client)){
		ReplyToCommand(client,"is ubered? %s",War3_IsUbered(client)?"true":"false");
		if(args==2){
			new String:buf[10];
			GetCmdArg(1,buf,sizeof(buf));
			new n1=StringToInt(buf);
			GetCmdArg(2,buf,sizeof(buf));
			new n2=StringToInt(buf);
			War3_SetXP(client,n1,n2);
		}
		if(args==1){
			new String:buf[10];
			GetCmdArg(1,buf,sizeof(buf));
			new n1=StringToInt(buf);
			
			if(!War3_GetOwnsItem(client,n1)){
							
				W3SetVar(TheItemBoughtOrLost,n1);
				W3CreateEvent(DoForwardClientBoughtItem,client);
			}
			else{
				ReplyToCommand(client,"Already haz item %d",n1);
				
			}
		}
	}
}



public Action:FullSkilltest(client,args){
	new race=War3_GetRace(client);
	new SkillCount = War3_GetRaceSkillCount(race);
	for(new i=1;i<=SkillCount;i++){
		War3_SetSkillLevel(client,race,i,4);
	}
}







*/



public OnMapStart()
{
	PrintToServer("OnMapStart");
	W3CreateEvent(UNLOADPLUGINSBYMODE,0); // not something that is considered unapprovable but make sure your defines have naming schemas like War3Event_Blah
		
	DoWar3InterfaceExecForward();
	
	LoadRacesAndItems();
	
	CreateTimer(5.0, CheckCvars, 0);

	
	
	
	OneTimeForwards();

}

///test script
public Action:CheckCvars(Handle:timer, any:client)
{
	new Handle:convarList = INVALID_HANDLE, Handle:conVar = INVALID_HANDLE;
	new bool:isCommand;
	new flags;
	new String:buffer[70], String:buffer2[70], String:desc[256];
	
	convarList = FindFirstConCommand(buffer, sizeof(buffer), isCommand, flags, desc, sizeof(desc));
	if(convarList == INVALID_HANDLE)
		return Plugin_Handled;
	
	do
	{
		// don't print commands or convars without the NOTIFY flag
		if(isCommand || (!isCommand && (flags & FCVAR_NOTIFY == 0)))
			continue;
		
		conVar = FindConVar(buffer);
		GetConVarString(conVar, buffer2, sizeof(buffer2));
		SetConVarString(conVar, buffer2, false, false);
		CloseHandle(conVar);
		
	} while(FindNextConCommand(convarList, buffer, sizeof(buffer), isCommand, flags, desc, sizeof(desc)));
	
	if(convarList != INVALID_HANDLE)
		CloseHandle(convarList);
	
	return Plugin_Handled;
}




public Action:OnGetGameDescription(String:gameDesc[64])
{
// Lol @ function named W3
	if(W3()&&GetConVarInt(hChangeGameDescCvar)>0)
	{
		Format(gameDesc,sizeof(gameDesc),"War3Source %s",VERSION_NUM);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnAllPluginsLoaded() //called once only, will not call again when map changes
{
	PrintToServer("OnAllPluginsLoaded");
}


LoadRacesAndItems()
{	

	PrintToServer("RACE ITEM LOAD");
	new Float:starttime=GetEngineTime();
	//ordered loads
	new res;
	if(W3())
	{
		for(new i;i<=MAXRACES*10;i++)
		{
			Call_StartForward(g_OnWar3PluginReadyHandle);
			Call_PushCell(i);		
			Call_Finish(res);
		}
		
		//orderd loads 2
		for(new i;i<=MAXRACES*10;i++)
		{
			Call_StartForward(g_OnWar3PluginReadyHandle2);
			Call_PushCell(i);		
			Call_Finish(res);
		}
		
		//unorderd loads
		Call_StartForward(g_OnWar3PluginReadyHandle3);
		Call_Finish(res);
	}
	
	if(SH())
	{
		
		//SH ordered load
		for(new i;i<=MAXRACES*10;i++)
		{
			Call_StartForward(hOnSHLoadHeroOrItemOrdered);
			Call_PushCell(i);		
			Call_Finish(res);
		}
	}

	PrintToServer("RACE ITEM LOAD FINISHED IN %.2f seconds",GetEngineTime()-starttime);
	
	DelayedWar3SourceCfgExecute();
	
}

DelayedWar3SourceCfgExecute()
{
	if(W3())
	{
		if(FileExists("cfg/war3source.cfg"))
		{
			ServerCommand("exec war3source.cfg");
			PrintToServer("[War3Source] Executing war3source.cfg");
		}
		else
		{
			PrintToServer("[War3Source] Could not find war3source.cfg, we recommend all servers have this file");
		}
	}
	
	if(SH())
	{
		if(FileExists("cfg/superhero.cfg"))
		{
			ServerCommand("exec superhero.cfg");
			PrintToServer("[War3Source] Executing superhero.cfg");
		}
		else
		{
			PrintToServer("[War3Source] Could not find superhero.cfg, we recommend all servers have this file");
		}
	}
}

public OnClientPutInServer(client)
{
	LastLoadingHintMsg[client]=GetGameTime();
	//DatabaseSaveXP now handles clearing of vars and triggering retrieval
}

public OnClientDisconnect(client)
{
	//DatabaseSaveXP now handles clearing of vars and triggering retrieval
}

