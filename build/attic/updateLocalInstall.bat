rem     Simple windows script to rsync --no-delete working copy of mod with installed copy
rem     Copyright (c) 2012 Mark A. Taff <mark@marktaff.com>


@echo off
rem echo "Hello World"
rem set cwd=%cd%
rem echo "%cwd%"

rem     Copy the working copy of the mod to the cod4 folder, skipping zone_source
rem     and *.svn folders, and this script
rem
set sourceDirectory="C:\Users\Mark\work\rotu\trunk\rotu21"
set modDirectory="C:\Program Files (x86)\Activision\Call of Duty 4 - Modern Warfare\Mods\rotu21"

rem     the /TEE and /L switches are just used for script testing
robocopy %sourceDirectory% %modDirectory% /COPYALL /E /XD .svn /XD zone_source /XF updateLocalInstall.bat


rem     Copy the working copy of zone_source to the cod4 zone_source folder,
rem     skipping *.svn folders
rem
set sourceDirectory="C:\Users\Mark\work\rotu\trunk\rotu21\zone_source"
set modDirectory="C:\Program Files (x86)\Activision\Call of Duty 4 - Modern Warfare\zone_source"

rem     the /TEE and /L switches are just used for script testing
robocopy %sourceDirectory% %modDirectory% /COPYALL /E /XD .svn

rem     Now you can run compileMod.bat to compile the mod
