#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Events",
    author = "War3Source Team",
    description = "Generic War3Source events"
};

new Handle:g_War3GlobalEventFH; 
new Handle:g_hfwddenyable; 
new dummyreturn;
new bool:notdenied=true;

public bool:InitNativesForwards()
{
    CreateNative("W3CreateEvent",NW3CreateEvent);//foritems
    
    CreateNative("W3Denied",NW3Denied);
    CreateNative("W3Deny",NW3Deny);
    g_War3GlobalEventFH=CreateGlobalForward("OnWar3Event",ET_Ignore,Param_Cell,Param_Cell);
    g_hfwddenyable=CreateGlobalForward("OnW3Denyable",ET_Ignore,Param_Cell,Param_Cell);
    return true;
}
public NW3CreateEvent(Handle:plugin,numParams)
{

    new event=GetNativeCell(1);
    new client=GetNativeCell(2);
    DoFwd_War3_Event(W3EVENT:event,client);
//    if(event==SHSelectHeroesMenu){
//        ThrowNativeError(1,"asdf");
//    }
}

DoFwd_War3_Event(W3EVENT:event,client){
    Call_StartForward(g_War3GlobalEventFH);
    Call_PushCell(event);
    Call_PushCell(client);
    Call_Finish(dummyreturn);
}

public NW3Denied(Handle:plugin,numParams){
    notdenied=true;
    Call_StartForward(g_hfwddenyable);
    Call_PushCell(GetNativeCell(1)); //event,/
    Call_PushCell(GetNativeCell(2));    //client
    Call_Finish(dummyreturn);
    return !notdenied;
}
public NW3Deny(Handle:plugin,numParams){
    notdenied=false;
}

public OnWar3Event(W3EVENT:event,client){
    if(event==DoShowHelpMenu){
        //War3Source_War3Help(client);
    }
}
public OnW3Denyable(W3DENY:event,client){
    //if(event==ChangeRace){
//        W3Deny();
//        DP("blocked chancerace %d",client);
        //War3Source_War3Help(client);
//    }
}
