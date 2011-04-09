for /f "tokens=* delims=" %%i in ('dir /s /b /a:d *svn') do (
  rd /s /q "%%i"
)