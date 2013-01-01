#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/sdkhooks"
#include "W3SIncs/War3Source_Interface"

new thisItem;
new String:helmSound0[256]; //="physics/metal/metal_solid_impact_bullet1.wav";
new String:helmSound1[256]; //="physics/metal/metal_solid_impact_bullet2.wav";
new String:helmSound2[256]; //="physics/metal/metal_solid_impact_bullet3.wav";
new String:helmSound3[256]; //="physics/metal/metal_solid_impact_bullet4.wav";

public Plugin:myinfo = 
{
	name = "War3Source - Shopitem - Helm",
	author = "War3Source Team",
	description = "Become immune to headshots"
};

public OnPluginStart()
{
	if(GAMECSGO)
	{
		strcopy(helmSound0,sizeof(helmSound0),"music/war3source/helm/metal_solid_impact_bullet1.mp3");
		strcopy(helmSound1,sizeof(helmSound1),"music/war3source/helm/metal_solid_impact_bullet2.mp3");
		strcopy(helmSound2,sizeof(helmSound2),"music/war3source/helm/metal_solid_impact_bullet3.mp3");
		strcopy(helmSound3,sizeof(helmSound3),"music/war3source/helm/metal_solid_impact_bullet4.mp3");
	}
	else
	{
		strcopy(helmSound0,sizeof(helmSound0),"war3source/helm/metal_solid_impact_bullet1.mp3");
		strcopy(helmSound1,sizeof(helmSound1),"war3source/helm/metal_solid_impact_bullet2.mp3");
		strcopy(helmSound2,sizeof(helmSound2),"war3source/helm/metal_solid_impact_bullet3.mp3");
		strcopy(helmSound3,sizeof(helmSound3),"war3source/helm/metal_solid_impact_bullet4.mp3");
	}


	War3_PrecacheSound(helmSound0);
	War3_PrecacheSound(helmSound1);
	War3_PrecacheSound(helmSound2);
	War3_PrecacheSound(helmSound3);
	
	LoadTranslations("w3s.item.helm.phrases");
}
public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==100){
	
		thisItem=War3_CreateShopItemT("helm",10,3500);
	}	
}
public OnClientPutInServer(client){
	SDKHook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
}
public OnClientDisconnect(client){
	SDKUnhook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack); 
}

public Action:SDK_Forwarded_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(hitgroup==1&&War3_GetOwnsItem(victim,thisItem)&&!Perplexed(victim)){
		damage=0.0;
		new random = GetRandomInt(0,3);
		if(random==0){
			EmitSoundToAll(helmSound0,victim);
		}else if(random==1){
			EmitSoundToAll(helmSound1,victim);
		}else if(random==2){
			EmitSoundToAll(helmSound2,victim);
		}else{
			EmitSoundToAll(helmSound3,victim);
		}
		if(War3_GetGame()==TF){
			decl Float:pos[3];
			GetClientEyePosition(victim, pos);
			pos[2] += 4.0;
			War3_TF_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos
		}
	}
	return Plugin_Changed;
}