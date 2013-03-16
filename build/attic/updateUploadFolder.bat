rem     Simple windows script to update upload folder with files from test environment
rem     Copyright (c) 2012-2013 Mark A. Taff <mark@marktaff.com>


@echo off
rem set cwd=%cd%
rem echo "%cwd%"

rem     Copy the files needed for test server from mod folder to upload folder

set sourceDirectory="C:\Users\Mark\work\rotu\trunk\rotu21"
set modDirectory="C:\Program Files (x86)\Activision\Call of Duty 4 - Modern Warfare\Mods\rotu21"
set uploadDirectory="C:\Users\Mark\Desktop\rotu2.2.upload"

copy %modDirectory%\ban.txt %uploadDirectory%\ban.txt /Y

copy %modDirectory%\server.cfg %uploadDirectory%\server.cfg /Y
copy %modDirectory%\damage.cfg %uploadDirectory%\damage.cfg /Y
copy %modDirectory%\didyouknow.cfg %uploadDirectory%\didyouknow.cfg /Y
copy %modDirectory%\admin.cfg %uploadDirectory%\admin.cfg /Y
copy %modDirectory%\mapvote.cfg %uploadDirectory%\mapvote.cfg /Y
copy %modDirectory%\weapons.cfg %uploadDirectory%\weapons.cfg /Y
copy %modDirectory%\easy.cfg %uploadDirectory%\easy.cfg /Y

copy %modDirectory%\mod.ff %uploadDirectory%\mod.ff /Y

copy %modDirectory%\2d.iwd %uploadDirectory%\2d.iwd /Y
copy %modDirectory%\rotu_svr_custom.iwd %uploadDirectory%\rotu_svr_custom.iwd /Y
copy %modDirectory%\rotu_svr_scripts.iwd %uploadDirectory%\rotu_svr_scripts.iwd /Y
copy %modDirectory%\ru.iwd %uploadDirectory%\ru.iwd /Y
copy %modDirectory%\sas.iwd %uploadDirectory%\sas.iwd /Y
copy %modDirectory%\sound.iwd %uploadDirectory%\sound.iwd /Y
copy %modDirectory%\spe.iwd %uploadDirectory%\spe.iwd /Y
copy %modDirectory%\weapon_skins.iwd %uploadDirectory%\weapon_skins.iwd /Y
copy %modDirectory%\weapons.iwd %uploadDirectory%\weapons.iwd /Y
copy %modDirectory%\z_skins.iwd %uploadDirectory%\z_skins.iwd /Y
copy %modDirectory%\zz_clan_menu.iwd %uploadDirectory%\zz_clan_menu.iwd /Y
copy %modDirectory%\zz_clan_outro.iwd %uploadDirectory%\zz_clan_outro.iwd /Y
copy %modDirectory%\zz_knife.iwd %uploadDirectory%\zz_knife.iwd /Y
copy %modDirectory%\zz_skins.iwd %uploadDirectory%\zz_skins.iwd /Y


copy %modDirectory%\bipo.public.domain.dedication.png %uploadDirectory%\bipo.public.domain.dedication.png /Y

rem     Now you can upload the files to the server
