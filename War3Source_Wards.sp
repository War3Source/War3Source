/*
* File: War3Source_Wards.sp
* Description: Ward Behavior definitions
* Author(s): Invalid
*/

#include <SourceMod>
#include "W3SIncs/War3Source_Interface"

#define WARDBELOW -2.0 // player is 60 units tall about (6 feet)
#define WARDABOVE 160.0
#define MAXWARDDATA 32

enum {
	DAMAGE=0,
	HEAL
}

new WardIndex[3];

new BeamSprite =-1;
new HaloSprite =-1;

public Plugin:myinfo = 
{
	name = "War3Source - Ward Behavior Definitions",
	author = "Invalid",
	description = "Ward behaviors",
	version = "1.0",
	url = "none"
};

public OnPluginStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if (num==0)
	{
		WardIndex[DAMAGE]=War3_CreateWardBehavior("damage","Damage ward","Deals damage to targets");
		WardIndex[HEAL]=War3_CreateWardBehavior("heal","Healing ward","Heals targets");
	}
}

public OnWardPulse(wardindex) {
	new beamcolor[4];

	if (wardindex==WardIndex[DAMAGE]) {
		beamcolor={255,0,0,160};
		doVisualEffect(wardindex,beamcolor);
	}
	else if (wardindex==WardIndex[HEAL]) {
		beamcolor={0,255,0,160};
		doVisualEffect(wardindex,beamcolor);
	}
}

doVisualEffect(wardindex,beamcolor[4]) {
	decl Float:location[3];
	War3_GetWardLocation(wardindex,location);
	new Float:interval = War3_GetWardInterval(wardindex);
	new radius = War3_GetWardRadius(wardindex);

	new Float:start_pos[3];
	new Float:end_pos[3];
	new Float:tempVec1[]={0.0,0.0,WARDBELOW};
	new Float:tempVec2[]={0.0,0.0,WARDABOVE};
	AddVectors(location,tempVec1,start_pos);
	AddVectors(location,tempVec2,end_pos);
	TE_SetupBeamPoints(start_pos,end_pos,BeamSprite,HaloSprite,0,GetRandomInt(30,100),interval,70.0,70.0,0,30.0,beamcolor,10);
	TE_SendToAll()
	
	new Float:StartRadius = radius/2.0;
	new Speed = RoundToFloor((radius-StartRadius)/interval)
	
	TE_SetupBeamRingPoint(location,StartRadius,float(radius),BeamSprite,HaloSprite,0,1,interval,20.0,1.5,beamcolor,Speed,0);
	TE_SendToAll();
}

public OnWardTrigger(wardindex,victim,owner) {
	decl data[MAXWARDDATA];
	decl Float:VictimPos[3];
	
	War3_GetWardData(wardindex,data);
	GetClientAbsOrigin(victim,VictimPos);

	if (wardindex==WardIndex[DAMAGE]) {
		new damage = data[0];
		
		War3_DealDamage(victim,damage,owner,_,"weapon_wards");
		VictimPos[2]+=65.0;
		War3_TF_ParticleToClient(0, GetClientTeam(victim)==2?"healthgained_red":"healthgained_blu", VictimPos);
	}
	else if (wardindex==WardIndex[HEAL]) {
		new healamt = data[0];
		
		new cur_hp=GetClientHealth(victim);
		new new_hp=cur_hp+healamt;
		new max_hp=War3_GetMaxHP(victim);
		if(new_hp>max_hp)	new_hp=max_hp;
		if(cur_hp<new_hp)
		{
			War3_HealToMaxHP(victim,healamt);
			VictimPos[2]+=65.0;
			War3_TF_ParticleToClient(0, GetClientTeam(victim)==2?"healthgained_red":"healthgained_blu", VictimPos);
		}
	}
}