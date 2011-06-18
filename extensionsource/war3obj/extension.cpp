//YOUR CUSTOM EXTENSION

#include <sourcemod_version.h>
#include "extension.h"
#include <sm_platform.h>

#include <iostream>
#include <vector>
//#include "ShareSys.h"
#define MAXMODULE 99

/** 
 * @file extension.cpp
 * @brief Implement extension code here.
 */

War3Obj war3_ext;		/**< Global singleton for extension's main interface */
SMEXT_LINK(&war3_ext); //not related to dll

HandleType_t g_MyHandleType=0;

#include "myobjectclass.include.cpp"



enum ElementPropIndex{ //ENUM
	DATA,
	IS_VALID,
	IS_OBJECT,
	IS_HANDLE,
	IS_STRING,
	FUNC_DELETE_CALLBACK,

	OBJ_ELEMENTSIZE,
};


class ElementStruct {
	cell_t cells[OBJ_ELEMENTSIZE];

	char *mystr;
	//cell_t leaktest[10000];
public:
	
	ElementStruct(){
		mystr=NULL;
	}
	~ElementStruct(){
		
		if(mystr!=NULL){
			//DP("trying to delet str");
			free(mystr);
			//DP("deleted");
		}
	}
	void SetStr(char* tempstr){
		if(mystr!=NULL){
			free(mystr);
		}
		mystr=(char*)malloc(strlen(tempstr)+1); //+1 for null terminator
		strcpy(mystr,tempstr);
		//DP("size %d len %d",strlen(mystr),strlen(tempstr));
		
	}
	char* GetStr(){
		if(mystr==NULL){
			ERR("tried to retrieve a string when string is not initialized, not even \"\" (NULL)");
			ERR("we created a \"\" and returned to you just so this won't crash");
			mystr=(char*)malloc(1*sizeof(char));
			mystr[0]='\0';
		}
		return mystr;
	}

	cell_t Get(int propindex)
	{
		if(propindex>=OBJ_ELEMENTSIZE){
			ERR("element prop index out of bounds: %d / max %d",propindex,OBJ_ELEMENTSIZE);
			return 0;
		}
		else{
			return cells[propindex];
		}
	}
	
	void Set(int propindex, cell_t value)
	{
		if(propindex>=OBJ_ELEMENTSIZE){
			ERR("element prop index out of bounds: %d / max %d",propindex,OBJ_ELEMENTSIZE);
		}
		else{
			cells[propindex]=value;
		}
	}
};
 class MyObject{
	
	std::vector<ElementStruct*> *mynewobj;
	int isSTATIC;

	//cell_t leaktest[10000];
	
 public:
	cell_t Size(){ return mynewobj->size(); }
	MyObject(int initialsize, int shallbestatic)
	{
		isSTATIC=shallbestatic;
		mynewobj=new std::vector<ElementStruct*>;

		for( int i=0;i<initialsize;i++){
			ElementStruct* element=new ElementStruct();
			for(int j=0;j<OBJ_ELEMENTSIZE;j++){ //initialize all to zero
				element->Set(j,0);
			}
			mynewobj->push_back(element);
		}
		
	}
	~MyObject()
	{
		delete mynewobj;
	}
	ElementStruct* GetElement(int elementindex){
		if(elementindex>=Size()||elementindex<0)
		{
			//if(isSTATIC){
				ERR("index out of bounds! tried to access %d, size of %d",elementindex,Size());
				return NULL;
			//}
			/*else{ //dynamically add
				for( int i=size;i<  elementindex  ;i++){
					ElementStruct* element=new ElementStruct();
					for(int j=0;j<OBJ_ELEMENTSIZE;j++){ //initialize all to zero
						element->Set(j,0);
					}
					mynewobj->push_back(element);
				}
				//if(elementindex>200){
				//	ERR("WARNING, AUTO GREW object to over 200");
				//}
			}*/
		}
		
		return mynewobj->at(elementindex);
		
	}
	
};
#ifdef SMEXT_CONF_METAMOD
bool War3Obj::SDK_OnMetamodLoad(ISmmAPI *ismm, char *error, size_t maxlen, bool late)
{

	return true;
}
#endif
bool War3Obj::SDK_OnLoad(char *error, size_t maxlength, bool late)
{
	g_pShareSys->AddNatives(myself,MyNatives);

	//rules on handle access security
	HandleAccess rules;
	TypeAccess typerules;
	g_pHandleSys->InitAccessDefaults(&typerules, &rules);
 
	typerules.access[ HTypeAccess_Create]=true;
	/* Restrict delete to only our identity */
	rules.access[HandleAccess_Delete] = 0; //allow all
	rules.access[HandleAccess_Read]=0; //allowall
	 

	/* Register the type with default security permissions */
	g_MyHandleType = g_pHandleSys->CreateType("war3obj",  //MUST BE UNIQUE
		&war3_ext, //passing own class, as we implemented handle destroy func
		0, 
		&typerules, 
		&rules, 
		myself->GetIdentity(), 
		NULL);
	
	return true;
}
void War3Obj::SDK_OnUnload()
{ 
	/* Remove the type on shutdown */
	g_pHandleSys->RemoveType(g_MyHandleType, myself->GetIdentity());
}

