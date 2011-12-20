#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"  
//#include "W3SIncs/War3Source_Effects"

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

new SKILL_GENERIC,SKILL_EVADE,SKILL_SWIFT,SKILL_SPEED,ULTIMATE;
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
		SKILL_EVADE=War3_UseGenericSkill(thisRaceID,"g_evasion",evasiondata,"Evasion","RD Evasion Skill Desc");
		
		SKILL_SWIFT=War3_AddRaceSkill(thisRaceID,"Swiftness","");
		SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Speed","");
		ULTIMATE=War3_AddRaceSkill(thisRaceID,"Sonic Rainboom","",true); 
		War3_CreateRaceEnd(thisRaceID); ///DO NOT FORGET THE END!!!
	}
}

public OnPluginStart()
{
	CreateTimer(1.0,CalcWards,_,TIMER_REPEAT);
	
}

public OnMapStart()
{

}
public Action:CalcWards(Handle:t){
	for(new i=1;i<66;i++){
		if(ValidPlayer(i)&&!IsFakeClient(i)){

		//DP("tick");
		//static data;
		//DP("level %d data %d",W3_GenericSkillLevel(i,SKILL_GENERIC,data),data);
		//DP("data %d",data);
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
