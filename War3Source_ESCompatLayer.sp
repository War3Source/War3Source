/**
* File: War3Source_Engine_ESCompatLayer.sp
* Description: Support for the ES race format.
* Since WCS restricts the sale of content, this is a great option for transition! You may sell War3 content forever and always ;]
* Author(s): Anthony Iacono and Derek Ownz
*/

#pragma semicolon 1
#pragma dynamic 40000					
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>

new String:g_EventList[][32] = {
"intro_finish",
"intro_nextcamera",
"player_changeclass",
"player_death",
"object_removed",
"object_destroyed",
"tf_map_time_remaining",
"tf_game_over",
"ctf_flag_captured",
"controlpoint_initialized",
"controlpoint_updateimages",
"controlpoint_updatelayout",
"controlpoint_updatecapping",
"controlpoint_updateowner",
"controlpoint_starttouch",
"controlpoint_endtouch",
"controlpoint_pulse_element",
"controlpoint_fake_capture",
"controlpoint_fake_capture_mult",
"teamplay_round_selected",
"teamplay_round_start",
"teamplay_round_active",
"teamplay_waiting_begins",
"teamplay_waiting_ends",
"teamplay_waiting_abouttoend",
"teamplay_restart_round",
"teamplay_ready_restart",
"teamplay_round_restart_seconds",
"teamplay_team_ready",
"teamplay_round_win",
"teamplay_update_timer",
"teamplay_round_stalemate",
"teamplay_overtime_begin",
"teamplay_overtime_end",
"teamplay_suddendeath_begin",
"teamplay_suddendeath_end",
"teamplay_game_over",
"teamplay_map_time_remaining",
"teamplay_broadcast_audio",
"teamplay_timer_flash",
"teamplay_timer_time_added",
"teamplay_point_startcapture",
"teamplay_point_captured",
"teamplay_point_locked",
"teamplay_point_unlocked",
"teamplay_capture_broken",
"teamplay_capture_blocked",
"teamplay_flag_event",
"teamplay_win_panel",
"teamplay_teambalanced_player",
"teamplay_setup_finished",
"show_freezepanel",
"hide_freezepanel",
"freezecam_started",
"localplayer_changeteam",
"localplayer_score_changed",
"localplayer_changeclass",
"localplayer_respawn",
"building_info_changed",
"localplayer_changedisguise",
"player_account_changed",
"spy_pda_reset",
"flagstatus_update",
"player_stats_updated",
"playing_commentary",
"player_chargedeployed",
"player_builtobject",
"player_upgradedobject",
"achievement_earned",
"spec_target_updated",
"tournament_stateupdate",
"player_calledformedic",
"localplayer_becameobserver",
"player_ignited_inv",
"player_ignited",
"player_extinguished",
"player_teleported",
"player_healedmediccall",
"localplayer_chargeready",
"localplayer_winddown",
"player_invulned",
"escort_speed",
"escort_progress",
"escort_recede",
"client_loadout_changed",
"gameui_activated",
"gameui_hidden",
"player_escort_score",
"player_healonhit",
"player_stealsandvich",
"show_class_layout",
"show_vs_panel",
"player_damaged",
"player_hurt",
"arena_player_notification",
"arena_match_maxstreak",
"arena_round_start",
"arena_win_panel",
"inventory_updated",
"air_dash",
"landed",
"player_damage_dodged",
"player_stunned",
"scout_grand_slam",
"scout_slamdoll_landed",
"arrow_impact",
"player_jarated",
"player_jarated_fade",
"player_shield_blocked",
"player_pinned",
"player_healedbymedic",
"player_spawn",
"player_sapped_object",
"item_found",
"show_annotations",
"hide_annotations",
"post_inventory_application",
"controlpoint_unlock_updated",
"deploy_buff_banner",
"player_buff",
"medic_death",
"overtime_nag",
"teams_changed",
"halloween_pumpkin_grab",
"rocket_jump",
"rocket_jump_landed",
"sticky_jump",
"sticky_jump_landed",
"medic_defended",
"localplayer_healed",
"player_destroyed_pipebomb",
"object_deflected",
"player_mvp",
"raid_spawn_mob",
"raid_spawn_squad",
"nav_blocked",
"path_track_passed",
"num_cappers_changed",
"player_regenerate",
"update_status_item",
"cart_updated",
"store_pricesheet_updated",
"stats_resetround",
"gc_connected",
"item_schema_initialized",
"achievement_earned_local",
"player_healed",
"item_pickup",
"duel_status",
"fish_notice",
"pumpkin_lord_summoned",
"pumpkin_lord_killed",
"bomb_abortdefuse",
"bomb_abortplant",
"bomb_beep",
"bomb_begindefuse",
"bomb_beginplant",
"bomb_defused",
"bomb_dropped",
"bomb_exploded",
"bomb_pickup",
"bomb_planted",
"break_breakable",
"break_prop",
"bullet_impact",
"door_moving",
"flashbang_detonate",
"game_end",
"game_message",
"game_start",
"grenade_bounce",
"hegrenade_detonate",
"hostage_call_for_help",
"hostage_follows",
"hostage_hurt",
"hostage_killed",
"hostage_rescued",
"hostage_rescued_all",
"hostage_stops_following",
"player_activate",
"player_blind",
"player_changename",
"player_chat",
"player_class",
"player_connect",
"player_disconnect",
"player_falldamage",
"player_footstep",
"player_info",
"player_jump",
"player_radio",
"player_say",
"player_score",
"player_shoot",
"player_team",
"player_use",
"round_end",
"round_freeze_end",
"round_start",
"server_addban",
"server_cvar",
"server_message",
"server_removeban",
"server_shutdown",
"smokegrenade_detonate",
"vip_escaped",
"vip_killed",
"weapon_fire",
"weapon_fire_on_empty",
"weapon_reload",
"weapon_zoom",
"nav_generate"
};

