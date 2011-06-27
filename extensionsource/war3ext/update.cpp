
		//try out our downloader
	IWebTransfer *foo=((IWebternet*)g->sminterfaceIWebternet)->CreateSession();
	using namespace std;
	string original=""; //auto delete when thread dies
	char buf[2000];
	
	FORMAT(buf,1000,"http://ownageclan.com/war3source/updater/filelist.txt");
	foo->Download(buf,&war3_ext,&original); //blocking
	delete foo;
	
	cout<<original<<endl;

	using namespace std;
	ofstream myfile;
	g_pSM->BuildPath(Path_SM, path, sizeof(path), "filelist.txt");
	myfile.open (path);
	myfile << original;
	myfile.close();

	/*size_t end=0;
	int begin=0;
	cout<<" "<<endl;
	while(1){
		end=original.find("\n",end);
		if(end==string::npos){
			if(original.length()>1){
				end=original.length()-1;
			}
			else{
				break;
			}

		}

		string line=original.substr ( begin, end+1 ) ;

		original=original.substr(end+1);
		
		cout<<"line:"<<line<<endl;
		//cout<<"original:"<<original<<endl;
		}*/
	

	string cleaned=replacestr(original,string("\r"),string(""));

	string delimiter="\n";
	vector<string> exploded;
	explode(exploded,cleaned,delimiter);

	for(int i=0;i<(int)exploded.size();i++){
		cout<<"'"<<exploded.at(i)<<";"<<endl;
		updatefile(exploded.at(i));
	}

