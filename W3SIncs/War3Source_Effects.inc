/**
 * File: War3Source_Effects.inc
 * Description: Finally collecting some methods I keep copying over and over again
 * Author(s): Glider  
 * 
 */

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
 * @param particleIndex Entity index of the particle you want to modify
 * @param client Client index to attach the particle to
 * @param String:attachTo Model attachment to attach to.
 */
stock ModifyEntityAttach(const particleIndex, const client, const String:attachTo[])
{	
	if (IsValidEdict(particleIndex))
	{
		SetVariantString("!activator");
		AcceptEntityInput(particleIndex, "SetParent", client, particleIndex, 0);
		
		SetVariantString(attachTo);
		AcceptEntityInput(particleIndex, "SetParentAttachment", particleIndex, particleIndex, 0);
		ActivateEntity(particleIndex);
		AcceptEntityInput(particleIndex, "Start");
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

stock AttachParticle(const client, const String:effectName[], const String:attachTo[])
{	
	new particle = CreateW3SParticle(effectName, NULL_VECTOR);
	ModifyEntityAttach(particle, client, attachTo);
	
	return particle;
}

stock AttachedThrowAwayParticle(const client, const String:effectName[], const String:attachTo[], const Float:lifetime)
{	
	new particle = CreateW3SParticle(effectName, NULL_VECTOR);
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

stock AttachLight(const client, const String:color[], const String:style[], const Float:distance, const String:attachTo[])
{	
	new light = CreateW3SLight(NULL_VECTOR, color, style, distance);
	ModifyEntityAttach(light, client, attachTo);
	
	return light;
}

stock AttachedThrowAwayLight(const client, const String:color[], const String:style[], const Float:distance, const String:attachTo[], const Float:lifetime)
{	
	new light = CreateW3SLight(NULL_VECTOR, color, style, distance);
	ModifyEntityAttach(light, client, attachTo);
	ModifyEntityAddDeathTimer(light, lifetime);
	
	return light;
}

