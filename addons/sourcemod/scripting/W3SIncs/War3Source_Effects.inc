/**
 * File: War3Source_Effects.inc
 * Description: Stocks to make races flashier
 * Author(s): War3Source Team  
 */
#define BEAMSPRITE_CSGO      "materials/sprites/laserbeam.vmt"
#define BEAMSPRITE_SOURCE    "materials/sprites/lgtning.vmt"

#define HALOSPRITE_CSGO     "materials/sprites/halo.vmt"
#define HALOSPRITE_SOURCE   "materials/sprites/halo01.vmt"

#define MAX_BEAM_SCROLLSPEED 100
#define PushClientToVector PushEntToVector

//=============================================================================
//                                 One liners...
//=============================================================================

//=========================================
//                 PARTICLES
//==========================================

stock ThrowAwayParticle(const String:effectName[], const Float:fPos[3], const Float:lifetime, const Float:fAngles[3]=NULL_VECTOR)
{
    new particle = CreateW3SParticle(effectName, fPos, fAngles);
    ModifyEntityAddDeathTimer(particle, lifetime);
    
    return particle;
}

// If you have an attachment point you can pass NULL_VECTOR to fPos
stock AttachParticle(const client, const String:effectName[], const Float:fPos[3], const String:attachTo[]="", const Float:fAngles[3]=NULL_VECTOR)
{    
    new particle = CreateW3SParticle(effectName, fPos, fAngles);
    ModifyEntityAttach(particle, client, attachTo);
    
    return particle;
}

// If you have an attachment point you can pass NULL_VECTOR to fPos
stock AttachThrowAwayParticle(const client, const String:effectName[], const Float:fPos[3], const String:attachTo[], const Float:lifetime, const Float:fAngles[3]=NULL_VECTOR)
{    
    new particle = CreateW3SParticle(effectName, fPos, fAngles);
    ModifyEntityAttach(particle, client, attachTo);
    ModifyEntityAddDeathTimer(particle, lifetime);
    
    return particle;
}

//=========================================
//                 LIGHTS
//==========================================

stock ThrowAwayLightEmitter(const Float:fPos[3], const String:color[], const String:style[], const Float:distance, const Float:lifetime)
{    
    new light = CreateW3SLight(fPos, color, style, distance);
    ModifyEntityAddDeathTimer(light, lifetime);
}

// If you have an attachment point you can pass NULL_VECTOR to fPos
stock AttachLight(const client, const Float:fPos[3], const String:color[], const String:style[], const Float:distance, const String:attachTo[])
{    
    new light = CreateW3SLight(fPos, color, style, distance);
    ModifyEntityAttach(light, client, attachTo);
    
    return light;
}

// If you have an attachment point you can pass NULL_VECTOR to fPos
stock AttachThrowAwayLight(const client, const Float:fPos[3], const String:color[], const String:style[], const Float:distance, const String:attachTo[], const Float:lifetime)
{    
    new light = CreateW3SLight(fPos, color, style, distance);
    ModifyEntityAttach(light, client, attachTo);
    ModifyEntityAddDeathTimer(light, lifetime);
    
    return light;
}

//=============================================================================
//                                 Temp Entitys
//=============================================================================

stock TE_SetupBubbles(const Float:vecOrigin[3], const Float:vecFinish[3],modelIndex,const Float:heightF,count,const Float:speedF)
{
    TE_Start("Bubbles");
    TE_WriteVector("m_vecMins", vecOrigin);
    TE_WriteVector("m_vecMaxs", vecFinish);
    TE_WriteFloat("m_fHeight", heightF);
    TE_WriteNum("m_nModelIndex", modelIndex);
    TE_WriteNum("m_nCount", count);
    TE_WriteFloat("m_fSpeed", speedF);
}

//=============================================================================
//                                 Screen effects
//=============================================================================

/**
 * Flashes a player's screen a certain color for a duration.
 * @param client: Client's index.
 * @param color[4]: RGBA value of the color, see above for presets.
 * @param duration: Length of flash, optional.
 * @param flags: Flags of Fade user message, optional.
 * @noreturn
 */
native W3FlashScreen(client,color[4],Float:holdduration=0.1,Float:fadeduration=0.2,flags=FFADE_IN);

/**
 * Shakes a player's screen at a magnitude and noise for a duration.
 * @param client: Client's index.
 * @param duration: Optional, how long to shake.
 * @param magnitude: Optional magnitude value.
 * @param noise: Optional noise value.
 * @noreturn
 */
