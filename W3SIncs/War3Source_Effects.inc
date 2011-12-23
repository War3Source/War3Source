/**
 * File: War3Source_Effects.inc
 * Description: Finally collecting some methods I keep copying over and over again
 * Author(s): Glider
 * 
 */

///LOOK FURTHER DOWN FOR SIMPLIFIED STOCK FUNCTIONS


/**
 * CreateW3SParticle
 * 
 * @param String:effectName Name of the particle effect you want to spawn.
 * 							Don't forget to precache this OnMapStart!
 * @param Float:fPos[3] Position to spawn the particle at
 * 
 * @returns entity index for the particle or -1 if no particle was spawned
 */
stock CreateW3SParticle(const String:effectName[], const Float:fPos[3])
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, fPos, NULL_VECTOR, NULL_VECTOR);
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
 * 						  Leave this out or set it to "" when you don't want
 * 						  to attach to any specific point.
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

//=============================================================================
//                                 One liners...
//=============================================================================

//=========================================
//                 PARTICLES
//==========================================

stock ThrowAwayParticle(const String:effectName[], const Float:fPos[3], const Float:lifetime)
{	
	new particle = CreateW3SParticle(effectName, fPos);
	ModifyEntityAddDeathTimer(particle, lifetime);
	
	return particle;
}

// If you have an attachment point you can pass NULL_VECTOR to fPos
stock AttachParticle(const client, const String:effectName[], const Float:fPos[3], const String:attachTo[]="")
{	
	new particle = CreateW3SParticle(effectName, fPos);
	ModifyEntityAttach(particle, client, attachTo);
	
	return particle;
}

