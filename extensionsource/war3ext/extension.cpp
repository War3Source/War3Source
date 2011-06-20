//YOUR CUSTOM EXTENSION
#include <sourcemod_version.h>
#include "extension.h"
#include <sm_platform.h>



#define MAXMODULE 99


/**
 * @file extension.cpp
 * @brief Implement extension code here.
 */

War3Ext war3_ext;		/**< Global singleton for extension's main interface */
CWar3DLLInterface *cwar3; //our dll object
SMEXT_LINK(&war3_ext); //not related to dll


//Those are function pointers

typedef CWar3DLLInterface* (*GetCWar3DLLPtr)();
typedef void (*DeleteCWar3DLLPtr)(CWar3DLLInterface*);


///super shared global vars!!! access with g.(members!)
myglobalstruct g;

IMutex *threadcountmutex;

 int threadcount=0;
 bool webternet=false;

 //clean up metamod stuff
 void War3Ext::cleanupmetamod(){
	 m_EventManager->RemoveListener(this);
 }
War3Ext::~War3Ext(){}
bool War3Ext::SDK_OnLoad(char *error, size_t maxlength, bool late)
{
    META_CONPRINTF("[war3ext] SDK_OnLoad\n");
    g.pwar3_ext=this;

	g.threadticket=new Semaphore(0);
	g.threadticketrequest=new Semaphore(0);
	g.threadticketmutex=threader->MakeMutex();


	sharesys->AddDependency(myself, "webternet.ext", true, true);

	GetInterface("INativeInterface",(SMInterface**)&g.nativeinterf,true);
	g.invoker=g.nativeinterf->CreateInvoker();

	GetInterface("IWebternet",(SMInterface**)&g.sminterfaceIWebternet,true);
	threadcountmutex=threader->MakeMutex();

	GetInterface("ITimerSys",(SMInterface**)&g.sminterfacetimer,true);
	timersys->CreateTimer(&war3_ext,0.01,NULL, TIMER_FLAG_REPEAT);

	g_pShareSys->AddNatives(myself,MyNatives);


	m_OurTestForward=forwards->CreateForward("W3ExtTestForward",ET_Ignore,2,NULL,Param_Any, Param_String);

	char path[PLATFORM_MAX_PATH];
	g_pSM->BuildPath(Path_SM, path, sizeof(path), "extensions");
	META_CONPRINTF("path %s\n", path);

	using namespace std;
	char path2[PLATFORM_MAX_PATH]="\0";
	strcat (path2,path);
	strcat (path2,"/war3dll");



	void *hLib=LoadSharedLibraryCustom(path2);
	if(hLib==NULL) {
		//META_CONPRINTF("COULD NOT LOAD %s\n", path2/*,GetLastError()*/);
		g_pSM->Format(error,maxlength,"[war3ext] could not load war3dll");
		cleanupmetamod();
		return false;
    }
	else{
		META_CONPRINTF("LoadLibrary Loaded\n");
	}

	char mod[MAXMODULE];

    GetModuleFileNameCustom(hLib, mod, MAXMODULE);
    cout << "Library loaded: " << mod << endl;


    if(GetFunctionCustom(hLib, "CreateInterface")==NULL) {
        cout << "Unable to load function(s): ERR "<< dlerror() << endl;
    }
	else{
		cout << "found CreateInterface"<<endl;
	}
	cout<<1;
	GetCWar3DLLPtr GetCWar3DLL=(GetCWar3DLLPtr)GetFunctionCustom(hLib, "GetCWar3DLL");
	if(GetCWar3DLL==NULL)
	{
		cout << "Unable to load function(s): GetCWar3DLL ERR "<< dlerror() << endl;
        	FreeSharedLibraryCustom(hLib);
        	return false;
	}
	cout<<2;
	cwar3=GetCWar3DLL();
	cout<<3;
	// to communicate with dll
	cwar3->DLLVersion(); // this IS communication ;]
	//cwar3->OnEvent(player_index, "PLAYER_DIED");
	cout<<cwar3->DLLVersion()<<endl;

	cwar3->PassStuff(g_pSM,engine,g_pForwards,g_pShareSys,myself,&war3_ext,threader);
	cwar3->DoStuff();

	//destructor
	/*DeleteCWar3DLLPtr DeleteCWar3DLL=(DeleteCWar3DLLPtr)GetFunctionCustom(hLib, "DeleteCWar3DLL");
	if(DeleteCWar3DLL==NULL)
	{
		cout << "Unable to load function(s)." << endl;
        FreeSharedLibraryCustom(hLib);
        return false;
	}
	DeleteCWar3DLL(cwar3);*/

    //FreeSharedLibraryCustom(hLib); //dont free, cuz we usin it

	#include "update.cpp"



	return true;
}

