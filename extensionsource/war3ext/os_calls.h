//http://www.codeproject.com/KB/architecture/plat_ind_coding.aspx

//Boby Thomas pazheparampil - march 2006
#ifndef os_call_h
#define os_call_h
#include<string>

//apparrently DLL_EXPORT is deifned by metamod or hl2sdk
#if defined _MSC_VER
	//#define DLL_EXPORT				extern "C" __declspec(dllexport)
	//#define openlib(lib)			LoadLibrary(lib)
	//#define closelib(lib)			FreeLibrary(lib)
	//#define findsym(lib, sym)		GetProcAddress(lib, sym)
	//#define PLATFORM_EXT			".dll"
	//#define vsnprintf				_vsnprintf
	//#define PATH_SEP_CHAR			"\\"
	//inline bool IsPathSepChar(char c) 
	//{
	//	return (c == '/' || c == '\\');
	//}
	#include <Windows.h>
#else
	//#define DLL_EXPORT				extern "C" __attribute__((visibility("default")))
	//#define openlib(lib)			dlopen(lib, RTLD_NOW)
	//#define closelib(lib)			dlclose(lib)
	//#define findsym(lib, sym)		dlsym(lib, sym)
	//#define PLATFORM_EXT			".so"
	//typedef void *					HINSTANCE;
	//#define PATH_SEP_CHAR			"/"
	//inline bool IsPathSepChar(char c) 
	//{
	//	return (c == '/');
	//}
	#include <dlfcn.h>
#endif



/*
#define RTLD_LAZY   1
#define RTLD_NOW    2
#define RTLD_GLOBAL 4
*/

void* LoadSharedLibraryCustom(char *pcDllname, int iMode = 2)
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
#define dlerror() "cannot get error msg on windows"
#endif


#endif //os_call_h


