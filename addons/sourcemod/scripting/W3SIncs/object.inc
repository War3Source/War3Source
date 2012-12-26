#if defined _war3obj_included
  #endinput
#endif
#define _war3obj_included


#define OBJ_ELEMENTSIZE 6
enum ObjStructIndex{
	DATA,
	IS_VALID,
	IS_OBJECT,
	IS_HANDLE,
	IS_STRING,
	FUNC_DELETE_CALLBACK,
};

//forces the function you pass as a prototype of this
funcenum DeleteHandleCallback
{
	public(Handle:closeThisHandleToo),
}
//gerinic handle delete callback
public Delete(Handle:deleteme){
	CloseHandle(deleteme);
}
//create new object
native Object:CreateObj(size);
//delete object, it will itterate the elements to check if any of them is holding a handle, 
//if so, will call callback for YOU to free it. (because extensions are not allow to close other extension's handles)
//will recursively delete objects in objects
native Object:DeleteObj(Object:obj);


//access a member of that object (cell) with access to its sub fields
native GetObj(Object:obj,memberelementindex,					ObjStructIndex:elementsubindex=DATA);
native SetObj(Object:obj,memberelementindex,any:elementDATA,		ObjStructIndex:elementsubindex=DATA);

stock SetObjHandle(Object:obj,memberelementindex,Handle:handletoAdd,		DeleteHandleCallback:cleanupfunc){
	SetObj(Object:obj,memberelementindex,handletoAdd,			DATA);
	SetObj(Object:obj,memberelementindex,true,					IS_HANDLE);
	SetObj(Object:obj,memberelementindex,cleanupfunc,			FUNC_DELETE_CALLBACK);
}

native SetObjStr(Object:obj,memberelementindex,String:str[]);
native GetObjStr(Object:obj,memberelementindex,String:returnstr[],maxlen);



/**
 * Do not edit below this line!
 */
public Extension:__ext_war3obj = 
{
	name = "War3 Extension Obj",
	file = "war3obj.ext", //FILE NAME MUST BE LIKE THIS with .ext
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