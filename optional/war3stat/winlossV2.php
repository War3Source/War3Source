<?php

	include("header.php");

	mysql_select_db("<USERNAME_OMITTED>",$db) ;
	$steamid=$_GET['steamid'];
	$raceshort=$_GET['raceshort'];
	$ip=$_GET['ip'];
	$game=$_GET['game'];
	$win=$_GET['win'];
	$clientteam=$_GET['clientteam'];
	$lvl=$_GET['lvl'];
	
	$result=OCmysql_query  ("SELECT * FROM disabledservers WHERE ipport='$ip' and nostats='1' ");
	if(mysql_num_rows($result)){
		die( "success winloss disabled");
	}
	
	  
	$query="INSERT INTO racedataeventsv2 SET steamid='$steamid' , raceshort='$raceshort' , ipport='$ip' , game='$game' , event='winloss',data1='$win'";
	$result=mysql_query  ($query);
	if (!$result) {	    die('Invalid query: ' . mysql_error());  }
	
	$query="INSERT INTO recentwins SET steamid='$steamid' , raceshort='$raceshort' , ip='$ip' , game='$game' , win='$win', clientteam='$clientteam' , lvl='$lvl'";
	$result=mysql_query  ($query);
	if (!$result) {	    die('Invalid query: ' . mysql_error());  }
	
	
	$query="INSERT INTO agg_racekill_day SET raceshort='$raceshort', date=CURDATE()  ON DUPLICATE KEY UPDATE ";
	if(strcmp ( $win , "1" )==0){
		$query.="win=win+1";
	}
	else{
		$query.="loss=loss+1";
	}
	$result=mysql_query  ($query);
	if (!$result) {	    die('Invalid query: ' . mysql_error());  }
	
	
	echo "winloss success";
?>