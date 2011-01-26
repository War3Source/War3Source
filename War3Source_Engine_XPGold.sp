

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo= 
{
	name="War3Source Engine XP Gold",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};

new String:levelupSound[]="war3source/levelupcaster.wav";


///MAXLEVELXPDEFINED is in constants
new XPLongTermREQXP[MAXLEVELXPDEFINED+1] //one extra for even if u reached max level
new XPLongTermKillXP[MAXLEVELXPDEFINED+1]
new XPShortTermREQXP[MAXLEVELXPDEFINED+1]
new XPShortTermKillXP[MAXLEVELXPDEFINED+1]


// not game specific
new Handle:HeadshotXPCvar;
new Handle:MeleeXPCvar;
new Handle:RoundWinXPCvar;
new Handle:AssistKillXPCvar;
new Handle:BotIgnoreXPCvar;
new Handle:hLevelDifferenceBounus;
new Handle:minplayersXP;

// cs
new Handle:DefuseXPCvar;
new Handle:PlantXPCvar;
new Handle:RescueHostageXPCvar;

// tf
new Handle:PointCaptureXPCvar;
new Handle:PointCapBlockXPCvar;
new Handle:CaptureFlagXPCvar;

//gold

new Handle:MaxGoldCvar;
new Handle:KillGoldCvar;
new Handle:AssistGoldCvar;



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

	BotIgnoreXPCvar=CreateConVar("war3_ignore_bots_xp","0","Set to 1 to not award XP for killing bots");
	HeadshotXPCvar=CreateConVar("war3_percent_headshotxp","20","Percent of kill XP awarded additionally for headshots");
	MeleeXPCvar=CreateConVar("war3_percent_meleexp","100","Percent of kill XP awarded additionally for melee/knife kills");
	AssistKillXPCvar=CreateConVar("war3_percent_assistkillxp","75","Percent of kill XP awarded for an assist kill.");
	RoundWinXPCvar=CreateConVar("war3_percent_roundwinxp","100","Percent of kill XP awarded for being on the winning team");
	DefuseXPCvar=CreateConVar("war3_percent_cs_defusexp","200","Percent of kill XP awarded for defusing the bomb");
	PlantXPCvar=CreateConVar("war3_percent_cs_plantxp","200","Percent of kill XP awarded for planting the bomb");
	RescueHostageXPCvar=CreateConVar("war3_percent_cs_hostagerescuexp","100","Percent of kill XP awarded for rescuing a hostage");
	PointCaptureXPCvar=CreateConVar("war3_percent_tf_pointcapturexp","25","Percent of kill XP awarded to the capturing team");
	PointCapBlockXPCvar=CreateConVar("war3_percent_tf_blockcapturexp","20","Percent of kill XP awarded for blocking a capture");
	CaptureFlagXPCvar=CreateConVar("war3_percent_tf_flagcapturexp","100","Percent of kill XP awarded for capturing the flag");
	hLevelDifferenceBounus=CreateConVar("war3_xp_level_difference_bonus","0","Bounus Xp awarded per level if victim has a higher level");
	minplayersXP=CreateConVar("war3_min_players_xp_gain","2","minimum amount of players needed on teams for people to gain xp");
	MaxGoldCvar=CreateConVar("war3_maxgold","1000");
	
	KillGoldCvar=CreateConVar("war3_killgold","2");
	AssistGoldCvar=CreateConVar("war3_assistgold","1");
	
	ParseXPSettingsFile();
	
	
	if(!HookEventEx("player_death",War3Source_PlayerDeathEvent,EventHookMode_Pre))
	{
		PrintToServer("[War3Source] Could not hook the player_spawn event.");
	}
	
	if(War3_GetGame()==CS){
		if(!HookEventEx("bomb_defused",War3Source_BombDefusedEvent))
		{
			PrintToServer("[War3Source] Could not hook the bomb_defused event.");
			
		}
		if(!HookEventEx("bomb_planted",War3Source_BombPlantedEvent))
		{
			PrintToServer("[War3Source] Could not hook the bomb_planted event.");
			
		}
		if(!HookEventEx("hostage_rescued",War3Source_HostageRescuedEvent))
		{
			PrintToServer("[War3Source] Could not hook the hostage_rescued event.");
			
		}
		
		if(!HookEventEx("round_end",War3Source_RoundOverEvent))
		{
			PrintToServer("[War3Source] Could not hook the round_end event.");
		}
	}
	
	else if(War3_GetGame()==Game_TF)
	{
		if(!HookEventEx("teamplay_round_win",War3Source_RoundOverEvent))
		{
			PrintToServer("[War3Source] Could not hook the teamplay_round_win event.");
			
		}
		if(!HookEventEx("teamplay_point_captured",War3Source_PointCapturedEvent))
		{
			PrintToServer("[War3Source] Could not hook the teamplay_point_captured event.");
			
		}
		if(!HookEventEx("teamplay_capture_blocked",War3Source_PointCapBlockedEvent))
		{
			PrintToServer("[War3Source] Could not hook the teamplay_capture_blocked event.");
			
		}
		if(!HookEventEx("teamplay_flag_event",War3Source_FlagEvent))
		{
			PrintToServer("[War3Source] Could not hook the teamplay_flag_event event.");
			
		}
	}
	
}
public OnMapStart(){
	War3_PrecacheSound(levelupSound);
}
bool:InitNativesForwards()
{
	CreateNative("W3GetReqXP" ,NW3GetReqXP)
	CreateNative("W3GetKillXP",NW3GetKillXP)
	CreateNative("War3_ShowXP",Native_War3_ShowXP);
	CreateNative("W3GetMaxGold",NW3GetMaxGold);
	
	CreateNative("W3GiveXPGold",NW3GiveXPGold);
	
	return true;
}
public NW3GetReqXP(Handle:plugin,numParams)
{
	new level=GetNativeCell(1);
	if(level>MAXLEVELXPDEFINED)
		level=MAXLEVELXPDEFINED;
	return IsShortTerm()?XPShortTermREQXP[level] :XPLongTermREQXP[level]
}
public NW3GetKillXP(Handle:plugin,numParams)
{
	new level=GetNativeCell(1);
	if(level>MAXLEVELXPDEFINED)
		level=MAXLEVELXPDEFINED;
	return IsShortTerm()?XPShortTermKillXP[level] :XPLongTermKillXP[level];
}	
public Native_War3_ShowXP(Handle:plugin,numParams)
{
	ShowXP(GetNativeCell(1));
}
public NW3GetMaxGold(Handle:plugin,numParams)
{
	return GetConVarInt(MaxGoldCvar);
}
public NW3GiveXPGold(Handle:plugin,args){
	new client=GetNativeCell(1);
	new race=GetNativeCell(2);
	new xp=GetNativeCell(3);
	new gold=GetNativeCell(4);
	new String:strreason[64];
	GetNativeString(5,strreason,sizeof(strreason));
	TryToGiveXPGold(client,race,XPAwardByGeneric,xp,gold,strreason);
	
}


