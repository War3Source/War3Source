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

new SKILL_LEAP, SKILL_REWIND, SKILL_BASH, ULT_SPHERE;
////we add stuff later

//leap
new Float:leapPower[5]={0.0,300.0,350.0,400.0,450.0};

//rewind
new Float:RewindChance[5]={0.0,0.1,0.15,0.2,0.25}; 
new RewindHPAmount[MAXPLAYERS];

//bash
new Float:TimeLockChance[5]={0.0,0.1,0.15,0.2,0.25};

//sphere
new Float:ultRange=200;
new Handle:ultCooldownCvar;
new String:leapsnd[]="war3source/chronos/timeleap.mp3";

new oldbuttons[MAXPLAYERS];

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
		HookEvent("player_jump",PlayerJumpEvent);
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
		SKILL_BASH=War3_AddRaceSkill(thisRaceID,"Time Lock","Chance to stun your enemy",false,4);
		ULT_SPHERE=War3_AddRaceSkill(thisRaceID,"Chronosphere","Rip space and time to trap enemy",true,4); //TEST
		War3_CreateRaceEnd(thisRaceID);
	}
}

public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	PlayerJumped(client);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	/*if ((buttons & IN_JUMP)&&
	(GetEntityFlags(client) & FL_ONGROUND)
	&&
	!(oldbuttons[client] & IN_JUMP))///War3_GetGame() != Game_CS / //assault for non CS games
	{
	PlayerJumped(client);
	}
	oldbuttons[client]=buttons;*/
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
					
					//PrintToChatAll("post vec %f %f %f",velocity[0],velocity[1],velocity[2]);
					SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
					EmitSoundToAll(leapsnd,client);
					EmitSoundToAll(leapsnd,client);
					//War3_CooldownMGR(client,10.0,thisRaceID,SKILL_LEAP,_,_,_,"Time Leap");
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

public OnWar3EventPostHurt(victim,attacker,dmgamount)
{
	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,true)){
		{	
			
			new skilllevel=War3_GetSkillLevel(victim,thisRaceID,SKILL_REWIND);
			//we do a chance roll here, and if its less than our limit (RewindChance) we proceede i a with u
			if(War3_GetRace(victim)==thisRaceID && skilllevel>0&& War3_Chance(RewindChance[skilllevel]) && !W3HasImmunity(attacker,Immunity_Skills)&&!Hexed(victim)) //chance roll, and attacker isnt immune to skills
			{
				RewindHPAmount[victim]+=dmgamount;//we create this variable
				PrintHintText(victim,"Rewind +%d HP!",dmgamount);
			}
			
			
			new race_attacker=War3_GetRace(attacker);
			skilllevel=War3_GetSkillLevel(attacker,thisRaceID,SKILL_BASH);
			if(race_attacker==thisRaceID && skilllevel > 0 )
			{
				if(War3_Chance(TimeLockChance[skilllevel])&& !W3HasImmunity(victim,Immunity_Skills) && !Stunned(victim)&&!Hexed(attacker))
				{
					PrintHintText(victim,"You got Time Locked");
					PrintHintText(attacker,"Time Lock!");
					
					
					W3FlashScreen(victim,RGBA_COLOR_BLUE);
					CreateTimer(0.15,UnfreezeStun,victim);
				}
			}
		}
	}
}

public OnWar3EventSpawn(client){
	
	War3_SetBuff(client,bStunned,thisRaceID,false);
}

public Action:UnfreezeStun(Handle:h,any:client) //always keep timer data generic
{
	
	War3_SetBuff(client,bStunned,thisRaceID,false);
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

