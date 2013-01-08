<?php

	require("config.php");

?>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

	<html xmlns="http://www.w3.org/1999/xhtml" dir="ltr">

		<head profile="http://gmpg.org/xfn/11">

			<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />

			<link href="style.css" rel="stylesheet" type="text/css" />

			<meta name="keywords" content="war3source,war3source stats,war3source info,war3source rank" />

			<meta name="description" content="War3Source plugin database statistics." />

			<title>War3Source: Stats</title>

		</head>

		<body>

			<table id="page_table">

				<tr id="page_header" style="text-align:center">

					<td >

						<img src="<?php echo $config->logo_path; ?>" alt="War3Source: Stats" />

					</td>

				</tr>

				<tr id="page_body">

					<td>

<?php

	require("includes/ez_sql.php");

	require("includes/functions.inc.php");
	mysql_set_charset("utf8");



		// Initate the SQL connection

	$db = new db($config->user,$config->pass,$config->database,$config->host);

	

	// What page are we on?

	// 0 == home (general stats)

	// 1 == search

	// 2 == player info

	// 3 == race info

	

	$page=0;

	if(isset($_GET['page']))

	{

			$page=$_GET['page'];

			$page=stripslashes(trim($page));

			$page=nl2br($page);

			$page=(int)htmlentities($page);

	}

	

	// Three generic parameters of string datatype

	$param_x='0';

	$param_y='0';

	$param_z='0';

	if(isset($_GET['x']))

	{

			$param_x=$_GET['x'];

			$param_x=stripslashes(trim($param_x));

			$param_x=nl2br($param_x);

			$param_x=htmlentities($param_x);

	}

	if(isset($_GET['y']))

	{

			$param_y=$_GET['y'];

			$param_y=stripslashes(trim($param_y));

			$param_y=nl2br($param_y);

			$param_y=htmlentities($param_y);

	}

	if(isset($_GET['z']))

	{

			$param_z=$_GET['z'];

			$param_z=stripslashes(trim($param_z));

			$param_z=nl2br($param_z);

			$param_z=htmlentities($param_z);

	}

	

	// First, if page isn't "home" then check if parameters are correct, if not override to home

	if($page>0)

	{

		// Parameters required for "search" are query (x) and search_type (y)

		if($page==1)

		{

			if($param_x=='0' or $param_y=='0')

			{

				$page=0;

			}

		}

		// Parameters required for "player info" are steamid (x)

		// Parameters required for "race info" are shortname (x)

		else if($page==2 or $page==3)

		{

			if($param_x=='0')

			{

				$page=0;

			}

		}

		// Unrecognized page number, force to 0

		else

		{

			$page=0;

		}

	}

	

	// Cool, validated parameters exist, this doesn't mean they are truly valid however

	if($page==1)

	{

		// Start search query page

		// End search query page

	}

	else if($page==2)

	{

		// Start player info page

		$steamid=$param_x;

		$sql="SELECT * FROM war3source WHERE steamid = '".$steamid."'";

		$result=$db->get_results($sql);

?>

					<table class="player_info">

						<tr>

							<td>

							 <a href="index.php">Return Home</a><br/><br/>

<?php

		if(count($result)<=0)

		{

			echo "Error, player not in database.";

		}

		else

		{

			$player=$result[0];

			$sql="SELECT * FROM war3sourceraces";

			$races=$db->get_results($sql);

			if(count($races)<=0)

			{

				echo "Error, try again later.";

			}

			else

			{

				$display_race="No Race";

				foreach($races as $race)

				{

					if($race->shortname==$player->currentrace)

					{

						$display_race=$race->name;

					}

				}

?><b>XP Statistics for <?php echo ($player->name=="0" || $player->name=="")?$player->steamid:$player->name; ?></b><br />

Total Level: <?php echo $player->total_level ?><br />

Total XP: <?php echo $player->total_xp ?><br />

Current Race: <?php echo $display_race; ?><br /><br />

<?php

				foreach($races as $race)

				{	

					$sql="SELECT * FROM war3source_racedata1 WHERE steamid = '".$steamid."' AND raceshortname='".$race->shortname."'";

					$result=$db->get_results($sql);

					if(count($result)>0)

					{
					
						$player_race=$result[0];
					
						

?>

<table class="race_player">

	<tr class="player_row">

		<td class="rp_left"><b>Race</b></td>

		<td class="rp_right"><?php echo $race->name." &nbsp; Level: ".$player_race->level." XP: ".$player_race->xp; ?></td>

	</tr>



	<tr class="off_color_row">

		<td class="rp_left"><b><?php echo $race->skill1; ?></b><br/>Level <?php echo $player_race->skill1; ?></td>

		<td class="rp_right"><?php echo $race->skilldesc1; ?></td>

	</tr>

	<tr class="player_row">

		<td class="rp_left"><b><?php echo $race->skill2; ?></b><br/>Level <?php echo $player_race->skill2; ?></td>

		<td class="rp_right"><?php echo $race->skilldesc2; ?></td>

	</tr>

<tr class="off_color_row">

		<td class="rp_left"><b><?php echo $race->skill3; ?></b><br/>Level <?php echo $player_race->skill3; ?></td>

		<td class="rp_right"><?php echo $race->skilldesc3; ?></td>

	</tr>

	
	
	<tr class="player_row">

		<td class="rp_left"><b><?php echo $race->skill4; ?></b><br/>Level <?php echo $player_race->skill4; ?></td>

		<td class="rp_right"><?php echo $race->skilldesc4; ?></td>

	</tr>

<?php
	}
	if($race->skill5>0){
	?>
	<tr class="off_color_row">

		<td class="rp_left"><b><?php echo $race->skill5; ?></b><br/>Level <?php echo $player_race->skill5; ?></td>

		<td class="rp_right"><?php echo $race->skilldesc5; ?></td>

	</tr>
<?php

	}

	if($race->skill6>0){
	?>
	<tr class="player_row">

		<td class="rp_left"><b><?php echo $race->skill6; ?></b><br/>Level <?php echo $player_race->skill6; ?></td>

		<td class="rp_right"><?php echo $race->skilldesc6; ?></td>

	</tr>
<?php
	}

	if($race->skill7>0){
	?>
	?>	
	<tr class="off_color_row">

		<td class="rp_left"><b><?php echo $race->skill7; ?></b><br/>Level <?php echo $player_race->skill7; ?></td>

		<td class="rp_right"><?php echo $race->skilldesc7; ?></td>

	</tr>
<?php
	}
	?>


</table><br />

<?php

					}

				}

			}

	//	}

?>						</td>

						</tr>

					</table>

<?php

		// End player info page

	}

	else if($page==3)

	{

		// Start race info page

		// End race info page

	}

	else

	{

		// Start home page

		// NOTE: If param_x!='0' then cast it to a number for SELECT limit

		$start_number=0;

		$ignore_first_result=false;

		if($param_x!='0')

		{

			$start_number=(int)$param_x;

		}

		if($start_number<=0)

		{

			$start_number=0;

		}

		$end_number=$start_number+51; // The two extra are for checking if there is a Next/Previous link

		$has_next_button=false;

		$has_previous_button=false;

		if($start_number>0)

		{

			$has_previous_button=true;

		}

		$cur_page=($start_number/50)+1;

		// Query for races

		$sql="SELECT shortname,name FROM war3sourceraces";

		$races=$db->get_results($sql);

		// Total pages?

		$sql="SELECT * FROM war3source";

		$total_players=$db->get_results($sql);

		$pages=ceil(count($total_players)/50);

		// Query for players from main table by rank

		$sql="SELECT * FROM war3source ORDER BY total_level DESC,total_xp DESC LIMIT $start_number,$end_number";

		$players=$db->get_results($sql);

		$result_number=0;

		// Start making an HTML table

		if(count($players)>50)

		{

			$has_next_button=true;

		}

?>

					<table class="main_desc">

						<tr>

							<td style="text-align:center">

								Welcome to the War3Source stats page for <?php echo $config->server_name ?>!

							</td>

						</tr>

						<tr>

							<td style="text-align:center">

								<?php if($has_previous_button==true) echo "<a href='index.php?x=".($start_number-50)."'>Previous</a>"; ?><?php if($has_next_button==true) echo " <a href='index.php?x=".($start_number+50)."'>Next</a>"; ?><br />

<?php

		if($pages>0)

		{

?>



								Jump to Page: <select name='page_num' onchange='window.location.href="index.php?x="+this.options[this.selectedIndex].value'> 

<?php

			for($counter=0;$counter<$pages;$counter+=1)

			{

				$value_set=$counter*50;

?>

									<option value="<?php echo $value_set; ?>"<?php if(($counter+1)==$cur_page) echo " selected";?>><?php echo ($counter+1); ?></option>

<?php

			}

?>

								</select>

<?php

		}

?>

							</td>

						</tr>

					</table>	

<?php

		if(count($players)<=0)

		{

?>

					No results found

<?php

		}

		else

		{

?>

					<table class="players_table">

						<tr class="player_row">

							<td class="td_rank">Rank</td>

							<td class="td_name">Name</td>

							<td class="td_steam">SteamID</td>

							<td class="td_level">Total Level</td>

							<td class="td_xp">Total XP</td>

							<td class="td_race">Race</td>

						</tr>

<?php

			foreach($players as $player)

			{

				$result_number=$result_number+1;

				if($result_number>50)

				{

					break;

				}

				$friend_id=GetFriendID($player->steamid);

?>

						<tr class="player_row<?php if($result_number & 1) echo ' off_color_row';?>">

<?php

				// We need to find out what race they really are, if none default to $races[0]->$name

				$display_race="No Race";

				foreach($races as $race)

				{

					if($race->shortname==$player->currentrace)

					{

						$display_race=$race->name;

					}

				}

				echo "							<td class=\"td_rank\">".($result_number+$start_number)."</td>\n";			

				echo "							<td class=\"td_name\"><a href='index.php?page=2&x=".$player->steamid."'>".(($player->name=="0" || $player->name=="")?$player->steamid:$player->name)."</a></td>\n";

				echo "							<td class=\"td_steam\"><a href='http://steamcommunity.com/profiles/".$friend_id."'>".$player->steamid."</a></td>\n";

				echo "							<td class=\"td_level\">".$player->total_level."</td>\n";

				echo "							<td class=\"td_xp\">".$player->total_xp."</td>\n";

				echo "							<td class=\"td_race\">".$display_race."</td>\n";

?>

						</tr>

<?php

			}

?>

					</table>

<?php

		}

		// End home page

	}

?>

					</td>

				</tr>

				<tr class="page_footer">

					<td>

						<!-- Alot of time and effort was put into War3Source. -->

						<!-- Please don't remove. -->

						<br />&copy; <a href="http://war3source.com/">War3Source</a> Dev Team

					</td>

				</tr>

			</table>

		</body>

	</html>