# Introduction #

This page contains instructions and information about setting up a development environment for rotu.

  * **Applies to:** Rotu 2.2
  * **Tested on:** MS Windows Vista, MS Windows 7
  * **Status:** Final


> ## Prerequisite Software ##
> All of the software below is either [Free Software](http://www.gnu.org/licenses/gpl.html) or [Open Source Software](http://opensource.org/), except for the COD Mod Tools, which is governed by Activision/IW's EULA.  In any event, all of the software is available at no-cost.
> > ### Subversion ###
> > In order to download the source code, you will need a Subversion client.  Subversion is a source code version control system that tracks changes made to source code.  If you do not have a subversion client installed, you must install one.  [TortoiseSVN](http://tortoisesvn.net/) is recommended. [Tortoise SVN Primer](http://tortoisesvn.net/docs/release/TortoiseSVN_en/tsvn-dug.html)
> > ### Perl ###
> > The build system is written in Perl, a programming language that excels at text-processing.  If you do not have a recent Perl installed, you must install one.  [Strawberry Perl](http://strawberryperl.com/) is recommended.
> > ### Text Editor ###
> > A good text editor is required for programming.  [Kate](http://kate-editor.org/get-it/), the KDE Advanced Text Editor, is strongly recommended.  Other text editors may be sufficient (Notepad isn't sufficient, and Wordpad isn't a text editor), but Kate is known to have the features required.
> > ### Kompare ###
> > If you installed the KDE for Windows development tools (for Kate), you also probably installed Kompare.  Kompare is a difference viewer--it can read a unified diff file (`*`.diff) or compare two files and report the differences.  For each incremental release of RotU, we intend to release a unified diff that covers just the `*`.cfg files so you can see the default configuration changes.  You can then apply the changes, either manually or using Kompare, as opposed to overwriting your config files and starting from scratch.  There are other diff programs, but I use Kompare, and haven't investigated any of them.
> > ### GIMP ###
> > To edit raster images used in the project,  [GIMP](http://www.gimp.org/), the GNU Image Manipulation Program, together with the [GIMP DDS Plugin](http://code.google.com/p/gimp-dds/), is recommended.
> > ### Inkscape ###
> > To edit SVG (Scalable Vector Graphic) files used in the project, you must have an SVG program. [Inkscape](http://inkscape.org/) is recommended.
> > ### COD4 Mod Tools ###
> > To build the mod, you must install Activision/IW's [Mod Tools](http://callofduty.filefront.com/file/Call_of_Duty_4_Modern_Warfare_Mod_Tools;85947).


> ## Backup CoD4 ##
> Before you get started, we **strongly** recommend that you zip your entire CoD4 folder and stash it someplace safe in case things go horribly wrong.  You've been warned. :-)

> ## Get the Source Code ##
> Use your subversion client to download the source code to a local working directory.  Project members will do a read-write checkout, while others will do a read-only anonymous svn checkout.  N.B. A read-only checkout doesn't mean you can't change the code you download, it just means you can't upload your changes back to the subversion repository.

> Your local working directory should **not** be in the COD folder, but rather someplace convenient.  I use C:\Users\Mark\work\rotu\trunk, and most developers use a similar location.

> For an anonymous svn checkout using TortoiseSVN (for everyone except developers), check out:

> <tt><strong><em>http</em></strong>://reign-of-the-undead.googlecode.com/svn/trunk</tt>

> Developers should checkout using a secure https connection using the credentials you were given:

> <tt><strong><em>https</em></strong>://reign-of-the-undead.googlecode.com/svn/trunk</tt>

> ## Configure the Build System ##
> The build system is contained primarily within build\makeMod.pl.  The configuration for makeMod.pl is contained in build\makeConfig.pl. Using your text editor, open makeConfig.pl and edit the codPath, modPath, and uploadPath variables as required for your system. Save your changes, then use your text editor to open makeMod.pl.

> The first line is the path to the perl interpreter you previously installed. You need to edit the line as required, depending on where you installed perl.  Make sure the line begins with the shebang #!, and that it is the very first line in the file.  Save your changes, then close the files.

> ### Windows 7 Note: ###
> If your CoD4 install is on a different drive than the source code you downloaded, the mod will not compile as is.  This is because Microsoft changed the 'cd' command.  If this applies to you, delete the file build\makeFF.bat, then rename build\makeFF\_win7.bat to build\makeFF.bat.

> ## Configure the the Mod ##
> In the src folder are several `*_default.cfg` configuration files.  These files will need to be edited. Using your text editor, open each of these files and save it in the src folder without the `_default`, i.e. save `server_default.cfg` as `server.cfg`.  **After** you have saved the file under the new name, edit the config settings as appropriate for your system and as desired.

> In the src folder are several `*_default.bat` batch files.  These files will need to be edited. Using your text editor, open each of these files and save it in the src folder without the `_default`, i.e. save `playMod_default.bat` as `playMod.bat`.  **After** you have saved the file under the new name, edit the batch file as appropriate for your system and as desired.

> ## Build the Mod ##
> To build the mod, open a command line (cmd.exe, i.e. 'Command Prompt'), then cd as required to get to the build directory (C:\Users\Mark\work\rotu\trunk\build or similar). To get an idea of makeMod.pl's features, at the command prompt execute
> > `perl makeMod.pl -h`

> Once you've read that brief documentation, execute
> > `perl makeMod.pl`

> to build the mod.  Building may take a minute or more, depending on the speed of your computer.  When the script finishes, the mod will have been compiled, installed, and relevant files copied to the uploadPath you specified in makeConfig.pl.

> ## Play the Mod ##
> Using your file manager, browse to the modPath you specified earlier, then click on playMod.bat to play the mod.  If it starts up OK, it is safe to copy the files from the uploadPath to your server.