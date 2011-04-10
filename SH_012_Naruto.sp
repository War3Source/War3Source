#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

// War3Source stuff
new Float:teleportpos[66][3];
new thisRaceID;
new BeamSprite,HaloSprite;
//new String:Rasengang[]="SH/Rasengang.wav";
new Raattacker[66];
public Plugin:myinfo = 
{
	name = "SH Hero Naruto",
	author = "GGHH3322",
	description = "SH Hero",
	version = "1.0.0.0",
	url = "http://war3source.com"
};

// War3Source Functions
public OnPluginStart()
{
}
public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	//War3_PrecacheSound(Rasengang);
}

public OnSHLoadHeroOrItemOrdered(num)
{
	if(num==30)
	{
		
		thisRaceID=SHRegisterHero(
		"Naruto",
		"naruto",
		"Rasengang",
		"1.5sec Make Rasengang, and shot target",
		true
		);
		
	}
}

new Float:oldpos[66][3];
new Float:dirRasen[3];
new Float:endpos[3];
new Float:startpos[3];
new ClientTracer;
new Float:distanceRasen=500.0;
new Float:angleRasen[3];
public OnPowerCommand(client,herotarget,bool:pressed){
	//PrintToChatAll("%d",herotarget);
	if(SHHasHero(client,herotarget)&&herotarget==thisRaceID){
		//PrintToChatAll("1");
		if(pressed && War3_SkillNotInCooldown(client,thisRaceID,0,true)){
			new target = War3_GetTargetInViewCone(client,500.0,false,_,ImmunityFilterFunc);
			if(target>0)
			{
				GetClientAbsOrigin(client,oldpos[client]);
				
				if(!TeleportToPlayer(client,target)){
					PrintHintText(client,"Could not find empty location");
				}
				
			}
			else{
				W3MsgNoTargetFound(client,500.0);
			}
		}
	}
}
public bool:ImmunityFilterFunc(entity){
	if(!W3HasImmunity(entity,Immunity_Skills)){
		return true;
	}
	return true;
}

new ignoreClient;
public bool:AimTargetFilter(entity){
	if(entity==ignoreClient){
		return false;
	}
	return true;
}

bool:TeleportToPlayer(client,target){
	new Float:clientpos[3]
	new Float:targetpos[3]
	GetClientAbsOrigin(client,clientpos);
	GetClientAbsOrigin(target,targetpos);
	
	new Float:distanceVector[3];
	SubtractVectors(targetpos,clientpos,distanceVector);
	new Float:distance=GetVectorDistance(targetpos,clientpos);
	new Float:newdistance=distance-30.0;
	ScaleVector(distanceVector,newdistance/distance)
	//PrintToChatAll("scale %f",newdistance/distance);
	
	new Float:newpos[3];
	AddVectors(clientpos, distanceVector, newpos)
	
	new Float:returnpos[3];
	getEmptyLocationHull(client,newpos,returnpos);
	if(GetVectorLength(returnpos)<0.1){
		return false;
	}
	else{
		TeleportEntity(client,returnpos,NULL_VECTOR,NULL_VECTOR);
	}
	return true;
}
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};//,27,-27,30,-30,33,-33,40,-40}; //for human it needs to be smaller

public bool:getEmptyLocationHull(client,Float:originalpos[3],Float:returnpos[3]){
	
	
	new Float:mins[3];
	new Float:maxs[3];
	GetClientMins(client,mins);
	GetClientMaxs(client,maxs);
	
	//PrintToChatAll("min : %.1f %.1f %.1f MAX %.1f %.1f %.1f",mins[0],mins[1],mins[2],maxs[0],maxs[1],maxs[2]);
	new absincarraysize=sizeof(absincarray);
	
	new limit=5000;
	for(new x=0;x<absincarraysize;x++){
		if(limit>0){
			for(new y=0;y<=x;y++){
				if(limit>0){
					for(new z=0;z<=y;z++){
						new Float:pos[3]={0.0,0.0,0.0};
						AddVectors(pos,originalpos,pos);
						pos[0]+=float(absincarray[x]);
						pos[1]+=float(absincarray[y]);
						pos[2]+=float(absincarray[z]);
						
						//PrintToChatAll("hull at %.1f %.1f %.1f",pos[0],pos[1],pos[2]);
						//PrintToServer("hull at %d %d %d",absincarray[x],absincarray[y],absincarray[z]);
						TR_TraceHullFilter(pos,pos,mins,maxs,MASK_SOLID,CanHitThis,client);
						//new ent;
						if(TR_DidHit(_))
						{
							//PrintToChatAll("2");
							//ent=TR_GetEntityIndex(_);
							//PrintToChatAll("hit %d self: %d",ent,client);
						}
						else{
							//TeleportEntity(client,pos,NULL_VECTOR,NULL_VECTOR);
							AddVectors(Float:{0.0,0.0,0.0},pos,returnpos); ///set this gloval variable
							limit=-1;
							break;
						}
					
						if(limit--<0){
							break;
						}
					}
					
					if(limit--<0){
						break;
					}
				}
			}
			
			if(limit--<0){
				break;
			}
			
		}
		
	}

} 
public bool:CanHitThis(entityhit, mask, any:data)
{
	if(entityhit == data )
	{// Check if the TraceRay hit the itself.
		return false; // Don't allow self to be hit, skip this result
	}
	if(ValidPlayer(entityhit)&&ValidPlayer(data)&&War3_GetGame()==Game_TF&&GetClientTeam(entityhit)==GetClientTeam(data)){
		return false; //skip result, prend this space is not taken cuz they on same team
	}
	return true; // It didn't hit itself
}

