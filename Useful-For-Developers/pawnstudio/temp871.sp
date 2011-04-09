//Cooldown manager
//keeps track of all cooldowns

//Delay Tracker:
//setting an object's state to false for X seconds, manually retrieve the state




#include <sourcemod>
#include "W3SIncs/War3Source_Interface"




///cooldown class [2] is [0] SKILL [1] ULTIMATE
new Float:CooldownExpireTime[66][MAXRACES][MAXSKILLCOUNT]; //[CLIENT][RACE][SKILL OR ULT][SKILL NUM]
new bool:CooldownExpireOnSpawn[66][MAXRACES][MAXSKILLCOUNT];
new bool:CooldownExpireOnDeath[66][MAXRACES][MAXSKILLCOUNT];
new bool:CooldownPrintMsgExpireByTime[66][MAXRACES][MAXSKILLCOUNT];

new String:CooldownPrintMsgSkillName[66][MAXRACES][MAXSKILLCOUNT][32]; //exceeded max amount of dementiosn
















#define MAXTHREADS 2000
new Float:expireTime[MAXTHREADS];
new threadsLoaded;


public Plugin:myinfo= 
{
	name="War3Source Engine 1",
	author="Ownz",
	description="Core utilities for War3Source.",
	version="1.0",
	url="http://war3source.com/"
};



