




new Handle:hRaceLimitEnabled;


new Handle:hChangeGameDescCvar;
new Handle:hUseMetric;

new Handle:introclannamecvar;
new Handle:clanurl;

War3Source_InitCVars()
{
    introclannamecvar=CreateConVar("war3_introclanname","war3_introclanname","Intro menu clan name (welcome to 'YOUR CLAN NAME' War3Source server!)");
    clanurl=CreateConVar("war3_clanurl","Www.OwnageClan.Com (set war3_clanurl)","The url to display on intro menu");

    hRaceLimitEnabled=CreateConVar("war3_racelimit_enable","1","Should race limit restrictions per team be enabled");
    W3SetVar(hRaceLimitEnabledCvar,hRaceLimitEnabled);


    hChangeGameDescCvar=CreateConVar("war3_game_desc","1","change game description to war3source? does not affect player connect");
    
    hUseMetric=CreateConVar("war3_metric_system","0","Do you want use metric system? 1-Yes, 0-No");
    W3SetVar(hUseMetricCvar,hUseMetric);
    return true;
}

