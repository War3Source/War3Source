 	

////BUFF SYSTEM




#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/sdkhooks"
#include "W3SIncs/War3Source_Interface"


new m_OffsetClrRender;


new m_OffsetGravity[MAXPLAYERSCUSTOM];
new m_OffsetSpeed;

new reapplyspeed[MAXPLAYERSCUSTOM];

//for debuff index, see constants, its in an enum
new any:buffdebuff[MAXPLAYERSCUSTOM][W3Buff][MAXITEMS+MAXRACES+MAXITEMS2+CUSTOMMODIFIERS]; ///a race may only modify a property once
//start loop for items only: i=1;i<MAXITEMS   
//start loop for races only: i=MAXITEMS;i<MAXITEMS+MAXRACES]
//buffs may be bool, float, or int
//MAXITEMS+MAXRACES is last because we usually loop through this last index

new BuffProperties[W3Buff][W3BuffProperties];

new any:BuffCached[MAXPLAYERSCUSTOM][W3Buff];// instead of looping, we cache everything in the last dimension, see enum W3BuffCache

new bool:skiptest;

stock halo;
public Plugin:myinfo= 
{
	name="War3Source Buff System",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};

new bool:invisWeaponAttachments[MAXPLAYERSCUSTOM];



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
	
	RegConsoleCmd("bufflist",cmdbufflist);
}

public OnMapStart(){
	halo=PrecacheModel("materials/sprites/halo01.vmt");
}
public bool:InitNativesForwards()
{
	
	CreateNative("War3_SetBuff",Native_War3_SetBuff);//for races
	CreateNative("War3_SetBuffItem",Native_War3_SetBuffItem);//foritems
	CreateNative("War3_SetBuffItem2",Native_War3_SetBuffItem2);//foritems
	CreateNative("W3GetPhysicalArmorMulti",NW3GetPhysicalArmorMulti);
	CreateNative("W3GetMagicArmorMulti",NW3GetMagicArmorMulti);
	
	
	CreateNative("W3GetBuff",NW3GetBuff);
	
	CreateNative("W3GetBuffHasTrue",NW3GetBuffHasTrue);
	CreateNative("W3GetBuffStackedFloat",NW3GetBuffStackedFloat);
	
	CreateNative("W3GetBuffSumFloat",NW3GetBuffSumFloat);
	CreateNative("W3GetBuffMinFloat",NW3GetBuffMinFloat);
	CreateNative("W3GetBuffMaxFloat",NW3GetBuffMaxFloat);

	CreateNative("W3GetBuffMinInt",NW3GetBuffMinInt);

	CreateNative("W3ResetAllBuffRace",NW3ResetAllBuffRace);
	CreateNative("W3ResetBuffRace",NW3ResetBuffRace);
	

	return true;
}
ItemsPlusRacesLoaded(){
	return W3GetItemsLoaded()+War3_GetRacesLoaded()+W3GetItems2Loaded()+CUSTOMMODIFIERS;
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
		/*if(raceid==0){
			new String:buf[64];
			GetPluginFilename(plugin, buf, sizeof(buf));
			ThrowError("warning, war3_setbuff passed zero raceid %s",buf);
		}*/
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
		
		/*if(itemid==0){
			new String:buf[64];
			GetPluginFilename(plugin, buf, sizeof(buf));
			ThrowError("warning, war3_setbuffitem passed zero itemid %s",buf);
		}*/
	}
}
public Native_War3_SetBuffItem2(Handle:plugin,numParams) //buff is from an item
{
	if(numParams==4) //client,race,buffindex,value
	{
		new client=GetNativeCell(1);
		new W3Buff:buffindex=GetNativeCell(2);
		new itemid=GetNativeCell(3);
		new any:value=GetNativeCell(4);
		SetBuff(client,buffindex,W3GetItemsLoaded()+War3_GetRacesLoaded()+itemid,value); //not offseted
		
		/*if(itemid==0){
			new String:buf[64];
			GetPluginFilename(plugin, buf, sizeof(buf));
			LogError("warning, war3_setbuffitem2 passed zero itemid %s",buf);
		}*/
	}
}
public NW3GetBuff(Handle:plugin,numParams)
{
	
	new client=GetNativeCell(1);
	new W3Buff:buffindex=GetNativeCell(2);
	new raceiditemid=GetNativeCell(3);
	new bool:isItem=GetNativeCell(4);
	if(!isItem){
		raceiditemid+=W3GetItemsLoaded();
	}
	if(ValidBuff(buffindex)){
		return buffdebuff[client][buffindex][raceiditemid];
	}
	else{
		ThrowError("invalidbuffindex");
	}
	return -1;
}


