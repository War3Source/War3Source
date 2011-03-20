

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new bool:heroHasPowerBind[MAXRACES];

public Plugin:myinfo= 
{
	name="SH Engine Hero Class",
	author="Ownz",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};





public OnPluginStart()
{
}

public bool:InitNativesForwards()
{

	CreateNative("SHGetHeroHasPowerBind",NSHGetHeroHasPowerBind);
	CreateNative("SHSetHeroHasPowerBind",NSHSetHeroHasPowerBind);
	return true;
}


public NSHGetHeroHasPowerBind(Handle:plugin,numParams){
	return heroHasPowerBind[GetNativeCell(1)];
}


public NSHSetHeroHasPowerBind(Handle:plugin,numParams){
	heroHasPowerBind[GetNativeCell(1)]=bool:GetNativeCell(2);
}
