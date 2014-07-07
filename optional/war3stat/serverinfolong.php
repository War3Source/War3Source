<?php
	include("header.php");
	//$db=mysql_pconnect  ("<SERVER_OMITTED>", "<USERNAME_OMITTED>",  "<PASSWORD_OMITTED>" );
	//if(!$db) die("Could not connect to mysql db. ". mysql_error());

	//mysql_select_db("<USERNAME_OMITTED>",$db) ;
	
	$ip=mysql_real_escape_string ($_REQUEST['ip']);
	$races=mysql_real_escape_string ($_REQUEST['races']);
	$config=mysql_real_escape_string ($_REQUEST['config']);
	$items=mysql_real_escape_string ($_REQUEST['items']);

	$query="UPDATE serverinfo SET ";
	$needcomma=false;
	
	$hasinfotoupdate=false;
	if(strlen($config)){
		$query.=" config='$config' ";
		$needcomma=true;
		$hasinfotoupdate=true;
	}
	if(strlen($races)){
		if($needcomma){
			$query.=" , ";
		}
		$query.=" races='$races' ";
		$needcomma=true;
		$hasinfotoupdate=true;
	}
	if(strlen($items)){
		if($needcomma){
			$query.=" , ";
		}
		$query.=" items='$items' ";
		$hasinfotoupdate=true;
	}
	$query.=" WHERE ip='$ip' ";
	
	
	$queryclean="UPDATE serverinfo SET races='pending' , config='pending' , items='pending' postdatelong='".mysql_real_escape_string("HEADER:::: ".json_encode(getallheaders())." WHERE ip='$ip' ";
	//ACTUAL QUERY
	OCmysql_query($queryclean);
	
	if(!$hasinfotoupdate){
		WriteErrorToDB ("no info to update  $races $config $items $ip",$query);
		die("no info to update $races $config $items $ip");
	}
	
	//ACTUAL QUERY
	$result=OCmysql_query($query); 
	
	if(mysql_affected_rows ()==0){
		WriteErrorToDB ("ERR NO AFFECTED ROWS  $races $config $items $ip",$query);
	}
	
	echo "success serverinfolong";
?>