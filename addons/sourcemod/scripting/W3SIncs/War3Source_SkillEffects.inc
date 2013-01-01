/**
 * File: War3Source_SkillEffects.inc
 * Description: Provide effects for certain skills so they feel the same across all races
 * Author(s): Glider  
 * 
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