new String:g_EventKeyList[][32] = {
"userid",
"attacker",
"weapon",
"headshot",
"health",
"armor",
"dmg_health",
"dmg_armor",
"hitgroup",
"site",
"posx",
"posy",
"haskit",
"hostage",
"slot",
"entindex",
"item",
"x",
"y",
"z",
"damage",
"area",
"blocked",
"teamid",
"teamname",
"score",
"oldteam",
"disconnect",
"autoteam",
"silent",
"name",
"class",
"teamonly",
"text",
"kills",
"deaths",
"mode",
"entity",
"oldname",
"newname",
"mapname",
"roundslimit",
"timelimit",
"fraglimit",
"objective",
"winner",
"reason",
"message",
"target",
"material",
"entindex_killed",
"entindex_attacker",
"entindex_inflictor",
"damagebits",
"numadvanced",
"numbronze",
"numsilver",
"numgold",
"achievement_name",
"cur_val",
"max_val",
"achievement_id",
"hostname",
"address",
"port",
"game",
"maxplayers",
"os",
"dedicated",
"password",
"cvarname",
"cvarvalue",
"networkid",
"ip",
"duration",
"by",
"kicked",
"bot",
"player",
"victim_entindex",
"inflictor_entindex",
"weaponid",
"customkill",
"assister",
"weapon_logclassname",
"stun_flags",
"death_flags",
"silent_kill",
"dominated",
"assister_dominated",
"revenge",
"assister_revenge",
"first_blood",
"feign_death",
"objecttype",
"index",
"was_building",
"seconds",
"capping_team",
"capping_team_score",
"int_data",
"full_reset",
"winreason",
"team",
"flagcaplimit",
"full_round",
"round_time",
"losing_team_num_caps",
"was_sudden_death",
"sound",
"time_remaining",
"timer",
"seconds_added",
"cp",
"cpname",
"capteam",
"cappers",
"captime",
"blocker",
"carrier",
"eventtype",
"panel_style",
"winning_team",
"blue_score",
"red_score",
"blue_score_prev",
"red_score_prev",
"round_complete",
"rounds_remaining",
"player_1",
"player_1_points",
"player_2",
"player_2_points",
"player_3",
"player_3_points",
"killer",
"object_mode",
"building_type",
"remove",
"disguised",
"old_value",
"new_value",
"forceupload",
"isbuilder",
"achievement",
"namechange",
"readystate",
"pyro_entindex",
"medic_entindex",
"dist",
"medic_userid",
"speed",
"players",
"progress",
"reset",
"recedetime",
"points",
"owner",
"amount",
"show",
"damageamount",
"crit",
"minicrit",
"allseecrit",
"streak",
"player_1_healing",
"player_1_damage",
"player_1_lifetime",
"player_1_kills",
"player_2_healing",
"player_2_damage",
"player_2_lifetime",
"player_2_kills",
"player_3_healing",
"player_3_damage",
"player_3_lifetime",
"player_3_kills",
"player_4_healing",
"player_4_damage",
"player_4_lifetime",
"player_4_kills",
"player_5_healing",
"player_5_damage",
"player_5_lifetime",
"player_5_kills",
"player5",
"player_6_healing",
"player_6_damage",
"player_6_lifetime",
"player_6_kills",
"player6",
"victim_capping",
"stunner",
"big_stun",
"scout_id",
"target_id",
"attachedEntity",
"shooter",
"boneIndexAttached",
"bonePositionX",
"bonePositionY",
"bonePositionZ",
"boneAnglesX",
"boneAnglesY",
"boneAnglesZ",
"thrower_entindex",
"pinned",
"sapperid",
"quality",
"method",
"propername",
"worldPosX",
"worldPosY",
"worldPosZ",
"buff_type",
"buff_owner",
"healing",
"charged",
"count",
"patient",
"healer",
"score_type",
"initiator",
"initiator_score",
"target_score"
};

new Handle:hCurrentEventData = INVALID_HANDLE;
new Handle:hWCSRaces = INVALID_HANDLE;
 
public Plugin:myinfo = 
{
	name = "War3 Engine ESCompatLayer",
	author = "Anthony & Ownz",
	description = "Support for the ES race format.",
	version = "1.0.0.0",
	url = "http://war3source.com"
};

bool:ESCheck()
{
	new Handle:hVar = FindConVar("eventscripts_ver");
	if(hVar)
	{
		return true;
	}
	return false;
}

bool:ESTCheck()
{
	new Handle:hVar = FindConVar("est_version");
	if(hVar)
	{
		return true;
	}
	return false;
}

String:firstchar(const String:buffer[])
{
	return buffer[0];
}

String:lastchar(const String:buffer[])
{
	return buffer[strlen(buffer)-1];
}

new Handle:g_ToDelete = INVALID_HANDLE;

// Last resort to help with the handles.
ClearDeletionQueue()
{
	ClearArray(g_ToDelete);
}

AddToDeletionQueue(Handle:h)
{
	new c = GetArraySize(g_ToDelete);
	new bool:found=false;    
	for(new x=0;x<c;x++)
	{
		if(GetArrayCell(g_ToDelete,x)==h)
		{
			found=true;
			break;
		}
	}
	if(!found)
	{
		PushArrayCell(g_ToDelete,h);
	}
}

ExecDeletionQueue()
{
	new c = GetArraySize(g_ToDelete);
	for(new x=0;x<c;x++)
	{
		new Handle:h = GetArrayCell(g_ToDelete,x);
		if(h)
		{
			CloseHandle(h);
		}
	}   
}

// Parse out WC:S race file format.
// It is like INI but a bit different.
// error_type 1 = open error
// error_type 2 = parsing error
bool:wcsfile_parse(const String:path[], Handle:arrayHandle, &error_type, &lnum, &Handle:fileHandle)
{
	// If false is returned, lnum and lpos will be set to error pos.
	new Handle:hFile = OpenFile(path, "r");
	fileHandle = hFile;
	if(!hFile)
	{
		error_type = 1;                      
		return false;
	}
	// Take it line by line,
	// If the first non-whitespace character of the line is a #, then its a comment line.
	new String:line[4096];
	// Create a handle in outHandle, we can nest Kv's.
	new Handle:sectionKV = INVALID_HANDLE;
	new String:currentSubsection[64];
	new String:currentSection[64];
	new Handle:keysArray = INVALID_HANDLE;
	new lnum_track;
	while(ReadFileLine(hFile, line, sizeof(line)))
	{
		lnum_track++;
		// First of all, trim it.
		TrimString(line);
		new len = strlen(line);
		if(len>0) // Else, empty line.
		{
			new String:first=firstchar(line);
			new String:last=lastchar(line);
			if(first=='#')
			{
				continue; // This line is a comment.
			}
			else if(first=='[')
			{
				if(len<2)
				{
					error_type = 2; // parsing error (no section defined)
					lnum = lnum_track;
					return false;
				}
				if(last==']')
				{
					if(line[1]=='[')
					{
						if(line[len-2]==']')
						{
							// Take from 2 - len-3
							if(len<5)
							{
								error_type = 2; // parsing error
								lnum = lnum_track;
								return false;
							}
							else
							{
								if(!sectionKV)
								{
									error_type = 2; // parsing error
									lnum = lnum_track;
									return false;
								}
								strcopy(currentSubsection, len-3, line[2]);
							}
						}
						else
						{
							error_type = 2; // parsing error
							lnum = lnum_track;
							return false;
						}
					}
					else
					{
						if(len<3)
						{
							error_type = 2; // parsing error
							lnum = lnum_track;
							return false;
						}
						strcopy(currentSection, len-1, line[1]);
						if(!WCSValidSection(currentSection))
						{
							error_type = 2; // parsing error
							lnum = lnum_track;
							return false;							
						}
						Format(currentSubsection, sizeof(currentSubsection), "");
						sectionKV = CreateKeyValues(currentSection);
						keysArray = CreateArray(64);
						AddToDeletionQueue(sectionKV);
						AddToDeletionQueue(keysArray);
						KvSetNum(sectionKV, "keys", _:keysArray);
						PushArrayCell(arrayHandle, sectionKV);
					}					
				}
				else
				{
					error_type = 2; // parsing error (no section defined)
					lnum = lnum_track;
					return false;
				}
			}
			else
			{
				// This must be a:
				// something = value
				// or
				// something="value"
				if(!sectionKV)
				{
					error_type = 2; // parsing error (no section defined)
					lnum = lnum_track;
					return false;
				}
				new String:keyName[64];
				new String:keyValue[1024];
				new cur_state = 0; // scanning name
				// 1 = scanning value
				for(new x=0;x<len;x++)
				{
					new String:cAt = line[x];
					if(cur_state==0)
					{
						if(cAt=='=')
						{
							cur_state = 1;
							continue;
						}
						else
						{
							Format(keyName, sizeof(keyName), "%s%c", keyName, cAt);
						}
					}
					else
					{
						Format(keyValue, sizeof(keyValue), "%s%c", keyValue, cAt);
					}
				}
				TrimString(keyName);
				TrimString(keyValue);
				StripQuotes(keyValue);
				if(cur_state!=1 || !WCSValidKeyName(keyName))
				{
					error_type = 2; // parsing error.
					lnum = lnum_track;
					return false;
				}
				// insert into sectionKV as subsection_key
				// that means roots will be under _key
				new String:realKey[128];
				Format(realKey, sizeof(realKey), "%s_%s", currentSubsection, keyName);
				KvSetString(sectionKV, realKey, keyValue);
				if(keysArray)
				{
					PushArrayString(keysArray, realKey);
				} 	
			}	
		}
	}
	return true;
}

