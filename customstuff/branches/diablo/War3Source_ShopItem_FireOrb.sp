#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisItem;

public Plugin:myinfo= {
	name="War3Source Shopitem - Orb of Fire",
	author="Axin & El Diablo",
	description="War3Source",
	version="1.0",
	url="http://www.nguclan.com/"
};



public OnPluginStart()
{
	LoadTranslations("w3s.item.fireorb.phrases");
//Hook events here!!!!
	HookEvent("player_hurt",PlayerHurtEvent);
}
public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==4)
	{
		thisItem=War3_CreateShopItemT("fireorb",3,3000);
	}	
}

public OnItemPurchase(client,item)
{
	if(item==thisItem&&ValidPlayer(client))
	{
		War3_SetOwnsItem(client,item,true);
		//War3_SetBuffItem(client,fArmorPhysical,item,7.5);
	}
}

public OnWar3EventDeath(victim){
	if(War3_GetOwnsItem(victim,thisItem)){
		War3_SetOwnsItem(victim,thisItem,false);
		//War3_SetBuffItem(victim,fArmorPhysical,thisItem,0.0);
	}
}

public PlayerHurtEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
    new victim = GetClientOfUserId( GetEventInt( event, "userid" ) );
    new attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );

    if( victim > 0 && attacker > 0 && attacker != victim && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
		if( War3_GetOwnsItem(attacker,thisItem) )
		{
            if( ValidPlayer( victim, true, false ) == true )
            {
                if( !War3_IsUbered(victim) && !W3HasImmunity(victim,Immunity_Items) && !TF2_IsPlayerInCondition(victim,TFCond_OnFire))
                {
                    //IgniteEntity(entity, Float:time, bool:npc=false, Float:size=0.0, bool:level=false);
                    //IgniteEntity(victim, 3.0, false);
                    TF2_IgnitePlayer(victim, attacker);
                }
            }
        }
    }
}

