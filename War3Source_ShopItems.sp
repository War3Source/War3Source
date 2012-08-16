/**
 * File: War3Source_ShopItems.sp
 * Description: The shop items that come with War3Source.
 * Author(s): Anthony Iacono
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>

#include <cstrike>

enum{
	ANKH=0,
	BOOTS,
	CLAW,
	CLOAK,
	MASK,
	NECKLACE,
	FROST,
	HEALTH,
	TOME, 
	RESPAWN,
	SOCK,
	GLOVES,
	RING,
	MOLE,
	
}

new shopItem[MAXITEMS];//
new bool:bDidDie[65]; // did they die before spawning?
new Handle:BootsSpeedCvar;
new ActiveWeaponOffset;
new Handle:ClawsAttackCvar;
new Handle:MaskDeathCvar;
new bool:bFrosted[65]; // don't frost before unfrosted
new Handle:OrbFrostCvar;
new Handle:TomeCvar;
new bool:bSpawnedViaScrollRespawn[65]; // don't allow multiple scroll respawns
new Handle:SockCvar;
new Handle:RegenHPCSCvar;
new Handle:RegenHPTFCvar;

new Handle:MoleDeathmatchCvar;
new String:sOldModel[65][256]; // reset model after 10 seconds

new String:buyTombSound[]="war3source/tomes.wav";
new String:masksnd[]="war3source/mask.mp3";
new maskSoundDelay[66];


// Offsets
new OriginOffset,MyWeaponsOffset,AmmoOffset,Clip1Offset;

public Plugin:myinfo = 
{
	name = "W3S - Shopitems",
	author = "PimpinJuice",
	description = "The shop items that come with War3Source.",
	version = "1.0.0.0",
	url = "http://pimpinjuice.net/"
};

public OnPluginStart()
{
	HookEvent("round_start",RoundStartEvent);
	OriginOffset=FindSendPropOffs("CBaseEntity","m_vecOrigin");
	MyWeaponsOffset=FindSendPropOffs("CBaseCombatCharacter","m_hMyWeapons");
	
	ActiveWeaponOffset=FindSendPropOffs("CBaseCombatCharacter","m_hActiveWeapon"); 
	
	Clip1Offset=FindSendPropOffs("CBaseCombatWeapon","m_iClip1");
	AmmoOffset=FindSendPropOffs("CBasePlayer","m_iAmmo");
	BootsSpeedCvar=CreateConVar("war3_shop_boots_speed","1.2","Boots speed, 1.2 is default");
	ClawsAttackCvar=CreateConVar("war3_shop_claws_damage",GameTF()?"10":"6","Claws of attack additional damage per bullet (CS) or per second (TF)");
	MaskDeathCvar=CreateConVar("war3_shop_mask_percent","0.30","Percent of damage rewarded for Mask of Death, from 0.0 - 1.0");
	OrbFrostCvar=CreateConVar("war3_shop_orb_speed","0.6","Orb of Frost speed, 1.0 is normal speed, 0.6 default for orb.");
	TomeCvar=CreateConVar("war3_shop_tome_xp","100","Experience awarded for Tome of Experience.");
	SockCvar=CreateConVar("war3_shop_sock_gravity","0.4","Gravity used for Sock of Feather, 0.4 is default for sock, 1.0 is normal gravity");
	RegenHPCSCvar=CreateConVar("war3_shop_ring_hp_cs","2","How much HP is regenerated for CS.");
	RegenHPTFCvar=CreateConVar("war3_shop_ring_hp_tf","4","How much HP is regenerated for TF.");

	MoleDeathmatchCvar=CreateConVar("war3_shop_mole_dm","0","Set this to 1 if server is deathmatch");
	
	//RegConsoleCmd("frostme",cmdfrostme);
	
	
	CreateTimer(1.0,SecondLoop,_,TIMER_REPEAT);
	CreateTimer(0.1,PointOneSecondLoop,_,TIMER_REPEAT);
	CreateTimer(10.0,GrenadeLoop,_,TIMER_REPEAT);
	
	for(new i=1;i<=MaxClients;i++){
		maskSoundDelay[i]=War3_RegisterDelayTracker();
	}
}
new bool:war3ready;
public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==10){
	
		war3ready=true;
		for(new x=0;x<MAXITEMS;x++)
			shopItem[x]=0;
		if(War3_GetGame()==Game_CS) 
			shopItem[ANKH]=War3_CreateShopItemT("ankh",3,2000);
		
		shopItem[BOOTS]=War3_CreateShopItemT("boot",3,2500);
		
		shopItem[CLAW]=War3_CreateShopItemT("claw",3,5000);
		
		shopItem[CLOAK]=War3_CreateShopItemT("cloak",2,1000);
		
		shopItem[MASK]=War3_CreateShopItemT("mask",3,1500);
		
		shopItem[NECKLACE]=War3_CreateShopItemT("lace",2,800);
		//War3_CreateShopItemRef(shopItem[NECKLACE],"necklace_immunity");
		
		//if(War3_GetGame()!=Game_TF) 
		shopItem[FROST]=War3_CreateShopItemT("orb",3,2000);
		
		shopItem[RING]=War3_CreateShopItemT("ring",3,1500);
		
		
		if(War3_GetGame()!=Game_TF) 
			shopItem[HEALTH]=War3_CreateShopItemT("health",3,3000);
		
		shopItem[TOME]=War3_CreateShopItemT("tome",10,10000);
		War3_SetItemProperty(	shopItem[TOME], ITEM_USED_ON_BUY,true);
	
		if(War3_GetGame()!=Game_TF) 
			shopItem[RESPAWN]=War3_CreateShopItemT("scroll",15,6000);
		
		shopItem[SOCK]=War3_CreateShopItemT("sock",2,1500);
		
		if(War3_GetGame()==Game_CS) 
			shopItem[GLOVES]=War3_CreateShopItemT("glove",5,3000);
		
		
		if(War3_GetGame()!=Game_TF) 
			shopItem[MOLE]=War3_CreateShopItemT("mole",10,10000);
		

	
	}
	
	
}
public OnMapStart()
{
	War3_PrecacheSound(buyTombSound);
	War3_PrecacheSound(masksnd);
	if(GAMECSGO) {
		// Theese models aren't always precached
		PrecacheModel("models/player/ctm_gsg9.mdl");
		PrecacheModel("models/player/tm_leet.mdl");
	}
}


public Action:SecondLoop(Handle:timer,any:data)
{
	
}

public Action:PointOneSecondLoop(Handle:timer,any:data)
{
	if(war3ready){
		doCloak();
	}
}
public doCloak() //this loop should detec weapon chnage and add a new alpha
{
	for(new x=1;x<=MaxClients;x++)
	{
		//PrintToServer("%s",shopItem[CLOAK]);
		if(ValidPlayer(x,true)&&War3_GetOwnsItem(x,shopItem[CLOAK]))
		{
			War3_SetBuffItem(x,fInvisibilityItem,shopItem[CLOAK],0.6);
			
			///knife? melle?
			new ent=GetEntDataEnt2(x,ActiveWeaponOffset);//MyWeaponsOffset);//ActiveWeaponOffset);
			if(ent>0 && IsValidEdict(ent))
			{
				decl String:wepName[64];
				GetEdictClassname(ent,wepName,sizeof(wepName));
				if(StrEqual(wepName,"weapon_knife",false))
				{
					War3_SetBuffItem(x,fInvisibilityItem,shopItem[CLOAK],0.4);
				}
			}
		}
	}
	//CreateTimer(1.0,Cloak);
}

//gloves giving nades
public Action:GrenadeLoop(Handle:timer,any:data)
{
	if(war3ready&&War3_GetGame()==Game_CS){
		
		for(new x=1;x<=MaxClients;x++)
		{
			if(ValidPlayer(x,true)&&War3_GetOwnsItem(x,shopItem[GLOVES]))
			{
				new bool:has_grenade=false;
				for(new s=0;s<10;s++)
				{
					new ent=War3_CachedWeapon(x,s);
					if(ent>0 && IsValidEdict(ent))
					{
						decl String:wepName[64];
						GetEdictClassname(ent,wepName,sizeof(wepName));
						if(StrEqual(wepName,"weapon_hegrenade",false))
						{
							has_grenade=true;
						}
					}
				}
				if(!has_grenade)
				{
					GivePlayerItem(x,"weapon_hegrenade");
					PrintHintText(x,"%T","+HEGRENADE",x);
				}
			}
		}
	}
	//CreateTimer(10.0,Grenade);
}


public OnItemPurchase(client,item)
{
	if(item==shopItem[BOOTS] /*&& War3_GetGame()!=Game_TF*/) // boots of speed
	{
		War3_SetBuffItem(client,fMaxSpeed,shopItem[BOOTS],GetConVarFloat(BootsSpeedCvar));
		//War3_SetMaxSpeed(client,GetConVarFloat(BootsSpeedCvar),shopItem[1]);
		if(IsPlayerAlive(client))
			War3_ChatMessage(client,"%T","You strap on your boots",client);
	}
	if(item==shopItem[SOCK])
	{
		War3_SetBuffItem(client,fLowGravityItem,shopItem[SOCK],GetConVarFloat(SockCvar));
		//War3_SetMinGravity(client,GetConVarFloat(SockCvar),shopItem[10]);
		if(IsPlayerAlive(client))
			War3_ChatMessage(client,"%T","You pull on your socks",client);
	}
	if(item==shopItem[NECKLACE]) // immunity
	{
		War3_SetBuffItem(client,bImmunityUltimates,shopItem[NECKLACE],true);
	}
	if(War3_GetGame()!=Game_TF && item==shopItem[HEALTH] && IsPlayerAlive(client)) // health
	{
		//SetEntityHealth(client,GetClientHealth(client)+50);
		//War3_SetMaxHP(client,War3_GetMaxHP(client)+50);
		War3_SetBuffItem(client,iAdditionalMaxHealth,shopItem[HEALTH],50);
			
		War3_ChatMessage(client,"%T","+50 HP",client);
	}
	if(item==shopItem[TOME]) // tome of xp
	{
		new race=War3_GetRace(client);
		new add_xp=GetConVarInt(TomeCvar);
		if(add_xp<0)	add_xp=0;
		War3_SetXP(client,race,War3_GetXP(client,race)+add_xp);
		W3DoLevelCheck(client);
		War3_SetOwnsItem(client,item,false);
		War3_ChatMessage(client,"%T","+{amount} XP",client,add_xp);
		War3_ShowXP(client);
		if(IsPlayerAlive(client)){
			EmitSoundToAll(buyTombSound,client);
		}
		else{
			EmitSoundToClient(client,"war3source/tomes.wav");
		}
		
	}
	if(item==shopItem[RING]) 
	{
		new Float:regen_hp=GetConVarFloat((War3_GetGame()==Game_CS)?RegenHPCSCvar:RegenHPTFCvar);
		War3_SetBuffItem(client,fHPRegen,shopItem[RING],regen_hp);
	}
	if(War3_GetGame()!=Game_TF && item==shopItem[RESPAWN])
	{
		bSpawnedViaScrollRespawn[client]=false;
		
		if(!IsPlayerAlive(client)&&GetClientTeam(client)>1){
			War3_ChatMessage(client,"%T","You will be respawned",client);
			CreateTimer(0.2,RespawnPlayerViaScrollRespawn,client);
			//CreateTimer(0.5,Reincarnate,GetClientUserId(client));
		}
		else{
			War3_ChatMessage(client,"%T","Next time you die you will respawn",client);
		}
	}
}

