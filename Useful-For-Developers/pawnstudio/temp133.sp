/**
* File: War3Source_NightElf.sp
* Description: The Night Elf race for War3Source.
* Author(s): Anthony Iacono 
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface" 
//see u only include this file
#include <sdktools>

new thisRaceID;

new bool:bIsEntangled[MAXPLAYERS];
new bool:bIsBashed[MAXPLAYERS];
new SKILL_LEAP, SKILL_REWIND, SKILL_BASH, ULT_SPHERE;
////we add stuff later

//leap


//rewind
new Float:RewindChance[5]={0.0,0.1,0.15,0.2,0.25}; //an array of data for this skill    array length of five cuz skill has 4 levels wait what if we wanted 6 levels can I just add two to array ? you have to tell war3s this skill is 6 levels i nh tohwe registation process show me
new RewindHPAmount[MAXPLAYERS]; //wtf is this MAXPLAYERS? well its the client index, client 1-64, we use MAXPLAYERS just to be safe ...lame HLTV extends the slot countlol. YOU can use MAXPLAYERS if u wanted, but that is 64 not MAXPLAYERS and u may have trouble in 64 player server
new Float:RewindLastPrintScreen[MAXPLAYERS];
//bash
new Float:BashChance[5]={0.0,0.1,0.15,0.2,0.25};

//sphere

new Handle:ultCooldownCvar;


public Plugin:myinfo = 
{
	name = "War3Source Race - Chronos",
	author = "Ownz",
	description = "Chronos",
	version = "1.0.0.0",
	url = "www.ownageclan.com"
};

public OnPluginStart()
{
	ultCooldownCvar=CreateConVar("war3_chronos_ult_cooldown","20");
}

public OnMapStart()
{
	
}

public OnWar3LoadRaceOrItemOrdered(num)
{	
	if(num==1)// why 150?
	{
		thisRaceID=War3_CreateNewRace("Chronos","chronos");
		SKILL_LEAP=War3_AddRaceSkill(thisRaceID,"Time Leap","Teleport forward",false,4);
		SKILL_REWIND=War3_AddRaceSkill(thisRaceID,"Rewind","Chance to heal the damage you took back",false,4);
		SKILL_BASH=War3_AddRaceSkill(thisRaceID,"Time Lock","Chance to bash your enemy",false,4);
		ULT_SPHERE=War3_AddRaceSkill(thisRaceID,"Chronosphere","Rip space and time to trap enemy",true,4); //TEST
		War3_CreateRaceEnd(thisRaceID);
	}
}



public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && IsPlayerAlive(client) && pressed)
	{
		new skill_level=War3_GetSkillLevel(client,race,ULT_SPHERE);
		if(skill_level>0)
		{
			
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_SPHERE,true)){
				
				//to do:  some crazy stuff and effects here 
			}
		}
		else
		{
			PrintHintText(client,"Level Your Ultimate First");
		}
	}
}

///this is when a player takes damage, but before the damage is actually dealt (what we call a PRE event) we dont actually need it for chonos
//public Action:OnWar3TakeDamage(victim,attacker,inflictor,Float:damage,damagetype)
//{
//}


///this is when a player takes damage (hurt) and is after the player already took damage (POST event)
public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new victimuserid=GetEventInt(event,"userid"); //we have to indvidually get every data from the event
	new attackeruserid=GetEventInt(event,"attacker");
	new dmg=GetEventInt(event,"dmg_health");
	if(War3_GetGame()==Game_TF)
	{
		dmg=GetEventInt(event,"damageamount");
	}
	
	// do i work here and called? if attacker is raceid or do i make a new block instead of hurt to attack or something?
	//new block for attacker
	if(victimuserid&&attackeruserid&&victimuserid!=attackeruserid) //damage is not self dealt
	{
		new victim=GetClientOfUserId(victimuserid); //event is forwarded with userids, we usualy convert them to "client" index (like 1-64 for a 64 person server)
		new attacker=GetClientOfUserId(attackeruserid);
		
		new race_victim=War3_GetRace(victim);
		new skilllevel=War3_GetSkillLevel(victim,thisRaceID,SKILL_REWIND);
		// Evasion
		if(race_victim==thisRaceID && skilllevel>0 && GetClientHealth(victim)>0) //if this person is actually our race...and has a level in our skill of interest
		{
			//we do a chance roll here, and if its less than our limit (RewindChance) we proceede i a with u
			if(GetRandomFloat(0.0,1.0)<=RewindChance[skilllevel] && !W3HasImmunity(attacker,Immunity_Skills)) //chance roll, and attacker isnt immune to skills
			{
				RewindHPAmount[victim]+=dmg;//we create this variable
				PrintHintText(victim,"Rewind Mutha Fucka");
				/// the += operator means
				// variable = variable + 2nd variable
				// variable+=2nd variable
				//i want to add 5 to variable "omfg"
				// omfg+=5; ok but victim is the client why add dmg, is dmg part of sm
				//we are not adding damage, but adding the amount of  hp he should recieve back in OnGameFrame ok but did we tell game to make that variable dmg or hp ? 
				//u create these varibles , these are plugin vairables and do nothing in game  itself did we create alreadyy? create what? that varaible yes with the keyword "new"
				// but we didnt give it any rela value just [MAXPLAYERS] , u mean rewindhp amount? we leave it blank, default is 0 so then waht will this command do to it? =+ dmg
				//RewindHPAmount[victim]=RewindHPAmount[victim]+dmg; couldnt we just do rewindhpamount = dmg ?
				//no because that variable is not a player property in game, it has nothing to do with in game variables or properties. variables u declare are for your plugin only.are u refering to reiwind or thwheree dmg ? both are ur own plugin variables a.re we gona define dmg? we defined dmg.
			}
		}
		
		
		// let me try
		
		new race_attacker=War3_GetRace(attacker);
		skilllevel=War3_GetSkillLevel(attacker,thisRaceID,SKILL_BASH);
		if(race_attacker==thisRaceID && skilllevel > 0 && IsPlayerAlive(victim))
		{
			if(GetRandomFloat(0.0,1.0)<=BashChance[skilllevel] && !W3HasImmunity(victim,Immunity_Skills) && !bIsBashed[victim])
			{
				PrintHintText(victim,"You got Bashed");
				PrintHintText(attacker,"Bash!");
				bIsBashed[victim]=true;
				SetEntityMoveType(victim,MOVETYPE_NONE);
				W3FlashScreen(victim,RGBA_COLOR_GREEN);
				CreateTimer(0.25,UnfreezePlayer,victim);
			}
		}
	}
}

public OnWar3EventSpawn(client){
	bIsBashed[client]=false;
	SetEntityMoveType(client,MOVETYPE_WALK);
}

public Action:UnfreezePlayer(Handle:TCisKING,any:client) //always keep timer data generic
{
	if(ValidPlayer(client,true))
	{
		SetEntityMoveType(client,MOVETYPE_WALK);
		bIsBashed[client]=false;
	}
}


public OnGameFrame() //this is a sourcemod forward?, every game frame it is called. forwards if u implement it sourcemod will call you
{
	for(new i=1;i<=MaxClients;i++){//MaxClients is a variable assigned by sourcemod depending on the slot count of the server so ur looping from 1 client to all clients? yesk
		if(ValidPlayer(i,true))//valid (in game and shit) and alive (true parameter)k
		{
			if(RewindHPAmount[i]>0){
				War3_HealToMaxHP(i,1); //A FEW Q ok now what is +=dmg so here we say if it has a value above 0
				// then we heal player 20 per second to max? yes, and decreashmm oke rewindhpamount so he doesnt heal infinitely.hmm ok
				//its not exactly 20 hp / second, just looks like some amount in a short time,  uyeall 
				RewindHPAmount[i]--;
				if(RewindLastPrintScreen[i]<GetGameTime()+0.4)//lets say 5 time per second it stays green
				{
					
				}
			}
		}
		
	}
}

///and we are done with our (second skill) let me look for a seconfd see if ihave ques
