<?php

	include("header.php");
	
	$steamid=$_GET['steamid'];
	$name=$_GET['name'];
	$hostname=$_GET['hostname'];
	$ipport=$_GET['ipport'];
	$totallevels=$_GET['totallevels'];
	

	
	$query="INSERT  INTO playerinfoperserver SET ";
	$query.="steamid='$steamid' ,";
	$query.="name='$name' ,";
	$query.="hostname='$hostname' ,";
	$query.="ipport='$ipport' ,";
	$query.="totallevels='$totallevels' ";
	$query.="ON DUPLICATE KEY UPDATE ";
	$query.="name='$name' ,";
	$query.="hostname='$hostname' ,";
	$query.="ipport='$ipport' ,";
	$query.="totallevels='$totallevels' ";
	
	$result=mysql_query  ($query);
	if (!$result) {	    die('Invalid query: ' . mysql_error());  }
	
	$query="INSERT  INTO playerinfounique SET ";
	$query.="steamid='$steamid' ,";
	$query.="name='$name' ,";
	$query.="lastserverhostname='$hostname' ,";
	$query.="lastserveripport='$ipport' ";
	$query.="ON DUPLICATE KEY UPDATE "; 
	$query.="name='$name' ,";
	$query.="lastserverhostname='$hostname' ,";
	$query.="lastserveripport='$ipport' ";
	
	
	$result=mysql_query  ($query);
	if (!$result) {	    die('Invalid query: ' . mysql_error());  }
	
	
	
	
	
	
	echo "playerinfo success";
?>