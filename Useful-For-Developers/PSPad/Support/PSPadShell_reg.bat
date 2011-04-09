@Echo off
@Cls
: This batch file registers the PSPad context menu handler
: To unregister it, use PSPadShell_Unreg.bat
Echo.
Echo Trying register PSPadShell.dll using RegSvr32...
Echo.
Echo You need admin rights to registr library
Echo On Windows Vista run this batch with right mouse As Administrator
Echo.
"%SystemRoot%\System32\RegSvr32" "%~d0%~p0\..\PSPadShell.dll"
