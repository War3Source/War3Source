

#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"

new m_OffsetActiveWeapon;
new m_OffsetNextPrimaryAttack;
new Handle:hSDKWeaponDrop;

new String:weaponsAllowed[MAXPLAYERS][MAXRACES][300];
new restrictionPriority[MAXPLAYERS][MAXRACES];
new highestPriority[MAXPLAYERS];
new bool:restrictionEnabled[MAXPLAYERS][MAXRACES]; ///if restriction has length, then this should be true (caching allows quick skipping)
new bool:hasAnyRestriction[MAXPLAYERS]; //if any of the races said client has restriction, this is true (caching allows quick skipping)



new g_iWeaponRateQueue[MAXPLAYERS][2]; //ent, client
new g_iWeaponRateQueueLength;

new bool:zdebug[66];

new timerskip;

public Plugin:myinfo= 
{
	name="War3Source Engine Weapons",
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
	CreateTimer(0.1,DeciSecondTimer,_,TIMER_REPEAT);
	
	m_OffsetActiveWeapon=FindSendPropOffs("CBasePlayer","m_hActiveWeapon");
	if(m_OffsetActiveWeapon==-1)
	{
		LogError("[War3Source] Error finding active weapon offset.");
	}
	m_OffsetNextPrimaryAttack= FindSendPropOffs("CBaseCombatWeapon","m_flNextPrimaryAttack");
	if(m_OffsetNextPrimaryAttack==-1)
	{
		LogError("[War3Source] Error finding active weapon offset.");
	}
	
	if(War3_GetGame()==CS){
		new Handle:hGameConf = LoadGameConfigFile("plugin.war3source");
		if(hGameConf == INVALID_HANDLE)
		{
			SetFailState("gamedata/plugin.war3source.txt load failed");
		}
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CSWeaponDrop");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		hSDKWeaponDrop = EndPrepSDKCall();
		if(hSDKWeaponDrop == INVALID_HANDLE){
			SetFailState("Unable to find WeaponDrop Signature");
		}

	
		HookEvent("weapon_fire",WeaponFireEvent, EventHookMode_Pre); //CS
	}
	RegConsoleCmd("weapontest",weapontest);
	
}

public Action:weapontest(client,args){
	zdebug[client]=true;
}




bool:InitNativesForwards()
{
	CreateNative("War3_WeaponRestrictTo",NWar3_WeaponRestrictTo);
	CreateNative("W3GetCurrentWeaponEnt",NW3GetCurrentWeaponEnt);
	CreateNative("W3DropWeapon",NW3DropWeapon);
	return true;
}

public NW3GetCurrentWeaponEnt(Handle:plugin,numParams){
	return GetCurrentWeaponEnt(GetNativeCell(1));
}
GetCurrentWeaponEnt(client){
	return GetEntDataEnt2(client,m_OffsetActiveWeapon);
}

public NW3DropWeapon(Handle:plugin,numParams)
{
	new client = GetNativeCell(1)
	new wpent = GetNativeCell(2);
	if (ValidPlayer(client,true) && IsValidEdict(wpent))
		SDKCall(hSDKWeaponDrop, client, wpent, false, false);
}


public NWar3_WeaponRestrictTo(Handle:plugin,numParams)
{
	
	new client=GetNativeCell(1);
	new raceid=GetNativeCell(2);
	new String:restrictedto[300];
	GetNativeString(3,restrictedto,sizeof(restrictedto));

	restrictionPriority[client][raceid]=GetNativeCell(4);
	//new String:pluginname[100];
	//GetPluginFilename(plugin, pluginname, 100);
	//PrintToServer("%s NEW RESTRICTION: %s",pluginname,restrictedto);
	//LogError("%s NEW RESTRICTION: %s",pluginname,restrictedto);
	//PrintIfDebug(client,"%s NEW RESTRICTION: %s",pluginname,restrictedto);
	strcopy(weaponsAllowed[client][raceid],200,restrictedto);
	CalculateWeaponRestCache(client);
}
CalculateWeaponRestCache(client){
	new num=0;
	new limit=War3_GetRacesLoaded();
	new highestpri=0;
	for(new raceid=0;raceid<=limit;raceid++){
		restrictionEnabled[client][raceid]=(strlen(weaponsAllowed[client][raceid])>0)?true:false;
		if(restrictionEnabled[client][raceid]){
		
		
			num++;
			if(restrictionPriority[client][raceid]>highestpri){
				highestpri=restrictionPriority[client][raceid];
			}
		}
	}
	hasAnyRestriction[client]=num>0?true:false;
	
	
	highestPriority[client]=highestpri;
	
	timerskip=0; //force next timer to check weapons
}







public OnClientPutInServer(client){
	//War3_WeaponRestrictTo(client,0,""); //REMOVE RESTICTIONS ON JOIN
	new limit=War3_GetRacesLoaded();
	for(new raceid=0;raceid<=limit;raceid++){
		restrictionEnabled[client][raceid]=false;
		//Format(weaponsAllowed[client][i],3,"");
		
	}
	CalculateWeaponRestCache(client);
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse); //weapon touch and equip only
}
public OnClientDisconnect(client){
	SDKUnhook(client,SDKHook_WeaponCanUse,OnWeaponCanUse); 
	zdebug[client]=false;
}




