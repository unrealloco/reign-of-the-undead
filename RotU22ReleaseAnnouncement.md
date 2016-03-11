## RotU 2.2 Release Announcement ##
March 16, 2013

We are pleased to announce the public release of Reign of the Undead 2.2, which represents over 900 hours of work.  Many bugs have been fixed, and many new features have been implemented.  See the full changelog for details.

### Thanks ###
I couldn't have done this on my own.  I'd like to thank Bipo and the other original contributors for their work in developing RotU through version 2.1.  I'd also like to thank Bipo for open-sourcing RotU when he decided to move on to other projects.

Pulsar's support was instrumental during the development of RotU 2.2.  He provided me with a test server, as well as ideas for new features and bugs to be fixed.  Also, the |PZA| admins and players were quite supportive through numerous server restarts and download loops, and were instrumental in testing the features being developed.

Thanks to smokinjoe for providing us with a free 1.7 development server, and also for testing whether the binary version of RotU 2.2 would even run on a 1.7 server.

Thanks to Jerkan for creating a new official test map for RotU 2.2.  The entire source (and generated files) for this map are in the repository.  The intent is that this map will serve as a useful learning tool for new mapmakers, as well as informing veteran map-makers about some **very** common bugs in their maps.

### Support for Mapmakers ###
Mapmakers that wish to open-source their maps may use this code repository for their source code, and also for binary releases of their maps.  If this interests you, send me an email, and we will get you credentials for read-write access to the repository.

### Support ###
We have created many wiki pages of documentation to help our users make full use of this release.  Please read [Writing Useful Bug Reports](WritingUsefulBugReports.md) before submitting any bug reports.

