
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>


public SHONLY(){}

// War3Source stuff
new thisRaceID;
new BeamSprite,HaloSprite; 
//Sound
new String:ThunderClapSound[]="SH/ThunderClapCaster.wav";

public Plugin:myinfo = 
{
	name = "SH hero Hulk",
	author = "Ownz",
	description = "SH Race",
	version = "1.0.0.0",
	url = "http://ownageclan.com"
};

// War3Source Functions

public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	War3_PrecacheSound(ThunderClapSound);
}
public OnPluginStart()
{
	
}
public OnSHLoadHeroOrItemOrdered(num)
{
	if(num==30)
	{
	
	
		
		thisRaceID=SHRegisterHero(
		"Hulk",
		"hulk",
		"Power Stomp",
		"Stun close by enemies and yourself",
		true
		);
	}
}

public OnSHEventSpawn(client)
{
	if(SH()){	//PrintToChatAll("SPAWN %d",client);
		War3_SetBuff(client,bStunned,thisRaceID,false);	
		War3_SetBuff(client,bStunned,thisRaceID,false);
	}
}



public OnPowerCommand(client,herotarget,bool:pressed){
	//PrintToChatAll("%d",herotarget);
	if(SHHasHero(client,herotarget)&&herotarget==thisRaceID){
		//PrintToChatAll("1");
		if(pressed && SH_SkillNotInCooldown(client,thisRaceID,true)){
			new Float:dist = 360.0;
			new ClaperTeam = GetClientTeam(client);
			new Float:ClaperPos[3];
			GetClientAbsOrigin(client,ClaperPos);
			new Float:VecPos[3];
			PrintHintText(client,"Used Stomp!!");
			EmitSoundToAll(ThunderClapSound,client);
			TE_SetupBeamRingPoint(ClaperPos, 10.0, dist, BeamSprite, HaloSprite, 0, 15, 0.5, 50.0, 10.0, {255,69,0,255}, 700, 0);
			TE_SendToAll();	
			for(new i=1;i<=MaxClients;i++)
			{
				if(ValidPlayer(i,true)&& GetClientTeam(i)!=ClaperTeam )
				{
					GetClientAbsOrigin(i,VecPos);
					if(GetVectorDistance(ClaperPos,VecPos)<=dist)
					{
						War3_DealDamage(i,30,client,_,"powestomp",W3DMGORIGIN_ULTIMATE,W3DMGTYPE_PHYSICAL);
						if(GetClientTeam(i)!=ClaperTeam){
						PrintHintText(i,"Attacked by Power Stomp -30HP , Slow");
						}			
						War3_SetBuff(i,bStunned,thisRaceID,true);
						CreateTimer(3.0,EndStunned,i);
					}
				}
			}
			SH_CooldownMGR(client,20.0,thisRaceID,_,_);
		}
	}
}
public Action:EndStunned(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		War3_SetBuff(client,bStunned,thisRaceID,false);
	}
}