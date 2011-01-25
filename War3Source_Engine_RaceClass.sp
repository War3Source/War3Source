

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


new totalRacesLoaded=0;  ///USE raceid=1;raceid<=GetRacesLoaded();raceid++ for looping
///race instance variables
//RACE ID = index of [MAXRACES], raceid 1 is raceName[1][32]

new String:raceName[MAXRACES][32];
new String:raceShortname[MAXRACES][16];
new bool:raceTranslated[MAXRACES];
new bool:ignoreRaceEnd; ///dont do anything on CreateRaceEnd cuz this its already done once

//zeroth skill is used
new raceSkillCount[MAXRACES];
new String:raceSkillName[MAXRACES][MAXSKILLCOUNT][32];
new String:raceSkillDescription[MAXRACES][MAXSKILLCOUNT][512];
new raceSkillDescReplaceNum[MAXRACES][MAXSKILLCOUNT];
new String:raceSkillDescReplace[MAXRACES][MAXSKILLCOUNT][5][64]; ///MAX 5 params for replacement //64 string length

new String:raceString[MAXRACES][RaceString][512];
new String:raceSkillString[MAXRACES][MAXSKILLCOUNT][SkillString][512];


new bool:skillIsUltimate[MAXRACES][MAXSKILLCOUNT];
new skillMaxLevel[MAXRACES][MAXSKILLCOUNT];


new MinLevelCvar[MAXRACES];
new AccessFlagCvar[MAXRACES];
new RaceOrderCvar[MAXRACES];
new RaceFlagsCvar[MAXRACES]
new RestrictItemsCvar[MAXRACES]
new RestrictLimitCvar[MAXRACES][2];

new Handle:m_MinimumUltimateLevel;

new bool:racecreationended=true;
new String:creatingraceshortname[16];

//END race instance variables


