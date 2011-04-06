/**
 * Prints Message to server and all chat
 * For debugging prints
 */ 
stock DP(const String:szMessage[], any:...)
{
	
	decl String:szBuffer[1000];

	VFormat(szBuffer, sizeof(szBuffer), szMessage, 2);
	PrintToServer("[Debug Print] %s", szBuffer);
	PrintToChatAll("[Debug Print] %s", szBuffer);

}
/**
 * Returns UNIX time (integer)
 */ 
stock NOW(){
	return GetTime();
}
/**
 * returns the larger integer of the two
 */ 
stock IntMax(one,two){
	return  one>two?one:two;
}