// example for the socket extension
#pragma semicolon 1;

#include <sourcemod>
#include "W3SIncs/socket.inc"
//use ur own natives and stocks
#include "W3SIncs/War3Source_Interface"

#pragma dynamic 100000 //cells.....*4 for bytes
//#pragma amxram 40960 // 4 KB available for data+stack.

new Handle:hShowSocketError;
new const MAXSOCKETS=5;
new const MAXQUEUELEN=3000;
new trieCount;
new socketCount;
enum SOCKETTYPE{ RAW,HTTPGET,HTTPPOST};

new backoffcounter;
new Handle:socketQueue;
public Plugin:myinfo = {
	name = "W3S Engine Stats sockets 2",
	author = "Ownz (DarkEnergy)",
	description = "statistics collector",
	version = "1.0",
	url = "war3source.com"
};


public OnPluginStart() {
	hShowSocketError=CreateConVar("w3_show_sockets_error","0","show socket errors");
//	CreateTimer(0.1,DeciTimer,_,TIMER_REPEAT);
	socketQueue=CreateArray();
}
//public Action:PrintTrieCount(Handle:t){
//	PrintToServer("%d",trieCount);
//}

public bool:InitNativesForwards()
{
	CreateNative("W3Socket",NW3Socket);
	CreateNative("W3Socket2",NW3Socket2);
	return true;
}
public NW3Socket(Handle:plugin,numParams)
{
	PrepareSocket(plugin,HTTPGET);
}
public NW3Socket2(Handle:plugin,numParams)
{
	PrepareSocket(plugin,HTTPPOST);
}
PrepareSocket(Handle:plugin,SOCKETTYPE:type)
{

	if(trieCount<MAXQUEUELEN) //1000
	{
		decl String:path[2000];
		path[0]='\0';
		GetNativeString(1,path,sizeof(path));
		
		decl String:data[8000];
		data[0]='\0';
		new Function:func;
		if(type==HTTPGET){
			
			func=Function:GetNativeCell(2); //callback;
		}
		else if(type==HTTPPOST){
			GetNativeString(2,data,sizeof(data));///ASSUME DATA IS PHP ESCAPED
			func=Function:GetNativeCell(3); //callback;
		}
		
		
	
		new Handle:trie = CreateTrie();
		trieCount++;
		
		
		SetTrieString(trie,"path", path);
		SetTrieString(trie,"data", data);
		SetTrieValue(trie,"func", func);
		SetTrieValue(trie,"plugin", plugin);
		SetTrieString(trie,"response", "RESPONSE:");
		SetTrieValue(trie,"type", type);
	/*	SetTrieString(trie,"TEST","NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN");
		SetTrieString(trie,"TEST1","NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN");
		SetTrieString(trie,"TEST2","NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN");
		SetTrieString(trie,"TEST11","NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN");
		SetTrieString(trie,"TEST111","NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN");
		SetTrieString(trie,"TEST112","NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN");
		SetTrieString(trie,"TEST11","NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN");
		SetTrieString(trie,"TEST111","NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN");
		SetTrieString(trie,"TEST112","NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN");
	*/	
		if(socketCount<MAXSOCKETS&&backoffcounter==0)
		{
			InitiateSocket(trie);
		}
		else if(GetArraySize(socketQueue)<100000)
		{
			PushArrayCell(socketQueue,trie);
		}
		
	}
	else{
		if(ShowError())
		{
			W3LogNotError("Cannot create more queue tries, %d queued connections reached",MAXQUEUELEN);
		}
	}	
}
InitiateSocket(Handle:trie){
	new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
	if(socket!=INVALID_HANDLE){
		socketCount++;	
		SocketSetArg(socket,trie);
		SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "ownageclan.com", 80);
	}
	else{
		W3LogError("Create Socket Failed");
	}
}
public OnGameFrame(){
	if(backoffcounter>0){
		backoffcounter--;
		if(backoffcounter>200){
			backoffcounter=200;
		}
	}
	
	new initiates=MAXSOCKETS; //wonpt actually be this many, it will consider the amount of open sockets later
	if(backoffcounter>0){ //only allow 1 socket if errored not long ago
		initiates=1;
	}
	else if(backoffcounter==0){
		initiates=MAXSOCKETS;
	}
	while(socketCount<MAXSOCKETS&&initiates>0){
		initiates--;
		if(GetArraySize(socketQueue)>0){
			InitiateSocket(GetArrayCell(socketQueue,0));
			RemoveFromArray(socketQueue, 0);
		}
	}
	return;
	//DP("%d",GetArraySize(socketQueue));
}
public OnSocketConnected(Handle:socket, any:trie) {
	decl String:path[2000];
	path[0]='\0';
	GetTrieString(trie,"path",path,sizeof(path));
	
	decl String:data[8000];
	data[0]='\0';
	GetTrieString(trie,"data",data,sizeof(data));
	
	decl String:requestStr[8000];
	requestStr[0]='\0';
	new SOCKETTYPE:type;
	GetTrieValue(trie,"type",type);
	if(type==HTTPGET)
	{
		Format(requestStr, sizeof(requestStr), "GET /%s HTTP/1.0\r\nHost: %s\r\n\r\n\r\n", path, "mysql.ownageclan.com");
	}
	else if(type==HTTPPOST)
	{
		Format(requestStr, sizeof(requestStr), "POST /%s HTTP/1.0\r\nHost: %s\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: %d\r\n\r\n%s\r\n", path, "mysql.ownageclan.com",strlen(data),data);
	}
	else{
		Format(requestStr, sizeof(requestStr), "%s",data);
	}
	SocketSend(socket, requestStr);
	
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:trie) {
	// receive another chunk and write it to <modfolder>/dl.htm
	// we could strip the http response header here, but for example's sake we'll leave it in

	//PrintToServer(receiveData, false);
	
	
	decl String:responsestr[8000];
	responsestr[0]='\0';
	GetTrieString(trie,"response",responsestr,sizeof(responsestr));
	StrCat(responsestr,sizeof(responsestr),receiveData);
	SetTrieString(trie,"response",responsestr);
}

