


//DAMAGE SYSTEM




#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"

///would you like to see the damage stack print out?
//#define DEBUG

new Handle:FHOnW3TakeDmgAllPre;
new Handle:FHOnW3TakeDmgBulletPre;
new Handle:FHOnW3TakeDmgAll;
new Handle:FHOnW3TakeDmgBullet;

new Handle:g_OnWar3EventPostHurtFH;


new g_CurDamageType=-99;
new g_CurInflictor=-99; //variables from sdkhooks, natives retrieve them if needed
new g_CurDamageIsWarcraft=0; //for this damage only
new g_CurDamageIsTrueDamage=0; //not used yet?

new Float:g_CurDMGModifierPercent=-99.9;

new g_CurLastActualDamageDealt=-99;

new bool:g_CanSetDamageMod=false; //default false, you may not change damage percent when there is none to change
new bool:g_CanDealDamage=true; //default true, you can initiate damage out of nowhere
//for deal damage only
new g_NextDamageIsWarcraftDamage=0; 
new g_NextDamageIsTrueDamage=0;

new dummyresult;


new damagestack=0;


public Plugin:myinfo= 
{
	name="W3S Engine Damage",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};


public OnPluginStart()
{
	HookEvent("player_hurt",EventPlayerHurt);
}


public bool:InitNativesForwards()
{
	CreateNative("War3_DamageModPercent",Native_War3_DamageModPercent);

	CreateNative("W3GetDamageType",NW3GetDamageType);
	CreateNative("W3GetDamageInflictor",NW3GetDamageInflictor);
	CreateNative("W3GetDamageIsBullet",NW3GetDamageIsBullet);
	CreateNative("W3ForceDamageIsBullet",NW3ForceDamageIsBullet);
	
	CreateNative("War3_DealDamage",Native_War3_DealDamage);
	CreateNative("War3_GetWar3DamageDealt",Native_War3_GetWar3DamageDealt);

	CreateNative("W3GetDamageStack",NW3GetDamageStack);


	FHOnW3TakeDmgAllPre=CreateGlobalForward("OnW3TakeDmgAllPre",ET_Hook,Param_Cell,Param_Cell,Param_Cell);
	FHOnW3TakeDmgBulletPre=CreateGlobalForward("OnW3TakeDmgBulletPre",ET_Hook,Param_Cell,Param_Cell,Param_Cell);
	FHOnW3TakeDmgAll=CreateGlobalForward("OnW3TakeDmgAll",ET_Hook,Param_Cell,Param_Cell,Param_Cell);
	FHOnW3TakeDmgBullet=CreateGlobalForward("OnW3TakeDmgBullet",ET_Hook,Param_Cell,Param_Cell,Param_Cell);

	
	g_OnWar3EventPostHurtFH=CreateGlobalForward("OnWar3EventPostHurt",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);

	return true;
}

public Native_War3_DamageModPercent(Handle:plugin,numParams)
{
	if(!g_CanSetDamageMod){
		LogError("You may not set damage mod percent here, use ....Pre forward");
		W3LogError("You may not set damage mod percent here, use ....Pre forward");
		PrintPluginError(plugin);
	}

	new Float:num=GetNativeCell(1); 
	#if defined DEBUG
	PrintToServer("percent change %f",num);
	#endif
	g_CurDMGModifierPercent*=num;
	
}



public NW3GetDamageType(Handle:plugin,numParams){
	return g_CurDamageType;
}
public NW3GetDamageInflictor(Handle:plugin,numParams){
	return g_CurInflictor;
}
public NW3GetDamageIsBullet(Handle:plugin,numParams){
	return _:(!g_CurDamageIsWarcraft);
}
public NW3ForceDamageIsBullet(Handle:plugin,numParams){
	g_CurDamageIsWarcraft=false;
}
public NW3GetDamageStack(Handle:plugin,numParams){
	return damagestack;
}




public OnClientPutInServer(client){
	SDKHook(client,SDKHook_OnTakeDamage,SDK_Forwarded_OnTakeDamage);
}
public OnClientDisconnect(client){
	SDKUnhook(client,SDKHook_OnTakeDamage,SDK_Forwarded_OnTakeDamage); 
}



