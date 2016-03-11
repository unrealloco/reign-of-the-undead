## RotU 2.2.2-Patch1 Release Announcement ##
January 14, 2014

We are pleased to announce the public release of Patch1 for Reign of the Undead 2.2.2.  This patch fixes some trivial bugs and includes support for 30 additional maps. None of the elements for the new AI or any of the optimizations are included.

### Thanks ###
I couldn't have done this on my own.  UnionJack put in a huge amount of effort porting many of these maps to RotU, and we thank him for his efforts. Thanks to Pulsar's Zombie Admin (|PZA|) and the players on our servers for their help testing new features and bugfixes.

### Support ###
We have created many wiki pages of documentation to help our users make full use of this release.  Please read [Writing Useful Bug Reports](WritingUsefulBugReports.md) before submitting any bug reports.

### Get the Release ###
The binary version is available from the 'Downloads' tab.  The source code is available using a subversion client, as explained in [Setting Up a Development Environment](DevelopmentEnvironment.md).  This patch is in branches\rotu-2.2.2. If you checkout head, you will get the current unstable (and unplayable) code.

### Upgrading From RotU 2.2.2 ###
Replace your existing rotu`_`svr`_`mapdata.iwd and rotu`_`svr`_`scripts.iwd with the version from this release.

In mapvote.cfg, copy the new map name dvars into your existing mapvote.cfg, then add the new maps into the mapvoting dvars as you like.

In game.cfg, copy the new 'game\_assistance\_max\_rank' dvar into your existing game.cfg

### Known Issues ###
Map mp\_dome is known to have g\_spawn errors after about 6 waves on a 64-slot server.

### Future Plans ###
There may be an additional patch for RotU 2.2.2 with even more maps in the future, but that seems unlikely at this point.  The next planned general release will be RotU 2.3.0, which will have the new AI, the optimizations, and Jerkan's traps.  As my work on 2.3.0 progresses, I will release pre-alpha, alpha, and beta versions as appropriate.

### New Maps ###
These maps may be downloaded from the usual sources--Google is your friend.

  * mp`_`brecourt`_`v2 "Brecourt"
  * mp`_`mw2`_`term "Terminal"
  * mp`_`nuketown "Nuketown"
  * mp`_`damnalley "Damn Alley"
  * mp`_`firingrange`_`v2 "Firing Range"
  * mp`_`lake "Lake"
  * mp`_`4t4`_`scrap "Scrap"
  * mp`_`argel "Argel"
  * mp`_`summit "Summit"
  * mp`_`vac`_`2`_`snow "Vacant Snow"
  * mp`_`highrise "Highrise"
  * mp`_`sbase "Submarine Base"
  * mp`_`ctan "Carentan"
  * mp`_`bastogne "Bastogne"
  * mp`_`fallout "Fallout"
  * mp`_`dome "Dome"
  * mp`_`redzone "Red Zone"
  * mp`_`d2c "Dust 2 Classic"
  * mp`_`asylum "Asylum"
  * mp`_`atp "ATP"
  * mp`_`backlot`_`snow "Backlot Snow"
  * mp`_`karachi "Karachi"
  * mp`_`psycho "Psycho"
  * mp`_`zaseda "Zaseda"
  * mp`_`steamlab "Steamlab"
  * mp`_`dustcod4 "Dust CoD4"
  * mp`_`modern`_`rust "Modern Rust"

The following maps are intended as a preview, and may not be playable yet.  Fart House is done, but will be quite laggy without the optimizations planned for 2.3.0.  NCC 1701 is nearly done, but won't be playable until the new waypoint features in 2.3.0.  Doo House is being used to develop the new waypoint and pathfinding features.  It is generally playable, but there may be many stuck zombies as 25% of the waypoints are designed for 2.3.0. Collectively, these three maps do a good job highlighting the limitations of the current AI, which is why we are using them to help develop the new AI.
  * mp`_`fart`_`house`_`v2 "Fart House"
  * mp`_`doohouse "Doo House"
  * mp`_`ncc`_`1701 "NCC 1701"