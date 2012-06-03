/*
File: offsets.inc
Description: Offset definitions.
Author(s): Anthony Iacono  
*/



new Handle:hSpawnPlayer;


public bool:War3Source_InitOffset()
{
	new bool:ret=true;
		
	
	
	new Handle:hGameConf=INVALID_HANDLE;
	if(War3_GetGame()==Game_TF)
		hGameConf=LoadGameConfigFile("sm-tf2.games");
	else if(War3_GetGame()==Game_CS || War3_GetGame()==Game_CSGO)
		hGameConf=LoadGameConfigFile("sm-cstrike.games");
	else if(War3_IsL4DEngine())
		return true; // don't need fancy offsets... yet
	if(hGameConf && War3_GetGame()==Game_TF)
	{
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"ForceRespawn");
		hSpawnPlayer=EndPrepSDKCall();
		CloseHandle(hGameConf);
	}
	else if(hGameConf && (War3_GetGame()==Game_CS || War3_GetGame()==Game_CSGO))
	{
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(hGameConf,SDKConf_Signature,"RoundRespawn");
		hSpawnPlayer=EndPrepSDKCall();
		CloseHandle(hGameConf);
	}
	else
	{
		PrintToServer("[War3Source] Error, could not find configuration file for game.");
		ret=false;
	}
	return ret;
}

public War3Respawn(client)
{
	SDKCall(hSpawnPlayer,client);
}