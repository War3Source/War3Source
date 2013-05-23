<?php

	include("headernolim.php");
	
	$steamid=$_GET['steamid'];
	$name=$_GET['name'];
	$clientip=$_GET['clientip'];
	$hostname=$_GET['hostname'];
	$ipport=$_GET['ipport'];
	$version=$_GET['version'];
	$reportstr=$_GET['reportstr'];

	mysql_query ("SET NAMES 'utf8'");
	$query="INSERT INTO w3bugreport SET steamid='$steamid' ,name='$name'  , clientip='$clientip', hostname='$hostname',serverip='$ipport' ,version='$version' ,reportstring='$reportstr'";	
	$result=mysql_query  ($query);
	if (!$result) {	    die('Invalid query: ' . mysql_error());  }
	
	
	echo "success bugreport";
?>