native War3_ShakeScreen(client,Float:duration=1.0,Float:magnitude=40.0,Float:noise=30.0);

//=============================================================================
//                             Precaching
//=============================================================================

stock War3_PrecacheBeamSprite() 
{
    new spriteIndex = PrecacheModel(GAMECSGO ? BEAMSPRITE_CSGO : BEAMSPRITE_SOURCE);

    if(spriteIndex == -1) 
    {
        War3_LogCritical("Failed to precache BeamSprite material \"%s\"", GAMECSGO ? BEAMSPRITE_CSGO : BEAMSPRITE_SOURCE);
    }
    
    return spriteIndex;
}

stock War3_PrecacheHaloSprite() 
{
    new spriteIndex = PrecacheModel(GAMECSGO ? HALOSPRITE_CSGO : HALOSPRITE_SOURCE);

    if(spriteIndex == -1) 
    {
        War3_LogCritical("Failed to precache HaloSprite material \"%s\"", GAMECSGO ? HALOSPRITE_CSGO : HALOSPRITE_SOURCE);
    }
    
    return spriteIndex;
}

//=============================================================================
//                             Raw particle/light methods
//=============================================================================

//=========================================
//                 CREATION
//==========================================

/**
 * CreateW3SParticle
 * 
 * @param String:effectName Name of the particle effect you want to spawn.
 *                             Don't forget to precache this OnMapStart!
 * @param Float:fPos[3] Position to spawn the particle at
 * 
 * @returns entity index for the particle or -1 if no particle was spawned
 */
stock CreateW3SParticle(const String:effectName[], const Float:fPos[3], const Float:fAngles[3])
{
    new particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle))
    {
        TeleportEntity(particle, fPos, fAngles, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", effectName);
        DispatchSpawn(particle);
        
        ActivateEntity(particle);
        AcceptEntityInput(particle, "Start");

        return particle;
    }
    else
    {
        PrintToServer("Couldn't create info_particle_system!");
    }
    
    return -1;
}

/**
 * CreateW3SLight
 * 
 * Spawns a light_dynamic at a fixed position.
 * 
 * @param Float:fPos[3] Position to spawn the light at
 * @param String:color RGBA value of the color like "255 255 255 255"
 * @param String:style See http://developer.valvesoftware.com/wiki/Light under "Appearances"
 * @param distance how far the light stretches
 * 
 * @returns the entinty index of the light or -1 if there was none created
 */
stock CreateW3SLight(const Float:fPos[3], const String:color[], const String:style[], const Float:distance)
{
    new light = CreateEntityByName("light_dynamic");
    if (IsValidEdict(light))
    {
        DispatchKeyValue(light, "_light", color);
        DispatchKeyValue(light, "brightness", "1");
        
        // Not so sure how this changes the looks. 
        DispatchKeyValueFloat(light, "spotlight_radius", 32.0);
        DispatchKeyValueFloat(light, "distance", distance);
        DispatchKeyValue(light, "style", style);
        DispatchSpawn(light);
        AcceptEntityInput(light, "TurnOn");
        
        TeleportEntity(light, fPos, NULL_VECTOR, NULL_VECTOR);
        
        return light;
    }
    else
    {
        PrintToServer("Couldn't create light_dynamic!");
    }

    return -1;
}

//=========================================
//                 ATTACHMENT
//==========================================

/**
 * ModifyEntityAddDeathTimer
 * 
 * @param entityIndex Entity index you want to modify
 * @param Float:lifetime Seconds after wich the entity should be killed
 */
stock ModifyEntityAddDeathTimer(const entityIndex, const Float:lifetime)
{
    if (IsValidEdict(entityIndex))
    {
        decl String:variantString[60];
        Format(variantString, sizeof(variantString), "OnUser1 !self:Kill::%f:-1", lifetime);
                
        SetVariantString(variantString);
        AcceptEntityInput(entityIndex, "AddOutput");
        AcceptEntityInput(entityIndex, "FireUser1");
    }
}

/**
 * ModifyEntityAttach
 * 
 * http://developer.valvesoftware.com/wiki/Entity_Hierarchy_%28parenting%29
 * 
 * @param entityIndex Entity index of the entity you want to modify
 * @param otherEntityIndex Entity index to attach the particle to
 * @param String:attachTo Attachment point of the otherEntityIndex.
 *                           Leave this out or set it to "" when you don't want
 *                           to attach to any specific point.
 */
