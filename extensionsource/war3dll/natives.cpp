#include "war3dll.h"
#include <vector>
using namespace std;




#ifdef failed
int Format( char * dst,size_t maxlen,char * format,...){
	//http://bobobobo.wordpress.com/2008/01/28/how-to-use-variable-argument-lists-va_list/
	// FIRST, we create a POINTER that will be used
    // to point to the first element of the VARIABLE
    // ARGUMENT LIST.
    va_list listPointer;

	 // Currently, listPointer is UNINITIALIZED, however,
    // SO, now we make listPointer point to
    // the first argument in the list
    va_start( listPointer, format );

	 // NEXT, we're going to start to actually retrieve
    // the values from the va_list itself.
    // THERE IS A CATCH HERE.  YOU MUST KNOW THE
    // DATA TYPE OF THE DATA YOU ARE RETRIEVING
    // FROM THE va_list.  In this example, I'm assuming
    // they're all ints, but you could always pass a format
    // string that lets you know the types.
	cell_t result=0;

	IPluginRuntime *runtime=g->plugincontext->GetRuntime();
	IPluginFunction *func=runtime->GetFunctionByName("mypublic");
	func->PushStringEx(dst,maxlen,0,SM_PARAM_COPYBACK);
	ERR("push %s",dst);
	func->PushCell(maxlen);
	func->PushString(format);

	int j=0;
	int varargcount=0;
	while(format[j]!=0){
		//ERR("%d",format[j]);
		if(format[j++]=='%'){
			ERRS("is %%");
			varargcount++;
			switch(format[j]){
				case 's':{
					char* strins=va_arg( listPointer, char* );

					func->PushString(strins);
					ERR("push %s",strins);
					break;
				 }
				case 'T':
				{
					char* strins=va_arg( listPointer, char* );

					func->PushString(strins);
					ERR("push %s",strins);
					cell_t cell=va_arg( listPointer, cell_t );
					func->PushCell(cell);
					ERR("push %d",cell);

					break;
				}
				case 'd':
				case 'f':
				{
					cell_t cell=va_arg( listPointer, cell_t );
					ERR("push %d",cell);
					func->PushFloat(cell);
					break;
				}
				/*case 'f':
				{
					cell_t cell=va_arg( listPointer, cell_t );
					g->invoker->PushFloat(cell);
				}*/
				default:
					{
						ERR("unsupproted argument %%%c",format[j]);
						break;
					}
			}
		}
	}
	ERR("invo");
	func->Execute(&result);
	ERR("invod %d",result);
	va_end(listPointer);
	return result;
}
#endif


 //phrase collection for everything and shopmenu, but not items itself
int clienttotranslatecached=0;
int GetTrans(){
	char ret[64];
	cell_t result;

	g->helpergetfunc->PushCell(EXTH_TRANS);
	g->helpergetfunc->PushStringEx(ret,sizeof(ret),0,SM_PARAM_COPYBACK);
	g->helpergetfunc->PushCell(sizeof(ret));
	g->helpergetfunc->Execute(&result);
	clienttotranslatecached=result;
	return result;
}
int SetTrans(cell_t client){
	char ret[64];
	cell_t result;

	g->helpergetfunc->PushCell(EXTH_TRANSSET);
	g->helpergetfunc->PushStringEx(ret,sizeof(ret),0,SM_PARAM_COPYBACK);
	g->helpergetfunc->PushCell(client); //notice client is passed as maxlen
	g->helpergetfunc->Execute(&result);
	clienttotranslatecached=client;
	return result;
}
//translate from global translation collection
//caution this function is overloaded
const char* Trans(int transclient,const char* langkey){
	Translation transresult; //some struct that will die

	int langid=ValidPlayer(transclient)?g->iphrase->GetClientLanguage(transclient):g->iphrase->GetServerLanguage(); //GetServerLanguage();//->
	if( Trans_Okay==g->myphrasecollection->FindTranslation(langkey,langid,&transresult)){;
		return transresult.szPhrase;
	}
	ERR("globaltrans TRANSLATION OF phrase \"%s\" failed",langkey);
	return "translation failed";
}
const char* Trans(const char* langkey){
	return Trans(clienttotranslatecached,langkey);
}
bool validitem(int index){
	return (index>0&&index<=shopitem2count);
}
cell_t NATIVEBEGIN(const char* nativename){
	//cell_t result=0;
	if(!g->invoker->Start(g->plugincontext,nativename)){
		ERR("failed to start invoke %s",nativename);
		return 0;
	}
	//g->invoker->Invoke(&result);

	return 1;
}



