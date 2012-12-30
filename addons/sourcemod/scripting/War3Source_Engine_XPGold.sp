#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON
#pragma tabsize 0     // doesn't mess with how you format your lines

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo= 
{
	name="W3S Engine XP Gold",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};

new String:levelupSound[256]; //="war3source/levelupcaster.mp3";


///MAXLEVELXPDEFINED is in constants
new XPLongTermREQXP[MAXLEVELXPDEFINED+1]; //one extra for even if u reached max level
new XPLongTermKillXP[MAXLEVELXPDEFINED+1];
new XPShortTermREQXP[MAXLEVELXPDEFINED+1];
new XPShortTermKillXP[MAXLEVELXPDEFINED+1];


// not game specific
new Handle:HeadshotXPCvar; 
new Handle:MeleeXPCvar;
new Handle:RoundWinXPCvar;
new Handle:AssistKillXPCvar;
new Handle:BotIgnoreXPCvar;
new Handle:hLevelDifferenceBounus;
new Handle:minplayersXP;
new Handle:NoSpendSkillsLimitCvar;

// l4d
new Handle:KillSmokerXPCvar;
new Handle:KillBoomerXPCvar;
new Handle:KillHunterXPCvar;
new Handle:KillJockeyXPCvar;
new Handle:KillSpitterXPCvar;
new Handle:KillChargerXPCvar;
new Handle:KillCommonXPCvar;
new Handle:KillUncommonXPCvar;
new MZombieClass;

//gold 
new Handle:MaxGoldCvar;
new Handle:KillGoldCvar;
new Handle:AssistGoldCvar;



