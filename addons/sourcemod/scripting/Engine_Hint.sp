#pragma semicolon 1

#include <profiler>
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "War3Source - Engine - Hint Display",
	author = "War3Source Team",
	description = "Improved HintText functionality"
};


new UserMsg:umHintText;
new bool:enabled = true; //cvar value

new Handle:objarray[MAXPLAYERSCUSTOM][W3HintPriority];
new bool:updatenextframe[MAXPLAYERSCUSTOM];
new String:lastoutput[MAXPLAYERSCUSTOM][129];

public bool:InitNativesForwards()
{
	CreateNative("W3Hint",NW3Hint);
	//W3Hint(client,W3HintPriority:type=HINT_LOWEST,Float:duration=5.0,String:format[],any:...);
	return true;
}

public OnPluginStart()
{
	// NOTICE: file a bug report if you wan't this to be disabled for cs:go
	//CreateTimer(0.2,Time,_,TIMER_REPEAT);
	
	umHintText = GetUserMessageId("HintText");
	
	if (umHintText == INVALID_MESSAGE_ID)
		SetFailState("This game doesn't support HintText???");
	
	HookUserMessage(umHintText, MsgHook_HintText,true);
}

public OnWar3EventSpawn(client)
{
	//delay then refresh their hints
	//W3Hint(client,_,0.1,"Www.War3Source.Com"); //this is a hackish way of doing it, since it will not refresh if hint string is equal
	lastoutput[client][0] = '\0';
}

public OnWar3Event(W3EVENT:event,client)
{
	switch(event)
	{
		case ClearPlayerVariables:
		{ 
			DeleteObject(client);
		}
	}
}

public NW3Hint(Handle:plugin,numParams)
{
	if(enabled)
	{
		new client= GetNativeCell(1);
		if(!ValidPlayer(client)) return 0;

		new W3HintPriority:priority=W3HintPriority:GetNativeCell(2);
		new Float:Duration=GetNativeCell(3);
		if(Duration>20.0){ Duration=20.0;}	
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

		//must have \n					  
		new len=strlen(output);		 
		if(len>0&&output[len-1]!='\n')
		{
			StrCat(output, sizeof(output), "\n");
		}

		new Handle:arr=objarray[client][priority];
		if (arr == INVALID_HANDLE)
			objarray[client][priority] = arr = CreateArray(ByteCountToCells(128)); //128 characters;

		if(W3GetHintPriorityType(priority)==HINT_TYPE_SINGLE)
		{
			ClearArray(arr);
		}

		//does it already exist? then update time
		new index=FindStringInArray(arr,output);
		if(index>=0)
		{
			SetArrayCell(arr,index+1,Duration + GetEngineTime()); //ODD
		}
		else
		{
			PushArrayString(arr, output); //EVEN
			PushArrayCell(arr,Duration + GetEngineTime()); //ODD
		}

		updatenextframe[client]=true;
	}
	return 1;
}

/*public Action:Time(Handle:t){
	//PrintHintTextToAll("01234567890123456789012345678901234567890123456789\n01234567890123456789012345678901234567890123456789\n01234567890123456789012345678901234567890123456789\n01234567890123456789012345678901234567890123456789\n01234567890123456789012345678901234567890123456789\n");
	
}*/

