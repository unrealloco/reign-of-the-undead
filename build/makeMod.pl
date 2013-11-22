#!C:\strawberry\perl\bin\perl

#******************************************************************************
#     Reign of the Undead, v2.x
#
#     Copyright (c) 2010-2013 Reign of the Undead Team.
#     See AUTHORS.txt for a listing.
#
#     Permission is hereby granted, free of charge, to any person obtaining a copy
#     of this software and associated documentation files (the "Software"), to
#     deal in the Software without restriction, including without limitation the
#     rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
#     sell copies of the Software, and to permit persons to whom the Software is
#     furnished to do so, subject to the following conditions:
#
#     The above copyright notice and this permission notice shall be included in
#     all copies or substantial portions of the Software.
#
#     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#     IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#     FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#     AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#     LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#     OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#     SOFTWARE.
#
#     The contents of the end-game credits must be kept, and no modification of its
#     appearance may have the effect of failing to give credit to the Reign of the
#     Undead creators.
#
#     Some assets in this mod are owned by Activision/Infinity Ward, so any use of
#     Reign of the Undead must also comply with Activision/Infinity Ward's modtools
#     EULA.
#******************************************************************************

use Getopt::Std;
use Digest::MD5 qw(md5);
use File::Find;
use File::Basename;
use File::Path qw/make_path/;
use Cwd 'abs_path';

# Source the make configuration
unless (-e 'makeConfig.pl') {die "You first need to save a copy of makeConfig.default as makeConfig.pl, the edit makeConfig.pl as required.\n";}
my %config = do 'makeConfig.pl';
my %map = ();

my $rebuild2D = 0;
my $rebuildWeapons = 0;
my $rebuildSound = 0;
my $rebuildServerCustom = 0;
my $rebuildServerScripts = 0;
my $rebuildCustomIwd = 0;
my $rebuildCustomMapsIwd = 0;
my $rebuildMod = 0;

my $needToUpdateChecksums = 0;
my $installConfig = 0;
my $installBatchFiles = 0;

# use strict;
# use warnings;

# Pre-declare subroutines
sub loadFiles();
sub selectFiles();
sub doInitialBuild();
sub buildNonDebugScriptFile;
sub buildIwdFiles();
sub findChanges();
sub rebuildMod();
sub writeUpdatedChecksumFile();
sub buildNewChecksumFile();
sub installConfig();
sub installBatchFiles();
sub deleteFile;
sub selectScriptFiles();
sub clean();
sub version();
sub help();
sub report;
sub quality();
sub release();
sub checksumUnreadable();
sub updateUploadFolder();
sub rebuildScriptsOnly();

my @files = ();
my @rawFiles = ();

my $report = "\nmakeMod.pl Job Report:\n\n";
my $quality = "\nmakeMod.pl Quality Report:\n\n";

my $license = "";
my $tab = "";
my $lineEndings = "";
my $todo = "";
my $bug = "";
my $fixme = "";
my $hack = "";
my $deprecated = "";
my $functions = "";
my $documentedFunctions = "";
my $functionEntrance = "";
my $doxErrors = "";
my $sloc = 0;
my %usedFiles = ();
my $deprecatedFiles = "";
my %functionCounts = ();
my $unusedFunctions = "";
my $unusedIncludes = "";
my %funcDefs = ();
my %funcKeysByFile = ();
my %processedFiles = ();

# Set root directory
my $dir = abs_path("..");
my $checksumFile = "$dir/build/checksums.txt";


# Process command line args
getopts('fcqhvsdr:'); # all boolean switches, except r, which takes a parameter
if ($opt_h){
    # Help
    help();
} elsif ($opt_v){
    # Version
    version();
} elsif ($opt_f){
    # Force a full rebuild
    print "Forcing a full rebuild\n";
    doInitialBuild();
} elsif ($opt_s){
    # Force rebuild of scripts only
    print "Forcing a rebuild of scripts only...\n";
    rebuildScriptsOnly();
} elsif ($opt_c){
    # Clean
    print "Cleaning build...\n";
    clean();
} elsif ($opt_q){
    # Quality checks
    print "Performing code quality checks...\n";
    quality();
} elsif ($opt_r){
    # Build a release
    print "Creating a RotU release named $opt_r\n";
    release();
} else {
    # Build mod

    # If we can't read from the checksum file, we do an initial build, then exit
    open(C,"<$checksumFile") or checksumUnreadable();

    # Otherwise, build and install components as required
    findChanges();
    buildIwdFiles();
    rebuildMod();
    installConfig();
    installBatchFiles();
    updateUploadFolder();
    writeUpdatedChecksumFile();

    print $report;
}

sub release()
{
    $folder = $config{releasePath}."\\".$opt_r;
    mkdir $folder;

    my $file = "";
    my $defaultfile = "";

    # Copy test map from svn working copy
    my $mapFolder = $folder.'\mp_surv_testmap';
    mkdir $mapFolder;
    my $srcFolder = $config{workPath};
    $srcFolder =~ s!src!map_src\\contrib\\test_map\\usermaps\\mp_surv_testmap!;
    my @files = ("mp_surv_testmap.ff", "mp_surv_testmap.iwd", "mp_surv_testmap_load.ff");
    foreach $file (@files) {
        $cmd = 'copy /y'.' "'.$srcFolder.'\\'.$file.'" "'.$mapFolder.'\\'.$file.'"';
        # for robocopy, a byte-shifted return code of 3 or less is success
        system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
    }
    report "Copied test map to $folder\n";

    # Copy config files from svn working copy
    foreach $file (@{$config{configFiles}}) {
        $defaultfile = $file;
        $defaultfile =~ s/.cfg/_default.cfg/;
        $cmd = 'copy /y'.' "'.$config{workPath}.'\\'.$defaultfile.'" "'.$folder.'\\'.$file.'"';
        # for robocopy, a byte-shifted return code of 3 or less is success
        system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
    }
    report "Copied config files to $folder\n";

    # Copy batch files from svn working copy
    my @files = ("playMod.bat", "host.bat", "join.bat");
    foreach $file (@files) {
        $defaultfile = $file;
        $defaultfile =~ s/.bat/_default.bat/;
        $cmd = 'copy /y'.' "'.$config{workPath}.'\\'.$defaultfile.'" "'.$folder.'\\'.$file.'"';
        # for robocopy, a byte-shifted return code of 3 or less is success
        system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
    }
    report "Copied batch files to $folder\n";

    # Do a full non-debug build
    my $cmd = 'perl makeMod.pl -f';
    system($cmd) == 0 or die "system $cmd failed: $?";

    my $copyCmd = 'robocopy ';
    my $switches = '/COPYALL /NFL /NDL /NJH  /NJS ';

    # Copy rotu_svr_scripts.iwd over
    $file = 'rotu_svr_scripts.iwd ';
    $cmd = $copyCmd.' "'.$config{modPath}.'" "'.$folder.'" '.$file.$switches;
    $cmd =~ s!\\!\/!g;
    # for robocopy, a byte-shifted return code of 3 or less is success
    system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
    report "Copied rotu_svr_scripts.iwd to $folder\n";

    # Copy rotu_svr_custom.iwd over
    $file = 'rotu_svr_custom.iwd ';
    $cmd = $copyCmd.' "'.$config{modPath}.'" "'.$folder.'" '.$file.$switches;
    $cmd =~ s!\\!\/!g;
    # for robocopy, a byte-shifted return code of 3 or less is success
    system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
    report "Copied rotu_svr_custom.iwd to $folder\n";

    # Copy yz_custom.iwd over
    $file = 'yz_custom.iwd ';
    $cmd = $copyCmd.' "'.$config{modPath}.'" "'.$folder.'" '.$file.$switches;
    $cmd =~ s!\\!\/!g;
    # for robocopy, a byte-shifted return code of 3 or less is success
    system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
    report "Copied yz_custom.iwd to $folder\n";

    # Copy rotu_svr_mapdata.iwd over
    $file = 'rotu_svr_mapdata.iwd ';
    $cmd = $copyCmd.' "'.$config{modPath}.'" "'.$folder.'" '.$file.$switches;
    $cmd =~ s!\\!\/!g;
    # for robocopy, a byte-shifted return code of 3 or less is success
    system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
    report "Copied rotu_svr_mapdata.iwd to $folder\n";

    # Copy sound.iwd over
    $file = 'sound.iwd ';
    $cmd = $copyCmd.' "'.$config{modPath}.'" "'.$folder.'" '.$file.$switches;
    $cmd =~ s!\\!\/!g;
    # for robocopy, a byte-shifted return code of 3 or less is success
    system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
    report "Copied sound.iwd to $folder\n";

    # Copy 2d.iwd over
    $file = '2d.iwd ';
    $cmd = $copyCmd.' "'.$config{modPath}.'" "'.$folder.'" '.$file.$switches;
    $cmd =~ s!\\!\/!g;
    # for robocopy, a byte-shifted return code of 3 or less is success
    system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
    report "Copied 2d.iwd to $folder\n";

    # Copy weapons.iwd over
    $file = 'weapons.iwd ';
    $cmd = $copyCmd.' "'.$config{modPath}.'" "'.$folder.'" '.$file.$switches;
    $cmd =~ s!\\!\/!g;
    # for robocopy, a byte-shifted return code of 3 or less is success
    system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
    report "Copied weapons.iwd to $folder\n";

    # Copy mod.ff over
    $file = 'mod.ff ';
    $cmd = $copyCmd.' "'.$config{modPath}.'" "'.$folder.'" '.$file.$switches;
    $cmd =~ s!\\!\/!g;
    # for robocopy, a byte-shifted return code of 3 or less is success
    system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
    report "Copied mod.ff to $folder\n";

    # Build a debug version of rotu_svr_scripts
    my $cmd = 'perl makeMod.pl -sd';
    system($cmd) == 0 or die "system $cmd failed: $?";

    # Copy debug version of rotu_svr_scripts
    $file = "rotu_svr_scripts.iwd";
    $debugFile = "rotu_svr_scripts_debug.iwd";
    $cmd = 'copy /y'.' "'.$config{modPath}.'\\'.$file.'" "'.$folder.'\\'.$debugFile.'"';
    # for robocopy, a byte-shifted return code of 3 or less is success
    system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
    report "Copied debug version of rotu_svr_scripts.iwd to $folder\n";

    my $cwd = Cwd::cwd();
    my $zipCmd = $cwd.'/7za.exe a -tzip -xr!?svn ';
    my $archive = "";

    $archive = $config{releasePath}.'\\'.$opt_r.'.zip';
    deleteFile($archive);
    $cmd = $zipCmd.'"'.$archive.'" '.$folder;
    $cmd =~ s!\\!\/!g;
    system($cmd) == 0 or die "system $cmd failed: $?";
    report "Saved zip archive of release to $archive\n";

    print $report;
    exit 0;
}