bool War3Ext::SDK_OnMetamodLoad(ISmmAPI *ismm, char *error, size_t maxlen, bool late)
{
	META_CONPRINTF("[war3ext] SDK_OnMetamodLoad\n");


	// add us to the metamod listener list
	ismm->AddListener(this,this); // lemme find the first param


	// i dont know if you are following 100% but basically they assume you'll use GET_V_IFACE_CURRENT inside OnMetaModload, since that is proper.
	GET_V_IFACE_CURRENT(GetEngineFactory, m_Cvars, ICvar, CVAR_INTERFACE_VERSION);
	GET_V_IFACE_CURRENT(GetEngineFactory, m_EventManager, IGameEventManager2, INTERFACEVERSION_GAMEEVENTSMANAGER2);
	if(!m_Cvars)
	{
		META_CONPRINTF("[war3ext] ConVar interface found!\n");
		return false;
	}
	if(!m_EventManager)
	{
		META_CONPRINTF("[war3ext] ConVar interface found!\n");
		return false;
	}
	// Now that you have the event manager, add listeners. I believe it is supposed to be done on map start

	m_EventManager->AddListener(this, "player_spawn", true);
	m_EventManager->AddListener(this, "player_death", true);

	return true;
}
static cell_t W3ExtRegister(IPluginContext *pCtx, const cell_t *params)
{
	g.plugincontext=pCtx;
	char* strarg1;
	pCtx->LocalToString(params[1], &strarg1);
	PRINT("%d smx loaded\n",(int)strarg1);

	g.helpergetfunc=pCtx->GetFunctionByName("Get");
	if(g.helpergetfunc==NULL){
		for(int i=0;i<100;i++){
			ERR("ERROR, COULD NOT GET FUNCTION FROM EXTENSION HELPER PLUGIN");

		}
		exit(0);
	}

	cwar3->W3ExtRegister2(pCtx,params);

	//not signaled by default, do not wait
	g.sem_callfin=new Semaphore(0);


	threader->MakeThread(g.pwar3_ext);


	MyThread *pmythread = new MyThread();
	threader->MakeThread(pmythread);

	return 1;
}
void War3Ext::OnLevelInit(char const *pMapName,
								 char const *pMapEntities,
								 char const *pOldLevel,
								 char const *pLandmarkName,
								 bool loadGame,
								 bool background)
{
	//m_EventManager->AddListener(this, "player_death", true);
	//m_EventManager->AddListener(this, "player_spawn", true);
}

void War3Ext::OnLevelShutdown()
{
	//m_EventManager->RemoveListener(this);
}

void War3Ext::FireGameEvent( IGameEvent *event) ///event was fired
{
	//META_CONPRINTF("Event called: %s %i\n", event->GetName(),event->GetInt("userid")); // ooo name
	//if(StrEquali(event->GetName(),"player_SPAWN")){
	//	 std::cout<<"OMFG IT IS strcmp(event->GetName(),\n";
	//}
}
//insensitive compare
bool StrEquali(const char *str1,const char *str2){
	return (strcmpi(str1,str2)==0)?true:false;
}
void War3Ext::SDK_OnUnload()
{
}

const char *War3Ext::GetExtensionVerString()
{
	return SMEXT_CONF_VERSION;
}

const char *War3Ext::GetExtensionDateString()
{
	return SM_BUILD_TIMESTAMP;
}

