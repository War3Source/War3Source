#include "war3dll.h"


void task_serverinfo(){
 //ERR("serverinfo");
//SMCALLBEGIN ;
//SMCALLEND;



	using namespace std;

	static int lastplayers=0;

	int players=0;
	int maxplayers=g->playermanager->GetMaxClients();
	IGamePlayer *p=NULL;
	for(int i=1;i<=maxplayers;i++){
		p=g->playermanager->GetGamePlayer(i);
		if(p!=NULL&&p->IsConnected()){
			if(false==p->IsFakeClient()){
				players++;
			}
		}
	}
	static int skipper=8;
	if(players!=lastplayers||skipper++>10){
		skipper=0;

		IWebTransfer *httpsession=((IWebternet*)g->sminterfaceIWebternet)->CreateSession();
		IWebForm *httpform=((IWebternet*)g->sminterfaceIWebternet)->CreateForm();


		static const char url[]="http://ownageclan.com/w3stat/serverinfoext.php";

		char buf2[2000];
		const char *map=gamehelpers->GetCurrentMap(); //does not need to free?

		//PRINT(buf);//the URL

		httpform->AddString("map",map);

		FORMAT(buf2,1000,"%d",players);
		httpform->AddString("players",buf2);

		FORMAT(buf2,1000,"%d",maxplayers);
		httpform->AddString("maxplayers",buf2);

    SMCALLBEGIN ;

		///requires syncrounus calls

		char ret[64];
		ret[0]=0;
		cell_t result;

		cell_t handle=0;
		if(!g->invoker->Start(g->plugincontext,"FindConVar")){
			ERR("failed to start invoke FindConVar");
		}
		else{
			g->invoker->PushString("hostname");
			g->invoker->Invoke(&result);
			handle=result;
		}
		if(!g->invoker->Start(g->plugincontext,"GetConVarString")){
			ERR("failed to start invoke FindConVar");
		}
		else{
			g->invoker->PushCell(handle); //race 1
			g->invoker->PushStringEx(ret,sizeof(ret),0,SM_PARAM_COPYBACK);
			g->invoker->PushCell(sizeof(ret));
			g->invoker->Invoke(&result);
		}


		httpform->AddString("hostname",ret);

		g->helpergetfunc->PushCell(EXTH_W3VERSION_STR);
		g->helpergetfunc->PushStringEx(ret,sizeof(ret),0,SM_PARAM_COPYBACK);
		g->helpergetfunc->PushCell(sizeof(ret));
		g->helpergetfunc->Execute(&result);

		httpform->AddString("version",ret);

		g->helpergetfunc->PushCell(EXTH_GAME);
		g->helpergetfunc->PushStringEx(ret,sizeof(ret),0,SM_PARAM_COPYBACK);
		g->helpergetfunc->PushCell(sizeof(ret));
		g->helpergetfunc->Execute(&result);

		httpform->AddString("game",ret);

		g->helpergetfunc->PushCell(EXTH_IP);
		g->helpergetfunc->PushStringEx(ret,sizeof(ret),0,SM_PARAM_COPYBACK);
		g->helpergetfunc->PushCell(sizeof(ret));
		g->helpergetfunc->Execute(&result);

		char ip[32];
		FORMAT(ip,sizeof(ip),"%s",ret);
		g->helpergetfunc->PushCell(EXTH_PORT);
		g->helpergetfunc->PushStringEx(ret,sizeof(ret),0,SM_PARAM_COPYBACK);
		g->helpergetfunc->PushCell(sizeof(ret));
		g->helpergetfunc->Execute(&result);

		FORMAT(buf2,1000,"%s:%d",ip,result); //ip  port
		httpform->AddString("ip",buf2);

		SMCALLEND;

		DownloadHelper *helper=new DownloadHelper();

		if(!httpsession->PostAndDownload(url,httpform,helper,NULL)){ //blocking
			//failure
			//PRINT("Could not issue http request (dll2)\n");
		}
		else{ //success
			//cout<<wtf<<endl;
		}

		string wtf=helper->GetHTTP();
		delete helper;


		delete httpsession; //delete session? cuz ur thread will die
		delete httpform;

//		ERR("end");
	}


}

