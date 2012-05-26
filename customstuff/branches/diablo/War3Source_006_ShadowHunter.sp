 /**
 * File: War3Source_ShadowHunter.sp
 * Description: The Shadow Hunter race for War3Source.
 * Author(s): Anthony Iacono & Ownage | Ownz (DarkEnergy)
 */
 
#pragma semicolon 1
#pragma tabsize 0

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
public W3ONLY(){} //unload this?



////TO DO:
//native that asks if the damage is by direct weapon, not lasting burn


new thisRaceID;
new AuraID;

new SKILL_HEALINGWAVE, SKILL_HEX, SKILL_RECARN_WARD, ULT_VOODOO;


//skill 1
new Float:HealingWaveAmountArr[]={0.0,1.0,2.0,3.0,4.0};
new Float:HealingWaveDistance=500.0;
new ParticleEffect[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; // ParticleEffect[Source][Destination]

//skill 2
new Float:HexChanceArr[]={0.00,0.02,0.050,0.075,0.100};

//skill 3
// Healing Ward Specific
#define MAXWARDS 64*4 //on map LOL
#define WARDRADIUS 70
// WARDHEAL WAS 4
#define WARDHEAL 10
#define WARDBELOW -2.0 // player is 60 units tall about (6 feet)
#define WARDABOVE 160.0
new CurrentWardCount[MAXPLAYERSCUSTOM];
new WardStartingArr[]={0,1,2,3,4};
new Float:WardLocation[MAXWARDS][3];
new WardOwner[MAXWARDS];


//ultimate
new Handle:ultCooldownCvar;

new Float:UltimateDuration[]={0.0,0.66,1.0,1.33,1.66}; ///big bad voodoo duration

new bool:flashedscreen[MAXPLAYERSCUSTOM];

new bool:bVoodoo[65];

new String:ultimateSound[]="war3source/divineshield.wav";
new String:wardDamageSound[]="war3source/thunder_clap.wav";

new bool:particled[MAXPLAYERSCUSTOM]; //heal particle


new BeamSprite,HaloSprite; //wards
//new AuraID;
public Plugin:myinfo = 
{
	name = "Race - Shadow Hunter",
	author = "PimpinJuice & Ownz (DarkEnergy)",
	description = "The Shadow Hunter race for War3Source.",
	version = "1.0.0.0",
	url = "http://Www.OwnageClan.Com"
};

public OnPluginStart()
{

	ultCooldownCvar=CreateConVar("war3_hunter_voodoo_cooldown","20","Cooldown between Big Bad Voodoo (ultimate)");
    CreateTimer(1.0,CalcWards,_,TIMER_REPEAT);
	CreateTimer(1.0,CalcHexHealWaves,_,TIMER_REPEAT);
	
	LoadTranslations("w3s.race.hunter.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==60)
	{
		
		
		thisRaceID=War3_CreateNewRaceT("hunter");
		SKILL_HEALINGWAVE=War3_AddRaceSkillT(thisRaceID,"HealingWave",false,4);
		SKILL_HEX=War3_AddRaceSkillT(thisRaceID,"Hex",false,4);
		SKILL_RECARN_WARD=War3_AddRaceSkillT(thisRaceID,"HealingWard",false,4);
		ULT_VOODOO=War3_AddRaceSkillT(thisRaceID,"BigBadVoodoo",true,4); 
		War3_CreateRaceEnd(thisRaceID);
		AuraID=W3RegisterAura("hunter_healwave",HealingWaveDistance);

	}

}

// Events
public OnWar3EventSpawn(client){
	bVoodoo[client]=false;
	RemoveWards(client);
	StopParticleEffect(client, true);
}

public OnClientDisconnect(client)
{
	StopParticleEffect(client, true);
}

public OnWar3EventDeath(victim, attacker)
{
	StopParticleEffect(victim, false);
}


public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	
	War3_PrecacheSound(ultimateSound);
	War3_PrecacheSound(wardDamageSound);
}

public OnWar3PlayerAuthed(client)
{
	bVoodoo[client]=false;
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace==thisRaceID)
	{
		new level=War3_GetSkillLevel(client,thisRaceID,SKILL_HEALINGWAVE);
		W3SetAuraFromPlayer(AuraID,client,level>0?true:false,level);
		
	}
	else{
		//PrintToServer("deactivate aura");
		War3_SetBuff(client,bImmunitySkills,thisRaceID,false);
		W3SetAuraFromPlayer(AuraID,client,false);
		RemoveWards(client);
	}
}

