#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>

public Plugin:myinfo = 
{
    name = "War3Source - Race - Luna Moonfang",
    author = "War3Source Team",
    description = "The Luna Moonfang race for War3Source."
};

new thisRaceID;
new String:beamsnd[256]; // = "war3source/moonqueen/beam.mp3";
new String:lunasnd2[256]; // = "weapons/flashbang/flashbang_explode2.wav";

//skill is auto cast via chance
//new Float:LucentChance[5] = {0.00,0.05,0.11,0.22,0.30};
new LucentBeamMin[5] = {0, 3, 4, 5, 6};
new LucentBeamMax[5] = {0, 7, 8, 9, 10};

new Float:GlaiveRadius[5] = {0.0,250.0,300.0,350.0,400.0};
new Float:GlaiveChance = 0.22;
new GlaiveDamage[5] = {0,4,6,8,12};

new Float:BlessingRadius = 280.0;
new BlessingIncrease[5] = {0,1,2,2,3};

new Float:EclipseRadius=500.0;
new EclipseAmount[5]= {0,4,6,8,10};

new SKILL_MOONBEAM,SKILL_BOUNCE,SKILL_AURA,ULT;
new LightModel;
new XBeamSprite,CoreSprite,MoonSprite,HaloSprite;
//new BlueSprite;
new Handle:ultCooldownCvar = INVALID_HANDLE;
new AuraID;

public OnPluginStart()
{
    ultCooldownCvar=CreateConVar("war3_luna_ultimate_cooldown","20","Luna Moonfangs ultimate cooldown (ultimate)");
    //CreateTimer(3.0,CalcBlessing,_,TIMER_REPEAT);
    LoadTranslations("w3s.race.luna.phrases.txt");
}

public OnMapStart()
{
    War3_AddSoundFolder(beamsnd, sizeof(beamsnd), "moonqueen/beam.mp3");
    if(GameCS()) {
        War3_AddSoundFolder(lunasnd2, sizeof(lunasnd2), "flashbang_explode2.mp3");
    } else {
        War3_AddSoundFolder(lunasnd2, sizeof(lunasnd2), "moonqueen/flashbang_explode1.mp3");
    }
    
    War3_AddCustomSound( beamsnd );
    War3_AddCustomSound( lunasnd2 );
    
    //BeamSprite=War3_PrecacheBeamSprite();
    HaloSprite=War3_PrecacheHaloSprite();
    if(War3_GetGame() == Game_CSGO) {
        CoreSprite = PrecacheModel( "materials/effects/combinemuzzle1.vmt" );
        MoonSprite = PrecacheModel( "materials/sprites/light_glow02.vmt" );
        XBeamSprite = PrecacheModel( "materials/sprites/physbeam.vmt" );
        //PrecacheModel("particle/particle_flares/particle_flare_004");
    }
    else {
        CoreSprite = PrecacheModel( "materials/sprites/physcannon_blueflare1.vmt" );
        MoonSprite = PrecacheModel( "materials/sprites/physcannon_bluecore1b.vmt");
        //BlueSprite = PrecacheModel( "materials/sprites/physcannon_bluelight1.vmt" );
        XBeamSprite = PrecacheModel( "materials/sprites/XBeam2.vmt" );
        LightModel = PrecacheModel( "models/effects/vol_light.mdl" );
        //PrecacheModel("particle/fire.vmt");
    }
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==280)
    {

        thisRaceID=War3_CreateNewRaceT("luna");
        SKILL_MOONBEAM=War3_AddRaceSkillT(thisRaceID,"LucentBeam",false,4);
        SKILL_BOUNCE=War3_AddRaceSkillT(thisRaceID,"MoonGlaive",false,4);
        SKILL_AURA=War3_AddRaceSkillT(thisRaceID,"LunarBlessing",false,4);
        ULT=War3_AddRaceSkillT(thisRaceID,"Eclipse",true,4);
        War3_CreateRaceEnd(thisRaceID);
        
        War3_AddAuraSkillBuff(thisRaceID, SKILL_AURA, iDamageBonus, BlessingIncrease, 
                              "luna_blessing", BlessingRadius, 
                              true);
        
        // since we cant look up aura ids by shortname right now, do it this way ;)
        AuraID = W3RegisterAura("luna_blessing", BlessingRadius);
    }
}

