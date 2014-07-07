#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new bool:g_bCanEnumerateMsgType = false;
new UserMsg:g_umsgKeyHintText = INVALID_MESSAGE_ID;
new UserMsg:g_umsgFade = INVALID_MESSAGE_ID;
new UserMsg:g_umsgShake = INVALID_MESSAGE_ID;

public Plugin:myinfo = 
{
    name = "War3Source - Engine - UserMessages",
    author = "War3Source Team",
    description = "Manages UserMessage's"
};

public OnPluginStart()
{
    if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available)
    {
        g_bCanEnumerateMsgType = true;
    }

    // Lookup message id's and cache them.
    g_umsgKeyHintText = GetUserMessageId("KeyHintText");
    if (g_umsgKeyHintText == INVALID_MESSAGE_ID)
    {
        LogError("This game doesn't support KeyHintText!");
    }

    g_umsgFade = GetUserMessageId("Fade");
    if (g_umsgFade == INVALID_MESSAGE_ID)
    {
        LogError("This game doesn't support Fade!");
    }

    g_umsgShake = GetUserMessageId("Shake");
    if (g_umsgShake == INVALID_MESSAGE_ID)
    {
        LogError("This game doesn't support Shake!");
    }
}

public bool:InitNativesForwards()
{
    CreateNative("W3FlashScreen",Native_W3FlashScreen);
    CreateNative("War3_ShakeScreen",Native_War3_ShakeScreen);

    CreateNative("War3_KeyHintText",Native_War3_KeyHintText);

    return true;
}

public Native_W3FlashScreen(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    new color[4];
    GetNativeArray(2,color,4);
    new Float:holdduration = GetNativeCell(3);
    new Float:fadeduration = GetNativeCell(4);
    new flags = GetNativeCell(5);
    if(ValidPlayer(client,false))
    {
        new Handle:hBf = StartMessageExOne(g_umsgFade,client);
        if(hBf != INVALID_HANDLE)
        {
            if (g_bCanEnumerateMsgType && GetUserMessageType() == UM_Protobuf)
            {
                PbSetInt(hBf, "duration", RoundFloat(255.0*fadeduration));
                PbSetInt(hBf, "hold_time", RoundFloat(255.0*holdduration));
                PbSetInt(hBf, "flags", flags);
                PbSetColor(hBf, "clr", color);
            }
            else
            {
                BfWriteShort(hBf,RoundFloat(255.0*fadeduration));
                BfWriteShort(hBf,RoundFloat(255.0*holdduration)); //holdtime
                BfWriteShort(hBf,flags);
                BfWriteByte(hBf,color[0]);
                BfWriteByte(hBf,color[1]);
                BfWriteByte(hBf,color[2]);
                BfWriteByte(hBf,color[3]);
            }
            EndMessage();
        }
    }
}

public Native_War3_ShakeScreen(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    new Float:duration = GetNativeCell(2);
    new Float:magnitude = GetNativeCell(3);
    new Float:noise = GetNativeCell(4);
    if(ValidPlayer(client,false))
    {
        new Handle:hBf = StartMessageExOne(g_umsgShake,client);
        if(hBf != INVALID_HANDLE)
        {
            if (g_bCanEnumerateMsgType && GetUserMessageType() == UM_Protobuf)
            {
                PbSetInt(hBf, "command", 0);
                PbSetFloat(hBf, "local_amplitude", magnitude);
                PbSetFloat(hBf, "frequency", noise);
                PbSetFloat(hBf, "duration", duration);
            }
            else
            {
                BfWriteByte(hBf,0);
                BfWriteFloat(hBf,magnitude);
                BfWriteFloat(hBf,noise);
                BfWriteFloat(hBf,duration);
            }
            EndMessage();
        }
    }
}

public Native_War3_KeyHintText(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    new Handle:userMessage = StartMessageExOne(g_umsgKeyHintText, client);
    if(userMessage != INVALID_HANDLE)
    {
        decl String:format[254];
        
        // We don't need to format the string if we just received 2 params.
        if(numParams > 2)
        {
            decl String:buffer[254];

            GetNativeString(2, buffer, sizeof(buffer));
            GetNativeString(3, format, sizeof(buffer));
            
            SetGlobalTransTarget(client);
            FormatNativeString(0, 2, 3, sizeof(format), _, format);
        }
        else
        {
            GetNativeString(2, format, sizeof(format));
        }

        if (g_bCanEnumerateMsgType && GetUserMessageType() == UM_Protobuf)
        {
            PbSetString(userMessage, "hints", format);
        }
        else
        {
            BfWriteByte(userMessage, 1);
            BfWriteString(userMessage, format);
        }
        
        EndMessage();
    }
    return true;
}

stock Handle:StartMessageExOne(UserMsg:msg, client, flags=0)
{
    new players[1];
    players[0] = client;

    return StartMessageEx(msg, players, 1, flags);
}
