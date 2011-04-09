#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"


new m_OffsetClrRender;


new m_OffsetGravity[MAXPLAYERS];
new m_OffsetSpeed;

new reapplyspeed[MAXPLAYERS];

//for debuff index, see constants, its in an enum
new any:buffdebuff[MAXPLAYERS][W3Buff][MAXITEMS+MAXRACES]; ///a race may only modify a property once
//start loop for items only: i=1;i<MAXITEMS   
//start loop for races only: i=MAXITEMS;i<MAXITEMS+MAXRACES]
//buffs may be bool, float, or int
//MAXITEMS+MAXRACES is last because we usually loop through this last index

new BuffProperties[W3Buff][2];

new any:BuffCached[MAXPLAYERS][W3Buff];// instead of looping, we cache everything in the last dimension, see enum W3BuffCache

new bool:skiptest;

public Plugin:myinfo= 
{
	name="War3Source Engine 5",
	author="Ownz",
	description="Core utilities for War3Source.",
	version="1.0",
	url="http://war3source.com/"
};



public APLRes:AskPluginLoad2(Handle:myself,bool:late,String:error[],err_max)
{
	if(!InitNativesForwards())
	{
		LogError("[War3Source] There was a failure in creating the native / forwards based functions, definately halting.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateTimer(0.1,DeciSecondTimer,_,TIMER_REPEAT);
	
	InitiateBuffPropertiesArray(BuffProperties);
	
	if(War3_GetGame()==Game_TF)
	{
		m_OffsetSpeed=FindSendPropOffs("CTFPlayer","m_flMaxspeed");
	}
	else
	m_OffsetSpeed=FindSendPropOffs("CBasePlayer","m_flLaggedMovementValue");
	if(m_OffsetSpeed==-1)
	{
		PrintToServer("[War3Source] Error finding speed offset.");
	}
	
	m_OffsetClrRender=FindSendPropOffs("CBaseAnimating","m_clrRender");
	if(m_OffsetClrRender==-1)
	{
		PrintToServer("[War3Source] Error finding render color offset.");
	}
	
	RegConsoleCmd("skipbufftest",cmdskipbufftest);
	RegConsoleCmd("skipbufftestend",cmdskipbufftestend);
}
public OnPluginEnd(){
	PrintToServer("[W3S Engine] Plugin End");
}

bool:InitNativesForwards()
{
	
	CreateNative("War3_SetBuff",Native_War3_SetBuff);//for races
	CreateNative("War3_SetBuffItem",Native_War3_SetBuffItem);//foritems
	CreateNative("W3GetPhysicalArmorMulti",NW3GetPhysicalArmorMulti);//foritems
	CreateNative("W3GetMagicArmorMulti",NW3GetMagicArmorMulti);//foritems
	CreateNative("W3GetBuffHasTrue",NW3GetBuffHasTrue);//foritems
	CreateNative("W3GetBuffStacked",NW3GetBuffStacked);
	
	CreateNative("W3ResetAllBuff",NW3ResetAllBuff);
	return true;
}


public Native_War3_SetBuff(Handle:plugin,numParams)
{
	if(numParams==4) //client,race,buffindex,value
	{
		new client=GetNativeCell(1);
		new W3Buff:buffindex=GetNativeCell(2);
		new raceid=GetNativeCell(3);
		new any:value=GetNativeCell(4);
		SetBuff(client,buffindex,raceid+W3GetItemsLoaded(),value); //ofsetted
	}
}
public Native_War3_SetBuffItem(Handle:plugin,numParams) //buff is from an item
{
	if(numParams==4) //client,race,buffindex,value
	{
		new client=GetNativeCell(1);
		new W3Buff:buffindex=GetNativeCell(2);
		new itemid=GetNativeCell(3);
		new any:value=GetNativeCell(4);
		SetBuff(client,buffindex,itemid,value); //not offseted
	}
}

//stop complaining that we are returning a float!
public NW3GetPhysicalArmorMulti(Handle:plugin,numParams) {
	return _:MagicArmorMulti(GetNativeCell(1));
}

public NW3GetMagicArmorMulti(Handle:plugin,numParams) {
	
	return _:PhysicalArmorMulti(GetNativeCell(1));
}
public NW3GetBuffHasTrue(Handle:plugin,numParams) {
	//all one true bools are cached
	return _:GetBuffHasOneTrueCached(GetNativeCell(1),GetNativeCell(2)); //returns bool
}
public NW3GetBuffStacked(Handle:plugin,numParams) {
	
	return _:GetBuffStacked(GetNativeCell(1),GetNativeCell(2)); //returns float usually
}
public NW3ResetAllBuff(Handle:plugin,numParams) {
	new client=GetNativeCell(1);
	new race=GetNativeCell(2);
	
	
	for(new buffindex=0;buffindex<MaxBuffLoopLimit;buffindex++)
	{	
		
		ResetBuffParticularRaceOrItem(client,W3Buff:buffindex,W3GetItemsLoaded()+race);
	}
	
}




public Action:cmdskipbufftest(client,args){
	if(W3IsDeveloper(client)){
		skiptest=true;
		ReplyToCommand(client,"buffs will now skip");
	}
}
public Action:cmdskipbufftestend(client,args){
	if(W3IsDeveloper(client)){
		skiptest=false;
		ReplyToCommand(client,"ending buff skipping");
	}
}

public OnClientPutInServer(client){
	m_OffsetGravity[client]=FindDataMapOffs(client,"m_flGravity");
	
	//reset all buffs
	for(new buffindex=0;buffindex<MaxBuffLoopLimit;buffindex++)
	{
		ResetBuff(client,W3Buff:buffindex);
	}
}


new Float:speedBefore[MAXPLAYERS];
new Float:speedWeSet[MAXPLAYERS];

public Action:DeciSecondTimer(Handle:timer)
{
	if(!skiptest){
		// Boy, this is going to be fun.
		for(new client=1;client<=MaxClients;client++)
		{
			if(ValidPlayer(client,true))
			{
				
				new raceid=War3_GetRace(client);
				if(raceid>0)
				{
					//PrintToChatAll("sdf %d",client);
					new Float:gravity=1.0; //default
					if(!GetBuffHasOneTrueCached(client,bLowGravityDenyAll)&&!GetBuffHasOneTrueCached(client,bBuffDenyAll)) //can we change gravity?
					{
						//if(!GetBuffHasOneTrue(client,bLowGravityDenySkill)){
						new Float:gravity1=FloatMul(gravity,GetBuffMin(client,fLowGravitySkill));
						//}
						//if(!GetBuffHasOneTrue(client,bLowGravityDenyItem)){
						new Float:gravity2=FloatMul(gravity,GetBuffMin(client,fLowGravityItem));
						
						gravity=gravity1<gravity2?gravity1:gravity2;
						//}
						//gravity=; //replace
						//PrintToChat(client,"mingrav=%f",gravity);
					}
					///now lets set the grav
					if(GetEntDataFloat(client,m_OffsetGravity[client])!=gravity) ///gravity offset is somewhoe different for each person? this offset is got on PutInServer
						SetEntDataFloat(client,m_OffsetGravity[client],gravity);
					
					
					new r=255,g=255,b=255,alpha=255;
					new bool:skipinvis=false;
					
					new bestindex=-1;
					new highestvalue=0;
					new Float:settime=0.0;
					
					new limit=W3GetItemsLoaded()+War3_GetRacesLoaded();
					for(new i=0;i<=limit;i++){
						if(GetBuff(client,iGlowPriority,i)>highestvalue){
							highestvalue=GetBuff(client,iGlowPriority,i);
							bestindex=i;
							settime=Float:GetBuff(client,fGlowSetTime,i);
						}
						else if(GetBuff(client,iGlowPriority,i)==highestvalue&&highestvalue>0){ //equal priority
							if(GetBuff(client,fGlowSetTime,i)>settime){ //only if this one set it sooner
								highestvalue=GetBuff(client,iGlowPriority,i);
								bestindex=i;
								settime=Float:GetBuff(client,fGlowSetTime,i);
							}
						}
					}
					if(bestindex>-1){
						r=GetBuff(client,iGlowRed,bestindex);
						g=GetBuff(client,iGlowGreen,bestindex);
						b=GetBuff(client,iGlowBlue,bestindex);
						alpha=GetBuff(client,iGlowAlpha,bestindex);
						skipinvis=true;
					}
					
					new bool:set=false;
					if(GetPlayerR(client)!=r)
						set=true;
					if(GetPlayerG(client)!=g)
						set=true;
					if(GetPlayerB(client)!=b)
						set=true;
					//alpha set is after invis block
					if(set){
						//	PrintToChatAll("%d %d %d %d",r,g,b,alpha);
						SetPlayerRGB(client,r,g,b);
					}
					
					
					
					
					
					///invisbility!
					//PrintToChatAll("GetBuffMin(client,fInvisibility) %f %f %f ",GetBuffMin(client,fInvisibility),float(alpha),float(alpha)*GetBuffMin(client,fInvisibility));
					if(!skipinvis&&!GetBuffHasOneTrueCached(client,bInvisibilityDenyAll)&&!GetBuffHasOneTrueCached(client,bBuffDenyAll)) ///buff is not denied
					{
						new Float:falpha=1.0;
						if(!GetBuffHasOneTrueCached(client,bInvisibilityDenySkill))
						{
							falpha=FloatMul(falpha,GetBuffMin(client,fInvisibilitySkill));
							
						}
						//if(!GetBuffHasOneTrue(client,bInvisibilityDenySkillbInvisibl  ///we dont have an item deny yet
						new Float:itemalpha=GetBuffMin(client,fInvisibilityItem);
						if(falpha!=1.0){
							//PrintToChatAll("has skill invis");
							//has skill, reduce stack
							itemalpha=Pow(itemalpha,0.75);
						}
						falpha=FloatMul(falpha,itemalpha);
						
						//PrintToChatAll("%f",GetBuffMin(client,fInvisibilityItem));
						
						new alpha2=RoundFloat(       FloatMul(255.0,falpha)  ); 
						//PrintToChatAll("alpha2 = %d",alpha2);
						if(alpha2>=0&&alpha2<=255){
							alpha=alpha2;
						}
						else{
							LogError("alpha playertracking out of bounds 0 - 255");
						}
					}
					//PrintToChatAll("%d",alpha);
					if(GetPlayerAlpha(client)!=alpha)
						SetPlayerAlpha(client,alpha);
					if(GetWeaponAlpha(client)!=alpha)
						SetWeaponAlpha(client,alpha);
					
					///NEED 4 SPEED!
					///SPEED IS IN PLAYER FRAME	
				}
			}
		}
	}
}



public OnGameFrame()
{
	if(!skiptest){
		for(new client=1;client<=MaxClients;client++)
		{
			if(ValidPlayer(client,true))//&&!bIgnoreTrackGF[client])
			{
				new Float:currentmaxspeed=GetEntDataFloat(client,m_OffsetSpeed);
				if(currentmaxspeed!=speedWeSet[client]) ///SO DID engien set a new speed? copy that!! //TFIsDefaultMaxSpeed(client,currentmaxspeed)){ //ONLY IF NOT SET YET
				{	//PrintToChatAll("3");
					speedBefore[client]=currentmaxspeed;
					reapplyspeed[client]++;
				}
				
				
				
				//PrintToChat(client,"speed %f %s",currentmaxspeed, TFIsDefaultMaxSpeed(client,currentmaxspeed)?"T":"F");
				if(reapplyspeed[client]>0)
				{
					reapplyspeed[client]=0;
					///player frame tracking, if client speed is not what we set, we reapply speed
					
					//PrintToChatAll("1");
					if(War3_GetGame()==Game_TF){
						
						
						
						
						if(	speedBefore[client]>10.0){ //reapply speed, using previous cached base speed, make sure the cache isnt' zero lol 
							new Float:speedmulti=1.0;
							
							new Float:speedadd=1.0;
							if(!GetBuffHasOneTrueCached(client,bBuffDenyAll)){
								speedadd=GetBuffMax(client,fMaxSpeed);
							}
							if(GetBuffHasOneTrueCached(client,bStunned)||GetBuffHasOneTrueCached(client,bBashed)){
								speedadd=0.0;
							}
							speedmulti=FloatMul(speedadd,GetBuffStacked(client,fSlow)); 
							//PrintToConsole(client,"speedmulti should be 1.0 %f %f",speedmulti,speedadd);
							new Float:newmaxspeed=FloatMul(speedBefore[client],speedmulti);
							
							speedWeSet[client]=newmaxspeed;
							SetEntDataFloat(client,m_OffsetSpeed,newmaxspeed,true);
							
						}
					}
					else{ //cs?
						
						new Float:speedmulti=1.0;
						
						//new Float:speedadd=1.0;
						if(!GetBuffHasOneTrueCached(client,bBuffDenyAll)){
							speedmulti=FloatMul(speedmulti,GetBuffMax(client,fMaxSpeed));
						}
						if(GetBuffHasOneTrueCached(client,bStunned)||GetBuffHasOneTrueCached(client,bBashed)){
							speedmulti=0.0;
						}
						else{
							speedmulti=FloatMul(speedmulti,GetBuffStacked(client,fSlow)); 
							speedmulti=FloatMul(speedmulti,GetBuffStacked(client,fSlow2)); 
						}
						
						if(GetEntDataFloat(client,m_OffsetSpeed)!=speedmulti){
							SetEntDataFloat(client,m_OffsetSpeed,speedmulti);
						}
					}
				}
				
				
				
				new MoveType:currentmovetype=GetEntityMoveType(client);
				new MoveType:shouldmoveas=MOVETYPE_WALK;
				if(GetBuffHasOneTrueCached(client,bNoMoveMode)){
					shouldmoveas=MOVETYPE_NONE;
				}
				else if(GetBuffHasOneTrueCached(client,bFlyMode)&&!GetBuffHasOneTrueCached(client,bFlyModeDeny)){
					shouldmoveas=MOVETYPE_FLY;
				}
				if(currentmovetype!=shouldmoveas){
					SetEntityMoveType(client,shouldmoveas);
				}
				//PrintToChatAll("end");
			}
		}
	}
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(!skiptest&&ValidPlayer(client,true)){ //block attack
		if(GetBuffHasOneTrueCached(client,bStunned)||GetBuffHasOneTrueCached(client,bDisarm)){
			if((buttons & IN_ATTACK) || (buttons & IN_ATTACK2))
			{
				buttons &= ~IN_ATTACK;
				buttons &= ~IN_ATTACK2;
			}
		}
	}
	return Plugin_Continue;
}


SetBuff(client,W3Buff:buffindex,itemraceindex,value)
{
	//PrintToServer("client %d buffindex %d raceitemindex %d value: %d %f",client,buffindex,itemraceindex,value,value);
	buffdebuff[client][buffindex][itemraceindex]=value;
	
	if(buffindex==fMaxSpeed||buffindex==fSlow||buffindex==bStunned||buffindex==bBashed){
		reapplyspeed[client]++; //0th is the 0th item which is dummy, kludge here
	}
	
	DoCalculateBuffCache(client,buffindex);
}
GetBuff(client,W3Buff:buffindex,itemraceindex){
	return buffdebuff[client][buffindex][itemraceindex];
}

ResetBuff(client,W3Buff:buffindex){
	
	if(ValidBuff(buffindex))
	{
		for(new i=0;i<=W3GetItemsLoaded()+War3_GetRacesLoaded();i++)
		{
			buffdebuff[client][buffindex][i]=BuffDefault(buffindex);
			
			DoCalculateBuffCache(client,buffindex);
		}
	}
}
ResetBuffParticularRaceOrItem(client,W3Buff:buffindex,particularraceitemindex){
	if(ValidBuff(buffindex))
	{
		buffdebuff[client][buffindex][particularraceitemindex]=BuffDefault(buffindex);
		
		DoCalculateBuffCache(client,buffindex);
	}
}

DoCalculateBuffCache(client,W3Buff:buffindex){
	///after we set it, we do an entire calculation to cache its value ( on selected buffs , mainly bools we test for HasTrue )
	switch(BuffProperties[buffindex][BuffStackType]){
		case DoNotCache: {}
		case bHasOneTrue: BuffCached[client][buffindex]=CalcBuffHasOneTrue(client,buffindex);
		case iAbsolute: BuffCached[client][buffindex]=CalcBuffSum(client,buffindex);
		case fStacked: BuffCached[client][buffindex]=CalcBuffStacked(client,buffindex);
		case fMaximum: BuffCached[client][buffindex]=CalcBuffMax(client,buffindex);
		case fMinimum: BuffCached[client][buffindex]=CalcBuffMin(client,buffindex);
	}
}


any:BuffDefault(W3Buff:buffindex){
	return BuffProperties[buffindex][DefaultValue];
}





////loop through the value of all items and races contributing values
stock any:CalcBuffMax(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{
		new any:value=buffdebuff[client][buffindex][0];
		for(new i=1;i<=W3GetItemsLoaded()+War3_GetRacesLoaded();i++)
		{
			new any:value2=buffdebuff[client][buffindex][i];
			//PrintToChatAll("%f",value2);
			if(value2>value){
				value=value2;
			}
		}
		return value;
	}
	LogError("invalid buff index");
	return -1;
}
stock any:CalcBuffMin(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{
		new any:value=buffdebuff[client][buffindex][0];
		for(new i=1;i<=W3GetItemsLoaded()+War3_GetRacesLoaded();i++)
		{
			new any:value2=buffdebuff[client][buffindex][i];
			if(value2<value){
				value=value2;
			}
		}
		return value;
	}
	LogError("invalid buff index");
	return -1;
}
stock bool:CalcBuffHasOneTrue(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{
		for(new i=0;i<=W3GetItemsLoaded()+War3_GetRacesLoaded();i++)
		{
			if(buffdebuff[client][buffindex][i])
			{
				//PrintToChat(client,"hasonetrue: true: buffindex = %d itter %d",buffindex,i);
				return true;
			}
		}
		return false;
		
	}
	LogError("invalid buff index");
	return false;
}


//multiplied all the values together , only for floats
stock Float:CalcBuffStacked(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{
		new Float:value=buffdebuff[client][buffindex][0];
		for(new i=1;i<=W3GetItemsLoaded()+War3_GetRacesLoaded();i++)
		{
			value=FloatMul(value,buffdebuff[client][buffindex][i]);
		}
		return value;
	}
	LogError("invalid buff index");
	return -1.0;
}
///SUM of ( value-1.0) ,, an "absolute" base stack, does not stack with itself
stock any:CalcBuffSumAbsolute(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{
		new any:value=1.0;
		//this one starts from zero
		for(new i=0;i<=W3GetItemsLoaded()+War3_GetRacesLoaded();i++)
		{
			value+=(buffdebuff[client][buffindex][i]-1.0);
		}
		return value;
	}
	LogError("invalid buff index");
	return -1;
}

///all values added!
stock CalcBuffSum(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{
		new any:value=0;
		//this one starts from zero
		for(new i=0;i<=W3GetItemsLoaded()+War3_GetRacesLoaded();i++)
		{
			value+=(buffdebuff[client][buffindex][i]);
		}
		return value;
	}
	LogError("invalid buff index");
	return -1;
}


////////getting cached values!
stock bool:GetBuffHasOneTrueCached(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{	
		if(BuffProperties[buffindex][BuffStackType]!=bHasOneTrue){
			ThrowError("Tried to get cached value when buff index should not cache this type");
		}
		return BuffCached[client][buffindex];
		
	}
	LogError("invalid buff index");
	return false;
}
stock Float:GetBuffStacked(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{	
		if(BuffProperties[buffindex][BuffStackType]!=fStacked){
			ThrowError("Tried to get cached value when buff index should not cache this type");
		}
		return BuffCached[client][buffindex];
		
	}
	LogError("invalid buff index");
	return 0.0;
}
stock GetBuffSum(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{	
		if(BuffProperties[buffindex][BuffStackType]!=iAbsolute){
			ThrowError("Tried to get cached value when buff index should not cache this type");
		}
		return BuffCached[client][buffindex];
		
	}
	LogError("invalid buff index");
	return false;
}
stock Float:GetBuffMax(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{	
		if(BuffProperties[buffindex][BuffStackType]!=fMaximum){
			ThrowError("Tried to get cached value when buff index should not cache this type");
		}
		return BuffCached[client][buffindex];
		
	}
	LogError("invalid buff index");
	return 0.0;
}
stock Float:GetBuffMin(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{	
		if(BuffProperties[buffindex][BuffStackType]!=fMinimum){
			ThrowError("Tried to get cached value when buff index should not cache this type");
		}
		return BuffCached[client][buffindex];
		
	}
	LogError("invalid buff index");
	return 0.0;
}











Float:PhysicalArmorMulti(client){
	new Float:armor=float(GetBuffSum(client,fArmorPhysical));
	return (1-(armor*0.06)/(1+armor*0.06));
}
Float:MagicArmorMulti(client){
	new Float:armor=float(GetBuffSum(client,fArmorMagic));
	return (1-(armor*0.06)/(1+armor*0.06));
}



stock GetPlayerAlpha(index)
{
	return GetEntData(index,m_OffsetClrRender+3,1);
}

stock GetPlayerR(index)
{
	return GetEntData(index,m_OffsetClrRender,1);
}

stock GetPlayerG(index)
{
	return GetEntData(index,m_OffsetClrRender+1,1);
}

stock GetPlayerB(index)
{
	return GetEntData(index,m_OffsetClrRender+2,1);
}

stock SetPlayerRGB(index,r,g,b)
{
	SetEntityRenderMode(index,RENDER_TRANSCOLOR);
	SetEntityRenderColor(index,r,g,b,GetPlayerAlpha(index));	
}

// FX Distort == 14
// Render TransAdd == 5
stock SetPlayerAlpha(index,alpha)
{
	SetEntityRenderMode(index,RENDER_TRANSCOLOR);
	SetEntityRenderColor(index,GetPlayerR(index),GetPlayerG(index),GetPlayerB(index),alpha);	
}

stock GetWeaponAlpha(client)
{
	new wep=W3GetCurrentWeaponEnt(client);
	if(wep>MaxClients && IsValidEdict(wep))
	{
		return GetPlayerAlpha(wep);
	}
	return 255;
}

stock SetWeaponAlpha(client,alpha)
{
	new wep=W3GetCurrentWeaponEnt(client);
	if(wep>MaxClients && IsValidEdict(wep))
	{
		SetPlayerAlpha(wep,alpha);
	}
}
stock ValidBuff(W3Buff:buffindex){
	return (_:buffindex>=0&&_:buffindex<MaxBuffLoopLimit);
}
