//YOUR CUSTOM EXTENSION


#include <sourcemod_version.h>
#include "extension.h"
#include <sm_platform.h>

#include "mytimer.h"

//    using namespace std;
//   using namespace boost;



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


///super shared global vars!!! access with g->(members!)
myglobalstruct *g;
myglobalstruct gg;
IMutex *threadcountmutex;

 int threadcount=0;
 bool webternet=false;

War3Ext::~War3Ext(){}

void tickme(){
    ERR("tickme");
}
bool War3Ext::SDK_OnLoad(char *error, size_t maxlength, bool late)
{


    META_CONPRINTF("[war3ext] SDK_OnLoad\n");
	g=&gg;
	g->pwar3_ext=NULL;
	g->sminterfaceIWebternet=NULL; //SMInterface
	g->sminterfacetimersys=NULL;
	g->IWebTransferxfer=NULL; //single object for transfer handling
	g->helpergetfunc=NULL;
	g->playermanager=NULL;

	g->sem_callfin=NULL; //signal when OnTimer sychronous thread finished
	g->docallmutex=NULL;
	g->plugincontext=NULL; //context to call natives
	g->nativeinterf=NULL;
	g->invoker=NULL;

	g->threadticketrequest=NULL;
	g->threadticket=NULL;
	g->threadticketdone=NULL;

	g->imytimer=NULL;

	g->needsWar3Update=false;
	g->minversionexceeded=false;
	g->sharesys=NULL;

	g->iphrase=translator;

	g->helper=false;
	g->imenus=menus;


	g->pwar3_ext=this;
	//initalize struct
	g->needsWar3Update=false;

	g->threadticket=new Semaphore(0);

	g->threadticketrequest=new Semaphore(0);
	g->threadticketdone=new Semaphore(0);
	g->myphrasecollection=g->iphrase->CreatePhraseCollection();

	char path[PLATFORM_MAX_PATH];
	g_pSM->BuildPath(Path_SM, path, sizeof(path), "logs/w3extlog.log");
	g->log = fopen(path, "w");
	if (!g->log)
	{
		ERR("COULD NOT OPEN W3E LOG %s",path);
		
		return false;
	}
	ERR("LOOL");
	
	sharesys->AddDependency(myself, "webternet.ext", true, true);

	GetInterface("INativeInterface",(SMInterface**)&g->nativeinterf,true);
	g->invoker=g->nativeinterf->CreateInvoker();

	GetInterface("IWebternet",(SMInterface**)&g->sminterfaceIWebternet,true);
	threadcountmutex=threader->MakeMutex();

	GetInterface("IPlayerManager",(SMInterface**)&g->playermanager,true);

	g->sminterfacetimersys=timersys;

	
	//add translation
	
	g->myphrasecollection->AddPhraseFile("w3s._common.phrases");
	g->myphrasecollection->AddPhraseFile("sh._common.phrases");
	g->myphrasecollection->AddPhraseFile("w3s.shopmenu2.phrases");

	m_OurTestForward=forwards->CreateForward("W3ExtTestForward",ET_Ignore,2,NULL,Param_Any, Param_String);

	g->sharesys=sharesys;

	
	
	g_pSM->BuildPath(Path_SM, path, sizeof(path), "extensions");


	using namespace std;
	char path2[PLATFORM_MAX_PATH]="\0";
	strcat (path2,path);
	strcat (path2,"/war3dll");
    META_CONPRINTF("path %s\n", path2);


	void *hLib=LoadSharedLibraryCustom(path2);
	if(hLib==NULL) {
		//META_CONPRINTF("COULD NOT LOAD %s\n", path2/*,GetLastError()*/);
		g_pSM->Format(error,maxlength,"[war3ext] could not load war3dll");
		#if defined(__GNUC__)
		ERR("%s",dlerror());
		#endif
		//cleanupmetamod();
		return false;
    }
	else{
		META_CONPRINTF("LoadLibrary Loaded\n");
	}

	char mod[PLATFORM_MAX_PATH];

    GetModuleFileNameCustom(hLib, mod, PLATFORM_MAX_PATH-1);
    cout << "Library loaded: " << mod << endl;


	GetCWar3DLLPtr GetCWar3DLL=(GetCWar3DLLPtr)GetFunctionCustom(hLib, "GetCWar3DLL");
	if(GetCWar3DLL==NULL)
	{
		cout << "Unable to load function(s): GetCWar3DLL ERR "<< dlerror() << endl;
        FreeSharedLibraryCustom(hLib);
        return false;
	}

	cwar3=GetCWar3DLL();

	// to communicate with dll
	cwar3->DLLVersion(); // this IS communication ;]

	cout<<cwar3->DLLVersion()<<endl;

    g->teststr="globalteststr";


	//#include "update.cpp"

    timersys->CreateTimer(&war3_ext,0.1f,NULL, TIMER_FLAG_REPEAT);

	sharesys->AddNatives(myself,MyNatives);

	g->imytimer=new MyTimer();
	//g->imytimer->AddTimer(&tickme,100); //test



	//PASS STUFF
	cwar3->Init(g_pSM,g_pForwards,g_pShareSys,myself,&war3_ext,threader,&g);

	return true;
}
void War3Ext::LOGf(char* format,...)
{
	va_list ap;
	va_start(ap, format);

	char buffer[2000];
	UTIL_Format(buffer,sizeof(buffer),format,ap);
	//g_pSM->LogError(myself,buffer);
	time_t rawtime;
	struct tm * timeinfo;
	time ( &rawtime );
	timeinfo = localtime ( &rawtime );
	char timebuffer[32];
	strftime(timebuffer,sizeof(timebuffer)-1,"%m/%d %X",timeinfo);
	fprintf(g->log,"%s [W3E] %s\n",timebuffer,buffer);
	fflush(g->log);
	printf("%s [W3E] %s\n",timebuffer,buffer);
	
	va_end(ap);
}
static cell_t W3ExtRegister(IPluginContext *pCtx, const cell_t *params)
{
	g->plugincontext=pCtx;
	char* strarg1;
	pCtx->LocalToString(params[1], &strarg1);
	PRINT("%d smx loaded\n",(int)strarg1);

	g->helpergetfunc=pCtx->GetFunctionByName("Get");
	if(g->helpergetfunc==NULL){
		for(int i=0;i<100;i++){
			ERR("ERROR, COULD NOT GET FUNCTION FROM EXTENSION HELPER PLUGIN");

		}
		exit(0);
	}
	IPluginManager *interf;
	GetInterface("IPluginManager",(SMInterface**)&interf,true);
	IPlugin *iplugin=interf->FindPluginByContext((const sp_context_t*)pCtx);
	if(iplugin==NULL){
		for(int i=0;i<10;i++){
			ERR("IPlugin *iplugin=interf->FindPluginByContext((const sp_context_t*)pCtx);");
			exit(0);
		}
	}
	g->helperplugin=iplugin;
	//ERR("found iplugin");


	cwar3->DoStuff();



	///get revision once
	char ret[64];
	ret[0]=0;
	cell_t result;

	g->helpergetfunc->PushCell(EXTH_IP);
	g->helpergetfunc->PushStringEx(ret,sizeof(ret),0,SM_PARAM_COPYBACK);
	g->helpergetfunc->PushCell(sizeof(ret));
	g->helpergetfunc->Execute(&result);

	if(!g->invoker->Start(g->plugincontext,"W3GetW3Revision")){
		ERR("failed to start invoke W3GetW3Revision");
	}
	else{
		g->invoker->Invoke(&result);
		g->war3revision=result;
	}
	//g->helperplugin=
	threader->MakeThread(g->pwar3_ext); //self

	//MyThread *pmythread = new MyThread();
	//threader->MakeThread(pmythread);

	return 1;
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


 void War3Ext::OnTerminate 	( 	IThreadHandle *  	pHandle,		bool  	cancel	 	) { META_CONPRINTF("THREAD TERMINATE cancel:%d\n",cancel);}


static cell_t OurTestNative2(IPluginContext *pCtx, const cell_t *params)
{

	//cwar3->PassStuff(g_pSM,engine);
	cwar3->DoStuff();
	//cell_t result;

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
	if(g->helpergetfunc==NULL){
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
    //ERR("tick");
	/*if(g->helpergetfunc==NULL){
		for(int i=0;i<100;i++){
			g_pSM->LogError(myself,"ERROR, HELPER FUNCTION FROM EXTENSION HELPER PLUGIN NOT REGISTERED");

		}
		exit(0);
	}

	if(g->threadticketrequest->Wait_Try()){ //eat 1 request at a time, we have modified wait try to return 1 if successful
		//ERR("got req");
		g->threadticket->Signal();
		//ERR("sig req");

		g->threadticketdone->Wait();
	}
*/
	return Pl_Continue; //continue with timer repeat...
}

//thread to do nothing.... somehow this allows semaphores to work properly??? on linux
 void War3Ext::RunThread 	( 	IThreadHandle *  	pHandle 	 ){
	 //callfinmutex->Lock();
	 while(0){

		g->threadticketrequest->Signal();
		g->threadticket->Wait();

        char ret[64];
        cell_t result;

		g->helpergetfunc->PushCell(EXTH_HOSTNAME);
		g->helpergetfunc->PushStringEx(ret,sizeof(ret),0,SM_PARAM_COPYBACK);
		g->helpergetfunc->PushCell(sizeof(ret));
		g->helpergetfunc->Execute(&result);



		g->threadticketdone->Signal();
		threader->ThreadSleep(2000);

	 }
	 while(0){
	     int foo=g->threadticketdone->Value()+g->threadticket->Value()+g->threadticketrequest->Value();
	     ERR("%d  %d %d",g->threadticketrequest->Value(),g->threadticket->Value(),g->threadticketdone->Value());
	     /*if(g->threadticketdone->Wait_Try()){
	         g->threadticketdone->Signal();
	     }
	     if(g->threadticketrequest->Wait_Try()){
	         g->threadticketrequest->Signal();
	     }
	     if(g->threadticket->Wait_Try()){
	         g->threadticket->Signal();
	     }*/
	     threader->ThreadSleep(2000);
	 }



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