//stop complaining that we are returning a float!
public NW3GetPhysicalArmorMulti(Handle:plugin,numParams) {
	return _:PhysicalArmorMulti(GetNativeCell(1));
}

public NW3GetMagicArmorMulti(Handle:plugin,numParams) {
	
	return _:MagicArmorMulti(GetNativeCell(1));
}
public NW3GetBuffHasTrue(Handle:plugin,numParams) {
	//all one true bools are cached
	return _:GetBuffHasOneTrue(GetNativeCell(1),GetNativeCell(2)); //returns bool
}
public NW3GetBuffStackedFloat(Handle:plugin,numParams) {
	
	return _:GetBuffStackedFloat(GetNativeCell(1),GetNativeCell(2)); //returns float usually
}
public NW3GetBuffSumFloat(Handle:plugin,numParams) {
	
	return _:GetBuffSumFloat(GetNativeCell(1),GetNativeCell(2)); 
}
public NW3GetBuffMinFloat(Handle:plugin,numParams) {
   return _:GetBuffMinFloat(GetNativeCell(1),GetNativeCell(2)); 
}
public NW3GetBuffMaxFloat(Handle:plugin,numParams) {
   return _:GetBuffMaxFloat(GetNativeCell(1),GetNativeCell(2)); 
}
public NW3GetBuffMinInt(Handle:plugin,numParams) {
   return GetBuffMinInt(GetNativeCell(1),GetNativeCell(2)); 
}