sub quality()
{
    loadFiles();

    # Find function definitions
    print "Finding function definitions...";
    foreach my $file (@files) {
        # only test source files
        next unless ($file =~ /\/src\//);

        # only test *.gsc files
        next unless ($file =~ /\.gsc/);
        findFunctionDefinitions($file);
    }
    print "done.\nPreparing files for analysis...";
    foreach my $file (@files) {
        # only test source files
        next unless ($file =~ /\/src\//);

        # only test *.gsc files
        next unless ($file =~ /\.gsc/);
        stripComments($file);
    }
    print "done.\nChecking files for a proper license...";

    ## we begin with some checks best done with slurpped files, then we proceed
    ## line by line

    # License check
    foreach my $file (@files) {
        # only test source files
        next unless ($file =~ /\/src\//);

        # only test *.gsc files
        next unless ($file =~ /\.gsc/);
        open(R, "<$file") or die "can't open file: $!";
        # slurp in file
        my $contents = do { local $/; <R> };
        close(R);
        $file =~ /.*\/(src\/.*)/;
        my $relFile = $1;

        unless (($contents =~ /Copyright \(c\) 2010-2013 Reign of the Undead Team/) and
                ($contents =~ /THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND/))
        {
            $license .= "Missing or improper license: $relFile\n";
        }
    }
    print "done.\nChecking files for tab characters (use spaces instead!)...";

    # Tab check (we use 4 spaces)
    foreach my $file (@files) {
        # only test source files
        next unless ($file =~ /\/src\//);

        # only test text files
        next unless ($file =~ /(.gsc|.menu|.cfg|.txt)/);
        open(R, "<$file") or die "can't open file: $!";
        # slurp in file
        my $contents = do { local $/; <R> };
        close(R);
        $file =~ /.*\/(src\/.*)/;
        my $relFile = $1;
        if ($contents =~ /\t/) {
            $tab .= "Found tab character: $relFile\n";
        }
    }
    my $previous_default = select(STDOUT); # save previous default
    $|++; # autoflush STDOUT
    print "done.\nChecking for 'bug', 'todo', 'hack', 'fixme', and 'deprecated' notations...";

    ## Line by line processing
    my $testLine = "";
    my $functionLine = "";;
    my $lineNumber = "";
    foreach my $file (@files) {
        # only test source files
        next unless ($file =~ /\/src\//);

        # only test *.gsc files
        next unless ($file =~ /.gsc/);
        open(R, "<$file") or die "can't open file: $!";
        my $lineNumber = 1;
        my $lineIndex = 0;
        $file =~ /.*\/(src\/.*)/;
        my $relFile = $1;
        my @lines = ();
        my @functionLines = ();
        while (my $line = <R>) {
            if ($line =~ /\@todo\b/i) {$todo .= "Todo found: $relFile:$lineNumber:$line";}
            elsif ($line =~ /\@bug\b/i) {$bug .= "Bug found: $relFile:$lineNumber:$line";}
            elsif ($line =~ /\@deprecated\b/i) {$deprecated .= "Deprecated item found: $relFile:$lineNumber:$line";}
            elsif ($line =~ /hack:/i) {$hack .= "Hack found: $relFile:$lineNumber:$line";}
            elsif ($line =~ /fixme/i) {$fixme .= "Fixme found: $relFile:$lineNumber:$line";}
            elsif ($line =~ /^\w*\(.*\).*;{0,0}\n/i) {
                push @functionLines, $lineIndex;
            }
            push @lines, $line;
            $lineNumber++;
            $lineIndex++;
        }
        $sloc += scalar(@lines);
        close(R);
        foreach my $index (@functionLines) {
            $testLine = $lines[$index-1];
            $functionLine = $lines[$index];
            $lineNumber = $index + 1;

            my($filename, $directories, $suffix) = fileparse($file, '.gsc');
            $functionLine =~ /(^\w*)\((.*)\).*;{0,0}\n/i;
            my $functionName = $1;
            my $args = $2;

            # While we are here, load function IDs so we can search for unused functions later
            my $path = $relFile;
            $path =~ s!src\/!!;
            $path =~ s!\.gsc!!;
            $path =~ s!\/!\\!g;
            unless ($functionName eq "init") {
                my $function = "$path\:\:$functionName";
                $functionCounts{$function} = 0;
            }

            # Now get back to checking for proper function entrance debug statements
            my $testLine = $lines[$index+2];
            my $pattern = qr/    debugPrint\(\"in $filename\:\:$functionName\(\)\", \"fn\", level/;
            unless ($testLine =~ $pattern){
                unless ($testLine =~ /most-called function/){
                    # Add exception for the 21 most-used functions (~95% of all function calls)
                    $functionEntrance .= "Missing or wrong function entrance debug statement found: $relFile:$lineNumber:$functionLine";
                }
            }

        }

    }
    print "done.\nAnalyzing functions...";

    # Start with ../src/maps/mp/gametypes/surv.gsc
    $file = "../src/maps/mp/gametypes/surv.gsc";
    findFunctionCalls($file);

    # Look for possibly deprecated files
    my @uniqueFiles = ();
    foreach my $key (keys %processedFiles) {
        push @uniqueFiles, $processedFiles{$key};
    }
    my @sorted = sort @uniqueFiles;
    foreach my $file (@files) {
        # only test source files
        next unless ($file =~ /\/src\//);

        # only test *.gsc files
        next unless ($file =~ /.gsc/);
        $file =~ /.*\/src\/(.*)/;
        my $relFile = $1;
        $relFile =~ s!/!\\!g;
        unless ($relFile ~~ @sorted) {
            # add some exceptions; don't count these as deprecated
            unless ($relFile eq 'maps\mp\_load.gsc' or
                    $relFile eq 'maps\mp\gametypes\dm.gsc' or
                    $relFile eq 'maps\mp\gametypes\surv.gsc' or
                    $relFile eq 'maps\mp\gametypes\war.gsc')
            {
                $deprecatedFiles .= "Possibly deprecated file: $file\n";
            }
        }
    }



    # Look for unused functions
    foreach my $key (sort keys %funcDefs) {
        next unless (scalar @{$funcDefs{$key}->{uses}} == 0);
        # some zombiescript files may be deprecated, so for now, do not mark their
        # functions as being unused
        unless ($key =~ m/zombiescript/)
        {
            $unusedFunctions .= "Unused function found: $key\n";
        }
    }
    print "done.\n";
    select($previous_default);              # restore previous default

    my $number =()= $license =~ /\n/gi;
    $quality .= "  Found $number improperly licensed files\n";
    $number =()= $tab =~ /\n/gi;
    $quality .= "  Found $number files with tab characters\n";
    $number =()= $todo =~ /\n/gi;
    $quality .= "  Found $number \@todo items\n";
    $number =()= $bug =~ /\n/gi;
    $quality .= "  Found $number \@bug items\n";
    $number =()= $deprecated =~ /\n/gi;
    $quality .= "  Found $number \@deprecated items\n";
    $number =()= $hack =~ /\n/gi;
    $quality .= "  Found $number hack items\n";
    $number =()= $fixme =~ /\n/gi;
    $quality .= "  Found $number fixme items\n";
    $number =()= $functions =~ /\n/gi;
    $quality .= "  Found ".keys(%funcDefs)." function definitions\n";
    $quality .= "  Found $number undocumented functions\n";
    $number =()= $documentedFunctions =~ /\n/gi;
    $quality .= "  Found $number documented functions\n";
    $number =()= $functionEntrance =~ /\n/gi;
    $quality .= "  Found $number functions with missing or improper function entrance debug statements\n";
    $number =()= $doxErrors =~ /\n/gi;
    $quality .= "  Found $number doxygen errors\n";
    $number =()= $deprecatedFiles =~ /\n/gi;
    $quality .= "  Found $number possibly deprecated files\n";
    $number =()= $unusedFunctions =~ /\n/gi;
    $quality .= "  Found $number apparently unused functions\n";
    $number =()= $unusedIncludes =~ /\n/gi;
    $quality .= "  Found $number unused #include statements\n";
    $quality .= "\n  $sloc Source Lines of Code in *.gsc files\n";

    # print results to screen
    print $license;
    print $tab;
    print $todo;
    print $bug;
    print $hack;
    print $fixme;
    print $functions;
#     print $documentedFunctions;
    print $functionEntrance;
    print $doxErrors;
    print $deprecatedFiles;
    print $unusedFunctions;
    print $unusedIncludes;
    print $quality;

    my $file = "qualityReport.log";
    open(Q, ">$file") or die "can't open file: $!";
    print Q "$quality\n";
    print Q $license;
    print Q $tab;
    print Q $todo;
    print Q $bug;
    print Q $hack;
    print Q $fixme;
    print Q $functions;
#     print Q $documentedFunctions;
    print Q $functionEntrance;
    print Q $doxErrors;
    print Q $deprecatedFiles;
    print Q $unusedFunctions;
    print Q $unusedIncludes;
    close(Q);

    printFunctionUses();

}

# Create a version of file $contents without comments, but preserving line numbers
sub stripComments
{
    $file = shift;
#     print "$file\n";
    open(R, "<$file") or die "can't open file $file: $!";

    $lineNumber = 0;
    $openCommentCount = 0;
    my @lines = ();
    push @lines, "";
    while (my $line = <R>) {
        $open =()= $line =~ /\/\*/gi;
        $close =()= $line =~ /\*\//gi;
        if ($open == 1 and $close == 1) {
            # This line has a single /* comment */, remove it
            $line =~ s!\/\*.*\*\/!!;
        }
        # Add number of opening multi-line comment delimiters in this line
        $openCommentCount += $open;
        # Subtract number of closing multi-line comment delimiters in this line
        $openCommentCount -= $close;
        # If $openCommentCount is non-zero, we are in a multiline comment
        if ($openCommentCount) {
            # replace contents of line with \n
            $line = "\n";
            $lineNumber++;
            push @lines, $line;
#             print $line;
            next;
        }
        # this is the last line of a multi-line comment
        if ($line =~ /(.*\*\/)(.*)/gi) {
            my $pad = "";
            for (my $i = 0; $i < length($1); $i++) {
                $pad .= ' ';
            }
            $line = $pad.$2."\n";
            $lineNumber++;
            push @lines, $line;
#             print $line;
            next;
        }
        # strip // comments
        $line =~ s!//.*!!;
        $lineNumber++;
        push @lines, $line;
#         print $line;
    }
    close(R);

    $file =~ m!.*/src/(.*)!;
    $relFile = $1;
    $relFile =~ s!/!\\!g;

    # Store the comment-stripped @lines for later use
    $funcKeysByFile{$relFile}->{fileLines} = [ @lines ];
}


sub printFunctionUses()
{
    my $file = "functionUseReport.log";
    open(F, ">$file") or die "can't open file: $!";

    foreach $key (sort keys %funcDefs) {
        $key =~ m/(.*)\:\:/;
        my $name = $1;
        print F "Function ".$name."::".$funcDefs{$key}->{fnPrototype}."\n";
        print F "    Definition:\n";
        print F "        ".$funcDefs{$key}->{file}.":".$funcDefs{$key}->{lineNumber}.":".$funcDefs{$key}->{columnNumber}."\n";
        print F "    Uses:\n";
        my $useCount = scalar @{$funcDefs{$key}->{uses}};
        if ($useCount) {
            foreach $use (@{$funcDefs{$key}->{uses}}) {
                $use->{file} =~ m!.*/src/(.*)!;
                $relFile = $1;
                $relFile =~ s!/!\\!g;
                print F "        ".$relFile.":".$use->{line}.":".$use->{column}."\n";
            }
        } else {
            print F "        No uses of this function were found\n";
        }
        print F "\n";
    }
    close(F);
}

sub findFunctionCalls
{
    my $file = shift;
    $file =~ m!.*/src/(.*)!;
    $relFile = $1;
    $relFile =~ s!/!\\!g;
#     print "Finding function calls in $relFile\n";

    # Mark this file as already being processed
    $hash = Digest::MD5->new->add($relFile)->hexdigest;
    $processedFiles{$hash} = $relFile;

    my @internalFuncKeys = ();
    my @internalFileKeys = ();
    my $lineNumber = 0;
    my $lookingForIncludes = 1;
    my $contents = join "", @{$funcKeysByFile{$relFile}->{fileLines}};
    my %includeFiles = ();

    push @internalFileKeys, $relFile;
    # Load the keys for the functions defined in this file
    foreach $key (@{$funcKeysByFile{$relFile}->{fnKeys}}) {
        push @internalFuncKeys, $key;
    }

    foreach $line (@{$funcKeysByFile{$relFile}->{fileLines}}) {
        $lineNumber++;
        if ($line =~ /#include\s(.*);\n/) {
            my $relFile = $1.'.gsc';
            push @internalFileKeys, $relFile;
            $includeFiles{$1}->{count} = 0;

            $hash = Digest::MD5->new->add($relFile)->hexdigest;
            unless (exists $processedFiles{$hash}) {
                # recurse
                my $newFile = '../src/'.$relFile;
                $newFile =~ s!\\!\/!g;
                unless (-e $newFile) {
                    my $rawFile = $config{codPath}.'/raw/'.$relFile;
                    $rawFile =~ s!\\!\/!g;
                    unless (-e $rawFile) {
                        $unusedIncludes .= "Include file $relFile included in $file does not exist in src or raw\n";
                    } else {
                        findFunctionCalls($rawFile);
                    }
                } else {
                    findFunctionCalls($newFile);
                }
            }

            # Load the keys for the functions defined in this include file
            foreach $key (@{$funcKeysByFile{$relFile}->{fnKeys}}) {
                push @internalFuncKeys, $key;
            }
#             print "Found include $1\n";
        }
        if ($lookingForIncludes and $line =~ /^\w/) {
            $lookingForIncludes = 0;
#             print "Done looking for include files\n";
        }

    }

    # Search this file for function calls using the scoping operator
    foreach my $key (sort keys %funcDefs) {
        my $matchPos = 0;
        while ($contents =~ /$funcDefs{$key}->{extRegex}/sg) {
            my $pos = $-[1];
            my $lineN = 0;
            my $colN = 0;
            $matchPos = $pos;
            $matchSize = length($&);
            pos $contents = 0;
            while ($contents =~ m/(\n)/g) {
                $lineN++;
                last if ($-[1] >= $pos);
                $colN = $pos - length($`); # position of \n
            }
            # now reset pos the location of last match
            pos $contents = $matchPos + $matchSize;

#             print "(Ext) Found use of $key: $file:$lineN:$colN\n";
            my $line = ${$funcKeysByFile{$relFile}->{fileLines}}[$lineN];
            my $use = {
                file        => $file,
                line        => $lineN,
                column      => $colN,
                contents    => $line,
            };
            push @{$funcDefs{$key}->{uses}}, $use;
        } # end while this key matches

        # If $matchPos is non-zero, we found at least one use of this external function
        if ($matchPos) {
            $key =~ m/(.*)\:\:/;
            my $relFile = $1.'.gsc';
            $hash = Digest::MD5->new->add($relFile)->hexdigest;
            unless (exists $processedFiles{$hash}) {
                # recurse
                my $newFile = '../src/'.$relFile;
                $newFile =~ s!\\!\/!g;
                unless (-e $newFile) {
                    my $rawFile = $config{codPath}.'/raw/'.$relFile;
                    $rawFile =~ s!\\!\/!g;
                    unless (-e $rawFile) {
                        print "Referenced file $relFile does not exist in src or raw\n";
                        next;
                    }
                }
                findFunctionCalls($newFile);
            }
        }
    } # end foreach $key

    # Search this file for internal function calls
    # reset $relFile
    $file =~ m!.*/src/(.*)!;
    $relFile = $1;
    $relFile =~ s!/!\\!g;
    foreach my $key (@internalFuncKeys) {
        my $matchPos = 0;
        while ($contents =~ /$funcDefs{$key}->{intRegex}/sg) {
#             print $funcDefs{$key}->{intRegex}."\n";
            my $pos = $-[1];
            my $lineN = 0;
            my $colN = 0;
            $matchPos = $pos;
            $matchSize = length($&);
            pos $contents = 0;
            while ($contents =~ m/(\n)/g) {
                $lineN++;
                last if ($-[1] >= $pos);
                $colN = $pos - length($`); # position of \n
            }
            # now reset pos the location of last match
            pos $contents = $matchPos + $matchSize;

            # We probably found an internal function call, but it could be inside
            # a quoted string, and so not really an executable function call
#             print "(Int) Possibly found use of $key: $file:$lineN:$colN\n";
            $key =~ m/(.*)\:\:/;
            my $line = ${$funcKeysByFile{$relFile}->{fileLines}}[$lineN];
            $line =~ s!\".+?\"!!g;  # strip quoted text
            if ($line =~ /$funcDefs{$key}->{intRegex}/sg) {
                # If it still matches with the quoted strings removed, then it
                # is a valid function call
#                 print "(Int) Found use of $key: $file:$lineN:$colN\n";

                my $line = ${$funcKeysByFile{$relFile}->{fileLines}}[$lineN];
                my $use = {
                    file        => $file,
                    line        => $lineN,
                    column      => $colN,
                    contents    => $line,
                };
                push @{$funcDefs{$key}->{uses}}, $use;


                # If this internal function call calls an included file, increment
                # the include file's use counter
                foreach my $includeKey (keys %includeFiles) {
                    $tmp = $includeKey;
                    $tmp =~ s!\\!\\\\!g;
                    if ($key =~ qr/$tmp/i) {
                        $includeFiles{$includeKey}->{count}++;
                    }
                }
            }
        }
    } # end foreach $key

    # Are any of the include'd files unused?
    foreach my $includeKey (keys %includeFiles) {
#         print "file: $file include file: $includeKey\n";
        unless ($includeFiles{$includeKey}->{count}) {
            next if ($includeKey =~ m/common_scripts/);
            $unusedIncludes .= "Unused include file $includeKey included in $file\n";
        }
    }

}

sub findFunctionDefinitions
{
    $file = shift;
#     print "$file\n";
    open(R, "<$file") or die "can't open file $file: $!";
    $lineNumber = 0;
    $openCommentCount = 0;
    my @lines = ();
    push @lines, "";
    while (my $line = <R>) {
        $lineNumber++;
        push @lines, $line;
        # Add number of opening multi-line comment delimiters in this line
        $openCommentCount +=()= $line =~ /\/\*/gi;
        # Subtract number of closing multi-line comment delimiters in this line
        $openCommentCount -=()= $line =~ /\*\//gi;
        # If $openCommentCount is non-zero, we are in a multiline comment
        next if ($openCommentCount);
        $line =~ s!//.*!!;
        next unless ($line =~ m/^\w/);
        $line =~ m/((\w*)\(.*?\))[ {]{0,}\n/;
        $fnPrototype = $1;
        next unless ($fnPrototype);
#         print "line number: $lineNumber  $fnPrototype\n";
        $fnName = $2;
        $file =~ m!.*/src/(.*)!;
        $relFile = $1;
        $relFile =~ s!/!\\!g;
        $key = $relFile.'::'.$fnName;
        $key =~ s!.gsc!!;
        $columnNumber = 0;

        # We found a function definition, now check if it is properly documented
        unless ($lines[$lineNumber - 1] =~ / \*\/\n/) {
            $functions .= "Undocumented function found: $relFile:$lineNumber:$fnPrototype\n";
        } else {
            # todo check the validity of the comment block
            validateDocumentation(\@lines, $lineNumber, $relFile);
            $documentedFunctions .= "Documented function found: $relFile:$lineNumber:$fnPrototype\n";
        }

        $tmp = $key;
        $tmp = "(".$tmp.")";
        $tmp =~ s!\\!\\\\!g;
        $tmp =~ s!:!\\:!g;
        $extRegex = qr/$tmp/i;
        $tmp = $fnName;
        $tmp = "(?:[ {(!])(".$tmp.")";
        $intRegex = qr/$tmp/i;

        # Store function information indexed by full scope
        $funcDefs{$key} = {
            file            => $relFile,
            fnName          => $fnName,
            fnPrototype     => $fnPrototype,
            lineNumber      => $lineNumber,
            columnNumber    => $columnNumber,
            extRegex        => $extRegex,
            intRegex        => $intRegex,
            uses            => [ @uses ],
        };

        # Store function keys indexed by relative filename
        push @{$funcKeysByFile{$relFile}->{fnKeys}}, $key;
    }
    close(R);
}

sub validateDocumentation
{
    my $linesRef = shift;
    my $functionIndex = shift;
    my $relFile = shift;

    my $dox = "";

    my $functionLine = @{$linesRef}[$functionIndex];

    my $count = 0;
    my $index = $functionIndex;
    while (@{$linesRef}[$index] ne "/**\n") {
        $index--;
        $count++;
        if ($count > 45) {return;}
    }

    for (my $i=$index; $index < $functionIndex; $index++) {
        $dox .= @{$linesRef}[$index];
    }

    $functionLine =~ /(^\w*)\((.*)\).*;{0,0}\n/i;
    my $functionName = $1;
    my $arg = $2;

    if ($arg) {
        # there is some argument text, perhaps containing multiple arguments
        my @args = split(/,\s*/, $arg);
        if (@args) {
            # there was at least one argument
            foreach my $arg (@args) {
                $arg =~ s/\s*//g;
                unless ($dox =~ /\@param $arg/) {
                    $doxErrors .= "Doxygen block \'$arg\' parameter is undocumented: $relFile:$functionIndex:$functionName\n";
                }
            }
        }
    }

    unless ($dox =~ /\@brief/) {
        $doxErrors .= "Doxygen block missing the \@brief tag: $relFile:$functionIndex:$functionName\n";
    }
    unless ($dox =~ /\@returns/) {
        $doxErrors .= "Doxygen block missing the \@returns tag: $relFile:$functionIndex:$functionName\n";
    }
}

sub clean()
{
    my $cmd = "";

    # Delete all files in modPath
    deleteFile($config{modPath}.'\2d.iwd');
    deleteFile($config{modPath}.'\rotu_svr_custom.iwd');
    deleteFile($config{modPath}.'\rotu_svr_scripts.iwd');
    deleteFile($config{modPath}.'\rotu_svr_mapdata.iwd');
    deleteFile($config{modPath}.'\rotu_svr_scripts.debug');
    deleteFile($config{modPath}.'\sound.iwd');
    deleteFile($config{modPath}.'\weapons.iwd');
    deleteFile($config{modPath}.'\yz_custom.iwd');
    deleteFile($config{modPath}.'\mod.ff');
    deleteFile($config{modPath}.'\console_mp.log');
    deleteFile($config{modPath}.'\server_mp.log');
    deleteFile($config{modPath}.'\host.bat');
    deleteFile($config{modPath}.'\join.bat');
    deleteFile($config{modPath}.'\playMod.bat');
    foreach my $file (@{$config{configFiles}}) {
        deleteFile($config{modPath}.'\\'.$file);
    }
    report "Cleaned files from $config{modPath}\n";

    # Delete all files in build\non_debug
    my $folder = 'non_debug\scripts';
    if (-d $folder) {
        $cmd = 'rd /Q /S '.$folder;
        system($cmd) == 0 or die "system $cmd failed: $?";
    }
    report "Cleaned files from $folder\n";

    # Delete all files in uploadPath
    opendir(D, $config{uploadPath}) or die "can't open dir: $!";
    my @uploadFiles = grep { $_ ne '.' and $_ ne '..' } readdir D;
    close D;
    foreach my $file (@uploadFiles) {
        deleteFile($config{uploadPath}.'\\'.$file);
    }
    report "Cleaned files from $config{uploadPath}\n";

    # Delete all files in codPath/raw that are in src
    if (-e 'cod.raw.backup.zip') {
        # There is a backup, so ok to delete files from the raw folder
        loadRawFiles();
        foreach my $file (@rawFiles) {
            if ($file =~ /.*\/src(\/.*)/) {
                my $delFile = $config{codPath}.'\raw'.$1;
                $delFile =~ s!\/!\\!g;
                if (my $i >=1) {exit;}
#                 print "Deleting: $delFile\n";
                deleteFile($delFile);
            }
        }
        report "Cleaned files from $config{codPath}\\raw\n";
    } else {
        print "\n  Backup of raw folder not detected!  We will not try to delete files\n";
        print "  from $config{codPath}\\raw\n";
        print "  until you make a zip archive of that folder named cod.raw.backup.zip\n";
        print "  and place it in the build folder.\n";
        report "Backup wasn't detected, so we did not clean files from $config{codPath}\\raw\n";
    }

    print $report;
}

# Walk the directory tree
sub loadRawFiles()
{
  find(\&selectRawFiles,"$dir");
}

# Evaluate each file in dir
sub selectRawFiles()
{
    my $file_dir = $File::Find::name;
    return if ($file_dir =~ /\.svn/);   # skip .svn folder
    return if -d $file_dir;             # don't list directories themselves
    if ($file_dir =~ /.*src\/(ui_mp|mp|english|soundaliases|xanim|xmodel|xmodelparts|
                              xmodelsurfs|materials|material_properties|fx|shock|vision)\/.*/x)
    {
        push @rawFiles, $file_dir;
    }
}

sub report
{
    $report .= '  '.shift;
}

sub version()
{
    print "\n";
    print "  makeMod.pl - Builds the Reign of the Undead Call of Duty Mod\n";
    print "               Copyright (c) 2013 Mark A. Taff <mark\@marktaff.com>\n";
    print "               Version 0.97 Licensed under the MIT License.\n"
}

sub help()
{
    version();
    print "\n";
    print "  Usage: $0 [-f | -c | -d | -q | -s | -h | -v | -r release]\n\n";
    print "  Called with no switches, $0 builds only the components required due\n";
    print "  to source code changes it detects. Prior to first use, ensure you\n";
    print "  have edited makeConfig.pl to suit your environment. $0 depends on\n";
    print "  being called from the build folder.\n\n";
    print "  Switches:\n";
    print "    -f          Forces a full rebuild\n";
    print "    -c          Cleans up the development environment by deleting files it\n";
    print "                placed the CoD raw folder, in this mod's folder, in the build\n";
    print "                folder, and in the upload folder, then exits\n";
    print "    -d          Creates the debug version of the server script files. Can be\n";
    print "                combined with the -f or -s switches\n";
    print "    -q          Performs various code quality checks, then exits.  The checks\n";
    print "                are not infallible nor definitive.  They are intended to help\n";
    print "                find the needle in the haystack, not as a substitute for reason.\n";
    print "    -s          Forces a rebuild of the server script files only\n";
    print "    -h          Prints this help information\n";
    print "    -v          Prints version and copyright information\n";
    print "    -r release  Prepares a binary release from your working copy. The parameter\n";
    print "                'release' should be the name of the release.\n";
    print "\n";
    print "  Examples:\n";
    print "    perl $0 -fd                  Force a full debug rebuild\n";
    print "    perl $0 -sd                  Force a debug rebuild of the server scripts only\n";
    print "    perl $0 -r rotu.2.2.1r104    Prepare the 2.2.1 binary release\n";
}

sub updateUploadFolder()
{
    unless (-d $config{uploadPath}) {make_path($config{uploadPath});}

    print "Updating the upload folder...\n";

    my $copyCmd = 'robocopy ';
    my $switches = '/E /COPYALL /NFL /NDL /NJH  /NJS ';
    my $cmd = "";
    my $file = "";

    if ($rebuildServerScripts) {
        # Copy rotu_svr_scripts.iwd over
        $file = 'rotu_svr_scripts.iwd ';
        $cmd = $copyCmd.' "'.$config{modPath}.'" "'.$config{uploadPath}.'" '.$file.$switches;
        $cmd =~ s!\\!\/!g;
        # for robocopy, a byte-shifted return code of 3 or less is success
        system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
        report "Copied rotu_svr_scripts.iwd to $config{uploadPath}\n";
    }
    if ($rebuildServerCustom) {
        # Copy rotu_svr_custom.iwd over
        $file = 'rotu_svr_custom.iwd ';
        $cmd = $copyCmd.' "'.$config{modPath}.'" "'.$config{uploadPath}.'" '.$file.$switches;
        $cmd =~ s!\\!\/!g;
        # for robocopy, a byte-shifted return code of 3 or less is success
        system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
        report "Copied rotu_svr_custom.iwd to $config{uploadPath}\n";
    }
    if ($rebuildCustomIwd) {
        # Copy yz_custom.iwd over
        $file = 'yz_custom.iwd ';
        $cmd = $copyCmd.' "'.$config{modPath}.'" "'.$config{uploadPath}.'" '.$file.$switches;
        $cmd =~ s!\\!\/!g;
        # for robocopy, a byte-shifted return code of 3 or less is success
        system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
        report "Copied yz_custom.iwd to $config{uploadPath}\n";
    }
    if ($rebuildCustomMapsIwd) {
        # Copy rotu_svr_mapdata.iwd over
        $file = 'rotu_svr_mapdata.iwd ';
        $cmd = $copyCmd.' "'.$config{modPath}.'" "'.$config{uploadPath}.'" '.$file.$switches;
        $cmd =~ s!\\!\/!g;
        # for robocopy, a byte-shifted return code of 3 or less is success
        system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
        report "Copied rotu_svr_mapdata.iwd to $config{uploadPath}\n";
    }
    if ($rebuildSound) {
        # Copy sound.iwd over
        $file = 'sound.iwd ';
        $cmd = $copyCmd.' "'.$config{modPath}.'" "'.$config{uploadPath}.'" '.$file.$switches;
        $cmd =~ s!\\!\/!g;
        # for robocopy, a byte-shifted return code of 3 or less is success
        system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
        report "Copied sound.iwd to $config{uploadPath}\n";
    }
    if ($rebuild2D) {
        # Copy 2d.iwd over
        $file = '2d.iwd ';
        $cmd = $copyCmd.' "'.$config{modPath}.'" "'.$config{uploadPath}.'" '.$file.$switches;
        $cmd =~ s!\\!\/!g;
        # for robocopy, a byte-shifted return code of 3 or less is success
        system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
        report "Copied 2d.iwd to $config{uploadPath}\n";
    }
    if ($rebuildWeapons) {
        # Copy weapons.iwd over
        $file = 'weapons.iwd ';
        $cmd = $copyCmd.' "'.$config{modPath}.'" "'.$config{uploadPath}.'" '.$file.$switches;
        $cmd =~ s!\\!\/!g;
        # for robocopy, a byte-shifted return code of 3 or less is success
        system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
        report "Copied weapons.iwd to $config{uploadPath}\n";
    }
    if ($rebuildMod) {
        # Copy mod.ff over
        $file = 'mod.ff ';
        $cmd = $copyCmd.' "'.$config{modPath}.'" "'.$config{uploadPath}.'" '.$file.$switches;
        $cmd =~ s!\\!\/!g;
        # for robocopy, a byte-shifted return code of 3 or less is success
        system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
        report "Copied mod.ff to $config{uploadPath}\n";
    }
    if ($installConfig) {
        # Copy over all the config files
        foreach my $file (@{$config{configFiles}}) {
            $cmd = $copyCmd.' "'.$config{modPath}.'" "'.$config{uploadPath}.'" '.$file.' '.$switches;
            $cmd =~ s!\\!\/!g;
            # for robocopy, a byte-shifted return code of 3 or less is success
            system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
            report "Copied $file to $config{uploadPath}\n";
        }
    }

}
sub checksumUnreadable()
{
    print "Checksum file is unreadable, doing a full build.\n";
    doInitialBuild();
}

sub rebuildScriptsOnly()
{
    # Create a new checksum file
    buildNewChecksumFile();

    $rebuildMod = 0;
    $installConfig = 0;
    $installBatchFiles = 0;
    $rebuild2D = 0;
    $rebuildWeapons = 0;
    $rebuildSound = 0;
    $rebuildServerCustom = 1;
    $rebuildServerScripts = 1;
    $rebuildCustomIwd = 0;
    $rebuildCustomMapsIwd = 0;
    buildIwdFiles();

    updateUploadFolder();

    print "The server script files have been rebuilt.\n";
    print "$report";

    exit 0;
}

sub doInitialBuild()
{
    print "Building new checksum file...\n";

    # Create a new checksum file
    buildNewChecksumFile();

    # Build all the *.iwd zip files
    $rebuild2D = 1;
    $rebuildWeapons = 1;
    $rebuildSound = 1;
    $rebuildServerCustom = 1;
    $rebuildServerScripts = 1;
    $rebuildCustomIwd = 1;
    $rebuildCustomMapsIwd = 1;
    buildIwdFiles();

    # Build mod.ff
    $rebuildMod = 1;
    rebuildMod();

    # Install configuration files
    $installConfig = 1;
    installConfig();

    # Install batch files to launch the game
    $installBatchFiles = 1;
    installBatchFiles();

    updateUploadFolder();

    print "The mod is now installed and configured!\n";
    print "$report";

    exit 0;
}

sub buildNonDebugScriptFile
{
    # Make sure path to new file exists
    my $cwd = Cwd::cwd();
    my $newpath = $cwd;
    $newpath =~ s|src|build/non_debug|g;
    unless (-d $newpath) {make_path($newpath);}

    # Read in source file
    my $file = $_;
    open(R, "<$file") or die "can't open file: $!";
    # Open (create) the non-debug version of the file
    my $newfile = $newpath.'/'.$file;
    open(W, ">$newfile") or die "can't open file: $!";

    my $openCommentCount = 0;
    my $removeLine = 0;
    my $inMultiline = 0;
    while (my $line = <R>) {
        # Don't examine lines in multi-line comments, just print them to the
        # new file
        $open =()= $line =~ /\/\*/gi;
        $close =()= $line =~ /\*\//gi;
        # Add number of opening multi-line comment delimiters in this line
        $openCommentCount += $open;
        # Subtract number of closing multi-line comment delimiters in this line
        $openCommentCount -= $close;
        # If $openCommentCount is non-zero, we are in a multiline comment
        if ($openCommentCount) {
            print W $line;
            next;
        }
        # this is the last line of a multi-line comment
        if ($line =~ /(.*\*\/)(.*)/gi) {
            print W $line;
            next;
        }

        # Look for lines to remove
        if ($line =~ m!<debug>.*!) {
            $removeLine = 1;
            $inMultiline = 1;
        } elsif ($line =~ m!</debug>.*!) {
            $removeLine = 1;
            $inMultiline = 0;
        } elsif ($line =~ m!\/\/\s.*<debug \/>.*!) {
            $removeLine = 1;
        } elsif ($line =~ m!^\s*debugPrint\(".*!) {#    debugPrint("string"...)
            $removeLine = 1;
        } elsif ($line =~ m!^\s+debugPrint\(.*!) { #    debugPrint(currentMap + ...)
            $removeLine = 1;
        }

        if ($removeLine) {
#             print "Removed: $line";
            $line = "\n";
            unless ($inMultiline) {$removeLine = 0;}
        }
        print W $line;
    }
    close(R);
    close(W);
}

sub deleteFile
{
    my $file = $_[0];
#     print "$file\n";
    unless (-e $file) {return;}
#     print "deleting file\n";
    my $cmd = 'del "'.$file.'"';
#     $cmd =~ s!\\!\/!g;
    system($cmd) == 0 or die "system $cmd failed: $?";
}

sub prepareNonDebugBuild()
{
    my $cwd = Cwd::cwd();
    my $folder = 'non_debug\scripts';
    $folder =~ s!\/!\\!g;
    if (-d $folder) {
        my $cmd = 'rd /S /Q '.$folder;
        system($cmd) == 0 or die "system $cmd failed: $?";
    }

    my $path = '..\src\scripts';
    $path  =~ s!\\!\/!g;
    # Walk the directory tree
    find(\&selectScriptFiles,"$path");
}

# Find *.gsc files in scripts folder
sub selectScriptFiles()
{
    my $file_dir = $File::Find::name;
    return if ($file_dir =~ /\.svn/);   # skip .svn folder
    return if -d $file_dir;             # don't list directories themselves
#     print "$file_dir\n" if(/\.gsc$/i);
    buildNonDebugScriptFile($file_dir) if (/\.gsc$/i);
}

sub buildIwdFiles()
{
    my $cwd = Cwd::cwd();
    # @bug Do NOT use the -r switch for 7za.  It does NOT recurse directories, it
    # filters all folders that match, regardless of their location in the tree!
    my $zipCmd = $cwd.'/7za.exe a -tzip -xr!?svn ';
    my $archive = "";
    my $folders = "";
    my $cmd = "";
    my $nonDebugFilename = "";
    my $debugFilename = "";

    if ($rebuildServerScripts) {
        if ($opt_d){ # make debug version of server scripts
            $archive = $config{modPath}.'\rotu_svr_scripts.iwd';
            deleteFile($archive);
            $folders = '..\src\custom_scripts ..\src\maps ..\src\scripts';
            $cmd = $zipCmd.'"'.$archive.'" '.$folders;
            $cmd =~ s!\\!\/!g;
            system($cmd) == 0 or die "system $cmd failed: $?";
            report "Rebuilt debug version of rotu_svr_scripts.iwd\n";
        } else { # make non-debug version of server scripts
            prepareNonDebugBuild();
            $archive = $config{modPath}.'\rotu_svr_scripts.iwd';
            deleteFile($archive);
            $folders = '..\src\custom_scripts ..\src\maps .\non_debug\scripts';
            $cmd = $zipCmd.'"'.$archive.'" '.$folders;
            $cmd =~ s!\\!\/!g;
            system($cmd) == 0 or die "system $cmd failed: $?";
            report "Rebuilt non-debug version of rotu_svr_scripts.iwd\n";
        }
    } else {
        print "We do not need to rebuild rotu_svr_scripts.iwd\n";
    }
    if ($rebuildServerCustom) {
        $archive = $config{modPath}.'\rotu_svr_custom.iwd';
        deleteFile($archive);
        $folders = '..\src\custom_scripts ..\src\animtrees';
        $cmd = $zipCmd.'"'.$archive.'" '.$folders;
        $cmd =~ s!\\!\/!g;
        system($cmd) == 0 or die "system $cmd failed: $?";
        report "Rebuilt rotu_svr_custom.iwd\n";
    } else {
        print "We do not need to rebuild rotu_svr_custom.iwd\n";
    }
    if ($rebuildCustomIwd) {
        $archive = $config{modPath}.'\yz_custom.iwd';
        deleteFile($archive);
        $folders = '..\src\custom\images ..\src\custom\sound';
        $cmd = $zipCmd.'"'.$archive.'" '.$folders;
        $cmd =~ s!\\!\/!g;
        system($cmd) == 0 or die "system $cmd failed: $?";
        report "Rebuilt yz_custom.iwd\n";
    } else {
        print "We do not need to rebuild yz_custom.iwd\n";
    }
    if ($rebuildCustomMapsIwd) {
        $archive = $config{modPath}.'\rotu_svr_mapdata.iwd';
        deleteFile($archive);
        $folders = '..\src\custom_maps\maps';
        $cmd = $zipCmd.'"'.$archive.'" '.$folders;
        $cmd =~ s!\\!\/!g;
        system($cmd) == 0 or die "system $cmd failed: $?";
        report "Rebuilt rotu_svr_mapdata.iwd\n";
    } else {
        print "We do not need to rebuild rotu_svr_mapdata.iwd\n";
    }
    if ($rebuildSound) {
        $archive = $config{modPath}.'\sound.iwd';
        deleteFile($archive);
        $folders = '..\src\sound';
        $cmd = $zipCmd.'"'.$archive.'" '.$folders;
        $cmd =~ s!\\!\/!g;
        system($cmd) == 0 or die "system $cmd failed: $?";
        report "Rebuilt sound.iwd\n";
    } else {
        print "We do not need to rebuild sound.iwd\n";
    }
    if ($rebuild2D) {
        $archive = $config{modPath}.'\2d.iwd';
        deleteFile($archive);
        $folders = '..\src\images';
        $cmd = $zipCmd.'"'.$archive.'" '.$folders;
        $cmd =~ s!\\!\/!g;
        system($cmd) == 0 or die "system $cmd failed: $?";
        report "Rebuilt 2d.iwd\n";
    } else {
        print "We do not need to rebuild 2d.iwd\n";
    }
    if ($rebuildWeapons) {
        $archive = $config{modPath}.'\weapons.iwd';
        deleteFile($archive);
        $folders = '..\src\weapons';
        $cmd = $zipCmd.'"'.$archive.'" '.$folders;
        $cmd =~ s!\\!\/!g;
        system($cmd) == 0 or die "system $cmd failed: $?";
        report "Rebuilt weapons.iwd\n";
    } else {
        print "We do not need to rebuild weapons.iwd\n";
    }

}

sub findChanges()
{
    print "Looking for changed files...\n";

    # Walk the directory tree
    loadFiles();

    my $key = "";
    my $digest = "";

    # Read in all the saved checksum data
    open(C,"<$checksumFile") or die "Unable to open check file $checksumFile:$!\n";
    while (<C>){
        chomp;
        my @record = split('\|');
        $map{$record[0]} = $record[1];
#         $map{@record[0]} = @record[1];
    }
    close(C);

    foreach (@files) {
        open(F,$_) or die "Unable to open $_:$!\n";
        $key = Digest::MD5->new->add($_)->hexdigest;
        $digest = Digest::MD5->new->addfile(F)->hexdigest;

        # @todo handle new and/or removed files
        if ($map{$key} eq $digest) {
            # The files hasn't changed, so skip it
            next;
        } else {
            # ignore changes to checksumFile
            next if (m/.*checksum.*/);

            print "Found changed file: $_\n";
            $needToUpdateChecksums = 1;

            # What parts do we have to rebuild?
            if (m/.*\/maps\/.*/ or m/.*\/scripts\/.*/) {
                $rebuildServerScripts = 1;
                $rebuildCustomMapsIwd = 1;
            } elsif (m/.*\/custom\/.*/) {
                $rebuildCustomIwd = 1;
            } elsif (m/.*\/custom_scripts\/.*/ or m/.*\/animtrees\/.*/) {
                $rebuildServerScripts = 1;
                $rebuildServerCustom = 1;
            } elsif (m/.*\/images\/.*/) {
                $rebuild2D = 1;
                $rebuildMod = 1;
            } elsif (m/.*\/weapons\/.*/) {
                $rebuildWeapons = 1;
                $rebuildMod = 1;
            } elsif (m/.*\/sound\/.*/) {
                $rebuildSound = 1;
                $rebuildMod = 1;
            } elsif (m/.*\/ui_mp\/.*/ or
                     m/.*\/mp\/.*/ or
                     m/.*\/english\/.*/ or
                     m/.*\/soundaliases\/.*/ or
                     m/.*\/xanim\/.*/ or
                     m/.*\/xmodel\/.*/ or
                     m/.*\/xmodelparts\/.*/ or
                     m/.*\/xmodelsurfs\/.*/ or
                     m/.*\/materials\/.*/ or
                     m/.*\/material\/.*/ or
                     m/.*\/material_properties\/.*/ or
                     m/.*\/fx\/.*/ or
                     m/.*\/shock\/.*/ or
                     m/.*\/vision\/.*/ or
                     m/.*mod.csv/)
            {
                $rebuildMod = 1;
            } elsif (m/.*\.cfg/) {
                $installConfig = 1;
            } elsif (m/.*playMod.bat/ or
                     m/.*host.bat/ or
                     m/.*join.bat/)
            {
                $installBatchFiles = 1;
            }

            # Now update the hash
            $map{$key} = $digest;
        }
#         print C "$key|$digest","\n";
    }

}


sub rebuildMod()
{
    if ($rebuildMod) {
        print "Copying files as required so we can build mod.ff...\n";
        my $source = "";
        my $destination = "";
        my $cmd = "";
        my $file = "";
        my $path = "";

        my $copyCmd = 'robocopy ';
        my $switches = '/E /COPYALL /NFL /NDL /NJH  /NJS ';
        my $excludeDirs = '/XD .svn ';

        my @folders = ('\ui_mp', '\mp', '\maps', '\animtrees', '\english', '\soundaliases',
                    '\xanim', '\xmodel', '\xmodelparts', '\xmodelsurfs', '\materials',
                    '\material_properties', '\fx', '\shock', '\vision', '\images',
                    '\sound', '\weapons');
        foreach my $folder (@folders) {
            $destination = ' "'.$config{codPath}.'\raw'.$folder.'" ';
            $source = '..\src'.$folder;
            $cmd = $copyCmd.$source.$destination.$switches.$excludeDirs;
            $cmd =~ s!\\!\/!g;
            # for robocopy, a byte-shifted return code of 2 or less is success
            system($cmd) / 256 <= 3 or die "system $cmd failed: $?"
        }

        # Copy mod.csv over
        $source = '..\src';
        $file = '\mod.csv';
        $destination = ' "'.$config{codPath}.'\zone_source\"';
        $cmd = 'copy /Y '.$source.$file.' '.$destination;
        system($cmd) == 0 or die "system $cmd failed: $?";

        # Copy zone_source\*.csv files over
        $source = '..\src\zone_source ';
        $destination = ' "'.$config{codPath}.'\zone_source" ';
        $cmd = $copyCmd.$source.$destination.$switches.$excludeDirs;
        $cmd =~ s!\\!\/!g;
        # for robocopy, a byte-shifted return code of 2 or less is success
        system($cmd) / 256 <= 3 or die "system $cmd failed: $?";

        print "Finished copying files. Building mod.ff...\n";

        # Rebuild the mod.ff
        $cmd = '"'.$config{codPath}.'\bin\linker_pc.exe" -language english -compress -cleanup mod';
        $path = '"'.$config{codPath}.'\bin"';
        $cmd = '.\makeFF.bat '.$path;
        system($cmd) == 0 or die "system $cmd failed: $?";

        # Copy mod.ff to the mod folder
        $source = ' "'.$config{codPath}.'\zone\english" ';
        $file = 'mod.ff ';
        $destination = ' "'.$config{modPath}.'" ';
        $cmd = $copyCmd.$source.$destination.$file.$switches;
        $cmd =~ s!\\!\/!g;
        # for robocopy, a byte-shifted return code of 2 or less is success
        system($cmd) / 256 <= 3 or die "system $cmd failed: $?";

        report "Rebuilt mod.ff\n";
        print "Finished building the mod.ff fastfile. The rumble errors are harmless.\n";
    } else {
        print "We do not need to rebuild mod.ff\n";
    }
}

sub installConfig()
{
    if ($installConfig) {
        my $copyCmd = 'robocopy ';
        my $switches = '/COPYALL /NFL /NDL /NJH  /NJS ';
        my $source = "";
        my $file = "";
        my $destination = "";
        my $cmd = "";

        foreach my $file (@{$config{configFiles}}) {
            $file =~ m/(\w*).cfg/;
            $base = $1;
            $cfg = "../src/$file";
            unless (-e $cfg) {
                $default = "../src/$base".'_default.cfg';
                open(R, "<$default") or die "can't open file: $!";
                my $contents = do { local $/; <R> };
                close(R);
                open(W, ">$cfg") or die "can't open file: $!";
                print W $contents;
                close(W);
            }
            $source = '..\src ';
            $file = $file.' ';
            $destination = ' "'.$config{modPath}.'" ';
            $cmd = $copyCmd.$source.$destination.$file.$switches;
            $cmd =~ s!\\!\/!g;
            # for robocopy, a byte-shifted return code of 3 or less is success
            system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
#             report "Installed $file to $config{modPath}\n";
        }
    } else {
        print "We do not need to install config files.\n";
    }
}

sub installBatchFiles()
{
    if ($installBatchFiles) {
        my $copyCmd = 'robocopy ';
        my $switches = '/COPYALL /NFL /NDL /NJH  /NJS ';
        my $source = "";
        my $file = "";
        my $destination = "";
        my $cmd = "";

        my @batchFiles = ('playMod.bat', 'host.bat', 'join.bat');
        foreach my $file (@batchFiles) {
            $file =~ m/(\w*).bat/;
            $base = $1;
            $bat = "../src/$file";
            unless (-e $bat) {
                $default = "../src/$base".'_default.bat';
                open(R, "<$default") or die "can't open file: $!";
                my $contents = do { local $/; <R> };
                close(R);
                open(W, ">$bat") or die "can't open file: $!";
                print W $contents;
                close(W);
            }
            $source = '..\src ';
            $file = $file.' ';
            $destination = ' "'.$config{modPath}.'" ';
            $cmd = $copyCmd.$source.$destination.$file.$switches;
            $cmd =~ s!\\!\/!g;
            # for robocopy, a byte-shifted return code of 2 or less is success
            system($cmd) / 256 <= 3 or die "system $cmd failed: $?";
            report "Installed $file to $config{modPath}\n";
        }
    } else {
        print "We do not need to install batch files.\n";
    }
}

sub writeUpdatedChecksumFile()
{
    return unless $needToUpdateChecksums;

    print "Updating checksum file...\n";

    open(C,"+>$checksumFile") or die "Unable to open check file $checksumFile:$!\n";

    foreach my $key (keys %map) {
#         print "$key|$map{$key}","\n";
        print C "$key|$map{$key}","\n";
    }
    close C;

}

sub buildNewChecksumFile()
{
    # Walk the directory tree
    loadFiles();

    open(C,">$checksumFile") or die "Unable to open check file $checksumFile:$!\n";

    my $key = "";
    my $digest = "";
    foreach (@files) {
        open(F,$_) or die "Unable to open $_:$!\n";
        $key = Digest::MD5->new->add($_)->hexdigest;
        $digest = Digest::MD5->new->addfile(F)->hexdigest;
        print C "$key|$digest","\n";
    }
    close(C);
    print "Created new checksum file.\n";
}

# Walk the directory tree
sub loadFiles()
{
  find(\&selectFiles,"$dir");
}

# Evaluate each file in dir
sub selectFiles()
{
    my $file_dir = $File::Find::name;
    return if ($file_dir =~ /\.svn/);   # skip .svn folder
    return if ($file_dir =~ /rotu21/);   # skip legacy rotu21 folder -- ok to remove when rotu21 folder is deleted
    return if -d $file_dir;             # don't list directories themselves
    push @files, $file_dir;# if(/\.pl$/i);
}
