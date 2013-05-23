<?php
	include("funcaggregateplayercount.php");
	//include("header.php");
	//$db=mysql_pconnect  ("<SERVER_OMITTED>", "<USERNAME_OMITTED>",  "<PASSWORD_OMITTED>" );
	//if(!$db) die("Could not connect to mysql db. ". mysql_error());

	$remoteip=$_SERVER['REMOTE_ADDR'];

	//mysql_select_db("<USERNAME_OMITTED>",$db) ;
	//$hostname=mysql_real_escape_string($_REQUEST['hostname']); escaped in header
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
		
		$iponly=$arr[0];
		$port=":".$arr[1]; //get port
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
	$remoteip=$remoteip.$port;
//	$querystring="SELECT * FROM serverinfo WHERE ip LIKE '$ip' AND timestamp > NOW() - INTERVAL 10 MINUTE";
//	$result=OCmysql_query($querystring); 
//	$rowsreturned=mysql_num_rows($result);

//	if($rowsreturned==0){
		OCmysql_query("INSERT INTO serverinfo SET ip='$ip', timestamp_firstseen=NOW() ON DUPLICATE KEY UPDATE timestamp=NOW(), remoteip='$remoteip' , hostname='$hostname',version='$version',game='$game',map='$map',players='$players',maxplayers='$maxplayers',	fromext='1' , postdataext='".mysql_real_escape_string("HEADER:::: ".json_encode(getallheaders())." \$_REQUEST::serverinfoext.php:: ".json_encode($_REQUEST))."'");  
		
//	}
	//aggregate players is in funcaggregateplayrecount.php 

	echo "success serverinfoext";
	echo json_encode($_REQUEST)."INSERT INTO serverinfo SET ip='$ip', timestamp_firstseen=NOW() ON DUPLICATE KEY UPDATE timestamp=NOW(), remoteip='$remoteip' , hostname='$hostname',version='$version',game='$game',map='$map',players='$players',maxplayers='$maxplayers',	fromext='1' ";
?>