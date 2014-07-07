<?php
	$showownagemenu=0;
	include("header.php");
	include('headersql.php');
	$maxrows=20000000;
	$rowjumper=5000000;
	// First, select EVERYTHING we're going to need. The gross query.
	$total1 = microtime(true);
	$t1 = time();
	function print_r_cool($a, $die = false)
	{
		echo("<pre>");
		print_r($a);
		echo("</pre>");
		if($die)
			die("");
	}	
	$servers = array();
	$all = array();
	$games = array();
	
	function ez_increment(&$var)
	{
		if(!isset($var))
		{
			$var = 0;
		}
		$var++;
	}
	function rgb2html($r, $g=-1, $b=-1)
	{
	    if (is_array($r) && sizeof($r) == 3)
	        list($r, $g, $b) = $r;
	
	    $r = intval($r); $g = intval($g);
	    $b = intval($b);
	
	    $r = dechex($r<0?0:($r>255?255:$r));
	    $g = dechex($g<0?0:($g>255?255:$g));
	    $b = dechex($b<0?0:($b>255?255:$b));
	
	    $color = (strlen($r) < 2?'0':'').$r;
	    $color .= (strlen($g) < 2?'0':'').$g;
	    $color .= (strlen($b) < 2?'0':'').$b;
	    return '#'.$color;
	}
	
	
	///HEADING AND FILTER OPTIONS
	echo "Race <b>Kill Death Ratio (KDR)</b> and <b>Win Loss Ratio (WLR)</b> ";
	flush();
	

	
	$ipfilter=@$_GET['ipfilter'];
	if(!isset($ipfilter)){
		$ipfilter='%%';
	}
	
	$game=@$_GET['game'];
	if(!isset($game)){
		$game='%%';
	}
	$lvl=@$_GET['lvl'];
	if(!isset($lvl)){
		$lvl='-1';
	}
	
	
	
	$nofilters=false;
	if(strcmp($ipfilter,"%%")==0&&strcmp($game,"%%")==0&&strcmp($lvl,"-1")==0){
		$nofilters=true;
	}
	//has filter
	else{
		if(strcmp($ipfilter,"%%")==0){
		//	$hours=72;
		}	
	}
	if($nofilters){
		echo "from last 10 days";
	}
	$timeplayed=false;
	if($nofilters){
		$timeplayed=true;
	}
	
	$datelimit=" date > NOW()- INTERVAL 10 DAY "; ///limits for date AGGREGATE ONLY
 
	$timestamplimit="";//" timestamp > NOW()- INTERVAL $hours HOUR ";
	$iplimit=" ipport LIKE '$ipfilter' "; //AND removed
	$gamelimit=" AND game LIKE '$game' ";
	
	$lvllimit=" AND killerlvl >= '$lvl' AND viclvl >= '$lvl' ";
	$lvllimitwl=" AND lvl > '$lvl' ";
	
	$kdrlimits=$timestamplimit.$iplimit.$gamelimit.$lvllimit;
	
	$iplimit=" ip LIKE '$ipfilter' ";
	$wllimits=$timestamplimit.$iplimit.$gamelimit.$lvllimitwl;
	
	
	
	
	if(!isset($jquery)){
		echo "<script type='text/javascript' src='jquery.js'></script>";
	}

	echo "<script type='text/javascript' src='jquery.tablesorter.js'></script> ";

	//echo "<script> $(document).ready(function()  {      $(\"#myTable\").tablesorter({ sortList: [[4,1]] });    } ); </script>";
	//ready is called each time the document changes again
	echo "<script> function dosort()  {      $(\"#myTable\").tablesorter({ sortList: [[5,1]] });    }  </script>";
 
	
	//filter form
	echo "<form action='".curPageURL()."' method='GET'> ";
	echo "IP Filter: <select name='ipfilter'>";
	$result=mysql_query  ("SELECT hostname,ip,remoteip FROM serverinfo WHERE timestamp > NOW()- INTERVAL 1 MINUTE  ORDER BY hostname,ip"); 
	if (!$result) {	    die('Invalid query: ' . mysql_error());  }
	$rowsreturned=mysql_num_rows($result);
	echo "<option value='%%'>All servers</option>";
	for($i=0;$i<$rowsreturned;$i++){
		$ipz=mysql_result($result,$i,"ip");
		$hostname=mysql_result($result,$i,"hostname");
		
		echo "<option value='$ipz' ";
			if(strcmp($ipz, $ipfilter)==0){ echo "selected='yes'";}
		echo ">$hostname $ipz</option>";
		
		//REMOTE IP
		$ipz=mysql_result($result,$i,"remoteip");
		$hostname=mysql_result($result,$i,"hostname");
		
		echo "<option value='$ipz' ";
			if(strcmp($ipz, $ipfilter)==0){ echo "selected='yes'";}
		echo ">$hostname $ipz</option>";
	}
	//additional option to list number of servers
	echo "<option value='%%'>$rowsreturned</option>";
	
	echo "</select>";
	echo "<br>";
	echo "Game Filter: <select name='game'>";
	
	echo "<option value='%%' ";
	if(strcmp($game, "%%")==0){	 "selected='yes'";	}
	echo ">ALL</option>";
	
	echo "<option value='cstrike' ";
	if(strcmp($game, "cstrike")==0){ echo "selected='yes'";}
	echo ">CSS</option>";
	
	
	echo "<option value='tf' ";
	if(strcmp($game, "tf")==0){ echo "selected='yes'";}
	echo ">TF2</option>";
	
	
	echo "</select>";
	echo "<br>";
	echo "Minimum level for killer and victim: <input name='lvl' type='text' size='3' value='$lvl'>";
	
	echo "<input type='submit' value='Query' /></form>";


	
	///GET RACES FIRST
	$result=mysql_query  ("SELECT raceshort,racename,finalizedname FROM racesv2 "); 
	if (!$result) {	    die('Invalid query: ' . mysql_error());  }
	$araceshort = array();
	$aracename =array();
	$racecount=mysql_num_rows($result);
	for($i=0;$i<$racecount;$i++){
		
		$aracename[$i]=mysql_result($result,$i,"racename");
		$araceshort[$i]=mysql_result($result,$i,"raceshort");
		
		if(strlen(mysql_result($result,$i,"finalizedname"))>1){
			$aracename[$i]=mysql_result($result,$i,"finalizedname");
		}
	}
	
	if($nofilters){ //READ DATA FROM DAILY CACHE
		echo "Reading data from cache...";
	
		for($i=0;$i<$racecount;$i++){
			$raceshort=$araceshort[$i];
			$result=OCmysql_query  ("SELECT SUM(kills) as kills, SUM(deaths) as deaths , SUM(win) as win, SUM(loss) as loss , sum(timeplayed) as timeplayed FROM agg_racekill_day WHERE  raceshort='".$raceshort."'  AND  $datelimit "); 
			if(mysql_num_rows($result)){
				$all[$raceshort]['kills']=mysql_result($result,0,"kills");
				$all[$raceshort]['deaths']=mysql_result($result,0,"deaths");
				$all[$raceshort]['wins']=mysql_result($result,0,"win");
				$all[$raceshort]['losses']=mysql_result($result,0,"loss");
				$all[$raceshort]['timeplayed']=mysql_result($result,0,"timeplayed");
			}
			
		}
	}
	else{ //READ BY ROW SCANS
		echo "Reading raw data. KD: <span id='kdprogress'></span>";
	
		//ROW SCANS
		// recentkills
		// do X at a time
		$n = 0;
		$number_rows = 1; // just so the loop doesn't die right away
		flush();	
		while(1) //MUST BREAK
		{	
			//echo "SELECT raceshort,vicrace FROM recentkills  WHERE $kdrlimits LIMIT $n, $rowjumper";
			
			$result = OCmysql_query_unbuffered("SELECT raceshort,vicrace FROM recentkills  WHERE $kdrlimits LIMIT $n, $rowjumper");//
			$number_rows=0;// = mysql_num_rows($result);
			$t0 = microtime(true);
			$t1 = microtime(true);
			while($row = mysql_fetch_assoc($result))
			{
				$all[$row['raceshort']]['kills']++;
				$all[$row['vicrace']]['deaths']++;
				$number_rows++;
				$t2 = microtime(true);
				if($t2-$t1>1.0){
					$rate=number_format($number_rows/($t2-$t0),0);
					echo "<script>document.getElementById('kdprogress').innerHTML = '$number_rows ($rate/s)';</script>\n";
					$t1=$t2;
					flush();
				}
			}
		//	$t2 = microtime(true);
		//	mysql_free_result($result);
			
		
			$n+=$number_rows;	 //normally number of rows is row jumper if there is more results
			
			$t2 = microtime(true);
			$rate=number_format($number_rows/($t2-$t0),0);
			echo "<script>document.getElementById('kdprogress').innerHTML = '$number_rows ($rate/s)';</script>\n";
					
		//	echo number_format($t2-$t1,2).")";
			flush();
			if($n>$maxrows || $number_rows<$rowjumper){
				break;
			}	
		}
		echo "..done<br>WL: <span id='wlprogress'></span>";
		// recentwins
		// do  at a time
		$n = 0;
		while(1) //MUST BREAK
		{
		//die("SELECT * FROM recentwins WHERE $wllimits LIMIT $n, 50000");
			
			$result = OCmysql_query_unbuffered("SELECT raceshort,win FROM recentwins WHERE $wllimits LIMIT $n, $rowjumper"); //
			$number_rows=0;// = mysql_num_rows($result);
			$t0 = microtime(true);
			$t1 = microtime(true);
			while($row = mysql_fetch_assoc($result))
			{
				
				if($row['win']){ //this data point is a WIN
					$all[$row['raceshort']]['wins']++;
				}
				else{
					$all[$row['raceshort']]['losses']++;
				}
				$number_rows++;
				$t2 = microtime(true);
				if($t2-$t1>1.0){
					$rate=number_format($number_rows/($t2-$t0),0);
				echo "<script>document.getElementById('wlprogress').innerHTML = '$number_rows ($rate/s)';</script>\n";
					flush();
					//echo number_format($t2-$t1,2).")";
					$t1=$t2;
					
				}
			}
		//	$t2 = microtime(true);
		//	mysql_free_result($result);	
			
			
			
			$n+=$number_rows;	//normally number of rows is row jumper if there is more results
			$t2 = microtime(true);
			$rate=number_format($number_rows/($t2-$t0),0);
			echo "<script>document.getElementById('wlprogress').innerHTML = '$number_rows ($rate/s)';</script>\n";
			flush();
			if($n>$maxrows || $number_rows<$rowjumper){
				break;
			}		
		}
	}
	
	/*
	foreach($servers as $ip=>$server)
	{
		if(!isset($server['kills']))
		{
			continue;
		}
		foreach($server['kills'] as $shortname=>$kills)
		{
			$max_level = 0;
			foreach($kills as $lvlstr=>$unused)
			{
				$lvl = (int)substr($lvlstr, 3);
				if($lvl>$max_level)
				{
					$max_level = $lvl;
				}
			}
			// each number 0 - $max_level must be provided a kdr
			for($lvl_min=0;$lvl_min<=$max_level;$lvl_min++)
			{
				$tk = 0;
				$td = 0;
				// add every kill (and death) data if $lvl_min <= $lvl_from_str
				if(is_array($server['deaths'][$shortname]))
				{
					foreach($server['deaths'][$shortname] as $lvlstr2=>$death_num)
					{
						$lvl_from_str = (int)substr($lvlstr2, 3);
						if($lvl_from_str >= $lvl_min)
						{
							$td+=$death_num;
						}				
					}
				}				
				if(is_array($server['kills'][$shortname]))
				{
					foreach($server['kills'][$shortname] as $lvlstr2=>$kill_num)
					{
						$lvl_from_str = (int)substr($lvlstr2, 3);
						if($lvl_from_str >= $lvl_min)
						{
							$tk+=$kill_num;
						}					
					}
				}
				$kdr = "";
				if($td>0)
				{
					$kdr = number_format(($tk/$td), 2);
				}
				$servers[$ip]['kdr'][$shortname]['lvl'.$lvl_min] = $kdr;					
			}
		}
	}
	
	if(isset($all['kills']))
	{
		foreach($all['kills'] as $shortname=>$kills)
		{
			$max_level = 0;
			foreach($kills as $lvlstr=>$unused)
			{
				$lvl = (int)substr($lvlstr, 3);
				if($lvl>$max_level)
				{
					$max_level = $lvl;
				}
			}
			// each number 0 - $max_level must be provided a kdr
			for($lvl_min=0;$lvl_min<=$max_level;$lvl_min++)
			{
				$tk = 0;
				$td = 0;
				// add every kill (and death) data if $lvl_min <= $lvl_from_str
				if(is_array($all['deaths'][$shortname]))
				{
					foreach($all['deaths'][$shortname] as $lvlstr2=>$death_num)
					{
						$lvl_from_str = (int)substr($lvlstr2, 3);
						if($lvl_from_str >= $lvl_min)
						{
							$td+=$death_num;
						}				
					}
				}				
				if(is_array($all['kills'][$shortname]))
				{
					foreach($all['kills'][$shortname] as $lvlstr2=>$kill_num)
					{
						$lvl_from_str = (int)substr($lvlstr2, 3);
						if($lvl_from_str >= $lvl_min)
						{
							$tk+=$kill_num;
						}					
					}
				}
				$kdr = "";
				if($td>0)
				{
					$kdr = number_format(($tk/$td), 2);
				}
				$all['kdr'][$shortname]['lvl'.$lvl_min] = $kdr;					
			}
		}
	}
	
	// drop the current cache
	mysql_query("DELETE FROM stats_cache WHERE 1");
		
	// now, lets add in all the entries to the table
	$server_used = array();
	foreach($servers as $ip=>$server)
	{
		$ip = mysql_real_escape_string($ip);
		$server_used[$ip] = 1;
		$game = mysql_real_escape_string($server['game']);
		$kills_json_sql = mysql_real_escape_string(json_encode($server['kills']));
		$deaths_json_sql = mysql_real_escape_string(json_encode($server['deaths']));
		$wins_json_sql = mysql_real_escape_string(json_encode($server['wins']));
		$kdr_json_sql = mysql_real_escape_string(json_encode($server['kdr']));
		$losses_json_sql = mysql_real_escape_string(json_encode($server['losses']));
		$query = "INSERT INTO stats_cache (server, game, kill_data, death_data, kdr_data, win_data, loss_data) VALUES ('".$ip."', '".$game."', '".$kills_json_sql."', '".$deaths_json_sql."', '".$kdr_json_sql."', '".$wins_json_sql."', '".$losses_json_sql."')";
		mysql_query($query); 	 	 	 		
	}
	$kills_json_sql = mysql_real_escape_string(json_encode($all['kills']));
	$deaths_json_sql = mysql_real_escape_string(json_encode($all['deaths']));
	$wins_json_sql = mysql_real_escape_string(json_encode($all['wins']));
	$kdr_json_sql = mysql_real_escape_string(json_encode($all['kdr']));
	$losses_json_sql = mysql_real_escape_string(json_encode($all['losses']));
	$query = "INSERT INTO stats_cache (server, game, kill_data, death_data, kdr_data, win_data, loss_data) VALUES ('all', 'all', '".$kills_json_sql."', '".$deaths_json_sql."', '".$kdr_json_sql."', '".$wins_json_sql."', '".$losses_json_sql."')";
	mysql_query($query);	*/
	
	
	$killssum=0;
	$deathssum=0;
	$winssum=0;
	$lossessum=0;
	
	
	//print_r($araceshort);
	
	
	///print SHIT
	echo "<table border=1 cellpadding=2 cellspacing=0 id=myTable BORDERCOLOR=white>";
	echo "<thead> <tr>   <th><a href='#'>racename<a></th> <th><a href='#'>raceshort</a></th> <th>&nbsp;</th> <th><a href='#'>Kills</a></th> <th><a href='#'>Deaths</a></th> <th><a href='#'>KDR</a></th>  <th>&nbsp;</th>  <th><a href='#'>Wins</a></th> <th><a href='#'>Losses</a></th> <th><a href='#'>WLR</a></th> ";
	if($timeplayed){
		echo "<th>&nbsp;</th> <th><a href='#'>T/D</a></th> ";   
	}
	echo "</tr></thead>    <tbody> ";
	
	$raceslisted=0;
	
	for($i=0;$i<$racecount;$i++){
		
		$racename=(string)$aracename[$i];
		$raceshort=(string)$araceshort[$i];
		
		if(isset($all[   $raceshort      ]['kills']  )){
			$kills=$all[   $raceshort      ] ['kills'];
			$deaths=$all[  $raceshort     ] ['deaths'];
			$wins=$all[   $raceshort      ] ['wins'];
			$losses=$all[   $raceshort      ] ['losses'];
			
			$killssum+=$kills;
			$deathssum+=$deaths;
			$winssum+=$wins;
			$lossessum+=$losses;
			
			///RACE HAS DATA
			//print_r($all[    $racename[$i]        ] );
			
			if($deaths==0||$kills==0){
				continue;
			}
			$raceslisted++;
			
			$kdr='-';
			if($deaths>100&&$kills>100){
				$kdr=number_format($kills/$deaths,2);
			}
			
			
			echo "<tr>";
			
			echo "<td>";
			
			echo $racename;
			
			echo "</td><td><a href='http://www.ownageclan.com/plot/?raceshort=".$raceshort."' target='_blank'>".$raceshort."</a></td><td></td>";
			echo "<td>".$kills."</td>"; 
			echo "<td>".$deaths."</td>"; 
			
			
			
			
			$hex=rgb2html(abs($kdr-1)/0.30*255,255-abs($kdr-1)/0.40*255,(1-$kdr)/0.30*155);
		
			echo "<td><FONT COLOR='$hex'>".$kdr."</FONT></td>";
				
			
			$kdr='-';
			if($wins>50&&$losses>50){
				echo "<td></td>";
				echo "<td>".$wins."</td>"; 
				echo "<td>".$losses."</td>"; 
				
				
				$kdr=number_format($wins/$losses,2);
				
				$hex=rgb2html(abs($kdr-1)/0.30*255,255-abs($kdr-1)/0.40*255,(1-$kdr)/0.30*155);
				
				echo "<td><FONT COLOR='$hex'>".$kdr."</FONT></td>";
				
			
				//
			}
			else{
				echo "<td></td><td></td><td></td><td></td>"; 
			}
			
			if($timeplayed){
				echo "<td></td>";
				if(isset($all[$raceshort]['timeplayed'])){
					echo "<td>".round($all[$raceshort]['timeplayed']/10)."</td>"; //10 days
				}
				else{
					echo "<td></td>";
				}
			}
			
			
			
			echo "</tr>";
			
		
			
			
			flush();
			
			
			
			
			
			
			
			
			
			
		}
	}
	echo "<tr>   <td>SUM</td><td></td><td> </td><td> $killssum</td><td>$deathssum</td><td></td><td></td><td>$winssum</td><td>$lossessum</td><td></td>".($timeplayed?"<td></td><td></td>":"")." </tr>";
	
	echo "<br>";
		
		
			echo "</tbody> </table>";
	echo "$raceslisted races listed";
	echo "<script> $('#myTable').tablesorter();  </script>"; //enable the sorter
	
	
	$total2 = microtime(true);
	echo("<br>Loaded in ".number_format($total2-$total1,3)." seconds");
	
?>