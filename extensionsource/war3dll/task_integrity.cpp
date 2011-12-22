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
		

		////////////////////
		//g_pSM->BuildPath(Path_SM, path, sizeof(path), "plugins\\");
		//const char* filename22=g->helperplugin->GetFilename(); //"w3s\\a.txt";
		//strcat(path,filename22);

		/*string out22,line22;
		ifstream inFile22;

		FILE *pFile =fopen ( path, "rb" );
		ERR("%s",filename22);
		if (pFile!=NULL)
		{
			fseek (pFile , 0 , SEEK_END);
  int lSize = ftell (pFile);
  rewind (pFile);

			  MD5 *mymd5class=new MD5();
			  unsigned char buffer[1024];
			  int len;
			  int totallen=0;

			  while ((len=fread(buffer, 1, 1024, pFile))){
					ERR("len %d",len);
				mymd5class->update(buffer, len);
				totallen+=len;
			  }
			  mymd5class->finalize();

			  fclose (pFile);

			 // mymd5class->update(pFile);
			   //string hashed22=md5(out22);
				ERR("%d %d %s",totallen,lSize,mymd5class->hexdigest().c_str());
				delete mymd5class;
		}
		else{
			ERR("COULD NOT OPEN FILE");
		}
		/*inFile22.open(path,ios::binary);
		if (!inFile22.is_open()) {
			ERR("could not open %s",path);
			goto filereadfailed;
		}
		while (inFile22 >> line22) {
			out22 +=line22;
		}
		inFile22.close();
		ERR("file len = %d",out22.length());
		string hashed22=md5(out22);
		ERR("%s",hashed22.c_str());
		*/

		///////////

		g_pSM->BuildPath(Path_SM, path, sizeof(path), "plugins\\");
		const char* filename=g->helperplugin->GetFilename();
		strcat(path,filename);

		/*string out,line;
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
		ERR("file len = %d",out.length());*/
		string hashed=md5file(path);
		ERR("Your helper hash: %s",hashed.c_str());

		if(hashed.length()==0){
			ERR("[PIC] ERR Zero length hash");
			goto redotask;
		}



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