ParseXPSettingsFile(){
	new Handle:keyValue=CreateKeyValues("War3SourceSettings");
	decl String:path[1024];
	BuildPath(Path_SM,path,sizeof(path),"configs/war3source.ini");
	FileToKeyValues(keyValue,path);
	// Load level configuration
	KvRewind(keyValue);
	
	
	
	if(!KvJumpToKey(keyValue,"levels"))
		return SetFailState("error, key value for levels configuration not found");
		

	decl String:read[2048];
	if(!KvGotoFirstSubKey(keyValue))
		return SetFailState("sub key failed");
		
		
		
		
	// required xp, long term
	KvGetString(keyValue,"required_xp",read,sizeof(read));
	new tokencount=StrTokenCount(read);
	if(tokencount!=MAXLEVELXPDEFINED+1)
		return SetFailState("XP config improperly formatted, not enought or too much levels defined?");
			
	decl String:temp_iter[16];
	for(new x=1;x<=tokencount;x++)
	{
		// store it
		StrToken(read,x,temp_iter,15);
		XPLongTermREQXP[x-1]=StringToInt(temp_iter)
	}
	
	
	
	
	
	// kill xp, long term
	KvGetString(keyValue,"kill_xp",read,sizeof(read));
	tokencount=StrTokenCount(read);
	if(tokencount!=MAXLEVELXPDEFINED+1)
		return SetFailState("XP config improperly formatted, not enought or too much levels defined?");
			
	for(new x=1;x<=tokencount;x++)
	{
		// store it
		StrToken(read,x,temp_iter,15);
		XPLongTermKillXP[x-1]=StringToInt(temp_iter);
	}
	
	
	
	
	
	
	
	if(!KvGotoNextKey(keyValue))
		return SetFailState("XP No Next key");
	// required xp, short term
	KvGetString(keyValue,"required_xp",read,sizeof(read));
	tokencount=StrTokenCount(read);
	if(tokencount!=MAXLEVELXPDEFINED+1)
		return SetFailState("XP config improperly formatted, not enought or too much levels defined?");
	for(new x=1;x<=tokencount;x++)
	{
		// store it
		StrToken(read,x,temp_iter,15);
		XPShortTermREQXP[x-1]=StringToInt(temp_iter);
	}
	
	
	
	
	
	// kill xp, short term
	KvGetString(keyValue,"kill_xp",read,sizeof(read));
	tokencount=StrTokenCount(read);
	if(tokencount!=MAXLEVELXPDEFINED+1)
		return SetFailState("XP config improperly formatted, not enought or too much levels defined?");
		
		
	for(new x=1;x<=tokencount;x++)
	{
		// store it
		StrToken(read,x,temp_iter,15);
		XPShortTermKillXP[x-1]=StringToInt(temp_iter);
	}
	
	return true;
}




