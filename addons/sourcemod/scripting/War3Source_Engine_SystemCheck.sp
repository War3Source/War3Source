//Ownz:
//THIS IS ANCIENT HISTORY, BUT DO NOT MODIFY, DO NOT DELETE FROM REPO
//THIS IS ANCIENT HISTORY, BUT DO NOT MODIFY, DO NOT DELETE FROM REPO
//THIS IS ANCIENT HISTORY, BUT DO NOT MODIFY, DO NOT DELETE FROM REPO
//THIS IS ANCIENT HISTORY, BUT DO NOT MODIFY, DO NOT DELETE FROM REPO
//THIS IS ANCIENT HISTORY, BUT DO NOT MODIFY, DO NOT DELETE FROM REPO
//THIS IS ANCIENT HISTORY, BUT DO NOT MODIFY, DO NOT DELETE FROM REPO
//THIS IS ANCIENT HISTORY, BUT DO NOT MODIFY, DO NOT DELETE FROM REPO
//THIS IS ANCIENT HISTORY, BUT DO NOT MODIFY, DO NOT DELETE FROM REPO
//THIS IS ANCIENT HISTORY, BUT DO NOT MODIFY, DO NOT DELETE FROM REPO
//THIS IS ANCIENT HISTORY, BUT DO NOT MODIFY, DO NOT DELETE FROM REPO
//THIS IS ANCIENT HISTORY, BUT DO NOT MODIFY, DO NOT DELETE FROM REPO
//THIS IS ANCIENT HISTORY, BUT DO NOT MODIFY, DO NOT DELETE FROM REPO
//THIS IS ANCIENT HISTORY, BUT DO NOT MODIFY, DO NOT DELETE FROM REPO
//THIS IS ANCIENT HISTORY, BUT DO NOT MODIFY, DO NOT DELETE FROM REPO
//THIS IS ANCIENT HISTORY, BUT DO NOT MODIFY, DO NOT DELETE FROM REPO
//THIS IS ANCIENT HISTORY, BUT DO NOT MODIFY, DO NOT DELETE FROM REPO

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

#define COREPLUGINSNUM 9

public Plugin:myinfo = 
{
    name = "War3Source - Engine - System Check",
    author = "War3Source Team",
    description = "Verify we got some necessary engines"
};

//if these plugins fail, HALT all war3 plugins
new String:coreplugins[COREPLUGINSNUM][]={
"War3Source.smx",
"War3Source_Engine_CooldownMgr",
"War3Source_Engine_PlayerTrace",
"War3Source_Engine_PlayerCollision",
"War3Source_Engine_Weapon",
"War3Source_Engine_Buff",
"War3Source_Engine_DamageSystem",
"War3Source_Engine_CooldownMgr",
"Engine_Hint"
};


new Handle:g_War3FailedFH;

public OnPluginStart()
{
    CreateTimer(2.0,TwoSecondTimer,_,TIMER_REPEAT);
    CreateTimer(0.1,TwoSecondTimer);
    DoNatives();
}
public bool:InitNativesForwards(){
    CreateNative("War3Failed",Native_War3Failed);
    g_War3FailedFH=CreateGlobalForward("War3FailedSignal",ET_Ignore,Param_String); 
    return true;
}
public Native_War3Failed(Handle:plugin,numParams)
{
    new String:str[2000];
    GetNativeString(1,str,2000);
    DoFwd_War3Failed(str);
}

DoFwd_War3Failed(String:str[]){
    Call_StartForward(g_War3FailedFH);
    Call_PushString(str);
    new dummyret;
    Call_Finish(dummyret);
}

public Action:TwoSecondTimer(Handle:h,any:a){

    for(new i=0;i<COREPLUGINSNUM;i++){
        new Handle:plug=FindPluginByFileCustom(coreplugins[i]);
        if(plug==INVALID_HANDLE){
            LogError("Could not find plugin (handle): %s",coreplugins[i]);
        }
        else{
            new PluginStatus:stat=GetPluginStatus(plug);
            if(stat!=Plugin_Running&&stat!=Plugin_Loaded){
                new String:reason[3000];
                Format(reason,sizeof(reason),"%s failed",coreplugins[i]);
                War3Failed(reason);
            }
        }    
    }
//    new String:str[64];
//    Format(str,sizeof(str),"живете зел1о, земля, 2и иже и ка3ко люди");
//DP(str);
//DP("%s",str);
}




DoNatives(){

    decl String:path[1024];
    BuildPath(Path_SM,path,sizeof(path),"configs/natives.txt");
    new Handle:file;
    file=OpenFile(path, "r");
    
    
    //new line=0;
    if(file){
        BuildPath(Path_SM,path,sizeof(path),"configs/nativeout.txt");
        new Handle:file2=OpenFile(path,"w+");
        
        
        new String:linestr[1000];
        new String:nativename[100];
        new temp;
        new result;
        while(ReadFileLine(file, linestr, sizeof(linestr)))
        {
            //PrintToServer("LINE:%s",linestr);
            
            temp=StrContains(linestr,"native ",true);
            new nativestrlen=strlen("native ");
            
            if(temp>-1 &&temp<20){ ///20 is arbitrary, makes sure it captures native in front, not a native in teh back somewhere
                result=temp+nativestrlen;
                PrintToServer("native ' at %d",result);
                temp=StrContains(linestr[result],":",true);
                if(temp>-1){
                    new temp2=StrContains(linestr[result],"(",true);
                    if(temp2>temp){
                        result+=(temp+1);
                        //PrintToServer("%s",linestr[result]);
                    }
                }
                
                new result2=StrContains(linestr[result],"(",true);
                if(result2>-1){
                    strcopy(nativename, result2+1, linestr[result]);
                
                    //PrintToServer("CreateNative('%s %d \n\n\n\n",nativename,result2);
                    WriteFileLine(file2,"MarkNativeAsOptional(\"%s\");",nativename);
                    FlushFile(file2);
                }
            }
        }    
    }
}

