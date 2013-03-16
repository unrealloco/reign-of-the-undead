#!C:\MinGW\msys\1.0\bin\perl
#/******************************************************************************
#
#   mergeBanLists.pl - merges several ban.txt files into one mergedBan.txt file
#
#   Copyright (c) 2013 Mark A. Taff <mark@marktaff.com>.  Licensed under the
#   GNU GPL, v.3
# ******************************************************************************/

# use strict;
use warnings;

#C:\Users\Mark\Desktop\rotu2.2.upload\backup\ban.files>perl C:\Users\Mark\work\rotu\trunk\rotu21\mergeBanLists.pl .

# print "Hello, Perl!\n";

# hash of arrays that will hold the ban entries
my %entries = ();

# Get a list of all the ban files
my $dir = shift || die "Argument missing: directory name\n";
opendir(DIR, $dir);
@files =  grep { /ban/ } readdir(DIR);
closedir(DIR);

# Process each file
$fileCount = 0;
$lineCount = 0;
my @entries = ();
my $entry = "";
foreach $file (@files) {
    open my $data, $file or die "Could not open $file: $!";
    $fileCount++;
#     print "On file: $file\n";

    while(my $line = <$data>)  {
        $lineCount++;
        if ($line =~ /.*[[:xdigit:]]{32}.*/ism) {
            # There is at least one guid in this line
            @tokens = split " ", $line;
            foreach $token (@tokens) {
                if ($token =~ /[[:xdigit:]]{32}/ism) {
                    # this token begins an entry
                    if ($entry ne "") {
                        # we are starting a new entry from this line, save the
                        # current entry, then start this entry
                        push @entries, $entry;
#                         print "entry: $entry\n";
                        $entry = "$token ";
                        next;
                    }
                }
                $entry .= "$token ";
            }
        }
    }
    close $data;
    # add last entry in file
#     print "Last entry: $entry\n";
    push @entries, $entry;
    $entry = "";
}

$entriesFoundCount = @entries;
$dupCount = 0;
# We now have all the ban entries in the @entries array, ready to be split and hashed
foreach $entry (@entries) {
    @tokens = split " ", $entry;
    $guid = shift @tokens;
    # $text may contain the name and/or the reason for the ban
    $text = join " ", @tokens;
    $dupCount++ if exists $entries{$guid};
    # add the entry to the hash
    $entries{$guid} = $text;
}

# Write out the unique ban entries to merged_ban.txt
$count = 0;
my $ban;
open ($ban, ">merged_ban.txt") or die "Could not open merged_ban.txt: $!";
while (($guid,$text) = each %entries) {
    print {$ban} "$guid $text\n";
    $count++;
}

print "\nFiles: $fileCount    Lines: $lineCount     Entries Found: $entriesFoundCount   Duplicate Entries: $dupCount    Unique Entries: $count\n";



