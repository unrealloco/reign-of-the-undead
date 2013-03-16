@echo off
del 2d.iwd
del sound.iwd
del weapons.iwd
del mod.ff

rem TAFF: added to create missing *.iwd files that are on Pulsar's server
del rotu_svr_custom.iwd
del rotu_svr_scripts.iwd

xcopy ui_mp ..\..\raw\ui_mp /SY
xcopy mp ..\..\raw\mp /SY
xcopy maps ..\..\raw\maps /SY
xcopy weapons ..\..\raw\weapons /SY
xcopy animtrees ..\..\raw\animtrees /SY
xcopy mp ..\..\raw\mp /SY
xcopy english ..\..\raw\english /SY
xcopy sound ..\..\raw\sound /SY
xcopy soundaliases ..\..\raw\soundaliases /SY
xcopy xanim ..\..\raw\xanim /SY
xcopy xmodel ..\..\raw\xmodel /SY
xcopy xmodelparts ..\..\raw\xmodelparts /SY
xcopy xmodelsurfs ..\..\raw\xmodelsurfs /SY
xcopy materials ..\..\raw\materials /SY
xcopy material_properties ..\..\raw\material_properties /SY
xcopy fx ..\..\raw\fx /SY
xcopy scripts ..\..\raw\scripts /SY

rem Taff fix for missing files
xcopy images ..\..\raw\images /SY
xcopy material ..\..\raw\materials /SY
xcopy shock ..\..\raw\shock /SY
xcopy vision ..\..\raw\vision /SY


rem compile fast file
copy /Y mod.csv ..\..\zone_source
cd ..\..\bin
linker_pc.exe -language english -compress -cleanup mod
pause
cd ..\mods\rotu21
copy ..\..\zone\english\mod.ff

7za a -r -tzip 2d.iwd images
7za a -r -tzip weapons.iwd weapons
7za a -r -tzip sound.iwd sound

rem TAFF: added to create missing *.iwd files that are on Pulsar's server
7za a -r -tzip rotu_svr_custom.iwd custom_scripts animtrees
7za a -r -tzip rotu_svr_scripts.iwd custom_scripts maps scripts


pause
