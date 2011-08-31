 	
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



new Handle:mytimer[MAXPLAYERSCUSTOM]; //INVLAID_HHANDLE is default 0
new Float:LastDamageTime[MAXPLAYERSCUSTOM];

public OnPluginStart()
{
//	for(new i=0;i<MAXPLAYERSCUSTOM;i++){
//		mytimer[i]=INVALID_HANDLE;
//	}	
	
	CreateTimer(0.1,TFHPBuff,_,TIMER_REPEAT);
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
		//DP("additonal %d",hpadd);
		SetEntityHealth(client,GetClientHealth(client)+hpadd);
		War3_SetMaxHP(client,War3_GetMaxHP(client)+hpadd);
		
		LastDamageTime[client]=GetEngineTime()-100.0;
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

public OnWar3EventPostHurt(victim,attacker,damage){
	LastDamageTime[victim]=GetEngineTime();
}
public Action:TFHPBuff(Handle:h,any:data){
	if(War3_GetGame()==Game_TF){
		new Float:now=GetEngineTime();
		//only create timer of TF2
		for(new i=1;i<=MaxClients;i++){
			if(ValidPlayer(i,true)){
				if(now>LastDamageTime[i]+10.0){
					
						// Devotion Aura
						new curhp =GetClientHealth(i);
						new hpadd=W3GetBuffSumInt(i,iAdditionalMaxHealth);
						new maxhp =War3_GetMaxHP(i)-hpadd;
						
						if(curhp>=maxhp&&curhp<maxhp+hpadd){ ///we should add
							new newhp=curhp+2;
							if(newhp>maxhp+hpadd){
								newhp=maxhp+hpadd;
							}
							//SetEntPropEnt(entity, PropType:type, const String:prop[], other);
							//SetEntPropEnt(client,SetEntPropEnt(entity, PropType:type, const String:prop[], other);
							//SetEntityHealth(i,newhp);
							//SetEntProp(i, Prop_Data , "m_iMaxHealth", maxhp+hpadd);

							SetEntityHealth(i, newhp);
							
							//SetEntProp(i, Prop_Send, "m_iHealth", newhp , 1);
					
						//curhp =GetClientHealth(i);
						//if(curhp>maxhp&&curhp<=maxhp+hpadd)
						//{
						//	TF2_AddCondition(i, TFCond_Healing, 1.0); //TF2 AUTOMATICALLY ADDS PARTICLES?
					//	}
						//else{
						//}
					}
				}
			}
		}
	}   
}