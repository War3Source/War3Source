



///SH wrappers

//
forward OnSHLoadHeroOrItemOrdered(num);

native SHHasHero(client,heroid);
native SHSetHasHero(client,hero,bool:hasThisHero);


native SHGetHeroHasPowerBind(hero);
native SHSetHeroHasPowerBind(hero,bool:hasPowerBind=true);



//returns hero id!!
stock SHRegisterHero(String:heroname[],String:shortheroname[],String:shortSkillName[]="no activateble skill",String:longDescription[],bool:hasPowerBind=false){
	new heroid=War3_CreateNewRace(heroname,shortheroname);
	War3_AddRaceSkill(heroid,shortSkillName,longDescription,false,4); ///

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

native SHGetHeroesClientCanHave(client);
stock SHHasHeroesNum(client){
	new num;
	for(new i=1;i<=War3_GetRacesLoaded();i++){
		if(SHHasHero(client,i)){
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

stock SHShowCRMenuIfCanChoose(client){ //show changerace menu if player can select more races
	if(W3IsPlayerXPLoaded(client)){
		if(SHHasHeroesNum(client)<SHGetHeroesClientCanHave(client)){
			W3CreateEvent(SHSelectHeroesMenu,client);
			return true;
		}
	}
	return false;
}

stock SH_CooldownMGR(client,Float:cooldownTime,heroID,bool:resetOnSpawn=true,bool:printMsgOnExpireByTime=true){
	War3_CooldownMGR(client,Float:cooldownTime,heroID,0,resetOnSpawn, printMsgOnExpireByTime);  
} 