//deactivate BUFFS AND PASSIVES
public OnItemLost(client,item){ //deactivate passives , client may have disconnected
	if(item==shopItem[SOCK])
	{
		War3_SetBuffItem(client,fLowGravityItem,shopItem[SOCK],1.0);
	}
	else if(item==shopItem[HEALTH]&&ValidPlayer(client))
	{
		War3_SetBuffItem(client,iAdditionalMaxHealth,shopItem[HEALTH],0);
		
		//War3_SetMaxHP(client,War3_GetMaxHP(client)-50);
		if(GetClientHealth(client)>War3_GetMaxHP(client)){
			SetEntityHealth(client,War3_GetMaxHP(client));
		}
	}
	else if(item==shopItem[BOOTS]){
		War3_SetBuffItem(client,fMaxSpeed,shopItem[BOOTS],1.0);
	}
	else if(item==shopItem[CLOAK])
	{
		War3_SetBuffItem(client,fInvisibilityItem,shopItem[CLOAK],1.0);
	}
	if(item==shopItem[NECKLACE]) // immunity
	{
		War3_SetBuffItem(client,bImmunityUltimates,shopItem[NECKLACE],false);
	}
	if(item==shopItem[RING]) 
	{
		War3_SetBuffItem(client,fHPRegen,shopItem[RING],0.0);
	}
}
///change ownership only, DO NOT RESET BUFFS here, do that in OnItemLost
public OnWar3EventDeath(client){
	if (ValidPlayer(client))
	{
		bDidDie[client]=true;
		
		if(War3_GetOwnsItem(client,shopItem[BOOTS])) // boots
		{
			War3_SetOwnsItem(client,shopItem[BOOTS],false);
			War3_SetBuffItem(client,fMaxSpeed,shopItem[BOOTS],1.0);
		}
		if(War3_GetOwnsItem(client,shopItem[SOCK]))
		{
			War3_SetOwnsItem(client,shopItem[SOCK],false);
			War3_SetBuffItem(client,fLowGravityItem,shopItem[SOCK],1.0);
		}
		if(War3_GetOwnsItem(client,shopItem[CLAW])) // claws
		{
			War3_SetOwnsItem(client,shopItem[CLAW],false);
		}
		if(War3_GetOwnsItem(client,shopItem[CLOAK]))
		{
			War3_SetOwnsItem(client,shopItem[CLOAK],false); // cloak
			War3_SetBuffItem(client,fInvisibilityItem,shopItem[CLOAK],1.0);
		}
		if(War3_GetOwnsItem(client,shopItem[MASK]))
		{
			War3_SetOwnsItem(client,shopItem[MASK],false); // mask of death
		}
		if(War3_GetOwnsItem(client,shopItem[NECKLACE])) // immunity
		{
			War3_SetOwnsItem(client,shopItem[NECKLACE],false);
		}
		if(War3_GetOwnsItem(client,shopItem[FROST])) // orb of frost
		{
			War3_SetOwnsItem(client,shopItem[FROST],false);
		}
		if(War3_GetOwnsItem(client,shopItem[HEALTH]))
		{
			War3_SetOwnsItem(client,shopItem[HEALTH],false);
		}
		if(War3_GetGame()==Game_CS && War3_GetOwnsItem(client,shopItem[GLOVES])) // gloves
		{
			War3_SetOwnsItem(client,shopItem[GLOVES],false);
		}
		if(War3_GetOwnsItem(client,shopItem[RING])) // regen
		{
			War3_SetOwnsItem(client,shopItem[RING],false);
			
		}
		//dont delete mole
		if(War3_GetGame()!=Game_TF && War3_GetOwnsItem(client,shopItem[RESPAWN]))//&&!bSpawnedViaScrollRespawn[client])
		{
			CreateTimer(1.25,RespawnPlayerViaScrollRespawn,client);  ///default orc is 1.0, 1.25 so orc activates first
			
		}
	}
}

