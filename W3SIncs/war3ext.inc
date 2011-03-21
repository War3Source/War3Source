

#if defined _war3ext_included
  #endinput
#endif
#define _war3ext_included

native OurTestNative(Float:f=22.2,String:str[]="didnt pass string",int=55,String:returnstring[],maxlen);

native W3ExtVersion(String:returnstr[],maxlen,Function:Func);


/**
 * Do not edit below this line!
 */
public Extension:__ext_war3ext = 
{
	name = "War3 Extension",
	file = "war3ext.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 1, //def 0
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 1, //deb 0
#endif
};
