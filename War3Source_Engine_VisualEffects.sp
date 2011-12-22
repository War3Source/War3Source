#include <sourcemod>
#include <clientprefs>
#include "W3SIncs/War3Source_Interface"
#define FLAG_NOFX "nofx"

new Handle:g_Effects = INVALID_HANDLE;
new Handle:g_EffectCookie = INVALID_HANDLE
new g_TERaceID = -1;
new bool:bCanSeeFX[MAXPLAYERS];

new bool:bLegacy=false; //legacy mode enables experimental features

public Plugin:myinfo= 
{
	name="W3S Engine Visual Effects",
	author="DonRevan",
	description="Handles War3Source Visual Effects",
	version="1.0",
	url="http://war3source.com/"
};

public OnPluginStart()
{
	g_Effects = CreateConVar("war3_effects","1","0=Prevent War3Source effects 1=Allow client to disable effects(default) 2=Always draw effects regardless of client settings");
	g_EffectCookie = RegClientCookie("war3_effects", "War3Source Visual Effects settings.", CookieAccess_Private);
	//SetCookiePrefabMenu(g_EffectCookie, CookieMenu_YesNo, "Visual Effects", CookieCallback);
	SetCookieMenuItem(Menu_Cookies, 0, "Visual Effects Settings (error: translations missing)");
	RegServerCmd("war3_effects_experimental",Command_ToogleLegacyMode,"Toggles experimental FX features");
	
}

public OnPluginStop()
{
	ToggleLegacyMode(true);
}

public bool:InitNativesForwards()
{
	CreateNative("W3GetEffectRace",Native_ReturnBufferedRaceID);
	CreateNative("W3ClientCanSeeEffect",Native_ClientCanSeeEffect);
	CreateNative("W3CreateEffect",Native_CreateEffect)
	CreateNative("W3SendToClient",Native_SendToClient);
	CreateNative("W3SendToArea",Native_SendByAoE);
	CreateNative("W3SendToTeam",Native_SendByTeam);
	CreateNative("W3SendToAll",Native_SendToAll);
	return true;
}

public Action:Command_ToogleLegacyMode(args) {
	//Hook's every commonly used Temp Entity
	ToggleLegacyMode();
}

ToggleLegacyMode(bool:bAllowUnloadOnly=false) {
	if(bLegacy) {
		RemoveTempEntHook("Sparks",TempEntityCallback);
		RemoveTempEntHook("Smoke",TempEntityCallback);
		RemoveTempEntHook("GlowSprite",TempEntityCallback);
		RemoveTempEntHook("Explosion",TempEntityCallback);
		RemoveTempEntHook("BeamRingPoint",TempEntityCallback);
		RemoveTempEntHook("BeamPoints",TempEntityCallback);
		RemoveTempEntHook("BeamFollow",TempEntityCallback);
		bLegacy=false;
	}
	else if(!bAllowUnloadOnly) {
		AddTempEntHook("Sparks",TempEntityCallback);
		AddTempEntHook("Smoke",TempEntityCallback);
		AddTempEntHook("GlowSprite",TempEntityCallback);
		AddTempEntHook("Explosion",TempEntityCallback);
		AddTempEntHook("BeamRingPoint",TempEntityCallback);
		AddTempEntHook("BeamPoints",TempEntityCallback);
		AddTempEntHook("BeamFollow",TempEntityCallback);
		bLegacy=true;
	}
	PrintToServer("[WAR3] Global FX Handler mode changed to %b",bLegacy);
}

public Menu_Cookies(client, CookieMenuAction:action, any:info, String:buffer[], maxlen) 
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
			Format(buffer, maxlen, "%T", "Visual Effects Settings", client);
		case CookieMenuAction_SelectOption:
			if(GetConVarInt(g_Effects)==1) {
				DisplayFXPreferences(client);
			}
			else {
				War3_ChatMessage(client,"%T","Sorry, but the Server decided to take control of this option",client);
			}		
	}
}

