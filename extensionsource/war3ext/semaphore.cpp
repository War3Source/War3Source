
#include "extension.h"

/*
why is a binary semaphore not enough? well we need to keep counts thats all...
consider this situation:
threads must execute in a specific location in a script, and synchrounously, such as OnTimer,
because we have to make sure no other functions are being called into the sourcepawn plugins.

In the timer callback, it will allow these threads to execute by giving a ticket, where one of the threads is allowed to execute.
"synchrounously" requirement means that the threads must complete and the main OnTimer thread must wait for these threads.
multiple threads can execute simutaneously, but OnTimer must wait for them to complete.

How does the OnTimer thread know when BOTH threads have completed?
Answer: wait on two semaphores, or wait two times on a counting semaphore.
What if we want 6 threads to execute simutaneously? wait on 6 semaphores or wait 6 times on the counting semaphore.
The counting semaphore allows scaling without more binary semaphores.

How does the OnTimer handler know there are 6 threads ready to execute? what if there is only 1 ready to execute?
Answer: semaphore for each thread, or a counting semphore! it can issue 6 or less tickets depending on the count of the semaphore.

How does each thread tell the handler that it is ready to execute?
Answer: semaphore as a flag for each thread, or a counting semaphore so the handler can give an exact amount of tickets.
*/




Semaphore::Semaphore( int tcount): count(tcount){ //c++ initialization list

	mutexwait=threader->MakeMutex();

	mutexsignal=threader->MakeMutex();
	mutexsignal->Lock();

	mutexwait2=threader->MakeMutex();

	mysem=threader->MakeEventSignal();

}
void Semaphore::Wait(){
    ERR("mutexwait2");
    mutexwait2->Lock(); //to prevent count from decremented below -1
    ERR("mutexwait");
	mutexwait->Lock();


	//cout<<count<<"|";;
	count--; //count may go negative signally people are waiting (blocking) so we should use Signal internally when signalling
	if(count>0){
        //do nothing, we already did decrement
        mutexwait2->Unlock();
		mutexwait->Unlock();

	}
	else{ //crap, it is now -1 or less, we must wait for a signal when someone releases

		mutexwait->Unlock();

		mutexsignal->Lock(); //when someone releases, this will be unlocked
        mutexwait2->Unlock();
	}

}
void Semaphore::Signal(){
    ERR("mutexwait release");
	mutexwait->Lock();
	count++;
	if(count<1){ //originally was -1 or less, that means some is doing the wait

		mutexsignal->Unlock(); //unlock retains its unlcoked state

	}
	mutexwait->Unlock();

}
bool Semaphore::WaitNoBlock(){
    ERR("mutexwait noblock");
	mutexwait->Lock();
	bool returnvalue=false;
	if(count>0){
		count--;
		returnvalue=true;
	}
	mutexwait->Unlock();
	return returnvalue;
}
