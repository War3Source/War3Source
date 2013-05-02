#pragma dynamic 10000
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Race Class",
    author = "War3Source Team",
    description = "Information about races"
};

new totalRacesLoaded=0;  ///USE raceid=1;raceid<=GetRacesLoaded();raceid++ for looping
///race instance variables
//RACE ID = index of [MAXRACES], raceid 1 is raceName[1][32]

new String:raceName[MAXRACES][32];
new String:raceShortname[MAXRACES][16];
new bool:raceTranslated[MAXRACES];
new bool:ignoreRaceEnd; ///dont do anything on CreateRaceEnd cuz this its already done once

//zeroth skill is NOT  used
new raceSkillCount[MAXRACES];
new String:raceSkillName[MAXRACES][MAXSKILLCOUNT][32];
new String:raceSkillDescription[MAXRACES][MAXSKILLCOUNT][512];
new raceSkillDescReplaceNum[MAXRACES][MAXSKILLCOUNT];
new String:raceSkillDescReplace[MAXRACES][MAXSKILLCOUNT][5][64]; ///MAX 5 params for replacement //64 string length
new bool:skillTranslated[MAXRACES][MAXSKILLCOUNT];

new String:raceString[MAXRACES][RaceString][512];
new String:raceSkillString[MAXRACES][MAXSKILLCOUNT][SkillString][512];

enum SkillRedirect
{
    genericskillid,
}
new bool:SkillRedirected[MAXRACES][MAXSKILLCOUNT];
new SkillRedirectedToSkill[MAXRACES][MAXSKILLCOUNT];

new bool:skillIsUltimate[MAXRACES][MAXSKILLCOUNT];
new skillMaxLevel[MAXRACES][MAXSKILLCOUNT];
new skillProp[MAXRACES][MAXSKILLCOUNT][W3SkillProp];

new MinLevelCvar[MAXRACES];
new AccessFlagCvar[MAXRACES];
new RaceOrderCvar[MAXRACES];
new RaceFlagsCvar[MAXRACES];
new RestrictItemsCvar[MAXRACES];
new RestrictLimitCvar[MAXRACES][2];

new Handle:m_MinimumUltimateLevel;

new bool:racecreationended=true;
new String:creatingraceshortname[16];

new raceCell[MAXRACES][ENUM_RaceObject];


//END race instance variables

public OnPluginStart()
{
    //silence error
    skillProp[0][0][0]=0;
    m_MinimumUltimateLevel=CreateConVar("war3_minimumultimatelevel","6");
}


public bool:InitNativesForwards()
{
    
    CreateNative("War3_CreateNewRace",NWar3_CreateNewRace);
    CreateNative("War3_AddRaceSkill",NWar3_AddRaceSkill);
    
    CreateNative("War3_CreateNewRaceT",NWar3_CreateNewRaceT);
    CreateNative("War3_AddRaceSkillT",NWar3_AddRaceSkillT);
    
    CreateNative("War3_CreateGenericSkill",NWar3_CreateGenericSkill);
    CreateNative("War3_UseGenericSkill",NWar3_UseGenericSkill);
    CreateNative("W3_GenericSkillLevel",NW3_GenericSkillLevel);
    
    CreateNative("War3_CreateRaceEnd",NWar3_CreateRaceEnd);
    
    
    
    
    CreateNative("War3_GetRaceName",Native_War3_GetRaceName);
    CreateNative("War3_GetRaceShortname",Native_War3_GetRaceShortname);
    CreateNative("W3GetRaceString",NW3GetRaceString);
    
    
    CreateNative("War3_GetRaceIDByShortname",NWar3_GetRaceIDByShortname);
    CreateNative("War3_GetRacesLoaded",NWar3_GetRacesLoaded);
    CreateNative("W3GetRaceMaxLevel",NW3GetRaceMaxLevel);
    
    CreateNative("War3_GetRaceSkillCount",NWar3_GetRaceSkillCount);
    CreateNative("War3_IsSkillUltimate",NWar3_IsSkillUltimate);
    CreateNative("W3GetRaceSkillName",NW3GetRaceSkillName);
    CreateNative("W3GetRaceSkillDesc",NW3GetRaceSkillDesc);
    
    CreateNative("W3GetRaceOrder",NW3GetRaceOrder);
    CreateNative("W3RaceHasFlag",NW3RaceHasFlag);
    
    CreateNative("W3GetRaceAccessFlagStr",NW3GetRaceAccessFlagStr);
    CreateNative("W3GetRaceItemRestrictionsStr",NW3GetRaceItemRestrictionsStr);
    CreateNative("W3GetRaceMinLevelRequired",NW3GetRaceMinLevelRequired);
    CreateNative("W3GetRaceMaxLimitTeam",NW3GetRaceMaxLimitTeam);
    CreateNative("W3GetRaceMaxLimitTeamCvar",NW3GetRaceMaxLimitTeamCvar);
    CreateNative("W3GetRaceSkillMaxLevel",NW3GetRaceSkillMaxLevel);
    
    CreateNative("W3GetRaceList",NW3GetRaceList);
    
    CreateNative("W3GetMinUltLevel",NW3GetMinUltLevel);
    
    CreateNative("W3IsRaceTranslated",NW3IsRaceTranslated);
    
    CreateNative("W3GetRaceCell",NW3GetRaceCell);
    CreateNative("W3SetRaceCell",NW3SetRaceCell);
    return true;
}


