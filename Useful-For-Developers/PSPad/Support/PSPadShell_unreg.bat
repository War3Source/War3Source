@Echo off
@Cls
: This batch file unregisters the PSPad context menu handler
: to sucessfully unregister it, yu need to close PSPad, 
: all Windows explorer windows and other File manager Windows 
: from where you call PSPad using context menu before
Echo.
Echo Trying unregister PSPadShell.dll using RegSvr32...
Echo.
Echo You need admin rights to registr library
Echo On Windows Vista run this batch with right mouse As Administrator
Echo.
"%SystemRoot%\System32\RegSvr32" "%~d0%~p0\..\PSPadShell.dll" /u
