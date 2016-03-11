# Introduction #

This page provides general instructions on how to install and set up a hosted RotU 2.2 public server.


# Details #
### Obtain the Binary Files ###
> You may download a binary release of RotU 2.2 from this site.  Alternatively, you may use a subversion client to set up a [Development Environment](DevelopmentEnvironment.md).  In that case, after you build the mod, the binary files will be located in the uploadPath you specified.

### Edit the RotU 2.2 Configuration Files ###
> Each of the `*`.cfg files will need to be edited to suit your server and to customize RotU 2.2 to your liking.  I suggest making a backup copy of the `*`.cfg files before you begin, in case things go horribly wrong.  Begin by editing server.cfg, then proceed to the other `*`.cfg files.  Most of the settings are documented inside the files.

### Create a folder for RotU 2.2 ###
> You will need to create a folder inside the Mods folder on your server.  You should choose a name that is unique to your server(s).  If you choose a name that others are likely to choose, you will force your players to repeatedly download different versions of the same files as they play on different servers.  If you run multiple servers, and want players' rank to be the same on each server, use the same folder name on all the servers.  If you want them to be different, then use different folder names on each of your servers.  For example, on Pulsar's servers, we might use 'pza.rotu22' and 'pza.rotu22easy'.

### Upload the Server Files ###
> Upload the following files to the folder you created inside the Mods folder on your server:
  * 2d.iwd
  * rotu\_svr\_custom.iwd
  * rotu\_svr\_scripts.iwd
  * rotu\_svr\_mapdata.iwd (optional; only if you want our map fixes)
  * sound.iwd
  * weapons.iwd
  * yz\_custom.iwd (optional)
  * mod.ff
  * admin.cfg
  * damage.cfg
  * didyouknow.cfg
  * easy.cfg
  * mapvote.cfg
  * server.cfg
  * game.cfg (since RotU 2.2.2)
  * weapons.cfg
  * ban.txt (create an empty file, or use a previous ban file)

> startnewserver.cfg (since RotU 2.2.2) is not required for a hosted public server.

### Install Maps ###
> Any map listed in one of the `sv_mapvoting` dvars in mapvote.cfg need to be installed to the server (or the mod will fail when it tries to load a non-existent map).  Maps should be installed to the usermaps folder, e.g. usermaps\mp\_fnrp\_bridge.  Many maps are available from [ModDB.com](http://www.moddb.com/mods/reign-of-the-undead-zombies).  Most maps from versions 1.15, 2.0, and 2.1 will work with 2.2, as we have made efforts to support legacy maps.  However, some maps are known not to work--these are blacklisted in the source code, and noted in mapvote.cfg.  If you try to load a bad map, it may play wonky, or have massive runtime errors, or it may even prevent the server from starting.

### Set the Command Line ###
> You will need to use the tools made available by your hosting provider to set the command line that should be run to start your RotU server.  For example, here is the command that launches Rotu 2.2 on Pulsar's test server:
`+set fs_savepath C:\UserFiles\JACOBM\GameServers\TC55587050742312272315616\ +set dedicated 2 +set net_ip 69.28.220.207 +set net_port 28960 +set sv_maxclients 40 +set ui_maxclients 40 +set fs_game Mods/rotu22 +set sv_punkbuster "0" +exec server.cfg +map_rotate`
> Note there isn't actually an executable file in that command line--your provider may prepend the command on its own. Your server provider will will be able to provide more specific information.

### Start the Server ###
> Use your server provider's interface to start the server.  Then join the game and test the configuration choices you made.  After making changes to the configuration files, you will need to upload your changes then restart the server for the changes to take effect.