public NWar3_CreateNewRace(Handle:plugin,numParams){
    
    
    decl String:name[64],String:shortname[16];
    GetNativeString(1,name,sizeof(name));
    GetNativeString(2,shortname,sizeof(shortname));
    
    War3_LogInfo("add race %s %s",name,shortname);
    
    return CreateNewRace(name,shortname);
    
}


public NWar3_AddRaceSkill(Handle:plugin,numParams){
    
    
    
    new raceid=GetNativeCell(1);
    if(raceid>0){
        new String:skillname[32];
        new String:skilldesc[2001];
        GetNativeString(2,skillname,sizeof(skillname));
        GetNativeString(3,skilldesc,sizeof(skilldesc));
        new bool:isult=GetNativeCell(4);
        new tmaxskilllevel=GetNativeCell(5);
        
        War3_LogInfo("add skill %s %s",skillname,skilldesc);
        
        return AddRaceSkill(raceid,skillname,skilldesc,isult,tmaxskilllevel);
    }
    return 0;
}

//translated
public NWar3_CreateNewRaceT(Handle:plugin,numParams){
    
    
    
    decl String:name[64],String:shortname[32];
    GetNativeString(1,shortname,sizeof(shortname));
    new newraceid=CreateNewRace(name,shortname);
    if(newraceid)
    {
        raceTranslated[newraceid]=true;
        new String:buf[64];
        Format(buf,sizeof(buf),"w3s.race.%s.phrases",shortname);
        LoadTranslations(buf);
    }
    return newraceid;
    
}
//translated
public NWar3_AddRaceSkillT(Handle:plugin,numParams){
    
    
    new raceid=GetNativeCell(1);
    if(raceid>0)
    {
        new String:skillname[32];
        new String:skilldesc[1]; //DUMMY
        GetNativeString(2,skillname,sizeof(skillname));
        new bool:isult=GetNativeCell(3);
        new tmaxskilllevel=GetNativeCell(4);
        
        
        War3_LogInfo("add skill T %d %s",raceid,skillname);
        
        new newskillnum=AddRaceSkill(raceid,skillname,skilldesc,isult,tmaxskilllevel);
        skillTranslated[raceid][newskillnum]=true;
        
        if(ignoreRaceEnd==false){
            for(new arg=5;arg<=numParams;arg++){
                
                GetNativeString(arg,raceSkillDescReplace[raceid][newskillnum][raceSkillDescReplaceNum[raceid][newskillnum]],64);
                raceSkillDescReplaceNum[raceid][newskillnum]++;
            }
        }
        
        return newskillnum;
    }
    return 0;//failed
}

public NWar3_CreateRaceEnd(Handle:plugin,numParams){
    War3_LogInfo("race end %d",GetNativeCell(1));
    CreateRaceEnd(GetNativeCell(1));
}
///this is get raceid, not NAME!
public Native_War3_GetRaceByShortname(Handle:plugin,numParams)
{
    new String:short_lookup[16];
    GetNativeString(1,short_lookup,sizeof(short_lookup));
    new RacesLoaded = GetRacesLoaded();
    for(new x=1;x<=RacesLoaded;x++)
    {
        
        new String:short_name[16];
        GetRaceShortname(x,short_name,sizeof(short_name));
        if(StrEqual(short_name,short_lookup,false))
        {
            return x;
        }
    }
    return 0;
}