stock ModifyEntityAttach(const entityIndex, const otherEntityIndex, const String:attachTo[]="")
{    
    if (IsValidEdict(entityIndex))
    {
        SetVariantString("!activator");
        AcceptEntityInput(entityIndex, "SetParent", otherEntityIndex, entityIndex, 0);
        
        if (!StrEqual(attachTo, ""))
        {
            SetVariantString(attachTo);
            AcceptEntityInput(entityIndex, "SetParentAttachment", entityIndex, entityIndex, 0);
        }
    }
}


//==========================================================
//                 BACKWARDS COMPATIBILITY REVANTOOLS.INC
//===========================================================

/*
By Revan
www.wcs-lagerhaus.de
Version : 1.0
*/

/********************************************PARTICLES*************************************************************************************/

stock CreateParticles(const client,bool:parentent,Float:fLifetime,Float:fAng[3],Float:BaseSpread,Float:StartSize,Float:EndSize,Float:Twist,String:material[],String:renderclr[],String:SpreadSpeed[],String:JetLength[],String:Speed[],String:Rate[]){
    new particle = CreateEntityByName("env_smokestack");
    if(IsValidEdict(particle) && IsClientInGame(client))
    {
        decl String:Name[32], Float:fPos[3];
        Format(Name, sizeof(Name), "W3S_particles_%i", client);
        GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
        fPos[2] += 50.0;
        // Set Key Values
        DispatchKeyValueVector(particle, "Origin", fPos);
        DispatchKeyValueVector(particle, "Angles", fAng);
        DispatchKeyValueFloat(particle, "BaseSpread", BaseSpread);
        DispatchKeyValueFloat(particle, "StartSize", StartSize);
        DispatchKeyValueFloat(particle, "EndSize", EndSize);
        DispatchKeyValueFloat(particle, "Twist", Twist);
        
        DispatchKeyValue(particle, "Name", Name);
        DispatchKeyValue(particle, "SmokeMaterial", material);
        DispatchKeyValue(particle, "RenderColor", renderclr);
        DispatchKeyValue(particle, "SpreadSpeed", SpreadSpeed);
        DispatchKeyValue(particle, "RenderAmt", "255");
        DispatchKeyValue(particle, "JetLength", JetLength);
        DispatchKeyValue(particle, "RenderMode", "0");
        DispatchKeyValue(particle, "Initial", "0");
        DispatchKeyValue(particle, "Speed", Speed);
        DispatchKeyValue(particle, "Rate", Rate);
        DispatchSpawn(particle);
        
        // Set Entity Inputs
        if(parentent)
        {
            SetVariantString("!activator");
            AcceptEntityInput(particle, "SetParent", client, particle, 0);
        }
        AcceptEntityInput(particle, "TurnOn");
        CreateTimer(fLifetime, INCTimer_RemoveEntity, particle);
        return particle;
    }
    else
    {
        LogError("Failed to create entity env_smokestack!");
    }
    return -1;
}

