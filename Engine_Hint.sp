
#include <profiler>
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


new Handle:objarray;
new UserMsg:umHintText

//add arbitrary short charactres to this
#define MAXKEYCOUNT 30
#define MAXKEYLEN 2
new String:key[MAXKEYCOUNT][MAXKEYLEN]; // "1\0" = 2 bytes
//need these fake keys for tries
/*
enum W3HintPriority{
	HINT_DMG_DEALT,
	HINT_DMG_RCVD,
	HINT_COOLDOWN,
	HINT_LOWEST,
}
*/
public Plugin:myinfo= 
{
	name="Engine Hint Display",
	author="Ownz",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};

public APLRes:AskPluginLoad2Custom(Handle:plugin,bool:late,String:error[],err_max)
{
	for(new i=0;i<MAXKEYCOUNT;i++){
		IntToString(i,key[i],MAXKEYLEN);
	}
	objarray=CreateArray(1,MAXPLAYERSCUSTOM+1);
	for(new i=0;i<GetArraySize(objarray);i++){
		SetArrayCell(objarray,i,INVALID_HANDLE);
	}
	return APLRes_Success;
}
public bool:InitNativesForwards(){
	CreateNative("W3Hint",NW3Hint);
	//W3Hint(client,W3HintPriority:type=HINT_LOWEST,Float:duration=5.0,String:format[],any:...);
	return true;
}
public OnPluginStart()
{
	CreateTimer(1.0,Time,_,TIMER_REPEAT);
	
	
	umHintText = GetUserMessageId("HintText");
	
	if (umHintText == INVALID_MESSAGE_ID)
		SetFailState("This game doesn't support HintText");
	
	HookUserMessage(umHintText, MsgHook_HintText);
}
public OnWar3Event(W3EVENT:event,client){
	switch(event){
		case InitPlayerVariables:{
			 CreateObject(client);
			 for(new i=0;i<_:HINT_SIZE;i++)
			 {
			 	SetCell(Object(client),  i  ,CreateArray(ByteCountToCells(128)));
			 	
			 }
			 for(new i=0;i<_:HINT_SIZE;i++)
			 {
			 	PrintToServer("%d",GetCell(Object(client),i));
			 }
		}
		case ClearPlayerVariables:
		{ 
			//if ur object holds handles, close them!!
			for(new i=0;i<_:HINT_SIZE;i++)
			{
				//new Handle:h=
				PrintToServer("%d",GetCell(Object(client),i));
				PrintToServer("%d",i);
			//	CloseHandle(Handle:GetCell(Object(client),i));
			}
			DeleteObject(client);
		}
	}
}
public NW3Hint(Handle:plugin,numParams)
{
	new client= GetNativeCell(1);
	
	if(!ValidPlayer(client)) return 0;
	
	new priority=GetNativeCell(2);
	new Float:Duration=GetNativeCell(3);
	if(Duration>20){ Duration=20.0;}	
	new String:format[128];
	GetNativeString(4,format,sizeof(format));
	new String:output[128];
	FormatNativeString(0, 
                          4, 
                          5, 
                          sizeof(output),
                          dummy,
                          output
						  );
						  
						 // PrintToServer("%s || %s",format,output);
	StrCat(output, sizeof(output), "\n");
	new Handle:arr=Handle:GetCell(Object(client),priority);
	if(W3GetHintPriorityType(W3HintPriority:priority)==HINT_TYPE_SINGLE){
		ClearArray(Handle:arr);
	}
	PushArrayString(arr, output); //EVEN
	PushArrayCell(arr,Duration); //ODD
	Update(client);
	return 1;
}
public Action:Time(Handle:t){
	//PrintHintTextToAll("01234567890123456789012345678901234567890123456789\n01234567890123456789012345678901234567890123456789\n01234567890123456789012345678901234567890123456789\n01234567890123456789012345678901234567890123456789\n01234567890123456789012345678901234567890123456789\n");
	for (new i = 1; i <= MaxClients; i++)
	{
		if (ValidPlayer(i))
		{
			//Update(i);
		}
	} 
}
Update(client){
#if defined PROFILE
	new Handle:p=CreateProfiler();
	StartProfiling(p);
#endif
	static Float:lastshow[MAXPLAYERSCUSTOM];
	if(lastshow[client]<GetEngineTime()-0.01){
		
		lastshow[client]=GetEngineTime();
		new String:output[128];
		for(new priority=0;priority<_:HINT_SIZE;priority++)
		{
			new Handle:arr=Handle:GetCell(Object(client),priority);
			new size=GetArraySize(arr);
			if(size){
				for(new arrindex=0;arrindex<size;arrindex+=2){
					new Float:expiretime=GetArrayCell(arr,arrindex+1);
					if(expiretime<21.0){
						SetArrayCell(arr,arrindex+1,expiretime+GetEngineTime());
					}
					if(expiretime<GetEngineTime()){
						new String:str[128];
						GetArrayString(arr,arrindex   ,str,sizeof(str));	
						StrCat(output,sizeof(output),str);
						if(W3GetHintPriorityType(W3HintPriority:priority)!=HINT_TYPE_ALL){
							break;
						}
					}
					else{
						//expired
						RemoveFromArray(arr, arrindex);
						RemoveFromArray(arr, arrindex); //new array shifted down, delete same position
						size=GetArraySize(arr); //resized
						arrindex-=2;					//rollback
						continue;
					}
					
				}
			}
		}
		if(strlen(output)){
			//PrintToServer("|||%s",output);
			StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
			PrintHintText(client,"%s \nASFD\nASFD\nASFD\nASFD\nASFD\nASFD\nASFD\nASFD",output); //it wants a space after it, or it will display same line twice....
			
		}
	
	}
	#if defined PROFILE
	StopProfiling(p);
	PrintToServer("%f",GetProfilerTime(p));
	CloseHandle(p);
	#endif
}







CreateObject(client){
	SetArrayCell(objarray,client,CreateTrie());
}
DeleteObject(client){
	//if(Object(client)!=INVALID_HANDLE)
//	{
	CloseHandle(Object(client));
//	}
	SetArrayCell(objarray,client,INVALID_HANDLE);
}
Handle:Object(client){
	return Handle:GetArrayCell(objarray,client);
}
GetCell(Handle:obj,any:index){
	
	PrintToServer("%s",key[index]);
	new value;
	if(!GetTrieValue(obj, key[index], value)){
		return ThrowError("trie get cell failed");
	}
	return value;
}

SetCell(Handle:obj,any:index,any:value){
	
	if(!SetTrieValue(obj, key[index], value)){
		return ThrowError("trie set cell failed");
	}
	return value;
}
stock GetString(Handle:obj,any:index,String:str[],maxlen){

	if(!GetTrieString(obj, key[index], str,maxlen)){
		return ThrowError("trie get cell failed");
	}
	return 1;
}
stock SetString(Handle:obj,any:index,String:str[]){
	
	if(!SetTrieString(obj, key[index], str)){
		return ThrowError("trie get cell failed");
	}
	return 1;
}

public Action:MsgHook_HintText(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	//new String:str[128];
	//BfReadString(Handle:bf, str, sizeof(str), false);
	//	PrintToServer("%s",str);
	for (new i = 0; i < playersNum; i++)
	{
		if (players[i] != 0 && IsClientInGame(players[i]) && !IsFakeClient(players[i]))
		{
			StopSound(players[i], SNDCHAN_STATIC, "UI/hint.wav");
		}
	}
}