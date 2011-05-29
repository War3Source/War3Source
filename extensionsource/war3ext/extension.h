#ifndef _INCLUDE_SOURCEMOD_EXTENSION_PROPER_H_
#define _INCLUDE_SOURCEMOD_EXTENSION_PROPER_H_

#include "smsdk_ext.h"
#include "igameevents.h"
#include <IWebternet.h>
#include <IThreader.h>
#include <INativeInvoker.h>
//#include "war3dll.h" // copy this file from source please :)

#ifdef WIN32
#include <process.h>
#include <fcntl.h>
#define sleep(sec)   Sleep (sec)
#else
#define sleep(sec) usleep(1000*sec);
#endif

#define PRINT META_CONPRINTF
#define FORMAT g_pSM->Format
#define MAXMODULE 99
/**
 * @brief Sample implementation of the SDK Extension.
 * Note: Uncomment one of the pre-defined virtual functions in order to use it.
 */
class War3Ext : 
	public SDKExtension, //implementing all these interfaces
	public IGameEventListener2,   // now that War3Ext inherits eventlistener it can be added to the manager.
	public IMetamodListener, 
	public ITransferHandler, 
	public IThread,
	public ITimedEvent
{
public:
	// Some variables.
//	IWar3DLL *m_War3DLL;
	IForward *m_OurTestForward;
	ICvar *m_Cvars;
	IGameEventManager2 *m_EventManager; // used to ADD listeners what can we exactly listen to? player5_hgurt, etc only engine stuff? no custom stuff? anything in the event system, but in general you can't create a custom event anyway. event with SM you are lismitted to events initialized so its not some kind of War3Event custom thing? correct 
	/**
	 * @brief This is called after the initial loading sequence has been processed.
	 *
	 * @param error		Error message buffer.
	 * @param maxlength	Size of error message buffer.
	 * @param late		Whether or not the module was loaded after map load.
	 * @return			True to succeed loading, false to fail.
	 */
	virtual bool SDK_OnLoad(char *error, size_t maxlength, bool late);
	
	/**
	 * @brief This is called right before the extension is unloaded.
	 */
	virtual void SDK_OnUnload();

	/**
	 * @brief This is called once all known extensions have been loaded.
	 * Note: It is is a good idea to add natives here, if any are provided.
	 */
	//virtual void SDK_OnAllLoaded();

	/**
	 * @brief Called when the pause state is changed.
	 */
	//virtual void SDK_OnPauseChange(bool paused);

	/**
	 * @brief this is called when Core wants to know if your extension is working.
	 *
	 * @param error		Error message buffer.
	 * @param maxlength	Size of error message buffer.
	 * @return			True if working, false otherwise.
	 */
	//virtual bool QueryRunning(char *error, size_t maxlength);
	const char *GetExtensionVerString();
	const char *GetExtensionDateString();
public:
#if defined SMEXT_CONF_METAMOD
	/**
	 * @brief Called when Metamod is attached, before the extension version is called.
	 *
	 * @param error			Error buffer.
	 * @param maxlength		Maximum size of error buffer.
	 * @param late			Whether or not Metamod considers this a late load.
	 * @return				True to succeed, false to fail.
	 */
	virtual bool SDK_OnMetamodLoad(ISmmAPI *ismm, char *error, size_t maxlength, bool late);

	/**
	 * @brief Called when Metamod is detaching, after the extension version is called.
	 * NOTE: By default this is blocked unless sent from SourceMod.
	 *
	 * @param error			Error buffer.
	 * @param maxlength		Maximum size of error buffer.
	 * @return				True to succeed, false to fail.
	 */
	//virtual bool SDK_OnMetamodUnload(char *error, size_t maxlength);

	/**
	 * @brief Called when Metamod's pause state is changing.
	 * NOTE: By default this is blocked unless sent from SourceMod.
	 *
	 * @param paused		Pause state being set.
	 * @param error			Error buffer.
	 * @param maxlength		Maximum size of error buffer.
	 * @return				True to succeed, false to fail.
	 */
	//virtual bool SDK_OnMetamodPauseChange(bool paused, char *error, size_t maxlength);

	// Now we are also a metamod listener, which is essentially like a VSP class.
	virtual void OnLevelInit(char const *pMapName, 
								 char const *pMapEntities, 
								 char const *pOldLevel, 
								 char const *pLandmarkName, 
								 bool loadGame, 
								 bool background);
	virtual void OnLevelShutdown();
	virtual void FireGameEvent( IGameEvent *event );





#endif
	void cleanupmetamod();

	 ~War3Ext();
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

	 //imutex
	/* virtual ~IMutex() { };
	virtual bool TryLock() =0;
	virtual void Lock() =0;
	virtual void Unlock() =0;
	virtual void DestroyThis() =0;*/

	 //timer
	 ResultType 	OnTimer (ITimer *pTimer, void *pData);
	void 	OnTimerEnd (ITimer *pTimer, void *pData);
 	
};

//extern is like function prototype, for variables
extern const sp_nativeinfo_t MyNatives[]; //because functions are not listed in header, we cant initialize these entries at the beginning, we put them here so other places we can reference them first
extern  const sp_nativeinfo_t tMyNatives;
bool StrEquali(const char*,const char*);


#endif // _INCLUDE_SOURCEMOD_EXTENSION_PROPER_H_

