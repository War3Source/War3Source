#include "os_calls.h"


#ifdef WIN32
#include <process.h>
#include <fcntl.h>
#define sleep(sec)   Sleep (sec)
#else
#define sleep(sec) usleep(1000*sec);
#endif

/*
#define RTLD_LAZY   1
#define RTLD_NOW    2
#define RTLD_GLOBAL 4
*/

void* LoadSharedLibraryCustom(char *pcDllname, int iMode )
{
    std::string sDllName = pcDllname;
    #if defined(_MSC_VER) // Microsoft compiler
    	sDllName += ".dll";
	strcat (pcDllname,".dll");
        return (void*)LoadLibrary(pcDllname);
    #elif defined(__GNUC__) // GNU compiler
    	sDllName += ".so";
	strcat (pcDllname,".so");
        return dlopen(sDllName.c_str(),iMode);
    #endif
}
void *GetFunctionCustom(void *Lib, char *Fnname)
{
#if defined(_MSC_VER) // Microsoft compiler
    return (void*)GetProcAddress((HINSTANCE)Lib,Fnname);
#elif defined(__GNUC__) // GNU compiler
    return dlsym(Lib,Fnname);
#endif
}

bool FreeSharedLibraryCustom(void *hDLL)
{
#if defined(_MSC_VER) // Microsoft compiler
    return FreeLibrary((HINSTANCE)hDLL)?true:false; //shut up the error
#elif defined(__GNUC__) // GNU compiler
    return dlclose(hDLL);
#endif
}

bool GetModuleFileNameCustom(void *hDLL,char mod[],int maxlen)
{
#if defined(_MSC_VER) // Microsoft compiler
    return GetModuleFileName((HINSTANCE)hDLL, (LPTSTR)mod, maxlen)?true:false;
#elif defined(__GNUC__) // GNU compiler
	strcpy(mod,"no module name on linux"); 
	//Dl_info info;  
	//dladdr(hDLL, &info);   
	//strcpy(mod,info.dli_fname); //dli_sname
    return true;
	
#endif
}

//dlerror() function for windows
#if defined(_MSC_VER) // Microsoft compiler

#endif
