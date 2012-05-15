
//tired of writing stuff over and over, why not just do it here? gets a pointer to what u stored from handle, you can cast it to anything actually after it returns
static MyObject* HandleToObj(Handle_t hndl){
	MyObject* objectpointer;

	HandleError err;
	HandleSecurity security; /* Build our security descriptor */
	security.pOwner = NULL;	/* Not needed, owner access is not checked */
	security.pIdentity = myself->GetIdentity();	/* But only this extension can read */

	if ((err = g_pHandleSys->ReadHandle(hndl, g_MyHandleType, &security, (void **)&objectpointer))
			!= HandleError_None)
	{
		ERRS("Invalid handle to war3obj  %x (error %d)\b", hndl, err);
		return NULL;
	}
	return objectpointer;
	
}
static cell_t CreateObj(IPluginContext *pCtx, const cell_t *params)
{
	
	int objsize = params[1];
	if(objsize<=0){
		return pCtx->ThrowNativeError("invalid size %d",objsize);
	}
	int isstatic = params[2];
	MyObject* myobj=new MyObject(objsize,isstatic);

	/* Create the Handle with our type, the plugin's identity, and our identity */
	HandleError err; //will be garbage if handle created successfully
	cell_t handle =  g_pHandleSys->CreateHandle(g_MyHandleType, 
		myobj,  //the pointer
		NULL,//pCtx->GetIdentity(), 
		NULL,//myself->GetIdentity(), 
		&err); //returns 0 if failed
	if(handle==0)
	{
		pCtx->ThrowNativeError("fail to create handle, war3obj handle %x (error %d)", handle, err);
	}
	return handle;
}
//native
static cell_t internal_delete_object(IPluginContext *pCtx,MyObject *myobj){
	
	int objsize=myobj->Size();
	
	cell_t hndl;
	for( int i=0;i<objsize;i++){
		ElementStruct* element=myobj->GetElement(i);
		if(element->Get(IS_OBJECT)){ //data field a handle to another object, delete it recursively
			hndl=element->Get(DATA);
			//DP("recurse delete ");
			//ERRS("%x %d",hndl,i);

			MyObject *nextobj=HandleToObj(hndl);
			internal_delete_object(pCtx,nextobj);
		}
		if(element->Get(IS_HANDLE)){
			//DP("element is handle\n");
			hndl=element->Get(DATA);
			int ishndl=element->Get(IS_HANDLE);
			if(element->Get(FUNC_DELETE_CALLBACK)){ ///this handle requires cleanup function
				cell_t functionid=element->Get(FUNC_DELETE_CALLBACK);
				IPluginFunction *pFunc;
				pFunc = pCtx->GetFunctionById(functionid);
				if (!pFunc)
				{
					pCtx->ThrowNativeError("Invalid delete callback function id (%d), LIKELY HANDLE LEAK\n", functionid);
				}
				else{
					//DP("calling delete func");
					cell_t res;
					pFunc->PushCell(hndl); //data contains the handle
					pFunc->Execute(&res);
				}
			}
			else{ //did not provide callback, we force generic delete on its interface public Delete function
				//TODO
			}
			
		}
		delete element; //free an element
	}
	delete myobj; //free the object (vector)
	return 1;
}
static cell_t DeleteObj(IPluginContext *pCtx, const cell_t *params)
{
	// params[0] is the count.
	cell_t hndl = params[1];

	//DP("deleting obj");
	MyObject *myobj= HandleToObj(hndl);
	
	internal_delete_object(pCtx,myobj);
	
	return 1;
}
//native
static cell_t GetObj(IPluginContext *pContext, const cell_t *params)
{
	Handle_t hndl = static_cast<Handle_t>(params[1]);
	int elementindex=params[1];
	int elementpropindex=params[2];
	//DP("GetObj");
	MyObject *myobj=HandleToObj(hndl);

	
	unsigned int subindex=params[3];
	ElementStruct* element=myobj->GetElement(elementindex);
	return element->Get(elementpropindex);
}
//native
static cell_t SetObj(IPluginContext *pContext, const cell_t *params)
{
	//META_CONPRINTF("setobj");
	Handle_t hndl = static_cast<Handle_t>(params[1]);
	cell_t elementindex=params[2];
	cell_t prop=params[3];
	cell_t subindex=params[4];
	//DP("SetObj");
	MyObject *myobj=HandleToObj(hndl);

	if(elementindex>=myobj->Size()){
		return pContext->ThrowNativeError("attempted to access element %d when there is only %d elements",elementindex,myobj->Size());
	}
	//DP("obj at %d",myobj);
	ElementStruct* element=myobj->GetElement(elementindex);

	element->Set(subindex,prop);

	//DP("element %d data %d subelement %d",params[2],params[3],params[4]);
	return 1;
}
static cell_t SetObjStr(IPluginContext *pContext, const cell_t *params)
{
	Handle_t hndl = static_cast<Handle_t>(params[1]);
	cell_t elementindex=params[2];
	char *pStr;
	pContext->LocalToString(params[3], &pStr);

	MyObject *myobj=HandleToObj(hndl);
	myobj->GetElement(elementindex)->SetStr(pStr);

	return 1;
}
static cell_t GetObjStr(IPluginContext *pContext, const cell_t *params)
{
	Handle_t hndl = static_cast<Handle_t>(params[1]);
	cell_t elementindex=params[2];

	MyObject *myobj=HandleToObj(hndl);
	char* pStr= myobj->GetElement(elementindex)->GetStr();
	pContext->StringToLocal(params[3],params[4], pStr);

	return 1;
}

