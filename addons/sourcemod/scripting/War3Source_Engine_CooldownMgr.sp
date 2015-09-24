#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Cooldown Manager",
    author = "War3Source Team",
    description = "Manages Cooldowns and doesn't afraid of anything"
};

new bool:CooldownOnSpawn[MAXRACES][MAXSKILLCOUNT];
new bool:CdOnSpawnPrintOnExpire[MAXRACES][MAXSKILLCOUNT];
new Float:CooldownOnSpawnDuration[MAXRACES][MAXSKILLCOUNT];

new String:ultimateReadySound[256];
new String:abilityReadySound[256];

new Handle:g_CooldownExpiredForwardHandle;


new CooldownPointer[MAXPLAYERSCUSTOM][MAXRACES][MAXSKILLCOUNT];

enum CooldownClass
{
    Float:cexpiretime,
    cclient,
    crace,
    cskill,
    bool:cexpireonspawn,
    bool:cprintmsgonexpire,
    cnext,
}

#define MAXCOOLDOWNS 64*2
new Cooldown[MAXCOOLDOWNS][CooldownClass];

#define MAXTHREADS 2000
new Float:expireTime[MAXTHREADS];
new threadsLoaded;

public OnPluginStart()
{
    CreateTimer(0.1,DeciSecondTimer,_,TIMER_REPEAT);

}
public OnMapStart()
{
    new String:sHintSound[256];
    War3_AddSoundFolder(ultimateReadySound, sizeof(ultimateReadySound), "ult_ready.mp3");
    War3_AddSoundFolder(abilityReadySound, sizeof(abilityReadySound), "ability_refresh.mp3");
    War3_GetHintSound(sHintSound, sizeof(sHintSound));

    for(new i=0;i<MAXTHREADS;i++){
        expireTime[i]=0.0;
    }
    
    if(sHintSound[0] != '\0') {
        War3_AddCustomSound(sHintSound);
    }
    War3_AddCustomSound(abilityReadySound);
    War3_AddCustomSound(ultimateReadySound);


    ClearAllCooldowns();
}

