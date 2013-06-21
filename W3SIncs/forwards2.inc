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


new Handle:g_OnWar3PluginReadyHandle2; //other races

///END forwards


bool:War3Source_InitForwards2()
{
	g_OnWar3PluginReadyHandle2=CreateGlobalForward("OnWar3LoadRaceOrItemOrdered2",ET_Ignore,Param_Cell,Param_Cell,Param_String);//ordered
	return true;
}
