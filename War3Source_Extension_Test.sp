

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/war3ext"

public Plugin:myinfo= 
{
	name="War3Source Extension Test",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};




public OnPluginStart()
{
	new String:buf[32];
	
	W3ExtVersion(buf,sizeof(buf));
	PrintToServer("[sm] W3ExtVersion %s",buf);
	
	W3ExtTestFunc(CallMe,INVALID_HANDLE);//it will use our own plugin handle
	W3ExtTestFunc(CallMe,GetMyHandle());//still using our own plugin handle
}

public CallMe(client,String:phonenumber[]){
	PrintToServer("You called CallMe, client %d Phone# %s",client,phonenumber);
}

public StaticFuncName(client,String:phonenumber[]){
	PrintToServer("StaticFuncName client %d Phone# %s",client,phonenumber);
}






