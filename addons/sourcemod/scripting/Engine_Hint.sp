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

new UserMsg:umsgHintText;
new bool:bEnabled = true; //cvar value
new bool:bUpdateNextFrame[MAXPLAYERSCUSTOM];
new String:sLastOutput[MAXPLAYERSCUSTOM][129];
new Handle:hObjArray[MAXPLAYERSCUSTOM][W3HintPriority];

public bool:InitNativesForwards()
{
    CreateNative("W3Hint", NW3Hint);

    return true;
}

public OnPluginStart()
{
    umsgHintText = GetUserMessageId("HintText");

    if (umsgHintText == INVALID_MESSAGE_ID)
    {
        SetFailState("This game doesn't support HintText!");
    }

    HookUserMessage(umsgHintText, MsgHook_HintText, true);
    
    //LoadTranslations("w3s._common.phrases.txt");
}

public OnWar3EventSpawn(client)
{
    sLastOutput[client][0] = '\0';
}

public OnWar3Event(W3EVENT:event, client)
{
    if(event == ClearPlayerVariables)
    { 
        DeleteObject(client);
    }
}


W3Hint_Internal(client,W3HintPriority:priority,Float:fDuration,String:sOutput[128])
{
    if(bEnabled)
    {
        // why sFormat??  it doesn't even use it!
        //new String:sFormat[128];

        //new client = GetNativeCell(1);
        //new W3HintPriority:priority = W3HintPriority:GetNativeCell(2);
        //new Float:fDuration = GetNativeCell(3);
        //GetNativeString(4, sFormat, sizeof(sFormat));

        //if(!ValidPlayer(client)) 
        //{
          //  return 0;
        //}
        if(fDuration > 20.0)
        {
            fDuration = 20.0;
        }
        
        //new String:sOutput[128];
        //FormatNativeString(0, 4, 5, sizeof(sOutput), dummy, sOutput);

        //must have \n
        new len = strlen(sOutput);
        if(len > 0 && sOutput[len-1] != '\n')
        {
            StrCat(sOutput, sizeof(sOutput), "\n");
        }

        new Handle:arr = hObjArray[client][priority];
        if (arr == INVALID_HANDLE)
        {
            hObjArray[client][priority] = arr = CreateArray(ByteCountToCells(128)); //128 characters;
        }

        if(W3GetHintPriorityType(priority) == HINT_TYPE_SINGLE)
        {
            ClearArray(arr);
        }

        //does it already exist? then update time
        new index = FindStringInArray(arr, sOutput);
        if(index >= 0)
        {
            SetArrayCell(arr, index + 1, fDuration + GetEngineTime()); //ODD
        }
        else
        {
            PushArrayString(arr, sOutput); //EVEN
            PushArrayCell(arr, fDuration + GetEngineTime()); //ODD
        }

        bUpdateNextFrame[client] = true;
    }
    
    return 1;
}

public NW3Hint(Handle:plugin,numParams)
{
    if(bEnabled)
    {
        new client = GetNativeCell(1);

        if(!ValidPlayer(client)) 
        {
            return 0;
        }

        new W3HintPriority:priority = W3HintPriority:GetNativeCell(2);
        new Float:fDuration = GetNativeCell(3);

        new String:sOutput[128];
        FormatNativeString(0, 4, 5, sizeof(sOutput), dummy, sOutput);

        return W3Hint_Internal(client,priority,fDuration,sOutput);
    }
    return 1;
}

