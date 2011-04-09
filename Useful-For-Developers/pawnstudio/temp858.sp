#pragma semicolon 1	///WE RECOMMEND THE SEMICOLON

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "War3Source Race - Hammerstorm",
	author = "Ted Theodore Logan",
	description = "Hammerstorm (The Rogue Knight) race for War3Source.",
	version = "1.2",
};

/* Changelog
 * 1.2 - Fixed speed buff not being removed on race switch
 */

new thisRaceID;
new SKILL_BOLT, SKILL_CLEAVE, SKILL_WARCRY, ULT_STRENGTH;

// Tempents
new g_BeamSprite;
new g_HaloSprite;

// Storm Bolt 
new BoltDamage[5] = {0,5,10,15,20};
new Float:BoltRange[5]={0.0,150.0,175.0,200.0,225.0};
new Float:BoltStunDuration=0.3;
new Float:StormCooldownTime=15.0;


new const StormCol[4] = {255, 255, 255, 155}; // Color of the beacon



// Cleave Multiplayer
new Float:CleaveDistance=150.0;
new Float:CleaveMultiplier[5] = {0.0,0.1,0.2,0.3,0.4};

// Warcry Buffs
new Float:WarcrySpeed[5]={1.0,1.06,1.09,1.12,1.15};
new WarcryArmor[5]={0,1,2,3,4};

// Gods Strength
new Float:GodsStrength[5]={1.0,1.20,1.30,1.40,1.50};
new bool:bStrengthActivated[MAXPLAYERS];
new Handle:ultCooldownCvar; // cooldown

// Sounds
new String:hammerboltsound[]="war3source/hammerstorm/stun.mp3";
new String:ultsnd[]="war3source/hammerstorm/ult.mp3";
//new String:galvanizesnd[]="war3source/hammerstorm/galvanize.mp3";

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==170)
	{
		thisRaceID=War3_CreateNewRace("Hammerstorm","hammerstorm");
		SKILL_BOLT=War3_AddRaceSkill(thisRaceID,"Storm Bolt (Ability)","Stuns enemies in 150-225 radius for 0.1-0.3 seconds, deals 5-20 damage.",false,4);
		SKILL_CLEAVE=War3_AddRaceSkill(thisRaceID,"Great Cleave","Your attacks splash 10-40 percent damage to enemys within 150 units",false,4);
		SKILL_WARCRY=War3_AddRaceSkill(thisRaceID,"Warcry","Gain 1-4 physical armor, increases your speed by 6-15 percent",false,4);
		ULT_STRENGTH=War3_AddRaceSkill(thisRaceID,"Gods Strength (Ultimate)","Greatly enhance your damage by 20-50 percent for a short amount of time.",true,4); 
		War3_CreateRaceEnd(thisRaceID); 
	}
}

public OnPluginStart()
{
	ultCooldownCvar=CreateConVar("war3_hammerstorm_strength_cooldown","25","Cooldown timer.");
}

public OnMapStart()
{
	// Precache the stuff for the beacon ring
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");   
	//Sounds
	War3_PrecacheSound(hammerboltsound);
	War3_PrecacheSound(ultsnd);
}

public OnWar3EventSpawn(client)
{
	InitPassiveSkills(client);
	
	bStrengthActivated[client] = false;
	W3ResetPlayerColor(client, thisRaceID);
}

public OnSkillLevelChanged(client,race,skilllvl,newskilllvllevel)
{
	InitPassiveSkills(client);
}

public InitPassiveSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_WARCRY);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,WarcrySpeed[skilllvl]);
		War3_SetBuff(client,fArmorPhysical,thisRaceID,float(WarcryArmor[skilllvl]));
		
	}
}

public OnRaceSelected(client,newrace)
{
	if(newrace!=thisRaceID)
	{
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
	}
}


