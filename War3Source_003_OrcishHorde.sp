/**
 * File: War3Source_OrcishHorde.sp
 * Description: The Orcish Horde race for War3Source.
 * Author(s): Anthony Iacono 
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>


#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS
public W3ONLY(){} //unload this?
new thisRaceID;
new bool:bHasRespawned[MAXPLAYERSCUSTOM]; //cs
new Handle:RespawnDelayCvar;
new Handle:ultCooldownCvar;

new bool:bBeenHit[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; // [caster][victim] been hit this chain lightning?


new MyWeaponsOffset,AmmoOffset;
//Clip1Offset


// Chance/Data Arrays
new Float:ReincarnationChance[5]={0.0,0.15,0.37,0.59,0.8};
new Float:CriticalStrikePercent[5]={0.0,0.33,0.66,1.01,1.33}; 
new Float:CriticalGrenadePercent[5]={0.0,0.7,1.2,1.7,2.2};
new Float:ChainDistance[5]={0.0,150.0,200.0,250.0,300.0};


new Float:WindWalkAlpha[5]={1.0,0.84,0.68,0.56,0.40};
new Float:WindWalkVisibleDuration[5]={5.0,4.2,3.4,2.6,2.0};
// TF2 Specific
new Float:WindWalkReinvisTime[MAXPLAYERSCUSTOM]; //when can he invis again?

new Handle:hCvarDisableCritWithGloves;

// Healing Ward Specific
#define MAXWARDS 64*4 //on map LOL
#define WARDRADIUS 70
#define WARDHEAL 4
#define WARDBELOW -2.0 // player is 60 units tall about (6 feet)
#define WARDABOVE 160.0
new CurrentWardCount[MAXPLAYERSCUSTOM];
new WardStartingArr[]={0,1,2,3,4}; 
new Float:WardLocation[MAXWARDS][3]; 
new WardOwner[MAXWARDS];

new String:lightningSound[]="war3source/lightningbolt.wav";

new SKILL_CRIT,SKILL_NADE_INVIS,SKILL_RECARN_WARD,ULT_LIGHTNING;
// Effects
new BeamSprite,HaloSprite; 

new bool:flashedscreen[MAXPLAYERSCUSTOM];

public Plugin:myinfo = 
{
	name = "Race - Orcish Horde",
	author = "PimpinJuice",
	description = "The Orcish Horde race for War3Source.",
	version = "1.0.0.0",
	url = "http://war3source.com"
};

public OnPluginStart()
{  

	HookEvent("round_start",RoundStartEvent);
	RespawnDelayCvar=CreateConVar("war3_orc_respawn_delay","1","How long before spawning for reincarnation?");
	ultCooldownCvar=CreateConVar("war3_orc_chain_cooldown","20","Cooldown time for chain lightning.");

	hCvarDisableCritWithGloves=CreateConVar("war3_orc_nocritgloves","1","Disable nade crit with gloves");
	
	MyWeaponsOffset=FindSendPropOffs("CBaseCombatCharacter","m_hMyWeapons");
//	Clip1Offset=FindSendPropOffs("CBaseCombatWeapon","m_iClip1");
	AmmoOffset=FindSendPropOffs("CBasePlayer","m_iAmmo");
	CreateTimer(1.0,CalcWards,_,TIMER_REPEAT);
	CreateTimer(0.1,DeciSecondTimer,_,TIMER_REPEAT);
	
	LoadTranslations("w3s.race.orc.phrases");
}  
   

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==30)
	{
	
		new String:skill1_name[64]="CriticalGrenade";
		new String:skill2_name[64]="Reincarnation";
		if(War3_GetGame()==Game_TF)
		{
			strcopy(skill1_name,64,"WindWalker");
			strcopy(skill2_name,64,"HealingWard");
		}
		

		/*thisRaceID=War3_CreateNewRace("Orcish Horde","orc");
		SKILL_CRIT=War3_AddRaceSkill(thisRaceID,"Critical Strike","Chance of doing critical damage",false,4);
		SKILL_NADE_INVIS=War3_AddRaceSkill(thisRaceID,skill1_name,skill1_desc,false,4);
		SKILL_RECARN_WARD=War3_AddRaceSkill(thisRaceID,skill2_name,skill2_desc,false,4);
		ULT_LIGHTNING=War3_AddRaceSkill(thisRaceID,"Chain Lightning","Discharges a bolt of lightning that jumps\nnearby enemies 150-300 units in range,\ndealing each damage",true,4); //TEST
		*/
		
		thisRaceID=War3_CreateNewRaceT("orc");
		SKILL_CRIT=War3_AddRaceSkillT(thisRaceID,"CriticalStrike",false,4);
		SKILL_NADE_INVIS=War3_AddRaceSkillT(thisRaceID,skill1_name,false,4);
		SKILL_RECARN_WARD=War3_AddRaceSkillT(thisRaceID,skill2_name,false,4);
		ULT_LIGHTNING=War3_AddRaceSkillT(thisRaceID,"ChainLightning",true,4); //TEST
		
		
		W3SkillCooldownOnSpawn(thisRaceID,ULT_LIGHTNING,10.0,_); //translated doesnt use this "Chain Lightning"?
		War3_CreateRaceEnd(thisRaceID);
	
	}
}

