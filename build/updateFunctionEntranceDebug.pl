#!C:\strawberry\perl\bin\perl

# A quick hack to change the function entrance debug statement verbosity based on
# function call frequency

use Getopt::Std;
use Digest::MD5 qw(md5);
use File::Find;
use File::Basename;
use File::Path qw/make_path/;
use Cwd 'abs_path';

use warnings;

my %functionCounts = ();
my %records = ();
my $file = 'C:\Users\Mark\Desktop\rotudevUpload\function_frequency_data_server_mp.log';
#     print "$file\n";
my @files = ();

# Pre-declare subroutines
sub loadFiles();
sub selectFiles();
sub editFiles();

my $dir = abs_path("..");
# editFiles();
exit 0;

open(R, "<$file") or die "can't open file $file: $!";

my $i = 0;
my $key = "";
my $funcKey = "";

while (my $line = <R>) {
    $line =~ m/.*\sin\s(.*)\n/;
    $funcKey = $1;
    next unless ($funcKey);
    $key = Digest::MD5->new->add($funcKey)->hexdigest;
#     print $line;
#     print "$funcKey\n";
    if (exists $functionCounts{$key}) {
        $functionCounts{$key}->{count}++;
    } else {
        $functionCounts{$key}->{name} = $funcKey;
        $functionCounts{$key}->{count} = 1;
    }
    $i++;
#     last if ($i == 1000);
    if ($i == 500000) {
        print "500,000 lines processed\n";
        $i = 0;
    }
}
close(R);

sub byCounts { $functionCounts{$b}->{count} <=> $functionCounts{$a}->{count} }
sub sortCounts { $records{$b}->{count} <=> $records{$a}->{count} }


$file = "functionFrequencyReport_backup.csv";
open(Q, ">$file") or die "can't open file: $!";
$j = 1;
for $key (sort byCounts keys %functionCounts) {
    print $functionCounts{$key}->{name}.':'.$functionCounts{$key}->{count}."\n";
#     print Q '"'.$functionCounts{$key}->{name}.'","'.$j.'","'.$functionCounts{$key}->{count}.'"'."\n";
    print Q $functionCounts{$key}->{name}.','.$j.','.$functionCounts{$key}->{count}."\n";
    $j++;
}
close(Q);

sub editFiles()
{
    my $totalCount = 0;

    loadFiles();

    $file = "functionFrequencyReport.csv";
    open(R, "<$file") or die "can't open file: $!";

    while (my $line = <R>) {
#         print $line;
        ($key, $order, $count) = split /,/, $line, 3;
        chomp $count;
        $totalCount += $count;
        ($fileBasename, $remainder) = split /\:\:/, $key, 3;
#         print "file: $fileBasename remainder: $remainder\n";
        $fileBasename .= '.gsc';
#         print "$fileBasename:$key:$order:$count\n";
        $records{$key}->{order} = $order;
        $records{$key}->{count} = $count;
        $records{$key}->{basename} = $fileBasename;
#         print "$records{$key}->{basename}\n";
        $matchFound = 0;
        foreach $file (@files) {
            if ($file =~ /\/$records{$key}->{basename}/) {
#                 print "matches: $file\n";
                $matchFound = $file;
                $records{$key}->{path} = $file;
                last;
            }
        }
        unless ($matchFound) {print "No match for $matchFound\n";}
    }
    close(R);

    $n = 1;
    $verbosity = 7;
    $limit = $totalCount / 2 ** $n;
#     print "$totalCount\n";
#     print "$n:$verbosity:$limit\n";
    for $key (sort sortCounts keys %records) {
        print "Fixing key: $key\n";
        $runningCount += $records{$key}->{count};
        if ($runningCount > $limit and $verbosity > 0) {
            $n++;
            $verbosity--;
            $limit = $totalCount / 2 ** $n;
#             print "$n:$verbosity:$limit\n";
            $runningCount = $records{$key}->{count};
#             $runningCount = 0;
        }
        $records{$key}->{verbosity} = $verbosity;
#         print $records{$key}->{path}.':'.$key.':'.$records{$key}->{count}.':'.$records{$key}->{verbosity}."\n";
        open(R, "<$records{$key}->{path}") or die "can't open file: $!";
        my $contents = do { local $/; <R> };
        $tmpKey = $key;
        $tmpKey =~ s!\(\)!\\(\\)!g;
        $tmpKey =~ s!\:\:!\\:\\:!g;
        if ($records{$key}->{verbosity} == 7) {$textVerbosity = "fullVerbosity";}
        elsif ($records{$key}->{verbosity} == 6) {$textVerbosity = "absurdVerbosity";}
        elsif ($records{$key}->{verbosity} == 5) {$textVerbosity = "veryHighVerbosity";}
        elsif ($records{$key}->{verbosity} == 4) {$textVerbosity = "highVerbosity";}
        elsif ($records{$key}->{verbosity} == 3) {$textVerbosity = "medVerbosity";}
        elsif ($records{$key}->{verbosity} == 2) {$textVerbosity = "lowVerbosity";}
        elsif ($records{$key}->{verbosity} == 1) {$textVerbosity = "veryLowVerbosity";}
        elsif ($records{$key}->{verbosity} == 0) {$textVerbosity = "nonVerbose";}
        $newLine = '    debugPrint('.'"'."in $key".'", "fn", level.'.$textVerbosity.");\n";
        $pattern = qr/    debugPrint\(\"in $tmpKey", \"fn\", level.(.*)\);\n/;
        $pattern = qr/(    debugPrint\(\"in $tmpKey", \"fn\", level..*\);\n)/;
        $contents =~ s!$pattern!$newLine!;
#         print "old: $1";
#         print "new: $newLine";
#         print "$pattern\n";
#         unless ($contents =~ $pattern) {
#             print "Couldn't find pattern: $records{$key}->{path}:$key\n";
#         }
#         print "$1\n";
        close(R);
        open(W, ">$records{$key}->{path}") or die "can't open file: $!";
        print W $contents;
        close(W);
#         print "$runningCount>$limit\n";
    }
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
    return if ($file_dir =~ /build/);   # skip legacy rotu21 folder -- ok to remove when rotu21 folder is deleted
    return if -d $file_dir;             # don't list directories themselves
    push @files, $file_dir if(/\.gsc$/i);
}













