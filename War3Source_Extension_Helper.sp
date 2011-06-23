

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

#include "W3SIncs/war3ext"

#pragma dynamic 10000

//extension helper
enum EXTH { 
EXTH_HOSTNAME,
EXTH_W3VERSION_STR,
EXTH_W3VERSION_NUM,
EXTH_GAME ,
EXTH_W3_SH_MODE,
 EXTH_IP ,
EXTH_PORT
};

public Plugin:myinfo= 
{
	name="War3Source Extension Wrapper",
	author="Ownz",
	description="War3Source SH Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};
native W3ExtTick();
new Handle:hHostname;
new String:serverip[16];
new serverport;

public OnPluginStart()
{
	W3ExtRegister("helper1");
	hHostname=FindConVar("hostname");
	CreateTimer(1.0,SecondTick,_,TIMER_REPEAT);
}
public OnMapStart(){
	
	new iIp = GetConVarInt(FindConVar("hostip"));
	Format(serverip, sizeof(serverip), "%i.%i.%i.%i", (iIp >> 24) & 0x000000FF,
	(iIp >> 16) & 0x000000FF,
	(iIp >>  8) & 0x000000FF,
	iIp         & 0x000000FF);
	
	serverport=GetConVarInt(FindConVar("hostport"));
}
public any:Get(id,String:buf[],maxlen){
	buf[0]=0;
	
	//PrintToServer("got id %d buf %s len %d",id,buf,maxlen);
	switch(id){
		case EXTH_HOSTNAME: GetConVarString(hHostname,buf,maxlen);
		case EXTH_W3VERSION_STR: W3GetW3Version(buf,maxlen);
		case EXTH_W3VERSION_NUM: return W3GetW3Revision();
		case EXTH_GAME: GetGameFolderName(buf,maxlen);
		case EXTH_W3_SH_MODE: return W3();
		case EXTH_IP: Format(buf,maxlen,serverip);
		case EXTH_PORT: return serverport;
		
		default: { PrintToServer("bad index for ext helper %d",id);}
	}
	return 0;
}
public Action:SecondTick(Handle:t){
	W3ExtTick();
}