bool:WCSValidSection(const String:kName[])
{
	new len=strlen(kName);
	if(len<1)
	{
		return false;
	}
	for(new x=0;x<len;x++)
	{
		if(!((kName[x]>='A' && kName[x]<='Z') || (kName[x]>='a' && kName[x]<='z') || (kName[x]>='0' && kName[x]<='9') || kName[x]==' ' || kName[x]=='_' || kName[x]=='=' || kName[x]=='-' || kName[x]=='.' || kName[x]=='!' || kName[x]==',' || kName[x]=='<' || kName[x]=='>'))
		{
			return false;
		}
	}
	return true;
}

bool:WCSValidKeyName(const String:kName[])
{
	new len=strlen(kName);
	if(len<1)
	{
		return false;
	}
	for(new x=0;x<len;x++)
	{
		if(!((kName[x]>='A' && kName[x]<='Z') || (kName[x]>='a' && kName[x]<='z') || (kName[x]>='0' && kName[x]<='9') || kName[x]==' ' || kName[x]=='_'))
		{
			return false;
		}
	}
	return true;
}

TestRecurse(Handle:kv)
{
	new index = 1;
	new String:keyName[256];
	while(KvFindKeyById(kv, index, keyName, 256))
	{
		PrintToServer("%d: %s", index, keyName);
		index++;
	}
}

War3_LoadWCSRaces()
{
	new ecode;
	new lnum;
	new String:racesPath[1024];
	BuildPath(Path_SM, racesPath, sizeof(racesPath), "configs/races.ini");
	new Handle:fileArray = CreateArray();
	new Handle:fHandle = INVALID_HANDLE;
	new bool:result = wcsfile_parse(racesPath, fileArray, ecode, lnum, fHandle);
	if(fHandle)
	{
		CloseHandle(fHandle);
	}
	if(!result)
	{
		ExecDeletionQueue(); // Auto clean up.
		if(ecode==1)
		{
			if(FileExists(racesPath))
			{
				PrintToServer("[War3Source] Error opening configs/races.ini even though it exists.");
			}
		}
		else if(ecode==2)
		{
			PrintToServer("[War3Source] Error parsing WCS race file at line %d.", lnum);
		}
	}
	else
	{
		// Things will be deleted properly without the delete queue, just clear it.
		ClearDeletionQueue();
		new size = GetArraySize(fileArray);
		for(new x=0;x<size;x++)
		{
			new Handle:curRace = GetArrayCell(fileArray, x);
			new Handle:keysArray = Handle:KvGetNum(curRace, "keys"); // This is a list of all key names.
			/*for(new y=0;y<GetArraySize(keysArray);y++) // Just a test recurse and print.
			{
				new String:keyValue[1024];
				new String:keyName[64];
				GetArrayString(keysArray, y, keyName, sizeof(keyName));
				KvGetString(curRace, keyName, keyValue, sizeof(keyValue));
				PrintToServer("[%s] - %s", keyName, keyValue);
			}*/
			new String:raceName[64];
			KvGetSectionName(curRace, raceName, sizeof(raceName));
			new numberofskills = KvGetNum(curRace, "_numberofskills");	
			//WCS_StartCreateRace(raceName, required,maximum,restrictmap,restrictteam,restrictitem,author,desc,spawncmd,deathcmd,roundstartcmd,roundendcmd,preloadcmd,allowonly,onchange,numberofskills,numberoflevels,skillnames,skilldescr,skillcfg,skillneeded);			
/*			new String:shortName[16];
			GenShortName(raceName, shortName, sizeof(shortName));
			*/			

			CloseHandle(curRace); // Close key value.
			CloseHandle(keysArray); // Close list of all key names.
		}
		PrintToServer("Total of %d races", size);
	}
	CloseHandle(fileArray); // Close the array of key values.
}

public OnMapStart()
{
	ClearDeletionQueue();
	ClearArray(hWCSRaces);
	War3_LoadWCSRaces();
}

