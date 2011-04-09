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

new bool:bTrapped[MAXPLAYERS];

new SKILL_LEAP, SKILL_REWIND, SKILL_TIMELOCK, ULT_SPHERE;
////we add stuff later

//leap
new Float:leapPower[5]={0.0,300.0,350.0,400.0,450.0};

//rewind
new Float:RewindChance[5]={0.0,0.1,0.15,0.2,0.25}; 
new RewindHPAmount[MAXPLAYERS];

//bash
new Float:TimeLockChance[5]={0.0,0.1,0.15,0.2,0.25};

//sphere
new Float:ultRange=200.0;
new Handle:ultCooldownCvar;
new String:leapsnd[]="war3source/chronos/timeleap.mp3";
new String:spheresnd[]="war3source/chronos/sphere.mp3";


new BeamSprite;
new HaloSprite;

stock oldbuttons[MAXPLAYERS];

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
new glowsprite;
public OnMapStart()
{
	War3_PrecacheSound(leapsnd);
	War3_PrecacheSound(spheresnd);
	glowsprite=PrecacheModel("sprites/strider_blackball.spr");
	
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}

public OnWar3LoadRaceOrItemOrdered(num)
{	
	if(num==1)// why 150?
	{
		thisRaceID=War3_CreateNewRace("Chronos","chronos");
		SKILL_LEAP=War3_AddRaceSkill(thisRaceID,"Time Leap","Leap in the direction you are moving (auto on jump)",false,4);
		SKILL_REWIND=War3_AddRaceSkill(thisRaceID,"Rewind","Chance to regain the damage you took",false,4);
		SKILL_TIMELOCK=War3_AddRaceSkill(thisRaceID,"Time Lock","Chance to stun your enemy",false,4);
		ULT_SPHERE=War3_AddRaceSkill(thisRaceID,"Chronosphere","Rip space and time to trap enemy. Trapped victims cannot move can only receive melle damage, their attack speed is reduced dramatically",true,4); 
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
				
				new Float:endpos[3];
				War3_GetAimTraceMaxLen(client,endpos,ultRange);
				
				new Float:down[3];
				down[0]=endpos[0];
				down[1]=endpos[1];
				down[2]=endpos[2]-200;
				TR_TraceRay(endpos,down,MASK_ALL,RayType_EndPoint);
				TR_GetEndPosition(endpos);
				
				EmitSoundToAll(spheresnd,0,_,_,_,_,_,_,endpos);
				EmitSoundToAll(spheresnd,0,_,_,_,_,_,_,endpos);
				
				new Float:life=10.0;
				
				//new Float:angles[10]={
				//TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{0,255,0,255},10,0);
				new Float:realradius=300.0;
				new Float:radius;
				for(new i=-1;i<=8;i++){
					new Float:rad=float(i*10)/360.0*(3.14159265*2);
					radius=realradius*Cosine(rad);
					new Float:heightoffset=realradius*Sine(rad)/2.0;
					
					//PrintToChatAll("degree %d rad %f sin %f cos %f radius %f offset %f",i*10,rad,Sine(rad),Cosine(rad),radius,heightoffset);
					
					new Float:origin[3];
					origin[0]=endpos[0];
					origin[1]=endpos[1];
					origin[2]=endpos[2]+heightoffset;
					TE_SetupBeamRingPoint(origin, radius-0.1, radius, BeamSprite, HaloSprite, 0, 0, life, 2.0, 0.0, {80,200,255,122}, 10, 0);
					TE_SendToAll();
				}
				
				
				
				
				new Float:victimpos[3];
				new trapcount;
				new team=GetClientTeam(client);
				for(new i=1;i<=MaxClients;i++){
					if(ValidPlayer(i,true)&&GetClientTeam(i)!=team){
						GetClientEyePosition(client,victimpos);
						if(GetVectorDistance(endpos,victimpos)<radius)
						{
							CreateTimer(life,unBashUlt,i);
							War3_SetBuff(i,bBashed,thisRaceID,true);
							War3_SetBuff(i,fAttackSpeed,thisRaceID,0.4);
							
							War3_SetBuff(i,bImmunitySkills,thisRaceID,false);
							War3_SetBuff(i,bImmunityUltimates,thisRaceID,false);
							bTrapped[i]=true;
							PrintHintText(i,"You have been trapped by a Chronosphere!\nYou can only receive Melle damage");
							trapcount++;
						}
					}
				}
				PrintHintText(client,"You trapped %d enemies",trapcount);
				
				TE_SetupGlowSprite(endpos,glowsprite,life,3.57,255);
				TE_SendToAll();
				War3_CooldownMGR(client,0.0,thisRaceID,ULT_SPHERE);
			}
		}
		else
		{
			PrintHintText(client,"Level Your Ultimate First");
		}
	}
}
public Action:unBashUlt(Handle:h,any:client){
	War3_SetBuff(client,bBashed,thisRaceID,false);
	War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
	bTrapped[client]=false;
	War3_SetBuff(client,bImmunitySkills,thisRaceID,false);
	War3_SetBuff(client,bImmunityUltimates,thisRaceID,false);
	
}
public OnW3TakeDmgAll(victim,attacker,Float:damage){
	if(bTrapped[victim]){
		if(ValidPlayer(attacker,true)){
			new wpnent = W3GetCurrentWeaponEnt(attacker);
			if(wpnent>0&&IsValidEdict(wpnent)){
				decl String:WeaponName[32];
				GetEdictClassname(wpnent, WeaponName, 32);
				if(StrContains(WeaponName,"weapon_knife",false)<0){
					
					PrintToChatAll("block");
					War3_DamageModPercent(0.0);
				}
			}
			else{
				PrintToChatAll("block");
				War3_DamageModPercent(0.0);
			}
		}
		else{
			PrintToChatAll("block");
			War3_DamageModPercent(0.0);
		}
	}
}
public OnWar3EventPostHurt(victim,attacker,dmgamount)
{
	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,true))
	{	
		
		new skilllevel=War3_GetSkillLevel(victim,thisRaceID,SKILL_REWIND);
		//we do a chance roll here, and if its less than our limit (RewindChance) we proceede i a with u
		if(War3_GetRace(victim)==thisRaceID && skilllevel>0&& War3_Chance(RewindChance[skilllevel]) && !W3HasImmunity(attacker,Immunity_Skills)&&!Hexed(victim)) //chance roll, and attacker isnt immune to skills
		{
			RewindHPAmount[victim]+=dmgamount;//we create this variable
			PrintHintText(victim,"Rewind +%d HP!",dmgamount);
			W3FlashScreen(victim,RGBA_COLOR_GREEN);
		}
		
		
		new race_attacker=War3_GetRace(attacker);
		skilllevel=War3_GetSkillLevel(attacker,thisRaceID,SKILL_TIMELOCK);
		if(race_attacker==thisRaceID && skilllevel > 0 )
		{
			if(War3_Chance(TimeLockChance[skilllevel])&& !W3HasImmunity(victim,Immunity_Skills) && !Stunned(victim)&&!Hexed(attacker))
			{
				PrintHintText(victim,"You got Time Locked");
				PrintHintText(attacker,"Time Lock!");
				
				
				W3FlashScreen(victim,RGBA_COLOR_BLUE);
				CreateTimer(0.15,UnfreezeStun,victim);
				
				War3_SetBuff(victim,bStunned,thisRaceID,true);
			}
		}
		
	}
}


public Action:UnfreezeStun(Handle:h,any:client) //always keep timer data generic
{
	War3_SetBuff(client,bStunned,thisRaceID,false);
}
public OnWar3EventDeath(victim,attacker){
	RewindHPAmount[victim]=0;
}
new skip;
public OnGameFrame() //this is a sourcemod forward?, every game frame it is called. forwards if u implement it sourcemod will call you
{
	if(skip==0){
	
		for(new i=1;i<=MaxClients;i++){
			if(ValidPlayer(i,true))//valid (in game and shit) and alive (true parameter)k
			{
				if(RewindHPAmount[i]>0){
					War3_HealToMaxHP(i,1);
					RewindHPAmount[i]--;
				}
			}
			
		}
		skip=2;
	}
	skip--;
}

