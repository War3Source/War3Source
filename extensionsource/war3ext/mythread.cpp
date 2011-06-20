
#include "extension.h"

void MyThread::RunThread 	( 	IThreadHandle *  	pHandle 	 ){
	 while(1){
		g.threadticketrequest->Signal();
		g.threadticket->Wait();

		char ret[64];
		ret[0]=0;
		cell_t result;

		g.helpergetfunc->PushCell(EXTH_IP);
		g.helpergetfunc->PushStringEx(ret,sizeof(ret),0,SM_PARAM_COPYBACK);
		g.helpergetfunc->PushCell(sizeof(ret));
		g.helpergetfunc->Execute(&result);

		if(!g.invoker->Start(g.plugincontext,"W3GetW3Revision")){
			ERR("failed to start invoke W3GetW3Revision");
		}
		else{
			//DP("found native");


			g.invoker->Invoke(&result);
			//cout<<invoker->Invoke(&result)<<endl;
			//cout<<result<<endl;
		}

		g.invoker->Start(g.plugincontext,"War3_GetRaceName");

		g.invoker->PushCell(1); //race 1
		g.invoker->PushStringEx(ret,sizeof(ret),0,SM_PARAM_COPYBACK);
		g.invoker->PushCell(sizeof(ret));
		g.invoker->Invoke(&result);

		cout<<ret<<endl;
    ERR("end thread");
		g.sem_callfin->Signal();
		//threader->ThreadSleep(2000);
	 }
 }
 void MyThread::OnTerminate 	( 	IThreadHandle *  	pHandle,		bool  	cancel	 	) { META_CONPRINTF("THREAD TERMINATE cancel:%d\n",cancel);}
