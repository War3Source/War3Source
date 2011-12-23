#include <sourcemod>
#include "W3SIncs/fakenpc"
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/sdkhooks"
#define NPC_THINKSPEED 0.1 //each x seconds npc will search for enemyes
#define MAXENTITY 2048//source engine definition

enum AnimationPriority
{
	Disabled=0, //currently no animation
	Normal, //just a normal priority
	High //overrides other
};

new NPCDamageBuffer[MAXNPC][2]; //holds mindamage and maxdamage
new Float:FNPCLastValidLoc[MAXNPC][3];
new Float:fNPCSpeedBuffer[MAXNPC][2]; //holds attackspeed and movement speed
new Float:fNPCRange[MAXNPC]; //holds melee range
new Float:fNPCAnimDuration[MAXNPC][3]; //holds duration for attack,move,pain
new String:NPCAnimations[MAXNPC][4][64]; //holds idle,attack,move,pain

new AnimationPriority:NPCAnimation[MAXNPC];
//new bool:InAnimation[MAXNPC];

//TODO:
//-implement last valid position thing for the npc
//-allow the fake npc's to kill each other to start merging of digimon and war3source lol xD..but you know: friendship is magic!
//-add some more npc vars to allow easy customisation
//-probably add simple sound system?
//These huge arrays are quite a good way to kill nasty ressources :s
new iNPCIndex[MAXENTITY]=-1;
new iNPCNum=0;

// Handles
new Handle:hNPCVariables;
new Handle:hOnNPCThink;
new Handle:hOnNPCMove;
new Handle:hOnNPCHitTarget;
new Handle:hOnNPCFocus;
new Handle:hOnNPCHurt;
new Handle:hOnNPCDied;
new Handle:hSpawnRagdoll;
new Handle:hLOSLength;

new Float:fNPCLoSLength=1000.0;

// Temp. Entities
new ExplosionSprite,BloodSpray,BloodDrop;

// Colission Groups
enum Collision_Group
{
	COLLISION_GROUP_NONE  = 0,
	COLLISION_GROUP_DEBRIS,			// Collides with nothing but world and static stuff
	COLLISION_GROUP_DEBRIS_TRIGGER, // Same as debris, but hits triggers
	COLLISION_GROUP_INTERACTIVE_DEB,	// Collides with everything except other interactive debris or debris
	COLLISION_GROUP_INTERACTIVE,	// Collides with everything except interactive debris or debris
	COLLISION_GROUP_PLAYER,
	COLLISION_GROUP_BREAKABLE_GLASS,
	COLLISION_GROUP_VEHICLE,
	COLLISION_GROUP_PLAYER_MOVEMENT,  // For HL2, same as Collision_Group_Player
	
	COLLISION_GROUP_NPC,			// Generic NPC group
	COLLISION_GROUP_IN_VEHICLE,		// for any entity inside a vehicle
	COLLISION_GROUP_WEAPON,			// for any weapons that need collision detection
	COLLISION_GROUP_VEHICLE_CLIP,	// vehicle clip brush to restrict vehicle movement
	COLLISION_GROUP_PROJECTILE,		// Projectiles!
	COLLISION_GROUP_DOOR_BLOCKER,	// Blocks entities not permitted to get near moving doors
	COLLISION_GROUP_PASSABLE_DOOR,	// Doors that the player shouldn't collide with
	COLLISION_GROUP_DISSOLVING,		// Things that are dissolving are in this group
	COLLISION_GROUP_PUSHAWAY,		// Nonsolid on client and server, pushaway in player code

	COLLISION_GROUP_NPC_ACTOR,		// Used so NPCs in scripts ignore the player.

	LAST_SHARED_COLLISION_GROUP
};

public Plugin:myinfo = 
{
	name = "WCX - Fake NPC",
	author = "DonRevan",
	description = "Basic War3Source NPC Engine",
	version = FAKENPC_VERSION,
	url = "http://wcs-lagerhaus.de"
}

public bool:InitNativesForwards()
{
	hOnNPCThink=CreateGlobalForward("OnNPCThink",ET_Event,Param_Cell);
	hOnNPCMove=CreateGlobalForward("OnNPCMove",ET_Hook,Param_Cell,Param_Float,Param_Array,Param_Array);
	hOnNPCHitTarget=CreateGlobalForward("OnNPCHitTarget",ET_Hook,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Float);
	hOnNPCFocus=CreateGlobalForward("OnNPCFocusTarget",ET_Hook,Param_Cell,Param_Cell);
	hOnNPCHurt=CreateGlobalForward("OnNPCHurt",ET_Hook,Param_Cell,Param_Cell,Param_FloatByRef);
	hOnNPCDied=CreateGlobalForward("OnNPCDied",ET_Hook,Param_Cell,Param_Cell);
	CreateNative("War3_CreateFakeNPC",W3Native_CreateNPC);
	CreateNative("War3_GetNPCIndex",W3Native_GetNPCIDFromIndex);
	CreateNative("War3_SetOwner",W3Native_SetNPCOwner);
	CreateNative("War3_GetOwner",W3Native_GetNPCOwner);
	CreateNative("War3_SetNPCStrength",W3Native_SetNPCDMG);
	CreateNative("War3_GetNPCStrength",W3Native_GetNPCDMG);
	CreateNative("War3_SetNPCAnimation",W3Native_SetNPCSequence);
	CreateNative("War3_SetNPCMaxRange",W3Native_SetNPCRange);
	CreateNative("War3_GetNPCMaxRange",W3Native_GetNPCRange);
	CreateNative("War3_SetNPCSpeed",W3Native_SetNPCSpeed);
	CreateNative("War3_GetNPCSpeed",W3Native_GetNPCSpeed);	
	return true;
}