static cell_t OurTestNative(IPluginContext *pCtx, const cell_t *params)
{
	cwar3->DoStuff();

	// params[0] is the count.
	PRINT("You passed me %d parameters.", (int)params[0]);

	//show me float
	float p1 = sp_ctof(params[1]);

	//show me string
	char *pStr;
	pCtx->LocalToString(params[2], &pStr);

	// third int
	int p3 = params[3]; // literally NOTHING needs to be done.
	PRINT("Passed: %f %s %d\n", p1, pStr, (int)p3);

	// 4th param buffer, 5th maxlen
	pCtx->StringToLocal(params[4], params[5], "Test this out ;]");

	//lets call a function in sourcepawn
	//pCtx->


	//return value of native, return cells only
	return  sp_ftoc(2.4f);
}
unsigned int War3Ext::GetURLInterfaceVersion( 		 ) {
	return 1;
}
 DownloadWriteStatus  War3Ext::OnDownloadWrite(IWebTransfer *session,
                               void *userdata,
                              void *rcvddataptr,
                               size_t size, //supposed interpretation of data? number of bytes?
                              size_t nmemb) //number of 'size' blocks, so total bytes = size * nmemb
                     {

						 ((std::string*)(userdata))->append((char*)rcvddataptr,nmemb);
						// META_CONPRINTF("%s",(char*)ptr);
						 //META_CONPRINTF("len %d %d\n",size,nmemb);
                               return DownloadWrite_Okay;//DownloadWrite_Error;
                    }

 void War3Ext::RunThread 	( 	IThreadHandle *  	pHandle 	 ){
	 while(1){
		g.threadticketrequest->Signal();
		g.threadticket->Wait();

        char ret[64];
        cell_t result;

		g.helpergetfunc->PushCell(EXTH_HOSTNAME);
		g.helpergetfunc->PushStringEx(ret,sizeof(ret),0,SM_PARAM_COPYBACK);
		g.helpergetfunc->PushCell(sizeof(ret));
		g.helpergetfunc->Execute(&result);

		g.sem_callfin->Signal();
		//threader->ThreadSleep(2000);


	 }



 }
 void War3Ext::OnTerminate 	( 	IThreadHandle *  	pHandle,		bool  	cancel	 	) { META_CONPRINTF("THREAD TERMINATE cancel:%d\n",cancel);}


