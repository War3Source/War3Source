<?php 
	header("Cache-Control: no-store, no-cache, must-revalidate"); 
	include("headersql.php");
	
	$maxrows=5;
		
	$count=$_GET['uid'];
	
	$canexit=false;
	if($count==0){
		$result=mysql_query  ("SELECT MAX(uni) FROM racedataeventsv2");
	
			if (!$result) {
		    die('Invalid query: ' . mysql_error());
		  }
		  while($row = mysql_fetch_array($result)){
		 	$count=$row['MAX(uni)']-$maxrows-1;
			}
	}

	for($i=0;$i<5;$i++){

		//$limit=$maxrows+;
		$result=mysql_query  ("SELECT * FROM racedataeventsv2 WHERE uni>$count ORDER BY uni ASC  LIMIT $maxrows");

		if (!$result) {
	    die('Invalid query: ' . mysql_error());
	  }
		$rows=mysql_num_rows($result);
		if($rows>0){ 
		  for($i=0;$i<mysql_num_rows($result);$i++){
		  	echo "[]event|0x".strtoupper (dechex(intval(mysql_result($result,$i,"uni")))) ."|".	mysql_result($result,$i,"uni") ."|".mysql_result($result,$i,"steamid")."|". 	mysql_result($result,$i,"raceshort")."|". 	mysql_result($result,$i,"event")."|". 	mysql_result($result,$i,"data1")."|". 	mysql_result($result,$i,"data2")."|". 	mysql_result($result,$i,"killerlvl")."|". 	mysql_result($result,$i,"victimlvl")."|". 	mysql_result($result,$i,"timestamp");
		  }
		  
		  
		  
		  break;
		}
	  ///otherwise, sleep and try agin
	  usleep(100000);
	}
	
	
	$querystring="SELECT SUM(players),SUM(maxplayers) FROM serverinfo WHERE timestamp > NOW() -  INTERVAL 60 SECOND";
	$result=OCmysql_query($querystring);
	$rowsreturned=mysql_num_rows($result);

	for($i=0;$i<$rowsreturned;$i++){
		$players=mysql_result($result,$i,"SUM(players)");
		$maxplayers=mysql_result($result,$i,"SUM(maxplayers)");
		
		echo "[]playercount|".$players;
	}
	//usleep(500000);
?>
