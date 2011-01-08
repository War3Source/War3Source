
====== About War3Source (W3S) ======

War3Source (W3S) brings the Warcraft 3 leveling style and races into the game.
It is originally based on the amxmodx (AMX) version War3FT.

Each standard race has total of 16 levels, made up of 3 skills and 1 ultimate 
where each skill/ultimate can be leveled 4 times for a total of 16 levels.

War3Source features a modular design where races can be coded independently and loaded into the main plugin.
Independent plugins (Addons) can be created to complement or change aspects War3Source.

There are also items in W3S as there are in all Warcraft mods.

War3Source is written in SourcePawn under the SourceMod extension.

War3Source is not WCS (warcraft-source), and we ask that you do not call it 
or refer to it as WCS (or even just "warcraft source") for any reason. 
W3S and WCS are similar such as they can feature the same races and they bring forth the same style of gameplay, 
but they are two completely different projects.
War3Source offerers unbeatable performance and quality under SourcePawn and involves more interaction between races,
and has a buff/debuff system where races are expected to respect other race's buffs and debuffs.

W3S came first to the source engine, WCS came later but matured faster under the nature of ES/Python prototyping 
languages but is limited in performance and features compared to W3S. 

W3S was originally founded by Anthony Iacono (AKA "pimpinjuice") and is also the founder of superhero mod (SH).
Yi (Derek) Luo (AKA "Ownage | Ownz", "DarkEnergy") is the second developer of War3Source 
and took over primary develpement after march 2010.



====== INSTALLATION ======

Please read all instructions before installing or follow the directions below: 
http://war3source.com/wiki/

War3Source REQUIRES SDKHOOKS
http://forums.alliedmods.net/showthread.php?t=106748
download the correct version (likely CSS/TF2/DODS)

DO NOT USE COMMAND SPAMMING KICKER ON YOUR SERVER! WAR3SOURCE IS COMMAND INPUT INTENSIVE!

We do not recomend strict sv_pure. You should know what you are doing if you are using sv_pure.

If you are upgrading from a previous version, 
you may not have to do all of the below...just upload new files / changes you want to apply.
It is recommended to always overwrite every .smx file.
(if you already have your config files modified, apply changes appropriately)
It is recommended to always update translations folder, gamedata folder, and sounds folder.

Each version may have specific installation instructions, please read the release notes (the topic on the release) and the changelog(.txt)

--------------
The installation breakdown:

Put stuff in the 'addons' beings in your 'addons' folder 

Put stuff in 'compiled' beings in your 'addons/sourcemod/plugins/war3source' (i highly recommend its own folder within the plugins folder)

Put stuff in 'sound' beings in your 'sound' folder (always overwrite all on this one)

If you have a fast download mirror, put 'sound' into the appropriate location on your fast download mirror

(Advanced users only:) If you wish to add custom races or content / learn to program SM and W3S, put "*.sp" files and "W3SIncs" in your designated programming (scripting) folder

----------------------------------
Note on upgrading while server is running:

You may overwrite the files while the server is running. YOU MUST do an "sm plugins unload_all", and then CHANGE THE MAP to force sm plugins to reload. This may or may not work for you.

War3Source will execute /cfg/war3source.cfg (case sensitive on linux) ONCE, after all races and items are loaded. 
Please put war3source specific cvars in here such as cooldowns etc

see war3source associated Cvars and Commands, use "cvarlist war3" AND "war3 cvarlist" on the server console

ALWAYS check your ERROR LOGS if war3source does not load correctly! Go to the forums for further help.


