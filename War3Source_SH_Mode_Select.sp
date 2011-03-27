

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"



new tValveGame;

new bool:bGameModeDetermined;

new bool:bWar3Mode;
new bool:bSHMode;

public Plugin:myinfo= 
{
	name="War3Source SHSource switch",
	author="Ownz",
	description="War3Source SH Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};



public APLRes:AskPluginLoad2(Handle:myself,bool:late,String:error[],err_max)
{

	PrintToServer("#       #######    #    ######  ### #     #  #####  ");
	PrintToServer("#       #     #   # #   #     #  #  ##    # #     # ");
	PrintToServer("#       #     #  #   #  #     #  #  # #   # #       ");
	PrintToServer("#       #     # #     # #     #  #  #  #  # #  #### ");
	PrintToServer("#       #     # ####### #     #  #  #   # # #     # ");
	PrintToServer("#       #     # #     # #     #  #  #    ## #     # ");
	PrintToServer("####### ####### #     # ######  ### #     #  #####  ");


	
	if(!bGameModeDetermined){
		DetermineGameMode();
	}
	


	
	new i=0;
	new Handle:iter=GetPluginIterator();
	while(MorePlugins(iter)){
		i++;
		//new String:buf[64];
		new Handle:plugin=ReadPlugin(iter);
		//GetPluginFilename(plugin,buf, 64);
		new Function:func;
		
	
		
		func=GetFunctionByName(plugin, "W3SetForwarededVar");
		if(func!=INVALID_FUNCTION){ //non war3 plugins dont have this function
			Call_StartFunction(plugin, func);
			Call_PushCell(ValveGame);
			Call_PushCell(tValveGame);
			Call_Finish(dummy);
			
			Call_StartFunction(plugin, func);
			Call_PushCell(W3Mode);
			Call_PushCell(bWar3Mode);
			Call_Finish(dummy);
			
			Call_StartFunction(plugin, func);
			Call_PushCell(SHMode);
			Call_PushCell(bSHMode);
			Call_Finish(dummy);
		}
		func=GetFunctionByName(plugin, "GlobalOptionalNatives");
		if(func!=INVALID_FUNCTION){ //non war3 plugins dont have this function
			Call_StartFunction(plugin, func);
			Call_Finish(dummy);
		}
		
		
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	PrintToServer("OnPluginStart");
	RegServerCmd("war3mode",cmdwar3mode);  
	RegServerCmd("w3mode",cmdwar3mode);
	RegServerCmd("shmode",cmdshmode);
	RegServerCmd("whichmode",cmdwhichmode);
	
}
public Action:cmdwar3mode(args)
{
	new Handle:file=OpenFile("cfg/shsourcemode.cfg", "w"); //overwrite
	WriteFileLine(file, "//shsource");
	WriteFileLine(file, "//uncomment above line to enable sh mode");
	CloseHandle(file);
	PrintToServer("War3 mode configured. Please do a full restart")
	return Plugin_Handled;
}
public Action:cmdshmode(args){
	new Handle:file=OpenFile("cfg/shsourcemode.cfg", "w"); //overwrite
	WriteFileLine(file, "shsource");
	WriteFileLine(file, "//comment above line to disable sh mode");
	CloseHandle(file);
	PrintToServer("SH mode configured. Please do a full restart")
	return Plugin_Handled;
}
public Action:cmdwhichmode(args){
	PrintToServer("W3? %d",bWar3Mode);
	PrintToServer("SH? %d",bSHMode);
	
}

public OnWar3Event(W3EVENT:event,client){
	if(event==UNLOADPLUGINSBYMODE){
		new i=0;
		new Handle:iter=GetPluginIterator();
		while(MorePlugins(iter)){
			i++;
			new String:buf[64];
			new Handle:plugin=ReadPlugin(iter);
			GetPluginFilename(plugin,buf, 64);
			
			
			//UNLOAD plugins
			new String:bufff[99];
			if(!bWar3Mode){
				Format(bufff,sizeof(bufff),"Only active in W3 mode");
			}
			else if(!bSHMode){
				Format(bufff,sizeof(bufff),"Not active in SH mode");
			}
			new String:lookforfunc[32];
			Format(lookforfunc,sizeof(lookforfunc),"UNLOADME");
			if(!bWar3Mode){
				Format(lookforfunc,sizeof(lookforfunc),"W3ONLY");
			}
			if(!bSHMode){
				Format(lookforfunc,sizeof(lookforfunc),"SHONLY");
			}
			new Function:func=GetFunctionByName(plugin,lookforfunc );
			
			if(func!=INVALID_FUNCTION){
				
				ServerCommand("sm plugins unload %d",i);
				i--;
			}
		}
	}	
}


public W3EarlyPublic(){
	if(!bGameModeDetermined){
		DetermineGameMode();
	}
	return bWar3Mode;
}
public SHEarlyPublic(){
	if(!bGameModeDetermined){
		DetermineGameMode();
	}
	return bSHMode;
}
public ValveGameEnum:War3_GetGameEarlyPublic(){
	if(!bGameModeDetermined){
		DetermineGameMode();
	}
	return ValveGameEnum:tValveGame;
}
DetermineGameMode(){
	//DETERMIE GAME MODE
	PrintToServer("[SH] READING shsourcemode.cfg trying to find 'shsource' in the file");
	new Handle:file=OpenFile("cfg/shsourcemode.cfg", "a+"); //creates new file if one not exists
	
	bWar3Mode=true; //default
	bSHMode=false; //default
	new String:buffer[256]
	while (ReadFileLine(file, buffer, sizeof(buffer)))
	{
		if(strncmp(buffer, "shsource",strlen( "shsource"), false)==0){
			bWar3Mode=false;
			bSHMode=true;

			PrintToServer("[SH] SHSource MODE ENABLED");
			break;
		}
	}
	CloseHandle(file);
	PrintToServer("[SH] FINISHED READING shsourcemode.cfg");
	
	
	


	//DETERMINE GAME TYPE: CS TF ETC
	new String:gameDir[64];
	GetGameFolderName(gameDir,sizeof(gameDir));
	if(StrContains(gameDir,"cstrike",false)==0)
	{
		tValveGame=_:Game_CS;
		PrintToServer("[War3Source] Game set: Counter-Strike Source ValveGame %d",tValveGame);
		ServerCommand("sv_allowminmodels 0");
	}
	else if(StrContains(gameDir,"dod",false)==0)
	{
		PrintToServer("[War3Source] Game set: Day of Defeat Source (ONLY DEVELOPER SUPPORT!)");
		tValveGame=_:Game_DOD;
	}
	else if(StrContains(gameDir,"tf",false)==0)
	{
		PrintToServer("[War3Source] Game set: Team Fortress 2");
		tValveGame=_:Game_TF;
	}
	else
	{
		SetFailState("[War3Source] Sorry, this game isn't support by War3Source yet. If you think this is a mistake, you probably renamed your game directory. For example, re-naming cstrike to cstrike2 will cause this error.");
	}
	
}