public bool:InitNativesForwards()
{
    
    ///LIST ALL THESE NATIVES IN INTERFACE
    CreateNative("War3_CooldownMGR",Native_War3_CooldownMGR);
    CreateNative("War3_CooldownRemaining",Native_War3_CooldownRMN);
    CreateNative("War3_CooldownReset",Native_War3_CooldownReset);
    CreateNative("War3_SkillNotInCooldown",Native_War3_SkillNIC);
    CreateNative("War3_PrintSkillIsNotReady",Native_War3_PrintSkillINR);
    
    
    CreateNative("War3_RegisterDelayTracker",NWar3_RegisterDelayTracker);
    CreateNative("War3_TrackDelay",NWar3_TrackDelay);
    CreateNative("War3_TrackDelayExpired",NWar3_TrackDelayExpired);
    
    CreateNative("W3SkillCooldownOnSpawn",NW3SkillCooldownOnSpawn);
    g_CooldownExpiredForwardHandle=CreateGlobalForward("OnCooldownExpired",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
    
    return true;
}


public NWar3_RegisterDelayTracker(Handle:plugin,numParams)
{
    if(threadsLoaded<MAXTHREADS){
        return threadsLoaded++;
    }
    LogError("[W3S Engine 1] DELAY TRACKER MAXTHREADS LIMIT REACHED! return -1");
    return -1;
}
public NWar3_TrackDelay(Handle:plugin,numParams)
{
    new index=GetNativeCell(1);
    new Float:delay=GetNativeCell(2);
    expireTime[index]=GetEngineTime()+delay;
}
public NWar3_TrackDelayExpired(Handle:plugin,numParams)
{
    return GetEngineTime()>expireTime[GetNativeCell(1)];
}
    
public NW3SkillCooldownOnSpawn(Handle:plugin,numParams)
{
    new raceid=GetNativeCell(1);
    new skillid=GetNativeCell(2);
    new Float:cooldowntime=GetNativeCell(3);
    new bool:print=GetNativeCell(4);
    CooldownOnSpawn[raceid][skillid]=true;
    CdOnSpawnPrintOnExpire[raceid][skillid]=print;
    CooldownOnSpawnDuration[raceid][skillid]=cooldowntime;
}

    
    
    
    
    
    
    

    
    
    
    

    
    
    
public Native_War3_CooldownMGR(Handle:plugin,numParams)
{
    
        new client = GetNativeCell(1);
        new Float:cooldownTime= GetNativeCell(2);
        new raceid = GetNativeCell(3);
        new skillNum = GetNativeCell(4); ///can use skill numbers
        new bool:resetOnSpawn = GetNativeCell(5);
        new bool:printMsgOnExpireByTime = GetNativeCell(6);

        Internal_CreateCooldown(client,cooldownTime,raceid,skillNum,resetOnSpawn,printMsgOnExpireByTime);
    
}
public Native_War3_CooldownRMN(Handle:plugin,numParams) //cooldown remaining time
{
    if(numParams==3){
        new client = GetNativeCell(1);
        new raceid = GetNativeCell(2);
        new skillNum = GetNativeCell(3); ///can use skill numbers
        
        new index=GetCooldownIndexByCRS(client,raceid,skillNum);
        if(index>0){
            return RoundToCeil(Cooldown[index][cexpiretime]-GetEngineTime());
        }
        return _:0.0;
    }
    return -1;
}
public Native_War3_CooldownReset(Handle:plugin,numParams)
{
    if(numParams==3){
        new client = GetNativeCell(1);
        new raceid = GetNativeCell(2);
        new skillNum = GetNativeCell(3); ///can use skill numbers
        CooldownResetByCRS(client,raceid,skillNum);
    }
    return -1;
}
public Native_War3_SkillNIC(Handle:plugin,numParams) //NOT IN COOLDOWN , skill available
{
    if(numParams>=3){
        new client = GetNativeCell(1);
        new raceid = GetNativeCell(2);
        new skillNum = GetNativeCell(3); ///can use skill numbers
        new bool:printTextIfNotReady=false;
        if(numParams>3){
            printTextIfNotReady=GetNativeCell(4);
        }
        new bool:result= InternalIsSkillNotInCooldown(client,raceid,skillNum);
        if(result==false&&printTextIfNotReady){
            Internal_PrintSkillNotAvailable(GetCooldownIndexByCRS(client,raceid,skillNum));
        }
        return result;
    }
    return -1;
}
public Native_War3_PrintSkillINR(Handle:plugin,numParams)
{
    if(numParams==3){
        new client = GetNativeCell(1);
        new raceid = GetNativeCell(2);
        new skillNum = GetNativeCell(3); ///can use skill numbers
        
        
        Internal_PrintSkillNotAvailable(GetCooldownIndexByCRS(client,raceid,skillNum)); //cooldown inc
    }
    return -1;
}
    
    
    
    
public OnClientPutInServer(client){
    
}
        
ClearAllCooldowns()
{

            ///we just dump the entire linked list
    for(new i=0;i<MAXCOOLDOWNS;i++){
        //we need to "unenable" aka free each cooldown
        Cooldown[i][cexpiretime]=0.0;
        
    }
    Cooldown[0][cnext]=0;
    
    
    for(new i=1;i<=MaxClients;i++)
    {
        for(new raceid=0;raceid< MAXRACES;raceid++)
        {
            for(new skillNum=0;skillNum<MAXSKILLCOUNT;skillNum++) //strart from zero anyway
            {
                //CooldownExpireTime[i][raceid][skillNum]=0.0;
                
        
                
                CooldownPointer[i][raceid][skillNum]=0;
            }
        }
    }
}


Internal_CreateCooldown(client,Float:cooldownTime,raceid,skillNum,bool:resetOnSpawn,bool:printMsgOnExpireByTime){

    new indextouse=-1;
    new bool:createlinks=true;
    if(CooldownPointer[client][raceid][skillNum]>0){ //already has a cooldown
        indextouse=CooldownPointer[client][raceid][skillNum];
        createlinks=false;
    }
    else{
        for(new i=1;i<MAXCOOLDOWNS;i++){
            if(Cooldown[i][cexpiretime]<1.0){ //consider this one empty
                indextouse=i;
                break;
                
            }
        }
    }
    /**********************
     * this isliked a linked list
     */         
    if(indextouse==-1){
        LogError("ERROR, UNABLE TO CREATE COOLDOWN");
    }
    else{
        if(createlinks){ //if u create links again and u are already link from the prevous person, u will infinite loop
        
            Cooldown[indextouse][cnext]=Cooldown[indextouse-1][cnext]; //this next is the previous guy's next
            Cooldown[indextouse-1][cnext]=indextouse; //previous guy points to you
        }
        
        Cooldown[indextouse][cexpiretime]=GetEngineTime()+cooldownTime;
        Cooldown[indextouse][cclient]=client;
        Cooldown[indextouse][crace]=raceid;
        Cooldown[indextouse][cskill]=skillNum;
        Cooldown[indextouse][cexpireonspawn]=resetOnSpawn;
        Cooldown[indextouse][cprintmsgonexpire]=printMsgOnExpireByTime;

        CooldownPointer[client][raceid][skillNum]=indextouse;
    }
}
public Action:DeciSecondTimer(Handle:h,any:data){
    
    CheckCooldownsForExpired(false);
}
CheckCooldownsForExpired(bool:expirespawn,clientthatspawned=0)
{
    
    new Float:currenttime=GetEngineTime();
    new tempnext;
    new skippedfrom;
    
    new Handle:arraylist[MAXPLAYERSCUSTOM]; //hint messages will be attached to an arraylist
    
    for(new i=0;i<MAXCOOLDOWNS;i++){
        if(Cooldown[i][cexpiretime]>1.0) //enabled
        {
            new bool:expired;
            new bool:bytime;
            if(currenttime>Cooldown[i][cexpiretime]){
                expired=true;
                bytime=true;
            }
            else if(expirespawn&&Cooldown[i][cclient]==clientthatspawned&&Cooldown[i][cexpireonspawn]){
                expired=true;
            }
            
            
            if(expired)
            {
                //PrintToChatAll("EXPIRED");
                CooldownExpired(i, bytime);
                Cooldown[i][cexpiretime]=0.0;
                
                if(i>0){ //not front do some pointer changes, shouldnt be front anyway
                    Cooldown[skippedfrom][cnext]=Cooldown[i][cnext];
                    //PrintToChatAll("changing next at %d to %d",skippedfrom,Cooldown[i][cnext]);
                    
                    
                }
                
                //PrintToChatAll("CD expired %d %d %d",Cooldown[i][cclient],Cooldown[i][crace],Cooldown[i][cskill]);
                
                i=skippedfrom;
            }
            else{
                new client=Cooldown[i][cclient];
                new race=Cooldown[i][crace];
                new skill=Cooldown[i][cskill];
                new timeremaining=RoundToCeil(Cooldown[i][cexpiretime]-GetEngineTime());
                if(War3_GetRace(client)==Cooldown[i][crace] && War3_GetSkillLevel(client,race,skill)>0&& timeremaining<=5 && Cooldown[i][cprintmsgonexpire]==true){ //is this race, and has this skill
                    
                    if(arraylist[client]==INVALID_HANDLE){
                        arraylist[client]=CreateArray(ByteCountToCells(128));
                    }
                    new String:str[128];
                    SetTrans(client);
                    new String:skillname[32];
                    W3GetRaceSkillName(Cooldown[i][crace],Cooldown[i][cskill],skillname,sizeof(skillname));
                    Format(str,sizeof(str),"%s%s: %d",GetArraySize(arraylist[client])>0?"\n":"",skillname,timeremaining);
                    PushArrayString(arraylist[client],str);
                }
            }
        }
        tempnext=Cooldown[i][cnext];
    
        if(tempnext==0){
            //PrintToChatAll("DeciSecondTimer break because next is zero at index %d",i);
            break;
        }    
        skippedfrom=i;
        i=tempnext-1; //i will increment, decremet it first here
    }
    static bool:cleared[MAXPLAYERSCUSTOM];
    for(new client=1;client<=MaxClients;client++){
    
        if(arraylist[client]){
            new Handle:array=arraylist[client];
            new String:str[128];
            new String:newstr[128];
            new size=GetArraySize(array);
            for(new i=0;i<size;i++){
                GetArrayString(array,i,newstr,sizeof(newstr));
                StrCat(str,sizeof(str),newstr);
            }
            W3Hint(client,HINT_COOLDOWN_COUNTDOWN,4.0,str);
            CloseHandle(arraylist[client]);
            arraylist[client]=INVALID_HANDLE;
            cleared[client]=false;
        }
        else{
            if(cleared[client]==false){
                cleared[client]=true;
                W3Hint(client,HINT_COOLDOWN_COUNTDOWN,0.0,"");//CLEAR IT , so we dont have "ready" and "cooldown" of same skill at same time
            }
        }
    }
}


CooldownResetByCRS(client,raceid,skillnum){
    if(CooldownPointer[client][raceid][skillnum]>0){
        Cooldown[CooldownPointer[client][raceid][skillnum]][cexpiretime]=GetEngineTime(); ///lol
    }
}
CooldownExpired(i,bool:expiredByTimer)
{    
    new client=Cooldown[i][cclient];
    new raceid=Cooldown[i][crace];
    new skillNum=Cooldown[i][cskill];
    CooldownPointer[client][raceid][skillNum]=-1;

    if(expiredByTimer){
        if(ValidPlayer(client,true)&&Cooldown[i][cprintmsgonexpire]&& (  (War3_GetRace(client)==raceid)) ){ //if still the same race and alive
            if(War3_GetSkillLevel(client,raceid,skillNum)>0){
            
                new String:skillname[64];
                SetTrans(client);
                W3GetRaceSkillName(raceid,skillNum,skillname,sizeof(skillname));
                //{ultimate} is just an argument, we fill it in with skillname
                new String:str[128];
                Format(str,sizeof(str),"%T","{ultimate} Is Ready",client,skillname);
                W3Hint(client,HINT_COOLDOWN_EXPIRED,4.0,str);
                W3Hint(client,HINT_COOLDOWN_NOTREADY,0.0,""); //if something is ready, force erase the not ready
            
                EmitSoundToAllAny( War3_IsSkillUltimate(raceid,skillNum)?ultimateReadySound:abilityReadySound , client);
            }
        }
    }

    Call_StartForward(g_CooldownExpiredForwardHandle);
    Call_PushCell(client);
    Call_PushCell(raceid);
    Call_PushCell(skillNum);
    Call_PushCell(expiredByTimer);
    new result;
    Call_Finish(result); //this will be returned to ?
    
    //DP("expired");
}


public bool:InternalIsSkillNotInCooldown(client,raceid,skillNum){
    new index=GetCooldownIndexByCRS(client,raceid,skillNum);
    if(index>0){
        return false; //has record = in cooldown
    }
    return true; //no cooldown record
}
GetCooldownIndexByCRS(client,raceid,skillNum){
    
    return CooldownPointer[client][raceid][skillNum];

}

public Internal_PrintSkillNotAvailable(cooldownindex){
    new client=Cooldown[cooldownindex][cclient];
    new race=Cooldown[cooldownindex][crace];
    new skill=Cooldown[cooldownindex][cskill];
    if(ValidPlayer(client,true)){
        new String:skillname[64];
        SetTrans(client);
        W3GetRaceSkillName(race,skill,skillname,sizeof(skillname));
        W3Hint(client,HINT_COOLDOWN_NOTREADY,2.5,"%T","{skill} Is Not Ready. {amount} Seconds Remaining",client,skillname,War3_CooldownRemaining(client,race,skill));

    }
}

public OnWar3EventSpawn(client){
    

    CheckCooldownsForExpired(true,client);

    new race=War3_GetRace(client);
    for(new i=1;i<MAXSKILLCOUNT;i++){
        if(CooldownOnSpawn[race][i]){ //only his race
            
            Internal_CreateCooldown(client,CooldownOnSpawnDuration[race][i],race,i,false,CdOnSpawnPrintOnExpire[race][i]);
        }
        
    }
}