public ShowXP(client)
{
	new race=War3_GetRace(client);
	if(race==0)
	{
		//if(bXPLoaded[client])
		War3_ChatMessage(client,"%T","You must first select a race with changerace!",client);
		return;
	}
	new level=War3_GetLevel(client,race);
	decl String:racename[64];
	War3_GetRaceName(race,racename,sizeof(racename));
	if(level<W3GetRaceMaxLevel(race))
		War3_ChatMessage(client,"%T","{racename} - Level {amount} - {amount} XP / {amount} XP",client,racename,level,War3_GetXP(client,race),W3GetReqXP(level+1));
	else
		War3_ChatMessage(client,"%T","{racename} - Level {amount} - {amount} XP",client,racename,level,War3_GetXP(client,race));
}
public War3Source_PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new uid_victim=GetEventInt(event,"userid");
	new uid_attacker=GetEventInt(event,"attacker");
	new uid_assister=0;
	if(War3_GetGame()==Game_TF)
	{
		uid_assister=GetEventInt(event,"assister");
	}
	new victimIndex=GetClientOfUserId(uid_victim);
	new attackerIndex=GetClientOfUserId(uid_attacker);
		
	new bool:deadringereath=false;
	if(uid_victim>0)
	{
		
		new deathFlags = GetEventInt(event, "death_flags");
		if (War3_GetGame()==Game_TF&&deathFlags & 32 || IsPlayerAlive(victimIndex))
		{
			deadringereath=deadringereath?true:true; //stfu
		   //PrintToChat(client,"war3 debug: dead ringer kill");
		}
	}

	if(uid_victim!=uid_attacker&&uid_attacker>0)
	{
		
		
		new assistIndex=0;
		if(uid_assister>0)
		{
			assistIndex=GetClientOfUserId(uid_assister);
		}
		if(GetClientTeam(attackerIndex)!=GetClientTeam(victimIndex))
		{
			decl String:weapon[64];
			GetEventString(event,"weapon",weapon,sizeof(weapon));
			new bool:is_hs,bool:is_melee;
			if(IsFakeClient(victimIndex) && GetConVarBool(BotIgnoreXPCvar))
				return;
			if(War3_GetGame()==Game_TF)
			{
				is_hs=(GetEventInt(event,"customkill")==1);
				
			}
			else
			{
				is_hs=GetEventBool(event,"headshot");
				
			}
			is_melee=W3IsDamageFromMelee(weapon);
			
			/*(StrEqual(weapon,"bat",false) ||
					StrEqual(weapon,"bat_wood",false) ||
					StrEqual(weapon,"bonesaw",false) ||
					StrEqual(weapon,"bottle",false) ||
					StrEqual(weapon,"club",false) ||
					StrEqual(weapon,"fireaxe",false) ||
					StrEqual(weapon,"fists",false) ||
					StrEqual(weapon,"knife",false) ||
					StrEqual(weapon,"lunchbox",false) ||
					StrEqual(weapon,"shovel",false) ||
					StrEqual(weapon,"wrench",false));
					
					is_melee=StrEqual(weapon,"knife");*/
					
			if(assistIndex>=0 && War3_GetRace(assistIndex)>0)
			{
				GiveAssistKillXP(assistIndex);
			}
			
			GiveKillXPCreds(attackerIndex,victimIndex,is_hs,is_melee);
		}
	}
	
}
public War3Source_RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
// cs - int winner
// tf2 - int team
	new team=-1;
	if(War3_GetGame()==Game_TF)
	{
		team=GetEventInt(event,"team");
	}
	else
	{
		team=GetEventInt(event,"winner");
	}
	if(team>-1)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			
			if(ValidPlayer(i)&&  GetClientTeam(i)==team)
			{
				
				new race=War3_GetRace(i);
				if(race>0)
				{
					new addxp=((GetKillXP(War3_GetLevel(i,War3_GetRace(i)))*GetConVarInt(RoundWinXPCvar))/100);
					
					new String:teamwinaward[64];
					Format(teamwinaward,sizeof(teamwinaward),"%T","being on the winning team",i);
					TryToGiveXPGold(i,race,XPAwardByWin,addxp,0,teamwinaward);
				}
			}
		}
	}
}