public Action:DoAnkhAction(Handle:t,any:client){ //just respawned, passed that he didnt respawn from scroll, too bad if he respawned from orc or mage
	GivePlayerCachedDeathWPNFull(INVALID_HANDLE,client);
	War3_SetOwnsItem(client,shopItem[ANKH],false);
	War3_ChatMessage(client,"%T","You reincarnated with all your gear",client);
	
}
public Action:GivePlayerCachedDeathWeapons(Handle:t,any:client){ //not used because all items give full ammo in this case
	if(ValidPlayer(client,true)){
		for(new s=0;s<10;s++)
		{
			new ent=GetEntDataEnt2(client,MyWeaponsOffset+(s*4));
			if(ent>0 && IsValidEdict(ent))
			{
				new String:ename[64];
				GetEdictClassname(ent,ename,sizeof(ename));
				if(StrEqual(ename,"weapon_c4") || StrEqual(ename,"weapon_knife"))
				{
					continue; // DONT REMOVE THESE
				}
				W3DropWeapon(client,ent);
				UTIL_Remove(ent);
			}
		}
		// restore iAmmo
		for(new s=0;s<32;s++)
		{
			SetEntData(client,AmmoOffset+(s*4),War3_CachedDeadAmmo(client,s),4);
		}
		// give them their weapons
		for(new s=0;s<10;s++)
		{
			new String:wep_check[64];
			War3_CachedDeadWeaponName(client,s,wep_check,sizeof(wep_check));
			if(!StrEqual(wep_check,"") && !StrEqual(wep_check,"",false) && !StrEqual(wep_check,"weapon_c4") && !StrEqual(wep_check,"weapon_knife"))
			{
				new wep_ent=GivePlayerItem(client,wep_check);
				if(wep_ent>0) //DONT SET LESS AMMO ON FULL
				{
					SetEntData(wep_ent,Clip1Offset,War3_CachedDeadClip1(client,s),4);
				}
			}
		}
		War3_SetCSArmor(client,100);
		War3_SetCSArmorHasHelmet(client,true);
	}
}
public Action:GivePlayerCachedDeathWPNFull(Handle:h,any:client){
	if(ValidPlayer(client,true)){
		for(new s=0;s<10;s++)
		{
			new ent=GetEntDataEnt2(client,MyWeaponsOffset+(s*4));
			if(ent>0 && IsValidEdict(ent))
			{
				new String:ename[64];
				GetEdictClassname(ent,ename,sizeof(ename));
				if(StrEqual(ename,"weapon_c4") || StrEqual(ename,"weapon_knife"))
				{
					continue; // DONT REMOVE THESE
				}
				W3DropWeapon(client,ent);
				UTIL_Remove(ent);
			}
		}
		///NO RESETTING AMMO FOR FULL AMMO???
		// restore iAmmo    
		//for(new s=0;s<32;s++)
		//{
		//	SetEntData(client,AmmoOffset+(s*4),War3_CachedDeadAmmo(client,s),4);
		//}
		// give them their weapons
		for(new s=0;s<10;s++)
		{
			new String:wep_check[64];
			War3_CachedDeadWeaponName(client,s,wep_check,sizeof(wep_check));
			if(!StrEqual(wep_check,"") && !StrEqual(wep_check,"",false) && !StrEqual(wep_check,"weapon_c4") && !StrEqual(wep_check,"weapon_knife"))
			{
				//new wep_ent=
				GivePlayerItem(client,wep_check);
				//if(wep_ent>0)//DONT SET LESS AMMO ON FULL
				//{
				//	SetEntData(wep_ent,Clip1Offset,War3_CachedDeadClip1(client,s),4);
				//}
			}
		}
		War3_SetCSArmor(client,100);
		War3_SetCSArmorHasHelmet(client,true);
	}
}