public Action:SDK_Forwarded_OnTakeDamage(victim,&attacker,&inflictor,&Float:damage,&damagetype)
{
	
	new String:race[32];
	War3_GetRaceName(War3_GetRace(attacker),race,sizeof(race));
	
	if(IsPlayerAlive(victim)){

		//store old variables on local stack!
	
		new old_DamageType= g_CurDamageType;
		new old_Inflictor= g_CurInflictor;
		new old_IsWarcraftDamage= g_CurDamageIsWarcraft;
		new Float:old_DamageModifierPercent = g_CurDMGModifierPercent;
		new old_IsTrueDamage = g_CurDamageIsTrueDamage;
		
		//set these to global
		g_CurDamageType=damagetype;
		g_CurInflictor=inflictor;
		g_CurDMGModifierPercent=1.0;
		g_CurDamageIsWarcraft=g_NextDamageIsWarcraftDamage;
		g_CurDamageIsTrueDamage=g_NextDamageIsTrueDamage;
		
		
		#if defined DEBUG
		DP2("sdktakedamage %d->%d atrace %s damage [%.2f]",attacker,victim,race,damage);
		#endif
		damagestack++;
		
		if(g_CurDamageIsWarcraft){
			damage=FloatMul(damage,W3GetMagicArmorMulti(victim));
			//PrintToChatAll("magic %f %d to %d",W3GetMagicArmorMulti(victim),attacker,victim);
		}
		else if(!g_CurDamageIsTrueDamage){ //bullet 
			damage=FloatMul(damage,W3GetPhysicalArmorMulti(victim));
			
			//PrintToChatAll("physical %f %d to %d",W3GetPhysicalArmorMulti(victim),attacker,victim);
			//g_CurDamageIsWarcraft=false;
		}
		//else it is true damage
		//PrintToChatAll("takedmg %f BULLET %d   lastiswarcraft %d",damage,isBulletDamage,g_CurDamageIsWarcraft);
		
		new bool:old_CanSetDamageMod=g_CanSetDamageMod;
		new bool:old_CanDealDamage=g_CanDealDamage;
		g_CanSetDamageMod=true;
		g_CanDealDamage=false;
		Call_StartForward(FHOnW3TakeDmgAllPre);
		Call_PushCell(victim);
		Call_PushCell(attacker);
		Call_PushCell(damage);
		Call_Finish(dummyresult); //this will be returned to
		
		if(!g_CurDamageIsWarcraft){
			Call_StartForward(FHOnW3TakeDmgBulletPre);
			Call_PushCell(victim);
			Call_PushCell(attacker);
			Call_PushCell(damage);
			Call_Finish(dummyresult); //this will be returned to
			
		}
		g_CanSetDamageMod=false;
		g_CanDealDamage=true;
		Call_StartForward(FHOnW3TakeDmgAll);
		Call_PushCell(victim);
		Call_PushCell(attacker);
		Call_PushCell(damage);
		Call_Finish(dummyresult); //this will be returned to
		
		
		if(!g_CurDamageIsWarcraft){
			Call_StartForward(FHOnW3TakeDmgBullet);
			Call_PushCell(victim);
			Call_PushCell(attacker);
			Call_PushCell(damage);
			Call_Finish(dummyresult); //this will be returned to
			
		}
		g_CanSetDamageMod=old_CanSetDamageMod;
		g_CanDealDamage=old_CanDealDamage;	
		//modify final damage
		damage=damage*g_CurDMGModifierPercent; ////so we calculate the percent 
	
		//nobobdy retrieves our global variables outside of the forward call, restore old stack vars
		g_CurDamageType= old_DamageType;
		g_CurInflictor= old_Inflictor;
		g_CurDamageIsWarcraft= old_IsWarcraftDamage;
		g_CurDMGModifierPercent = old_DamageModifierPercent;
		g_CurDamageIsTrueDamage = old_IsTrueDamage;
		
		
		
		damagestack--;
		#if defined DEBUG
		
		DP2("sdktakedamage %d->%d END dmg [%.2f]",attacker,victim,damage);
		#endif
	
	}
	
	return Plugin_Changed;
}


public EventPlayerHurt(Handle:event,const String:name[],bool:dontBroadcast)
{
	
	new victim_userid=GetEventInt(event,"userid");
	new attacker_userid=GetEventInt(event,"attacker");
	new damage=GetEventInt(event,"dmg_health");
	if(War3_GetGame()==Game_TF)
		damage=GetEventInt(event,"damageamount");
	
	new victim=GetClientOfUserId(victim_userid);
	
	new attacker=GetClientOfUserId(attacker_userid);
	
	
	
	#if defined DEBUG
	DP2("PlayerHurt %d->%d  dmg [%d] ",attacker,victim,damage);
	#endif
	damagestack++;
	
	new bool:old_CanDealDamage=g_CanDealDamage;
	g_CanSetDamageMod=true;
	
	new Handle:oldevent=W3GetVar(SmEvent);
	W3SetVar(SmEvent,event); //stacking on stack 
	
	//do the forward
	Call_StartForward(g_OnWar3EventPostHurtFH);
	Call_PushCell(victim);
	Call_PushCell(attacker);
	Call_PushCell(damage);
	Call_Finish(dummyresult);
	
	W3SetVar(SmEvent,oldevent); //restore on stack , if any
	g_CanDealDamage=old_CanDealDamage;
	
	
	damagestack--;
	#if defined DEBUG
	
	DP2("PlayerHurt %d->%d  dmg [%d] END ",attacker,victim,damage);
	
	if(	damagestack==0){
	
	PrintToServer("   ");
	PrintToChatAll("   ");
	PrintToServer("   ");
	PrintToChatAll("   ");
	}
	#endif
	
	g_CurLastActualDamageDealt=damage;
}
stock DP2(const String:szMessage[], any:...)
{
	new String:szBuffer[1000];
	new String:pre[132];
	for(new i=0;i<damagestack;i++){
		StrCat(pre,sizeof(pre),"    ");
	}
	VFormat(szBuffer, sizeof(szBuffer), szMessage, 2);
	PrintToServer("[DP2] %s%s %s",pre,szBuffer,W3GetDamageIsBullet()?"B":"",!g_NextDamageIsWarcraftDamage?"NB":"");
	PrintToChatAll("[DP2] %s%s %s", pre, szBuffer,W3GetDamageIsBullet()?"B":"",!g_NextDamageIsWarcraftDamage?"NB":"");
	
}














