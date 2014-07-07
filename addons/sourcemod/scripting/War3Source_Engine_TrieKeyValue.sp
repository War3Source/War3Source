#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Trie Key Value",
    author = "War3Source Team",
    description = "Convert between cvars and tries"
};

new Handle:Cvartrie;
new Handle:Cvararraylist; //cvar
new Handle:Cvararraylist2; //cvar definition

public OnPluginStart()
{
    RegConsoleCmd("war3",cmdWar3,"War3 internal variables and commands");
}

public bool:InitNativesForwards()
{
    Cvartrie=CreateTrie();
    Cvararraylist=CreateArray(ByteCountToCells(64));  //cvar
    Cvararraylist2=CreateArray(ByteCountToCells(1024)); //cvar desc
    PushArrayString(Cvararraylist, "ZEROTH CVAR, INVALID CVARID PASSED");
    PushArrayString(Cvararraylist2, "ZEROTH CVAR, INVALID CVARID PASSED");
    CreateNative("W3CreateCvar",NW3CreateCvar);
    CreateNative("W3GetCvar",NW3GetCvar);
    CreateNative("W3SetCvar",NW3SetCvar);
    CreateNative("W3FindCvar",NW3FindCvar);
    
    CreateNative("W3CvarList",NW3CvarList);
    CreateNative("W3GetCvarByString",NW3GetCvarByString);
    
    CreateNative("W3GetCvarActualString",NW3GetCvarActualString);
    return true;
}
public NW3CreateCvar(Handle:plugin,numParams){
    new String:cvar[64];
    new String:value[1024];
    new String:desc[1024];
    GetNativeString(1,cvar,sizeof(cvar));
    GetNativeString(2,value,sizeof(value));
    GetNativeString(3,desc,sizeof(desc));
    
    new bool:ReplaceCvars=GetNativeCell(4)>=1?true:false;
    
    if(!SetTrieString(Cvartrie,cvar,value,ReplaceCvars)){
        ThrowError("W3 Cvar %s %s already created, or creation failed",cvar,desc);
        
    }
    PushArrayString(Cvararraylist, cvar);
    PushArrayString(Cvararraylist2, desc);
    
    return GetArraySize(Cvararraylist)-1;
}

public NW3GetCvar(Handle:plugin,numParams){
    new cvarid=GetNativeCell(1);
    new String:cvarstr[64];
    GetArrayString(Cvararraylist, cvarid,cvarstr,sizeof(cvarstr));
    
    
    new String:outstr[1024];
    if(!GetTrieString(Cvartrie, cvarstr, outstr, sizeof(outstr))){
        ThrowError("Could not GET Cvar: cvarid %d",cvarid);
    }
    //PrintToServer("%s %d",outstr,cvarid);
    SetNativeString(2,outstr,GetNativeCell(3));
    
}
public NW3SetCvar(Handle:plugin,numParams){
    new cvarid=GetNativeCell(1);
    new String:cvarstr[64];
    GetArrayString(Cvararraylist, cvarid,cvarstr,sizeof(cvarstr));
    
    new String:setvalue[1024];
    GetNativeString(2,setvalue,sizeof(setvalue));
    
    new String:outstr[32];
    if(!GetTrieString(Cvartrie, cvarstr, outstr, sizeof(outstr))){
        ThrowError("Could not FIND Cvar");
    }
    else if(!SetTrieString(Cvartrie, cvarstr, setvalue)){
        ThrowError("Could not SET Cvar");
    }
}

public NW3FindCvar(Handle:plugin,numParams){
    decl String:cvarstr[64];
    GetNativeString(1,cvarstr,sizeof(cvarstr));
    return FindStringInArray(Cvararraylist, cvarstr);
}
public NW3CvarList(Handle:plugin,numParams){
    
    return _:CloneHandle(Cvararraylist);
}

public NW3GetCvarByString(Handle:plugin,numParams){
    decl String:cvarstr[64];
    GetNativeString(1,cvarstr,sizeof(cvarstr));
    
    new String:outstr[1024];
    if(!GetTrieString(Cvartrie, cvarstr, outstr, sizeof(outstr))){
        ThrowError("Could not GET Cvar %s, not in Trie, not registered?",cvarstr);
    }
    //PrintToServer("%s %d",outstr,cvarid);
    SetNativeString(2,outstr,GetNativeCell(3));
    
}
public NW3GetCvarActualString(Handle:plugin,numParams){
    new String:ret[64];
    GetArrayString(Cvararraylist,GetNativeCell(1),ret,sizeof(ret));
    SetNativeString(2,ret,GetNativeCell(3));
}