public Native_War3_GetRaceName(Handle:plugin,numParams)
{
    new race=GetNativeCell(1);
    new bufsize=GetNativeCell(3);
    if(race>-1 && race<=GetRacesLoaded()) //allow "No Race"
    {
        new String:race_name[64];
        GetRaceName(race,race_name,sizeof(race_name));
        SetNativeString(2,race_name,bufsize);
    }
}
public Native_War3_GetRaceShortname(Handle:plugin,numParams)
{
    new race=GetNativeCell(1);
    new bufsize=GetNativeCell(3);
    if(race>=1 && race<=GetRacesLoaded())
    {
        new String:race_shortname[64];
        GetRaceShortname(race,race_shortname,sizeof(race_shortname));
        SetNativeString(2,race_shortname,bufsize);
    }
}
public NWar3_GetRacesLoaded(Handle:plugin,numParams){
    return GetRacesLoaded();
}

public NW3GetRaceMaxLevel(Handle:plugin,numParams)
{
    return GetRaceMaxLevel(GetNativeCell(1));
}


public NWar3_GetRaceSkillCount(Handle:plugin,numParams)
{
    return GetRaceSkillCount(GetNativeCell(1));
}
public NWar3_IsSkillUltimate(Handle:plugin,numParams)
{
    return IsSkillUltimate(GetNativeCell(1),GetNativeCell(2));
}

public NW3GetRaceString(Handle:plugin,numParams)
{
    new race=GetNativeCell(1);
    new RaceString:racestringid=GetNativeCell(2);
    
    new String:longbuf[1000];
    Format(longbuf,sizeof(longbuf),raceString[race][RaceString:racestringid]);
    SetNativeString(3,longbuf,GetNativeCell(4));
}
public NW3GetRaceSkillString(Handle:plugin,numParams)
{
    new race=GetNativeCell(1);
    new skill=GetNativeCell(2);
    new SkillString:raceskillstringid=GetNativeCell(3);
    
    
    new String:longbuf[1000];
    Format(longbuf,sizeof(longbuf),raceSkillString[race][skill][raceskillstringid]);
    SetNativeString(4,longbuf,GetNativeCell(5));
}

public NW3GetRaceSkillName(Handle:plugin,numParams)
{
    new race=GetNativeCell(1);
    new skill=GetNativeCell(2);
    new maxlen=GetNativeCell(4);
    
    if(race<1||race>War3_GetRacesLoaded()){
        ThrowNativeError(1,"bad race %d",race);
    }
    if(skill<1||skill>War3_GetRaceSkillCount(race)){
        ThrowNativeError(1,"bad skillid %d",skill);
    }
    new String:buf[32];
    GetRaceSkillName(race,skill,buf,sizeof(buf));
    SetNativeString(3,buf,maxlen);
}
public NW3GetRaceSkillDesc(Handle:plugin,numParams)
{
    new race=GetNativeCell(1);
    new skill=GetNativeCell(2);
    new maxlen=GetNativeCell(4);
    
    new String:longbuf[1000];
    GetRaceSkillDesc(race,skill,longbuf,sizeof(longbuf));
    SetNativeString(3,longbuf,maxlen);
}
public NWar3_GetRaceIDByShortname(Handle:plugin,numParams)
{
    new String:shortname[32];
    GetNativeString(1,shortname,sizeof(shortname));
    return GetRaceIDByShortname(shortname);
}
public NW3GetRaceAccessFlagStr(Handle:plugin,numParams)
{
    new String:buf[32];
    
    new raceid=GetNativeCell(1);
    W3GetCvar(AccessFlagCvar[raceid],buf,sizeof(buf));
    SetNativeString(2,buf,GetNativeCell(3));
    
}
public NW3GetRaceOrder(Handle:plugin,numParams)
{
    new raceid=GetNativeCell(1);
    //DP("getraceorder race %d cvar %d",raceid,RaceOrderCvar[raceid]);
    return W3GetCvarInt(RaceOrderCvar[raceid]);
    
}
public NW3RaceHasFlag(Handle:plugin,numParams)
{
    new raceid=GetNativeCell(1);
    new String:buf[1000];
    W3GetCvar(RaceFlagsCvar[raceid],buf,sizeof(buf));
    
    new String:flagsearch[32];
    GetNativeString(2,flagsearch,sizeof(flagsearch));
    return (StrContains(buf,flagsearch)>-1);
}
public NW3GetRaceList(Handle:plugin,numParams)
{
    new listcount=0;
    new RacesLoaded = War3_GetRacesLoaded();
    new Handle:racesAvailable = CreateArray(1); //1 cell
    
    for(new raceid = 1; raceid <= RacesLoaded; raceid++){
        
        if(!W3RaceHasFlag(raceid,"hidden"))
        {
            PushArrayCell(racesAvailable, raceid);
            listcount++;
        }
    }
    new racelist[MAXRACES];
    SortADTArrayCustom(racesAvailable, SortRacesByRaceOrder);
    for(new i = 0; i < listcount; i++)
    {
        racelist[i] = GetArrayCell(racesAvailable, i);
    }
    CloseHandle(racesAvailable);
    
    SetNativeArray(1, racelist, MAXRACES);
    return listcount;
}
public NW3GetRaceItemRestrictionsStr(Handle:plugin,numParams)
{
    
    new raceid=GetNativeCell(1);
    new String:buf[64];
    W3GetCvar(RestrictItemsCvar[raceid],buf,sizeof(buf));
    SetNativeString(2,buf,GetNativeCell(3));
}

