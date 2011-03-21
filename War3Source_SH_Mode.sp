

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/war3ext"



new tValveGame;
new bool:SHMODE=false;

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


	if(!InitNativesForwards())
	{
		LogError("[War3Source] There was a failure in creating the native / forwards based functions, definately halting.");
		return APLRes_Failure;
	}

	//DETERMIE GAME MODE
	PrintToServer("[SH] READING shsourcemode.cfg trying to find 'shsource' in the file");
	new Handle:file=OpenFile("cfg/shsourcemode.cfg", "a+"); //creates new file if one not exists
	
	new String:buffer[256]
	while (ReadFileLine(file, buffer, sizeof(buffer)))
	{
		if(strncmp(buffer, "shsource",strlen( "shsource"), false)==0){
			SHMODE=true;
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
	
	


	//all plugins shoudl have been loaded, but not really initialized
	//we manually force every plugin to create their natives and forwards
	//no natives have been "bound" at this point, aka they cannot call "W3", but they can call W3Early which forces a function call
	PrintToServer("[War3Source] Initalizing Natives and Forwards");
	new Handle:iter=GetPluginIterator();
	while(MorePlugins(iter)){
		
		new String:buf[64];
		new Handle:plugin=ReadPlugin(iter);
		GetPluginFilename(plugin,buf, 64);
		
		
		
		new Function:func=GetFunctionByName(plugin, "W3SetForwarededVar");
		if(func!=INVALID_FUNCTION){
			Call_StartFunction(plugin, func);
			Call_PushCell(ValveGame);
			Call_PushCell(tValveGame);
			Call_Finish(dummy);
			
			Call_StartFunction(plugin, func);
			Call_PushCell(W3Mode);
			Call_PushCell(SHMODE==false);
			Call_Finish(dummy);
			
			Call_StartFunction(plugin, func);
			Call_PushCell(SHMode);
			Call_PushCell(SHMODE==true);
			Call_Finish(dummy);
		}
		else{
			//LogError("Plugin %s does not have required function, interface compatability?",buf);
		}
		//PrintToServer("%s",buf);
		func=GetFunctionByName(plugin, "InitNativesForwards");
		if(func!=INVALID_FUNCTION){
			Call_StartFunction(plugin, func);
			Call_Finish(dummy);
			if(dummy<1){
				LogError("InitNativesForwards of %s did not return > 0, maybe something went wrong",buf);
			}
		}
		else{		}
	}
	PrintToServer("[War3Source] End");
	return APLRes_Success;
}

public OnPluginStart()
{
	new String:buf[32];
	PrintToServer("%f",OurTestNative(3.0,"OnPluginStart",3,buf,sizeof(buf)));
	PrintToServer("%s",buf);
}

bool:InitNativesForwards()
{
	
	return true;
}






