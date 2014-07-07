/**
 * File: War3Source_ShopItems.sp
 * Description: The shop items that come with War3Source.
 * Author(s): Anthony Iacono
 *
 *-- Added mypiggybank  == Cash Regen for MVM
 *-- Uncomment line 143 in order to enable it.
 *--
 *-- El Diablo
 *-- www.war3evo.com
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>

#include <cstrike>

enum ITEMENUM{
  POSTHASTE=0,
  TRINKET,
  LIFETUBE,
  SNAKE_BRACELET,
  FORTIFIED_BRACER,
  //CASH_REGEN,
  //DIE_LAUGHING,
  //SCROLL_OF_REVIVE,
  //SCROLL_OF_ESSENCE
  /*
  //basic "Accessories"
  striders
  
  soulscream ring , Alchemist's Bones, charged hammer
  Trinket of Restoration
  sustainer
  
  //support
  ring of the teacher
  Refreshing Ornament
  Shield of the Five
  helm
  headdress
  
  //protective
  Iron Shield
  daemonic breastplate
  frostfield plate  
  behe's heart
  snake bracelet
  barbed armor
  //combata
  spell shards??? needs some recoding
  thunderclaw
  modk of brilliance
  warclept - attack speed
  //morph 
  shiel dbreakder
  frostburn
  some leech 
  
  
  
  
  
  
  */
}

new ItemID[MAXITEMS];

public Plugin:myinfo = 
{
  name = "W3S - Shopitems2",
  author = "Ownz",
  description = "The shop items that come with War3Source.",
  version = "1.0.0.0",
  url = "http://war3source.com/"
};

public OnPluginStart()
{
  //RegConsoleCmd("+ability1",War3Source_AbilityCommand);
  //RegConsoleCmd("-ability1",War3Source_AbilityCommand);
    
  //CreateTimer(1.0,test,_,TIMER_REPEAT);
  W3CreateCvar("w3shop2items","loaded","is the shop2 loaded");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
  if(num==10){

    for(new x=0;x<MAXITEMS;x++)
      ItemID[x]=0;

    ItemID[POSTHASTE]=War3_CreateShopItem2T("posthaste",10);
    if(ItemID[POSTHASTE]==0){
      DP("ERR ITEM ID RETURNED IS ZERO");
    }
    ItemID[TRINKET]=War3_CreateShopItem2T("trinket",15);
    ItemID[LIFETUBE]=War3_CreateShopItem2T("lifetube",40);
    ItemID[SNAKE_BRACELET]=War3_CreateShopItem2T("sbracelt",10);
    ItemID[FORTIFIED_BRACER]=War3_CreateShopItem2T("fbracer",10);
  }
}

public OnItem2Purchase(client,item)
{
//DP("purchase %d %d",client,item);
  if(item==ItemID[POSTHASTE] )
  {
    War3_SetBuffItem2(client,fMaxSpeed2,ItemID[POSTHASTE],1.034);
  }
  if(item==ItemID[TRINKET] ) 
  {
    War3_SetBuffItem2(client,fHPRegen,ItemID[TRINKET],0.5);
  }
  if(item==ItemID[LIFETUBE] ) 
  {
    War3_SetBuffItem2(client,fHPRegen,ItemID[LIFETUBE],1.0);
  }
  if(item==ItemID[FORTIFIED_BRACER]){
  
    War3_SetBuffItem2(client,iAdditionalMaxHealth,ItemID[FORTIFIED_BRACER],10);
    War3_SetBuffItem(client,fHPRegenDeny,ItemID[FORTIFIED_BRACER],true);
    War3_HealToMaxHP(client,10);
  }
}

public OnItem2Lost(client,item){ //deactivate passives , client may have disconnected
//DP("lost %d %d",client,item);
  if(item==ItemID[POSTHASTE]){
    War3_SetBuffItem2(client,fMaxSpeed2,ItemID[POSTHASTE],1.0);
  }
  if(item==ItemID[TRINKET] ) // boots of speed
  {
    War3_SetBuffItem2(client,fHPRegen,ItemID[TRINKET],0.0);
  }
  if(item==ItemID[LIFETUBE] ) // boots of speed
  {
    War3_SetBuffItem2(client,fHPRegen,ItemID[LIFETUBE],0.0);
  }
  if(item==ItemID[FORTIFIED_BRACER]){
    War3_SetBuffItem2(client,iAdditionalMaxHealth,ItemID[FORTIFIED_BRACER],0);
    War3_SetBuffItem(client,fHPRegenDeny,ItemID[FORTIFIED_BRACER],false);
  }
}
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
//sh has no shop2 items
  if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
  {
    new vteam=GetClientTeam(victim);
    new ateam=GetClientTeam(attacker);
    if(vteam!=ateam)
    {
      if(!Perplexed(victim,false)&&War3_GetOwnsItem2(victim,ItemID[SNAKE_BRACELET]))
      {
        if(W3Chance(0.05))
        {
          War3_DamageModPercent(0.0); //NO DAMAMGE
          W3MsgEvaded(victim,attacker);
        }
      }
    }
  }
}