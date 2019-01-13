#!/usr/local/bin/perl -w
#

use strict;
use lib '/packages/techsas/current/lib';
use TechSAS;

die "Usage: $0 tstamp\n" unless scalar(@ARGV) == 1;

my $techsas = TechSAS->new();

$techsas->attach('GPS-CNAV-cnav');
$techsas->find_time($ARGV[0]);

0;

