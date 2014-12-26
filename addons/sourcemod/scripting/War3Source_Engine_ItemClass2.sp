#define PLUGIN_VERSION "0.0.0.1"

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


new totalItems2Loaded=0;  ///USE raceid=1;raceid<=GetRacesLoaded();raceid++ for looping
///race instance variables
//RACE ID = index of [MAXRACES], raceid 1 is raceName[1][32]

//new Handle:DiamondTimerHandle;

new String:item2Name[MAXITEMS][64];
new String:item2Shortname[MAXITEMS][16];
new String:item2Description[MAXITEMS][512];

new item2diamondCost[MAXITEMS];
new item2Property[MAXITEMS][W3ItemProp] ;

new item2OrderCvar[MAXITEMS];
new item2FlagsCvar[MAXITEMS];
new item2CategoryCvar[MAXITEMS];

new bool:item2Translated[MAXITEMS];
new Handle:hShop2Enabled;

public Plugin:myinfo= 
{
  name="W3S Engine Item Class 2",
  author="Ownz (DarkEnergy)",
  description="War3Source Core Plugins",
  version="1.0",
  url="http://war3source.com/"
};


public OnPluginStart()
{
  //DiamondTimerHandle=CreateTimer(66.0,Diamond_Timer,TIMER_REPEAT);
  //CreateTimer(60.0,Diamond_Timer,TIMER_REPEAT);
  CreateTimer(60.0,Timer_Diamonds);
}

public OnAllPluginsLoaded()
{
	hShop2Enabled = FindConVar("war3_shop2_enabled");
}

bool:Shop2Enabled()
{
	if(hShop2Enabled != INVALID_HANDLE)
	{
		return GetConVarBool(hShop2Enabled);
	}
	return false;
}
/*
public OnPluginEnd()
{
  KillTimer(DiamondTimerHandle);
}


public OnMapEnd()
{
  KillTimer(DiamondTimerHandle);
}
*/

public bool:InitNativesForwards()
{
  CreateNative("War3_CreateShopItem2",NWar3_CreateShopItem2);
  CreateNative("War3_CreateShopItem2T",NWar3_CreateShopItem2T);
  
  CreateNative("War3_SetItem2Property",NWar3_SetItem2Property);
  CreateNative("War3_GetItem2Property",NWar3_GetItem2Property);
  
  CreateNative("War3_GetItem2IdByShortname",NWar3_GetItem2IdByShortname);
  
  CreateNative("W3GetItem2Name",NW3GetItem2Name);
  CreateNative("W3GetItem2Shortname",NW3GetItem2Shortname);
  CreateNative("W3GetItem2Desc",NW3GetItem2Description);

  CreateNative("W3GetItems2Loaded",Native_GetItems2Loaded);
  
  CreateNative("W3GetItem2Cost",NW3GetItem2Cost);


  CreateNative("W3GetItem2Order",NW3GetItem2Order);
  CreateNative("W3Item2HasFlag",NW3Item2HasFlag);
  CreateNative("W3GetItem2Catagory",NW3GetItem2Catagory);
  
  
  return true;
}

public Action:Timer_Diamonds(Handle:timer, any:userid)
{
	if(Shop2Enabled())
	{
		for(new i=1; i<GetMaxClients(); i++)
		{
			if(ValidPlayer(i))
			{
				new GivePlayerDiamonds = War3_GetDiamonds(i) + 1;
				War3_SetDiamonds(i, GivePlayerDiamonds);
			}
		}
	}
	CreateTimer(60.0,Timer_Diamonds);
}


public NWar3_CreateShopItem2(Handle:plugin,numParams)
{
  
  decl String:name[64],String:shortname[16],String:desc[512];
  GetNativeString(1,name,sizeof(name));
  GetNativeString(2,shortname,sizeof(shortname));
  GetNativeString(3,desc,sizeof(desc));
  new cost=GetNativeCell(4);
  new itemid=CreateNewItem2(name,shortname,desc,cost);
  return itemid;
}
public NWar3_CreateShopItem2T(Handle:plugin,numParams)
{
  
  decl String:name[64],String:shortname[16],String:desc[512];
  GetNativeString(1,shortname,sizeof(shortname));
  new cost=GetNativeCell(2);
  
  Format(name,sizeof(name),"%s_temName",shortname);

  Format(desc,sizeof(desc),"%s_temDesc",shortname);

  new itemid=CreateNewItem2(name,shortname,desc,cost);
  item2Translated[itemid]=true;

  /*
  if(StrEqual(shortname,"scroll")){
    Format(shortname,sizeof(shortname),"_scroll");   ///SHORTNAME IS ONLY USED ONCE BELOW
  }
  */
  
  new String:buf[64];
  Format(buf,sizeof(buf),"w3s.item2.%s.phrases.txt",shortname);
  LoadTranslations(buf);
  return itemid;
}

public NWar3_SetItem2Property(Handle:plugin,numParams)
{
  new item=GetNativeCell(1);
  new W3ItemProp:property=GetNativeCell(2);
  new any:value=GetNativeCell(3);
  SetItem2Property(item,property,value);
}
public NWar3_GetItem2Property(Handle:plugin,numParams)
{
  new item=GetNativeCell(1);
  new W3ItemProp:property=GetNativeCell(2);
  return GetItem2Property(item,property);
}
public NWar3_GetItem2IdByShortname(Handle:plugin,numParams)
{

  new String:itemshortname[16],String:argstr[16];
  GetNativeString(1,argstr,16);
  new ItemsLoaded = W3GetItems2Loaded();
  for(new i=1;i<=ItemsLoaded;i++){
    GetItem2Shortname(i,itemshortname,sizeof(itemshortname));
    if(StrEqual(argstr,itemshortname)){
      return i;
    }
  }
  return 0;
}