DisplayFXPreferences(client) {
	decl Handle:hMenu, String:sBuffer[128];
	hMenu = CreateMenu(War3Source_Menu_VisualEffects);
	Format(sBuffer, sizeof(sBuffer), "%T", "Choose a option", client);
	SetMenuTitle(hMenu, sBuffer);
	SetMenuPagination(hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(hMenu, true);
	Format(sBuffer, sizeof(sBuffer), "%T", "Enable", client);
	AddMenuItem(hMenu, "1", sBuffer);
	Format(sBuffer, sizeof(sBuffer), "%T", "Disable", client);
	AddMenuItem(hMenu, "0", sBuffer);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public War3Source_Menu_VisualEffects(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			if(param2==MenuCancel_ExitBack) ShowCookieMenu(param1);
		case MenuAction_Select:
		{
			decl String:sBuffer[4];
			GetMenuItem(menu, param2, sBuffer, sizeof(sBuffer));
			if(StringToInt(sBuffer)==0) {
				bCanSeeFX[param1]=true;
				War3_ChatMessage(param1,"%T","Effects are now enabled!",param1);
			}
			else {
				bCanSeeFX[param1]=false;
				War3_ChatMessage(param1,"%T","Effects are now disabled!",param1);
			}
			DisplayFXPreferences(param1);
		}
	}
}

public Action:TempEntityCallback(const String:te_name[],const clients[],client_count,Float:delay) {
	if(GetConVarInt(g_Effects)==-1 && W3RaceCanDrawFX(g_TERaceID))
		return Plugin_Stop;
	return Plugin_Continue;
}

public OnClientCookiesCached(client) {
	decl String:cookie[4];
	GetClientCookie(client, g_EffectCookie, cookie, sizeof(cookie)); 
	if(StringToInt(cookie)==0) {//if non-zero
		//So there are some sort of no fx shades
		bCanSeeFX[client]=false;
	}
	else {//if zero
		//If zero client actually CAN see fx
		bCanSeeFX[client]=true;
	}
	PrintToConsole(client,"[WAR3] FX Mode: %b",bCanSeeFX[client]);
}

public _:Native_ClientCanSeeEffect(Handle:plugin,numParams) {
	return HasEffectsEnabled(GetNativeCell(1));
}

public Native_ReturnBufferedRaceID(Handle:plugin,numParams) {
	return g_TERaceID;
}

public _:Native_CreateEffect(Handle:plugin,numParams) {
	if(GetConVarInt(g_Effects)>0) {
		new String:testr[128],raceid;
		GetNativeString(1,testr,sizeof(testr));
		raceid = GetNativeCell(2);
		if(strlen(testr)>0) {
			if(W3RaceCanDrawFX(raceid)) {
				g_TERaceID = raceid;
				TE_Start(testr);
				return true;
			}
		}
		else {
			return ThrowNativeError(SP_ERROR_NATIVE,"Invalid TE name");
		}		
	}
	return false;
}

public Native_SendToClient(Handle:plugin,numParams){
	if(GetConVarInt(g_Effects)>0) {
		decl Float:delay,client;
		client = GetNativeCell(1);
		delay = GetNativeCell(2);
		if(ValidPlayer(client,false) && HasEffectsEnabled(client)) {
			TE_SendToClient(client,delay);
			g_TERaceID = -1;
		}
		else {
			return ThrowNativeError(SP_ERROR_NATIVE,"Invalid Client");
		}
	}
	return 1;
}

public Native_SendToAll(Handle:plugin,numParams){
	if(GetConVarInt(g_Effects)>0) {
		decl bool:aliveOnly,Float:delay;
		aliveOnly = GetNativeCell(1);
		delay = GetNativeCell(2);
		new total = 0;
		new clients[MaxClients];
		for (new i=1; i<=MaxClients; i++)
		{
			if (ValidPlayer(i,aliveOnly) && HasEffectsEnabled(i))
			{
				clients[total++] = i;
			}
		}
		TE_Send(clients, total, delay);
		g_TERaceID = -1;
	}
	return 1;
}

public Native_SendByAoE(Handle:plugin,numParams){
	if(GetConVarInt(g_Effects)>0) {
		decl Float:fPos[3],Float:distance,Float:delay,total,clients[MaxClients],bool:aliveOnly;
		GetNativeArray(1, fPos, sizeof(fPos)); 
		distance = GetNativeCell(2);
		aliveOnly = GetNativeCell(3);
		delay = GetNativeCell(4);	
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,aliveOnly) && HasEffectsEnabled(i))
			{
				decl Float:VictimPos[3];
				GetClientAbsOrigin(i,VictimPos);
				if(GetVectorDistance(fPos,VictimPos)<=distance)
				{
					clients[total++] = i;
				}
			}
		}
		TE_Send(clients, total, delay);
		g_TERaceID = -1;
	}
	return 1;
}

public Native_SendByTeam(Handle:plugin,numParams){
	if(GetConVarInt(g_Effects)>0) {
		decl Float:delay,iTeam,total,clients[MaxClients],bool:aliveOnly;
		iTeam = GetNativeCell(1);
		aliveOnly = GetNativeCell(2);
		delay = GetNativeCell(3);
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,aliveOnly))
			{
				if(HasEffectsEnabled(i) && GetClientTeam(i)==iTeam) {
					clients[total++] = i;
				}
			}
		}
		TE_Send(clients, total, delay);
		g_TERaceID = -1;
	}
	return 1;
}

public _:Native_RaceCanDrawFX(Handle:plugin,numParams){
	return W3RaceCanDrawFX(GetNativeCell(1));
}

stock bool:W3RaceCanDrawFX(raceid) {
	if(W3RaceHasFlag(raceid,FLAG_NOFX))
		return false;
	return true;
}

stock bool:HasEffectsEnabled(client) {
	//If client have enabled effects or the server decided to take control of them
	if(GetConVarInt(g_Effects)==0 || bCanSeeFX[client]==true)
		return false;
	return true;
}