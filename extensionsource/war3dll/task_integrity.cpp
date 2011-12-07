#include "war3dll.h"
#include <iostream>
#include <sstream>

extern int Format( char * format,size_t maxlen,char * src,...);
void task_integrity(){

	//char foo[100];
	//Format(foo,sizeof(foo),"derp %s %T %d %f","no","[War3Source]",(cell_t)1,88,99.9f);
	//ERR("FOO:%s",foo);
	ERR("task_integrity()");



	IWebTransfer *httpsession=((IWebternet*)g->sminterfaceIWebternet)->CreateSession();
	IWebForm *httpform=((IWebternet*)g->sminterfaceIWebternet)->CreateForm();
	DownloadHelper *helper=new DownloadHelper();

	//static int countdown=100;
	//countdown--;
	//if(countdown==0){ //we tried 100 times....
		//
	//	goto end;
	//}
	if(g->helperplugin==NULL){
		goto redotask;
	}
	else{
		char path[PLATFORM_MAX_PATH*2];
		g_pSM->BuildPath(Path_SM, path, sizeof(path), "plugins\\");
		const char* filename=g->helperplugin->GetFilename();
		strcat(path,filename);

		string out,line;
		ifstream inFile;

		inFile.open(path,ios::binary);
		if (!inFile.is_open()) {
			ERR("could not open %s",path);
			goto filereadfailed;
		}
		while (inFile >> line) {
			out +=line;
		}
		inFile.close();
		string hashed=md5(out);
		ERR("%s",hashed.c_str());




		httpform->AddString("hash",hashed.c_str());
		using namespace std;

		static const char url[]="http://ownageclan.com/w3stat/integrity.php";


		if(!httpsession->PostAndDownload(url,httpform,helper,NULL)){ //blocking
			//failure
			ERR("[PIC] Could not issue http request (dll2 integrity)");
			goto redotask;
		}
		else{ //success
			//cout<<wtf<<endl;
		}
		string wtf=helper->GetHTTP();
		//ERR("http return: %s",wtf.c_str());
		size_t pos=wtf.find("::");
		if(pos!=string::npos){
			string resultstr=wtf.substr(pos+2);
			if(resultstr.length()){
				if(0==resultstr.compare(md5(hashed))){
					//authenticated
					PRINT("[PIC] helper plugin authenticated\n");
					g->helperVerifiedIntegrity=true;
				}
				else{
					//failed
					ERR("[PIC] plugin integrity check failed");
				}


			}
			else{
				ERR("[PIC]  :: after has no length");
				goto redotask;
			}
		}
		else{
			ERR("[PIC] integrity query failed, :: not found");
			goto redotask;
		}

		goto end;
	}

redotask:
filereadfailed:
	ERR("[PIC] reschedule integrity check");
	g->imytimer->AddTimer(&task_integrity,5000,false);


end:
	delete helper;

	delete httpsession; //delete session? cuz ur thread will die
	delete httpform;

}
