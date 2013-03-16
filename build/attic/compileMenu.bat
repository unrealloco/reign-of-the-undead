del mod.ff

xcopy english ..\..\raw\english /SY
xcopy ui_mp ..\..\raw\ui_mp /SY
copy /Y mod.csv ..\..\zone_source
cd ..\..\bin
linker_pc.exe -language english -compress -cleanup mod
cd ..\mods\rotu21
copy ..\..\zone\english\mod.ff
