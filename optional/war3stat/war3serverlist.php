<?php 
$showownagemenu=0;
include("header.php");
?>

<script type="text/javascript" src="balloontip.js">
</script>
<link rel="stylesheet" type="text/css" href="balloontip.css" />

<?php 
	$count=$_GET['count'];
	if(!isset($count)){
		$count=99;
	}


	
	
	include("headersql.php");

	$result=mysql_query  ("SELECT * from serverinfo WHERE timestamp > NOW()- INTERVAL 2 MINUTE    ORDER BY players DESC, maxplayers DESC LIMIT $count");
	if (!$result) {	    die('Invalid query: ' . mysql_error());  }

	echo "<script type='text/javascript' src='jquery.js'></script> "; 
	
	   
	echo "<nobr><table style='white-space:nowrap;' border=1 cellpadding=2 cellspacing=0 id=serverlisttable BORDERCOLOR=white>";
	echo "<thead> <tr><th>Server Name</th><th>Game</th><th>Map</th><th>Players</th><th>CC</th><th>Join</th><th>W3S Version</th></tr></thead>\n";
	
	$serversip=array();
	
	
	$rowsreturned=mysql_num_rows($result);
	for($i=0;$i<$rowsreturned;$i++){
		$serversip[$i]=mysql_result($result,$i,"ip");
	
		echo "<tr><td>";
		
		
		echo "<a href='http://www.gametracker.com/server_info/".mysql_result($result,$i,"ip")."' rel='balloon$i'  target='_blank'>".mysql_result($result,$i,"hostname")."</a>";
	
		$link='#';
		
		//@$arr= @get_object_vars(@unserialize(@file_get_contents("http://module.game-monitor.com/".mysql_result($result,$i,"ip")."/data/server.php")));
		//$link=@$arr['link'];
		//echo"<div id='balloon$i' class='balloonstyle' style='width: 0px; height: 0px; background-color: black ; border:none '>";
		//echo "<a href='$link'  target='_blank'><img src='http://module.game-monitor.com/".mysql_result($result,$i,"ip")."/image/default/default.png'></a>";
		//echo"</div>";
		
		echo "</td><td>";
		echo mysql_result($result,$i,"game");
		
		echo "</td><td>";
		echo mysql_result($result,$i,"map");
		
		echo "</td><td align='center'>";
		echo mysql_result($result,$i,"players")." / ".mysql_result($result,$i,"maxplayers");
		
		echo "</td><td>-";
		//@$arr= @unserialize(@file_get_contents('http://www.geoplugin.net/php.gp?ip='.strtok(mysql_result($result,$i,"ip"),":")));
	
		//echo @$arr['geoplugin_countryCode'];
		
		
		echo "</td><div id='country$i'></div><td>";
		echo "<a href='steam://connect/". mysql_result($result,$i,"ip")."'  target='_blank'>";
		echo "<image src='http://www.game-monitor.com/i/launch.gif' style='border-style: none'>Join";
		echo "</a>";
		
		echo "</td><td>";
		echo mysql_result($result,$i,"version");
		
		echo "</td></tr>\n";
		flush();
	}
	echo "</table>";
	if($count==99){
		echo "$rowsreturned servers";
	}
	
	
echo <<<HED

<div id='asdf'></div>
<script type='text/javascript' >


HED;
echo "var servers=$rowsreturned;\n";
echo "var serversip=new Array();\n";

	for($i=0;$i<$rowsreturned;$i++){
		
		echo "serversip[$i]=\"".$serversip[$i]."\";";
	}

echo <<<HED
\n
//$(document).ajaxError(function(e, xhr, settings, exception) {
//alert('error in: ' + settings.url + ' '+'error:' + xhr.responseText );
//}); 

var ajaxCallbackPointer = function(contextargument) {
    return function(data, textStatus) {
        // do something with extraStuff
        var i=contextargument;
    	if(data.length>1){
		    //var coun=data.split("\"geoplugin_countryCode\":\"")[1];
		   	//if(coun!=null){ //may have been blacklisted by geoplugin
		   	//	coun=coun.split("\",")[0];
		   	//}
		   	//if(coun!=null){
		  	document.getElementById('serverlisttable').rows[i+1].cells[4].innerHTML=data; //coun
		  	//}
		}

    };
};




for(var i=0;i<servers;i++){
//	$.get("curl.php?url=http://module.game-monitor.com/"+serversip[i]+"/data/server.js",
//   ajaxCallbackPointer(i)
//      );
   
   
   
/*

	$.get("curl.php?url=http://module.game-monitor.com/"+serversip[i]+"/data/server.js",
   function(data){
   
   	//alert(data);
   	var JSONObject = eval( "(" + data + ")" ); 
     
 document.getElementById('serverlisttable').rows[i+1].cells[3].innerHTML=JSONObject.ip;


   });

*/

	var ip=serversip[i].split(":", 1)[0];
	var extraStuff="omg";	
	$.get("countrylookupcache.php?ip="+ip,
   ajaxCallbackPointer(i)

   );
}



HED;
	
?>
</script> 
<script> initalizetooltip(); </script>