// For ..., there should be numberofskills * 3 params + optional race alias'es in multiples of two params (aliasname, value)
public WCS_StartCreateRace(const String:raceName[],required,maximum,const String:restrictmap[],restrictteam,const String:restrictitem[],const String:author[],
				const String:desc[],const String:spawncmd[],const String:deathcmd[],const String:roundstartcmd[],
				const String:roundendcmd[],const String:preloadcmd[],const String:allowonly[],const String:onchange[],
				numberofskills,numberoflevels,const String:skillnames[],const String:skilldescr[],const String:skillcfg[],
				const String:skillneeded[])
{
/*
  			if(numberOfSkills>=1)
			{
				PrintToServer("Creating %s (%s) with %d skills", raceName, shortName, numberOfSkills);
				new raceID = War3_CreateNewRace(raceName, shortName);
				for(new y=1;y<=numberOfSkills;y++)
				{
					new String:keyName[64];
					
					//War3_AddRaceSkill(raceID, skillName, skillDesc,(x==numberOfSkills),maxskilllevel=DEF_MAX_SKILL_LEVEL);
				}
				War3_CreateRaceEnd(raceID);
				if(requiredLevel>0)
				{
					Format(tString, sizeof(tString), "%s_minlevel", shortName);
					new var = W3FindCvar(tString);
					new String:tString2[1024];
					Format(tString2, sizeof(tString2), "%d", requiredLevel);
					if(var>=0)
					{
						W3SetCvar(var, tString2);
					}					
				}
				if(!StrEqual(restrictItems,"") && !StrEqual(restrictItems,"0"))
				{
					Format(tString, sizeof(tString), "%s_restrict_items", shortName);
					new var = W3FindCvar(tString);
					if(var>=0)
					{
						W3SetCvar(var, restrictItems);
					}
				}
				if(restrictTeam>1)
				{
					if(restrictTeam==2)
					{
						Format(tString, sizeof(tString), "%s_team1_limit", shortName);
					}
					else if(restrictTeam==3)
					{
						Format(tString, sizeof(tString), "%s_team2_limit", shortName);
					}
					new var = W3FindCvar(tString);
					if(var>=0)
					{
						W3SetCvar(var, "0");
					}
				}
			}
			else
			{
			}	
*/
}

public WCS_EndCreateRace(raceID)
{
	
}

GenShortName(const String:buffer[], String:out[], maxlen)
{
	Format(out, maxlen, "");
	new len = strlen(buffer);
	for(new x=0;x<len;x++)
	{
		if( (buffer[x]>='A' && buffer[x]<='Z') || (buffer[x]>='a' && buffer[x]<='z') || (buffer[x]>='0' && buffer[x]<='9') )
		{
			Format(out, maxlen, "%s%c", out, CharToLower(buffer[x]));
		}
	}
}

// War3Source Functions
public OnPluginStart()
{
	g_ToDelete = CreateArray();
	hWCSRaces = CreateArray();
	ClearDeletionQueue();
	RegServerCmd("war3_if", War3EngIf, "Logical statement.");
	RegServerCmd("war3_xif", War3EngXIf, "Non-expanded logical statement.");		
	RegServerCmd("war3_setinfo", War3EngSetinfo, "Set a server variable.");
	RegServerCmd("war3_xsetinfo", War3EngXSetinfo, "Non expanded, set a server variable.");
	RegServerCmd("war3_set", War3EngSetinfo, "Set a server variable.");
	RegServerCmd("war3_xset", War3EngXSetinfo, "Non expanded, set a server variable.");
	RegServerCmd("war3_cmd", War3EngCmd, "Expanded command.");
	RegServerCmd("war3_getplayerlocation", War3EngGetPlayerLocation, "Expanded get player location.");
	RegServerCmd("war3_xgetplayerlocation", War3EngXGetPlayerLocation, "Non-expanded get player location.");
	RegServerCmd("war3_effect", War3EngEffect, "Expanded effect.");
	RegServerCmd("war3_xeffect", War3EngXEffect, "Non-expanded effect.");
	if(!ESCheck())
	{
		RegServerCmd("es_if", War3EngIf, "Logical statement.");
		RegServerCmd("es_xif", War3EngXIf, "Non-expanded logical statement.");
		RegServerCmd("if", War3EngIf, "Logical statement.");
		RegServerCmd("es_set", War3EngSetinfo, "Set a server variable.");
		RegServerCmd("es_xset", War3EngXSetinfo, "Non expanded, set a server variable.");		
		RegServerCmd("es", War3EngCmd, "Expanded command.");
		RegServerCmd("es_getplayerlocation", War3EngGetPlayerLocation, "Expanded get player location.");
		RegServerCmd("es_xgetplayerlocation", War3EngXGetPlayerLocation, "Non-expanded get player location.");
	}
	if(!ESTCheck())
	{
		RegServerCmd("est_effect", War3EngEffect, "Expanded effect.");
		RegServerCmd("est_xeffect", War3EngXEffect, "Non-expanded effect.");
	}
	for(new x=0;x<sizeof(g_EventList);x++)
	{
		if(EventExists(g_EventList[x]))
		{
		//	PrintToServer("Hooking event: %s", g_EventList[x]);
			HookEvent(g_EventList[x], GlobalEventCB, EventHookMode_Pre);
		}
	}
	hCurrentEventData = CreateKeyValues("event_data");
}

public Action:GlobalEventCB(Handle:event, const String:name[], bool:dontBroadcast)
{
	// The goal is to cache as many values as possible using a keyvalue that we can recurse through.
	new String:testStr[32];
	for(new x=0;x<sizeof(g_EventKeyList);x++)
	{
		GetEventString(event,g_EventKeyList[x],testStr,32);
		TrimString(testStr);
		if(!StrEqual(testStr, ""))
		{
			KvSetString(hCurrentEventData, g_EventKeyList[x], testStr);
		}
	}
}

bool:EventExists(const String:eventName[])
{
	new Handle:hTest = CreateEvent(eventName, true);
	if(hTest)
	{
		CancelCreatedEvent(hTest);
		return true;
	}
	return false;
}

bool:validExpressionChar(String:chr)
{
	if(chr=='-' || chr=='.' || (chr>='0' && chr<='9') || (chr>='a' && chr<='z') || (chr>='A' && chr<='Z') || chr=='_' || chr=='(' || chr==')')
	{
		return true;
	}
	return false;
}

bool:validExpressionChar2(String:chr)
{
	if(validExpressionChar(chr) || chr=='>' || chr=='<' || chr=='=' || chr=='!')
	{
		return true;
	}
	return false;
}

bool:IsNumber(const String:buffer[])
{
	new bool:decimal=false;
	new len = strlen(buffer);
	for(new x=0;x<len;x++)
	{
		if(buffer[x]=='-')
		{
			if(x!=0)
			{
				return false;				
			}
			else
			{
				continue;
			}
		}
		if(buffer[x]=='.')
		{
			if(decimal)
			{
				return false;
			}
			else
			{
				if(x==(len-1))
				{
					return false;
				}
				decimal=true;
			}
		}
		else if(buffer[x]<'0' || buffer[x]>'9')
		{
			return false;
		}
	}
	return true;
}

bool:nextchar(const String:buffer[], index, &String:nextchar)
{
	if(strlen(buffer)>index+1)
	{
		nextchar = buffer[index+1];
		return true;
	}
	return false;
}

bool:nextcharnonwhite(const String:buffer[], index, &String:nextchar, &fIndex)
{
	new len = strlen(buffer);
	for(new x=index+1;x<len;x++)
	{
		if(buffer[x]!=' ')
		{
			nextchar=buffer[x];
			fIndex=x;
			return true;
		}
	}
	return false;
}

