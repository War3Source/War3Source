#include "extension.h"
#include <string>
#include <iostream>
#include <algorithm>
void updatefile(string file){
	for(int breakme=0;breakme<1;breakme++){
	int pos=file.find('\n');
	if(pos!=(int)string::npos){
		file.erase ( pos, 1);
		//cout<<"FOUND slashN"<<endl;
	}
	pos=file.find('\r');
	if(pos!=(int)string::npos){
		file.erase ( pos, 1);
		//cout<<"FOUND slashR"<<endl;
	}
	if(file.length()<1){
		break;
	}
	//char damnfile[2000];
	//FORMAT(damnfile,sizeof(damnfile),"%s",file.c_str());
	//
	//for(int i=0;i<sizeof(damnfile);i++){
	//	if(damnfile[i]=='\0'){break;}
//
	//	if(damnfile[i]=='\n'){
	//		damnfile[i]='\0';
	//		break;
	//	}
	//}


	char filepath[3000];
	IWebTransfer *foo=((IWebternet*)g->sminterfaceIWebternet)->CreateSession();
	using namespace std;
	string wtf=""; //auto delete when thread dies
	char urlpath[3000];
	
	FORMAT( urlpath,1000,"http://ownageclan.com/war3source/updater/%s",file.c_str());
	//cout<<buf<<endl;
	if(!foo->Download(urlpath,&war3_ext,&wtf)){ //blocking
		cout<<"Failed to download "<<urlpath<<endl;
		delete foo;
		break;
	}
	delete foo;
	
	//cout<<wtf<<endl;

	using namespace std;
	g_pSM->BuildPath(Path_SM, filepath, sizeof(filepath), file.c_str());
	//cout<<filepath<<endl;
	ofstream myfile;
	
	myfile.open (filepath);
	if(myfile.good()){
		//cout<<"write: to file "<<filepath<<endl<<wtf<<endl;
		myfile << wtf;
		myfile.flush();
		myfile.close();
	}
	else{
		
		cout<<"zopen"<<filepath<<"zerror\n";
		 cout << "\nfile = " << myfile;  
   cout << "\nError state = " <<myfile.rdstate();  
   cout << "\ngood() = " << myfile.good();  
   cout << "\neof() = " << myfile.eof();  
   cout << "\nfail() = " << myfile.fail();  
   cout << "\nbad() = " << myfile.bad() << endl;  
	}
	
	} //breakme loop
}
