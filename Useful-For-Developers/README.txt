bat files are provied for you to customize, 
copy them to a War3SourceP (the upper directory) and modify it there, 
DO NOT MODIFY THEM IN THIS FOLDER, THEY CAN GET MESSED UP IN THE REPOSITORY

Also put compiled.exe and spcomp.exe in War3SourceP folder, so the .bat works




We recommend PSPad for programming, it has full directory searching.
SM style syntax highligting included, you maybe have to do some work to make it default on .sp and .inc files


put this in server.cfg


alias res "sm plugins unload_all;wait;wait;wait;changelevel de_dust2"
//it allows you to change map and reload the plugins