public NW3GetRaceMaxLimitTeam(Handle:plugin,numParams)
{
    new raceid=GetNativeCell(1);
    if(raceid>0){
        
        new team=GetNativeCell(2);
        if(team==TEAM_T||team==TEAM_RED){
            return W3GetCvarInt(RestrictLimitCvar[raceid][0]);
        }
        if(team==TEAM_CT||team==TEAM_BLUE){
            return W3GetCvarInt(RestrictLimitCvar[raceid][1]);
        }
    }
    return 99;
}
public NW3GetRaceMaxLimitTeamCvar(Handle:plugin,numParams)
{
    new raceid=GetNativeCell(1);
    if(raceid>0){
        
        new team=GetNativeCell(2);
        if(team==TEAM_T||team==TEAM_RED){
            return RestrictLimitCvar[raceid][0];
        }
        if(team==TEAM_CT||team==TEAM_BLUE){
            return RestrictLimitCvar[raceid][1];
        }
    }
    return -1;
}
public NW3GetRaceMinLevelRequired(Handle:plugin,numParams){
    return W3GetCvarInt(MinLevelCvar[GetNativeCell(1)]);
}
public NW3GetRaceSkillMaxLevel(Handle:plugin,numParams){
    return GetRaceSkillMaxLevel(GetNativeCell(1),GetNativeCell(2));
}
public NW3GetMinUltLevel(Handle:plugin,numParams){
    return GetConVarInt(m_MinimumUltimateLevel);
}
public NW3IsRaceTranslated(Handle:plugin,numParams){
    return raceTranslated[GetNativeCell(1)];
}
public NW3SetRaceCell(Handle:plugin,numParams){
    return raceCell[GetNativeCell(1)][GetNativeCell(2)]=GetNativeCell(3);
}
public NW3GetRaceCell(Handle:plugin,numParams){
    return raceCell[GetNativeCell(1)][GetNativeCell(2)];
}









new genericskillcount=0;