### Get the Release ###
The binary version is available from the 'Downloads' tab.  The source code is available using a subversion client, as explained in [Setting Up a Development Environment](DevelopmentEnvironment.md).  For RotU 2.2, checkout [revision 37](https://code.google.com/p/reign-of-the-undead/source/detail?r=37).  If you checkout head, you will get the current code, including changes made since I packaged RotU 2.2 for release.

### Known Issues ###
We have opened several bug reports detailing a few of the known issues.  I didn't have time to give the usables system the TLC it needs, but I decided we could live with those bugs for a while in the interest of releasing this code.

### Blacklisted Maps ###
Some maps are known to cause severe problems, and are thus blacklisted.  The blacklisting will be removed in a future release if the map-makers fix their maps.

  * mp\_surv\_ffc\_parkorman   // barricade errors
  * mp\_mrx\_castle           // barricade errors
  * mp\_evil\_house           // com\_bottle precache errors, and **many** more
  * mp\_fnrp\_futurama\_v3     // crashes iw3.exe
  * mp\_surv\_aftermath       // prevents server from starting
  * mp\_surv\_bjelovar        // prevents server from starting
  * mp\_surv\_RE4village      // prevents server from starting
  * mp\_surv\_winter\_bo       // prevents server from starting
  * mp\_surv\_moon            // prevents server from starting
  * mp\_surv\_matmata         // prevents server from starting
  * mp\_surv\_ddv\_army        // prevents server from starting
  * mp\_surv\_fregata         // fatal error: xmodel for ak47 doesn't load
  * mp\_surv\_sir2            // fatal error: xmodel for ak47 doesn't load

Old versions of mp\_madhouse\_picnic also prevent the server from starting.  Madhouse has since fixed the problem (due to weapons laying on the ground), so the blacklisting for that map has been removed.

### Deprecated Files ###
`_`mapvoting.gsc, `_`zombiescript - kopie.gsc, and `_`zombiescript2.gsc are deprecated, and will be removed from the next release, so I suggest not using them in any customizations you do.

### Future Plans ###
There is no RotU 2.3 planned at this time.  We will continue fix bugs and implement a few more features.  As we get a reasonable amount of work done, we will release a 2.2.x version, with the first being 2.2.1.

### Changelog ###
  * Secondary abilities in UI cleaned up to prevent the UI from tricking players into thinking there are actually secondary abilities
  * The abilities shown on the class menu are actually implemented now
  * New 'Last Man Standing' ability for soldiers, scouts, and engineers: 80% less damage while reviving if they are the last player alive
  * Player Alive/Down counts are now correct, so the game will never think there are still players alive when everyone is actually down
  * The bug that lead to the assassin's invincibility glitch and spectator glitching is fixed
  * The HUD now displays current wave / total waves
  * You can now have an arbitrary number of waves
  * You can now have an arbitrary number of special waves up to one wave less than the total waves
  * The order of the regular and special waves is now pseudo-random
  * New zombie type: burning (exploding) dogs.  Running dogs with flames, they explode when killed.
  * New zombie type: burning (exploding) tank zombies.  Tank (hell) zombies with flames, they explode when killed.
  * New zombie type: cyclops. Like a boss zombie, but much easier to kill, and can be damaged with gun fire as well as explosives and knifing.
  * New special wave type: cyclops.  1-2 fewer cyclops than the number of players, with at least one cyclops.
  * New special wave type: runners.  Nothing but sprinting zombies.
  * New special wave type: burning dog.  Burning (exploding) dogs.
  * New special wave type: burning tank (hell).  Burning (exploding) tank zombies.
  * New special wave type: inferno.  Inferno is a pseudo-random mix of burning zombies, burning dogs, and burning tank.
  * New special wave type: random.  A pseudo-random mix of all the special zombies
  * Only admin can leave and rejoin the game during a wave.  Regular players must wait until the current wave is finished to rejoin.
  * Admin can join a game, even if there are not enough survivors alive.
  * In regular waves, every nth zombie is a pseudo-random special zombie.  Default is every 10th, configurable.
  * The number of zombies in a special wave is now 33% of what the regular wave would be instead of 25%, and this setting is now configurable.
  * In the second half of the game, zombies' health, damage, and speed increases between 20% and 60% for various zombies. You can now scale these overall increases from 0% to 100%.
  * Up to 60 in-game 'Did You Know' messages, configurable.  Four are scrolled though between each wave.
  * Claymores are now implemented
  * C4 now works, even if the player had once become a zombie.
  * Per-player maximum emplaced and on-hand claymores and C4 is settable in weapons.cfg. Max on-hand ammo for these weapons is still governed by their respective weapon\_mp files.
  * New welcome messages welcome a player by name, and tell them their prestige level
  * Players get an upgrade point bonus for each prestige level when they first join the game.
  * Special weapons are implemented and available during the last half of the game to players that have prestiged and continue to prestige as possible.
  * New map voting UI.  Allows for 13 pseudo-random maps to be displayed.  Option to replay the current map if the players lost.  New 'None of The Above' option gives players a second chance at voting with a new map selection.  The UI tells you which map you have voted for, and lists the players that voted for each map, in real-time.
  * Map voting no longer depends on the map rotation dvar, but instead uses up to seven of its own dvars, allowing for well over 175 maps to be available for voting.
  * It is now possible to specify a list of maps that should appear in map voting at a reduced frequency, and also at a greatly reduced frequency.
  * Map voting uses an English name (configurable) for the maps rather than the code name for the map
  * The source code and the configuration files are now documented with doxygen-style documentation.
  * New admin system with fine-grain powers allows the server owner great flexibility in granting admin powers.
  * New in-game admin menu for punishing, warning, banning, and rewarding players. The menu also permits finishing or restarting waves and maps, as well as changing the map.  Admin can operate in a stealth session where their actions are not broadcast to other players (default setting) or they can make their session visible so players are informed of their actions.  Admin can cure, revive, down, teleport, healing aura, ammo can, promote, demote, give upgrade points, and much more.
  * New warning system warns, then temp bans and perm bans for language and regular warnings (distinct counts). Warnings are persistent just like rank.  How many warnings of each type will result in a temp ban or a permanent ban is configurable.
  * New debugging system that can print function entrance messages, value messages, and emitted signals.  Debugging system has seven verbosity levels.
  * New headicons for admin, engineers, medics, and moderately-low health.
  * The number of assassins, engineers, and medics in the game is now limited.  These limits do not apply to admin.
  * New demerits system that issues persistent demerits for being a poor team player. After 20 demerits (configurable), the player loses 500 rank points.
  * Over 175 maps have been tested with 2.2.  Those that cause grievous errors are black-listed so they cannot be voted on or loaded.  Our test server currently has 155 maps that are known to work and may be voted on.
  * Thousands of run-time errors and race conditions have been fixed.
  * The 2.2 server starts/restarts very quickly compared to 2.1.
  * Several maps have been fixed to resolve precache and bg\_fallDamage[Min|Max]Height issues
  * dustrailsIR effect is now precached in the mod to fix maps that call for the effect but don't precache it themselves.  Ditto for com\_bottle[1|2|3|4].
  * Minimap shows a 'kill' objective on each player-zombie to help others find and kill them
  * Minimap show a flashing red exclamation mark on down players to help others find them
  * 'Autotext' feature tells players when a player is down, and asks them to revive if possible
  * Players now get rank and upgrade points for covering the revival of another player during a wave
  * The number of rank points for large killing sprees has been greatly reduced to limit the benefit of spree glitching
  * Ammo boxes are now biased towards other players and non-engineers.  The primary way for an engineer to get ammo is to use their special.  The better an engineer is at giving other players ammo, the more frequently they can throw an ammo box.  Special weapons are now (slowly) reloadable from ammo boxes.
  * MG + barrel now works without force-disconnecting players
  * Player spawn protection makes players invincible for 2 seconds after they spawn
  * PERL script to merge ban.txt files from multiple mods on multiple servers (manual downloading and uploading still required).
  * **DEPRECATED** Multiple compile scripts so you can re-compile just the portions that you have changed rather than the entire mod.  Also scripts to facilitate using subversion and uploading files to the game server. Located in build\attic
  * New build system, makeMod.pl, builds the mod without leaving detritus laying about. It will only rebuild the parts that need to be rebuilt, based on changes it detects to the source code.  It can be forced to do a full rebuild.  It can perform a multitude of code-quality checks.  It can produce a listing of every function definition and where it is defined, and each place it is used in the code.  It creates debug and non-debug versions of the server scripts.  It can clean the mod, removing almost all traces that it had ever been there.
  * About two-dozen deprecated files have been removed.
  * Players get no points for killing a burning zombie if they damage a teammate in the process
  * New end-game credits display, with multiple server providers permitted in the config file
  * Server.cfg file has been split into several smaller config files, including an easy.cfg to facilitate running an 'easy' version of the game
  * Grenade and minigun defense turrets now work, and are configurable in weapons.cfg. Each player may own only one turret at a time.  Turrets disappear when they run out of ammo, not after a preset time. Grenade and minigun turrets are unlocked at different prestige levels (configurable).  Turrets do not lag the game.
  * Players now get upgrade points for damaging a player-zombie, to help defray the cost of expended ammunition and such.
  * New string library
  * New array library
  * New matrix library
  * Can turn on/off each type of debug statement from server.cfg, and also set the debug verbosity.
  * Auto-spawning when the next wave begins or when there are enough player's alive now works.
  * Can change class anytime and respawn immediately, if you have enough upgrade points. The cost of changing your class is the sum of health + ammo + cure from the shop
  * Admin menu works while spectating, hit the 'use' key to open
  * Development console "admin:" messages configurable in server.cfg
  * Removed source of burning human and ambient sound errors when building the mod. Only the non-consequential rumble errors remain.
  * Axis and Allies team names can now be set in server.cfg
  * Final Zombie now has up to four kill methods: explosives, primary weapon, sidearm, and knifing.  Each type can be turned on/off from server.cfg.  Each type also has a difficulty factor, configurable in server.cfg, to make each type easier or harder.  There is also a new factor set in server.cfg to make the kill balls appear more or less frequently.
  * The number of zombies in the next wave is now calculated just before the wave starts instead of immediately after the previous wave ended.
  * Timeout that ends god-mode when the admin menu is closed is settable in admin.cfg
  * Teleporters now work properly on legacy maps (maps that don't use waypoints)
  * New home of the source code: http://code.google.com/p/reign-of-the-undead/