public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(War3_GetGame()!=Game_TF)
	{
		if(!GetConVarBool(MoleDeathmatchCvar))
		{
			for(new x=1;x<=MaxClients;x++)
			{
				if(ValidPlayer(x,true)&&GetClientTeam(x)>1&&War3_GetOwnsItem(x,shopItem[MOLE]))
				{
					StartMole(x);
				}
			}
		}
	}
}

public StartMole(client)
{
	new Float:mole_time=5.0;
	PrintHintText(client,"%T","WARNING! MOLE IN {amount} SECONDS (item)!",client,mole_time);
	War3_ChatMessage(client,"%T","WARNING! MOLE IN {amount} SECONDS (item)!",client,mole_time);
	CreateTimer(0.2+mole_time,DoMole,client);
}
public Action:DoMole(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		new team=GetClientTeam(client);
		new searchteam=(team==2)?3:2;
		
		new Float:emptyspawnlist[100][3];
		new availablelocs=0;
		
		new Float:playerloc[3];
		new Float:spawnloc[3];
		new ent=-1;
		while((ent = FindEntityByClassname(ent,(searchteam==2)?"info_player_terrorist":"info_player_counterterrorist"))!=-1)
		{
			if(!IsValidEdict(ent)) continue;
			GetEntDataVector(ent,OriginOffset,spawnloc);
			
			new bool:is_conflict=false;
			for(new i=1;i<=MaxClients;i++)
			{
				if(ValidPlayer(i,true)){
					GetClientAbsOrigin(i,playerloc);
					if(GetVectorDistance(spawnloc,playerloc)<60.0)
					{
						is_conflict=true;
						break;
					}				
				}
			}
			if(!is_conflict)
			{
				emptyspawnlist[availablelocs][0]=spawnloc[0];
				emptyspawnlist[availablelocs][1]=spawnloc[1];
				emptyspawnlist[availablelocs][2]=spawnloc[2];
				availablelocs++;
			}
		}
		if(availablelocs==0)
		{
			War3_ChatMessage(client,"%T","This map does not have enemy spawn points, can not mole!",client);
			return;
		}
		GetClientModel(client,sOldModel[client],256);
		if(War3_GetGame() == Game_CS) {
			SetEntityModel(client,(searchteam==2)?"models/player/t_leet.mdl":"models/player/ct_urban.mdl");
		}
		else {
			SetEntityModel(client,(searchteam==2)?"models/player/tm_leet.mdl":"models/player/ctm_gsg9.mdl");
		}
		TeleportEntity(client,emptyspawnlist[GetRandomInt(0,availablelocs-1)],NULL_VECTOR,NULL_VECTOR);
		War3_ChatMessage(client,"%T","You have moled!",client);
		PrintHintText(client,"%T","You have moled!",client);
		War3_ShakeScreen(client,1.0,20.0,12.0);
		CreateTimer(10.0,ResetModel,client);
		
		War3_SetOwnsItem(client,shopItem[MOLE],false) ;
	}
	return;
}
public Action:ResetModel(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		SetEntityModel(client,sOldModel[client]);
		War3_ChatMessage(client,"%T","You are no longer disguised",client);
	}
}


