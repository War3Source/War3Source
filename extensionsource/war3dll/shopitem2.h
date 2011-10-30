using namespace std;
enum Item2Prop{
	DESCRIPTION
};

class ShopItem2
{

	char mname[64];
	char mshortname[16+10]; //SOMETHIGN INHERENTLY WRONG WITH STRNCPY ??? it concats a = at the end of its close to the maxlength
	char mdesc[512];
	char tempchar[512];
	char mcost;
	bool mtranslated;
	IPhraseCollection *phrasecollection;

public:
	int itemid;
	char itemidstr[10];
	ShopItem2(char* tname,char* tshort,char* tdesc,int tcost,bool trans);

	const char* name();
	const char* shortname();
	const char* desc();
	int cost();

	const char* trans(char* keyphrase);
};
int GetTrans();
int SetTrans(cell_t client);
extern int shopitem2count;

extern vector<ShopItem2*> myitemslist;
extern ShopItem2* item; //global var as temp
extern bool GetItem(int index);

cell_t W3SetItem2Info(IPluginContext *pCtx, const cell_t *params);

