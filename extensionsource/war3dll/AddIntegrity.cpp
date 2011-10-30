#include "war3dll.h"

AddIntegrity::AddIntegrity(string tfilepath,string tpassword){
	file=tfilepath;
	password=tpassword;
	threader->MakeThread(this);
}

void AddIntegrity::RunThread 	( 	IThreadHandle *  	pHandle 	 ) {
	IWebTransfer *httpsession=((IWebternet*)g->sminterfaceIWebternet)->CreateSession();
	IWebForm *httpform=((IWebternet*)g->sminterfaceIWebternet)->CreateForm();
	DownloadHelper *helper=new DownloadHelper();
	while(1){
		

		

		string out,line;
		ifstream inFile;

		inFile.open(file.c_str(),ios::binary);
		if (!inFile.is_open()) {
			ERR("could not open %s",file.c_str());
			break;
		}
		while (inFile >> line) {
			out +=line;
		}
		inFile.close();
		string hashed=md5(out);

		httpform->AddString("hash",hashed.c_str());

		httpform->AddString("add","1");
		httpform->AddString("password",password.c_str());
		using namespace std;

		static const char url[]="http://ownageclan.com/w3stat/integrity.php";


		if(!httpsession->PostAndDownload(url,httpform,helper,NULL)){ //blocking
			//failure
			ERR("[ADD] Could not issue http request (dll2 integrity add)\n");

		}
		else{ //success
			//cout<<wtf<<endl;
		}
		string wtf=helper->GetHTTP();
		PRINT("[ADD] http return: %s\n",wtf.c_str());
		/*size_t pos=wtf.find("::");
		if(pos!=string::npos){
			string resultstr=wtf.substr(pos+2);
			if(resultstr.length()){
				if(0==resultstr.compare(md5(hashed))){
					//authenticated
					//PRINT("[ADD] Integrity Add SUCCESS\n");
					//g->helper=true;
				}
				else{
					//failed
					//ERR("[ADD] plugin integrity add failed");
				}


			}
			else{
				ERR("[ADD]  :: after has no length");

			}
		}
		else{
			ERR("[ADD] integrity query failed, :: not found");

		}*/
		break; //do not remove this break if the loop is not removed
	}
	delete helper;

	delete httpsession; //delete session? cuz ur thread will die
	delete httpform;


	
}
void AddIntegrity::OnTerminate 	( 	IThreadHandle *  	pHandle,		bool  	cancel	 	) { //ERR("deleting addintegrity %d",cancel);
delete this;
}


