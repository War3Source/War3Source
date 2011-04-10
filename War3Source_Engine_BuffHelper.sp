 	
//Buff SET AND FORGET


///todo: sliding for speed

#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"

#define MAXBUFFHELPERS /// not the bStunned but how many buffs this helper system can track


enum BuffHelperObject{
	String:ExecuteString[1000],
	W3Buff:BuffModifier,
}


new W3Buff:BuffHelperSimpleModifier[MAXPLAYERSCUSTOM][MAXRACES];
new Float:BuffHelperSimpleRemoveTime[MAXPLAYERSCUSTOM][MAXRACES];

public Plugin:myinfo= 
{
	name="War3Source Engine Buff Tracker (Buff helper)",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};



public APLRes:AskPluginLoad2Custom(Handle:myself,bool:late,String:error[],err_max)
{
	GlobalOptionalNatives();
	if(!InitNativesForwards())
	{
		LogError("[War3Source] There was a failure in creating the native / forwards based functions, definately halting.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateTimer(0.1,DeciSecondTimer,_,TIMER_REPEAT);
}

bool:InitNativesForwards()
{
	//CreateNative("W3RegisterBuffHelper",NW3ApplyBuff);
	//CreateNative("W3SetBuffHelper",NW3ApplyBuff);
	CreateNative("W3ApplyBuffSimple",NW3ApplyBuffSimple);
	return true;
}

public NW3ApplyBuffSimple(Handle:plugin,numParams) {
	new client=GetNativeCell(1);
	new W3Buff:buffindex=GetNativeCell(2);
	new raceid=GetNativeCell(3);
	new any:initialValue=GetNativeCell(4);
	new Float:duration=GetNativeCell(5);
	
	War3_SetBuff(client,buffindex,raceid,initialValue);
	
	BuffHelperSimpleModifier[client][raceid]=buffindex;
	BuffHelperSimpleRemoveTime[client][raceid]=GetGameTime()+duration;
}

public Action:DeciSecondTimer(Handle:h){
	new Float:time=GetGameTime();
	new limit=War3_GetRacesLoaded();
	for(new client=1;client<=MaxClients;client++){
		
		for(new itemraceindex=0;itemraceindex<=limit;itemraceindex++){
		
			if(BuffHelperSimpleRemoveTime[client][itemraceindex]>1.0&&BuffHelperSimpleRemoveTime[client][itemraceindex]<time){
				W3ResetBuffRace(client,BuffHelperSimpleModifier[client][itemraceindex],itemraceindex);
			}
		}
	}
}

