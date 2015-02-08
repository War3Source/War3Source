#pragma semicolon 1
//size of cells for stack
//#pragma dynamic 200000

#include <sourcemod>
#include "socket.inc"


public Plugin:myinfo = 
{
    name = "War3Source - Updater",
    author = "War3Source Team",
    description = "Auto Update"
};

new fileSuccess = 0;
new fileExpected = 0;
new fileSkipped = 0;
new playerToPrint = 0;
new String:formatstr[10000];
#define EXPLODE_COUNT_SIZE 800
#define EXPLODE_STRING_SIZE 100
new String:exploded[EXPLODE_COUNT_SIZE][EXPLODE_STRING_SIZE]; //large memory, put on global instead of stack

new String:___tempstr___[1000];
PTC(const String:str[], any:...)
{
   VFormat(___tempstr___,sizeof(___tempstr___),str, 2);
   PrintToConsole(playerToPrint, "[W3Update] %s",___tempstr___);
}


#define PTCC(%0) Format(___tempstr___,sizeof(___tempstr___),"%d",%0); PrintToConsole(playerToPrint, ___tempstr___)

public OnPluginStart()
{    
    playerToPrint = 0;
    RegServerCmd("war3_update",cmdUpdate);
    return;
}

//make sure w3s directory exists
bool:CheckW3SDirectory()
{
    //create file?
    new String:folderpath[2000];
    BuildPath(Path_SM, folderpath, sizeof(folderpath), "plugins/w3s");
    //PTC(folderpath);
    
    new String:filepath[2000];
    Format(filepath, sizeof(filepath), "%s/%s",folderpath, "War3Source.smx");
    new Handle:fp = OpenFile(filepath,"r");
    if(fp==INVALID_HANDLE)
    {
       PTC("ERROR: plugins/w3s/War3Source.smx not found");
       PTC("ERROR: plugins/w3s/War3Source.smx must exist");
       PTC("ERROR: Unmodified plugins must be placed in plugins/w3s");
       PTC("ERROR: You should reinstall W3S (.smx files) into plugins/w3s");
       PTC("ERROR: custom .smx files may be placed into plugins/w3s_custom");
       return false;
    }
    else
    {
       CloseHandle(fp);
    }
    return true;
}
public Action:cmdUpdate(args)
{
    if(!CheckW3SDirectory())
    {
       PTC("ERROR: Update denied due to configuration requirements");
       return Plugin_Handled;
    }
    if(args == 0) // no parameters
    {
       PTC("Getting available updates");
       OCHTTPrequest("war3source/updater/listdirectories.php",callbackGetVersions);
    }
    if(args == 1) 
    {
       new String:arg[333];
       GetCmdArg(1, arg, sizeof(arg));
       new String:geturl[333];
       Format(geturl, sizeof(geturl), "war3source/updater/listfiles.php?path=%s", arg);
       new Handle:trie = OCHTTPrequest(geturl, callbackSpecifiedVersion);
       SetTrieString(trie, "versionDirectory", arg);
    }
    return Plugin_Handled;
}


public callbackGetVersions(Handle:trie, bool:success)
{
    if(!success)
    {
      PTC("Getting available versions to update to failed.");
      return;
    }
    
    new Handle:dataArray;
    GetTrieValue(trie,"data",any:dataArray);
    
    //convert trie data binary to ascii
    DataToString(trie, formatstr, sizeof(formatstr));
    
    
    if(StrContains(formatstr, "{") != 0 || StrContains(formatstr, "}") == -1)
    {
      PTC("{ and } not found in HTTP response");
      return; //failure
    }
    
    ReplaceString(formatstr, sizeof(formatstr), "{", "");
    ReplaceString(formatstr, sizeof(formatstr), "}", "");
    
    new explodedNumber = ExplodeString(formatstr, ",", String:exploded, 30, 101, true);
    PTC("---");
    if(explodedNumber>30) { explodedNumber = 30;} //max 30 versions to print
    for(new i = 0; i < explodedNumber; i++)
    {
    PTC("Version Available for update: %s", String:exploded[i]);
    }
    PTC("---");
    PTC("ONLY .smx files are updated.");
    PTC("");
    PTC("Auto updated files will be written to");
    PTC("   addons/sourcemod/plugins/w3s");
    PTC("");
    PTC("Folder listed above must exist.");
    PTC("   War3Source.smx must also exist in the folder.");
    PTC("");
    PTC("Files that exist in");
    PTC("   addons/sourcemod/plugins/w3s_custom");
    PTC("   will NOT be updated (name matching).");
    
    PTC("---");
    PTC("Enter command: war3_update <version> to update.");
    PTC("Example: war3_update 123");

}


