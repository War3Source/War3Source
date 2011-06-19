 
#include "extension.h"

void MyThread::RunThread 	( 	IThreadHandle *  	pHandle 	 ){ 
	 while(1){
		threadticketrequest->Signal();
		threadticket->Wait();
	
		char ret[64];
		ret[0]=0;
		cell_t result;

		helpergetfunc->PushCell(EXTH_IP);
		helpergetfunc->PushStringEx(ret,sizeof(ret),0,SM_PARAM_COPYBACK);
		helpergetfunc->PushCell(sizeof(ret));
		helpergetfunc->Execute(&result);
		
		if(!invoker->Start(plugincontext,"W3GetW3Revision")){
			ERR("failed to start invoke W3GetW3Revision");
		}
		else{
			//DP("found native");

			
			invoker->Invoke(&result);
			//cout<<invoker->Invoke(&result)<<endl;
			//cout<<result<<endl;
		}

		invoker->Start(plugincontext,"War3_GetRaceName");

		invoker->PushCell(1); //race 1
		invoker->PushStringEx(ret,sizeof(ret),0,SM_PARAM_COPYBACK);
		invoker->PushCell(sizeof(ret));
		invoker->Invoke(&result);

		cout<<ret<<endl;
		
		sem_callfin->Signal();
	 }
 } 
 void MyThread::OnTerminate 	( 	IThreadHandle *  	pHandle,		bool  	cancel	 	) { META_CONPRINTF("THREAD TERMINATE cancel:%d\n",cancel);}
