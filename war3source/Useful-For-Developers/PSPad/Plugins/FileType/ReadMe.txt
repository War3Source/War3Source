PSPad File handling plugin

Idea - each file extension has own DLL. 
Plugin is used for the file open/save handling if DLL exists and match plugin name to file extension. 
If some error occurs in DLL (DLL functions return False), PSPad internal file handling is used.
PSPad internally checks Plugin version and the message dialog occurs if the incorrect version is found 

DLL must export 3 functions:

function PSP_LoadFromFile(FileName, Data: PChar; DataSize: Integer): Integer; stdcall;
	- parameter DataSize - max. size of allocated buffer on the PSPad side
	- returns real data size 

function PSP_SaveToFile(FileName, Data: PChar; DataSize: Integer): LongBool; stdcall;
	- parameter DataSize - real. size of data
	- returns success state - True/False 

function PSP_Version: LongInt; stdcall;
	- returns plug-in version