public War3Source_PointCapturedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new team=GetEventInt(event,"team");
	if(team>-1)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			
			if(ValidPlayer(i,true)&&  GetClientTeam(i)==team)
			{

				
				new race=War3_GetRace(i);
				if(race>0)
				{
					new addxp=((GetKillXP(War3_GetLevel(i,War3_GetRace(i)))*GetConVarInt(PointCaptureXPCvar))/100);
					
					new String:captureaward[64];
					Format(captureaward,sizeof(captureaward),"%T","being on the capturing team",i);
					TryToGiveXPGold(i,race,XPAwardByPointCap,addxp,0,captureaward);
				}
			}
		}
	}
}

public War3Source_PointCapBlockedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new blocker_uid=GetEventInt(event,"blocker");
	if(blocker_uid>0)
	{
		new client=GetClientOfUserId(blocker_uid);

		if(client>0 )
		{
		
			new race=War3_GetRace(client);
			if(race>0)
			{
				new addxp=((GetKillXP(War3_GetLevel(client,War3_GetRace(client)))*GetConVarInt(PointCapBlockXPCvar))/100);
				
				new String:pointcaptureaward[64];
				Format(pointcaptureaward,sizeof(pointcaptureaward),"%T","blocking point capture",client);
				TryToGiveXPGold(client,race,XPAwardByPointCapBlock,addxp,0,pointcaptureaward);
			}
		}
	}
}

public War3Source_FlagEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new userid=GetEventInt(event,"carrier");
	if(userid>0)
	{
		new client=GetClientOfUserId(userid);
		new type=GetEventInt(event,"eventtype");
		if(client>0  && type==2)
		{
		
			new race=War3_GetRace(client);
			if(race>0)
			{
				new addxp=((GetKillXP(War3_GetLevel(client,War3_GetRace(client)))*GetConVarInt(CaptureFlagXPCvar))/100);
				
				new String:pointcaptureaward[64];
				Format(pointcaptureaward,sizeof(pointcaptureaward),"%T","blocking point capture",client);
				TryToGiveXPGold(client,race,XPAwardByFlagCap,addxp,0,pointcaptureaward);
			}
		}
	}
}




