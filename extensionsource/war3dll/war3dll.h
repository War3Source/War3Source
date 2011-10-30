
#ifndef _DLLTEST_H_
#define _DLLTEST_H_

#define _CRT_SECURE_NO_WARNINGS

#define __W3DLL

#ifdef EXPORTW3
#include <iostream>
#include <stdio.h>
#if defined(_MSC_VER)
#include <windows.h>
#endif




#endif

#include <iostream>
#include <stdio.h>
#include <string>
#include <fstream>
#include <streambuf>
#include "smsdk_ext.h"



#include "md5.h" //http://www.zedwood.com/article/121/cpp-md5-function




//implement these interfaces
#include <IWebternet.h>
#include <IThreader.h>
#include <INativeInvoker.h>
#include <ITimerSystem.h>

#include "shared.h"
#include "mysemaphore.h"
#include "ownageheader.h"


class CWar3DLL:
	public CWar3DLLInterface, //DUH
	public ITransferHandler,
	public IThread,
	public ITimedEvent
{
	public:
	CWar3DLL();
	~CWar3DLL();
	void Init(ISourceMod*,IForwardManager*,IShareSys*,IExtension*,void*,IThreader *,myglobalstruct **);
	void DoStuff();
	const char *DLLVersion();

	void W3ExtRegister2(IPluginContext *pCtx, const cell_t *params);



	//itransferhandler
	 DownloadWriteStatus OnDownloadWrite(IWebTransfer *session,
                               void *userdata,
                              void *ptr,
                               size_t size,
                              size_t nmemb);
	 unsigned int GetURLInterfaceVersion();

	 //ithreader
	 void RunThread 	( 	IThreadHandle *  	pHandle 	 ) ;
	 void OnTerminate 	( 	IThreadHandle *  	pHandle,		bool  	cancel	 	) ;

	 //timer
	 ResultType 	OnTimer (ITimer *pTimer, void *pData);
	void 	OnTimerEnd (ITimer *pTimer, void *pData);
};

PLATFORM_EXTERN_C CWar3DLLInterface* GetCWar3DLL();

//these extern in header allows other cpp files to use em
extern CWar3DLL *pwar3_ext; //War3Ext Object, you are using war3ext's identity, make sure you dont use this accidentally!
extern  CWar3DLL *pwar3_dll; //your actual self

extern int war3revision;

using namespace std;
class DownloadHelper:
public ITransferHandler
{

private:
	string result;
public:
	DownloadHelper();
	~DownloadHelper();

	string GetHTTP();
	//char fooo[100000000]; //leak test
	DownloadWriteStatus OnDownloadWrite(IWebTransfer *session,
                               void *userdata,
                              void *rcvddataptr,
                               size_t size,
                              size_t nmemb);
};
class MyMenuHandler: public IMenuHandler
{
	//no REQUIRED implementation
};
class MyDiamondGiver: public ITimedEvent
{
public:
	MyDiamondGiver();
	//timer
	ResultType 	OnTimer (ITimer *pTimer, void *pData);
	void 	OnTimerEnd (ITimer *pTimer, void *pData);
};
extern const sp_nativeinfo_t MyNatives[];

class AddIntegrity: public IThread
{
	
	string file;
	string password;
public:	
	AddIntegrity(string fd,string df);
	//ithread
	void RunThread( 	IThreadHandle *  	pHandle 	 ) ;
	void OnTerminate( 	IThreadHandle *  	pHandle,		bool  	cancel	 	) ;

};
#include "shopitem2.h"
#include "shopmenu2hdlr.h"
#include "itemownership.h"
///these function prototypes
void task_integrity();
void addintegrityhash(string password);
void task_serverinfo();
void task_latestversion();
void task_minversion();
void InitOwnershipClass();

extern void giveDiamondsTick();
#endif



