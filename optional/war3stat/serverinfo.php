<?php
	require_once("funcaggregateplayercount.php");
	//include("header.php");
	//$db=mysql_pconnect  ("<SERVER_OMITTED>", "<USERNAME_OMITTED>",  "<PASSWORD_OMITTED>" );
	//if(!$db) die("Could not connect to mysql db. ". mysql_error());

	//mysql_select_db("<USERNAME_OMITTED>",$db) ;
	//$hostname=mysql_real_escape_string($_REQUEST['hostname']); escaped in header
	
	$remoteip=$_SERVER['REMOTE_ADDR'];
	
	
	$version=$_REQUEST['version'];
	$game=$_REQUEST['game'];
	$map=$_REQUEST['map'];
	$players=$_REQUEST['players'];
	$maxplayers=$_REQUEST['maxplayers'];
	
	$ip=$_REQUEST['ip'];
	if(!$ip){
		$ip=$_SERVER['REMOTE_ADDR'];//
	}
	$arr=explode(":",$ip);
	$port=":00000"; //already has colon
	if(count($arr)==2){
		$port=":".$arr[1]; //get port
		$iponly=$arr[0];
	}
	else{
		$iponly=$remoteip;
	}
	
	function is_private_ip($ip) {
	    if (empty($ip) or !ip2long($ip)) {
		return NULL;
	    }
	 
	    $private_ips = array (
		array('10.0.0.0','10.255.255.255'),
		array('172.16.0.0','172.31.255.255'),
		array('192.168.0.0','192.168.255.255')
	    );
	 
	    $ip = ip2long($ip);
	    foreach ($private_ips as $ipr) {
		$min = ip2long($ipr[0]);
		$max = ip2long($ipr[1]);
		if (($ip >= $min) && ($ip <= $max)) return true;
	    }
	 
	    return false;
	}
	if(is_private_ip($iponly)||$iponly=="0.0.0.0"){
		$ip=$remoteip.$port;
	}
	
	
	
	///serverinfo and
 	//aggregate players is in funcaggregateplayrecount.php 
 	
 	
 	//this var is from header.php
 	//echo "tries ".$tries;
 	if($tries==-1 || false){ //we didnt retry, so we can sleep , otherwise there is congestion, don't wait
		
		$result=OCmysql_query("SELECT wvalue FROM kv  WHERE wkey='congestion' AND wvalue < NOW() - INTERVAL 1 SECOND ");
		//echo "rows ".mysql_num_rows($result);
		if(mysql_num_rows($result)){
			//usleep(1000000);
			//echo "sleep";
		}
	}
	
	
	
	
	
	
		OCmysql_query("INSERT INTO serverinfo SET ip='$ip', timestamp_firstseen=NOW() ON DUPLICATE KEY UPDATE timestamp=NOW(), remoteip='$remoteip' , hostname='$hostname',version='$version',game='$game',map='$map',players='$players',maxplayers='$maxplayers',	fromext='0' , postdata='".mysql_real_escape_string("HEADER:::: ".json_encode(getallheaders())." \$_REQUEST:::: ".json_encode($_REQUEST))."'");  
	


	
	
	
	
	
	$querystring="UPDATE kv SET wvalue=NOW()       WHERE wkey='now'";
	$result=mysql_query($querystring); 
	if(!$result){WriteErrorToDB (mysql_error(),$querystring); }
	
	$querystring="UPDATE kv SET wvalue=NOW()+ INTERVAL 1 MINUTE       WHERE wkey='lastcron' AND  wvalue < NOW()- INTERVAL 1 SECOND";
	$result=mysql_query($querystring); 
	if(!$result){WriteErrorToDB (mysql_error(),$querystring); }
	
	if(mysql_affected_rows()>0)
	{
		exec("php /var/www/html/w3stat/cron.php –wkey lastcron > /dev/null 2>&1 &");
	}
	else{
		$querystring="UPDATE kv SET wvalue=NOW()+ INTERVAL 1 MINUTE       WHERE wkey='lastcron2' AND  wvalue < NOW()- INTERVAL 1 SECOND";
		$result=mysql_query($querystring); 
		if(!$result){WriteErrorToDB (mysql_error(),$querystring); }
		
		if(mysql_affected_rows()>0)
		{
			exec("php /var/www/html/w3stat/cron.php –wkey lastcron2 > /dev/null 2>&1 &");
		}
	}
 
	echo "success serverinfo"; // .mysql_real_escape_string(json_encode(getallheaders()))  ;
?>