public OnPluginStart()
{
	
	BotIgnoreXPCvar=CreateConVar("war3_ignore_bots_xp","0","Set to 1 to not award XP for killing bots");
	HeadshotXPCvar=CreateConVar("war3_percent_headshotxp","20","Percent of kill XP awarded additionally for headshots");
	MeleeXPCvar=CreateConVar("war3_percent_meleexp","120","Percent of kill XP awarded additionally for melee/knife kills");
	AssistKillXPCvar=CreateConVar("war3_percent_assistkillxp","75","Percent of kill XP awarded for an assist kill.");

	RoundWinXPCvar=CreateConVar("war3_percent_roundwinxp","100","Percent of kill XP awarded for being on the winning team");

	hLevelDifferenceBounus=CreateConVar("war3_xp_level_difference_bonus","0","Bounus Xp awarded per level if victim has a higher level");
	minplayersXP=CreateConVar("war3_min_players_xp_gain","2","minimum amount of players needed on teams for people to gain xp");
	MaxGoldCvar=CreateConVar("war3_maxgold","1000");
	
	KillGoldCvar=CreateConVar("war3_killgold","2");
	AssistGoldCvar=CreateConVar("war3_assistgold","1");
	
	ParseXPSettingsFile();
	
	// l4d
	KillSmokerXPCvar=CreateConVar("war3_l4d_smokerxp","50","XP awarded to a player killing a Smoker");
	KillBoomerXPCvar=CreateConVar("war3_l4d_boomerxp","50","XP awarded to a player killing a Boomer");
	KillHunterXPCvar=CreateConVar("war3_l4d_hunterxp","50","XP awarded to a player killing a Hunter");
	KillJockeyXPCvar=CreateConVar("war3_l4d_jockeyexp","50","XP awarded to a player killing a Jockey");
	KillSpitterXPCvar=CreateConVar("war3_l4d_spitterxp","50","XP awarded to a player killing a Spitter");
	KillChargerXPCvar=CreateConVar("war3_l4d_chargerexp","50","XP awarded to a player killing a Charger");
	KillCommonXPCvar=CreateConVar("war3_l4d_commonexp","5","XP awarded to a player killing a common infected");
	KillUncommonXPCvar=CreateConVar("war3_l4d_uncommonexp","10","XP awarded to a player killing a uncommon infected");
	
	 
	if(War3_GetGame()==CS){
		
		if(!HookEventEx("round_end",War3Source_RoundOverEvent))
		{
			PrintToServer("[War3Source] Could not hook the round_end event.");
		}
	}
	
	else if(War3_GetGame()==Game_TF)
	{
		if(!HookEventEx("teamplay_round_win",War3Source_RoundOverEvent)) //usual win xp
		{
			PrintToServer("[War3Source] Could not hook the teamplay_round_win event.");
			
		}
	}
	else if(War3_IsL4DEngine())
	{		
		MZombieClass = FindSendPropInfo("CTerrorPlayer", "m_zombieClass");
	}
}
public OnMapStart()
{
	if(GAMECSGO){
		strcopy(levelupSound,sizeof(levelupSound),"music/war3source/levelupcaster.mp3");
	}
	else
	{
		strcopy(levelupSound,sizeof(levelupSound),"war3source/levelupcaster.mp3");
	}

	War3_PrecacheSound(levelupSound);
}
public bool:InitNativesForwards()
{
	CreateNative("W3GetReqXP" ,NW3GetReqXP);
	CreateNative("War3_ShowXP",Native_War3_ShowXP);
	CreateNative("W3GetKillXP",NW3GetKillXP);

	CreateNative("W3GetMaxGold",NW3GetMaxGold);
	CreateNative("W3GetKillGold",NW3GetKillGold);
	CreateNative("W3GetAssistGold",NW3GetAssistGold);
	CreateNative("W3GiveXPGold",NW3GiveXPGold);
	
	return true;
}
public NW3GetReqXP(Handle:plugin,numParams)
{
	new level=GetNativeCell(1);
	if(level>MAXLEVELXPDEFINED)
		level=MAXLEVELXPDEFINED;
	return IsShortTerm()?XPShortTermREQXP[level] :XPLongTermREQXP[level];
}
public NW3GetKillXP(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new race=War3_GetRace(client);
	if(race>0){
		new level=War3_GetLevel(client,race);
		if(level>MAXLEVELXPDEFINED)
			level=MAXLEVELXPDEFINED;
		new leveldiff=	GetNativeCell(2);
		
		if(leveldiff<0) leveldiff=0;
		
		return (IsShortTerm()?XPShortTermKillXP[level] :XPLongTermKillXP[level]) + (GetConVarInt(hLevelDifferenceBounus)*leveldiff);
	}
	return 0;
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
	new W3XPAwardedBy:awardby=W3XPAwardedBy:GetNativeCell(2);
	new xp=GetNativeCell(3);
	new gold=GetNativeCell(4);
	new String:strreason[64];
	GetNativeString(5,strreason,sizeof(strreason));
	TryToGiveXPGold(client,awardby,xp,gold,strreason);
	
}


