/**
 * File: War3Source_Addon_LevelUpParticle.sp
 * Description: Displays particles whenever somebody levels up.
 * Author(s): Glider & xDr.HaaaaaaaXx
 */

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
	name = "W3S - Addon - Display Particles on Level Up",
	author = "Glider & xDr.HaaaaaaaXx",
	description = "Displays particles whenever somebody levels up",
	version = "1.2",
};

public OnPluginStart(){
	LoadTranslations("w3s.addon.nospysuicide.phrases");
}
public OnW3Denyable(W3DENY:event, client)
{
	if(event==Suicide && GameTF() && TFClass_Spy==TF2_GetPlayerClass(client)){
		W3Deny();
		War3_ChatMessage(client,"%T","No suiciding on SPY",client);
	}
}
