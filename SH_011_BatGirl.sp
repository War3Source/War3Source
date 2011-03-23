#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "SH Hero BatGirl",
	author = "Ownz & Anthony",
	description = "SH Hero",
	version = "1.0.0.0",
	url = "http://war3source.com"
};

new heroID;
new bool:isHooked[MAXPLAYERS+1];
new Float:hookOrigin[MAXPLAYERS+1][3];
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
		origin[2]+=20.0;
	
		new color[4];
		color[0]=r;
		color[1]=g;
		color[2]=b;
		color[3]=a;

		TE_SetupBeamPoints(origin,hookOrigin[client],beamPrecache,0,     1,         10,   0.2, 10.0  ,1.0,      0,0.0,color,50);
		TE_SendToAll(0.0);
		origin[2]-=20.0;
		
		
		new Float:nil[3],Float:velocity[3],Float:A[3];
		
		GetEntPropVector(client,Prop_Data,"m_vecVelocity",velocity);
		
		A[0]=hookOrigin[client][0]-origin[0];
		A[1]=hookOrigin[client][1]-origin[1];
		A[2]=hookOrigin[client][2]-origin[2];
		new Float:dist=GetVectorDistance(nil,A);
		velocity[0]+=A[0]*GetConVarFloat(cvarSpeed)/dist;
		velocity[1]+=A[1]*GetConVarFloat(cvarSpeed)/dist;
		velocity[2]+=A[2]*GetConVarFloat(cvarSpeed)/dist;
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
    GetClientAbsOrigin(client,origin);
    origin[2]+=20.0;
    
    new color[4];
    color[0]=r;
    color[1]=g;
    color[2]=b;
    color[3]=a;
    TE_SetupBeamPoints(origin,hookOrigin[client],beamPrecache,0,     1,         10,   0.2, 10.0  ,1.0,      0,0.0,color,50);
    TE_SendToAll(0.0);
    
    origin[2]-=20.0;
    new Float:velocity[3];
    
    velocity[0]=hookOrigin[client][0]-origin[0];
    velocity[1]=hookOrigin[client][1]-origin[1];
    velocity[2]=hookOrigin[client][2]-origin[2];
    
    NormalizeVector(velocity,velocity);
    velocity[0]*=GetConVarFloat(cvarSpeed);
    velocity[1]*=GetConVarFloat(cvarSpeed);
    velocity[2]*=GetConVarFloat(cvarSpeed);
    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
    CreateTimer(0.1,HookTask,client);
}

public bool:TraceFilter(entity,mask)
{
    if(entity==traceDeny)
        return false;
    return true;
}