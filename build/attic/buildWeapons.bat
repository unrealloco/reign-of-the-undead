@echo off

rem This file rebuilds the weapons.iwd file

del weapons.iwd

xcopy weapons ..\..\raw\weapons /SY

7za a -r -tzip weapons.iwd weapons

pause