public OnWar3EventSpawn(client){
	if( bFrosted[client])
	{
		bFrosted[client]=false;
		War3_SetBuffItem(client,fSlow,shopItem[FROST],1.0);
	}
	if(War3_GetGame()==Game_CS && (War3_GetOwnsItem(client,shopItem[ANKH])||W3IsDeveloper(client)) && bDidDie[client])
	{
		if(!bSpawnedViaScrollRespawn[client]){ //only if he didnt already respawn from the "respawn item" cuz that gives items too

			CreateTimer(0.1,DoAnkhAction,client);
		}
		
	}
	if(War3_GetOwnsItem(client,shopItem[HEALTH]))
	{
		//SetEntityHealth(client,GetClientHealth(client)+50);
		War3_SetBuffItem(client,iAdditionalMaxHealth,shopItem[HEALTH],50);
		//War3_SetMaxHP(client,War3_GetMaxHP(client)+50);
		War3_ChatMessage(client,"%T","+50 HP",client);
	}
	if(War3_GetOwnsItem(client,shopItem[SOCK]))
	{
		War3_SetBuffItem(client,fLowGravityItem,shopItem[SOCK],GetConVarFloat(SockCvar));
		//War3_SetMinGravity(client,GetConVarFloat(SockCvar),shopItem[10]);
		War3_ChatMessage(client,"%T","You pull on your socks",client);
	}
	if(War3_GetGame()!=Game_TF && War3_GetOwnsItem(client,shopItem[MOLE]) && GetConVarBool(MoleDeathmatchCvar)) // deathmatch
	{
		StartMole(client);
	}
	bDidDie[client]=false;
	
}


