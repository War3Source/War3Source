

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

#include "W3SIncs/war3ext"

#define EXTH_HOSTNAME 1
#define EXTH_W3VERSION 2
#define EXTH_GAME 3
#define EXTH_W3_SH_MODE 4
#define EXTH_IP 5
#define EXTH_PORT 6
#define EXTH_
#define EXTH_
#define EXTH_
#define EXTH_

public Plugin:myinfo= 
{
	name="War3Source Extension Wrapper",
	author="Ownz",
	description="War3Source SH Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};


new Handle:hHostname;
new String:serverip[16];
new serverport;

public OnPluginStart()
{
	W3ExtRegister("helper1");
	hHostname=FindConVar("hostname");
	
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
	switch(id){
		case EXTH_HOSTNAME: GetConVarString(hHostname,buf,maxlen);
		case EXTH_W3VERSION: W3GetW3Version(buf,maxlen);
		case EXTH_GAME: GetGameFolderName(buf,maxlen);
		case EXTH_W3_SH_MODE: return W3();
		case EXTH_IP: Format(buf,maxlen,serverip);
		case EXTH_PORT: return serverport;
	}
	return 0;
}


