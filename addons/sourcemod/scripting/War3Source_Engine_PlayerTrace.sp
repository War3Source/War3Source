#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Player Trace",
    author = "War3Source Team",
    description = "Some trace utilitys"
};

public bool:InitNativesForwards()
{
    ///LIST ALL THESE NATIVES IN INTERFACE
    CreateNative("War3_GetAimEndPoint",NWar3_GetAimEndPoint);
    CreateNative("War3_GetAimTraceMaxLen",NWar3_GetAimTraceMaxLen);
    
    CreateNative("War3_GetTargetInViewCone",Native_War3_GetTargetInViewCone);
    
    CreateNative("W3LOS",NW3LOS);
    return true;
}

new ignoreClient;
public NWar3_GetAimEndPoint(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    new Float:angle[3];
    GetClientEyeAngles(client,angle);
    new Float:endpos[3];
    new Float:startpos[3];
    GetClientEyePosition(client,startpos);
    
    ignoreClient=client;
    TR_TraceRayFilter(startpos,angle,MASK_ALL,RayType_Infinite,AimTargetFilter);
    TR_GetEndPosition(endpos);
    
    SetNativeArray(2,endpos,3);
}
public NWar3_GetAimTraceMaxLen(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    new Float:angle[3];
    GetClientEyeAngles(client,angle);
    new Float:endpos[3];
    new Float:startpos[3];
    GetClientEyePosition(client,startpos);
    new Float:dir[3];
    GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
    
    ScaleVector(dir, GetNativeCell(3));
    AddVectors(startpos, dir, endpos);
    
    ignoreClient=client;
    TR_TraceRayFilter(startpos,endpos,MASK_ALL,RayType_EndPoint,AimTargetFilter);
    
    TR_GetEndPosition(endpos); //overwrites to actual end pos
    
    SetNativeArray(2,endpos,3);
}
public bool:AimTargetFilter(entity,mask)
{
    return !(entity==ignoreClient);
}
public bool:CanHitThis(entityhit, mask, any:data)
{
    if(entityhit == data )
    {// Check if the TraceRay hit the itself.
        return false; // Don't allow self to be hit, skip this result
    }
    if(ValidPlayer(entityhit)&&ValidPlayer(data)&&War3_GetGame()==Game_TF&&GetClientTeam(entityhit)==GetClientTeam(data)){
        return false; //skip result, prend this space is not taken cuz they on same team
    }
    return true; // It didn't hit itself
}










