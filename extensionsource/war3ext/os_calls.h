//http://www.codeproject.com/KB/architecture/plat_ind_coding->aspx

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
	#define dlerror() "cannot get error msg on windows"
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



void* LoadSharedLibraryCustom(char *pcDllname, int iMode =2);
void *GetFunctionCustom(void *Lib, char *Fnname);
bool FreeSharedLibraryCustom(void *hDLL);
bool GetModuleFileNameCustom(void *hDLL,char mod[],int maxlen);


#endif //os_call_h


