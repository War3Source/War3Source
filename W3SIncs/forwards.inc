/*
File: forwards.inc
Description: All the forwards that keep us from having to make a C++ extension,
I <3 SourceMod :) 
* 
* forwards are initiated and defined
* 
* 
* actual parameters passed is defined elsewhere 
* 
* 	Call_StartForward(g_OnWar3TakeDamageHandle);
* 	Call_PushCell(victim);
* 	Call_PushCell(attacker);
* 	Call_PushCell(inflictor);
* 	Call_PushCell(damage);
* 	Call_PushCell(damagetype);
* 	new result;
* 	Call_Finish(result);
* 	return Action:result;
* 
* 
*  MUST LIST THE FORWARD IN THE War3Source_Interface!!!!!!!!!!!!!!!!!!!!!!!!!!! 

Author(s): Anthony Iacono  
* 
* 
*/

// Forward Handles, one each

// IE:  new Handle:g_OnWar3adsfasfd;






/////FORWARD HANDLES (FH)


new Handle:g_OnWar3PluginReadyHandle; //loadin default races in order
new Handle:g_OnWar3PluginReadyHandle2; //other races
new Handle:g_OnWar3PluginReadyHandle3; //other races backwards compatable

new Handle:hOnSHLoadHeroOrItemOrdered;


new Handle:g_OnWar3EventSpawnFH;
new Handle:g_OnWar3EventDeathFH;


new Handle:g_OnSHEventSpawnFH;
new Handle:g_OnSHEventDeathFH;

new Handle:g_CheckCompatabilityFH;
new Handle:g_War3InterfaceExecFH;


///END forwards


bool:War3Source_InitForwards()
{
	
	
	g_OnWar3PluginReadyHandle=CreateGlobalForward("OnWar3LoadRaceOrItemOrdered",ET_Ignore,Param_Cell);//ordered
	g_OnWar3PluginReadyHandle2=CreateGlobalForward("OnWar3LoadRaceOrItemOrdered2",ET_Ignore,Param_Cell);//ordered
	g_OnWar3PluginReadyHandle3=CreateGlobalForward("OnWar3PluginReady",ET_Ignore); //unodered rest of the items or races. backwards compatable..
	
	hOnSHLoadHeroOrItemOrdered=CreateGlobalForward("OnSHLoadHeroOrItemOrdered",ET_Ignore,Param_Cell);
	
	g_OnWar3EventSpawnFH=CreateGlobalForward("OnWar3EventSpawn",ET_Ignore,Param_Cell);
	g_OnWar3EventDeathFH=CreateGlobalForward("OnWar3EventDeath",ET_Ignore,Param_Cell,Param_Cell);
	
	g_OnSHEventSpawnFH=CreateGlobalForward("OnSHEventSpawn",ET_Ignore,Param_Cell);
	g_OnSHEventDeathFH=CreateGlobalForward("OnSHEventDeath",ET_Ignore,Param_Cell,Param_Cell);
	
	
	g_CheckCompatabilityFH=CreateGlobalForward("CheckWar3Compatability",ET_Ignore,Param_String);
	g_War3InterfaceExecFH=CreateGlobalForward("War3InterfaceExec",ET_Ignore);
	
	return true;
}

OneTimeForwards(){
	Call_StartForward(g_CheckCompatabilityFH);
	Call_PushString(interfaceVersion);
	Call_Finish(dummyreturn);

}

DoForward_OnWar3EventSpawn(client){
	if(W3()){
		Call_StartForward(g_OnWar3EventSpawnFH);
		Call_PushCell(client);
		Call_Finish(dummyreturn);
	}
	if(SH()){
		Call_StartForward(g_OnSHEventSpawnFH);
		Call_PushCell(client);
		Call_Finish(dummyreturn);
	}
}
DoForward_OnWar3EventDeath(victim,killer){
	if(W3()){
		Call_StartForward(g_OnWar3EventDeathFH);
		Call_PushCell(victim);
		Call_PushCell(killer);
		Call_Finish(dummyreturn);
	}
	if(SH()){
		Call_StartForward(g_OnSHEventDeathFH);
		Call_PushCell(victim);
		Call_PushCell(killer);
		Call_Finish(dummyreturn);
	}
}

DoWar3InterfaceExecForward(){
	Call_StartForward(g_War3InterfaceExecFH);
	Call_Finish(dummyreturn);
}
