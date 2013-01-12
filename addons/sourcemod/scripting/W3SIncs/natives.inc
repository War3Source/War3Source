/*
File: natives.inc
Description: All the natives that keep us from having to make a C++ extension,
I <3 SourceMod :) 
* 
* natives are initiated and defined
* 
* 
* MUST LIST THE NATIE IN THE War3Source_Interface!!!!!!!!!!!!!!!!!!!!!!!!!!! 
* 
Author(s): Anthony Iacono  
*/




public Native_War3_InFreezeTime(Handle:plugin,numParams)
{
    return (bInFreezeTime)?1:0;
}






public Native_W3FlashScreen(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    new color[4];
    GetNativeArray(2,color,4);
    new Float:holdduration=GetNativeCell(3);
    new Float:fadeduration=GetNativeCell(4);
    new flags=GetNativeCell(5);
    if(ValidPlayer(client,false))
    {
        new Handle:hBf=StartMessageOne("Fade",client);
        if(hBf!=INVALID_HANDLE)
        {
            BfWriteShort(hBf,RoundFloat(255.0*fadeduration));
            BfWriteShort(hBf,RoundFloat(255.0*holdduration)); //holdtime
            BfWriteShort(hBf,flags);
            BfWriteByte(hBf,color[0]);
            BfWriteByte(hBf,color[1]);
            BfWriteByte(hBf,color[2]);
            BfWriteByte(hBf,color[3]);
            EndMessage();
        }
    }
}

public Native_War3_ShakeScreen(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    new Float:duration=GetNativeCell(2);
    new Float:magnitude=GetNativeCell(3);
    new Float:noise=GetNativeCell(4);
    if(ValidPlayer(client,false))
    {
        new Handle:hBf=StartMessageOne("Shake",client);
        if(hBf!=INVALID_HANDLE)
        {
            BfWriteByte(hBf,0);
            BfWriteFloat(hBf,magnitude);
            BfWriteFloat(hBf,noise);
            BfWriteFloat(hBf,duration);
            EndMessage();
        }
    }
}




public Native_War3_IsUbered(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (War3_GetGame() == Game_TF)
    {
        //PrintToChatAll("tf game %d vs current %d",Game_TF,War3_GetGame());
        new m_nPlayerCond = FindSendPropInfo("CTFPlayer","m_nPlayerCond") ;
        new cond = GetEntData(client, m_nPlayerCond);
        if(cond & 32)
        {
            return true;
        } 
    }
    return false;
}


public Native_War3_HasFlag(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (War3_GetGame() == Game_TF)
    {
        new ent = -1;
        while ((ent = FindEntityByClassname(ent, "item_teamflag")) != -1)
        {
            if (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity")==client)
                return true;
        }
    }
    return false;
}

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




public Native_War3_IsCloaked(Handle:plugin,numParams)
{

    new client = GetNativeCell(1);
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






public Native_War3_TF_PTC(Handle:plugin,numParams)
{
    
    new client = GetNativeCell(1);
    new String:str[32];
    GetNativeString(2, str, sizeof(str));
    new Float:pos[3];
    GetNativeArray(3,pos,3);
    if(War3_GetGame()==Game_TF){
        return TE_ParticleToClient(client,str,pos);
    }
    return 0;
}
TE_ParticleToClient(client,
String:Name[],
Float:origin[3]=NULL_VECTOR,
Float:start[3]=NULL_VECTOR,
Float:angles[3]=NULL_VECTOR,
entindex=-1,
attachtype=-1,
attachpoint=-1,
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



bool:War3Source_InitNatives()
{
    ///LIST ALL THESE NATIVES IN INTERFACE
    
    CreateNative("War3_InFreezeTime",Native_War3_InFreezeTime);
    
    
    
    CreateNative("W3FlashScreen",Native_W3FlashScreen);
    CreateNative("War3_ShakeScreen",Native_War3_ShakeScreen);



    CreateNative("War3_IsUbered",Native_War3_IsUbered);
    
    //CreateNative("War3_PrecacheSound",Native_War3_PrecacheSound);
    
    CreateNative("War3_IsCloaked",Native_War3_IsUbered);
    
    
    CreateNative("War3_TF_ParticleToClient",Native_War3_TF_PTC);
    
    


    CreateNative("W3GetVar",NW3GetVar);
    CreateNative("W3SetVar",NW3SetVar);
    CreateNative("W3HasDiedThisFrame",NW3HasDiedThisFrame);

    return true;
}




public NW3GetVar(Handle:plugin,numParams){
    return _:W3VarArr[War3Var:GetNativeCell(1)];
}
public NW3SetVar(Handle:plugin,numParams){
    W3VarArr[War3Var:GetNativeCell(1)]=GetNativeCell(2);
}

public GetStatsVersion(){
    //return W3GetStatsVersion();
}

public NW3HasDiedThisFrame(Handle:plugin,numParams){
    new client=GetNativeCell(1);
    return ValidPlayer(client)&&bHasDiedThisFrame[client];
}