stock CreateFire(const client,String:firesize[],String:health[],String:fireattack[],String:firetype[],String:flags[],Float:damagescale,Float:fLifetime){
    new fire = CreateEntityByName("env_fire");
    if(IsValidEdict(fire) && IsClientInGame(client))
    {
        decl String:Name[32], Float:fPos[3];
        Format(Name, sizeof(Name), "W3S_fire_%i", client);
        GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
        DispatchKeyValueFloat(fire, "damagescale", damagescale);

        DispatchKeyValue(fire, "Name", Name);
        DispatchKeyValue(fire, "health", health);
        DispatchKeyValue(fire, "fireattack", fireattack);
        DispatchKeyValue(fire, "firetype", firetype);
        DispatchKeyValue(fire, "flags", flags);
        DispatchKeyValue(fire, "firesize", firesize);
        DispatchSpawn(fire);
        ActivateEntity(fire);
        TeleportEntity(fire, fPos, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(fire, "StartFire");
        CreateTimer(fLifetime, INCTimer_RemoveEntity, fire);
        return fire;
    }
    else
    {
        LogError("Failed to create entity env_fire!");
    }
    return -1;
}


stock CreateTesla(const client,Float:flifetime_min,Float:flifetime_max,Float:thick_min,Float:thick_max,Float:interval_min,Float:interval_max,Float:radiustesla,String:beamcount_min[],String:beamcount_max[],String:ColorTesla[],String:sound[],String:beammodel[],bool:spark){
    new point_tesla = CreateEntityByName("point_tesla");
    if(IsValidEdict(point_tesla) && IsClientInGame(client))
    {
        decl String:Name[32], Float:fPos[3];
        Format(Name, sizeof(Name), "W3S_tesla_%i", client);
        GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
        fPos[2]+=42.0;
        DispatchKeyValueFloat(point_tesla, "lifetime_min", flifetime_min);
        DispatchKeyValueFloat(point_tesla, "lifetime_min", flifetime_max);
        DispatchKeyValueFloat(point_tesla, "thick_min", thick_min);
        DispatchKeyValueFloat(point_tesla, "thick_max", thick_max);
        DispatchKeyValueFloat(point_tesla, "interval_min", interval_min);
        DispatchKeyValueFloat(point_tesla, "interval_max", interval_max);
        DispatchKeyValueFloat(point_tesla, "m_flRadius", radiustesla);
        DispatchKeyValue(point_tesla, "m_Color", ColorTesla);

        DispatchKeyValue(point_tesla, "Name", Name);
        DispatchKeyValue(point_tesla, "beamcount_min", beamcount_min);
        DispatchKeyValue(point_tesla, "beamcount_max", beamcount_max);
        DispatchKeyValue(point_tesla, "m_SoundName", sound);
        DispatchKeyValue(point_tesla, "texture", beammodel);
        DispatchSpawn(point_tesla);
        ActivateEntity(point_tesla);
        TeleportEntity(point_tesla, fPos, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(point_tesla, "TurnOn");
        if(spark)
        AcceptEntityInput(point_tesla, "DoSpark");
        
        CreateTimer(flifetime_max+0.2, INCTimer_RemoveEntity, point_tesla);
        return point_tesla;
    }
    else
    {
        LogError("Failed to create entity point_tesla!");
    }
    return -1;
}

stock CreateExplosion(Float:VectorPos[3], owner, String:classname[], String:magnitude[])
{
    new g_ent = CreateEntityByName("env_explosion");
    SetEntPropEnt(g_ent, Prop_Send, "m_hOwnerEntity", owner);
    DispatchKeyValue(g_ent, "classname", classname);
    DispatchKeyValue(g_ent, "iMagnitude", magnitude);
    DispatchSpawn(g_ent);
    TeleportEntity(g_ent, VectorPos, NULL_VECTOR, NULL_VECTOR);
    AcceptEntityInput(g_ent, "Explode");
    RemoveEdict(g_ent);
}

/******************************************** FUNCTIONS *************************************************************************************/


public Action:INCTimer_RemoveEntity(Handle:timer, any:edict)
{
    if(IsValidEdict(edict))
    {
        AcceptEntityInput(edict, "Kill");
    }
}

stock SetEntityAimToClient( edict, target)
{
    new Float:spos[3],  Float:epos[3], Float:vecles[3], Float:angles[3];
    GetEntPropVector(edict, Prop_Send, "m_vecOrigin", spos);
    GetClientAbsOrigin( target, epos );
    SubtractVectors( epos, spos, vecles );
    GetVectorAngles( vecles, angles );
    angles[2] = 0.0;
    TeleportEntity( edict, NULL_VECTOR, angles, NULL_VECTOR );
}



stock PushEntToVector( edict, Float:pos1[3], Float:power )
{
    new Float:pos2[3], Float:main_origin[3], Float:velo1[3], Float:velo2[3];
    GetEntPropVector(edict, Prop_Send, "m_vecOrigin", pos2);

    main_origin[0] = pos1[0] - pos2[0], main_origin[1] = pos1[1] - pos2[1], main_origin[2] = pos1[2] - pos2[2];
    velo1[0] += 0, velo1[1] += 0, velo1[2] += 300;
    
    velo2[0] = main_origin[0] * ( 100 * power );
    velo2[1] = main_origin[1] * ( 100 * power );
    velo2[2] = main_origin[2] * ( 100 * power );

    TeleportEntity( edict, NULL_VECTOR, NULL_VECTOR, velo1 );
    TeleportEntity( edict, NULL_VECTOR, NULL_VECTOR, velo2 );
}
