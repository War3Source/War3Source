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

new m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity; //offsets

new bool:bIsEntangled[MAXPLAYERS];
new bool:bIsBashed[MAXPLAYERS];
new SKILL_LEAP, SKILL_REWIND, SKILL_BASH, ULT_SPHERE;
////we add stuff later

//leap
new Float:leapPower[5]={0.0,300.0,350.0,400.0,450.0};

//rewind
new Float:RewindChance[5]={0.0,0.1,0.15,0.2,0.25}; 
new RewindHPAmount[MAXPLAYERS];

//bash
new Float:BashChance[5]={0.0,0.1,0.15,0.2,0.25};

//sphere
new Float:ultRange=200;
new Handle:ultCooldownCvar;
new String:leapsnd[]="war3source/chronos/timeleap.mp3";

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
	
	m_vecVelocity_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	m_vecVelocity_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	
	if(War3_GetGame()==CS){
		//HookEvent("player_jump",PlayerJumpEvent);
	}
}

public OnMapStart()
{
	War3_PrecacheSound(leapsnd);
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

public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	PlayerJumped(client);
}
new oldbuttons[MAXPLAYERS];

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if ((buttons & IN_JUMP)&&(GetEntityFlags(client) & FL_ONGROUND)&&!(oldbuttons[client] & IN_JUMP))/*War3_GetGame() != Game_CS */) //assault for non CS games
	{
		PlayerJumped(client);
	}
	oldbuttons[client]=buttons;
}
PlayerJumped(client){
	if(ValidPlayer(client,true)){
		new race=War3_GetRace(client);
		if (race==thisRaceID)
		{
			
			new sl=War3_GetSkillLevel(client,race,SKILL_LEAP);
			
			if(sl>0&&SkillAvailable(client,thisRaceID,SKILL_LEAP))
			{
				
				new Float:velocity[3]={0.0,0.0,0.0};
				velocity[0]= GetEntDataFloat(client,m_vecVelocity_0);
				velocity[1]= GetEntDataFloat(client,m_vecVelocity_1);
				//velocity[0]*=leapPower[sl];
				//velocity[1]*=leapPower[sl];
				//NormalizeVector(velocity,
				new Float:len=GetVectorLength(velocity);
				if(len>3.0){
					//PrintToChatAll("pre  vec %f %f %f",velocity[0],velocity[1],velocity[2]);
					ScaleVector(velocity,leapPower[sl]/len);
					SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
					EmitSoundToAll(leapsnd,client);
					EmitSoundToAll(leapsnd,client);
					War3_CooldownMGR(client,10.0,thisRaceID,SKILL_LEAP,_,_,_,"Time Leap");
				}
			}
		}
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
	War3_SetBuff(client,bBashed,thisRaceID,false);
}

public Action:UnfreezePlayer(Handle:TCisKING,any:client) //always keep timer data generic
{
	if(ValidPlayer(client,true))
	{
		War3_SetBuff(client,bBashed,thisRaceID,false);
		bIsBashed[client]=false;
	}
}


public OnGameFrame() //this is a sourcemod forward?, every game frame it is called. forwards if u implement it sourcemod will call you
{
	for(new i=1;i<=MaxClients;i++){
		if(ValidPlayer(i,true))//valid (in game and shit) and alive (true parameter)k
		{
			if(RewindHPAmount[i]>0){
				War3_HealToMaxHP(i,1);
				
			}
		}
		
	}
}