public Action:War3Setinfo(arg_count, bool:expand)
{
	new String:buffer[600];
	new String:varName[64];
	new String:varValue[512];
	if(arg_count<2)
	{
		PrintToServer("TODO: Syntax error");
		return Plugin_Handled;
	}
	GetCmdArgString(buffer,sizeof(buffer));
	TrimString(buffer);
	new spaceAt = StrContains(buffer, " ");	
	if(spaceAt==-1)
	{
		PrintToServer("TODO: Syntax error");
		return Plugin_Handled;
	}
	else
	{
		strcopy(varName, spaceAt+1, buffer);
		Format(varValue, sizeof(varValue), "%s", buffer[spaceAt+1]);
	}
	
	if(expand)
	{
		ExpandVars(varName, sizeof(varName));
		ExpandVars(varValue, sizeof(varValue));
	}
	TrimString(varName);
	TrimString(varValue);
	
	SetInf(varName, varValue);
	return Plugin_Handled;
}

SetInf(const String:varName[], const String:varValue[])
{
	new Handle:h = FindConVar(varName);
	if(h)
	{
		SetConVarString(h, varValue);
	}
	else
	{
		CreateConVar(varName, varValue);
	}
}	
	
public Action:War3If(arg_count, bool:expand)
{
	// syntax: war3_if ( value1 operator value2 ) then command
	new String:buffer[512];
	GetCmdArgString(buffer, sizeof(buffer));
	new len = strlen(buffer);
	new current_state = 0;
	// at this point, we can be a little less complex and look for then.
	new String:value1[512];
	new String:value2[512];
	new String:operatorstr[512];
	new bool:pOpen = false;
	new bool:qOpen = false;
	new last_was = 0;
	for(new x=0;x<len;x++)
	{
		new String:currentChar = buffer[x];
		if(current_state==0) // looking for initial (
		{
			if(currentChar==' ')
			{
				continue; // nothing special, whitespace
			}
			else if(currentChar=='(')
			{
				// cool, now we are moving on
				current_state = 1;
				continue;
			}
			else
			{
				// alright, malformed.
				current_state = -1;
				break;
			}
		}
		else if(current_state==1) // 1 = looking for value1 (pre)
		{
			if(currentChar==' ')
			{
				// thats fine, just continue.
				continue;
			}
			else if(currentChar=='"')
			{
				qOpen = true;
				current_state = 2;
				continue;
			}
			else if(validExpressionChar(currentChar))
			{
				// first character of value 1.
				Format(value1, sizeof(value1), "%s%c", value1, currentChar);
				current_state = 2;
				continue;				
			}
			else
			{
				// malformed
				current_state = -1;
				break;
			}
		}
		else if(current_state==2) // 2 = looking for value1
		{
			if(currentChar==' ')
			{
				if(qOpen)
				{
					Format(value1, sizeof(value1), "%s%c", value1, currentChar);
					continue;
				}
				else
				{
					// k, done with value1
					current_state=3;
					continue;
				}
			}
			else if(currentChar=='"') 
			{
				if(qOpen)
				{
					qOpen = false;
					new String:nextChar;
					if(nextchar(buffer, x, nextChar))
					{
						if(nextChar!=' ')
						{
							current_state = -1;
							break;
						}
					}
					else
					{
						current_state = -1;
						break;
					}
					current_state = 3;
					x++;
					continue;	
				}
				else
				{
					current_state = -1;
					break;
				}
			}
			else if(validExpressionChar(currentChar))
			{
				Format(value1, sizeof(value1), "%s%c", value1, currentChar);
				continue;
			}
			else
			{
				current_state = -1;
				break;
			}
		}
		else if(current_state==3)
		{
			if(currentChar==' ')
			{
				// thats fine, just continue.
				continue;
			}
			else if(validExpressionChar2(currentChar))
			{
				// first character of operator
				Format(operatorstr, sizeof(operatorstr), "%s%c", operatorstr, currentChar);
				current_state = 4;
				continue;				
			}
			else
			{
				current_state = -1;
				break;
			}
		}
		else if(current_state==4)
		{
			if(currentChar==' ')
			{
				// k, done with operator
				current_state=5;
				continue;
			}
			else if(validExpressionChar2(currentChar))
			{
				Format(operatorstr, sizeof(operatorstr), "%s%c", operatorstr, currentChar);
				continue;
			}
			else
			{
				current_state = -1;
				break;
			}
		} 
		else if(current_state==5)
		{
			if(currentChar==' ')
			{
				// thats fine, just continue.
				continue;
			}
			else if(currentChar=='"')
			{
				qOpen = true;
				current_state = 6;
				continue;
			}
			else if(validExpressionChar(currentChar))
			{
				// first character of value2
				Format(value2, sizeof(value2), "%s%c", value2, currentChar);
				current_state = 6;
				continue;				
			}
			else
			{
				current_state = -1;
				break;
			}
		}
		else if(current_state==6)
		{
			if(currentChar==' ')
			{
				if(qOpen)
				{
					Format(value2, sizeof(value2), "%s%c", value2, currentChar);
					continue;
				}
				else
				{
					// k, done with value2
					current_state=7;
					// ensure the next non white space is a )
					new String:chkNext;
					new lInd;
					if(nextcharnonwhite(buffer, x, chkNext, lInd))
					{
						if(chkNext==')')
						{
							last_was = lInd;
							break;
						}
						else
						{
							current_state = -1;
							break;
						}
					}
					else
					{
						current_state = -1;
						break;
					}
				}
			}
			else if(currentChar=='"') 
			{
				if(qOpen)
				{
					qOpen = false;
					new String:nextChar;
					new findIndex;
					if(nextcharnonwhite(buffer, x, nextChar, findIndex))
					{
						if(nextChar!=')')
						{
							current_state = -1;
							break;
						}
					}
					else
					{
						current_state = -1;
						break;
					}
					current_state = 7;
					last_was = findIndex;
					continue;	
				}
				else
				{
					current_state = -1;
					break;
				}
			}
			else if(validExpressionChar(currentChar))
			{
				if(currentChar=='(' && !pOpen)
				{
					pOpen = true;
				}
				if(currentChar==')' && !pOpen)
				{
					current_state=7;
					last_was = x;
					break;
				}
				if(currentChar==')' && pOpen)
				{
					pOpen = false;
				}
				Format(value2, sizeof(value2), "%s%c", value2, currentChar);
				continue;
			}
			else
			{
				current_state = -1;
				break;
			}
		}
	}
	if(current_state!=7)
	{
		PrintToServer("TODO: Error with syntax");
		return Plugin_Handled;
	}
	//PrintToServer("%s:%s:%s",value1,operatorstr,value2);
	// Now we can just take the rest, verify that a "then" is there, and execute the preciding command after converting server_var instances
	new String:afterStart[512];
	if(len<(last_was)+2)
	{
		// not long enough
		PrintToServer("TODO: Error with syntax");
		return Plugin_Handled;
	}
	Format(afterStart, sizeof(afterStart), "%s", buffer[last_was+1]);
	TrimString(afterStart);
	// First five characters must be:
	new len2 = strlen(afterStart);
	if(!((afterStart[0]=='t' || afterStart[0]=='T')
		&& (afterStart[1]=='h' || afterStart[1]=='H')
 		&& (afterStart[2]=='e' || afterStart[2]=='E')
 		&& (afterStart[3]=='n' || afterStart[3]=='N')
 		&& afterStart[4]==' ' && len2>5))
 	{
		PrintToServer("TODO: Error with syntax");
		return Plugin_Handled;
	}
	Format(afterStart, sizeof(afterStart), "%s", afterStart[5]);
	TrimString(afterStart);
		
	if(expand)
	{
		ExpandVars(value1, sizeof(value1));
		ExpandVars(operatorstr, sizeof(operatorstr));
		ExpandVars(value2, sizeof(value2));
		ExpandVars(afterStart, sizeof(afterStart));
	}
	
	TrimString(operatorstr);
	if(StrEqual(operatorstr,"==") || StrEqual(operatorstr,"=") || StrEqual(operatorstr,"equalto", false))
	{
		if(IsNumber(value1) && IsNumber(value2))
		{
			if(StringToFloat(value1)==StringToFloat(value2))
			{
				ServerCommand("%s\n", afterStart);
			}			
		}
		else
		{
			if(StrEqual(value1,value2))
			{
				ServerCommand("%s\n", afterStart);
			}
		}
	}
	else if(StrEqual(operatorstr,"!=") || StrEqual(operatorstr,"notequalto", false))
	{
		if(IsNumber(value1) && IsNumber(value2))
		{
			if(StringToFloat(value1)!=StringToFloat(value2))
			{
				ServerCommand("%s\n", afterStart);
			}			
		}
		else
		{
			if(!StrEqual(value1,value2))
			{
				ServerCommand("%s\n", afterStart);
			}
		}
	}
	else if(StrEqual(operatorstr,">") || StrEqual(operatorstr,"greaterthan", false))
	{
		if(IsNumber(value1) && IsNumber(value2))
		{
			if(StringToFloat(value1)>StringToFloat(value2))
			{
				ServerCommand("%s\n", afterStart);
			}			
		}
	}
	else if(StrEqual(operatorstr,"<") || StrEqual(operatorstr,"lessthan", false))
	{
		if(IsNumber(value1) && IsNumber(value2))
		{
			if(StringToFloat(value1)<StringToFloat(value2))
			{
				ServerCommand("%s\n", afterStart);
			}			
		}
	}
	else if(StrEqual(operatorstr,">=") || StrEqual(operatorstr,"notlessthan", false))
	{
		if(IsNumber(value1) && IsNumber(value2))
		{
			if(StringToFloat(value1)>=StringToFloat(value2))
			{
				ServerCommand("%s\n", afterStart);
			}			
		}
	}
	else if(StrEqual(operatorstr,"<=") || StrEqual(operatorstr,"notgreaterthan", false))
	{
		if(IsNumber(value1) && IsNumber(value2))
		{
			if(StringToFloat(value1)>=StringToFloat(value2))
			{
				ServerCommand("%s\n", afterStart);
			}			
		}
	}
	return Plugin_Handled;
}

