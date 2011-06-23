#include "extension.h"

typedef void (*funcpointer)(void); //of void return and no args
///use funcpointer variable= blah

class MyTimer:
	public IThread
{
public:
	void AddTimer(funcpointer func,int milisecondInterval){
		myvector.push_back(func);
		myvectornexttick.push_back((long int)timersys->GetTickedTime()*1000+ milisecondInterval);
		myvectorinterval.push_back( milisecondInterval);
	}
	MyTimer(){
		threader->MakeThread(this);
	}
private:

	vector<funcpointer> myvector;
	vector<long int> myvectornexttick;
	vector<long int> myvectorinterval;

	void RunThread 	( 	IThreadHandle *  	pHandle 	 ) {
		while(1){
			threader->ThreadSleep(100);
			int size=myvector.size();
			if(size>0){
				float min=timersys->GetTickedTime()*1000;
				int minindex=-1;
				for(int i=0;i<size;i++){
					if(myvectornexttick.at(i)<min){
						min=myvectornexttick.at(i);
						minindex=i;
					}
				}
				if(minindex>=0){
					int nexttick=myvectornexttick.at(minindex)+myvectorinterval.at(minindex);

					myvectornexttick.at(minindex)=nexttick;

					funcpointer addr=(funcpointer)(myvector.at(minindex));
					addr();
				}
			}
		}
	}
	void OnTerminate 	( 	IThreadHandle *  	pHandle,		bool  	cancel	 	) {}
};


