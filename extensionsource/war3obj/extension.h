#ifndef _INCLUDE_SOURCEMOD_EXTENSION_PROPER_H_
#define _INCLUDE_SOURCEMOD_EXTENSION_PROPER_H_

#include "smsdk_ext.h"
#include "igameevents.h"
//#include "war3dll.h" // copy this file from source please :)

#include "ownageheaderstd.h"

#define MAXMODULE 99
/**
 * @brief Sample implementation of the SDK Extension.
 * Note: Uncomment one of the pre-defined virtual functions in order to use it.
 */

//standard prints
#ifndef PRINT
#define PRINT printf
#endif
#ifndef CPRINT
#define CPRINT std::cout << 
#endif

#define FORMAT g_pSM->Format
//end standard prints


class War3Obj : public SDKExtension, /*public IGameEventListener2,*/  public IHandleTypeDispatch // now that War3Ext inherits eventlistener it can be added to the manager.
{
public:
	// Some variables.
//	IWar3DLL *m_War3DLL;
	IForward *m_OurTestForward;
	//ICvar *m_Cvars;
	//IGameEventManager2 *m_EventManager; // used to ADD listeners what can we exactly listen to? player5_hgurt, etc only engine stuff? no custom stuff? anything in the event system, but in general you can't create a custom event anyway. event with SM you are lismitted to events initialized so its not some kind of War3Event custom thing? correct 
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
	/*virtual void OnLevelInit(char const *pMapName, 
								 char const *pMapEntities, 
								 char const *pOldLevel, 
								 char const *pLandmarkName, 
								 bool loadGame, 
								 bool background);
	virtual void OnLevelShutdown();
	virtual void FireGameEvent( IGameEvent *event );*/
#endif

	///need to implement this when inheriting another abstract class
	void OnHandleDestroy(HandleType_t type, void *object);
};

//extern is like function prototype, for variables
extern const sp_nativeinfo_t MyNatives[]; 


//set equal to the amount of enums below
//#define OBJ_ELEMENTSIZE 6




#endif // _INCLUDE_SOURCEMOD_EXTENSION_PROPER_H_

