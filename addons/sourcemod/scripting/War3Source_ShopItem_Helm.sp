#pragma semicolon 1

#include "sdkhooks"
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
    War3_AddSoundFolder(helmSound0, sizeof(helmSound0), "helm/metal_solid_impact_bullet1.mp3");
    War3_AddSoundFolder(helmSound1, sizeof(helmSound1), "helm/metal_solid_impact_bullet2.mp3");
    War3_AddSoundFolder(helmSound2, sizeof(helmSound2), "helm/metal_solid_impact_bullet3.mp3");
    War3_AddSoundFolder(helmSound3, sizeof(helmSound3), "helm/metal_solid_impact_bullet4.mp3");

    War3_AddCustomSound(helmSound0);
    War3_AddCustomSound(helmSound1);
    War3_AddCustomSound(helmSound2);
    War3_AddCustomSound(helmSound3);
    
    LoadTranslations("w3s.item.helm.phrases");
}
public OnWar3LoadRaceOrItemOrdered2(num)
{
    if(num==100){
    
        thisItem = War3_CreateShopItemT("helm", 10, true);
    }    
}
public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_TraceAttack, SDK_Forwarded_TraceAttack);
}
public OnClientDisconnect(client)
{
    SDKUnhook(client, SDKHook_TraceAttack, SDK_Forwarded_TraceAttack); 
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