public War3Source_BombDefusedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(GetEventInt(event,"userid")>0)
	{
		new client=GetClientOfUserId(GetEventInt(event,"userid"));
		
		
		GiveDefuseXP(client);
	}
}

public War3Source_BombPlantedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(GetEventInt(event,"userid")>0)
	{
		new client=GetClientOfUserId(GetEventInt(event,"userid"));
	
		GivePlantXP(client);
	}
}

public War3Source_HostageRescuedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(GetEventInt(event,"userid")>0)
	{
		new client=GetClientOfUserId(GetEventInt(event,"userid"));
		GiveHostageRescuedXP(client);
	}
}


























//fire event and allow addons to modify xp and gold
TryToGiveXPGold(client,race,W3XPAwardedBy:awardedfromevent,xp,gold,String:awardedprintstring[]){
	if(GetConVarInt(minplayersXP)>PlayersOnTeam(2)+PlayersOnTeam(3)){
		War3_ChatMessage(client,"%T","No XP is given when less than {amount} players are playing",client,GetConVarInt(minplayersXP));
		return;
	}
	W3SetVar(EventArg1,awardedfromevent); //set event vars
	W3SetVar(EventArg2,xp);
	W3SetVar(EventArg3,gold);
	W3CreateEvent(OnPreGiveXPGold,client); //fire event
	
	
	new addxp=	W3GetVar(EventArg2); //retrieve possibly modified vars
	new addgold=W3GetVar(EventArg3);
	
	War3_SetXP(client,race,War3_GetXP(client,War3_GetRace(client))+addxp);

	new oldgold=War3_GetGold(client);
	new newgold=oldgold+addgold;
	new maxgold=GetConVarInt(MaxGoldCvar);
	if(newgold>maxgold)
	{
		newgold=maxgold;
		addgold=newgold-oldgold;
	}
	War3_SetGold(client,newgold);
	if(addxp>0&&addgold>0)
		War3_ChatMessage(client,"%T","You have gained {amount} XP and {amount} gold for {award}",client,addxp,addgold,awardedprintstring);
	else if(addxp>0)
		War3_ChatMessage(client,"%T","You have gained {amount} XP for {award}",client,addxp,awardedprintstring);
	else if(addgold>0){
		War3_ChatMessage(client,"%T","You have gained {amount} gold for {award}",client,addgold,awardedprintstring);
	}
	
	if(War3_GetLevel(client,race)!=W3GetRaceMaxLevel(race))
		W3DoLevelCheck(client);
	
	W3CreateEvent(OnPostGiveXPGold,client);	
	return;
}









GiveKillXPCreds(client,playerkilled,bool:headshot,bool:melee)
{
	//PrintToChatAll("1");
	new race=War3_GetRace(client);
	new killerlevel=War3_GetLevel(client,War3_GetRace(client));
	new victimlevel=War3_GetLevel(playerkilled,War3_GetRace(playerkilled));
	
	new killxp=GetKillXP(killerlevel,victimlevel-killerlevel);
	
	new addxp=killxp;
	if(headshot)	addxp+=((killxp*GetConVarInt(HeadshotXPCvar))/100);
	if(melee)		addxp+=((killxp*GetConVarInt(MeleeXPCvar))/100);
	
	new String:killaward[64];
	Format(killaward,sizeof(killaward),"%T","a kill",client);
	TryToGiveXPGold(client,race,XPAwardByKill,addxp,GetKillGold(),killaward);
}