//how many skills can use a generic skill, limited for memory
#define MAXCUSTOMERRACES 32
enum GenericSkillClass
{
    String:cskillname[32], 
    redirectedfromrace[MAXCUSTOMERRACES], //theset start from 0!!!!
    redirectedfromskill[MAXCUSTOMERRACES],
    redirectedcount, //how many races are using this generic skill, first is 1, loop from 1 to <=redirected count
    Handle:raceskilldatahandle[MAXCUSTOMERRACES], //handle the customer races passed us
}
//55 generic skills
new GenericSkill[55][GenericSkillClass];
public NWar3_CreateGenericSkill(Handle:plugin,numParams){
    new String:tempgenskillname[32];
    GetNativeString(1,tempgenskillname,32);
    
    //find existing
    for(new i=1;i<=genericskillcount;i++){
        
        if(StrEqual(tempgenskillname,GenericSkill[i][cskillname])){
            return i;
        }
    }
    
    //no existing found, add 
    genericskillcount++;
    GetNativeString(1,GenericSkill[genericskillcount][cskillname],32);
    return genericskillcount;
}
public NWar3_UseGenericSkill(Handle:plugin,numParams){
    new raceid=GetNativeCell(1);
    new String:genskillname[32];
    GetNativeString(2,genskillname,sizeof(genskillname));
    new Handle:genericSkillData=Handle:GetNativeCell(3);
    //start from 1
    for(new i=1;i<=genericskillcount;i++){
        //DP("1 %s %s ]",genskillname,GenericSkill[i][cskillname]);
        if(StrEqual(genskillname,GenericSkill[i][cskillname])){
            //DP("2");
            if(raceid>0){
                
                
                
                //DP("3");
                new String:raceskillname[2001];
                new String:raceskilldesc[2001];
                GetNativeString(4,raceskillname,sizeof(raceskillname));
                GetNativeString(5,raceskilldesc,sizeof(raceskilldesc));
                
                new bool:istranaslated=GetNativeCell(6);
                
                //native War3_UseGenericSkill(raceid,String:gskillname[],Handle:genericSkillData,String:yourskillname[],String:untranslatedSkillDescription[],bool:translated=false,bool:isUltimate=false,maxskilllevel=DEF_MAX_SKILL_LEVEL,any:...);
                
                new bool:isult=GetNativeCell(7);
                new tmaxskilllevel=GetNativeCell(8);
                
                new newskillnum;
                newskillnum    = AddRaceSkill(raceid,raceskillname,raceskilldesc,isult,tmaxskilllevel);
                if(istranaslated){
                    skillTranslated[raceid][newskillnum]=true;    
                }
                
                //check that the data handle isnt leaking
                new genericcustomernumber=GenericSkill[i][redirectedcount];
                for(new j=0;j<=genericcustomernumber;j++){
                    if(
                    GenericSkill[i][redirectedfromrace][j]==raceid
                    &&
                    GenericSkill[i][redirectedfromskill][j]==newskillnum
                    ){
                        if(GenericSkill[i][raceskilldatahandle][j]!=INVALID_HANDLE && GenericSkill[i][raceskilldatahandle][j] !=genericSkillData){
                            //DP("ERROR POSSIBLE HANDLE LEAK, NEW GENERIC SKILL DATA HANDLE PASSED, CLOSING OLD GENERIC DATA HANDLE");
                            CloseHandle(GenericSkill[i][raceskilldatahandle][j]);
                            GenericSkill[i][raceskilldatahandle][j]=genericSkillData;
                        }    
                    }
                    
                }
                
                
                //first time creating the race
                if(ignoreRaceEnd==false)
                {
                    //variable args start at 8
                    for(new arg=9;arg<=numParams;arg++){
                        
                        GetNativeString(arg,raceSkillDescReplace[raceid][newskillnum][raceSkillDescReplaceNum[raceid][newskillnum]],64);
                        raceSkillDescReplaceNum[raceid][newskillnum]++;
                    }
                    
                    SkillRedirected[raceid][newskillnum]=true;
                    SkillRedirectedToSkill[raceid][newskillnum]=i;
                    
                    
                    GenericSkill[i][raceskilldatahandle][genericcustomernumber]=genericSkillData;
                    GenericSkill[i][redirectedfromrace][GenericSkill[i][redirectedcount]]=raceid;
                    
                    GenericSkill[i][redirectedfromskill][GenericSkill[i][redirectedcount]]=newskillnum;
                    GenericSkill[i][redirectedcount]++;
                    //DP("FOUND GENERIC SKILL %d, real skill id for race %d",i,newskillnum);
                }
                
                return newskillnum;
                
            }
        }
    }
    War3_LogError("NO GENERIC SKILL FOUND");
    return 0;
}
public NW3_GenericSkillLevel(Handle:plugin,numParams){
    
    new client=GetNativeCell(1);
    new genericskill=GetNativeCell(2);
    new count=GenericSkill[genericskill][redirectedcount];
    new found=0;
    new level=0;
    new reallevel=0;
    new customernumber=0;
    new clientrace=War3_GetRace(client);
    for(new i=0;i<count;i++){
        if(clientrace==GenericSkill[genericskill][redirectedfromrace][i]){
            level = War3_GetSkillLevel( client, GenericSkill[genericskill][redirectedfromrace][i], GenericSkill[genericskill][redirectedfromskill][i]);
            if(level)
            { 
                found++;
                reallevel=level;
                customernumber=i;
            }
        }
    }
    if(found>1){
        War3_LogError("ERR FOUND MORE THAN 1 GERNIC SKILL MATCH");
        return 0;
    }
    if(found){
        SetNativeCellRef(3,GenericSkill[genericskill][raceskilldatahandle][customernumber]);
        if(numParams>=4){
            SetNativeCellRef(4, GenericSkill[genericskill][redirectedfromrace][customernumber]);
        }
        if(numParams>=5){
            SetNativeCellRef(5, GenericSkill[genericskill][redirectedfromskill][customernumber]);
        }
    }
    return reallevel;
    
}


