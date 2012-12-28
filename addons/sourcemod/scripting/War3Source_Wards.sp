/*
* File: War3Source_Wards.sp
* Description: Ward Behavior definitions
* Author(s): Invalid
*/

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

enum {
	DAMAGE=0,
	HEAL
}

new BehaviorIndex[3];

new BeamSprite =-1;
new HaloSprite =-1;

public Plugin:myinfo = 
{
	name = "War3Source - Ward Behavior Definitions",
	author = "Invalid && necavi",
	description = "Ward behaviors",
	version = "1.0",
	url = "http://necavi.org/"
};

public OnPluginStart()
{
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if (num==0)
	{
		BehaviorIndex[DAMAGE]=War3_CreateWardBehavior("damage","Damage ward","Deals damage to targets");
		BehaviorIndex[HEAL]=War3_CreateWardBehavior("heal","Healing ward","Heals targets");
	}
}

public OnWardPulse(wardindex, behavior) {
	new beamcolor[4];
	if(War3_GetWardUseDefaultColor(wardindex)) {
		if(behavior == BehaviorIndex[DAMAGE]) {
			if(GetClientTeam(War3_GetWardOwner(wardindex)) == 2) {
				beamcolor = {0,0,255,255};
			} else {
				beamcolor = {255,0,0,255};
			}
		} else {
			if(GetClientTeam(War3_GetWardOwner(wardindex)) == 2) {
				beamcolor = {0,255,128,255};
			} else {
				beamcolor = {128,255,0,255};
			}
		}
	} else {
		if(GetClientTeam(War3_GetWardOwner(wardindex)) == 2) {
			War3_GetWardColor2(wardindex, beamcolor);
		} else {
			War3_GetWardColor3(wardindex, beamcolor);
		}
	}
	doVisualEffect(wardindex,beamcolor);
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

public OnWardTrigger(wardindex,victim,owner,behavior) {
	decl data[MAXWARDDATA];
	decl Float:VictimPos[3];
	
	War3_GetWardData(wardindex,data);
	GetClientAbsOrigin(victim,VictimPos);

	if (behavior==BehaviorIndex[DAMAGE]) {
		new damage = data[War3_GetSkillLevel(owner,War3_GetRace(owner),War3_GetWardSkill(wardindex))];
		
		War3_DealDamage(victim,damage,owner,_,"weapon_wards");
		VictimPos[2]+=65.0;
		War3_TF_ParticleToClient(0, GetClientTeam(victim)==2?"healthgained_red":"healthgained_blu", VictimPos);
	}
	else if (behavior==BehaviorIndex[HEAL]) {
		new healamt = data[War3_GetSkillLevel(owner,War3_GetRace(owner),War3_GetWardSkill(wardindex))];
		
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