public NW3GetItem2Name(Handle:plugin,numParams)
{
  new itemid=GetNativeCell(1);
  new String:str[64];
  GetItem2Name(itemid,str,sizeof(str));
  SetNativeString(2,str,GetNativeCell(3));
}
public NW3GetItem2Shortname(Handle:plugin,numParams)
{
  new itemid=GetNativeCell(1);

  new String:str[16];
  GetItem2Shortname(itemid,str,sizeof(str));
  SetNativeString(2,str,GetNativeCell(3));
  
}
public NW3GetItem2Description(Handle:plugin,numParams)
{
  new itemid=GetNativeCell(1);

  new String:str[512];
  GetItem2Description(itemid,str,sizeof(str));
  SetNativeString(2,str,GetNativeCell(3));
}
public Native_GetItems2Loaded(Handle:plugin,numParams)
{
  return totalItems2Loaded;
}


public NW3GetItem2Cost(Handle:plugin,numParams)
{
  new itemid=GetNativeCell(1);
  return W3GetCvarInt(item2diamondCost[itemid]);
}


public NW3GetItem2Order(Handle:plugin,numParams)
{
  new itemid=GetNativeCell(1);
  return W3GetCvarInt(item2OrderCvar[itemid]);
}
public NW3Item2HasFlag(Handle:plugin,numParams)
{
  new itemid=GetNativeCell(1);
  new String:buf[1000];
  W3GetCvar(item2FlagsCvar[itemid],buf,sizeof(buf));
  
  new String:flagsearch[32];
  GetNativeString(2,flagsearch,sizeof(flagsearch));
  
  return (StrContains(buf,flagsearch)>-1);
}
public NW3GetItem2Catagory(Handle:plugin,numParams)
{
  new itemid=GetNativeCell(1);
  new String:buf[1000];
  W3GetCvar(item2CategoryCvar[itemid],buf,sizeof(buf));
  SetNativeString(2,buf,GetNativeCell(3));
}











CreateNewItem2(String:titemname[] ,String:titemshortname[] ,String:titemdescription[], itemcostgold){
  
  if(totalItems2Loaded+1==MAXITEMS){ //make sure we didnt reach our item capacity limit
    LogError("MAX ITEMS REACHED, CANNOT REGISTER %s",titemname);
    return -1;
  }
  
  //first item registering, fill in the  zeroth  along
  if(totalItems2Loaded==0){
    
    Format(item2Name[0],31,"ZEROTH ITEM");

  }
  else{
    decl String:shortnameexisted[16];
    new ItemsLoaded = W3GetItems2Loaded();
    for(new i=1;i<=ItemsLoaded;i++){
      GetItem2Shortname(i,shortnameexisted,sizeof(shortnameexisted));
      if(StrEqual(titemshortname,shortnameexisted)){
        return i; //item already exists
      }
    }
  }
  
  
  
  totalItems2Loaded++;
  new titemid=totalItems2Loaded;
  
  strcopy(item2Name[titemid], 31, titemname);
  strcopy(item2Shortname[titemid], 15, titemshortname);
  strcopy(item2Description[titemid], 511, titemdescription);
  
  new String:cvarstr[32];
  Format(cvarstr,sizeof(cvarstr),"%s_diamondcost",titemshortname);
  item2diamondCost[titemid]=W3CreateCvarInt(cvarstr,itemcostgold,"item2 cost with diamonds");
  
  Format(cvarstr,sizeof(cvarstr),"%s_item2order",titemshortname);
  item2OrderCvar[titemid]=W3CreateCvarInt(cvarstr,titemid*200,"item2 order");
  
  Format(cvarstr,sizeof(cvarstr),"%s_item2flags",titemshortname);
  item2FlagsCvar[titemid]=W3CreateCvar(cvarstr,"0","item2 flags");
  
  Format(cvarstr,sizeof(cvarstr),"%s_item2category",titemshortname);
  item2CategoryCvar[titemid]=W3CreateCvar(cvarstr,"0","item2 category");
  
  return titemid; //this will be the new item's id / index
}
GetItem2Name(itemid,String:str[],len){
  if(item2Translated[itemid]){
    
    new String:buf[64];
    Format(buf,sizeof(buf),"%T",item2Name[itemid],GetTrans());
    strcopy(str,len,buf);
  }
  else{
    strcopy(str,len,item2Name[itemid]);
  }
}
GetItem2Shortname(itemid,String:str[],len){
  strcopy(str,len,item2Shortname[itemid]);

}
GetItem2Description(itemid,String:str[],len){
  if(item2Translated[itemid]){
    new String:buf[512];
    Format(buf,sizeof(buf),"%T",item2Description[itemid],GetTrans());
    strcopy(str,len,buf);
  }
  else{
    strcopy(str,len,item2Description[itemid]);
  }
}



SetItem2Property(item,W3ItemProp:ITEMproperty,any:value)  {
  item2Property[item][ITEMproperty]=value;
}
GetItem2Property(item,W3ItemProp:ITEMproperty){
  return item2Property[item][ITEMproperty];
}