public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	
	War3_PrecacheSound(lightningSound);
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID && War3_GetGame()==Game_TF)
	{
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0); // for tf2, remove alpha
		War3_SetBuff(client,bInvisibilityDenySkill,thisRaceID,false);
		WindWalkReinvisTime[client]=0.0;
	}
}



public DoChain(client,Float:distance,dmg,bool:first_call,last_target)
{
	new target=0;
	new Float:target_dist=distance+1.0; // just an easy way to do this
	new caster_team=GetClientTeam(client);
	new Float:start_pos[3];
	if(last_target<=0)
		GetClientAbsOrigin(client,start_pos);
	else
		GetClientAbsOrigin(last_target,start_pos);
	for(new x=1;x<=MaxClients;x++)
	{
		if(ValidPlayer(x,true)&&!bBeenHit[client][x]&&caster_team!=GetClientTeam(x)&&!W3HasImmunity(x,Immunity_Ultimates))
		{
			new Float:this_pos[3];
			GetClientAbsOrigin(x,this_pos);
			new Float:dist_check=GetVectorDistance(start_pos,this_pos);
			if(dist_check<=target_dist)
			{
				// found a candidate, whom is currently the closest
				target=x;
				target_dist=dist_check;
			}
		}
	}
	if(target<=0)
	{
		// no target, if first call dont do cooldown
		if(first_call)
		{
			W3MsgNoTargetFound(client,distance);
		}
		else
		{
			// alright, time to cooldown
			new Float:cooldown=GetConVarFloat(ultCooldownCvar);
			War3_CooldownMGR(client,cooldown,thisRaceID,ULT_LIGHTNING,_,_);
		}
	}
	else
	{
		// found someone
		bBeenHit[client][target]=true; // don't let them get hit twice
		War3_DealDamage(target,dmg,client,DMG_ENERGYBEAM,"chainlightning");
		PrintHintText(target,"%T","Hit by Chain Lightning -{amount} HP",target,War3_GetWar3DamageDealt());
		start_pos[2]+=30.0; // offset for effect
		new Float:target_pos[3];
		GetClientAbsOrigin(target,target_pos);
		target_pos[2]+=30.0;
		TE_SetupBeamPoints(start_pos,target_pos,BeamSprite,HaloSprite,0,35,1.0,40.0,40.0,0,40.0,{255,100,255,255},40);
		TE_SendToAll();
		EmitSoundToAll( lightningSound , target,_,SNDLEVEL_TRAIN);
		new new_dmg=RoundFloat(float(dmg)*0.66);
		
		DoChain(client,distance,new_dmg,false,target);
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client))
	{
		new skill=War3_GetSkillLevel(client,race,ULT_LIGHTNING);
		if(skill>0)
		{
			
			if(War3_SkillNotInCooldown(client,thisRaceID,3,true)&&!Silenced(client))
			{
					
				for(new x=1;x<=MaxClients;x++)
					bBeenHit[client][x]=false;
				
				new Float:distance=ChainDistance[skill];
				
				DoChain(client,distance,60,true,0); // This function should also handle if there aren't targets
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}


public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetGame()==Game_TF && War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_RECARN_WARD);
		if(skill_level>0&&!Silenced(client))
		{
			if(CurrentWardCount[client]<WardStartingArr[skill_level])
			{
				CreateWard(client);
				CurrentWardCount[client]++;
				
				W3MsgCreatedWard(client,CurrentWardCount[client],WardStartingArr[skill_level]);
			}
			else
			{
				W3MsgNoWardsLeft(client);
			}	
		}
	}
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	if(War3_GetGame()==Game_TF&&race==thisRaceID&&skill==SKILL_NADE_INVIS&&newskilllevel>=0&&War3_GetRace(client)==thisRaceID)
	{
		new Float:alpha=WindWalkAlpha[newskilllevel];
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,alpha);
		War3_SetBuff(client,bInvisibilityDenySkill,thisRaceID,false);
		WindWalkReinvisTime[client]=0.0;
		if(newskilllevel>0 && IsPlayerAlive(client)) // dont tell them if they are dead
		{
			if(newskilllevel==1)
			{
				War3_ChatMessage(client,"%T","You fade slightly into the backdrop",client);
			}
			else if(newskilllevel==2)
			{
				War3_ChatMessage(client,"%T","You fade well into the backdrop",client);
			}
			else if(newskilllevel==3)
			{
				War3_ChatMessage(client,"%T","You fade greatly into the backdrop",client);
			}
			else
			{
				War3_ChatMessage(client,"%T","You fade dramatically into the backdrop",client);
			}
		}
	}
}

