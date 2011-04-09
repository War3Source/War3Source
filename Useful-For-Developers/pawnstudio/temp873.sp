

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"



////new player variables
//RESET THESE IN ClearPlayerVariables (War3Source.sp)


new p_xp[MAXPLAYERS][MAXRACES];
new p_level[MAXPLAYERS][MAXRACES];
new p_skilllevel[MAXPLAYERS][MAXRACES][MAXSKILLCOUNT];

new p_properties[MAXPLAYERS][W3PlayerProp];


new Handle:g_OnRaceSelectedHandle;
new Handle:g_OnSkillLevelChangedHandle;

public Plugin:myinfo= 
{
	name="War3source Engine player class",
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
}

bool:InitNativesForwards()
{
	g_OnRaceSelectedHandle=CreateGlobalForward("OnRaceSelected",ET_Ignore,Param_Cell);
	g_OnSkillLevelChangedHandle=CreateGlobalForward("OnSkillLevelChanged",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell);



	CreateNative("War3_SetRace",NWar3_SetRace); //these have forwards to handle
	CreateNative("War3_GetRace",NWar3_GetRace); 
	
	CreateNative("War3_SetLevel",NWar3_SetLevel); //these have forwards to handle
	CreateNative("War3_GetLevel",NWar3_GetLevel); 
	
	CreateNative("War3_SetXP",NWar3_SetXP); //these have forwards to handle
	CreateNative("War3_GetXP",NWar3_GetXP); 
	
	CreateNative("War3_SetSkillLevel",NWar3_SetSkillLevel); //these have forwards to handle
	CreateNative("War3_GetSkillLevel",NWar3_GetSkillLevel); 
	
	
	CreateNative("W3SetProp",NW3GetProp);
	CreateNative("W3GetProp",NW3SetProp);
	
	CreateNative("W3ClearPlayerVariables",NW3ClearPlayerVariables);
	return true;
}
public NWar3_SetRace(Handle:plugin,numParams){
	p_properties[GetNativeCell(1)][CurrentRace]=GetNativeCell(2);
}
public NWar3_GetRace(Handle:plugin,numParams){
	return p_properties[GetNativeCell(1)][CurrentRace];
}

public NWar3_SetLevel(Handle:plugin,numParams){
	p_level[GetNativeCell(1)][GetNativeCell(2)]=GetNativeCell(3);
}
public NWar3_GetLevel(Handle:plugin,numParams){
	return p_level[GetNativeCell(1)][GetNativeCell(2)];
}


public NWar3_SetXP(Handle:plugin,numParams){
	p_xp[GetNativeCell(1)][GetNativeCell(2)]=GetNativeCell(3);
}
public NWar3_GetXP(Handle:plugin,numParams){
	return p_xp[GetNativeCell(1)][GetNativeCell(2)];
}
public NWar3_SetSkillLevel(Handle:plugin,numParams){
	new client=GetNativeCell(1);
	new race=GetNativeCell(2);
	new skill=GetNativeCell(3);
	new level=GetNativeCell(4);
	p_skilllevel[client][race][skill]=level;
	Call_StartForward(g_OnSkillLevelChangedHandle);
	Call_PushCell(client);
	Call_PushCell(race);
	Call_PushCell(skill);
	Call_PushCell(level);
	Call_Finish(dummyresult);
	
}
public NWar3_GetSkillLevel(Handle:plugin,numParams){
	return p_skilllevel[GetNativeCell(1)][GetNativeCell(2)][GetNativeCell(3)];
}
public NW3GetProp(Handle:plugin,numParams){
	return p_properties[GetNativeCell(1)][GetNativeCell(2)];
}
public NW3SetProp(Handle:plugin,numParams){
	p_properties[GetNativeCell(1)][GetNativeCell(2)]=GetNativeCell(3);
}