public NW3GetKillGold(Handle:plugin,args){
	return GetConVarInt(KillGoldCvar);
}
public NW3GetAssistGold(Handle:plugin,args){
	return GetConVarInt(AssistGoldCvar);
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
		XPLongTermREQXP[x-1]=StringToInt(temp_iter);
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
	SetTrans(client);
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
//main plugin forwards this, does not forward on spy dead ringer, blocks double forward within same frame of same victim
public OnWar3EventDeath(victim,attacker){
	new Handle:event=W3GetVar(SmEvent);
	if(War3_IsL4DEngine())
	{
		if (attacker > 0 && GetClientTeam(attacker) == TEAM_SURVIVORS)
		{
			
			new bool:is_hs = GetEventBool(event,"headshot");		
			
			decl String:victimclass[32];
			GetEventString(event, "victimname", victimclass, sizeof(victimclass));
			
			new EventZombieClass = GetEntData(victim, MZombieClass);
			
			if (StrEqual(victimclass, "Infected"))
			{
				if (War3_IsUncommonInfected(GetEventInt(event, "entityid")))
				{
					new addxp = GetConVarInt(KillUncommonXPCvar);
					if(is_hs) addxp += ((addxp*GetConVarInt(HeadshotXPCvar))/100);
					
					new String:killaward[64];
					Format(killaward,sizeof(killaward),"%T","killing a uncommon infected",attacker);
					W3GiveXPGold(attacker,XPAwardByKill,addxp,0,killaward);
				}
				else
				{
					new addxp = GetConVarInt(KillCommonXPCvar);
					if(is_hs) addxp += ((addxp*GetConVarInt(HeadshotXPCvar))/100);
					
					new String:killaward[64];
					Format(killaward,sizeof(killaward),"%T","killing a common infected",attacker);
					W3GiveXPGold(attacker,XPAwardByKill,addxp,0,killaward);
				}
			}
			else if (StrEqual(victimclass, "Smoker"))
			{
				new addxp = GetConVarInt(KillSmokerXPCvar);
				new addgold = GetConVarInt(KillGoldCvar);
				if(is_hs) addxp += ((addxp*GetConVarInt(HeadshotXPCvar))/100);
				
				new String:killaward[64];
				Format(killaward,sizeof(killaward),"%T","killing a Smoker",attacker);
				
				if (ValidPlayer(victim) && IsFakeClient(victim))
					W3GiveXPGold(attacker,XPAwardByKill,addxp,addgold,killaward);
				else
					GiveKillXPCreds(attacker, victim, false, false);
			}
			else if (StrEqual(victimclass, "Boomer"))
			{
				new addxp = GetConVarInt(KillBoomerXPCvar);
				new addgold = GetConVarInt(KillGoldCvar);
				if(is_hs) addxp += ((addxp*GetConVarInt(HeadshotXPCvar))/100);
				
				new String:killaward[64];
				Format(killaward,sizeof(killaward),"%T","killing a Boomer",attacker);

				if (ValidPlayer(victim) && IsFakeClient(victim))
					W3GiveXPGold(attacker,XPAwardByKill,addxp,addgold,killaward);
				else
					GiveKillXPCreds(attacker, victim, false, false);
			}
			else if (StrEqual(victimclass, "Witch"))
			{
				return; // witch is handled in its own event
			}
			else if (StrEqual(victimclass, "Tank"))
			{
				return; // tank is handled in its own event
			}
			else if (StrEqual(victimclass, "Hunter"))
			{
				new addxp = GetConVarInt(KillHunterXPCvar);
				new addgold = GetConVarInt(KillGoldCvar);
				if(is_hs) addxp += ((addxp*GetConVarInt(HeadshotXPCvar))/100);
				
				new String:killaward[64];
				Format(killaward,sizeof(killaward),"%T","killing a Hunter",attacker);

				if (ValidPlayer(victim) && IsFakeClient(victim))
					W3GiveXPGold(attacker,XPAwardByKill,addxp,addgold,killaward);
				else
					GiveKillXPCreds(attacker, victim, false, false);
			}				
			else if (StrEqual(victimclass, "Spitter"))
			{
				PrintToChatAll("WHAT THE FUCK?");
			}
			else if (StrEqual(victimclass, "Jockey"))
			{
				new addxp = GetConVarInt(KillJockeyXPCvar);
				new addgold = GetConVarInt(KillGoldCvar);
				if(is_hs) addxp += ((addxp*GetConVarInt(HeadshotXPCvar))/100);
				
				new String:killaward[64];
				Format(killaward,sizeof(killaward),"%T","killing a Jockey",attacker);

				if (ValidPlayer(victim) && IsFakeClient(victim))
					W3GiveXPGold(attacker,XPAwardByKill,addxp,addgold,killaward);
				else
					GiveKillXPCreds(attacker, victim, false, false);
			}
			else if (StrEqual(victimclass, "Charger"))
			{
				if (EventZombieClass == 4)
				{
					new addxp = GetConVarInt(KillSpitterXPCvar);
					new addgold = GetConVarInt(KillGoldCvar);
					if(is_hs) addxp += ((addxp*GetConVarInt(HeadshotXPCvar))/100);
					
					new String:killaward[64];
					Format(killaward,sizeof(killaward),"%T","killing a Spitter",attacker);

					if (ValidPlayer(victim) && IsFakeClient(victim))
						W3GiveXPGold(attacker,XPAwardByKill,addxp,addgold,killaward);
					else
						GiveKillXPCreds(attacker, victim, false, false);
				}
				else
				{
					new addxp = GetConVarInt(KillChargerXPCvar);
					new addgold = GetConVarInt(KillGoldCvar);
					if(is_hs) addxp += ((addxp*GetConVarInt(HeadshotXPCvar))/100);
					
					new String:killaward[64];
					Format(killaward,sizeof(killaward),"%T","killing a Charger",attacker);
	
					if (ValidPlayer(victim) && IsFakeClient(victim))
						W3GiveXPGold(attacker,XPAwardByKill,addxp,addgold,killaward);
					else
						GiveKillXPCreds(attacker, victim, false, false);
				}
			}
		}
		// finished with l4d xp stuff, everything else is related to other games
		return;
	}
	
	//DP("get event %d",event);
	new assister=0;
	if(War3_GetGame()==Game_TF)
	{
		assister=GetClientOfUserId(GetEventInt(event,"assister"));
	}

	if(victim!=attacker&&ValidPlayer(attacker))
	{
		
		if(GetClientTeam(attacker)!=GetClientTeam(victim))
		{
			decl String:weapon[64];
			GetEventString(event,"weapon",weapon,sizeof(weapon));
			new bool:is_hs,bool:is_melee;
			if(IsFakeClient(victim) && GetConVarBool(BotIgnoreXPCvar))
				return;
			if(War3_GetGame()==Game_TF)
			{
				is_hs=(GetEventInt(event,"customkill")==1);
				
			}
			else
			{
				is_hs=GetEventBool(event,"headshot");
				
			}
			//DP("wep %s",weapon);
			is_melee=W3IsDamageFromMelee(weapon);
			//DP("me %d",is_melee);
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
					
			if(assister>=0 && War3_GetRace(assister)>0)
			{
				GiveAssistKillXP(assister);
			}
			
			GiveKillXPCreds(attacker,victim,is_hs,is_melee);
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
				new addxp=((  W3GetKillXP(i)*GetConVarInt(RoundWinXPCvar)  )/100);
				
				new String:teamwinaward[64];
				Format(teamwinaward,sizeof(teamwinaward),"%T","being on the winning team",i);
				W3GiveXPGold(i,XPAwardByWin,addxp,0,teamwinaward);
			
			}
		}
	}
}















