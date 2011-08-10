/**
* File: War3Source_UndeadScourge.sp
* Description: The Undead Scourge race for War3Source.
* Author(s): Anthony Iacono 
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>

public SHONLY(){}


// War3Source stuff
new thisRaceID;
new suicidedAsTeam[MAXPLAYERSCUSTOM];
new String:explosionSound1[]="war3source/particle_suck1.wav";
new ExplosionModel;
new bSuicided[MAXPLAYERSCUSTOM];
new BeamSprite;
new HaloSprite;

new Handle:SuicideDamageSentryCvar;

// Chance/Data Arrays
//new Float:DistractChance[5]={0.0,0.05,0.10,0.15,0.2};
new Float:SuicideBomberRadius[5]={0.0,200.0,233.0,275.0,333.0}; 

new Float:SuicideBomberDamage[5]={0.0,166.0,200.0,233.0,266.0};
new Float:SuicideBomberDamageTF[5]={0.0,133.0,175.0,250.0,300.0}; 

new Float:SuicideLocation[MAXPLAYERSCUSTOM][3];


public Plugin:myinfo = 
{
	name = "SH - Hero - Al Qaeda",
	author = "Ownz,DarkEnergy",
	description = "",
	version = "1.0.0.0",
	url = "http://war3source.com"
};

// War3Source Functions
public OnPluginStart()
{
	SuicideDamageSentryCvar=CreateConVar("war3_undead_suicidebomber_sentry","1","Should suicide bomber damage sentrys?");
}

public OnSHLoadHeroOrItemOrdered(num)
{
	if(num==10)
	{
			thisRaceID=SHRegisterHero(
			"Al Qaeda",
			"undead",
			"Explode when you die",
			"Explode when you die, dealing damage around you",
			false
			);
	}
}

public OnMapStart()
{
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

	War3_PrecacheSound(explosionSound1);

}

public OnSHEventDeath(victim,attacker)
{

	if(SHHasHero(victim,thisRaceID)&& !Hexed(victim))
	{
		bSuicided[victim]=true;
		suicidedAsTeam[victim]=GetClientTeam(victim); //NOW set in spawn, because when switch team he may aleady have changed team
		GetClientAbsOrigin(victim,SuicideLocation[victim]);
		CreateTimer(0.15,DelayedBomber,victim);
	}
		
}
public Action:DelayedBomber(Handle:h,any:client){
	if(ValidPlayer(client)&&!IsPlayerAlive(client)){
		SuicideBomber(client,4);
	}
	else{
		bSuicided[client]=false;
	}
}

public SuicideBomber(client,level)
{
	//PrintToChatAll("%d %d",client,level);
	new our_team=GetClientTeam(client); 
	if( suicidedAsTeam[client]!=our_team){
		return;
	}
	new Float:radius=SuicideBomberRadius[level];
	
	
	new Float:client_location[3];
	for(new i=0;i<3;i++){
		client_location[i]=SuicideLocation[client][i];
	}
	
	TE_SetupExplosion(client_location,ExplosionModel,10.0,1,0,RoundToFloor(radius),160);
	TE_SendToAll();
	
	if(War3_GetGame()==Game_TF){
		client_location[2]+=30.0;
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
					
					PrintToConsole(client,"[W3S] Suicide bomber BUILDING damage: %d at distance %f",damage,dist);
					
					SetVariantInt(damage);
					AcceptEntityInput(ent,"RemoveHealth",client); // last parameter should make death messages work
				}
				else{
					PrintToConsole(client,"[W3S] Player %d has immunity (protecting buildings)",builder);
				}
			}
		}
	}
	
	new Float:location_check[3];
	for(new x=1;x<=MaxClients;x++)
	{
		if(ValidPlayer(x,true)&&client!=x&&GetClientTeam(x)!=our_team)
		{

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
				PrintToConsole(client,"[W3S] Suicide bomber damage: %d to %d at distance %f",War3_GetWar3DamageDealt(),x,distance);
				
				
				War3_ShakeScreen(x,3.0*factor,250.0*factor,30.0);
				W3FlashScreen(x,RGBA_COLOR_RED);
			}
			else
			{
				PrintToConsole(client,"[W3S] Could not damage player %d due to immunity",x);
			}
			
		}
	}
	//PrintCenterText(client,"BOMB DETONATED!");
}


public OnSHEventSpawn(client)
{
	suicidedAsTeam[client]=GetClientTeam(client);
	if(SHHasHero(client,thisRaceID))
	{
		bSuicided[client]=false;
	}
	else{
		bSuicided[client]=true; //kludge, not to allow some other race switch to this race and explode on death (ultimate)
	}
}


public OnPowerCommand(client,herotarget,bool:pressed){
	if(herotarget==thisRaceID&&pressed){
		SH_ChatMessage(client,"power bomber");
	}
}