public OnWar3EventSpawn(client)
{
	RemoveWards(client);
	for(new x=1;x<=MaxClients;x++)
		bBeenHit[client][x]=false;
	
	if(War3_GetGame()==Game_TF && War3_GetRace(client)==thisRaceID)
	{
		new skill_wind=War3_GetSkillLevel(client,thisRaceID,SKILL_NADE_INVIS);
		if(skill_wind>0)
		{
			new Float:alpha=WindWalkAlpha[skill_wind];
			War3_SetBuff(client,fInvisibilitySkill,thisRaceID,alpha);
			//War3_ChatMessage(client,"You fade %s into the backdrop.",(skill_wind==1)?"slightly":(skill_wind==2)?"well":(skill_wind==3)?"greatly":"dramatically");
			War3_SetBuff(client,bInvisibilityDenySkill,thisRaceID,false);
		}
	}
	WindWalkReinvisTime[client]=0.0; 
}


public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new Float:chance_mod=W3ChanceModifier(attacker);
			if(race_attacker==thisRaceID)
			{
				new skill_cs_attacker=War3_GetSkillLevel(attacker,race_attacker,SKILL_CRIT);
				if(skill_cs_attacker>0&&!Hexed(attacker,false))
				{
					new Float:chance=0.15*chance_mod;
					if( GetRandomFloat(0.0,1.0)<=chance && !W3HasImmunity(victim,Immunity_Skills))
					{
						new Float:percent=CriticalStrikePercent[skill_cs_attacker]; //0.0 = zero effect -1.0 = no damage 1.0=double damage
						new health_take=RoundFloat(damage*percent);
						//new new_health=GetClientHealth(victim)-health_take;
						//if(new_health<0)
						//	new_health=0;
						//SetEntityZHealth(victim,new_health);
						if(War3_DealDamage(victim,health_take,attacker,_,"orccrit",W3DMGORIGIN_SKILL,W3DMGTYPE_PHYSICAL,true))
						{	
							W3PrintSkillDmgHintConsole(victim,attacker,War3_GetWar3DamageDealt(),"Critical Strike");
							
							
							/*War3_DamageModPercent(percent);
							PrintToConsole(attacker,"%.1fX Critical ! ",percent+1.0);
							PrintHintText(attacker,"Critical !",percent+1.0);
							
							PrintToConsole(victim,"Received %.1fX Critical Dmg!",percent+1.0);
							PrintHintText(victim,"Received Critical Dmg!");
							*/
							
							W3FlashScreen(victim,RGBA_COLOR_RED);
						}
					}
				}
			}
		}
	}
}

