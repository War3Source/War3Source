// example for the socket extension
#pragma semicolon 1;

#include <sourcemod>
#include <profiler>
#include "W3SIncs/socket.inc"
//use ur own natives and stocks
#include "W3SIncs/War3Source_Interface"

#pragma dynamic 200000 //cells.....*4 for bytes
//#pragma amxram 40960 // 4 KB available for data+stack.
#define RESPONSESTRINGLEN 32000


public Plugin:myinfo = 
{
    name = "War3Source - Engine - Stats Socket 2",
    author = "War3Source Team",
    description = "Collect statistics and send them to Ownz"
};

new Handle:hShowSocketError;
new const MAXSOCKETS=5;
new const MAXQUEUELEN=3000;
new trieCount;
new socketCount;
enum SOCKETTYPE{ RAW,HTTPGET,HTTPPOST};

new backoffcounter;
new Handle:socketQueue;

public OnPluginStart() {
    hShowSocketError=CreateConVar("w3_show_sockets_error","0","show socket errors");
//    CreateTimer(0.1,DeciTimer,_,TIMER_REPEAT);
    socketQueue=CreateArray();
}
//public Action:PrintTrieCount(Handle:t){
//    PrintToServer("%d",trieCount);
//}

public bool:InitNativesForwards()
{
    CreateNative("W3Socket",NW3Socket);
    CreateNative("W3Socket2",NW3Socket2);
    return true;
}
public NW3Socket(Handle:plugin,numParams)
{
    //functions inside use the GetNative parameters
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
       //default host
        decl String:host[2000];
        host[0]='\0';
        Format(host,sizeof(host),"mysql.ownageclan.com");
        
        decl String:path[2000];
        path[0]='\0';
        GetNativeString(1,path,sizeof(path));
        
        //OVERRIDE PATH
        if(StrContains(path,"http://")>-1)
        {
            new pos=FindCharInString(path, '/');
            //DP("pos %d %s",pos,path[pos+1]);
            pos+=FindCharInString(path[pos+1], '/')+1;
            //DP("pos %d %s",pos,path[pos+1]);
            new front=pos; //for cutting http://
            pos+=FindCharInString(path[pos+1], '/')+1;
            //DP("pos %d %s",pos,path[pos+1]);
            new back=pos;


            Format(host,back-front,"%s",path[front+1]);
            //DP("%s",host);
            
            Format(path,sizeof(path),"%s",path[back+1]); // we later append /
            //DP("path %s",path);
        }
        
        decl String:data[8000];
        data[0]='\0';
        new Function:func;
        if(type==HTTPGET){
            
            func=GetNativeCell(2); //callback;
        }
        else if(type==HTTPPOST){
            GetNativeString(2,data,sizeof(data));///ASSUME DATA IS PHP ESCAPED
            func=GetNativeCell(3); //callback;
        }
        
        
    
        new Handle:trie = CreateTrie();
        trieCount++;
        
        SetTrieString(trie,"host", host);
        SetTrieString(trie,"path", path);
        SetTrieString(trie,"data", data);
        SetTrieValue(trie,"func", _:func);
        SetTrieValue(trie,"plugin", plugin);
        SetTrieString(trie,"response", "RESPONSE:");
        SetTrieValue(trie,"type", type);
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
            War3_LogInfo("Cannot create more queue tries, %d queued connections reached",MAXQUEUELEN);
        }
    }    
}
InitiateSocket(Handle:trie){
    new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
    if(socket!=INVALID_HANDLE){
        socketCount++;    
        SocketSetArg(socket,trie);
        decl String:host[2000];
        host[0]='\0';
        GetTrieString(trie,"host",host,sizeof(host));
        //DP("host %s",host);
        SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, host, 80);
    }
    else{
        War3_LogInfo("Create Socket Failed");
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
    decl String:host[2000];
    host[0]='\0';
    GetTrieString(trie,"host",host,sizeof(host));
    
    decl String:path[2000];
    path[0]='\0';
    GetTrieString(trie,"path",path,sizeof(path));
    
    decl String:data[16000];
    data[0]='\0';
    GetTrieString(trie,"data",data,sizeof(data));
    
    //HTTP header and stuffs, with post data
    decl String:requestStr[8000];
    requestStr[0]='\0';
    new SOCKETTYPE:type;
    GetTrieValue(trie,"type",type);
    if(type==HTTPGET)
    {
        Format(requestStr, sizeof(requestStr), "GET /%s HTTP/1.0\r\nHost: %s\r\n\r\n\r\n", path, host);
    }
    else if(type==HTTPPOST)
    {
        Format(requestStr, sizeof(requestStr), "POST /%s HTTP/1.0\r\nHost: %s\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: %d\r\n\r\n%s\r\n", path, "mysql.ownageclan.com",strlen(data),data);
    }
    else{
        //NO HTTP HEADER, DIRECT TCP
        Format(requestStr, sizeof(requestStr), "%s",data);
    }
    SocketSend(socket, requestStr);
    
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:trie) {
    // receive another chunk and write it to <modfolder>/dl.htm
    // we could strip the http response header here, but for example's sake we'll leave it in

    //PrintToServer(receiveData, false);
    //DATA never exceeds 4096 including null terminator chunks! (according to documentation)
    
    
    //new Handle:profiler=CreateProfiler();
    //StartProfiling(profiler);
    decl String:responsestr[RESPONSESTRINGLEN];
    responsestr[0]='\0';
    GetTrieString(trie,"response",responsestr,sizeof(responsestr));
    StrCat(responsestr,sizeof(responsestr),receiveData);
    SetTrieString(trie,"response",responsestr);
    //StopProfiling(profiler);
    
    //DP("%f %d",GetProfilerTime(profiler),strlen(responsestr));
    //CloseHandle(profiler);
    
    //0.00006 seconds !
}

public OnSocketDisconnected(Handle:socket, any:trie) {
    CloseHandle(socket);
    socketCount--;
    
    new String:responsestr[RESPONSESTRINGLEN];
    GetTrieString(trie,"response",responsestr,sizeof(responsestr));
    
    new String:exploded[2][RESPONSESTRINGLEN];
    new index=StrContains(responsestr,"\r\n\r\n");
    if(index==-1)
    {
        if(ShowError())
        {
            War3_LogInfo("\r\n\r\n rnrn not found, reset / error / congestion");
        }
    }
    else{
        
        ExplodeString(responsestr, "\r\n\r\n", exploded, 2, RESPONSESTRINGLEN);
    }
    if(strlen(responsestr)==0&&ShowError()){ //zero length is probably failed, HTTP has 200 OK message at least
        War3_LogInfo("Zero length socket return disconnect");
    }
    
    new Function:func;
    GetTrieValue(trie,"func", _:func);
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
        War3_LogInfo("Does not affect functionality, do not report this error: socket error %d (errno %d)", errorType, errorNum);
        if(errorNum==10061){
            War3_LogInfo("Conn Refused");
        }
        if(errorNum==10060){
            War3_LogInfo("Timeout");
        }
    }
    SetTrieString(trie,"response","");
    FrontInsertQueue(trie);
    backoffcounter+=5;
    
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