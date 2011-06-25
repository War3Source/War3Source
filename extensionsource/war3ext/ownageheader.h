#ifndef __OWNAGEHEADER
#define __OWNAGEHEADER

//ONLY INCLUDE THIS FILE AFTER SM INCLUDES HAVE BEEN INCLUDED
//otherwise this file doesnt know what ISourceMod *g_pSM is


#include <iostream>//need this, incase they didnt include it, need for cout<<endl

//standard prints
#ifndef PRINT
#define PRINT printf
#endif
#ifndef CPRINT
#define CPRINT std::cout << 
#endif

#define FORMAT g_pSM->Format
//end standard prints

#define DP PRINT

//extern needs to stay outside of anoy-namespace
extern ISourceMod *g_pSM;
extern IExtension *myself;	



namespace //anoynamous namespace, 
	//these funcs are only accisible by the cpp files that included this file.
	//however, that means you have duplicate code...its a trade off for ease of use
{

	//prototypes
	void ERR(char* str,...);
	size_t UTIL_Format(char *buffer, size_t maxlength, const char *fmt, va_list params);
	bool GetInterface(char* interf,SMInterface** pointer,bool quitifnotfound=false);

	void ERR(char* format,...)
	{
		va_list ap;
		va_start(ap, format);
	
	
		char buffer[2000];
		UTIL_Format(buffer,sizeof(buffer),format,ap);
		g_pSM->LogError(myself,buffer);
		va_end(ap);
	}

	size_t UTIL_Format(char *buffer, size_t maxlength, const char *fmt, va_list params)
	{
		size_t len = vsnprintf_s(buffer, maxlength, 9999,fmt, params);

		if (len >= maxlength)
		{
			len = maxlength - 1;
			buffer[len] = '\0';
		}

		return len;
	}

	//helper for getting a sm interface
	bool GetInterface(char* interf,SMInterface** pointer,bool quitifnotfound){
		//PRINT("[war3dll] try to get")<<interf<< std::endl;
		if(!(g_pShareSys->RequestInterface(interf,0,myself,pointer))){
			CPRINT("[war3ext] could not get sm interface ")<<interf<< std::endl;
			if(quitifnotfound){
				for(int i=0;i<100;i++){
					ERR("could not get sm interface %s",interf);
				}
				exit(0);
			}
			return false;
		}
		else if(*pointer!=NULL){
			CPRINT("[war3ext] got interface ")<<interf<< std::endl;
			return true;
		}
		return false;
	}
}

#endif

