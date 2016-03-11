Since: RotU 2.2.2

# Introduction #

This document covers setting up and playing Reign of the Undead on your own computer.

# Architecture & Definitions #

RotU is a mod for the COD4 multiplayer game, which uses a client/server architecture, which means that anytime you want to play the game, you must set up a server.

If everyone that you want to play with is on your own private network, typically 192.168.0.0/16 (255.255.0.0) for home networks, then a LAN server will suffice.

If any of the people you want to play with will need to connect over the Internet, you will need an Internet server, and you will need to ensure that the proper ports are forwarded from your router to the machine you are running the server on.  Also, you will probably want to password protect your server, so only your friends can connect.

# Prerequisites #
You should have already followed the instructions in [Setting Up A Server](SettingUpAServer.md) though the "Install Maps" item, skipping the "Uploading the Server Files" item.

# Listen Server #
In a listen server, the COD4 client and server run in the same process, which makes it the easiest to set up.  The downside is that there can be only one player, and you can't change maps.  When the game ends, the process ends.  I always use a listen server for testing code changes and for editing maps with the UMI Map Editor.

To set up a listen server, in server.cfg, you must have
`set dedicated 0`.  `net_ip` and `net_port` have no effect.

You will need to edit playMod.bat.  By default, the mod is "mods\rotudev".  You will need to edit the line that begins with `iw3mp.exe +set fs_game "mods\rotudev"` so it points to whatever you have called your RotU mod.

In the same line, set `+devmap mp_surv_testmap` to the map you want to play.  The map must be a stock map that works with RotU, or a custom RotU map that is located in your usermaps folder.

You should also edit the last line `cd mods\rotudev` to point to whatever you have called your RotU mod.

Once your server is configured and you have edited playMod.bat as required, you can play the game by running playMod.bat from the Windows command line, or by clicking on playMod.bat.

# LAN & Internet Servers #
## Hosting ##
To set up a LAN server, in server.cfg, you must have
`set dedicated 1`.  `net_ip` and `net_port` will need to be set to the local machine's ip address and a suitable port.

To set up an Internet server, in server.cfg, you must have
`set dedicated 2`.  `net_ip` and `net_port` will need to be set to your router's external IP address and a suitable port.  You will also need to set up port forwarding as required.  For a server with a `net_port` of 28960, the ports/protocol to forward are:

  * 20800 UDP
  * 20810 UDP
  * 28960 UDP

How to actually forward those ports on your router is beyond the scope of this tutorial.

For both types of servers, you will need to edit host.bat exactly as described for playMod.bat in the Listen server section above.  You can then start the server by running host.bat. A desktop shortcut to host.bat will let you start the server with a single click.

## Joining ##
You will need to edit join.bat so the `iw3mp.exe` line and the last `cd` line point to the right mod folder, as you did for host.bat.

You must then set `+connect 192.168.1.11` to the IP address of the server you want to connect to.  For a LAN server, this should be the private IP address of the machine the server is running on.  For an Internet server, this should be the external IP address of your router.

You can then join the already running server by running join.bat.

Alternatively, you can add your LAN or Internet Server as a favorite in COD4, then join the game the same way you would any other favorite server.  Other players can join the game using this method, as they won't have the join.bat file.

Also, if your Internet server is properly configured, it will show up in the in-game list of Internet COD4 servers.

# Using the "Start New Server" Menu #
It is possible to start a server this way, but it isn't recommended, as it isn't as quick and easy using host.bat.

Some things to keep in mind:
  * You still need to install all the same files and do the same configuration editing as you would if you were using `playMod.bat`, `host.bat`, and `join.bat`.
  * If 'Dedicated:' is 'No', then the server will be a Listen server.
  * If 'Dedicated:' is LAN, then 'IP Address:' can be 'localhost' or a private IP address.
  * If 'Dedicated:' is 'Internet', then 'IP Address:' must be an Internet IP address, typically the external IP address of your router, and you will need to forward the appropriate ports (see above).
  * `startnewserver.cfg` is used in lieu of `server.cfg`
  * You must not have the `dedicated` dvar in `startnewserver.cfg` or the menu won't work properly.