#include "war3dll.h"

int shopitem2count=-1;

vector<ShopItem2*> myitemslist;
ShopItem2* item; //global var as temp

ShopItem2::ShopItem2(char* tname,char* tshort,char* tdesc,int tcost,bool trans){

	strncpys(mname,sizeof(mname),tname);
	strncpys(mshortname,sizeof(mshortname),tshort);
	//PRINT("new item %s > %s\n",tshort,mshortname);
	strncpys(mdesc,sizeof(mdesc),tdesc);

	mcost=tcost;
	mtranslated=trans;
	itemid=myitemslist.size();
	myitemslist.push_back(this);


	if(mtranslated){
		phrasecollection=g->iphrase->CreatePhraseCollection();

		char filename[300];
		FORMAT(filename,sizeof(filename),"w3s.item2.%s.phrases",mshortname);
		//ERR("%d %s",g->iphrase,filename);

		phrasecollection->AddPhraseFile(filename); //dont care about return
		FORMAT(mname,sizeof(mname),"%s_ItemName",mshortname);
		FORMAT(mdesc,sizeof(mname),"%s_ItemDesc",mshortname);
	}
	shopitem2count++;
	itemid=shopitem2count;
	FORMAT(itemidstr,sizeof(itemidstr), "%d",itemid);
}


const char* ShopItem2::name(){
	return trans(mname); ///LIVE TRANSLATE
}
const char* ShopItem2::shortname(){
	return mshortname; //shortname is not translated
}
const char* ShopItem2::desc(){
	return trans(mdesc);
}
int ShopItem2::cost(){
	return mcost;
}


const char* ShopItem2::trans(char* keyphrase){
	if(!mtranslated){
		return keyphrase;
	}
	Translation transresult;

	int transclient=GetTrans();
	int langid=ValidPlayer(transclient)?g->iphrase->GetClientLanguage(transclient):g->iphrase->GetServerLanguage(); //GetServerLanguage();//->
	if( Trans_Okay==phrasecollection->FindTranslation(keyphrase,langid,&transresult)){;
		return transresult.szPhrase;
	}
	ERR("ShopItem2::trans TRANSLATION OF phrase \"%s\" failed on item %d",keyphrase,itemid);
	return "translation failed";

}


///sets the global item we are messing with, not thread safe!
bool GetItem(int index){
	if(index>0&&index<=shopitem2count){
		item= myitemslist.at(index);
		return true;
	}
	item= NULL;
	ERR(" tried to get bad shopitem 2 index = %d",index);
	return false;
}

cell_t W3SetItem2Info(IPluginContext *pCtx, const cell_t *params)
{
	return 0;
}
