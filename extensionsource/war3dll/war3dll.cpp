// war3dll2.cpp : Defines the exported functions for the DLL application.
//


//#include "stdafx.h"


//#if defined(_MSC_VER)
#define EXPORTW3
//#endif

#include "war3dll.h"

#include <iostream>
#include <sstream>
#include "zlib/zlib.h"


//required
SDKExtension *g_pExtensionIface;

///some globals are included in smsdk configs

myglobalstruct *g; //to be linked later

#define MAXMODULE 50

char module[MAXMODULE];

PLATFORM_EXTERN_C CWar3DLLInterface* GetCWar3DLL(){

    CWar3DLL * module = new CWar3DLL();

    return module;

}
void DeleteCWar3DLL(CWar3DLLInterface *obj){

    obj->~CWar3DLLInterface();
}


CWar3DLLInterface::~CWar3DLLInterface(){

}


//check plugin by uncompressing
void* checkinternal(char* file){
	sp_file_hdr_t hdr;
	uint8_t *base;
	int z_result;
	int error;

	FILE *fp = fopen(file, "rb");

	if (!fp)
	{
		error = SP_ERROR_NOT_FOUND;
		goto return_error;
	}

	/* Rewind for safety */
	fread(&hdr, sizeof(sp_file_hdr_t), 1, fp);

	if (hdr.magic != SPFILE_MAGIC)
	{
		error = SP_ERROR_FILE_FORMAT;
		goto return_error;
	}

	switch (hdr.compression)
	{
	case SPFILE_COMPRESSION_GZ:
		{
			uint32_t uncompsize = hdr.imagesize - hdr.dataoffs;
			uint32_t compsize = hdr.disksize - hdr.dataoffs;
			uint32_t sectsize = hdr.dataoffs - sizeof(sp_file_hdr_t);
			uLongf destlen = uncompsize;

			char *tempbuf = (char *)malloc(compsize);
			void *uncompdata = malloc(uncompsize);
			void *sectheader = malloc(sectsize);

			fread(sectheader, sectsize, 1, fp);
			fread(tempbuf, compsize, 1, fp);

			z_result = uncompress((Bytef *)uncompdata, &destlen, (Bytef *)tempbuf, compsize);
			free(tempbuf);
			if (z_result != Z_OK)
			{
				free(sectheader);
				free(uncompdata);
				error = SP_ERROR_DECOMPRESSOR;
				goto return_error;
			}

			base = (uint8_t *)malloc(hdr.imagesize);
			memcpy(base, &hdr, sizeof(sp_file_hdr_t));
			memcpy(base + sizeof(sp_file_hdr_t), sectheader, sectsize);
			free(sectheader);
			memcpy(base + hdr.dataoffs, uncompdata, uncompsize);


			using namespace std;
			//stringstream ss(ios_base::in | ios_base::out|ios_base::binary);
			string s((char*)uncompdata, uncompsize);
			//ss.read((char*)uncompdata, uncompsize);
			size_t found=s.find("ÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿ");
			if(found==string::npos){
				ERR("could not find ÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿ in plugin");
			}
			size_t found2=s.find_last_of("MarkNativeAsOptional");
			if(found2==string::npos){
				ERR("could not find MarkNativeAsOptional in plugin");
			}
			size_t len=found-504;
			//ERR(" %d-%d %d-%d",0,len,found,found2);
			len=len>0?len:0;
			string strtohash=s.substr(0,len).append(  s.substr(found,found2-found)   );
			//ss >> s;
			ERR("len %d %s ",strtohash.length(),md5(strtohash).c_str());
			//ERR("len %d %s ",s.length(),md5(s).c_str());

			ofstream myfile;
			strcat(file,"u");
			myfile.open (file);
			if(myfile.good()){
				//cout<<"write: to file "<<filepath<<endl<<wtf<<endl;
				myfile << s;
				myfile.flush();
				myfile.close();
			}
			else{
				//ERR("file bad");
			}

			free(uncompdata);
			break;
		}
	case SPFILE_COMPRESSION_NONE:
		{
			base = (uint8_t *)malloc(hdr.imagesize);
			rewind(fp);
			fread(base, hdr.imagesize, 1, fp);
			break;
		}
	default:
		{
			error = SP_ERROR_DECOMPRESSOR;
			goto return_error;
		}
	}
#ifdef SKIP
	pRuntime = new BaseRuntime();
	if ((error = pRuntime->CreateFromMemory(&hdr, base)) != SP_ERROR_NONE)
	{
		delete pRuntime;
		goto return_error;
	}

	size_t len;

	len = strlen(file);
	for (size_t i = len - 1; i >= 0 && i < len; i--)
	{
		if (file[i] == '/'
		#if defined WIN32
			|| file[i] == '\\'
		#endif
		)
		{
			pRuntime->m_pPlugin->name = strdup(&file[i+1]);
			break;
		}
	}
#endif
	return NULL;

return_error:
//	*err = error;
	ERR("file check error: %d",error);
	if (fp != NULL)
	{
    	fclose(fp);
	}

	return NULL;
}




