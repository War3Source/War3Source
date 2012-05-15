#include "extension.h"

struct TimerEntry{
	funcpointer func;
	bool repeat;
	long int nexttick;
	long int interval;
};
class MyTimer:
	public IThread,
	public IMyTimer
{
public:
	void AddTimer(funcpointer tfunc,int milisecondInterval,bool trepeat){
		TimerEntry *te=new TimerEntry;
		te->func=tfunc;
		te->repeat=trepeat;
		te->nexttick=(long int)timersys->GetTickedTime()*1000+ milisecondInterval;
		te->interval=milisecondInterval;
		myvector.push_back(te);

	}
	MyTimer(){
		threader->MakeThread(this);
	}
private:

	vector<TimerEntry*> myvector;

	void RunThread 	( 	IThreadHandle *  	pHandle 	 ) {
		while(1){
			static int sleeptime=100;
			threader->ThreadSleep(sleeptime);
			int size=myvector.size();
			if(size>0){
				int readycount=0;

				float min=timersys->GetTickedTime()*1000;
				//ERR("%f",min);
				int minindex=-1;
				for(int i=0;i<size;i++){
					TimerEntry *te=myvector.at(i);
					if(te->nexttick<min){
						min=(float)te->nexttick;
						minindex=i;
						readycount++;
					}
				}
				if(minindex>=0){
					TimerEntry *te=myvector.at(minindex);
					te->nexttick=te->nexttick+te->interval;

					funcpointer addr=(funcpointer)(te->func);
					addr(); //invoke func

					if(!te->repeat){
						delete myvector.at(minindex);
						myvector.erase(myvector.begin()+minindex);
					}
				}
				sleeptime=(readycount>1)?100:10;
			}
			else{
				sleeptime=100;
			}
		}
	}
	void OnTerminate 	( 	IThreadHandle *  	pHandle,		bool  	cancel	 	) {}
};