CreateNewRace(String:tracename[]  ,  String:traceshortname[]){
    
    
    
    if(RaceExistsByShortname(traceshortname)){
        new oldraceid=GetRaceIDByShortname(traceshortname);
        //PrintToServer("Race already exists: %s, returning old raceid %d",traceshortname,oldraceid);
        ignoreRaceEnd=true;
        return oldraceid;
    }
    
    if(totalRacesLoaded+1==MAXRACES){ //make sure we didnt reach our race capacity limit
        LogError("MAX RACES REACHED, CANNOT REGISTER %s %s",tracename,traceshortname);
        return 0;
    }
    
    if(racecreationended==false){
        new String:error[512];
        Format(error,sizeof(error),"CreateNewRace was called before previous race creation was ended!!! first race not ended: %s second race: %s ",creatingraceshortname,traceshortname);
        War3Failed(error);
    }
    
    racecreationended=false;
    Format(creatingraceshortname,sizeof(creatingraceshortname),"%s",traceshortname);
    
    //first race registering, fill in the  zeroth race along
    if(totalRacesLoaded==0){
        for(new i=0;i<MAXSKILLCOUNT;i++){
            Format(raceSkillName[totalRacesLoaded][i],31,"ZEROTH RACE SKILL");
            Format(raceSkillDescription[totalRacesLoaded][i],2000,"ZEROTH RACE SKILL DESCRIPTION");
            
        }
        Format(raceName[totalRacesLoaded],31,"No Race");
    }
    
    
    totalRacesLoaded++;
    new traceid=totalRacesLoaded;
    
    strcopy(raceName[traceid], 31, tracename);
    strcopy(raceShortname[traceid], 16, traceshortname);
    
    //make all skills zero so we can easily debug
    for(new i=0;i<MAXSKILLCOUNT;i++){
        Format(raceSkillName[traceid][i],31,"NO SKILL DEFINED %d",i);
        Format(raceSkillDescription[traceid][i],2000,"NO SKILL DESCRIPTION DEFINED %d",i);
    }
    
    return traceid; //this will be the new race's id / index
}

GetRacesLoaded(){
    return  totalRacesLoaded;
}
IsSkillUltimate(raceid,skill){
    return skillIsUltimate[raceid][skill];
}
GetRaceSkillMaxLevel(raceid,skill){
    return skillMaxLevel[raceid][skill];
}
GetRaceName(raceid,String:retstr[],maxlen){
    
    if(raceTranslated[raceid]){
        new String:buf[64];
        new String:longbuf[1000];
        Format(buf,sizeof(buf),"%s_RaceName",raceShortname[raceid]);
        Format(longbuf,sizeof(longbuf),"%T",buf,GetTrans());
        return strcopy(retstr, maxlen,longbuf);
    }
    new num=strcopy(retstr, maxlen, raceName[raceid]);
    return num;
}
GetRaceShortname(raceid,String:retstr[],maxlen){
    new num=strcopy(retstr, maxlen, raceShortname[raceid]);
    return num;
}

