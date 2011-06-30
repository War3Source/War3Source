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

class War3Ext;
extern War3Ext war3_ext;
namespace //anoynamous namespace,
	//these funcs are only accisible by the cpp files that included this file.
	//however, that means you have duplicate code...its a trade off for ease of use
{
	
	#ifndef __W3DLL
#define LOG	war3_ext.LOGf
#else
#define LOG ((IWar3ExtInterface*)g->pwar3_ext)->LOGf
#endif
	
	
	void ERR(char* format,...)
	{
		va_list ap;
		va_start(ap, format);


		char buffer[2000];
		UTIL_Format(buffer,sizeof(buffer),format,ap);
		//g_pSM->LogError(myself,buffer);
		std::printf("[W3E] %s\n",buffer);
		LOG("[W3E] %s\n",buffer);
		va_end(ap);
	}


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

