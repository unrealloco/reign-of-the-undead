# Introduction #

Since RotU is open-source software, there are no limits to customization, other than the arbitrary and capricious limits Activision/IW has placed in the game (such as limits on client strings, hud elements, etc).  Many of the customizations below will require you to set up a [development environment](DevelopmentEnvironment.md).  Changing the values of settings in the configuration files (`*`.cfg) is not covered in this document.


## What Not to Change ##
> While you have the ability to change everything, there is one thing you cannot do, and several other things we would prefer you not to do.  You may not remove the license header in each `*`.gsc file.  If you add **significantly** to the functionality in a `*`.gsc file, you may feel free to add your copyright to the license header.  Adding 50 SLOC in a 1000 SLOC file is not a significant contribution.  For example:
```
    Copyright (c) 2010-2013 Reign of the Undead Team.
    See AUTHORS.txt for a listing.
    Copyright (c) 2013 John Q. Public <jpublic@example.com>
```

> On the main menu, please do not alter or remove the URL for this website, the 'Reign of the Undead 2.2' title, and the 'About RotU' menu.  Feel free to customize the main menu background image to include information about your server or clan.

> Do not remove or alter the end credits in such a way that would fail to give credit where credit is due.  Do not remove the end credit statement about RotU being open-source software, nor the URL for this website.  It you make major changes to the source code, skins, etc., feel free to add a credit to the top of the list, something like: RotU 2.2 Customization: My Awesome Clan

## Changing the Main Menu Background ##
> The main menu background image is src\images\bg\_front.iwi.  There is a DDS version in src\ddsimages\bg\_front.dds.  You can create a new image from scratch (1024 x 512), or customize the existing image. GIMP with the DDS plugin will do the trick.  You can then convert the dds image to an iwi image using your iwi/dds converter.  Do not change the name or pixel size of the iwi image.  Then rebuild the mod with makeMod.pl.
