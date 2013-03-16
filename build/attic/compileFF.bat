
del mod.ff

xcopy soundaliases ..\..\raw\soundaliases /SY
copy /Y mod.csv ..\..\zone_source
cd ..\..\bin
linker_pc.exe -language english -compress -cleanup mod
cd ..\mods\rotu21
copy ..\..\zone\english\mod.ff

pause