public Action:cmdWar3(client,args){
    if(client!=0&&!HasSMAccess(client,ADMFLAG_ROOT)){
        ReplyToCommand(client,"No Access. This is not a command for players. say war3menu for the main menu");
    }
    else{    
        
        new bool:pass=false;
        if(args>=1){
    
            new String:arg1[64];
            GetCmdArg(1,arg1,sizeof(arg1));
            
            if(StrEqual(arg1,"cvarlist")){
                PrintCvars(client,args>1,2);
                pass=true;
            }
            
            if (!pass&&args==2){
                SetCvar(client);
                pass=true;
            }
            if (!pass&&args==1){
                PrintCvars(client,true,1);
                pass=true;
            }
        }
        
        if(!pass){
            new String:arg0[32];
            new String:arg[32];
            GetCmdArg(0,arg0,sizeof(arg0));
            GetCmdArgString(arg, sizeof(arg));
            ReplyToCommand(client,"-----------------------------------");
            ReplyToCommand(client,"war3 <arg> ...  Unknown CMD: %s %s Args: %d",arg0,arg,args);
            ReplyToCommand(client,"    Available commands:");
            ReplyToCommand(client,"war3 cvarlist <optional prefix filter>");
            ReplyToCommand(client,"war3 <cvar> <value>");
            ReplyToCommand(client,"    Use double quotes when needed");
            ReplyToCommand(client,"-----------------------------------");
        }
    }
}
PrintCvars(client,bool:hasfilter,filterarg){

    new limit=GetArraySize(Cvararraylist);
    
    if(!hasfilter){
        ReplyToCommand(client,"LISTING ALL WAR3 INTERNAL CVARS" );
        for(new i;i<limit;i++){
            decl String:out1[32];
            decl String:out11[32];
            decl String:out2[1024];
            GetArrayString(Cvararraylist,i,out1,sizeof(out1)); //cvar
            GetTrieString(Cvartrie,out1,out11,sizeof(out11)); //value
            Format(out1,sizeof(out1),"%s \"%s\" ",out1,out11);
            //ReplyToCommand(client,"%s",out);
            if(strlen(out1)<32){
                StrCat(out1,32,"                                ");
            }
            
            GetArrayString(Cvararraylist2,i,out2,sizeof(out2)); //desc
            ReplyToCommand(client,"%s%s",out1,out2);
        }
    }
    else{
        
        new String:arg2[32];
        GetCmdArg(filterarg,arg2,sizeof(arg2));    
        ReplyToCommand(client,"LISTING ALL WAR3 INTERNAL CVARS THAT BEGINS WITH '%s'" ,arg2);
        
        for(new i;i<limit;i++){
            decl String:out1[32];
            decl String:out11[32];
            decl String:out2[1024];
            GetArrayString(Cvararraylist,i,out1,sizeof(out1)); //cvar
            
            if(StrContains(out1,arg2,false)==0){
                GetTrieString(Cvartrie,out1,out11,sizeof(out11)); //value
                Format(out1,sizeof(out1),"%s \"%s\" ",out1,out11);
                //ReplyToCommand(client,"%s",out);
                if(strlen(out1)<32){
                    StrCat(out1,32,"                                ");
                }
                
                GetArrayString(Cvararraylist2,i,out2,sizeof(out2)); //desc
                ReplyToCommand(client,"%s%s",out1,out2);
            }
        }
    }
}

SetCvar(client){
    new String:arg1[64];
    GetCmdArg(1,arg1,sizeof(arg1));
    
    new cvar=W3FindCvar(arg1);
    if(cvar==-1){
        ReplyToCommand(client,"W3CVAR \"%s\" not found, please fix/clean up your config",arg1);
        War3_LogWarning("W3CVAR (internal)  \"%s\" not found, please fix/clean up your config",arg1);
        return;
    }
    
    new String:arg2[1024];
    GetCmdArg(2,arg2,sizeof(arg2));
    
    W3SetCvar(cvar,arg2);
    
    new String:out[1024];
    W3GetCvar(cvar,out,sizeof(out));
    ReplyToCommand(client,"W3CVAR %s is now \"%s\"",arg1,out);
    
    
    return;
}