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
 * Returns flag carrier
 *
 * @param   team        Team index
 * @return              Client index, -1 if not found
 */
stock GetFlagCarrier(team)
{
    if (War3_GetGame() == Game_TF)
    {
        new ent = -1;
        while ((ent = FindEntityByClassname(ent, "item_teamflag")) != -1)
        {
            new owner = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");
            if (owner > 0)
            {
                if (GetClientTeam(owner) == team)
                    return owner;
            }
        }
    }
    return -1;
}

/**
 * Is player ubered (TF2)
 * @param client:
 * @return: true false
 */
stock bool:War3_IsUbered(client)
{
    if (War3_GetGame() == Game_TF)
    {
        new m_nPlayerCond = FindSendPropInfo("CTFPlayer","m_nPlayerCond") ;
        new cond = GetEntData(client, m_nPlayerCond);
        if(cond & 32)
        {
            return true;
        } 
    }
    return false;
}

/**
 * Is player carrying intellegence
 * @param client:
 * @return: true false
 */
stock bool:War3_HasFlag(client)
{
    return GetFlagCarrier( GetClientTeam(client) ) == client ? true:false;
}

/**
 * Is player cloaked
 * @param client:
 * @return: true false
 */
stock bool:War3_IsCloaked(client)
{
    if (War3_GetGame() == Game_TF)
    {
        new m_nPlayerCond = FindSendPropInfo("CTFPlayer","m_nPlayerCond") ;
        new cond = GetEntData(client, m_nPlayerCond);
        if(cond & 16)
        {
            return true;
        } 
    }
    return false;
}

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

//Sends a particle to client like "miss_text"
stock War3_TF_ParticleToClient( client=0, const String:Name[],
                                Float:origin[3]=NULL_VECTOR,
                                Float:start[3]=NULL_VECTOR,
                                Float:angles[3]=NULL_VECTOR,
                                entindex=-1,attachtype=-1,attachpoint=-1,
                                bool:resetParticles=true,
                                Float:delay=0.0)
{
    // find string table
    new tblidx = FindStringTable("ParticleEffectNames");
    if (tblidx==INVALID_STRING_TABLE) 
    {
        LogError("Could not find string table: ParticleEffectNames");
        return 0;
    }
    
    // find particle index
    new String:tmp[256];
    new count = GetStringTableNumStrings(tblidx);
    new stridx = INVALID_STRING_INDEX;
    new i;
    for (i=0; i<count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if (StrEqual(tmp, Name, false))
        {
            stridx = i;
            break;
        }
    }
    if (stridx==INVALID_STRING_INDEX)
    {
        LogError("Could not find particle: %s", Name);
        return 0;
    }
    
    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", stridx);
    if (entindex!=-1)
    {
        TE_WriteNum("entindex", entindex);
    }
    if (attachtype!=-1)
    {
        TE_WriteNum("m_iAttachType", attachtype);
    }
    if (attachpoint!=-1)
    {
        TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    }
    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0); 
    if(client==0)
    {
        TE_SendToAll(delay);
    }
    else
    {
        TE_SendToClient(client, delay);
    }
    return 0;
}