//need event for weapon string
public OnWar3EventPostHurt(victim,attacker,dmg){
	if(victim>0&&attacker>0&&victim!=attacker)
	{
		new race_attacker=War3_GetRace(attacker);
		if(War3_GetGame()==Game_TF)
		{
			if(race_attacker==thisRaceID)
			{
				//hurt someone else, no invis
				new skill_wind=War3_GetSkillLevel(attacker,thisRaceID,SKILL_NADE_INVIS);
				if(skill_wind>0)
				{
					new Float:fix_delay=WindWalkVisibleDuration[skill_wind];
					War3_SetBuff(attacker,bInvisibilityDenySkill,thisRaceID,true); // make them visible, override so shop can't screw up
					WindWalkReinvisTime[attacker]=GetGameTime()+fix_delay;
				}
			}
			//getting hurt = no invis allowed
			if(War3_GetRace(victim)==thisRaceID){
				new skill_wind=War3_GetSkillLevel(victim,thisRaceID,SKILL_NADE_INVIS);
				if(skill_wind>0)
				{
					new Float:fix_delay=WindWalkVisibleDuration[skill_wind];
					War3_SetBuff(victim,bInvisibilityDenySkill,thisRaceID,true); // make them visible, override so shop can't screw up
					WindWalkReinvisTime[victim]=GetGameTime()+fix_delay;
				}
			}
		}
		else   //cs
		{
		
			new skill_cg_attacker=War3_GetSkillLevel(attacker,race_attacker,SKILL_NADE_INVIS);
			if(race_attacker==thisRaceID && skill_cg_attacker>0 && !Hexed(attacker,false))
			{
				new gloveitem=War3_GetItemIdByShortname("glove");
				if(GetConVarInt(hCvarDisableCritWithGloves)>0&&gloveitem>0&&War3_GetOwnsItem(attacker,gloveitem)){
					///no crit nade of he has gloves
				}
				else
				{
					decl String:weapon[64];
					GetEventString(W3GetVar(SmEvent),"weapon",weapon,63);
					if(StrEqual(weapon,"hegrenade",false) && !W3HasImmunity(victim,Immunity_Skills))
					{
						new Float:percent=CriticalGrenadePercent[skill_cg_attacker];
						new originaldamage=dmg;
						new health_take=RoundFloat((float(dmg)*percent));
						
						new onehp=false;
						///you cannot die from orc nade unless the usual nade damage kills you
						if(GetClientHealth(victim)>originaldamage&&health_take>GetClientHealth(victim)){
						        health_take=GetClientHealth(victim) -1;
						        onehp=true;
						}
						////new new_health=GetClientHealth(victim)-health_take;
						//if(new_health<0)
						//	new_health=0;
						//SetEntityZHealth(victim,new_health);
						if(War3_DealDamage(victim,health_take,attacker,_,"criticalnade",W3DMGORIGIN_SKILL,W3DMGTYPE_TRUEDMG))
						{
							W3PrintSkillDmgHintConsole(victim,attacker,War3_GetWar3DamageDealt(),"Critical Nade");
							W3FlashScreen(victim,RGBA_COLOR_RED);
							if(onehp){
								SetEntityHealth(victim,1); 
							}  
						}
						
					}
				}
			}
		}
	}
}


public OnWar3EventDeath(index,attacker)
{	
	if(ValidPlayer(index)){
		new race=W3GetVar(DeathRace); //get  immediate variable, which indicates the race of the player when he died
		if(race==thisRaceID&&!bHasRespawned[index]&&War3_GetGame()!=Game_TF)
		{
			new skill=War3_GetSkillLevel(index,race,SKILL_RECARN_WARD);
			if(skill) //let them revive even if hexed
			{
				new Float:percent=ReincarnationChance[skill];
				if(GetRandomFloat(0.0,1.0)<=percent)
				{
					new Float:delay_spawn=GetConVarFloat(RespawnDelayCvar);
					if(delay_spawn<0.25)
						delay_spawn=0.25;
					CreateTimer(delay_spawn,RespawnPlayer,index);
					PrintHintText(index,"%T","REINCARNATION IN {amount} SECONDS!",index,delay_spawn);
					
				}
			}
		}
	}
}

public Action:RespawnPlayer(Handle:timer,any:client)
{
	if(ValidPlayer(client)&&!IsPlayerAlive(client)&&GetClientTeam(client)>1)
	{
		War3_SpawnPlayer(client);
		new Float:pos[3];
		new Float:ang[3];
		War3_CachedAngle(client,ang);
		War3_CachedPosition(client,pos);
		TeleportEntity(client,pos,ang,NULL_VECTOR);
		// cool, now remove their weapons besides knife and c4 
		for(new slot=0;slot<10;slot++)
		{
			new ent=GetEntDataEnt2(client,MyWeaponsOffset+(slot*4));
			if(ent>0 && IsValidEdict(ent))
			{
				new String:ename[64];
				GetEdictClassname(ent,ename,64);
				if(StrEqual(ename,"weapon_c4") || StrEqual(ename,"weapon_knife"))
				{
					continue; // don't think we need to delete these
				}
				W3DropWeapon(client,ent);
				UTIL_Remove(ent);
			}
		}
		// restore iAmmo
		for(new ammotype=0;ammotype<32;ammotype++)
		{
			SetEntData(client,AmmoOffset+(ammotype*4),War3_CachedDeadAmmo(client,ammotype),4);
		}
		// give them their weapons
		for(new slot=0;slot<10;slot++)
		{
			new String:wep_check[64];
			War3_CachedDeadWeaponName(client,slot,wep_check,64);
			//PrintToChatAll("zz %s",wep_check);
			if(!StrEqual(wep_check,"weapon_c4") && !StrEqual(wep_check,"weapon_knife"))
			{
				new wep_ent=GivePlayerItem(client,wep_check);
				if(wep_ent>0) 
				{
					///dont set clip
					//SetEntData(wep_ent,Clip1Offset,War3_CachedDeadClip1(client,slot),4);
				}
			}
		}
		bHasRespawned[client]=true;
		War3_ChatMessage(client,"%T","Reincarnated via skill",client);
	}
	else{
		//gone or respawned via some other race/item
		bHasRespawned[client]=false;
	}
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new x=1;x<=64;x++)
		bHasRespawned[x]=false;
}