public OnSocketDisconnected(Handle:socket, any:trie) {
	CloseHandle(socket);
	socketCount--;
	
	new String:responsestr[8000];
	GetTrieString(trie,"response",responsestr,sizeof(responsestr));
	
	new String:exploded[2][2000];
	new index=StrContains(responsestr,"\r\n\r\n");
	if(index==-1)
	{
		if(ShowError())
		{
			W3LogNotError("\r\n\r\n rnrn not found, reset / error / congestion");
		}
	}
	else{
		
		ExplodeString(responsestr, "\r\n\r\n", exploded, 2, 2000);
	}
	if(strlen(responsestr)==0&&ShowError()){ //zero length is probably failed, HTTP has 200 OK message at least
		W3LogNotError("Zero length socket return disconnect");
	}
	
	new Function:func;
	GetTrieValue(trie,"func",func);
	new Handle:plugin;
	GetTrieValue(trie,"plugin",plugin);
	
	index=StrContains(responsestr,"success");
	
	CloseHandle(trie);
	trieCount--;
	
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
	socketCount--;
	if(ShowError())
	{
		W3LogNotError("Does not affect functionality, do not report this error: socket error %d (errno %d)", errorType, errorNum);
		if(errorNum==10061){
			W3LogNotError("Conn Refused");
		}
		if(errorNum==10060){
			W3LogNotError("Timeout");
		}
	}
	SetTrieString(trie,"response","");
	FrontInsertQueue(trie);
	backoffcounter+=5;
/*	new Function:func;
	GetTrieValue(trie,"func",func);
	new Handle:plugin;
	GetTrieValue(trie,"plugin",plugin);
	
	
	CloseHandle(trie);
	trieCount--;
	
	Call_StartFunction(plugin,func);
	Call_PushCell(0);
	Call_PushCell(1);
	Call_Finish(dummy);*/
	
}
FrontInsertQueue(Handle:trie)
{
	if(GetArraySize(socketQueue)>0){
		ShiftArrayUp(socketQueue,0);
		SetArrayCell(socketQueue,0,trie);
	}
	else{
		PushArrayCell(socketQueue,trie);
	}
}
stock bool:ShowError(){
	return GetConVarInt(hShowSocketError)>0?true:false;
}