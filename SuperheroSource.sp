/*
* File: War3Source.sp
* Description: The main file for War3Source.
* Author(s): Anthony Iacono  & OwnageOwnz (DarkEnergy)
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>



#define VERSION_NUM "0.2.1"
#define REVISION_NUM 10001 //increment every release


#define AUTHORS "PimpinJuice and Ownz (DarkEnergy)" 

//variables needed by includes here



//use ur own natives and stocks
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo= 
{
	name="SuperHero Source",
	author=AUTHORS,
	description="Brings the superhero gamemode to the Source engine.",
	version=VERSION_NUM,
	url="http://war3source.com/"
};

new Handle:hChangeGameDescCvar;



public APLRes:AskPluginLoad2(Handle:myself,bool:late,String:error[],err_max)
{

	new String:version[64];
	Format(version,sizeof(version),"%s by %s",VERSION_NUM,AUTHORS);
	
	CreateConVar("a_sh_version",version,"War3Source version.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
}

public OnPluginStart()
{
    hChangeGameDescCvar=CreateConVar("war3_game_desc","1","change game description to war3source? does not affect player connect");
	
}

public Action:OnGetGameDescription(String:gameDesc[64])
{
	if(SH()&&GetConVarInt(hChangeGameDescCvar)>0){
		Format(gameDesc,sizeof(gameDesc),"SHSource %s",VERSION_NUM);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
public OnMapStart(){
	if(SH()){
		DelayedSHCfgExecute();
	}
}

public DelayedSHCfgExecute()
{
	if(FileExists("cfg/superhero.cfg"))
	{
		ServerCommand("exec superhero.cfg");
		PrintToServer("[War3Source] Executed superhero.cfg");
	}
}