//dealdamage reaches far into the stack:
/*
[DP2]     playerHurt 1->10  dmg [34]  B
[DP2]     dealdamage 10->1 { 
[DP2]         sdktakedamage 10->1 atrace Night Elf damage [6.00] 
[DP2]         sdktakedamage 10->1 END dmg [6.00] 
[DP2]         PlayerHurt 10->1  dmg [3]  
[DP2]         PlayerHurt 10->1  dmg [3] END  
				^^^^coplies the damage to global
[DP2]     dealdamage 10->1 } B
[*/
public Native_War3_DealDamage(Handle:plugin,numParams)
{
	new bool:whattoreturn=true;
	if(!g_CanDealDamage){
		LogError("War3_DealDamage called when DealDamage is not suppose to be called, please use the non PRE forward");
		W3LogError("War3_DealDamage called when DealDamage is not suppose to be called, please use the non PRE forward");
		PrintPluginError(plugin);
	}
	
		
	decl victim;
	victim=GetNativeCell(1);
	decl damage;
	damage=GetNativeCell(2);
	decl attacker;
	attacker=GetNativeCell(3);
		
	
	if(ValidPlayer(victim,true) && damage>0 )
	{
		//new old_DamageDealt=g_CurActualDamageDealt;
		new old_IsWarcraftDamage= g_CurDamageIsWarcraft;
		new old_IsTrueDamage = g_CurDamageIsTrueDamage;
		
		new old_NextDamageIsWarcraftDamage=g_NextDamageIsWarcraftDamage; 
		new old_NextDamageIsTrueDamage=g_NextDamageIsTrueDamage;
		
		g_CurLastActualDamageDealt=-88;
		
		
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
			g_NextDamageIsWarcraftDamage=false;
		}
		else {
			g_NextDamageIsWarcraftDamage=true;
		}
		g_CurDamageIsWarcraft=g_NextDamageIsWarcraftDamage;
		///sdk immediately follows, we must expose this to posthurt once sdk exists
		//new bool:settobullet=bool:W3GetDamageIsBullet(); //just in case someone dealt damage inside this forward and made it "not bullet"
	 
		
	
		
		decl oldcsarmor;
		if((WAR3_DMGTYPE==W3DMGTYPE_TRUEDMG||WAR3_DMGTYPE==W3DMGTYPE_MAGIC)&&War3_GetGame()==CS){
			oldcsarmor=War3_GetCSArmor(victim);
			War3_SetCSArmor(victim,0) ;
		}
		
		g_NextDamageIsTrueDamage=(WAR3_DMGTYPE==W3DMGTYPE_TRUEDMG);
		g_CurDamageIsTrueDamage=(WAR3_DMGTYPE==W3DMGTYPE_TRUEDMG);
		
		if(damage<1){
			damage=1;
		}
	

		#if defined DEBUG
		DP2("dealdamage %d->%d {",attacker,victim);
		damagestack++;
		#endif
		
		decl String:dmg_str[16];
		IntToString(damage,dmg_str,sizeof(dmg_str));
		decl String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,sizeof(dmg_type_str));
		
		new pointHurt=CreateEntityByName("point_hurt");
		if(pointHurt)
		{
			//	PrintToChatAll("%d %d %d",victim,damage,g_CurActualDamageDealt);
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
			//	PrintToChatAll("%d %d %d",victim,damage,g_CurActualDamageDealt);
		}
		//damage has been dealt BY NOW
		
		if((WAR3_DMGTYPE==W3DMGTYPE_TRUEDMG||WAR3_DMGTYPE==W3DMGTYPE_MAGIC)&&War3_GetGame()==CS){
			War3_SetCSArmor(victim,oldcsarmor);
		}
		
		if(g_CurLastActualDamageDealt==-88){
			g_CurLastActualDamageDealt=0;
			whattoreturn=false;
		}
		
		g_CurDamageIsWarcraft= old_IsWarcraftDamage;
	
		g_CurDamageIsTrueDamage = old_IsTrueDamage;
		
		g_NextDamageIsWarcraftDamage=old_NextDamageIsWarcraftDamage; 
		g_NextDamageIsTrueDamage=old_NextDamageIsTrueDamage;
	}
	else{
		//player is already dead
		whattoreturn=false;
	}
	#if defined DEBUG
	damagestack--;
	DP2("dealdamage %d->%d }",attacker,victim);
	#endif
	
	
	return whattoreturn;
}
public Native_War3_GetWar3DamageDealt(Handle:plugin,numParams) {
	return g_CurLastActualDamageDealt;
}