bool:CheckCanUseWeapon(client,weaponent){
	decl String:WeaponName[32];
	GetEdictClassname(weaponent, WeaponName, sizeof(WeaponName));
	
	if(StrContains(WeaponName,"c4")>-1){ //allow c4
		return true;
	}
	
	new limit=War3_GetRacesLoaded();
	for(new raceid=0;raceid<=limit;raceid++){
		if(restrictionEnabled[client][raceid]&&restrictionPriority[client][raceid]==highestPriority[client]){ //cached strlen is not zero
			if(StrContains(weaponsAllowed[client][raceid],WeaponName)<0){ //weapon name not found
				return false;
			}
		}
	}
	return true; //allow
}


public Action:OnWeaponCanUse(client, weaponent)
{
	if(hasAnyRestriction[client]){
		if(CheckCanUseWeapon(client,weaponent))
		{
     	 	return Plugin_Continue; //ALLOW
		}
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
public Action:DeciSecondTimer(Handle:h,any:a){
	timerskip--;
	if(timerskip<1){
		timerskip=10;
		for(new client=1;client<=MaxClients;client++){
			/*if(true){ //test
				new wpnent = GetCurrentWeaponEnt(client);
				if(FindSendPropOffs("CWeaponUSP","m_bSilencerOn")>0){
				
					SetEntData(wpnent,FindSendPropOffs("CWeaponUSP","m_bSilencerOn"),true,true);
					}
					
			}*/
		
			if(hasAnyRestriction[client]&&ValidPlayer(client,true)){
			
				new String:name[32];
				GetClientName(client,name,sizeof(name));
				//PrintToChatAll("ValidPlayer %d",client);
				
				new wpnent = GetCurrentWeaponEnt(client);
				//PrintIfDebug(client,"   weapon ent %d %d",client,wpnent);
				//new String:WeaponName[32];
				
				//if(IsValidEdict(wpnent)){
					
			//	}
	
				//PrintIfDebug(client,"    %s res: (%s) weapon: %s",name,weaponsAllowed[client],WeaponName);		
			//	if(strlen(weaponsAllowed[client])>0){
				if(wpnent>0&&IsValidEdict(wpnent)){
					
					
					if (CheckCanUseWeapon(client,wpnent)){
						//allow
					}
					else
					{
						//RemovePlayerItem(client,wpnent);
						
						//PrintIfDebug(client,"            drop");
						
						
						SDKCall(hSDKWeaponDrop, client, wpnent, false, false);
						AcceptEntityInput(wpnent, "Kill");
						//UTIL_Remove(wpnent);
						
					}
		
				}
				else{
					//PrintIfDebug(client,"no weapon");
					//PrintToChatAll("no weapon");
				}
			//	}
			}
		}
	}
}
stock PrintIfDebug(client,String:fmt[],any:...){
	if(zdebug[client]){
		
		
		decl String:str_out[1024];
		VFormat(str_out,sizeof(str_out),fmt,3);
		
		PrintToConsole(client,str_out);
	}
}

		

		
		
		
public WeaponFireEvent(Handle:event,const String:name[],bool:dontBroadcast)
{ 

    new client = GetClientOfUserId(GetEventInt(event,"userid"));
    
    ///PrintToServer("3");
	//SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", Float:{0.0,0.0,0.0});
    
    //if(!IsRace(client))
    //  return;
   // if( (g_fDuration[client] < GetEngineTime()) || ( g_fMulti[client] < 1.0 ) ) //g_fDuratioin is for "in the fast attack speed mode"
  //    return;
    new ent = GetCurrentWeaponEnt(client);
    if(ent != -1)
    {
        //fill the stack for next frame
        g_iWeaponRateQueue[g_iWeaponRateQueueLength][0] = ent;
        g_iWeaponRateQueue[g_iWeaponRateQueueLength++][1] = client;
    } 
}


public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
   // new client = GetClientOfUserId(GetEventInt(event,"userid"));
    //if(!IsRace(client))
    //  return;
   // if( (g_fDuration[client] < GetEngineTime()) || ( g_fMulti[client] < 1.0 ) ) //g_fDuratioin is for "in the fast attack speed mode"
  //    return;
    new ent = GetEntDataEnt2(client,m_OffsetActiveWeapon);
    if(ent != -1)
    {
        //fill the stack for next frame
        g_iWeaponRateQueue[g_iWeaponRateQueueLength][0] = ent;
        g_iWeaponRateQueue[g_iWeaponRateQueueLength][1] = client;
        g_iWeaponRateQueueLength++;
    } 
}

public OnGameFrame(){

	if(g_iWeaponRateQueueLength>0)       //see events
	{
		decl ent, client, Float:time;
		new Float:enginetime = GetGameTime();
		for(new i = 0; i < g_iWeaponRateQueueLength; i++) {
			ent = g_iWeaponRateQueue[i][0];
			if(IsValidEntity(ent)) {   //weapon ent is valid
				
				client = g_iWeaponRateQueue[i][1];
				new Float:multi = W3GetBuffStackedFloat(client,fAttackSpeed);
				if(multi!=1.0){        //do we need to change it?
					time = (GetEntDataFloat(ent,m_OffsetNextPrimaryAttack) - enginetime) / multi;
					SetEntDataFloat(ent,m_OffsetNextPrimaryAttack,time + enginetime,true);
				}
			}
		} 
		g_iWeaponRateQueueLength = 0; 
	}
}
		
		
		
	
	
	