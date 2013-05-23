<?php

	include("headernolim.php");
	
	$racename=$_GET['racename'];
	$raceshort=$_GET['raceshort'];
	
	
	if(strlen($racename)>1){
		$query="INSERT INTO racesv2 SET  racename='$racename' , raceshort='$raceshort' ON DUPLICATE KEY UPDATE racename='$racename' , timestamp=NOW()";
	}
	else{
		$query="INSERT IGNORE INTO racesv2 SET  raceshort='$raceshort' , timestamp=NOW()";
	}
	
	$result=mysql_query  ($query);
	if (!$result) {	    die('Invalid query: ' . mysql_error());  }
	
	
	
	
	
	
	echo "success raceinsert";
?>