public Action:DeciSecondTimer(Handle:h)
{
	if(War3_GetGame()==Game_TF){
		
		for(new x=1;x<=MaxClients;x++)
		{
			if(ValidPlayer(x,true))
			{
				if(WindWalkReinvisTime[x]!=0.0 && GetGameTime()>WindWalkReinvisTime[x])
				{
					War3_SetBuff(x,bInvisibilityDenySkill,thisRaceID,false);//can invis again
					WindWalkReinvisTime[x]=0.0;
				}
			}
		}
	}
}

// Wards
public CreateWard(client)
{
	for(new i=0;i<MAXWARDS;i++)
	{
		if(WardOwner[i]==0)
		{
			WardOwner[i]=client;
			GetClientAbsOrigin(client,WardLocation[i]);
			break;
		}
	}
}

public RemoveWards(client)
{
	for(new i=0;i<MAXWARDS;i++)
	{
		if(WardOwner[i]==client)
		{
			WardOwner[i]=0;
		}
	}
	CurrentWardCount[client]=0;
}

public Action:CalcWards(Handle:timer,any:userid)
{
	for(new i=0;i<=MaxClients;i++){
		flashedscreen[i]=false;
	}
	new client;
	for(new i=0;i<MAXWARDS;i++)
	{
		
		if(WardOwner[i]!=0)
		{
			client=WardOwner[i];
			if(!ValidPlayer(client,true))
			{
				WardOwner[i]=0; //he's dead, so no more wards for him
				--CurrentWardCount[client];
			}
			else
			{
				WardEffectAndHeal(client,i);
			}
		}
	}
}
//healing wards
public WardEffectAndHeal(owner,wardindex)
{
	new beamcolor[]={0,255,0,150};
	new Float:start_pos[3];
	new Float:end_pos[3];
	new Float:tempVec1[]={0.0,0.0,WARDBELOW};
	new Float:tempVec2[]={0.0,0.0,WARDABOVE};
	AddVectors(WardLocation[wardindex],tempVec1,start_pos);
	AddVectors(WardLocation[wardindex],tempVec2,end_pos);
	TE_SetupBeamPoints(start_pos,end_pos,BeamSprite,HaloSprite,0,GetRandomInt(30,100),1.2,float(WARDRADIUS),float(WARDRADIUS),0,30.0,beamcolor,10);
	TE_SendToAll();
	new Float:BeamXY[3];
	for(new x=0;x<3;x++) BeamXY[x]=start_pos[x]; //only compare xy
	new Float:BeamZ= BeamXY[2];
	BeamXY[2]=0.0;
	new Float:VictimPos[3];
	new Float:tempZ;

	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true))
		{
			GetClientAbsOrigin(i,VictimPos);
			tempZ=VictimPos[2];
			VictimPos[2]=0.0; //no Z
			if(GetVectorDistance(BeamXY,VictimPos) < WARDRADIUS) ////ward RADIUS
			{
				// now compare z
				if(tempZ>BeamZ+WARDBELOW && tempZ < BeamZ+WARDABOVE)
				{
					//Heal!!
					new DamageScreen[4];
					DamageScreen[0]=beamcolor[0];
					DamageScreen[1]=beamcolor[1];
					DamageScreen[2]=beamcolor[2];
					DamageScreen[3]=20; //alpha
					new cur_hp=GetClientHealth(i);
					new new_hp=cur_hp+WARDHEAL;
					new max_hp=War3_GetMaxHP(i);
					if(new_hp>max_hp)	new_hp=max_hp;
					if(cur_hp<new_hp)
					{
						if(!flashedscreen[i]){
							flashedscreen[i]=true;
							W3FlashScreen(i,DamageScreen);
						}
						//SetEntityZHealth(i,new_hp);
						War3_HealToMaxHP(i,WARDHEAL);
						VictimPos[i]+=65.0;
						War3_TF_ParticleToClient(0, GetClientTeam(i)==2?"healthgained_red":"healthgained_blu", VictimPos);
					}
				}
			}
		}
	}
}