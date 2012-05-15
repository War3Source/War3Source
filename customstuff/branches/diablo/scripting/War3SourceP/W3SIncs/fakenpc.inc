#define FAKENPC_VERSION "0.5"
#define MAXNPC 16//max npc per time
// damage enumeration
enum NPCDamage
{
	MinDamage=0,
	MaxDamage
};
enum NPCSpeed
{
	MoveSpeed=0,
	AttackSpeed
};
// Speed Definitions
#define NPCMaxSpeed 0
#define NPCAttackSpeed 1
// Sequence Definitions
#define SEQUENCE_IDLE 0
#define SEQUENCE_ATTACK 1
#define SEQUENCE_PAIN 2
#define SEQUENCE_MOVE 3

//Used to spawn a Fake NPC
native War3_CreateFakeNPC(health,team,Float:fPos[3],String:NPCName[32],String:IdleAnimation[32],String:ModelPath[32],bool:bTeamColored=true);

//Returns the internal NPC index by entity index
native War3_GetNPCIndex(entity);

//Changes the owner of the Entity/NPC
native War3_SetOwner(entity, owner);

//Returns the owner of the Entity/NPC
native War3_GetOwner(entity);

//Mods NPC Strength(=damage)
native War3_SetNPCStrength(entity,MinDamage,MaxDamage);

//Returns NPC Min OR Max Damage
native War3_GetNPCStrength(entity,NPCDamage:value);

//Set's the NPC's Animation Sequence (Look at SEQUENCE_ definitions)
native War3_SetNPCAnimation(entity,iSequence,Float:fAnimDuration,String:AnimationName[32]);

//Set's the NPC melee attack range
native War3_SetNPCMaxRange(entity,Float:fRange);

//Returns the NPC ma-range
native Float:War3_GetNPCMaxRange(entity);

//Mods specific NPC Speed(stepsize!)
native War3_SetNPCSpeed(entity,NPCSpeed:value,Float:fSpeedValue);

//Returns specific NPC Speed
native Float:War3_GetNPCSpeed(entity,NPCSpeed:value);

//Called when a NPC starts thinking
forward OnNPCThink(entity);

//Called when the NPC moves
forward OnNPCMove(entity,Float:fStepSize,Float:fStartPos[3],Float:fEndPos[3]);

//Called when the NPC hurts someone
forward OnNPCHitTarget(entity,victim,owner,damage,Float:fAtkSpeed);

//Called when the NPC attempts to focus someone(can be blocked with plugin_Handled etc.)
forward Action:OnNPCFocusTarget(entity,target);

//Called when the NPC is damaged
forward OnNPCHurt(entity,attacker,&Float:damage);

//Called when a NPC got killed
forward OnNPCDied(entity,attacker);

