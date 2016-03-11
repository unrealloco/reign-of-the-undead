## RotU 2.2.2 Release Announcement ##
November 23, 2013

We are pleased to announce the public release of Reign of the Undead 2.2.2.  Some rather irritating bugs have been fixed, and some new features have been implemented.  See the full changelog for details.

### Thanks ###
I couldn't have done this on my own.  Some of these bug fixes are a direct result of bug reports users have filed, so please keep making good bug reports.  Thanks to Pulsar's Zombie Admin (|PZA|) and the players on our servers for their help testing new features and bugfixes.

### Support ###
We have created many wiki pages of documentation to help our users make full use of this release.  Please read [Writing Useful Bug Reports](WritingUsefulBugReports.md) before submitting any bug reports.

### Get the Release ###
The binary version is available from the 'Downloads' tab.  The source code is available using a subversion client, as explained in [Setting Up a Development Environment](DevelopmentEnvironment.md).  For RotU 2.2.2, checkout [revision 198](https://code.google.com/p/reign-of-the-undead/source/detail?r=198).  If you checkout head, you will get the current code, including changes made since I packaged RotU 2.2.2 for release.

### Upgrading From RotU 2.2.1 ###
Simply copy the new files over the old ones, **except** for the `*`.cfg files.  For the config files, it is probably easier if you use the links to the diffs (below) to see what changes have been made and then just manually update your config files.

damage.cfg: https://code.google.com/p/reign-of-the-undead/source/diff?spec=svn198&r=197&format=side&path=/trunk/src/damage_default.cfg&old_path=/trunk/src/damage_default.cfg&old=102

didyouknow.cfg: https://code.google.com/p/reign-of-the-undead/source/diff?path=/trunk/src/didyouknow_default.cfg&format=side&r=197&old_path=/trunk/src/didyouknow_default.cfg&old=102

easy.cfg: https://code.google.com/p/reign-of-the-undead/source/diff?format=side&path=/trunk/src/easy_default.cfg&r=197&spec=svn197

mapvote.cfg: https://code.google.com/p/reign-of-the-undead/source/diff?path=/trunk/src/mapvote_default.cfg&format=side&r=197&old_path=/trunk/src/mapvote_default.cfg&old=102

server.cfg: https://code.google.com/p/reign-of-the-undead/source/diff?path=/trunk/src/server_default.cfg&format=side&r=197&old_path=/trunk/src/server_default.cfg&old=102

weapons.cfg: https://code.google.com/p/reign-of-the-undead/source/diff?path=/trunk/src/weapons_default.cfg&format=side&r=197&old_path=/trunk/src/weapons_default.cfg&old=102

admin.cfg: https://code.google.com/p/reign-of-the-undead/source/diff?path=/trunk/src/admin_default.cfg&format=side&r=197&old_path=/trunk/src/admin_default.cfg&old=102

game.cfg: new required file

startnewserver.cfg: new required file

Note that server.cfg has been split into server.cfg and game.cfg--you must apply those changes!

### Known Issues ###
The 'Delete Waypoint Link' command in the UMI Map Editor is very likely to hang the mod, and I haven't taken the time to debug it yet.  I suggest you instead delete one of the linked waypoints, then recreate the deleted waypoint and the links you want.

### Future Plans ###
The next planned release will be RotU 2.2.3, but there is no timetable for that release.  As we get a reasonable amount of work done, we will release a 2.2.3 version.  As support for new maps is added, or when improvements are made to supported non-RotU map data, we **may** release an updated version of rotu`_`svr`_`mapdata.iwd.

### Changelog ###
  * New UMI Map Editor.  Allows creating, editing, linking, and moving waypoints in-game when the map is launched in UMI Editor mode.  The editing menu is available from b then 5 in-game.
  * Improved bot elevation following logic helps prevent bots from getting stuck in stairs.
  * Improved waypoints and tradespawns for map mp\_pipeline.
  * Removed the gameboy-like normal map from claymores.
  * Removed many unused images from yz\_custom.iwd.
  * TNT now works after having been a zombie.
  * Limit TNT to one per on-screen ammo box to prevent engineers from killing all the zombies themselves.
  * AI tweak to make zombies target other players faster when their original target goes down.
  * New 'New Player Assistance' feature to make the game easier for new players while they learn how to play.  When they go down, they are auto-revived, cured, given some upgrade points, and told to 'run to survive'.  This assistance ends at prestige level 0, rank 30.  New players are limited to 3 assists per wave, then they go down as normal.
  * Native GIMP `*`.xcf masks to facilitate skinning player uniforms.  This required some changes to the models used for players, so if you were using custom uniforms already, you will need to customize images for the new models.
  * Explicitly include the dvars needed for special weapons in weapons.cfg
  * Various improvements to the special weapons.
  * Fix bug where prestige 38 used the prestige 3 icon.
  * Add 20 additional prestige levels; max prestige is now 65.
  * Engineer's ammo special now recharges both primary and secondary weapon ammo supply.
  * Improved waypoints for mp\_creek and mp\_farm.
  * Initial waypoints and tradspawns for map mp\_brecourt\_v2.
  * Improved waypoints for map mp\_surv\_new\_moon\_lg.
  * New 'many\_bosses' option for final wave.
  * Deprecated and removed the RotU 2.1 wave count system
  * Reduced rank points for killing sprees and increased the rank points required for each promotion. Between this and the extra prestige levels, it should now take about 3 times as much game-play to max out your prestige.
  * Split server.cfg into server.cfg and game.cfg to facilitate getting local servers working properly.
  * Starting Listen, LAN, and Internet servers now works as expected via playMod.bat, host.bat, and join.bat.
  * Removed recoil from raygun so players can't use it to help get outside of maps.
  * Added a dvar to allow raygun to be purchased anytime, though I think this hurts gameplay.  The prestige limits still apply.
  * Improved waypoints and anti-glitching fixes in map mp\_surv\_zombiedesert.
  * Initial waypoints for map mp\_surv\_boss\_road.
  * Add two unrestricted machine guns to map mp\_surv\_tunnel so that it is actually possible to beat the map.
  * In the UMI Map Editor, if there are more waypoint links than the line() function will draw, only draw the links within 2500 units of the dev player.
  * Fix the bug where players got demerits when their grenade or minigun turret killed burning zombies.
  * Demerits for not reviving players between waves are now real, not simulated.
  * Improved waypoints for map mp\_nwa\_forest\_v2 so zombies are less likely to get stuck on the roof.
  * Make 'Start New Server' menu item work as expected.  Uses the new config file startnewserver.cfg.
  * New 'Server Customization' credit and dvar for people making code changes, skins, etc., on their server.
  * New release() function in makeMod.pl to build and package releases.
  * Admin promote/demote commands now do one rank or 750 rank points instead on 500 points, due to the larger points needed for each rank now.
  * UMI Map Editor shortcuts are disabled on real server to prevent an admin from inadvertently borking a running map.
  * Implement the 'Scouting Drone' passive ability for scouts.
  * New UMI functions to remove built-in turrets from maps, and also for disambiguating built-in barrels from the barrels available for purchase.
  * Initial waypoints and tradespawns for the map mp\_caen.
  * Implement the admin command 'Spawn Spectator', which spawns a spectating player as one of the randomly chosen unrestricted classes: soldier, scout, or armored.