// If you have an attachment point you can pass NULL_VECTOR to fPos
stock AttachThrowAwayParticle(const client, const String:effectName[], const Float:fPos[3], const String:attachTo[], const Float:lifetime)
{	
	new particle = CreateW3SParticle(effectName, fPos);
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

//Returns true if race is allowed to draw effects - false otherwhise
native bool:W3RaceCanDrawEffects(raceid);
//Returns true if the client can actually see effects
native bool:W3ClientCanSeeEffect(client);
//returns the raceid of the last create w3effect
native W3GetEffectRace();
//War3Source TE_ methods - use them instead of the 'old' ones!:
native bool:W3CreateEffect(const String:te_name[],raceid); //actually init. the effect(register's it to a race)
native W3SendToArea(Float:fPos[3],Float:fMaxDistance,bool:aliveOnly=false,Float:fDelay=0.0);
native W3SendToTeam(iTeam,bool:aliveOnly=false,Float:fDelay=0.0);
native W3SendToAll(bool:aliveOnly=false,Float:fDelay=0.0);
native W3SendToClient(client,Float:fDelay=0.0);
//NOTE: use W3CreateEffect instead of TE_Start and the W3Send methods instead of the TE_Send ones
//Modified sdktools tempent stocks
stock W3SetupSmoke(raceid, const Float:pos[3], Model, Float:Scale, FrameRate)
{
	W3CreateEffect("Smoke",raceid);
	TE_WriteVector("m_vecOrigin", pos);
	TE_WriteNum("m_nModelIndex", Model);
	TE_WriteFloat("m_fScale", Scale);
	TE_WriteNum("m_nFrameRate", FrameRate);
}
stock W3SetupSparks(raceid, const Float:pos[3], const Float:dir[3], Magnitude, TrailLength)
{
	W3CreateEffect("Sparks",raceid);
	TE_WriteVector("m_vecOrigin[0]", pos);
	TE_WriteVector("m_vecDir", dir);
	TE_WriteNum("m_nMagnitude", Magnitude);
	TE_WriteNum("m_nTrailLength", TrailLength);
}
stock W3SetupGlowSprite(raceid, const Float:pos[3], Model, Float:Life, Float:Size, Brightness)
{
	W3CreateEffect("GlowSprite",raceid);
	TE_WriteVector("m_vecOrigin", pos);
	TE_WriteNum("m_nModelIndex", Model);
	TE_WriteFloat("m_fScale", Size);
	TE_WriteFloat("m_fLife", Life);
	TE_WriteNum("m_nBrightness", Brightness);
}
stock W3SetupExplosion(raceid, const Float:pos[3], Model, Float:Scale, Framerate, Flags, Radius, Magnitude, const Float:normal[3]={0.0, 0.0, 1.0}, MaterialType='C')
{
	W3CreateEffect("Explosion",raceid);
	TE_WriteVector("m_vecOrigin[0]", pos);
	TE_WriteVector("m_vecNormal", normal);
	TE_WriteNum("m_nModelIndex", Model);
	TE_WriteFloat("m_fScale", Scale);
	TE_WriteNum("m_nFrameRate", Framerate);
	TE_WriteNum("m_nFlags", Flags);
	TE_WriteNum("m_nRadius", Radius);
	TE_WriteNum("m_nMagnitude", Magnitude);
	TE_WriteNum("m_chMaterialType", MaterialType);
}
stock W3SetupBeamRingPoint(raceid, const Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex, HaloIndex, StartFrame, 
				FrameRate, Float:Life, Float:Width, Float:Amplitude, const Color[4], Speed, Flags)
{
	W3CreateEffect("BeamRingPoint",raceid);
	TE_WriteVector("m_vecCenter", center);
	TE_WriteFloat("m_flStartRadius", Start_Radius);
	TE_WriteFloat("m_flEndRadius", End_Radius);
	TE_WriteNum("m_nModelIndex", ModelIndex);
	TE_WriteNum("m_nHaloIndex", HaloIndex);
	TE_WriteNum("m_nStartFrame", StartFrame);
	TE_WriteNum("m_nFrameRate", FrameRate);
	TE_WriteFloat("m_fLife", Life);
	TE_WriteFloat("m_fWidth", Width);
	TE_WriteFloat("m_fEndWidth", Width);
	TE_WriteFloat("m_fAmplitude", Amplitude);
	TE_WriteNum("r", Color[0]);
	TE_WriteNum("g", Color[1]);
	TE_WriteNum("b", Color[2]);
	TE_WriteNum("a", Color[3]);
	TE_WriteNum("m_nSpeed", Speed);
	TE_WriteNum("m_nFlags", Flags);
	TE_WriteNum("m_nFadeLength", 0);
}
stock W3SetupBeamPoints(raceid, const Float:start[3], const Float:end[3], ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life, 
				Float:Width, Float:EndWidth, FadeLength, Float:Amplitude, const Color[4], Speed)
{
	W3CreateEffect("BeamPoints",raceid);
	TE_WriteVector("m_vecStartPoint", start);
	TE_WriteVector("m_vecEndPoint", end);
	TE_WriteNum("m_nModelIndex", ModelIndex);
	TE_WriteNum("m_nHaloIndex", HaloIndex);
	TE_WriteNum("m_nStartFrame", StartFrame);
	TE_WriteNum("m_nFrameRate", FrameRate);
	TE_WriteFloat("m_fLife", Life);
	TE_WriteFloat("m_fWidth", Width);
	TE_WriteFloat("m_fEndWidth", EndWidth);
	TE_WriteFloat("m_fAmplitude", Amplitude);
	TE_WriteNum("r", Color[0]);
	TE_WriteNum("g", Color[1]);
	TE_WriteNum("b", Color[2]);
	TE_WriteNum("a", Color[3]);
	TE_WriteNum("m_nSpeed", Speed);
	TE_WriteNum("m_nFadeLength", FadeLength);
}
stock W3SetupBeamFollow(raceid, EntIndex, ModelIndex, HaloIndex, Float:Life, Float:Width, Float:EndWidth, FadeLength, const Color[4])
{
	W3CreateEffect("BeamFollow",raceid);
	TE_WriteEncodedEnt("m_iEntIndex", EntIndex);
	TE_WriteNum("m_nModelIndex", ModelIndex);
	TE_WriteNum("m_nHaloIndex", HaloIndex);
	TE_WriteNum("m_nStartFrame", 0);
	TE_WriteNum("m_nFrameRate", 0);
	TE_WriteFloat("m_fLife", Life);
	TE_WriteFloat("m_fWidth", Width);
	TE_WriteFloat("m_fEndWidth", EndWidth);
	TE_WriteNum("m_nFadeLength", FadeLength);
	TE_WriteNum("r", Color[0]);
	TE_WriteNum("g", Color[1]);
	TE_WriteNum("b", Color[2]);
	TE_WriteNum("a", Color[3]);
}
stock W3SetupBloodSprite(raceid, const Float:pos[3], const Float:dir[3], const color[4], Size, SprayModel, BloodDropModel)
{
	W3CreateEffect("Blood Sprite",raceid);
	TE_WriteVector("m_vecOrigin", pos);
	TE_WriteVector("m_vecDirection", dir);
	TE_WriteNum("r", color[0]);
	TE_WriteNum("g", color[1]);
	TE_WriteNum("b", color[2]);
	TE_WriteNum("a", color[3]);
	TE_WriteNum("m_nSize", Size);
	TE_WriteNum("m_nSprayModel", SprayModel);
	TE_WriteNum("m_nDropModel", BloodDropModel);
}
//////Engine_Particles.sp
//Purpose: precaches a particle system(not a def. file!)
native PrecacheParticleSystem(const String:strParticleSystem[]);
//Purpose: reads a particle def. file
native bool:ReadParticleConfigFile(const String:strParticleFile[],bool:bPrecache,bool:bDecommitTempMemory=true);