public callbackSpecifiedVersion(Handle:trie, bool:success)
{
    if(!success)
    {
        PTC("Getting available versions to update to failed.");
        return;
    }
    
    new Handle:dataArray;
    GetTrieValue(trie,"data",any:dataArray);
    //convert trie data binary to ascii
    DataToString(trie, formatstr, sizeof(formatstr));
    
    
    if(StrContains(formatstr, "{") != 0 || StrContains(formatstr, "}") == -1)
    {
        PTC("{ and } not found in HTTP response");
        return; //failure
    }
    
    ReplaceString(formatstr, sizeof(formatstr), "{", "");
    ReplaceString(formatstr, sizeof(formatstr), "}", "");
    
    
    new explodedNumber = ExplodeString(formatstr, ",", String:exploded, EXPLODE_COUNT_SIZE, EXPLODE_STRING_SIZE, true);
    PTC("---");
    if(explodedNumber <10)
    {
        PTC("Unexpected result. Invalid version to update, or this version you are trying to update may not have files to update.");
     
        return;
    }
    if(explodedNumber %2 != 0)
    {
        PTC("Unexpected result. (count not even) Invalid version to update, or this version you are trying to update may not have files to update.");
        return;
    }
    fileSuccess = 0;
    fileExpected = explodedNumber/2;
    fileSkipped = 0;
    PTC("%d files found available for update", fileExpected );
    
    
    new String:versionDirectory[32];
    GetTrieString(trie,"versionDirectory",versionDirectory,sizeof(versionDirectory));
    for(new i = 0; i < explodedNumber; i++)
    {
       UpdateFile(versionDirectory, exploded[i], exploded[i+1]);
       i++;
    }

}

UpdateFile(const String:versionDirectory[], const String:filename[], const String:filesize[])
{
    //create file?
    new String:folderpath[2000];
    BuildPath(Path_SM, folderpath, sizeof(folderpath), "plugins/w3s_custom");
    //PTC(folderpath);
    
    new String:filepath[2000];
    Format(filepath, sizeof(filepath), "%s/%s",folderpath, filename);
    //PTC(filepath);
    new Handle:fp = OpenFile(filepath,"r");
    if(fp==INVALID_HANDLE)
    {
       //file not found in custom folder, we can update
       new String:urlpath[2000]; 
       Format(urlpath, sizeof(urlpath), "war3source/updater/%s/%s", versionDirectory, filename);
       new Handle:trie = OCHTTPrequest(urlpath, callbackGetFile);
       //PTC(urlpath);
       SetTrieString(trie, "filename", filename);
       SetTrieString(trie, "filesize", filesize);
    }
    else
    {
     PTC("- %s found in plugins/w3s_custom", filename);
     PTC("- ^^^ this file will not be updated");
     fileSkipped++;
     CloseHandle(fp);
    }
    
}

public callbackGetFile(Handle:trie, bool:success)
{
    for(new once = 0; once == 0; once++) //break logic
    {
        if(!success)
        {
          PTC("Getting file failed.");
          fileSkipped++;
          break;
        }
        
        new String:filename[100];
        GetTrieString(trie,"filename",filename,sizeof(filename));
        new String:filesize[100];
        GetTrieString(trie,"filesize",filesize,sizeof(filesize));
        new filesizeInt =  StringToInt(filesize);
        
        
        new Handle:dataArray;
        GetTrieValue(trie,"data",any:dataArray);
        
        //new array size
        new arraysize = GetArraySize(dataArray);
        if(filesizeInt != arraysize)
        {
            PTC("+ %s", filename);
            PTC("^^^ ERROR: unexpected size. Expected %d, got %d", filesizeInt, arraysize);
            fileSkipped++;
            break;
        }
        else
        { 
            PTC("+ %s | size OK: %d bytes", filename, arraysize);
        }
        
        //create file?
        new String:folderpath[2000];
        BuildPath(Path_SM, folderpath, sizeof(folderpath), "plugins/w3s");
        //PTC(folderpath);
        
        new String:filepath[2000];
        Format(filepath, sizeof(filepath), "%s/%s",folderpath, filename);
        //PTC(filepath);
        
        new Handle:fp =OpenFile(filepath,"wb"); //write, binary
        if(fp==INVALID_HANDLE)
        {
            PTC("could not open %s. Do you have permission to write to this directory?", filepath);
            fileSkipped++;
            break;
        }
        
        arraysize = GetArraySize(dataArray);
        //PTCC(arraysize);
        for(new i=0;i<arraysize;i++)
        {
            WriteFileCell(fp, GetArrayCell(dataArray, i), 1);
        }
        CloseHandle(fp);
        fileSuccess++;
    } //end break
    
    //if we got to this point, we good
    //see if we got all files
    if(fileExpected == (fileSkipped + fileSuccess) )
    {
        PTC("Total files: %d, skipped: %d, downloaded %d", fileExpected, fileSkipped, fileSuccess);
        PTC("Update complete");
        PTC("Hard server restart is recommended.");
    }

}













