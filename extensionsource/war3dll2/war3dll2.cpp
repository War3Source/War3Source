// war3dll2.cpp : Defines the exported functions for the DLL application.
//


//#include "stdafx.h"


//#if defined(_MSC_VER) 
#define EXPORTW3
//#endif
#include "smsdk_ext.h"
#include "war3dll2.h"
#include <iostream>










//required
SDKExtension *g_pExtensionIface;


#define MAXMODULE 50

char module[MAXMODULE];

PLATFORM_EXTERN_C CWar3DLLInterface* GetCWar3DLL(){
	
    CWar3DLL * module = new CWar3DLL();

    return module;

}
void DeleteCWar3DLL(CWar3DLLInterface *obj){
	
    obj->~CWar3DLLInterface();
}
CWar3DLLInterface::~CWar3DLLInterface(){

}

CWar3DLL::CWar3DLL()
{
	std::cout << "CWar3DLL constructor" << std::endl;
}

CWar3DLL::~CWar3DLL()
{	
	std::cout << "CWar3DLL destructor" << std::endl;
}
void CWar3DLL::PassStuff(ISourceMod *g_pSM2,IVEngineServer *tengine,IForwardManager *tg_pForwards)
{
	g_pSM=g_pSM2;
	engine=tengine;
	g_pForwards=tg_pForwards;
	std::cout<<"Passed Stuff "<<std::endl;

}
void CWar3DLL::DoStuff()
{
	std::cout<<"W3DLL DoStuff DoStuff DoStuff DoStuff"<<std::endl;
	char path[PLATFORM_MAX_PATH];
	g_pSM->BuildPath(Path_SM, path, sizeof(path), "extensions");
	std::cout<<"OMFG "<<path<<std::endl;
	//engine->ServerCommand("say OMFG engine ServerCommand\n");
	//engine->ServerCommand("bot_quota 10\n");
	//engine->ServerCommand("bot_quota 20\n");
	//engine->ServerExecute();
}
const char* CWar3DLL::DLLVersion()
{
	
	return "0.0.22";
}


//extern "C" __declspec(dllexport)  already defined in header, dont need this line
void NumberList() {
//linux does not like LPTSTR
#if defined(_MSC_VER) 
    GetModuleFileName(NULL, (LPTSTR)module, MAXMODULE);
	using namespace std;
    cout << "\n\nThis function was called from "
        << module 
        << endl << endl;

    cout << "NumberList(): ";


    for(int i=0;  i<10; i++) {

        cout << i << " ";
    }

    cout << endl << endl;
#endif
}

//extern "C" __declspec(dllexport)   already defined in header, dont need this line
void LetterList() {
#if defined(_MSC_VER) 
    GetModuleFileName(NULL, (LPTSTR)module, MAXMODULE);
	using namespace std;
    cout << "\n\nThis function was called from "
        << module 
        << endl << endl;

    cout << "LetterList(): ";


    for(int i=0;  i<26; i++) {

        cout << char(97 + i) << " ";
    }

    cout << endl << endl;
#endif
}

