#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

// War3Source stuff
new bool:bNoclip[66];
new Float:oldpos[66][3];
new Float:newpos[66][3];
new SKILL_NOCLIP;
new thisRaceID;
new Float:sectemp[66];
new Float:skill_sec=6.0;
public Plugin:myinfo = 
{
	name = "SH Hero Nightcrawler",
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
}

public OnSHLoadHeroOrItemOrdered(num)
{
	if(num==30)
	{
		
		thisRaceID=SHRegisterHero(
		"Nightcrawler",
		"nc",
		"Noclip",
		"Walk through walls",
		true
		);
		
	}
}

public OnWar3EventSpawn(client)
{
	if(SH()){
		if(SHHasHero(client,thisRaceID))
		{
			bNoclip[client]=false;
			War3_SetBuff(client,bNoClipMode,thisRaceID,false);	
		}
	}
}
public OnPowerCommand(client,herotarget,bool:pressed){
	//PrintToChatAll("%d",herotarget);
	if(SHHasHero(client,herotarget)&&herotarget==thisRaceID){
		//PrintToChatAll("1");
		if(pressed && War3_SkillNotInCooldown(client,thisRaceID,SKILL_NOCLIP,true) && !bNoclip[client]){
			GetClientAbsOrigin(client,oldpos[client]);
			bNoclip[client]=true;
			sectemp[client]=skill_sec;
			War3_SetBuff(client,bNoClipMode,thisRaceID,true);
			CreateTimer(0.0,TurnNoClip,client);
			SH_CooldownMGR(client,25.0,thisRaceID,_,_);
		}
	}
}
public Action:TurnNoClip(Handle:h,any:client){
	if(sectemp[client]<1.0)
	{
		War3_SetBuff(client,bNoClipMode,thisRaceID,false);
		GetClientAbsOrigin(client,newpos[client]);
		newpos[client][2]+=1.0;
		TeleportEntity(client,newpos[client],NULL_VECTOR,NULL_VECTOR);
		bNoclip[client]=false;
		CreateTimer(0.1,ChkStuck,client);
	}
	else{
		PrintCenterText(client, "Warning: Time limit : %.0f sec",sectemp[client]);
		sectemp[client]-=1.0;
		CreateTimer(1.0,TurnNoClip,client);
	}
}
public Action:ChkStuck(Handle:h,any:client){
	new Float:location[3];
	GetClientAbsOrigin(client,location);
	if(GetVectorDistance(newpos[client],location)<0.001)
	{
		PrintHintText(client, "You stucked, Teleport Old position");
		TeleportEntity(client,oldpos[client],NULL_VECTOR,NULL_VECTOR);
	}
}
