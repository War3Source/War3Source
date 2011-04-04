// example for the socket extension
#pragma semicolon 1;

#include <sourcemod>
#include <socket>
//use ur own natives and stocks
#include "W3SIncs/War3Source_Interface"

#pragma dynamic 10000 //cells.....*4 for bytes
//#pragma amxram 40960 // 4 KB available for data+stack.

public Plugin:myinfo = {
	name = "War3Source Engine Stats sockets",
	author = "Ownz (DarkEnergy)",
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
	CreateNative("W3Socket2",NW3Socket2);
	return true;
}
public NW3Socket2(Handle:plugin,numParams){
	new String:path[2000];
	GetNativeString(1,path,sizeof(path));
	
	
	new String:data[8000];
	GetNativeString(2,data,sizeof(data));///ASSUME DATA IS PHP ESCAPED
	
	//ReplaceString(data,sizeof(data)," ","%20");
	//if(strlen(path)>sizeof(path)-10){
	//	W3LogError("socket path exceeds 1990 string chars");
	//}
	
	
	//PrintToServer("%s",path);
	
	new Function:func=Function:GetNativeCell(3);
	
	
	new Handle:trie = CreateTrie();
	SetTrieString(trie,"path", path);
	SetTrieString(trie,"data", data);
	SetTrieValue(trie,"func", func);
	SetTrieValue(trie,"plugin", plugin);
	SetTrieString(trie,"response", "RESPONSE:");
	
	new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketSetArg(socket,trie);
	// open a file handle for writing the result
	//new Handle:hFile = OpenFile("dl.htm", "wb");
	// pass the file handle to the callbacks
	//SocketSetArg(socket, hFile);
	// connect the socket
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "mysql.ownageclan.com", 80);
}

public OnSocketConnected(Handle:socket, any:trie) {
	new String:path[2000];
	GetTrieString(trie,"path",path,sizeof(path));
	new String:data[8000];
	GetTrieString(trie,"data",data,sizeof(data));
	
	new String:requestStr[8000];
	requestStr[0]='\0';
	Format(requestStr, sizeof(requestStr), "POST /%s HTTP/1.0\r\nHost: %s\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: %d\r\n\r\n%s\r\n", path, "mysql.ownageclan.com",strlen(data),data);
	//PrintToServer("/////////");
	//PrintToServer("////////");
	//PrintToServer("/////////");
	//PrintToServer("%s",requestStr);
	SocketSend(socket, requestStr);
	
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:trie) {
	// receive another chunk and write it to <modfolder>/dl.htm
	// we could strip the http response header here, but for example's sake we'll leave it in

	//PrintToServer(receiveData, false);
	
	
	new String:responsestr[8000];
	GetTrieString(trie,"response",responsestr,sizeof(responsestr));
	StrCat(responsestr,sizeof(responsestr),receiveData);
	SetTrieString(trie,"response",responsestr);
}

public OnSocketDisconnected(Handle:socket, any:trie) {
	CloseHandle(socket);
	
	
	new String:responsestr[8000];
	GetTrieString(trie,"response",responsestr,sizeof(responsestr));
	
	new String:exploded[2][2000];
	new index=StrContains(responsestr,"\r\n\r\n");
	if(index==-1){
		W3LogNotError("\r\n\r\n rnrn not found");
	}
	else{
		
		ExplodeString(responsestr, "\r\n\r\n", exploded, 2, 2000);
	}
	
	new Function:func;
	GetTrieValue(trie,"func",func);
	new Handle:plugin;
	GetTrieValue(trie,"plugin",plugin);
	
	index=StrContains(responsestr,"success");
	
	CloseHandle(trie);
	
	Call_StartFunction(plugin,func);
	Call_PushCell(index>=0?1:0);
	Call_PushCell(0);
	Call_PushString(exploded[1]);
	Call_Finish(dummy);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:trie) {
	// a socket error occured
	if(socket!=INVALID_HANDLE){
		CloseHandle(socket);
	}
	W3LogNotError("Does not affect functionality, do not report this error: socket error %d (errno %d)", errorType, errorNum);
	if(errorNum==10061){
		W3LogNotError("Conn Refused");
	}
	if(errorNum==10060){
		W3LogNotError("Timeout");
	}
	

	new Function:func;
	GetTrieValue(trie,"func",func);
	new Handle:plugin;
	GetTrieValue(trie,"plugin",plugin);
	
	
	CloseHandle(trie);
	
	Call_StartFunction(plugin,func);
	Call_PushCell(0);
	Call_PushCell(1);
	Call_Finish(dummy);
	
}
