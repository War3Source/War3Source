<?php

	include("header.php");
	
	$steamid=$_GET['steamid'];
	$ip=$_GET['ip'];
	$raceshort=$_GET['raceshort'];
	$game=$_GET['game'];
	
	$data1=$_GET['data1']; //vic steamid
	$data2=$_GET['data2']; //vic race
	$killerlvl=$_GET['killerlvl'];
	$victimlvl=$_GET['victimlvl'];
	
	$statsversion=@$_GET['statsversion'];
	$war3revision=@$_GET['war3revision'];
	
	$result=OCmysql_query  ("SELECT * FROM disabledservers WHERE ipport='$ip' and nostats='1' ");
	if(mysql_num_rows($result)){
		die( "success kill disabled");
	}
	
	
	$result=OCmysql_query  ("INSERT INTO racedataeventsv2 SET steamid='$steamid' , ipport='$ip' , raceshort='$raceshort' , game='$game', event='kill' , data1='$data1' , data2='$data2',killerlvl='$killerlvl',victimlvl='$victimlvl'  , processed='1'");
	
	
	$result=OCmysql_query  ("INSERT INTO recentkills SET steamid='$steamid',raceshort='$raceshort',killerlvl='$killerlvl',ipport='$ip', game='$game', vicsteamid='$data1' , vicrace='$data2',viclvl='$victimlvl' , war3revision='$war3revision' , statsversion='$statsversion'");
	

	$query="INSERT INTO perplayerraceplaytimelongv2 SET steamid='$steamid' , raceshort='$raceshort'  ON DUPLICATE KEY UPDATE kills=kills+1";
	$result=OCmysql_query  ($query); 

	
	$query="INSERT INTO perplayerraceplaytimelongv2 SET steamid='$data1' , raceshort='$data2'  ON DUPLICATE KEY UPDATE deaths=deaths+1";
	$result=OCmysql_query  ($query); 
	
	
	$query="INSERT INTO agg_racekill_day SET raceshort='$raceshort', date=CURDATE()  ON DUPLICATE KEY UPDATE ";
	$query.="kills=kills+1";
	$result=OCmysql_query  ($query);
	
	$query="INSERT INTO agg_racekill_day SET raceshort='$data2', date=CURDATE()  ON DUPLICATE KEY UPDATE ";
	$query.="deaths=deaths+1";
	$result=OCmysql_query  ($query);
	
	echo "success kill";
?>