static cell_t OurTestNative2(IPluginContext *pCtx, const cell_t *params)
{

	//cwar3->PassStuff(g_pSM,engine);
	cwar3->DoStuff();
	//cell_t result;


#ifdef BAD

		SMInterface *somesminterface;
		if(g_pShareSys->RequestInterface("INativeInterface",0,myself,&somesminterface)){
			META_CONPRINTF("NativeInvoker INTERFACE SUCC %s\n",somesminterface->GetInterfaceName());

			INativeInterface *myNativeInterface= (INativeInterface*)somesminterface;
			IPluginRuntime *fakeruntime =myNativeInterface->CreateRuntime("war3extfakeruntime",NINVOKE_DEFAULT_MEMORY);
			INativeInvoker* myinvoker=(INativeInvoker*)myNativeInterface->CreateInvoker();
			if(myinvoker!=NULL){

				if(true){



					IPlugin *pPlugin;
					pPlugin = plsys->FindPluginByContext(pCtx->GetContext());
					pPlugin->GetBaseContext();
					if(false==(myinvoker->Start(pPlugin->GetBaseContext(),"LogError")))
					{

						myinvoker->PushCell(1111);
						myinvoker->PushCell(2222);
						myinvoker->Invoke(&result);
					}
					else{
						META_CONPRINTF("myinvoker->Start FAILED\n");
					}
				}

				if(false==(myinvoker->Start((IPluginContext*)fakeruntime/*pCtx*/,"OurTestNative")))
				{

					myinvoker->PushCell(1111);
					myinvoker->PushCell(2222);
					myinvoker->Invoke(&result);
				}
				else{
					META_CONPRINTF("myinvoker->Start FAILED\n");
					unsigned int nativeindex;
					nativeindex=0;
					pCtx->FindNativeByName("OurTestNative",&nativeindex);
					META_CONPRINTF("native index %d\n",nativeindex);

					nativeindex=0;
					pCtx->FindNativeByName("OurTestNative2",&nativeindex);
					META_CONPRINTF("native index %d\n",nativeindex);

					nativeindex=0;
					pCtx->FindNativeByName("LogError",&nativeindex);
					META_CONPRINTF("native index %d\n",nativeindex);

					nativeindex=0;
					pCtx->FindNativeByName("War3_CreateRace",&nativeindex);
					META_CONPRINTF("native index %d\n",nativeindex);

					nativeindex=0;
					pCtx->FindNativeByName("GetNativeCell",&nativeindex);
					META_CONPRINTF("native index %d\n",nativeindex);


					IPlugin *pPlugin;
					pPlugin = plsys->FindPluginByContext(pCtx->GetContext());
					nativeindex=0;
					pPlugin->GetBaseContext()->FindNativeByName("ExtensionSPNative",&nativeindex);

					META_CONPRINTF("native index %d\n",nativeindex);
					/*int errCode = pPlugin->GetBaseContext()-
					if(errCode==SP_ERROR_NOT_FOUND)
					{
						return pCtx->ThrowNativeError("Plugin public function not found '%s'", pNamePub);
					}
					else
					{
						META_CONPRINTF("Found pub func id : %d\n", pubfuncindex);
					}*/



				}

			}
			else{
				META_CONPRINTF("could not get invoker\n");
			}

		}
		else{
			META_CONPRINTF("NativeInvoker INTERFACE FAIL\n");

		}
#endif
	//ExtensionSPNative
	return 1;
}
static cell_t W3ExtVersion(IPluginContext *pCtx, const cell_t *params)
{
	// params[0] is the count.
	// in SM usually you dont have to, but we should verify params.
	//if(params[0]<2) { return 0; } // todo: error?
	//META_CONPRINTF("%s", SMEXT_CONF_VERSION);
	pCtx->StringToLocal(params[1], params[2],  SMEXT_CONF_VERSION);

	//return value of native, return cells only
	return  1;
}

/* Turn a public index into a function ID */
inline funcid_t PublicIndexToFuncId(uint32_t idx)
{
	return (idx << 1) | (1 << 0); //times 2 (shift left) then plus 1 (or with 1)
}
static cell_t W3ExtTick(IPluginContext *pCtx, const cell_t *params)
{
	if(g.helpergetfunc==NULL){
		for(int i=0;i<100;i++){
			ERR("ERROR, HELPER FUNCTION FROM EXTENSION HELPER PLUGIN NOT REGISTERED");

		}
		exit(0);
	}

	return 0;
}
static cell_t W3ExtTestFunc(IPluginContext *pCtx, const cell_t *params)
{
	return  1;//sp_ftoc(2.4f);
}

ResultType 	War3Ext::OnTimer(ITimer *pTimer, void *pData){
	if(g.helpergetfunc==NULL){
		for(int i=0;i<100;i++){
			g_pSM->LogError(myself,"ERROR, HELPER FUNCTION FROM EXTENSION HELPER PLUGIN NOT REGISTERED");

		}
		exit(0);
	}

	while(g.threadticketrequest->WaitNoBlock()){

		//cout<<"GOT REQUEST, allow them now";

	}
	if(!g.threadticket->WaitNoBlock()){ ///no ticket available
		g.threadticket->Signal();
		g.sem_callfin->Wait();
	}


	return Pl_Continue; //continue with timer repeat...
}
void 	War3Ext::OnTimerEnd(ITimer *pTimer, void *pData){
}




///MUST BE AFTER NATIVE FUNCS, stupid 1 pass compiler doesnt know what the functions are


const sp_nativeinfo_t MyNatives[] =
{
	{"OurTestNative",			OurTestNative},
	{"OurTestNative2",			OurTestNative2},
	{"W3ExtTick",			W3ExtTick},
	{"W3ExtVersion",			W3ExtVersion},
	{"W3ExtTestFunc",			W3ExtTestFunc},
	{"W3ExtRegister",			W3ExtRegister},

	{NULL,							NULL}, // last entry is null, it marks the end for all the loop operations.
};

