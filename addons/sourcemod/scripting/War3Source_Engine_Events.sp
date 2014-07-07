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
new bool:notdenied=true;
new W3VarArr[W3Var];

public bool:InitNativesForwards()
{
    CreateNative("W3CreateEvent",NW3CreateEvent);//foritems
    
    CreateNative("W3Denied",NW3Denied);
    CreateNative("W3Deny",NW3Deny);

    CreateNative("W3GetVar",NW3GetVar);
    CreateNative("W3SetVar",NW3SetVar);

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
    Call_Finish();
}

public NW3Denied(Handle:plugin,numParams){
    notdenied=true;
    Call_StartForward(g_hfwddenyable);
    Call_PushCell(GetNativeCell(1)); //event,/
    Call_PushCell(GetNativeCell(2));    //client
    Call_Finish();
    return !notdenied;
}
public NW3Deny(Handle:plugin,numParams){
    notdenied=false;
}

public NW3GetVar(Handle:plugin,numParams){
    return _:W3VarArr[War3Var:GetNativeCell(1)];
}
public NW3SetVar(Handle:plugin,numParams){
    W3VarArr[War3Var:GetNativeCell(1)]=GetNativeCell(2);
}