public OnW3PlayerAuraStateChanged(client,aura,bool:inAura,level)
{
    if(aura == AuraID)
    {
        if(War3_GetGame() != Game_CSGO) 
        {
            if(inAura == true && ValidPlayer(client, true)) 
            {
                decl Float:client_pos[3];
                GetClientAbsOrigin(client, client_pos);
                TE_SetupGlowSprite(client_pos, LightModel, 2.0, 1.0, 255);
                TE_SendToAll();
            }
        }
    }
}

public OnW3TakeDmgBullet( victim, attacker, Float:damage )
{
    if( IS_PLAYER( victim ) && IS_PLAYER( attacker ) && victim > 0 && attacker > 0 && attacker != victim )
    {
        new vteam = GetClientTeam( victim );
        new ateam = GetClientTeam( attacker );
        if( vteam != ateam )
        {
            new race_attacker = War3_GetRace( attacker );
            new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_MOONBEAM );
            new skill_level2 = War3_GetSkillLevel( attacker, thisRaceID, SKILL_BOUNCE );
            if( race_attacker == thisRaceID &&!Hexed(attacker))
            {

                if( !W3IsOwnerSentry(attacker) && skill_level > 0 && SkillAvailable(attacker,thisRaceID,SKILL_MOONBEAM,false) &&!W3HasImmunity( victim, Immunity_Skills ))
                {
                    MoonBeamDamageAndEffect(victim, attacker, LucentBeamMin[skill_level], LucentBeamMax[skill_level]);

                    /*        decl Float:start_pos[3];
                     decl Float:target_pos[3];
                     GetClientAbsOrigin(attacker,start_pos);
                     GetClientAbsOrigin(victim,target_pos);
                     target_pos[2]+=60.0;
                     start_pos[1]+=50.0;
                     TE_SetupBeamPoints(target_pos, start_pos, BlueSprite, HaloSprite, 0, 100, 2.0, 1.0, 3.0, 0, 0.0, {255,0,255,255}, 10);
                     TE_SendToAll();
                     TE_SetupBeamPoints(target_pos, start_pos, BlueSprite, HaloSprite, 0, 100, 2.0, 3.0, 5.0, 0, 0.0, {128,0,255,255}, 30);
                     TE_SendToAll(2.0);    
                     //TE_SetupBeamRingPoint(const Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex(Precache), HaloIndex(Precache), StartFrame, FrameRate, Float:Life, Float:Width, Float:Amplitude, const Color[4], Speed, Flags);
                     TE_SetupBeamRingPoint(target_pos, 20.0, 90.0, XBeamSprite, HaloSprite, 0, 1, 1.0, 90.0, 0.0, {128,0,255,255}, 10, 0);
                     TE_SendToAll(2.0);                
                     TE_SetupBeamPoints(target_pos, start_pos, BlueSprite, HaloSprite, 0, 100, 2.0, 5.0, 7.0, 0, 0.0, {128,0,255,255}, 70);
                     TE_SendToAll(4.0);
                     TE_SetupBeamPoints(target_pos, start_pos, BlueSprite, HaloSprite, 0, 100, 2.0, 6.0, 8.0, 0, 0.0, {128,0,255,255}, 170);
                     TE_SendToAll(9.0);
                     */
                    War3_CooldownMGR(attacker,3.0,thisRaceID,SKILL_MOONBEAM,true,false);
                }

                if( skill_level2 > 0 && W3Chance(GlaiveChance) )
                {
                    new lunadmg = GlaiveDamage[skill_level2];
                    new Float:sparkdir[3] = {0.0,0.0,90.0};
                    new Float:maxdist = GlaiveRadius[skill_level2];
                    decl Float:start_pos[3];
                    decl Float:end_pos2[3];
                    GetClientAbsOrigin(victim,start_pos);
                    GetClientAbsOrigin(victim,end_pos2);
                    end_pos2[2]+=1000.0;
                    //TE_SetupBeamPoints(start_pos,end_pos2,XBeamSprite, HaloSprite, 0, 1, Float:2.0,  Float:3.0, 3.0, 1, 0.0, {255,255,255,255}, 0);
                    //TE_SendToAll(0.0);
                    //TE_SetupBeamRingPoint(start_pos, 20.0, maxdist+10.0, XBeamSprite, HaloSprite, 0, 1, 1.0, 90.0, 0.0, {128,0,255,255}, 10, 0);
                    //TE_SendToAll(2.0);
                    for (new i = 1; i <= MaxClients; i++) {
                        if(ValidPlayer(i,true) && GetClientTeam(i) != GetClientTeam(attacker)&&!W3HasImmunity(i,Immunity_Wards)) {
                            decl Float:TargetPos[3];
                            GetClientAbsOrigin(i, TargetPos);
                            if (GetVectorDistance(start_pos, TargetPos) <= maxdist) {
                                TE_SetupSparks(TargetPos, sparkdir, 90, 90);
                                TE_SendToAll();
                                War3_DealDamage( i, lunadmg, attacker, DMG_FALL, "moonglaive" );
                                W3PrintSkillDmgConsole(i,attacker, War3_GetWar3DamageDealt(),SKILL_BOUNCE);
                                PrintHintText(i,"%T","You have been hit by a Moon Glaive!",i);
                            }
                        }
                    }
                    EmitSoundToAllAny(lunasnd2,victim);
                    EmitSoundToAllAny(lunasnd2,attacker);
                }
            }

        }
    }
}

