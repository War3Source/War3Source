#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"  
//#include "W3SIncs/War3Source_Effects"

/*
public APLRes:AskPluginLoad2Custom(Handle:plugin,bool:late,String:error[],err_max)
{
	if(!GameTF())
		return APLRes_SilentFailure;
	return APLRes_Success;
}
*/
new thisRaceID;
public Plugin:myinfo = 
{
	name = "Race - Rainbow Dash",
	author = "OWNAGE",
	description = "",
	version = "1.0",
	url = "http://ownageclan.com/"
};
new Float:EvadeChance[5]={0.0,0.05,0.10,0.15,0.20};
new Float:attackspeed[5]={1.0,1.04,1.08,1.12,1.15};
new Float:abilityspeed[5]={1.0,1.15,1.23,1.32,1.40};

new Float:LastDamageTime[MAXPLAYERSCUSTOM];

new SKILL_GENERIC,SKILL_EVADE,SKILL_SWIFT,SKILL_SPEED,ULTIMATE;

new Float:rainboomradius[5]={0.0,200.0,266.0,333.0,400.0};
public OnWar3LoadRaceOrItemOrdered(num)
{	
	if(num==1)
	{
		SKILL_GENERIC=War3_CreateGenericSkill("g_evasion");
		//DP("registereing gernicsadlfjasf");
	}
	if(num==230)
	{
		thisRaceID=War3_CreateNewRace("[MLP:FIM] Rainbow Dash","rainbowdash");
		
		new Handle:evasiondata=CreateArray(5,1);
		SetArrayArray(evasiondata,0,EvadeChance,sizeof(EvadeChance));
		SKILL_EVADE=War3_UseGenericSkill(thisRaceID,"g_evasion",evasiondata,"Evasion","20% evasion.");
		
		SKILL_SWIFT=War3_AddRaceSkill(thisRaceID,"Swiftness","+ 15% Attack Speed");
		SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Speed","(ability) +40% speed for 6 seconds.\nMust not be injured in the last 10 seconds.\nEnds if injured.");
		ULTIMATE=War3_AddRaceSkill(thisRaceID,"Sonic Rainboom","Buff teammates' damage around you for 4 sec, 200-400 units. Must be in speed (ability) mode to cast.",true); 
		War3_CreateRaceEnd(thisRaceID); ///DO NOT FORGET THE END!!!
	}
}
public FOO(){
	SKILL_EVADE=SKILL_EVADE+0;
}
public OnPluginStart()
{
	CreateTimer(1.0,CalcWards,_,TIMER_REPEAT);
	
}

new HaloSprite,XBeamSprite;
public OnMapStart()
{
	HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );   
	XBeamSprite = PrecacheModel( "materials/sprites/lgtning.vmt" );
}
public Action:CalcWards(Handle:t){
	for(new i=1;i<66;i++){
		if(ValidPlayer(i)&&!IsFakeClient(i)){
				
//TF2_AddCondition(i,TFCond_SpeedBuffAlly,1.3);
//TF2_AddCondition(i,TFCond_Buffed,1.3);
	

//TF2_AddCondition(i,TFCond_Charging,1.3);
	
		//DP("tick");
		//static data;
		//DP("level %d data %d",W3_GenericSkillLevel(i,SKILL_GENERIC,data),data);
		//DP("data %d",data);
		}
	}
}

///look attack speed
public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	if(race==thisRaceID&&skill==SKILL_SWIFT)
	{
		War3_SetBuff(client,fAttackSpeed,thisRaceID,attackspeed[newskilllevel]);
	}
}

new bool:inSpeed[MAXPLAYERSCUSTOM];
new Handle:speedendtimer[MAXPLAYERSCUSTOM];
////speed ability
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client,true)&& pressed && IsPlayerAlive(client))
	{
		
			new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
			if(skill_level>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_SPEED)){
					inSpeed[client]=true;
					if(GameTF()){
						TF2_AddCondition(client,TFCond_SpeedBuffAlly,6.0);
						War3_SetBuff(client,fMaxSpeed,thisRaceID,abilityspeed[skill_level]);
						War3_SetBuff(client,fSlow,thisRaceID,0.740740741); //slow down by the factor of the SpeedBuffAlly (1.35)
					}
					else{
						War3_SetBuff(client,fMaxSpeed,thisRaceID,abilityspeed[skill_level]);
					}
					speedendtimer[client]=CreateTimer(6.0,EndSpeed,client);
					War3_CooldownMGR(client,20.0,thisRaceID,SKILL_SPEED,_,_);
				}
			}

	}
}
public Action:EndSpeed(Handle:t,any:client){
	if(GameTF()){
		//DP("end");
		TF2_RemoveCondition(client,TFCond_SpeedBuffAlly);
	}
	War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	War3_SetBuff(client,fSlow,thisRaceID,1.0);
	speedendtimer[client]=INVALID_HANDLE;
	inSpeed[client]=false;
}
public OnWar3EventDeath(client){
	if(speedendtimer[client]!=INVALID_HANDLE){
		TriggerTimer(speedendtimer[client]);
	}
}
public OnWar3EventPostHurt(victim,attacker,damage){
	LastDamageTime[victim]=GetEngineTime();
	if(speedendtimer[victim]!=INVALID_HANDLE){
		TriggerTimer(speedendtimer[victim]);
	}
	else if(War3_GetRace(victim)==thisRaceID){
		War3_CooldownMGR(victim,10.0,thisRaceID,SKILL_SPEED,_,_);
	}
}


