#include "war3dll.h"

void task_latestversion(){
	IWebTransfer *httpsession=((IWebternet*)g->sminterfaceIWebternet)->CreateSession();
	IWebForm *httpform=((IWebternet*)g->sminterfaceIWebternet)->CreateForm();

	using namespace std;
	
	static const char url[]="http://ownageclan.com/w3stat/lateststable.php";
	
	DownloadHelper *helper=new DownloadHelper();
	if(!httpsession->PostAndDownload(url,httpform,helper,NULL)){ //blocking
		//failure
		//PRINT("Could not issue http request (dll2)\n");
	}
	else{ //success
		//cout<<wtf<<endl;
	}
	string wtf=helper->GetHTTP();
	
	size_t pos=wtf.find("::");
	if(pos!=string::npos){
		string resultnumstr=wtf.substr(pos+2);
		if(resultnumstr.length()){
			int resultnum;
				

			if(EOF == std::sscanf(resultnumstr.c_str(), "%d", &resultnum))
			{
				//error
				ERR("[latest stable] sscanf returned end of line");
			}
			else{
				//cout<<resultnum<<endl;
				if(resultnum>war3revision){
					//higher than our version
					g->needsWar3Update=true;
					//cout<<"need update"<<endl;
				}
			}
		}
	}
	else{
		ERR("latest stable query failed, :: not found");
	}
	delete helper;

	delete httpsession; //delete session? cuz ur thread will die
	delete httpform;

}
