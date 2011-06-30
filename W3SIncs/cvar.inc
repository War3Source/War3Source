




new Handle:hRaceLimitEnabled;

/*

new Handle:ChanceModifierPlasma;
new Handle:ChanceModifierBurn;
new Handle:ChanceModifierHeavy;
new Handle:ChanceModifierSentry;
new Handle:ChanceModifierSentryRocket;
new Handle:ChanceModifierMedic;
new Handle:ChanceModifierSMGSniper;
*/

new Handle:hChangeGameDescCvar;
new Handle:hUseMetric;



/////END CVARS
///other cvar handle definitions are in war3source.inc ??
War3Source_InitCVars()
{
	
	/*	
	ChanceModifierPlasma=CreateConVar("war3_chancemodifier_directburn","0.0625","From 0.0 to 1.0 chance modifier for direct burns (plasma)");
	ChanceModifierBurn=CreateConVar("war3_chancemodifier_burn","0.10","From 0.0 to 1.0 chance modifier for burns");
	ChanceModifierHeavy=CreateConVar("war3_chancemodifier_heavy","0.125","From 0.0 to 1.0 chance modifier for heavy gun");
	ChanceModifierSentry=CreateConVar("war3_chancemodifier_sentry","0.1","From 0.0 to 1.0 chance modifier for sentry");
	ChanceModifierSentryRocket=CreateConVar("war3_chancemodifier_sentryrocket","0.0625","From 0.0 to 1.0 chance modifier for sentry rockets");
	ChanceModifierMedic=CreateConVar("war3_chancemodifier_medic","0.125","From 0.0 to 1.0 chance modifier for medic needle gun");
	ChanceModifierSMGSniper=CreateConVar("war3_chancemodifier_smgsniper","0.5","From 0.0 to 1.0 chance modifier for sniper SMG");
	
	*/
	hRaceLimitEnabled=CreateConVar("war3_racelimit_enable","1","Should race limit restrictions per team be enabled");
	W3SetVar(hRaceLimitEnabledCvar,hRaceLimitEnabled);


	hChangeGameDescCvar=CreateConVar("war3_game_desc","1","change game description to war3source? does not affect player connect");
	
	hUseMetric=CreateConVar("war3_metric_system","0","Do you want use metric system? 1-Yes, 0-No");
	W3SetVar(hUseMetricCvar,hUseMetric);
	return true;
}

