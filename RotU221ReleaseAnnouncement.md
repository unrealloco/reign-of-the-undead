## RotU 2.2.1 Release Announcement ##
May 30, 2013

We are pleased to announce the public release of Reign of the Undead 2.2.1.  Some rather irritating bugs have been fixed, and some new features have been implemented, the largest of which is the new Unified Mapping Interface (UMI).  See the full changelog for details.

### Thanks ###
I couldn't have done this on my own.  Some of these bug fixes are a direct result of bug reports users have filed, so please keep making good bug reports.

### Support ###
We have created many wiki pages of documentation to help our users make full use of this release.  Please read [Writing Useful Bug Reports](WritingUsefulBugReports.md) before submitting any bug reports.

### Get the Release ###
The binary version is available from the 'Downloads' tab.  The source code is available using a subversion client, as explained in [Setting Up a Development Environment](DevelopmentEnvironment.md).  For RotU 2.2.1, checkout [revision 104](https://code.google.com/p/reign-of-the-undead/source/detail?r=104).  If you checkout head, you will get the current code, including changes made since I packaged RotU 2.2.1 for release.

### Upgrading From RotU 2.2 ###
Simply copy the new files over the old ones, **except** for the `*`.cfg files.  For the config files, it is probably easier if you use the links to the diffs (below) to see what changes have been made and then just manually update your config files.

damage.cfg: http://code.google.com/p/reign-of-the-undead/source/diff?spec=svn104&old=30&r=102&format=side&path=%2Ftrunk%2Fsrc%2Fdamage_default.cfg

didyouknow.cfg: http://code.google.com/p/reign-of-the-undead/source/diff?spec=svn104&r=102&format=side&path=/trunk/src/didyouknow_default.cfg&old_path=/trunk/src/didyouknow_default.cfg&old=30

easy.cfg: http://code.google.com/p/reign-of-the-undead/source/diff?spec=svn104&r=102&format=side&path=/trunk/src/easy_default.cfg&old_path=/trunk/src/easy_default.cfg&old=30

mapvote.cfg: http://code.google.com/p/reign-of-the-undead/source/diff?spec=svn101&old=36&r=102&format=side&path=%2Ftrunk%2Fsrc%2Fmapvote_default.cfg

server.cfg: http://code.google.com/p/reign-of-the-undead/source/diff?spec=svn101&old=30&r=102&format=side&path=%2Ftrunk%2Fsrc%2Fserver_default.cfg

weapons.cfg: http://code.google.com/p/reign-of-the-undead/source/diff?spec=svn101&old=30&r=102&format=side&path=%2Ftrunk%2Fsrc%2Fweapons_default.cfg

admin.cfg: http://code.google.com/p/reign-of-the-undead/source/diff?spec=svn101&old=30&r=102&format=side&path=%2Ftrunk%2Fsrc%2Fadmin_default.cfg

### Known Issues ###
The UMI is neither stable nor complete--I reserve the right to change the interface as I see fit until I release RotU 2.2.2.  That isn't to say it doesn't work, because it does.  It just means you shouldn't be surprised if I change function names or add or remove functions entirely.  For examples of UMI files that make non-RotU maps work in RotU, see: http://code.google.com/p/reign-of-the-undead/source/browse/#svn%2Ftrunk%2Fsrc%2Fcustom_maps%2Fmaps%2Fmp

### Deprecated Files ###
`_`mapvoting.gsc, `_`zombiescript - kopie.gsc, and `_`zombiescript2.gsc are deprecated, and have been removed from this release.

`_`zombiescript.gsc has been deprecated in favor of UMI, **however** the `_`zombiescript.gsc interface will be maintained **indefinitely** to ensure backwards-compatibility.  This means that mappers may continue to use `_`zombiescript.gsc for new maps if they choose to.

### Future Plans ###
The next planned release will be RotU 2.2.2, but there is no timetable for that release.  As we get a reasonable amount of work done, we will release a 2.2.2 version.  As support for new maps is added, or when improvements are made to supported non-RotU map data, we will periodically release an updated version of rotu`_`svr`_`mapdata.iwd.

### Changelog ###
  * Enable night vision by default, and at no cost.
  * Note in admin\_default.cfg that at least one admin must be defined for the mod to run
  * Fix teleporters and MG+Barrels so they cannot be emplaced too close to a shop or weapons crate.
  * Fix bug where 'Restore Ammo' at shop restored c4, claymores, and tnt, which permitted players to exceed the per-player limits.  'Restore Ammo' now only restores bullets and grenades, as intended.
  * Implement TNT.
  * Make frag grenades hurt final zombie on 'explosives' kill method
  * Added a clan-specific message to the main menu.  Configurable in server.cfg.
  * Fix for rare bug where barrels appeared to be 'stuck' to a player after they tried to emplace the barrel. See [Issue 6](https://code.google.com/p/reign-of-the-undead/issues/detail?id=6).
  * Issue where rcon password sometimes changed has been fixed.
  * Add ability to sometimes, always, or never show zombies on the minimap.  Configurable in server.cfg
  * Force players to automatically drop a MG+Barrel turret when it runs out of ammo, so their body doesn't become hidden if they don't drop the turret immediately.
  * Fix for an admin sometimes not being recognized as an admin such that they can't open the admin menu.  The issue presented itself when multiple admins connected to the game within one second of each other.
  * Reduce start and max ammo for the gold desert eagle from 500 to 250 rounds.
  * Deprecate and remove the 2.1 map voting system
  * Deprecate and remove `_`zombiescipt2.gsc and `_`zombiescript - kopie.gsc
  * Increased sv\_maptoing dvars to 10, which will allow for about 250 maps
  * Support 12 of the CoD4 built-in maps via UMI--the rest have too many xmodels and will never work with RotU.
  * Enable 'Start New Server' command from RotU menu.  You will need a full install of RotU--the files downloaded while playing on someone's server are insufficient.
  * New Unified Mapping Interface (UMI) replaces `_`zombiescript. Maps written to the `_`zombiescript interface will continue to work.  We can now load maps that require external BTD waypoints and tradespawns.  New file rotu\_srv\_mapdata.iwd holds tradespawn, waypoint, and main script files for non-native RotU maps. I will be writing a wiki tutorial with example files for mappers.  New UMI dev functions to convert RotU waypoints to BTD waypoints and vice-versa. New admin development functions that allow an admin to be given, emplace, delete, and pick up weapon and equipment shops.  When they are satisfied with the shop locations, 'Save Tradespawns' will write a new tradespawns file to the server log.
  * Support three non-RotU maps via UMI: mp\_prunis, mp\_burgundy\_bulls, and mp\_arkona\_osg. We are not distributing these maps--just the files we wrote and the data required to make them run in RotU 2.2.1.  You can get the maps from the usual places.