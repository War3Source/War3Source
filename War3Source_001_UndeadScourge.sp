/**
* File: War3Source_UndeadScourge.sp
* Description: The Undead Scourge race for War3Source.
* Author(s): Anthony Iacono 
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
public W3ONLY(){} //unload this?

// War3Source stuff
new thisRaceID;
new Handle:FriendlyFireSuicideCvar;
new Handle:SuicideDamageSentryCvar;
new Handle:MPFFCvar;
new ExplosionModel;
new bool:bSuicided[MAXPLAYERSCUSTOM];
new suicidedAsTeam[MAXPLAYERSCUSTOM];
new String:explosionSound1[]="war3source/particle_suck1.wav";

new BeamSprite;
new HaloSprite;

// Chance/Data Arrays
//new Float:DistractChance[5]={0.0,0.05,0.10,0.15,0.2};
new Float:SuicideBomberRadius[5]={0.0,200.0,233.0,275.0,333.0}; 

new Float:SuicideBomberDamage[5]={0.0,166.0,200.0,233.0,266.0};
new Float:SuicideBomberDamageTF[5]={0.0,133.0,175.0,250.0,300.0}; 

new Float:UnholySpeed[5]={1.0,1.06,1.12,1.18,1.23};
new Float:LevitationGravity[5]={1.0,0.85,0.7,0.6,0.5};
//new Float:VampirePercent[5]={0.0,0.07,0.14,0.22,0.30};
new Float:VampirePercent[5]={0.0,0.07,0.13,0.19,0.25};

new Float:SuicideLocation[MAXPLAYERSCUSTOM][3];

new SKILL_LEECH,SKILL_SPEED,SKILL_LOWGRAV,SKILL_SUICIDE;

public Plugin:myinfo = 
{
	name = "Race - Undead Scourge",
	author = "PimpinJuice",
	description = "The Undead Scourge race for War3Source.",
	version = "1.0.0.0",
	url = "http://war3source.com"
};

// War3Source Functions
public OnPluginStart()
{
	//HookEvent("player_spawn",PlayerSpawnEvent);
	//HookEvent("player_death",PlayerDeathEvent);
	FriendlyFireSuicideCvar=CreateConVar("war3_undead_suicidebomber_ff","0","Friendly fire for suicide bomber, 0 for no, 1 for yes, 2 for mp_friendlyfire");
	SuicideDamageSentryCvar=CreateConVar("war3_undead_suicidebomber_sentry","1","Should suicide bomber damage sentrys?");
	MPFFCvar=FindConVar("mp_friendlyfire");
	
	//RegConsoleCmd("spriteme",cmdspriteme);
	
	LoadTranslations("w3s.race.undead.phrases");
}
new glowsprite;
public Action:cmdspriteme(client,args){
	
	
	new Float:endpos[3];
	War3_GetAimTraceMaxLen(client,endpos,10.0);
	/*PrintToChatAll("1 %d",glowsprite);
	new Float:loc[3];
	GetClientAbsOrigin(client,loc);
	
	loc[2]+=40;
	*/
	//TE_SetupGlowSprite(endpos,glowsprite,30.0,6.0,255);
	//TE_SendToAll(0.0);
	
	TE_Start("Sprite Spray");
	TE_WriteVector("m_vecOrigin",endpos);
	TE_WriteNum("m_nModelIndex",glowsprite);
	TE_WriteFloat("m_fNoise",99.0);
	TE_WriteNum("m_nSpeed",1);
	TE_WriteNum("m_nCount",10);
	TE_SendToAll(0.0);
	//TE_WriteNum("exponent",iExponent);
    //TE_WriteFloat("m_fRadius",fRadius);
	/*
	
	//TE_SetupDynamicLight(loc,255,0,255,5,100.0,2.0,2.0);
	//TE_SendToAll(0.0);
	
	new ent = CreateEntityByName("env_sprite");
	if (ent)
	{
		DispatchKeyValue(ent, "model", "sprites/strider_blackball.spr");
		DispatchKeyValue(ent, "classname", "env_sprite");
		DispatchKeyValue(ent, "spawnflags", "1");
		DispatchKeyValue(ent, "scale", "1.0");
		DispatchKeyValue(ent, "rendermode", "1");
		DispatchKeyValue(ent, "rendercolor", "255 255 255");
		DispatchKeyValue(ent, "targetname", "donator_spr");
		DispatchSpawn(ent);

		new Float:vOrigin[3];
		if (War3_GetGame()==Game_TF)
			GetClientEyePosition(client, vOrigin);
		else
			GetClientAbsOrigin(client, vOrigin);

		vOrigin[2] += 90.0;

		TeleportEntity(ent, vOrigin, NULL_VECTOR, {0.0,0.0,-20.0});
		
		//if (War3_GetGame()==Game_TF)
		SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
			
		//else
		//{
			//new String:szTemp[64]; 
			//Format(szTemp, sizeof(szTemp), "client%i", client);
			//DispatchKeyValue(client, "targetname", szTemp);
			//DispatchKeyValue(ent, "parentname", szTemp);

		//	SetVariantString(szTemp);
		//	AcceptEntityInput(ent, "SetParent", ent, ent, 0);
		//	SetVariantString("head");
		//	AcceptEntityInput(ent, "SetParentAttachmentMaintainOffset", ent, ent, 0);
		//}
	}
	
	 */
	
	
	//est_Effect_33 <Player Filter> <Delay> <model> <Position "X Y Z"> <size> <brightness> 
	/*TE_Start("Sprite");
	TE_WriteNum("m_nModelIndex", glowsprite);

    TE_WriteVector("m_vecOrigin",loc);
	//TE_WriteFloat("m_flSize", 1.0);
	TE_WriteNum("m_nBrightness", 100);

    //TE_WriteNum("g",g);
    //TE_WriteNum("b",b);
    //TE_WriteNum("exponent",iExponent);
    //TE_WriteFloat("m_fRadius",fRadius);
    //TE_WriteFloat("m_fTime",fTime);
	//TE_WriteFloat("m_fDecay",fDecay);
	TE_SendToAll(0.0);*/
	
	PrintToConsole(client,"spriteme completed");
}
stock TE_SetupDynamicLight(const Float:vecOrigin[3], r,g,b,iExponent,Float:fRadius,Float:fTime,Float:fDecay)
{
    TE_Start("Dynamic Light");
    TE_WriteVector("m_vecOrigin",vecOrigin);
    TE_WriteNum("r",r);
    TE_WriteNum("g",g);
    TE_WriteNum("b",b);
    TE_WriteNum("exponent",iExponent);
    TE_WriteFloat("m_fRadius",fRadius);
    TE_WriteFloat("m_fTime",fTime);
    TE_WriteFloat("m_fDecay",fDecay);
}
public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==10)
	{
		/*thisRaceID=War3_CreateNewRace("Undead Scourge","undead");
		SKILL_LEECH=War3_AddRaceSkill(thisRaceID,"Vampiric Aura","You gain health after a successful attack",false,4);
		SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Unholy Aura","You move faster",false,4);
		SKILL_LOWGRAV=War3_AddRaceSkill(thisRaceID,"Levitation","You can jump higher",false,4);
		SKILL_SUICIDE=War3_AddRaceSkill(thisRaceID,"Suicide Bomber","You explode when you die, can be manually activated",true,4); */
		
		///new translated system
		thisRaceID=War3_CreateNewRaceT("undead");
		SKILL_LEECH=War3_AddRaceSkillT(thisRaceID,"VampiricAura",false,4);
		SKILL_SPEED=War3_AddRaceSkillT(thisRaceID,"UnholyAura",false,4);
		SKILL_LOWGRAV=War3_AddRaceSkillT(thisRaceID,"Levitation",false,4);
		SKILL_SUICIDE=War3_AddRaceSkillT(thisRaceID,"SuicideBomber",true,4); 
		
		
		
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnMapStart()
{
	glowsprite=PrecacheModel("sprites/strider_blackball.spr");
	glowsprite++;   //stfu
	glowsprite--;
	
	if(War3_GetGame()==Game_TF)
	{
		ExplosionModel=PrecacheModel("materials/particles/explosion/explosionfiresmoke.vmt",false);
		PrecacheSound("weapons/explode1.wav",false);
	}
	else
	{
		ExplosionModel=PrecacheModel("materials/sprites/zerogxplode.vmt",false);
		PrecacheSound("weapons/explode5.wav",false);
	}
	
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	

	
	//SetFailState("[War3Source] There was a failure in creating the shop vector, definately halting.");
	//new String:longsound[130];
	//new String:sound[]="war3source/particle_suck1.wav";
	
	//Format(longsound,sizeof(longsound), "sound/%s", sound);
	////AddFileToDownloadsTable(longsound); 
	//PrecacheSound(sound, true);	
	//if(!
	War3_PrecacheSound(explosionSound1);
	//){
	//	SetFailState("[War3Source UNDEAD] FATAL ERROR! FAILURE TO PRECACHE SOUND %s!!! CHECK TO SEE IF U HAVE THE SOUND FILES",explosionSound1);
	//}
	//("war3source/levelupcaster.wav");
}

public SuicideBomber(client,level)
{
	if(suicidedAsTeam[client]!=GetClientTeam(client)){
		return; //switched team
	}
	new Float:radius=SuicideBomberRadius[level];
	if(level<=0)
		return; // just a safety check
	new ss_ff=GetConVarInt(FriendlyFireSuicideCvar);
	new bool:mp_ff=GetConVarBool(MPFFCvar);
	new our_team=GetClientTeam(client); 
	new Float:client_location[3];
	for(new i=0;i<3;i++){
		client_location[i]=SuicideLocation[client][i];
	}
	
	
	TE_SetupExplosion(client_location,ExplosionModel,10.0,1,0,RoundToFloor(radius),160);
	TE_SendToAll();
	
	if(War3_GetGame()==Game_TF){
	

		ThrowAwayParticle("ExplosionCore_buildings", client_location,  5.0);
		ThrowAwayParticle("ExplosionCore_MidAir", client_location,  5.0);
		ThrowAwayParticle("ExplosionCore_MidAir_underwater", client_location,  5.0);
		ThrowAwayParticle("ExplosionCore_sapperdestroyed", client_location,  5.0);
		ThrowAwayParticle("ExplosionCore_Wall", client_location,  5.0);
		ThrowAwayParticle("ExplosionCore_Wall_underwater", client_location,  5.0);
	}
	else{
		client_location[2]-=40.0;
	}
	
	TE_SetupBeamRingPoint(client_location, 10.0, radius, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, {255,255,255,33}, 120, 0);
	TE_SendToAll();
	
	new beamcolor[]={0,200,255,255}; //blue //secondary ring
	if(our_team==2)
	{ //TERRORISTS/RED in TF?
		beamcolor[0]=255;
		beamcolor[1]=0;
		beamcolor[2]=0;
		
	} //secondary ring
	TE_SetupBeamRingPoint(client_location, 20.0, radius+10.0, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, beamcolor, 120, 0);
	TE_SendToAll();

	if(War3_GetGame()==Game_TF){
		client_location[2]-=30.0;
	}
	else{
		client_location[2]+=40.0;
	}
	
	EmitSoundToAll(explosionSound1,client);
	
	if(War3_GetGame()==Game_TF){
		EmitSoundToAll("weapons/explode1.wav",client);
	}
	else{
		EmitSoundToAll("weapons/explode5.wav",client);
	}
	
	///building damage
	if(War3_GetGame()==Game_TF && GetConVarBool(SuicideDamageSentryCvar))
	{
		// Do they have a sentry that should get blasted too?
		new ent=0;
		
		new buildinglist[1000];
		new buildingsfound=0;
		
		while((ent = FindEntityByClassname(ent,"obj_sentrygun"))>0)
		{
			buildinglist[buildingsfound]=ent;
			buildingsfound++;
		}
		while((ent = FindEntityByClassname(ent,"obj_teleport"))>0)
		{
			buildinglist[buildingsfound]=ent;
			buildingsfound++;
		}
		while((ent = FindEntityByClassname(ent,"obj_dispenser"))>0)
		{
			buildinglist[buildingsfound]=ent;
			buildingsfound++;
		}

		for(new i=0;i<buildingsfound;i++){
			ent=buildinglist[i];
			if(!IsValidEdict(ent)) continue;
			new builder=GetEntPropEnt(ent,Prop_Send,"m_hBuilder");
			if(GetClientTeam(builder)!=our_team)
			{
				new Float:pos_comp[3];
				GetEntPropVector(ent,Prop_Send,"m_vecOrigin",pos_comp);
				new Float:dist=GetVectorDistance(client_location,pos_comp);
				if(dist>radius)
					continue;
				
				if(!W3HasImmunity(builder,Immunity_Ultimates))
				{
					//new damage=RoundFloat(100*(1-FloatDiv(dist,radius)+0.40));
					new damage=RoundFloat(SuicideBomberDamageTF[level]*(radius-dist)/radius); //special case
					
					PrintToConsole(client,"%T","Suicide bomber BUILDING damage: {amount} at distance {amount}",client,damage,dist);
					
					SetVariantInt(damage);
					AcceptEntityInput(ent,"RemoveHealth",client); // last parameter should make death messages work
				}
				else{
					PrintToConsole(client,"%T","Player {player} has immunity (protecting buildings)",client,builder);
				}
			}
		}
	}
	
	new Float:location_check[3];
	for(new x=1;x<=MaxClients;x++)
	{
		if(ValidPlayer(x,true)&&client!=x)
		{
			new team=GetClientTeam(x);
			if(ss_ff==0 && team==our_team)
				continue;
			else if(ss_ff==2 && !mp_ff && team==our_team)
				continue;

			GetClientAbsOrigin(x,location_check);
			new Float:distance=GetVectorDistance(client_location,location_check);
			if(distance>radius)
				continue;
			
			if(!W3HasImmunity(x,Immunity_Ultimates))
			{
				new Float:factor=(radius-distance)/radius;
				new damage;
				if(War3_GetGame()==Game_TF){
					damage=RoundFloat(SuicideBomberDamageTF[level]*factor);
				}
				else{
					damage=RoundFloat(SuicideBomberDamage[level]*factor);
				}
				//PrintToChatAll("daage suppose to be %d/%.1f max. distance %.1f",damage,SuicideBomberDamage[level],distance);
				
				War3_DealDamage(x,damage,client,_,"suicidebomber",W3DMGORIGIN_ULTIMATE,W3DMGTYPE_PHYSICAL);
				//PrintToConsole(client,"%T","Suicide bomber damage: {amount} to {amount} at distance {amount}",client,War3_GetWar3DamageDealt(),x,distance);
				W3PrintSkillDmgConsole(x,client,War3_GetWar3DamageDealt(),SKILL_SUICIDE);
				
				War3_ShakeScreen(x,3.0*factor,250.0*factor,30.0);
				W3FlashScreen(x,RGBA_COLOR_RED);
			}
			else
			{
				PrintToConsole(client,"%T","Could not damage player {player} due to immunity",client,x);
			}
			
		}
	}
	//PrintCenterText(client,"BOMB DETONATED!");
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(pressed)
	{
		if(race==thisRaceID&&IsPlayerAlive(client)&&!bSuicided[client]&&!Silenced(client))
		{
			new ult_level=War3_GetSkillLevel(client,race,SKILL_SUICIDE);
			if(ult_level>0)
			{
				suicidedAsTeam[client]=GetClientTeam(client);
				ForcePlayerSuicide(client); //this causes them to die...
			}
			else
			{
				W3MsgUltNotLeveled(client);
			}
		}
	}
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	InitPassiveSkills(client);
}
public InitPassiveSkills(client){
	if(War3_GetRace(client)==thisRaceID)
	{
		bSuicided[client]=false;
		new skilllevel_unholy=War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
		new Float:speed=UnholySpeed[skilllevel_unholy];
		War3_SetBuff(client,fMaxSpeed,thisRaceID,speed);
		
		new skilllevel_levi=War3_GetSkillLevel(client,thisRaceID,SKILL_LOWGRAV);
		new Float:gravity=LevitationGravity[skilllevel_levi];
		War3_SetBuff(client,fLowGravitySkill,thisRaceID,gravity);

	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		//if(War3_GetGame()!=Game_TF) 
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.0);
		
		//if(true)
		//War3_WeaponRestrictTo(client, "");
	}
	else
	{	
		//if(true)
		//War3_WeaponRestrictTo(client, "weapon_knife");
		if(IsPlayerAlive(client)){
			InitPassiveSkills(client);
			
		}	
	}
}

