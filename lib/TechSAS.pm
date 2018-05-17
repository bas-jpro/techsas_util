# TechSAS Data Utilities
#
# JPRO 17/05/2018
#

package TechSAS;
use strict;

use lib '/packages/techsas/current/lib';
use TechSAS::NMEA;
use TechSAS::NetCDF;

my $TECHSAS_PATH = "/data/cruise/dy/current/TechSAS";

sub new {
	my $class = shift;

	my $self = bless {
		nmea   => TechSAS::NMEA->new($TECHSAS_PATH),
	}, $class;

	return $self;
}

sub list_streams {
	my $self = shift;

	return $self->{nmea}->list_streams();
}

1;