public GiveAssistKillXP(client)
{
	new race=War3_GetRace(client);
	new addxp=((GetKillXP(War3_GetLevel(client,War3_GetRace(client)))*GetConVarInt(AssistKillXPCvar))/100);
	
	new String:helpkillaward[64];
	Format(helpkillaward,sizeof(helpkillaward),"%T","assisting a kill",client);
	TryToGiveXPGold(client,race,XPAwardByAssist,addxp,GetAssistGold(),helpkillaward);
}

public GiveDefuseXP(client)
{
	new Float:origin[3];
	GetClientAbsOrigin(client,origin);
	new team=GetClientTeam(client);
	new Float:otherorigin[3];
	for(new i=1;i<=MaxClients;i++){
		if(ValidPlayer(i,true)&&GetClientTeam(i)==team){
			
			GetClientAbsOrigin(i,otherorigin);
			if(GetVectorDistance(origin,otherorigin)<1000.0&&War3_GetRace(i)>0){
		
				// Called when a player defuses the bomb
			
				new race=War3_GetRace(i);
				new addxp=((GetKillXP(War3_GetLevel(i,War3_GetRace(i)))*GetConVarInt(DefuseXPCvar))/100);
				
				new String:defusaward[64];
				new String:helpdefusaward[64];
				Format(defusaward,sizeof(defusaward),"%T","defusing the bomb",i);
				Format(helpdefusaward,sizeof(helpdefusaward),"%T","being near bomb defuse",i);
				TryToGiveXPGold(i,race,XPAwardByBomb,addxp,0,i==client?defusaward:helpdefusaward);
			}
		}
	}
					
}

public GivePlantXP(client)
{	
	new Float:origin[3];
	GetClientAbsOrigin(client,origin);
	new team=GetClientTeam(client);
	new Float:otherorigin[3];
	for(new i=1;i<=MaxClients;i++){
		if(ValidPlayer(i,true)&&GetClientTeam(i)==team){
			
			GetClientAbsOrigin(i,otherorigin);
			if(GetVectorDistance(origin,otherorigin)<1000.0&&War3_GetRace(i)>0){
		
		
			
				// Called when a player plants the bomb
			
				new race=War3_GetRace(i);
				new addxp=((GetKillXP(War3_GetLevel(i,War3_GetRace(i)))*GetConVarInt(PlantXPCvar))/100);
				
				new String:plantaward[64];
				new String:helpplantaward[64];
				Format(plantaward,sizeof(plantaward),"%T","planting the bomb",i);
				Format(helpplantaward,sizeof(helpplantaward),"%T","being near bomb plant",i);
				TryToGiveXPGold(i,race,XPAwardByBomb,addxp,0,i==client?plantaward:helpplantaward);
			}
		}
	}
	
}

public GiveHostageRescuedXP(client)
{
	// Called when a player rescues a hostage
	new race=War3_GetRace(client);
	new addxp=((GetKillXP(War3_GetLevel(client,War3_GetRace(client)))*GetConVarInt(RescueHostageXPCvar))/100);
	
	new String:hostageaward[64];
	Format(hostageaward,sizeof(hostageaward),"%T","rescuing a hostage",client);
	TryToGiveXPGold(client,race,XPAwardByHostage,addxp,0,hostageaward);
}





bool:IsShortTerm(){
	return GetConVarInt(Handle:W3GetVar(hSaveEnabledCvar))?false:true;
}


//redirect stock
GetKillXP(level,leveldiff=0){
	//PrintToChatAll("GetKillXP level %d level diff %d = %d",level,leveldiff,W3GetKillXP(level)+leveldiff>0?GetConVarInt(hLevelDifferenceBounus)*leveldiff:0);
	return W3GetKillXP(level)+((leveldiff>0)?GetConVarInt(hLevelDifferenceBounus)*leveldiff:0);
}

GetKillGold(){
	return GetConVarInt(KillGoldCvar);
}
GetAssistGold(){
	return GetConVarInt(AssistGoldCvar);
}













public OnWar3Event(W3EVENT:event,client){
	if(event==DoLevelCheck){
		LevelCheck(client);
	}
}


