
#include "war3dll.h"
using namespace std;

DownloadHelper::DownloadHelper(){ //constructor
	result="";
}

DownloadHelper::~DownloadHelper(){
}
string DownloadHelper::GetHTTP(){
	return result;
}
//using namespace SourceMod;
//itransferhandler
DownloadWriteStatus DownloadHelper::OnDownloadWrite(IWebTransfer *session,
                               void *userdata,
                              void *rcvddataptr,
                               size_t size,
                              size_t nmemb)
{

	result.append((char*)rcvddataptr,nmemb);
	return DownloadWrite_Okay;//DownloadWrite_Error;;
}
	