W3VarByStr(const String:lookup[])
{
	for(new x=0;x<sizeof(W3VarStrings);x++)
	{
		if(StrEqual(lookup, W3VarStrings[x], false)) // wow im tired lol
		{
			return x;
		}
	}
	return -1;
}

// Returns true if one was expanded.
bool:ExpandAVar(String:buffer[], maxlen)
{
	new len = strlen(buffer);
	if(len==0)
	{
		return false;
	}
	new pos = strlen(buffer)-1;
	new pos2 = -1;
	new vType = 0; // 0 = server_var, 1 = event_var, 2 = war3_int, 3 = war3_float
	for(new x=pos;x>=0;x--)
	{
		if(StrContains(buffer[x], "server_var(", false)==0)
		{
			pos2 = x;
			break;
		}
		else if(StrContains(buffer[x], "event_var(", false)==0)
		{
			pos2 = x;
			vType = 1;
			break;
		}
		else if(StrContains(buffer[x], "war3_int(", false)==0)
		{
			pos2 = x;
			vType = 2;
			break;
		}
		else if(StrContains(buffer[x], "war3_float(", false)==0)
		{
			pos2 = x;
			vType = 3;
			break;
		}
	}
	if(pos2==-1)
	{
		return false;
	}
	new String:collectSymbol[64];
	new bool:endFound = false;
	new bool:hasStarted = false;
	new endAt;
	new offset = 0;
	if(vType==0)
	{
		offset = 11;
	}
	else if(vType==1) // event_var(
	{
		offset = 10;
	}
	else if(vType==2) // war3_int(
	{
		offset = 9;
	}
	else // war3_float(
	{
		offset = 11;
	}
	for(new x=(pos2+offset);x<len;x++)
	{
		if(buffer[x]==')')
		{
			endAt = x;
			endFound = true;
			break;	
		}
		else if(buffer[x]==' ')
		{
			if(hasStarted)
			{
				Format(collectSymbol, 64, "%s%c", collectSymbol, buffer[x]);
			}
			else
			{
				continue;
			}
		}
		else
		{
			hasStarted = true;
			Format(collectSymbol, 64, "%s%c", collectSymbol, buffer[x]);
		}
	}
	if(!endFound)
	{
		return false;
	}
	// Find the console variable.
	new String:replaceWith[64] = "0";
	if(vType==0)
	{
		new Handle:hVar = FindConVar(collectSymbol);
		if(hVar!=INVALID_HANDLE)
		{
			GetConVarString(hVar, replaceWith, sizeof(replaceWith));		
		}
	}
	else if(vType==1)
	{
		EventVar(collectSymbol, replaceWith, sizeof(replaceWith));		
	}
	else if(vType==2) // war3_int
	{
		new ind = W3VarByStr(collectSymbol);
		if(ind==-1)
		{
			Format(replaceWith, sizeof(replaceWith), "0");
		}
		else
		{
			Format(replaceWith, sizeof(replaceWith), "%d", W3GetVar(W3Var:ind));
		}
	}
	else // war3_float
	{
		new ind = W3VarByStr(collectSymbol);
		if(ind==-1)
		{
			Format(replaceWith, sizeof(replaceWith), "0");
		}
		else
		{
			Format(replaceWith, sizeof(replaceWith), "%f", W3GetVar(W3Var:ind));
		}
	}
	new String:beforeStr[512];
	new String:afterStr[512];
	strcopy(beforeStr, pos2+1, buffer);
	Format(afterStr, sizeof(afterStr), "%s", buffer[endAt+1]);
	Format(buffer, maxlen, "%s%s%s", beforeStr, replaceWith, afterStr);
	return true;                                               
}

