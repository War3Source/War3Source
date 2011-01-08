// example for the socket extension

#include <sourcemod>
#include <socket>
//use ur own natives and stocks
#include "W3SIncs/War3Source_Interface"


public Plugin:myinfo = {
	name = "War3Source Engine Stats sockets",
	author = "Ownz",
	description = "statistics collector",
	version = "1.0",
	url = "war3source.com"
};

public APLRes:AskPluginLoad2(Handle:myself,bool:late,String:error[],err_max)
{
	if(!InitNativesForwards())
	{
		LogError("[War3Source] There was a failure in creating the native / forwards based functions, definately halting.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}
public OnPluginStart() {
	
}

bool:InitNativesForwards()
{
	CreateNative("W3Socket",NW3Socket);
	return true;
}
public NW3Socket(Handle:plugin,numParams){
	new String:path[2000];
	GetNativeString(1,path,sizeof(path));
	ReplaceString(path,sizeof(path)," ","%20");
	if(strlen(path)>sizeof(path)-10){
		W3LogError("socket path exceeds 1990 string chars");
	}
	//PrintToServer("%s",path);
	
	new Function:func=Function:GetNativeCell(2);
	new Handle:pack = CreateDataPack()
	WritePackString(pack, path)
	WritePackCell(pack, _:func)
	WritePackCell(pack, _:plugin)
	WritePackString(pack, "RESPONSE:")
	
	new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketSetArg(socket,pack)
	// open a file handle for writing the result
	//new Handle:hFile = OpenFile("dl.htm", "wb");
	// pass the file handle to the callbacks
	//SocketSetArg(socket, hFile);
	// connect the socket
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "mysql.ownageclan.com", 80)
}

public OnSocketConnected(Handle:socket, any:pack) {
	decl String:path[2000];
	ResetPack(pack);
	ReadPackString(pack, path, sizeof(path));

	decl String:requestStr[3000];
	Format(requestStr, sizeof(requestStr), "GET /%s HTTP/1.0\r\nHost: %s\r\n\r\n\r\n", path, "mysql.ownageclan.com");
	SocketSend(socket, requestStr);
	
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:pack) {
	// receive another chunk and write it to <modfolder>/dl.htm
	// we could strip the http response header here, but for example's sake we'll leave it in

	//PrintToServer(receiveData, false);
	ResetPack(pack);
	decl String:path[2000];
	ReadPackString(pack, path, sizeof(path));
	new Function:func=Function:ReadPackCell(pack);
	new Handle:plugin=Handle:ReadPackCell(pack);
	new String:buff[10000];
	ReadPackString(pack, buff, sizeof(buff));
	StrCat(buff,sizeof(buff),receiveData);
	
	
	ResetPack(pack,true);
	WritePackString(pack, path)
	WritePackCell(pack, _:func)
	WritePackCell(pack, _:plugin)
	WritePackString(pack, buff)
}

public OnSocketDisconnected(Handle:socket, any:pack) {
	CloseHandle(socket);
	
	ResetPack(pack);
	decl String:path[2000];
	ReadPackString(pack, path, sizeof(path));
	new Function:func=Function:ReadPackCell(pack);
	new Handle:plugin=Handle:ReadPackCell(pack);
	new String:buff[10000];
	ReadPackString(pack, buff, sizeof(buff));
	
	new String:exploded[2][2000];
	new index=StrContains(buff,"\r\n\r\n");
	if(index==-1){
		LogError("not found");
	}
	else{
		
		ExplodeString(buff, "\r\n\r\n", exploded, 2, 2000);
	}
	
	CloseHandle(pack);
	
	Call_StartFunction(plugin,func);
	Call_PushCell(1);
	Call_PushCell(0);
	Call_PushString(exploded[1]);
	Call_Finish(dummy);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:pack) {
	// a socket error occured
	if(socket!=INVALID_HANDLE){
		CloseHandle(socket);
	}
	W3LogError("Does not affect functionality, do not report this error: socket error %d (errno %d)", errorType, errorNum);
//	if(errorNum==10061){
//		W3LogError("No connection could be made because the target computer actively refused it. This usually results from trying to connect to a service that is inactive on the foreign host—that is, one with no server application running.");
//	}
//	if(errorNum==10060){
//		W3LogError("A connection attempt failed because the connected party did not properly respond after a period of time, or the established connection failed because the connected host has failed to respond.");
//	}
	
	ResetPack(pack);
	decl String:path[2000];
	ReadPackString(pack, path, sizeof(path));
	new Function:func=Function:ReadPackCell(pack);
	new Handle:plugin=Handle:ReadPackCell(pack);
	
	CloseHandle(pack);
	
	
	Call_StartFunction(plugin,func);
	Call_PushCell(0);
	Call_PushCell(1);
	Call_Finish(dummy);
	
}
