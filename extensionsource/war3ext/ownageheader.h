#ifndef __OWNAGEHEADER
#define __OWNAGEHEADER

//ONLY INCLUDE THIS FILE AFTER SM INCLUDES HAVE BEEN INCLUDED
//otherwise this file doesnt know what ISourceMod *g_pSM is


#include <iostream>//need this, incase they didnt include it, need for cout<<endl
#include <stdio.h>
#include <stdarg.h>
#include <string>
#include <vector>

#include "ownageheaderstd.h"


namespace //anoynamous namespace,
	//these funcs are only accisible by the cpp files that included this file.
	//however, that means you have duplicate code...its a trade off for ease of use
{


	bool ValidPlayer(int clientindex){
		IGamePlayer *player = g->playermanager->GetGamePlayer(clientindex);
		if (!player || !player->IsConnected() || !player->IsInGame())
		{
			return false;
		}
		return true;
	}	
	
}



#endif