new EclipseOwner[MAXPLAYERSCUSTOM];
new EclipseAmountLeft[MAXPLAYERSCUSTOM];
public OnUltimateCommand( client, race, bool:pressed )
{
    if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
    {
        new level = War3_GetSkillLevel( client, race, ULT );
        if( level > 0)
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT, true ) )
            {
                EclipseAmountLeft[client]=EclipseAmount[ level];

                CreateTimer( 0.15, Timer_EclipseLoop, client);

                decl Float:StartPos[3];
                GetClientAbsOrigin(client, StartPos);
                StartPos[2]+=400.0;
                TE_SetupGlowSprite(StartPos, MoonSprite, 5.0, 3.0, 255);
                TE_SendToAll();

                /*
                 es est_Effect_06 #a .9 sprites/physcannon_blueflare1.vmt server_var(vector2) server_var(vector1) 100 3 16 8 10 0 128 0 255 255 170
                 es est_effect_08 #a .3 sprites/XBeam2.vmt server_var(vector1) 200 90 3 3 100 400 0 128 0 255 255 10 1
                 es est_Effect_06 #a 0 sprites/physcannon_blueflare1.vmt server_var(vector2) server_var(vector1) 100 .3 17 11 10 10 228 228 228 255 100
                 es est_effect_08 #a 0 sprites/physcannon_blueflare1.vmt server_var(vector1) 5000 40 3 5 90 400 0 255 255 255 255 10 1
                 es est_effect_08 #a 0 sprites/physcannon_blueflare1.vmt server_var(vector1) 40 5000 3 5 90 400 0 255 255 255 255 10 1
                 es est_effect_08 #a 0 sprites/physcannon_blueflare1.vmt server_var(vector1) 400 500 3 5 90 400 0 255 255 255 255 10 1
                 
                 est_Effect_08 <player Filter> <delay> <model> <center 'X Y Z'> <Start Radius> <End Radius> <framerate> <life> <width> <spread> <amplitude> <R> <G> <B> <A> <speed> <flags>
                 */
                TE_SetupBeamRingPoint(StartPos, 1000.0, 40.0, CoreSprite, HaloSprite, 0, 3, 5.0, 90.0, 0.0, {255,255,255,255}, 10, 0);
                TE_SendToAll();
                TE_SetupBeamRingPoint(StartPos, 40.0, 1000.0, CoreSprite, HaloSprite, 0, 3, 5.0, 90.0, 0.0, {255,255,255,255}, 10, 0);
                TE_SendToAll();
                TE_SetupBeamRingPoint(StartPos, 400.0, 500.0, CoreSprite, HaloSprite, 0, 3, 5.0, 90.0, 0.0, {255,255,255,255}, 10, 0);
                TE_SendToAll();
                TE_SetupBeamRingPoint(StartPos, 200.0, 90.0, XBeamSprite, HaloSprite, 0, 3, 3.0, 100.0, 0.0, {128,0,255,255}, 10, 0);
                TE_SendToAll(3.0);

                War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT,true,true);
            }
        }
        else
        W3MsgUltNotLeveled( client );
    }
}

