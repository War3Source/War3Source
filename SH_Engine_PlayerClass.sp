

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

enum SHPlayer{
	xp,
	level,
	bool:hasHero[MAXRACES],
	powerbind[3],
}
new player[MAXPLAYERSCUSTOM][SHPlayer];

new Handle:g_OnHeroChangedHandle;

new Handle:hMaxHeroesPerPlayer;

public Plugin:myinfo= 
{
	name="SH Engine player class",
	author="Ownz",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};


public OnPluginStart()
{
	hMaxHeroesPerPlayer=CreateConVar("sh_heroes_per_player","3","How many heroes can a player have");
}

public bool:InitNativesForwards()
{
	g_OnHeroChangedHandle=CreateGlobalForward("OnHeroChanged",ET_Ignore,Param_Cell);
	
	CreateNative("SHGetLevel",NSHGetLevel);
	CreateNative("SHSetLevel",NSHSetLevel);
	CreateNative("SHGetXP",NSHGetXP);
	CreateNative("SHSetXP",NSHSetXP);
	CreateNative("SHHasHero",NSHHasHero);
	CreateNative("SHSetHasHero",NSHSetHasHero);
	
	CreateNative("SHGetPowerBind",NSHGetPowerBind);
	CreateNative("SHSetPowerBind",NSHSetPowerBind);
	
	CreateNative("SHGetHeroesClientCanHave",NSHGetHeroesClientCanHave);
	
	return true;
}


public NSHGetLevel(Handle:plugin,numParams){
	return player[GetNativeCell(1)][level];
}
public NSHSetLevel(Handle:plugin,numParams){
	player[GetNativeCell(1)][level]=GetNativeCell(2);
}
public NSHGetXP(Handle:plugin,numParams){
	return player[GetNativeCell(1)][xp];
}
public NSHSetXP(Handle:plugin,numParams){
	player[GetNativeCell(1)][xp]=GetNativeCell(2);
}


public NSHHasHero(Handle:plugin,numParams){
	//PrintToServer("%d %d",GetNativeCell(1),GetNativeCell(2));
	if(SH()){
		return player[GetNativeCell(1)][hasHero][GetNativeCell(2)];
	}
	return _:false;
}
public NSHSetHasHero(Handle:plugin,numParams){
	new bool:oldhas=player[GetNativeCell(1)][hasHero][GetNativeCell(2)];
	player[GetNativeCell(1)][hasHero][GetNativeCell(2)]=GetNativeCell(3);
	
	new String:heroname[32];
	SHGetHeroName(GetNativeCell(2),heroname,sizeof(heroname));
	if(GetNativeCell(3)==true&&oldhas==false){
		
		War3_ChatMessage(GetNativeCell(1),"You now have hero %s",heroname);
	}
	else if(GetNativeCell(3)==false&&oldhas==true){
		War3_ChatMessage(GetNativeCell(1),"You no longer have hero %s",heroname);
	}
	
	Call_StartForward(g_OnHeroChangedHandle);
	Call_PushCell(GetNativeCell(1));
	new result;
	Call_Finish(result);
}

public NSHGetPowerBind(Handle:plugin,numParams){
	return player[GetNativeCell(1)][powerbind][GetNativeCell(2)];
}


public NSHSetPowerBind(Handle:plugin,numParams){
	player[GetNativeCell(1)][powerbind][GetNativeCell(2)]=GetNativeCell(3);
}

public NSHGetHeroesClientCanHave(Handle:plugin,numParams){
	new client=GetNativeCell(1);
	return SHGetLevel(client)<GetConVarInt(hMaxHeroesPerPlayer)?SHGetLevel(client):GetConVarInt(hMaxHeroesPerPlayer);
}




public OnWar3Event(W3EVENT:event,client){
	if(SH()){
		if(event==ClearPlayerVariables){
			InternalClearPlayerVars(client);
		}
	}
}
InternalClearPlayerVars(client){
	for(new i=0;i<=War3_GetRacesLoaded();i++){
		SHSetHasHero(client,i,false);
		
	}
	for(new i=0;i<3;i++){
		SHSetPowerBind(client,i,0);
	}
	SHSetLevel(client,0);
	SHSetXP(client,0);
}