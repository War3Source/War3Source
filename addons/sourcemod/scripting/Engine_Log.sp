

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


new Handle:hW3Log;
new Handle:hW3LogError;
new Handle:hW3LogNotError;
new Handle:hGlobalErrorFwd;
public Plugin:myinfo= 
{
	name="Engine Log Error",
	author="Ownz",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};

public APLRes:AskPluginLoad2Custom(Handle:myself,bool:late,String:error[],err_max)
{

	new String:path_log[1024];
	BuildPath(Path_SM,path_log,sizeof(path_log),"logs/war3sourcelog.txt");
	new Handle:hFile=OpenFile(path_log,"a+");
	if(hFile)
	{
		CloseHandle(hFile);
		DeleteFile(path_log);
		
	}

	hW3Log=OpenFile(path_log,"a+");
	
	BuildPath(Path_SM,path_log,sizeof(path_log),"logs/war3sourceerrorlog.txt");
	hW3LogError=OpenFile(path_log,"a+");
	
	
	
	
	BuildPath(Path_SM,path_log,sizeof(path_log),"logs/war3sourcenoterrorlog.txt");
	hFile=OpenFile(path_log,"a+");
	if(hFile)
	{
		CloseHandle(hFile);
		DeleteFile(path_log);
	}
	hW3LogNotError=OpenFile(path_log,"a+");
	
	return APLRes_Success;
}

public OnPluginStart()
{
}

public bool:InitNativesForwards()
{
	
	CreateNative("W3Log",NW3Log);
	CreateNative("W3LogError",NW3LogError);
	CreateNative("W3LogNotError",NW3LogNotError);

	CreateNative("CreateWar3GlobalError",NCreateWar3GlobalError);
	hGlobalErrorFwd=CreateGlobalForward("OnWar3GlobalError",ET_Ignore,Param_String);
	
	return true;
}


public NW3Log(Handle:plugin,numParams)//{const String:fmt[],any:...)
{
	
	decl String:outstr[1000];
	
	FormatNativeString(0, 
                          1, 
                          2, 
                          sizeof(outstr),
						  _,
						  outstr);
	decl String:date[32];
	FormatTime(date, sizeof(date), "%c");					  					  
	Format(outstr,sizeof(outstr),"%s %s",date,outstr);
	
	PrintToServer("%s",outstr);
	WriteFileLine(hW3Log,outstr);
	FlushFile(hW3Log);
}
public NW3LogError(Handle:plugin,numParams)//{const String:fmt[],any:...)
{
	
	decl String:outstr[1000];
	
	FormatNativeString(0, 
                          1, 
                          2, 
                          sizeof(outstr),
						  _,
						  outstr);
	decl String:date[32];
	FormatTime(date, sizeof(date), "%c");					  					  
	Format(outstr,sizeof(outstr),"%s %s",date,outstr);
	
	PrintToServer("%s",outstr);
	WriteFileLine(hW3LogError,outstr);
	FlushFile(hW3LogError);
}
public NW3LogNotError(Handle:plugin,numParams)//{const String:fmt[],any:...)
{
	
	decl String:outstr[1000];
	
	FormatNativeString(0, 
                          1, 
                          2, 
                          sizeof(outstr),
						  _,
						  outstr);
	decl String:date[32];
	FormatTime(date, sizeof(date), "%c");					  					  
	Format(outstr,sizeof(outstr),"%s %s",date,outstr);
	
	PrintToServer("%s",outstr);
	WriteFileLine(hW3LogNotError,outstr);
	FlushFile(hW3LogNotError);
}
public NCreateWar3GlobalError(Handle:plugin,numParams){
	decl String:outstr[1000];
	
	FormatNativeString(0, 
		      1, 
		      2, 
		      sizeof(outstr),
			_,
			outstr);
			
	Call_StartForward(hGlobalErrorFwd);
	Call_PushString(outstr);
	Call_Finish(dummy);

}