/*
* File: War3Source.sp
* Description: The main file for War3Source.
* Author(s): Anthony Iacono  & OwnageOwnz 
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>



#define VERSION_NUM "1.2.0.2"
#define REVISION_NUM 12002 //increment every release


#define AUTHORS "PimpinJuice and Ownz" 

//variables needed by includes here



//use ur own natives and stocks
#include "W3SIncs/War3Source_Interface"



// War3Source Includes
#include "W3SIncs/War3SourceMain"




public Plugin:myinfo= 
{
	name="War3Source",
	author=AUTHORS,
	description="Brings a Warcraft like gamemode to the Source engine.",
	version=VERSION_NUM,
	url="http://war3source.com/"
};





public APLRes:AskPluginLoad2(Handle:myself,bool:late,String:error[],err_max)
{
	PrintToServer("--------------------------AskPluginLoad2----------------------\n[War3Source] Plugin loading...");
	
	
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
	
	
	
	new String:gameDir[64];
	GetGameFolderName(gameDir,sizeof(gameDir));
	//new Handle:dummyCvar=CreateConVar("war3_dummy_cvar","0","DO NOT TOUCH THIS!");
	if(StrContains(gameDir,"cstrike",false)==0)
	{
		
		g_Game=Game_CS;
		PrintToServer("[War3Source] Game set: Counter-Strike Source g_Game %d",g_Game);
		ServerCommand("sv_allowminmodels 0");
	}
	else if(StrContains(gameDir,"dod",false)==0)
	{
		PrintToServer("[War3Source] Game set: Day of Defeat Source (ONLY DEVELOPER SUPPORT!)");
		g_Game=Game_DOD;
	}
	else if(StrContains(gameDir,"tf",false)==0)
	{
		PrintToServer("[War3Source] Game set: Team Fortress 2");
		g_Game=Game_TF;
	}
	else
	{
		SetFailState("[War3Source] Sorry, this game isn't support by War3Source yet. If you think this is a mistake, you probably renamed your game directory. For example, re-naming cstrike to cstrike2 will cause this error.");
	}
	
	
	//mark some natives
	//MarkNativeAsOptional("TF2_IsPlayerInvuln");
	//TE_ParticleToClient(attacker, "miss_text", pos); //mark?
	new String:path_log[1024];
	BuildPath(Path_SM,path_log,sizeof(path_log),"logs/war3sourcelog.txt");
	new Handle:hFile=OpenFile(path_log,"a+");
	if(hFile)
	{
		CloseHandle(hFile);
		DeleteFile(path_log);
		
	}

	hW3Log=OpenFile(path_log,"a+");
	
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
	
	
	
	// MaxSpeed/MinGravity/MinAlpha/OverrideSpeed/OverrideGravity/OverrideAlpha
	CreateTimer(0.1,DeciSecondLoop,_,TIMER_REPEAT);
		
	PrintToServer("[War3Source] Plugin finished loading.\n-------------------END OnPluginStart-------------------");
	
	RegServerCmd("loadraces",CmdLoadRaces);
	
	RegConsoleCmd("dmgtest",CmdDmgTest);
	
	//testihng commands here
	RegConsoleCmd("flashscreen",FlashTest);
	RegConsoleCmd("ubertest",UberTest);
//	RegConsoleCmd("fullskill",FullSkilltest);

	RegConsoleCmd("war3refresh",refreshcooldowns);
	RegConsoleCmd("armortest",armortest);
	RegConsoleCmd("calltest",calltest);
	RegConsoleCmd("calltest2",calltest2);
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
}
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
}
public Action:CmdDmgTest(client,args){
	War3_DealDamage(client,50,_,_,"testdmg");
}
public Action:CmdLoadRaces(args){
	PrintToServer("FORCE LOADING ALL RACES AND ITEMS");
	LoadRacesAndItems();
	return Plugin_Handled;
}
public Action:refreshcooldowns(client,args){
	if(W3IsDeveloper(client)){
		new raceid=War3_GetRace(client);
		for( new skillnum;skillnum<MAXSKILLCOUNT;skillnum++){
			War3_CooldownMGR(client,0.0,raceid,skillnum,_,_,false);
		}
		
	}
}

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
	for(new i;i<War3_GetRaceSkillCount(race);i++){
		War3_SetSkillLevel(client,race,i,4);
	}
}











public OnMapStart()
{
	
	DoWar3InterfaceExecForward();
	
	LoadRacesAndItems();
	
	CreateTimer(5.0, CheckCvars, 0);

	
	DelayedWar3SourceCfgExecute();//
	
	
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
	//new String:buffer2[70];
	//GetConVarString(hWar3versionConvarHandle, buffer2, sizeof(buffer2));
	//SetConVarString(hWar3versionConvarHandle, buffer2, false, false);
}




public Action:OnGetGameDescription(String:gameDesc[64])
{
	if(GetConVarInt(hChangeGameDescCvar)>0){
		Format(gameDesc,sizeof(gameDesc),"War3Source %s",VERSION_NUM);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnAllPluginsLoaded() //called once only, will not call again when map changes
{
	PrintToServer("OnAllPluginsLoaded");
}
public DelayedWar3SourceCfgExecute()
{
	if(FileExists("cfg/war3source.cfg"))
	{
		ServerCommand("exec war3source.cfg");
		PrintToServer("[War3Source] Executed war3source.cfg");
	}
}

public LoadRacesAndItems()
{	
	new Float:starttime=GetEngineTime();
	//ordered loads
	new res;
	for(new i;i<=MAXRACES*10;i++){
		Call_StartForward(g_OnWar3PluginReadyHandle);
		Call_PushCell(i);		
		Call_Finish(res);
	}
	
	//orderd loads 2
	for(new i;i<=MAXRACES*10;i++){
		Call_StartForward(g_OnWar3PluginReadyHandle2);
		Call_PushCell(i);		
		Call_Finish(res);
	}
	
	//unorderd loads
	Call_StartForward(g_OnWar3PluginReadyHandle3);
	Call_Finish(res);

	PrintToServer("RACE ITEM LOAD FINISHED IN %.2f seconds",GetEngineTime()-starttime);
}




public zOnPluginEnd() //public OnMapEnd()
{	
	PrintToServer("[War3Source] OnPluginEnd ");
}

public OnConfigsExecuted()
{
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