public Native_War3_GetTargetInViewCone(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    if(ValidPlayer(client))
    {
        new Float:max_distance=GetNativeCell(2);
        new bool:include_friendlys=GetNativeCell(3);
        new Float:cone_angle=GetNativeCell(4);
        new Function:FilterFunction=GetNativeCell(5);
        if(max_distance<0.0)    max_distance=0.0;
        if(cone_angle<0.0)    cone_angle=0.0;
        
        new Float:PlayerEyePos[3];
        new Float:PlayerAimAngles[3];
        new Float:PlayerToTargetVec[3];
        new Float:OtherPlayerPos[3];
        GetClientEyePosition(client,PlayerEyePos);
        GetClientEyeAngles(client,PlayerAimAngles);
        new Float:ThisAngle;
        new Float:playerDistance;
        new Float:PlayerAimVector[3];
        GetAngleVectors(PlayerAimAngles,PlayerAimVector,NULL_VECTOR,NULL_VECTOR);
        new bestTarget=0;
        new Float:bestTargetDistance;
        for(new i=1;i<=MaxClients;i++)
        {
            if(cone_angle<=0.0)    break;
            if(ValidPlayer(i,true)&& client!=i)
            {
                if(FilterFunction!=INVALID_FUNCTION)
                {
                    Call_StartFunction(plugin,FilterFunction);
                    Call_PushCell(i);
                    new result;
                    if(Call_Finish(result)>SP_ERROR_NONE)
                    {
                        result=1; // bad callback, lets return 1 to be safe
                        new String:plugin_name[256];
                        GetPluginFilename(plugin,plugin_name,sizeof(plugin_name));
                        PrintToServer("[War3Source] ERROR in plugin \"%s\" traced to War3_GetTargetInViewCone(), bad filter function provided.",plugin_name);
                    }
                    if(result==0)
                    {
                        continue;
                    }
                }
                if(!include_friendlys && GetClientTeam(client) == GetClientTeam(i))
                {
                    continue;
                }
                GetClientEyePosition(i,OtherPlayerPos);
                playerDistance = GetVectorDistance(PlayerEyePos,OtherPlayerPos);
                if(max_distance>0.0 && playerDistance>max_distance)
                {
                    continue;
                }
                SubtractVectors(OtherPlayerPos,PlayerEyePos,PlayerToTargetVec);
                ThisAngle=ArcCosine(GetVectorDotProduct(PlayerAimVector,PlayerToTargetVec)/(GetVectorLength(PlayerAimVector)*GetVectorLength(PlayerToTargetVec)));
                ThisAngle=ThisAngle*360/2/3.14159265;
                if(ThisAngle<=cone_angle)
                {
                    ignoreClient=client;
                    TR_TraceRayFilter(PlayerEyePos,OtherPlayerPos,MASK_ALL,RayType_EndPoint,AimTargetFilter);
                    if(TR_DidHit())
                    {
                        new entity=TR_GetEntityIndex();
                        if(entity!=i)
                        {
                            continue;
                        }
                    }
                    if(bestTarget>0)
                    {
                        if(playerDistance<bestTargetDistance)
                        {
                            bestTarget=i;
                            bestTargetDistance=playerDistance;
                        }
                    }
                    else
                    {
                        bestTarget=i;
                        bestTargetDistance=playerDistance;
                    }
                }
            }
        }
        if(bestTarget==0) //still no target, use direct trace
        {
            new Float:endpos[3];
            if(max_distance>0.0){
                ScaleVector(PlayerAimVector,max_distance);
            }
            else{
            
                ScaleVector(PlayerAimVector,56756.0);
                AddVectors(PlayerEyePos,PlayerAimVector,endpos);
                TR_TraceRayFilter(PlayerEyePos,endpos,MASK_ALL,RayType_EndPoint,AimTargetFilter);
                if(TR_DidHit())
                {
                    new entity=TR_GetEntityIndex();
                    if(entity>0 && entity<=MaxClients && IsClientConnected(entity) && IsPlayerAlive(entity) && GetClientTeam(client)!=GetClientTeam(entity) )
                    {
                        new result=1;
                        if(FilterFunction!=INVALID_FUNCTION)
                        {
                            Call_StartFunction(plugin,FilterFunction);
                            Call_PushCell(entity);
                            if(Call_Finish(result)>SP_ERROR_NONE)
                            {
                                result=1; // bad callback, return 1 to be safe
                                new String:plugin_name[256];
                                GetPluginFilename(plugin,plugin_name,sizeof(plugin_name));
                                PrintToServer("[War3Source] ERROR in plugin \"%s\" traced to War3_GetTargetInViewCone(), bad filter function provided.",plugin_name);
                            }
                        }
                        if(result!=0)
                        {
                            bestTarget=entity;
                        }
                    }
                }
            }
        }
        return bestTarget;
    }
    return 0;
}
new los_target;
public NW3LOS(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    new target=GetNativeCell(2);
    los_target=target;
    if(ValidPlayer(client,true)&&ValidPlayer(target,true))
    {
        new Float:PlayerEyePos[3];
        new Float:OtherPlayerPos[3];
        GetClientEyePosition(client,PlayerEyePos); //GetClientEyePosition(
        GetClientEyePosition(target,OtherPlayerPos); //GetClientAbsPosition
        ignoreClient=client;
        TR_TraceRayFilter(PlayerEyePos,OtherPlayerPos,MASK_ALL,RayType_EndPoint,LOSFilter);
        if(TR_DidHit())
        {
            new entity=TR_GetEntityIndex();
            if(entity==target)
            {
                return true;
            }
        }
    }
    return false;
}
public bool:LOSFilter(entity,mask)
{
    return !(entity==ignoreClient || (ValidPlayer(entity,true)&&entity!=los_target));
}




