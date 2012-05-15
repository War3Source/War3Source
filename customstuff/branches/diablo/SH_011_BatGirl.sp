#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public SHONLY(){}

public Plugin:myinfo = 
{
	name = "SH Hero BatGirl",
	author = "Ownz & Anthony",
	description = "SH Hero",
	version = "1.0.0.0",
	url = "http://war3source.com"
};

new heroID;
new bool:isHooked[MAXPLAYERSCUSTOM+1];
new Float:hookOrigin[MAXPLAYERSCUSTOM+1][3];
new Handle:cvarColor,Handle:cvarSpeed;
new traceDeny;
new beamPrecache;
new bool:canHook;

public OnSHLoadHeroOrItemOrdered(num)
{

	if(num==30)
	{
	    heroID=SHRegisterHero("Bat Girl","batgirl","Hook","Hook onto walls!",true);
	    cvarColor=CreateConVar("batgirl_color","0"); // 0 == team, 1 == white
	    cvarSpeed=CreateConVar("batgirl_hookspeed","300.0");
	    HookEvent("round_freeze_end",RoundStart);
	    HookEvent("round_end",RoundEnd);
    }
}

public OnClientDisconnect(client)
{
    isHooked[client]=false;
}

public OnMapStart()
{
    PrecacheSound("weapons/crossbow/hit1.wav");
    beamPrecache=PrecacheModel("materials/sprites/laserbeam.vmt");
}

public RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
    canHook=true;
}

public RoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
    canHook=false;
}

public OnPowerCommand(client,hero,bool:pressed)
{
    if(hero==heroID&&SHHasHero(client,heroID))
    {
        if(pressed&&canHook)
        {
            if(!isHooked[client])
                Bat_Attach(client);
        }
        else
            isHooked[client]=false;
    }
}

Bat_Attach(client)
{
	new Float:eyepos[3];
	GetClientEyePosition(client,eyepos);
	new Float:angle[3];
	GetClientEyeAngles(client,angle);
	new Float:origin[3];
	GetClientAbsOrigin(client,origin);
	traceDeny=client;
	TR_TraceRayFilter(eyepos,angle,MASK_SOLID,RayType_Infinite,TraceFilter);
	if(TR_DidHit())
	{
		isHooked[client]=true;
		new Float:end[3];
		TR_GetEndPosition(end);
		hookOrigin[client]=end;
		War3_SetBuff(client,fLowGravitySkill,heroID,0.001);
		EmitSoundToAll("weapons/crossbow/hit1.wav",client);
	
		origin[2]+=20.0;

		DrawBeam(client,origin,hookOrigin[client]);
	
		origin[2]-=20.0;
		
		///give player initial upward boost, maybe help him get off the ground, jump is nicer thou
		new Float:velocity[3];
		GetEntPropVector(client,Prop_Data,"m_vecVelocity",velocity);
		velocity[2]+=70.0;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
		
		CreateTimer(0.1,HookTask,client);
	}
}

public Action:HookTask(Handle:timer,any:client)
{
    if(!IsClientInGame(client))
    {
        isHooked[client]=false;
        return;
    }
    if(!SHHasHero(client,heroID)||!ValidPlayer(client,true)||!isHooked[client]||!canHook)
    {
        isHooked[client]=false;
        War3_SetBuff(client,fLowGravitySkill,heroID,1.0);
        return;
    }
    new Float:origin[3]
    
    GetClientAbsOrigin(client,origin);
    origin[2]+=20.0;
    
    DrawBeam(client,origin,hookOrigin[client]);
    origin[2]-=20.0;
    
    
    ///move player toward hook location
    new Float:velocity[3];

    SubtractVectors(hookOrigin[client],origin,velocity);
    NormalizeVector(velocity,velocity);
    
    new Float:distance=GetVectorDistance(hookOrigin[client],origin);
    if(distance<100.0){ //reduce speed when close to hoook, less jittery
    	new Float:scale=(GetConVarFloat(cvarSpeed)*(100.0-distance*4.0)/100.0);
    	ScaleVector(velocity, (scale>10.0)?scale:10.0) ;
    }
    else{
    	ScaleVector(velocity, GetConVarFloat(cvarSpeed));
    }
    //PrintToChat(client,"speed %f: %f %f %f Distance %f",GetVectorLength(velocity),velocity[0],velocity[1],velocity[2],distance);
    
    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
    CreateTimer(0.1,HookTask,client);
}
DrawBeam(client,Float:tplayerorigin[3],Float:thookorigin[3]){
	new r,g,b,a;
	a=255;
	if(GetConVarInt(cvarColor)==1)
	{
		r=255;
		b=255;
		g=255;
	}
	else
	{
		if(GetClientTeam(client)==2)
			r=255;
		else
			b=255;
	}
	new color[4];
	color[0]=r;
	color[1]=g;
	color[2]=b;
	color[3]=a;
	TE_SetupBeamPoints(tplayerorigin,thookorigin,beamPrecache,0,     1,         10,   0.2, 10.0  ,1.0,      0,0.0,color,50);
	TE_SendToAll(0.0);
}
public bool:TraceFilter(entity,mask)
{
    if(entity==traceDeny)
        return false;
    return true;
}