//a handle to the TRIE is returned, free it after
Handle:OCHTTPrequest(String:path[], Function:callback)
{
    new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
    if(socket!=INVALID_HANDLE)
    {
        new Handle:trie = CreateTrie();
        new Handle:data = CreateArray();
        new String:host[100] = "ownageclan.com";
        
        SetTrieString(trie, "host", host);
        SetTrieString(trie, "path", path);
        SetTrieValue(trie, "data", data);
        SetTrieValue(trie, "callback", _:callback);
        
        SocketSetArg(socket,trie);
        
        SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, host, 80);
        return trie;
    }
    else{
      PTC("Create Socket Failed");
    }
    return INVALID_HANDLE;
}

//callback

public OnSocketError(Handle:socket, const errorType, const errorNum, any:trie) {
    // a socket error occured
    if(socket!=INVALID_HANDLE){
        CloseHandle(socket);
    }
    new Function:callbackFunction;
    GetTrieValue(trie,"callback",_:callbackFunction);
    //INVALID_HANDLE = local plugin
    Call_StartFunction(INVALID_HANDLE, callbackFunction);
    Call_PushCell(trie);
    Call_PushCell(false);
    Call_Finish();
    
    CloseTrie(trie);
    
    if(errorNum==10061){
        PTC("SOCKET ERROR: Conn Refused");
    }
    else if(errorNum==10060){
        PTC("SOCKET ERROR: Timeout");
    }
    else
    {
       PTC("SOCKET ERROR NUMBER %d",errorNum);
    }
    
}
public OnSocketConnected(Handle:socket, any:trie) {

    decl String:host[100];
    GetTrieString(trie,"host",host,sizeof(host));
    
    decl String:path[2000];
    GetTrieString(trie,"path",path,sizeof(path));
    
    decl String:requestStr[1000];
    Format(requestStr, sizeof(requestStr), "GET /%s HTTP/1.0\r\nHost: %s\r\n\r\n\r\n", path, host);
 
    //Format(requestStr, sizeof(requestStr), "POST /%s HTTP/1.0\r\nHost: %s\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: %d\r\n\r\n%s\r\n", path, "mysql.ownageclan.com",strlen(data),data);
    
    SocketSend(socket, requestStr);
    
}


public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:trie)
{
    // receive another chunk
    
    new Handle:dataArray;
    GetTrieValue(trie,"data",any:dataArray);
    for(new i=0;i<dataSize;i++)
    {
       PushArrayCell(dataArray, any:receiveData[i]);
    }
}

public OnSocketDisconnected(Handle:socket, any:trie)
{
    CloseHandle(socket);
    
    new Handle:dataArray;
    GetTrieValue(trie,"data",dataArray);
    //PTC("response length:");
    
    

    new arraysize = GetArraySize(dataArray);

    formatstr[0]=0;
    new bool:foundrnrn = false;
    for(new i=0;i<arraysize-4;i++)
    {
       if(13 == GetArrayCell(dataArray, 0) &&
       10 == GetArrayCell(dataArray, 1) &&
       13 == GetArrayCell(dataArray, 2) &&
       10 == GetArrayCell(dataArray, 3))
       {
          foundrnrn = true;
          //remove the four we just found
          RemoveFromArray(dataArray,0);
          RemoveFromArray(dataArray,0);
          RemoveFromArray(dataArray,0);
          RemoveFromArray(dataArray,0);
          
          break; //beginning of array is now beginning of data
          
       }
       RemoveFromArray(dataArray,0);
    }
    
    new Function:callbackFunction;
    GetTrieValue(trie,"callback",_:callbackFunction);
    //INVALID_HANDLE = local plugin
    Call_StartFunction(INVALID_HANDLE, callbackFunction);
    Call_PushCell(trie);
    Call_PushCell(foundrnrn); //success?
    Call_Finish();
    
    CloseTrie(trie);

}
DataToString(Handle:trie, String:str[], maxlen)
{
    new Handle:dataArray;
    GetTrieValue(trie,"data",any:dataArray);
    
    //new array size
    new arraysize = GetArraySize(dataArray);
    for(new i=0;i<arraysize;i++)
    {
       Format(str,maxlen,"%s%c",formatstr, GetArrayCell(dataArray, i));
    }
}
CloseTrie(Handle:trie)
{
   //destructor
   if(trie!=INVALID_HANDLE)
   {
      new Handle:dataArray;
      GetTrieValue(trie,"data",dataArray); //close inner object
      CloseHandle(dataArray);
      CloseHandle(trie);
   }
}