public OnW3PlayerAuraStateChanged(client,aura,bool:inAura,level)
{
	if(aura==AuraID)
	{
		War3_SetBuff(client,fHPRegen,thisRaceID,inAura?HealingWaveAmountArr[level]:0.0);
		//DP("%d %f",inAura,HealingWaveAmountArr[level]);
	}
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	
	if(race==thisRaceID && War3_GetRace(client)==thisRaceID)
	{
		if(skill==SKILL_HEALINGWAVE) //1
		{
			W3SetAuraFromPlayer(AuraID,client,newskilllevel>0?true:false,newskilllevel);
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	new userid=GetClientUserId(client);
	if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) )
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_VOODOO);
		if(ult_level>0)
		{
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_VOODOO,true))
			{
				bVoodoo[client]=true;
				
				W3SetPlayerColor(client,thisRaceID,255,200,0,_,GLOW_ULTIMATE); //255,200,0);
				CreateTimer(UltimateDuration[ult_level],EndVoodoo,client);
				new Float:cooldown=	GetConVarFloat(ultCooldownCvar);
				War3_CooldownMGR(client,cooldown,thisRaceID,ULT_VOODOO,_,_);
				W3MsgUsingVoodoo(client);
				EmitSoundToAll(ultimateSound,client);
				EmitSoundToAll(ultimateSound,client);
			}

		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}



public Action:EndVoodoo(Handle:timer,any:client)
{
	bVoodoo[client]=false;
	W3ResetPlayerColor(client,thisRaceID);
	if(ValidPlayer(client,true))
	{
		W3MsgVoodooEnded(client);
	}
}

public Action:CalcHexHealWaves(Handle:timer,any:userid)
{
	if(thisRaceID>0)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			particled[i]=false;
			if(ValidPlayer(i,true))
			{
				if(War3_GetRace(i)==thisRaceID)
				{
					new bool:value=(GetRandomFloat(0.0,1.0)<=HexChanceArr[War3_GetSkillLevel(i,thisRaceID,SKILL_HEX)]&&!Hexed(i,false));
					War3_SetBuff(i,bImmunitySkills,thisRaceID,value);
				}
			}
		}
	}
}


StopParticleEffect(client, bKill)
{
	if(War3_GetGame() == Game_TF)
	{
		for(new i=1; i <= MaxClients; i++)
		{
			decl String:className[64];
			decl String:className2[64];

			if(IsValidEdict(ParticleEffect[client][i]))
				GetEdictClassname(ParticleEffect[client][i], className, sizeof(className));
			if(IsValidEdict(ParticleEffect[i][client]))
			GetEdictClassname(ParticleEffect[i][client], className2, sizeof(className2));

			if(StrEqual(className, "info_particle_system"))
			{
				AcceptEntityInput(ParticleEffect[client][i], "stop");
				if(bKill)
				{
					AcceptEntityInput(ParticleEffect[client][i], "kill");
					ParticleEffect[client][i] = 0;
				}
			}

			if(StrEqual(className2, "info_particle_system"))
			{
				AcceptEntityInput(ParticleEffect[i][client], "stop");
				if(bKill)
				{
					AcceptEntityInput(ParticleEffect[i][client], "kill");
					ParticleEffect[i][client] = 0;
				}
			}
		}
	}
}


/* ORC SWAP ABILITY BELOW */

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



public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0) //block self inflicted damage
	{
		if(bVoodoo[victim]&&attacker==victim){
			War3_DamageModPercent(0.0);
			return;
		}
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		
		
		if(vteam!=ateam)
		{
			if(bVoodoo[victim])
			{
				if(!W3HasImmunity(attacker,Immunity_Ultimates))
				{
					if(War3_GetGame()==Game_TF){
						decl Float:pos[3];
						GetClientEyePosition(victim, pos);
						pos[2] += 4.0;
						War3_TF_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos
						
						//War3_TF_ParticleToClient(0, "healthgained_blu", pos);
					}
					War3_DamageModPercent(0.0);
				}
				else
				{
					W3MsgEnemyHasImmunity(victim,true);
				}
			}
		}
	}
	return;
}

