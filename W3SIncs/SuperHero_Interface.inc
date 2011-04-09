



///SH wrappers

//
forward OnSHLoadHeroOrItemOrdered(num);

native SHHasHero(client,heroid);
native SHSetHasHero(client,hero,bool:hasThisHero);


native SHGetHeroHasPowerBind(hero);
native SHSetHeroHasPowerBind(hero,bool:hasPowerBind=true);

//when player spawns, fires only in sh mode
forward OnSHEventSpawn(client);

//when player dies, fires only in sh mode
forward OnSHEventDeath(victim,attacker);

//when a player's heros change
forward OnHeroChanged(client);

//returns hero id!!
//Skill name is displayed in cooldowns
stock SHRegisterHero(String:heroname[],String:shortheroname[],String:tttSkillName[]="No Activateble Skill",String:longDescription[],bool:hasPowerBind=false){
	new heroid=War3_CreateNewRace(heroname,shortheroname);
	War3_AddRaceSkill(heroid,tttSkillName,longDescription,false,4); ///

	SHSetHeroHasPowerBind(heroid,hasPowerBind);

	War3_CreateRaceEnd(heroid);

	return heroid;
}
stock SHGetHeroName(heroid,String:str[],maxlen){
	War3_GetRaceName(heroid,str,maxlen);
}
stock SHGetHeroShortname(heroid,String:str[],maxlen){
	War3_GetRaceShortname(heroid,str,maxlen);
}
stock SHGetHeroShortDesc(heroid,String:str[],maxlen){
	W3GetRaceSkillName(heroid,0,str,maxlen);
}
stock SHGetHeroLongDesc(heroid,String:str[],maxlen){
	W3GetRaceSkillDesc(heroid,0,str,maxlen);
}

native SHGetLevel(client);
native SHSetLevel(client,newlevel);

native SHGetXP(client);
native SHSetXP(client,newxp);
native SHShowXP(client);
native SHGetReqXP(level); //get required xp for leveling to the level, use (level+1) for xp required for next level

/**
 * how many heroes a player can have
 * sh_heroes_per_player read
 */ 
native SHGetHeroesClientCanHave(client);

/**
 * how many heroes this person have?
 */ 
stock SHHasHeroesNum(client){
	new num;
	for(new i=1;i<=War3_GetRacesLoaded();i++)
	{
		if(SHHasHero(client,i))
		{
			num++;
		}
	}
	return num;
}

//returns the race that is bound to this power index, 0 index is used
native SHGetPowerBind(client,powerbindindex); //0 - 2
native SHSetPowerBind(client,powerbindindex,heroBoundedTo);

forward OnPowerCommand(client,targetHero,bool:pressed);

native SHMaxLevel();

native SHSaveXP(client);

native SHTryToGiveClientHero(client,herotogive,bool:showchangeracemenuagain);

/********
 * //show changerace menu if player can select more races
 */ 
stock SHShowCRMenuIfCanChoose(client){ 
	if(W3IsPlayerXPLoaded(client)){
		if(SHHasHeroesNum(client)<(client)){
			W3CreateEvent(SHSelectHeroesMenu,client);
			return true;
		}
	}
	return false;
}
/**********************
 * cooldown wrapper, see war3_cooldownmgr for specifics
 */ 
stock SH_CooldownMGR(client,Float:cooldownTime,ttheroID,bool:resetOnSpawn=true,bool:printMsgOnExpireByTime=true){
	War3_CooldownMGR(client,Float:cooldownTime,ttheroID,0,resetOnSpawn, printMsgOnExpireByTime);  
} 
stock SH_SetBuff(client,W3Buff:buffindex,heroid,any:value){
	if(SH()){
		War3_SetBuff(client,W3Buff:buffindex,heroid,any:value);
	}
}


/** 
 * Prints a message in the chat area with [War3Source] pre-appended.
 * Support color tags: {default}, {green}, {lightgreen}, {red}, {blue}, {olive}.
 * 
 * @param client      Client index, pass 0 for message to all.
 * @param szMessage   Message (formatting rules).
 * @return            No return
 */
stock SH_ChatMessage(client, const String:szMessage[], any:...)
{
	if (client == 0)
	{
		decl String:szBuffer[MAX_MESSAGE_LENGTH];
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				SetGlobalTransTarget(i);
				VFormat(szBuffer, sizeof(szBuffer), szMessage, 3);
				//Format(szBuffer, sizeof(szBuffer), "%T%s", "[SH]", i, szBuffer);
				Format(szBuffer, sizeof(szBuffer), "[SuperHero] %s",  szBuffer);
				CPrintToChat(i, szBuffer);
			}
		}
	}
	else
	{
		decl String:szBuffer[MAX_MESSAGE_LENGTH];
		SetGlobalTransTarget(client);
		VFormat(szBuffer, sizeof(szBuffer), szMessage, 3);
		//Format(szBuffer, sizeof(szBuffer), "%T%s", "[SH]", client, szBuffer);
		Format(szBuffer, sizeof(szBuffer), "[SuperHero] %s",  szBuffer);
		CPrintToChat(client, szBuffer);
	}
}