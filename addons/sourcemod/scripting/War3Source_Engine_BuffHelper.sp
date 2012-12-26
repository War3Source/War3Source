 	
//Buff SET AND FORGET


///todo: sliding for speed

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/sdkhooks"
#include "W3SIncs/War3Source_Interface"

#define MAXBUFFHELPERS 99 /// not the bStunned but how many buffs this helper system can track

/*
enum BuffHelperObject{
	//String:ExecuteString[1000],
	Race,
	W3Buff:BuffIndex,
	ClientAppliedTo,
	Float:Expiration
}


new W3Buff:BuffHelperSimpleModifier[MAXPLAYERSCUSTOM][MAXRACES];
new Float:BuffHelperSimpleRemoveTime[MAXPLAYERSCUSTOM][MAXRACES];

#define MAXTRACKERS 400;
new trackers[MAXTRACKERS][BuffHelperObject];*/

//paralell arrays
//ZEROTH is not used and filled wiht -99
new Handle:objRace;
new Handle:objBuffIndex;
new Handle:objClientAppliedTo;
new Handle:objExpiration;


public Plugin:myinfo= 
{
	name="W3S Engine Buff Tracker (Buff helper)",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};



public OnPluginStart()
{
	CreateTimer(0.1,DeciSecondTimer,_,TIMER_REPEAT);
	objRace=CreateArray();
	objBuffIndex=CreateArray();
	objClientAppliedTo=CreateArray();
	objExpiration=CreateArray();
	PushArrayCell(objRace, -99); 
	PushArrayCell(objBuffIndex, -99); 
	PushArrayCell(objClientAppliedTo, -99); 
	PushArrayCell(objExpiration, -99); 
	
}
//note, accepts duration, not expiration
stock SetObject(index,race,buffindex,client,Float:duration){
	SetArrayCell(objRace,index, race); 
	SetArrayCell(objBuffIndex,index, _:buffindex); 
	SetArrayCell(objClientAppliedTo,index, client); 
	SetArrayCell(objExpiration,index, AbsoluteTime()+duration); 
}
GetObject(&index,&race,&buffindex,&client,&Float:expiration){
	race=GetArrayCell(objRace,index); 
	buffindex=GetArrayCell(objBuffIndex,index); 
	client=GetArrayCell(objClientAppliedTo,index ); 
	expiration=GetArrayCell(objExpiration,index ); 
}

// use  1 -- < len
ObjectLen(){
return GetArraySize(objRace);
}
RemoveObject(index){
	RemoveFromArray(objRace, index); 
	RemoveFromArray(objBuffIndex, index); 
	RemoveFromArray(objClientAppliedTo, index); 
	RemoveFromArray(objExpiration, index); 
}


public bool:InitNativesForwards()
{
	//CreateNative("W3RegisterBuffHelper",NW3ApplyBuff);
	//CreateNative("W3SetBuffHelper",NW3ApplyBuff);
	CreateNative("W3ApplyBuffSimple",NW3ApplyBuffSimple);
	return true;
}

public NW3ApplyBuffSimple(Handle:plugin,numParams) {
	new client=GetNativeCell(1);
	new buffindex=GetNativeCell(2);
	new race=GetNativeCell(3);
	new any:initialValue=GetNativeCell(4);
	new Float:duration=GetNativeCell(5);
	new bool:allowoverwrite=GetNativeCell(6);
	
	if(!ValidPlayer(client)){
		ThrowError("INVALID CLIENT");
	}
	if(! ValidBuff(W3Buff:buffindex)){
		ThrowError("INVALID BUFF");
	}
	if(!ValidRace(race)){
		ThrowError("INVALID RACE");
	}
	new index=FindExisting(race,buffindex,client);
	//something exists
	if(allowoverwrite==false && index>0){
		return;
	}
//	DP("set client %d",client);
	War3_SetBuff(client,W3Buff:buffindex,race,initialValue);
	
	
	if(index>0){ //replace
		SetObject(index,race,buffindex,client,Float:duration);
		
	}
	else{ //add to end
		AddToTracker(race,buffindex,client,Float:duration);
	}
//	BuffHelperSimpleModifier[client][raceid]=buffindex;
//	BuffHelperSimpleRemoveTime[client][raceid]=GetGameTime()+duration;
}
FindExisting(race,buffindex,client){
	new len=ObjectLen();
	for(new i=0;i<len;i++){
		if(
		GetArrayCell(objRace,i)==race&&
		GetArrayCell(objBuffIndex,i)==_:buffindex&&
		GetArrayCell(objClientAppliedTo,i)==client
		){
		return i;
		}
	}
	return 0;
}
AddToTracker(race,buffindex,client,Float:duration){
	PushArrayCell(objRace, race); 
	PushArrayCell(objBuffIndex, _:buffindex); 
	PushArrayCell(objClientAppliedTo, client); 
	PushArrayCell(objExpiration, AbsoluteTime()+duration); 
}
public Action:DeciSecondTimer(Handle:h){
	new Float:now=AbsoluteTime();
	new limit=ObjectLen();
	new race,buffindex,client,Float:expiration;
	for(new index=1;index<limit;index++){
		GetObject(index,race,buffindex,client,Float:expiration);
		if(now>expiration){
		//	DP("expire client %d",client);
			W3ResetBuffRace(client,W3Buff:buffindex,race);
			RemoveObject(index);
			limit=ObjectLen();
			index--; 
		}
	}
}