public OnMapStart() 
{
	ExplosionSprite = PrecacheModel("sprites/floorfire4_.vmt");
	BloodSpray = PrecacheModel("sprites/bloodspray.vmt");
	BloodDrop = PrecacheModel("sprites/blood.vmt");
}

public OnPluginStart() {
	hSpawnRagdoll=CreateConVar("war3_npcragdoll","1","If non-zero there will be corpses once a NPC is killed.");
	hLOSLength=CreateConVar("war3_npclos","1000.0","Determines how far the NPC can \"look\" for enemyes.");
	hNPCVariables=CreateArray(); //array position == npc index
	HookEvent("round_start",OnRoundStart);
	HookConVarChange(hLOSLength, OnLOSMaxChanged);
}

public OnPluginStop() {
	UnhookEvent("round_start",OnRoundStart);
	UnhookConVarChange(hLOSLength, OnLOSMaxChanged);
	if(hNPCVariables!=INVALID_HANDLE) {
		CloseHandle(hNPCVariables);
	}
}
/// #############################################
/// #########  NPC Natives ##################
/// ##############################################
public W3Native_CreateNPC(Handle:plugin,numParams) {
	decl Float:fPos[3],iHealth,iTeam,String:sName[32],String:sAnim[32],String:sModel[32],bool:bTeamcolor;
	iHealth = GetNativeCell(1);
	iTeam = GetNativeCell(2);
	GetNativeArray(3, fPos, 3);
	GetNativeString(4, sName, sizeof(sName));
	GetNativeString(5, sAnim, sizeof(sAnim));
	GetNativeString(6, sModel, sizeof(sModel));
	bTeamcolor = GetNativeCell(7);
	if(iHealth>0) {
		if(!TR_PointOutsideWorld(fPos)) {
			if(strlen(sName)>0) {
				if(strlen(sModel)>0) {
					new entity = CreateNPC(iHealth,iTeam,fPos,sName,sAnim,sModel,bTeamcolor);
					if(entity>0) return entity;
					else return ThrowNativeError(1,"Could not create a NPC!");
				}
				else return ThrowNativeError(1,"Invalid model was given!");
			}
			else return ThrowNativeError(1,"You must pass a valid NPC name!");
		}
		else return ThrowNativeError(1,"Passed origin is outside of the world!");
	}
	else return ThrowNativeError(1,"Health must be greater than zero!");
}

public W3Native_GetNPCIDFromIndex(Handle:plugin,numParams) {
	decl npc_ent;
	npc_ent = GetNativeCell(1);
	if(IsValidNPC(npc_ent)) {
		return NPCVars_GetNum(npc_ent);
	}
	else return ThrowNativeError(1,"Entity(%i) is not a Fake NPC",npc_ent);
}

public W3Native_SetNPCOwner(Handle:plugin,numParams) {
	new npc_ent = GetNativeCell(1);
	new iOwner = GetNativeCell(2);
	if(IsValidNPC(npc_ent)) { //since this value is automatic set false if it get's destroyed this can be used as a validation
		if(ValidPlayer(iOwner,false)) {
			SetOwner(npc_ent,iOwner);
			return 1;
		}
		else return ThrowNativeError(1,"Passed Player Index(%i) is not a valid Player!",iOwner);
	}
	else return ThrowNativeError(1,"Passed Entity Index(%i) is not a valid NPC!",npc_ent);
}

public W3Native_GetNPCOwner(Handle:plugin,numParams) {
	new npc_ent = GetNativeCell(1);
	if(IsValidNPC(npc_ent)) {
		return GetOwner(npc_ent);
	}
	else return ThrowNativeError(1,"Passed Entity Index(%i) is not a valid NPC!",npc_ent);
}

public W3Native_SetNPCDMG(Handle:plugin,numParams) {
	new npc_ent = GetNativeCell(1);
	new iMinDamage = GetNativeCell(2);
	new iMaxDamage = GetNativeCell(3);
	if(IsValidNPC(npc_ent)) { //since this value is automatic set false if it get's destroyed this can be used as a validation
		if(iMaxDamage>=iMinDamage) {
			decl DamageArray[2];
			DamageArray[0]=iMinDamage,DamageArray[1]=iMaxDamage;
			NPCVars_SetDamageArray(NPCVars_GetNum(npc_ent), DamageArray);
			return 1;
		}
		else return ThrowNativeError(1,"MaxDamage(%i) must be greater than MinDamage(%i)",iMaxDamage,iMinDamage);
	}
	else return ThrowNativeError(1,"Passed Entity Index(%i) is not a valid NPC!",npc_ent);
}

public W3Native_GetNPCDMG(Handle:plugin,numParams) {
	new npc_ent = GetNativeCell(1);
	new NPCDamage:num=GetNativeCell(2);
	if(IsValidNPC(npc_ent)) { //since this value is automatic set false if it get's destroyed this can be used as a validation
		//if(num==NPC_MINDAMAGE||num==NPC_MAXDAMAGE) {
		decl DamageArray[2];
		NPCVars_GetDamageArray(NPCVars_GetNum(npc_ent), DamageArray);
		return DamageArray[num];
	}
	else return ThrowNativeError(1,"Passed Entity Index(%i) is not a valid NPC!",npc_ent);
}

