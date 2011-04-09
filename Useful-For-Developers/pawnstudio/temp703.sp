

#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"

new m_OffsetActiveWeapon;

new String:weaponsAllowed[MAXPLAYERS][300];
public Plugin:myinfo= 
{
	name="War3Source Engine 4",
	author="Ownz",
	description="Core utilities for War3Source.",
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
	CreateTimer(1.0,SecondTimer,_,TIMER_REPEAT);
	
	m_OffsetActiveWeapon=FindSendPropOffs("CBasePlayer","m_hActiveWeapon");
	if(m_OffsetActiveWeapon==-1)
	{
		LogError("[War3Source] Error finding active weapon offset.");

	}
}

public bool:InitNativesForwards()
{
	CreateNative("War3_WeaponRestrict",NWar3_WeaponRestrict);
	return true;
}

public NWar3_WeaponRestrict(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	GetNativeArray(2,weaponsAllowed[client],300);
}

public OnClientPutInServer(client){
	Format(weaponsAllowed[client],300,""); //REMOVE RESTICTIONS ON JOIN
	
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse); //weapon touch and equip only
}
public OnClientDisconnect(client){
	SDKUnhook(client,SDKHook_WeaponCanUse,OnWeaponCanUse); 
}


public Action:OnWeaponCanUse(client, weaponent)
{
	if(strlen(weaponsAllowed[client])>0){
		new String:weaponname[64];
		GetEdictClassname(weaponent, weaponname, 64);
		
		//PrintToChatAll("weapon: %s",name);
		//if(StrEqual(name, "weapon_knife", false))
		if (StrContains(weaponsAllowed[client],weaponname)){
     	 	return Plugin_Continue;
		}
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
public Action:SecondTimer(Handle:h,any:a){
	for(new client=1;client<=MaxClients;client++){
		if(ValidPlayer(client,true)){
			if(strlen(weaponsAllowed[client])>0){
				
			}
		}
	}
}