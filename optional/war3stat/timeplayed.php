<?php

	include("header.php");

	mysql_select_db("<USERNAME_OMITTED>",$db) ;
	$steamid=@$_GET['steamid'];
	$raceshort=@$_GET['raceshort'];
	$ip=@$_GET['ip'];
	$data1=@$_GET['data1'];
	$data2=@$_GET['data2'];
	$level=@$_GET['level'];
	$game=@$_GET['game'];
	
	$result=OCmysql_query  ("SELECT * FROM disabledservers WHERE ipport='$ip' and nostats='1' ");
	if(mysql_num_rows($result)){
		die( "success stats disabled for this server");
	}
	
	///event log
	OCmysql_query  ("INSERT INTO racedataeventsv2 SET steamid='$steamid' , raceshort='$raceshort' , ipport='$ip' , event='timeplayed' , data1='$data1' , data2='$data2' , killerlvl='$level'  , processed='1'"); 

	//event log
	OCmysql_query  ("INSERT INTO timeplayedlog SET steamid='$steamid' , game='$game', raceshort='$raceshort' ,  lvl='$level' , ipport='$ip' "); 

		/////////////////
	$query="INSERT INTO perplayerraceplaytimelongv2 SET steamid='$steamid' , raceshort='$raceshort'  ON DUPLICATE KEY UPDATE ";
	if(strcmp($data2,"alive")==0){
		$query.=" timealive=timealive+1";
	}
	else{
		$query.=" timedead=timedead+1";
	}
	OCmysql_query($query); 
	
	///////////
	$query="UPDATE playerinfoperserver SET timeplayed=timeplayed+1 WHERE steamid='$steamid'  AND ipport='$ip'";
	OCmysql_query ($query); 
	
	////////////////
	$query="UPDATE agg_racekill_day SET ";
	if(strcmp($data2,"alive")==0){
		$query.=" timeplayed=timeplayed+1 ";
	}
	else{
		$query.=" timeplayed_dead=timeplayed_dead+1 ";
	}
	$query.=" WHERE raceshort='$raceshort'  AND date=CURDATE()";
	OCmysql_query  ($query); 
	
	//////////////////
	$query="INSERT INTO playerinfoperday SET steamid='$steamid' , date=CURDATE() ON DUPLICATE KEY UPDATE timeplayed=timeplayed+1 ";
	OCmysql_query($query); 
	
	$query="INSERT INTO timeplayed_day SET date=CURDATE() ON DUPLICATE KEY UPDATE timeplayed=timeplayed+1 ";
	OCmysql_query($query); 
	
	echo "success timeplayed";
?>