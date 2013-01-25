/*
File: natives.inc
Description: All the natives that keep us from having to make a C++ extension,
I <3 SourceMod :) 
* 
* natives are initiated and defined
* 
* 
* MUST LIST THE NATIE IN THE War3Source_Interface!!!!!!!!!!!!!!!!!!!!!!!!!!! 
* 
Author(s): Anthony Iacono  
*/




public Native_War3_InFreezeTime(Handle:plugin,numParams)
{
    return (bInFreezeTime)?1:0;
}







bool:War3Source_InitNatives()
{
    ///LIST ALL THESE NATIVES IN INTERFACE
    
    CreateNative("War3_InFreezeTime",Native_War3_InFreezeTime);


    return true;
}
