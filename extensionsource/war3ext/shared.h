#ifndef __INCLUDED_SHARED
#define __INCLUDED_SHARED

using namespace std;
//#include <boost/algorithm/string.hpp>
typedef  unsigned int uint;
#include "ITranslator.h"
#include <vector>
#include <string>
class Semaphore;

typedef void (*funcpointer)(void); //of void return and no args
///use funcpointer variable= blah
class IMyTimer
{
public:
	virtual void AddTimer(funcpointer func,int milisecondInterval,bool repeat=true)=0;
};
class War3Ext; //forward declaration...
class IWar3DLL;

struct myglobalstruct
{
	
	War3Ext *pwar3_ext;
	
	IWebternet *sminterfaceIWebternet; //SMInterface
	ITimerSystem *sminterfacetimersys;
	IWebTransfer *IWebTransferxfer; //single object for transfer handling
	IPluginFunction *helpergetfunc;
	IPlayerManager *playermanager;

	IEventSignal *sem_callfin; //signal when OnTimer sychronous thread finished
	IMutex *docallmutex;
	IPluginContext *plugincontext; //context to call natives
	INativeInterface *nativeinterf;
	INativeInvoker *invoker;

	Semaphore *threadticketrequest;
	Semaphore *threadticket;
	Semaphore *threadticketdone;

	IMyTimer *imytimer;

	int war3revision;
	bool needsWar3Update;
	bool minversionexceeded;
	std::string teststr;

	IShareSys *sharesys;
	IPlugin *helperplugin;

	ITranslator *iphrase;
	bool helper;

	IMenuManager *imenus;
	IPhraseCollection *myphrasecollection;
	FILE *log;

	vector<string> filelist; //integrity
	vector<string> filepath;
};
extern myglobalstruct *g;

#define SMCALLBEGIN g->threadticketrequest->Signal(); g->threadticket->Wait()
#define SMCALLEND g->threadticketdone->Signal()
//you add the semicolon

//extension helper
enum EXTH { 
EXTH_HOSTNAME,
EXTH_W3VERSION_STR,
EXTH_W3VERSION_NUM,
EXTH_GAME ,
EXTH_W3_SH_MODE,
 EXTH_IP ,
EXTH_PORT,
EXTH_TRANS,
EXTH_TRANSSET
};



class CWar3DLLInterface
{
public:
    virtual ~CWar3DLLInterface()=0; // <= important!?

	//put all wrapped functions here, and in actual class
    virtual const char *DLLVersion() = 0; //rememer = 0;
	virtual void Init(ISourceMod*,IForwardManager*,IShareSys*,IExtension*,void*,IThreader *,myglobalstruct**)=0;
	virtual void DoStuff()=0;

};
class IWar3ExtInterface //exposed funcs
{
public:
	virtual void LOGf(char* format,...)=0;
};

#define META_CONPRINTF std::cout<<



#endif

