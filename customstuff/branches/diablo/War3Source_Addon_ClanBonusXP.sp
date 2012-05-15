//////////////////////////////////////
// 			CSS   O N L Y          //
//////////////////////////////////////

#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON
#include <sourcemod>
#include "W3SIncs/cssclantags"
#include "W3SIncs/War3Source_Interface"  

new Handle:g_hClanVar = INVALID_HANDLE;
new Handle:g_hGOMultipler = INVALID_HANDLE;
new Handle:g_hXPMultipler = INVALID_HANDLE;
new Handle:g_hVarWelcomeMsg = INVALID_HANDLE;
public Plugin:myinfo= 
{
	name="W3S Addon ClanBonusXP",
	author="Revan. Edited by alex0310",
	description="War3Source Addon Plugin",
	version="1.0.0.1",
};
public LoadCheck(){
	return GameCS();
}
public OnPluginStart()
{
   g_hClanVar = CreateConVar("war3_bonusclan_name","*СМЕРШ*","Player who are wearing this clantag will gain bonus XP");
   g_hXPMultipler = CreateConVar("war3_bonusclan_xprate","1.2","Bonus XP Multipler", 0, true, 1.0);
   g_hGOMultipler = CreateConVar("war3_bonusclan_goldrate","1.0","Bonus Gold Multipler", 0, true, 1.0);
   g_hVarWelcomeMsg = CreateConVar ("war3_bonusclan_welcome", "1.0", "Enable the welcome message", 0, true, 0.0, true, 1.0);
   
   LoadTranslations ("w3s.addon.clanbonusxp.phrases");
}

public OnWar3Event(W3EVENT:event,client)
{
	
	if(event==OnPreGiveXPGold && !IsFakeClient(client))	{
		decl String:buffer[32],String:buffer2[32];
		CS_GetClientClanTag(client,buffer, sizeof(buffer));
		GetConVarString(g_hClanVar,buffer2,sizeof(buffer2));
		if(strlen(buffer)>0 && strlen(buffer2)>0) {
			if(strcmp(buffer, buffer2)==0) {
				W3SetVar(EventArg2,FloatMul(W3GetVar(EventArg2),GetConVarFloat(g_hXPMultipler)));
				W3SetVar(EventArg3,FloatMul(W3GetVar(EventArg3),GetConVarFloat(g_hGOMultipler)));
			}
		}
	}
}
public OnClientPutInServer (client)
{
    if ((client == 0) || !IsClientConnected (client))
        return;

    CreateTimer (30.0, WelcomeAdvertTimer, client);
}
public Action:WelcomeAdvertTimer (Handle:timer, any:client)
{
	decl String:ClientName[MAX_NAME_LENGTH] = "",String:buffer2[32];
	new Float:xprate =(GetConVarFloat(g_hXPMultipler)-1)*100;
	new Float:goldrate =(GetConVarFloat(g_hGOMultipler)-1)*100;
	new String:str_xprate[8],String:str_goldrate[8];
	if (GetConVarInt (g_hVarWelcomeMsg) && IsClientConnected (client) && IsClientInGame (client)) 
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
