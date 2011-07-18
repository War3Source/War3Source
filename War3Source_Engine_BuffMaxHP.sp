 	

////BUFF SYSTEM




#pragma semicolon 1

#include <sourcemod>

#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo= 
{
	name="War3Source Buff MAXHP",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};

public OnPluginStart()
{
			
}
public OnWar3EventSpawn(client){
	CreateTimer(0.1,CheckHP,client);

}
public Action:CheckHP(Handle:h,any:client){
DP("1");
	if(ValidPlayer(client,true)){
		
		new hpadd=W3GetBuffSumInt(client,iAdditionalMaxHealth);
		DP("2 %d",hpadd):
		SetEntityHealth(client,GetClientHealth(client)+hpadd);
		War3_SetMaxHP(client,War3_GetMaxHP(client)+hpadd);
	}
	

}