public OnGameFrame()
{
	if(enabled)
	{
	//#define PROFILE
	#if defined PROFILE
		new Handle:p=CreateProfiler();
		StartProfiling(p);
	#endif
		for (new client = 1; client <= MaxClients; client++)
		{
			if (ValidPlayer(client,true)&&!IsFakeClient(client))
			{
				//this 0.3 resolution only affects expiry, does not delay new messages as that is signaled by updatenextframe
				static Float:lastshow[MAXPLAYERSCUSTOM];
				new Float:time = GetEngineTime();
				if (lastshow[client] < time-0.3 || updatenextframe[client])
				{
					//PrintToServer("%f < %f, bool %d", lastshow[client],time-0.5,updatenextframe[client]);
					updatenextframe[client]=false;
					lastshow[client]=time;
					decl String:output[128];
					output[0]=0;
					for (new W3HintPriority:priority=HINT_NORMAL; priority < HINT_SIZE; priority++)
					{
						new Handle:arr=objarray[client][priority];
						if (arr != INVALID_HANDLE)
						{
							new size=GetArraySize(arr);
							
							//DP("%d size %d",priority,size);
							if (size)
							{
								for (new arrindex=0;arrindex<size;arrindex+=2)
								{
									new Float:expiretime=GetArrayCell(arr,arrindex+1);
									if (time > expiretime)
									{
										//expired
										RemoveFromArray(arr, arrindex);
										RemoveFromArray(arr, arrindex); //new array shifted down, delete same position
										size=GetArraySize(arr); //resized
										arrindex-=2;					//rollback
										continue;
									}
									else
									{
										//then this did not expire, we can print
										new String:str[128];
										GetArrayString(arr,arrindex   ,str,sizeof(str));	
										StrCat(output,sizeof(output),str);
										//DP("cat %s",str);
										if(W3GetHintPriorityType(W3HintPriority:priority)!=HINT_TYPE_ALL) //PRINT ONLY 1
										{
											break;
										}
									}
								}
								if (size&&W3HintPriority:priority==HINT_NORMAL) //size may have changed when somethign expired
								{
									StrCat(output,sizeof(output)," \n");
								}
							}
						}
					}
					//DP("0000 %s %d %d %d",output ,strlen(output), strcmp(output," "),strcmp(output,"  "));

					if(strlen(output)>1 /*&& strcmp(output," ")==-1 && strcmp(output,"  ")==-1*/)
					{
						//DP("-1");
						if(GAMECSGO)
						{
							StopSound(client, SNDCHAN_STATIC, "music/war3source/csgo/ui/hint.mp3");
						}
						else
						{
							StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
						}
						//if(output[strlen(output)-1]=='\n')
						//{ 
						//PrintToServer("deleted");
						//output[strlen(output)-1]='\0';
						//	}
						/*	PrintToServer("|||%s",output);
							new index=FindCharInString(output, '\n');
							PrintToServer("IDE%d",index);
							if(index>0&&index==strlen(output)-1){
						//StrCat(output,sizeof(output),"\n\n");
						PrintToServer("cat");
						}*/

						new len=strlen(output);
						while (len>0 && (output[len-1]=='\n' || output[len-1]==' ' ))
						{
							len -= 1; //keep eating the last returns
							output[len] = '\0';
						}

						if (!StrEqual(lastoutput[client],output))
						{
						//DP("1");
							//PrintToServer("[W3Hint] printing \"%s\"",output);
							PrintHintText(client," %s",output); //NEED SPACE
							//if(!IsFakeClient(client)){
							//	DP("%s %d",output,GetGameTime());
							//}

							//PrintToChat(client,"%s %f",output,lastshow[client]);
						}
						//DP("2");
					}
					strcopy(lastoutput[client],sizeof(output),output);
				}
				//Update(i);
			}
		} 
#if defined PROFILE
		StopProfiling(p);
		PrintToServer("%f",GetProfilerTime(p));
		CloseHandle(p);
#endif
	}
}

DeleteObject(client)
{
	//if ur object holds handles, close them!!
	for(new W3HintPriority:i=HINT_NORMAL; i < HINT_SIZE; i++)
	{
		new Handle:arr=objarray[client][i];
		if (arr)
		{
			//PrintToServer("%d",arr));
			CloseHandle(arr); //this is the array created above
			objarray[client][i] = INVALID_HANDLE;
		}
	}
}

public Action:MsgHook_HintText(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
//do NOT print to chat here
//do NOT print to chat here
//do NOT print to chat here
//do NOT print to chat here
//do NOT print to chat here

	new bool:intercept=false;
	
	if(enabled)
	{
		new String:str[128];
		BfReadString(Handle:bf, str, sizeof(str), false);
		//PrintToServer("[W3Hint] recieved \"%s\"",str);

		if(str[0]!=' '&&str[0]!='#')
		{
			intercept=true;
		}

		for (new i = 0; i < playersNum; i++)
		{
			if (players[i] != 0 && IsClientInGame(players[i]) && !IsFakeClient(players[i]))
			{
				if(GAMECSGO)
				{
					StopSound(players[i], SNDCHAN_STATIC, "music/war3source/csgo/ui/hint.mp3");
				}
				else
				{
					StopSound(players[i], SNDCHAN_STATIC, "UI/hint.wav");
				}
				if (intercept)
				{
					W3Hint(players[i],HINT_NORMAL,4.0,str); //causes update
					//urgent update
					updatenextframe[players[i]]=true;
					//Update(players[i]);
					//PrintToServer("captured %s",str);
					
				}
			}
		}
	}
	return (intercept) ? Plugin_Handled : Plugin_Continue;
}