public Action:RespawnPlayerViaScrollRespawn(Handle:h,any:client)
{
	if(ValidPlayer(client)&&!IsPlayerAlive(client)) //not revived from something else
	{
		bSpawnedViaScrollRespawn[client]=true; ///prevent ankh from activating
		CS_RespawnPlayer(client);
		PrintCenterText(client,"%T","RESPAWNED!",client);
		CreateTimer(0.2,GivePlayerCachedDeathWPNFull,client);
		bSpawnedViaScrollRespawn[client]=false;
		War3_SetOwnsItem(client,shopItem[RESPAWN],false);
		War3_ChatMessage(client,"%T","Respawned by Scroll of Respawning",client);
		CreateTimer(1.0,NoLongerSpawnedViaScroll,client);
	}
}
public Action:NoLongerSpawnedViaScroll(Handle:t,any:client){
	bSpawnedViaScrollRespawn[client]=false;
}



public OnWar3EventPostHurt(victim,attacker,damage){
	if(W3GetDamageIsBullet()&&ValidPlayer(victim)&&ValidPlayer(attacker,true)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		//DP("bullet 1 claw %d vic alive%d",War3_GetOwnsItem(attacker,shopItem[CLAW]),ValidPlayer(victim,true,true));
		//new vteam=GetClientTeam(victim);
		//new ateam=GetClientTeam(attacker);
		
		if(!W3HasImmunity(victim,Immunity_Items)&&!Perplexed(attacker))
		{
			if(War3_GetOwnsItem(attacker,shopItem[CLAW])&&ValidPlayer(victim,true,true)) // claws of attack
			{
				new Float:dmg=GetConVarFloat(ClawsAttackCvar);
				if(dmg<0.0) 	dmg=0.0;
				
				//SetEntityHealth(victim,new_hp);
				if(GameTF()){
					//DP("%f",W3ChanceModifier(attacker));
					if(W3ChanceModifier(attacker)<0.99){
					dmg*=W3ChanceModifier(attacker);
					}
					else{
						dmg*=0.50;
					}
				}
			//	DP("%f",dmg);
				if(War3_DealDamage(victim,RoundFloat(dmg),attacker,_,"claws",W3DMGORIGIN_ITEM,W3DMGTYPE_PHYSICAL)){ //real damage with indicator
				
					PrintToConsole(attacker,"%T","+{amount} Claws Damage",attacker,War3_GetWar3DamageDealt());
				}
			}
				
			if( War3_GetOwnsItem(attacker,shopItem[FROST]) && !bFrosted[victim]  )
			{
				new Float:speed_frost=GetConVarFloat(OrbFrostCvar);
				if(speed_frost<=0.0) speed_frost=0.01; // 0.0 for override removes
				if(speed_frost>1.0)	speed_frost=1.0;
				War3_SetBuffItem(victim,fSlow,shopItem[FROST],speed_frost);
				bFrosted[victim]=true;
				
				PrintToConsole(attacker,"%T","ORB OF FROST!",attacker);
				PrintToConsole(victim,"%T","Frosted, reducing your speed",victim);
				CreateTimer(2.0,Unfrost,victim);
			}
	

			if(War3_GetOwnsItem(attacker,shopItem[MASK])) // Mask of death
			{
				new Float:hp_percent=GetConVarFloat(MaskDeathCvar);
				if(hp_percent<0.0)	hp_percent=0.0;
				if(hp_percent>1.0)	hp_percent=1.0;  //1 = 100%
				new add_hp=RoundFloat(FloatMul(float(damage),hp_percent));
				if(add_hp>40)	add_hp=40; // awp or any other weapon, just limit it
				War3_HealToBuffHP(attacker,add_hp);
				/*
				tock EmitSoundToAll(const String:sample[],
	                 entity = SOUND_FROM_PLAYER,
	                 channel = SNDCHAN_AUTO,
	                 level = SNDLEVEL_NORMAL,
	                 flags = SND_NOFLAGS,
	                 Float:volume = SNDVOL_NORMAL,
	                 pitch = SNDPITCH_NORMAL,
	                 speakerentity = -1,
	                 const Float:origin[3] = NULL_VECTOR,
	                 const Float:dir[3] = NULL_VECTOR,
	                 bool:updatePos = true, */
	                 
				if(War3_TrackDelayExpired(maskSoundDelay[attacker])){
					EmitSoundToAll(masksnd,attacker);
					War3_TrackDelay(maskSoundDelay[attacker],0.25);
				}
				if(War3_TrackDelayExpired(maskSoundDelay[victim])){
					EmitSoundToAll(masksnd,victim);
					War3_TrackDelay(maskSoundDelay[victim],0.25);
				}
				PrintToConsole(attacker,"%T","+{amount} Mask leeched HP",attacker,add_hp);
			}
		}
	}
}
public Action:Unfrost(Handle:timer,any:client)
{
	bFrosted[client]=false;
	//War3_SetOverrideSpeed(client,0.0,shopItem[6]);
	War3_SetBuffItem(client,fSlow,shopItem[FROST],1.0);
	if(ValidPlayer(client))
	{
	
		PrintToConsole(client,"%T","REGAINED SPEED from frost",client);
	}
}


public Action:cmdfrostme(victim,args){

	W3ApplyBuffSimple(victim,fSlow,0,0.1,2.0);
	//War3_SetBuffItem(victim,fSlow,shopItem[FROST],0.1);
	
	//bFrosted[victim]=true;
	
	PrintToConsole(victim,"%T","Frosted, reducing your speed",victim);
	CreateTimer(2.0,Unfrost,GetClientUserId(victim));
}


public OnWar3Event(W3EVENT:event,client){
	if(event==ClearPlayerVariables){
		bDidDie[client]=false;
	}
}