#include "war3dll.h"
#define MAXPLAYERS 67
#define MAXITEMS 200

cell_t diamonds[MAXPLAYERS];

class playeritemownership
{
public:
	vector<bool> item;
	playeritemownership(){
		for(int i=0;i<MAXITEMS;i++){
			item.push_back(false);
		}
	}
};
playeritemownership *playersownershipobj;


bool GetOwnsItem(cell_t client,cell_t itemid){
	if(itemid<(cell_t)1||itemid>=MAXITEMS){
		ERR("invalid item ownership access. client:%d itemid:%d",client,itemid);
		return 0;
	}
	
	return playersownershipobj[client].item[itemid];
}
void SetOwnsItem(cell_t client,cell_t itemid,bool newownsitem){
	if(itemid<(cell_t)0||itemid>=MAXITEMS){
		ERR("invalid item ownership set client %d itemid %d / maxitem %d ",client,itemid ,MAXITEMS);
	}
	else{
		//ERR("1r");
		playersownershipobj[client].item[itemid]=newownsitem;
		IPluginIterator *iterator = g->pluginmanager->GetPluginIterator();
		//ERR("iter");
		while(iterator->MorePlugins()){
			IPlugin* plugin=iterator->GetPlugin();
			IPluginFunction *func=plugin->GetRuntime()->GetFunctionByName(newownsitem?"OnItem2Purchase":"OnItem2Lost");
			if(func!=NULL){
				cell_t myparams[2];
				myparams[0]=client;
				myparams[1]=itemid;
				//ERR("call");
				func->CallFunction(myparams,2,&dummy);
			}
			iterator->NextPlugin();
		}
	}
}
static cell_t War3_GetOwnsItem2(IPluginContext *pCtx, const cell_t *params)
{
	return GetOwnsItem(params[1],params[2]);
}

static cell_t War3_SetOwnsItem2(IPluginContext *pCtx, const cell_t *params)
{
	SetOwnsItem(params[1],params[2],params[3]!=0);
	return 0;
}
cell_t GetClientItemsOwned(cell_t client){
	cell_t sum=0;
	for(int i=1;i<=shopitem2count;i++){
		if(GetOwnsItem(client,i))
		{
			sum++;
		}
	}
	return sum;
}


///////////////////
cell_t GetDiamonds(cell_t client){
	if(client<0||client>=MAXPLAYERS){
		ERR("invalid diamond count set %d",client);
		return 0;
	}
	else{
		return diamonds[client];
	}
}
void SetDiamonds(cell_t client,cell_t count){
	if(client<0||client>=MAXPLAYERS){
		ERR("invalid diamond count set %d",client);
	}
	else{
		diamonds[client]=count;
	}
}

static cell_t War3_GetDiamonds(IPluginContext *pCtx, const cell_t *params)
{
	return GetDiamonds(params[1]);
}

static cell_t War3_SetDiamonds(IPluginContext *pCtx, const cell_t *params)
{
	SetDiamonds(params[1],params[2]);
	return 0;
}

void giveDiamondsTick(){
	cell_t result;
	IPluginFunction* func= PUBLIC("EXTGetClientTeam");
		
	for(cell_t i=0;i<MAXPLAYERS;i++){
		
		if(ValidPlayer(i)){
			func->CallFunction(&i,1,&result);
			if(result>1){
				diamonds[i]++;
			}
		}
	}
}

static const sp_nativeinfo_t MyNatives2[] =
{
	{"War3_GetOwnsItem2EXT",			War3_GetOwnsItem2},
	{"War3_SetOwnsItem2EXT",			War3_SetOwnsItem2},
	{"War3_GetDiamondsEXT",			War3_GetDiamonds},
	{"War3_SetDiamondsEXT",			War3_SetDiamonds},
	
	//{"W3GetItem2Name",			W3GetItem2Name},
	//{"W3ExtCommandListener",	W3ExtCommandListener},
	//{"W3ExtShowShop2",	W3ExtShowShop2},
	{NULL,							NULL}, // last entry is null, it marks the end for all the loop operations.
};
void InitOwnershipClass(){
	g->sharesys->AddNatives(myself,MyNatives2);


	playersownershipobj= new playeritemownership[MAXPLAYERS];//max items
	
}