public Plugin:myinfo= 
{
	name="War3Source Engine Race Class",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
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

public OnPluginStart()
{
	
	m_MinimumUltimateLevel=CreateConVar("war3_minimumultimatelevel","6");
	
}


bool:InitNativesForwards()
{

	CreateNative("War3_CreateNewRace",NWar3_CreateNewRace);
	CreateNative("War3_AddRaceSkill",NWar3_AddRaceSkill);
	
	CreateNative("War3_CreateNewRaceT",NWar3_CreateNewRaceT);
	CreateNative("War3_AddRaceSkillT",NWar3_AddRaceSkillT);
	
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
	return true;
}


public NWar3_CreateNewRace(Handle:plugin,numParams){
	
	
	decl String:name[64],String:shortname[16];
	GetNativeString(1,name,sizeof(name));
	GetNativeString(2,shortname,sizeof(shortname));
	
	//W3Log("add race %s %s",name,shortname);
	
	return CreateNewRace(name,shortname);

}


public NWar3_AddRaceSkill(Handle:plugin,numParams){
	


	new raceid=GetNativeCell(1);
	new String:skillname[32];
	new String:skilldesc[2001];
	GetNativeString(2,skillname,sizeof(skillname));
	GetNativeString(3,skilldesc,sizeof(skilldesc));
	new bool:isult=GetNativeCell(4);
	new tmaxskilllevel=GetNativeCell(5);
	
	//W3Log("add skill %s %s",skillname,skilldesc);
	
	return AddRaceSkill(raceid,skillname,skilldesc,isult,tmaxskilllevel);
}

//translated
public NWar3_CreateNewRaceT(Handle:plugin,numParams){

	
	
	decl String:name[64],String:shortname[32];
	GetNativeString(1,shortname,sizeof(shortname));
	new newraceid=CreateNewRace(name,shortname);
	raceTranslated[newraceid]=true;
	new String:buf[64];
	Format(buf,sizeof(buf),"w3s.race.%s.phrases",shortname);
	LoadTranslations(buf);
	
	//W3Log("add raceT %s %d",shortname,newraceid);

	return newraceid;

}
//translated
public NWar3_AddRaceSkillT(Handle:plugin,numParams){

	
	new raceid=GetNativeCell(1);
	new String:skillname[32];
	new String:skilldesc[1]; //DUMMY
	GetNativeString(2,skillname,sizeof(skillname));
	new bool:isult=GetNativeCell(3);
	new tmaxskilllevel=GetNativeCell(4);
	
	//W3Log("add skill T %d %s",raceid,skillname);
		
	new newskillnum=AddRaceSkill(raceid,skillname,skilldesc,isult,tmaxskilllevel);
	
	
	if(ignoreRaceEnd==false&&numParams>4){
		for(new arg=5;arg<=numParams;arg++){
			GetNativeString(arg,raceSkillDescReplace[raceid][newskillnum][raceSkillDescReplaceNum[raceid][newskillnum]],64);
			raceSkillDescReplaceNum[raceid][newskillnum]++;
		}
	}
	
	return newskillnum;
}

public NWar3_CreateRaceEnd(Handle:plugin,numParams){
	//W3Log("race end %d",GetNativeCell(1));
	CreateRaceEnd(GetNativeCell(1));
}
///this is get raceid, not NAME!
public Native_War3_GetRaceByShortname(Handle:plugin,numParams)
{
	new String:short_lookup[16];
	GetNativeString(1,short_lookup,sizeof(short_lookup));
	for(new x=1;x<=GetRacesLoaded();x++)
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
	
	new String:buf[32];
	GetRaceSkillName(race,skill,buf,sizeof(buf))
	SetNativeString(3,buf,maxlen);
}
public NW3GetRaceSkillDesc(Handle:plugin,numParams)
{	new race=GetNativeCell(1);
	new skill=GetNativeCell(2);
	new maxlen=GetNativeCell(4);
	
	new String:longbuf[1000];
	GetRaceSkillDesc(race,skill,longbuf,sizeof(longbuf))
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
public NW3GetRaceList(Handle:plugin,numParams){

	new listcount=0;
	
	new Handle:hdynamicarray=CreateArray(1,War3_GetRacesLoaded()); //2 indexes
	for(new raceid=1;raceid<=War3_GetRacesLoaded();raceid++){
		if(!W3RaceHasFlag(raceid,"hidden")){
	
	
			SetArrayCell(hdynamicarray, listcount, raceid);
			listcount++
		}
		//else{
		//	PrintToChatAll("hidden");
	//	}
	}
	new racelist[MAXRACES];
	new Handle:result=MergeSort(hdynamicarray); //closes hdynamicarray
	for(new i=0;i<listcount;i++){
		racelist[i]=GetArrayCell(result, i);
	}
	//printArray("",result); 
	//PrintToServer("result array size %d/%d", GetArraySize(result),War3_GetRacesLoaded());
	CloseHandle(result);

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









































CreateNewRace(String:tracename[]  ,  String:traceshortname[]){
	
	
	
	if(RaceExistsByShortname(traceshortname)){
		new oldraceid=GetRaceIDByShortname(traceshortname);
		PrintToServer("Race already exists: %s, returning old raceid %d",traceshortname,oldraceid);
		ignoreRaceEnd=true;
		return oldraceid;
	}
	
	if(totalRacesLoaded+1==MAXRACES){ //make sure we didnt reach our race capacity limit
		LogError("MAX RACES REACHED, CANNOT REGISTER %s %s",tracename,traceshortname);
		return 0;
	}
	
	if(racecreationended==false){
		new String:error[512];
		Format(error,sizeof(error),"CreateNewRace was called before previous race creation was ended!!! first race not ended: %s second race: %s ",creatingraceshortname,traceshortname)
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
		Format(raceSkillName[traceid][i],31,"NO SKILL DEFINED");
		Format(raceSkillDescription[traceid][i],2000,"NO SKILL DESCRIPTION DEFINED");
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

	if(raceTranslated[raceid]){
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
	if(raceTranslated[raceid]){
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
	return raceSkillCount[raceid];
}

stock GetRaceSkillNonUltimateCount(raceid){
	new num;
	for(new i=0;i<GetRaceSkillCount(raceid);i++){
		if(!IsSkillUltimate(raceid,i)) //regular skill
		{
			num++;
		}
	}
	return num;
}
stock GetRaceSkillIsUltimateCount(raceid){
	new num;
	for(new i=0;i<GetRaceSkillCount(raceid);i++){
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
	for(new skill=0;skill<GetRaceSkillCount(raceid);skill++){
		num+=skillMaxLevel[raceid][skill];
	}
	return num;
}





////we add skill or ultimate here, but we have to define if its a skill or ultimate we are adding
AddRaceSkill(raceid,String:skillname[],String:skilldescription[],bool:isUltimate,tmaxskilllevel){
	if(raceid>0){
		//ok is it an existing skill?
		//new String:existingskillname[64];
		for(new i=0;i<GetRaceSkillCount(raceid);i++){
			//GetRaceSkillName(raceid,i,existingskillname,sizeof(existingskillname));
			if(StrEqual(skillname,raceSkillName[raceid][i],false)){ ////need raw skill name, because of translations
				//PrintToServer("Skill exists %s, returning old skillid %d",skillname,i);
				
				return i;
			}
		}
		//if(ignoreRaceEnd){
		//	W3Log("%s skill not found, REadding for race %d",skillname,raceid);
		//}
		
		//not existing, will it exceeded maximum?
		if(raceSkillCount[raceid]==MAXSKILLCOUNT){
			LogError("SKILL LIMIT FOR RACE %d reached!",raceid);
			return -1;
		}
		
		
		
		strcopy(raceSkillName[raceid][raceSkillCount[raceid]], 32, skillname);
		strcopy(raceSkillDescription[raceid][raceSkillCount[raceid]], 2000, skilldescription);
		skillIsUltimate[raceid][raceSkillCount[raceid]]=isUltimate;
		
		skillMaxLevel[raceid][raceSkillCount[raceid]]=tmaxskilllevel;
		
		raceSkillCount[raceid]++;
		
		return raceSkillCount[raceid]-1; //return their actual skill number
		
	}
	return 0;
}


CreateRaceEnd(raceid){
	racecreationended=true;
	Format(creatingraceshortname,sizeof(creatingraceshortname),"");
	///now we put shit into the database and create cvars
	if(!ignoreRaceEnd&&raceid>0)
	{
		new Handle:DBIDB=Handle:W3GetVar(hDatabase);
		
		new String:shortname[16];
		GetRaceShortname(raceid,shortname,sizeof(shortname));
		
		///min level cvar
		//new String:cvar_min[64];
		//Format(cvar_min,sizeof(cvar_min),"war3_%s_minlevel",shortname);
		
		//hcvar_MinLevel[raceid]=CreateConVar(cvar_min,"0","Minimum level for race");
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
		
	
		
		
		
		/*new String:buf[32];
		Format(buf,sizeof(buf),"%s minlevel",shortname);
		SetTrieString(htrie,buf,"0");
		
		Format(buf,sizeof(buf),"%s accessflag",shortname);
		SetTrieString(htrie,buf,"0");
		Format(buf,sizeof(buf),"%s restrict items",shortname);
		SetTrieString(htrie,buf,"");
		Format(buf,sizeof(buf),"%s team1 limit",shortname);
		SetTrieString(htrie,buf,"99");
		Format(buf,sizeof(buf),"%s team2 limit",shortname);
		SetTrieString(htrie,buf,"99");*/
		
		// create war3sourceraces structure, shouldn't be harmful if already exists
		if(DBIDB)
		{
			PrintToServer("---Starting Threaded race operations: %s----------",shortname);
			//PrintToServer("Creating race into war3sourceraces if not exists %s",shortname);
			
			
			new String:longquery[4001];
			// populate war3sourceraces
			
			Format(longquery,sizeof(longquery),"INSERT %s IGNORE INTO war3sourceraces (shortname) VALUES ('%s')",W3GetVar(hDatabaseType)==SQLType_SQLite?"OR":"",shortname);
			
			SQL_TQuery(DBIDB,T_CallbackInsertRace1,longquery,raceid,DBPrio_High);
			
			
			
		}
	}
	ignoreRaceEnd=false;
}

public T_CallbackInsertRace1(Handle:owner,Handle:hndl,const String:error[],any:raceid)
{
	SQLCheckForErrors(hndl,error,"T_CallbackInsertRace1");
	new Handle:DBIDB=Handle:W3GetVar(hDatabase);
	
	
	new String:retstr[2000];
	new String:escapedstr[2000];
	new String:longquery[4000];
	Format(longquery,sizeof(longquery),"UPDATE war3sourceraces SET ");
	
	GetRaceName(raceid,retstr,sizeof(retstr));
	SQL_EscapeString(DBIDB,retstr,escapedstr,sizeof(escapedstr));
	Format(longquery,sizeof(longquery),"%s name='%s'",longquery,escapedstr);
	
	
	for(new i=0;i<GetRaceSkillCount(raceid);i++){
		GetRaceSkillName(raceid,i,retstr,sizeof(retstr));
		SQL_EscapeString(DBIDB,retstr,escapedstr,sizeof(escapedstr));
		Format(longquery,sizeof(longquery),"%s, skill%d='%s %s'",longquery,i,IsSkillUltimate(raceid,i)?"Ultimate":"",escapedstr);
		
		GetRaceSkillDesc(raceid,i,retstr,sizeof(retstr));
		SQL_EscapeString(DBIDB,retstr,escapedstr,sizeof(escapedstr));
		Format(longquery,sizeof(longquery),"%s, skilldesc%d='%s'",longquery,i,escapedstr);
	}
	
	new String:shortname[16];
	GetRaceShortname(raceid,shortname,sizeof(shortname));
	
	Format(longquery,sizeof(longquery),"%s WHERE shortname = '%s'",longquery,shortname);
	SQL_TQuery(DBIDB,  T_CallbackInsertRace2,longquery,raceid,DBPrio_High);//
}
public T_CallbackInsertRace2(Handle:owner,Handle:hndl,const String:error[],any:raceid)
{
	SQLCheckForErrors(hndl,error,"T_CallbackInsertRace2");
	
	//new String:racename[32];
//	GetRaceName(raceid,racename,sizeof(racename));
	//PrintToServer("[War3Source] SQL operations done for war3sourceraces: race %s",racename);
}

stock SQLCheckForErrors(Handle:hndl,const String:originalerror[],const String:prependstr[]=""){
	if(!StrEqual("", originalerror))
		LogError("SQL error: [%s] %s", prependstr, originalerror);
	else if(hndl == INVALID_HANDLE)
	{
		decl String:err[512];
		SQL_GetError(hndl, err, sizeof(err));
		LogError("SQLCheckForErrors: [%s] %s", prependstr, err);
	}
}









bool:RaceExistsByShortname(String:shortname[]){
	new String:buffer[16];
	
	for(new raceid=1;raceid<=GetRacesLoaded();raceid++){
		GetRaceShortname(raceid,buffer,sizeof(buffer));
		if(StrEqual(shortname, buffer, false)){
			return true;
		}
	}
	return false;
}
GetRaceIDByShortname(String:shortname[]){
	new String:buffer[16];
	
	for(new raceid=1;raceid<=GetRacesLoaded();raceid++){
		GetRaceShortname(raceid,buffer,sizeof(buffer));
		if(StrEqual(shortname, buffer, false)){
			return raceid;
		}
	}
	return -1;
}



Handle:MergeSort(Handle:array){
	
	new len=GetArraySize(array);
	if(len==1){
		return array;
	}
	new cut=len/2;
	
	new Handle:smallerarrayleft=CreateArray(1,cut);
	new Handle:smallerarrayright=CreateArray(1,len-cut);
	
	for(new i=0;i<cut;i++){
		SetArrayCell(smallerarrayleft, i, GetArrayCell(array, i));
	
	}
	for(new i=cut;i<len;i++){
		SetArrayCell(smallerarrayright, i-cut, GetArrayCell(array, i ));
	
	}
	CloseHandle(array);
	
	
	new Handle:leftresult=	MergeSort(smallerarrayleft);
	new Handle:rightresult=	MergeSort(smallerarrayright);
	
	new Handle:resultarray=CreateArray(1,0);
	new index=0;
	while(GetArraySize(leftresult)>0&&GetArraySize(rightresult)>0){
		new leftval=W3GetRaceOrder( GetArrayCell(leftresult, 0));
		new rightval=W3GetRaceOrder( GetArrayCell(rightresult, 0));
		//PrintToServer("left %d vs right %d",leftval,rightval);
		
		if(leftval<=rightval){
			PushArrayCell(resultarray,-1); //add index 
			SetArrayCell(resultarray, index, GetArrayCell(leftresult, 0));
		
			RemoveFromArray(leftresult, 0);
			
			//printArray("took left" ,resultarray);
		}
		else{
			PushArrayCell(resultarray,-1); //add index 
			SetArrayCell(resultarray, index, GetArrayCell(rightresult, 0));
		
			RemoveFromArray(rightresult, 0);
			//printArray("took right" ,resultarray);
		}
		index++;
	}
	
	new bool:closeleft,bool:closeright;
	if(GetArraySize(leftresult)>0){ 
		resultarray=append(resultarray,leftresult);
		closeright=true;
	}
	else if(GetArraySize(rightresult)>0){ 
		resultarray=append(resultarray,rightresult);
		closeleft=true;
	}
	
	
	if(closeleft){
		CloseHandle(leftresult);
	}
	if(closeright){
		CloseHandle(rightresult);
	}

	return resultarray;
	
}
Handle:append(Handle:leftarr,Handle:rightarr){
	new leftindex=GetArraySize(leftarr);
	new rigthlen=GetArraySize(rightarr);
	
	for(new i=0;i<rigthlen;i++){
		//append right
		PushArrayCell(leftarr,-1); //add index to left
		SetArrayCell(leftarr, leftindex, GetArrayCell(rightarr, 0));
	
		RemoveFromArray(rightarr, 0);
		leftindex++;
	}
	CloseHandle(rightarr);
	//printArray("appended" ,leftarr);
	return leftarr;
}
stock printArray(String:prepend[]="",Handle:arr){
	new len=GetArraySize(arr);
	new String:print[100];
	Format(print,sizeof(print),"%s {",prepend);
	for(new i=0;i<len;i++){
		Format(print,sizeof(print),"%s %d",print,GetArrayCell(arr,i));
	}
	Format(print,sizeof(print),"%s}",print);
	PrintToServer(print);
}
