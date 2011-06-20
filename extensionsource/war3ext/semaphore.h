#ifndef __SEMPAHOREHEADER
#define __SEMPAHOREHEADER
class Semaphore
{
	int count;
	IMutex *mutexwait;
	IMutex *mutexsignal;

public:

	Semaphore(int uicount=1);
	void Wait();
	void Signal();
	bool WaitNoBlock();
};
#endif
