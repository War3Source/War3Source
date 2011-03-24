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




public NW3GetW3Revision(Handle:plugin,numParams){
	return REVISION_NUM;
}
public NW3GetW3Version(Handle:plugin,numParams){	
	SetNativeString(1,VERSION_NUM,GetNativeCell(2));
}
public Native_War3_InFreezeTime(Handle:plugin,numParams)
{
	return (bInFreezeTime)?1:0;
}






public Native_W3ChanceModifier(Handle:plugin,numParams)
{
	if(numParams!=1)
		return _:1.0;
	new attacker=GetNativeCell(1);
	new inflictor=W3GetDamageInflictor();
	new damagetype=W3GetDamageType();
	if(attacker<=0 || attacker>MaxClients || !IsValidEdict(attacker))
		return _:1.0;
	if(damagetype&DMG_BURN)
	{
		return _:GetConVarFloat(ChanceModifierBurn);
	}
	if(damagetype&DMG_PLASMA)
	{
		return _:GetConVarFloat(ChanceModifierPlasma);
	}
	if(attacker!=inflictor)
	{
		if(inflictor>0 && IsValidEdict(inflictor))
		{
			new String:ent_name[64];
			GetEdictClassname(inflictor,ent_name,sizeof(ent_name));
			if(StrContains(ent_name,"obj_sentrygun",false)==0)
			{
				return _:GetConVarFloat(ChanceModifierSentry);
			}
			else if(StrContains(ent_name,"tf_projectile_sentryrocket",false)==0)
			{
				return _:GetConVarFloat(ChanceModifierSentryRocket);
			}
		}
	}
	new String:weapon[64];
	GetClientWeapon(attacker,weapon,sizeof(weapon));
	if(StrEqual(weapon,"tf_weapon_minigun",false))
	{
		return _:GetConVarFloat(ChanceModifierHeavy);
	}
	if(StrEqual(weapon,"tf_weapon_syringegun_medic",false))
	{
		return _:GetConVarFloat(ChanceModifierMedic);
	}
	if(StrEqual(weapon,"tf_weapon_smg",false))
	{
		return _:GetConVarFloat(ChanceModifierSMGSniper);
	}
	return _:1.0;
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

public Native_War3_SpawnPlayer(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new ignore_check=GetNativeCell(2);
	if(ValidPlayer(client,false) && (ignore_check!=0 || !IsPlayerAlive(client)))
	{
		War3Respawn(client);
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


public Native_War3_HTMHP(Handle:plugin,numParams)
{
	new client = GetNativeCell(1);
	new addhp = GetNativeCell(2);
	new maxhp=War3_GetMaxHP(client);
	new currenthp=GetClientHealth(client);
	if(currenthp<maxhp){ ///do not make hp lower
		new newhp=GetClientHealth(client)+addhp;
		if (newhp>maxhp){
			newhp=maxhp;
		}
		Entity_SetHealth(client,newhp);
	}
	return 0;
}
public Native_War3_HTBHP(Handle:plugin,numParams)
{
	new client = GetNativeCell(1);
	new addhp = GetNativeCell(2);
	new maxhp=(War3_GetGame()==Game_TF)?RoundFloat(float(War3_GetMaxHP(client))*1.5):War3_GetMaxHP(client);
	new currenthp=GetClientHealth(client);
	if(currenthp<maxhp){ ///do not make hp lower
		new newhp=GetClientHealth(client)+addhp;
		if (newhp>maxhp){
			newhp=maxhp;
		}
		Entity_SetHealth(client,newhp);
	}
}

public Native_War3_DecreaseHP(Handle:plugin,numParams)
{
	new client = GetNativeCell(1);
	new dechp = GetNativeCell(2);
	new newhp=GetClientHealth(client)-dechp;
	if(newhp<1){
		newhp=1;
	}
	Entity_SetHealth(client,newhp);
}





public bool:War3Source_InitNatives()
{
	///LIST ALL THESE NATIVES IN INTERFACE
	
	CreateNative("W3GetW3Version",NW3GetW3Version);
	CreateNative("W3GetW3Revision",NW3GetW3Revision);
	
	CreateNative("War3_InFreezeTime",Native_War3_InFreezeTime);
	
	
	CreateNative("W3ChanceModifier",Native_W3ChanceModifier);

	CreateNative("W3FlashScreen",Native_W3FlashScreen);
	CreateNative("War3_ShakeScreen",Native_War3_ShakeScreen);

	CreateNative("War3_SpawnPlayer",Native_War3_SpawnPlayer);


	CreateNative("War3_IsUbered",Native_War3_IsUbered);
	
	//CreateNative("War3_PrecacheSound",Native_War3_PrecacheSound);
	
	CreateNative("War3_IsCloaked",Native_War3_IsUbered);
	
	
	CreateNative("War3_TF_ParticleToClient",Native_War3_TF_PTC);
	
	
	CreateNative("War3_HealToMaxHP",Native_War3_HTMHP);
	CreateNative("War3_HealToBuffHP",Native_War3_HTBHP);
	CreateNative("War3_DecreaseHP",Native_War3_DecreaseHP);

	
	CreateNative("W3IsDeveloper",NW3IsDeveloper);

	CreateNative("W3GetVar",NW3GetVar);
	CreateNative("W3SetVar",NW3SetVar);
	
	CreateNative("W3Log",NW3Log);
	CreateNative("W3LogError",NW3LogError);
	CreateNative("W3LogNotError",NW3LogNotError);
	return true;
}


public NW3IsDeveloper(Handle:plugin,numParams)
{
	new client=GetNativeCell(1); //offical W3 developers
	if(ValidPlayer(client)){
		return W3GetPlayerProp(client,isDeveloper);
	}
	return false;
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



public NW3Log(Handle:plugin,numParams)//{const String:fmt[],any:...)
{
	
	decl String:outstr[1000];
	
	FormatNativeString(0, 
                          1, 
                          2, 
                          sizeof(outstr),
						  _,
						  outstr);
	decl String:date[32];
	FormatTime(date, sizeof(date), "%c");					  					  
	Format(outstr,sizeof(outstr),"%s %s",date,outstr);
	
	PrintToServer("%s",outstr);
	WriteFileLine(hW3Log,outstr);
	FlushFile(hW3Log);
}
public NW3LogError(Handle:plugin,numParams)//{const String:fmt[],any:...)
{
	
	decl String:outstr[1000];
	
	FormatNativeString(0, 
                          1, 
                          2, 
                          sizeof(outstr),
						  _,
						  outstr);
	decl String:date[32];
	FormatTime(date, sizeof(date), "%c");					  					  
	Format(outstr,sizeof(outstr),"%s %s",date,outstr);
	
	PrintToServer("%s",outstr);
	WriteFileLine(hW3LogError,outstr);
	FlushFile(hW3LogError);
}
public NW3LogNotError(Handle:plugin,numParams)//{const String:fmt[],any:...)
{
	
	decl String:outstr[1000];
	
	FormatNativeString(0, 
                          1, 
                          2, 
                          sizeof(outstr),
						  _,
						  outstr);
	decl String:date[32];
	FormatTime(date, sizeof(date), "%c");					  					  
	Format(outstr,sizeof(outstr),"%s %s",date,outstr);
	
	PrintToServer("%s",outstr);
	WriteFileLine(hW3LogNotError,outstr);
	FlushFile(hW3LogNotError);
}