#include "war3dll.h"

static bool alreadycreated=false;
extern void giveDiamondsTick();
//DO NOT CREATE UNTIL TIMER SYS IS UP
MyDiamondGiver::MyDiamondGiver()
{
	if(!alreadycreated){
		timersys->CreateTimer(this,60.0f,NULL,TIMER_FLAG_REPEAT);
		alreadycreated=true;
	}
	else{
		ERR("Diamond giver already created");
	}
}


ResultType MyDiamondGiver::OnTimer(ITimer *pTimer, void *pData){
	giveDiamondsTick();
	return Pl_Continue; //no result
}
void MyDiamondGiver::OnTimerEnd(ITimer *pTimer, void *pData){

}
