#ifndef __OWNAGEHEADER
#define __OWNAGEHEADER

//ONLY INCLUDE THIS FILE AFTER SM INCLUDES HAVE BEEN INCLUDED
//otherwise this file doesnt know what ISourceMod *g_pSM is



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
static void ERR(char* str,...);
size_t UTIL_Format(char *buffer, size_t maxlength, const char *fmt, va_list params);


static void ERR(char* format,...)
{
	va_list ap;
	va_start(ap, format);
	
	
	char buffer[2000];
	FORMAT(buffer,sizeof(buffer),format,ap);
	g_pSM->LogError(myself,buffer);
	va_end(ap);
}

size_t UTIL_Format(char *buffer, size_t maxlength, const char *fmt, va_list params)
{
	size_t len = vsnprintf(buffer, maxlength, fmt, params);

	if (len >= maxlength)
	{
		len = maxlength - 1;
		buffer[len] = '\0';
	}

	return len;
}
}

#endif