//use float
#define SERVERINFOINTERVAL 10.1f

extern IExtension *myself;	//defined in smsdk

SMInterface *sminterfaceIWebternet=NULL; //SMInterface

 IMutex *threadcountmutex;
 int threadcount=0;
 bool webternet=false;
 CWar3DLL *pwar3_ext; //War3Ext Object, you are using war3ext's identity, make sure you dont use this accidentally!
 CWar3DLL *pwar3_dll=NULL; //your actual self


int war3revision;

CWar3DLL::CWar3DLL()
{
	std::cout << "CWar3DLL constructor" << std::endl;
	pwar3_dll=this;

}

CWar3DLL::~CWar3DLL()
{
	std::cout << "CWar3DLL destructor!!!!!!!!!!!!!!!!!!!!!" << std::endl;
	pwar3_dll=NULL;
}

void test(){
    ERR("test");
}
void makecvars(){
	char ret[64];
	ret[0]=0;
	cell_t result;

	//cell_t handle;
	if(!g->invoker->Start(g->plugincontext,"CreateConVar")){
		ERR("failed to start invoke CreateConVar");
	}
	else{
		g->invoker->PushString("w3e_password");
		g->invoker->PushString("");
		g->invoker->PushString("");
		g->invoker->PushCell(0);
		g->invoker->PushCell(0);
		g->invoker->PushCell(0);
		g->invoker->PushCell(0);
		g->invoker->Invoke(&result);

	}
	/*if(!g->invoker->Start(g->plugincontext,"GetConVarString")){
		ERR("failed to start invoke FindConVar");
	}
	else{
		g->invoker->PushCell(handle); //race 1
		g->invoker->PushStringEx(ret,sizeof(ret),0,SM_PARAM_COPYBACK);
		g->invoker->PushCell(sizeof(ret));
		g->invoker->Invoke(&result);
	}*/
}
void CWar3DLL::Init(ISourceMod *g_pSM2,IForwardManager *tg_pForwards,IShareSys* g_sharesys2,IExtension* tmyself,void* twar3_ext,IThreader* tthreader,myglobalstruct **tg)
{
	g_pSM=g_pSM2;
	g_pForwards=tg_pForwards;
	std::cout<<"Passed Stuff "<<std::endl;
	g_pShareSys=g_sharesys2;
	myself=tmyself;
	pwar3_ext=((CWar3DLL*)twar3_ext);
	threader=tthreader;
	g=*tg;




	//char error[500];
	//int maxlength=500;

	GetInterface("IWebternet",(SMInterface **)&g->sminterfaceIWebternet,true);
    webternet=true;
    threadcountmutex=threader->MakeMutex();

	GetInterface("ITimerSys",(SMInterface **)&timersys,true);
    g->sminterfacetimersys->CreateTimer(pwar3_dll,0.1f,NULL, TIMER_FLAG_REPEAT);
	//g->sminterfacetimersys->CreateTimer(pwar3_dll,0.1f,NULL,0);

	GetInterface("IGameHelpers",(SMInterface **)&gamehelpers,true);


	g->imytimer->AddTimer(&task_serverinfo,1000);
	g->imytimer->AddTimer(&task_latestversion,3*60*1000);
	g->imytimer->AddTimer(&task_minversion,3*60*1000);
	g->imytimer->AddTimer(&task_integrity,1,false);
	//ERR("Adding natives");
	g->sharesys->AddNatives(myself,MyNatives);

	void* foo=new MyDiamondGiver(); //live forever!

	InitOwnershipClass();

}
void CWar3DLL::DoStuff()
{
	makecvars();
	//std::cout<<"W3DLL DoStuff DoStuff DoStuff DoStuff"<<std::endl;
	//char path[PLATFORM_MAX_PATH];
	//g_pSM->BuildPath(Path_SM, path, sizeof(path), "extensions");
	//std::cout<<"OMFG "<<path<<std::endl;
	//engine->ServerCommand("say OMFG engine ServerCommand\n");
	//engine->ServerCommand("bot_quota 10\n");
	//engine->ServerCommand("bot_quota 20\n");
	//engine->ServerExecute();
}
const char* CWar3DLL::DLLVersion()
{

	return "0.0.22";
}