public Action:Timer_EclipseLoop( Handle:timer, any:attacker )
{

    EclipseAmountLeft[attacker]--;
    if( ValidPlayer(attacker,true))
    {
        //get list of players
        new playerlist[MAXPLAYERSCUSTOM];
        new playercount=0;
        new teamattacker=GetClientTeam(attacker);
        decl Float:AttackerPos[3];
        GetClientAbsOrigin(attacker,AttackerPos);
        decl Float:TargetPos[3];
        for (new i = 1; i <= MaxClients; i++) {

            if(ValidPlayer(i,true)&&!W3HasImmunity( i, Immunity_Ultimates )&&teamattacker != GetClientTeam(i) && teamattacker!=GetApparentTeam(i) && W3LOS(attacker,i)) {

                GetClientAbsOrigin(i, TargetPos);
                if (GetVectorDistance(AttackerPos, TargetPos) <= EclipseRadius) {
                    playerlist[playercount]=i;
                    playercount++;
                }
            }
        }
        //DP("%d",playercount);
        if(playercount > 0) { //get randomplayer and deal damage
            new index = GetRandomInt(0, playercount - 1);
            new victim = playerlist[index];

            // Use level 4 damage values for the ultimate
            MoonBeamDamageAndEffect(victim, attacker, LucentBeamMin[4], LucentBeamMax[4]);
            W3FlashScreen(victim, RGBA_COLOR_WHITE);
        }
        if(EclipseAmountLeft[attacker] > 0) {
            CreateTimer(0.5, Timer_EclipseLoop, any:attacker);
        }

    }
}

public Action:Timer_EclipseStop(Handle:timer, any:victim)
{
    EclipseOwner[victim] = -1;
}

MoonBeamDamageAndEffect(victim, attacker, min, max) {
    decl Float:start_pos[3];
    decl Float:end_pos2[3];

    GetClientAbsOrigin(victim, start_pos);
    GetClientAbsOrigin(victim, end_pos2);

    end_pos2[2] += 10000.0;
    //TE_SetupBeamPoints(const Float:start[3], const Float:end[3], ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life, Float:Width, Float:EndWidth, FadeLength, Float:Amplitude, const Color[4], Speed)
    TE_SetupBeamPoints(start_pos, end_pos2, XBeamSprite, HaloSprite, 0, 30, Float:1.0, Float:20.0, 20.0, 0, 0.0, {255,255,255,255}, 300);
    TE_SendToAll(0.0);

    //TE_SetupBeamRingPoint(const Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life, Float:Width, Float:Amplitude, const Color[4], Speed, Flags)
    TE_SetupBeamRingPoint(start_pos, 20.0, 99.0, XBeamSprite, HaloSprite, 0, 1, 0.5, 30.0, 0.0, {255,255,255,255}, 10, 0);
    TE_SendToAll(0.3);

    War3_DealDamage(victim, GetRandomInt(min, max), attacker ,DMG_FALL, "lucentbeam");
    W3PrintSkillDmgHintConsole(victim, attacker, War3_GetWar3DamageDealt(), SKILL_MOONBEAM);

    EmitSoundToAllAny(beamsnd, victim);
    EmitSoundToAllAny(beamsnd, attacker);

}