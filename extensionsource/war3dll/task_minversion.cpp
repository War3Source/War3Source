#include "war3dll.h"

void task_minversion(){
	IWebTransfer *httpsession=((IWebternet*)g->sminterfaceIWebternet)->CreateSession();
	IWebForm *httpform=((IWebternet*)g->sminterfaceIWebternet)->CreateForm();

	using namespace std;
	
	static const char url[]="http://ownageclan.com/w3stat/war3minver.php";
	
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
				ERR("[minver] sscanf returned end of line");
			}
			else{
				//cout<<resultnum<<endl;
				if(resultnum>g->war3revision){
					//higher than our version
					g->minversionexceeded=true;
					for(int i=0;i<100;i++){
						ERR("War3 requires update!!! yours: %d   minimum: %d",g->war3revision,resultnum);
					}
					exit(0);
					//cout<<"needasdfasdf update"<<resultnum<<" "<<g->war3revision<<endl;
				}
				else{
					//cout<<"no update"<<resultnum<<" "<<g->war3revision<<endl;
				}
			}
		}
	}
	else{
		ERR("minver query failed, :: not found");
	}
	delete helper;

	delete httpsession; //delete session? cuz ur thread will die
	delete httpform;

}