public OnWar3EventDeath(victim,attacker)
{
	if(!bSuicided[victim])
	{
		new race=War3_GetRace(victim);
		new skill=War3_GetSkillLevel(victim,thisRaceID,SKILL_SUICIDE);
		if(race==thisRaceID && skill>0 && !Hexed(victim))
		{
			bSuicided[victim]=true;
			//suicidedAsTeam[victim]=GetClientTeam(victim); 
			GetClientAbsOrigin(victim,SuicideLocation[victim]);
			CreateTimer(0.15,DelayedBomber,victim);
		}
	}
}
public Action:DelayedBomber(Handle:h,any:client){
	new level=War3_GetSkillLevel(client,thisRaceID,SKILL_SUICIDE);
	if(level>0&&ValidPlayer(client)&&!IsPlayerAlive(client)&& suicidedAsTeam[client]==GetClientTeam(client) ){
		if(W3Denyable(Suicide,client)){
			SuicideBomber(client,War3_GetSkillLevel(client,thisRaceID,SKILL_SUICIDE));
		}
	}
	else{
		bSuicided[client]=false;
	}
}


public OnWar3EventPostHurt(victim,attacker,damage)
{
	if(ValidPlayer(victim)&&ValidPlayer(attacker,true)&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race=War3_GetRace(attacker);
			if(race==thisRaceID)
			{
				new skill_level=War3_GetSkillLevel(attacker,race,SKILL_LEECH);
				
				if(skill_level>0&&!W3HasImmunity(victim,Immunity_Skills)&&!Hexed(attacker))
				{	
					new Float:percent_health=VampirePercent[skill_level];
					new leechhealth=RoundToFloor(damage*percent_health);
					if(leechhealth>40) leechhealth=40; // woah, woah, woah, AWPs!
				
					PrintToConsole(attacker,"%T","Leeched +{amount} HP",attacker,leechhealth);

					//W3FlashScreen(victim,RGBA_COLOR_RED);
					W3FlashScreen(attacker,RGBA_COLOR_GREEN);	
					War3_HealToBuffHP(attacker,leechhealth);
				}
			}
		}
	}
}    

public OnWar3EventSpawn(client)
{
	//PrintToChatAll("SPAWN %d",client);
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		suicidedAsTeam[client]=GetClientTeam(client);
		InitPassiveSkills(client); //sets suicide
		
	}
	else{
		bSuicided[client]=true; //kludge, not to allow some other race switch to this race and explode on death (ultimate)
	}
}