public OnGameFrame()
{
    if(bEnabled)
    {
    //#define PROFILE
    #if defined PROFILE
        new Handle:p = CreateProfiler();
        StartProfiling(p);
    #endif
        for (new client = 1; client <= MaxClients; client++)
        {
            if (ValidPlayer(client, true) && !IsFakeClient(client))
            {
                //this 0.3 resolution only affects expiry, does not delay new messages as that is signaled by bUpdateNextFrame
                static Float:fLastShown[MAXPLAYERSCUSTOM];
                new Float:fCurrentTime = GetEngineTime();
                
                if (fLastShown[client] < fCurrentTime - 0.3 || bUpdateNextFrame[client])
                {
                    bUpdateNextFrame[client] = false;
                    fLastShown[client] = 0.0;
                    decl String:sOutput[128];
                    sOutput[0] = 0;
                    for (new W3HintPriority:priority=HINT_NORMAL; priority < HINT_SIZE; priority++)
                    {
                        new Handle:arr = hObjArray[client][priority];
                        if (arr != INVALID_HANDLE)
                        {
                            new size = GetArraySize(arr);
                            
                            if (size)
                            {
                                for (new arrindex=0; arrindex < size; arrindex += 2)
                                {
                                    new Float:expiretime=GetArrayCell(arr, arrindex + 1);
                                    if (fCurrentTime > expiretime)
                                    {
                                        //expired
                                        RemoveFromArray(arr, arrindex);
                                        RemoveFromArray(arr, arrindex); //new array shifted down, delete same position
                                        size=GetArraySize(arr); //resized
                                        arrindex -= 2; //rollback
                                        continue;
                                    }
                                    else
                                    {
                                        //then this did not expire, we can print
                                        new String:sArrayString[128];
                                        GetArrayString(arr, arrindex, sArrayString, sizeof(sArrayString));
                                        StrCat(sOutput, sizeof(sOutput), sArrayString);

                                        if(W3GetHintPriorityType(W3HintPriority:priority) != HINT_TYPE_ALL) //PRINT ONLY 1
                                        {
                                            break;
                                        }
                                    }
                                }
                                
                                //size may have changed when something expired
                                if (size && W3HintPriority:priority == HINT_NORMAL)
                                {
                                    StrCat(sOutput,sizeof(sOutput)," \n");
                                }
                            }
                        }
                    }

                    if(strlen(sOutput) > 1) 
                    {
                        // If this game has hudhint sounds make sure the player never hears them.
                        if(!GAMECSGO)
                        {
                            if(GAMEFOF)
                            {
                                StopSound(client, SNDCHAN_STATIC, "war3source/csgo/ui/hint.mp3");
                            }
                            else
                            {
                                StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
                            }
                        }

                        new len = strlen(sOutput);
                        while (len > 0 && (sOutput[len-1] == '\n' || sOutput[len-1] == ' '))
                        {
                            len -= 1; //keep eating the last returns
                            sOutput[len] = '\0';
                        }

                        if (!StrEqual(sLastOutput[client], sOutput))
                        {
                            if(GAMEFOF)
                            {
                                War3_ChatMessage(client, "{lightgreen} %s", sOutput);
                            }
                            else
                            {
                                PrintHintText(client, " %s", sOutput); //NEED SPACE
                            }
                        }
                    }
                    strcopy(sLastOutput[client], sizeof(sOutput), sOutput);
                }
            }
        } 
#if defined PROFILE
        StopProfiling(p);
        PrintToServer("%f", GetProfilerTime(p));
        CloseHandle(p);
#endif
    }
}

DeleteObject(client)
{
    //if ur object holds handles, close them!!
    for(new W3HintPriority:i=HINT_NORMAL; i < HINT_SIZE; i++)
    {
        new Handle:arr = hObjArray[client][i];
        if (arr)
        {
            CloseHandle(arr); //this is the array created above
            hObjArray[client][i] = INVALID_HANDLE;
        }
    }
}

/*
 * Intercept regular hint messages and pipe them through our W3Hint
 */
public Action:MsgHook_HintText(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
    new bool:bIntercept=false;
    
    if(bEnabled)
    {
        decl String:str[128];
        if (GetUserMessageType() != UM_Protobuf)
        {
            BfReadString(Handle:bf, str, sizeof(str), false);
        }
        else
        {
            PbReadString(bf, "text", str, sizeof(str));
        }

        if(str[0] != ' ' && str[0] != '#')
        {
            bIntercept = true;
        }

        for (new i = 0; i < playersNum; i++)
        {
            if (players[i] != 0 && IsClientInGame(players[i]) && !IsFakeClient(players[i]))
            {
                // Stop hudhint sound. This is not required on csgo because there is no sound.
                if(!GAMECSGO)
                {
                    StopSound(players[i], SNDCHAN_STATIC, "UI/hint.wav");
                }
                
                if (bIntercept)
                {
                    // Place the hint and shedule it to be shown immediately
                    W3Hint(players[i], HINT_NORMAL, 4.0, str);
                    bUpdateNextFrame[players[i]] = true;
                }
            }
        }
    }
    return (bIntercept) ? Plugin_Handled : Plugin_Continue;
}
