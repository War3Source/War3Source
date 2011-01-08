/**
 * File: War3Source.inc
 * Description: Holds all the War3Source specific functions.
 * Author(s): Anthony Iacono  
 */


#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <cstrike>
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS
	
#include <sdktools>
#include <sdktools_functions>

// SourceMod stuff
#include <keyvalues>

// GameFrame tracking definitions








// War3Source Includes

#include "W3SIncs/vars"
#include "W3SIncs/cvar"
#include "W3SIncs/forwards"
#include "W3SIncs/natives"
#include "W3SIncs/offsets"
#include "W3SIncs/gameevents"

#include "W3SIncs/racesutils"

#include "W3SIncs/gameframeandtimer"

#include "W3SIncs/menuintro" 






















// Stocks
stock StrToken(const String:inputstr[],tokennum,String:outputstr[],maxlen)
{
	new String:buf[maxlen+1];
	new cur_idx;
	new idx;
	new curind;
	idx=BreakString(inputstr,buf,maxlen);
	if(tokennum==1)
	{
		strcopy(outputstr,maxlen,buf);
		return;
	}
	curind=1;
	while(idx!=-1)
	{
		cur_idx+=idx;
		idx=BreakString(inputstr[cur_idx],buf,maxlen);
		curind++;
		if(tokennum==curind)
		{
			strcopy(outputstr,maxlen,buf);
			break;
		}
	}
}

stock StrTokenCount(const String:input[])
{
	decl String:buf[32];
	new cur_idx;
	new idx;
	new curind;
	while(idx!=-1)
	{
		cur_idx+=idx;
		idx=BreakString(input[cur_idx],buf,sizeof(buf));
		curind++;
	}
	return curind;
}