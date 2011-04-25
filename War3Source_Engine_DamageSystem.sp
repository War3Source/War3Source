


//DAMAGE SYSTEM




#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"

new Handle:FHOnW3TakeDmgAll;
new Handle:FHOnW3TakeDmgBullet;

new Handle:g_OnWar3EventPostHurtFH;


new g_Lastdamagetype;
new g_Lastinflictor; //variables from sdkhooks, natives retrieve them if needed
new g_LastDamageIsWarcraft; //for this damage only


new Float:damageModifierPercent;

new actualdamagedealt;

new bool:nextDamageIsWarcraftDamage; //dealdamage tells hook that the damage he hooked is warcraft damage
new bool:nextDamageIsTrueDamage;

new dummyresult;
public Plugin:myinfo= 
{
	name="W3S Engine Damage",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};



public APLRes:AskPluginLoad2Custom(Handle:myself,bool:late,String:error[],err_max)
{
	GlobalOptionalNatives();
	if(!InitNativesForwards())
	{
		LogError("[War3Source] There was a failure in creating the native / forwards based functions, definately halting.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	HookEvent("player_hurt",EventPlayerHurt);
	CreateTimer(1.0,SecondTimer,_,TIMER_REPEAT);
}


bool:InitNativesForwards()
{
	CreateNative("War3_DamageModPercent",Native_War3_DamageModPercent);

	CreateNative("W3GetDamageType",NW3GetDamageType);
	CreateNative("W3GetDamageInflictor",NW3GetDamageInflictor);
	CreateNative("W3GetDamageIsBullet",NW3GetDamageIsBullet);
	CreateNative("W3ForceDamageIsBullet",NW3ForceDamageIsBullet);
	
	CreateNative("War3_DealDamage",Native_War3_DealDamage);
	CreateNative("War3_GetWar3DamageDealt",Native_War3_GetWar3DamageDealt);

	
	FHOnW3TakeDmgAll=CreateGlobalForward("OnW3TakeDmgAll",ET_Hook,Param_Cell,Param_Cell,Param_Cell);
	FHOnW3TakeDmgBullet=CreateGlobalForward("OnW3TakeDmgBullet",ET_Hook,Param_Cell,Param_Cell,Param_Cell);

	
	g_OnWar3EventPostHurtFH=CreateGlobalForward("OnWar3EventPostHurt",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);

	return true;
}

public Native_War3_DamageModPercent(Handle:plugin,numParams)
{
	if(numParams==1)
	{
		new Float:num=GetNativeCell(1); 
		//PrintToChatAll("percent change %f",num);
		damageModifierPercent*=num;
		//1.0*num;
		//PrintToChatAll("2percent change %f",1.0+num);
		//PrintToChatAll("3percent change %f",100.0*(1.0+num));
	}
}



public NW3GetDamageType(Handle:plugin,numParams){
	return g_Lastdamagetype;
}
public NW3GetDamageInflictor(Handle:plugin,numParams){
	return g_Lastinflictor;
}
public NW3GetDamageIsBullet(Handle:plugin,numParams){
	return bool:(!g_LastDamageIsWarcraft);
}
public NW3ForceDamageIsBullet(Handle:plugin,numParams){
	g_LastDamageIsWarcraft=false;
}


public OnClientPutInServer(client){
	SDKHook(client,SDKHook_OnTakeDamage,SDK_Forwarded_OnTakeDamage);
}
public OnClientDisconnect(client){
	SDKUnhook(client,SDKHook_OnTakeDamage,SDK_Forwarded_OnTakeDamage); 
}


new DamageStack[255];
new DamageStackVictim[255];
new DamageStackLen=-1;

public Action:SDK_Forwarded_OnTakeDamage(victim,&attacker,&inflictor,&Float:damage,&damagetype)
{
	if(IsPlayerAlive(victim)){
	
		if(DamageStackLen>240){
			LogError("damage stack exceeded 240!");
			return Plugin_Changed;
		}
		DamageStackLen++;
		
		DamageStackVictim[DamageStackLen]=victim;
		
		//PrintToChatAll("SDKforwarded %f inflictor %d stack %d",damage,inflictor,DamageStackLen);
		damageModifierPercent=1.0;
		
	
		//set these first
		g_Lastdamagetype=damagetype;
		g_Lastinflictor=inflictor;
		
		new isBulletDamage=true;
		if(nextDamageIsWarcraftDamage){
			nextDamageIsWarcraftDamage=false; //reset this and set g_LastDamageIsWarcraft to that value
			g_LastDamageIsWarcraft=true;
			
			isBulletDamage=false;
			
			if(!nextDamageIsTrueDamage){
				damage=FloatMul(damage,W3GetMagicArmorMulti(victim));
			}
			//PrintToChatAll("magic %f %d to %d",W3GetMagicArmorMulti(victim),attacker,victim);
		}
		else{ //count as bullet now
		
			if(!nextDamageIsTrueDamage){
				damage=FloatMul(damage,W3GetPhysicalArmorMulti(victim));
			}
			//PrintToChatAll("physical %f %d to %d",W3GetPhysicalArmorMulti(victim),attacker,victim);
			g_LastDamageIsWarcraft=false;
		}
		
		//PrintToChatAll("takedmg %f BULLET %d   lastiswarcraft %d",damage,isBulletDamage,g_LastDamageIsWarcraft);
		
		
		Call_StartForward(FHOnW3TakeDmgAll);
		Call_PushCell(victim);
		Call_PushCell(attacker);
		Call_PushCell(damage);
		Call_Finish(dummyresult); //this will be returned to
	
		if(isBulletDamage){
			Call_StartForward(FHOnW3TakeDmgBullet);
			Call_PushCell(victim);
			Call_PushCell(attacker);
			Call_PushCell(damage);
			Call_Finish(dummyresult); //this will be returned to
			
		}
	
		//modify final damage
		damage=damage*damageModifierPercent; ////so we calculate the percent 
	
		//PrintToChatAll("new damage? %f",damage);
		//return Action:result;
	}
	return Plugin_Changed;
}


public EventPlayerHurt(Handle:event,const String:name[],bool:dontBroadcast){
	

	new victim_userid=GetEventInt(event,"userid");
	new attacker_userid=GetEventInt(event,"attacker");
	new dmgamount=GetEventInt(event,"dmg_health");
	if(War3_GetGame()==Game_TF)
		dmgamount=GetEventInt(event,"damageamount");
	
	new victim=GetClientOfUserId(victim_userid);
	new attacker=GetClientOfUserId(attacker_userid);
	
//	new String:weapon[32];
	//GetEventString(event, "weapon", weapon, sizeof(weapon));
	//PrintToChatAll("PostHurt %d %s stack %d",dmgamount,weapon,DamageStackLen);
	
	DamageStack[DamageStackLen]=dmgamount;
	
	new Handle:oldevent=W3GetVar(SmEvent,event);
	W3SetVar(SmEvent,event); //stacking on stack 
	DoFwd_OnWar3EventPostHurt(victim,attacker,dmgamount);
	W3SetVar(SmEvent,oldevent); //stacking on stack 
	
	
	DamageStackLen--;
}

DoFwd_OnWar3EventPostHurt(victim,attacker,dmgamount){
	Call_StartForward(g_OnWar3EventPostHurtFH);
	Call_PushCell(victim);
	Call_PushCell(attacker);
	Call_PushCell(dmgamount);
	Call_Finish(dummyresult);
//	PrintToChatAll("posthurt %d",dmgamount);
}


////if dealdamage is called then player died, posthurt will not be called and stack length stays longer
///since this is single threaded, we assume there is no actual damage exchange when a timer hits, we reset the stack length 
public Action:SecondTimer(Handle:t,any:a){
	DamageStackLen=-1;
}















public Native_War3_DealDamage(Handle:plugin,numParams)
{
	
	if(numParams!=9){
		
		ThrowError("Error War3_DealDamage OLD INCOMPATABLE RACE!!: params %d",numParams);
	}
	if(numParams==9)
	{
		
		
		decl victim;
		victim=GetNativeCell(1);
		decl damage;
		damage=GetNativeCell(2);
		
		if(ValidPlayer(victim,true) && damage>0 )
		{
			actualdamagedealt=0;
			
			decl attacker;
			attacker=GetNativeCell(3);
			new dmg_type;
			dmg_type=GetNativeCell(4);  //original weapon damage type
			decl String:weapon[64];
			GetNativeString(5,weapon,64);
			
			
			
			decl War3DamageOrigin:W3DMGORIGIN;
			W3DMGORIGIN=GetNativeCell(6);
			decl War3DamageType:WAR3_DMGTYPE;
			WAR3_DMGTYPE=GetNativeCell(7);
			
			decl bool:respectVictimImmunity;
			respectVictimImmunity=GetNativeCell(8);
			
			if(respectVictimImmunity){
				switch(W3DMGORIGIN){
					case W3DMGORIGIN_SKILL:  {
						if(W3HasImmunity(victim,Immunity_Skills) ){
							return false;
						}
					}
					case W3DMGORIGIN_ULTIMATE:  {
						if(W3HasImmunity(victim,Immunity_Ultimates) ){
							return false;
						}
					}
					case W3DMGORIGIN_ITEM:  {
						if(W3HasImmunity(victim,Immunity_Items) ){
							return false;
						}
					}
					
				}
				
				
				switch(WAR3_DMGTYPE){
					case W3DMGTYPE_PHYSICAL:  {
						if(W3HasImmunity(victim,Immunity_PhysicalDamage) ){
							return false;
						}
					}
					case W3DMGTYPE_MAGIC:  {
						if(W3HasImmunity(victim,Immunity_MagicDamage) ){
							return false;
						}
					}
				}
			}
			new bool:countAsFirstTriggeredDamage;
			countAsFirstTriggeredDamage=GetNativeCell(9);
			
			if(countAsFirstTriggeredDamage){
				nextDamageIsWarcraftDamage=false;
			}
			else {
				nextDamageIsWarcraftDamage=true;
			}
		
			new bool:settobullet=bool:W3GetDamageIsBullet(); //just in case someone dealt damage inside this forward and made it "not bullet"
			new Float:oldDamageMulti=damageModifierPercent; //nested damage woudl change the first triggering damage multi
			/////TO DO: IMPLEMENT PHYAISCAL AND MAGIC ARMOR
			
			actualdamagedealt=damage;
			decl oldcsarmor;
			if((WAR3_DMGTYPE==W3DMGTYPE_TRUEDMG||WAR3_DMGTYPE==W3DMGTYPE_MAGIC)&&War3_GetGame()==CS){
				oldcsarmor=War3_GetCSArmor(victim);
				War3_SetCSArmor(victim,0) ;
			}
			
			nextDamageIsTrueDamage=(WAR3_DMGTYPE==W3DMGTYPE_TRUEDMG);
		
			
			if(damage<1){
				damage=1;
			}
		
			
			//decl oldvictimhp;
			//oldvictimhp=GetClientHealth(victim);
			

			
			decl String:dmg_str[16];
			IntToString(damage,dmg_str,sizeof(dmg_str));
			decl String:dmg_type_str[32];
			IntToString(dmg_type,dmg_type_str,sizeof(dmg_type_str));
			
			new pointHurt=CreateEntityByName("point_hurt");
			if(pointHurt)
			{
			//	PrintToChatAll("%d %d %d",victim,damage,actualdamagedealt);
				DispatchKeyValue(victim,"targetname","war3_hurtme"); //set victim as the target for damage
				DispatchKeyValue(pointHurt,"Damagetarget","war3_hurtme");
				DispatchKeyValue(pointHurt,"Damage",dmg_str);
				DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
				if(!StrEqual(weapon,""))
				{
					DispatchKeyValue(pointHurt,"classname",weapon);
				}
				else{
					DispatchKeyValue(pointHurt,"classname","war3_point_hurt");
				}
				DispatchSpawn(pointHurt);
				AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
				//DispatchKeyValue(pointHurt,"classname","point_hurt");
				DispatchKeyValue(victim,"targetname","war3_donthurtme"); //unset the victim as target for damage
				RemoveEdict(pointHurt);
			//	PrintToChatAll("%d %d %d",victim,damage,actualdamagedealt);
			}
			/*point_hurtEntity=CreateEntityByName("point_hurt");
			if(point_hurtEntity)
			{
				
				DispatchKeyValue(victim,"targetname","war3_hurtme"); //set victim as the target for damage
				DispatchKeyValue(point_hurtEntity,"Damagetarget","war3_hurtme");
				DispatchKeyValue(point_hurtEntity,"Damage",dmg_str);
				DispatchKeyValue(point_hurtEntity,"DamageType",dmg_type_str);
				
				if(!StrEqual(weapon,""))
				{
					DispatchKeyValue(point_hurtEntity,"classname",weapon);
				}
				else{
					DispatchKeyValue(point_hurtEntity,"classname","war3_point_hurt");
				}
				DispatchSpawn(point_hurtEntity);
				AcceptEntityInput(point_hurtEntity,"Hurt",(attacker>0)?attacker:-1);
				
				DispatchKeyValue(victim,"targetname","war3_donthurtme"); //unset the victim as target for damage
				RemoveEdict(point_hurtEntity);
			}*/
			
			//PrintToChatAll("damagestack after dealdamage = %d len %d",DamageStack[DamageStackLen+1],DamageStackLen);
			actualdamagedealt=DamageStack[DamageStackLen+1];
			/*   ///after damage is dealt
			if(IsPlayerAlive(victim)){
				actualdamagedealt=oldvictimhp-GetClientHealth(victim);
				//PrintToChatAll("victim still alive: remaining hp %d with, %d damage dealt?",GetClientHealth(victim),actualdamagedealt);
			}
			else{    
			
				//he died, estimate ddamage dealt with armor
				
				if(WAR3_DMGTYPE==W3DMGTYPE_PHYSICAL){
					damage=RoundFloat(FloatMul(W3GetPhysicalArmorMulti(victim),float(damage)));
				}
				else if(WAR3_DMGTYPE==W3DMGTYPE_MAGIC){
					damage=RoundFloat(FloatMul(W3GetMagicArmorMulti(victim),float(damage)));
				}
				
				actualdamagedealt=damage;
				//PrintToChatAll("victim is dead, assumed damge = %d",actualdamagedealt);
				
			}*/
			if((WAR3_DMGTYPE==W3DMGTYPE_TRUEDMG||WAR3_DMGTYPE==W3DMGTYPE_MAGIC)&&War3_GetGame()==CS){
				War3_SetCSArmor(victim,oldcsarmor);
			}
			
			if(settobullet){
				W3ForceDamageIsBullet(); //just in case someone dealt damage inside this forward and made it "not bullet"
			}
			damageModifierPercent=oldDamageMulti;
		}
		else{
			return false;
		}
	}
	return true;
}
public Native_War3_GetWar3DamageDealt(Handle:plugin,numParams) {
	return actualdamagedealt;
}