GetRaceSkillName(raceid,skillindex,String:retstr[],maxlen){
    if(skillTranslated[raceid][skillindex]){
        new String:buf[64];
        new String:longbuf[512];
        
        Format(buf,sizeof(buf),"%s_skill_%s",raceShortname[raceid],raceSkillName[raceid][skillindex]);
        Format(longbuf,sizeof(longbuf),"%T",buf,GetTrans());
        return strcopy(retstr, maxlen,longbuf);
    }
    
    new num=strcopy(retstr, maxlen, raceSkillName[raceid][skillindex]);
    return num;
}

GetRaceSkillDesc(raceid,skillindex,String:retstr[],maxlen){
    if(skillTranslated[raceid][skillindex]){
        new String:buf[64];
        new String:longbuf[512]; 
        Format(buf,sizeof(buf),"%s_skill_%s_desc",raceShortname[raceid],raceSkillName[raceid][skillindex]);
        Format(longbuf,sizeof(longbuf),"%T",buf,GetTrans());
        
        new strreplaces=raceSkillDescReplaceNum[raceid][skillindex];
        for(new i=0;i<strreplaces;i++){
            new String:find[10];
            Format(find,sizeof(find),"#%d#",i+1);
            ReplaceString(longbuf,sizeof(longbuf),find,raceSkillDescReplace[raceid][skillindex][i]);
        }
        
        return strcopy(retstr, maxlen,longbuf);
    }
    
    new num=strcopy(retstr, maxlen, raceSkillDescription[raceid][skillindex]);
    return num;
}

GetRaceSkillCount(raceid){
    if(raceid>0){
        return raceSkillCount[raceid];
    }
    else{
        LogError("bad race ID %d",raceid);
        ThrowNativeError(15,"bad race ID %d",raceid);
    }
    return 0;
}

stock GetRaceSkillNonUltimateCount(raceid){
    new num;
    new skillcount = GetRaceSkillCount(raceid);
    for(new i=1;i<=skillcount;i++){
        if(!IsSkillUltimate(raceid,i)) //regular skill
        {
            num++;
        }
    }
    return num;
}
stock GetRaceSkillIsUltimateCount(raceid){
    new num;
    new SkillCount = GetRaceSkillCount(raceid);
    for(new i=1;i<=SkillCount;i++){
        if(IsSkillUltimate(raceid,i)) //regular skill
        {
            num++;
        }
    }
    return num;
}
//gets max level based on the max levels of its skills
GetRaceMaxLevel(raceid){
    new num=0;
    new SkillCount = GetRaceSkillCount(raceid);
    for(new skill=1;skill<=SkillCount;skill++){
        num+=skillMaxLevel[raceid][skill];
    }
    return num;
}





////we add skill or ultimate here, but we have to define if its a skill or ultimate we are adding
AddRaceSkill(raceid,String:skillname[],String:skilldescription[],bool:isUltimate,tmaxskilllevel){
    if(raceid>0){
        //ok is it an existing skill?
        //new String:existingskillname[64];
        new SkillCount = GetRaceSkillCount(raceid);
        for(new i=1;i<=SkillCount;i++){
            //GetRaceSkillName(raceid,i,existingskillname,sizeof(existingskillname));
            if(StrEqual(skillname,raceSkillName[raceid][i],false)){ ////need raw skill name, because of translations
                //PrintToServer("Skill exists %s, returning old skillid %d",skillname,i);
                
                return i;
            }
        }
        //if(ignoreRaceEnd){
        //    W3Log("%s skill not found, REadding for race %d",skillname,raceid);
        //}
        
        //not existing, will it exceeded maximum?
        if(raceSkillCount[raceid]+1==MAXSKILLCOUNT){
            LogError("SKILL LIMIT FOR RACE %d reached!",raceid);
            return -1;
        }
        
        
        raceSkillCount[raceid]++;
        
        strcopy(raceSkillName[raceid][raceSkillCount[raceid]], 32, skillname);
        strcopy(raceSkillDescription[raceid][raceSkillCount[raceid]], 2000, skilldescription);
        skillIsUltimate[raceid][raceSkillCount[raceid]]=isUltimate;
        
        skillMaxLevel[raceid][raceSkillCount[raceid]]=tmaxskilllevel;
        
        //We remove all dependencys(atm there aren't any but we need to call this to apply our default value)
        War3_RemoveDependency(raceid,raceSkillCount[raceid]);
        
        return raceSkillCount[raceid]; //return their actual skill number
        
    }
    return 0;
}


