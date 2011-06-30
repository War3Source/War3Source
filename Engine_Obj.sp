
#include <profiler>
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/object.inc"
#include "W3SIncs/cvarmonitor.inc"

//add arbitrary short charactres to this
#define MAXKEYCOUNT 30
#define MAXKEYLEN 2


public Plugin:myinfo= 
{
	name="Engine Obj test",
	author="Ownz",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};


new global;
new Handle:cr;
new cvarvalue;
public OnPluginStart()
{
	global=0;
//	CreateTimer(1.0,dotime,_,TIMER_REPEAT);
	cr=CreateCellReference(global);
	
	LinkConVar(cvarvalue,"sv_cheats");
}

public Action:dotime(Handle:t){
	for(new i=0;i<10000;i++){
	CreateObj(1);
	PrintToServer("%d",i);
	}
	/*PrintToServer("tick");
	new Object:obj=CreateObj(6);
	SetObj(obj,0,66);
	SetObjHandle(obj,1,CreateArray(1000,10000),Delete);
	
	
	new Handle:arr2=CreateArray();
	for(new i=0;i<10;i++){
		PushArrayCell(arr2, CreateArray(100,10000));
	}
	SetObjHandle(obj,2,arr2,DeleteArrayInArrayFunc);
	
	//DeleteObj(obj);
	
	
	new Object:obj3=CreateObj(100);
	SetObj(obj3,2,obj,DATA);
	SetObj(obj3,2,true,IS_OBJECT);
	
	SetObjStr(obj3,3,"OBJECT STRINGsssssssssssssssssssssssssssssssss");
	SetObjStr(obj3,3,"OBJECT STRINGssssssssssssssssssssssssssssssssssssssssssssssssssssssssss");
	new String:buf[32];
	GetObjStr(obj3,3,buf,sizeof(buf));
	PrintToServer("%s",buf);
	GetObjStr(obj3,4,buf,sizeof(buf));
	PrintToServer("%s",buf);
	DeleteObj(obj3);
	
	
	SetByRef(cr);
	PrintToServer(" global : %d",global);
	
	PrintToServer("cvar value %d",cvarvalue);
*/
}
SetByRef(Handle:ref){
	PrintToServer("handle %d",ref);
	PrintToServer("deref %d",CellDereference(ref));
	SetCellByReference(ref,CellDereference(ref)+1);
}

public DeleteArrayInArrayFunc(Handle:arr){
	//PrintToServer("to delete array in array");
	for(new i=0;i<10;i++){
		CloseHandle(GetArrayCell(arr,0));
		RemoveFromArray(arr, 0);
	}
	CloseHandle(arr);
}