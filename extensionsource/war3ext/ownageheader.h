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

extern int GetTrans();

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
	

	cell_t NATIVE(const char* nativename){
		cell_t result=0;
		if(!g->invoker->Start(g->plugincontext,nativename)){
			ERR("failed to start invoke %s",nativename);
			return 0;
		}
		g->invoker->Invoke(&result);
	
		return result;
	}
	cell_t NATIVE(const char* nativename,cell_t cellparam){
		cell_t result=0;
		if(!g->invoker->Start(g->plugincontext,nativename)){
			ERR("failed to start invoke %s",nativename);
			return 0;
		}
		g->invoker->PushCell(cellparam);
		g->invoker->Invoke(&result);
	
		return result;
	}
	IPluginFunction* PUBLIC(const char* publicname){
		IPluginRuntime *runtime=g->plugincontext->GetRuntime();
		return runtime->GetFunctionByName(publicname);
	}
	void EXTChatMessage(cell_t client,char* string){
		IPluginFunction* func=PUBLIC("EXTChatMessage");
		func->PushCell(client);
		func->PushString(string);
		func->Execute(&dummy);
	}
#ifdef __W3DLL
	//uses GetTrans
	void TRANS(	char* buffer, cell_t bufferlen,char* translatedphrase){
		cell_t client=GetTrans();
		void* param2[2];
		param2[0]=(void*)"[War3Source] Select an item to buy. You have {amount}/{amount} items";
		param2[1]=&client;
		size_t dummy;
		char* failedchar=0;
		bool success=g->myphrasecollection->FormatString(buffer,sizeof(buffer),"%T",param2,sizeof(param2),&dummy,(const char**)&failedchar);
		if(! success){
			ERR("translated failed %s",translatedphrase);
		}
		if(failedchar!=NULL){
			ERR("failed phrase %s",failedchar);
		}
	}
#endif

}



#endif

