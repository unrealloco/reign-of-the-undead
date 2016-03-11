**Status:** Final

**Applies to:** RotU 2.2

**Intended Audience:** Server administrators, and, to a lesser extent, in-game admins

# Introduction #

This document provides basic information on administering a RotU 2.2 server.  It does not generally cover settings in the `*`.cfg files--documentation for those is inside the individual files themselves.


### Log Files ###

The two main log files are, by default, console\_mp.log and server\_mp.log. The former contains all the error and progress information that is written to the CoD4 console, including dvar settings, compile errors, and run-time errors.  The latter contains chat messages, join/quit events, RotU-specific notices, warnings, and errors, as well as any RotU debugging you may have turned on.

In RotU 2.1 and earlier, there was a bug that over-wrote the console\_mp.log file every time the map changed, resulting in the loss of valuable debug information.  That bug is fixed in RotU 2.2, and the console\_mp.log file is now only overwritten when you restart the server, typically using a web-based control panel provided by your hosting provider.  The server\_mp.log file is **never** over-written.

Because these files are over-written less frequently, it is more likely they will become very large over time.  If you do not need the data they contain, I suggest deleting them when they are above 10 MB or so, just because large files are harder to download and read.

If the server crashes or the game is otherwise buggy, you **must** save a copy of console\_mp.log under another name **before** you restart the server, or you will lose that information, making it nearly impossible for us to fix the bug that caused the issue.

## Maps ##
Most maps made for RotU 1.15, 2.0, and 2.1 work sufficiently well with 2.2.  However, about a dozen are known to prevent the server from starting, or to crash the server at start-up, or to generate so many errors that it threatens server stability.  These maps are blacklisted in the source code--the **only** way to start them is by using an rcon tool or putting them as the first map in the sv\_maprotation dvar temporarily.

In RotU 2.2, the sv\_maprotation dvar is **only** used to choose the map to load when the server first starts, so you only need one map listed in that dvar.  All the map config is located in mapvote.cfg.

### Installing New Maps ###
To install a new map, copy the map's folder to the usermaps folder on the server.  Then edit the mapvote.cfg file.  You will need to add the map to one of the sv\_mapvoting dvars.  These dvars have a maximum allowable character length--if they are too long, the server will fail to load properly. A length of about 620 characters is known to work just fine.  You may have up to seven sv\_mapvoting dvars, which should permit having close to 200 maps eligible to be voted on.

You also need to create a dvar for the "English" name of the map--it is this string that will be the name of the map used in map voting.  Failing to do so will cause a notice to be printed to the server\_mp.log file, and the map name (i.e. mp\_fnrp\_store) will be used as a fallback.

If you try to start a map that isn't in the usermaps folder, when you start the server, you will get a black screen, and there will be no information in the log files.  This can easily happen if you run multiple servers and do not take care to install all maps on all servers, and then copy mapvote.cfg between servers.

There is no harm in having a dvar for the "English" name of a map that isn't installed or listed in one of the sv\_mapvoting dvars.

### Customizing a Map ###
If you run a customized version of a map, please do **not** use the same map name as the stock version of the map, as this will cause players to have to download the map again and again as they play on different servers.  Note that changing the name of the folder for the map itself is insufficient, and will not work--you need to be able to edit the source of the map to change the name.  But if you can do that, please use a unique name for your version to limit unnecessary downloading.

## Uploading Files ##
You may upload `*`.cfg files even when the server is running.  However, they will not be re-read until you restart the server.  You may only upload `*`.iwd files and mod.ff when the server is stopped.  If you have a manual redirect, make sure you upload the new files to the redirect server as well.  If you have an automatic redirect, there may be a download loop for the players until your redirect syncs its files with the main server.  You can bypass the download loop for yourself by manually copying the new binary files to the specific mod's folder in your local CoD4 install.

Changes to the `*`.cfg files and the rotu`_`svr`_*`.iwd files will never cause a download loop, as these files are never downloaded by players.

## Manual Redirect ##
The games servers I have experience with limit downloads to about 10 KiB/s.  If your personal or clan website has enough storage and better bandwith, you can use that website as your manual redirect.

On your website, create a root folder, e.g. 'rotu'.  Then create the folders 'usermaps' and 'mods' inside the 'rotu' folder.  Inside the 'mods' folder create a folder with the same name as your mod on the game sever, e.g. 'rotu22.myclan'.  Copy all the maps from your game server into the 'usermaps' folder on the redirect, then copy all the `*`.iwd files from the rotu folder on the game server to the same folder on the redirect (except for the `*_`svr`_*`.iwd files).

Then set the redirect in server.cfg, e.g.:

`set sv_wwwBaseURL "http://example.com/rotu/"`

## Admin System ##
The admin system is contained in six files:

  * admin.cfg: contains configuration settings for the admin system
  * admin.menu: contains the menu elements that comprise the in-game admin menu
  * adminCommon.gsc: contains functions used by several other files
  * `_`adminCommands.gsc: the actual implementation of the admin commands
  * `_`adminInterface.gsc: an interface that connects the in-game admin menu with `_`adminCommands.gsc
  * `_`rconInterface.gsc: an interface that connects an rcon tool with `_`adminCommands.gsc

### In-game Admin Menu ###
While playing the game, press b then 4 to access the admin menu.  While spectating, press 'use' to access the admin menu.  By default, your admin session will be a hidden 'stealth' session, so players will have little or no notification of your admin actions.  You may toggle your session between visible and hidden with the 'toggle session visibility' command in the admin menu.  When visible, an admin status icon will appear in the scoreboard, and an admin headicon will appear over your head (unless you are injured or infected).

The admin menu behaves differently depending on whether you are visible or not.  For example, we like to ensure we are visible before warning, kicking, temp-banning, or banning a player.  This is because if you are visible, **every** player will see a large notice that the player was punished, which we feel helps to keep other players in line.

While the admin menu is open, and for two seconds after it closes (configurable), the admin player is god and is non-targetable.  Due to race conditions and lag, this isn't flawless, but it usually works quite well.

While the admin menu is open, all the admin powers are listed at the bottom center of the screen.  Those powers you have are in green, those you do not have are in red.

## yz\_custom.iwd ##
The yz\_custom.iwd file consolidates many different zz files that we run on PZA servers.  The mod should run just fine without it, but this has not been tested.  The name was chosen to preserve the zz files ability, and also to give us maximum flexibility for naming core RotU `*`.iwd files in the future.  Perusing this file will give you an idea of the kinds of things you can use zz files to override.