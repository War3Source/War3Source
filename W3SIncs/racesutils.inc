/**
* File: races.inc
* Description: The root of all race specific stuff.
* Author(s): Anthony Iacono  
*/



///check race limit and force re-choose race
CheckRaceTeamLimit(raceid,team){
	new Float:youngest=-1.0;
	new target=0;
	for(new i=1;i<=MaxClients;i++){
	    if(ValidPlayer(i))
		{
			if(War3_GetRace(i)==raceid&&!W3IsDeveloper(i))
			{
				if(GetClientTeam(i)==team)
				{
					if(W3GetPlayerProp(i,LastChangeTeamTime)>youngest){
						target=i;
						youngest=W3GetPlayerProp(i,LastChangeTeamTime);
					}
				}
			}
		}
	}
	if(target>0){
		War3_SetRace(target,0);
		new String:racename[64];
		War3_GetRaceName(raceid,racename,sizeof(racename));
		War3_ChatMessage(target,"%T","{race} race team limit has reached (MAX {amount}), please select a different race",target,racename,W3GetRaceMaxLimitTeam(raceid,team));
		
		new cvar=W3GetRaceMaxLimitTeamCvar(raceid,team);
		new String:cvarstr[64];
		if(cvar>-1){
			W3GetCvarActualString(cvar,cvarstr,sizeof(cvarstr));
		}
		cvar=W3FindCvar(cvarstr);
		new String:cvarvalue[64];
		if(cvar>-1){
			W3GetCvar(cvar,cvarvalue,sizeof(cvarvalue));
		}
		
		
		W3Log("race %s blocked on client %d due to restrictions limit %d (CheckRaceTeamLimit)  %s %s",racename,target,W3GetRaceMaxLimitTeam(raceid,team),cvarstr,cvarvalue);
		W3CreateEvent(DoShowChangeRaceMenu,target);
	}
	
}

/*
HasRaceAccess(client,Handle:hRace)
{
	new String:flag_str[8];
	new Handle:cvarCheck=GetArrayCell(hRace,14);
	GetConVarString(cvarCheck,flag_str,8);
	new first_char=_:flag_str[0];
	if(StrEqual(flag_str,"0",false) || first_char<(_:'a') || first_char>(_:'z'))
		return true; // no valid cvar value, give them access
	new AdminFlag:flag_check;
	if(!FindFlagByChar(first_char,flag_check))
		return true; // bad flag provided
	new AdminId:admin = GetUserAdmin(client);
	if((admin!=INVALID_ADMIN_ID)&&(GetAdminFlag(admin,flag_check,Access_Effective)==true))
		return true; // user has flag
		
	
	
	return IsDeveloper(client); // must not have proper flag if it got all the way down here.
}
*/


