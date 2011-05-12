@echo off
del compiled /S /Q
compile
copy "compiled\*.smx" "..\..\plugins\w3s\"
pause