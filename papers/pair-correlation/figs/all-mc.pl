#!/usr/bin/perl -w

use strict;
use Digest::SHA qw(sha1_hex);
use File::Slurp qw(read_file);

my $dir = "papers/pair-correlation/figs";
my $sha1code = sha1_hex(read_file("src/Monte-Carlo/pair-monte-carlo.cpp"));

system "scons pair-monte-carlo";

my $iters  = 999999999999999;
my $acc = 0.001;

my $dd;
foreach $dd ([30,655, 0.1], [30,1327, 0.2], [30, 2009, 0.3], [30, 2696, 0.4]) {#, [30, 3381, 0.5]) {
    my $len = sprintf("%02.0f", $$dd[0]);
    my $N = sprintf("%03.0f", $$dd[1]);
    my $ff = sprintf("%02.1f", $$dd[2]);

    # Here I estimate the amount of memory that will be needed...
    my $memuse = sprintf "%.0f", 0.04*($N) + 50; # It's a very hokey guess

    my $scriptname = "$dir/wallsMC-pair-$len-$N.tmp.sh";

    my $da_dz_outfilename = "$dir/mc/a1/wallsMC-a1-pair-$ff";
    my $outfilename = "$dir/mc/wallsMC-pair-$ff";
    my $command = "./pair-monte-carlo $N $iters $acc $outfilename $da_dz_outfilename periodxy $len wallz $len flatdiv path";

    open SCRIPT, ">$scriptname" or die $!;
    print SCRIPT "#!/bin/sh
#SBATCH --mem-per-cpu=$memuse
##SBATCH --mail-type ALL
#SBATCH --output wallsMC-pair-$len-$N.out

set -ev

hostname
date

echo I think this will take $memuse megs of memory
time nice -19 $command

cat > $outfilename.sum << ENDF
$sha1code
$command
ENDF

date

";
    close(SCRIPT);
    my $oldsha1 = "\n";
    if (-e "$outfilename.sum") {
      $oldsha1 = read_file("$outfilename.sum");
    }
    if ($oldsha1 eq "$sha1code\n$command\n") {
      print "Pair-monte-carlo with $N spheres and length $len wallz and flat divisions has already been done.\n"
    } else {
      print "Submitting pair-monte-carlo with $N spheres and cavity with length $len wallz and flat divisions\n";

      system("sbatch", $scriptname);
      #system("nohup bash $scriptname &> $outfilename &");
    }
}
