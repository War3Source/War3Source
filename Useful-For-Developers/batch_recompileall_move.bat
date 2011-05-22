REM WINDOWS ONLY!!
REM THIS WILL EMPTY YOUR COMPILED FOLDER AND RECOMPILE ALL .sp FILES, then copy them to destination
REM compile.exe must be in this directory

@echo off
del compiled /S /Q
REM old: compile
SMBatchCompile

REM this line is a comment.... Change the path to your liking 
REM you will have to press enter so the compiler exits (it doesnt exit by itself), then it starts copying

xcopy /Y "compiled\*.smx" "S:\srcdscss\orangebox\cstrike\addons\sourcemod\plugins\w3s\*.*" /e /i
xcopy /Y "compiled\*.smx" "U:\home\ownage\Desktop\srcdscss\orangebox\cstrike\addons\sourcemod\plugins\compiled\*.*" /e /i

pause