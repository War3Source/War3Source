#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
public Plugin:myinfo= 
{
	name="W3S Engine Race Factions",
	author="Revan",
	description="Handles W3S Faction Related stuff",
	version="1.0",
	url="http://war3source.com/"
};

new String:strFactions[MAXFACTIONS][FACTION_LENGTH];
new raceFactions[MAXRACES];
new CurFactions = 0;
//all factions are neutral by default
new factionBehavior[MAXFACTIONS][MAXFACTIONS];

//Inits. Natives
public bool:InitNativesForwards()
{
	//W3Faction(raceid,String:strFactionName[],bool:bCreateIfNotExist=false);
	CreateNative("W3Faction",NWar3_MainFactionFunction);
	//W3FactionRelation(faction1,faction2,FactionBehavior:relation=-1);
	CreateNative("W3FactionBehavior",NWar3_RelationFactionFunction);
	//W3FactionBehaviorByName(String:strFactionName1[],String:strFactionName2[],FactionBehavior:relation=-1);
	CreateNative("W3FactionBehaviorByName",NWar3_RelationFactionFunction_N);
	//W3FactionCompare(race1,race2);
	CreateNative("W3FactionCompare",NWar3_FactionCompare);
	//W3GetRaceFaction(race,String:strReturn[],maxsize);
	CreateNative("W3GetRaceFaction",NWar3_GetRaceFaction);
	return true;
}

//Compares the faction of 2 races
public _:NWar3_FactionCompare(Handle:plugin,numParams) {
	decl r1,r2;
	r1 = GetNativeCell(1);
	r2 = GetNativeCell(2);
	if(r1>0&&r2>0) {
		decl f1,f2;
		f1 = W3GetFaction(r1);
		f2 = W3GetFaction(r2);
		if(f1>=0&&f2>=0) {
			return factionBehavior[f1][f2];
		}
		return ThrowNativeError(SP_ERROR_NATIVE,"Could not resolve race factions");
	}
	return ThrowNativeError(SP_ERROR_NATIVE,"Invalid RaceId1 and/or RaceId2");
}
//FakeNative callback of "W3Faction"
public NWar3_MainFactionFunction(Handle:plugin,numParams) {
	decl String:name[FACTION_LENGTH], raceid, bool:bCreate;
	raceid = GetNativeCell(1);
	GetNativeString(2,name,sizeof(name));
	bCreate = GetNativeCell(3);
	if(raceid>0 && strlen(name)>0) {
		//Check if the faction allready exist or not
		decl faction;
		faction = W3GetFactionIdByName(name,bCreate);
		/*if(bCreate && faction==-1) {
			//Don't exist -> add it
			faction = W3AddFaction(name);
			PrintToServer("[WAR3] Adding Faction(%i): %s",CurFactions,name);
		}*/
		//Store the faction of the race inside a nice runtime buffer
		if(faction!=-1)
		W3SetFaction(raceid,faction);
		return faction;
	}
	return ThrowNativeError(SP_ERROR_NATIVE,"Invalid RaceId and/or FactionName");
}

//FakeNative callback of "W3FactionRelationByName"
public _:NWar3_RelationFactionFunction_N(Handle:plugin,numParams) {
	decl String:f1N[FACTION_LENGTH],String:f2N[FACTION_LENGTH],any:value;
	GetNativeString(1,f1N,sizeof(f1N));
	GetNativeString(2,f2N,sizeof(f2N));
	value=GetNativeCell(3);
	//if(strlen(f1N)!=0 || strlen(f2N)!=0) {
	decl f1,f2;
	f1 = W3GetFactionIdByName(f1N,true);
	f2 = W3GetFactionIdByName(f2N,true);
	if(f1>=0&&f2>=0) {
		if(value!=-1) {
			//create new and return old
			factionBehavior[f1][f2]=value;
		}
		return factionBehavior[f1][f2];
	}
	return 0;
	//}
	//return ThrowNativeError(SP_ERROR_NATIVE,"Invalid Faction1(%s)/Faction2(%s) Name",f1N,f2N);
}

//FakeNative callback of "W3FactionRelation"
public _:NWar3_RelationFactionFunction(Handle:plugin,numParams) {
	decl f1,f2,any:value;
	f1=GetNativeCell(1);
	f2=GetNativeCell(2);
	value=GetNativeCell(3);
	if(f1>=0&&f2>=0) {
		if(value!=-1) {
			factionBehavior[f1][f2]=value;
		}
		return factionBehavior[f1][f2];
	}
	return ThrowNativeError(SP_ERROR_NATIVE,"Invalid FactionId1/FactionId2");
}

//FakeNative callback of "W3GetRaceFaction"
public _:NWar3_GetRaceFaction(Handle:plugin,numParams) {
	decl iRace,iSize;
	iRace=GetNativeCell(1);
	iSize=GetNativeCell(3);
	decl String:buffer[iSize];
	W3GetFactionNameById(W3GetFaction(iRace),buffer,iSize);
	SetNativeString(2, buffer, iSize);
}

//Factions gonna get refreshed
public OnMapStart() {
	W3RemoveFaction();
}

//Purpose: Sets a race faction
stock W3SetFaction(raceId,factionId) {
	if(factionId>=0)
	raceFactions[raceId] = factionId;
}
//Purpose: Gets a race faction
stock W3GetFaction(raceId) {
	return raceFactions[raceId];
}
//Purpose: Add's new faction by name - returns faction id
stock W3AddFaction(String:sFactionName[]) {
	new faction_id = -1;
	if(CurFactions<MAXFACTIONS) {
		strcopy(strFactions[CurFactions],FACTION_LENGTH,sFactionName);
		faction_id = CurFactions;
		CurFactions++;
		return faction_id;
	}
	return faction_id;
}
//Purpose: Get's a faction index by name
stock W3GetFactionIdByName(String:sFactionName[],bool:bCreateOnFail=false) {
	new index = -1;
	for(new i=0;i<CurFactions;i++) {
		if(strcmp(strFactions[i], sFactionName, false)==0) {
			index = i;
			break;
		}
	}
	if(bCreateOnFail && index==-1) {
		index = W3AddFaction(sFactionName);
		PrintToServer("adding faction: %s",sFactionName);
	}
	return index;	
}
//Purpose: Get's a faction name by index
stock bool:W3GetFactionNameById(factionid,String:sReturnBuffer[],maxsize) {
	if(CurFactions<MAXFACTIONS) {
		strcopy(sReturnBuffer,maxsize,strFactions[factionid]);
		return true;
	}
	return false;
}
//Purpose: Removes all/a single Faction(s)
stock W3RemoveFaction(id=-1) {
	if(id>=0) {
		strcopy(strFactions[id],FACTION_LENGTH,"");
	}
	else {
		for(new i=0;i<=CurFactions;i++) {
			strcopy(strFactions[i],FACTION_LENGTH,"");
		}
		CurFactions = 0;
	}
}