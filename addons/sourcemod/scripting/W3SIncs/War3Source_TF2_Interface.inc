/**
 * File: War3Source_TF2_Interface.inc
 * Description: Functions and stuff to make TF2 specific races and whatnot
 * Author(s): War3Source Team  
 */

stock bool:Spying(client) {
	return GameTF()&&( TF2_IsPlayerInCondition(client,TFCond_Disguising)||TF2_IsPlayerInCondition(client,TFCond_Disguised) || TF2_IsPlayerInCondition(client,TFCond_Cloaked));
}
//team 2 3 swapped if spying
stock GetApparentTeam(client) {
	new team = GetClientTeam(client);
	if (Spying(client)) {
		if (team == 2)
			team++;
		else if (team == 3)
			team--;
	}
	return team;
}

/**
 * Is player ubered (TF2)
 * @param client:
 * @return: true false
 */

native bool:War3_IsUbered(client);

/**
 * Is player carrying intellegence
 * @param client:
 * @return: true false
 */
native bool:War3_HasFlag(client);

/**
 * Is player cloaked
 * @param client:
 * @return: true false
 */

native bool:War3_IsCloaked(client);

/**
 * Stock, checks if a player is near an engineer building.
 * @param client: Client's index.
 * @param distance: Optional, how far is "near."
 * @return ADT array of results, otherwise INVALID_HANDLE
 * DO NOT FORGET TO CloseHandle() the results if they don't equal INVALID_HANDLE!!! 
 */
stock Handle:War3_NearBuilding(client,Float:distance=150.0)
{
	if(War3_GetGame()==Game_TF)
	{
		new Handle:hEnts=CreateDataPack();
		WritePackString(hEnts,"obj_dispenser");
		WritePackString(hEnts,"obj_sentrygun");
		WritePackString(hEnts,"obj_teleporter_entrance");
		WritePackString(hEnts,"obj_teleporter_exit");
		new Handle:result=War3_NearEntsByName(client,hEnts,4,distance);
		CloseHandle(hEnts);
		return result;
	}
	return INVALID_HANDLE;
}

stock Float:TF2_GetUberLevel(client)
{
	if (TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		new index = GetPlayerWeaponSlot(client, 1);
		if (index > 0)
		{
			return GetEntPropFloat(index, Prop_Send, "m_flChargeLevel");
		}
		else
		{
			return 0.0;
		}
	}
	else {
		return fUberCharge[client];
	}
}

stock TF2_SetUberLevel(client, Float:uberlevel)
{
	if (TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		new index = GetPlayerWeaponSlot(client, 1);
		if (index > 0)
		{
			SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel);
		}
	}
	else {
		fUberCharge[client] = uberlevel;
	}
}