

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"





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
	if(!InitNativesForwards())
	{
		LogError("[War3Source] There was a failure in creating the native / forwards based functions, definately halting.");
		return APLRes_Failure;
	}

	LogMessage("[SH] READING shsourcemode.cfg trying to find 'shsource' in the file");
	new Handle:file=OpenFile("cfg/shsourcemode.cfg", "a+"); //creates new file if one not exists
	
	new String:buffer[256]
	while (ReadFileLine(file, buffer, sizeof(buffer)))
	{
		if(strncmp(buffer, "shsource",strlen( "shsource"), false)==0){
			SHMODE=true;
			LogMessage("[SH] SHSource MODE ENABLED");
			CloseHandle(file);
			break;
		}
   			
		if (IsEndOfFile(file)){
			LogMessage("[SH] 'shsource' not found in file");
			CloseHandle(file);
			break;
		}
	}
	LogMessage("[SH] FINISHED READING shsourcemode.cfg");

	return APLRes_Success;
}

public OnPluginStart()
{
	
}

bool:InitNativesForwards()
{
	CreateNative("SH",NSH);
	CreateNative("W3",NW3);
	return true;
}
public NSH(Handle:plugin,numParams)
{
	return SHMODE;
}
public NW3(Handle:plugin,numParams)
{
	return SHMODE==false;
}





