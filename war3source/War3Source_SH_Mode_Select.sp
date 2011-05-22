

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"




public Plugin:myinfo= 
{
	name="War3Source SHSource switch",
	author="Ownz",
	description="War3Source SH Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};



public APLRes:AskPluginLoad2Custom(Handle:myself,bool:late,String:error[],err_max)
{
	GlobalOptionalNatives();
	for(new i=0;i<20;i++){
		PrintToServer("                                                  ");
	}
	PrintToServer("#       #######    #    ######  ### #     #  #####  ");
	PrintToServer("#       #     #   # #   #     #  #  ##    # #     # ");
	PrintToServer("#       #     #  #   #  #     #  #  # #   # #       ");
	PrintToServer("#       #     # #     # #     #  #  #  #  # #  #### ");
	PrintToServer("#       #     # ####### #     #  #  #   # # #     # ");
	PrintToServer("#       #     # #     # #     #  #  #    ## #     # ");
	PrintToServer("####### ####### #     # ######  ### #     #  #####  ");

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
	if(event==UNLOADPLUGINSBYMODE&&false){ ///NO LONGER USES THIS
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
