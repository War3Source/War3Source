 
#include "extension.h"

void MyThread::RunThread 	( 	IThreadHandle *  	pHandle 	 ){ 
	 while(1){
		
		sem_docall->Wait();

		char ret[64];
		ret[0]=0;
		cell_t result;

		for(int i=0;i<1;i++){
		 
	//cout<<"enter1";
		helpergetfunc->PushCell(EXTH_IP);
		helpergetfunc->PushStringEx(ret,sizeof(ret),0,SM_PARAM_COPYBACK);
		helpergetfunc->PushCell(sizeof(ret));
		helpergetfunc->Execute(&result);
		//cout<<"end1"<<result;
		//cout<<ret<<endl;
		

		 // mymutex->Unlock();
		 // threader->ThreadSleep(0);
		//nativeinterf->CreateInvoker();//leak
		
		if(!invoker->Start(plugincontext,"W3GetW3Revision")){
			ERR("fail");
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
		//cout<<invoker->Invoke(&result)<<endl;
		//cout<<ret<<endl;
		//cout<<result<<endl;

		//delete invoker;





		}


		//cout<<ret<<endl;
		//cout<<result<<endl;



		  sem_callfin->Signal();
		 // pHandle->
	 }



 } 
 void MyThread::OnTerminate 	( 	IThreadHandle *  	pHandle,		bool  	cancel	 	) { META_CONPRINTF("THREAD TERMINATE cancel:%d\n",cancel);}
