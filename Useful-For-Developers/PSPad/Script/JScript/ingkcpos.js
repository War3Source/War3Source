/*	
	°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•
	
	Provided under the MIT License
	Copyright (c) July 2007 Damion Hankejh, d@ingk.com
	---
	FILE:			ingkcpos.js
	VERSION:		0.6
	WEB:			www.sf.net/projects/ingkcpos

	DESCRIP:		PSPad Editor Extension to enhance 
					CTRL+(SHIFT)+RIGHT/LEFT cursor behavior.

					Compatible/tested with PSPad versions:
					-	(full version) 4.5.2 (2240) - Windows XP/SP2 
					-	(beta release) 4.5.3 (2262) - Windows XP/SP2
					-	(beta release) 4.5.3 (2265) - Windows XP/SP2
					-	(beta release) 4.5.3 (2278) - Windows XP/SP2
					-	(full version) 4.5.3 (2291) - Windows XP/SP2
					-	(beta release) 4.5.3 (2296) - Windows XP/SP2
					

	INSTALL:		1.	If a previous version has been installed, uninstall 
						it by deleting these files:
						
						~\PSPad editor\Script\JScript\CTRL+SHIFT+RIGHT.js
						~\PSPad editor\Script\JScript\CTRL+SHIFT+LEFT.js
						~\PSPad editor\Script\JScript\CTRL+RIGHT.js
						~\PSPad editor\Script\JScript\CTRL+LEFT.js

					2.	Exit PSPad

					3.	Place the this script (ingkcpos.js) in:
						~\PSPad editor\Script\JScript\
						
					4.	Place the settings.hta file in:
						~\PSPad editor\Script\JScript\Ingkcpos\

					5.	Start PSPad


	USE:			[ CTRL+RIGHT ] and [ CTRL+LEFT ] move the cursor to 
					the next right/left-context cursor stop.

					[ CTRL+SHIFT+RIGHT/LEFT ] selects text with each
					cursor move.

	AUTHORS:		Original:	Damion Hankejh, d@ingk.com
					Updates:		AndyBridges, Michal Caplygin, GriGri, Petr Matejka

	LICENSE:		MIT License
					www.opensource.org/licenses/mit-license.php

	---
	NOTES:		Behavior

					-	Native positioning in PSPad yields cursor stops 
						indicated by "|" in:

							Key combo				Cursor stops (PSPad)
							---						---
							Original text			if (isSet($error) && $error != '') $text_block.= '<p>'.$error.'</p>';			
							CTRL+(SHIFT)+RIGHT	if (|isSet($|error) && $|error != '') $|text_block.= '<|p>'.$|error.'</|p>';|
							CTRL+(SHIFT)+LEFT		|if (|isSet($|error) && $|error != '') $|text_block.= '<|p>'.$|error.'</|p>';		

					-	Enhanced positioning enabled with the ingkcpos 
						PSPad extension yields:

							Key combo				Cursor stops (ingkcpos)
							---						---
							Original text			if (isSet($error) && $error != '') $text_block.= '<p>'.$error.'</p>';
							CTRL+(SHIFT)+RIGHT	if |(|isSet|($|error|) |&& $|error |!= |'') $|text|_|block|.= |'<|p|>'.$|error|.'</|p|>';|
							CTRL+(SHIFT)+LEFT		|if |(|isSet|(|$|error|)| |&&| |$|error |!=| |'')| |$|text|_|block|.=| |'<|p|>'.$|error|.'</|p|>';| 

	---
	TODO:			Add Settings GUI Dialog
	
					*	GriGri has added a settings dialog to ease management of whitespace, alphanumeric and 
						delimiter characters (using existing regexp patterns).  We need to add a "Reset to Default"
						button to the dialog before turning it on in the Scripts > Ingkcpos > Settings menu, but 
						the code remains in place in version 0.6; its addMenuItem() call in Init() has been 
						commented out for now.

					-	In some cases, it is useful to have cursor stops on specific characters (eg. TAB).  
						A settings GUI dialog accessible from the [Scripts > Ingkcpos] submenu would provide 
						convenient access to this as well as accepting input for additional cursor navigation
						settings.  Storing settings in the ~\PSPad editor\ directory would further improve
						a settings implementation. 

					-	Access to white, alpha and delim regular expressions could also be added to a
						settings dialog.

					Implement alternate cursor behavior models

					-	Ingkcpos cursor behavior is modeled on (most similar to) UltraEdit/TextPad.
						Implementing alternate behavior models drawn from other editors or browsers would
						further customize cursor movement:

						WinVi:			  	if |(isSet($error) |&& |$error |!= |'') |$text_block.= |'<p>'.$error.'</p>';|
						Firefox:				if |(|isSet($|error) |&& |$|error |!= |'') |$|text_|block.= |'<|p>'.$|error.'</|p>';|
						Cold fusion(R):	if (|isSet($|error) && $|error != |'') $|text_block.= |'|<p>|'.$|error|.'|</p>|';|
						Cold Fusion(K):	|if (|isSet($|error) && $|error != |'') $|text_block.= |'|<p>|'.$|error.|'|</p>|';

	---
	DONE:			Unsaved Changes

					-	Use ingkcpos to reposition the cursor causes the editor to flag the file as
						modified (indicated by a red triangle in the file tab, or by a diskette icon in the 
						status bar).  However, no changes whatsoever are made to the contents of the file.
						
						June 26, 2007 - AndyBridges killed this bug.  
						Thanks to his investigation, the "modified flag" bug appears to be related to the 
						use of 'ed.command("ecNextLineStart");' to position the cursor, so he replaced it 
						with calls to ed.caretX() and ed.caretY().
						
					Non-ASCII Character Support
					
					-	Cursor movement stops upon encountering non-ASCII characters.
					
						July 16, 2007 - Michal Caplygin
						Altered the alpha regular expression to enable cursor movement when editing files 
						containing non-ASCII characters.
						
					Scroll Past EOL/EOF Support
					
					-	CTRL+(SHIFT)+LEFT does not behave correctly with this setting enabled:
						Settings > Program Settings > Editor (part 1) > Scroll pas EOL and EOF
						
						November 22, 2007 - Petr Matejka killed this bug.  
						Petr patched the ueCL, ueCSL and ueCSR functions (see PM notes in comments).
					

	°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•°•
*/