ExpandVars(String:buffer[], maxlen)
{
	// find all instances of server_var and event_var
	new c=0;
	while(ExpandAVar(buffer, maxlen))
	{
		c++;		
	}
	return c;
}

EventVar(const String:key[], String:buffer[], maxlen)
{
	if(hCurrentEventData)
	{
		KvGetString(hCurrentEventData, key, buffer, maxlen);
		if(StrEqual(buffer,""))
		{
			Format(buffer, maxlen, "0");
		}
	}
	else
	{
		Format(buffer, maxlen, "0");
	}
}

bool:GetArgCustom(const String:buffer[], number, String:outBuf[], maxlen)
{
	new len = strlen(buffer);
	new current_state = 0; // in arg (pre)
	// 1 = in arg
	// 2 = in quotes
	Format(outBuf, maxlen, "");      
	new argCount = 1;
	new bool:isCurArg = false;
	new bool:res = false;
	for(new x=0;x<len;x++)
	{
		if(argCount==number)
		{
			res = true;
			isCurArg = true;	
		}
		else
		{
			isCurArg = false;
		}
		if(current_state==0)
		{
			if(buffer[x]==' ')
			{
				continue;
			}
			else if(buffer[x]=='"')
			{
				current_state = 2;
				continue;
			}
			else
			{
				current_state = 1;
				if(isCurArg)
				{
					Format(outBuf, maxlen, "%s%c", outBuf, buffer[x]);
				}			
				continue;
			}
		}
		else if(current_state==1)
		{
			if(buffer[x]==' ')
			{
				argCount++;
				current_state = 0;
				continue;
			}
			else
			{
				if(isCurArg)
				{
					Format(outBuf, maxlen, "%s%c", outBuf, buffer[x]);
				}		
				continue;
			}
		}
		else
		{
			if(buffer[x]=='"')
			{
				// ensure the next non white space is a )
				new String:nextChar;
				if(nextchar(buffer, x, nextChar))
				{
					if(nextChar!=' ')
					{
						if(isCurArg)
						{
							Format(outBuf, maxlen, "%s%c", outBuf, buffer[x]);
						}		
						continue;
					}
					else
					{
						current_state = 0;              
						argCount++;
					}
				}
				else
				{
					current_state = 0;
					break;
				}				
			}
			else
			{
				if(isCurArg)
				{
					Format(outBuf, maxlen, "%s%c", outBuf, buffer[x]);
				}		
				continue;			
			}
		}
	}
	return res;   
}

GetArgCountCustom(const String:buffer[])
{
	new len = strlen(buffer);
	new current_state = 0; // in arg (pre)
	// 1 = in arg
	// 2 = in quotes 
	new argCount = 1;
	if(len==0)
	{
		return 0;
	}
	for(new x=0;x<len;x++)
	{
		if(current_state==0)
		{
			if(buffer[x]==' ')
			{
				continue;
			}
			else if(buffer[x]=='"')
			{
				current_state = 2;
				continue;
			}
			else
			{
				current_state = 1;
				continue;
			}
		}
		else if(current_state==1)
		{
			if(buffer[x]==' ')
			{
				argCount++;
				current_state = 0;
				continue;
			}
			else
			{
				continue;
			}
		}
		else
		{
			if(buffer[x]=='"')
			{
				// ensure the next non white space is a )
				new String:nextChar;
				if(nextchar(buffer, x, nextChar))
				{
					if(nextChar!=' ')
					{
						continue;
					}
					else
					{
						current_state = 0;              
						argCount++;
					}
				}
				else
				{
					current_state = 0;
					break;
				}				
			}
		}
	}
	return argCount;      
}

