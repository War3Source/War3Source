

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo= 
{
	name="War3Source Engine XP Gold",
	author="Ownz",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};


new Handle:hXPMultiCvar;
new Handle:hMaxLevelCvar;



// not game specific
new Handle:HeadshotXPCvar;
new Handle:MeleeXPCvar;
new Handle:RoundWinXPCvar;
new Handle:AssistKillXPCvar;
new Handle:hLevelDifferenceBounus;

public APLRes:AskPluginLoad2Custom(Handle:myself,bool:late,String:error[],err_max)
{
	GlobalOptionalNatives();
	if(!InitNativesForwards())
	{
		LogError("[War3Source] There was a failure in creating the native / forwards based functions, definately halting.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	if(SH()){
		hXPMultiCvar=CreateConVar("sh_xp_multi","100","how much additional xp required per level");
		hMaxLevelCvar=CreateConVar("sh_maxlevel","10000","What level do people stop gaining XP?")
	
		HeadshotXPCvar=CreateConVar("war3_percent_headshotxp","20","Percent of kill XP awarded additionally for headshots");
		MeleeXPCvar=CreateConVar("war3_percent_meleexp","100","Percent of kill XP awarded additionally for melee/knife kills");
		AssistKillXPCvar=CreateConVar("war3_percent_assistkillxp","75","Percent of kill XP awarded for an assist kill.");
		RoundWinXPCvar=CreateConVar("war3_percent_roundwinxp","100","Percent of kill XP awarded for being on the winning team");
		//DefuseXPCvar=CreateConVar("war3_percent_cs_defusexp","200","Percent of kill XP awarded for defusing the bomb");
		//PlantXPCvar=CreateConVar("war3_percent_cs_plantxp","200","Percent of kill XP awarded for planting the bomb");
		//RescueHostageXPCvar=CreateConVar("war3_percent_cs_hostagerescuexp","100","Percent of kill XP awarded for rescuing a hostage");
		//PointCaptureXPCvar=CreateConVar("war3_percent_tf_pointcapturexp","25","Percent of kill XP awarded to the capturing team");
		//PointCapBlockXPCvar=CreateConVar("war3_percent_tf_blockcapturexp","20","Percent of kill XP awarded for blocking a capture");
		//CaptureFlagXPCvar=CreateConVar("war3_percent_tf_flagcapturexp","100","Percent of kill XP awarded for capturing the flag");
		hLevelDifferenceBounus=CreateConVar("war3_xp_level_difference_bonus","0","Bounus Xp awarded per level if victim has a higher level");
	
		if(!HookEventEx("player_death",War3Source_PlayerDeathEvent,EventHookMode_Pre))
		{
			PrintToServer("[War3Source] Could not hook the player_spawn event.");
		}
		
		if(War3_GetGame()==CS)
		{
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
		}
	}
}

bool:InitNativesForwards()
{
	if(SH()){
		CreateNative("SHGetReqXP",NShGetReqXP);
		CreateNative("SHShowXP",NSHShowXP);
	}
	
	CreateNative("SHMaxLevel",NSHMaxLevel);
	return true;
}
public NShGetReqXP(Handle:plugin,numParams)
{
	new level=GetNativeCell(1);
	return GetConVarInt(hXPMultiCvar)*level
}
public NSHShowXP(Handle:plugin,numParams)
{
	ShowXP(GetNativeCell(1));
}
public NSHMaxLevel(Handle:plugin,numParams){
	return GetConVarInt(hMaxLevelCvar);
}


public ShowXP(client)
{
	
	new level=SHGetLevel(client);
	if(level>=SHMaxLevel()){
		if(level>SHMaxLevel()){
			SHSetLevel(client,SHMaxLevel());
		}
		War3_ChatMessage(client,"Level %d",SHMaxLevel());
		
	}
	else{
		War3_ChatMessage(client,"Level %d - %d XP / %d XP.",level,SHGetXP(client),SHGetReqXP(level+1));
	}

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
	
	new bool:deadringereath=false;
	if(uid_victim>0)
	{
		
		new deathFlags = GetEventInt(event, "death_flags");
		if (War3_GetGame()==Game_TF&&deathFlags & 32)
		{
			deadringereath=deadringereath?true:true; //stfu
		   //PrintToChat(client,"war3 debug: dead ringer kill");
		}
	}
	
	if(uid_victim!=uid_attacker&&uid_attacker>0)
	{
		new victimIndex=GetClientOfUserId(uid_victim);
		new attackerIndex=GetClientOfUserId(uid_attacker);
		
		new assistIndex=0;
		if(uid_assister>0)
		{
			assistIndex=GetClientOfUserId(uid_assister);
		}
		if(GetClientTeam(attackerIndex)!=GetClientTeam(victimIndex))
		{
			decl String:weapon[64];
			GetEventString(event,"weapon",weapon,63);
			new bool:is_hs,bool:is_melee;
		
			if(War3_GetGame()==Game_TF)
			{
				is_hs=(GetEventInt(event,"customkill")==1);
				is_melee=(StrEqual(weapon,"bat",false) ||
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
			}
			else
			{
				is_hs=GetEventBool(event,"headshot");
				is_melee=StrEqual(weapon,"knife");
			}
			if(assistIndex>0)
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
	if(team>1)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			
			if(ValidPlayer(i)&&  GetClientTeam(i)==team)
			{
				new znewxp;
				
				new win_xp=((GetKillXP(SHGetLevel(i))*GetConVarInt(RoundWinXPCvar))/100);
				znewxp=SHGetXP(i)+win_xp;
				
				War3_ChatMessage(i,"You have gained %d XP for being on the winning team.",win_xp);
				SHSetXP(i,znewxp);
				
			}
		}
	}
}

GiveKillXPCreds(client,playerkilled,bool:headshot,bool:melee)
{
	//PrintToChatAll("1");
	new killerlevel=SHGetLevel(client);
	new victimlevel=SHGetLevel(playerkilled);
	
	new killxp=GetKillXP(killerlevel,victimlevel-killerlevel);
	
	new addxp=killxp;
	if(headshot)	addxp+=((killxp*GetConVarInt(HeadshotXPCvar))/100);
	if(melee)		addxp+=((killxp*GetConVarInt(MeleeXPCvar))/100);
	
	
	
	SHSetXP(client,SHGetXP(client)+addxp);
	War3_ChatMessage(client,"You have gained %d XP for killing an enemy.",addxp);

	InternalLevelCheck(client);
}

public GiveAssistKillXP(client)
{

	new killxp=((GetKillXP(SHGetLevel(client))*GetConVarInt(AssistKillXPCvar))/100);
	new addxp=killxp;
	SHSetXP(client,SHGetXP(client)+addxp);

	War3_ChatMessage(client,"You have gained %d XP for assisting a kill.",addxp);
	
	InternalLevelCheck(client);
}

/*
bool:IsShortTerm(){
	return GetConVarInt(Handle:W3GetVar(hSaveEnabledCvar))?false:true;
}*/


//redirect stock
GetKillXP(level,leveldiff=0){
	level+=0;
	leveldiff+=0;
	return 25+((leveldiff>0)?GetConVarInt(hLevelDifferenceBounus):0);
}


InternalLevelCheck(client){
	///seting xp or level recurses!!! SET XP FIRST!! or you will have a cascading level increment
	new keepchecking=true;
	

	while(keepchecking)
	{	
		new curlevel=SHGetLevel(client);
		
		if(curlevel<SHMaxLevel()&&SHGetXP(client)>=SHGetReqXP(curlevel+1))
		{
			//PrintToChatAll("LEVEL %d xp %d reqxp=%d",curlevel,GetXP(client,race),ReqLevelXP(curlevel+1));
			
			War3_ChatMessage(client,"You are now level %d.",SHGetLevel(client)+1);
			
			new newxp=SHGetXP(client)-SHGetReqXP(curlevel+1);
			SHSetXP(client,newxp); //recurse first!!!! else u set level xp is same and it tries to use that xp again
			
			SHSetLevel(client,SHGetLevel(client)+1); 
			
			SHShowCRMenuIfCanChoose(client);
			
			//War3Source_SkillMenu(client);
			
			//PrintToChatAll("LEVEL %d  xp2 %d",GetXP(client,race),ReqLevelXP(curlevel+1));
			if(IsPlayerAlive(client)){
				//EmitSoundToAll(levelupSound,client);
			}
			else{
				//EmitSoundToClient(client,levelupSound);
			}
		}
		else{
			keepchecking=false;
		}

	}
	
}