public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		
		new skill=War3_GetSkillLevel(client,race,ULTIMATE);
		if(skill>0)
		{
			if(SkillAvailable(client,thisRaceID,ULTIMATE))
			{
				if(!inSpeed[client]){
					PrintHintText(client,"You must be in speed mode (ability)");
				}
				else{
					//TriggerTimer(speedendtimer[client]);
					War3_CooldownMGR(client,20.0,thisRaceID,ULTIMATE,_,_);
					
					decl Float:start_pos[3];
					GetClientAbsOrigin(client,start_pos);
					
					//TE_SetupBeamRingPoint(const Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life, Float:Width, Float:Amplitude, const Color[4], Speed, Flags)
					TE_SetupBeamRingPoint(start_pos,                 20.0,            rainboomradius[skill]*2,			 XBeamSprite, HaloSprite,	 0, 		1, 				0.5, 	30.0, 		0.0, 			{255,0,0,255}, 10, 	0);
					TE_SendToAll(0.0);
					TE_SetupBeamRingPoint(start_pos,                 20.0,            rainboomradius[skill]*2,			 XBeamSprite, HaloSprite,	 0, 		1, 				0.5, 	30.0, 		0.0, 			{255, 127, 0,255}, 10, 	0);
					TE_SendToAll(0.05);
					TE_SetupBeamRingPoint(start_pos,                 20.0,            rainboomradius[skill]*2,			 XBeamSprite, HaloSprite,	 0, 		1, 				0.5, 	30.0, 		0.0, 			{255, 255, 0,255}, 10, 	0);
					TE_SendToAll(0.09);
					TE_SetupBeamRingPoint(start_pos,                 20.0,            rainboomradius[skill]*2,			 XBeamSprite, HaloSprite,	 0, 		1, 				0.5, 	30.0, 		0.0, 			{0, 255, 0,255}, 10, 	0);
					TE_SendToAll(0.11);
					TE_SetupBeamRingPoint(start_pos,                 20.0,            rainboomradius[skill]*2,			 XBeamSprite, HaloSprite,	 0, 		1, 				0.5, 	30.0, 		0.0, 			{0, 127, 255,255}, 10, 	0);
					TE_SendToAll(0.13);
					TE_SetupBeamRingPoint(start_pos,                 20.0,            rainboomradius[skill]*2,			 XBeamSprite, HaloSprite,	 0, 		1, 				0.5, 	30.0, 		0.0, 			{0,0,255,255}, 10, 	0);
					TE_SendToAll(0.15);
					TE_SetupBeamRingPoint(start_pos,                 20.0,            rainboomradius[skill]*2,			 XBeamSprite, HaloSprite,	 0, 		1, 				0.5, 	30.0, 		0.0, 			{143, 0, 255,255}, 10, 	0);
					TE_SendToAll(0.17);
					//DP("%f %f",rainboomradius[skill],rainboomradius[skill]*2);
				
					decl Float:TargetPos[3];
					for (new i = 1; i <= MaxClients; i++) {
						if(ValidPlayer(i,true) && GetClientTeam(i) == GetClientTeam(client)&&GetClientTeam(client) == GetApparentTeam(i)) {
							
							GetClientAbsOrigin(i, TargetPos);
							if (GetVectorDistance(start_pos, TargetPos) <= rainboomradius[skill]) {
								TF2_AddCondition(i,TFCond_Buffed,4.0);
								War3_ShakeScreen(i,0.5,100.0,80.0);
							}
						}
					}
				}
			}
			
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}

















public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim)&&ValidPlayer(attacker)&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
				new Handle:data;
				new Float:chances[5];
				
				new level=W3_GenericSkillLevel(victim,SKILL_GENERIC,data);
				GetArrayArray(data,	0,chances);
				if(data!=INVALID_HANDLE&& level>0 &&!Hexed(victim,false) && W3Chance(chances[level]) && !W3HasImmunity(attacker,Immunity_Skills))
				{
					
					W3FlashScreen(victim,RGBA_COLOR_BLUE);
					
					War3_DamageModPercent(0.0); //NO DAMAMGE
					
					W3MsgEvaded(victim,attacker);
					if(War3_GetGame()==Game_TF){
						decl Float:pos[3];
						GetClientEyePosition(victim, pos);
						pos[2] += 4.0;
						War3_TF_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos
					}	
				}
			
		}
	}
}