CreateRaceEnd(raceid){
    if(raceid>0){
        racecreationended=true;
        Format(creatingraceshortname,sizeof(creatingraceshortname),"");
        ///now we put shit into the database and create cvars
        if(!ignoreRaceEnd&&raceid>0)
        {
            new String:shortname[16];
            GetRaceShortname(raceid,shortname,sizeof(shortname));
            
            new String:cvarstr[64];
            Format(cvarstr,sizeof(cvarstr),"%s_minlevel",shortname);
            MinLevelCvar[raceid]=W3CreateCvar(cvarstr,"0","Minimum level for race");
            
            Format(cvarstr,sizeof(cvarstr),"%s_accessflag",shortname);
            AccessFlagCvar[raceid]=W3CreateCvar(cvarstr,"0","Admin access flag required for race");
            
            Format(cvarstr,sizeof(cvarstr),"%s_raceorder",shortname);
            new String:buf[16];
            Format(buf,sizeof(buf),"%d",raceid*100);
            RaceOrderCvar[raceid]=W3CreateCvar(cvarstr,buf,"This race's Race Order on changerace menu");
            
            Format(cvarstr,sizeof(cvarstr),"%s_flags",shortname);
            RaceFlagsCvar[raceid]=W3CreateCvar(cvarstr,"","This race's flags, ie 'hidden,etc");
            
            Format(cvarstr,sizeof(cvarstr),"%s_restrict_items",shortname);
            RestrictItemsCvar[raceid]=W3CreateCvar(cvarstr,"","Which items to restrict for people on this race. Separate by comma, ie 'claw,orb'");
            
            Format(cvarstr,sizeof(cvarstr),"%s_team%d_limit",shortname,1);
            RestrictLimitCvar[raceid][0]=W3CreateCvar(cvarstr,"99","How many people can play this race on team 1 (RED/T)");
            Format(cvarstr,sizeof(cvarstr),"%s_team%d_limit",shortname,2);
            RestrictLimitCvar[raceid][1]=W3CreateCvar(cvarstr,"99","How many people can play this race on team 2 (BLU/CT)");
            
            new temp;
            Format(cvarstr,sizeof(cvarstr),"%s_restrictclass",shortname);
            temp=W3CreateCvar(cvarstr,"","Which classes are not allowed to play this race? Separate by comma. MAXIMUM OF 2!! list: scout,sniper,soldier,demoman,medic,heavy,pyro,spy,engineer");
            W3SetRaceCell(raceid,ClassRestrictionCvar,temp);
            
            Format(cvarstr,sizeof(cvarstr),"%s_category",shortname);
            W3SetRaceCell(raceid,RaceCategorieCvar,W3CreateCvar(cvarstr,"default","Determines in which Category the race should be displayed(if cats are active)"));
            
        }
        ignoreRaceEnd=false;
    }
}




bool:RaceExistsByShortname(String:shortname[]){
    new String:buffer[16];
    
    new RacesLoaded = GetRacesLoaded();
    for(new raceid=1;raceid<=RacesLoaded;raceid++){
        GetRaceShortname(raceid,buffer,sizeof(buffer));
        if(StrEqual(shortname, buffer, false)){
            return true;
        }
    }
    return false;
}
GetRaceIDByShortname(String:shortname[]){
    new String:buffer[16];
    
    new RacesLoaded =GetRacesLoaded();
    for(new raceid=1;raceid<=RacesLoaded;raceid++){
        GetRaceShortname(raceid,buffer,sizeof(buffer));
        if(StrEqual(shortname, buffer, false)){
            return raceid;
        }
    }
    return -1;
}
public SortRacesByRaceOrder(race1, race2, Handle:races, Handle:hndl)
{
    if(race1 > 0 && race2 > 0)
    {
        new order1 = W3GetRaceOrder(race1);
        new order2 = W3GetRaceOrder(race2);
        if(order1 < order2)
        {
            return -1;
        } 
        else if(order2 < order1)
        {
            return 1;
        }
    }
    return 0;
}