public W3Native_SetNPCSpeed(Handle:plugin,numParams) {
	new npc_ent = GetNativeCell(1);
	new NPCSpeed:num = GetNativeCell(2);
	new Float:fSpeed = GetNativeCell(3);
	if(IsValidNPC(npc_ent)) { //since this value is automatic set false if it get's destroyed this can be used as a validation
		decl NPCIndex,Float:fSpeedArray[2];
		NPCIndex=NPCVars_GetNum(npc_ent);
		NPCVars_GetSpeedArray(NPCIndex, fSpeedArray);
		fSpeedArray[num]=fSpeed;
		NPCVars_SetSpeedArray(NPCIndex, fSpeedArray);
		return 1;
	}
	else return ThrowNativeError(1,"Passed Entity Index(%i) is not a valid NPC!",npc_ent);
}

public W3Native_GetNPCSpeed(Handle:plugin,numParams) {
	new npc_ent = GetNativeCell(1);
	new NPCSpeed:num = GetNativeCell(2);
	if(IsValidNPC(npc_ent)) { //since this value is automatic set to false if it get's destroyed this can be used as a validation
		decl Float:fSpeedArray[2];
		NPCVars_GetSpeedArray(NPCVars_GetNum(npc_ent), fSpeedArray);
		return _:fSpeedArray[num];//return float
	}
	else return ThrowNativeError(1,"Passed Entity Index(%i) is not a valid NPC!",npc_ent);
}


public W3Native_SetNPCRange(Handle:plugin,numParams) {
	new npc_ent = GetNativeCell(1);
	new Float:fRange = GetNativeCell(2);
	if(IsValidNPC(npc_ent)) { //since this value is automatic set false if it get's destroyed this can be used as a validation
		NPCVars_SetMaxRange(NPCVars_GetNum(npc_ent),fRange);
		return 1;
	}
	else return ThrowNativeError(1,"Passed Entity Index(%i) is not a valid NPC!",npc_ent);
}

public W3Native_GetNPCRange(Handle:plugin,numParams) {
	new npc_ent = GetNativeCell(1);
	if(IsValidNPC(npc_ent)) { //since this value is automatic set false if it get's destroyed this can be used as a validation{
		return _:NPCVars_GetMaxRange(NPCVars_GetNum(npc_ent));//returns a float pointing value
	}
	else return ThrowNativeError(1,"Passed Entity Index(%i) is not a valid NPC!",npc_ent);
}

public W3Native_SetNPCSequence(Handle:plugin,numParams) {
	new npc_ent = GetNativeCell(1);
	new iSequence = GetNativeCell(2);
	new Float:fDuration = GetNativeCell(3);
	decl String:buffer[32];
	GetNativeString(4, buffer, sizeof(buffer));
	if(IsValidNPC(npc_ent)) { //since this value is automatic set false if it get's destroyed this can be used as a validation
		if(IsValidSequence(iSequence)) {
			if(strlen(buffer)>0) {
				decl varindex,Float:DurationArray[3];
				varindex = NPCVars_GetNum(npc_ent);
				NPCVars_SetAnimBySequence(varindex, iSequence, buffer);
				NPCVars_GetDurationArray(varindex, DurationArray);
				DurationArray[iSequence-1]=fDuration;
				NPCVars_SetDurationArray(varindex, DurationArray, iSequence-1);
				return 1;
			}
			else return ThrowNativeError(1,"Given animation string is invalid!");
		}
		else return ThrowNativeError(1,"Sequence Index(%i) is not valid!",iSequence);
	}
	else return ThrowNativeError(1,"Passed Entity Index(%i) is not a valid NPC!",npc_ent);
}

