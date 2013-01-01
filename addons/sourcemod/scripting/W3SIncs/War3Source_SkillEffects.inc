/**
 * File: War3Source_SkillEffects.inc
 * Description: Provide effects for certain skills so they feel the same across all races
 * Author(s): War3Source Team  
 */

/** 
 * Evade incoming damage.
 * 
 * Use inside OnW3TakeDmgAllPre or OnW3TakeDmgBulletPre if the victim
 * should evade the incoming damage.
 */
stock EvadeDamage(victim, attacker)
{
	W3FlashScreen(victim, RGBA_COLOR_BLUE);
	War3_DamageModPercent(0.0);
	W3MsgEvaded(victim, attacker);
	
	if(War3_GetGame() == Game_TF)
	{
		decl Float:pos[3];
		GetClientEyePosition(victim, pos);
		pos[2] += 4.0;
		War3_TF_ParticleToClient(0, "miss_text", pos);
	}
}

/** 
 * Stock for skills that return damage, like Thorns Aura.
 * 
 * Doesn't actually return any damage, only does the effect :)
 * 
 * Note that victim is the guy getting shot and attacker the guy
 * who takes return damage.
 */
stock War3_EffectReturnDamage(victim, attacker, damage, skill)
{
	new beamSprite = War3_PrecacheBeamSprite();
	new haloSprite = War3_PrecacheHaloSprite();
	
	decl Float:f_AttackerPos[3];
	decl Float:f_VictimPos[3];
	
	GetClientAbsOrigin(attacker, f_AttackerPos);
	GetClientAbsOrigin(victim, f_VictimPos);
	
	f_AttackerPos[2] += 35.0;
	f_VictimPos[2] += 40.0;
	
	TE_SetupBeamPoints(f_AttackerPos, f_VictimPos, beamSprite, beamSprite, 0, 45, 0.4, 10.0, 10.0, 0, 0.5, {255, 35, 15, 255}, 30);
	TE_SendToAll();
	
	f_VictimPos[0] = f_AttackerPos[0];
	f_VictimPos[1] = f_AttackerPos[1];
	f_VictimPos[2] = 80.0 + f_AttackerPos[2];
	
	TE_SetupBubbles(f_AttackerPos, f_VictimPos, haloSprite, 35.0, GetRandomInt(6, 8), 8.0);
	TE_SendToAll();
	
	War3_PlayerTookDamageFromSkill(victim, attacker, damage, skill);
}