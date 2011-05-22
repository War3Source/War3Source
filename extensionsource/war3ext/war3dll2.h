
#ifndef _DLLTEST_H_
#define _DLLTEST_H_

#ifdef EXPORTW3
#include <iostream>
#include <stdio.h>
#if defined(_MSC_VER) 
#include <windows.h>
#endif
#include "smsdk_ext.h"


#endif



class CWar3DLLInterface
{
public:
    virtual ~CWar3DLLInterface(); // <= important!?
	
	//put all wrapped functions here, and in actual class
    virtual const char *DLLVersion() = 0; //rememer = 0;
	virtual void PassStuff(ISourceMod*,IVEngineServer*,IForwardManager*)=0; 
	virtual void DoStuff()=0; 
};


class CWar3DLL: public CWar3DLLInterface
{
	public:
	CWar3DLL();
	~CWar3DLL();
	void PassStuff(ISourceMod*,IVEngineServer*,IForwardManager*);
	void DoStuff();
	const char *DLLVersion();
};

PLATFORM_EXTERN_C CWar3DLLInterface* GetCWar3DLL();



#endif



