 	
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
	version="1.1",
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
new ORIGINALHP[MAXPLAYERSCUSTOM];
new bool:bHealthAddedThisSpawn[MAXPLAYERSCUSTOM];
public OnWar3EventSpawn(client){
	ORIGINALHP[client]=GetClientHealth(client);
	//if(!IsFakeClient(client))
  	//	DP("SPAWN set oroginal %d",ORIGINALHP[client]);
 
	
//	if(W3GetPlayerProp(client,bStatefulSpawn)){
	if(mytimer[client]!=INVALID_HANDLE){
		CloseHandle(mytimer[client]);
	}
	mytimer[client]=CreateTimer(0.01,CheckHP,client);
	//DP("TIMERCREATE");
//	}
}

public OnWar3EventDeath(client){
	bHealthAddedThisSpawn[client]=false;
}

public Action:CheckHP(Handle:h,any:client){
//DP("TIMERHIT");
	mytimer[client]=INVALID_HANDLE;
	if(ValidPlayer(client,true) && !bHealthAddedThisSpawn[client]){
		new hpadd=W3GetBuffSumInt(client,iAdditionalMaxHealth);
		//if(!IsFakeClient(client))
		//DP("oroginal %d, additonal %d",ORIGINALHP[client],hpadd);
		new curhp=GetClientHealth(client);
		SetEntityHealth(client,curhp+hpadd);
		War3_SetMaxHP_INTERNAL(client,ORIGINALHP[client]+hpadd);
		//if(!IsFakeClient(client))
		//DP("was curhp %d, set to %d",curhp,GetClientHealth(client));
		LastDamageTime[client]=GetEngineTime()-100.0;
	}
}

new Handle:mytimer2[MAXPLAYERSCUSTOM];
public OnWar3Event(W3EVENT:event,client){
	if(event==OnBuffChanged)
	{
		if(W3GetVar(EventArg1)==iAdditionalMaxHealth&&ValidPlayer(client,true)){
			if(mytimer2[client]==INVALID_HANDLE){	
				mytimer2[client]=CreateTimer(0.1,CheckHPBuffChange,client);
			}
		}
	}
	//DP("EVENT %d",event);
}
public Action:CheckHPBuffChange(Handle:h,any:client){
	if(ValidPlayer(client,true)){
		mytimer2[client]=INVALID_HANDLE;
		new oldmaxhp=War3_GetMaxHP(client);
		new hpadd=W3GetBuffSumInt(client,iAdditionalMaxHealth);
		if(hpadd>0) {
			new newmaxhp=ORIGINALHP[client]+hpadd;
			
			War3_SetMaxHP_INTERNAL(client,newmaxhp);
			
			new newhp=GetClientHealth(client)+newmaxhp-oldmaxhp;
			if(newhp<1){
				newhp=1;
			}
			SetEntityHealth(client,newhp);
			bHealthAddedThisSpawn[client]=true;
		}
	}
}

public OnWar3EventPostHurt(victim,attacker,damage){
	if (ValidPlayer(victim)) {
		LastDamageTime[victim]=GetEngineTime();
	}
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
						new maxhp =War3_GetMaxHP(i)-hpadd; //nomal player hp
						
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