public Action:War3Effect(arg_count, bool:expand)
{

	new String:buffer[1024];
	GetCmdArgString(buffer, sizeof(buffer));

	if(expand)
	{
		ExpandVars(buffer, sizeof(buffer));
	}

	TrimString(buffer);	 	
	arg_count = GetArgCountCustom(buffer);
	if(arg_count<2)
	{
		PrintToServer("TODO: Syntax error.");
		return Plugin_Handled;
	}
	
/*
est_Effect 01 <player Filter> <delay> <model> <position X Y Z> <direction X Y Z>
Creates a armour ricochet effect.
est_Effect 02 <player Filter> <delay> <model> <start ent> <start position X Y Z> <end ent> <end position X Y Z> <framerate> <life> <start width> <end width> <fade distance> <amplitude> <Red> <Green> <Blue> <Alpha> <speed>
Creates a beam ent point effect.
est_Effect 03 <player Filter> <delay> <model> <start ent> <end ent> <framerate> <life> <start width> <end width> <fade distance> <amplitude> <Red> <Green> <Blue> <Alpha> <speed>
Creates a beam ents effect.
est_Effect 04 <player Filter> <delay> <model> <Follow ent> <life> <start width> <end width> <fade distance> <Red> <Green> <Blue> <Alpha>
Creates a beam ent follow effect
est_Effect 05 <player Filter> <delay> <model> <start ent> <end ent> <framerate> <life> <start width> <end width> <fade distance> <amplitude> <Red> <Green> <Blue> <Alpha> <speed>
Creates a beam laser effect.
est_Effect 06 <player Filter> <delay> <model> <start position X Y Z> <end position X Y Z> <framerate> <life> <start width> <end width> <fade distance> <amplitude> <Red> <Green> <Blue> <Alpha> <speed>
Creates a Beam Points Effect.
est_Effect 07 <player Filter> <delay> <model> <start ent> <end ent> <framerate> <life> <width> <spread> <amplitude> <Red> <Green> <Blue> <Alpha> <speed>
Creates a beam Beam Ring Ent Effect.
est_Effect 08 <player Filter> <delay> <model> <middle X Y Z> <Start Radius> <End Radius> <framerate> <life> <width> <spread> <amplitude> <Red> <Green> <Blue> <Alpha> <speed> <flags>
Creates a Beam Ring Ent Effect.
est_Effect 09 <player Filter> <delay> <model> <points> <rgPoints X Y Z>
Creates a Beam Spline Effect.
est_Effect 10 <player Filter> <delay> <model> <origin X Y Z> <direction X Y Z> <Red> <Green> <Blue> <Alpha> <Size>
Creates a Blood Sprite Effect.
est_Effect 11 <player Filter> <delay> <model> <origin X Y Z> <direction X Y Z> <Red> <Green> <Blue> <Alpha> <Amount>
Creates a Blood Stream Effect.
est_Effect 12 <player Filter> <delay> <model> <origin X Y Z> <angle Pitch Yaw Roll> <Size X Y Z> <Velocity X Y Z> <Randomization> <count> <time> <flags>
Creates a Blood Stream Effect.
est_Effect 13 <player Filter> <delay> <decal> <origin X Y Z> <target entity index>
Creates a BSP Decal (permanently attach a sprite to an entity, use 0 for the world).
est_Effect 14 <player Filter> <delay> <model> <Min X Y Z> <Max X Y Z> <height> <count> <speed>
Creates a Bubbles Effect.
est_Effect 15 <player Filter> <delay> <model> <Min X Y Z> <Max X Y Z> <heighth> <count> <speed>
Creates a Bubble Trail Effect.
est_Effect 16 <player Filter> <delay> <model> <Position X Y Z> <Start X Y Z> <entity index> <hitbox>
Creates a Decal Effect.
est_Effect 17 <player Filter> <delay> <Position X Y Z> <Direction X Y Z> <size> <speed>
Creates a Dust Effect.
est_Effect 18 <player Filter> <delay> <Position X Y Z> <Red> <Green> <Blue> <Alpha> <exponent> <radius> <time> <decay>
Creates a Dynamic Light Effect.
est_Effect 19 <player Filter> <delay> <Position X Y Z> <Direction X Y Z> <Explosive>
Creates a Energy Splash Effect.
est_Effect 20 <player Filter> <delay> <model> <Position X Y Z> <scale> <framerate> <flags> <radius> <magnitude> [Normal X Y Z] [Material Type]
Creates a Energy Splash Effect .
est_Effect 21 <player Filter> <delay> <model> <entity> <density> <current>
Creates a Fizz Effect.
est_Effect 22 <player Filter> <delay> <Position X Y Z> <Direction X Y Z> <type>
Creates a Guass Explosion Effect.
est_Effect 23 <player Filter> <delay> <model> <Position X Y Z> <life> <size> <brightness>
Creates a Glow Sprite Effect.
est_Effect 24 <player Filter> <delay> <model> <Position X Y Z> <reversed>
Creates a Large Funnel Effect.
est_Effect 25 <player Filter> <delay> <Position X Y Z> <Direction X Y Z>
Creates a Metal Sparks Effect.
est_Effect 26 <player Filter> <delay> <Position X Y Z> <Angle Pitch Yaw Roll> <scale> <type>
Creates a Muzzle Flash Effect.
est_Effect 27 <player Filter> <delay> <model> <subtype> <Position X Y Z> <Angle Pitch Yaw Roll> <Velocity X Y Z> <flags> <unknown>
Creates a Physics Prop Effect.
est_Effect 28 <player Filter> <delay> <Position X Y Z> <playerindex> <entity>
Creates a Player Decal Effect.
est_Effect 29 <player Filter> <delay> <decal> <Position X Y Z> <Angle Pitch Yaw Roll> <distance>
Creates a Project Decal Effect.
est_Effect 30 <player Filter> <delay> <Start X Y Z> <End X Y Z>
Creates a Show Line Effect.
est_Effect 31 <player Filter> <delay> <model> <Position X Y Z> <scale> <framerate>
Creates a Smoke Effect.
est_Effect 32 <Player Filter> <Delay> <Position X Y Z> <Magnitude> <Trail Length> <Direction X Y Z>
Creates a Spark Effect.
est_Effect 33 <Player Filter> <Delay> <model> <Position X Y Z> <size> <brightness>
Creates a Sprite Effect.
est_Effect 34 <Player Filter> <Delay> <model> <Position X Y Z> <Direction X Y Z> <speed> <noise> <count>
Creates a Sprite Spray Effect.
est_Effect 35 <Player Filter> <Delay> <Decal> <Position X Y Z>
Creates a World Decal Effect. 
*/
	
	return Plugin_Handled;	
}
public Action:War3GetPlayerLocation(arg_count, bool:expand)
{

	new String:buffer[1024];
	GetCmdArgString(buffer, sizeof(buffer));

	if(expand)
	{
		ExpandVars(buffer, sizeof(buffer));
	}

	TrimString(buffer);
	 	
	arg_count = GetArgCountCustom(buffer);
	if(arg_count<4)
	{
		PrintToServer("TODO: Syntax error.");
		return Plugin_Handled;
	}
	
 	new String:x_var[64];
 	new String:y_var[64];
 	new String:z_var[64];
 	new String:userid[32];
 	GetArgCustom(buffer, 1, x_var, sizeof(x_var));
 	GetArgCustom(buffer, 2, y_var, sizeof(y_var));
 	GetArgCustom(buffer, 3, z_var, sizeof(z_var));
 	GetArgCustom(buffer, 4, userid, sizeof(userid));
 	
 	new uid = StringToInt(userid);
 	new index = GetClientOfUserId(uid);
 	if(ValidPlayer(index))
 	{
 		new Float:location[3];
 		GetClientAbsOrigin(index, location);
 		new String:x_val[64];
 		new String:y_val[64];
 		new String:z_val[64];
 		Format(x_val, sizeof(x_val), "%f", location[0]);
 		Format(y_val, sizeof(y_val), "%f", location[1]);
 		Format(z_val, sizeof(z_val), "%f", location[2]);
 		SetInf(x_var, x_val);
        SetInf(y_var, y_val);
        SetInf(z_var, z_val);
	}
	else
	{
		PrintToServer("TODO: Bad userid (%s)", userid);
 		SetInf(x_var, "0");
        SetInf(y_var, "0");
        SetInf(z_var, "0");
	}   
	return Plugin_Handled; 	
}

public Action:War3EngIf(arg_count)
{
	return War3If(arg_count, true);
}

public Action:War3EngXIf(arg_count)
{
	return War3If(arg_count, false);	
}

public Action:War3EngGetPlayerLocation(arg_count)
{
	return War3GetPlayerLocation(arg_count, true);	
}

public Action:War3EngXGetPlayerLocation(arg_count)
{
	return War3GetPlayerLocation(arg_count, false);	
}

public Action:War3EngSetinfo(arg_count)
{
	return War3Setinfo(arg_count, true);	
}

public Action:War3EngXSetinfo(arg_count)
{
	return War3Setinfo(arg_count, true);	
}

public Action:War3EngCmd(arg_count)
{
	new String:buffer[512];
	GetCmdArgString(buffer, sizeof(buffer));
	ExpandVars(buffer,sizeof(buffer));
	TrimString(buffer);
	ServerCommand("%s\n", buffer);
	return Plugin_Handled;
}

public Action:War3EngEffect(arg_count)
{
	return War3Effect(arg_count, true);	
}

public Action:War3EngXEffect(arg_count)
{
	return War3Effect(arg_count, false);	
}