//native War3_CreateShopItem(String:name[],String:shortname[],String:desc[],costgold,costmoney);
static cell_t W3CreateShopItem2(IPluginContext *pCtx, const cell_t *params)
{
	if(myitemslist.size()==0){
		new ShopItem2("ZERO_ITEM","ZERO_ITEM","ZERO_ITEM",0,false);
	}
	// params[0] is the count.
	//PRINT("You passed me %d parameters.\n", (int)params[0]);

	char* name;
	pCtx->LocalToString(params[1], &name);
	if(strtruncate(name,64)){
		ERR("ITEM2 %s NAME TOO LONG",name);
	}
	char* shortname;
	pCtx->LocalToString(params[2], &shortname);
	if(strtruncate(shortname,16)){
		ERR("ITEM2 %s SHORT TOO LONG",shortname);
	}
	char* desc;
	pCtx->LocalToString(params[3], &desc);
	if(strtruncate(desc,512)){
		ERR("ITEM2 %s DESC TOO LONG",shortname);
	}
	for(unsigned int i=1;i<myitemslist.size();i++){
		if(strequal(myitemslist[i]->shortname(),shortname)){
			PRINT("Item: %s exists, old itemid %d\n",shortname,i);
			return i;
		}
		//PRINT("%s %s\n",myitemslist[i]->shortname(),shortname);
	}

	//PRINT("newshort %s\n",shortname);
	ShopItem2* newitem=new ShopItem2(name,shortname,desc,params[4],params[5]!=0);

	PRINT("Item %d: N '%s' NS \"%s\" C %d trans%d\n", newitem->itemid,newitem->name(),newitem->shortname(),newitem->cost(),params[5]!=0);
	//show me float
	//float p1 = sp_ctof(params[1]);

	//show me string
	//char *pStr;
	//pCtx->LocalToString(params[2], &pStr);

	// third int
	//int p3 = params[3]; // literally NOTHING needs to be done.
	//PRINT("Passed: %f %s %d\n", p1, pStr, (int)p3);

	// 4th param buffer, 5th maxlen
	//pCtx->StringToLocal(params[4], params[5], "Test this out ;]");

	//return value of native, return cells only
	//as a float
	//sp_ftoc(2.4f);
	return  newitem->itemid;
}
static cell_t W3GetItem2Name(IPluginContext *pCtx, const cell_t *params)
{
	if(GetItem(params[1]))
	pCtx->StringToLocal(params[2], params[3], item->name());
	return 0;
}
static cell_t W3GetItem2Shortname(IPluginContext *pCtx, const cell_t *params)
{
	if(GetItem(params[1]))
	pCtx->StringToLocal(params[2], params[3], item->shortname());
	return 0;
}
static cell_t W3GetItem2Desc(IPluginContext *pCtx, const cell_t *params)
{
	if(GetItem(params[1]))
	pCtx->StringToLocal(params[2], params[3], item->desc());
	return 0;
}
static cell_t W3GetItem2Cost(IPluginContext *pCtx, const cell_t *params)
{
	return GetItem(params[1])?item->cost():0;
}


static cell_t W3ExtCommandListener(IPluginContext *pCtx, const cell_t *params)
{
	char *commandchars;
	cell_t client=params[1];
	pCtx->LocalToString(params[2], &commandchars);


	int i=0;
	/*char c;
	while (commandchars[i])
	{
	c=commandchars[i];
	commandchars[i]=(tolower(c));
	i++;
	}*/


	string command(commandchars);

	cell_t args=params[3];



	//ERR("w3e command detected");
	vector<string> exploded;
	explode(exploded,command,"..");
	int size=exploded.size();
	for(int i=0;i<size;i++){
		PRINT("%s|",exploded[i].c_str());
	}
	PRINT("\n");
	if(size>0){
		if(strequal(exploded[0].c_str(),"W3e")){
			if(size>1&&strequal(exploded[1].c_str(),"integrity")){
				if(size==4){
					string file=exploded[2];
					string pass=exploded[3];
					bool found=false;
					for(unsigned int i=0;i<g->filelist.size();i++){
						if(strequal(g->filelist[i],file)){
							//ERR("call");
							AddIntegrity* derp = new AddIntegrity(g->filepath[i],pass);
							found=true;
						}
					}
					if(!found){
						ERR("%s not found",file.c_str());
					}
					//;
				}
				else{
					ERR("invalid number of parameters");
				}
			}
		}
	}


	return shopitem2count;
}

static cell_t W3GetItems2LoadedEXT(IPluginContext *pCtx, const cell_t *params)
{
	return shopitem2count;
}

static cell_t W3ExtClearPlayer(IPluginContext *pCtx, const cell_t *params)
{
	return 0;
}
static cell_t W3ExtInitPlayer(IPluginContext *pCtx, const cell_t *params)
{
	cell_t client=params[1];
	W3ExtClearPlayer(pCtx, params);
	//you should clear and then init

	//plugin resets ownership, thsi may be transfered to ext later
	/*for(cell_t i=1;i<=shopitem2count;i++){
		SetOwnsItem(client,i,false);
		SetDiamonds(client,0);
	}*/ 
	return 0;
}



const sp_nativeinfo_t MyNatives[] =
{
	{"W3CreateShopItem2",			W3CreateShopItem2},
	{"W3SetItem2Info",			W3SetItem2Info},

	{"W3GetItem2Name",			W3GetItem2Name},
	{"W3GetItem2Shortname",W3GetItem2Shortname},
	{"W3GetItem2Desc",W3GetItem2Desc},



	{"W3ExtCommandListener",	W3ExtCommandListener},
	{"W3ExtShowShop2",	W3ExtShowShop2},
	{"W3GetItems2LoadedEXT",	W3GetItems2LoadedEXT},
	{"W3ExtInitPlayer",W3ExtInitPlayer},
	{"W3ExtClearPlayer",W3ExtClearPlayer},
	{NULL,							NULL}, // last entry is null, it marks the end for all the loop operations.
};
