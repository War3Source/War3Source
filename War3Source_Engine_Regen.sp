

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


public Plugin:myinfo= 
{
	name="W3S Engine HP Regen",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};


new Float:nextRegenTime[MAXPLAYERSCUSTOM];
new tf2displayskip[MAXPLAYERSCUSTOM];
public OnPluginStart()
{

}

public OnGameFrame()
{
	new Float:now=GetEngineTime();
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true))
		{
			if(nextRegenTime[client]<now){
				
				new Float:fbuffsum=W3GetBuffSumFloat(client,fHPRegen);
				//PrintToChat(client,"regein tick %f %f",fbuffsum,now);
				if(fbuffsum>0.01){
					War3_HealToMaxHP(client,1);  
					
					if(War3_GetGame()==TF){
						tf2displayskip[client]++;
						if(tf2displayskip[client]>4){
							new Float:VecPos[3];
							GetClientAbsOrigin(client,VecPos);
							VecPos[2]+=55.0;
							War3_TF_ParticleToClient(0, GetClientTeam(client)==2?"healthgained_red":"healthgained_blu", VecPos);
							tf2displayskip[client]=0;
						}
					}
				}
				new Float:nexttime=1.0/fbuffsum;
				if(nexttime<2.0&&nexttime>0.01){
					//ok we use this value
					//DP("nexttime<1.0&&nexttime>0.01");
				}
				else{
					nexttime=2.0;
				}
				nextRegenTime[client]=now+nexttime;
			}
		}
	}
}