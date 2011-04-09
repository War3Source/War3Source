/*
* File: War3Source.sp
* Description: The main file for War3Source.
* Author(s): Anthony Iacono  & OwnageOwnz
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>



#define VERSION_NUM "1.1.6B5"
#define REVISION_NUM 1165 //increment every release


#define AUTHORS "PimpinJuice and Ownz" 

//variables needed by includes here

new String:levelupSound[]="war3source/levelupcaster.wav";



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
	Format(version,63,"%s by %s",VERSION_NUM,AUTHORS);
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
	GetGameFolderName(gameDir,64);
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
	
	
	
	return APLRes_Success;
}

public OnPluginStart()
{
    
	PrintToServer("--------------------------OnPluginStart----------------------");
	
	if(GetExtensionFileStatus("sdkhooks.ext") < 1)
		SetFailState("SDK Hooks is not loaded.");
	
		
	if(!War3Source_InitiateHelpVector())
		SetFailState("[War3Source] There was a failure in creating the help vector, definitely halting.");
	if(!War3Source_HookEvents())
		SetFailState("[War3Source] There was a failure in initiating event hooks.");
	if(!War3Source_InitCVars())
		SetFailState("[War3Source] There was a failure in initiating console variables.");
	if(!War3Source_RegAdminConsoleCmds())
		SetFailState("[War3Source] There was a failure in initiating admin console commands.");
	if(!War3Source_InitHooks())
		SetFailState("[War3Source] There was a failure in initiating the hooks.");
	if(!War3Source_InitOffset())
		SetFailState("[War3Source] There was a failure in finding the offsets required.");
	
	
	////DATABSE CONNECTS HERE
	if(!War3Source_ParseSettings())
		SetFailState("[War3Source] There was a failure in parsing the configuration file.");
	
	War3Source_InitHelpCommands();
	
	LoadTranslations("w3s._main.phrases");
	
	// MaxSpeed/MinGravity/MinAlpha/OverrideSpeed/OverrideGravity/OverrideAlpha
	CreateTimer(0.1,DeciSecondLoop,_,TIMER_REPEAT);
		
	PrintToServer("[War3Source] Plugin finished loading.\n-------------------END OnPluginStart-------------------");
	
	RegServerCmd("loadraces",CmdLoadRaces);
	
	RegConsoleCmd("dmgtest",CmdDmgTest);
	
	//testihng commands here
	RegConsoleCmd("flashscreen",FlashTest);
	RegConsoleCmd("ubertest",UberTest);
	RegConsoleCmd("fullskill",FullSkilltest);
	RegConsoleCmd("menutest",MenuTest);
	RegConsoleCmd("war3refresh",refreshcooldowns);
	RegConsoleCmd("armortest",armortest);
	RegConsoleCmd("calltest",calltest);
}
public Action:calltest(client,args){


	Call_StartForward(g_CheckCompatabilityFH);
	Call_PushString(interfaceVersion);
	Call_Finish(dummyreturn);
	
	
	
	
	decl String:buffer[256];
	
	new Handle:iter = GetPluginIterator();
	new Handle:pl;
	new Handle:func;
	while (MorePlugins(iter))
	{
		pl = ReadPlugin(iter);
		GetFunctionByName(pl,"CheckWar3Compatability");
	}
	
	CloseHandle(iter);
	

}
public Action:armortest(client,args){
	if(IsDeveloper(client)){
		for(new i=1;i<=MaxClients;i++){
			new String:arg[10];
			GetCmdArg(1,arg,10);
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
	if(IsDeveloper(client)){
		for(new raceid=1;raceid<=GetRacesLoaded();raceid++){
			for( new skillnum;skillnum<MAXSKILLCOUNT;skillnum++)
				War3_CooldownMGR(client,0.0,raceid,skillnum,_,_,false);
		}
	}
}
public Action:MenuTest(client,args){
	new Handle:hMenu=CreateMenu(War3_playertargetMenuSelected);
	SetMenuExitButton(hMenu,true);
	
	new String:title[3000];
	for(new i=0;i<3000;i++){
	
		if(i%100==0)    
			Format(title,3000,"%s\n",title,i%10);
		else
			Format(title,3000,"%s%d",title,i%10);
		
	} 
	SetMenuTitle(hMenu,"0123456789");
	AddMenuItem(hMenu,"-1",title); //empty line
	DisplayMenu(hMenu,client,MENU_TIME_FOREVER);
}
public Action:FlashTest(client,args){
	if(args==6){
		new String:arg[32];
		GetCmdArg(1,arg,31);
		new r=StringToInt(arg);
		GetCmdArg(2,arg,31);
		new g=StringToInt(arg);
		GetCmdArg(3,arg,31);
		new b=StringToInt(arg);
		GetCmdArg(4,arg,31);
		new a=StringToInt(arg);
		GetCmdArg(5,arg,31);
		new Float:duration=StringToFloat(arg);
		
		GetCmdArg(6,arg,31);
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
	if(IsDeveloper(client)){
		ReplyToCommand(client,"is ubered? %s",War3_IsUbered(client)?"true":"false");
		if(args==2){
			new String:buf[10];
			GetCmdArg(1,buf,9);
			new n1=StringToInt(buf);
			GetCmdArg(2,buf,9);
			new n2=StringToInt(buf);
			War3_SetXP(client,n1,n2);
		}
		if(args==1){
			new String:buf[10];
			GetCmdArg(1,buf,9);
			new n1=StringToInt(buf);
			
			if(!War3_GetOwnsItem(client,n1)){
				War3_SetOwnsItem(client,n1,1);
				
				Call_StartForward(g_OnItemPurchaseHandle); //IN WAR3SOURCE_SHOPITEMS
				Call_PushCell(client);
				Call_PushCell(n1);
				new result;
				Call_Finish(result);
			}
			else{
				ReplyToCommand(client,"Already haz item %d",n1);
				
			}
		}
	}
}



public Action:FullSkilltest(client,args){
	new race=GetClientRace(client);
	for(new i;i<GetRaceSkillCount(race);i++){
		SetSkillLevel(client,race,i,4);
	}
}











public OnMapStart()
{
	
	DoWar3InterfaceExecForward();
	
	LoadRacesAndItems();
	
	CreateTimer(5.0, CheckCvars, 0);

	
	DelayedWar3SourceCfgExecute();//
	
	War3_PrecacheSound(levelupSound);
	
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
		Format(gameDesc,64,"War3Source %s",VERSION_NUM);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnAllPluginsLoaded() //called once only, will not call again when map changes
{
	PrintToServer("OnAllPluginsLoaded");

	
	if(DBIDB)
		War3Source_SQLTable();
	
	
	
	War3Source_UpdateStats(); // prepare war3top at beginning
	
	
	
	//new Handle:hpdecaycvar=FindConVar("tf_boost_drain_time");
	//if(hpdecaycvar!=INVALID_HANDLE){
	//	SetConVarInt(hpdecaycvar,20);
	//}
	
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




public OnPluginEnd() //public OnMapEnd()
{
	PrintToServer("[War3Source] OnPluginEnd Plugin shutdown finished.\n-------------------------------------------------------------------------");
}

new bool:onceTime;

public Action:DoAutosave(Handle:timer,any:data)
{
	if(SAVE_ENABLED)
	{
		for(new x=1;x<=MaxClients;x++)
		{
			if(ValidPlayer(x)&& bXPLoaded[x])
			{
				War3Source_SavePlayerData(x);
			}
		}
		if(GetConVarInt(hCvarPrintOnSave)>0){
			War3_ChatMessage(0,"Saving all player XP and updating stats.");
		}
		
		War3Source_UpdateStats(); // technically this only sets booleans and gathers top100 stuff
	}
	CreateTimer(GetConVarFloat(m_AutosaveTime),DoAutosave);
}

public OnConfigsExecuted()
{
	if(!onceTime)
	{
		CreateTimer(GetConVarFloat(m_AutosaveTime),DoAutosave);
		onceTime=true;
	}
}












public OnClientPutInServer(client)
{
	
	if(client>0)
	{ 
		bXPLoaded[client]=false;
		bRankCached[client]=false;
		
		ClearPlayerVariables(client); 
		
		
		
		Call_StartForward(g_OnWar3PlayerAuthedHandle);
		Call_PushCell(client);
		
		
		new res;
		Call_Finish(res);
		m_OffsetGravity[client]=FindDataMapOffs(client,"m_flGravity");
		if(SAVE_ENABLED)
		{
			War3_ChatMessage(client,"Loading player data...");
			War3Source_LoadPlayerData(client);
		}
		else{
			DoForwardOnWar3PlayerAuthed(client);
		}
		if(!(SAVE_ENABLED) || DBIDB==INVALID_HANDLE)
			bXPLoaded[client]=true; // kinda hacky, if db failed then ....
		m_FirstSpawn[client]=true;
	}
	else
	SetFailState("[War3Source] There was a failure on processing client, halting.");
	
	
}
public ClearPlayerVariables(client){
	

	//rset race skills and xp
	
	p_currentRace[client]=0; //0
	p_pendingRace[client]=0; //0
	p_gold[client]=0;
	
	for(new i=0;i<MAXRACES;i++)
	{
		p_xp[client][i]=0;
		p_racelevel[client][i]=0;
		for(new x=0;x<MAXSKILLCOUNT;x++){
			p_skilllevel[client][i][x]=0;
		}
	}
	for(new i=0;i<MAXITEMS;i++){
		ClientLostItem(client,i);
	}
	
	pLevelBank[client]=0;
	
	bXPLoaded[client]=false;
	RaceChosenTime[client]=0.0;
	RaceSetByAdmin[client]=false;
}

public OnClientDisconnect(client)
{
	
	if(SAVE_ENABLED && bXPLoaded[client])
		War3Source_SavePlayerData(client);
	
	
	ClearPlayerVariables(client);
	
	
	m_FirstSpawn[client]=true;
}


public OnGameFrame()
{
	War3Source_TrackGameFrame();
}
/*
FillHealth(entity){
	switch(TF2_GetPlayerClass(entity)){
		case TFClass_Heavy:		
		SetEntityHealth(entity, 300);
		case TFClass_Sniper:
		SetEntityHealth(entity, 125);
		case TFClass_Pyro:
		SetEntityHealth(entity, 175);
		case TFClass_Scout:
		SetEntityHealth(entity, 125);
		case TFClass_Soldier:
		SetEntityHealth(entity, 200);	
		case TFClass_Engineer:
		SetEntityHealth(entity, 125);	
		case TFClass_DemoMan:
		SetEntityHealth(entity, 175);	
		case TFClass_Spy:
		SetEntityHealth(entity, 125);
		case TFClass_Medic:
		SetEntityHealth(entity, 150);
	}*/
//}//IsValidEntity(GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon")) && GetEntProp(GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon"), Prop_Send, "m_iItemDefinitionIndex") == WEP_HUNTSMA