//fire event and allow addons to modify xp and gold
TryToGiveXPGold(client,W3XPAwardedBy:awardedfromevent,xp,gold,String:awardedprintstring[]){
	new race=War3_GetRace(client);
	if(race>0){
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
		
		if(addxp<0&&War3_GetXP(client,War3_GetRace(client)) +addxp<0){ //negative xp?
			addxp=-1*War3_GetXP(client,War3_GetRace(client));
		}
		
		War3_SetXP(client,race,War3_GetXP(client,War3_GetRace(client))+addxp);
	
		new oldgold=War3_GetGold(client);
		new newgold=oldgold+addgold;
		new maxgold=GetConVarInt(MaxGoldCvar);
		if(newgold>maxgold)
		{
			newgold=maxgold;
			addgold=newgold-oldgold;
		}
		War3_SetGold(client,oldgold+addgold);
		if(addxp>0&&addgold>0)
			War3_ChatMessage(client,"%T","You have gained {amount} XP and {amount} gold for {award}",client,addxp,addgold,awardedprintstring);
		else if(addxp>0)
			War3_ChatMessage(client,"%T","You have gained {amount} XP for {award}",client,addxp,awardedprintstring);
		else if(addgold>0){
			War3_ChatMessage(client,"%T","You have gained {amount} gold for {award}",client,addgold,awardedprintstring);
		}
		
		else if(addxp<0&&addgold<0)
			War3_ChatMessage(client,"%T","You have lost {amount} XP and {amount} gold for {award}",client,addxp,addgold,awardedprintstring);
		else if(addxp<0)
			War3_ChatMessage(client,"%T","You have lost {amount} XP for {award}",client,addxp,awardedprintstring);
		else if(addgold<0){
			War3_ChatMessage(client,"%T","You have lost {amount} gold for {award}",client,addgold,awardedprintstring);
		}
		
		//if(War3_GetLevel(client,race)!=W3GetRaceMaxLevel(race))
		W3DoLevelCheck(client); //in case they didnt level any skills
		
		W3CreateEvent(OnPostGiveXPGold,client);	
	}
	else{
		ShowChangeRaceMenu(client);
	}
	return;
}









