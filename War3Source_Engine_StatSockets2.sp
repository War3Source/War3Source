// example for the socket extension
#pragma semicolon 1;

#include <sourcemod>
#include <socket>
//use ur own natives and stocks
#include "W3SIncs/War3Source_Interface"

#pragma dynamic 100000 //cells.....*4 for bytes
//#pragma amxram 40960 // 4 KB available for data+stack.

new Handle:hShowSocketError;

new trieCount;

public Plugin:myinfo = {
	name = "W3S Engine Stats sockets 2",
	author = "Ownz (DarkEnergy)",
	description = "statistics collector",
	version = "1.0",
	url = "war3source.com"
};


public OnPluginStart() {
	hShowSocketError=CreateConVar("war3_show_sockets_error","0","show socket errors");
	//CreateTimer(1.0,PrintTrieCount,_,TIMER_REPEAT);
}
//public Action:PrintTrieCount(Handle:t){
//	PrintToServer("%d",trieCount);
//}

public bool:InitNativesForwards()
{
	CreateNative("W3Socket2",NW3Socket2);
	return true;
}
public NW3Socket2(Handle:plugin,numParams){
	if(trieCount<200)
	{
		new String:path[2000];
		GetNativeString(1,path,sizeof(path));
		
		
		new String:data[8000];
		GetNativeString(2,data,sizeof(data));///ASSUME DATA IS PHP ESCAPED
		
		new Function:func=Function:GetNativeCell(3); //callback
	
		new Handle:trie = CreateTrie();
		trieCount++;
		
		///////////////////////////////Fill in trie to magnify memory usage during debug
		//new String:str[1000][8];
		//new String:str2[]="zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz";
		//for(new i=0;i<1000;i++){
		//	Format(str[i],sizeof(str),"%d",i);
		//	
		//}
		//for(new i=0;i<1000;i++){
		//	SetTrieString(trie, str[i], str2,true); 
		//}
	
	
		
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
		W3LogNotError("\r\n\r\n rnrn not found, reset / error / congestion");
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
	

	new Function:func;
	GetTrieValue(trie,"func",func);
	new Handle:plugin;
	GetTrieValue(trie,"plugin",plugin);
	
	
	CloseHandle(trie);
	trieCount--;
	
	Call_StartFunction(plugin,func);
	Call_PushCell(0);
	Call_PushCell(1);
	Call_Finish(dummy);
	
}
stock bool:ShowError(){
	return GetConVarInt(hShowSocketError)>0?true:false;
}