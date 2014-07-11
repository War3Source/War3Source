#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include "W3SIncs/War3Source_Interface"

#include <tf2>
#include <tf2_stocks>

public Plugin:myinfo = 
{
    name = "War3Source - Addon - No Spy Suicide",
    author = "War3Source Team",
    description = "Deny Spy players a unhonorable death"
};

new Handle:nosuicidecvar;
public OnPluginStart(){
    LoadTranslations("w3s.addon.nospysuicide.phrases.txt");
    nosuicidecvar=CreateConVar("war3_no_spy_suicide","1");
}
public OnW3Denyable(W3DENY:event, client)
{
    if(event==DN_Suicide && GameTF() && TFClass_Spy==TF2_GetPlayerClass(client)&&GetConVarInt(nosuicidecvar)){
        W3Deny();
        War3_ChatMessage(client,"%T","No suiciding on SPY",client);
    }
}
