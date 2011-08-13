 	

////BUFF SYSTEM




#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo= 
{
	name="War3Source Buff MAXHP",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};
new Handle:mytimer[MAXPLAYERSCUSTOM];
public OnPluginStart()
{
	for(new i=0;i<MAXPLAYERSCUSTOM;i++){
		mytimer[i]=INVALID_HANDLE;
	}	
}
public OnWar3EventSpawn(client){
	
	if(mytimer[client]!=INVALID_HANDLE){
		CloseHandle(mytimer[client]);
	}
	mytimer[client]=CreateTimer(0.1,CheckHP,client);

}
public Action:CheckHP(Handle:h,any:client){
	mytimer[client]=INVALID_HANDLE;
	if(ValidPlayer(client,true)){
		new hpadd=W3GetBuffSumInt(client,iAdditionalMaxHealth);
		SetEntityHealth(client,GetClientHealth(client)+hpadd);
		War3_SetMaxHP(client,War3_GetMaxHP(client)+hpadd);
	}
}

public OnClientPutInServer(client)
{
   //  SDKHook(client, SDKHook_PostThink, PostThinkHook);
}
 
public PostThinkHook(client)
{
    //if(GameTF()){
    //      TF2_SetPlayerResourceData(client, TFResource_MaxHealth, War3_GetMaxHP(client));
    //}
    
}  