const char *War3Obj::GetExtensionVerString()
{
	return SMEXT_CONF_VERSION;
}
 
const char *War3Obj::GetExtensionDateString()
{
	return SM_BUILD_TIMESTAMP;
}
//std::vector<std::vector<ObjStruct>*> mylist;
//native

#include "mynatives.include.cpp"


///direct CloseHandle(..)
void War3Obj::OnHandleDestroy(HandleType_t type, void *object){
	for(int i=0;i<2;i++){
		//DP("DO NOT CALL CloseHandle, use DeleteObj instead!!!");
	}
}


static void NERR(IPluginContext *pContext,char* format,...)
{
	va_list ap;
	va_start(ap, format);
	
	
	char buffer[2000];
	UTIL_Format(buffer,sizeof(buffer),format,ap);
	pContext->ThrowNativeError(buffer);
	va_end(ap);
}
static cell_t OurTestNative2(IPluginContext *pCtx, const cell_t *params)
{
	
	return 1;
}

/* Turn a public index into a function ID */
inline funcid_t PublicIndexToFuncId(uint32_t idx)
{
	return (idx << 1) | (1 << 0); //times 2 (shift left) then plus 1 (or with 1)
}
static cell_t W3ExtTestFunc(IPluginContext *pCtx, const cell_t *params)
{
	
	return  1;//sp_ftoc(2.4f);
}




//allows a global var in pawn to be changed by reference / get a pointer to it 

cell_t CreateCellReference(IPluginContext *pCtx, const cell_t *params)
{
	cell_t *celladdr;
	pCtx->LocalToPhysAddr(params[1], &celladdr);
	//DP("celladdr is %d\n",celladdr);
	/* Create the Handle with our type, the plugin's identity, and our identity */
	HandleError err; //will be garbage if handle created successfully
	cell_t handle =  g_pHandleSys->CreateHandle(g_MyHandleType, 
		celladdr,  //the pointer
		NULL,//pCtx->GetIdentity(), 
		NULL,//myself->GetIdentity(), 
		&err); //returns 0 if failed
	if(handle==0)
	{
		pCtx->ThrowNativeError("fail to create handle, war3obj handle %x (error %d)", handle, err);
	}
	return handle;
}
cell_t CellDereference(IPluginContext *pContext, const cell_t *params)
{
	Handle_t handle = static_cast<Handle_t>(params[1]);
	cell_t *celladdr;
	
	celladdr = (cell_t*) HandleToObj(handle);
	//DP("CellDereference celladdr is %d\n",celladdr);
	return *celladdr;
}
cell_t SetCellByReference(IPluginContext *pContext, const cell_t *params)
{
	Handle_t handle = static_cast<Handle_t>(params[1]);
	cell_t *celladdr;
	
	celladdr =  (cell_t*)HandleToObj(handle);
	//DP("SetCellByReference celladdr is %d\n",celladdr);
	*celladdr = params[2];
	return 1;
}




#include "mynativeslist.include.cpp"
///MUST BE AFTER NATIVE FUNCS, stupid 1 pass compiler


