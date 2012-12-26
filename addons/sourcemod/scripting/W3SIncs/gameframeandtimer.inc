






public Action:DeciSecondLoop(Handle:timer)
{
	// Boy, this is going to be fun.
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true))
		{
			//for(new i=0;i<=W3GetItemsLoaded()+War3_GetRacesLoaded();i++)
			//{
			//	PrintToServer("denybuff val: %d iter %d", buffdebuff[client][bBuffDeny][i],i);
			//}
			if(!W3IsPlayerXPLoaded(client))
			{
				if(GetGameTime()>LastLoadingHintMsg[client]+4.0)
				{
					PrintHintText(client,"%T","Loading XP... Please Wait",client);
					LastLoadingHintMsg[client]=GetGameTime();
				}
				continue;
			}
		}
	}
}



