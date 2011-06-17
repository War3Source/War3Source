
		//try out our downloader
	IWebTransfer *foo=((IWebternet*)sminterfaceIWebternet)->CreateSession();
	using namespace std;
	string wtf=""; //auto delete when thread dies
	char buf[2000];
	
	FORMAT(buf,1000,"http://ownageclan.com/war3source/updater/filelist.txt");
	foo->Download(buf,&war3_ext,&wtf); //blocking
	delete foo;
	
	//cout<<wtf<<endl;

	using namespace std;
	ofstream myfile;
	g_pSM->BuildPath(Path_SM, path, sizeof(path), "filelist.txt");
	myfile.open (path);
	myfile << wtf;
	myfile.close();

	/*size_t end=0;
	int begin=0;
	cout<<" "<<endl;
	while(1){
		end=wtf.find("\n",end);
		if(end==string::npos){
			if(wtf.length()>1){
				end=wtf.length()-1;
			}
			else{
				break;
			}

		}

		string line=wtf.substr ( begin, end+1 ) ;

		wtf=wtf.substr(end+1);
		
		cout<<"line:"<<line<<endl;
		//cout<<"wtf:"<<wtf<<endl;
		}*/
	string delimiter="\n";
	vector<string> exploded;
	exploded=explode(delimiter,wtf);

	for(int i=0;i<(int)exploded.size();i++){
		//cout<<exploded.at(i)<<endl;
		updatefile(exploded.at(i));
	}