var module_name	= "Ingkcpos";
var module_ver		= "0.6";
var module_title	= 
	"CTRL+(SHIFT)+LEFT/RIGHT cursor navigator";
var white =	/\s/;																					// Specify whitespaces, alphanumerics and delimiters
var alpha = /[^\s\~\!\@\#\$\%\^\&\*\(\)\_\+\{\}\|\:\<\>\?\`\-\=\[\]\\\;\,\.\/\"\']/;	
var delim =	/[\~,\!,\@,\#,\$,\%,\^,\&,\*,\(,\),\_,\+,\{,\},\|,\:,\<,\>,\?,\`,\’,\-,\–,\—,\=,\[,\],\\,\;,\,,\.,\/,\",\']/;

var settings_keys = ['white', 'alpha', 'delim'];

var fso = new ActiveXObject("Scripting.FileSystemObject");
var shl = new ActiveXObject("WScript.Shell");

function Init() 
{
	/* Adds this extension to the PSPad Script menu
		and assigns hot keys.
	*/
	
	// Load settings
	var dataFilePath = settingsFolder() + "\\settings.dat";
	
	if (fso.FileExists(dataFilePath)) {
    var config = loadSettingsFile(dataFilePath);
    for (i=0; i<settings_keys.length; i++) {
      if (typeof(config[settings_keys[i]]) != 'undefined') {
        // use eval because they are regexps
        this[settings_keys[i]] = eval(config[settings_keys[i]]);
      }
    }
	}

	addMenuItem("CTRL+RIGHT","Ingkcpos","ueCR","CTRL+RIGHT");
	addMenuItem("CTRL+LEFT","Ingkcpos","ueCL","CTRL+LEFT");			
	addMenuItem("CTRL+SHIFT+RIGHT","Ingkcpos","ueCSR","CTRL+SHIFT+RIGHT");
	addMenuItem("CTRL+SHIFT+LEFT","Ingkcpos","ueCSL","CTRL+SHIFT+LEFT");
	addMenuItem("-","Ingkcpos","","");														// Menu divider
	addMenuItem("Edit this script","Ingkcpos","editMe");								// Edit this script in PSPad
	//addMenuItem("Settings...","Ingkcpos","showConfig");								// Edit this script in PSPad
 	addMenuItem("-","Ingkcpos","","");														// Menu divider
	addMenuItem("About","Ingkcpos","about","");											// About this extension
	return;
}

function settingsFolder() {
  return fso.GetFile(moduleFileName(module_name)).ParentFolder.Path + "\\" + module_name;
}

function showConfig() {
  // Write current values to temp file
  var tempFilePath = settingsFolder() + "\\temp.dat";
  var htaFilePath  = settingsFolder() + "\\settings.hta";
  var dataFilePath = settingsFolder() + "\\settings.dat";
  var config = {};
  for (i=0; i<settings_keys.length; i++) {
    config[settings_keys[i]] = this[settings_keys[i]];
  }
  saveSettingsFile(tempFilePath, config);
  
  // Call the settings dialog [synchronously]
  shl.Run('mshta.exe "' + htaFilePath + '" "' + tempFilePath + '"', 1, true);
  sleep(50);

  if (!fso.FileExists(tempFilePath)) {
    // Cancel or dialog closed - do nothing
    return;
  }
  config = loadSettingsFile(tempFilePath);
  
  // Apply and save
  for (i=0; i<settings_keys.length; i++) {
    if (typeof(config[settings_keys[i]]) != 'undefined') {
      // use eval because they are regexps
      this[settings_keys[i]] = config[settings_keys[i]] = eval(config[settings_keys[i]]);
    }
  }
  
  saveSettingsFile(dataFilePath, config);
}


function editMe() 
{
	/*	Edit this script in PSPad.
	*/
	
	oEdit = newEditor();
	oEdit.openFile(moduleFileName(module_name));
}


function constructEditor() 
{
	/* Construct new editor object, get line text and
		set trim.
	*/

	ed = newEditor();																				// Construct new editor object.
	try {
		ed.assignActiveEditor();																// Assign active editor window.
		
	} catch(e) {
		echo("Failed to assign active editor window.");
		return;															
	}
	line = ed.lineText();																		// Get current text line.
	curx = ed.caretX();																			// Current cursor column position.
	cury = ed.caretY();																			// Current cursor row position.
	trim = 0;																						// Tally of trimmed characters.
	return;
}


function ueCR() 
{
	/* UltraEdit/TextPad [ CTRL+RIGHT ] cursor behavior:
		move to next right-context cursor stop.
	*/

	constructEditor();																			// Construct editor obj, etc.
	var posx = curx - 1;																			// String pos begins at 0, cursor begins at column 1.
	if (curx >= line.length) {																	// IF cursor at end-of-line,
		//ed.command("ecNextLineStart");														// move to start of next line.
		curx = 0;
		cury++;
		
	} else {																							// ELSE find next CTRL+RIGHT stop
		var c = line.charAt((posx + trim));
		if (c.match(white)) {																	// CURSOR ON WHITE SPACE:
			trim += 
				count((line.slice(posx + trim)), white);									// move over white spaces,
			var c = line.charAt((posx + trim));
			if (c == '$') {																		// move over $ trailing whites.
				trim++;
			}

		} else 
		if (c.match(delim)) {																	// CURSOR ON DELIMITER:
			trim += 
				count((line.slice(posx + trim)), delim);									// move over delimiters,
			c = line.charAt((posx + trim));
			trim +=
				count((line.slice(posx + trim)), white);									// move over white space trailing delims,
			c = line.charAt((posx + trim));
			if (c == '$') {																		// move over $ trailing whites.
				trim++;
			}

		} else 
		if (c.match(alpha)) {																	// CURSOR ON ALPHANUMERIC:
			trim +=
				count((line.slice(posx + trim)), alpha);									// move over alphanumerics,
			c = line.charAt((posx + trim));
			trim +=
				count((line.slice(posx + trim)), white);									// move over white space trailing alphas,
			c = line.charAt((posx + trim));
			if (c == '$') {																		// move over $ trailing whites.
				trim++;
			}
		}
		curx += trim;																				// Account for trimmed chars.
	} // IF (cursor at end of line)	
	ed.caretX(curx);																				// Reposition cursor column.
	ed.caretY(cury);																				// Reposition cursor row.
	return;
}


function ueCL() 
{
	/* UltraEdit/TextPad [ CTRL+LEFT ] cursor behavior: 
		move to next left-context cursor stop.
	*/

	constructEditor();																			// Construct editor obj, etc.
	var posx = line.length - curx + 1;														// Column position in string.
	if (curx == 1) {																				// IF cursor at start-of-line,
		if (cury > 1) {																			// PM: if not on first line
			ed.command("ecUp");																	// PM: move cursor up
			ed.command("ecLineEnd");															// PM: and to the end of line
		}
		
	} else 
	if (curx > line.length + 1) {																// PM: if beyond end of line
		ed.command("ecLineEnd");																// PM: move cursor to the end of line

	} else {																							// ELSE find next CTRL+LEFT stop
		line = line.reverse();																	// Reverse the text to leverage CTRL-RIGHT logic. PM: moved from beginning of the function to here, no need to run it every time
		var c = line.charAt((posx + trim));
		if (c == '$') {																			// CURSOR ON $:
			trim++;																					// move over $.

		} else
		if (c.match(white)) {																	// CURSOR ON WHITE SPACE:
			trim +=
				count((line.slice(posx + trim)), white);									// move over white spaces,
			trim +=
				count((line.slice(posx + trim)), alpha);									// move over alphas.
			var c = line.charAt((posx + trim));
			
		} else 
		if (c.match(delim)) {																	// CURSOR ON DELIMITER:
			trim +=
				count((line.slice(posx + trim)), delim);									// move over delimiters,
			
		} else 
		if (c.match(alpha)) {																	// CURSOR ON ALPHANUMERIC:
			trim +=
				count((line.slice(posx + trim)), alpha);									// move over alphanumerics,
		}
		curx = curx - trim;																		// Account for trimmed chars.
		ed.caretX(curx);																			// Reposition cursor.
	} // IF (cursor at start-of-line)
	return;
}


function ueCSR() 
{
	/* UltraEdit/TextPad [ CTRL+SHIFT+RIGHT ] cursor 
		behavior: move and select tax through next 
		right-context cursor stop.
	*/

	constructEditor();																			// Construct editor obj, etc.
	var posx =	curx - 1;																		// String pos begins at 0, cursor begins at column 1.

	if (curx >= line.length) {																	// If cursor at end-of-line,
//		ed.command("ecSelRight");																// continue selection to start of next line. PM: command replaced
		ed.command("ecSelDown");																// PM: Move selection to the next line
		ed.command("ecSelLineStart");															// PM: Move selection to the begging of the line
	
	} else {																							// ELSE find next CTRL+RIGHT stop
		var c = line.charAt((posx + trim));
		if (c.match(white)) {																	// CURSOR ON WHITE SPACE:
			trim +=
				count((line.slice(posx + trim)), white);									// move over white spaces,
			var c = line.charAt((posx + trim));
			if (c == '$') {																		// move over $ trailing whites.
				trim++;
			}

		} else 
		if (c.match(delim)) {																	// CURSOR ON DELIMITER:
			trim +=
				count((line.slice(posx + trim)), delim);									// move over delimiters,
			c = line.charAt((posx + trim));
			trim +=
				count((line.slice(posx + trim)), white);									// move over white space trailing delims,
			c = line.charAt((posx + trim));
			if (c == '$') {																		// move over $ trailing whites.
				trim++;
			}

		} else 
		if (c.match(alpha)) {																	// CURSOR ON ALPHANUMERIC:
			trim +=
				count((line.slice(posx + trim)), alpha);									// move over alphanumerics,
			c = line.charAt((posx + trim));
			trim +=
				count((line.slice(posx + trim)), white);									// move over white space trailing alphas,
			c = line.charAt((posx + trim));
			if (c == '$') {																		// move over $ trailing whites.
				trim++;
			}
		}
		for (n=0; n < trim; n++) {																// Position cursor by
			ed.command("ecSelRight");															// selecting each trim char.
		}
	}
	return;
}


function ueCSL() 
{
	/* UltraEdit/TextPad [ CTRL+SHIFT+LEFT ] cursor 
		behavior: move and select tax through next 
		left-context cursor stop.
	*/

	constructEditor();																			// Construct editor obj, etc.
	var posx = line.length - curx + 1;														// Column position in string.
	if (curx == 1) {																				// If cursor at start-of-line,
//		ed.command("ecSelLeft");																// continue selection to end of previous line. PM: Command replaced
		if (cury > 1) {																			// PM: If not on first line
			ed.command("ecSelUp");																// PM: move selection on line up
			ed.command("ecSelLineEnd");														// PM: and to the end of line
		}
		
	} else 
	if (curx > line.length+1) {																// PM: if beyond end of line
		ed.command("ecSelLineEnd");															// PM: move selection to the end of line
	
	} else {																							// ELSE find next CTRL+LEFT stop
		line = line.reverse();																	// Reverse the text so as to reuse CTRL-RIGHT logic. PM: moved from beginning of the function to here, no need to run it every time
		var c = line.charAt( (posx + trim) );
		if (c == '$') {																			// CURSOR ON $:
			trim++;																					// move over $.

		} else
		if (c.match(white)) {																	// CURSOR ON WHITE SPACE:
			trim +=
				count((line.slice(posx + trim)), white);									// move over white spaces,
			trim +=
				count((line.slice(posx + trim)), alpha);									// move over alphas.
			var c	 = line.charAt( (posx + trim) );

		} else 
		if (c.match(delim)) {																	// CURSOR ON DELIMITER:
			trim +=
				count((line.slice(posx + trim)), delim);									// move over delimiters,

		} else 
		if (c.match(alpha)) {																	// CURSOR ON ALPHANUMERIC:
			trim +=
				count((line.slice(posx + trim)), alpha);									// move over alphanumerics,
		}
		for (n=0; n < trim; n++) {																// Position cursor by
			ed.command("ecSelLeft");															// selecting each trim char.
		}
	} // IF (cursor at start-of-line)
	return;
}


function about() 
{
	/*	Extension description, how to use, license, 
		open source project web address, and developer 
		credits. 	
	*/

	echo(
		"\n" + module_name + " " + module_ver + "\n\n" +
		"_________________\n" +
		"DESCRIPTION\n\n" +
		"   PSPad Editor extension to enhance native\n" +
		"   cursor behavior.\n" +
		"_________________\n" +
		"USE\n\n" +
		"   [ CTRL+RIGHT ] and [ CTRL+LEFT ] move the\n" + 
		"   cursor to the next right/left-context stop.\n\n" +
		"   [ SHIFT+CTRL+RIGHT ] and [ SHIFT+CTRL+LEFT ]\n" +
		"   select text with each move.\n" +
		"_________________\n" +
		"CREDITS\n\n" +
		"   www.sf.net/projects/ingkcpos\n\n" +
		"   MIT License\n" +
		"   Copyright (c) July 2007 Damion Hänkejh, ingk.com\n" +
		"   www.opensource.org/licenses/mit-license.php\t\t\n\n" +
		"   Contributing developer(s):\n" +
		"   AndyBridges, Michal Caplygin, GriGri, Petr Matejka\n"
	);
	return;
}


function count(text, charType) 
{
	/* Count consecutive regex:charType characters
		in string:text.
	*/

	var n = 0;
	var c = text.charAt(n);
	while (c.match(charType)) {																// While char is regex:charType
		n++;																							// move cursor forward,
		c = text.charAt(n);																		// get next char.
	}
	return n;
}


String.prototype.reverse = 
	function() 
	{
		/* Return the string reversed.
		*/

		var s = "";
		var n = this.length;
		while (n > 0) {
			s += this.substring((n - 1), n);
			n--;
		}
		return s;
	}


function loadSettingsFile(path) 
{
  var ts = fso.OpenTextFile(path, 1);
  var settings = {};
  var line = "";
  var bits = null;
  var eq = null;
  var key, value;

  while (!ts.AtEndOfStream) {
    // Read line and trim
    line = ts.ReadLine().replace(/^\s+|\s+$/g, '');
    eq = line.indexOf('=');
    if (eq != -1) {
      key = line.substr(0, eq);
      value = line.substr(eq+1);
      settings[key] = unescape(value);
    }
  };

  ts.Close();

  return settings;
}

function saveSettingsFile(path, settings) 
{
  //echo("Saving settings to " + path);
  var ts = fso.CreateTextFile(path, true);
  for (key in settings) {
    ts.WriteLine(key + "=" + escape(settings[key]));
  }
  ts.Close();
}
