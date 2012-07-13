//////////////////////////////////////
// 			CSS   O N L Y          //
//////////////////////////////////////

#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON
#include <sourcemod>
#undef REQUIRE_EXTENSIONS
#include "W3SIncs/steamtools"
#define REQUIRE_EXTENSIONS
#include "W3SIncs/cssclantags"
#include "W3SIncs/War3Source_Interface"

new Handle:g_hClanVar = INVALID_HANDLE;
new Handle:g_hClanID = INVALID_HANDLE;
new Handle:g_hGOMultipler = INVALID_HANDLE;
new Handle:g_hXPMultipler = INVALID_HANDLE;
new Handle:g_hVarWelcomeMsg = INVALID_HANDLE;

// Macro by GoD-Tony
#define HAS_STEAMTOOLS()	(GetFeatureStatus(FeatureType_Native, "RequestGroupStatus") == FeatureStatus_Available)
new bool:g_bSteamTools = false;
new bool:bIsInGroup[MAXPLAYERSCUSTOM] = false;

public Plugin:myinfo= 
{
	name="W3S Addon ClanBonusXP",
	author="Revan. Edited by alex0310",
	description="War3Source Addon Plugin",
	version="1.1.0.0",
};
public LoadCheck(){
	// Allow loading if either steamtools has been loaded or we're running CS:S
	return (GAMECS || HAS_STEAMTOOLS());
}
public OnPluginStart()
{
	if(HAS_STEAMTOOLS()) {
		// Revan: I'm using seperate convar names because theese are also separate values and generic clantags might be prefered
		g_hClanID = CreateConVar("war3_bonusclan_id","0","If GroupID is non-zero the plugin will use steamtools to identify clan players(Overrides 'war3_bonusclan_name')");
	}
	g_hClanVar = CreateConVar("war3_bonusclan_name","","Player who are wearing this clantag will gain bonus XP");
	g_hXPMultipler = CreateConVar("war3_bonusclan_xprate","1.2","Bonus XP Multipler", 0, true, 1.0);
	g_hGOMultipler = CreateConVar("war3_bonusclan_goldrate","1.0","Bonus Gold Multipler", 0, true, 1.0);
	g_hVarWelcomeMsg = CreateConVar ("war3_bonusclan_welcome", "1.0", "Enable the welcome message", 0, true, 0.0, true, 1.0);

	LoadTranslations ("w3s.addon.clanbonusxp.phrases");
}

public OnWar3Event(W3EVENT:event,client)
{
	if(event==OnPreGiveXPGold && !IsFakeClient(client)) {
		new bool:bAwardBonus = false;
		if(check_steamtools()) {
			bAwardBonus = bIsInGroup[client];
		}
		else if(GAMECS && !bAwardBonus) {
			decl String:buffer[32],String:buffer2[32];
			CS_GetClientClanTag(client,buffer, sizeof(buffer));
			GetConVarString(g_hClanVar,buffer2,sizeof(buffer2));
			if(strlen(buffer)>0 && strlen(buffer2)>0) {
				if(strcmp(buffer, buffer2)==0) {
					bAwardBonus = true;
				}
			}
		}
		if( bAwardBonus ) {
			// Award dat bonus
			W3SetVar(EventArg2,FloatMul(W3GetVar(EventArg2),GetConVarFloat(g_hXPMultipler)));
			W3SetVar(EventArg3,FloatMul(W3GetVar(EventArg3),GetConVarFloat(g_hGOMultipler)));
		}
	}
}

public OnClientAuthorized(client, const String:auth[])
{
	if (!IsFakeClient(client))
	{
		if(check_steamtools()) {
			new iGroupID = GetConVarInt(g_hClanID);
			if(iGroupID != 0) {
				Steam_RequestGroupStatus(client, iGroupID);
			}
		}
	}
}

public OnClientPutInServer (client)
{
	if ((client == 0) || !IsClientConnected (client))
	return;

	if(GetConVarBool (g_hVarWelcomeMsg)) {
		CreateTimer (30.0, WelcomeAdvertTimer, client);
	}
	// reset cached group status
	bIsInGroup[client] = false;
}

public Action:WelcomeAdvertTimer (Handle:timer, any:client)
{
	decl String:ClientName[MAX_NAME_LENGTH] = "",String:buffer2[32];
	new Float:xprate =(GetConVarFloat(g_hXPMultipler)-1)*100;
	new Float:goldrate =(GetConVarFloat(g_hGOMultipler)-1)*100;
	new String:str_xprate[8],String:str_goldrate[8];
	if (!CvarEmpty(g_hClanVar) && ValidPlayer(client)) 
	{
		GetClientName (client, ClientName, sizeof (ClientName));
		GetConVarString(g_hClanVar,buffer2,sizeof(buffer2));
		FloatToCutString(xprate, str_xprate, sizeof(str_xprate),0);
		FloatToCutString(goldrate, str_goldrate, sizeof(str_goldrate),0);
		
		Format(ClientName, sizeof(ClientName), "\x01\x03%s\x01", ClientName);
		Format(buffer2, sizeof(buffer2), "\x01\x04%s\x01", buffer2);
		Format(str_xprate,sizeof(str_xprate),"\x01\x04%s\x01",str_xprate);
		Format(str_goldrate,sizeof(str_goldrate),"\x01\x04%s\x01",str_goldrate);
		PrintToChat (client, "\x01\x04[War3Source]\x01 %T", "Welcome",client,ClientName,buffer2);
		if (xprate!=0 && goldrate!=0){
			PrintToChat (client, "\x01\x04[War3Source]\x01 %T", "Welcome_XP_GO",client,str_xprate,str_goldrate);
		}
		if (xprate!=0 && goldrate==0){
			PrintToChat (client, "\x01\x04[War3Source]\x01 %T", "Welcome_XP",client,str_xprate);
		}
		if (xprate==0 && goldrate!=0){
			PrintToChat (client, "\x01\x04[War3Source]\x01 %T", "Welcome_GO",client,str_goldrate);
		}
		if (xprate==0 && goldrate==0){
			PrintToChat (client, "\x01\x04[War3Source]\x01 %T", "Welcome_No_Bonus",client);
		}
	}

	return Plugin_Stop;
}

/* SteamTools */


public Steam_FullyLoaded()
{
	g_bSteamTools = true;
}

public Steam_Shutdown()
{
	g_bSteamTools = false;
}

public Steam_GroupStatusResult(client, groupID, bool:bIsMember, bool:bIsOfficer)
{
	if(groupID == GetConVarInt(g_hClanID)) {
		bIsInGroup[client] = bIsMember;
	}
}

// Checks if steamtools is currently running properly
stock bool:check_steamtools()
{
	if(HAS_STEAMTOOLS()) {
		if(!g_bSteamTools) {
			LogError("SteamTools was detected but not properly loaded");
			return false;
		}
		return true;
	}
	return false;
}