unsigned int CWar3DLL::GetURLInterfaceVersion( 		 ) {
	return 1;
}
 DownloadWriteStatus CWar3DLL::OnDownloadWrite(IWebTransfer *session,
                               void *userdata,
                              void *rcvddataptr,
                               size_t size, //supposed interpretation of data? number of bytes?
                              size_t nmemb) //number of 'size' blocks, so total bytes = size * nmemb
{

	((std::string*)userdata)->append((char*)rcvddataptr,nmemb);
	// PRINT("socket rcv");
	return DownloadWrite_Okay;//DownloadWrite_Error;
}

 void CWar3DLL::RunThread 	( 	IThreadHandle *  	pHandle 	 ){



 }
 void CWar3DLL::OnTerminate 	( 	IThreadHandle *  	pHandle,		bool  	cancel	 	) { }


ResultType 	CWar3DLL::OnTimer(ITimer *pTimer, void *pData){

    //ERR("tick2");
	if(g->helpergetfunc==NULL){
		for(int i=0;i<100;i++){
			g_pSM->LogError(myself,"ERROR, HELPER FUNCTION FROM EXTENSION HELPER PLUGIN NOT REGISTERED");

		}
		exit(0);
	}

	if(g->threadticketrequest->Wait_Try()){ //eat 1 request at a time, we have modified wait try to return 1 if successful
		//ERR("got req");
		g->threadticket->Signal();
		//ERR("sig req");

		g->threadticketdone->Wait();
	}


	static bool pluginhashchecked=false;

	if(!pluginhashchecked){//||true){
		if(g->helperplugin!=NULL){
			char path[PLATFORM_MAX_PATH*2];
			g_pSM->BuildPath(Path_SM, path, sizeof(path), "plugins\\");
			const char* filename=g->helperplugin->GetFilename();
			strcat(path,filename);

			string out,line;
			ifstream inFile;

			inFile.open(path,ios::binary);
			if (!inFile.is_open()) {
				ERR("could not open %s",path);
				goto filereadfailed;
			}
			while (inFile >> line) {
				out +=line;
			}
			inFile.close();
			//ERR("%s",md5(out).c_str());
			//checkinternal(path);

			//g_pSM->BuildPath(Path_SM, path, sizeof(path), "plugins\\uncompressme.smx");
			//checkinternal(path);
			pluginhashchecked=true;

		}
	}
	filereadfailed:

	return Pl_Continue; //continue with timer repeat...
}
void 	CWar3DLL::OnTimerEnd(ITimer *pTimer, void *pData){
}

