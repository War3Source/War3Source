#pragma semicolon 1

#include <sourcemod>
#include "sdkhooks"
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
  name = "War3Source - Engine - Buff System",
  author = "War3Source Team",
  description = "The main controller when it comes to setting/getting buffs"
};

//for debuff index, see constants, its in an enum
new any:buffdebuff[MAXPLAYERSCUSTOM][W3Buff][MAXITEMS+MAXRACES+MAXITEMS2+CUSTOMMODIFIERS]; ///a race may only modify a property once

new BuffProperties[W3Buff][W3BuffProperties];

new any:BuffCached[MAXPLAYERSCUSTOM][W3Buff];// instead of looping, we cache everything in the last dimension, see enum W3BuffCache

public OnPluginStart()
{
  
  InitiateBuffPropertiesArray(BuffProperties);
  
  
  RegConsoleCmd("bufflist",cmdbufflist);
}

public bool:InitNativesForwards()
{
  
  CreateNative("War3_SetBuff",Native_War3_SetBuff);//for races
  CreateNative("War3_SetBuffItem",Native_War3_SetBuffItem);//foritems
  CreateNative("War3_SetBuffItem2",Native_War3_SetBuffItem2);//foritems
  
  CreateNative("W3BuffCustomOFFSET",NW3BuffCustomOFFSET);
  
  CreateNative("W3GetPhysicalArmorMulti",NW3GetPhysicalArmorMulti);
  CreateNative("W3GetMagicArmorMulti",NW3GetMagicArmorMulti);
  
  
  CreateNative("W3GetBuff",NW3GetBuff);
  CreateNative("W3GetBuffSumInt",NW3GetBuffSumInt);
  CreateNative("W3GetBuffHasTrue",NW3GetBuffHasTrue);
  CreateNative("W3GetBuffStackedFloat",NW3GetBuffStackedFloat);
  
  CreateNative("W3GetBuffSumFloat",NW3GetBuffSumFloat);
  CreateNative("W3GetBuffMinFloat",NW3GetBuffMinFloat);
  CreateNative("W3GetBuffMaxFloat",NW3GetBuffMaxFloat);
  
  CreateNative("W3GetBuffMinInt",NW3GetBuffMinInt);
  CreateNative("W3GetBuffLastValue",NW3GetBuffLastValue);
  
  CreateNative("W3ResetAllBuffRace",NW3ResetAllBuffRace);
  CreateNative("W3ResetBuffRace",NW3ResetBuffRace);
  CreateNative("W3ResetBuffItem",NW3ResetBuffItem);
  
  CreateNative("W3GetBuffLoopLimit",NW3GetBuffLoopLimit);
  return true;
}
ItemsPlusRacesLoaded(){
  return W3GetItemsLoaded()+War3_GetRacesLoaded()+CUSTOMMODIFIERS;
}
public NW3BuffCustomOFFSET(Handle:plugin,numParams)
{
  return W3GetItemsLoaded()+War3_GetRacesLoaded();
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
public NW3GetBuffSumInt(Handle:plugin,numParams)
{
  new client=GetNativeCell(1);
  new W3Buff:buffindex=GetNativeCell(2);
  return GetBuffSumInt(client,buffindex);
}

//stop complaining that we are returning a float!
public NW3GetPhysicalArmorMulti(Handle:plugin,numParams) {
  return _:PhysicalArmorMulti(GetNativeCell(1));
}

public NW3GetMagicArmorMulti(Handle:plugin,numParams) {
  
  return _:MagicArmorMulti(GetNativeCell(1));
}
public NW3GetBuffLastValue(Handle:plugins,numParams) {
  return GetBuffLastValue(GetNativeCell(1),GetNativeCell(2));
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

public NW3ResetBuffItem(Handle:plugin,numParams) {
  new client=GetNativeCell(1);
  new W3Buff:buffindex=W3Buff:GetNativeCell(2);
  new item=GetNativeCell(3);
  
  ResetBuffParticularRaceOrItem(client,W3Buff:buffindex,item);  
}

public NW3GetBuffLoopLimit(Handle:plugin,numParams) {
  return BuffLoopLimit();
}




public Action:cmdbufflist(client, args){
  
  if(args==1){
    new String:arg[32];
    GetCmdArg(1,arg,sizeof(arg));
    new buff=StringToInt(arg);
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
      War3_LogInfo("buff for client %d buffid %d : %d %f race/item %s",client,buff,buffdebuff[client][W3Buff:buff][i],buffdebuff[client][W3Buff:buff][i],name);
      
    }
  }
}


public OnClientPutInServer(client){
  
  //reset all buffs for each race and item
  for(new buffindex=0;buffindex<MaxBuffLoopLimit;buffindex++)
  {
    ResetBuff(client,W3Buff:buffindex);
  }
  
  
  //SDKHook(client, SDKHook_PreThink, OnPreThink);
  //SDKHook(client, SDKHook_PostThinkPost, OnPreThink);
  //SDKHook(client,SDKHook_PostThinkPost,SDK_Forwarded_PostThinkPost);
}




SetBuff(client,W3Buff:buffindex,itemraceindex,value)
{
  //PrintToServer("client %d buffindex %d raceitemindex %d value: %d %f",client,buffindex,itemraceindex,value,value);
  buffdebuff[client][buffindex][itemraceindex]=value;
  
  if(buffindex==fMaxSpeed||buffindex==fSlow||buffindex==bStunned||buffindex==bBashed){
    W3ReapplySpeed(client); 
  }
  DoCalculateBuffCache(client,buffindex,itemraceindex);
  
  W3SetVar(EventArg1,buffindex); //generic war3event arguments
  W3SetVar(EventArg2,itemraceindex); 
  W3SetVar(EventArg3,value); 
  W3CreateEvent(W3EVENT:OnBuffChanged,client);
  
  
}
/*
GetBuff(client,W3Buff:buffindex,itemraceindex){
return buffdebuff[client][buffindex][itemraceindex];
}*/
///REMOVE SINGLE BUFF FROM ALL RACES
ResetBuff(client,W3Buff:buffindex){
  
  if(ValidBuff(buffindex))
  {
    new loop = ItemsPlusRacesLoaded();
    for(new i=0;i<=loop;i++) //reset starts at 0
    {
      buffdebuff[client][buffindex][i]=BuffDefault(buffindex);
      
      DoCalculateBuffCache(client,buffindex,i);
    }
    W3ReapplySpeed(client);
    
  }
}
//RESET SINGLE BUFF OF SINGLE RACE
ResetBuffParticularRaceOrItem(client,W3Buff:buffindex,particularraceitemindex){
  if(ValidBuff(buffindex))
  {
    buffdebuff[client][buffindex][particularraceitemindex]=BuffDefault(buffindex);
    
    DoCalculateBuffCache(client,buffindex,particularraceitemindex);
    W3ReapplySpeed(client);
  }
}

DoCalculateBuffCache(client,W3Buff:buffindex,particularraceitemindex){
    //temporarily disable caching
    //return;
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
        case iLastValue: BuffCached[client][buffindex]=CalcBuffRecentValue(client,buffindex,particularraceitemindex);
    }
    return;
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

//Returns the most recent value set by any race
stock CalcBuffRecentValue(client,W3Buff:buffindex,race)
{
  if(ValidBuff(buffindex))
  {
    new value = buffdebuff[client][buffindex][race];
    if(value!=-1) 
    {
      return value;
    } else {
      return BuffCached[client][buffindex];
    }
  }
  LogError("invalid buff index");
  return -1;
}


////////getting cached values!
stock GetBuffLastValue(client,W3Buff:buffindex)
{
  if(ValidBuff(buffindex))
  { 
    if(BuffCacheType(buffindex)!=iLastValue){
      ThrowError("Tried to get cached value when buff index (%d) should not cache this type (%d)",buffindex,BuffCacheType(buffindex));
    }
    return BuffCached[client][buffindex];
    
  }
  LogError("invalid buff index");
  return false;
}
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
    if (ValidPlayer(client)) {
      return Float:BuffCached[client][buffindex];
    }
    else {
      return 0.0;
    }
    
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
  //  W3Log("deny render fx %d",index);
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


//use 0 < limit
stock BuffLoopLimit(){
  return W3GetItemsLoaded()+War3_GetRacesLoaded()+1;
}