/*public HealWave(client)
{
	//assuming client exists and has this race
	new skill = War3_GetSkillLevel(client,thisRaceID,SKILL_HEALINGWAVE);
	if(skill>0&&!Hexed(client,false))
	{
		new Float:dist = HealingWaveDistanceArr[skill];
		new HealerTeam = GetClientTeam(client);
		new Float:HealerPos[3];
		GetClientAbsOrigin(client,HealerPos);
		new Float:VecPos[3];

		
		War3_SetBuff(client,fHPRegen,thisRaceID,0.0);
		asdf fix aura
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&GetClientTeam(i)==HealerTeam)
			{
				GetClientAbsOrigin(i,VecPos);
				if(GetVectorDistance(HealerPos,VecPos)<=dist)
				{
					War3_HealToMaxHP(i,HealingWaveAmountArr[skill]);
					
					//War3_TF_ParticleToClient(0, "healthlost_blu", VecPos); //a poison death symbol
					
					
					
					if(!particled[i]){
						particled[i]=true;
						VecPos[2]+=65.0;
					
						War3_TF_ParticleToClient(0, HealerTeam==2?"healthgained_red":"healthgained_blu", VecPos);
					
					}
				}
			}
		}
	}
}
*/
//=======================================================================
//                  HEALING WAVE PARTICLE EFFECT (TF2 ONLY!)
//=======================================================================
/*
// Written by FoxMulder with some tweaks by me https://forums.alliedmods.net/showpost.php?p=909189&postcount=7
AttachParticle(ent, String:particleType[], controlpoint)
{
	if(War3_GetGame() == Game_TF)
	{
		new particle  = CreateEntityByName("info_particle_system");
		new particle2 = CreateEntityByName("info_particle_system");
		if (IsValidEdict(particle))
		{ 
			new String:tName[128];
			Format(tName, sizeof(tName), "target%i", ent);
			DispatchKeyValue(ent, "targetname", tName);
			
			new String:cpName[128];
			Format(cpName, sizeof(cpName), "target%i", controlpoint);
			DispatchKeyValue(controlpoint, "targetname", cpName);
			
			//--------------------------------------
			new String:cp2Name[128];
			Format(cp2Name, sizeof(cp2Name), "tf2particle%i", controlpoint);
			
			DispatchKeyValue(particle2, "targetname", cp2Name);
			DispatchKeyValue(particle2, "parentname", cpName);
			
			SetVariantString(cpName);
			AcceptEntityInput(particle2, "SetParent");
			
			SetVariantString("flag");
			AcceptEntityInput(particle2, "SetParentAttachment");
			//-----------------------------------------------
			
			DispatchKeyValue(particle, "targetname", "tf2particle");
			DispatchKeyValue(particle, "parentname", tName);
			DispatchKeyValue(particle, "effect_name", particleType);
			DispatchKeyValue(particle, "cpoint1", cp2Name);
			
			DispatchSpawn(particle);
			
			SetVariantString(tName);
			AcceptEntityInput(particle, "SetParent");
			
			SetVariantString("flag");
			AcceptEntityInput(particle, "SetParentAttachment");
			
			//The particle is finally ready
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");
			
			ParticleEffect[ent][controlpoint] = particle;
		}
	}
}
*/

//not used
/*
public Action:HealingWaveParticleTimer(Handle:timer, any:userid)
{
	if(War3_GetGame() == Game_TF)
		for(new client=1; client <= MaxClients; client++)
			if(ValidPlayer(client, true))
				if(War3_GetRace(client) == thisRaceID)
				{
					new skill = War3_GetSkillLevel(client, thisRaceID, SKILL_HEALINGWAVE);
					if(skill > 0)
					{ 
						new Float:HealerPos[3];
						new Float:TeammatePos[3];
						new Float:maxDistance = HealingWaveDistance;
						
						GetClientAbsOrigin(client, HealerPos);
	
						for(new i=1; i <= MaxClients; i++)
							if(ValidPlayer(i, true) && GetClientTeam(i) == GetClientTeam(client) && (i != client))
							{
								if(IsValidEdict(ParticleEffect[client][i]))
								{
									decl String:className[64];
									GetEdictClassname(ParticleEffect[client][i], className, sizeof(className));
									
									GetClientAbsOrigin(i, TeammatePos);
									if(GetVectorDistance(HealerPos, TeammatePos) <= maxDistance)
									{
										if(StrEqual(className, "info_particle_system"))
											AcceptEntityInput(ParticleEffect[client][i], "start");
										else
											switch(GetClientTeam(client))
											{
												case(2):
													AttachParticle(client, "medicgun_beam_red", i);
												case(3):
													AttachParticle(client, "medicgun_beam_blue", i);
											}
									}
									else
									{
										if(StrEqual(className, "info_particle_system"))
											AcceptEntityInput(ParticleEffect[client][i], "stop");
									}
								}
							}
					}
				}
}
*/


/* ******************** ORC HEALING ****************************** */
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
						VictimPos[2]+=65.0;
						War3_TF_ParticleToClient(0, GetApparentTeam(i)==2?"healthgained_red":"healthgained_blu", VictimPos);
					}
				}
			}
		}
	}
}