public OnW3TakeDmgBullet(victim,attacker,Float:damage){
	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,false)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new skilllvl;
			if(bStrengthActivated[attacker])
			{
				// GODS STRENGTH!
				skilllvl = War3_GetSkillLevel(attacker,thisRaceID,ULT_STRENGTH);
				War3_DamageModPercent(GodsStrength[skilllvl]);
				// For Cleave...
				damage = damage * GodsStrength[skilllvl];
			}
			// Cleave
			skilllvl = War3_GetSkillLevel(attacker,thisRaceID,SKILL_CLEAVE);
			new splashdmg = RoundToFloor(damage * CleaveMultiplier[skilllvl]);
			// AWP? AWP!
			if(splashdmg>40)
			{
				splashdmg = 40;
			}
			new Float:dist = CleaveDistance;
			new AttackerTeam = GetClientTeam(attacker);
			new Float:OriginalVictimPos[3];
			GetClientAbsOrigin(victim,OriginalVictimPos);
			new Float:VictimPos[3];
			
			if(attacker>0)
			{
				for(new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true)&&(GetClientTeam(i)!=AttackerTeam)&&(victim!=i))
					{
						GetClientAbsOrigin(i,VictimPos);
						if(GetVectorDistance(OriginalVictimPos,VictimPos)<=dist)
						{
							War3_DealDamage(i,splashdmg,attacker,_,"greatcleave");
							W3PrintSkillDmgConsole(i,attacker,War3_GetWar3DamageDealt(),"greatcleave");
						}
					}
				}
			}
		}
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_BOLT);
		if(skilllvl > 0)
		{
			
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_BOLT,true))
			{
				new damage = BoltDamage[skilllvl];
				new Float:AttackerPos[3];
				GetClientAbsOrigin(client,AttackerPos);
				new AttackerTeam = GetClientTeam(client);
				new Float:VictimPos[3];
				
				TE_SetupBeamRingPoint(AttackerPos, 10.0, BoltRange[skilllvl]*2.0, g_BeamSprite, g_HaloSprite, 0, 25, 0.5, 5.0, 0.0, StormCol, 10, 0);
				TE_SendToAll();
				AttackerPos[2]+=10.0;
				TE_SetupBeamRingPoint(AttackerPos, 10.0, BoltRange[skilllvl]*2.0, g_BeamSprite, g_HaloSprite, 0, 25, 0.5, 5.0, 0.0, StormCol, 10, 0);
				TE_SendToAll();
				
				EmitSoundToAll(hammerboltsound,client);
				EmitSoundToAll(hammerboltsound,client);
				
				for(new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true)){
						GetClientAbsOrigin(i,VictimPos);
						if(GetVectorDistance(AttackerPos,VictimPos)<BoltRange[skilllvl])
						{
							if(GetClientTeam(i)!=AttackerTeam&&!W3HasImmunity(client,Immunity_Skills))
							{
								War3_DealDamage(i,damage,client,DMG_BURN,"stormbolt",W3DMGORIGIN_SKILL);
								W3PrintSkillDmgConsole(i,client,War3_GetWar3DamageDealt(),"stormbolt");
								
								W3SetPlayerColor(i,thisRaceID, StormCol[0], StormCol[1], StormCol[2], StormCol[3]); 
								War3_SetBuff(i,bStunned,thisRaceID,true);

								W3FlashScreen(i,RGBA_COLOR_RED);
								CreateTimer(BoltStunDuration,UnstunPlayer,i);
								
								PrintHintText(i,"You were stunned by Storm Bolt");
								
							}
						}
					}
				}
				//EmitSoundToAll(hammerboltsound,client);
				War3_CooldownMGR(client,StormCooldownTime,thisRaceID,SKILL_BOLT);
			}
		}
	}
}

public Action:UnstunPlayer(Handle:timer,any:client)
{
	War3_SetBuff(client,bStunned,thisRaceID,false);
	W3ResetPlayerColor(client, thisRaceID);
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skilllvl = War3_GetSkillLevel(client,thisRaceID,ULT_STRENGTH);
		if(skilllvl>0)
		{	
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_STRENGTH,true ))
			{
				EmitSoundToAll(ultsnd,client);
				EmitSoundToAll(ultsnd,client);
				PrintHintText(client, "The gods lend you their strength");
				bStrengthActivated[client] = true;
				CreateTimer(5.0,stopUltimate,client);
				
				//EmitSoundToAll(ultsnd,client);  
				War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_STRENGTH);
			}
		}
	}
}


public Action:stopUltimate(Handle:t,any:client){
	bStrengthActivated[client] = false;
	if(ValidPlayer(client,true)){
		PrintHintText(client,"You feel less powerful");
	}
}