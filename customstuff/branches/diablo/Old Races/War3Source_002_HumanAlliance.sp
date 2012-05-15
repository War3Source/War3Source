/**
 * File: War3Source_HumanAlliance.sp
 * Description: The Human Alliance race for War3Source.
 * Author(s): Anthony Iacono 
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include "W3SIncs/sdkhooks"
public W3ONLY(){} //unload this?
new thisRaceID;

new Handle:ultCooldownCvar;
new bool:bIsBashed[MAXPLAYERSCUSTOM];

//new Handle:FreezeTimeCvar;


// Chance/Info Arrays
new Float:BashChance[5]={0.0,0.07,0.13,0.19,0.25};
new Float:TeleportDistance[5]={0.0,600.0,700.0,850.0,1000.0};

new Float:InvisibilityAlphaTF[5]={1.0,0.84,0.68,0.56,0.40};

new Float:InvisibilityAlphaCS[5]={1.0,0.90,0.8,0.7,0.6};


new DevotionHealth[5]={0,15,25,35,45};
//new health_Offset;


// Effects
new BeamSprite,HaloSprite;

new SKILL_INVIS, SKILL_BASH, SKILL_HEALTH,ULT_TELEPORT;

new String:teleportSound[]="war3source/blinkarrival.wav";

public Plugin:myinfo = 
{
	name = "Race - Human Alliance",
	author = "PimpinJuice",
	description = "The Human Alliance race for War3Source.",
	version = "1.0.0.0",
	url = "http://war3source.com"
};

public OnPluginStart()
{
	
	ultCooldownCvar=CreateConVar("war3_human_teleport_cooldown","20.0","Cooldown between teleports");
	

	
	LoadTranslations("w3s.race.human.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==20)
	{
	
		thisRaceID=War3_CreateNewRaceT("human");
		SKILL_INVIS=War3_AddRaceSkillT(thisRaceID,"Invisibility",false,4,"60% (CS), 40% (TF)");
		SKILL_HEALTH=War3_AddRaceSkillT(thisRaceID,"DevotionAura",false,4,"15/25/35/45");
		SKILL_BASH=War3_AddRaceSkillT(thisRaceID,"Bash",false,4,"7/13/19/25%","0.2");
		ULT_TELEPORT=War3_AddRaceSkillT(thisRaceID,"Teleport",true,4,"600/800/1000/1200");
		W3SkillCooldownOnSpawn(thisRaceID,ULT_TELEPORT,10.0,_);
		War3_CreateRaceEnd(thisRaceID);
		
		
		//if(War3_GetGame()==Game_TF){
			//health_Offset=FindSendPropOffs("CTFPlayer","m_iHealth");
	//	}
	}
}

public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	
	War3_PrecacheSound(teleportSound);
	
	
	
	
	//CreateTimer(0.2, LoadSounds);
}
public Action:LoadSounds(Handle:h){
	new String:longsound[512];
	
	Format(longsound,sizeof(longsound), "sound/%s", teleportSound);
	AddFileToDownloadsTable(longsound); 
	
	if(PrecacheSound(teleportSound, true)){
		PrintToServer("TPrecacheSound %s",longsound);
	}
	else{
		PrintToServer("Failed: PrecacheSound %s",longsound);
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0); // if we aren't their race anymore we shouldn't be controlling their alpha
	//	War3_SetBuff(client,bInvisWeaponOverride,thisRaceID,false);
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
			
	}
	else
	{
		ActivateSkills(client);
		
	}
}
public ActivateSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
	
		new skill_devo=War3_GetSkillLevel(client,thisRaceID,SKILL_HEALTH);
		if(skill_devo)
		{
			// Devotion Aura
			new hpadd=DevotionHealth[skill_devo];
			new Float:vec[3];
			GetClientAbsOrigin(client,vec);
			vec[2]+=20.0;
			new ringColor[4]={0,0,0,0};
			new team=GetClientTeam(client);
			if(team==2)
			{
				ringColor={255,0,0,255};
			}
			else if(team==3)
			{
				ringColor={0,0,255,255};
			}
			TE_SetupBeamRingPoint(vec,40.0,10.0,BeamSprite,HaloSprite,0,15,1.0,15.0,0.0,ringColor,10,0);
			TE_SendToAll();

			War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,hpadd);
			
		//	SetEntityHealth(client,GetClientHealth(client)+hpadd);
		//	War3_SetMaxHP(client,War3_GetMaxHP(client)+hpadd);
			
		}
		
		new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_INVIS);
		new Float:alpha=(War3_GetGame()==Game_CS)?InvisibilityAlphaCS[skilllevel]:InvisibilityAlphaTF[skilllevel];
	
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,alpha);
		//War3_SetBuff(client,bInvisWeaponOverride,thisRaceID,true);
		//War3_SetBuff(client,iInvisWeaponOverrideAmount,thisRaceID,1);

	}
}
new bool:inteleportcheck[MAXPLAYERSCUSTOM];
public OnUltimateCommand(client,race,bool:pressed)
{
	new userid=GetClientUserId(client);
	if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) && !Silenced(client))
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_TELEPORT);
		if(ult_level>0)
		{
			
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_TELEPORT,true)&&!inteleportcheck[client]) //not in the 0.2 second delay when we check stuck via moving
			{
				TeleportPlayerView(client,TeleportDistance[ult_level]);
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
			
		}
	}
}



public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	if(race==thisRaceID&&skill==0&&newskilllevel>=0&&War3_GetRace(client)==thisRaceID)
	{
		new Float:alpha=(War3_GetGame()==Game_CS)?InvisibilityAlphaCS[newskilllevel]:InvisibilityAlphaTF[newskilllevel];
		if(newskilllevel>0 && IsPlayerAlive(client)) // dont tell them if they are dead
			//War3_ChatMessage(client,"You fade %s into the backdrop.",(newskilllevel==1)?"slightly":(newskilllevel==2)?"well":(newskilllevel==3)?"greatly":"dramatically");
			War3_SetBuff(client,fInvisibilitySkill,thisRaceID,alpha);
	}
}

public OnWar3EventPostHurt(victim,attacker,damage){
	//LastDamageTime[victim]=GetEngineTime();
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race=War3_GetRace(attacker);
			if(race==thisRaceID)
			{
				new skill_bash=War3_GetSkillLevel(attacker,race,SKILL_BASH);
				if(skill_bash && !Hexed(attacker) &&!W3HasImmunity(victim,Immunity_Skills))
				{
					// Bash
					new Float:chance_mod=W3ChanceModifier(attacker);
					new Float:percent=BashChance[skill_bash];
					if(GetRandomFloat(0.0,1.0)<=percent*chance_mod && !bIsBashed[victim] && IsPlayerAlive(attacker))
					{
						
						bIsBashed[victim]=true;
						War3_SetBuff(victim,bBashed,thisRaceID,true);

						W3FlashScreen(victim,RGBA_COLOR_RED);
						CreateTimer(0.2,UnfreezePlayer,victim);
						
						PrintHintText(victim,"%T","RcvdBash",victim);
						PrintHintText(attacker,"%T","Bashed",attacker);
					}
				}
			}
		}
	}
}


public OnWar3EventSpawn(client){
	//PrintToChatAll("3");
	bIsBashed[client]=false;
	War3_SetBuff(client,bBashed,thisRaceID,false);
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		ActivateSkills(client);
		//LastDamageTime[client]=GetEngineTime()-10.0;
	}
}


public Action:UnfreezePlayer(Handle:timer,any:client)
{
	
	//PrintHintText(client,"NO LONGER BASHED");
	War3_SetBuff(client,bBashed,thisRaceID,false);
	//SetEntityMoveType(client,MOVETYPE_WALK);
	bIsBashed[client]=false;
	
}

// Teleport Stuff
// By: stinkyfax
// Much thanks, this would be a nightmare without him.
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERSCUSTOM][3];
new Float:teleportpos[MAXPLAYERSCUSTOM][3];

bool:TeleportPlayerView(client,Float:distance)
{
	if(client>0)
	{
		if(IsPlayerAlive(client))
		{
			
			new Float:angle[3];
			GetClientEyeAngles(client,angle);
			new Float:endpos[3];
			new Float:startpos[3];
			GetClientEyePosition(client,startpos);
			new Float:dir[3];
			GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
			
			ScaleVector(dir, distance);
			//PrintToChatAll("DIR %f %f %f",dir[0],dir[1],dir[2]);
			
			AddVectors(startpos, dir, endpos);
			
			GetClientAbsOrigin(client,oldpos[client]);
			
			
			//PrintToChatAll("1");
			
			ClientTracer=client;
			TR_TraceRayFilter(startpos,endpos,MASK_ALL,RayType_EndPoint,AimTargetFilter);
			TR_GetEndPosition(endpos);
			
			
			//new Float:normal[3];
			//TR_GetPlaneNormal(INVALID_HANDLE,normal);
			
			//ScaleVector(normal, 20.0);
			
			
			if(enemyImmunityInRange(client,endpos)){
				W3MsgEnemyHasImmunity(client);
				return false;
			}
			
			//PrintToChatAll("1endpos %f %f %f",endpos[0],endpos[1],endpos[2]);
			new Float:distanceteleport=GetVectorDistance(startpos,endpos);
			if(distanceteleport<150.0){
				new String:buffer[100];
				Format(buffer, sizeof(buffer), "%T", "Distance too short.", client);
				PrintHintText(client,buffer);
				return false;
			}
			GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);///get dir again
			ScaleVector(dir, distanceteleport-33.0);
			
			AddVectors(startpos,dir,endpos);
			//PrintToChatAll("DIR %f %f %f",dir[0],dir[1],dir[2]);
			
			//PrintToChatAll("2endpos %f %f %f",endpos[0],endpos[1],endpos[2]);
			
			//endpos[1]=(startpos[1]+(distance*Sine(DegToRad(angle[1]))));
			//endpos[0]=(startpos[0]+(distance*Cosine(DegToRad(angle[1]))));
			//if(!CheckPlayerBox(endpos,startpos,client))
			//	return false;
			emptypos[0]=0.0;
			emptypos[1]=0.0;
			emptypos[2]=0.0;
			
			endpos[2]-=30.0;
			getEmptyLocationHull(client,endpos);
			
			//PrintToChatAll("emptypos %f %f %f",emptypos[0],emptypos[1],emptypos[2]);
			if(GetVectorLength(emptypos)<1.0){
				new String:buffer[100];
				Format(buffer, sizeof(buffer), "%T", "NoEmptyLocation", client);
				PrintHintText(client,buffer);
				return false; //it returned 0 0 0
			}
			
			
			TeleportEntity(client,emptypos,NULL_VECTOR,NULL_VECTOR);
			EmitSoundToAll(teleportSound,client);
			EmitSoundToAll(teleportSound,client);
			
			
			
			teleportpos[client][0]=emptypos[0];
			teleportpos[client][1]=emptypos[1];
			teleportpos[client][2]=emptypos[2];
			
			inteleportcheck[client]=true;
			CreateTimer(0.14,checkTeleport,client);
			
			
			
			
			
			
			return true;
		}
	}
	return false;
}
public Action:checkTeleport(Handle:h,any:client){
	inteleportcheck[client]=false;
	new Float:pos[3];
	
	GetClientAbsOrigin(client,pos);
	
//	new Float:velocity[3];
	
	//GetEntDataVector(client,m_vecVelocity,velocity);
	//PrintToChatAll("%f/%f %f/%f %f/%f",teleportpos[client][0],pos[0],teleportpos[client][1],pos[1],teleportpos[client][2],pos[2]);
	
	if(GetVectorDistance(teleportpos[client],pos)<0.001)//he didnt move in this 0.1 second
	{
		TeleportEntity(client,oldpos[client],NULL_VECTOR,NULL_VECTOR);
		PrintHintText(client,"%T","CantTeleportHere",client);
	}
	else{
	
		
		PrintHintText(client,"%T","Teleported",client);
		
		new Float:cooldown=GetConVarFloat(ultCooldownCvar);
		War3_CooldownMGR(client,cooldown,thisRaceID,ULT_TELEPORT,_,_);
	}
}
public bool:AimTargetFilter(entity,mask)
{
	return !(entity==ClientTracer);
}


new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};//,27,-27,30,-30,33,-33,40,-40}; //for human it needs to be smaller

public bool:getEmptyLocationHull(client,Float:originalpos[3]){
	
	
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
							AddVectors(emptypos,pos,emptypos); ///set this gloval variable
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


public bool:enemyImmunityInRange(client,Float:playerVec[3])
{
	//ELIMINATE ULTIMATE IF THERE IS IMMUNITY AROUND
	//new Float:playerVec[3];
	//GetClientAbsOrigin(client,playerVec);
	new Float:otherVec[3];
	new team = GetClientTeam(client);

	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Ultimates))
		{
			GetClientAbsOrigin(i,otherVec);
			if(GetVectorDistance(playerVec,otherVec)<350)
			{
				return true;
			}
		}
	}
	return false;
}             
