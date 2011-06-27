
#include "../DO NOT COMPILE"
/**********************
 * DO NOT COMPILE THIS FILE BY YOURSELF, use the .smx provided in the compiled folder.
 * This file is required for war3 extensions, and must be not be tampered with.
 * Purpose of this plugin is to provide inter plugin-extension communication and compatability. 
 * War3 Extensions will not work properly if the hash of the .smx file is incorrect. 
 * The include line above is to prevent users from compiling 
 * 
 * to forcibly compile verify that this plugin does not contain malicious code, 
 *  remove the include line above, 
 *  compile, 
 *  and compare in binary of the file uncompressed using zlib
 *  please note again that war3 extensions will not work properly if you are not using the provided .smx 
 */ 



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
EXTH_PORT,
EXTH_TRANS
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
	if(!AddCommandListener(CommandListener,"")){
		W3LogError("COULD NOT REGISTER COMMAND LISTENER");
	}
	RegConsoleCmd("w3e", OnCommand);
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
		case EXTH_TRANS: return GetTrans();
		default: { PrintToServer("bad index for ext helper %d",id);}
	}
	return 0;
}
public Action:SecondTick(Handle:t){
	W3ExtTick();
}
native W3ExtCommandListener(client, const String:command[], argc);
public Action:CommandListener(client, const String:command[], argc){ //only actual commands
	W3ExtCommandListener(client,command,argc);
}

public Action:OnCommand(client,args){
	new String:cmd[1024];
	new String:argstr[1024];
	GetCmdArg(0,cmd,sizeof(cmd));
	GetCmdArgString(argstr,sizeof(argstr)); //command is arg 0
	Format(cmd,sizeof(cmd),"%s %s",cmd,argstr);
	W3ExtCommandListener(client,cmd,args);
	DP("%s",cmd);
}