public NW3ResetAllBuffRace(Handle:plugin,numParams) {
	new client=GetNativeCell(1);
	new race=GetNativeCell(2);
	
	
	for(new buffindex=0;buffindex<MaxBuffLoopLimit;buffindex++)
	{	
		
		ResetBuffParticularRaceOrItem(client,W3Buff:buffindex,W3GetItemsLoaded()+race);
	}
	//SOME NEEDS TO BE SET AGAIN TO REFRESH
	
}
public NW3ResetBuffRace(Handle:plugin,numParams) {
	new client=GetNativeCell(1);
	new W3Buff:buffindex=W3Buff:GetNativeCell(2);
	new race=GetNativeCell(3);
	
	ResetBuffParticularRaceOrItem(client,W3Buff:buffindex,W3GetItemsLoaded()+race);	
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

public Action:cmdbufflist(client,args){

	if(args==1){
		new String:arg[32];
		GetCmdArg(1,arg,sizeof(arg));
		new int=StringToInt(arg);
		new ItemsLoaded = W3GetItemsLoaded();
		new RacesPlusItems = ItemsLoaded+War3_GetRacesLoaded();
		for(new i=1;i<=RacesPlusItems;i++){
			new String:name[32];
			if(i<=ItemsLoaded){
				W3GetItemShortname(i,name,sizeof(name));
			}
			else{
				War3_GetRaceShortname(i-ItemsLoaded,name,sizeof(name));
			}
			W3Log("buff for client %d buffid %d : %d %f race/item %s",client,int,buffdebuff[client][W3Buff:int][i],buffdebuff[client][W3Buff:int][i],name);
		
		}
	}
}


public OnClientPutInServer(client){
	m_OffsetGravity[client]=FindDataMapOffs(client,"m_flGravity");
	
	//reset all buffs for each race and item
	for(new buffindex=0;buffindex<MaxBuffLoopLimit;buffindex++)
	{
		ResetBuff(client,W3Buff:buffindex);
	}
	

	//SDKHook(client, SDKHook_PreThink, OnPreThink);
	//SDKHook(client, SDKHook_PostThinkPost, OnPreThink);
	SDKHook(client,SDKHook_PostThinkPost,SDK_Forwarded_PostThinkPost);
}
public SDK_Forwarded_PostThinkPost(client)
{	
	//does not work, flickers
	/*if(ValidPlayer(client,true)){
    	if(invisWeaponAttachments[client]){
					
				if(War3_GetGame()==CS){
					
					SetEntProp(client, Prop_Send, "m_iAddonBits", 0); //m_iAddonBits //"m_iPrimaryAddon" and "m_iSecondaryAddon
					SetEntProp(client, Prop_Send, "m_iPrimaryAddon",0);
					SetEntProp(client, Prop_Send, "m_iSecondaryAddon",0);
					//if(W3Chance(0.1)){
					ChangeEdictState(client,  0);
						PrintToServer("m_iAddonBits %d %f",client,GetGameTime());
					//}
				}
			}
		}
	}*/
}

new Float:speedBefore[MAXPLAYERSCUSTOM];
new Float:speedWeSet[MAXPLAYERSCUSTOM];

public Action:DeciSecondTimer(Handle:timer)
{
	if(!skiptest){
		// Boy, this is going to be fun.
		for(new client=1;client<=MaxClients;client++)
		{
			if(ValidPlayer(client,true))
			{
				
		
				//PrintToChatAll("sdf %d",client);
				new Float:gravity=1.0; //default
				if(!GetBuffHasOneTrue(client,bLowGravityDenyAll)&&!GetBuffHasOneTrue(client,bBuffDenyAll)) //can we change gravity?
				{
					//if(!GetBuffHasOneTrue(client,bLowGravityDenySkill)){
					new Float:gravity1=GetBuffMinFloat(client,fLowGravitySkill);
					//}
					//if(!GetBuffHasOneTrue(client,bLowGravityDenyItem)){
					new Float:gravity2=GetBuffMinFloat(client,fLowGravityItem);
					
					gravity=gravity1<gravity2?gravity1:gravity2;
					//}
					//gravity=; //replace
					//PrintToChat(client,"mingrav=%f",gravity);
				}
				///now lets set the grav
				if(GetEntDataFloat(client,m_OffsetGravity[client])!=gravity) ///gravity offset is somewhoe different for each person? this offset is got on PutInServer
					SetEntDataFloat(client,m_OffsetGravity[client],gravity);
				
				
				new r=255,g=255,b=255,alpha=255;
			//	new bool:skipinvis=false;
				
				new bestindex=-1;
				new highestvalue=0;
				new Float:settime=0.0;
				
				new limit=W3GetItemsLoaded()+War3_GetRacesLoaded()+W3GetItems2Loaded();
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
				//	skipinvis=true;
				}
				
				new bool:set=false;
				if(GetPlayerR(client)!=r)
					set=true;
				if(GetPlayerG(client)!=g)
					set=true;
				if(GetPlayerB(client)!=b)
					set=true;
				//alpha set is after invis block, not here
				if(set){
					//	PrintToChatAll("%d %d %d %d",r,g,b,alpha);
					SetPlayerRGB(client,r,g,b);
				}
				
				
				
				
				
				///invisbility!
				//PrintToChatAll("GetBuffMinFloat(client,fInvisibility) %f %f %f ",GetBuffMinFloat(client,fInvisibility),float(alpha),float(alpha)*GetBuffMinFloat(client,fInvisibility));
				if(!GetBuffHasOneTrue(client,bInvisibilityDenyAll)&&!GetBuffHasOneTrue(client,bBuffDenyAll)) ///buff is not denied
				{
					new Float:falpha=1.0;
					if(!GetBuffHasOneTrue(client,bInvisibilityDenySkill))
					{
						falpha=FloatMul(falpha,GetBuffMinFloat(client,fInvisibilitySkill));
						
					}
					//if(!GetBuffHasOneTrue(client,bInvisibilityDenySkillbInvisibl  ///we dont have an item deny yet
					new Float:itemalpha=GetBuffMinFloat(client,fInvisibilityItem);
					if(falpha!=1.0){
						//PrintToChatAll("has skill invis");
						//has skill, reduce stack
						itemalpha=Pow(itemalpha,0.75);
					}
					falpha=FloatMul(falpha,itemalpha);
					
					//PrintToChatAll("%f",GetBuffMinFloat(client,fInvisibilityItem));
					
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
				if(GetEntityAlpha(client)!=alpha)
					SetEntityAlpha(client,alpha);
					
				invisWeaponAttachments[client]=alpha<200?true:false;
				
					
					
					
				new wpn=W3GetCurrentWeaponEnt(client);
				if(wpn>0){
					if(GetBuffHasOneTrue(client,bInvisWeaponOverride)){
						new alphaw=-1;
						new buffloop = BuffLoopLimit();
						for(new i=0;i<=buffloop;i++){
							if(W3GetBuff(client,bInvisWeaponOverride,i,true)){
								alphaw=W3GetBuff(client,iInvisWeaponOverrideAmount,i,true);
							}
						}
						if(alphaw==-1){
							ThrowError("could not find a valid weapon alpha");
						}
						if(GetWeaponAlpha(client)!=alphaw){
							SetEntityAlpha(wpn,alphaw);
						}
					}
					else if(!GetBuffHasOneTrue(client,bDoNotInvisWeapon)){
						if(GetWeaponAlpha(client)!=alpha){
							SetEntityAlpha(wpn,alpha);
							
						}
					}
					
				}
				
				
				/*for(new i=0;i<10;i++){
					new ent=GetPlayerWeaponSlot(client,i);
					if(ent>0){
						PrintToChatAll("2 ent %d %d %d",ent,GetEntityAlpha(ent),alpha);
						if(GetEntityAlpha(ent)!=alpha)
						{
							PrintToChatAll("3");
							
							
			
							SetEntityRenderMode(ent,RENDER_NONE);
							SetEntityRenderFx(ent,RENDERFX_FADE_FAST);
							SetEntityRenderColor(ent,0,0,0,0);	
							SetEntData(ent,FindSendPropOffs("CWeaponCSBaseGun","m_iParentAttachment"),0,_,true);
							SetEntData(ent,FindSendPropOffs("CWeaponCSBaseGun","moveparent"),0,_,true);
							SetEntData(ent,FindSendPropOffs("CWeaponCSBaseGun","movetype"),0,_,true);
							
							TeleportEntity(ent,Float:{0.0,0.0,0.0},Float:{0.0,0.0,0.0},Float:{0.0,0.0,0.0});
							//SetEntityAlpha(ent,alpha);
							TE_SetupKillPlayerAttachments(client);
							TE_SendToAll();
							TE_SetupKillPlayerAttachments(ent);
							TE_SendToAll();
							ChangeEdictState(ent);
							
							
							SetEntData(ent,FindSendPropOffs("CWeaponCSBaseGun","m_bIsPlayerSimulated")  ,0,1,true);
							SetEntData(ent,FindSendPropOffs("CWeaponCSBaseGun","m_bSimulatedEveryTick")  ,0,1,true);
							SetEntData(ent,FindSendPropOffs("CWeaponCSBaseGun","m_bAnimatedEveryTick") ,0,1,true);
							SetEntData(ent,FindSendPropOffs("CWeaponCSBaseGun","m_bAnimatedEveryTick") ,0,1,true);
							SetEntDataFloat(ent,FindSendPropOffs("CWeaponCSBaseGun","m_flAnimTime") ,0.0,true);
							SetEntData(ent,FindSendPropOffs("CWeaponCSBaseGun","m_bAnimatedEveryTick") ,0.0,_,true);
							SetEntDataFloat(ent,FindSendPropOffs("CWeaponCSBaseGun","m_flSimulationTime") ,0.0,true);
							SetEntData(ent,FindSendPropOffs("CWeaponCSBaseGun","m_nNextThinkTick") ,9999,true);
							
							SetEntData(ent,FindSendPropOffs("CWeaponCSBaseGun","m_iViewModelIndex")  ,halo,1,true);
							SetEntData(ent,FindSendPropOffs("CWeaponCSBaseGun","m_iWorldModelIndex")  ,halo,1,true);
							SetEntData(ent,FindSendPropOffs("CWeaponCSBaseGun","m_nModelIndex")  ,halo,1,true);
							
							
							
							PrintToChatAll("weapon alpha %d %f",alpha,GetGameTime());
						}
					}
				}*/
				
				///NEED 4 SPEED!
				///SPEED IS IN PLAYER FRAME	
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
							
							//new Float:speedadd=1.0;
							if(!GetBuffHasOneTrue(client,bBuffDenyAll)){
								speedmulti=GetBuffMaxFloat(client,fMaxSpeed);
							}
							if(GetBuffHasOneTrue(client,bStunned)||GetBuffHasOneTrue(client,bBashed)){
								speedmulti=0.0;
							}
							if(!GetBuffHasOneTrue(client,bSlowImmunity)){
								speedmulti=FloatMul(speedmulti,GetBuffStackedFloat(client,fSlow)); 
								speedmulti=FloatMul(speedmulti,GetBuffStackedFloat(client,fSlow2)); 
							}
							//PrintToConsole(client,"speedmulti should be 1.0 %f %f",speedmulti,speedadd);
							new Float:newmaxspeed=FloatMul(speedBefore[client],speedmulti);
							
							speedWeSet[client]=newmaxspeed;
							SetEntDataFloat(client,m_OffsetSpeed,newmaxspeed,true);
							
						}
					}
					else{ //cs?
											
						new Float:speedmulti=1.0;
						
						//new Float:speedadd=1.0;
						if(!GetBuffHasOneTrue(client,bBuffDenyAll)){
							new Float:speedmulti1=GetBuffMaxFloat(client,fMaxSpeed);
							new Float:speedmulti2=GetBuffMaxFloat(client,fMaxSpeed2);
							speedmulti=speedmulti1+(speedmulti2-1.0); ///1.0 + 1.0 - 1.0 = 1.0
						}
						if(GetBuffHasOneTrue(client,bStunned)||GetBuffHasOneTrue(client,bBashed)){
							speedmulti=0.0;
						}
						if(!GetBuffHasOneTrue(client,bSlowImmunity)){
							speedmulti=FloatMul(speedmulti,GetBuffStackedFloat(client,fSlow)); 
							speedmulti=FloatMul(speedmulti,GetBuffStackedFloat(client,fSlow2)); 
						}
						
						if(GetEntDataFloat(client,m_OffsetSpeed)!=speedmulti){
							SetEntDataFloat(client,m_OffsetSpeed,speedmulti);
						}
					}
				}
				
				
				
				new MoveType:currentmovetype=GetEntityMoveType(client);
				new MoveType:shouldmoveas=MOVETYPE_WALK;
				if(GetBuffHasOneTrue(client,bNoMoveMode)){
					shouldmoveas=MOVETYPE_NONE;
				}
				if(GetBuffHasOneTrue(client,bNoClipMode)){
					shouldmoveas=MOVETYPE_NOCLIP;
				}
				else if(GetBuffHasOneTrue(client,bFlyMode)&&!GetBuffHasOneTrue(client,bFlyModeDeny)){
					shouldmoveas=MOVETYPE_FLY;
				}
				
				/* Glider (290611): 
				 * 		I have implemented a extremly dirty way to prevent some
				 *      shit that goes wrong in L4D2.
				 *         
				 *      If a tank tries to climb a object, he changes his
				 *      move type. This code prevented them from ever
				 *      climbing anything.
				 *         
				 *      Players also change their move type when they get
				 *      hit so hard they stagger into a direction, making
				 *      them move slower. This code made them stagger much
				 *      faster, resulting in crossing a much larger distance
				 *      (usually right into some pit).
				 *         
				 *      TODO: Fix properly ;)
				 */
				
				if(currentmovetype!=shouldmoveas && !War3_IsL4DEngine()){
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
		if(GetBuffHasOneTrue(client,bStunned)||GetBuffHasOneTrue(client,bDisarm)){
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
///REMOVE SINGLE BUFF FROM ALL RACES
ResetBuff(client,W3Buff:buffindex){
	
	if(ValidBuff(buffindex))
	{
		new loop = ItemsPlusRacesLoaded();
		for(new i=0;i<=loop;i++) //reset starts at 0
		{
			buffdebuff[client][buffindex][i]=BuffDefault(buffindex);
			
			DoCalculateBuffCache(client,buffindex);
		}
		reapplyspeed[client]++;

	}
}
//RESET SINGLE BUFF OF SINGLE RACE
ResetBuffParticularRaceOrItem(client,W3Buff:buffindex,particularraceitemindex){
	if(ValidBuff(buffindex))
	{
		buffdebuff[client][buffindex][particularraceitemindex]=BuffDefault(buffindex);
		
		DoCalculateBuffCache(client,buffindex);
		reapplyspeed[client]++;
	}
}

DoCalculateBuffCache(client,W3Buff:buffindex){
	///after we set it, we do an entire calculation to cache its value ( on selected buffs , mainly bools we test for HasTrue )
	switch(BuffCacheType(buffindex)){
		case DoNotCache: {}
		case bHasOneTrue: BuffCached[client][buffindex]=CalcBuffHasOneTrue(client,buffindex);
		case iAbsolute: BuffCached[client][buffindex]=CalcBuffSumInt(client,buffindex);
		case fAbsolute: BuffCached[client][buffindex]=CalcBuffSumFloat(client,buffindex);
		case fStacked: BuffCached[client][buffindex]=CalcBuffStackedFloat(client,buffindex);
		case fMaximum: BuffCached[client][buffindex]=CalcBuffMax(client,buffindex);
		case fMinimum: BuffCached[client][buffindex]=CalcBuffMin(client,buffindex);
		case iMinimum: BuffCached[client][buffindex]=CalcBuffMinInt(client,buffindex);
	}
}


any:BuffDefault(W3Buff:buffindex){
	return BuffProperties[buffindex][DefaultValue];
}
BuffStackCacheType:BuffCacheType(W3Buff:buffindex){
	return BuffProperties[buffindex][BuffStackType];
}




////loop through the value of all items and races contributing values
stock any:CalcBuffMax(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{
		new any:value=buffdebuff[client][buffindex][0];
		new loop = ItemsPlusRacesLoaded();
		for(new i=1;i<=loop;i++)
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
		new loop = ItemsPlusRacesLoaded();
		for(new i=1;i<=loop;i++)
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
CalcBuffMinInt(client,W3Buff:buffindex)
{ 	
	if(ValidBuff(buffindex))
	{
		new value=buffdebuff[client][buffindex][0];
		new loop = ItemsPlusRacesLoaded();
		for(new i=1;i<=loop;i++)
		{
			new value2=buffdebuff[client][buffindex][i];
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
		new loop = ItemsPlusRacesLoaded();
		for(new i=1;i<=loop;i++)
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
stock Float:CalcBuffStackedFloat(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{
		new Float:value=buffdebuff[client][buffindex][0];
		new loop = ItemsPlusRacesLoaded();
		for(new i=1;i<=loop;i++)
		{
			value=FloatMul(value,buffdebuff[client][buffindex][i]);
		}
		return value;
	}
	LogError("invalid buff index");
	return -1.0;
}


///all values added!
stock CalcBuffSumInt(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{
		new any:value=0;
		//this one starts from zero
		new loop = ItemsPlusRacesLoaded();
		for(new i=1;i<=loop;i++)
		{
			
			value=value+buffdebuff[client][buffindex][i];
			
		}
		return value;
		
	}
	LogError("invalid buff index");
	return -1;
}

///all values added!
stock CalcBuffSumFloat(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{
		new any:value=0;
		//this one starts from zero
		new loop = ItemsPlusRacesLoaded();
		for(new i=1;i<=loop;i++)
		{
			
			value=Float:value+Float:(buffdebuff[client][buffindex][i]);
			
		}
		return value;
		
	}
	LogError("invalid buff index");
	return -1;
}


////////getting cached values!
stock bool:GetBuffHasOneTrue(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{	
		if(BuffCacheType(buffindex)!=bHasOneTrue){
			ThrowError("Tried to get cached value when buff index (%d) should not cache this type (%d)",buffindex,BuffCacheType(buffindex));
		}
		return BuffCached[client][buffindex];
		
	}
	LogError("invalid buff index");
	return false;
}
stock Float:GetBuffStackedFloat(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{	
		if(BuffCacheType(buffindex)!=fStacked){
			ThrowError("Tried to get cached value when buff index (%d) should not cache this type (%d)",buffindex,BuffCacheType(buffindex));
		}
		return BuffCached[client][buffindex];
		
	}
	LogError("invalid buff index");
	return 0.0;
}
stock GetBuffSumInt(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{	
		if(BuffCacheType(buffindex)!=iAbsolute){
			ThrowError("Tried to get cached value when buff index (%d) should not cache this type (%d)",buffindex,BuffCacheType(buffindex));
		}
		return BuffCached[client][buffindex];
		
	}
	LogError("invalid buff index");
	return false;
}
stock Float:GetBuffSumFloat(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{	
		if(BuffCacheType(buffindex)!=fAbsolute){
			ThrowError("Tried to get cached value when buff index (%d) should not cache this type (%d)",buffindex,BuffCacheType(buffindex));
		}
		return Float:BuffCached[client][buffindex];
		
	}
	LogError("invalid buff index");
	return 0.0;
}
stock Float:GetBuffMaxFloat(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{	
		if(BuffCacheType(buffindex)!=fMaximum){
			ThrowError("Tried to get cached value when buff index (%d) should not cache this type (%d)",buffindex,BuffCacheType(buffindex));
		}
		return BuffCached[client][buffindex];
		
	}
	LogError("invalid buff index");
	return 0.0;
}
stock Float:GetBuffMinFloat(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{	
		if(BuffCacheType(buffindex)!=fMinimum){
			ThrowError("Tried to get cached value when buff index (%d) should not cache this type (%d)",buffindex,BuffCacheType(buffindex));
		}
		return BuffCached[client][buffindex];
		
	}
	LogError("invalid buff index");
	return 0.0;
}
GetBuffMinInt(client,W3Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{	
		if(BuffCacheType(buffindex)!=iMinimum){
			ThrowError("Tried to get cached value when buff index (%d) should not cache this type (%d)",buffindex,BuffCacheType(buffindex));
		}
		return BuffCached[client][buffindex];
		
	}
	LogError("invalid buff index");
	return 0;
}











Float:PhysicalArmorMulti(client){
	new Float:armor=Float:GetBuffSumFloat(client,fArmorPhysical);
	
	if(armor<0.0){
		armor=armor*-1.0;
		return ((armor*0.06)/(1.0+armor*0.06))+1.0;
	}
	
	return (1.0-(armor*0.06)/(1.0+armor*0.06));
}
Float:MagicArmorMulti(client){

	new Float:armor=Float:GetBuffSumFloat(client,fArmorMagic);
	//PrintToServer("armor=%f",armor);
	if(armor<0.0){
		armor=armor*-1.0;
		return ((armor*0.06)/(1.0+armor*0.06))+1.0;
	}
	
	return (1.0-(armor*0.06)/(1.0+armor*0.06));
}



stock GetEntityAlpha(index)
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
	SetEntityRenderColor(index,r,g,b,GetEntityAlpha(index));	
}

// FX Distort == 14
// Render TransAdd == 5
stock SetEntityAlpha(index,alpha)
{	
	//if(FindSendPropOffs(index,"m_nRenderFX")>-1&&FindSendPropOffs(index,"m_nRenderMode")>-1){
	new String:class[32];
	GetEntityNetClass(index, class, sizeof(class) );
	//PrintToServer("%s",class);
	if(FindSendPropOffs(class,"m_nRenderFX")>-1){
		SetEntityRenderMode(index,RENDER_TRANSCOLOR);
		SetEntityRenderColor(index,GetPlayerR(index),GetPlayerG(index),GetPlayerB(index),alpha);
	}
	//else{
	//	W3Log("deny render fx %d",index);
	//}
	//}	
}

stock GetWeaponAlpha(client)
{
	new wep=W3GetCurrentWeaponEnt(client);
	if(wep>MaxClients && IsValidEdict(wep))
	{
		return GetEntityAlpha(wep);
	}
	return 255;
}

stock ValidBuff(W3Buff:buffindex){
	if(_:buffindex>=0&&_:buffindex<MaxBuffLoopLimit){
		return true;
		
	
	}
	ThrowError("invalid buff index (%d)",buffindex);
	return false;
}
//use 0 < limit
stock BuffLoopLimit(){
	return W3GetItemsLoaded()+War3_GetRacesLoaded()+1;
}
