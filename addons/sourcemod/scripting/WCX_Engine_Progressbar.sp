#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Warcraft Extended - Progressbar",
    author = "War3Source Team",
    description="Generic progressbar for CS:S"
};

new String:g_sPropProgressBarTime[66] = "m_flProgressBarStartTime";
new String:g_sPropProgressBarDur[66] = "m_iProgressBarDuration";

public OnPluginStart()
{
}

public bool:InitNativesForwards()
{
    CreateNative("War3_Progressbar",Native_War3_Progressbar);
    return true;
}

public Native_War3_Progressbar(Handle:plugin,numParams)
{
    new iPropTime, iPropDur;
    
    new client = GetNativeCell(1);
    new iDur = GetNativeCell(2);
    
    iPropTime = FindSendPropOffs("CCSPlayer", g_sPropProgressBarTime);
    iPropDur = FindSendPropOffs("CCSPlayer", g_sPropProgressBarDur);
    
    if (iDur < 1)
    {
        return;
    }
    else if (iDur > 15)
    {
        iDur = 15;
    }
    if(ValidPlayer(client,true))
    {
        SetEntDataFloat(client, iPropTime, GetGameTime());
        SetEntData(client, iPropDur, iDur);
        CreateTimer(float(iDur), Wcsx_RemoveProgressBar, client);
    }
}

public Action:Wcsx_RemoveProgressBar(Handle:hTimer, any:iClient)
{
    new iPropDur = FindSendPropOffs("CCSPlayer", g_sPropProgressBarDur);
    SetEntData(iClient, iPropDur, 0);
}



