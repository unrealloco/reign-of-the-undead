@echo off

rem This file rebuilds the rotu_svr_custom.iwd and rotu_svr_scripts.iwd files

del rotu_svr_custom.iwd
del rotu_svr_scripts.iwd

xcopy maps ..\..\raw\maps /SY
xcopy animtrees ..\..\raw\animtrees /SY
xcopy scripts ..\..\raw\scripts /SY
xcopy custom_scripts ..\..\raw\custom_scripts /SY

7za a -r -tzip rotu_svr_custom.iwd custom_scripts animtrees
7za a -r -tzip rotu_svr_scripts.iwd custom_scripts maps scripts

pause