GiveKillXPCreds(client,playerkilled,bool:headshot,bool:melee)
{
	//PrintToChatAll("1");
	new race=War3_GetRace(client);
	if(race>0){
		new killerlevel=War3_GetLevel(client,War3_GetRace(client));
		new victimlevel=War3_GetLevel(playerkilled,War3_GetRace(playerkilled));
		
		new killxp=W3GetKillXP(client,victimlevel-killerlevel);
		
		new addxp=killxp;
		if(headshot)	addxp+=((killxp*GetConVarInt(HeadshotXPCvar))/100);
		if(melee)		addxp+=((killxp*GetConVarInt(MeleeXPCvar))/100);
		
	
		
		new String:killaward[64];
		Format(killaward,sizeof(killaward),"%T","a kill",client);
		W3GiveXPGold(client,XPAwardByKill,addxp,W3GetKillGold(),killaward);
	}
}

public GiveAssistKillXP(client)
{

	new addxp=((W3GetKillXP(client)*GetConVarInt(AssistKillXPCvar))/100);
	
	new String:helpkillaward[64];
	Format(helpkillaward,sizeof(helpkillaward),"%T","assisting a kill",client);
	W3GiveXPGold(client,XPAwardByAssist,addxp,W3GetAssistGold(),helpkillaward);
}

bool:IsShortTerm(){
	return GetConVarInt(Handle:W3GetVar(hSaveEnabledCvar))?false:true;
}















public OnWar3Event(W3EVENT:event,client){
	if(event==DoLevelCheck){
		LevelCheck(client);
	}
}


LevelCheck(client){
	new race=War3_GetRace(client);
	if(race>0){
		new skilllevel;
		
		new ultminlevel=W3GetMinUltLevel();
		
		///skill or ult is more than what he can be? ie level 4 skill when he is only level 4...
		new curlevel=War3_GetLevel(client,race);
		new SkillCount = War3_GetRaceSkillCount(race);
		for(new i=1;i<=SkillCount;i++){
			skilllevel=War3_GetSkillLevelINTERNAL(client,race,i);
			if(!War3_IsSkillUltimate(race,i))
			{
            // El Diablo: I want to be able to allow skills to reach maximum skill level via skill points.
            //            I do not want to put a limit on skill points because of the
            //            direction I'm going with my branch of the war3source.
                NoSpendSkillsLimitCvar=FindConVar("war3_no_spendskills_limit");
                if (!GetConVarBool(NoSpendSkillsLimitCvar))
                {
				    if(skilllevel*2>curlevel+1)
                    {
				     ClearSkillLevels(client,race);
				     War3_ChatMessage(client,"%T","A skill is over the maximum level allowed for your current level, please reselect your skills",client);
				     W3CreateEvent(DoShowSpendskillsMenu,client);
				    }
                }
			}
			else
			{
            // El Diablo: Currently keeping the limit on the ultimates
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
					War3_SetXP(client,race,newxp); //set xp first, else infinite level!!! else u set level xp is same and it tries to use that xp again
					
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
}


ClearSkillLevels(client,race){
	new SkillCount =War3_GetRaceSkillCount(race); 
	for(new i=1;i<=SkillCount;i++){
		War3_SetSkillLevelINTERNAL(client,race,i,0);
	}
}