LevelCheck(client){
	new race=War3_GetRace(client);
	
	new skilllevel;
	
	new ultminlevel=W3GetMinUltLevel();
	
	///skill or ult is more than what he can be? ie level 4 skill when he is only level 4...
	new curlevel=War3_GetLevel(client,race);
	new SkillCount = War3_GetRaceSkillCount(race);
	for(new i=0;i<SkillCount;i++){
		skilllevel=War3_GetSkillLevel(client,race,i);
		if(!War3_IsSkillUltimate(race,i))
		{
			if(skilllevel*2>curlevel+1)
			{
				ClearSkillLevels(client,race);
				War3_ChatMessage(client,"%T","A skill is over the maximum level allowed for your current level, please reselect your skills",client);
				W3CreateEvent(DoShowSpendskillsMenu,client);
			}
		}
		else
		{
			if(skilllevel>0&&skilllevel*2+ultminlevel-1>curlevel+1){
				ClearSkillLevels(client,race);
				War3_ChatMessage(client,"%T","A ultimate is over the maximum level allowed for your current level, please reselect your skills",client);
				W3CreateEvent(DoShowSpendskillsMenu,client);
			}
		}
	}
	
	
	
	///seting xp or level recurses!!! SET XP FIRST!! or you will have a cascading level increment
	new keepchecking=true;
	while(keepchecking)
	{	
		curlevel=War3_GetLevel(client,race);
		if(curlevel<W3GetRaceMaxLevel(race))
		{
			
			if(War3_GetXP(client,race)>=W3GetReqXP(curlevel+1))
			{
				//PrintToChatAll("LEVEL %d xp %d reqxp=%d",curlevel,War3_GetXP(client,race),ReqLevelXP(curlevel+1));
				
				War3_ChatMessage(client,"%T","You are now level {amount}",client,War3_GetLevel(client,race)+1);
				
				new newxp=War3_GetXP(client,race)-W3GetReqXP(curlevel+1);
				War3_SetXP(client,race,newxp); //recurse first!!!! else u set level xp is same and it tries to use that xp again
				
				War3_SetLevel(client,race,War3_GetLevel(client,race)+1); 
				
				
				
				//War3Source_SkillMenu(client);
				
				//PrintToChatAll("LEVEL %d  xp2 %d",War3_GetXP(client,race),ReqLevelXP(curlevel+1));
				if(IsPlayerAlive(client)){
					EmitSoundToAll(levelupSound,client);
				}
				else{
					EmitSoundToClient(client,levelupSound);
				}
				W3CreateEvent(PlayerLeveledUp,client);
			}
			else{
				keepchecking=false;
			}
		}
		else{
			keepchecking=false;
		}

	}
	
	if(W3GetLevelsSpent(client,race)<War3_GetLevel(client,race)){
		//War3Source_SkillMenu(client);
		W3CreateEvent(DoShowSpendskillsMenu,client);
	}

}


ClearSkillLevels(client,race){
	new SkillCount =War3_GetRaceSkillCount(race); 
	for(new i=0;i<SkillCount;i++){
		War3_SetSkillLevel(client,race,i,0);
	}
}








// Stocks
stock StrToken(const String:inputstr[],tokennum,String:outputstr[],maxlen)
{
	new String:buf[maxlen+1];
	new cur_idx;
	new idx;
	new curind;
	idx=BreakString(inputstr,buf,maxlen);
	if(tokennum==1)
	{
		strcopy(outputstr,maxlen,buf);
		return;
	}
	curind=1;
	while(idx!=-1)
	{
		cur_idx+=idx;
		idx=BreakString(inputstr[cur_idx],buf,maxlen);
		curind++;
		if(tokennum==curind)
		{
			strcopy(outputstr,maxlen,buf);
			break;
		}
	}
}

stock StrTokenCount(const String:input[])
{
	decl String:buf[32];
	new cur_idx;
	new idx;
	new curind;
	while(idx!=-1)
	{
		cur_idx+=idx;
		idx=BreakString(input[cur_idx],buf,sizeof(buf));
		curind++;
	}
	return curind;
}

