
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
			g.invoker->Invoke(&result);
		}

		g.invoker->Start(g.plugincontext,"War3_GetRaceName");

		g.invoker->PushCell(1); //race 1
		g.invoker->PushStringEx(ret,sizeof(ret),0,SM_PARAM_COPYBACK);
		g.invoker->PushCell(sizeof(ret));
		g.invoker->Invoke(&result);

		cout<<ret<<endl;
		g.threadticketdone->Signal();
		//threader->ThreadSleep(1900);
	 }
 }
 void MyThread::OnTerminate 	( 	IThreadHandle *  	pHandle,		bool  	cancel	 	) { META_CONPRINTF("THREAD TERMINATE cancel:%d\n",cancel);}
