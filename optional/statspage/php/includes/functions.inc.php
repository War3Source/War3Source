<?php
  // Convert STEAMID into Community Page URL
  function GetFriendID($pszAuthID)
  {
    $iServer = 0;
    $iAuthID = 0;
  	$szAuthID = $pszAuthID;
  	$szTmp = strtok($szAuthID, ":");
  	while(($szTmp = strtok(":")) !== false)
    {
      $szTmp2 = strtok(":");
      if($szTmp2 !== false)
      {
        $iServer = (double)$szTmp;
        $iAuthID = (double)$szTmp2;
      }
    }
    if($iAuthID == 0)
      return "0";
    $i64friendID = $iAuthID*2;
    $i64friendID = $i64friendID+7960265728+$iServer; 
  	return "7656119".$i64friendID;
  }
?>