public APLRes:AskPluginLoad2(Handle:myself,bool:late,String:error[],err_max)
{
	if(!InitNatives())
	{
		LogError("[War3Source] There was a failure in creating the native based functions, definately halting.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateTimer(0.1,TimerTick,_,TIMER_REPEAT);
}
public OnMapStart(){
	for(new i=0;i<threadsLoaded;i++){
		expireTime[i]=0.0;
	}
}

public bool:InitNatives()
{
	///LIST ALL THESE NATIVES IN INTERFACE
	CreateNative("War3_CooldownMGR",Native_War3_CooldownMGR);
	CreateNative("War3_CooldownRemaining",Native_War3_CooldownRMN);
	CreateNative("War3_CooldownReset",Native_War3_CooldownReset);
	CreateNative("War3_SkillNotInCooldown",Native_War3_SkillNIC);
	CreateNative("War3_PrintSkillIsNotReady",Native_War3_PrintSkillINR);
	
	
	CreateNative("War3_RegisterDelayTracker",NWar3_RegisterDelayTracker);
	CreateNative("War3_TrackDelay",NWar3_TrackDelay);
	CreateNative("War3_TrackDelayExpired",NWar3_TrackDelayExpired);
	return true;
}


public NWar3_RegisterDelayTracker(Handle:plugin,numParams)
{
	if(threadsLoaded<MAXTHREADS){
		return threadsLoaded++;
	}
	LogError("[War3Source Engine 1] DELAY TRACKER MAXTHREADS LIMIT REACHED! return -1");
	return -1;
}
public NWar3_TrackDelay(Handle:plugin,numParams)
{
	new index=GetNativeCell(1);
	new Float:delay=GetNativeCell(2);
	expireTime[index]=GetGameTime()+delay;
}
public NWar3_TrackDelayExpired(Handle:plugin,numParams)
{
	return GetGameTime()>expireTime[GetNativeCell(1)];
}
	

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
public Native_War3_CooldownMGR(Handle:plugin,numParams)
{
	if(numParams>=4){
		new client = GetNativeCell(1);
		new Float:cooldownTime= GetNativeCell(2);
		new raceid = GetNativeCell(3);
		new skillNum = GetNativeCell(4); ///can use skill numbers
		new bool:resetOnSpawn=true;
		if(numParams>4){
			resetOnSpawn = GetNativeCell(5);
		}
		new bool:resetOnDeath=true;
		if(numParams>5){
			resetOnDeath = GetNativeCell(6);
		}
		new bool:printMsgOnExpireByTime=true;
		if(numParams>6){
			printMsgOnExpireByTime = GetNativeCell(7);
		}
		new String:skillNameStr[32];
		if(numParams>7){
			GetNativeString(8,skillNameStr,31);
		}
		
		//in playertracking 
		Internal_CreateCooldown(client,cooldownTime,raceid,skillNum,resetOnSpawn,resetOnDeath,printMsgOnExpireByTime,skillNameStr);
	}
}
public Native_War3_CooldownRMN(Handle:plugin,numParams) //cooldown remaining time
{
	if(numParams==3){
		new client = GetNativeCell(1);
		new raceid = GetNativeCell(2);
		new skillNum = GetNativeCell(3); ///can use skill numbers
		return RoundToCeil(CooldownExpireTime[client][raceid][skillNum]-GetGameTime());
	}
	return -1;
}
public Native_War3_CooldownReset(Handle:plugin,numParams)
{
	if(numParams==3){
		new client = GetNativeCell(1);
		new raceid = GetNativeCell(2);
		new skillNum = GetNativeCell(3); ///can use skill numbers
		CooldownExpired(client,raceid,skillNum,false);
	}
	return -1;
}
public Native_War3_SkillNIC(Handle:plugin,numParams) //NOT IN COOLDOWN , skill available
{
	if(numParams>=3){
		new client = GetNativeCell(1);
		new raceid = GetNativeCell(2);
		new skillNum = GetNativeCell(3); ///can use skill numbers
		new bool:printTextIfNotReady=false;
		if(numParams>3){
			printTextIfNotReady=GetNativeCell(4);
		}
		new bool:result= InternalIsSkillNotInCooldown(client,raceid,skillNum);
		if(result==false&&printTextIfNotReady){
			Internal_PrintSkillNotAvailable(client,raceid,skillNum);
		}
		return result;
	}
	return -1;
}
public Native_War3_PrintSkillINR(Handle:plugin,numParams)
{
	if(numParams==3){
		new client = GetNativeCell(1);
		new raceid = GetNativeCell(2);
		new skillNum = GetNativeCell(3); ///can use skill numbers
		Internal_PrintSkillNotAvailable(client,raceid,skillNum); //cooldown inc
	}
	return -1;
}
	
	
	
	
public ClearAllCooldown()
{
	for(new i=1;i<=MaxClients;i++)
	{
		for(new raceid=0;raceid< MAXRACES;raceid++)
		{
			for(new skillNum=0;skillNum<MAXSKILLCOUNT;skillNum++)
			{
				CooldownExpireTime[i][raceid][skillNum]=0.0;
			}
		}
	}
}


public Internal_CreateCooldown(client,Float:cooldownTime,raceid,skillNum,bool:resetOnSpawn,bool:resetOnDeath,bool:printMsgOnExpireByTime,String:skillNameStr[]){
	CooldownExpireTime[client][raceid][skillNum]=GetGameTime()+cooldownTime;

	CooldownExpireOnSpawn[client][raceid][skillNum]=resetOnSpawn;
	CooldownExpireOnDeath[client][raceid][skillNum]=resetOnDeath;
	CooldownPrintMsgExpireByTime[client][raceid][skillNum]=printMsgOnExpireByTime;
	Format(CooldownPrintMsgSkillName[client][raceid][skillNum],31,"%s",skillNameStr);
	
}
public Action:TimerTick(Handle:h,any:data){

	new Float:currenttime=GetGameTime();
	for(new i=1;i<=MaxClients;i++){
		if(War3_ValidPlayer(i)){
			new racesLoaded= War3_GetRacesLoaded();
			for(new raceid=1;raceid<=racesLoaded;raceid++){
				for(new skillultindex=0;skillultindex<War3_GetRaceSkillCount(raceid);skillultindex++){
					if(CooldownExpireTime[i][raceid][skillultindex]>1.0&&CooldownExpireTime[i][raceid][skillultindex]<currenttime){
						 CooldownExpired(i,raceid,skillultindex,true); //clears some vars
						 
					}
				}
			}
		}
	}
}
public CooldownExpired(client,raceid,skillNum,bool:expiredByTimer)
{
	CooldownExpireTime[client][raceid][skillNum]=0.0;
	//other variables do not need to be cleared cuz they will not trigger with first variable set
	//other variables will be assigned when new cooldown is made

	if(expiredByTimer){
		if(War3_ValidPlayer(client,true)&&CooldownPrintMsgExpireByTime[client][raceid][skillNum]&&War3_GetRace(client)==raceid){ //if still the same race and alive
			PrintHintText(client,"%s Is Ready",strlen(CooldownPrintMsgSkillName[client][raceid][skillNum])>0?CooldownPrintMsgSkillName[client][raceid][skillNum]:War3_War3_IsSkillUltimate(raceid,skillNum)?"Ultimate":"Ability");
			EmitSoundToAll( War3_IsSkillUltimate(raceid,skillNum)?ultimateReadySound:abilityReadySound , client,_,SNDLEVEL_TRAIN);
		}
	}

	Call_StartForward(g_CooldownExpiredForwardHandle);
	Call_PushCell(client);
	Call_PushCell(raceid);
	Call_PushCell(skillNum);
	Call_PushCell(expiredByTimer);
	new result;
	Call_Finish(result); //this will be returned to ?
}
public bool:InternalIsSkillNotInCooldown(client,raceid,skillNum){
	return (   CooldownExpireTime[client][raceid][skillNum]<GetGameTime()  );
}

public Internal_PrintSkillNotAvailable(client,raceid,skillNum){
	if(War3_ValidPlayer(client)){
		
		PrintHintText(client,"%s Is Not Ready. %d Seconds Remaining.",strlen(CooldownPrintMsgSkillName[client][raceid][skillNum])>0?CooldownPrintMsgSkillName[client][raceid][skillNum]:War3_IsSkillUltimate(raceid,skillNum)?"Ultimate":"Ability",War3_CooldownRemaining(client,raceid,skillNum));
		
		
	}
}

