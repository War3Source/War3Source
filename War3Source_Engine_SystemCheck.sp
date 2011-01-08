#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"


#define COREPLUGINSNUM 8
new String:coreplugins[COREPLUGINSNUM][]={
"War3Source.smx",
"War3Source_Engine_CooldownMgr",
"War3Source_Engine_PlayerTrace",
"War3Source_Engine_PlayerCollision",
"War3Source_Engine_Weapon",
"War3Source_Engine_Buff",
"War3Source_Engine_DamageSystem",
"War3Source_Engine_SystemCheck"
};


new Handle:g_War3FailedFH;


public Plugin:myinfo= 
{
	name="War3Source Engine System Check",
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
	CreateTimer(2.0,TwoSecondTimer,_,TIMER_REPEAT);
}


bool:InitNativesForwards()
{
	g_War3FailedFH=CreateGlobalForward("War3FailedSignal",ET_Ignore,Param_String);

	CreateNative("War3Failed",Native_War3Failed);
	return true;
}
public Native_War3Failed(Handle:plugin,numParams)
{
	new String:str[2000];
	GetNativeString(1,str,2000);
	DoFwd_War3Failed(str);
}

DoFwd_War3Failed(String:str[]){
	Call_StartForward(g_War3FailedFH);
	Call_PushString(str);
	new dummyret;
	Call_Finish(dummyret);
}

public Action:TwoSecondTimer(Handle:h,any:a){

	for(new i=0;i<COREPLUGINSNUM;i++){
		new Handle:plug=FindPluginByFileCustom(coreplugins[i]);
		if(plug==INVALID_HANDLE){
			LogError("Could not find plugin (handle): %s",coreplugins[i]);
		}
		else{
			new PluginStatus:stat=GetPluginStatus(plug);
			if(stat!=Plugin_Running&&stat!=Plugin_Loaded){
				new String:reason[3000];
				Format(reason,sizeof(reason),"%s failed",coreplugins[i]);
				War3Failed(reason);
			}
		}	
	}
}


stock Handle:FindPluginByFileCustom(const String:filename[])
{
	decl String:buffer[256];
	
	new Handle:iter = GetPluginIterator();
	new Handle:pl;
	
	while (MorePlugins(iter))
	{
		pl = ReadPlugin(iter);
		
		GetPluginFilename(pl, buffer, sizeof(buffer));
		if (StrContains(buffer,filename)>-1)
		{
			CloseHandle(iter);
			return pl;
		}
	}
	
	CloseHandle(iter);
	
	return INVALID_HANDLE;
}