/// #############################################
/// <#########  NPC Functions ##################>
/// ##############################################
stock bool:IsValidNPC(const iEntityIndex) {
	if(iEntityIndex>=0 && iNPCIndex[iEntityIndex]>=0) {
		return true;
	}
	return false;
}
stock bool:IsValidSequence(const iSequence) {
	if(iSequence <= 3 && iSequence > 0) { //smaller-OR-equal 3 and higher than 0 is a valid seq since we have 4 sequences(including zero)
		return true;
	}
	return false;
}
new iOwnerBuffer[MAXNPC]; //used to avoid tons of set/get offset things
stock SetOwner(const iEntityIndex,const iClient,bool:bUseBuffer=true) {
	SetEntPropEnt(iEntityIndex, Prop_Send, "m_hOwnerEntity", iClient);
	//Is that entity a NPC and are we allowed to use that buffer?
	if(IsValidNPC(iEntityIndex) && bUseBuffer) {
		//Updates the Buffer
		iOwnerBuffer[NPCVars_GetNum(iEntityIndex)]=iClient;
	}
}
stock GetOwner(const iEntityIndex,bool:bUseBuffer=true) {
	decl iOwner
	if(IsValidNPC(iEntityIndex) && bUseBuffer) {
		//Maybe the user is in that owner buffer so we don't need to call GetEntPropEnt
		iOwner=iOwnerBuffer[NPCVars_GetNum(iEntityIndex)];
	}
	if(!ValidPlayer(iOwner,false)) //probably the buffer is outdated or something different - just some safety
	iOwner=GetEntPropEnt(iEntityIndex, Prop_Send, "m_hOwnerEntity");
	return iOwner;
}
//Clears the Owner Buffer for the given Fake NPC index
stock ClearBuffer(const npc_index) {
	iOwnerBuffer[npc_index]=-1;
}
stock SetTeam(const iEntityIndex,iTeamIndex) {SetEntProp(iEntityIndex, Prop_Send, "m_iTeamNum", iTeamIndex);}
stock GetTeam(const iEntityIndex) {return GetEntProp(iEntityIndex, Prop_Data, "m_iTeamNum");}
stock GetEntityOrigin(const iEntityIndex,Float:vecOrigin[3]) {GetEntPropVector(iEntityIndex, Prop_Send, "m_vecOrigin", vecOrigin);}
stock GetEntityAngles(const iEntityIndex,Float:vecAngles[3]) {GetEntPropVector(iEntityIndex, Prop_Send, "m_angRotation" , vecAngles);}
stock SetEntityAimToClient( edict, target) {
	decl Float:spos[3],  Float:epos[3], Float:vecles[3], Float:angles[3];
	GetEntPropVector(edict, Prop_Send, "m_vecOrigin", spos);
	GetClientAbsOrigin( target, epos );
	SubtractVectors( epos, spos, vecles );
	GetVectorAngles( vecles, angles );
	angles[2] = 0.0; //ignore the z-axsis
	TeleportEntity( edict, NULL_VECTOR, angles, NULL_VECTOR );
}
stock CopyVector(Float:fSource[3],Float:fTarget[3]) {
	for (new i=0; i<3; i++)
	{
		fTarget[i]=fSource[i];
	}
}
new Float:fLastHit[MAXPLAYERS];
public bool:NPCAttack(iEntityIndex,iVictim,iOwner,iMinDamage,iMaxDamage,Float:fNPCAttackSpeed)
{
	if(iEntityIndex>0) {
		if(fLastHit[iVictim]<GetGameTime()-fNPCAttackSpeed)
		{
			decl String:classname[32],String:buffer[32],NPCIndex, iEnt, damage, Float:fAnimDuration[3];
			damage = GetRandomInt(iMinDamage,iMaxDamage);
			Call_StartForward(hOnNPCHitTarget);
			Call_PushCell(iEntityIndex);
			Call_PushCell(iVictim);
			Call_PushCell(iOwner);
			Call_PushCell(damage);
			Call_PushFloat(fNPCAttackSpeed);
			Call_Finish();
			NPCIndex=NPCVars_GetNum(iEntityIndex);
			NPCVars_GetAnimBySequence(NPCIndex, SEQUENCE_ATTACK, buffer, sizeof(buffer));
			NPCVars_GetDurationArray(NPCIndex, fAnimDuration);
			NPCAnimate(iEntityIndex,buffer,AnimationPriority:High,fAnimDuration[1]);
			GetEdictClassname(iEntityIndex, classname, sizeof(classname));		
			W3FlashScreen( iVictim,RGBA_COLOR_RED,0.8,_,FFADE_IN);			
			SetEntityAimToClient(iEntityIndex, iVictim);			
			fLastHit[iVictim]=GetGameTime();
			iEnt = CreateEntityByName("env_blood");
			if(DispatchSpawn(iEnt)) {
				DispatchKeyValue(iEnt, "spawnflags", "29");
				DispatchKeyValue(iEnt, "amount", "850");
				DispatchKeyValue(iEnt, "spraydir", "-90");
				DispatchKeyValue(iEnt, "color", "0");
				AcceptEntityInput(iEnt, "EmitBlood", iVictim);
				AcceptEntityInput(iEnt, "Kill");
			}
			return War3_DealDamage(iVictim, damage, iOwner, DMG_BULLET, classname, _, W3DMGTYPE_PHYSICAL);
		}
	}
	return false;
}
//actualy moves the npc
public bool:NPCSubmitMove(const iEntityIndex,Float:StartPos[3],Float:TargetPos[3],Float:fStepsize) {
	decl bool:bChanged;
	Call_StartForward(hOnNPCMove);
	Call_PushCell(iEntityIndex);
	Call_PushFloat(fStepsize);
	Call_PushArrayEx(StartPos, 3, SM_PARAM_COPYBACK);
	Call_PushArrayEx(TargetPos, 3, SM_PARAM_COPYBACK);
	Call_Finish();
	//if (value == Plugin_Stop || value==Plugin_Handled)
	//	return false;
	for (new ax=0; ax<2; ax++)
	{
		if(StartPos[ax] < TargetPos[ax]) {
			StartPos[ax]+=fStepsize;
			bChanged=true;
		}
		else if(StartPos[ax] > TargetPos[ax]) {
			StartPos[ax]-=fStepsize;
			bChanged=true;
		}
	}
	//some special movement(moves down)
	if(StartPos[2] > TargetPos[2]) {
		StartPos[2]-=fStepsize;
		bChanged=true;
	}
	if(bChanged) {
		TeleportEntity(iEntityIndex, StartPos, NULL_VECTOR, NULL_VECTOR);
	}
	return bChanged;
}

//returns true if something was hit, false otherwhise
public bool:NPCTraceRoute(const iEntityIndex,Float:fNPCMaxSpeed,Float:StartPos[3],Float:TargetPos[3],bool:bMove) {
	decl bool:did_hit, i, Float:fTempNPC[3],Float:fTempEnemy[3];
	did_hit = true;
	CopyVector(StartPos,fTempNPC);
	CopyVector(TargetPos,fTempEnemy);
	for (i=0; i<5; i++) //try to find a valid route(directly) 4 times in a row(heigth = 20->80)..
	{
		fTempNPC[2]+=20;
		fTempEnemy[2]+=20;
		TR_TraceRayFilter(fTempNPC, fTempEnemy, CONTENTS_SOLID, RayType_EndPoint, TR_EmptyFilter, 0);
		if (!TR_DidHit(INVALID_HANDLE)) {
			if(bMove) { //moving is enabled.. do some stuff!
				NPCSubmitMove(iEntityIndex,StartPos,TargetPos,fNPCMaxSpeed);
			}
			did_hit=false;
			break;//abort tha loop
		}
	}
	if(did_hit==true) { //Hm still not found.. try something other..
		/*first reset our directly route stuff
		fTempNPC[2]-=20*i;
		fTempEnemy[2]-=20*i;
		if(fTempNPC[0]!=StartPos[0] && fTempNPC[1]!=StartPos[1] && fTempNPC[2]!=StartPos[2]) {
			DP("fTempNPC != StartPos");
		}
		else if(fTempEnemy[0]!=TargetPos[0] && fTempEnemy[1]!=TargetPos[1] && fTempEnemy[2]!=TargetPos[2]) {
			DP("fTempEnemy != TargetPos");
		}*/
		for (new ax=0; ax<2; ax++) //x and y axsis
		{
			//randomness rulez! if we are unable to trace that target probably the next time we can!
			StartPos[ax]+=GetRandomFloat(fNPCMaxSpeed/1.5,fNPCMaxSpeed);
			TR_TraceRayFilter(StartPos, TargetPos, CONTENTS_SOLID, RayType_EndPoint, TR_EmptyFilter, 0);
			if (!TR_DidHit(INVALID_HANDLE)) {
				if(bMove) {
					NPCSubmitMove(iEntityIndex,StartPos,TargetPos,fNPCMaxSpeed);
				}
				did_hit=false;
				break;
			}
		}
	}
	//Enough!.. we are realy persistent :d
	return did_hit; //gonna spread some bools around the world
}
//Calls the global forward and returns the result...usefull for some npc immunity
public bool:CanFocus(iEntityIndex,iTarget) {
	decl value;
	Call_StartForward(hOnNPCFocus);
	Call_PushCell(iEntityIndex);
	Call_PushCell(iTarget);
	Call_Finish(value);
	if (value == 3 || value == 4)//plugin_handled + plugin_stop
		return false;
	//PrintToServer("CanFocus called - result %i",value);
	return true;
}
stock NPCVars_GetNum(const iEntityIndexIndex) {
	return iNPCIndex[iEntityIndexIndex];
}
//Adds a entry to the FakeNPC Data Storage
stock NPCVars_AddNPC(const iIndex, const String:strIdleAnim[32]="Idle", const String:strAttackAnim[32]="", const String:strPainAnim[32]="", const String:strMoveAnim[32]="", const iDamageArray[2]={20,40}, const Float:fDurationArray[3]={0.0,0.0,0.0}, const Float:fRange=100.0, const Float:fSpeed=10.0, const Float:fNPCAttackSpeed=2.0) {
	if(hNPCVariables!=INVALID_HANDLE) {
		decl num;
		num = PushArrayCell(hNPCVariables, iIndex); //stores the entity index in that array
		NPCDamageBuffer[num][NPCDamage:MinDamage]=iDamageArray[NPCDamage:MinDamage];
		NPCDamageBuffer[num][NPCDamage:MaxDamage]=iDamageArray[NPCDamage:MaxDamage];
		fNPCSpeedBuffer[num][NPCMaxSpeed]=fSpeed;
		fNPCSpeedBuffer[num][NPCAttackSpeed]=fNPCAttackSpeed;
		fNPCRange[num]=fRange;
		NPCAnimations[num][SEQUENCE_IDLE]=strIdleAnim;
		NPCAnimations[num][SEQUENCE_ATTACK]=strAttackAnim;
		NPCAnimations[num][SEQUENCE_PAIN]=strPainAnim;
		NPCAnimations[num][SEQUENCE_MOVE]=strMoveAnim;
		return num; //returns npc index
	}
	else
	return -1;
}
//Removes a NPC by npc index
public bool:NPCVars_RemoveNPC(iIndex) {
	if(hNPCVariables!=INVALID_HANDLE && iIndex>0) {
		NPCAnimation[iIndex]=AnimationPriority:Disabled;
		new iEntityIndex = GetArrayCell(hNPCVariables, iIndex);
		if(iEntityIndex>0) {
			iNPCIndex[iEntityIndex]=-1;
			iNPCNum--; //reduce our counter by one
			RemoveFromArray(hNPCVariables, iIndex);		
		}
		return false;
	}
	return false;
}
public bool:NPCVars_SetAnimBySequence(iIndex, const iSequence, String:buffer[32]) {
	new iEntityIndex = GetArrayCell(hNPCVariables, iIndex);
	if(iEntityIndex>0) {
		//Do not bother with it if whe did not get a valid sequence either..
		if(IsValidSequence(iSequence)) {
			NPCAnimations[iIndex][iSequence]=buffer;
			return true;
		}
		return false;
	}
	return false;
}
stock bool:NPCVars_GetAnimBySequence(iIndex, const iSequence, String:buffer[], const maxsize) { //sequences: 0=idle|1=attack|2=pain
	new iEntityIndex = GetArrayCell(hNPCVariables, iIndex);
	if(iEntityIndex > 0) {
		if(IsValidSequence(iSequence)) {
			strcopy(buffer, maxsize, NPCAnimations[iIndex][iSequence]);
		}
		return false;
	}
	return false;
}
public Float:NPCVars_GetMovementSpeed(iIndex) {
	new iEntityIndex = GetArrayCell(hNPCVariables, iIndex);
	if(iEntityIndex > 0) {
		return fNPCSpeedBuffer[iIndex][NPCMaxSpeed];
	}
	return 0.0;
}
public Float:NPCVars_GetAttackSpeed(iIndex) {
	new iEntityIndex = GetArrayCell(hNPCVariables, iIndex);
	if(iEntityIndex > 0) {
		return fNPCSpeedBuffer[iIndex][NPCAttackSpeed];
	}
	return 0.0;
}
public bool:NPCVars_SetSpeedArray(iIndex, Float:fSpeed[2]) {
	new iEntityIndex = GetArrayCell(hNPCVariables, iIndex);
	if(iEntityIndex > 0) {
		fNPCSpeedBuffer[iIndex][NPCMaxSpeed]=fSpeed[NPCMaxSpeed];
		fNPCSpeedBuffer[iIndex][NPCAttackSpeed]=fSpeed[NPCAttackSpeed];
		return true;
	}
	return false;
}
stock bool:NPCVars_GetSpeedArray(iIndex, Float:SpeedArray[2]) {
	new iEntityIndex = GetArrayCell(hNPCVariables, iIndex);
	if(iEntityIndex > 0) {
		SpeedArray[NPCMaxSpeed]=fNPCSpeedBuffer[iIndex][NPCMaxSpeed];
		SpeedArray[NPCAttackSpeed]=fNPCSpeedBuffer[iIndex][NPCAttackSpeed];
		return true;
	}
	return false;
}
stock bool:NPCVars_GetLastValidLocation(iIndex, Float:vecOrigin[3]) {
	new iEntityIndex = GetArrayCell(hNPCVariables, iIndex);
	if(iEntityIndex > 0) {
		vecOrigin[0]=FNPCLastValidLoc[iIndex][0];
		vecOrigin[1]=FNPCLastValidLoc[iIndex][1];
		vecOrigin[2]=FNPCLastValidLoc[iIndex][2];
		return true;
	}
	return false;
}
stock bool:NPCVars_GetDamageArray(iIndex, DamageArray[2]) {
	new iEntityIndex = GetArrayCell(hNPCVariables, iIndex);
	if(iEntityIndex > 0) {
		DamageArray[NPCDamage:MinDamage]=NPCDamageBuffer[iIndex][NPCDamage:MinDamage];
		DamageArray[NPCDamage:MaxDamage]=NPCDamageBuffer[iIndex][NPCDamage:MaxDamage];
		return true;
	}
	return false;
}
public bool:NPCVars_SetDamageArray(iIndex, DamageArray[2]) {
	new iEntityIndex = GetArrayCell(hNPCVariables, iIndex);
	if(iEntityIndex > 0) {
		NPCDamageBuffer[iIndex][NPCDamage:MinDamage]=DamageArray[NPCDamage:MinDamage];
		NPCDamageBuffer[iIndex][NPCDamage:MaxDamage]=DamageArray[NPCDamage:MaxDamage];
		return true;
	}
	return false;
}
stock bool:NPCVars_GetDurationArray(iIndex, Float:DurationArray[3]) {
	new iEntityIndex = GetArrayCell(hNPCVariables, iIndex);
	if(iEntityIndex > 0) {
		DurationArray[0]=fNPCAnimDuration[iIndex][0];
		DurationArray[1]=fNPCAnimDuration[iIndex][1];
		DurationArray[2]=fNPCAnimDuration[iIndex][2];
		return true;
	}
	return false;
}
public bool:NPCVars_SetDurationArray(iIndex, Float:DurationArray[3], iDimension) {
	new iEntityIndex = GetArrayCell(hNPCVariables, iIndex);
	if(iEntityIndex > 0) {
		if(iDimension==-1) {
			fNPCAnimDuration[iIndex][0]=DurationArray[0];
			fNPCAnimDuration[iIndex][1]=DurationArray[1];
			fNPCAnimDuration[iIndex][2]=DurationArray[2];
		}
		else {
			fNPCAnimDuration[iIndex][iDimension]=DurationArray[iDimension];
		}
		return true;
	}
	return false;
}
public Float:NPCVars_GetMaxRange(iIndex) {
	new iEntityIndex = GetArrayCell(hNPCVariables, iIndex);
	if(iEntityIndex > 0) {
		return fNPCRange[iIndex];
	}
	return 0.0;
}
public bool:NPCVars_SetMaxRange(iIndex, const Float:fMaxRange) {
	new iEntityIndex = GetArrayCell(hNPCVariables, iIndex);
	if(iEntityIndex > 0) {
		fNPCRange[iIndex]=fMaxRange;
		return true;
	}
	return false;
}
public CreateNPC(const iHealth,const iTeam,const Float:vecOrigin[3],const String:strName[32],const String:strIdleAnim[32],const String:strModel[32],bool:bTeamColored) {
	//Create a simple prop, that we gonna use as a npc (..later)
	new npc_ent = CreateEntityByName("prop_dynamic_override");
	if (npc_ent > 0 && IsValidEdict(npc_ent)) //valid?
	{
		decl String:entname[16];
		Format(entname, sizeof(entname), "npc_%i",npc_ent);
		//set model & other stuff
		SetEntityModel(npc_ent, strModel);
		DispatchKeyValue(npc_ent, "StartDisabled", "false");
		if (DispatchSpawn(npc_ent))
		{
			//Set the Color (if bTeamColored is true)
			if(iTeam>0 && bTeamColored) {
				if( iTeam==TEAM_CT || iTeam==TEAM_BLUE || iTeam==TEAM_INFECTED ) {
					SetEntityRenderColor(npc_ent, 120, 120, 255);
				} else {
					SetEntityRenderColor(npc_ent, 200, 120, 120);
				}
			}
			//Set the 'Damage Group' (avaible groups - 0 = POWNIE | 1=DAMAGE_NO | 2=DAMAGE_YES
			SetEntProp(npc_ent, Prop_Data, "m_takedamage", 2);
			//Set's the Solid spawnflags
			SetEntProp(npc_ent, Prop_Send, "m_usSolidFlags", 152);
			//Move NPC to target Position
			TeleportEntity(npc_ent, vecOrigin, NULL_VECTOR, NULL_VECTOR);
			//Set targetname(=name used for any input to the ent) and classname(=base entity name)
			DispatchKeyValue(npc_ent, "targetname", entname);
			DispatchKeyValue(npc_ent, "classname", strName);
			//Collision Group related changes 
			SetEntProp(npc_ent, Prop_Data, "m_MoveCollide", 1);
			SetEntProp(npc_ent, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_NPC); //use special npc collision group..
			//Sets the Team Index of the target NPC
			SetTeam(npc_ent, iTeam);
			//Sets the Owner of the NPC as invalid(un-owned)
			SetOwner(npc_ent, 0);
			//Only set the idle Animation if we want it! (empty string = no animating stuff around here!)
			if(strlen(strIdleAnim)>0) {
				SetVariantString(strIdleAnim);
				AcceptEntityInput(npc_ent, "SetAnimation", -1, -1, 0);
			}
			//Sets the Health of the NPC
			SetEntProp(npc_ent, Prop_Data, "m_iHealth", iHealth);
			//Setting up the NPC in our adt array with def variables
			new index=NPCVars_AddNPC(npc_ent, strIdleAnim);
			if(index>=0) {
				//Mark the entity as a npc
				iNPCIndex[npc_ent]=index;
				iNPCNum++;
				//Enable thinking
				CreateTimer(NPC_THINKSPEED, Timer_OnNPCThink, npc_ent, TIMER_REPEAT);
				//Switch on our TakeDamage listener
				SDKHook(npc_ent, SDKHook_OnTakeDamage, Callback_OnNPCDamaged);
				//Hook the OnBreak output
				HookSingleEntityOutput(npc_ent, "OnBreak", Callback_OnNPCKilled, true);
				//Return's the entity index
				return npc_ent;
			}
			return -1;
		}
		return -1;
	}
	return -1;
}
//Called when the NPC got killed
public Callback_OnNPCKilled(const String:output[], caller, activator, Float:delay)
{
	if(IsValidNPC(caller)) {
		if(GetConVarBool(hSpawnRagdoll)) {
			//Spawn a corpse :o
			new Ragdoll = CreateEntityByName("prop_ragdoll"); 
			if(IsValidEntity(Ragdoll))
			{
				decl String:ModelName[128];
				GetEntPropString(caller, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));
				if(strlen(ModelName)>0) {
					decl Float:Position[3],Float:Angles[3];
					GetEntityOrigin(caller,Position);
					GetEntityAngles(caller,Angles);
					SetEntityModel(Ragdoll,ModelName);
					SetEntityMoveType(Ragdoll, MOVETYPE_VPHYSICS);
					SetEntProp(Ragdoll, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_NPC);
					//SetEntProp(Ragdoll, Prop_Data, "m_usSolidFlags", 16); 
					DispatchSpawn(Ragdoll); 
					Position[2]+=35;
					//using the explosion as some sort of "smoke" because it looks realy shitty when spawning just a ragdoll..
					W3SetupExplosion(thisRaceID, Position, ExplosionSprite, 1.0, 0, TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NODLIGHTS, 0 , 0);
					W3SendToAll();
					TeleportEntity(Ragdoll, Position, Angles, NULL_VECTOR);
				}
			}
			//Fire the forward
			decl value;
			Call_StartForward(hOnNPCDied);
			Call_PushCell(caller);
			Call_PushCell(activator);
			Call_Finish(_:value);
		}
	}
}
//Called when the NPC aquires damage
public Action:Callback_OnNPCDamaged(entity, &attacker, &inflictor, &Float:damage, &damagetype) {
	if(IsValidNPC(entity)) {
		Call_StartForward(hOnNPCHurt);
		Call_PushCell(entity);
		Call_PushCell(attacker);
		Call_PushFloatRef(damage);
		Call_Finish();
		//if (value != Plugin_Stop && value!=Plugin_Handled) {
		decl Float:Position[3],Float:Angles[3];
		GetEntityOrigin(entity,Position);
		GetEntityAngles(entity,Angles);
		//some you-hit-npc effects
		Position[2]+=40;
		TE_SetupBloodSprite(Position, Angles, {200, 20, 20, 255}, 24, BloodSpray, BloodDrop);
		TE_SendToAll();
		decl NPCIndex,String:buffer[32],Float:fAnimDuration[3];
		NPCIndex=NPCVars_GetNum(entity);
		NPCVars_GetAnimBySequence(NPCIndex, SEQUENCE_PAIN, buffer, sizeof(buffer));
		if(strlen(buffer)>0) {
			NPCVars_GetDurationArray(NPCIndex, fAnimDuration);
			NPCAnimate(entity,buffer,AnimationPriority:Normal,fAnimDuration[1]);
		}
		//}
		//return value;
	}
	return Plugin_Continue;
}
//Called when the NPC thinks
public Action:Timer_OnNPCThink(Handle:hTimer, any:iEntityIndex) {
	if(iEntityIndex>0 && IsValidEntity(iEntityIndex) && IsValidNPC(iEntityIndex)) {
		decl value,iTeam,NPCIndex,ClosestTarget,Float:fDistance,Float:fClosestDistance,Float:fSpeedArray[2],Float:fPos[3];
		Call_StartForward(hOnNPCThink);
		Call_PushCell(iEntityIndex);
		Call_Finish(_:value);
		//if (value != Plugin_Continue)
		//	return;
		//Retrieve the Pet Owner
		new client = GetOwner(iEntityIndex);
		//Get the absolute NPC Position
		GetEntityOrigin(iEntityIndex,fPos);
		//Find NPC's MaxRange in the npc data storage!
		fClosestDistance=fNPCLoSLength;
		if(client>0) { //Override the team index is a client is given!
			iTeam=GetClientTeam(client);
		}
		else //Get NPC team instead..
			iTeam=GetTeam(iEntityIndex);
		NPCIndex=NPCVars_GetNum(iEntityIndex);
		NPCVars_GetSpeedArray(NPCIndex,fSpeedArray);
		//At first we need to find the nearest player..
		for (new i = 1; i <= MaxClients; i++) {
			//Is the index a possible target for me?
			if(ValidPlayer(i,true) && client!=i && iTeam!=GetClientTeam(i)) {
				//Where he is?
				decl Float:fTargetPos[3];
				GetClientAbsOrigin(i, fTargetPos);
				//Gonna ask sourcemod how _long_ it takes to move to him..
				fDistance = GetVectorDistance(fPos, fTargetPos);
				//Should I move to him?
				if (fDistance < fClosestDistance) {
					//Are we allowed to focus him?
					if(CanFocus(iEntityIndex,i)) {
						//Hum.. Is there some solid content that cannot be ignored by some point of lazyness?
						if(!NPCTraceRoute(0,fSpeedArray[0],fPos,fTargetPos,false)) {
							//Found! Mark him as the best target(for now..)
							ClosestTarget = i;
							fClosestDistance = fDistance;
						}
					}
				}
			}
		}
		if(ValidPlayer(ClosestTarget,true)) { //Is there any valid target?
			decl Float:fFinalDistance,Float:fMaxRange,Float:fPos2[3];
			fMaxRange=NPCVars_GetMaxRange(NPCVars_GetNum(iEntityIndex));
			GetClientAbsOrigin(ClosestTarget, fPos2);
			SetEntityAimToClient(iEntityIndex, ClosestTarget);
			fFinalDistance=GetVectorDistance(fPos, fPos2);
			if(fFinalDistance<=fMaxRange) {
				decl DamageConfig[2];
				NPCVars_GetDamageArray(NPCIndex, DamageConfig);
				NPCAttack(iEntityIndex,ClosestTarget,client,DamageConfig[0],DamageConfig[1],fSpeedArray[1]);
				
			}
			else {
				decl Float:fAnimDuration[3],String:buffer[32];
				NPCTraceRoute(iEntityIndex, fSpeedArray[0] ,fPos, fPos2, true);
				NPCVars_GetAnimBySequence(NPCIndex, SEQUENCE_MOVE, buffer, sizeof(buffer));
				NPCVars_GetDurationArray(NPCIndex, fAnimDuration);
				NPCAnimate(iEntityIndex,buffer,AnimationPriority:Normal,fAnimDuration[2]);
			}
		}
	}	
	else {
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public bool:TR_EmptyFilter(entity, mask, any:data) {
	/* Fetch everything so just return false!
	 * returning true will mark as trace as 'DidHit',
	 * but since we are not filtering any props/entities
	 * we do not check a self hit and just return false..
	*/
	return false;
}

//Remove entity from array
//NOTE: This also allows you to safetly kill the entity via acceptinput or anything similar ;)
public OnEntityDestroyed(entity) {
	//PrintToServer("OnEntityDestroyed(%d)",entity);
	//Was the removed entity a npc?
	if(entity>=0 && IsValidNPC(entity)) {
		//Declare our variable
		decl npc_index;
		//Get the NPC index
		npc_index = NPCVars_GetNum(entity);
		//clear our owner buffer
		ClearBuffer(npc_index);
		//Remove our npc from the array
		NPCVars_RemoveNPC(npc_index);
	}
}

//ConVarChangeHook: Do this - so we do not need to obtain a new cvar value every time
public OnLOSMaxChanged(Handle:cvar, const String:oldValue[], const String:newValue[]) 
{ 
	new Float:value = StringToFloat(newValue);
	if(value>0.0)
	fNPCLoSLength=value;
}

//Since entities get's removed on round_start.. also clear that npc var array
public OnRoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(hNPCVariables!=INVALID_HANDLE)
	ClearArray(hNPCVariables);
	iNPCNum=0;
}

stock NPCAnimate(entity,const String:animation[],AnimationPriority:Priority,Float:duration=0.0)
{
	if(IsValidNPC(entity)&&Priority!=AnimationPriority:Disabled)
	{
		decl npc_index, bool:ignoreAnimation, bool:inAnimation;
		npc_index = NPCVars_GetNum(entity);
		if(Priority==AnimationPriority:High)
			ignoreAnimation=true;
		if(NPCAnimation[npc_index]!=AnimationPriority:Disabled)
			inAnimation=true;
		if(ignoreAnimation==true || inAnimation==false) {
			//DP("[NPCAnimate] Playing Sequence:'%s'",animation);
			if(strlen(animation)>0) {
				SetVariantString(animation);
				AcceptEntityInput(entity, "SetAnimation", -1, -1, 0);
				if(duration>0.0) {
					NPCAnimation[npc_index]=Priority;
					CreateTimer(duration, Timer_IdleAnim, entity);
				}
			}
			else {
				PrintToServer("[FakeNPC] Error: Invalid animation name passed");
			}
		}
	}
}
public Action:Timer_IdleAnim( Handle:timer, any:caller )
{
	if(IsValidEntity(caller) && IsValidNPC(caller)) {
		new npc_index = NPCVars_GetNum(caller);
		NPCAnimation[npc_index]=AnimationPriority:Disabled;
		decl String:buffer[32];
		NPCVars_GetAnimBySequence(npc_index, 0, buffer, sizeof(buffer));
		if(strlen(buffer)==0) {
			strcopy(buffer,sizeof(buffer),"Idle");
		}
		//DP("[NPCAnimate] Idle-Playing Sequence:'%s'",buffer);
		SetVariantString(buffer);
		AcceptEntityInput(caller, "SetAnimation", -1, -1, 0);
	}
}